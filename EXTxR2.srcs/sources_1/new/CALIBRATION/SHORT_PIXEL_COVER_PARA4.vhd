--$ 2607241407 SHORT_PIXEL_COVER_PARA4: hide short-pixel image error between AVG and TPC
--$ 2607241701 pixel-level detection + dark-run tolerance (fix 4-px word-boundary straddle)
-- Purpose : A "short pixel" shows up as an isolated dark dip inside a fully
--           saturated region. This block scans a flat horizontal pixel window and,
--           per pixel, replaces a dark pixel that has saturation within MAXRUN on
--           BOTH sides (dark run in between allowed) so the artifact is hidden
--           before gain/offset calibration.
-- Why     : Word-granular detection failed when the defect straddles a 4-px word
--           boundary (each neighbor word then holds part of the defect). Pixel-
--           level detection is alignment-agnostic and per-pixel replace avoids
--           over-covering whole words.
-- Where   : CALIB_TOP_PARA4, live data path between AVG_PROC and TPC_PROC.
-- Note    : Fixed latency = SPC_LAT (input->output). CALIB_TOP_PARA4 MUST delay
--           the DDR gain/offset streams by the same SPC_LAT to keep pixel/coeff
--           alignment into TPC (constant regardless of enable).

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity SHORT_PIXEL_COVER_PARA4 is
    port (
        idata_clk  : in std_logic;
        idata_rstn : in std_logic;

        --* control (0x04A8) : [0]en [7:4]dark_thres [11:8]restore [15:12]satref
        ireg_spc_ctrl : in std_logic_vector(16 - 1 downto 0);

        --* FROM. AVG stream (gated live data)
        ihsync : in  std_logic;
        ivsync : in  std_logic;
        ivcnt  : in  std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit
        ihcnt  : in  std_logic_vector(12 - 1 downto 0);
        idata  : in  std_logic_vector(64 - 1 downto 0);

        --* TO. TPC_PROC
        ohsync : out std_logic;
        ovsync : out std_logic;
        ovcnt  : out std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit
        ohcnt  : out std_logic_vector(12 - 1 downto 0);
        odata  : out std_logic_vector(64 - 1 downto 0)
    );
end entity SHORT_PIXEL_COVER_PARA4;

architecture behavioral of SHORT_PIXEL_COVER_PARA4 is

    --$ 2607241407 SPC pipeline latency (in->out). MUST match coeff delay in CALIB_TOP_PARA4.
    constant SPC_LAT : integer := 4;

    constant PARA : integer := 4;  --# 4 pixels per 64-bit word
    constant TAPS : integer := 5;  --# window t0(new) t1 t2(center) t3 t4(old)
    constant CENT : integer := 2;  --# center tap index (current pixel)

    --$ 2607241701 pixel-level detection with dark-run tolerance (fix word-boundary straddle)
    constant MAXRUN : integer := 4; --# max short-defect width tolerated per side
    constant NPX    : integer := PARA * TAPS;       --# 20 flat pixels (left->right)
    constant CBASE  : integer := PARA * CENT;       --# center word first pixel index (=8)
    type ty_px is array (0 to NPX - 1) of std_logic_vector(16 - 1 downto 0);

    type ty_tap_1b  is array (0 to TAPS - 1) of std_logic;
    type ty_tap_12b is array (0 to TAPS - 1) of std_logic_vector(12 - 1 downto 0);
    type ty_tap_13b is array (0 to TAPS - 1) of std_logic_vector(13 - 1 downto 0);
    type ty_tap_64b is array (0 to TAPS - 1) of std_logic_vector(64 - 1 downto 0);

    signal shsync_tap : ty_tap_1b  := (others => '0');
    signal svsync_tap : ty_tap_1b  := (others => '0');
    signal shcnt_tap  : ty_tap_12b := (others => (others => '0'));
    signal svcnt_tap  : ty_tap_13b := (others => (others => '0'));
    signal sdata_tap  : ty_tap_64b := (others => (others => '0'));

    --$ 2607241701 flat horizontal pixel view over the 5-tap window (left=old .. right=new)
    signal px : ty_px;

    -- ### decoded control (idata_clk domain) ###
    signal sspc_en   : std_logic := '0';
    signal sthres    : std_logic_vector(16 - 1 downto 0) := (others => '0'); --# dark threshold
    signal srestore  : std_logic_vector(16 - 1 downto 0) := (others => '0'); --# replace value
    signal ssatref   : std_logic_vector(16 - 1 downto 0) := (others => '0'); --# neighbor saturation ref

    -- ### output regs ###
    signal shsync_o : std_logic := '0';
    signal svsync_o : std_logic := '0';
    signal shcnt_o  : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal svcnt_o  : std_logic_vector(13 - 1 downto 0) := (others => '0');
    signal sdata_o  : std_logic_vector(64 - 1 downto 0) := (others => '0');

