library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AXI_WDATA_CONV is
generic (
	DATA_DEPTH 		: integer
);
port(
	iwr_clk			: in	std_logic;
	iwr_rstn		: in	std_logic;

	iwr_en			: in	std_logic;
	iwr_addr		: in	std_logic_vector(11 downto 0);
	iwr_vcnt		: in	std_logic_vector(11 downto 0);
	iwr_data		: in	std_logic_vector(DATA_DEPTH-1 downto 0);

	ird_clk			: in	std_logic;
	ird_rstn		: in	std_logic;

	ird_en			: in	std_logic;
	ird_addr		: in	std_logic_vector(11 downto 0);
	ird_vcnt		: in	std_logic_vector(11 downto 0);
	ord_data		: out	std_logic_vector(511 downto 0)
);
end entity AXI_WDATA_CONV;

architecture behavioral of AXI_WDATA_CONV is

	component DPRAM_64x768_512x96
	port (
		clka			: in	std_logic;
		ena				: in	std_logic;
		wea 			: in	std_logic;
		addra			: in	std_logic_vector(9 downto 0);
		dina 			: in	std_logic_vector(63 downto 0);
		clkb 			: in	std_logic;
		enb 			: in	std_logic;
		addrb			: in	std_logic_vector(6 downto 0);
		doutb			: out	std_logic_vector(511 downto 0)
	);
	end component;

	COMPONENT DPRAM_64x960_512x120 -- 2430 h size -- mbh 210412
	  PORT (
		clka : IN STD_LOGIC;
		ena : IN STD_LOGIC;
		wea : IN STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
		addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		clkb : IN STD_LOGIC;
		enb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(511 DOWNTO 0)
	  );
	END COMPONENT;

	component DPRAM_32x3072_512x192
	port (
		clka			: in	std_logic;
		ena				: in	std_logic;
		wea 			: in	std_logic;
		addra			: in	std_logic_vector(11 downto 0);
		dina 			: in	std_logic_vector(31 downto 0);
		clkb 			: in	std_logic;
		enb 			: in	std_logic;
		addrb			: in	std_logic_vector(7 downto 0);
		doutb			: out	std_logic_vector(511 downto 0)
	);
	end component;

	COMPONENT DPRAM_32x3840_512x240 -- 2430 h size
	  PORT (
		clka : IN STD_LOGIC;
		ena : IN STD_LOGIC;
		wea : IN STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
		addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		clkb : IN STD_LOGIC;
		enb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(511 DOWNTO 0)
	  );
	END COMPONENT;	

	COMPONENT DPRAM_16x4096_512x128
	  PORT (
		clka : IN STD_LOGIC;
		ena : IN STD_LOGIC;
		wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		clkb : IN STD_LOGIC;
		enb : IN STD_LOGIC;
		addrb : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		doutb : OUT STD_LOGIC_VECTOR(511 DOWNTO 0)
	  );
	END COMPONENT;

	signal swr_mem_sel		: std_logic;
	signal srd_mem_sel		: std_logic;

	signal swr_en_odd		: std_logic;
	signal swr_addr_odd		: std_logic_vector(11 downto 0);
	signal swr_data_odd		: std_logic_vector(DATA_DEPTH-1 downto 0);
	signal swr_en_even		: std_logic;
	signal swr_addr_even	: std_logic_vector(11 downto 0);
	signal swr_data_even	: std_logic_vector(DATA_DEPTH-1 downto 0);

	signal srd_en_odd		: std_logic;
	signal srd_addr_odd		: std_logic_vector(11 downto 0);
	signal srd_data_odd		: std_logic_vector(511 downto 0);
	signal srd_en_even		: std_logic;
	signal srd_addr_even	: std_logic_vector(11 downto 0);
	signal srd_data_even	: std_logic_vector(511 downto 0);

	signal swr_mem_sel_1d	: std_logic;
	signal swr_mem_sel_2d	: std_logic;
	signal swr_mem_sel_3d	: std_logic;
	signal srd_mem_sel_1d	: std_logic;
	signal srd_mem_sel_2d	: std_logic;
	signal srd_mem_sel_3d	: std_logic;

