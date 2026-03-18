
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
    use UNISIM.VCOMPONENTS.ALL;
    use WORK.TOP_HEADER.ALL;

entity TI_TFT_TOP is
  generic ( GNR_MODEL : string  := "EXT1616R" );
    port (
        iext_clk_p : in    std_logic;
        iext_clk_n : in    std_logic;
        iext_rst   : in    std_logic;

        iui_clk  : in    std_logic;
        iui_rstn : in    std_logic;

  -- ROIC Signals
        iroic_dclk : in    std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
        iroic_fclk : in    std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0);
        iroic_data : in    std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

        ibd_mclk     : in    std_logic;
        ibd_dclk     : in    std_logic;
        ibd_clk_lock : in    std_logic;

        oroic_mclk   : out   std_logic;
        oroic_sync   : out   std_logic;
        oroic_tp_sel : out   std_logic;

        oroic_spi_sck : out   std_logic;
        oroic_spi_cs  : out   std_logic;
        oroic_spi_sdo : out   std_logic;
        iroic_spi_sdi : in    std_logic_vector(ROIC_SDI_NUM(GNR_MODEL)-1 downto 0);

  -- GATE Signals
        ogate_cpv  : out   std_logic;
        ogate_dio1 : out   std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
        ogate_dio2 : out   std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
        ogate_oe1  : out   std_logic;
        ogate_oe2  : out   std_logic;
        ogate_xon  : out   std_logic;
        ogate_ind  : out   std_logic;
        ogate_flk  : out   std_logic;

  -- Power Enable
        opwr_en : out   std_logic_vector(PWR_NUM(GNR_MODEL)-1 downto 0);

  -- clock Register
        ireg_roic_str : in    std_logic_vector(7 downto 0);

  -- CPU Register
        ireg_pwr_mode   : in    std_logic;
        ireg_grab_en    : in    std_logic;
        ireg_gate_en    : in    std_logic_vector(7 downto 0);
        ireg_img_mode   : in    std_logic_vector(2 downto 0);
        ireg_rst_mode   : in    std_logic_vector(1 downto 0);
        ireg_rst_num    : in    std_logic_vector(3 downto 0);
        ireg_shutter    : in    std_logic;
        ireg_erase_en   : in    std_logic;
        ireg_erase_time : in    std_logic_vector(31 downto 0);

        ireg_trig_mode  : in    std_logic_vector(1 downto 0);
        ireg_trig_delay : in    std_logic_vector(15 downto 0);
        ireg_trig_filt  : in    std_logic_vector(7 downto 0);
        ireg_trig_valid : in    std_logic;

        ireg_roic_tp_sel    : in    std_logic;
        ireg_roic_cds1      : in    std_logic_vector(15 downto 0);
        ireg_roic_cds2      : in    std_logic_vector(15 downto 0);
        ireg_roic_intrst    : in    std_logic_vector(15 downto 0);
        ireg_gate_oe        : in    std_logic_vector(15 downto 0);
        ireg_gate_xon       : in    std_logic_vector(31 downto 0);
        ireg_gate_xon_flk   : in    std_logic_vector(31 downto 0);
        ireg_gate_flk       : in    std_logic_vector(31 downto 0);
        ireg_gate_rst_cycle : in    std_logic_vector(31 downto 0);

		ireg_timing_mode	: in	std_logic_vector( 1 downto 0);

        ireg_sexp_time      : in    std_logic_vector(31 downto 0);
        ireg_exp_time       : in    std_logic_vector(31 downto 0);
        ireg_frame_time     : in    std_logic_vector(31 downto 0);
        ireg_frame_num      : in    std_logic_vector(15 downto 0);
        ireg_frame_val      : in    std_logic_vector(15 downto 0);
		oreg_frame_cnt   	: out   std_logic_vector(31 downto 0);
        oreg_ext_exp_time   : out   std_logic_vector(31 downto 0);
        oreg_ext_frame_time : out   std_logic_vector(31 downto 0);

        ireg_width   : in    std_logic_vector(11 downto 0);
        ireg_height  : in    std_logic_vector(11 downto 0);
        ireg_offsetx : in    std_logic_vector(11 downto 0);
        ireg_offsety : in    std_logic_vector(11 downto 0);

        ireg_roic_en    : in    std_logic;
        ireg_roic_addr  : in    std_logic_vector(7 downto 0);
        ireg_roic_wdata : in    std_logic_vector(15 downto 0);
        oreg_roic_rdata : out   std_logic_vector(15 downto 0);

        ireg_req_align : in    std_logic;

        ireg_tp_mode  : in    std_logic;
        ireg_tp_sel   : in    std_logic_vector(3 downto 0);
        ireg_tp_dtime : in    std_logic_vector(15 downto 0);
        ireg_tp_value : in	  std_logic_vector(15 downto 0); --# 230717

        oreg_pwr_done   : out   std_logic;
        oreg_erase_done : out   std_logic;
        oreg_roic_done  : out   std_logic;
        oreg_align_done : out   std_logic;
        oreg_grab_done  : out   std_logic;

        ireg_bcal_ctrl	: in	std_logic_vector(31 downto 0);
        oreg_bcal_data  : out	std_logic_vector(31 downto 0);   

		--# d2m port 
		ireg_d2m_en			: in std_logic;
		ireg_d2m_exp_in		: in std_logic;
		ireg_d2m_sexp_time	: in std_logic_vector(32-1 downto 0);
		ireg_d2m_frame_time : in std_logic_vector(32-1 downto 0);
		ireg_d2m_xrst_num	: in std_logic_vector(16-1 downto 0);
		ireg_d2m_drst_num	: in std_logic_vector(16-1 downto 0);
		od2m_xray  			: out std_logic;
		od2m_dark  			: out std_logic;

		ireg_ExtTrigEn		: in std_logic;
		ireg_ExtRst_MODE 	: in std_logic_vector( 7 downto 0);
		ireg_ExtRst_DetTime : in std_logic_vector(31 downto 0);
		oExtTrig_Srst		: out std_logic;
        ostate_tftd			: out tstate_tft;

        osys_clk    : out   std_logic;
        osys_locked : out   std_logic;
        oref_clk    : out   std_logic;
        oddr_clk    : out   std_logic;
        oddr_rstn   : out   std_logic;

        iext_trig : in    std_logic;
        oext_trig : out   std_logic;

        ohsync : out   std_logic;
        ovsync : out   std_logic;
        ohcnt  : out   std_logic_vector(9 downto 0);
        ovcnt  : out   std_logic_vector(11 downto 0);
        odata  : out   std_logic_vector(63 downto 0);

        ireg_sync_ctrl	 : in std_logic_vector(31 downto 0); 
        oreg_sync_rcnt0	 : out std_logic_vector(31 downto 0); 
        oreg_sync_rcnt1  : out std_logic_vector(31 downto 0); 
        oreg_sync_rdata_AVCN0 : out std_logic_vector(31 downto 0); 
        oreg_sync_rdata_AVCN1 : out std_logic_vector(31 downto 0);   
        oreg_sync_rdata_BGLW0 : out std_logic_vector(31 downto 0); 
        oreg_sync_rdata_BGLW1 : out std_logic_vector(31 downto 0);   

        ireg_pwdac_cmd        : in  std_logic_vector(16 - 1 downto 0);
        ireg_pwdac_ticktime   : in  std_logic_vector(32 - 1 downto 0);
        ireg_pwdac_tickinc    : in  std_logic_vector(12 - 1 downto 0);
        ireg_pwdac_trig       : in  std_logic;
        oreg_pwdac_currlevel  : out std_logic_vector(16 - 1 downto 0);

        ostate_grab : out   tstate_grab;
        ostate_tft  : out   tstate_tft;
        ostate_roic : out   tstate_roic;
        ostate_gate : out   tstate_gate;
        ostate_roic_setting : out	tstate_roic_setting;
        ostate_dpram_data_align : out tstate_dpram_data_align;
        ostate_dpram_roi  : out   tstate_dpram_roi
    );
