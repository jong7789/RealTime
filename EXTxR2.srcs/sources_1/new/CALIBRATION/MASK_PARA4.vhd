-- =========================================================================
-- MASK_PARA4 : 3x3 neighborhood data extractor for para4 (4-pixel/cycle) video.
--
-- For each output pixel located at (vcnt_2x2, hcnt_2x2) produces 9 outputs:
--   data_1x1 / 1x2 / 1x3  : above-line  (left / center / right)
--   data_2x1 / 2x2 / 2x3  : center-line
--   data_3x1 / 3x2 / 3x3  : below-line
--
-- Architecture:
--   * Two 1024x64 BRAM line buffers in ping-pong (BUF0 even, BUF1 odd lines).
--   * Output sync FSM produces gen_hsyn/gen_vsyn with same blank period as input.
--   * Frame extender injects a phantom line during inter-frame blanking so
--     mask processing of the LAST output row gets valid BRAM reads.
--   * Sync taps at shf_g*(2) align with BRAM 1-cycle read + rdline mux delay.
--
--$ 2605281211 Clean rewrite (functionally equivalent to 2605271746..2605281121 fix chain).
-- =========================================================================
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
    i_reg_height : in  std_logic_vector(13 - 1 downto 0);

    i_hsyn       : in  std_logic;
    i_vsyn       : in  std_logic;
    i_vcnt       : in  std_logic_vector(13 - 1 downto 0);
    i_hcnt       : in  std_logic_vector(12 - 1 downto 0);
    i_data       : in  std_logic_vector(64 - 1 downto 0);

    o_hsyn_2x2   : out std_logic;
    o_vsyn_2x2   : out std_logic;
    o_hcnt_2x2   : out std_logic_vector(12 - 1 downto 0);
    o_vcnt_2x2   : out std_logic_vector(13 - 1 downto 0);

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

    -- =====================================================================
    -- Component declarations (BRAM line buffer + ILA debug probe)
    -- =====================================================================
    component mmr_64x1024
    port (
        clka  : in  std_logic;
        wea   : in  std_logic_vector(0 downto 0);
        addra : in  std_logic_vector(9 downto 0);
        dina  : in  std_logic_vector(63 downto 0);
        douta : out std_logic_vector(63 downto 0);
        clkb  : in  std_logic;
        web   : in  std_logic_vector(0 downto 0);
        addrb : in  std_logic_vector(9 downto 0);
        dinb  : in  std_logic_vector(63 downto 0);
        doutb : out std_logic_vector(63 downto 0)
    );
    end component;

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

    -- =====================================================================
    -- Constants & types
    -- =====================================================================
    constant SHF_REG_NUM : integer := 3;  -- reg_width/height delay (pipeline align)
    constant SHF_VID_NUM : integer := 8;  -- video pipeline depth

    type ty_reg_12b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(11 downto 0);
    type ty_reg_13b is array (SHF_REG_NUM - 1 downto 0) of std_logic_vector(12 downto 0);
    type ty_vid_12b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(11 downto 0);
    type ty_vid_13b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(12 downto 0);
    type ty_vid_64b is array (SHF_VID_NUM - 1 downto 0) of std_logic_vector(63 downto 0);

    type ty_fsm is (st_idle, st_start, st_line, st_line_end, st_line_wait, st_frame_end);

    -- =====================================================================
    -- Internal width/height (delayed for shf alignment)
    -- =====================================================================
    signal shf_reg_w : ty_reg_12b;
    signal shf_reg_h : ty_reg_13b;
    signal width     : std_logic_vector(11 downto 0) := (others => '0');  -- i_reg_width / 4 (para4 unit)
    signal heigh     : std_logic_vector(12 downto 0) := (others => '0');
    signal w_max_loc : std_logic_vector(11 downto 0);                     -- = width - 1 (para4 word max addr)

    -- =====================================================================
    -- Frame extender: phantom line injection for last output row
    -- =====================================================================
    signal i_hsyn_q1     : std_logic := '0';                          -- input hsyn delayed 1 cycle (edge detect)
    signal last_line_seen: std_logic := '0';                          -- arms when last real line (H-1) hsyn high observed
    signal inj_act       : std_logic := '0';                          -- registered: high from last-line fall to next-frame start
    signal frame_restart : std_logic;                                 -- comb: '1' on next-frame line 0 hsyn rise
    signal inj_active    : std_logic;                                 -- comb: inj_act AND (NOT frame_restart) -- early-exit
    signal inj_wait      : std_logic := '0';                          -- '1' during phantom-blank period after inj_act fires
    signal inj_wait_cnt  : std_logic_vector(15 downto 0) := (others => '0');
    signal inj_cnt       : std_logic_vector(11 downto 0) := (others => '0');  -- addrb scan counter during phantom line

    -- =====================================================================
    -- Internal video input (real video OR injected phantom)
    -- =====================================================================
    signal in_hsyn : std_logic;
    signal in_vsyn : std_logic;
    signal in_hcnt : std_logic_vector(11 downto 0);
    signal in_vcnt : std_logic_vector(12 downto 0);
    signal in_data : std_logic_vector(63 downto 0);

    -- =====================================================================
    -- Video pipeline (8-deep shift registers from in_*)
    -- =====================================================================
    signal shf_vsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_hsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_vcnt : ty_vid_13b;
    signal shf_hcnt : ty_vid_12b;
    signal shf_data : ty_vid_64b;
    signal shf_inj  : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');  -- shf of inj_active (wea gating)

    -- =====================================================================
    -- Line buffer ping-pong (BUF0 even, BUF1 odd lines)
    --   wea*_pingpong : raw LSB-based pattern -> drives read mux (preserves
    --                   correct routing through injection where wea is gated)
    --   wea*          : gated BRAM write enable (disabled during injection
    --                   so the last two real lines stay intact)
    -- =====================================================================
    signal wea0_pingpong : std_logic;
    signal wea1_pingpong : std_logic;
    signal wea0          : std_logic;
    signal wea1          : std_logic;
    signal rd_buf0       : std_logic_vector(63 downto 0) := (others => '0');
    signal rd_buf1       : std_logic_vector(63 downto 0) := (others => '0');
    signal rd_above_bram : std_logic_vector(63 downto 0) := (others => '0');  -- mask "above" row source
    signal rd_center_bram: std_logic_vector(63 downto 0) := (others => '0');  -- mask "center" row source
    signal shf_rd_above  : ty_vid_64b;
    signal shf_rd_center : ty_vid_64b;

    -- =====================================================================
    -- Output sync generator FSM
    -- =====================================================================
    signal state         : ty_fsm;
    signal i_hsyn_q1_sm  : std_logic;  -- input hsyn 1-cycle delayed (FSM detect)
    signal i_hsyn_q2_sm  : std_logic;  -- input hsyn 2-cycle delayed (FSM detect)
    signal fsm_hcnt      : std_logic_vector(11 downto 0) := (others => '0');  -- FSM internal hcnt
    signal fsm_vcnt      : std_logic_vector(12 downto 0) := (others => '0');  -- FSM internal vcnt
    signal waitcnt       : std_logic_vector(15 downto 0) := (others => '0');
    signal gen_hsyn      : std_logic;
    signal gen_hsyn_q1   : std_logic;                                         -- gen_hsyn 1-cycle delayed (falling edge detect)
    signal gen_vsyn      : std_logic;
    signal gen_hcnt      : std_logic_vector(11 downto 0) := (others => '0');
    signal gen_vcnt      : std_logic_vector(12 downto 0) := (others => '0');

    -- =====================================================================
    -- Input inter-line blank measurement (drives output FSM st_line_wait length)
    -- =====================================================================
    signal blank_cnt : std_logic_vector(15 downto 0) := (others => '0');
    signal blank_num : std_logic_vector(15 downto 0) := (others => '0');

    -- =====================================================================
    -- Gen-sync pipeline (aligned with rdline path: tap (2) = 3-cycle delay)
    -- =====================================================================
    signal shf_gvsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_ghsyn : std_logic_vector(SHF_VID_NUM - 1 downto 0) := (others => '0');
    signal shf_gvcnt : ty_vid_13b;
    signal shf_ghcnt : ty_vid_12b;

    -- =====================================================================
    -- Output registers (sync + 9 mask data windows)
    -- =====================================================================
    signal hsyn_2x2 : std_logic;
    signal vsyn_2x2 : std_logic;
    signal hcnt_2x2 : std_logic_vector(11 downto 0);
    signal vcnt_2x2 : std_logic_vector(12 downto 0);

    signal data_1x1, data_1x2, data_1x3 : std_logic_vector(63 downto 0);
    signal data_2x1, data_2x2, data_2x3 : std_logic_vector(63 downto 0);
    signal data_3x1, data_3x2, data_3x3 : std_logic_vector(63 downto 0);

