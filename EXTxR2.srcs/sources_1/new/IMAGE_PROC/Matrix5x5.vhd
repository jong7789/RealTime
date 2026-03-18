----------------------------------------------------------------------------------
-- Company: DRT
-- Engineer: bhmoon
-- Create Date: 2021/09/17 09:46:56
-- Module Name: Matrix5x5 - Behavioral
----------------------------------------------------------------------------------

library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.STD_LOGIC_ARITH.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
	use UNISIM.VComponents.all;

entity Matrix5x5 is
	port (
		i_clk  : in    std_logic;
		i_Coef : in    std_logic_vector(16 * 25 - 1 downto 0);

		i_hsyn : in    std_logic;
		i_vsyn : in    std_logic;
		i_hcnt : in    std_logic_vector(12 - 1 downto 0);
		i_vcnt : in    std_logic_vector(12 - 1 downto 0);
		i_data : in    std_logic_vector(16 * 25 - 1 downto 0);

		o_hsyn : out   std_logic;
		o_vsyn : out   std_logic;
		o_hcnt : out   std_logic_vector(12 - 1 downto 0);
		o_vcnt : out   std_logic_vector(12 - 1 downto 0);
		o_data : out   std_logic_vector(17 - 1 downto 0)
	);
end entity matrix5x5;

architecture behavioral of matrix5x5 is

	component mult_u16xs16zs40
		port (
			CLK : in	std_logic;
			A	: in	std_logic_vector(15 downto 0);
			B	: in	std_logic_vector(15 downto 0);
			CE	: in	std_logic;
			P	: out	std_logic_vector(39 downto 0)
		);
	end component;

	component add_s40ADDs40zs40
		port (
			A	: in	std_logic_vector(39 downto 0);
			B	: in	std_logic_vector(39 downto 0);
			CLK : in	std_logic;
			CE	: in	std_logic;
			S	: out	std_logic_vector(39 downto 0)
		);
	end component;

	signal clk : std_logic;

    type  type_25_40b is array (25-1 downto 0) of std_logic_vector(40 - 1 downto 0);

	signal hsyn0 : std_logic;
	signal vsyn0 : std_logic;
	signal hcnt0 : std_logic_vector(12 - 1 downto 0);
	signal vcnt0 : std_logic_vector(12 - 1 downto 0);
	signal data0 : std_logic_vector(16*25 - 1 downto 0);
	signal Coef0 : std_logic_vector(16*25 - 1 downto 0);

	signal hsyn1 : std_logic;
	signal vsyn1 : std_logic;
	signal hcnt1 : std_logic_vector(12 - 1 downto 0);
	signal vcnt1 : std_logic_vector(12 - 1 downto 0);
	signal mult1 : type_25_40b;

	signal hsyn2 : std_logic;
	signal vsyn2 : std_logic;
	signal hcnt2 : std_logic_vector(12 - 1 downto 0);
	signal vcnt2 : std_logic_vector(12 - 1 downto 0);
	signal mult2 : type_25_40b;
	signal add2  : type_25_40b;

	signal hsyn3 : std_logic;
	signal vsyn3 : std_logic;
	signal hcnt3 : std_logic_vector(12 - 1 downto 0);
	signal vcnt3 : std_logic_vector(12 - 1 downto 0);
	signal mult3 : type_25_40b;
	signal add3  : type_25_40b;

	signal hsyn4 : std_logic;
	signal vsyn4 : std_logic;
	signal hcnt4 : std_logic_vector(12 - 1 downto 0);
	signal vcnt4 : std_logic_vector(12 - 1 downto 0);
	signal mult4 : type_25_40b;
	signal add4  : type_25_40b;

	signal hsyn5 : std_logic;
	signal vsyn5 : std_logic;
	signal hcnt5 : std_logic_vector(12 - 1 downto 0);
	signal vcnt5 : std_logic_vector(12 - 1 downto 0);
	-- signal add5  : std_logic_vector(40*2 - 1 downto 0);
	signal add5  : type_25_40b;

	signal hsyn6 : std_logic;
	signal vsyn6 : std_logic;
	signal hcnt6 : std_logic_vector(12 - 1 downto 0);
	signal vcnt6 : std_logic_vector(12 - 1 downto 0);
	signal add6  : std_logic_vector(40*1 - 1 downto 0);

	signal hsyn7   : std_logic;
	signal vsyn7   : std_logic;
	signal hcnt7   : std_logic_vector(12 - 1 downto 0);
	signal vcnt7   : std_logic_vector(12 - 1 downto 0);
	signal result7 : std_logic_vector(17 - 1 downto 0);

	signal result_stat : std_logic_vector(4 - 1 downto 0);
 
-- !begin