end entity ti_tft_top;

architecture behavioral of ti_tft_top is

type tdata_par                  is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(15 downto 0);

    component TI_CLOCK_MANAGER
        port (
            iext_clk_p : in    std_logic;
            iext_clk_n : in    std_logic;
            iext_rst   : in    std_logic;

			omain_clk   : out   std_logic;	--*	 20 MHz 
			osys_clk    : out   std_logic;	--*	100 MHz 
			oref_clk    : out   std_logic;	--*	200 MHz 
			oroic_clk   : out   std_logic;	--*	240 MHz 
			oddr_clk    : out   std_logic;	--* 250 MHz 

            osys_locked : out   std_logic;

            omain_rstn : out   std_logic;
            oroic_rstn : out   std_logic;
            oddr_rstn  : out   std_logic
        );
    end component;

    component TI_PWR_CTRL
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            imain_clk  : in std_logic;
            imain_rstn : in std_logic;

            ireg_pwr_mode   : in std_logic;
            ireg_erase_en   : in std_logic;
            ireg_erase_time : in std_logic_vector(31 downto 0);

            ireg_pwdac_cmd        : in  std_logic_vector(16 - 1 downto 0);
            ireg_pwdac_ticktime   : in  std_logic_vector(32 - 1 downto 0);
            ireg_pwdac_tickinc    : in  std_logic_vector(12 - 1 downto 0);
            ireg_pwdac_trig       : in  std_logic;
            oreg_pwdac_currlevel : out std_logic_vector(16 - 1 downto 0);

            itft_busy : in std_logic;

            opwr_en     : out   std_logic_vector(PWR_NUM(GNR_MODEL)-1 downto 0);
            opwr_done   : out   std_logic;
            oerase_done : out   std_logic
        );
    end component;

    component TI_FRAME_MANAGER
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            imain_clk  : in    std_logic;
            imain_rstn : in    std_logic;

            ireg_grab_en  : in    std_logic;
            ireg_gate_en  : in    std_logic_vector(7 downto 0);
            ireg_img_mode : in    std_logic_vector(2 downto 0);
            ireg_rst_mode : in    std_logic_vector(1 downto 0);
            ireg_rst_num  : in    std_logic_vector(3 downto 0);
            ireg_shutter  : in    std_logic;

            ireg_trig_mode  : in    std_logic_vector(1 downto 0);
            ireg_trig_delay : in    std_logic_vector(15 downto 0);
            ireg_trig_filt  : in    std_logic_vector(7 downto 0);
            ireg_trig_valid : in    std_logic;

            ireg_roic_tp_sel    : in    std_logic;
            ireg_roic_cds1      : in    std_logic_vector(15 downto 0);
            ireg_roic_cds2      : in    std_logic_vector(15 downto 0);
            ireg_roic_intrst    : in    std_logic_vector(15 downto 0);
            ireg_gate_oe        : in    std_logic_vector(15 downto 0);
            ireg_gate_xon       : in    std_logic_vector(31 downto 0);
            ireg_gate_xon_flk   : in    std_logic_vector(31 downto 0);
            ireg_gate_flk       : in    std_logic_vector(31 downto 0);
            ireg_gate_rst_cycle : in    std_logic_vector(31 downto 0);

			ireg_timing_mode	: in	std_logic_vector( 1 downto 0); --* jhkim

            ireg_sexp_time      : in    std_logic_vector(31 downto 0);
            ireg_exp_time       : in    std_logic_vector(31 downto 0);
            ireg_frame_time     : in    std_logic_vector(31 downto 0);
            ireg_frame_num      : in    std_logic_vector(15 downto 0);
            ireg_frame_val      : in    std_logic_vector(15 downto 0);
			oreg_frame_cnt   	: out   std_logic_vector(31 downto 0);
            oreg_ext_exp_time   : out   std_logic_vector(31 downto 0);
            oreg_ext_frame_time : out   std_logic_vector(31 downto 0);

            ireg_offsetx : in    std_logic_vector(11 downto 0);
            ireg_offsety : in    std_logic_vector(11 downto 0);
            ireg_width   : in    std_logic_vector(11 downto 0);
            ireg_height  : in    std_logic_vector(11 downto 0);

			--# d2m port 
			ireg_d2m_en			: in std_logic;
			ireg_d2m_exp_in		: in std_logic;
			ireg_d2m_sexp_time	: in std_logic_vector(32-1 downto 0);
			ireg_d2m_frame_time : in std_logic_vector(32-1 downto 0);
			ireg_d2m_xrst_num	: in std_logic_vector(16-1 downto 0);
			ireg_d2m_drst_num	: in std_logic_vector(16-1 downto 0);
			od2m_xray  			: out std_logic;
			od2m_dark  			: out std_logic;

			ireg_ExtTrigEn		: in std_logic;
			ireg_ExtRst_MODE 	: in std_logic_vector( 7 downto 0);
			ireg_ExtRst_DetTime : in std_logic_vector(31 downto 0);
			oExtTrig_Srst		: out std_logic;
            --# 220511 bcal speed
            ireg_req_align : in    std_logic;

            iext_trig : in    std_logic;
            oext_trig : out   std_logic;

            otft_busy  : out   std_logic;
            ograb_done : out   std_logic;

            oroic_dvalid : out   std_logic;

            oroic_sync   : out   std_logic;
            oroic_tp_sel : out   std_logic;

            ogate_cpv  : out   std_logic;
            ogate_dio1 : out   std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
            ogate_dio2 : out   std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
            ogate_oe1  : out   std_logic;
            ogate_oe2  : out   std_logic;
            ogate_xon  : out   std_logic;
            ogate_flk  : out   std_logic;
            
            iroic_spi_sdi : in    std_logic; --# 240122
            
  --* test point
            sstate_tftd : out   tstate_tft;
            sstate_grab : out   tstate_grab;
            sstate_tft  : out   tstate_tft;
            sstate_roic : out   tstate_roic;
            sstate_gate : out   tstate_gate
        );
    end component;

    component TI_ROIC_SETTING
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            imain_clk  : in    std_logic;
            imain_rstn : in    std_logic;

            itft_busy : in    std_logic;

            ireg_roic_en    : in    std_logic;
            ireg_roic_addr  : in    std_logic_vector(7 downto 0);
            ireg_roic_wdata : in    std_logic_vector(15 downto 0);
            oreg_roic_rdata : out   std_logic_vector(15 downto 0);

            oroic_spi_sck : out   std_logic;
            oroic_spi_cs  : out   std_logic;
            oroic_spi_sdo : out   std_logic;
            iroic_spi_sdi : in    std_logic_vector(ROIC_SDI_NUM(GNR_MODEL)-1 downto 0);
            ostate_roic_setting : out	tstate_roic_setting;
            oroic_done : out   std_logic
        );
    end component;

    component GATE_SETTING
        port (
            imain_clk  : in    std_logic;
            imain_rstn : in    std_logic;

            ireg_img_mode : in    std_logic_vector(2 downto 0);

            itft_busy : in    std_logic;

            ogate_ind : out   std_logic
        );
    end component;

    component TI_LVDS_RX
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            iroic_clk  : in    std_logic;
            iroic_rstn : in    std_logic;
            iroic_dclk : in    std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
            
            isys_clk   : in    std_logic;

            ireg_req_align : in    std_logic;

            iroic_dvalid : in    std_logic;
            iroic_data   : in    std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);

            ireg_width  : in    std_logic_vector(11 downto 0);
            ireg_height : in    std_logic_vector(11 downto 0);

			ireg_bcal_ctrl	: in	std_logic_vector(31 downto 0);
			oreg_bcal_data  : out	std_logic_vector(31 downto 0);   
			
            oen_array   : out   std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
