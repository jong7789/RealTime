----------------------------------------------------------------------------------
-- Company: DRT
-- Engineer: MBH
-- Create Date: 2021/09/03 10:15:13
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity DNR is
    port (
        i_clk            : in    std_logic;
        i_RegHActive     : in    std_logic_vector(12 - 1 downto 0);
        i_RegVActive     : in    std_logic_vector(12 - 1 downto 0);
        i_RegDnrCtrl     : in    std_logic_vector(16 - 1 downto 0);
        i_RegSobelCoeff0 : in    std_logic_vector(16 - 1 downto 0);
        i_RegSobelCoeff1 : in    std_logic_vector(16 - 1 downto 0);
        i_RegSobelCoeff2 : in    std_logic_vector(16 - 1 downto 0);
        i_RegBlurOffset  : in    std_logic_vector(16 - 1 downto 0);

        i_hsyn : in    std_logic;
        i_vsyn : in    std_logic;
        i_hcnt : in    std_logic_vector(12 - 1 downto 0);
        i_vcnt : in    std_logic_vector(12 - 1 downto 0);
        i_data : in    std_logic_vector(16 - 1 downto 0);

        o_hsyn : out   std_logic;
        o_vsyn : out   std_logic;
        o_hcnt : out   std_logic_vector(12 - 1 downto 0);
        o_vcnt : out   std_logic_vector(12 - 1 downto 0);
        o_data : out   std_logic_vector(16 - 1 downto 0)
    );
end entity dnr;