begin
	clk <= i_clk;

	process (clk)
	begin
		if clk'event and clk='1' then
  --
  -- # phase 0
			hsyn0 <= i_hsyn;
			vsyn0 <= i_vsyn;
			hcnt0 <= i_hcnt;
			vcnt0 <= i_vcnt;
			data0 <= i_data;
			Coef0 <= i_coef;
  --
		end if;
	end process;

  -- ################
  -- # phase 1 <= 0 #
	process (clk)
	begin
		if clk'event and clk='1' then
			hsyn1 <= hsyn0;
			vsyn1 <= vsyn0;
			hcnt1 <= hcnt0;
			vcnt1 <= vcnt0;
		end if;
	end process;

	gen_mult: for ii in 0 to 25 - 1 generate
		mult : mult_u16xs16zs40
			port map (
				CLK => clk,
				A	=> data0((ii + 1) * 16 - 1 downto ii * 16),
				B	=> Coef0((ii + 1) * 16 - 1 downto ii * 16),
				CE	=> hsyn0,
				P	=> mult1(ii)
			);
	end generate gen_mult;

  -- ################
  -- # phase 2 <= 1 #
	process (clk)
	begin
		if clk'event and clk='1' then
			hsyn2 <= hsyn1;
			vsyn2 <= vsyn1;
			hcnt2 <= hcnt1;
			vcnt2 <= vcnt1;
			mult2 <= mult1;
		end if;
	end process;

	gen_add_step0 : for ii in 0 to 12 - 1 generate
		add_step0 : add_s40ADDs40zs40
			port map (
				CLK => clk,
				A	=> mult1(ii*2  ),
				B	=> mult1(ii*2+1),
				CE	=> hsyn1,
				-- S	=> add2((ii + 1) * 40 - 1 downto ii * 40)
				S	=> add2(ii)
			);
	end generate gen_add_step0;

  -- ################
  -- # phase 3 <= 2 #
	process (clk)
	begin
		if clk'event and clk='1' then
			hsyn3 <= hsyn2;
			vsyn3 <= vsyn2;
			hcnt3 <= hcnt2;
			vcnt3 <= vcnt2;
			mult3 <= mult2;
		end if;
	end process;

	gen_add_step1 : for ii in 0 to 6 - 1 generate
		add_step1 : add_s40ADDs40zs40
			port map (
				CLK => clk,
				A	=> add2(ii*2  ),
				B	=> add2(ii*2+1),
				CE	=> hsyn2,
				S	=> add3(ii)
			);
	end generate gen_add_step1;

  -- ################
  -- # phase 4 <= 3 #
	process (clk)
	begin
		if clk'event and clk='1' then
			hsyn4 <= hsyn3;
			vsyn4 <= vsyn3;
			hcnt4 <= hcnt3;
			vcnt4 <= vcnt3;
			mult4 <= mult3;
		end if;
	end process;

	gen_add_step2 : for ii in 0 to 3 - 1 generate
		add_step2 : add_s40ADDs40zs40
			port map (
				CLK => clk,
				A	=> add3(ii*2  ),
				B	=> add3(ii*2+1),
				CE	=> hsyn3,
				S	=> add4(ii)
			);
	end generate gen_add_step2;

  -- # phase 5 <= 4
	process (clk)
	begin
		if clk'event and clk='1' then
			hsyn5 <= hsyn4;
			vsyn5 <= vsyn4;
			hcnt5 <= hcnt4;
			vcnt5 <= vcnt4;
		end if;
	end process;

	add_step3a : add_s40ADDs40zs40
		port map (
			CLK => clk,
			A	=> add4(0),
			B	=> add4(1),
			CE	=> hsyn4,
			S	=> add5(0)
		);
	add_step3b : add_s40ADDs40zs40
		port map (
			CLK => clk,
			A	=> add4(2),
			B	=> mult4(25-1),
			CE	=> hsyn4,
			S	=> add5(1)
		);

  -- ################
  -- # phase 6 <= 5 #
	process (clk)
	begin
		if clk'event and clk='1' then
			hsyn6 <= hsyn5;
			vsyn6 <= vsyn5;
			hcnt6 <= hcnt5;
			vcnt6 <= vcnt5;
		end if;
	end process;

	add_step4 : add_s40ADDs40zs40
		port map (
			CLK => clk,
			A	=> add5(0),
			B	=> add5(1),
			CE	=> hsyn5,
			S	=> add6 -- 40b
		);

  -- ################
  -- # phase 7 <= 6 #
	process (clk)
	begin
		if clk'event and clk='1' then
	--
			hsyn7 <= hsyn6;
			vsyn7 <= vsyn6;
			hcnt7 <= hcnt6;
			vcnt7 <= vcnt6;
			if add6(add6'high)='1' and add6(add6'high downto 12+17-1)/=x"fff"  then  -- minus cut
				result7 <= '1' & x"0000";
				result_stat <= x"1";
			elsif add6(add6'high)='0' and  add6(add6'high downto 12) > x"ffff"  then -- over cut
				result7 <= '0' & x"ffff"; 
				result_stat <= x"2";
			else
				result7 <= add6(12 + 17 - 1 downto 12);
				result_stat <= x"3";
			end if;
			-- result7 <= add6(12 + 17 - 1 downto 12);
	--
		end if;
	end process;

	o_hsyn <= hsyn7;
	o_vsyn <= vsyn7;
	o_hcnt <= hcnt7;
	o_vcnt <= vcnt7;
	o_data <= result7;

end architecture behavioral;