--            odata_array : out   tdata_par;
            odata_array : out   std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
            oalign_done : out   std_logic;
            oroic_clk_sel : out	std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0); --# 241202


            irefvcnt : in    std_logic_vector(12 - 1 downto 0);
            ovcnt    : out   std_logic_vector(12 - 1 downto 0) -- for ila
        );
    end component;

    component TI_DATA_ALIGN
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port (
            iroic_clk  : in    std_logic;
            iroic_rstn : in    std_logic;
            iui_clk    : in    std_logic;
            iui_rstn   : in    std_logic;

            ialign_done : in   std_logic;
            ien_array   : in    std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
--            idata_array : in    tdata_par;
            idata_array : in    std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
            iroic_clk_sel : in	std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0); --# 241202

            ireg_width  : in    std_logic_vector(11 downto 0);
            ireg_height : in    std_logic_vector(11 downto 0);

            ohsync : out   std_logic;
            ovsync : out   std_logic;
            ohcnt  : out   std_logic_vector(9 downto 0);
            ovcnt  : out   std_logic_vector(11 downto 0);
            odata  : out   std_logic_vector(63 downto 0);

            orefvcnt : out   std_logic_vector(11 downto 0);
            ivcnt    : in    std_logic_vector(12 - 1 downto 0);
		    ostate_dpram_data_align : out tstate_dpram_data_align
        );
    end component;
    
    component ROI_PROC
        port (
            iui_clk  : in    std_logic;
            iui_rstn : in    std_logic;

            ireg_img_mode : in    std_logic_vector(2 downto 0);
            ireg_offsetx  : in    std_logic_vector(11 downto 0);
            ireg_offsety  : in    std_logic_vector(11 downto 0);
            ireg_width    : in    std_logic_vector(11 downto 0);
            ireg_height   : in    std_logic_vector(11 downto 0);

            ihsync : in    std_logic;
            ivsync : in    std_logic;
            ihcnt  : in    std_logic_vector(9 downto 0);
            ivcnt  : in    std_logic_vector(11 downto 0);
            idata  : in    std_logic_vector(63 downto 0);

            ohsync : out   std_logic;
            ovsync : out   std_logic;
            ohcnt  : out   std_logic_vector(9 downto 0);
            ovcnt  : out   std_logic_vector(11 downto 0);
            odata  : out   std_logic_vector(63 downto 0);
            
            ostate_dpram_roi  : out   tstate_dpram_roi
        );
    end component;

    component TEST_PATTERN
        port (
            iui_clk  : in    std_logic;
            iui_rstn : in    std_logic;

            ireg_grab_en   : in std_logic;
            ireg_frame_num : in std_logic_vector(15 downto 0);
            ireg_tp_mode   : in std_logic;
            ireg_tp_sel    : in std_logic_vector(3 downto 0);
            ireg_tp_dtime  : in std_logic_vector(15 downto 0);
            ireg_tp_value  : in	std_logic_vector(15 downto 0); --# 230717

            ireg_width  : in    std_logic_vector(11 downto 0);
            ireg_height : in    std_logic_vector(11 downto 0);
            id2m_dark   : in    std_logic;

            ihsync : in    std_logic;
            ivsync : in    std_logic;
            ihcnt  : in    std_logic_vector(9 downto 0);
            ivcnt  : in    std_logic_vector(11 downto 0);
            idata  : in    std_logic_vector(63 downto 0);

            ohsync : out   std_logic;
            ovsync : out   std_logic;
            ohcnt  : out   std_logic_vector(9 downto 0);
            ovcnt  : out   std_logic_vector(11 downto 0);
            odata  : out   std_logic_vector(63 downto 0)
        );
    end component;

    signal ssys_clk  : std_logic;
    signal smain_clk  : std_logic;
    signal smainstr_clk  : std_logic; -- 220901 str divided clk
    signal smain_rstn : std_logic;
    signal sroic_clk  : std_logic;
    signal sroic_rstn : std_logic;

    signal spwr_done   : std_logic;
    signal serase_done : std_logic;
    signal salign_done : std_logic;
    signal sroic_done  : std_logic;
    signal sgrab_done  : std_logic;

    signal sroic_dvalid : std_logic;

    signal stft_busy : std_logic;

    signal sen_array   : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    signal sroic_clk_sel   : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
