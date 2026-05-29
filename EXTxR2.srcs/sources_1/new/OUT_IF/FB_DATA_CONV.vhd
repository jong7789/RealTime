library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- EXT4343RD 10G framebuffer input packer: 8 x 64-bit beats -> 512-bit word
-- Write: 64-bit per beat (ien active, addra = ihcnt)
-- Read : 512-bit per 8 beats using DPRAM_64x960_512x120 asymmetric BRAM
--# 2605221642 Generic G_ODATA_WIDTH = 256 or 512 (selects asymmetric BRAM and pack ratio)
entity FB_DATA_CONV is
generic(
    G_ODATA_WIDTH : integer := 512                  --# 2605221642 256 or 512 only
);
port(
    iclk   : in  std_logic;
    irstn  : in  std_logic;

    ien    : in  std_logic;                                  -- pixel valid (shsync_img_proc & sreg_out_en)
    iframe : in  std_logic;                                  -- vsync   (svsync_img_proc & sreg_out_en)
    ihcnt  : in  std_logic_vector(9 downto 0);               -- horiz beat counter [9:0], 0..767 per line
    idata  : in  std_logic_vector(63 downto 0);              -- byte-swapped pixel data

    oen    : out std_logic;                                  -- packed-word valid (1/N rate of ien, N=G_ODATA_WIDTH/64)
    oframe : out std_logic;                                  -- vsync (1-clk delayed)
    odata  : out std_logic_vector(G_ODATA_WIDTH-1 downto 0); --# 2605221642 width follows generic
    owidth : out std_logic_vector(5 downto 0)                -- bytes-1 (e.g. 63=64B for 512, 31=32B for 256)
);
end FB_DATA_CONV;

architecture Behavioral of FB_DATA_CONV is

    --# 2605221642 Derived constants from G_ODATA_WIDTH
    -- C_BEATS_PER_WORD: 8 (512b) or 4 (256b)  -- # of 64-bit beats packed into 1 read word
    -- C_GROUP_LSB    : 3 (512b) or 2 (256b)  -- lower bits of ihcnt within a group
    -- C_RD_ADDR_W    : 7 (512b) or 8 (256b)  -- read-port (Port B) address width
    -- C_OWIDTH_VAL   : 63 (512b) or 31 (256b) -- owidth = bytes - 1
    function f_group_lsb(w : integer) return integer is                 --# 2605221642 VHDL-93 compatible
    begin
        if (w = 512) then return 3;
        else              return 2;
        end if;
    end function;
    constant C_BEATS_PER_WORD : integer := G_ODATA_WIDTH / 64;
    constant C_GROUP_LSB      : integer := f_group_lsb(G_ODATA_WIDTH);
    constant C_RD_ADDR_W      : integer := 10 - C_GROUP_LSB;
    constant C_OWIDTH_VAL     : integer := (G_ODATA_WIDTH / 8) - 1;

    --# 2605221642 Asymmetric BRAM (512-bit read): 64-bit x 960 write / 512-bit x 120 read
    component DPRAM_64x960_512x120
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(9 downto 0);
        dina  : in  std_logic_vector(63 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(6 downto 0);
        doutb : out std_logic_vector(511 downto 0)
    );
    end component;

    --# 2605221642 Asymmetric BRAM (256-bit read): 64-bit x 960 write / 256-bit x 240 read
    -- Generate in Vivado IP Catalog -> Block Memory Generator (Simple Dual Port, A:64x960, B:256x240, latency=1)
    component DPRAM_64x960_256x240
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(9 downto 0);
        dina  : in  std_logic_vector(63 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(7 downto 0);
        doutb : out std_logic_vector(255 downto 0)
    );
    end component;

    signal sien_1d    : std_logic                    := '0';
    signal sihcnt_1d  : std_logic_vector(9 downto 0) := (others => '0');

    signal srd_en        : std_logic                              := '0';
    signal srd_addr      : std_logic_vector(C_RD_ADDR_W-1 downto 0) := (others => '0');  --# 2605221642 width by generic
    signal srd_start     : std_logic                              := '0';                --$ 2605211430 ien falling-edge detect
    signal srd_active    : std_logic                              := '0';                --$ 2605211430 Burst-in-progress flag
    signal srd_cnt       : std_logic_vector(C_RD_ADDR_W-1 downto 0) := (others => '0');  --# 2605221642 width by generic
    signal srd_num       : std_logic_vector(C_RD_ADDR_W-1 downto 0) := (others => '0');  --# 2605221642 width by generic

    signal sodata : std_logic_vector(G_ODATA_WIDTH-1 downto 0) := (others => '0');       --# 2605221642 width by generic
    signal soen   : std_logic := '0';                                                    --$ 2605211930 Shadow of oen for falling-edge detect

