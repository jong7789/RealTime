-- ### history ###
--  210402 mbh
--      - defect dpram2bram 32x4096
--      - blk_mem_32x4096

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity DEFECT_PROC is
    port (
        idata_clk         : in  std_logic;
        idata_rstn        : in  std_logic;

        ireg_debug_mode   : in  std_logic;
        ireg_defect_map   : in  std_logic;

        ireg_defect_mode  : in  std_logic;
        ireg_defect_wen   : in  std_logic;
        ireg_defect_addr  : in  std_logic_vector(15 downto 0);
        ireg_defect_wdata : in  std_logic_vector(31 downto 0);
        oreg_defect_rdata : out std_logic_vector(31 downto 0);

        ireg_width        : in  std_logic_vector(11 downto 0);
        ireg_height       : in  std_logic_vector(11 downto 0);

        ihsync            : in  std_logic;
        ivsync            : in  std_logic;
        ihcnt             : in  std_logic_vector(11 downto 0);
        ivcnt             : in  std_logic_vector(11 downto 0);
        idata             : in  std_logic_vector(15 downto 0);

        ohsync            : out std_logic;
        ovsync            : out std_logic;
        ohcnt             : out std_logic_vector(11 downto 0);
        ovcnt             : out std_logic_vector(11 downto 0);
        odata             : out std_logic_vector(15 downto 0)
    );
end DEFECT_PROC;