architecture behavioral of dnr is

    component Mawari5x5 is
        port (
            i_clk        : in    std_logic;
            i_RegHActive : in    std_logic_vector(12 - 1 downto 0);
            i_RegVActive : in    std_logic_vector(12 - 1 downto 0);

            i_hsyn : in    std_logic;
            i_vsyn : in    std_logic;
            i_hcnt : in    std_logic_vector(12 - 1 downto 0);
            i_vcnt : in    std_logic_vector(12 - 1 downto 0);
            i_data : in    std_logic_vector(16 - 1 downto 0);

            o_hsyn : out   std_logic;
            o_vsyn : out   std_logic;
            o_hcnt : out   std_logic_vector(12 - 1 downto 0);
            o_vcnt : out   std_logic_vector(12 - 1 downto 0);
            o_data : out   std_logic_vector(16 * 25 - 1 downto 0)
        );
    end component mawari5x5;

    component blk_432b32
        port (
            clka  : in    std_logic;
            wea   : in    std_logic_vector(0 downto 0);
            addra : in    std_logic_vector(4 downto 0);
            dina  : in    std_logic_vector(431 downto 0);
            clkb  : in    std_logic;
            addrb : in    std_logic_vector(4 downto 0);
            doutb : out   std_logic_vector(431 downto 0)
        );
    end component;

    component matrix5x5 is
        port (
            i_clk  : in    std_logic;
            i_Coef : in    std_logic_vector(16 * 25 - 1 downto 0);

            i_hsyn : in    std_logic;
            i_vsyn : in    std_logic;
            i_hcnt : in    std_logic_vector(12 - 1 downto 0);
            i_vcnt : in    std_logic_vector(12 - 1 downto 0);
            i_data : in    std_logic_vector(16 * 25 - 1 downto 0);

            o_hsyn : out   std_logic;
            o_vsyn : out   std_logic;
            o_hcnt : out   std_logic_vector(12 - 1 downto 0);
            o_vcnt : out   std_logic_vector(12 - 1 downto 0);
            o_data : out   std_logic_vector(17 - 1 downto 0)
        );
    end component matrix5x5;

    component mult_s17xs17zs34
        port (
            CLK : in    std_logic;
            A   : in    std_logic_vector(16 downto 0);
            B   : in    std_logic_vector(16 downto 0);
            CE  : in    std_logic;
            P   : out   std_logic_vector(33 downto 0)
        );
    end component;

    component add_s34ADDs34zs35
        port (
            A   : in    std_logic_vector(33 downto 0);
            B   : in    std_logic_vector(33 downto 0);
            CLK : in    std_logic;
            CE  : in    std_logic;
            S   : out   std_logic_vector(34 downto 0)
        );
    end component;

    component Root_u35zu24
        port (
            aclk                    : in    std_logic;
            s_axis_cartesian_tvalid : in    std_logic;
            s_axis_cartesian_tdata  : in    std_logic_vector(39 downto 0);
            m_axis_dout_tvalid      : out   std_logic;
            m_axis_dout_tdata       : out   std_logic_vector(23 downto 0)
        );
    end component;

    component add_U16PlusU16zU17
        port (
            A   : in    std_logic_vector(15 downto 0);
            B   : in    std_logic_vector(15 downto 0);
            CLK : in    std_logic;
            S   : out   std_logic_vector(16 downto 0)
        );
    end component;

  -- !const
    constant Mawari_delay : integer := 25;
    constant arrLength    : integer := 18;

    signal clk : std_logic;

    type   type_reg16b is array (3 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    signal regDnrCtrl_arr     : type_reg16b;
    signal regSobelCoeff0_arr : type_reg16b;
    signal regSobelCoeff1_arr : type_reg16b;
    signal regSobelCoeff2_arr : type_reg16b;
    signal regBlurOffset_arr  : type_reg16b;
    signal regSobelCoeff0     : std_logic_vector(16 - 1 downto 0);
    signal regSobelCoeff1     : std_logic_vector(16 - 1 downto 0);
    signal regSobelCoeff2     : std_logic_vector(16 - 1 downto 0);
    signal regBlurOffset      : std_logic_vector(16 - 1 downto 0);
    signal regDnrCtrl         : std_logic_vector(16 - 1 downto 0);
    signal regDnrCtrl0        : std_logic_vector(16 - 1 downto 0);
    signal regDnrCtrl1        : std_logic_vector(16 - 1 downto 0);

    signal iMawari_hsyn : std_logic;
    signal iMawari_vsyn : std_logic;
    signal iMawari_hcnt : std_logic_vector(12 - 1 downto 0);
    signal iMawari_vcnt : std_logic_vector(12 - 1 downto 0);
    signal iMawari_data : std_logic_vector(16 - 1 downto 0);

    signal Mawari_hsyn : std_logic;
    signal Mawari_vsyn : std_logic;
    signal Mawari_hcnt : std_logic_vector(12 - 1 downto 0);
    signal Mawari_vcnt : std_logic_vector(12 - 1 downto 0);
    signal Mawari_data : std_logic_vector(16 * 25 - 1 downto 0);

    signal mw_addra : std_logic_vector(  5 - 1 downto 0) := (others=> '0');
    signal mw_dina  : std_logic_vector(432 - 1 downto 0) := (others=> '0');
    signal mw_addrb : std_logic_vector(  5 - 1 downto 0) := (others=> '0');
    signal mw_doutb : std_logic_vector(432 - 1 downto 0) := (others=> '0');

    type   type_coef_arr is array (25 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    signal RegCoeffRL_arr : type_coef_arr;
    signal RegCoeffUD_arr : type_coef_arr;
    signal RegCoeffRL     : std_logic_vector(16 * 25 - 1 downto 0);
    signal RegCoeffUD     : std_logic_vector(16 * 25 - 1 downto 0);

    signal MatrixRL_hsyn : std_logic;
    signal MatrixRL_vsyn : std_logic;
    signal MatrixRL_hcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixRL_vcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixRL_data : std_logic_vector(17 - 1 downto 0); -- signed 17b

    signal MatrixUD_hsyn : std_logic;
    signal MatrixUD_vsyn : std_logic;
    signal MatrixUD_hcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixUD_vcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixUD_data : std_logic_vector(17 - 1 downto 0); -- signed 17b

    type type_syn_shf is array (arrLength downto 0) of std_logic;

    type type_cnt_shf is array (arrLength downto 0) of std_logic_vector(12 - 1 downto 0);

    signal Sob_hsyn_shf  : type_syn_shf;
    signal Sob_vsyn_shf  : type_syn_shf;
    signal Sob_hcnt_shf  : type_cnt_shf;
    signal Sob_vcnt_shf  : type_cnt_shf;
    signal Sob_datA_shf0 : std_logic_vector(17 - 1 downto 0);
    signal Sob_datB_shf0 : std_logic_vector(17 - 1 downto 0);

    signal Sob_da2A_shf1 : std_logic_vector(34 - 1 downto 0);
    signal Sob_da2B_shf1 : std_logic_vector(34 - 1 downto 0);

    signal Sob_dSum_shf2  : std_logic_vector(35 - 1 downto 0);
    signal Sob_root_shf11 : std_logic_vector(24 - 1 downto 0);
    signal Sob_cut_shf12  : std_logic_vector(16 - 1 downto 0);

    signal   Sob_root_valid         : std_logic;
    signal   s_axis_cartesian_tdata : std_logic_vector(40 - 1 downto 0):=(others=> '0');
    constant ZERO40                 : std_logic_vector(40 - 1 downto 0) :=(others=> '0');

    signal BlurOffset13     : std_logic_vector(17 - 1 downto 0) := (others=>'0');
    signal BlurOffsetCut14  : std_logic_vector(16 - 1 downto 0) := (others=>'0');
    signal CoefBlur15centr  : std_logic_vector(16 - 1 downto 0) := (others=>'0');
    signal CoefBlur15other  : std_logic_vector(16 - 1 downto 0) := (others=>'0');
    signal CoefBlur16centr  : std_logic_vector(16 - 1 downto 0) := (others=>'0');
    signal CoefBlur16otherA : std_logic_vector(17 - 1 downto 0) := (others=>'0');
    signal CoefBlur16otherB : std_logic_vector(17 - 1 downto 0) := (others=>'0');
    signal CoefBlur16other  : std_logic_vector(17 - 1 downto 0) := (others=>'0');
    signal CoefBlur17       : type_coef_arr;
    signal mw_CoefBlur17    : std_logic_vector(16 * 25 - 1 downto 0);

    signal MatrixBr_hsyn : std_logic;
    signal MatrixBr_vsyn : std_logic;
    signal MatrixBr_hcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixBr_vcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixBr_data : std_logic_vector(17 - 1 downto 0); -- signed 17b

    signal MatrixBrCut_hsyn : std_logic;
    signal MatrixBrCut_vsyn : std_logic;
    signal MatrixBrCut_hcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixBrCut_vcnt : std_logic_vector(12 - 1 downto 0);
    signal MatrixBrCut_data : std_logic_vector(16 - 1 downto 0);

    -- signal RegEdgeEn : std_logic;
    -- signal RegDnrEn  : std_logic;
--    signal sm_Sel   : std_logic_vector(4 - 1 downto 0)  := (others=>'0');
    signal sm_Sel   : std_logic_vector(4 - 1 downto 0)  := x"1"; --# init routine for sel #231212 
    signal VideoSel : std_logic_vector(4 - 1 downto 0):= (others=>'0');

    signal hsynSel : std_logic;
    signal vsynSel : std_logic;
    signal hcntSel : std_logic_vector(12 - 1 downto 0);
    signal vcntSel : std_logic_vector(12 - 1 downto 0);
    signal dataSel : std_logic_vector(16 - 1 downto 0);

COMPONENT ila_dnr_vsync
PORT (
	clk : IN STD_LOGIC;
	probe0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
	probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
);
END COMPONENT  ;

-- !begin

begin
    clk <= i_clk;

    process (clk)
    begin
        if clk'event and clk='1' then
      --
            regDnrCtrl_arr     <= regDnrCtrl_arr(regDnrCtrl_arr'high -1 downto 0) & i_regDnrCtrl;
            regSobelCoeff0_arr <= regSobelCoeff0_arr(regSobelCoeff0_arr'high -1 downto 0) & i_regSobelCoeff0;
            regSobelCoeff1_arr <= regSobelCoeff1_arr(regSobelCoeff1_arr'high -1 downto 0) & i_regSobelCoeff1;
            regSobelCoeff2_arr <= regSobelCoeff2_arr(regSobelCoeff2_arr'high -1 downto 0) & i_regSobelCoeff2;
            regBlurOffset_arr  <= regBlurOffset_arr (regBlurOffset_arr'high  -1 downto 0) & i_regBlurOffset;

            regDnrCtrl     <= regDnrCtrl_arr(regDnrCtrl_arr'high);
            regSobelCoeff0 <= regSobelCoeff0_arr(regSobelCoeff0_arr'high);
            regSobelCoeff1 <= regSobelCoeff1_arr(regSobelCoeff1_arr'high);
            regSobelCoeff2 <= regSobelCoeff2_arr(regSobelCoeff2_arr'high);
            regBlurOffset  <= regBlurOffset_arr (regBlurOffset_arr'high);

            if regDnrCtrl = 0 then
                iMawari_hsyn <= '0';
                iMawari_vsyn <= '0';
                iMawari_hcnt <= (others=> '0');
                iMawari_vcnt <= (others=> '0');
                iMawari_data <= (others=> '0');
            else
                iMawari_hsyn <= i_hsyn;
                iMawari_vsyn <= i_vsyn;
                iMawari_hcnt <= i_hcnt;
                iMawari_vcnt <= i_vcnt;
                iMawari_data <= i_data;
            end if;
      --
        end if;
    end process;

    u_mawari : Mawari5x5
        port map (
            i_clk        => clk,
            i_RegHActive => i_RegHActive,
            i_RegVActive => i_RegVActive,

            i_hsyn => iMawari_hsyn,
            i_vsyn => iMawari_vsyn,
            i_hcnt => iMawari_hcnt,
            i_vcnt => iMawari_vcnt,
            i_data => iMawari_data,

            o_hsyn => Mawari_hsyn,
            o_vsyn => Mawari_vsyn,
            o_hcnt => Mawari_hcnt,
            o_vcnt => Mawari_vcnt,
            o_data => Mawari_data
        );

    process (clk)
    begin
        if clk'event and clk='1' then
      --
            mw_addra <= mw_addra + '1';
            if mw_addra = Mawari_delay - 1 then
                mw_addrb <= (others => '0');
            else
                mw_addrb <= mw_addrb + '1';
            end if;
      --
        end if;
    end process;

    mw_dina <= b"00_0000"  & -- 432 <= 6 + 1 + 1 + 12 + 12 + 400;
               Mawari_hsyn &
               Mawari_vsyn &
               Mawari_hcnt &
               Mawari_vcnt &
               Mawari_data;

    u_mawari_delay : blk_432b32
        port map (
            clka   => clk,
            wea(0) => '1',
            addra  => mw_addra,
            dina   => mw_dina,
            clkb   => clk,
            addrb  => mw_addrb,
            doutb  => mw_doutb
        );

-- ____ ___  ____ ____    ____ ____ ____
-- |___ |  \ | __ |___    |    |  | |___
-- |___ |__/ |__] |___    |___ |__| |___
-- !edge coe

    gen_coef_5 : for ii in 0 to 5 - 1 generate

        process (clk)
        begin
            if clk'event and clk='1' then
      --
      -- 12b=1 // x"1000"=1 // x"f000"=-1
                RegCoeffRL_arr(ii * 5 + 0) <= regSobelCoeff2;             --  x"f000"; --
                RegCoeffRL_arr(ii * 5 + 1) <= regSobelCoeff1;             --  x"e000"; --
                RegCoeffRL_arr(ii * 5 + 2) <= regSobelCoeff0;             --  x"0000"; --
                RegCoeffRL_arr(ii * 5 + 3) <= (not regSobelCoeff1) + '1'; --  x"2000"; --
                RegCoeffRL_arr(ii * 5 + 4) <= (not regSobelCoeff2) + '1'; --  x"1000"; --

                RegCoeffUD_arr(ii + 5 * 0) <= regSobelCoeff2;             -- x"f000"; --
                RegCoeffUD_arr(ii + 5 * 1) <= regSobelCoeff1;             -- x"e000"; --
                RegCoeffUD_arr(ii + 5 * 2) <= regSobelCoeff0;             -- x"0000"; --
                RegCoeffUD_arr(ii + 5 * 3) <= (not regSobelCoeff1) + '1'; -- x"2000"; --
                RegCoeffUD_arr(ii + 5 * 4) <= (not regSobelCoeff2) + '1'; -- x"1000"; --
    --
            end if;
        end process;

    end generate gen_coef_5;

    gen_coef_25 : for ii in 0 to 25 - 1 generate

        process (clk)
        begin
            if clk'event and clk='1' then
    --
                RegCoeffRL((ii + 1) * 16 - 1 downto ii * 16) <= RegCoeffRL_arr(ii);
                RegCoeffUD((ii + 1) * 16 - 1 downto ii * 16) <= RegCoeffUD_arr(ii);
    --
            end if;
        end process;

    end generate gen_coef_25;

-- ____ ___  ____ ____    _  _ ____ ___ ____ _ _  _
-- |___ |  \ | __ |___    |\/| |__|  |  |__/ |  \/
-- |___ |__/ |__] |___    |  | |  |  |  |  \ | _/\_
-- !edge matrix
    u_MatrixRL : Matrix5x5
        port map (
            i_clk  => clk,
            i_Coef => RegCoeffRL,

            i_hsyn => Mawari_hsyn,
            i_vsyn => Mawari_vsyn,
            i_hcnt => Mawari_hcnt,
            i_vcnt => Mawari_vcnt,
            i_data => Mawari_data,

            o_hsyn => MatrixRL_hsyn,
            o_vsyn => MatrixRL_vsyn,
            o_hcnt => MatrixRL_hcnt,
            o_vcnt => MatrixRL_vcnt,
            o_data => MatrixRL_data
        );

    u_MatrixUD : Matrix5x5
        port map (
            i_clk  => clk,
            i_Coef => RegCoeffUD,

            i_hsyn => Mawari_hsyn,
            i_vsyn => Mawari_vsyn,
            i_hcnt => Mawari_hcnt,
            i_vcnt => Mawari_vcnt,
            i_data => Mawari_data,

            o_hsyn => MatrixUD_hsyn,
            o_vsyn => MatrixUD_vsyn,
            o_hcnt => MatrixUD_hcnt,
            o_vcnt => MatrixUD_vcnt,
            o_data => MatrixUD_data
        );

  -- ##############
  -- ### phase0 ###
  -- # sobel square sum root
    process (clk)
    begin
        if clk'event and clk='1' then
    --
            Sob_hsyn_shf  <= Sob_hsyn_shf(Sob_hsyn_shf'high - 1 downto 0) & MatrixRL_hsyn;
            Sob_vsyn_shf  <= Sob_vsyn_shf(Sob_vsyn_shf'high - 1 downto 0) & MatrixRL_vsyn;
            Sob_hcnt_shf  <= Sob_hcnt_shf(Sob_hcnt_shf'high - 1 downto 0) & MatrixRL_hcnt;
            Sob_vcnt_shf  <= Sob_vcnt_shf(Sob_vcnt_shf'high - 1 downto 0) & MatrixRL_vcnt;
            Sob_datA_shf0 <= MatrixRL_data;
            Sob_datB_shf0 <= MatrixUD_data;
    --
        end if;
    end process;

  -- ###################
  -- ### phase1 <= 0 ###
  -- # sobel square sum root
    multA : mult_s17xs17zs34
        port map (
            CLK => clk,
            A   => Sob_datA_shf0,
            B   => Sob_datA_shf0,
            CE  => Sob_hsyn_shf(0),
            P   => Sob_da2A_shf1
        );
    multB : mult_s17xs17zs34
        port map (
            CLK => clk,
            A   => Sob_datB_shf0,
            B   => Sob_datB_shf0,
            CE  => Sob_hsyn_shf(0),
            P   => Sob_da2B_shf1
        );

  -- ###################
  -- ### phase2 <= 1 ###
  -- ### sobel square sum root
    sum : add_s34ADDs34zs35
        port map (
            CLK => clk,
            A   => Sob_da2A_shf1,
            B   => Sob_da2B_shf1,
            CE  => Sob_hsyn_shf(1),
            S   => Sob_dSum_shf2
        );

  -- ###################
  -- ### phase11 <= 2 ###
  -- ### sobel square sum root
  -- # 40 <= 5 + 35
    s_axis_cartesian_tdata <= b"0_0000" & Sob_dSum_shf2;
    -- s_axis_cartesian_tdata <= ZERO40 or Sob_dSum_shf2;
    u_Root : Root_u35zu24 -- 9 delay
        port map (
            aclk                    => clk,
            s_axis_cartesian_tvalid => Sob_hsyn_shf(2),
            s_axis_cartesian_tdata  => s_axis_cartesian_tdata,
            m_axis_dout_tvalid      => Sob_root_valid,
            m_axis_dout_tdata       => Sob_root_shf11
        );

-- ____ ___  ____ ____    ____ _  _ ___
-- |___ |  \ | __ |___    |    |  |  |
-- |___ |__/ |__] |___    |___ |__|  |
-- !cut
    process (clk)
    begin
        if clk'event and clk='1' then
    --
    -- #####################
    -- ### phase12 <= 11 ###
            if Sob_root_valid = '1' then
                if x"ffff" < Sob_root_shf11 then
                    Sob_cut_shf12 <= (others => '1');
                else
                    Sob_cut_shf12 <= Sob_root_shf11(16 - 1 downto 0);
                end if;
            else
                Sob_cut_shf12 <= (others => '0');
            end if;
    --
        end if;
    end process;

-- ___  _   _  _ ____    ____ ____ ____
-- |__] |   |  | |__/    |    |  | |___
-- |__] |___|__| |  \    |___ |__| |___
-- !blur coe

    -- #####################
    -- ### phase13 <= 12 ###
    u_edgePlusOffset : add_U16PlusU16zU17
        port map (
            CLK => clk,
            A   => Sob_cut_shf12,
            B   => regBlurOffset,
            S   => BlurOffset13
        );

    process (clk)
    begin
        if clk'event and clk='1' then
    --
    -- #####################
    -- ### phase13 <= 12 ###
    -- regBlurOffset default value should be 2622.
    -- when it is 2622, 25 coeff value has a same coeff. maximum blur.
            -- BlurOffset13 <= ('0' & Sob_cut_shf12) + regBlurOffset;
            -- u_edgePlusOffset

    -- #####################
    -- ### phase14 <= 13 ###
    -- ### over cut
            if x"ffff" < BlurOffset13 then
                BlurOffsetCut14 <= (others => '1');
            else
                BlurOffsetCut14 <= BlurOffset13(16 - 1 downto 0);
            end if;

    -- #####################
    -- ### phase15 <= 14 ###
    -- # 12b <= 16b
            CoefBlur15centr <= x"0" & BlurOffsetCut14(16 - 1 downto 4);
            -- CoefBlur15other <= x"0FFF" - BlurOffsetCut14(16 - 1 downto 4);
            CoefBlur15other <= x"0" & not(BlurOffsetCut14(16 - 1 downto 4)) + '1';

    -- #####################
    -- ### phase16 <= 15 ###
    -- # other / 24
            CoefBlur16centr <= CoefBlur15centr;
            -- CoefBlur16other <= -- /24 = 0x0aa   0000 1010 1010
            --                    x"0000" +
            --                    CoefBlur15other(16 - 1 downto 5) +
            --                    CoefBlur15other(16 - 1 downto 7) +
            --                    CoefBlur15other(16 - 1 downto 9) +
            --                    CoefBlur15other(16 - 1 downto 11);
       --Goal for 0.4 is about 0.3984375

    -- #####################
    -- ### phase17 <= 16 ###
            CoefBlur17(12) <= CoefBlur16centr;
            -- for ii in 0 to 11 loop
            --     CoefBlur17(ii) <= CoefBlur16other;
            -- end loop;
            -- for ii in 13 to 24 loop
            --     CoefBlur17(ii) <= CoefBlur16other;
            -- end loop;
    --
        end if;
    end process;

    -- #####################
    -- ### phase16 <= 15 ###
    u_edgePlusOffsetA : add_U16PlusU16zU17
        port map (
            CLK => clk,
            A   => b"0000_0"   & CoefBlur15other(16 - 1 downto 5),
            B   => b"0000_000" & CoefBlur15other(16 - 1 downto 7),
            S   => CoefBlur16otherA
        );
    u_edgePlusOffsetB : add_U16PlusU16zU17
        port map (
            CLK => clk,
            A   => b"0000_0000_0"  & CoefBlur15other(16 - 1 downto 9),
            B   => b"0000_0000_000" & CoefBlur15other(16 - 1 downto 11),
            S   => CoefBlur16otherB
        );

    -- #####################
    -- ### phase17 <= 16 ###
    u_edgePlusOffsetC : add_U16PlusU16zU17
        port map (
            CLK => clk,
            A   => CoefBlur16otherA(16 - 1 downto 0),
            B   => CoefBlur16otherB(16 - 1 downto 0),
            S   => CoefBlur16other
        );

    gen_coef_blurother12 : for ii in 0 to 11 generate
        CoefBlur17(ii) <= CoefBlur16other(16 - 1 downto 0);
    end generate gen_coef_blurother12;

    gen_coef_blurother24 : for ii in 13 to 24 generate
        CoefBlur17(ii) <= CoefBlur16other(16 - 1 downto 0);
    end generate gen_coef_blurother24;

-- ___  _    _  _ ____    _  _ ____ ___ ____ _ _  _
-- |__] |    |  | |__/    |\/| |__|  |  |__/ |  \/
-- |__] |___ |__| |  \    |  | |  |  |  |  \ | _/\_
-- !blur matrix
  -- matrix +8 delay

    gen_coef_blur25 : for ii in 0 to 25 - 1 generate
        mw_CoefBlur17 ((ii + 1) * 16 - 1 downto ii * 16) <= CoefBlur17(ii);
    end generate gen_coef_blur25;

    u_MatrixBlur : Matrix5x5
        port map (
            i_clk  => clk,
            i_Coef => mw_CoefBlur17,

            i_hsyn => mw_doutb(400 + 26 - 1),
            i_vsyn => mw_doutb(400 + 25 - 1),
            i_hcnt => mw_doutb(400 + 24 - 1 downto 400 + 12),
            i_vcnt => mw_doutb(400 + 12 - 1 downto 400),
            i_data => mw_doutb(400 - 1 downto 0), -- delay26 <= logic17 + matrix8 + 1

            o_hsyn => MatrixBr_hsyn,
            o_vsyn => MatrixBr_vsyn,
            o_hcnt => MatrixBr_hcnt,
            o_vcnt => MatrixBr_vcnt,
            o_data => MatrixBr_data
        );

-- !cut
    process (clk)
    begin
        if clk'event and clk='1' then
  --
            MatrixBrCut_hsyn <= MatrixBr_hsyn;
            MatrixBrCut_vsyn <= MatrixBr_vsyn;
            MatrixBrCut_hcnt <= MatrixBr_hcnt;
            MatrixBrCut_vcnt <= MatrixBr_vcnt;
            if x"ffff" < MatrixBr_data then
                MatrixBrCut_data <= (others => '1');
            else
                MatrixBrCut_data <= MatrixBr_data(16 - 1 downto 0);
            end if;
  --
        end if;
    end process;

-- ____ _  _ ___
-- |  | |  |  |
-- |__| |__|  |
-- !out

    process (clk)
    begin
        if clk'event and clk='1' then
  --
--            if MatrixBrCut_vsyn='0' and
--               Sob_vsyn_shf(14)= '0' and
--               i_vsyn='0' then
--                RegEdgeEn <= regDnrCtrl(0);
--                RegDnrEn  <= regDnrCtrl(1);
--            end if; -- prevent v image rotation bug 210924
            regDnrCtrl0 <= regDnrCtrl;
            regDnrCtrl1 <= regDnrCtrl0;

            case sm_Sel is
                when x"0" =>
                    if regDnrCtrl1 /= regDnrCtrl0 then
                        sm_Sel <= x"1";
                    end if;
                when x"1" =>
                    if vsynSel = '0' then
                        VideoSel <= x"3";         -- blank
                        sm_Sel   <= x"2";
                    end if;
                when x"2" =>
                    if regDnrCtrl0(1)='1' then    -- dnr sel
                        if MatrixBrCut_vsyn = '0' then
                            VideoSel <= x"1";
                            sm_Sel   <= x"3";
                        end if;
                    elsif regDnrCtrl0(0)='1' then -- edge sel
                        if Sob_vsyn_shf(14) = '0' then
                            VideoSel <= x"2";
                            sm_Sel   <= x"3";
                        end if;
                    else
                        if i_vsyn = '0' then      -- bypass
                            VideoSel <= x"0";
                            sm_Sel   <= x"3";
                        end if;
                    end if;
                when x"3" =>
                    sm_Sel <= x"0";
                when others =>
                    sm_Sel <= x"0";
            end case;

--             if RegDnrEn = '1' and MatrixBrCut_vsyn='0' then
--                 RegEdgeEn <= regDnrCtrl(0);
--                 RegDnrEn  <= regDnrCtrl(1);
--             elsif RegEdgeEn = '1' and Sob_vsyn_shf(14)= '0' then
--                 RegEdgeEn <= regDnrCtrl(0);
--                 RegDnrEn  <= regDnrCtrl(1);
--             elsif RegEdgeEn = '0' and i_vsyn='0' then
--                 RegEdgeEn <= regDnrCtrl(0);
--                 RegDnrEn  <= regDnrCtrl(1);
--             end if; -- prevent v image rotation bug 210924

            case (VideoSel) is
                when x"0" =>   -- # bypass
                    hsynSel <= i_hsyn;
                    vsynSel <= i_vsyn;
                    hcntSel <= i_hcnt;
                    vcntSel <= i_vcnt;
                    dataSel <= i_data;
                when x"1" =>   -- # dnr
                    hsynSel <= MatrixBrCut_hsyn;
                    vsynSel <= MatrixBrCut_vsyn;
                    hcntSel <= MatrixBrCut_hcnt;
                    vcntSel <= MatrixBrCut_vcnt;
                    dataSel <= MatrixBrCut_data;
                when x"2" =>   -- # edge
                    hsynSel <= Sob_hsyn_shf(14);
                    vsynSel <= Sob_vsyn_shf(14);
                    hcntSel <= Sob_hcnt_shf(14);
                    vcntSel <= Sob_vcnt_shf(14);
                    dataSel <= BlurOffsetCut14;
                when others => -- # blank
                    hsynSel <= '0';
                    vsynSel <= '0';
                    hcntSel <= (others=> '0');
                    vcntSel <= (others=> '0');
                    dataSel <= (others=> '0');
            end case;

    --
        end if;
    end process;

    o_hsyn <= hsynSel;
    o_vsyn <= vsynSel;
    o_hcnt <= hcntSel;
    o_vcnt <= vcntSel;
    o_data <= dataSel;
    
--u_ila_dnr_vsync : ila_dnr_vsync
--PORT MAP (
--	clk       => clk              ,      
----	probe0    => "00"& sm_Sel(1 downto 0), -- 4
----	probe1    => "00"& VideoSel(1 downto 0), -- 4
--	probe0    => sm_Sel, -- 4
--	probe1    => VideoSel, -- 4
--	probe2(0) => i_vsyn           , -- 1
--	probe3(0) => MatrixBrCut_vsyn , -- 1
--	probe4(0) => MatrixRL_vsyn , -- 1
--	probe5(0) => iMawari_vsyn     , -- 1
--	probe6(0) => Mawari_vsyn        -- 1
--);

end architecture behavioral;