begin

	process(iwr_clk, iwr_rstn)
	begin
		if(iwr_rstn = '0') then
			swr_mem_sel			<= '0';
			swr_mem_sel_1d		<= '0';
			swr_mem_sel_2d		<= '0';
			swr_mem_sel_3d		<= '0';
		elsif(iwr_clk'event and iwr_clk = '1') then
			swr_mem_sel			<= iwr_vcnt(0);
			swr_mem_sel_1d		<= swr_mem_sel;	   
			swr_mem_sel_2d		<= swr_mem_sel_1d; 
			swr_mem_sel_3d		<= swr_mem_sel_2d; 
		end if;
	end process;

	process(ird_clk, ird_rstn)
	begin
		if(ird_rstn = '0') then
			srd_mem_sel			<= '0';
			srd_mem_sel_1d		<= '0';
			srd_mem_sel_2d		<= '0';
			srd_mem_sel_3d		<= '0';
		elsif(ird_clk'event and ird_clk = '1') then
			srd_mem_sel			<= ird_vcnt(0);
			srd_mem_sel_1d		<= srd_mem_sel;	   
			srd_mem_sel_2d		<= srd_mem_sel_1d; 
			srd_mem_sel_3d		<= srd_mem_sel_2d; 
		end if;
	end process;

	swr_en_odd			<= iwr_en 		when swr_mem_sel_3d = '0' else '0';
	swr_addr_odd		<= iwr_addr		when swr_mem_sel_3d = '0' else (others => '0');
	swr_data_odd		<= iwr_data		when swr_mem_sel_3d = '0' else (others => '0');

	swr_en_even			<= iwr_en 		when swr_mem_sel_3d = '1' else '0';
	swr_addr_even		<= iwr_addr		when swr_mem_sel_3d = '1' else (others => '0');
	swr_data_even		<= iwr_data		when swr_mem_sel_3d = '1' else (others => '0');

	srd_en_odd			<= ird_en 		when srd_mem_sel_3d = '0' else '0';
	srd_addr_odd		<= ird_addr		when srd_mem_sel_3d = '0' else (others => '0');

	srd_en_even			<= ird_en 		when srd_mem_sel_3d = '1' else '0';
	srd_addr_even		<= ird_addr		when srd_mem_sel_3d = '1' else (others => '0');

	WIDTH_64_GEN : if(DATA_DEPTH = 64) generate
	begin
--		ODD_DPRAM_64x768_512x96 : DPRAM_64x768_512x96
		ODD_DPRAM_64x960_512x120 : DPRAM_64x960_512x120
		port map (
			clka 		=> iwr_clk, 		
			wea 		=> '1',
			ena 		=> swr_en_odd, 		
			addra 		=> swr_addr_odd(9 downto 0),
			dina 		=> swr_data_odd,
			clkb 		=> ird_clk, 		
			enb 		=> srd_en_odd, 		
			addrb 		=> srd_addr_odd(6 downto 0), 	
			doutb 		=> srd_data_odd 	
		);

--		EVEN_DPRAM_64x768_512x96 : DPRAM_64x768_512x96
		EVEN_DPRAM_64x960_512x120 : DPRAM_64x960_512x120
		port map (
			clka 		=> iwr_clk, 		
			wea 		=> '1',
			ena 		=> swr_en_even, 		
			addra 		=> swr_addr_even(9 downto 0),
			dina 		=> swr_data_even,
			clkb 		=> ird_clk, 		
			enb 		=> srd_en_even, 		
			addrb 		=> srd_addr_even(6 downto 0), 	
			doutb 		=> srd_data_even 	
		);
	end generate;

	WIDTH_32_GEN : if(DATA_DEPTH = 32) generate
	begin
--		ODD_DPRAM_32x3072_512x192 : DPRAM_32x3072_512x192
		ODD_DPRAM_32x3840_512x240 : DPRAM_32x3840_512x240
		port map (
			clka 		=> iwr_clk, 		
			wea 		=> '1',
			ena 		=> swr_en_odd, 		
			addra 		=> swr_addr_odd,
			dina 		=> swr_data_odd,
			clkb 		=> ird_clk, 		
			enb 		=> srd_en_odd, 		
			addrb 		=> srd_addr_odd(7 downto 0),
			doutb 		=> srd_data_odd 	
		);

--		EVEN_DPRAM_32x3072_512x192 : DPRAM_32x3072_512x192
		EVEN_DPRAM_32x3840_512x240 : DPRAM_32x3840_512x240
		port map (
			clka 		=> iwr_clk, 		
			wea 		=> '1',
			ena 		=> swr_en_even, 		
			addra 		=> swr_addr_even,
			dina 		=> swr_data_even,
			clkb 		=> ird_clk, 		
			enb 		=> srd_en_even, 		
			addrb 		=> srd_addr_even(7 downto 0),
			doutb 		=> srd_data_even 	
		);
	end generate;

	WIDTH_16_GEN : if(DATA_DEPTH = 16) generate
	begin
		ODD_DPRAM_16x4096_512x128 : DPRAM_16x4096_512x128
		port map (
			clka 		=> iwr_clk, 		
			wea(0)		=> '1',
			ena 		=> swr_en_odd, 		
			addra 		=> swr_addr_odd,
			dina 		=> swr_data_odd,
			clkb 		=> ird_clk, 		
			enb 		=> srd_en_odd, 		
			addrb 		=> srd_addr_odd(6 downto 0),
			doutb 		=> srd_data_odd 	
		);

		EVEN_DPRAM_16x4096_512x128 : DPRAM_16x4096_512x128
		port map (
			clka 		=> iwr_clk, 		
			wea(0) 		=> '1',
			ena 		=> swr_en_even, 		
			addra 		=> swr_addr_even,
			dina 		=> swr_data_even,
			clkb 		=> ird_clk, 		
			enb 		=> srd_en_even, 		
			addrb 		=> srd_addr_even(6 downto 0),
			doutb 		=> srd_data_even 	
		);
	end generate;
	ord_data			<= srd_data_odd when srd_mem_sel_3d = '0' else 
						   srd_data_even;

end architecture behavioral;
