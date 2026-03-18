library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity TB_TI_TFT_TOP is
end TB_TI_TFT_TOP;


architecture Behavioral of TB_TI_TFT_TOP is

	constant tb_d2m : std_logic := '0'; -- # simulation for D2 mode

	component TI_TFT_TOP is
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
        ireg_gate_en    : in    std_logic;
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
	end component;

	component SIM_AFE2256 is
    generic ( GNR_MODEL : string  := "EXT1616R" );
	port (
		iroic_mclk			: in	std_logic;
	
		iroic_sync			: in	std_logic;
		iroic_tp_sel		: in	std_logic;
		ialign_done			: in	std_logic;
	
		oroic_data			: out	std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
		oroic_dclk			: out	std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
		oroic_fclk			: out	std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0)
	);
	end component;
  
 constant GNR_MODEL  : string := "EXT1616R";
           
	signal tbclk_20m			: std_logic;
	signal tbclk_200m			: std_logic;
	constant period_200m		: time := 5.000 ns;
	signal tbclk_240m			: std_logic;
	constant period_240m		: time := 4.166 ns;
	signal tbclk_166m6			: std_logic;
	constant period_166m6		: time := 6.000 ns;
	signal tbrstn				: std_logic;
	signal tbext_in				: std_logic;
	signal salign_done			: std_logic;
	signal tbreq_align			: std_logic;

	signal tbclk_12_5m			: std_logic;
	signal tbclk_150m			: std_logic;

	signal sroic_data			: std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);	    
	signal sroic_dclk			: std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
	signal sroic_fclk			: std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0);
 
	signal model_roic_mclk		: std_logic;
	signal model_roic_dclk		: std_logic;
	signal sroic_mclk			: std_logic;
	signal sroic_sync			: std_logic;
	signal sroic_tp_sel			: std_logic;
	signal osys_clk			    : std_logic;

	signal ireg_bcal_ctrl		: std_logic_vector(32-1 downto 0) := (others=> '0');
	signal ireg_sync_ctrl		: std_logic_vector(32-1 downto 0) := (others=> '0');

	signal sreg_d2m_en			: std_logic;
	signal sreg_d2m_exp_in		: std_logic;

	signal cnt : std_logic_vector(32-1 downto 0) := (others=> '0');

	component tb_PLL_240M
	port (
		clk_in1			: in	std_logic;
		clk_out1		: out	std_logic;
		clk_out2		: out	std_logic;
		clk_out3		: out	std_logic;
		clk_out4		: out	std_logic;

		reset			: in	std_logic;
		locked			: out	std_logic
	);
	end component;
	
begin

	TB_CLK_200M_GEN : process
	begin
		tbclk_200m	<= '0';		wait for period_200m / 2;
		tbclk_200m	<= '1';		wait for period_200m / 2;
	end process;

	ROIC_CLK_GEN : tb_PLL_240M
	port map (
		clk_in1			=> osys_clk,
		clk_out1		=> tbclk_240m,
		clk_out2		=> tbclk_20m,
		clk_out3		=> tbclk_12_5m,
		clk_out4		=> tbclk_150m,

		reset			=> '0',
		locked			=> OPEN
	);
	
--	TB_CLK_240M_GEN : process
--	begin
--		tbclk_240m	<= '0';		wait for period_240m / 2;
--		tbclk_240m	<= '1';		wait for period_240m / 2;
--	end process;

	TB_CLK_166M6_GEN : process
	begin
		tbclk_166m6	<= '0';		wait for period_166m6 / 2;
		tbclk_166m6	<= '1';		wait for period_166m6 / 2;
	end process;

	TB_RSTN_GEN : process
	begin
		tbrstn		<= '0';		wait for 10us;
		tbrstn		<= '1';		wait;
	end process;

	TB_REQ_ALIGN_GEN : process
	begin
		tbreq_align	<= '0';		wait for 40us;
		tbreq_align	<= '1';		wait for 1us;
		tbreq_align	<= '0';		wait;
	end process;

gen_tb_d2mx : if (tb_d2m='0') generate
begin          
	TB_EXT_IN_GEN : process
	begin
		tbext_in	<= '0';		wait for 20us;

		-- Normal 
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 250us;		-- SCAN
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 250us;		-- SCAN

		-- Over Trigger
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 150us;		-- SCAN
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 150us;		-- SCAN
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 150us;		-- SCAN

		-- Normal 
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 250us;		-- SCAN
		tbext_in	<= '1';		wait for 20us;		-- EWT
		tbext_in	<= '0';		wait for 250us;		-- SCAN
	end process;
