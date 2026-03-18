library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity MODULE_RESET is
port (
	iclk		: in	std_logic;			  		
	irstn		: in	std_logic;			  		

	orstn		: out	std_logic
);
end MODULE_RESET;
	
architecture Behavioral of MODULE_RESET is

	signal srstn			: std_logic;
	signal scnt				: std_logic_vector(31 downto 0);

begin

	process(iclk, irstn)
	begin
		if(irstn = '0') then
			scnt		<= (others => '0');
			srstn		<= '0';
		elsif(iclk'event and iclk = '1') then
			if(	(SIMULATION = "ON"	and scnt >= x"FF") or
				(SIMULATION = "OFF" and scnt >= x"FFFF")) then
				srstn		<= '1';
			else
				scnt		<= scnt + '1';
			end if;
		end if;
	end process;

	orstn			<= srstn;

end Behavioral;
