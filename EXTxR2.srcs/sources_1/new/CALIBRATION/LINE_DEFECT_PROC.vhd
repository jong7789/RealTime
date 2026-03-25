library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity LINE_DEFECT_PROC is
generic (
    MODE : string
);
port (
    idata_clk          : in  std_logic;
    idata_rstn         : in  std_logic;

    ireg_debug_mode    : in  std_logic;
    ireg_defect_map    : in  std_logic;

    ireg_ldefect_mode  : in  std_logic;
    ireg_ldefect_wen   : in  std_logic;
    ireg_ldefect_addr  : in  std_logic_vector(3 downto 0);
    ireg_ldefect_wdata : in  std_logic_vector(15 downto 0); -- Line Enable NEWS 210817mbh
    oreg_ldefect_rdata : out std_logic_vector(15 downto 0);

    ireg_width         : in  std_logic_vector(11 downto 0);
    ireg_height        : in  std_logic_vector(11 downto 0);

    ihsync             : in  std_logic;
    ivsync             : in  std_logic;
    ihcnt              : in  std_logic_vector(11 downto 0);
    ivcnt              : in  std_logic_vector(11 downto 0);
    idata              : in  std_logic_vector(15 downto 0);

    ohsync             : out std_logic;
    ovsync             : out std_logic;
    ohcnt              : out std_logic_vector(11 downto 0);
    ovcnt              : out std_logic_vector(11 downto 0);
    odata              : out std_logic_vector(15 downto 0)
);
end LINE_DEFECT_PROC;

