library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity TB_TI_FRAME_MANAGER is
end TB_TI_FRAME_MANAGER;
	
architecture Behavioral of TB_TI_FRAME_MANAGER is

	component TI_FRAME_MANAGER 
	port (
		imain_clk			: in	std_logic;
		imain_rstn			: in	std_logic;
		
		ireg_grab_en		: in	std_logic;
		ireg_gate_en		: in	std_logic;					
		ireg_img_mode		: in	std_logic_vector(2 downto 0);					
		ireg_rst_mode		: in	std_logic_vector(1 downto 0);					
		ireg_rst_num		: in	std_logic_vector(3 downto 0);					
		ireg_shutter		: in	std_logic;				
		
		ireg_trig_mode		: in	std_logic_vector(1 downto 0);
		ireg_trig_delay		: in	std_logic_vector(15 downto 0);
		ireg_trig_filt		: in	std_logic_vector(7 downto 0);
		ireg_trig_valid		: in	std_logic;
		
		ireg_roic_cds1		: in	std_logic_vector(15 downto 0);
		ireg_roic_cds2		: in	std_logic_vector(15 downto 0);
		ireg_roic_intrst	: in	std_logic_vector(15 downto 0);
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
		
		ireg_offsetx		: in	std_logic_vector(11 downto 0);
		ireg_offsety		: in	std_logic_vector(11 downto 0);
		ireg_width			: in	std_logic_vector(11 downto 0);
		ireg_height			: in	std_logic_vector(11 downto 0);
		
		iext_trig			: in	std_logic;
		oext_trig			: out	std_logic;
		
		otft_busy			: out	std_logic;
		ograb_done			: out	std_logic;
		
		oroic_dvalid		: out	std_logic;
		
		oroic_sync			: out	std_logic;
		oroic_tp_sel		: out	std_logic;
		
		ogate_cpv			: out	std_logic;
		ogate_dio1			: out	std_logic_vector(GATE_NUM(MODEL)-1 downto 0);	
		ogate_dio2			: out	std_logic_vector(GATE_NUM(MODEL)-1 downto 0);	
		ogate_oe1			: out	std_logic;
		ogate_oe2			: out	std_logic;
		ogate_xon			: out	std_logic;
		ogate_flk			: out	std_logic	
	);
	end component;

	signal tbclk_20m			: std_logic;
	constant period_20m			: time := 50.000 ns;
	signal tbrstn				: std_logic;

	signal tbext_in				: std_logic;

begin

	TB_CLK_20M_GEN : process
	begin
		tbclk_20m	<= '0';		wait for period_20m / 2;
		tbclk_20m	<= '1';		wait for period_20m / 2;
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

	U0_TI_FRAME_MANAGER : TI_FRAME_MANAGER 
	port map (
		imain_clk			=> tbclk_20m,
		imain_rstn			=> tbrstn,
	
		ireg_grab_en		=> '1',
		ireg_gate_en		=> '1',
		ireg_img_mode		=> "000",
		ireg_rst_mode		=> "00",
		ireg_rst_num		=> "0000",
		ireg_shutter		=> '0',
	
		ireg_trig_mode		=> "00",
		ireg_trig_delay		=> x"0000",
		ireg_trig_filt		=> x"00",
		ireg_trig_valid		=> '0',
	
		ireg_roic_cds1		=> conv_std_logic_vector(ROIC_CDS1, 16),
		ireg_roic_cds2		=> conv_std_logic_vector(ROIC_CDS2, 16),
		ireg_roic_intrst	=> conv_std_logic_vector(ROIC_INTRST, 16),
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
	
		ireg_offsetx		=> x"000",
		ireg_offsety		=> x"000",
		ireg_width			=> conv_std_logic_vector(MAX_WIDTH(MODEL), 12),
		ireg_height			=> conv_std_logic_vector(MAX_HEIGHT(MODEL), 12),
	
		iext_trig			=> tbext_in,
		oext_trig			=> open,
	
		otft_busy			=> open,
		ograb_done			=> open,

		oroic_dvalid		=> open,
	
		oroic_sync			=> open,
		oroic_tp_sel		=> open,
		
		ogate_cpv			=> open,
		ogate_dio1			=> open,
		ogate_dio2			=> open,
		ogate_oe1			=> open,
		ogate_oe2			=> open,
		ogate_xon			=> open,
		ogate_flk			=> open
	);


end Behavioral;
