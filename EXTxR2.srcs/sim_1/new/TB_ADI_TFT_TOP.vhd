library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity TB_ADI_TFT_TOP is
end TB_ADI_TFT_TOP;


architecture Behavioral of TB_ADI_TFT_TOP is

	component ADI_TFT_TOP is
	port (
		iext_clk_p			: in	std_logic;
		iext_clk_n			: in	std_logic;
		iext_rst			: in	std_logic;
	
		iui_clk				: in	std_logic;
		iui_rstn			: in	std_logic;
	
		-- ROIC Signals
		oroic_dclk			: out	std_logic;
		iroic_data1			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);	    
		iroic_data2			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);	    
		oroic_sync			: out	std_logic;
		oroic_aclk			: out	std_logic;
	
		oroic_spi_rst		: out	std_logic;
		oroic_spi_sck		: out	std_logic;
		oroic_spi_cs		: out	std_logic;
		oroic_spi_sdo		: out	std_logic;
	
		-- GATE Signals
		ogate_cpv			: out	std_logic;						
		ogate_dio1			: out	std_logic_vector(GATE_NUM(MODEL)-1 downto 0);					
		ogate_dio2			: out	std_logic_vector(GATE_NUM(MODEL)-1 downto 0);					
		ogate_oe1			: out	std_logic;						
		ogate_oe2			: out	std_logic;						
		ogate_xon			: out	std_logic;						
		ogate_ind			: out	std_logic;							
		ogate_flk			: out	std_logic;						
	
		-- Power Enable
		opwr_en				: out	std_logic_vector(PWR_NUM(MODEL)-1 downto 0);						
	
		-- CPU Register
		ireg_pwr_mode		: in	std_logic;
		ireg_grab_en		: in	std_logic;
		ireg_gate_en		: in	std_logic;
		ireg_img_mode		: in	std_logic_vector(2 downto 0);	
		ireg_timing_mode	: in	std_logic_vector(1 downto 0);
		ireg_rst_mode		: in	std_logic_vector(1 downto 0);	
		ireg_rst_num		: in	std_logic_vector(3 downto 0);		
		ireg_shutter		: in	std_logic;		
		ireg_erase_en		: in	std_logic;		
		ireg_erase_time		: in	std_logic_vector(31 downto 0);		
	
		ireg_trig_mode		: in	std_logic_vector(1 downto 0);
		ireg_trig_delay		: in	std_logic_vector(15 downto 0);
		ireg_trig_filt		: in	std_logic_vector(7 downto 0);
		ireg_trig_valid		: in	std_logic;
	
		ireg_roic_shaazen	: in	std_logic;
		ireg_roic_fa		: in	std_logic_vector(15 downto 0);
		ireg_roic_cds1		: in	std_logic_vector(15 downto 0);
		ireg_roic_cds2		: in	std_logic_vector(15 downto 0);
		ireg_roic_intrst	: in	std_logic_vector(15 downto 0);
		ireg_roic_sync_aclk	: in	std_logic_vector(15 downto 0);
		ireg_roic_dead		: in	std_logic_vector(15 downto 0);
		ireg_roic_mute		: in	std_logic_vector(15 downto 0);
		ireg_roic_sync_dclk	: in	std_logic_vector(15 downto 0);
		ireg_roic_afe_dclk	: in	std_logic_vector(15 downto 0);
		ireg_gate_oe		: in	std_logic_vector(15 downto 0);
		ireg_gate_xon		: in	std_logic_vector(15 downto 0);
		ireg_gate_xon_flk	: in	std_logic_vector(15 downto 0);
		ireg_gate_flk		: in	std_logic_vector(15 downto 0);
		ireg_gate_rst_cycle	: in	std_logic_vector(31 downto 0);
	
		ireg_sexp_time		: in	std_logic_vector(31 downto 0);
		ireg_exp_time		: in	std_logic_vector(31 downto 0);
		ireg_frame_time		: in	std_logic_vector(31 downto 0);
		ireg_frame_num		: in	std_logic_vector(15 downto 0);		
		ireg_frame_val		: in	std_logic_vector(15 downto 0);		
		oreg_ext_exp_time	: out	std_logic_vector(31 downto 0);
		oreg_ext_frame_time	: out	std_logic_vector(31 downto 0);
	
		ireg_width			: in	std_logic_vector(11 downto 0);
		ireg_height			: in	std_logic_vector(11 downto 0);
		ireg_offsetx		: in	std_logic_vector(11 downto 0);
		ireg_offsety		: in	std_logic_vector(11 downto 0);
	
		ireg_roic_en		: in	std_logic;
		ireg_roic_addr		: in	std_logic_vector(3 downto 0);
		ireg_roic_wdata		: in	std_logic_vector(15 downto 0);
	
		ireg_req_align		: in	std_logic;
	
		ireg_tp_mode		: in	std_logic;
		ireg_tp_sel			: in	std_logic_vector(3 downto 0);
		ireg_tp_dtime		: in	std_logic_vector(15 downto 0);
	
		oreg_pwr_done		: out	std_logic;
		oreg_erase_done		: out	std_logic;
		oreg_roic_done		: out	std_logic;
		oreg_align_done		: out	std_logic;
		oreg_grab_done		: out	std_logic;
	
		oreg_roic_temp		: out	tdata_par;
	
		osys_clk			: out	std_logic;
		osys_locked			: out	std_logic;
		oref_clk			: out	std_logic;
		oddr_clk			: out	std_logic;
		oddr_rstn			: out	std_logic;
	
		iext_trig			: in	std_logic;				
		oext_trig			: out	std_logic;				
	
		ohsync				: out	std_logic;
		ovsync				: out	std_logic;
		ohcnt				: out	std_logic_vector(9 downto 0);
		ovcnt				: out	std_logic_vector(11 downto 0);
		odata				: out	std_logic_vector(63 downto 0)
	);
	end component;

	component SIM_ADAS1258 is
	port (
		iroic_clk_p			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		iroic_clk_n			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	
		iroic_sync			: in	std_logic;
	
		oroic_dclko_p		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		oroic_dclko_n		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		oroic_data1_p		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		oroic_data1_n		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		oroic_data2_p		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		oroic_data2_n       : out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0)
	);
	end component;

	signal tbclk_200m			: std_logic;
	signal tbclk_166m			: std_logic;
	constant period_200m		: time := 5.000 ns;
	constant period_166m		: time := 6.000 ns;
	signal tbrstn				: std_logic;
	signal tbext_in				: std_logic;

	signal sroic_sync			: std_logic;

	signal sroic_dclk			: std_logic;
	signal sroic_data1_p		: std_logic;
	signal sroic_data1_n		: std_logic;
	signal sroic_data2_p		: std_logic;
	signal sroic_data2_n		: std_logic;