architecture Behavioral of LINE_DEFECT_PROC is

    component MASK_OUT
    port (
        idata_clk  : in  std_logic;
        idata_rstn : in  std_logic;

        ireg_width  : in  std_logic_vector(11 downto 0);
        ireg_height : in  std_logic_vector(11 downto 0);

        ihsync : in  std_logic;
        ivsync : in  std_logic;
        ivcnt  : in  std_logic_vector(11 downto 0);
        ihcnt  : in  std_logic_vector(11 downto 0);
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

    component RAM_12x16
    port (
        clk : in  std_logic;
        a   : in  std_logic_vector(3 downto 0);
        d   : in  std_logic_vector(11 downto 0);
        we  : in  std_logic;
        spo : out std_logic_vector(11 downto 0)
    );
    end component;

    COMPONENT DUALRAM_12x16
    PORT (
        a    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        d    : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        dpra : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        clk  : IN STD_LOGIC;
        we   : IN STD_LOGIC;
        spo  : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
        dpo  : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
    );
    END COMPONENT;

    COMPONENT DUALRAM_16x16
    PORT (
        a    : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        d    : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        dpra : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        clk  : IN STD_LOGIC;
        we   : IN STD_LOGIC;
        spo  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dpo  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;

    signal sdefect_wen           : std_logic;
    signal sdefect_addr          : std_logic_vector(3 downto 0);
    signal vdefect_addr          : std_logic_vector(3 downto 0); -- mbh 210215
    signal sdefect_wdata         : std_logic_vector(15 downto 0);
    signal sdefect_rdata         : std_logic_vector(15 downto 0);

    signal swidth                : std_logic_vector(11 downto 0);
    signal sheight               : std_logic_vector(11 downto 0);
    signal sdebug_mode           : std_logic;
    signal sdefect_map           : std_logic;
    signal sldefect_mode         : std_logic;

    signal shsync_1x1            : std_logic;
    signal shsync_1x2            : std_logic;
    signal shsync_2x2            : std_logic;
    signal svsync_1x1            : std_logic;
    signal svsync_1x2            : std_logic;
    signal svsync_2x2            : std_logic;
    signal shcnt_1x1             : std_logic_vector(11 downto 0);
    signal shcnt_1x2             : std_logic_vector(11 downto 0);
    signal shcnt_2x2             : std_logic_vector(11 downto 0);
    signal svcnt_1x1             : std_logic_vector(11 downto 0);
    signal svcnt_1x2             : std_logic_vector(11 downto 0);
    signal svcnt_2x2             : std_logic_vector(11 downto 0);
    signal sdata_1x1             : std_logic_vector(15 downto 0);
    signal sdata_1x2             : std_logic_vector(15 downto 0);
    signal sdata_1x3             : std_logic_vector(15 downto 0);
    signal sdata_2x2             : std_logic_vector(15 downto 0);
    signal sdata_3x2             : std_logic_vector(15 downto 0);

    signal shsync                : std_logic;
    signal svsync                : std_logic;
    signal shcnt                 : std_logic_vector(11 downto 0);
    signal svcnt                 : std_logic_vector(11 downto 0);
    signal sdata                 : std_logic_vector(15 downto 0);
    signal srow_sum              : std_logic_vector(16 downto 0);
    signal scol_sum              : std_logic_vector(16 downto 0);

    signal shsync_defect         : std_logic;
    signal svsync_defect         : std_logic;
    signal shcnt_defect          : std_logic_vector(11 downto 0);
    signal svcnt_defect          : std_logic_vector(11 downto 0);
    signal sdata_defect          : std_logic_vector(15 downto 0);

    signal shsync_out            : std_logic;
    signal svsync_out            : std_logic;
    signal shcnt_out             : std_logic_vector(11 downto 0);
    signal svcnt_out             : std_logic_vector(11 downto 0);
    signal sdata_out             : std_logic_vector(15 downto 0);

    signal shsync_1d             : std_logic;
    signal sdata_1d              : std_logic_vector(15 downto 0);
    signal sreg_debug_mode       : std_logic;
    signal sreg_debug_mode_1d    : std_logic;
    signal sreg_debug_mode_2d    : std_logic;
    signal sreg_debug_mode_3d    : std_logic;
    signal sreg_defect_map       : std_logic;
    signal sreg_defect_map_1d    : std_logic;
    signal sreg_defect_map_2d    : std_logic;
    signal sreg_defect_map_3d    : std_logic;
    signal sreg_ldefect_mode     : std_logic;
    signal sreg_ldefect_mode_1d  : std_logic;
    signal sreg_ldefect_mode_2d  : std_logic;
    signal sreg_ldefect_mode_3d  : std_logic;
    signal sreg_ldefect_wen      : std_logic;
    signal sreg_ldefect_wen_1d   : std_logic;
    signal sreg_ldefect_wen_2d   : std_logic;
    signal sreg_ldefect_wen_3d   : std_logic;
    signal sreg_ldefect_addr     : std_logic_vector(3 downto 0);
    signal sreg_ldefect_addr_1d  : std_logic_vector(3 downto 0);
    signal sreg_ldefect_addr_2d  : std_logic_vector(3 downto 0);
    signal sreg_ldefect_addr_3d  : std_logic_vector(3 downto 0);
    signal sreg_ldefect_wdata    : std_logic_vector(15 downto 0);
    signal sreg_ldefect_wdata_1d : std_logic_vector(15 downto 0);
    signal sreg_ldefect_wdata_2d : std_logic_vector(15 downto 0);
    signal sreg_ldefect_wdata_3d : std_logic_vector(15 downto 0);
    signal sreg_width            : std_logic_vector(11 downto 0);
    signal sreg_width_1d         : std_logic_vector(11 downto 0);
    signal sreg_width_2d         : std_logic_vector(11 downto 0);
    signal sreg_width_3d         : std_logic_vector(11 downto 0);
    signal sreg_height           : std_logic_vector(11 downto 0);
    signal sreg_height_1d        : std_logic_vector(11 downto 0);
    signal sreg_height_2d        : std_logic_vector(11 downto 0);
    signal sreg_height_3d        : std_logic_vector(11 downto 0);

begin

    ROW_GEN : if(MODE = "ROW") generate
    begin
        U0_MASK_OUT : MASK_OUT
        port map (
            idata_clk  => idata_clk,
            idata_rstn => idata_rstn,

            ireg_width  => ireg_width,
            ireg_height => ireg_height,

            ihsync => ihsync,
            ivsync => ivsync,
            ihcnt  => ihcnt,
            ivcnt  => ivcnt,
            idata  => idata,

            ohsync_2x2 => shsync_2x2,
            ovsync_2x2 => svsync_2x2,
            ohcnt_2x2  => shcnt_2x2,
            ovcnt_2x2  => svcnt_2x2,

            odata_1x1 => open,
            odata_1x2 => sdata_1x2,
            odata_1x3 => open,
            odata_2x1 => open,
            odata_2x2 => sdata_2x2,
            odata_2x3 => open,
            odata_3x1 => open,
            odata_3x2 => sdata_3x2,
            odata_3x3 => open
        );

        shsync   <= shsync_2x2;
        svsync   <= svsync_2x2;
        shcnt    <= shcnt_2x2;
        svcnt    <= svcnt_2x2;
        sdata    <= sdata_2x2;
        srow_sum <= ('0' & sdata_1x2) + ('0' & sdata_3x2);

    end generate;

    COL_GEN : if(MODE = "COL") generate
    begin

        shsync_1x1 <= ihsync;
        svsync_1x1 <= ivsync;
        shcnt_1x1  <= ihcnt;
        svcnt_1x1  <= ivcnt;
        sdata_1x1  <= idata;

        --# 1-clock delay for column data pipeline
        process(idata_clk)
        begin
            if(idata_clk'event and idata_clk = '1') then
                if(idata_rstn = '0') then
                    shsync_1x2 <= '0';
                    svsync_1x2 <= '0';
                    shcnt_1x2  <= (others => '0');
                    svcnt_1x2  <= (others => '0');
                    sdata_1x2  <= (others => '0');
                    sdata_1x3  <= (others => '0');
                else
                    shsync_1x2 <= ihsync;
                    svsync_1x2 <= ivsync;
                    shcnt_1x2  <= ihcnt;
                    svcnt_1x2  <= ivcnt;
                    sdata_1x2  <= sdata_1x1;
                    sdata_1x3  <= sdata_1x2;
                end if;
            end if;
        end process;

        shsync  <= shsync_1x2;
        svsync  <= svsync_1x2;
        shcnt   <= shcnt_1x2;
        svcnt   <= svcnt_1x2;
        sdata   <= sdata_1x2;
        scol_sum <= ('0' & sdata_1x1) + ('0' & sdata_1x3);

    end generate;

--  U0_RAM_12x16 : RAM_12x16
--  port map(
--      clk         => idata_clk,
--      a           => sdefect_addr,
--      d           => sdefect_wdata,
--      we          => sdefect_wen,
--      spo         => sdefect_rdata
--  );
    U1_DUALRAM_16x16 : DUALRAM_16x16
    PORT MAP (
        clk  => idata_clk,
        we   => sdefect_wen,
        a    => sdefect_addr,
        d    => sdefect_wdata,
        spo  => oreg_ldefect_rdata,
        dpra => vdefect_addr,
        dpo  => sdefect_rdata
    );
    -- oreg_ldefect_rdata      <= sdefect_rdata;

    --# defect address control and write logic
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                sdefect_wen   <= '0';
                sdefect_addr  <= (others => '0');
                sdefect_wdata <= (others => '0');
            else
                sdefect_wen   <= sreg_ldefect_wen_3d;
                sdefect_addr  <= sreg_ldefect_addr_3d;
                sdefect_wdata <= sreg_ldefect_wdata_3d;

--              if(sdefect_wen = '0' and sdebug_mode = '0') then
                if( (MODE = "ROW" and svsync = '0') or
                    (MODE = "COL" and shsync = '0')) then
                    -- sdefect_addr    <= x"0";
                    vdefect_addr <= x"0";
                else
                    if( (MODE = "ROW" and svcnt = sdefect_rdata(12 - 1 downto 0) and shcnt = swidth - 1) or
                        (MODE = "COL" and shcnt = sdefect_rdata(12 - 1 downto 0) and shsync = '1')) then
                        -- sdefect_addr    <= sdefect_addr + '1';
                        vdefect_addr <= vdefect_addr + '1';
                    end if;
                end if;
--              else
--                  sdefect_addr        <= sreg_ldefect_addr_3d;
--                  sdefect_wdata       <= sreg_ldefect_wdata_3d;
--              end if;
            end if;
        end if;
    end process;

    --# line defect correction - replace defective line data with neighbor average
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                shsync_defect <= '0';
                svsync_defect <= '0';
                shcnt_defect  <= (others => '0');
                svcnt_defect  <= (others => '0');
                sdata_defect  <= (others => '0');
            else
                shsync_defect <= shsync;
                svsync_defect <= svsync;
                shcnt_defect  <= shcnt;
                svcnt_defect  <= svcnt;

                if(shsync = '1') then
                    if(sdefect_map = '0') then
                        if(MODE = "ROW") then
                            if(svcnt = sdefect_rdata(12 - 1 downto 0)) then
                                if(svcnt = 0) then
                                    sdata_defect <= sdata_3x2;
                                elsif(svcnt = sheight - 1) then
                                    sdata_defect <= sdata_1x2;
                                elsif(sdefect_rdata(12) = '1') then -- use south
                                    sdata_defect <= sdata_3x2;
                                elsif(sdefect_rdata(15) = '1') then -- use north
                                    sdata_defect <= sdata_1x2;
                                else
                                    sdata_defect <= srow_sum(16 downto 1);
                                end if;
                            else
                                sdata_defect <= sdata_2x2;
                            end if;
                        else
                            if(shcnt = sdefect_rdata(12 - 1 downto 0)) then
                                if(shcnt = 0) then
                                    sdata_defect <= sdata_1x3;
                                elsif(shcnt = swidth - 1) then
                                    sdata_defect <= sdata_1x1;
                                elsif(sdefect_rdata(13) = '1') then -- use west
                                    sdata_defect <= sdata_1x3;
                                elsif(sdefect_rdata(14) = '1') then -- use east
                                    sdata_defect <= sdata_1x1;
                                else
                                    sdata_defect <= scol_sum(16 downto 1);
                                end if;
                            else
                                sdata_defect <= sdata_1x2;
                            end if;
                        end if;
                    else
                        if(MODE = "ROW") then
                            if(svcnt = sdefect_rdata(12 - 1 downto 0)) then
                                sdata_defect <= x"FFFF";
                            else
                                if(sdata_2x2 = x"FFFF") then
                                    sdata_defect <= x"FFFF";
                                else
                                    sdata_defect <= (others => '0');
                                end if;
                            end if;
                        else
                            if(shcnt = sdefect_rdata(12 - 1 downto 0)) then
                                sdata_defect <= x"FFFF";
                            else
                                if(sdata_1x2 = x"FFFF") then
                                    sdata_defect <= x"FFFF";
                                else
                                    sdata_defect <= (others => '0');
                                end if;
                            end if;
                        end if;
                    end if;
                else
                    sdata_defect <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --# output mux - select between defect-corrected and original data
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
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

                if(sdefect_map = '0') then
                    if(sldefect_mode = '1') then
                        sdata_out <= sdata_defect;
                    else
                        sdata_out <= sdata_1d;
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

    --# latch register parameters on vsync boundary
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                sdebug_mode   <= '0';
                sdefect_map   <= '0';
                sldefect_mode <= '0';
                swidth        <= (others => '0');
                sheight       <= (others => '0');
            else
                sdebug_mode <= sreg_debug_mode_3d;

                if(svsync_out = '0') then
                    sdefect_map   <= sreg_defect_map_3d;
                    sldefect_mode <= sreg_ldefect_mode_3d;
                    swidth        <= sreg_width_3d;
                    sheight       <= sreg_height_3d;
                end if;
            end if;
        end if;
    end process;

    --# 3-stage synchronizer for all register inputs
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                shsync_1d              <= '0';
                sdata_1d               <= (others => '0');

                sreg_debug_mode        <= '0';
                sreg_debug_mode_1d     <= '0';
                sreg_debug_mode_2d     <= '0';
                sreg_debug_mode_3d     <= '0';
                sreg_ldefect_mode      <= '0';
                sreg_ldefect_mode_1d   <= '0';
                sreg_ldefect_mode_2d   <= '0';
                sreg_ldefect_mode_3d   <= '0';
                sreg_defect_map        <= '0';
                sreg_defect_map_1d     <= '0';
                sreg_defect_map_2d     <= '0';
                sreg_defect_map_3d     <= '0';
                sreg_ldefect_wen       <= '0';
                sreg_ldefect_wen_1d    <= '0';
                sreg_ldefect_wen_2d    <= '0';
                sreg_ldefect_wen_3d    <= '0';
                sreg_ldefect_addr      <= (others => '0');
                sreg_ldefect_addr_1d   <= (others => '0');
                sreg_ldefect_addr_2d   <= (others => '0');
                sreg_ldefect_addr_3d   <= (others => '0');
                sreg_ldefect_wdata     <= (others => '0');
                sreg_ldefect_wdata_1d  <= (others => '0');
                sreg_ldefect_wdata_2d  <= (others => '0');
                sreg_ldefect_wdata_3d  <= (others => '0');

                sreg_width             <= (others => '0');
                sreg_width_1d          <= (others => '0');
                sreg_width_2d          <= (others => '0');
                sreg_width_3d          <= (others => '0');
                sreg_height            <= (others => '0');
                sreg_height_1d         <= (others => '0');
                sreg_height_2d         <= (others => '0');
                sreg_height_3d         <= (others => '0');
            else
                shsync_1d              <= shsync;
                sdata_1d               <= sdata;

                sreg_debug_mode        <= ireg_debug_mode;
                sreg_debug_mode_1d     <= sreg_debug_mode;
                sreg_debug_mode_2d     <= sreg_debug_mode_1d;
                sreg_debug_mode_3d     <= sreg_debug_mode_2d;
                sreg_defect_map        <= ireg_defect_map;
                sreg_defect_map_1d     <= sreg_defect_map;
                sreg_defect_map_2d     <= sreg_defect_map_1d;
                sreg_defect_map_3d     <= sreg_defect_map_2d;
                sreg_ldefect_mode      <= ireg_ldefect_mode;
                sreg_ldefect_mode_1d   <= sreg_ldefect_mode;
                sreg_ldefect_mode_2d   <= sreg_ldefect_mode_1d;
                sreg_ldefect_mode_3d   <= sreg_ldefect_mode_2d;
                sreg_ldefect_wen       <= ireg_ldefect_wen;
                sreg_ldefect_wen_1d    <= sreg_ldefect_wen;
                sreg_ldefect_wen_2d    <= sreg_ldefect_wen_1d;
                sreg_ldefect_wen_3d    <= sreg_ldefect_wen_2d;
                sreg_ldefect_addr      <= ireg_ldefect_addr;
                sreg_ldefect_addr_1d   <= sreg_ldefect_addr;
                sreg_ldefect_addr_2d   <= sreg_ldefect_addr_1d;
                sreg_ldefect_addr_3d   <= sreg_ldefect_addr_2d;
                sreg_ldefect_wdata     <= ireg_ldefect_wdata;
                sreg_ldefect_wdata_1d  <= sreg_ldefect_wdata;
                sreg_ldefect_wdata_2d  <= sreg_ldefect_wdata_1d;
                sreg_ldefect_wdata_3d  <= sreg_ldefect_wdata_2d;

                sreg_width             <= ireg_width;
                sreg_width_1d          <= sreg_width;
                sreg_width_2d          <= sreg_width_1d;
                sreg_width_3d          <= sreg_width_2d;
                sreg_height            <= ireg_height;
                sreg_height_1d         <= sreg_height;
                sreg_height_2d         <= sreg_height_1d;
                sreg_height_3d         <= sreg_height_2d;
            end if;
        end if;
    end process;

u_defline : if(GEN_ILA_defectline_proc = "ON") generate
    COMPONENT ila_line_defect
    PORT (
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe3  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        probe4  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe5  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        probe6  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe7  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe8  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe9  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe10 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;
begin
    u_ila_line_defect : ila_line_defect
    PORT MAP (
        clk       => idata_clk,
        probe0(0) => sldefect_mode, -- 1
        probe1(0) => sdefect_map,   -- 1
        probe2(0) => sdefect_wen,   -- 1
        probe3    => sdefect_addr,  -- 4
        probe4    => sdefect_wdata, -- 16
        probe5    => vdefect_addr,  -- 4
        probe6    => sdefect_rdata, -- 16
        probe7    => sdata_defect,  -- 16
        probe8    => svcnt,         -- 12
        probe9    => shcnt,         -- 12
        probe10   => sdata_out      -- 16
    );
end generate;

end Behavioral;
