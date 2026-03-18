library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity RAM_512x2048 is
port(
	clka 		: in	std_logic;
	ena			: in	std_logic;
	wea 		: in	std_logic;
	addra		: in	std_logic_vector(10 downto 0);
	dina 		: in	std_logic_vector(511 downto 0);
	clkb	 	: in	std_logic;
	enb 		: in	std_logic;
	addrb 		: in	std_logic_vector(10 downto 0);
	doutb 		: out 	std_logic_vector(511 downto 0)
);
end RAM_512x2048;

architecture Behavioral of RAM_512x2048 is

	type mem_data		is array(0 to 2047) of std_logic_vector(511 downto 0);
	signal sdina		: mem_data := (others => (others => '0'));
	signal saddra		: integer range 0 to 2047 := 0;
	signal saddrb		: integer range 0 to 2047 := 0;

begin

	saddra		<= conv_integer(addra);
	saddrb		<= conv_integer(addrb);
	
	process(clka)
	begin
		if(clka'event and clka = '1') then
			if(ena = '1') then
				sdina(saddra)		<= dina;
			end if;
		end if;
	end process;

	process(clkb)
	begin
		if(clkb'event and clkb = '1') then
			if(enb = '1') then
				doutb		<= sdina(saddrb);
			end if;
		end if;
	end process;

end Behavioral;
