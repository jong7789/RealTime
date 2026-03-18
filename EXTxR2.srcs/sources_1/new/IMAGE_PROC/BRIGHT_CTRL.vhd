library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity BRIGHT_CTRL is
port (
	idata_clk			: in	std_logic;
	idata_rstn			: in	std_logic;

	ireg_bright			: in	std_logic_vector(16 downto 0);

	ihsync				: in	std_logic;
	ivsync				: in	std_logic;
	ihcnt				: in	std_logic_vector(11 downto 0);
	ivcnt				: in	std_logic_vector(11 downto 0);
	idata				: in	std_logic_vector(15 downto 0);

	ohsync				: out	std_logic;
	ovsync				: out	std_logic;
	ohcnt				: out	std_logic_vector(11 downto 0);
	ovcnt				: out	std_logic_vector(11 downto 0);
	odata				: out	std_logic_vector(15 downto 0)
);
end BRIGHT_CTRL;

architecture Behavioral of BRIGHT_CTRL is
	
	signal shsync_cal		: std_logic;
	signal svsync_cal		: std_logic;
	signal shcnt_cal		: std_logic_vector(11 downto 0);
	signal svcnt_cal		: std_logic_vector(11 downto 0);
	signal sdata_cal		: std_logic_vector(16 downto 0);

	signal sreg_bright_1d	: std_logic_vector(16 downto 0);
	signal sreg_bright_2d	: std_logic_vector(16 downto 0);
	signal sreg_bright_3d	: std_logic_vector(16 downto 0);

begin

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			shsync_cal		<= '0';
			svsync_cal		<= '0';
			shcnt_cal		<= (others => '0');
			svcnt_cal		<= (others => '0');
			sdata_cal		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			shsync_cal		<= ihsync;
			svsync_cal		<= ivsync;
			shcnt_cal		<= ihcnt;
			svcnt_cal		<= ivcnt;
			if(sreg_bright_3d(16) = '0') then
				sdata_cal	<= ('0' & idata) + sreg_bright_3d;
			else
				if(idata > sreg_bright_3d(15 downto 0)) then
					sdata_cal	<= ('0' & idata) - ('0' & sreg_bright_3d(15 downto 0));
				else
					sdata_cal	<= (others => '0');
				end if;
			end if;
		end if;
	end process;

	ohsync			<= shsync_cal;
	ovsync			<= svsync_cal;	
	ohcnt			<= shcnt_cal;	
	ovcnt			<= svcnt_cal;	
	odata			<= sdata_cal(15 downto 0) when sdata_cal(16) = '0' else x"FFFF";
	









	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			sreg_bright_1d		<= (others => '0');
			sreg_bright_2d		<= (others => '0');
			sreg_bright_3d		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			sreg_bright_1d		<= ireg_bright;
			sreg_bright_2d		<= sreg_bright_1d;
			sreg_bright_3d		<= sreg_bright_2d;
		end if;
	end process;

end Behavioral;

