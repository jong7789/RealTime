library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity IMG_PROC_TOP is
    generic ( GNR_MODEL : string  := "EXT1616R" );
    port (
        idata_clk        : in  std_logic;
        idata_rstn       : in  std_logic;

        ireg_width       : in  std_logic_vector(12-1 downto 0);
        ireg_height      : in  std_logic_vector(12-1 downto 0);

        ireg_iproc_mode  : in  std_logic_vector( 4-1 downto 0);
        ireg_bright      : in  std_logic_vector(17-1 downto 0);
        ireg_contrast    : in  std_logic_vector(16-1 downto 0);
        ireg_DnrCtrl     : in  std_logic_vector(16-1 downto 0);
        ireg_SobelCoeff0 : in  std_logic_vector(16-1 downto 0);
        ireg_SobelCoeff1 : in  std_logic_vector(16-1 downto 0);
        ireg_SobelCoeff2 : in  std_logic_vector(16-1 downto 0);
        ireg_BlurOffset  : in  std_logic_vector(16-1 downto 0);
        --# OSD
        isys_clk         : in  std_logic;
        iext_trig_in     : in  std_logic;
        ireg_osd_ctrl    : in  std_logic_vector(16-1 downto 0);
        oreg_trigcnt     : out std_logic_vector(16-1 downto 0);
        ireg_sync_rcnt   : in  std_logic_vector(32*30-1 downto 0);

        ichgdet_osd_en   : in  std_logic;
        ichgdet_osd_da   : in  std_logic_vector(16-1 downto 0);
        --# edge
        ireg_edge_ctrl   : in  std_logic_vector(16-1 downto 0);
        ireg_edge_value  : in  std_logic_vector(16-1 downto 0);
        ireg_edge_top    : in  std_logic_vector(16-1 downto 0);
        ireg_edge_left   : in  std_logic_vector(16-1 downto 0);
        ireg_edge_right  : in  std_logic_vector(16-1 downto 0);
        ireg_edge_bottom : in  std_logic_vector(16-1 downto 0);
        --# B&C
        ireg_bnc_ctrl    : in  std_logic_vector(16-1 downto 0);
        ireg_bnc_high    : in  std_logic_vector(16-1 downto 0);
        --# EQ
        ireg_EqCtrl      : in std_logic_vector(15 downto 0);
        ireg_EqTopVal    : in std_logic_vector(15 downto 0);

        ihsync           : in  std_logic;
        ivsync           : in  std_logic;
        ihcnt            : in  std_logic_vector(12-1 downto 0);
        ivcnt            : in  std_logic_vector(12-1 downto 0);
        idata            : in  std_logic_vector(16-1 downto 0);

        ohsync           : out std_logic;
        ovsync           : out std_logic;
        ohcnt            : out std_logic_vector(12-1 downto 0);
        ovcnt            : out std_logic_vector(12-1 downto 0);
        odata            : out std_logic_vector(16-1 downto 0)
    );
end entity img_proc_top;

