library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity MASK_PARA4 is
port (
    clk          : in  std_logic;
    rstn         : in  std_logic;

    i_reg_width  : in  std_logic_vector(12 - 1 downto 0);
    i_reg_height : in  std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit

    i_hsyn       : in  std_logic;
    i_vsyn       : in  std_logic;
    i_vcnt       : in  std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit
    i_hcnt       : in  std_logic_vector(12 - 1 downto 0);
    i_data       : in  std_logic_vector(64 - 1 downto 0);

    o_hsyn_2x2   : out std_logic;
    o_vsyn_2x2   : out std_logic;
    o_hcnt_2x2   : out std_logic_vector(12 - 1 downto 0);
    o_vcnt_2x2   : out std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit

    o_data_1x1   : out std_logic_vector(64 - 1 downto 0);
    o_data_1x2   : out std_logic_vector(64 - 1 downto 0);
    o_data_1x3   : out std_logic_vector(64 - 1 downto 0);
    o_data_2x1   : out std_logic_vector(64 - 1 downto 0);
    o_data_2x2   : out std_logic_vector(64 - 1 downto 0);
    o_data_2x3   : out std_logic_vector(64 - 1 downto 0);
    o_data_3x1   : out std_logic_vector(64 - 1 downto 0);
    o_data_3x2   : out std_logic_vector(64 - 1 downto 0);
    o_data_3x3   : out std_logic_vector(64 - 1 downto 0)
);
end MASK_PARA4;