begin
	TB_CLK_200M_GEN : process
	begin
		tbclk_200m	<= '0';		wait for period_200m / 2;
		tbclk_200m	<= '1';		wait for period_200m / 2;
	end process;

	TB_CLK_166M_GEN : process
	begin
		tbclk_166m	<= '0';		wait for period_166m / 2;
		tbclk_166m	<= '1';		wait for period_166m / 2;
	end process;

	TB_RSTN_GEN : process
	begin
		tbrstn		<= '0';		wait for 1us;
		tbrstn		<= '1';		wait;
	end process;

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

	U0_ADI_TFT_TOP : ADI_TFT_TOP 
	port map (
		iext_clk_p			=> tbclk_200m,
		iext_clk_n			=> not tbclk_200m,
		iext_rst			=> not tbrstn,
	
		iui_clk				=> tbclk_166m,
		iui_rstn			=> tbrstn,
	
		-- ROIC Signals
		oroic_dclk			=> sroic_dclk,
		iroic_data1			=> sroic_data1_p,
		iroic_data2			=> sroic_data2_p,
		oroic_sync			=> sroic_sync,
		oroic_aclk			=> open,
	
		oroic_spi_rst		=> open,
		oroic_spi_sck		=> open,
		oroic_spi_cs		=> open,
		oroic_spi_sdo		=> open,
	
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
	
		-- CPU Register
		ireg_pwr_mode		=> '0',
		ireg_grab_en		=> '1',
		ireg_gate_en		=> '1',
		ireg_img_mode		=> "000",
		ireg_timing_mode	=> "00",
		ireg_rst_mode		=> "00",
		ireg_rst_num		=> x"3",
		ireg_shutter		=> '0',
		ireg_erase_en		=> '0',
		ireg_erase_time		=> (others => '0'),
	
		ireg_trig_mode		=> "00",
		ireg_trig_delay		=> (others => '0'),
		ireg_trig_filt		=> (others => '0'),
		ireg_trig_valid		=> '0',
	
		ireg_roic_shaazen	=> '0',
		ireg_roic_fa		=> conv_std_logic_vector(ROIC_FA, 16),
		ireg_roic_cds1		=> conv_std_logic_vector(ROIC_CDS1, 16),
		ireg_roic_cds2		=> conv_std_logic_vector(ROIC_CDS2, 16),
		ireg_roic_intrst	=> conv_std_logic_vector(ROIC_INTRST, 16),
		ireg_roic_sync_aclk	=> conv_std_logic_vector(ROIC_SYNC_ACLK, 16),
		ireg_roic_dead		=> conv_std_logic_vector(ROIC_DEAD, 16),
		ireg_roic_mute		=> conv_std_logic_vector(ROIC_MUTE(MODEL), 16),
		ireg_roic_sync_dclk	=> conv_std_logic_vector(ROIC_SYNC_DCLK, 16),
		ireg_roic_afe_dclk	=> conv_std_logic_vector(ROIC_AFE_DCLK(MODEL), 16),
		ireg_gate_oe		=> conv_std_logic_vector(GATE_OE, 16),
		ireg_gate_xon		=> conv_std_logic_vector(SIM_GATE_XON, 16),
		ireg_gate_xon_flk	=> conv_std_logic_vector(SIM_GATE_XON_FLK, 16),
		ireg_gate_flk		=> conv_std_logic_vector(SIM_GATE_FLK, 16),
		ireg_gate_rst_cycle	=> conv_std_logic_vector(SIM_GATE_TRST_PERIOD, 32),
	                                                                            
		ireg_sexp_time		=> x"00000000",
		ireg_exp_time		=> x"00000000",
		ireg_frame_time		=> x"00000000",
		ireg_frame_num		=> x"0000",
		ireg_frame_val		=> x"0000",
		oreg_ext_exp_time	=> open,
		oreg_ext_frame_time	=> open,
	                                                                            
		ireg_width			=> x"000",
		ireg_height			=> x"000",
		ireg_offsetx		=> conv_std_logic_vector(MAX_WIDTH(MODEL), 12),
		ireg_offsety		=> conv_std_logic_vector(MAX_HEIGHT(MODEL), 12),
	
		ireg_roic_en		=> '0',
		ireg_roic_addr		=> x"0",
		ireg_roic_wdata		=> x"0000",
	
		ireg_req_align		=> '0',
	
		ireg_tp_mode		=> '0',
		ireg_tp_sel			=> x"0",
		ireg_tp_dtime		=> x"0000",
	
		oreg_pwr_done		=> open,
		oreg_erase_done		=> open,
		oreg_roic_done		=> open,
		oreg_align_done		=> open,
		oreg_grab_done		=> open,
	
		oreg_roic_temp		=> open,
	
		osys_clk			=> open,
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
		odata				=> open
	);

	U0_SIM_ADAS1258 : SIM_ADAS1258 
	port map (
		iroic_clk_p			=> sroic_dclk,	 
		iroic_clk_n			=> not sroic_dclk,	 
	                                        
		iroic_sync			=> sroic_sync,	 
	                                        
		oroic_dclko_p		=> open,
		oroic_dclko_n		=> open,
		oroic_data1_p		=> sroic_data1_p,
		oroic_data1_n		=> sroic_data1_n,
		oroic_data2_p		=> sroic_data2_p,
		oroic_data2_n       => sroic_data2_n
	);

end Behavioral;