end generate;

	U0_TI_TFT_TOP : TI_TFT_TOP 
	port map (
		iext_clk_p   		=> tbclk_200m, 
		iext_clk_n			=> not tbclk_200m,	
		iext_rst			=> not tbrstn,	

		iui_clk				=> tbclk_166m6,
		iui_rstn			=> tbrstn,
	
		-- ROIC Signals
		iroic_data			=> sroic_data,
		iroic_dclk			=> sroic_dclk,
		iroic_fclk			=> sroic_fclk,

        -- *ibd_mclk   	        => tbclk_20m,   1616
        -- *ibd_dclk   	        => tbclk_240m, 
--        ibd_mclk   	        => tbclk_12_5m,   4343
--        ibd_dclk   	        => tbclk_150m, 
        ibd_mclk   	        => model_roic_mclk,   
        ibd_dclk   	        => model_roic_dclk, 
        ibd_clk_lock        => '1',       

		oroic_mclk			=> sroic_mclk,
		oroic_sync			=> sroic_sync,
		oroic_tp_sel		=> sroic_tp_sel,
	
		oroic_spi_sck		=> open,
		oroic_spi_cs		=> open,
		oroic_spi_sdo		=> open,
		iroic_spi_sdi		=> (others => '0'),
	
		-- GATE Signals
		ogate_cpv			=> open,
		ogate_dio1			=> open,
		ogate_dio2			=> open,
		ogate_oe1			=> open,
		ogate_oe2			=> open,
		ogate_xon			=> open,
		ogate_ind			=> open,
		ogate_flk			=> open,
	
		-- Power Enable
		opwr_en				=> open,
	  ireg_roic_str  => (others=>'0'),

		-- CPU Register
		ireg_pwr_mode		=> '0',
		ireg_grab_en		=> '1',
		ireg_gate_en		=> '1',
		ireg_img_mode		=> "000",
		ireg_rst_mode		=> "01",
		ireg_rst_num		=> "0000",
		ireg_shutter		=> '0',
		ireg_erase_en		=> '0',
		ireg_erase_time		=> (others => '0'),
	
		ireg_trig_mode		=> "00",
		ireg_trig_delay		=> x"0000",
		ireg_trig_filt		=> x"00",
		ireg_trig_valid		=> '0',
		
	    ireg_roic_tp_sel    => '0', --# 201229
	    
		ireg_roic_cds1		=> conv_std_logic_vector(ROIC_CDS1(GNR_MODEL), 16),
		ireg_roic_cds2		=> conv_std_logic_vector(ROIC_CDS2(GNR_MODEL), 16),
		ireg_roic_intrst	=> conv_std_logic_vector(ROIC_INTRST(GNR_MODEL), 16),
		ireg_gate_oe		=> conv_std_logic_vector(GATE_OE(GNR_MODEL), 16),
		ireg_gate_xon		=> conv_std_logic_vector(SIM_GATE_XON(GNR_MODEL), 32),
		ireg_gate_xon_flk	=> conv_std_logic_vector(SIM_GATE_XON_FLK(GNR_MODEL), 32),
		ireg_gate_flk		=> conv_std_logic_vector(SIM_GATE_FLK(GNR_MODEL), 32),
		ireg_gate_rst_cycle	=> conv_std_logic_vector(SIM_GATE_TRST_PERIOD(GNR_MODEL), 32),
		
		--* 4343R
--		ireg_roic_cds1		=> conv_std_logic_vector(38, 16),
--		ireg_roic_cds2		=> conv_std_logic_vector(200, 16),
--		ireg_roic_intrst	=> conv_std_logic_vector(12, 16),
--		ireg_gate_oe		=> conv_std_logic_vector(25, 16),
--		ireg_gate_xon		=> conv_std_logic_vector(4250, 16),
--		ireg_gate_xon_flk	=> conv_std_logic_vector(625, 16),
--		ireg_gate_flk		=> conv_std_logic_vector(1875, 16),
--		ireg_gate_rst_cycle	=> conv_std_logic_vector(12500, 32) , --* 1/10

		ireg_timing_mode	=> "00",


		
	
		ireg_sexp_time		=> x"00000000",
		ireg_exp_time		=> x"00000000",
		ireg_frame_time		=> x"00000000",
		ireg_frame_num		=> x"0000",
		ireg_frame_val		=> x"0000",
		oreg_ext_exp_time	=> open,
		oreg_ext_frame_time	=> open,
	
		ireg_offsetx		=> x"000",
		ireg_offsety		=> x"000",
		ireg_width			=> conv_std_logic_vector(MAX_WIDTH(GNR_MODEL), 12), -- x"674",
		ireg_height			=> conv_std_logic_vector(MAX_HEIGHT(GNR_MODEL), 12), -- x"008",
	
		ireg_roic_en		=> '0',
		ireg_roic_addr		=> x"00",
		ireg_roic_wdata		=> x"0000",
		oreg_roic_rdata		=> open,

		ireg_req_align		=> tbreq_align,
	
		ireg_tp_mode		=> '0',
		ireg_tp_sel			=> x"0",
		ireg_tp_dtime		=> x"0000",
	  ireg_tp_value    => (others=>'0'),

		oreg_pwr_done		=> open,
		oreg_erase_done		=> open,
		oreg_roic_done		=> open,
		oreg_align_done		=> salign_done,
		oreg_grab_done		=> open,

        ireg_bcal_ctrl => ireg_bcal_ctrl,
        ireg_sync_ctrl => ireg_sync_ctrl,

         ireg_d2m_en		=> sreg_d2m_en	   ,	
         ireg_d2m_exp_in	=> sreg_d2m_exp_in ,	
         ireg_d2m_sexp_time	=> conv_std_logic_vector(500000, 32),
         ireg_d2m_frame_time=> conv_std_logic_vector(8000, 32),
         ireg_d2m_xrst_num	=> conv_std_logic_vector(10, 16),
         ireg_d2m_drst_num	=> conv_std_logic_vector(10, 16),
         od2m_xray          => open,
         od2m_dark          => open,

        ireg_ExtTrigEn      => '0',
        ireg_ExtRst_MODE    => (others => '0'),
        ireg_ExtRst_DetTime => (others => '0'), 

		osys_clk			=> osys_clk, -- open,
		osys_locked			=> open,
		oref_clk			=> open,
		oddr_clk			=> open,
		oddr_rstn			=> open,
	
		iext_trig			=> tbext_in,
		oext_trig			=> open,
	
		ohsync				=> open,
		ovsync				=> open,
		ohcnt				=> open,
		ovcnt				=> open,
		odata				=> open,

        ireg_pwdac_cmd      => (others => '0'),
        ireg_pwdac_ticktime => (others => '0'),
        ireg_pwdac_tickinc  => (others => '0'),
        ireg_pwdac_trig     => '0'
	);

