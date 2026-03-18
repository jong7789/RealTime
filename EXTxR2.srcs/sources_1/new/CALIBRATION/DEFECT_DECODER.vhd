library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity DEFECT_DECODER is
port (
	idata_clk		: in	std_logic;
	idata_rstn		: in	std_logic;

	idefect_data	: in	std_logic_vector(7 downto 0);

	ihsync			: in	std_logic;
	ivsync			: in	std_logic;
	ihcnt			: in	std_logic_vector(11 downto 0);
	ivcnt			: in	std_logic_vector(11 downto 0);
	idata_1x1		: in	std_logic_vector(15 downto 0);
	idata_1x2		: in	std_logic_vector(15 downto 0);
	idata_1x3		: in	std_logic_vector(15 downto 0);
	idata_2x1		: in	std_logic_vector(15 downto 0);
	idata_2x2		: in	std_logic_vector(15 downto 0);
	idata_2x3		: in	std_logic_vector(15 downto 0);
	idata_3x1		: in	std_logic_vector(15 downto 0);
	idata_3x2		: in	std_logic_vector(15 downto 0);
	idata_3x3		: in	std_logic_vector(15 downto 0);

	ohsync			: out	std_logic;
	ovsync			: out	std_logic;
	ohcnt			: out	std_logic_vector(11 downto 0);
	ovcnt			: out	std_logic_vector(11 downto 0);
	odata			: out	std_logic_vector(15 downto 0);

	odata_sum		: out	std_logic_vector(18 downto 0);
	odata_mul		: out	std_logic_vector(17 downto 0)
);
end DEFECT_DECODER;

architecture Behavioral of DEFECT_DECODER is

	type tdata_arr			is array (0 to 7) of std_logic_vector(18 downto 0);
	type tdefect_arr		is array (0 to 7) of std_logic_vector(3 downto 0);
	signal sdata_arr		: tdata_arr;
	signal sdata_mask		: tdata_arr;
	signal sdefect_arr		: tdefect_arr;
	
	signal sdefect_data		: std_logic_vector(7 downto 0);

	signal sdiv_num			: std_logic_vector(3 downto 0);
	signal sdiv_data		: std_logic_vector(18 downto 0);

	signal shsync_out		: std_logic;
	signal svsync_out		: std_logic;
	signal svcnt_out		: std_logic_vector(11 downto 0);
	signal shcnt_out		: std_logic_vector(11 downto 0);
	signal sdata_out		: std_logic_vector(15 downto 0);
	signal sdata_sum		: std_logic_vector(18 downto 0);
	signal sdata_mul		: std_logic_vector(17 downto 0);

	signal shsync_1d		: std_logic;
	signal svsync_1d		: std_logic;
	signal svcnt_1d			: std_logic_vector(11 downto 0);
	signal shcnt_1d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_1d		: std_logic_vector(15 downto 0);

begin

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			sdata_arr		<= (others => (others => '0'));
			sdefect_arr		<= (others => (others => '0'));
			sdefect_data	<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			sdata_arr(7)		<= "000" & idata_3x3;
			sdata_arr(6)		<= "000" & idata_3x2;
			sdata_arr(5)		<= "000" & idata_3x1;
			sdata_arr(4)		<= "000" & idata_2x3;
			sdata_arr(3)		<= "000" & idata_2x1;
			sdata_arr(2)		<= "000" & idata_1x3;
			sdata_arr(1)		<= "000" & idata_1x2;
			sdata_arr(0)		<= "000" & idata_1x1;
			
			sdefect_arr(7)		<= "000" & idefect_data(7);
			sdefect_arr(6)		<= "000" & idefect_data(6);
			sdefect_arr(5)		<= "000" & idefect_data(5);
			sdefect_arr(4)		<= "000" & idefect_data(4);
			sdefect_arr(3)		<= "000" & idefect_data(3);
			sdefect_arr(2)		<= "000" & idefect_data(2);
			sdefect_arr(1)		<= "000" & idefect_data(1);
			sdefect_arr(0)		<= "000" & idefect_data(0);

			sdefect_data		<= idefect_data;
		end if;
	end process;

	data_gen : for i in 0 to 7 generate
		sdata_mask(i)		<= sdata_arr(i) when sdefect_data(i) = '1' else (others => '0');
	end generate;

	sdiv_num 		<= (sdefect_arr(7) + sdefect_arr(6) + sdefect_arr(5) + sdefect_arr(4) + sdefect_arr(3) + sdefect_arr(2) + sdefect_arr(1) + sdefect_arr(0));
	sdiv_data		<= (sdata_mask(0) + sdata_mask(1) + sdata_mask(2) + sdata_mask(3) + sdata_mask(4) + sdata_mask(5) + sdata_mask(6) + sdata_mask(7));

	process(idata_clk, idata_rstn)
	begin	
		if(idata_rstn = '0') then
			shsync_out		<= '0';
			svsync_out		<= '0';
			shcnt_out		<= (others => '0');
			svcnt_out		<= (others => '0');
			sdata_out		<= (others => '0');

			sdata_sum		<= (others => '0'); 
			sdata_mul		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			shsync_out		<= shsync_1d;	
			svsync_out		<= svsync_1d;	
			shcnt_out		<= shcnt_1d;
			svcnt_out		<= svcnt_1d; 
			sdata_out		<= sdata_2x2_1d;

			if(shsync_1d = '1') then
				if(sdiv_num > 0) then
					sdata_sum		<= sdiv_data;
				else
					sdata_sum		<= "000" & sdata_2x2_1d;
				end if;

				case (sdiv_num) is
					when "0001"		=> sdata_mul		<= "01" & x"0000";		-- / 1
					when "0010"		=> sdata_mul		<= "00" & x"8000";		-- / 2
					when "0011"		=> sdata_mul		<= "00" & x"5555";		-- / 3
					when "0100"		=> sdata_mul		<= "00" & x"4000";		-- / 4
					when "0101"		=> sdata_mul		<= "00" & x"3333";		-- / 5
					when "0110"		=> sdata_mul		<= "00" & x"2AAA";		-- / 6
					when "0111"		=> sdata_mul		<= "00" & x"2492";		-- / 7
					when "1000"		=> sdata_mul		<= "00" & x"2000";		-- / 8
					when others		=> sdata_mul		<= "01" & x"0000";		-- / No Value
				end case;
			end if;
		end if;
	end process;

	ohsync			<= shsync_out;	 
	ovsync			<= svsync_out;	 
	ohcnt			<= shcnt_out;
	ovcnt			<= svcnt_out; 
	odata			<= sdata_out;

	odata_sum		<= sdata_sum;
	odata_mul		<= sdata_mul;




	process(idata_clk, idata_rstn)
	begin	
		if(idata_rstn = '0') then
			shsync_1d		<= '0';
			svsync_1d		<= '0';
			svcnt_1d		<= (others => '0');
			shcnt_1d		<= (others => '0');
			sdata_2x2_1d	<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			shsync_1d		<= ihsync;		
			svsync_1d		<= ivsync;		
			svcnt_1d		<= ivcnt;		
			shcnt_1d		<= ihcnt;		
			sdata_2x2_1d	<= idata_2x2;	
		end if;
	end process;

end Behavioral;

