library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
    use UNISIM.VCOMPONENTS.ALL;
    use WORK.TOP_HEADER.ALL;

entity TI_LVDS_RX is
    generic ( GNR_MODEL : string := "EXT1616R" );
    port (
        iroic_clk      : in std_logic;
        iroic_rstn     : in std_logic;
        iroic_dclk     : in std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);

        isys_clk       : in std_logic;

        ireg_req_align : in std_logic;

        iroic_dvalid   : in std_logic;
        iroic_data     : in std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

        ireg_width     : in std_logic_vector(11 downto 0);
        ireg_height    : in std_logic_vector(11 downto 0);

        ireg_bcal_ctrl : in  std_logic_vector(31 downto 0);
        oreg_bcal_data : out std_logic_vector(31 downto 0);

        oen_array      : out std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
        odata_array    : out std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
        oalign_done    : out std_logic;
        oroic_clk_sel  : out std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

        irefvcnt       : in  std_logic_vector(11 downto 0);
        ovcnt          : out std_logic_vector(12 - 1 downto 0)
    );
end entity TI_LVDS_RX;

architecture behavioral of TI_LVDS_RX is

    constant ALL_HIGH    : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0) := (others => '1');
    constant ALL_LOW     : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0) := (others => '0');
    constant stap_max    : integer range 0 to 32 := 32;
    constant strain_word : std_logic_vector(23 downto 0) := x"FFF000";

    component TI_ROIC_SERDES is
        generic ( geni : integer := 0);
        port (
            iroic_clk  : in  std_logic;
            iroic_rstn : in  std_logic;

            ireg_req_align : in  std_logic;

            idata_ser  : in  std_logic;
            odata_par  : out std_logic_vector(23 downto 0);
            odata_val  : out std_logic;
            odata_diff : out std_logic;
            odata_ff00 : out std_logic;

            obitslipm  : out std_logic;
            obitslipc  : out std_logic_vector(4 downto 0);
            ocntvalue  : out std_logic_vector(4 downto 0);
            oser_cnt   : out std_logic_vector(4 downto 0);

            idly_ce    : in  std_logic;
            idly_rst   : in  std_logic;
            ibitslip   : in  std_logic;

            sroic_dvalid_3d : in std_logic  --# for ila
        );
    end component;

    type tstate_align_ctrl is (
        s_IDLE,
        s_ALIGN,
        s_WAIT,
        s_CHECK
    );

    signal state_align_ctrl, state_align_ctrl0, state_align_ctrl1, state_align_ctrl2 : tstate_align_ctrl;
    signal sdata_ch    : integer range 0 to ROIC_NUM(GNR_MODEL) - 1;
    signal salign_done : std_logic;

    type tstate_align is (
        s_IDLE,       -- 0
        s_RESET1,     -- 1
        s_TAP_DELAY1, -- 2
        s_WAIT1,      -- 3
        s_CHECK,      -- 4
        s_CALC1,      -- 5
        s_CALC2,      -- 6
        s_RESET2,     -- 7
        s_TAP_DELAY2, -- 8
        s_WAIT2,      -- 9
        s_BITSLIP,    -- 10
        s_CHECK2,     -- 11
        s_FINISH      -- 12
    );

    type tstate_eye is (
        s_EDGE1,
        s_EDGE2
    );

    signal state_align, state_align0, state_align1, state_align2 : tstate_align;
    signal state_eye : tstate_eye;

    type tstate_dvalid is (
        s_IDLE,
        s_READY,
        s_START,
        s_VALID
    );

    type   state_dvalid_arr is array (0 to ROIC_NUM(GNR_MODEL)-1) of tstate_dvalid;
    signal state_dvalid : state_dvalid_arr;

    type   tdata_par_dummy is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(23 downto 0);
    signal sdata_par : tdata_par_dummy;

    signal sroic_dclk : std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
    signal sdata_val  : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    signal sdly_ce_or,  sdly_ce,  sdly_ce0,  sdly_ce1,  sdly_ce2  : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sdly_rst_or, sdly_rst, sdly_rst0, sdly_rst1, sdly_rst2 : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sbitslip_or, sbitslip, sbitslip0, sbitslip1, sbitslip2  : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    signal stap_cnt  : std_logic_vector(5 downto 0);
    signal swait_cnt : std_logic_vector(32-1 downto 0);
    signal serr_cnt  : std_logic_vector(5 downto 0);

    type   tbitslip_cnt is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(7 downto 0);
    signal sbitslip_cnt : tbitslip_cnt;

    signal scurr_data    : std_logic_vector(23 downto 0);
    signal sprev_data    : std_logic_vector(23 downto 0);

    type   teye_data is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(5 downto 0);
    signal seye_start : teye_data;
    signal seye_end   : teye_data;
    signal seye_mid   : teye_data;
    signal seye_sum   : teye_data;

    signal salign_success : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sdvalid        : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    type   tcnt_array is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(11 downto 0);
    signal shcnt     : tcnt_array;
    signal svcnt     : tcnt_array;
    signal svcnt_all : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    signal sreg_req_align_1d : std_logic;
    signal sreg_req_align_2d : std_logic;
    signal sreg_req_align_3d : std_logic;
    signal sroic_dvalid_1d   : std_logic;
    signal sroic_dvalid_2d   : std_logic;
    signal sroic_dvalid_3d   : std_logic;
    signal sreg_height_1d    : std_logic_vector(11 downto 0);
    signal sreg_height_2d    : std_logic_vector(11 downto 0);
    signal sreg_height_3d    : std_logic_vector(11 downto 0);

    signal ireg_bcal_ctrl_1d : std_logic_vector(31 downto 0);
    signal ireg_bcal_ctrl_2d : std_logic_vector(31 downto 0);
    signal sreg_bcal_ctrl    : std_logic_vector(31 downto 0);

    type type_sreg_bcal_data_array is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(32-1 downto 0);
    signal sreg_bcal_data_array : type_sreg_bcal_data_array;

    signal sen_array          : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sreg_roicbcal_pass : std_logic := '0';

    type tdata_par is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(15 downto 0);
    signal sdata_array : tdata_par;

    signal rclk_ch         : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal rclk_sel        : std_logic;

    signal sel         : std_logic_vector(2 downto 0) := "000";

    signal sroic_dvalidch_1d : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sroic_dvalidch_2d : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sroic_dvalidch_3d : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    signal FreeRunCnt   : std_logic_vector(32-1 downto 0) := (others => '0');
    signal ila_sdata_ch : std_logic_vector(5-1 downto 0);
    signal vio_clk_inv  : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal vio_ch       : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal vio_dly      : std_logic := '0';
    signal vio_rst      : std_logic := '0';
    signal vio_bit      : std_logic := '0';

    type type_vio_data is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(16-1 downto 0);
    signal vio_data : type_vio_data;

    signal ser_dly0, ser_dly1, ser_dly2, sd_ser_dly : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal ser_rst0, ser_rst1, ser_rst2, sd_ser_rst : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal ser_bit0, ser_bit1, ser_bit2, sd_ser_bit : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    signal notsel0 : std_logic := '0';
    signal sel0    : std_logic := '0';
    signal notsel1 : std_logic := '0';
    signal sel1    : std_logic := '0';

    signal idle_ce_or  : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal idle_rst_or : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal ibitslip_or : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

    type type_ocntvalue is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(5-1 downto 0);
    signal ocntvalue : type_ocntvalue;
    signal oser_cnt  : type_ocntvalue;
    signal obitslipc : type_ocntvalue;

    signal obitslipm        : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal dvalid_high_cnt  : std_logic_vector(8-1 downto 0);
    signal roic_dvalid_fcut : std_logic;

    constant BIT_ALIGN_MODEL : std_logic := FUNC_BIT_ALIGN(GNR_MODEL);

    signal sdata_diff     : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sdata_diff_ch0 : std_logic;
    signal sdata_diff_ch1 : std_logic;
    signal sdata_diff_ch  : std_logic;

    signal sdata_ff00     : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sdata_ff00_ch0 : std_logic;
    signal sdata_ff00_ch1 : std_logic;
    signal sdata_ff00_ch  : std_logic;
    
    signal clk_mux_a : std_logic;
    signal clk_mux_b : std_logic;

