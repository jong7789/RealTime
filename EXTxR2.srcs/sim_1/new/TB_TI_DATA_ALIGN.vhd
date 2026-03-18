library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity TB_TI_DATA_ALIGN is
end TB_TI_DATA_ALIGN;


architecture Behavioral of TB_TI_DATA_ALIGN is

	component TI_DATA_ALIGN is
	port (
		iroic_clk			: in	std_logic;
		iroic_rstn			: in	std_logic;
		iui_clk				: in	std_logic;
		iui_rstn			: in	std_logic;
		
		ien_array			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
		idata_array			: in	tdata_par;
		
		ireg_width			: in	std_logic_vector(11 downto 0);
		ireg_height			: in	std_logic_vector(11 downto 0);
		
		ohsync				: out	std_logic;
		ovsync				: out	std_logic;
		ohcnt				: out	std_logic_vector(9 downto 0);
		ovcnt				: out	std_logic_vector(11 downto 0);
		odata				: out	std_logic_vector(63 downto 0)
	);
	end component;

	signal tbclk_240m			: std_logic;
	constant period_240m		: time := 4.166 ns;
	signal tbclk_166m6			: std_logic;
	constant period_166m6		: time := 6.000 ns;
	signal tbrstn				: std_logic;

	signal tben_array			: std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	signal tbdata_array			: tdata_par;
	signal scnt					: std_logic_vector(7 downto 0) := (others => '0');
	signal scnt2				: std_logic_vector(7 downto 0) := (others => '0');
	signal scnt2_1d				: std_logic_vector(7 downto 0) := (others => '0');

begin

	TB_CLK_240M_GEN : process
	begin
		tbclk_240m	<= '0';		wait for period_240m / 2;
		tbclk_240m	<= '1';		wait for period_240m / 2;
	end process;

	TB_CLK_166M6_GEN : process
	begin
		tbclk_166m6	<= '0';		wait for period_166m6 / 2;
		tbclk_166m6	<= '1';		wait for period_166m6 / 2;
	end process;

	TB_RSTN_GEN : process
	begin
		tbrstn		<= '0';		wait for 1us;
		tbrstn		<= '1';		wait;
	end process;

	U0_TI_DATA_ALIGN : TI_DATA_ALIGN 
	port map (
		iroic_clk			=> tbclk_240m,
		iroic_rstn			=> tbrstn,
		iui_clk				=> tbclk_166m6,
		iui_rstn			=> tbrstn,
		
		ien_array			=> tben_array,
		idata_array			=> tbdata_array,
		
		ireg_width			=> x"674",
		ireg_height			=> x"008",
		
		ohsync				=> open,
		ovsync				=> open,
		ohcnt				=> open,
		ovcnt				=> open,
		odata				=> open
	);

	process(tbclk_240m, tbrstn)
	begin
		if(tbrstn = '0') then
			scnt		<= (others => '0');
			scnt2		<= (others => '0');
			scnt2_1d	<= (others => '0');
			tben_array	<= (others => '0');
		elsif(tbclk_240m'event and tbclk_240m = '1') then
			scnt2_1d	<= scnt2;
			if(scnt = 11) then
				if(scnt2 = 255) then
					scnt2		<= (others => '0');
				else
					scnt2		<= scnt2 + '1';
				end if;
				scnt		<= (others => '0');
				tben_array	<= (others => '1');
			else
				scnt		<= scnt + '1';
				tben_array	<= (others => '0');
			end if;
		end if;
	end process;
				


	DATA_GEN : for i in 0 to ROIC_NUM(MODEL)-1 generate
		tbdata_array(i)		<= x"00" & scnt2_1d(1 downto 0) & scnt2_1d(7 downto 2);
	end generate;




end Behavioral;