architecture behavioral of img_proc_top is

    component MASKING_PROC is
        port (
            idata_clk       : in  std_logic;
            idata_rstn      : in  std_logic;

            ireg_iproc_mode : in  std_logic_vector(3 downto 0);

            ireg_width      : in  std_logic_vector(11 downto 0);
            ireg_height     : in  std_logic_vector(11 downto 0);

            ihsync          : in  std_logic;
            ivsync          : in  std_logic;
            ihcnt           : in  std_logic_vector(11 downto 0);
            ivcnt           : in  std_logic_vector(11 downto 0);
            idata           : in  std_logic_vector(15 downto 0);

            ohsync          : out std_logic;
            ovsync          : out std_logic;
            ohcnt           : out std_logic_vector(11 downto 0);
            ovcnt           : out std_logic_vector(11 downto 0);
            odata           : out std_logic_vector(15 downto 0)
        );
    end component;

    component BritCont_master is
        port (
            i_clk   : in  std_logic;
            i_hsync : in  std_logic;
            i_vsync : in  std_logic;
            i_hcnt  : in  std_logic_vector(12-1 downto 0);
            i_vcnt  : in  std_logic_vector(12-1 downto 0);
            i_data  : in  std_logic_vector(16-1 downto 0);
                  
            i_reg_width    : in  std_logic_vector(12-1 downto 0);
            i_reg_height   : in  std_logic_vector(12-1 downto 0);
            i_reg_BNC_high : in std_logic_vector(16-1 downto 0);

            o_brit  : out std_logic_vector(17-1 downto 0);
            o_cont  : out std_logic_vector(16-1 downto 0)
        );
    end component;

    component BRIGHT_CTRL is
        port (
            idata_clk   : in  std_logic;
            idata_rstn  : in  std_logic;

            ireg_bright : in  std_logic_vector(16 downto 0);

            ihsync      : in  std_logic;
            ivsync      : in  std_logic;
            ihcnt       : in  std_logic_vector(11 downto 0);
            ivcnt       : in  std_logic_vector(11 downto 0);
            idata       : in  std_logic_vector(15 downto 0);

            ohsync      : out std_logic;
            ovsync      : out std_logic;
            ohcnt       : out std_logic_vector(11 downto 0);
            ovcnt       : out std_logic_vector(11 downto 0);
            odata       : out std_logic_vector(15 downto 0)
        );
    end component;

    component CONTRAST_CTRL is
        port (
            idata_clk     : in  std_logic;
            idata_rstn    : in  std_logic;

            ireg_contrast : in  std_logic_vector(15 downto 0);

            ihsync        : in  std_logic;
            ivsync        : in  std_logic;
            ihcnt         : in  std_logic_vector(11 downto 0);
            ivcnt         : in  std_logic_vector(11 downto 0);
            idata         : in  std_logic_vector(15 downto 0);

            ohsync        : out std_logic;
            ovsync        : out std_logic;
            ohcnt         : out std_logic_vector(11 downto 0);
            ovcnt         : out std_logic_vector(11 downto 0);
            odata         : out std_logic_vector(15 downto 0)
        );
    end component;

    component EQ_CTRL_1x1 is
        port (
            clk  : in  std_logic;
            rstn : in  std_logic;

            i_regHActive  : in std_logic_vector(12-1 downto 0);
            i_regVActive  : in std_logic_vector(12-1 downto 0);
            i_regEqCtrl   : in std_logic_vector(16-1 downto 0);
            i_regEqTopVal : in std_logic_vector(16-1 downto 0); 
        
            i_hsyn : in  std_logic;
            i_vsyn : in  std_logic;
            i_hcnt : in  std_logic_vector(11 downto 0);
            i_vcnt : in  std_logic_vector(11 downto 0);
            i_data : in  std_logic_vector(15 downto 0);
                   
            o_hsyn : out std_logic;
            o_vsyn : out std_logic;
            o_hcnt : out std_logic_vector(11 downto 0);
            o_vcnt : out std_logic_vector(11 downto 0);
            o_data : out std_logic_vector(15 downto 0)
        );
    end component;

    component DNR is
        port (
            i_clk            : in  std_logic;
            i_RegHActive     : in  std_logic_vector(12 - 1 downto 0);
            i_RegVActive     : in  std_logic_vector(12 - 1 downto 0);
            i_regDnrCtrl     : in  std_logic_vector(16 - 1 downto 0);
            i_regSobelCoeff0 : in  std_logic_vector(16 - 1 downto 0);
            i_regSobelCoeff1 : in  std_logic_vector(16 - 1 downto 0);
            i_regSobelCoeff2 : in  std_logic_vector(16 - 1 downto 0);
            i_regBlurOffset  : in  std_logic_vector(16 - 1 downto 0);

            i_hsyn           : in  std_logic;
            i_vsyn           : in  std_logic;
            i_hcnt           : in  std_logic_vector(12 - 1 downto 0);
            i_vcnt           : in  std_logic_vector(12 - 1 downto 0);
            i_data           : in  std_logic_vector(16 - 1 downto 0);

            o_hsyn           : out std_logic;
            o_vsyn           : out std_logic;
            o_hcnt           : out std_logic_vector(12 - 1 downto 0);
            o_vcnt           : out std_logic_vector(12 - 1 downto 0);
            o_data           : out std_logic_vector(16 - 1 downto 0)
        );
    end component dnr;

    component OSD is
    generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            i_sclk          : in  std_logic;
            i_ext_trig_in   : in  std_logic;
            i_reg_osd_ctrl  : in  std_logic_vector(16 - 1 downto 0);
            o_reg_trigcnt   : out std_logic_vector(16 - 1 downto 0);
            i_reg_sync_rcnt : in  std_logic_vector(32*30 - 1 downto 0);

            i_chgdet_osd_en : in  std_logic;
            i_chgdet_osd_da : in  std_logic_vector(16 - 1 downto 0);

            i_dclk          : in  std_logic;
            i_hsyn          : in  std_logic;
            i_vsyn          : in  std_logic;
            i_hcnt          : in  std_logic_vector(12 - 1 downto 0);
            i_vcnt          : in  std_logic_vector(12 - 1 downto 0);
            i_data          : in  std_logic_vector(16 - 1 downto 0);

            o_hsyn          : out std_logic;
            o_vsyn          : out std_logic;
            o_hcnt          : out std_logic_vector(12 - 1 downto 0);
            o_vcnt          : out std_logic_vector(12 - 1 downto 0);
            o_data          : out std_logic_vector(16 - 1 downto 0)
        );
    end component osd;

    component EDGE is
    port (
        clk : in std_logic;

        i_reg_width  : in std_logic_vector(11 downto 0);
        i_reg_height : in std_logic_vector(11 downto 0);

        i_reg_edge_ctrl   : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_value  : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_top    : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_left   : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_right  : in  std_logic_vector(16-1 downto 0);
        i_reg_edge_bottom : in  std_logic_vector(16-1 downto 0);

        i_hsyn  : in  std_logic;
        i_vsyn  : in  std_logic;
        i_hcnt  : in  std_logic_vector(12-1 downto 0);
        i_vcnt  : in  std_logic_vector(12-1 downto 0);
        i_data  : in  std_logic_vector(16-1 downto 0);

        o_hsyn  : out std_logic;
        o_vsyn  : out std_logic;
        o_hcnt  : out std_logic_vector(12-1 downto 0);
        o_vcnt  : out std_logic_vector(12-1 downto 0);
        o_data  : out std_logic_vector(16-1 downto 0)
    );
    end component EDGE;

    signal shsync_masking  : std_logic;
    signal svsync_masking  : std_logic;
    signal shcnt_masking   : std_logic_vector(11 downto 0);
    signal svcnt_masking   : std_logic_vector(11 downto 0);
    signal sdata_masking   : std_logic_vector(15 downto 0);
    signal shsync_bright   : std_logic;
    signal svsync_bright   : std_logic;
    signal shcnt_bright    : std_logic_vector(11 downto 0);
    signal svcnt_bright    : std_logic_vector(11 downto 0);
    signal sdata_bright    : std_logic_vector(15 downto 0);
    signal shsync_contrast : std_logic;
    signal svsync_contrast : std_logic;
    signal shcnt_contrast  : std_logic_vector(11 downto 0);
    signal svcnt_contrast  : std_logic_vector(11 downto 0);
    signal sdata_contrast  : std_logic_vector(15 downto 0);
    signal shsync_eq       : std_logic;
    signal svsync_eq       : std_logic;
    signal  shcnt_eq       : std_logic_vector(11 downto 0);
    signal  svcnt_eq       : std_logic_vector(11 downto 0);
    signal  sdata_eq       : std_logic_vector(15 downto 0);
    signal shsync_dnr      : std_logic;
    signal svsync_dnr      : std_logic;
    signal shcnt_dnr       : std_logic_vector(11 downto 0);
    signal svcnt_dnr       : std_logic_vector(11 downto 0);
    signal sdata_dnr       : std_logic_vector(15 downto 0);
    signal shsync_osd      : std_logic;
    signal svsync_osd      : std_logic;
    signal shcnt_osd       : std_logic_vector(11 downto 0);
    signal svcnt_osd       : std_logic_vector(11 downto 0);
    signal sdata_osd       : std_logic_vector(15 downto 0);
    signal shsync_edge     : std_logic;
    signal svsync_edge     : std_logic;
    signal  shcnt_edge     : std_logic_vector(11 downto 0);
    signal  svcnt_edge     : std_logic_vector(11 downto 0);
    signal  sdata_edge     : std_logic_vector(15 downto 0);
 
    signal sreg_bnc_en       : std_logic;
    signal sreg_bnc_high     : std_logic_vector(16-1 downto 0);
    signal bnc_bright        : std_logic_vector(17-1 downto 0);
    signal bnc_contrast      : std_logic_vector(16-1 downto 0);
    signal sreg_sel_bright   : std_logic_vector(17-1 downto 0);
    signal sreg_sel_contrast : std_logic_vector(16-1 downto 0);

    signal shsyn_maskbnc  : std_logic;
    signal svsyn_maskbnc  : std_logic;
    signal shcnt_maskbnc  : std_logic_vector(11 downto 0);
    signal svcnt_maskbnc  : std_logic_vector(11 downto 0);
    signal sdata_maskbnc  : std_logic_vector(15 downto 0);