--    signal sdata_array : tdata_par;
    signal sdata_array : std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);

    signal shsync_data_align : std_logic;
    signal svsync_data_align : std_logic;
    signal shcnt_data_align  : std_logic_vector(9 downto 0);
    signal svcnt_data_align  : std_logic_vector(11 downto 0);
    signal sdata_data_align  : std_logic_vector(63 downto 0);

    signal shsync_roi_proc : std_logic;
    signal svsync_roi_proc : std_logic;
    signal shcnt_roi_proc  : std_logic_vector(9 downto 0);
    signal svcnt_roi_proc  : std_logic_vector(11 downto 0);
    signal sdata_roi_proc  : std_logic_vector(63 downto 0);

    signal shsync_test_pattern : std_logic;
    signal svsync_test_pattern : std_logic;
    signal shcnt_test_pattern  : std_logic_vector(9 downto 0);
    signal svcnt_test_pattern  : std_logic_vector(11 downto 0);
    signal sdata_test_pattern  : std_logic_vector(63 downto 0);

    signal svnct_lvds : std_logic_vector(12 - 1 downto 0);
    signal srefvcnt   : std_logic_vector(12 - 1 downto 0);

  --* test point

    signal ssstate_tftd : tstate_tft;
    
    signal ssstate_grab : tstate_grab;
    signal ssstate_tft  : tstate_tft;
    signal ssstate_roic : tstate_roic;
    signal ssstate_gate : tstate_gate;

	signal smclk_cnt   : std_logic_vector(4-1 downto 0) := (others=>'0');
	signal smclkstr    : std_logic := '0';

	signal ssys_locked : std_logic := '0';

	signal sd2m_dark : std_logic;
	signal sroic_sync : std_logic;
	signal sstr_clk : std_logic;
	signal sreg_roic_str  : std_logic_vector(2-1 downto 0) := (others=>'0');
	