model_roic_mclk <=  tbclk_20m   when GNR_MODEL = "EXT1616R" else
                    tbclk_12_5m when GNR_MODEL = "EXT4343R" else
                    tbclk_20m;
model_roic_dclk <=  tbclk_240m   when GNR_MODEL = "EXT1616R" else
                    tbclk_150m when GNR_MODEL = "EXT4343R" else
                    tbclk_240m;
                
	U0_SIM_AFE2256 : SIM_AFE2256 
	port map (
		iroic_mclk			=> model_roic_mclk,	-- 20M Input -> 240M Output (= 240M)
--		iroic_mclk			=> tbclk_20m,		-- 20M Input -> 240M Output (= 240M)
--		iroic_mclk			=> tbclk_12_5m,		-- 20M Input -> 240M Output (= 240M)
	
		iroic_sync			=> sroic_sync,
		iroic_tp_sel		=> sroic_tp_sel,
		ialign_done			=> salign_done,
	
		oroic_data			=> sroic_data,
		oroic_dclk			=> sroic_dclk,
		oroic_fclk			=> sroic_fclk
	);


gen_tb_d2m : if (tb_d2m='1') generate
begin

	process(model_roic_mclk)
	begin
		if model_roic_mclk'event and model_roic_mclk='1' then
			cnt <= cnt + '1';
			if cnt > 6000 then
				sreg_d2m_en <= '1';     
			else
				sreg_d2m_en <= '0';     
			end if;

			if cnt(15) = '1' then
				sreg_d2m_exp_in <= '1';
			else
				sreg_d2m_exp_in <= '0';
			end if;
		end if;
	end process;

end generate;



end Behavioral;