begin

    -- =====================================================================
    -- SECTION A : ILA debug instance
    -- =====================================================================
    U0_ILA_MASK : ila_mask_para4
    port map (
        clk     => clk,
        probe0  => i_hsyn,
        probe1  => i_vsyn,
        probe2  => i_hcnt,
        probe3  => i_vcnt,
        probe4  => i_data,
        probe5  => shf_hsyn(0),
        probe6  => shf_vsyn(0),
        probe7  => shf_hcnt(0),
        probe8  => shf_vcnt(0),
        probe9  => shf_data(0),
        probe10 => hsyn_2x2,
        probe11 => vsyn_2x2,
        probe12 => hcnt_2x2,
        probe13 => vcnt_2x2,
        probe14 => data_2x2,
        probe15 => wea0,
        probe16 => wea1,
        probe17 => inj_act,
        probe18 => inj_cnt,
        probe19 => rd_buf0,
        probe20 => rd_buf1,
        probe21 => rd_above_bram,
        probe22 => rd_center_bram,
        probe23 => i_hsyn_q1,
        probe24 => in_hcnt
    );

    -- =====================================================================
    -- SECTION B : Width max in para4 word units (= i_reg_width / 4 - 1)
    -- =====================================================================
    w_max_loc <= ("00" & i_reg_width(11 downto 2)) - 1;

    -- =====================================================================
    -- SECTION C : Frame extender FSM
    --   Drives a phantom line during inter-frame blanking so the LAST
    --   output row has live BRAM reads. Three sub-states inside inj_act high:
    --     wait phase : inj_wait=1 for blank_num-1 cycles (mimics real blank)
    --     scan phase : inj_cnt counts 0..w_max_loc wrap (addr scan)
    --   last_line_seen distinguishes line H-1 fall from line H-2 fall,
    --   since both yield i_vcnt = H-1 (i_vcnt saturates at H-1 in upstream).
    -- =====================================================================
    p_ext_fsm : process(clk)
    begin
        if rising_edge(clk) then
            if rstn = '0' then
                inj_act        <= '0';
                inj_cnt        <= (others => '0');
                i_hsyn_q1      <= '0';
                last_line_seen <= '0';
                inj_wait       <= '0';
                inj_wait_cnt   <= (others => '0');
            else
                i_hsyn_q1 <= i_hsyn;

                -- Arm on line H-1 hsyn rising edge.
                if i_hsyn_q1 = '0' and i_hsyn = '1' and i_vcnt = (i_reg_height - 1) then
                    last_line_seen <= '1';
                end if;

                if inj_act = '0' then
                    -- Fire on hsyn falling edge AFTER flag set (= line H-1 fall).
                    if i_hsyn_q1 = '1' and i_hsyn = '0' and last_line_seen = '1' then
                        inj_act        <= '1';
                        inj_cnt        <= (others => '0');
                        last_line_seen <= '0';
                        inj_wait       <= '1';
                        inj_wait_cnt   <= (others => '0');
                    end if;
                else
                    if i_hsyn = '1' and i_vcnt < (i_reg_height - 1) then
                        -- Next frame begins: registered exit.
                        inj_act        <= '0';
                        inj_cnt        <= (others => '0');
                        last_line_seen <= '0';
                        inj_wait       <= '0';
                        inj_wait_cnt   <= (others => '0');
                    elsif inj_wait = '1' then
                        -- Mirror inter-line blank. -2 releases 1 cycle early to
                        -- compensate shf_hsyn + mux + BRAM read pipeline delay.
                        if inj_wait_cnt = blank_num - 2 then
                            inj_wait <= '0';
                        else
                            inj_wait_cnt <= inj_wait_cnt + '1';
                        end if;
                    elsif inj_cnt = w_max_loc then
                        inj_cnt <= (others => '0');
                    else
                        inj_cnt <= inj_cnt + '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- =====================================================================
    -- SECTION D : Combinational early-exit (1-cycle ahead of registered inj_act)
    --   so downstream muxes and shf_inj see clean transition in time for
    --   BUF0[0] of next frame line 0 to be written successfully.
    -- =====================================================================
    frame_restart <= '1' when (i_hsyn = '1' and i_vcnt < (i_reg_height - 1)) else '0';
    inj_active    <= inj_act and (not frame_restart);

    -- =====================================================================
    -- SECTION E : Internal video input mux (real vs phantom)
    --   vsyn/vcnt/data follow inj_active alone (keeps wea LSB pattern stable).
    --   hsyn/hcnt are released only after inj_wait clears.
    -- =====================================================================
    in_hsyn <= '1'             when (inj_active = '1' and inj_wait = '0') else i_hsyn;
    in_vsyn <= '1'             when  inj_active = '1'                     else i_vsyn;
    in_hcnt <= inj_cnt         when (inj_active = '1' and inj_wait = '0') else i_hcnt;
    in_vcnt <= i_reg_height    when  inj_active = '1'                     else i_vcnt;
    in_data <= (others => '0') when  inj_active = '1'                     else i_data;

    -- =====================================================================
    -- SECTION F : Line buffer wea + dual-port BRAMs
    --   wea*_pingpong : raw LSB-based pattern (drives read mux selector)
    --   wea*          : pingpong AND (NOT shf_inj(0)) (BRAM write enable)
    -- =====================================================================
    wea0_pingpong <= (not shf_vcnt(0)(0)) and shf_hsyn(0);
    wea1_pingpong <= (    shf_vcnt(0)(0)) and shf_hsyn(0);
    wea0          <= wea0_pingpong and (not shf_inj(0));
    wea1          <= wea1_pingpong and (not shf_inj(0));

    u_linebuf0 : mmr_64x1024
    port map (
        clka   => clk,
        wea(0) => wea0,
        addra  => shf_hcnt(0)(9 downto 0),
        dina   => shf_data(0),
        douta  => open,
        clkb   => clk,
        web(0) => '0',
        addrb  => in_hcnt(9 downto 0),
        dinb   => (others => '0'),
        doutb  => rd_buf0
    );

    u_linebuf1 : mmr_64x1024
    port map (
        clka   => clk,
        wea(0) => wea1,
        addra  => shf_hcnt(0)(9 downto 0),
        dina   => shf_data(0),
        douta  => open,
        clkb   => clk,
        web(0) => '0',
        addrb  => in_hcnt(9 downto 0),
        dinb   => (others => '0'),
        doutb  => rd_buf1
    );

    -- =====================================================================
    -- SECTION G : Read mux
    --   rd_above_bram  = buffer currently being written
    --                    (BRAM read-while-write returns 2-lines-ago = above row)
    --   rd_center_bram = other buffer (= previous fully written line = center)
    --   Selector uses RAW pingpong so injection preserves correct routing.
    -- =====================================================================
    rd_above_bram  <= rd_buf0 when wea0_pingpong = '1' else rd_buf1;
    rd_center_bram <= rd_buf1 when wea0_pingpong = '1' else rd_buf0;

    -- =====================================================================
    -- SECTION H : Output sync generator FSM + inter-line blank measurement
    -- =====================================================================
    p_gen_sync : process(clk)
    begin
        if rising_edge(clk) then
            i_hsyn_q1_sm <= i_hsyn;
            i_hsyn_q2_sm <= i_hsyn_q1_sm;

            case state is
                when st_idle =>
                    if i_vcnt = 1 and i_hsyn_q1_sm = '0' and i_hsyn = '1' then
                        state <= st_start;
                    end if;
                    gen_vsyn <= '0';
                    gen_hsyn <= '0';
                    fsm_vcnt <= (others => '0');

                when st_start =>
                    if i_hsyn_q2_sm = '0' and i_hsyn_q1_sm = '1' then
                        state <= st_line;
                    end if;
                    gen_vsyn <= '1';
                    gen_hsyn <= '1';

                when st_line =>
                    if fsm_hcnt = width - 2 then
                        state <= st_line_end;
                    end if;
                    gen_hsyn <= '1';
                    fsm_hcnt <= fsm_hcnt + '1';
                    waitcnt  <= (others => '0');

                when st_line_end =>
                    if fsm_vcnt >= heigh - 1 then
                        state    <= st_frame_end;
                        gen_vsyn <= '0';
                    else
                        state <= st_line_wait;
                    end if;
                    gen_hsyn <= '0';
                    fsm_hcnt <= (others => '0');
                    fsm_vcnt <= fsm_vcnt + '1';

                when st_line_wait =>
                    if waitcnt >= blank_num - 1 then
                        state    <= st_line;
                        gen_hsyn <= '1';
                    else
                        waitcnt  <= waitcnt + '1';
                        gen_hsyn <= '0';
                    end if;

                when st_frame_end =>
                    state <= st_idle;
            end case;

            -- gen_hcnt / gen_vcnt counters (driven by gen_hsyn pulse)
            gen_hsyn_q1 <= gen_hsyn;
            if gen_hsyn = '1' then
                gen_hcnt <= gen_hcnt + '1';
            else
                gen_hcnt <= (others => '0');
            end if;

            if gen_vsyn = '0' then
                gen_vcnt <= (others => '0');
            elsif gen_hsyn_q1 = '1' and gen_hsyn = '0' then
                gen_vcnt <= gen_vcnt + '1';
            end if;

            -- Inter-line blank measurement (latched per input line rising edge)
            if i_vsyn = '1' and i_hsyn = '0' then
                blank_cnt <= blank_cnt + '1';
            elsif i_hsyn = '1' and i_hsyn_q1_sm = '0' then
                blank_num <= blank_cnt;
                blank_cnt <= (others => '0');
            end if;
        end if;
    end process;

    -- =====================================================================
    -- SECTION I : Pipeline shift registers + output registers
    --
    -- Pipeline alignment summary:
    --   - shf_*       : 8-deep, 1 cycle per tap
    --   - BRAM read   : 1 cycle latency (addrb -> doutb)
    --   - gen-sync taps at (2) (= 3 cyc delay) align with the read-path
    --     pipeline (BRAM 1 + rdline mux 1 + shift register entry 1).
    --   - data_*x2 use shf_*(3) for center column
    --   - data_*x3 use shf_*(2)(15:0) for next-word first pixel
    --   - data_*x1 use shf_*(4)(63:48) (data_3x1 uses (5)) for prev-word last pixel
    -- =====================================================================
    p_pipeline : process(clk)
    begin
        if rising_edge(clk) then
            -- Width / height delay (aligned with shf-pipeline entry)
            shf_reg_w <= shf_reg_w(shf_reg_w'left - 1 downto 0) & i_reg_width;
            shf_reg_h <= shf_reg_h(shf_reg_h'left - 1 downto 0) & i_reg_height;
            width     <= "00" & shf_reg_w(shf_reg_w'left)(11 downto 2);  -- /4 (para4)
            heigh     <= shf_reg_h(shf_reg_h'left);

            -- Video pipeline (from internal input: real or phantom)
            shf_vsyn <= shf_vsyn(shf_vsyn'left - 1 downto 0) & in_vsyn;
            shf_hsyn <= shf_hsyn(shf_hsyn'left - 1 downto 0) & in_hsyn;
            shf_vcnt <= shf_vcnt(shf_vcnt'left - 1 downto 0) & in_vcnt;
            shf_hcnt <= shf_hcnt(shf_hcnt'left - 1 downto 0) & in_hcnt;
            shf_data <= shf_data(shf_data'left - 1 downto 0) & in_data;
            shf_inj  <= shf_inj (shf_inj 'left - 1 downto 0) & inj_active;

            -- BRAM read-path pipeline (rdline mux output -> 8-deep history)
            shf_rd_above  <= shf_rd_above (shf_rd_above 'left - 1 downto 0) & rd_above_bram;
            shf_rd_center <= shf_rd_center(shf_rd_center'left - 1 downto 0) & rd_center_bram;

            -- Generated sync pipeline (output FSM -> 8-deep)
            shf_gvsyn <= shf_gvsyn(shf_gvsyn'left - 1 downto 0) & gen_vsyn;
            shf_ghsyn <= shf_ghsyn(shf_ghsyn'left - 1 downto 0) & gen_hsyn;
            shf_gvcnt <= shf_gvcnt(shf_gvcnt'left - 1 downto 0) & gen_vcnt;
            shf_ghcnt <= shf_ghcnt(shf_ghcnt'left - 1 downto 0) & gen_hcnt;

            -- Output sync (tap (2) = 3-cycle delay, aligns with read-path)
            vsyn_2x2 <= shf_gvsyn(2);
            hsyn_2x2 <= shf_ghsyn(2);
            vcnt_2x2 <= shf_gvcnt(2);
            hcnt_2x2 <= shf_ghcnt(2);

            -- 3x3 mask windows (para4 word-aligned with +-1 pixel shift)
            -- Above row (data_1x*) from BRAM "current write buf" read history
            data_1x1 <= shf_rd_above(3)(47 downto 32) & shf_rd_above(3)(31 downto 16) & shf_rd_above(3)(15 downto  0) & shf_rd_above(4)(63 downto 48);
            data_1x2 <= shf_rd_above(3)(63 downto 48) & shf_rd_above(3)(47 downto 32) & shf_rd_above(3)(31 downto 16) & shf_rd_above(3)(15 downto  0);
            data_1x3 <= shf_rd_above(2)(15 downto  0) & shf_rd_above(3)(63 downto 48) & shf_rd_above(3)(47 downto 32) & shf_rd_above(3)(31 downto 16);
            -- Center row (data_2x*) from BRAM "other buf" read history
            data_2x1 <= shf_rd_center(3)(47 downto 32) & shf_rd_center(3)(31 downto 16) & shf_rd_center(3)(15 downto  0) & shf_rd_center(4)(63 downto 48);
            data_2x2 <= shf_rd_center(3)(63 downto 48) & shf_rd_center(3)(47 downto 32) & shf_rd_center(3)(31 downto 16) & shf_rd_center(3)(15 downto  0);
            data_2x3 <= shf_rd_center(2)(15 downto  0) & shf_rd_center(3)(63 downto 48) & shf_rd_center(3)(47 downto 32) & shf_rd_center(3)(31 downto 16);
            -- Below row (data_3x*) from input video pipeline (current line)
            data_3x1 <= shf_data(4)(47 downto 32) & shf_data(4)(31 downto 16) & shf_data(4)(15 downto  0) & shf_data(5)(63 downto 48);
            data_3x2 <= shf_data(4)(63 downto 48) & shf_data(4)(47 downto 32) & shf_data(4)(31 downto 16) & shf_data(4)(15 downto  0);
            data_3x3 <= shf_data(3)(15 downto  0) & shf_data(4)(63 downto 48) & shf_data(4)(47 downto 32) & shf_data(4)(31 downto 16);
        end if;
    end process;

    -- =====================================================================
    -- SECTION J : Output drivers
    -- =====================================================================
    o_hsyn_2x2 <= hsyn_2x2;
    o_vsyn_2x2 <= vsyn_2x2;
    o_hcnt_2x2 <= hcnt_2x2;
    o_vcnt_2x2 <= vcnt_2x2;

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