architecture Behavioral of MASK_PARA4 is

    COMPONENT mmr_64x1024
    PORT (
        clka  : IN  STD_LOGIC;
        wea   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        dina  : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        clkb  : IN  STD_LOGIC;
        web   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
        dinb  : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
    END COMPONENT;

    constant SHF_REG_NUM : integer := 3;

    type ty_reg_shf12b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    type ty_reg_shf13b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit
    signal shf_reg_width : ty_reg_shf12b;
    signal shf_reg_heigh : ty_reg_shf13b; --# 2604231608 Expand V-axis 12->13bit

    constant SHF_VID_NUM : integer := 8;

    signal shf_vsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_hsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');

    type ty_vid_shf12b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
    type ty_vid_shf13b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit
    signal shf_vcnt : ty_vid_shf13b; --# 2604231608 Expand V-axis 12->13bit
    signal shf_hcnt : ty_vid_shf12b;

    type ty_vid_shf64b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(64 - 1 downto 0);
    signal shf_data : ty_vid_shf64b;
    signal shf_rdd0 : ty_vid_shf64b;
    signal shf_rdd1 : ty_vid_shf64b;

    signal shf_gvsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_ghsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_gvcnt : ty_vid_shf13b; --# 2604231608 Expand V-axis 12->13bit
    signal shf_ghcnt : ty_vid_shf12b;

    signal width     : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal heigh     : std_logic_vector(13 - 1 downto 0) := (others => '0'); --# 2604231608 Expand V-axis 12->13bit
    signal hcnt      : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal vcnt      : std_logic_vector(13 - 1 downto 0) := (others => '0'); --# 2604231608 Expand V-axis 12->13bit
    signal gen_hsyn  : std_logic;
    signal gen_hsyn0 : std_logic;
    signal gen_vsyn  : std_logic;
    signal gen_hcnt  : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal gen_vcnt  : std_logic_vector(13 - 1 downto 0) := (others => '0'); --# 2604231608 Expand V-axis 12->13bit

    signal wea0 : std_logic;
    signal wea1 : std_logic;

    signal rdline0  : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal rdline1  : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal rdline00 : std_logic_vector(64 - 1 downto 0) := (others => '0');
    signal rdline01 : std_logic_vector(64 - 1 downto 0) := (others => '0');

    type type_sm_gensync is (st_idle, st_start, st_line, st_line_end, st_frame_end, st_line_wait);
--    type type_sm_gensync is (st_idle, st_start, st_line, st_line_wait);
    signal state : type_sm_gensync;

    signal hsyn0 : std_logic;
    signal hsyn1 : std_logic;

    signal waitcnt : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal hsyn_2x2 : std_logic;
    signal vsyn_2x2 : std_logic;
    signal hcnt_2x2 : std_logic_vector(12 - 1 downto 0);
    signal vcnt_2x2 : std_logic_vector(13 - 1 downto 0); --# 2604231608 Expand V-axis 12->13bit

    signal data_1x1 : std_logic_vector(64 - 1 downto 0);
    signal data_1x2 : std_logic_vector(64 - 1 downto 0);
    signal data_1x3 : std_logic_vector(64 - 1 downto 0);
    signal data_2x1 : std_logic_vector(64 - 1 downto 0);
    signal data_2x2 : std_logic_vector(64 - 1 downto 0);
    signal data_2x3 : std_logic_vector(64 - 1 downto 0);
    signal data_3x1 : std_logic_vector(64 - 1 downto 0);
    signal data_3x2 : std_logic_vector(64 - 1 downto 0);
    signal data_3x3 : std_logic_vector(64 - 1 downto 0);

    signal blank_cnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal blank_num : std_logic_vector(16 - 1 downto 0) := (others => '0');

--# 2605201056 Frame extender: inject synthetic line scan during inter-frame blanking
--#            so addrb keeps scanning -> last output line not frozen
    signal inj_act   : std_logic := '0';
    signal inj_cnt   : std_logic_vector(12 - 1 downto 0) := (others => '0');
    signal w_max_loc : std_logic_vector(12 - 1 downto 0);
    signal i_hsyn_x  : std_logic;
    signal i_vsyn_x  : std_logic;
    signal i_hcnt_x  : std_logic_vector(12 - 1 downto 0);
    signal i_vcnt_x  : std_logic_vector(13 - 1 downto 0);
    signal i_data_x  : std_logic_vector(64 - 1 downto 0);
--# 2605201123 i_hsyn delayed for falling-edge detection (revised trigger)
    signal hsyn_d    : std_logic := '0';
--$ 2605271746 shf register of inj_act for wea gating (BRAM write disable during inject)
    signal shf_inj_act : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
--$ 2605280937 Flag: last line H-1 hsyn-high observed, awaiting its falling edge to fire injection
    signal last_line_active : std_logic := '0';
--$ 2605280937 Raw wea (un-gated by inj) for mux selection; gated version used for BRAM write
    signal wea0_raw : std_logic;
    signal wea1_raw : std_logic;
--$ 2605281013 Wait phase between inj_act fire and addr scan start (sync addrb to output FSM phase)
    signal inj_wait     : std_logic := '0';
    signal inj_wait_cnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
--$ 2605281121 Combinational early-exit: effective inj-active 1 cycle ahead of registered inj_act
    signal inj_active_now : std_logic;
    signal exit_cond_now  : std_logic;

    component ila_mask_para4
    port (
        clk     : in std_logic;
        probe0  : in std_logic;
        probe1  : in std_logic;
        probe2  : in std_logic_vector(11 downto 0);
        probe3  : in std_logic_vector(12 downto 0);
        probe4  : in std_logic_vector(63 downto 0);
        probe5  : in std_logic;
        probe6  : in std_logic;
        probe7  : in std_logic_vector(11 downto 0);
        probe8  : in std_logic_vector(12 downto 0);
        probe9  : in std_logic_vector(63 downto 0);
        probe10 : in std_logic;
        probe11 : in std_logic;
        probe12 : in std_logic_vector(11 downto 0);
        probe13 : in std_logic_vector(12 downto 0);
        probe14 : in std_logic_vector(63 downto 0);
        probe15 : in std_logic;
        probe16 : in std_logic;
        probe17 : in std_logic;
        probe18 : in std_logic_vector(11 downto 0);
        probe19 : in std_logic_vector(63 downto 0);
        probe20 : in std_logic_vector(63 downto 0);
        probe21 : in std_logic_vector(63 downto 0);
        probe22 : in std_logic_vector(63 downto 0);
        probe23 : in std_logic;
        probe24 : in std_logic_vector(11 downto 0)
    );
    end component;

begin

--    U0_ILA_MASK : ila_mask_para4
--    port map (
--        clk     => clk,
--        probe0  => i_hsyn,
--        probe1  => i_vsyn,
--        probe2  => i_hcnt,
--        probe3  => i_vcnt,
--        probe4  => i_data,
--        probe5  => shf_hsyn(0),
--        probe6  => shf_vsyn(0),
--        probe7  => shf_hcnt(0),
--        probe8  => shf_vcnt(0),
--        probe9  => shf_data(0),
--        probe10 => hsyn_2x2,
--        probe11 => vsyn_2x2,
--        probe12 => hcnt_2x2,
--        probe13 => vcnt_2x2,
--        probe14 => data_2x2,
--        probe15 => wea0,
--        probe16 => wea1,
--        probe17 => inj_act,
--        probe18 => inj_cnt,
--        probe19 => rdline0,
--        probe20 => rdline1,
--        probe21 => rdline00,
--        probe22 => rdline01,
--        probe23 => hsyn_d,
--        probe24 => i_hcnt_x
--    );

--# 2605201056 width max in para4 units (= i_reg_width/4 - 1)
    w_max_loc <= ("00" & i_reg_width(12 - 1 downto 2)) - 1;

--# 2605201056 Single-flag frame extender FSM
--# 2605201123 Trigger revised: use i_hsyn falling edge with i_vcnt = i_reg_height-1
--#            (0-indexed last line). Drop i_hcnt comparison to avoid off-by-one.
--#            ILA confirms: last input line i_vcnt = 4299 with i_reg_height = 4300.
--#            ext_vcnt fixed at i_reg_height -> wea targets buf opposite of
--#            line H-1's buf so the line H-1 data is preserved during injection.
    ext_fsm : process(clk)
    begin
        if (clk'event and clk = '1') then
            if (rstn = '0') then
                inj_act <= '0';
                inj_cnt <= (others => '0');
                hsyn_d  <= '0';
                --$ 2605280937 Clear last-line flag on reset
                last_line_active <= '0';
                --$ 2605281013 Clear injection wait phase signals on reset
                inj_wait     <= '0';
                inj_wait_cnt <= (others => '0');
            else
                hsyn_d <= i_hsyn;

                --$ 2605280937 Set flag on rising edge of line H-1 hsyn (i_vcnt = H-1 during last line)
                if hsyn_d = '0' and i_hsyn = '1' and i_vcnt = (i_reg_height - 1) then
                    last_line_active <= '1';
                end if;
                if inj_act = '0' then
                    --# enter on i_hsyn FALLING edge at last real line (0-indexed)
--                  if hsyn_d = '1' and i_hsyn = '0' and i_vcnt = (i_reg_height - 1) then
                    --$ 2605280849 Trigger at end of line H-1 (real last line): i_vcnt advances to i_reg_height on its hsyn fall
--                  if hsyn_d = '1' and i_hsyn = '0' and i_vcnt = i_reg_height then
                    --$ 2605280937 Trigger only on hsyn fall AFTER last_line_active was set (= line H-1 fall)
                    if hsyn_d = '1' and i_hsyn = '0' and last_line_active = '1' then
                        inj_act <= '1';
                        inj_cnt <= (others => '0');
                        last_line_active <= '0';
                        --$ 2605281013 Enter wait phase: hold inj_cnt at 0 until phantom-line blanking elapses
                        inj_wait     <= '1';
                        inj_wait_cnt <= (others => '0');
                    end if;
                else
                    --# exit when next frame begins (any line other than last)
--                  if i_hsyn = '1' and i_vcnt < (i_reg_height - 1) then
                    --$ 2605280849 Exit when next frame begins: any hsyn high with i_vcnt below new trigger threshold
--                  if i_hsyn = '1' and i_vcnt < i_reg_height then
                    --$ 2605280937 Revert to original (i_vcnt < H-1) since i_vcnt saturates at H-1
                    if i_hsyn = '1' and i_vcnt < (i_reg_height - 1) then
                        inj_act <= '0';
                        inj_cnt <= (others => '0');
                        last_line_active <= '0';
                        --$ 2605281013 Clear injection wait phase signals on exit
                        inj_wait     <= '0';
                        inj_wait_cnt <= (others => '0');
                    --$ 2605281013 Wait blank_num cycles so phantom line aligns with output FSM st_line phase
                    elsif inj_wait = '1' then
--                      if inj_wait_cnt = blank_num - 1 then
                        --$ 2605281049 Advance wait clear by 1 cycle: compensate shf_hsyn/mux/BRAM pipeline (fix first word of row 3071)
                        if inj_wait_cnt = blank_num - 2 then
                            inj_wait <= '0';
                        else
                            inj_wait_cnt <= inj_wait_cnt + '1';
                        end if;
                    elsif inj_cnt = w_max_loc then
                        inj_cnt <= (others => '0'); --# wrap; keep scanning
                    else
                        inj_cnt <= inj_cnt + '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

--$ 2605281121 Detect exit condition combinationally; mux/shf_inj_act use it instead of registered inj_act
    exit_cond_now  <= '1' when (i_hsyn = '1' and i_vcnt < (i_reg_height - 1)) else '0';
    inj_active_now <= inj_act and (not exit_cond_now);

--# 2605201056 Internal copies fed to shf_* shift registers and BRAM addrb only
--#            (state machine and blank_cnt keep using raw i_*)
--  i_hsyn_x <= '1'             when inj_act = '1' else i_hsyn;
    --$ 2605281013 Hold hsyn low during inj_wait to mirror real-frame blank period
--  i_hsyn_x <= '1' when (inj_act = '1' and inj_wait = '0') else i_hsyn;
    --$ 2605281121 Use inj_active_now (combinational early-exit) so muxes switch in time for line 0 word 0
    i_hsyn_x <= '1' when (inj_active_now = '1' and inj_wait = '0') else i_hsyn;
--  i_vsyn_x <= '1'             when inj_act = '1' else i_vsyn;
    --$ 2605281121 Use inj_active_now (combinational early-exit) so muxes switch in time for line 0 word 0
    i_vsyn_x <= '1'             when inj_active_now = '1' else i_vsyn;
--  i_hcnt_x <= inj_cnt         when inj_act = '1' else i_hcnt;
    --$ 2605281013 Mute hcnt during inj_wait so addrb stays at 0 during phantom blank
--  i_hcnt_x <= inj_cnt when (inj_act = '1' and inj_wait = '0') else i_hcnt;
    --$ 2605281121 Use inj_active_now (combinational early-exit) so muxes switch in time for line 0 word 0
    i_hcnt_x <= inj_cnt when (inj_active_now = '1' and inj_wait = '0') else i_hcnt;
--  i_vcnt_x <= i_reg_height    when inj_act = '1' else i_vcnt;
    --$ 2605281121 Use inj_active_now (combinational early-exit) so muxes switch in time for line 0 word 0
    i_vcnt_x <= i_reg_height    when inj_active_now = '1' else i_vcnt;
--  i_data_x <= (others => '0') when inj_act = '1' else i_data;
    --$ 2605281121 Use inj_active_now (combinational early-exit) so muxes switch in time for line 0 word 0
    i_data_x <= (others => '0') when inj_active_now = '1' else i_data;

-- ▀█ █░░ █ █▄░█ █▀▀   █▄▄ █░█ █▀▀
-- █▄ █▄▄ █ █░▀█ ██▄   █▄█ █▄█ █▀░ %2line buffer
--  wea0 <= (not shf_vcnt(0)(0)) and shf_hsyn(0);
--  wea1 <= (    shf_vcnt(0)(0)) and shf_hsyn(0);
--$ 2605271746 Disable BRAM write during injection so last 2 lines (BUF0/BUF1) preserved
--  wea0 <= (not shf_vcnt(0)(0)) and shf_hsyn(0) and (not shf_inj_act(0));
--  wea1 <= (    shf_vcnt(0)(0)) and shf_hsyn(0) and (not shf_inj_act(0));
    --$ 2605280937 Split raw/gated: raw drives mux (preserve LSB pattern), gated drives BRAM write
    wea0_raw <= (not shf_vcnt(0)(0)) and shf_hsyn(0);
    wea1_raw <= (    shf_vcnt(0)(0)) and shf_hsyn(0);
    wea0     <= wea0_raw and (not shf_inj_act(0));
    wea1     <= wea1_raw and (not shf_inj_act(0));
    u_linebuf0 : mmr_64x1024
    port map (
        clka   => clk,
        wea(0) => wea0,
        addra  => shf_hcnt(0)(10 - 1 downto 0),
        dina   => shf_data(0),
        douta  => OPEN,
        clkb   => clk,
        web(0) => '0',
--      addrb  => i_hcnt(10 - 1 downto 0),
--# 2605201056 scan via extender during inter-frame blanking (last line fix)
        addrb  => i_hcnt_x(10 - 1 downto 0),
        dinb   => (others => '0'),
        doutb  => rdline0
    );

    u_linebuf1 : mmr_64x1024
    port map (
        clka   => clk,
        wea(0) => wea1,
        addra  => shf_hcnt(0)(10 - 1 downto 0),
        dina   => shf_data(0),
        douta  => OPEN,
        clkb   => clk,
        web(0) => '0',
--      addrb  => i_hcnt(10 - 1 downto 0),
--# 2605201056 scan via extender during inter-frame blanking (last line fix)
        addrb  => i_hcnt_x(10 - 1 downto 0),
        dinb   => (others => '0'),
        doutb  => rdline1
    );

--  rdline00 <= rdline0 when wea0 = '1' else rdline1;
--  rdline01 <= rdline1 when wea0 = '1' else rdline0;
    --$ 2605280937 Mux on RAW wea so injection (gated wea=0) still routes correct buffer
    rdline00 <= rdline0 when wea0_raw = '1' else rdline1;
    rdline01 <= rdline1 when wea0_raw = '1' else rdline0;

    --$260128 integrate sm
    --# State machine for sync generation, blank counting, and gen_sync output
    process(clk)
    begin
        if (clk'event and clk = '1') then
            hsyn0 <= i_hsyn;
            hsyn1 <= hsyn0;

            --█▀ █▀▄▀█
            --▄█ █░▀░█ --$sm
            case (state) is
                when st_idle =>
                    if (i_vcnt = 1 and hsyn0 = '0' and i_hsyn = '1') then
                        state <= st_start;
                    end if;

                    gen_vsyn <= '0';
                    gen_hsyn <= '0';
                    vcnt     <= (others => '0');
                when st_start =>
                    if (hsyn1 = '0' and hsyn0 = '1') then
                        state <= st_line;
                    end if;

                    gen_vsyn <= '1';
                    gen_hsyn <= '1';
                when st_line =>
                    if (hcnt = width - 2) then
                        state <= st_line_end;
                    end if;

                    gen_hsyn <= '1';
                    hcnt     <= hcnt + '1';
                    waitcnt  <= (others => '0');
                when st_line_end =>
                    if (vcnt >= heigh - 1) then
                        state    <= st_frame_end;
                        gen_vsyn <= '0';
                    else
                        state <= st_line_wait;
                    end if;

                    gen_hsyn <= '0';
                    hcnt     <= (others => '0');
                    vcnt     <= vcnt + '1';
                when st_line_wait =>
                    if (waitcnt >= blank_num - 1) then
                        state    <= st_line;
                        gen_hsyn <= '1';
                    else
                        waitcnt  <= waitcnt + '1';
                        gen_hsyn <= '0';
                    end if;

                when st_frame_end =>
                    state <= st_idle;
            end case;

            -- █▀▀ █▀▀ █▄░█   █▀ █▄█ █▄░█ █▀▀
            -- █▄█ ██▄ █░▀█   ▄█ ░█░ █░▀█ █▄▄--$gen sync
            gen_hsyn0 <= gen_hsyn;

            if gen_hsyn = '1' then
                gen_hcnt <= gen_hcnt + '1';
            else
                gen_hcnt <= (others => '0');
            end if;

            if gen_vsyn = '0' then
                gen_vcnt <= (others => '0');
            elsif gen_hsyn0 = '1' and gen_hsyn = '0' then
                gen_vcnt <= gen_vcnt + '1';
            end if;

            -- █▄▄ █░░ █▄▀   █▀▀ █▄░█ ▀█▀
            -- █▄█ █▄▄ █░█   █▄▄ █░▀█ ░█░ %blank cnt
            if i_vsyn = '1' and i_hsyn = '0' then
                blank_cnt <= blank_cnt + '1';
            elsif i_hsyn = '1' and hsyn0 = '0' then
                blank_num <= blank_cnt;
                blank_cnt <= (others => '0');
            end if;
        end if;
    end process;

--    SYNC_PROC: process (clk)
--    begin
--        if (clk'event and clk = '1') then

--            state <= next_state;
--            hsyn0 <= i_hsyn;
--            hsyn1 <= hsyn0;

--            -- █▀▀ █▀▀ █▄░█   █▀ █▄█ █▄░█ █▀▀
--            -- █▄█ ██▄ █░▀█   ▄█ ░█░ █░▀█ █▄▄ %gen sync
--            if state = st_line then
--                hcnt <= hcnt + '1';
--            else
--                hcnt <= (others=>'0');
--            end if;

--            if state = st_idle then
--                vcnt <= (others =>'0');
--            elsif state = st_line_end then
--                vcnt <= vcnt + '1';
--            end if;

--            if state = st_line then
--                gen_hsyn <= '1';
--            else
--                gen_hsyn <= '0';
--            end if;
--            gen_hsyn0 <= gen_hsyn;

--            if state = st_idle then
--                gen_vsyn <= '0';
--            else
--                gen_vsyn <= '1';
--            end if;

--            if gen_hsyn = '1' then
--                gen_hcnt <= gen_hcnt + '1';
--            else
--                gen_hcnt <= (others=>'0');
--            end if;

--            if gen_vsyn = '0' then
--                gen_vcnt <= (others=>'0');
--            elsif gen_hsyn0='1' and gen_hsyn='0' then
--                gen_vcnt <= gen_vcnt + '1';
--            end if;
--            -- █▄▄ █░░ █▄▀   █▀▀ █▄░█ ▀█▀
--            -- █▄█ █▄▄ █░█   █▄▄ █░▀█ ░█░ %blank cnt
--            if state = st_start then
--                stay_start_cnt <= stay_start_cnt + '1';
--            elsif state = st_line then
--                waitnum <= stay_start_cnt;
--            else
--                stay_start_cnt <= (others=> '0');
--            end if;

--            if state = st_line_wait then
--                waitcnt <= waitcnt + '1';
--            else
--                waitcnt <= (others=>'0');
--            end if;
--        --
--        end if;
--    end process;
--    -- █▀ █▀▄▀█
--    -- ▄█ █░▀░█ %sm
--    NEXT_STATE_DECODE: process (state, i_vcnt, i_hsyn,
--                                hsyn0, hsyn1, hcnt, width, heigh,
--                                waitcnt, waitnum)
--    begin
--       next_state <= state;
--       if i_vcnt=1 and hsyn0='0' and i_hsyn='1' then
--            next_state <= st_start;
--       else
--           case (state) is
--              when st_idle =>
--                  next_state <= st_idle; --stay
--              when st_start =>
--                 if hsyn1='0' and hsyn0='1' then
--                    next_state <= st_line;
--                 end if;
--              when st_line =>
--                 if hcnt+1 >= width then
--                    next_state <= st_line_end;
--                 end if;
--              when st_line_end =>
--                 if vcnt+2 = heigh then
--                     next_state <= st_line_wait;
--                 elsif vcnt+2 > heigh then
--                     next_state <= st_frame_end;
--                 else
--                     next_state <= st_start;
--                 end if;
--              --### st_line_wait : wait blank and make 1 more line - hync.
--              when st_line_wait =>
--                 if waitcnt >= waitnum-1 then
--                    next_state <= st_line;
--                end if;
--              when st_frame_end =>
--                     next_state <= st_idle; --stay
--              when others =>
--                 next_state <= st_idle;
--           end case;
--        end if;
--    end process;

    --# Shift registers for pipeline delay and 3x3 mask data mapping
    process(clk)
    begin
        if (clk'event and clk = '1') then
        --
            shf_reg_width <= shf_reg_width(shf_reg_width'left - 1 downto 0) & i_reg_width;
            shf_reg_heigh <= shf_reg_heigh(shf_reg_heigh'left - 1 downto 0) & i_reg_height;

                             --### divide width by para4 ###
            width         <= "00" & shf_reg_width(shf_reg_width'left)(12 - 1 downto 2);
            heigh         <= shf_reg_heigh(shf_reg_heigh'left);

--          shf_vsyn <= shf_vsyn(shf_vsyn'left - 1 downto 0) & i_vsyn;
--          shf_hsyn <= shf_hsyn(shf_hsyn'left - 1 downto 0) & i_hsyn;
--          shf_vcnt <= shf_vcnt(shf_vcnt'left - 1 downto 0) & i_vcnt;
--          shf_hcnt <= shf_hcnt(shf_hcnt'left - 1 downto 0) & i_hcnt;
--          shf_data <= shf_data(shf_data'left - 1 downto 0) & i_data;
--# 2605201056 feed extender output (i_*_x) so wea fires and line-buf
--#            write/read continues during synthetic scan (last line fix)
            shf_vsyn <= shf_vsyn(shf_vsyn'left - 1 downto 0) & i_vsyn_x;
            shf_hsyn <= shf_hsyn(shf_hsyn'left - 1 downto 0) & i_hsyn_x;
            shf_vcnt <= shf_vcnt(shf_vcnt'left - 1 downto 0) & i_vcnt_x;
            shf_hcnt <= shf_hcnt(shf_hcnt'left - 1 downto 0) & i_hcnt_x;
            shf_data <= shf_data(shf_data'left - 1 downto 0) & i_data_x;
--$ 2605271746 shf_inj_act follows shf_* timing to align with wea gating
--          shf_inj_act <= shf_inj_act(shf_inj_act'left - 1 downto 0) & inj_act;
            --$ 2605281121 Use combinational inj_active_now: wea ungates 1 cycle earlier at frame boundary
            shf_inj_act <= shf_inj_act(shf_inj_act'left - 1 downto 0) & inj_active_now;

            shf_rdd0 <= shf_rdd0(shf_rdd0'left - 1 downto 0) & rdline00;
            shf_rdd1 <= shf_rdd1(shf_rdd1'left - 1 downto 0) & rdline01;

            shf_gvsyn <= shf_gvsyn(shf_gvsyn'left - 1 downto 0) & gen_vsyn;
            shf_ghsyn <= shf_ghsyn(shf_ghsyn'left - 1 downto 0) & gen_hsyn;
            shf_gvcnt <= shf_gvcnt(shf_gvcnt'left - 1 downto 0) & gen_vcnt;
            shf_ghcnt <= shf_ghcnt(shf_ghcnt'left - 1 downto 0) & gen_hcnt;

--          vsyn_2x2 <= shf_gvsyn(1);
--          hsyn_2x2 <= shf_ghsyn(1);
--          vcnt_2x2 <= shf_gvcnt(1);
--          hcnt_2x2 <= shf_ghcnt(1);
--# 2605191759 sync tap (1)->(2): compensate BRAM 1-cyc read latency on rdline path
--# without this, mask_*_2x2 leads data_2x2/data_3x2 by 1 cycle -> 1st pixel skew + dup
            vsyn_2x2 <= shf_gvsyn(2);
            hsyn_2x2 <= shf_ghsyn(2);
            vcnt_2x2 <= shf_gvcnt(2);
            hcnt_2x2 <= shf_ghcnt(2);

            -- ▀▀█ ▀▄▀ ▀▀█  █▀▄▀█ ▄▀█ █▀█
            -- ▄▄█ █░█ ▄▄█  █░▀░█ █▀█ █▀▀ %33map
            data_1x1 <= shf_rdd0(3)(48 - 1 downto 32) & shf_rdd0(3)(32 - 1 downto 16) & shf_rdd0(3)(16 - 1 downto 00) & shf_rdd0(4)(64 - 1 downto 48);
            data_1x2 <= shf_rdd0(3)(64 - 1 downto 48) & shf_rdd0(3)(48 - 1 downto 32) & shf_rdd0(3)(32 - 1 downto 16) & shf_rdd0(3)(16 - 1 downto 00);
            data_1x3 <= shf_rdd0(2)(16 - 1 downto 00) & shf_rdd0(3)(64 - 1 downto 48) & shf_rdd0(3)(48 - 1 downto 32) & shf_rdd0(3)(32 - 1 downto 16);
            data_2x1 <= shf_rdd1(3)(48 - 1 downto 32) & shf_rdd1(3)(32 - 1 downto 16) & shf_rdd1(3)(16 - 1 downto 00) & shf_rdd1(4)(64 - 1 downto 48);
            data_2x2 <= shf_rdd1(3)(64 - 1 downto 48) & shf_rdd1(3)(48 - 1 downto 32) & shf_rdd1(3)(32 - 1 downto 16) & shf_rdd1(3)(16 - 1 downto 00);
            data_2x3 <= shf_rdd1(2)(16 - 1 downto 00) & shf_rdd1(3)(64 - 1 downto 48) & shf_rdd1(3)(48 - 1 downto 32) & shf_rdd1(3)(32 - 1 downto 16);
            data_3x1 <= shf_data(4)(48 - 1 downto 32) & shf_data(4)(32 - 1 downto 16) & shf_data(4)(16 - 1 downto 00) & shf_data(5)(64 - 1 downto 48);
            data_3x2 <= shf_data(4)(64 - 1 downto 48) & shf_data(4)(48 - 1 downto 32) & shf_data(4)(32 - 1 downto 16) & shf_data(4)(16 - 1 downto 00);
            data_3x3 <= shf_data(3)(16 - 1 downto 00) & shf_data(4)(64 - 1 downto 48) & shf_data(4)(48 - 1 downto 32) & shf_data(4)(32 - 1 downto 16);

        --
        end if;
    end process;

    o_vsyn_2x2 <= vsyn_2x2;
    o_hsyn_2x2 <= hsyn_2x2;
    o_vcnt_2x2 <= vcnt_2x2;
    o_hcnt_2x2 <= hcnt_2x2;

    o_data_1x1 <= data_1x1;
    o_data_1x2 <= data_1x2;
    o_data_1x3 <= data_1x3;
    o_data_2x1 <= data_2x1;
    o_data_2x2 <= data_2x2;
    o_data_2x3 <= data_2x3;
    o_data_3x1 <= data_3x1;
    o_data_3x2 <= data_3x2;
    o_data_3x3 <= data_3x3;

end Behavioral;

--# Unused signals (removed from declaration, used only in commented-out code):
--# signal rhcnt          : std_logic_vector(10 - 1 downto 0) := (others => '0');
--# signal next_state     : type_sm_gensync;
--# signal waitnum        : std_logic_vector(16 - 1 downto 0) := (others => '0');
--# signal stay_start_cnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