architecture Behavioral of DEFECT_PROC is

    component RAM_32x4096
        port (
            clk : in  std_logic;
            a   : in  std_logic_vector(11 downto 0);
            d   : in  std_logic_vector(31 downto 0);
            we  : in  std_logic;
            spo : out std_logic_vector(31 downto 0)
        );
    end component;

    COMPONENT blk_mem_32x4096
        PORT (
            clka  : IN  STD_LOGIC;
            wea   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
            dina  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            clkb  : IN  STD_LOGIC;
            web   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
            addrb : IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
            dinb  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    component MASK_OUT
        port (
            idata_clk  : in  std_logic;
            idata_rstn : in  std_logic;

            ireg_width  : in  std_logic_vector(11 downto 0);
            ireg_height : in  std_logic_vector(11 downto 0);

            ihsync : in  std_logic;
            ivsync : in  std_logic;
            ihcnt  : in  std_logic_vector(11 downto 0);
            ivcnt  : in  std_logic_vector(11 downto 0);
            idata  : in  std_logic_vector(15 downto 0);

            ohsync_2x2 : out std_logic;
            ovsync_2x2 : out std_logic;
            ohcnt_2x2  : out std_logic_vector(11 downto 0);
            ovcnt_2x2  : out std_logic_vector(11 downto 0);

            odata_1x1 : out std_logic_vector(15 downto 0);
            odata_1x2 : out std_logic_vector(15 downto 0);
            odata_1x3 : out std_logic_vector(15 downto 0);
            odata_2x1 : out std_logic_vector(15 downto 0);
            odata_2x2 : out std_logic_vector(15 downto 0);
            odata_2x3 : out std_logic_vector(15 downto 0);
            odata_3x1 : out std_logic_vector(15 downto 0);
            odata_3x2 : out std_logic_vector(15 downto 0);
            odata_3x3 : out std_logic_vector(15 downto 0)
        );
    end component;

    component DEFECT_DECODER
        port (
            idata_clk  : in  std_logic;
            idata_rstn : in  std_logic;

            idefect_data : in  std_logic_vector(7 downto 0);

            ihsync : in  std_logic;
            ivsync : in  std_logic;
            ihcnt  : in  std_logic_vector(11 downto 0);
            ivcnt  : in  std_logic_vector(11 downto 0);

            idata_1x1 : in  std_logic_vector(15 downto 0);
            idata_1x2 : in  std_logic_vector(15 downto 0);
            idata_1x3 : in  std_logic_vector(15 downto 0);
            idata_2x1 : in  std_logic_vector(15 downto 0);
            idata_2x2 : in  std_logic_vector(15 downto 0);
            idata_2x3 : in  std_logic_vector(15 downto 0);
            idata_3x1 : in  std_logic_vector(15 downto 0);
            idata_3x2 : in  std_logic_vector(15 downto 0);
            idata_3x3 : in  std_logic_vector(15 downto 0);

            ohsync : out std_logic;
            ovsync : out std_logic;
            ohcnt  : out std_logic_vector(11 downto 0);
            ovcnt  : out std_logic_vector(11 downto 0);
            odata  : out std_logic_vector(15 downto 0);

            odata_sum : out std_logic_vector(18 downto 0);
            odata_mul : out std_logic_vector(17 downto 0)
        );
    end component;

    component MULTI_19x17
        port (
            clk : in  std_logic;
            ce  : in  std_logic;
            a   : in  std_logic_vector(18 downto 0);
            b   : in  std_logic_vector(16 downto 0);
            p   : out std_logic_vector(35 downto 0)
        );
    end component;

    signal same              : std_logic; -- compare next data mbh 210402
    signal sdebug_mode       : std_logic;
    signal sdefect_mode      : std_logic;
    signal sdefect_map       : std_logic;
    signal sdefect_wen       : std_logic;
    signal sdefect_addr      : std_logic_vector(11 downto 0);
    signal sdefect_wdata     : std_logic_vector(31 downto 0);
    signal sdefect_rdata     : std_logic_vector(31 downto 0);
    signal snext_rdata       : std_logic_vector(31 downto 0);

    signal shsync_2x2        : std_logic;
    signal svsync_2x2        : std_logic;
    signal shcnt_2x2         : std_logic_vector(11 downto 0);
    signal svcnt_2x2         : std_logic_vector(11 downto 0);
    signal sdata_1x1         : std_logic_vector(15 downto 0);
    signal sdata_1x2         : std_logic_vector(15 downto 0);
    signal sdata_1x3         : std_logic_vector(15 downto 0);
    signal sdata_2x1         : std_logic_vector(15 downto 0);
    signal sdata_2x2         : std_logic_vector(15 downto 0);
    signal sdata_2x3         : std_logic_vector(15 downto 0);
    signal sdata_3x1         : std_logic_vector(15 downto 0);
    signal sdata_3x2         : std_logic_vector(15 downto 0);
    signal sdata_3x3         : std_logic_vector(15 downto 0);

    signal shsync_decoder    : std_logic;
    signal svsync_decoder    : std_logic;
    signal shcnt_decoder     : std_logic_vector(11 downto 0);
    signal svcnt_decoder     : std_logic_vector(11 downto 0);
    signal sdata_decoder     : std_logic_vector(15 downto 0);
    signal sdata_sum_decoder : std_logic_vector(18 downto 0);
    signal sdata_mul_decoder : std_logic_vector(17 downto 0);

    signal sdata_p           : std_logic_vector(35 downto 0);

    signal shsync_defect     : std_logic;
    signal svsync_defect     : std_logic;
    signal shcnt_defect      : std_logic_vector(11 downto 0);
    signal svcnt_defect      : std_logic_vector(11 downto 0);
    signal sdata_defect      : std_logic_vector(15 downto 0);

    signal shsync_out        : std_logic;
    signal svsync_out        : std_logic;
    signal shcnt_out         : std_logic_vector(11 downto 0);
    signal svcnt_out         : std_logic_vector(11 downto 0);
    signal sdata_out         : std_logic_vector(15 downto 0);

    signal sreg_debug_mode      : std_logic;
    signal sreg_debug_mode_1d   : std_logic;
    signal sreg_debug_mode_2d   : std_logic;
    signal sreg_debug_mode_3d   : std_logic;
    signal sreg_defect_mode     : std_logic;
    signal sreg_defect_mode_1d  : std_logic;
    signal sreg_defect_mode_2d  : std_logic;
    signal sreg_defect_mode_3d  : std_logic;
    signal sreg_defect_map      : std_logic;
    signal sreg_defect_map_1d   : std_logic;
    signal sreg_defect_map_2d   : std_logic;
    signal sreg_defect_map_3d   : std_logic;
    signal sreg_defect_wen      : std_logic;
    signal sreg_defect_wen_1d   : std_logic;
    signal sreg_defect_wen_2d   : std_logic;
    signal sreg_defect_wen_3d   : std_logic;
    signal sreg_defect_addr     : std_logic_vector(15 downto 0);
    signal sreg_defect_addr_1d  : std_logic_vector(15 downto 0);
    signal sreg_defect_addr_2d  : std_logic_vector(15 downto 0);
    signal sreg_defect_addr_3d  : std_logic_vector(15 downto 0);
    signal sreg_defect_wdata    : std_logic_vector(31 downto 0);
    signal sreg_defect_wdata_1d : std_logic_vector(31 downto 0);
    signal sreg_defect_wdata_2d : std_logic_vector(31 downto 0);
    signal sreg_defect_wdata_3d : std_logic_vector(31 downto 0);

    signal shsync_decoder_1d : std_logic;
    signal svsync_decoder_1d : std_logic;
    signal svcnt_decoder_1d  : std_logic_vector(11 downto 0);
    signal shcnt_decoder_1d  : std_logic_vector(11 downto 0);
    signal sdata_decoder_1d  : std_logic_vector(15 downto 0);
    signal shsync_decoder_2d : std_logic;
    signal svsync_decoder_2d : std_logic;
    signal svcnt_decoder_2d  : std_logic_vector(11 downto 0);
    signal shcnt_decoder_2d  : std_logic_vector(11 downto 0);
    signal sdata_decoder_2d  : std_logic_vector(15 downto 0);
    signal shsync_decoder_3d : std_logic;
    signal svsync_decoder_3d : std_logic;
    signal svcnt_decoder_3d  : std_logic_vector(11 downto 0);
    signal shcnt_decoder_3d  : std_logic_vector(11 downto 0);
    signal sdata_decoder_3d  : std_logic_vector(15 downto 0);
    signal sdata_decoder_4d  : std_logic_vector(15 downto 0);

    signal sdefect_rdata_1d : std_logic_vector(31 downto 0);
    signal sdefect_rdata_2d : std_logic_vector(31 downto 0);
    signal sdefect_rdata_3d : std_logic_vector(31 downto 0);
    signal sdefect_rdata_4d : std_logic_vector(31 downto 0);
    signal sdefect_rdata_5d : std_logic_vector(31 downto 0);

    signal sdefect_same : std_logic_vector(31 downto 0);
    signal portm_12b_0  : std_logic_vector(12 - 1 downto 0);

begin

    U0_MASK_OUT : MASK_OUT
    port map (
        idata_clk   => idata_clk,
        idata_rstn  => idata_rstn,

        ireg_width  => ireg_width,
        ireg_height => ireg_height,

        ihsync      => ihsync,
        ivsync      => ivsync,
        ihcnt       => ihcnt,
        ivcnt       => ivcnt,
        idata       => idata,

        ohsync_2x2  => shsync_2x2,
        ovsync_2x2  => svsync_2x2,
        ohcnt_2x2   => shcnt_2x2,
        ovcnt_2x2   => svcnt_2x2,

        odata_1x1   => sdata_1x1,
        odata_1x2   => sdata_1x2,
        odata_1x3   => sdata_1x3,
        odata_2x1   => sdata_2x1,
        odata_2x2   => sdata_2x2,
        odata_2x3   => sdata_2x3,
        odata_3x1   => sdata_3x1,
        odata_3x2   => sdata_3x2,
        odata_3x3   => sdata_3x3
    );

--  U0_DEFECT_RAM : RAM_32x4096
--  port map (
--      clk  => idata_clk,
--      a    => sdefect_addr,
--      d    => sdefect_wdata,
--      we   => sdefect_wen,
--      spo  => sdefect_rdata
--  );
    portm_12b_0 <= (sdefect_addr + '1');
    u_blk_mem_32x4096 : blk_mem_32x4096
    PORT MAP (
        clka   => idata_clk,
        wea(0) => sdefect_wen,
        addra  => sdefect_addr,
        dina   => sdefect_wdata,
        douta  => sdefect_rdata,
        clkb   => idata_clk,
        web(0) => '0',
        addrb  => portm_12b_0, --# (sdefect_addr+'1'),
        dinb   => (others => '0'),
        doutb  => snext_rdata
    );

    oreg_defect_rdata <= sdefect_rdata;

--u_ila_defect : ila_defect
--PORT MAP (
--  clk    => idata_clk,    -- 1
--  probe0 => same,         -- 1
--  probe1 => shsync_2x2,   -- 1
--  probe2 => svcnt_2x2,    -- 12
--  probe3 => shcnt_2x2,    -- 12
--  probe4 => sdefect_addr, -- 12
--  probe5 => sdefect_rdata, -- 32
--  probe6 => snext_rdata,  -- 32
--  probe7 => sdefect_wen   -- 1
--);

    sdefect_same <= sdefect_rdata when same = '0' else
                    snext_rdata;

    U0_DEFECT_DECODER : DEFECT_DECODER -- 1 Delay
    port map (
        idata_clk    => idata_clk,
        idata_rstn   => idata_rstn,

        idefect_data => sdefect_same(31 downto 24),

        ihsync       => shsync_2x2,
        ivsync       => svsync_2x2,
        ihcnt        => shcnt_2x2,
        ivcnt        => svcnt_2x2,
        idata_1x1    => sdata_1x1,
        idata_1x2    => sdata_1x2,
        idata_1x3    => sdata_1x3,
        idata_2x1    => sdata_2x1,
        idata_2x2    => sdata_2x2,
        idata_2x3    => sdata_2x3,
        idata_3x1    => sdata_3x1,
        idata_3x2    => sdata_3x2,
        idata_3x3    => sdata_3x3,

        ohsync       => shsync_decoder,
        ovsync       => svsync_decoder,
        ovcnt        => svcnt_decoder,
        ohcnt        => shcnt_decoder,
        odata        => sdata_decoder,

        odata_sum    => sdata_sum_decoder,
        odata_mul    => sdata_mul_decoder
    );

    U0_MULTI_19x17 : MULTI_19x17 -- 3 delay
    port map (
        clk => idata_clk,
        ce  => idata_rstn,
        a   => sdata_sum_decoder,
        b   => sdata_mul_decoder(16 downto 0),
        p   => sdata_p
    );

    --# defect RAM address control and write enable
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sdefect_wen   <= '0';
                sdefect_addr  <= (others => '0');
                sdefect_wdata <= (others => '0');
            else
                sdefect_wen <= sreg_defect_wen_3d;

                if (sreg_defect_wen_3d = '0' and sdebug_mode = '0') then
--                  if(sdebug_mode = '0') then
                    if (svsync_2x2 = '0') then
                        sdefect_addr <= x"000";
                        same <= '0';
                    else
                        if (shsync_2x2 = '1') then
                            if (sdefect_rdata(23 downto 12) = svcnt_2x2 and sdefect_rdata(11 downto 0) = shcnt_2x2) then
                                sdefect_addr <= sdefect_addr + '1';
                                same <= '1';
                            elsif (snext_rdata(23 downto 12) = svcnt_2x2 and snext_rdata(11 downto 0) = shcnt_2x2) and same = '1' then
                                sdefect_addr <= sdefect_addr + '1';
                                same <= '1';
                            else
                                same <= '0';
                            end if;
                        end if;
                    end if;
                else
                    sdefect_addr  <= sreg_defect_addr_3d(11 downto 0);
                    sdefect_wdata <= sreg_defect_wdata_3d;
                    same <= '0';
                end if;
            end if;
        end if;
    end process;

    --# defect correction output with multiplier result
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_defect <= '0';
                svsync_defect <= '0';
                shcnt_defect  <= (others => '0');
                svcnt_defect  <= (others => '0');
                sdata_defect  <= (others => '0');
            else
                shsync_defect <= shsync_decoder_3d;
                svsync_defect <= svsync_decoder_3d;
                shcnt_defect  <= shcnt_decoder_3d;
                svcnt_defect  <= svcnt_decoder_3d;

                if (shsync_decoder_3d = '1') then
                    if (sdefect_map = '0') then
                        if (sdefect_rdata_5d(23 downto 12) = svcnt_decoder_3d and sdefect_rdata_5d(11 downto 0) = shcnt_decoder_3d) then
                            if (sdata_p(35 downto 32) > 0) then
                                sdata_defect <= x"FFFF";
                            else
                                sdata_defect <= sdata_p(31 downto 16);
                            end if;
                        else
                            sdata_defect <= sdata_decoder_3d;
                        end if;
                    else
                        if (sdefect_rdata_5d(23 downto 12) = svcnt_decoder_3d and sdefect_rdata_5d(11 downto 0) = shcnt_decoder_3d) then
                            sdata_defect <= x"FFFF";
                        else
                            if (sdata_decoder_3d = x"FFFF") then
                                sdata_defect <= x"FFFF";
                            else
                                sdata_defect <= (others => '0');
                            end if;
                        end if;
                    end if;
                else
                    sdata_defect <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --# output stage with defect mode selection
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                svcnt_out  <= (others => '0');
                shcnt_out  <= (others => '0');
                sdata_out  <= (others => '0');
            else
                shsync_out <= shsync_defect;
                svsync_out <= svsync_defect;
                svcnt_out  <= svcnt_defect;
                shcnt_out  <= shcnt_defect;

                if (sdefect_map = '0') then
                    if (sdefect_mode = '1') then
                        sdata_out <= sdata_defect;
                    else
                        sdata_out <= sdata_decoder_4d;
                    end if;
                else
                    sdata_out <= sdata_defect;
                end if;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ovcnt  <= svcnt_out;
    ohcnt  <= shcnt_out;
    odata  <= sdata_out;

    --# latch debug/defect mode on vsync boundary
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sdebug_mode  <= '0';
                sdefect_mode <= '0';
                sdefect_map  <= '0';
            else
                sdebug_mode <= sreg_debug_mode_3d;

                if (svsync_defect = '0') then
                    sdefect_mode <= sreg_defect_mode_3d;
                    sdefect_map  <= sreg_defect_map_3d;
                end if;
            end if;
        end if;
    end process;

    --# register synchronizer pipeline (clock domain crossing)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sreg_debug_mode      <= '0';
                sreg_debug_mode_1d   <= '0';
                sreg_debug_mode_2d   <= '0';
                sreg_debug_mode_3d   <= '0';
                sreg_defect_mode     <= '0';
                sreg_defect_mode_1d  <= '0';
                sreg_defect_mode_2d  <= '0';
                sreg_defect_mode_3d  <= '0';
                sreg_defect_map      <= '0';
                sreg_defect_map_1d   <= '0';
                sreg_defect_map_2d   <= '0';
                sreg_defect_map_3d   <= '0';
                sreg_defect_wen      <= '0';
                sreg_defect_wen_1d   <= '0';
                sreg_defect_wen_2d   <= '0';
                sreg_defect_wen_3d   <= '0';
                sreg_defect_addr     <= (others => '0');
                sreg_defect_addr_1d  <= (others => '0');
                sreg_defect_addr_2d  <= (others => '0');
                sreg_defect_addr_3d  <= (others => '0');
                sreg_defect_wdata    <= (others => '0');
                sreg_defect_wdata_1d <= (others => '0');
                sreg_defect_wdata_2d <= (others => '0');
                sreg_defect_wdata_3d <= (others => '0');

                sdefect_rdata_1d     <= (others => '0');
                sdefect_rdata_2d     <= (others => '0');
                sdefect_rdata_3d     <= (others => '0');
                sdefect_rdata_4d     <= (others => '0');
                sdefect_rdata_5d     <= (others => '0');

                shsync_decoder_1d    <= '0';
                svsync_decoder_1d    <= '0';
                svcnt_decoder_1d     <= (others => '0');
                shcnt_decoder_1d     <= (others => '0');
                sdata_decoder_1d     <= (others => '0');
                shsync_decoder_2d    <= '0';
                svsync_decoder_2d    <= '0';
                svcnt_decoder_2d     <= (others => '0');
                shcnt_decoder_2d     <= (others => '0');
                sdata_decoder_2d     <= (others => '0');
                shsync_decoder_3d    <= '0';
                svsync_decoder_3d    <= '0';
                svcnt_decoder_3d     <= (others => '0');
                shcnt_decoder_3d     <= (others => '0');
                sdata_decoder_3d     <= (others => '0');
                sdata_decoder_4d     <= (others => '0');
            else
                sreg_debug_mode      <= ireg_debug_mode;
                sreg_debug_mode_1d   <= sreg_debug_mode;
                sreg_debug_mode_2d   <= sreg_debug_mode_1d;
                sreg_debug_mode_3d   <= sreg_debug_mode_2d;
                sreg_defect_mode     <= ireg_defect_mode;
                sreg_defect_mode_1d  <= sreg_defect_mode;
                sreg_defect_mode_2d  <= sreg_defect_mode_1d;
                sreg_defect_mode_3d  <= sreg_defect_mode_2d;
                sreg_defect_map      <= ireg_defect_map;
                sreg_defect_map_1d   <= sreg_defect_map;
                sreg_defect_map_2d   <= sreg_defect_map_1d;
                sreg_defect_map_3d   <= sreg_defect_map_2d;
                sreg_defect_wen      <= ireg_defect_wen;
                sreg_defect_wen_1d   <= sreg_defect_wen;
                sreg_defect_wen_2d   <= sreg_defect_wen_1d;
                sreg_defect_wen_3d   <= sreg_defect_wen_2d;
                sreg_defect_addr     <= ireg_defect_addr;
                sreg_defect_addr_1d  <= sreg_defect_addr;
                sreg_defect_addr_2d  <= sreg_defect_addr_1d;
                sreg_defect_addr_3d  <= sreg_defect_addr_2d;
                sreg_defect_wdata    <= ireg_defect_wdata;
                sreg_defect_wdata_1d <= sreg_defect_wdata;
                sreg_defect_wdata_2d <= sreg_defect_wdata_1d;
                sreg_defect_wdata_3d <= sreg_defect_wdata_2d;
                -- sdefect_rdata_1d  <= sdefect_rdata; -- 210811
                sdefect_rdata_1d     <= sdefect_same;
                sdefect_rdata_2d     <= sdefect_rdata_1d;
                sdefect_rdata_3d     <= sdefect_rdata_2d;
                sdefect_rdata_4d     <= sdefect_rdata_3d;
                sdefect_rdata_5d     <= sdefect_rdata_4d;

                shsync_decoder_1d    <= shsync_decoder;
                svsync_decoder_1d    <= svsync_decoder;
                svcnt_decoder_1d     <= svcnt_decoder;
                shcnt_decoder_1d     <= shcnt_decoder;
                sdata_decoder_1d     <= sdata_decoder;
                shsync_decoder_2d    <= shsync_decoder_1d;
                svsync_decoder_2d    <= svsync_decoder_1d;
                svcnt_decoder_2d     <= svcnt_decoder_1d;
                shcnt_decoder_2d     <= shcnt_decoder_1d;
                sdata_decoder_2d     <= sdata_decoder_1d;
                shsync_decoder_3d    <= shsync_decoder_2d;
                svsync_decoder_3d    <= svsync_decoder_2d;
                svcnt_decoder_3d     <= svcnt_decoder_2d;
                shcnt_decoder_3d     <= shcnt_decoder_2d;
                sdata_decoder_3d     <= sdata_decoder_2d;
                sdata_decoder_4d     <= sdata_decoder_3d;
            end if;
        end if;
    end process;

    u_defect : if (GEN_ILA_defect_proc = "ON") generate
        COMPONENT ila_defect
            PORT (
                clk    : IN STD_LOGIC;
                probe0 : IN STD_LOGIC;                    --_VECTOR(0 DOWNTO 0);
                probe1 : IN STD_LOGIC;                    --_VECTOR(0 DOWNTO 0);
                probe2 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                probe3 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                probe4 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
                probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
                probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
                probe7 : IN STD_LOGIC                     --_VECTOR(0 DOWNTO 0);
            );
        END COMPONENT;
    begin
        u_ila_defect : ila_defect
        PORT MAP (
            clk    => idata_clk,     -- 1
            probe0 => same,          -- 1
            probe1 => shsync_2x2,    -- 1
            probe2 => svcnt_2x2,     -- 12
            probe3 => shcnt_2x2,     -- 12
            probe4 => sdefect_addr,  -- 12
            probe5 => sdefect_rdata, -- 32
            probe6 => snext_rdata,   -- 32
            probe7 => sdefect_wen    -- 1
        );
    end generate;

end Behavioral;

--# unused signals (moved from architecture declarations)
--# signal shsync_decoder_1d : std_logic;
--# signal svsync_decoder_1d : std_logic;
--# signal shsync_decoder_2d : std_logic;
--# signal svsync_decoder_2d : std_logic;
--# NOTE: shsync_decoder_Xd / svsync_decoder_Xd are declared but only
--#       written, never read. Kept in architecture for now as pipeline
--#       placeholders matching the shcnt/svcnt/sdata delay chain.

--# unused component (duplicate declaration removed from architecture)
--# COMPONENT ila_defect
--# PORT (
--#     clk    : IN STD_LOGIC;
--#     probe0 : IN STD_LOGIC;
--#     probe1 : IN STD_LOGIC;
--#     probe2 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
--#     probe3 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
--#     probe4 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
--#     probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--#     probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--#     probe7 : IN STD_LOGIC
--# );
--# END COMPONENT;
