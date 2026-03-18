
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity DPRAM_16x128_64x32 is
port(
    clka    : in  std_logic;
    wea     : in  std_logic;
    ena     : in  std_logic;
    addra   : in  std_logic_vector(6 downto 0);  --$ 7-bit: 128 channels
    dina    : in  std_logic_vector(15 downto 0);
    toggle  : in  std_logic;
    clkb    : in  std_logic;
    enb     : in  std_logic;
    addrb   : in  std_logic_vector(4 downto 0);  --$ 5-bit: 32 entries
    doutb   : out std_logic_vector(63 downto 0)
);
end DPRAM_16x128_64x32;

architecture Behavioral of DPRAM_16x128_64x32 is

	component RAM_64x32
	port (
		clk			: in	std_logic;
		we 			: in	std_logic;
		a			: in	std_logic_vector(4 downto 0);
		d			: in	std_logic_vector(63 downto 0);
		qdpo_clk	: in	std_logic;
		dpra 		: in	std_logic_vector(4 downto 0);
		qdpo		: out	std_logic_vector(63 downto 0)
	);
	end component;
	    

    signal swe : std_logic := '0';
    signal sa  : std_logic_vector(4 downto 0) := (others => '0');
    signal sd  : std_logic_vector(63 downto 0) := (others => '0');

begin

    process(clka)
    begin
        if(clka'event and clka = '1') then
            if(ena = '1') then
                if(toggle = '0') then --$ Single ROIC
                    if(addra(1 downto 0) = "00") then
                        sd(15 downto 0) <= dina;
                        swe <= '0';
                    elsif(addra(1 downto 0) = "01") then
                        sd(31 downto 16) <= dina;
                        swe <= '0';
                    elsif(addra(1 downto 0) = "10") then
                        sd(47 downto 32) <= dina;
                        swe <= '0';
                    else
                        sd(63 downto 48) <= dina;
                        swe <= '1';
                    end if;
                else              --$ Dual ROIC
                    if(addra(1 downto 0) = "00") then
                        sd(15 downto 0) <= dina;
                        swe <= '1';
                    elsif(addra(1 downto 0) = "01") then
                        sd(31 downto 16) <= dina;
                        swe <= '0';
                    elsif(addra(1 downto 0) = "10") then
                        sd(47 downto 32) <= dina;
                        swe <= '0';
                    else
                        sd(63 downto 48) <= dina;
                        swe <= '0';
                    end if;
                end if;
            else
                swe <= '0';
            end if;
            sa <= addra(6 downto 2);  --$ 5-bit entry address
        end if;
    end process;

    U0_RAM_64x32 : RAM_64x32
	port map (
		clk			=> clka,
		we 			=> swe,
		a			=> sa,
		d			=> sd,
		qdpo_clk	=> clkb,
		dpra 		=> addrb,
		qdpo		=> doutb
	);
  
end Behavioral;