begin --# %begin

-- ▄█ █▀█ ▀█ █░█ █▀█
-- ░█ █▄█ █▄ ▀▀█ █▀▄ %1024
EXT1024 : if(GNR_MODEL = "EXT1024R") generate

    clkn : for i in 0 to ROIC_DCLK_NUM(GNR_MODEL) - 1 generate
        u_BUFG_roic_clk : BUFG port map ( --# top bufg
            O => sroic_dclk(i),
            I => iroic_dclk(i)
        );
    end generate clkn;

    rclk_ch(0) <= sroic_dclk(0);
    rclk_ch(1) <= sroic_dclk(0);
    rclk_ch(2) <= sroic_dclk(1);
    rclk_ch(3) <= sroic_dclk(2);
    rclk_ch(4) <= sroic_dclk(2);

    sel <= "000" when (sdata_ch = 0) else
           "000" when (sdata_ch = 1) else
           "001" when (sdata_ch = 2) else
           "010" when (sdata_ch = 3) else
           "010";
--##### 1 step mux #####
    notsel0 <= not sel(0);
    sel0    <= sel(0);

    BUFGCTRL_inst0 : BUFGCTRL
    generic map (
        INIT_OUT      => 0,    -- Initial value of BUFGCTRL output ($VALUES;)
        PRESELECT_I0  => TRUE, -- BUFGCTRL output uses I0 input ($VALUES;)
        PRESELECT_I1  => FALSE -- BUFGCTRL output uses I1 input ($VALUES;)
    )
    port map (
        O       => clk_mux_a,      -- 1-bit output: Clock output
        CE0     => '1',            -- 1-bit input: Clock enable input for I0
        CE1     => '1',            -- 1-bit input: Clock enable input for I1
        I0      => sroic_dclk(0),  -- 1-bit input: Primary clock
        I1      => sroic_dclk(1),  -- 1-bit input: Secondary clock
        IGNORE0 => '0',            -- 1-bit input: Clock ignore input for I0
        IGNORE1 => '0',            -- 1-bit input: Clock ignore input for I1
        S0      => notsel0,        -- 1-bit input: Clock select for I0
        S1      => sel0            -- 1-bit input: Clock select for I1
    );

--##### 2 step mux #####
    notsel1 <= not sel(1);
    sel1    <= sel(1);

    BUFGCTRL_inst2 : BUFGCTRL
    generic map (
        INIT_OUT     => 0,
        PRESELECT_I0 => TRUE,
        PRESELECT_I1 => FALSE
    )
    port map (
        O       => rclk_sel,
        CE0     => '1',
        CE1     => '1',
        I0      => clk_mux_a,
        I1      => sroic_dclk(2),
        IGNORE0 => '0',
        IGNORE1 => '0',
        S0      => notsel1,
        S1      => sel1
    );

end generate EXT1024;

-- █░█ ▀▀█ █░█ ▀▀█ █▀█
-- ▀▀█ ▄▄█ ▀▀█ ▄▄█ █▀▄ %4343
EXT4343R_dclk : if(GNR_MODEL = "EXT4343R_4" or GNR_MODEL = "EXT4343RI_4") generate

    clkn : for i in 0 to ROIC_DCLK_NUM(GNR_MODEL) - 1 generate