begin
--  ### axi control able clock ###
  smain_rstn <= ibd_clk_lock when SIMULATION = "OFF"   else iui_rstn;
  sroic_rstn <= ibd_clk_lock when SIMULATION = "OFF"   else iui_rstn;
    sroic_clk  <= ibd_dclk; --# default
    smain_clk <= ibd_mclk; --# 220728
    
	process(ibd_mclk)
	begin
		if ibd_mclk'event and ibd_mclk = '1' then
		--
               smclk_cnt <= smclk_cnt + '1';
		--
		end if;
	end process;
    sreg_roic_str <= ireg_roic_str(1 downto 0);
	sstr_clk <= ibd_mclk     when sreg_roic_str = 0 else --roic str 256
	            smclk_cnt(0) when sreg_roic_str = 1 else --roic str 512
	            smclk_cnt(1) when sreg_roic_str = 2 else --roic str 1024
	            smclk_cnt(2);                       --roic str 2048
    
    instBUFG_mclk : BUFG
    port map (
    	O => smainstr_clk,
    	I => sstr_clk     
    );

    U0_TI_CLOCK_MANAGER : TI_CLOCK_MANAGER
        port map (
            iext_clk_p => iext_clk_p,
            iext_clk_n => iext_clk_n,
            iext_rst   => iext_rst,

            omain_clk => OPEN, -- smain_clk, -- 20Mhz mbh 210115
            osys_clk  => ssys_clk,
            oref_clk  => oref_clk,
            oroic_clk => OPEN, -- sroic_clk, -- 240Mhz mbh 210115
            oddr_clk  => oddr_clk,

            osys_locked => ssys_locked,

            omain_rstn => OPEN, -- smain_rstn, -- mbh 210119
            oroic_rstn => OPEN, -- sroic_rstn, -- mbh 210119
            oddr_rstn  => oddr_rstn
        );
    osys_clk  <= ssys_clk;
    oroic_mclk <= ibd_mclk; -- smain_clk; mbh210720
    osys_locked <= ssys_locked;
    U0_TI_PWR_CTRL : TI_PWR_CTRL
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
--            imain_clk  => ssys_clk, -- smain_clk,
--            imain_rstn => ssys_locked, -- smain_rstn,
            --# 220504 mbh rollbcak clk
            imain_clk  => smain_clk,
            imain_rstn => smain_rstn,

            ireg_pwr_mode   => ireg_pwr_mode,
            ireg_erase_en   => ireg_erase_en,
            ireg_erase_time => ireg_erase_time,

            ireg_pwdac_cmd       => ireg_pwdac_cmd      ,
            ireg_pwdac_ticktime  => ireg_pwdac_ticktime ,
            ireg_pwdac_tickinc   => ireg_pwdac_tickinc  ,
            ireg_pwdac_trig      => ireg_pwdac_trig     ,
            oreg_pwdac_currlevel => oreg_pwdac_currlevel,

            itft_busy => stft_busy,

            opwr_en     => opwr_en,
            opwr_done   => spwr_done,
            oerase_done => serase_done
        );

    U0_TI_FRAME_MANAGER : TI_FRAME_MANAGER
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            imain_clk  => smainstr_clk,
            imain_rstn => smain_rstn,

            ireg_grab_en  => ireg_grab_en,
            ireg_gate_en  => ireg_gate_en,
            ireg_img_mode => ireg_img_mode,
            ireg_rst_mode => ireg_rst_mode,
            ireg_rst_num  => ireg_rst_num,
            ireg_shutter  => ireg_shutter,

            ireg_trig_mode  => ireg_trig_mode,
            ireg_trig_delay => ireg_trig_delay,
            ireg_trig_filt  => ireg_trig_filt,
            ireg_trig_valid => ireg_trig_valid,

            ireg_roic_tp_sel    => ireg_roic_tp_sel,
            ireg_roic_cds1      => ireg_roic_cds1,
            ireg_roic_cds2      => ireg_roic_cds2,
            ireg_roic_intrst    => ireg_roic_intrst,
            ireg_gate_oe        => ireg_gate_oe,
            ireg_gate_xon       => ireg_gate_xon,
            ireg_gate_xon_flk   => ireg_gate_xon_flk,
            ireg_gate_flk       => ireg_gate_flk,
            ireg_gate_rst_cycle => ireg_gate_rst_cycle,

			ireg_timing_mode	=> ireg_timing_mode, --* jhkim

            ireg_sexp_time      => ireg_sexp_time,
            ireg_exp_time       => ireg_exp_time,
            ireg_frame_time     => ireg_frame_time,
            ireg_frame_num      => ireg_frame_num,
            ireg_frame_val      => ireg_frame_val,
			oreg_frame_cnt   	=> oreg_frame_cnt,
            oreg_ext_exp_time   => oreg_ext_exp_time,
            oreg_ext_frame_time => oreg_ext_frame_time,

            ireg_offsetx => ireg_offsetx,
            ireg_offsety => ireg_offsety,
            ireg_width   => ireg_width,
            ireg_height  => ireg_height,

            ireg_d2m_en			=> ireg_d2m_en		  ,
            ireg_d2m_exp_in		=> ireg_d2m_exp_in	  ,
            ireg_d2m_sexp_time	=> ireg_d2m_sexp_time ,
            ireg_d2m_frame_time => ireg_d2m_frame_time,
            ireg_d2m_xrst_num	=> ireg_d2m_xrst_num  ,
            ireg_d2m_drst_num	=> ireg_d2m_drst_num  ,
            od2m_xray  			=> od2m_xray  		  ,
            od2m_dark  			=> sd2m_dark  		  ,

			ireg_ExtTrigEn		=> ireg_ExtTrigEn,
			ireg_ExtRst_MODE   	=> ireg_ExtRst_MODE,
			ireg_ExtRst_DetTime	=> ireg_ExtRst_DetTime,
			oExtTrig_Srst		=> oExtTrig_Srst ,
            sstate_tftd			=> ssstate_tftd,
            ireg_req_align      => ireg_req_align,

            iext_trig => iext_trig,
            oext_trig => oext_trig,

            otft_busy  => stft_busy,
            ograb_done => sgrab_done,

            oroic_dvalid => sroic_dvalid,