begin

    --$ 2605211000 Register ien and last-active ihcnt for falling-edge detect and last-group addr
    process(iclk)
    begin
        if(iclk'event and iclk = '1') then
            if(irstn = '0') then
                sien_1d   <= '0';
                sihcnt_1d <= (others => '0');
            else
                sien_1d <= ien;
                if(ien = '1') then
                    sihcnt_1d <= ihcnt;    -- retains last ihcnt=767 after line ends
                end if;
            end if;
        end if;
    end process;

    --$ 2605211430 Burst-read sequencer: on ien falling edge, sweep addr 0..sihcnt_1d[9:C_GROUP_LSB]
    --             srd_en held HIGH for (sihcnt_1d/N + 1) cycles; first srd_en cycle issues addr=0
    --# 2605221642 group index = sihcnt_1d(9 downto C_GROUP_LSB), C_GROUP_LSB=3(512)/2(256)
    srd_start <= sien_1d and (not ien);

    process(iclk)
    begin
        if(iclk'event and iclk = '1') then
            if(irstn = '0') then
                srd_active <= '0';
                srd_cnt    <= (others => '0');
                srd_num    <= (others => '0');
                srd_en     <= '0';
                srd_addr   <= (others => '0');
            else
                if(srd_active = '0') then
                    if(srd_start = '1') then
                        srd_active <= '1';
                        srd_num    <= sihcnt_1d(9 downto C_GROUP_LSB) + 1;   --# 2605221642 group count by generic
                        srd_cnt    <= (others => '0');
                        srd_en     <= '1';
                        srd_addr   <= (others => '0');                     -- first read = addr 0
                    else
                        srd_en   <= '0';
                        srd_addr <= (others => '0');
                    end if;
                else
                    if(srd_cnt = srd_num - 1) then
                        srd_active <= '0';
                        srd_en     <= '0';
                        srd_addr   <= (others => '0');
                        srd_cnt    <= (others => '0');
                    else
                        srd_cnt  <= srd_cnt + 1;
                        srd_addr <= srd_cnt + 1;
                        srd_en   <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    --# 2605221642 DPRAM IP selected by G_ODATA_WIDTH via if-generate (Port B width differs)
    GEN_DPRAM_512 : if G_ODATA_WIDTH = 512 generate
        U_DPRAM_512 : DPRAM_64x960_512x120
        port map (
            clka  => iclk,
            ena   => ien,
            wea   => '1',
            addra => ihcnt,
            dina  => idata,
            clkb  => iclk,
            enb   => srd_en,
            addrb => srd_addr,
            doutb => sodata
        );
    end generate GEN_DPRAM_512;

    GEN_DPRAM_256 : if G_ODATA_WIDTH = 256 generate
        U_DPRAM_256 : DPRAM_64x960_256x240
        port map (
            clka  => iclk,
            ena   => ien,
            wea   => '1',
            addra => ihcnt,
            dina  => idata,
            clkb  => iclk,
            enb   => srd_en,
            addrb => srd_addr,
            doutb => sodata
        );
    end generate GEN_DPRAM_256;

    --$ 2605211000 Output aligned to BRAM registered output (1-cycle latency)
    process(iclk)
    begin
        if(iclk'event and iclk = '1') then
            if(irstn = '0') then
                oen    <= '0';
                soen   <= '0';                                                       --$ 2605211930 Reset shadow
                oframe <= '0';
            else
                oen    <= srd_en;
                soen <= srd_en;                                                      --$ 2605211930 Mirror oen internally
                if (srd_en = '1' and iframe = '1') then                              --$ 2605211930 oframe rises with first oen of frame
                    oframe <= '1';
                elsif (srd_en = '0' and iframe = '0' and soen = '1') then            --$ 2605211930 Drop only when oen is falling AND outside frame
                    oframe <= '0';
                end if;
            end if;
        end if;
    end process;
    --$ 2605221045 Reverse 8x64-bit beat order to match block-internal MSB-first convention (fix psel4 32px reversal)
    --# 2605221652 Same reversal applied to 256-bit mode (4x64-bit beats); split via if-generate (slice width differs)
--    odata  <= sodata;
    GEN_ODATA_512 : if G_ODATA_WIDTH = 512 generate
        odata  <= sodata( 63 downto   0) &
                  sodata(127 downto  64) &
                  sodata(191 downto 128) &
                  sodata(255 downto 192) &
                  sodata(319 downto 256) &
                  sodata(383 downto 320) &
                  sodata(447 downto 384) &
                  sodata(511 downto 448);
    end generate GEN_ODATA_512;

    GEN_ODATA_256 : if G_ODATA_WIDTH = 256 generate                       --# 2605221652 Reverse 4x64-bit beats for 256b
        odata  <= sodata( 63 downto   0) &
                  sodata(127 downto  64) &
                  sodata(191 downto 128) &
                  sodata(255 downto 192);
    end generate GEN_ODATA_256;

    owidth <= conv_std_logic_vector(C_OWIDTH_VAL, 6);   --# 2605221642 bytes-1: 63(64B/512b) or 31(32B/256b)

end Behavioral;