--COMPONENT vio_wq
--  PORT (
--    clk : IN STD_LOGIC;
--    probe_out0 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--    probe_out1 : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
--  );
--END COMPONENT;

	COMPONENT ila_sync_counter
	PORT (
		clk : IN STD_LOGIC;
		probe0 : IN STD_LOGIC; -- _VECTOR(0 DOWNTO 0); 
		probe1 : IN STD_LOGIC; -- _VECTOR(0 DOWNTO 0); 
		probe2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
		probe3 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		probe4 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
	END COMPONENT  ;
	
begin
--your_instance_name : vio_wq
--  PORT MAP (
--    clk => idata_clk,
--    probe_out0 => ireg_EqCtrl  ,
--    probe_out1 => ireg_EqTopVal
--  );

    U0_MASKING_PROC : MASKING_PROC
        port map (
            idata_clk  => idata_clk,
            idata_rstn => idata_rstn,

            ireg_iproc_mode => ireg_iproc_mode,

            ireg_width  => ireg_width,
            ireg_height => ireg_height,

            ihsync => ihsync,
            ivsync => ivsync,
            ihcnt  => ihcnt,
            ivcnt  => ivcnt,
            idata  => idata,

            ohsync => shsync_masking,
            ovsync => svsync_masking,
            ohcnt  => shcnt_masking,
            ovcnt  => svcnt_masking,
            odata  => sdata_masking
        );

                         
--  █░█ █░█░█ ░ █▄▄ █▄░█ █▀▀
--  █▀█ ▀▄▀▄▀ ▄ █▄█ █░▀█ █▄▄

gen_bnc_on : if(GEN_BNC = '1') generate
begin           
--    BNC_MASKING_PROC : MASKING_PROC
--        port map (
--            idata_clk  => idata_clk,
--            idata_rstn => idata_rstn,
  
--            ireg_iproc_mode => x"4", --# blur
  
--            ireg_width  => ireg_width,
--            ireg_height => ireg_height,
  
--            ihsync => ihsync,
--            ivsync => ivsync,
--            ihcnt  => ihcnt,
--            ivcnt  => ivcnt,
--            idata  => idata,
  
--            ohsync => shsyn_maskbnc,
--            ovsync => svsyn_maskbnc,
--            ohcnt  => shcnt_maskbnc,
--            ovcnt  => svcnt_maskbnc,
--            odata  => sdata_maskbnc
--        );

    BNC_MinMax : BritCont_master
        port map 
        (
            i_clk   => idata_clk,
          i_hsync => ihsync,
          i_vsync => ivsync,
          i_hcnt  => ihcnt,
          i_vcnt  => ivcnt,
          i_data  => idata,
--            i_hsync => shsyn_maskbnc,
--            i_vsync => svsyn_maskbnc,
--            i_hcnt  => shcnt_maskbnc,
--            i_vcnt  => svcnt_maskbnc,
--            i_data  => sdata_maskbnc,

            i_reg_width    => ireg_width,
            i_reg_height   => ireg_height,
            i_reg_bnc_high => sreg_bnc_high,

            o_Brit  => bnc_bright,
            o_Cont  => bnc_contrast
        );
end generate gen_bnc_on;

-- ########################################
sreg_bnc_en       <= ireg_bnc_ctrl(0);
sreg_bnc_high     <= ireg_bnc_high(16-1 downto 0);
sreg_sel_bright   <= bnc_bright   when sreg_bnc_En='1' else ireg_bright;
sreg_sel_contrast <= bnc_contrast when sreg_bnc_En='1' else ireg_contrast;
-- ########################################

    U0_BRIGHT_CTRL : BRIGHT_CTRL
        port map (
            idata_clk  => idata_clk,
            idata_rstn => idata_rstn,

--          ireg_bright => ireg_bright,
            ireg_bright => sreg_sel_bright, --#230721

            ihsync => shsync_masking,
            ivsync => svsync_masking,
            ihcnt  => shcnt_masking,
            ivcnt  => svcnt_masking,
            idata  => sdata_masking,

            ohsync => shsync_bright,
            ovsync => svsync_bright,
            ohcnt  => shcnt_bright,
            ovcnt  => svcnt_bright,
            odata  => sdata_bright
        );

    U0_CONTRAST_CTRL : CONTRAST_CTRL
        port map (
            idata_clk  => idata_clk,
            idata_rstn => idata_rstn,

--          ireg_contrast => ireg_contrast,
            ireg_contrast => sreg_sel_contrast, --#230721

            ihsync => shsync_bright,
            ivsync => svsync_bright,
            ihcnt  => shcnt_bright,
            ivcnt  => svcnt_bright,
            idata  => sdata_bright,

            ohsync => shsync_contrast,
            ovsync => svsync_contrast,
            ohcnt  => shcnt_contrast,
            ovcnt  => svcnt_contrast,
            odata  => sdata_contrast
        );
             
-- --    U0_EQ_CTRL : EQ_CTRL
-- --        port map (
-- --            clk  => idata_clk,
-- --            rstn => idata_rstn,
-- 
-- --            i_regHActive  => ireg_width   ,
-- --            i_regVActive  => ireg_height  ,
-- --            i_regEqCtrl   => ireg_EqCtrl  ,
-- --            i_regEqTopVal => ireg_EqTopVal,
-- 
-- --            i_hsyn => shsync_contrast,
-- --            i_vsyn => svsync_contrast,
-- --            i_hcnt =>  shcnt_contrast,
-- --            i_vcnt =>  svcnt_contrast,
-- --            i_data =>  sdata_contrast,
-- 
-- --            o_hsyn => shsync_eq,
-- --            o_vsyn => svsync_eq,
-- --            o_hcnt =>  shcnt_eq,
-- --            o_vcnt =>  svcnt_eq,
-- --            o_data =>  sdata_eq 
-- --        );

--u_ila_sync_bricon : ila_sync_counter
--PORT MAP (
--	clk    => idata_clk            ,
--	probe0 => svsync_contrast      , -- 1
--	probe1 => shsync_contrast      , -- 1
--	probe2 => x"0"& svcnt_contrast , -- 16
--	probe3 => x"0"& shcnt_contrast , -- 16
--	probe4 => sdata_contrast         -- 16
--);
        
-- █▀▀ █▀█
-- ██▄ ▀▀█ %eq
gen_eq_on : if(GEN_EQ = '1') generate
begin           
  U0_EQ_CTRL : EQ_CTRL_1x1
      port map (
          clk  => idata_clk,
          rstn => idata_rstn,

          i_regHActive  => ireg_width   ,
          i_regVActive  => ireg_height  ,
          i_regEqCtrl   => ireg_EqCtrl  ,
          i_regEqTopVal => ireg_EqTopVal,

          i_hsyn => shsync_contrast,
          i_vsyn => svsync_contrast,
          i_hcnt =>  shcnt_contrast,
          i_vcnt =>  svcnt_contrast,
          i_data =>  sdata_contrast,

          o_hsyn => shsync_eq,
          o_vsyn => svsync_eq,
          o_hcnt =>  shcnt_eq,
          o_vcnt =>  svcnt_eq,
          o_data =>  sdata_eq 
      );
end generate gen_eq_on;

gen_eq_off : if(GEN_EQ = '0') generate
begin           
 shsync_eq  <=  shsync_contrast;
 svsync_eq  <=  svsync_contrast;
  shcnt_eq  <=   shcnt_contrast;
  svcnt_eq  <=   svcnt_contrast;
  sdata_eq  <=   sdata_contrast;
end generate gen_eq_off;
        
-- █▀▄ █▄░█ █▀█
-- █▄▀ █░▀█ █▀▄ %dnr
    gen_dnr_on : if(GEN_2DDNR = '1') generate
    begin
        u_dnr : DNR
            port map (
                i_clk            => idata_clk,
                i_RegHActive     => ireg_width,
                i_RegVActive     => ireg_height,
                i_regDnrCtrl     => ireg_DnrCtrl,
                i_regSobelCoeff0 => ireg_SobelCoeff0,
                i_regSobelCoeff1 => ireg_SobelCoeff1,
                i_regSobelCoeff2 => ireg_SobelCoeff2,
                i_regBlurOffset  => ireg_BlurOffset,

--                i_hsyn => shsync_contrast,
--                i_vsyn => svsync_contrast,
--                i_hcnt =>  shcnt_contrast,
--                i_vcnt =>  svcnt_contrast,
--                i_data =>  sdata_contrast, 

              i_hsyn => shsync_eq,
              i_vsyn => svsync_eq,
              i_hcnt =>  shcnt_eq,
              i_vcnt =>  svcnt_eq,
              i_data =>  sdata_eq,

                o_hsyn => shsync_dnr,
                o_vsyn => svsync_dnr,
                o_hcnt => shcnt_dnr,
                o_vcnt => svcnt_dnr,
                o_data => sdata_dnr
            );
    end generate gen_dnr_on;

    gen_dnr_off : if(GEN_2DDNR = '0') generate
        shsync_dnr <= shsync_eq;
        svsync_dnr <= svsync_eq;
        shcnt_dnr  <=  shcnt_eq;
        svcnt_dnr  <=  svcnt_eq;
        sdata_dnr  <=  sdata_eq;
    end generate gen_dnr_off;

--u_ila_sync_dnr : ila_sync_counter
--PORT MAP (
--	clk    => idata_clk       ,
--	probe0 => shsync_dnr      , -- 1 
--	probe1 => svsync_dnr      , -- 1 
--	probe2 => x"0"& shcnt_dnr , -- 16
--	probe3 => x"0"& svcnt_dnr , -- 16
--	probe4 => sdata_dnr         -- 16
--);
           
-- █▀█ █▀ █▀▄
-- █▄█ ▄█ █▄▀ %osd
    gen_OSD_on: if(GEN_OSD = '1') generate
    begin
        u_osd : OSD
            generic map( GNR_MODEL => GNR_MODEL)
            port map (
                i_sclk          => isys_clk,
                i_ext_trig_in   => iext_trig_in,
                i_reg_osd_ctrl  => ireg_osd_ctrl,
                o_reg_trigcnt   => oreg_trigcnt,
                i_reg_sync_rcnt => ireg_sync_rcnt,

                i_chgdet_osd_en => ichgdet_osd_en,
                i_chgdet_osd_da => ichgdet_osd_da,

                i_dclk => idata_clk,
                i_hsyn => shsync_dnr,
                i_vsyn => svsync_dnr,
                i_hcnt => shcnt_dnr,
                i_vcnt => svcnt_dnr,
                i_data => sdata_dnr,

                o_hsyn => shsync_osd,
                o_vsyn => svsync_osd,
                o_hcnt => shcnt_osd,
                o_vcnt => svcnt_osd,
                o_data => sdata_osd
            );
    end generate gen_osd_on;

    gen_OSD_off : if(GEN_OSD = '0') generate
        shsync_osd <= shsync_dnr;
        svsync_osd <= svsync_dnr;
        shcnt_osd  <= shcnt_dnr;
        svcnt_osd  <= svcnt_dnr;
        sdata_osd  <= sdata_dnr;
    end generate gen_osd_off;

--u_ila_sync_osd : ila_sync_counter
--PORT MAP (
--	clk    => idata_clk        ,
--	probe0 => shsync_osd       , -- 1
--	probe1 => svsync_osd       , -- 1
--	probe2 => x"0"&  shcnt_osd , -- 16
--	probe3 => x"0"&  svcnt_osd , -- 16
--	probe4 =>  sdata_osd         -- 16
--);
                
-- █▀▀ █▀▄ █▀▀ █▀▀
-- ██▄ █▄▀ █▄█ ██▄ %edge
    gen_EDGE_1: if(GEN_EDGE = '1') generate
    begin
        u_edge : EDGE
            port map (
                clk               => idata_clk,
                i_reg_width       => ireg_width ,
                i_reg_height      => ireg_height,
                i_reg_edge_ctrl   => ireg_edge_ctrl,
                i_reg_edge_value  => ireg_edge_value,
                i_reg_edge_top    => ireg_edge_top,
                i_reg_edge_left   => ireg_edge_left,
                i_reg_edge_right  => ireg_edge_right,
                i_reg_edge_bottom => ireg_edge_bottom,

                i_hsyn => shsync_osd,
                i_vsyn => svsync_osd,
                i_hcnt =>  shcnt_osd,
                i_vcnt =>  svcnt_osd,
                i_data =>  sdata_osd,

                o_hsyn => shsync_edge,
                o_vsyn => svsync_edge,
                o_hcnt =>  shcnt_edge,
                o_vcnt =>  svcnt_edge,
                o_data =>  sdata_edge
            );
    end generate gen_EDGE_1;

    gen_EDGE_0 : if(GEN_EDGE = '0') generate
        shsync_edge <= shsync_osd;
        svsync_edge <= svsync_osd;
         shcnt_edge <=  shcnt_osd;
         svcnt_edge <=  svcnt_osd;
         sdata_edge <=  sdata_osd;
    end generate gen_EDGE_0;

    ohsync <= shsync_edge;
    ovsync <= svsync_edge;
    ohcnt  <=  shcnt_edge;
    ovcnt  <=  svcnt_edge;
    odata  <=  sdata_edge;

--u_ila_sync_edge : ila_sync_counter
--PORT MAP (
--	clk    => idata_clk        ,
--	probe0 => shsync_edge      , -- 1
--	probe1 => svsync_edge      , -- 1
--	probe2 => x"0"& shcnt_edge , -- 16
--	probe3 => x"0"& svcnt_edge , -- 16
--	probe4 =>  sdata_edge        -- 16
--);

end architecture behavioral;