--            oroic_sync   => oroic_sync,
            oroic_sync   => sroic_sync, --# 220610
            oroic_tp_sel => oroic_tp_sel,

            ogate_cpv  => ogate_cpv,
            ogate_dio1 => ogate_dio1,
            ogate_dio2 => ogate_dio2,
            ogate_oe1  => ogate_oe1,
            ogate_oe2  => ogate_oe2,
            ogate_xon  => ogate_xon,
            ogate_flk  => ogate_flk,
            
            iroic_spi_sdi => iroic_spi_sdi(0), --# 240122
            
  -- *--* test point
            sstate_grab => ssstate_grab,
            sstate_tft  => ssstate_tft,
            sstate_roic => ssstate_roic,
            sstate_gate => ssstate_gate
        );
        
      oroic_sync <=  sroic_sync when  ireg_req_align = '0' else --# while bit calibration, Do not drive sync. 231026
                     '0';
--      oroic_sync <=  sroic_sync; --# 231026
                     
 od2m_dark <= sd2m_dark;
    U0_TI_ROIC_SETTING : TI_ROIC_SETTING
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            imain_clk  => smain_clk,
            imain_rstn => smain_rstn,

            itft_busy => stft_busy,

            ireg_roic_en    => ireg_roic_en,
            ireg_roic_addr  => ireg_roic_addr,
            ireg_roic_wdata => ireg_roic_wdata,
            oreg_roic_rdata => oreg_roic_rdata,

            oroic_spi_sck => oroic_spi_sck,
            oroic_spi_cs  => oroic_spi_cs,
            oroic_spi_sdo => oroic_spi_sdo,
            iroic_spi_sdi => iroic_spi_sdi,
            ostate_roic_setting => ostate_roic_setting,
            oroic_done => sroic_done
        );

    U0_GATE_SETTING : GATE_SETTING
        port map (
            imain_clk  => smainstr_clk,
            imain_rstn => smain_rstn,

            ireg_img_mode => ireg_img_mode,

            itft_busy => stft_busy,

            ogate_ind => ogate_ind
        );

    U0_TI_LVDS_RX : TI_LVDS_RX
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            iroic_clk  => sroic_clk,
            iroic_rstn => sroic_rstn,
            iroic_dclk => iroic_dclk,
            
            isys_clk   => ssys_clk,

            ireg_req_align => ireg_req_align,

            iroic_dvalid => sroic_dvalid,
            iroic_data   => iroic_data,

            ireg_width  => ireg_width,
            ireg_height => ireg_height,

            ireg_bcal_ctrl => ireg_bcal_ctrl,
            oreg_bcal_data => oreg_bcal_data,   
            
            oen_array   => sen_array,
            odata_array => sdata_array,
            oalign_done => salign_done,
            oroic_clk_sel => sroic_clk_sel,

            irefvcnt => srefvcnt,
            ovcnt    => svnct_lvds
        );

    U0_TI_DATA_ALIGN : TI_DATA_ALIGN
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            iroic_clk  => sroic_clk,
            iroic_rstn => sroic_rstn,
            iui_clk    => iui_clk,
            iui_rstn   => iui_rstn,

            ialign_done => salign_done,
            ien_array   => sen_array,
            idata_array => sdata_array,
            iroic_clk_sel => sroic_clk_sel,

            ireg_width  => ireg_width,
            ireg_height => ireg_height,

            ohsync => shsync_data_align,
            ovsync => svsync_data_align,
            ohcnt  => shcnt_data_align,
            ovcnt  => svcnt_data_align,
            odata  => sdata_data_align,

            orefvcnt => srefvcnt,
            ivcnt    => svnct_lvds,
            ostate_dpram_data_align => ostate_dpram_data_align
        );

    U0_ROI_PROC : ROI_PROC
        port map (
            iui_clk  => iui_clk,
            iui_rstn => iui_rstn,

            ireg_img_mode => ireg_img_mode,
            ireg_offsetx  => ireg_offsetx,
            ireg_offsety  => ireg_offsety,
            ireg_width    => ireg_width,
            ireg_height   => ireg_height,

            ihsync => shsync_data_align,
            ivsync => svsync_data_align,
            ihcnt  => shcnt_data_align,
            ivcnt  => svcnt_data_align,
            idata  => sdata_data_align,

            ohsync => shsync_roi_proc,
            ovsync => svsync_roi_proc,
            ohcnt  => shcnt_roi_proc,
            ovcnt  => svcnt_roi_proc,
            odata  => sdata_roi_proc,
            
            ostate_dpram_roi => ostate_dpram_roi
        );

    U0_TEST_PATTERN : TEST_PATTERN
        port map (
            iui_clk  => iui_clk,
            iui_rstn => iui_rstn,

            ireg_grab_en   => ireg_grab_en,
            ireg_frame_num => ireg_frame_num,
            ireg_tp_mode   => ireg_tp_mode,
            ireg_tp_sel    => ireg_tp_sel,
            ireg_tp_dtime  => ireg_tp_dtime,
            ireg_tp_value  => ireg_tp_value,

            ireg_width  => ireg_width,
            ireg_height => ireg_height,
            id2m_dark   => sd2m_dark,

            ihsync => shsync_roi_proc,
            ivsync => svsync_roi_proc,
            ihcnt  => shcnt_roi_proc,
            ivcnt  => svcnt_roi_proc,
            idata  => sdata_roi_proc,

            ohsync => shsync_test_pattern,
            ovsync => svsync_test_pattern,
            ohcnt  => shcnt_test_pattern,
            ovcnt  => svcnt_test_pattern,
            odata  => sdata_test_pattern
        );

    oreg_pwr_done   <= spwr_done;
    oreg_erase_done <= serase_done;
    oreg_roic_done  <= sroic_done;
    oreg_align_done <= salign_done;
    oreg_grab_done  <= sgrab_done;

    ohsync <= shsync_test_pattern;
    ovsync <= svsync_test_pattern;
    ohcnt  <= shcnt_test_pattern;
    ovcnt  <= svcnt_test_pattern;
    odata  <= sdata_test_pattern;

    ostate_tftd <= ssstate_tftd;

    ostate_grab <= ssstate_grab;
    ostate_tft  <= ssstate_tft;
    ostate_roic <= ssstate_roic;
    ostate_gate <= ssstate_gate;

 	---------------------------------------
 	--* ILA_TI_TFT_DATA
 	---------------------------------------
 	--* ILA_DEBUG2 : if(SIMULATION = "OFF") generate
 	ILA_DEBUG2 : if(GEN_ILA_tft_data = "ON") generate
 	
 		component ILA_TI_TFT_DATA
	port (
		clk				: in 	std_logic;				
		
		probe0 			:	in 	std_logic;
		probe1 			:	in 	std_logic;
		probe2 			:	in 	std_logic_vector(9 downto 0);
		probe3 			:	in 	std_logic_vector(11 downto 0);
		probe4 			:	in 	std_logic_vector(63 downto 0);
    	            	   	
		probe5 			:	in 	std_logic;
		probe6 			:	in 	std_logic;
		probe7 			:	in 	std_logic_vector(9 downto 0);
		probe8 			:	in 	std_logic_vector(11 downto 0);
		probe9 			:	in 	std_logic_vector(63 downto 0);
    	                 	
		probe10 		:	in 	std_logic;
		probe11 		:	in 	std_logic;
		probe12 		:	in 	std_logic_vector(9 downto 0);
		probe13 		:	in 	std_logic_vector(11 downto 0);
		probe14 		:	in 	std_logic_vector(63 downto 0);

		probe15			:	in	tstate_grab;		
		probe16			:	in	tstate_tft ;		
		probe17			:	in	tstate_roic;		
		probe18			:	in	tstate_gate		
	);
	end component;

 	begin
 		U0_ILA_TI_TFT_DATA	: ILA_TI_TFT_DATA
 		port map (
 			clk				=> 	iui_clk					,	--* 1 
 			
 			probe0 			=>	shsync_data_align		,	--* 1 
 			probe1 			=>	svsync_data_align		,	--* 1 
 			probe2 			=>	shcnt_data_align		,	--* 10 	
 			probe3 			=>	svcnt_data_align		,	--* 12	
 			probe4 			=>	sdata_data_align		,	--* 64	
     		            	  	                		
 			probe5 			=>	shsync_roi_proc			,	--* 1 
 			probe6 			=>	svsync_roi_proc			,	--* 1 
 			probe7 			=>	shcnt_roi_proc			,	--* 10
 			probe8 			=>	svcnt_roi_proc			,	--* 12
 			probe9 			=>	sdata_roi_proc			,	--* 64
     		                  	                		
 			probe10 		=>	shsync_test_pattern		,	--* 1 
 			probe11 		=>	svsync_test_pattern		,	--* 1 
 			probe12 		=>	shcnt_test_pattern		,	--* 10
 			probe13 		=>	svcnt_test_pattern		,	--* 12
 			probe14 		=>	sdata_test_pattern		,	--* 64
 
 			probe15			=>	ssstate_grab			,	--* 2 
 			probe16			=>	ssstate_tft 			,	--* 3
 			probe17			=>	ssstate_roic			,	--* 4
 			probe18			=>	ssstate_gate				--* 4
 		);
