library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;
------------------------
--* EXT_CLK 200MHz => Clk divider
--* Each CLK rst delay
------------------------



entity TI_CLOCK_MANAGER is
port (
	iext_clk_p			: in	std_logic;	--* 200 MHz
	iext_clk_n			: in	std_logic;
	iext_rst			: in	std_logic;

	omain_clk			: out	std_logic;	--*	 20 MHz
	osys_clk			: out	std_logic;	--* 100 MHz	 
	oref_clk			: out	std_logic;	--* 200 MHz 
	oroic_clk			: out	std_logic;	--* 240 MHz 
	oddr_clk			: out	std_logic;	--* 250 MHz 

	osys_locked			: out	std_logic;

	omain_rstn			: out	std_logic;
	oroic_rstn			: out	std_logic;
	oddr_rstn			: out	std_logic
);
end TI_CLOCK_MANAGER;
	
architecture Behavioral of TI_CLOCK_MANAGER is

	component PLL_20M_100M_200M_250M
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

	component PLL_240M
	port (
		clk_in1			: in	std_logic;
		clk_out1		: out	std_logic;

		reset			: in	std_logic;
		locked			: out	std_logic
	);
	end component;

	component MODULE_RESET
	port (
		iclk			: in	std_logic;
		irstn			: in	std_logic;

		orstn			: out	std_logic
	);
	end component;

	signal sext_clk			: std_logic;

	signal sclk_20m			: std_logic;
	signal sclk_100m		: std_logic;
	signal sclk_200m		: std_logic;
	signal sclk_240m		: std_logic;
	signal sclk_250m		: std_logic;

	signal srstn_20m		: std_logic;
	signal srstn_200m		: std_logic;
	signal srstn_240m		: std_logic;
	signal srstn_250m		: std_logic;

	signal slocked_pll1		: std_logic;
	signal slocked_pll2		: std_logic;
	signal slocked_pll		: std_logic;

begin

	U0_IBUFGDS : IBUFGDS
    generic map (
        DIFF_TERM   	=> FALSE
	)
	port map 
	(
		I				=> iext_clk_p,
		IB				=> iext_clk_n,
		O				=> sext_clk
	);

	CLK_GEN : PLL_20M_100M_200M_250M
	port map (
		clk_in1			=> sext_clk,
		clk_out1		=> sclk_20m,
		clk_out2		=> sclk_100m,
		clk_out3		=> sclk_200m,
		clk_out4		=> sclk_250m,

		reset			=> iext_rst,
		locked			=> slocked_pll1
	);

	ROIC_CLK_GEN : PLL_240M
	port map (
		clk_in1			=> sext_clk,
		clk_out1		=> sclk_240m,

		reset			=> iext_rst,
		locked			=> slocked_pll2
	);

	slocked_pll		<= slocked_pll1 and slocked_pll2;

	MAIN_RSTN_GEN : MODULE_RESET
	port map (
		iclk			=> sclk_20m,
		irstn			=> slocked_pll,

		orstn			=> srstn_20m
	);

	REF_RSTN_GEN : MODULE_RESET
	port map (
		iclk			=> sclk_200m,
		irstn			=> slocked_pll,

		orstn			=> srstn_200m
	);

	ROIC_RSTN_GEN : MODULE_RESET
	port map (
		iclk			=> sclk_240m,
		irstn			=> slocked_pll,

		orstn			=> srstn_240m
	);

	DDR_RSTN_GEN : MODULE_RESET
	port map (
		iclk			=> sclk_250m,
		irstn			=> slocked_pll,

		orstn			=> srstn_250m
	);



	omain_clk		<= sclk_20m;
	osys_clk		<= sclk_100m;
	oref_clk		<= sclk_200m;
	oroic_clk		<= sclk_240m;
--	oddr_clk		<= sclk_200m; -- for ddr 800Mhz 211005 mbh // sclk_250m;
	oddr_clk		<= sclk_250m;

	osys_locked		<= slocked_pll;

	omain_rstn		<= srstn_20m;
	oroic_rstn		<= srstn_240m;
	oddr_rstn		<= srstn_250m;

	U0_IDELAYCTRL : IDELAYCTRL
	port map (
		RDY 	=> open, 
		REFCLK 	=> sclk_200m,
		RST 	=> not srstn_200m 
	);

end Behavioral;