--  u_BUFG_roic_clk : BUFG port map ( --# top bufg
--    O => sroic_dclk(i),
--    I => iroic_dclk(i)
--    );
--   u_BUFMR_inst : BUFMR --# routing fail
--   port map (
--      O => sroic_dclk(i), -- 1-bit output: Clock output (connect to BUFIOs/BUFRs)
--      I => iroic_dclk(i)  -- 1-bit input: Clock input (Connect to IBUF)
--   );
--   u_BUFR_inst : BUFR
--   generic map (
--      BUFR_DIVIDE => "BYPASS",   -- Values: "BYPASS, 1, 2, 3, 4, 5, 6, 7, 8"
--      SIM_DEVICE => "7SERIES"  -- Must be set to "7SERIES"
--   )
--   port map (
--      O => sroic_dclk(i),     -- 1-bit output: Clock output port
--      CE => '1',   -- 1-bit input: Active high, clock enable (Divided modes only)
--      CLR => '0', -- CLR, -- 1-bit input: Active high, asynchronous clear (Divided modes only)
--      I => iroic_dclk(i)      -- 1-bit input: Clock buffer input driven by an IBUF, MMCM or local interconnect
--   );
        sroic_dclk(i) <= iroic_dclk(i);
    end generate clkn;

    clkm : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        rclk_ch(i) <= sroic_dclk(i/3); --### 3 pack clock group
    end generate clkm;

    sel <= "000" when (sdata_ch/3) = 0 else --# ch 012
           "001" when (sdata_ch/3) = 1 else --# ch 345
           "010" when (sdata_ch/3) = 2 else --# ch 678
           "011";

--##### 1 step mux #####
    notsel0 <= not sel(0);
    sel0    <= sel(0);

    BUFGCTRL_inst0 : BUFGCTRL
    generic map (
        INIT_OUT     => 0,        -- Initial value of BUFGCTRL output ($VALUES;)
        PRESELECT_I0 => TRUE, -- BUFGCTRL output uses I0 input ($VALUES;)
        PRESELECT_I1 => FALSE -- BUFGCTRL output uses I1 input ($VALUES;)
    )
    port map (
        O       => clk_mux_a,      -- 1-bit output: Clock output
        CE0     => '1',            -- 1-bit input: Clock enable input for I0
        CE1     => '1',            -- 1-bit input: Clock enable input for I1
        I0      => sroic_dclk(0),  -- 1-bit input: Primary clock
        I1      => sroic_dclk(1),  -- 1-bit input: Secondary clock
        IGNORE0 => '0',            -- 1-bit input: Clock ignore input for I0
        IGNORE1 => '0',            -- 1-bit input: Clock ignore input for I1
        S0      => notsel0,        -- 1-bit input: Clock select for I0
        S1      => sel0            -- 1-bit input: Clock select for I1
    );
    BUFGCTRL_inst1 : BUFGCTRL
    generic map (
        INIT_OUT     => 0,
        PRESELECT_I0 => TRUE,
        PRESELECT_I1 => FALSE
    )
    port map (
        O       => clk_mux_b,
        CE0     => '1',
        CE1     => '1',
        I0      => sroic_dclk(2),
        I1      => sroic_dclk(3),
        IGNORE0 => '0',
        IGNORE1 => '0',
        S0      => notsel0,
        S1      => sel0
    );

--##### 2 step mux #####
    notsel1 <= not sel(1);
    sel1    <= sel(1);

    BUFGCTRL_inst2 : BUFGCTRL
    generic map (
        INIT_OUT     => 0,
        PRESELECT_I0 => TRUE,
        PRESELECT_I1 => FALSE
    )
    port map (
        O       => rclk_sel,
        CE0     => '1',
        CE1     => '1',
        I0      => clk_mux_a,
        I1      => clk_mux_b,
        IGNORE0 => '0',
        IGNORE1 => '0',
        S0      => notsel1,
        S1      => sel1
    );
--#####################
end generate EXT4343R_dclk;

    --$ 260312 4343rd roic dclk
BIT_ALIGN : if(GNR_MODEL = "EXT4343RD" or GNR_MODEL = "EXT3643R") generate
    gen_bufr : for i in 0 to ROIC_DCLK_NUM(GNR_MODEL)-1 generate
        u_BUFR : BUFR
        generic map (
            BUFR_DIVIDE => "BYPASS"
        )
        port map (
            O   => sroic_dclk(i),
            I   => iroic_dclk(i),
            CE  => '1',
            CLR => '0'
        );
    end generate gen_bufr;

    gen_rclk : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        rclk_ch(i) <= sroic_dclk(i/3);
    end generate gen_rclk;

end generate BIT_ALIGN;

-- █ █▄░█ █▄░█ █▀▀ █▀█ ▄▄ █▀▀ █░░ █▄▀
-- █ █░▀█ █░▀█ ██▄ █▀▄ ░░ █▄▄ █▄▄ █░█ %clk
NO_BIT_ALIGN : if (BIT_ALIGN_MODEL = '0') generate
--    clkn : for i in 0 to ROIC_DCLK_NUM(GNR_MODEL) - 1 generate
--        u_BUFG_roic_clk : BUFG port map (
--        O => sroic_dclk(i),
--        I => iroic_dclk(i)
--        );
--    end generate clkn;

--    clkm : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
--      rclk_ch(i) <= sroic_dclk(0);
--    end generate clkm;

--    rclk_sel <= iroic_dclk(0);

    clkm : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
        rclk_ch(i) <= iroic_clk;
    end generate clkm;

    rclk_sel <= iroic_clk;
end generate NO_BIT_ALIGN;
--### ###

serdes : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate

-- █▀ █▀▀ █▀█ █▀▄ █▀▀ █▀
-- ▄█ ██▄ █▀▄ █▄▀ ██▄ ▄█ %ser
    U0_TI_ROIC_SERDES : TI_ROIC_SERDES
    generic map (
        geni => i
    )
    port map (
        iroic_clk  => rclk_ch(i),
        iroic_rstn => iroic_rstn,

        ireg_req_align => sreg_req_align_3d,

        idata_ser  => iroic_data(i),
        odata_par  => sdata_par(i),
        odata_val  => sdata_val(i),
        odata_diff => sdata_diff(i),
        odata_ff00 => sdata_ff00(i),

        ocntvalue => ocntvalue(i),  --# to vio, delay value from delaye2
        obitslipm => obitslipm(i),  --# to vio, bitslip toggle
        obitslipc => obitslipc(i),  --# to vio, bitslip counter
        oser_cnt  => oser_cnt(i),   --# to vio, every clock 0 to 11 count

        idly_ce  => idle_ce_or(i),  --# delay ctrl
        idly_rst => idle_rst_or(i), --# delay reset
        ibitslip => ibitslip_or(i), --# bit shift

        sroic_dvalid_3d => sroic_dvalid_3d --# to inside ila
    );

    idle_ce_or(i)  <= (sd_ser_dly(i));
    idle_rst_or(i) <= (sd_ser_rst(i));
    ibitslip_or(i) <= (sd_ser_bit(i));

    --# serdes ctrl 3width -> rising edge
    process (rclk_ch(i))
    begin
        if (rclk_ch(i)'event and rclk_ch(i) = '1') then
            ser_dly0(i) <= (vio_dly and vio_ch(i)) or sdly_ce_or(i);
            ser_dly1(i) <= ser_dly0(i);
            ser_dly2(i) <= ser_dly1(i);
            if ser_dly2(i) = '0' and ser_dly1(i) = '1' then
                sd_ser_dly(i) <= '1';
            else
                sd_ser_dly(i) <= '0';
            end if;

            ser_rst0(i) <= (vio_rst and vio_ch(i)) or sdly_rst_or(i);
            ser_rst1(i) <= ser_rst0(i);
            ser_rst2(i) <= ser_rst1(i);
            if ser_rst2(i) = '0' and ser_rst1(i) = '1' then
                sd_ser_rst(i) <= '1';
            else
                sd_ser_rst(i) <= '0';
            end if;

            ser_bit0(i) <= (vio_bit and vio_ch(i)) or sbitslip_or(i);
            ser_bit1(i) <= ser_bit0(i);
            ser_bit2(i) <= ser_bit1(i);
            if ser_bit2(i) = '0' and ser_bit1(i) = '1' then
                sd_ser_bit(i) <= '1';
            else
                sd_ser_bit(i) <= '0';
            end if;

            if (sroic_dvalidch_3d(i) = '1' and sdata_val(i) = '1') then
                vio_data(i) <= sdata_par(i)(23 downto 8);
            end if;

        end if;
    end process;

end generate serdes;

-- █▀ █▀▄▀█ ▄▄ ▄▀█ █░░ █ █▀▀ █▄░█ ▄▄ ▀█▀ █▀█ █▀█
-- ▄█ █░▀░█ ░░ █▀█ █▄▄ █ █▄█ █░▀█ ░░ ░█░ █▄█ █▀▀ %ch
--# align ctrl state machine (sync reset)
--    process (iroic_clk, iroic_rstn)
    process (isys_clk)
    begin
--        if(iroic_rstn = '0') then --# 260320 async->sync reset
--            state_align_ctrl <= s_IDLE;
--            sdata_ch         <= 0;
--            salign_done      <= '0';
--        elsif (iroic_clk'event and iroic_clk = '1') then
        if (isys_clk'event and isys_clk = '1') then
            if (iroic_rstn = '0') then
                state_align_ctrl <= s_IDLE;
                sdata_ch         <= 0;
                salign_done      <= '0';
            else
                state_align0 <= state_align;
                state_align1 <= state_align0;
                state_align2 <= state_align1; --# cdc 25092419
                case (state_align_ctrl) is
                    when s_IDLE =>
                        if (sreg_req_align_3d = '1') then
                            state_align_ctrl <= s_ALIGN;
                            sdata_ch         <= 0;
                            salign_done      <= '0';
                        end if;

                    when s_ALIGN =>
                        if (state_align2 = s_FINISH) then
                            if (sdata_ch = ROIC_NUM(GNR_MODEL)-1) then
                                state_align_ctrl <= s_CHECK;
                            else
                                state_align_ctrl <= s_WAIT;
                            end if;
                        end if;
                    when s_WAIT =>
                        if (state_align2 = s_IDLE) then
                            state_align_ctrl <= s_ALIGN;
                            if (sdata_ch < ROIC_NUM(GNR_MODEL)-1) then
                                sdata_ch <= sdata_ch + 1;
                            end if;
                        end if;

                    when s_CHECK =>
                        if (salign_success = ALL_HIGH) then
                            if (sreg_req_align_3d = '0') then
                                state_align_ctrl <= s_IDLE;
                            end if;
                            salign_done <= '1';
                        else
                            if (sreg_req_align_3d = '0') then
                                state_align_ctrl <= s_IDLE;
                            else
                                state_align_ctrl <= s_WAIT;
                            end if;
                            salign_done <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process;

--# alignment state machine (sync reset)
--    process (rclk_sel, iroic_rstn)
    process (isys_clk)
    begin
--        if(iroic_rstn = '0') then --# 260320 async->sync reset
--            state_align <= s_IDLE;
--            state_eye   <= s_EDGE1;
--            sdly_ce  <= (others => '0');
--            sdly_rst <= (others => '0');
--            sbitslip <= (others => '0');
--            stap_cnt  <= (others => '0');
--            swait_cnt <= (others => '0');
--            serr_cnt  <= (others => '0');
--            scurr_data <= (others => '0');
--            sprev_data <= (others => '0');
--            seye_start   <= (others => (others => '0'));
--            seye_end     <= (others => (others => '0'));
--            seye_mid     <= (others => (others => '0'));
--            seye_sum     <= (others => (others => '0'));
--            sbitslip_cnt <= (others => (others => '0'));
--            salign_success <= (others => '0');
--        elsif (rclk_sel'event and rclk_sel = '1') then
        if (isys_clk'event and isys_clk = '1') then
            if (iroic_rstn = '0') then
                state_align    <= s_IDLE;
                state_eye      <= s_EDGE1;
                sdly_ce        <= (others => '0');
                sdly_rst       <= (others => '0');
                sbitslip       <= (others => '0');
                stap_cnt       <= (others => '0');
                swait_cnt      <= (others => '0');
                serr_cnt       <= (others => '0');
                scurr_data     <= (others => '0');
                sprev_data     <= (others => '0');
                seye_start     <= (others => (others => '0'));
                seye_end       <= (others => (others => '0'));
                seye_mid       <= (others => (others => '0'));
                seye_sum       <= (others => (others => '0'));
                sbitslip_cnt   <= (others => (others => '0'));
                salign_success <= (others => '0');
            else

--          scurr_data_d0 <= sdata_par(sdata_ch);
--          scurr_data_d1 <= scurr_data_d0;
--          scurr_data_d2 <= scurr_data_d1;
                sdata_diff_ch0 <= sdata_diff(sdata_ch);
                sdata_diff_ch1 <= sdata_diff_ch0;
                sdata_diff_ch  <= sdata_diff_ch1;

                sdata_ff00_ch0 <= sdata_ff00(sdata_ch);
                sdata_ff00_ch1 <= sdata_ff00_ch0;
                sdata_ff00_ch  <= sdata_ff00_ch1;

                state_align_ctrl0 <= state_align_ctrl;
                state_align_ctrl1 <= state_align_ctrl0;
                state_align_ctrl2 <= state_align_ctrl1;

                sdly_ce2  <= sdly_ce1;  sdly_ce1  <= sdly_ce0;  sdly_ce0  <= sdly_ce;
                sdly_rst2 <= sdly_rst1; sdly_rst1 <= sdly_rst0; sdly_rst0 <= sdly_rst;
                sbitslip2 <= sbitslip1; sbitslip1 <= sbitslip0; sbitslip0 <= sbitslip;

                sdly_ce_or  <= sdly_ce2 or sdly_ce1 or sdly_ce0;
                sdly_rst_or <= sdly_rst2 or sdly_rst1 or sdly_rst0;
                sbitslip_or <= sbitslip2 or sbitslip1 or sbitslip0;

-- █▀ █▀▄▀█ ▄▄ ▄▀█ █░░ █ █▀▀ █▄░█ ▄▄ █▀▀ █░█
-- ▄█ █░▀░█ ░░ █▀█ █▄▄ █ █▄█ █░▀█ ░░ █▄▄ █▀█ %align
                case (state_align) is
                when s_IDLE =>
                    if (swait_cnt > 16) then --# reset delay #25092514 ch0 data0

                        if (state_align_ctrl2 = s_ALIGN) then
                            state_align <= s_RESET1;
                            state_eye   <= s_EDGE1;

                            if (sdata_ch = 0) then
                                salign_success <= (others => '0');
                                seye_start     <= (others => (others => '0'));
                                seye_end       <= (others => (others => '0'));
                                seye_mid       <= (others => (others => '0'));
                                seye_sum       <= (others => (others => '0'));
                            end if;
                        end if;

                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;
                    stap_cnt <= (others => '0');

                when s_RESET1 => -- Save Prev Data before changing tap delay
                    -- Tap Delay = 0
                    if (swait_cnt > 16) then --# reset delay
                        swait_cnt <= (others => '0');
                        if (sroic_dvalid_3d = '1') then
                            state_align        <= s_TAP_DELAY1;
                            sdly_rst(sdata_ch) <= '1';
--                            sprev_data         <= scurr_data_d2;
                            stap_cnt           <= (others => '0');
                        end if;
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;

                when s_TAP_DELAY1 => -- Save Prev Data before changing tap delay
                    -- Tap Delay + 1
--                    sprev_data_d0   <= scurr_data_d2;
--                    sprev_data_d1   <= sprev_data_d0;
                    if (swait_cnt > 64) then
                        if (sroic_dvalid_3d = '1') then
                            state_align       <= s_WAIT1;
                            sdly_ce(sdata_ch) <= '1';
--                            sprev_data        <= scurr_data_d2;
                            stap_cnt          <= stap_cnt + '1';
                            swait_cnt         <= (others => '0');
                            scurr_data        <= (others => '0');
                        end if;
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;
                    sdly_rst(sdata_ch) <= '0'; --# no all ctrl #25092511

                when s_WAIT1 =>
                    if (swait_cnt > 2**16) then --# 220610
                        if (sroic_dvalid_3d = '1') then
                            state_align <= s_CHECK;
--                            scurr_data  <= scurr_data_d2;
                            swait_cnt   <= (others => '0');
                        end if;
                    elsif (32 < swait_cnt) then
                        if (sroic_dvalid_3d = '1') then
--                            if scurr_data_d1 /= scurr_data_d0 then
                            if sdata_diff_ch = '1' then --# eye by sysclk 251215
                                state_align <= s_CHECK;
                                scurr_data  <= x"00AAFF";
                                swait_cnt   <= (others => '0');
                            else
                                swait_cnt <= swait_cnt + '1';
                            end if;
                        end if;
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;

                    sdly_ce <= (others => '0');

                when s_CHECK =>
                    -- Compare curr and prev data
                    if (stap_cnt >= stap_max - 1) then
                        state_align <= s_CALC1;

                        if (state_eye = s_EDGE1) then
                            seye_start(sdata_ch) <= (others => '0');
                            seye_end(sdata_ch)   <= "011111";
                        else
                            seye_end(sdata_ch) <= "011111";
                        end if;
                    else
                        case (state_eye) is
                            when s_EDGE1 =>
--                                if(scurr_data /= sprev_data) then
                                if (scurr_data = x"00AAFF") then
                                    if (stap_cnt > 15) then
                                        state_align          <= s_CALC1;
                                        state_eye            <= s_EDGE1;
                                        seye_start(sdata_ch) <= (others => '0');
                                        seye_end(sdata_ch)   <= stap_cnt;
                                    else
                                        state_align          <= s_TAP_DELAY1;
                                        state_eye            <= s_EDGE2;
                                        seye_start(sdata_ch) <= stap_cnt;
                                        serr_cnt             <= (others => '0');
                                    end if;
                                else
                                    state_align <= s_TAP_DELAY1;
                                end if;

                            when s_EDGE2 =>
--                                if(scurr_data /= sprev_data) then
                                if (scurr_data = x"00AAFF") then
                                    if (serr_cnt > 6) then
                                        state_eye          <= s_EDGE1;
                                        state_align        <= s_CALC1;
                                        seye_end(sdata_ch) <= stap_cnt;
                                    else
                                        state_align <= s_TAP_DELAY1;
                                        serr_cnt    <= serr_cnt + 1;
                                    end if;
                                else
                                    state_align <= s_TAP_DELAY1;
                                    serr_cnt    <= serr_cnt + 1;
                                end if;
                        end case;
                    end if;

                when s_CALC1 =>
                    state_align        <= s_CALC2;
                    seye_sum(sdata_ch) <= seye_start(sdata_ch) + seye_end(sdata_ch);
                when s_CALC2 =>
                    state_align        <= s_RESET2;
                    seye_mid(sdata_ch) <= ('0' & seye_sum(sdata_ch)(5 downto 1));
                when s_RESET2 =>
                    state_align        <= s_WAIT2;
                    sdly_rst(sdata_ch) <= '1';
                    stap_cnt           <= (others => '0');
                when s_TAP_DELAY2 =>
                    state_align        <= s_WAIT2;
                    sdly_ce(sdata_ch)  <= '1';
                    stap_cnt           <= stap_cnt + '1';

                when s_WAIT2 =>
                    if (swait_cnt = 31) then
                        if (stap_cnt = seye_mid(sdata_ch)) then
                            state_align <= s_CHECK2;
                        else
                            state_align <= s_TAP_DELAY2;
                        end if;
                        swait_cnt <= (others => '0');
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;

                    sdly_ce(sdata_ch)  <= '0';
                    sdly_rst(sdata_ch) <= '0';

                when s_BITSLIP =>
                    state_align            <= s_CHECK2;
                    sbitslip(sdata_ch)     <= '1';
                    sbitslip_cnt(sdata_ch) <= sbitslip_cnt(sdata_ch) + '1';
                when s_CHECK2 =>
                    if (swait_cnt = 31) then
                        if (sroic_dvalid_3d = '1') then
                            swait_cnt <= (others => '0');
                            if (sbitslip_cnt(sdata_ch) = 24*4-1) then --# 4 cycle for FFF000
                                state_align              <= s_FINISH;
                                salign_success(sdata_ch) <= '0';
                                sbitslip_cnt(sdata_ch)   <= (others => '0');
                            else
--                                if(scurr_data_d2 = strain_word) then
                                if (sdata_ff00_ch = '1') then --### FFF000 compare by 1bit #25121520
                                    state_align              <= s_FINISH;
                                    salign_success(sdata_ch) <= '1';
                                else
                                    state_align <= s_BITSLIP;
                                end if;
                            end if;
                        end if;
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;
                    sbitslip <= (others => '0');

                when s_FINISH =>
                    if (swait_cnt = 2) then
                        swait_cnt   <= (others => '0');
                        state_align <= s_IDLE;
                    else
                        swait_cnt <= swait_cnt + '1';
                    end if;
                end case;

            end if;
        end if;
    end process;

-- █▀ █▀▄▀█ ▄▄ █░█ ▄▀█ █░░ █ █▀▄
-- ▄█ █░▀░█ ░░ ▀▄▀ █▀█ █▄▄ █ █▄▀ %valid
data_en : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
    --# data valid state machine (sync reset)
    process (rclk_ch(i))
    begin
        if (rclk_ch(i)'event and rclk_ch(i) = '1') then
            if (iroic_rstn = '0') then
                state_dvalid(i) <= s_IDLE;
                sdvalid(i)      <= '0';
                shcnt(i)        <= (others => '0');
                svcnt(i)        <= (others => '0');
                svcnt_all(i)    <= '0';
            else
            --
                sroic_dvalidch_1d(i) <= sroic_dvalid_3d;
                sroic_dvalidch_2d(i) <= sroic_dvalidch_1d(i);
                sroic_dvalidch_3d(i) <= sroic_dvalidch_2d(i);

                case (state_dvalid(i)) is
                    when s_IDLE =>
                        if (sroic_dvalidch_3d(i) = '0') then
                            state_dvalid(i) <= s_READY;
                        end if;
                    when s_READY =>
                        if (sroic_dvalidch_3d(i) = '1') then
                            state_dvalid(i) <= s_START;
                            svcnt(i)        <= (others => '0'); -- 210331 mbh
                            shcnt(i)        <= (others => '0'); -- 210331 mbh
                        end if;
                    when s_START =>
                     -- if(sdvalid(i) = '1') then --# indivi dvalid #250922
                        if (sdvalid = ALL_HIGH) then --# stric
                            state_dvalid(i) <= s_VALID;
                        end if;

                        if (sdata_par(i)(7) = '1') then
                            sdvalid(i) <= '1';
                        end if;

                    when s_VALID =>
                        if (svcnt_all(i) = '1') then --# indivi dvalid #250922
                     -- if(svcnt_all = ALL_HIGH) then --# strict
                            state_dvalid(i) <= s_IDLE;
                            svcnt_all(i)    <= '0';
                        else
                            if (sdata_val(i) = '1') then
                                if (shcnt(i) >= ROIC_MAX_CH(GNR_MODEL) - 1) then
--                                  if(svcnt(i) >= sreg_height_3d - ROIC_DUAL_BY_MODEL(GNR_MODEL)) then
--                                  if(svcnt(i) >= ireg_height - ROIC_DUAL_BY_MODEL(GNR_MODEL)) then
                                    if (svcnt(i) >= sreg_height_2d - ROIC_DUAL_BY_MODEL(GNR_MODEL)) then
                                        svcnt_all(i) <= '1';
                                        svcnt(i)     <= (others => '0');
                                        sdvalid(i)   <= '0';
                                    else
                                        svcnt(i) <= svcnt(i) + ROIC_DUAL_BY_MODEL(GNR_MODEL);
                                    end if;
                                    shcnt(i) <= (others => '0');
                                else
                                    shcnt(i) <= shcnt(i) + '1';
                                end if;
                            end if;
                        end if;

                    when others => NULL;
                end case;
            --
            end if;
        end if;
    end process;
end generate data_en;

-- █▀█ █░█ ▀█▀
-- █▄█ █▄█ ░█░ %out
data_out : for i in 0 to ROIC_NUM(GNR_MODEL) - 1 generate
    --# data output latch (sync reset)
    process (rclk_ch(i))
    begin
        if (rclk_ch(i)'event and rclk_ch(i) = '1') then
            if (iroic_rstn = '0') then
                sen_array(i)   <= '0'; --# (others => '0');
                sdata_array(i) <= (others => '0');
            else
            --
                if sreg_roicbcal_pass = '1' then
                    sen_array(i)   <= sdata_val(i);
                    sdata_array(i) <= sdata_par(i)(23 downto 8);
                elsif (sdvalid(i) = '1') then
                    sen_array(i)   <= sdata_val(i);
                    sdata_array(i) <= sdata_par(i)(23 downto 8);
                else
                    sen_array(i) <= '0';
                end if;
            --
            end if;
        end if;
    end process;
end generate data_out;

--### osdata type mapping ### --# 231117
gen_out : for i in 0 to ROIC_NUM(GNR_MODEL)-1 generate
    odata_array((i+1)*16-1 downto i*16) <= sdata_array(i);
    oroic_clk_sel(i) <= rclk_ch(i);
end generate gen_out;

    oen_array   <= sen_array;
    oalign_done <= salign_done;
    ovcnt       <= svcnt(0);

-- █▀ █░█ █▀▀ ▀█▀
-- ▄█ █▀█ █▀░ ░█░ %shft
--# req_align shift register (sync reset)
    process (iroic_clk)
    begin
        if (iroic_clk'event and iroic_clk = '1') then
            if (iroic_rstn = '0') then
                sreg_req_align_1d <= '0';
                sreg_req_align_2d <= '0';
                sreg_req_align_3d <= '0';
            else
                sreg_req_align_1d <= ireg_req_align;
                sreg_req_align_2d <= sreg_req_align_1d;
                sreg_req_align_3d <= sreg_req_align_2d;
            end if;
        end if;
    end process;

--# dvalid/height shift register (sync reset)
--    process (rclk_sel, iroic_rstn)
    process (iroic_clk)
    begin
        if (iroic_clk'event and iroic_clk = '1') then
            if (iroic_rstn = '0') then
                sroic_dvalid_1d <= '0';
                sroic_dvalid_2d <= '0';
                sroic_dvalid_3d <= '0';
                sreg_height_1d  <= (others => '0');
                sreg_height_2d  <= (others => '0');
                sreg_height_3d  <= (others => '0');
--        elsif (rclk_sel'event and rclk_sel = '1') then
            else
            --
                sroic_dvalid_1d <= iroic_dvalid;
                sroic_dvalid_2d <= sroic_dvalid_1d and roic_dvalid_fcut; --# dvalid fcut 25092416
                sroic_dvalid_3d <= sroic_dvalid_2d;
                sreg_height_1d  <= ireg_height;
                sreg_height_2d  <= sreg_height_1d;

                --### dvalid front cut ###
                if sroic_dvalid_1d = '1' then
                    if dvalid_high_cnt < 127 then
                        dvalid_high_cnt <= dvalid_high_cnt + '1';
                    end if;
                else
                    dvalid_high_cnt <= (others => '0');
                end if;

                if 100 < dvalid_high_cnt then
                    roic_dvalid_fcut <= '1';
                else
                    roic_dvalid_fcut <= '0';
                end if;

                if svcnt(0) = 0 then -- v rotation bug point, mbh 210203
                    sreg_height_3d <= sreg_height_2d;
                end if;
            --
            end if;
        end if;
    end process;

-- █▀▀ █▄█ █▀▀
-- ██▄ ░█░ ██▄ %eye
--# eye data / bcal register
    process (iroic_clk)
    begin
        if (iroic_clk'event and iroic_clk = '1') then
        --
            ireg_bcal_ctrl_1d  <= ireg_bcal_ctrl;
            ireg_bcal_ctrl_2d  <= ireg_bcal_ctrl_1d;
            sreg_bcal_ctrl     <= ireg_bcal_ctrl_2d;
            sreg_roicbcal_pass <= sreg_bcal_ctrl(8);
            for i in 0 to ROIC_NUM(GNR_MODEL)-1 loop
                sreg_bcal_data_array(i) <= b"0000_000" & salign_success(i) &
                                           b"00" & seye_end(i) &
                                           b"00" & seye_mid(i) &
                                           b"00" & seye_start(i);
            end loop;
            oreg_bcal_data <= sreg_bcal_data_array(conv_integer(sreg_bcal_ctrl(8-1 downto 0)));
        --
        end if;
    end process;

-- █▀▄ █▄▄ █▀▀
-- █▄▀ █▄█ █▄█ %dbg 4343r vio
ILA_DEBUG : if(GEN_ILA_lvds_rx = "ON") generate
    COMPONENT vio_serdes_ctrl
    PORT (
        clk        : IN STD_LOGIC;
        probe_in0  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in1  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in2  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in3  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in4  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in5  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in6  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in7  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in8  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in9  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in10 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in11 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe_in12 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in13 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in14 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in15 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in16 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in17 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in18 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in19 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in20 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in21 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in22 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in23 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in24 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in25 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in26 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in27 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in28 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in29 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in30 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in31 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in32 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in33 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in34 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in35 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in36 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in37 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in38 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in39 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in40 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in41 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in42 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in43 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in44 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in45 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in46 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_in47 : IN STD_LOGIC_VECTOR( 4 DOWNTO 0);
        probe_out0 : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
        probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe_out4 : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
    );
    END COMPONENT;
begin
    u_vio_serdes_ctrl : vio_serdes_ctrl
    PORT MAP (
        clk        => iroic_clk,
        probe_in0  => vio_data(0),
        probe_in1  => vio_data(1),
        probe_in2  => vio_data(2),
        probe_in3  => vio_data(3),
        probe_in4  => vio_data(4),
        probe_in5  => vio_data(5),
        probe_in6  => vio_data(6),
        probe_in7  => vio_data(7),
        probe_in8  => vio_data(8),
        probe_in9  => vio_data(9),
        probe_in10 => vio_data(10),
        probe_in11 => vio_data(11),
        probe_in12 => ocntvalue(0),
        probe_in13 => ocntvalue(1),
        probe_in14 => ocntvalue(2),
        probe_in15 => ocntvalue(3),
        probe_in16 => ocntvalue(4),
        probe_in17 => ocntvalue(5),
        probe_in18 => ocntvalue(6),
        probe_in19 => ocntvalue(7),
        probe_in20 => ocntvalue(8),
        probe_in21 => ocntvalue(9),
        probe_in22 => ocntvalue(10),
        probe_in23 => ocntvalue(11),
        probe_in24 => oser_cnt(0),
        probe_in25 => oser_cnt(1),
        probe_in26 => oser_cnt(2),
        probe_in27 => oser_cnt(3),
        probe_in28 => oser_cnt(4),
        probe_in29 => oser_cnt(5),
        probe_in30 => oser_cnt(6),
        probe_in31 => oser_cnt(7),
        probe_in32 => oser_cnt(8),
        probe_in33 => oser_cnt(9),
        probe_in34 => oser_cnt(10),
        probe_in35 => oser_cnt(11),
        probe_in36 => obitslipc(0),
        probe_in37 => obitslipc(1),
        probe_in38 => obitslipc(2),
        probe_in39 => obitslipc(3),
        probe_in40 => obitslipc(4),
        probe_in41 => obitslipc(5),
        probe_in42 => obitslipc(6),
        probe_in43 => obitslipc(7),
        probe_in44 => obitslipc(8),
        probe_in45 => obitslipc(9),
        probe_in46 => obitslipc(10),
        probe_in47 => obitslipc(11),

        probe_out0    => vio_ch,
        probe_out1(0) => vio_dly,
        probe_out2(0) => vio_rst,
        probe_out3(0) => vio_bit,
        probe_out4    => vio_clk_inv
    );
--    process (iroic_clk, iroic_rstn)
--    begin
--        if (iroic_clk'event and iroic_clk = '1') then
--             FreeRunCnt <= FreeRunCnt + '1';
--        end if;
--    end process;
end generate;

ILA_LVDS_RX_DEBUG : if(GEN_ILA_lvds_rx_2 = "ON") generate
    COMPONENT ILA_LVDS_RX
    PORT (
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- idata_ser
        probe1  : IN STD_LOGIC_VECTOR(23 DOWNTO 0);   -- odata_par
        probe2  : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- odata_val
        probe3  : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- odata_diff
        probe4  : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- odata_ff00
        probe5  : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- obitslipm
        probe6  : IN STD_LOGIC_VECTOR(4  DOWNTO 0);   -- obitslipc
        probe7  : IN STD_LOGIC_VECTOR(4  DOWNTO 0);   -- ocntvalue
        probe8  : IN STD_LOGIC_VECTOR(4  DOWNTO 0);   -- oser_cnt
        probe9  : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- ireg_req_align
        probe10 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- idly_ce
        probe11 : IN STD_LOGIC_VECTOR(0  DOWNTO 0);   -- idly_rst
        probe12 : IN STD_LOGIC_VECTOR(0  DOWNTO 0)    -- ibitslip
    );
    END COMPONENT;
begin
    U0_ILA_LVDS_RX : ILA_LVDS_RX
    PORT MAP (
        clk        => isys_clk,
        probe0(0)  => iroic_data(0),
        probe1     => sdata_par(0),
        probe2(0)  => sdata_val(0),
        probe3(0)  => sdata_diff(0),
        probe4(0)  => sdata_ff00(0),
        probe5(0)  => obitslipm(0),
        probe6     => obitslipc(0),
        probe7     => ocntvalue(0),
        probe8     => oser_cnt(0),
        probe9(0)  => sreg_req_align_3d,
        probe10(0) => sd_ser_dly(0),
        probe11(0) => sd_ser_rst(0),
        probe12(0) => sd_ser_bit(0)
    );
end generate;

end architecture behavioral;