end generate;
 		
ILA_DEBUG_SYNC_COUNTER : if(GEN_SYNC_COUNTER = "ON") generate
	component sync_counter 
    generic (
        sysclkhz : integer   := 100_000_000;
        vio		 : std_logic := '1';
        para : integer -- := 4 -- 4 or 1
    );
    port (
        ISYSCLK : in    std_logic;

        ICLK   : in    std_logic;
        IVSYNC : in    std_logic;
        IHSYNC : in    std_logic;
		IDATA		   : in    std_logic_vector(16*para - 1 downto 0);
        IREG_CTRL      : in    std_logic_vector(32 - 1 downto 0);		
		OREG_CNT       : out   std_logic_vector(32 - 1 downto 0);
		OREG_DATA_AvCn : out   std_logic_vector(32 - 1 downto 0);
		OREG_DATA_BgLw : out   std_logic_vector(32 - 1 downto 0)
    );
	end component sync_counter;   
begin
	 -- ### Align OUT ###
	u_roic_sync_counter0 : sync_counter 
		generic map (
			sysclkhz => CSYSCLKHZ,         
			vio		 => GEN_VIO_SYNC_COUNTER0,
			para     => 4
		)
		port map (
			ISYSCLK => ssys_clk,
			ICLK    => iui_clk,
			IVSYNC  => svsync_data_align,
            IHSYNC  => shsync_data_align,
            IDATA   => sdata_data_align, -- (16-1 downto 0),
			IREG_CTRL       => ireg_sync_ctrl,            
            OREG_CNT         => oreg_sync_rcnt0,
            OREG_DATA_AvCn   => oreg_sync_rdata_AVCN0,
            OREG_DATA_BgLw   => oreg_sync_rdata_BGLW0
		);
                        
	 -- ### ROI OUT ###
	u_roic_sync_counter1 : sync_counter 
		generic map (
			sysclkhz => CSYSCLKHZ,         
			vio		 => GEN_VIO_SYNC_COUNTER0,
			para     => 4
		)
		port map (
			ISYSCLK => ssys_clk,
			ICLK    => iui_clk,
			IVSYNC  => svsync_roi_proc,
            IHSYNC  => shsync_roi_proc,
            IDATA   => sdata_roi_proc, -- (16-1 downto 0),
			IREG_CTRL       => ireg_sync_ctrl,            
            OREG_CNT         => oreg_sync_rcnt1,
            OREG_DATA_AvCn   => oreg_sync_rdata_AVCN1,
            OREG_DATA_BgLw   => oreg_sync_rdata_BGLW1
		);    
end generate;

end architecture behavioral;