begin

    --$ 2607241407 control field decode (value select from 4-bit enum index)
    process (idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            sspc_en <= ireg_spc_ctrl(0);

            case ireg_spc_ctrl(7 downto 4) is                 --# dark threshold
                when x"0"   => sthres <= conv_std_logic_vector(1,    16);
                when x"1"   => sthres <= conv_std_logic_vector(128,  16);
                when x"2"   => sthres <= conv_std_logic_vector(256,  16);
                when x"3"   => sthres <= conv_std_logic_vector(512,  16);
                when x"4"   => sthres <= conv_std_logic_vector(1024, 16);
                when others => sthres <= conv_std_logic_vector(512,  16);
            end case;

            case ireg_spc_ctrl(11 downto 8) is                --# restore value
                when x"0"   => srestore <= x"FFFF";                          -- 65535
                when x"1"   => srestore <= x"FFFE";                          -- 65534
                when x"2"   => srestore <= x"FFFA";                          -- 65530
                when x"3"   => srestore <= conv_std_logic_vector(60000, 16); -- 60000
                when others => srestore <= x"FFFF";
            end case;

            case ireg_spc_ctrl(15 downto 12) is               --# neighbor saturation ref
                when x"0"   => ssatref <= x"FFFF";                          -- 65535
                when x"1"   => ssatref <= x"FFFE";                          -- 65534
                when x"2"   => ssatref <= x"FFFA";                          -- 65530
                when x"3"   => ssatref <= conv_std_logic_vector(60000, 16); -- 60000
                when others => ssatref <= x"FFFF";
            end case;
        end if;
    end process;

    --$ 2607241407 5-tap centered window shift (t0=newest .. t4=oldest, center=t2)
    process (idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            shsync_tap(0) <= ihsync;
            svsync_tap(0) <= ivsync;
            shcnt_tap(0)  <= ihcnt;
            svcnt_tap(0)  <= ivcnt;
            sdata_tap(0)  <= idata;
            for i in 1 to TAPS - 1 loop
                shsync_tap(i) <= shsync_tap(i - 1);
                svsync_tap(i) <= svsync_tap(i - 1);
                shcnt_tap(i)  <= shcnt_tap(i - 1);
                svcnt_tap(i)  <= svcnt_tap(i - 1);
                sdata_tap(i)  <= sdata_tap(i - 1);
            end loop;
        end if;
    end process;

    --$ 2607241701 flat pixel map: px(0)=leftmost(oldest word) .. px(NPX-1)=rightmost(newest)
    GEN_PX_W : for w in 0 to TAPS - 1 generate
        GEN_PX_P : for p in 0 to PARA - 1 generate
            px(w * PARA + p) <= sdata_tap(TAPS - 1 - w)(16 * (p + 1) - 1 downto 16 * p);
        end generate;
    end generate;

    --$ 2607241701 per-pixel cover with dark-run tolerance (alignment-agnostic; fixes word-boundary straddle)
    -- dark(c)    : center pixel < dark threshold
    -- left_ok(c) : within MAXRUN pixels to the left a saturated pixel (>=satref) is
    --              reached, with only dark(<thres) pixels in between (the defect run)
    -- right_ok(c): symmetric to the right
    -- cover(c)   : en and dark and left_ok and right_ok  -> replace that pixel only
    -- boundary   : detection is pixel-level so it works regardless of 4-px word phase
    process (idata_clk)
        variable l_ok, r_ok, run_ok : std_logic;
        variable c : integer;
    begin
        if (idata_clk'event and idata_clk = '1') then
            -- sync/cnt travel with the center tap
            shsync_o <= shsync_tap(CENT);
            svsync_o <= svsync_tap(CENT);
            shcnt_o  <= shcnt_tap(CENT);
            svcnt_o  <= svcnt_tap(CENT);

            for k in 0 to PARA - 1 loop
                c := CBASE + k;

                -- left : saturation within MAXRUN, only dark pixels in the run
                l_ok := '0';
                for d in 1 to MAXRUN loop
                    run_ok := '1';
                    for e in 1 to d - 1 loop
                        if (px(c - e) >= sthres) then   -- intermediate not dark -> run broken
                            run_ok := '0';
                        end if;
                    end loop;
                    if (run_ok = '1' and px(c - d) >= ssatref) then
                        l_ok := '1';
                    end if;
                end loop;

                -- right : symmetric
                r_ok := '0';
                for d in 1 to MAXRUN loop
                    run_ok := '1';
                    for e in 1 to d - 1 loop
                        if (px(c + e) >= sthres) then
                            run_ok := '0';
                        end if;
                    end loop;
                    if (run_ok = '1' and px(c + d) >= ssatref) then
                        r_ok := '1';
                    end if;
                end loop;

                if (sspc_en = '1' and px(c) < sthres and l_ok = '1' and r_ok = '1') then
                    sdata_o(16 * (k + 1) - 1 downto 16 * k) <= srestore; --# per-pixel replace
                else
                    sdata_o(16 * (k + 1) - 1 downto 16 * k) <= px(c);    --# passthrough (center tap)
                end if;
            end loop;
        end if;
    end process;

    ohsync <= shsync_o;
    ovsync <= svsync_o;
    ohcnt  <= shcnt_o;
    ovcnt  <= svcnt_o;
    odata  <= sdata_o;

end architecture behavioral;
