----------------------------------------------------------------------------------
-- Company: DRT
-- Engineer: bhmoon
-- Create Date: 2021/09/13 12:03:48
----------------------------------------------------------------------------------

library IEEE;
	use IEEE.STD_LOGIC_1164.ALL;
	use IEEE.STD_LOGIC_ARITH.ALL;
	use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
	use UNISIM.VComponents.all;

entity Mawari5x5 is
	port (
		i_clk		 : in	 std_logic;
		i_RegHActive : in	 std_logic_vector(12 - 1 downto 0);
		i_RegVActive : in	 std_logic_vector(12 - 1 downto 0);

		i_hsyn : in    std_logic;
		i_vsyn : in    std_logic;
		i_hcnt : in    std_logic_vector(12 - 1 downto 0);
		i_vcnt : in    std_logic_vector(12 - 1 downto 0);
		i_data : in    std_logic_vector(16 - 1 downto 0);

		o_hsyn : out   std_logic;
		o_vsyn : out   std_logic;
		o_hcnt : out   std_logic_vector(12 - 1 downto 0);
		o_vcnt : out   std_logic_vector(12 - 1 downto 0);
		o_data : out   std_logic_vector(16 * 25 - 1 downto 0)
	);
end entity mawari5x5;

architecture behavioral of mawari5x5 is

	component blk_mem_16x4096
		port (
			clka  : in	  std_logic;
			wea   : in	  std_logic_vector(0 downto 0);
			addra : in	  std_logic_vector(11 downto 0);
			dina  : in	  std_logic_vector(15 downto 0);
			clkb  : in	  std_logic;
			enb   : in	  std_logic;
			addrb : in	  std_logic_vector(11 downto 0);
			doutb : out   std_logic_vector(15 downto 0)
		);
	end component;

	constant LineBuff : integer := 5;
	signal	 clk	  : std_logic;

	type   type_reg12b is array (4 - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
	signal RegHActiveArr : type_reg12b;
	signal RegVActiveArr : type_reg12b;

	signal RegHActive	     : std_logic_vector(12 - 1 downto 0) := (others => '0');
	signal RegVActive	     : std_logic_vector(12 - 1 downto 0) := (others => '0');
	signal RegHActiveMinus1	 : std_logic_vector(12 - 1 downto 0) := (others => '0');
	signal RegVActiveMinus1	 : std_logic_vector(12 - 1 downto 0) := (others => '0');
	signal RegHActiveMinus2	 : std_logic_vector(12 - 1 downto 0) := (others => '0');
	signal RegVActiveMinus2	 : std_logic_vector(12 - 1 downto 0) := (others => '0');

	signal wwea  : std_logic_vector(4 downto 0) := (others => '0');
	signal addra : std_logic_vector(11 downto 0) := (others => '0');
	signal dina  : std_logic_vector(15 downto 0) := (others => '0');
	signal clkb  : std_logic := '0';
	signal enb	 : std_logic := '0';
	signal addrb : std_logic_vector(11 downto 0) := (others => '0');

	type   type_doutb is array (LineBuff - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
	signal doutb  : type_doutb;
	signal doutb0 : type_doutb;
	signal doutb1 : type_doutb;
	signal doutb2 : type_doutb;
	signal doutb3 : type_doutb;
	signal doutb4 : type_doutb;
	signal doutb5 : type_doutb;
	signal doutb6 : type_doutb;

	signal HSyn  : std_logic;
	signal VSyn  : std_logic;
	signal HCnt  : std_logic_vector(12 - 1 downto 0);
	signal VCnt  : std_logic_vector(12 - 1 downto 0);
	signal VCnt0 : std_logic_vector(12 - 1 downto 0);
	signal DAta  : std_logic_vector(16 - 1 downto 0);
	signal HSyn0 : std_logic;
	signal VSyn0 : std_logic;

	signal HTotal	 : std_logic_vector(16 - 1 downto 0) := (others => '0');
	signal HTotalCnt : std_logic_vector(16 - 1 downto 0) := (others => '0');
	signal SyncStart : std_logic:= '0';
	signal GenHCnt	 : std_logic_vector(16 - 1 downto 0) := (others => '1');
	signal GenHCnt0  : std_logic_vector(16 - 1 downto 0) := (others => '1');
	signal GenHSyn0  : std_logic:= '0';
	signal GenVCnt	 : std_logic_vector(16 - 1 downto 0) := (others => '1');
	signal GenVCnt0  : std_logic_vector(16 - 1 downto 0) := (others => '1');
	signal GenVSyn0  : std_logic:= '0';

	signal GenHSynArr : std_logic_vector(8 - 1 downto 0) := (others => '0');
	signal GenVSynArr : std_logic_vector(8 - 1 downto 0) := (others => '0');

	type   type_gencntarr is array (8 - 1 downto 0) of std_logic_vector(12 - 1 downto 0);
	signal GenVCntArr : type_gencntarr;
	signal GenHCntArr : type_gencntarr;

	type type_2data is array (0 to 4) of std_logic_vector(16 - 1 downto 0);

	type   type_3data is array (0 to 4) of type_2data;
	signal d3data : type_3data;

	signal BrHSyn : std_logic;
	signal BrVSyn : std_logic;
	signal BrHCnt : std_logic_vector(12 - 1 downto 0);
	signal BrVCnt : std_logic_vector(12 - 1 downto 0);
	signal BrD5x5 : std_logic_vector(16*25 - 1 downto 0);
	signal Cnt5   : std_logic_vector(4 - 1 downto 0);

-- !begin

begin
	clk <= i_clk;

	process (clk)
	begin
		if clk'event and clk='1' then
  --
			RegHActiveArr <= RegHActiveArr(RegHActiveArr'high - 1 downto 0) & i_RegHActive;
			RegVActiveArr <= RegVActiveArr(RegVActiveArr'high - 1 downto 0) & i_RegVActive;
			RegHActive	  <= RegHActiveArr(RegHActiveArr'high);
			RegVActive	  <= RegVActiveArr(RegVActiveArr'high);
  -- # phase 0
			HSyn <= i_hsyn;
			VSyn <= i_vsyn;
			HCnt <= i_hcnt;
			VCnt <= i_vcnt;
			DAta <= i_data;
 RegHActiveMinus1<= RegHActive + x"FFF"; 
 RegVActiveMinus1<= RegVActive + x"FFF";
 RegHActiveMinus2<= RegHActive + x"FFE"; 
 RegVActiveMinus2<= RegVActive + x"FFE";
  -- # phase 1
			HSyn0 <= HSyn;
			VSyn0 <= VSyn;
			VCnt0 <= VCnt;

  -- # wea roatation
			if VCnt=0 then
				wwea <= b"10000";
			elsif VCnt0 /= VCnt then
				wwea <= wwea(0) & wwea(4 downto 1);
			end if;
			addra <= HCnt;
			dina  <= DAta;

  -- # start position
			if VCnt = 2 and HCnt = 1 then
				SyncStart <= '1';
			else
				SyncStart <= '0';
			end if;

  -- # cnt H total
			-- if 0<VCnt and VCnt<4 then
--			if VCnt=1 or VCnt=2 then
			if VCnt=4 then --# 231212
				if HSyn0='0' and HSyn='1' then
					HTotal	  <= HTotalCnt;
					HTotalCnt <= x"0000"; --(others=> '0');
				else
					HTotalCnt <= HTotalCnt + '1';
				end if;
			end if;

  -- # H V Cnt
			if SyncStart = '1' then
				GenHCnt <= (others => '0');
				GenVCnt <= (others => '0');
			else
				if GenVCnt < RegVActive then
					if GenHCnt < HTotal then
						GenHCnt <= GenHCnt + '1';
					else
						GenHCnt <= (others => '0');
						GenVCnt <= GenVCnt + '1';
					end if;
				end if;
			end if;

  -- # sync gen
			GenHCnt0 <= GenHCnt;
			GenVCnt0 <= GenVCnt;
			if	GenVCnt < RegVActive and
  GenHCnt < RegHActive then
				GenHSyn0 <= '1';
			else
				GenHSyn0 <= '0';
			end if;
			
			if SyncStart = '1' then --# preventing non Vsync 231212
			    GenVSyn0 <= '0';
			elsif GenVCnt < RegVActive then
				GenVSyn0 <= '1';
			else
				GenVSyn0 <= '0';
			end if;

  --
		end if;
	end process;

	gen_bram: for ii in 0 to 4 generate
		u_blk_mem_16x4096a : blk_mem_16x4096
			port map (
				clka  => clk,
				wea(0)=> wwea(ii),
				addra => addra,
				dina  => dina,
				clkb  => clk,
				enb   => enb,
				addrb => addrb,
				doutb => doutb(ii)
			);
	end generate gen_bram;

	enb   <= '1';
	addrb <= GenHCnt0(12-1 downto 0);

	process (clk)
	begin
		if clk'event and clk='1' then
  --
			GenVSynArr <= GenVSynArr(GenVSynArr'high - 1 downto 0) & GenVSyn0;
			GenHSynArr <= GenHSynArr(GenHSynArr'high - 1 downto 0) & GenHSyn0;
			GenVCntArr <= GenVCntArr(GenVCntArr'high - 1 downto 0) & GenVCnt0(12-1 downto 0);
			GenHCntArr <= GenHCntArr(GenHCntArr'high - 1 downto 0) & GenHCnt0(12-1 downto 0);
			if GenVCnt0 = 0 then
				Cnt5 <= (others=> '0');
			elsif GenVCntArr(0) < GenVCnt0 then
				if Cnt5 < 5 - 1 then
					Cnt5 <= Cnt5 + '1';
				else
					Cnt5 <= x"0";
				end if;
			end if;

	-- phase 1 <= 0
	-- ### line roll up
			if	  Cnt5 = 2 then doutb1(4)<=doutb(4); doutb1(3)<=doutb(3); doutb1(2)<=doutb(2); doutb1(1)<=doutb(1); doutb1(0)<=doutb(0);
			elsif Cnt5 = 3 then doutb1(4)<=doutb(3); doutb1(3)<=doutb(2); doutb1(2)<=doutb(1); doutb1(1)<=doutb(0); doutb1(0)<=doutb(4);
			elsif Cnt5 = 4 then doutb1(4)<=doutb(2); doutb1(3)<=doutb(1); doutb1(2)<=doutb(0); doutb1(1)<=doutb(4); doutb1(0)<=doutb(3);
			elsif Cnt5 = 0 then doutb1(4)<=doutb(1); doutb1(3)<=doutb(0); doutb1(2)<=doutb(4); doutb1(1)<=doutb(3); doutb1(0)<=doutb(2);
			elsif Cnt5 = 1 then doutb1(4)<=doutb(0); doutb1(3)<=doutb(4); doutb1(2)<=doutb(3); doutb1(1)<=doutb(2); doutb1(0)<=doutb(1);
			end if;

	-- phase 2 <= 1
	-- ### Row line copy
			if	  GenVCntArr(1)=0 then				doutb2(4)<=doutb1(2); doutb2(3)<=doutb1(2); doutb2(2)<=doutb1(2); doutb2(1)<=doutb1(1); doutb2(0)<=doutb1(0);
			elsif GenVCntArr(1)=1 then				doutb2(4)<=doutb1(3); doutb2(3)<=doutb1(3); doutb2(2)<=doutb1(2); doutb2(1)<=doutb1(1); doutb2(0)<=doutb1(0);
			elsif GenVCntArr(1)=RegVActiveMinus2 then doutb2(4)<=doutb1(4); doutb2(3)<=doutb1(3); doutb2(2)<=doutb1(2); doutb2(1)<=doutb1(1); doutb2(0)<=doutb1(1);
			elsif GenVCntArr(1)=RegVActiveMinus1 then doutb2(4)<=doutb1(4); doutb2(3)<=doutb1(3); doutb2(2)<=doutb1(2); doutb2(1)<=doutb1(2); doutb2(0)<=doutb1(2);
			else									doutb2(4)<=doutb1(4); doutb2(3)<=doutb1(3); doutb2(2)<=doutb1(2); doutb2(1)<=doutb1(1); doutb2(0)<=doutb1(0);
			end if;

	-- phase 3,4,5
			doutb3 <= doutb2;
			doutb4 <= doutb3;
			doutb5 <= doutb4;
			doutb6 <= doutb5;

	  -- phase 5 <= 4
	-- ### Column line copy
			BrVSyn <= GenVSynArr(4);
			BrHSyn <= GenHSynArr(4);
			BrVCnt <= GenVCntArr(4);
			BrHCnt <= GenHCntArr(4);
			if GenHCntArr(4)=0 then					-- line first
				BrD5x5 <= doutb4(4) & doutb4(4) & doutb4(4) & doutb3(4) & doutb2(4) &
						  doutb4(3) & doutb4(3) & doutb4(3) & doutb3(3) & doutb2(3) &
						  doutb4(2) & doutb4(2) & doutb4(2) & doutb3(2) & doutb2(2) &
						  doutb4(1) & doutb4(1) & doutb4(1) & doutb3(1) & doutb2(1) &
						  doutb4(0) & doutb4(0) & doutb4(0) & doutb3(0) & doutb2(0);
			elsif GenHCntArr(4)=1 then				-- line next first
				BrD5x5 <= doutb5(4) & doutb5(4) & doutb4(4) & doutb3(4) & doutb2(4) &
						  doutb5(3) & doutb5(3) & doutb4(3) & doutb3(3) & doutb2(3) &
						  doutb5(2) & doutb5(2) & doutb4(2) & doutb3(2) & doutb2(2) &
						  doutb5(1) & doutb5(1) & doutb4(1) & doutb3(1) & doutb2(1) &
						  doutb5(0) & doutb5(0) & doutb4(0) & doutb3(0) & doutb2(0);
			elsif GenHCntArr(4)=RegHActiveMinus2 then -- line before last
				BrD5x5 <= doutb6(4) & doutb5(4) & doutb4(4) & doutb3(4) & doutb3(4) &
						  doutb6(3) & doutb5(3) & doutb4(3) & doutb3(3) & doutb3(3) &
						  doutb6(2) & doutb5(2) & doutb4(2) & doutb3(2) & doutb3(2) &
						  doutb6(1) & doutb5(1) & doutb4(1) & doutb3(1) & doutb3(1) &
						  doutb6(0) & doutb5(0) & doutb4(0) & doutb3(0) & doutb3(0);
			elsif GenHCntArr(4)=RegHActiveMinus1 then -- line last
				BrD5x5 <= doutb6(4) & doutb5(4) & doutb4(4) & doutb4(4) & doutb4(4) &
						  doutb6(3) & doutb5(3) & doutb4(3) & doutb4(3) & doutb4(3) &
						  doutb6(2) & doutb5(2) & doutb4(2) & doutb4(2) & doutb4(2) &
						  doutb6(1) & doutb5(1) & doutb4(1) & doutb4(1) & doutb4(1) &
						  doutb6(0) & doutb5(0) & doutb4(0) & doutb4(0) & doutb4(0);
			else
				BrD5x5 <= doutb6(4) & doutb5(4) & doutb4(4) & doutb3(4) & doutb2(4) &
						  doutb6(3) & doutb5(3) & doutb4(3) & doutb3(3) & doutb2(3) &
						  doutb6(2) & doutb5(2) & doutb4(2) & doutb3(2) & doutb2(2) &
						  doutb6(1) & doutb5(1) & doutb4(1) & doutb3(1) & doutb2(1) &
						  doutb6(0) & doutb5(0) & doutb4(0) & doutb3(0) & doutb2(0);
			end if;

			o_vsyn <= BrVSyn;
			o_hsyn <= BrHSyn;
			o_vcnt <= BrVCnt;
			o_hcnt <= BrHCnt;
			o_data <= BrD5x5;

  --
		end if;
	end process;

	d3data(0)(0) <= BrD5x5(16 * 25 - 1 downto 16 * 24);
	d3data(0)(1) <= BrD5x5(16 * 24 - 1 downto 16 * 23);
	d3data(0)(2) <= BrD5x5(16 * 23 - 1 downto 16 * 22);
	d3data(0)(3) <= BrD5x5(16 * 22 - 1 downto 16 * 21);
	d3data(0)(4) <= BrD5x5(16 * 21 - 1 downto 16 * 20);
	d3data(1)(0) <= BrD5x5(16 * 20 - 1 downto 16 * 19);
	d3data(1)(1) <= BrD5x5(16 * 19 - 1 downto 16 * 18);
	d3data(1)(2) <= BrD5x5(16 * 18 - 1 downto 16 * 17);
	d3data(1)(3) <= BrD5x5(16 * 17 - 1 downto 16 * 16);
	d3data(1)(4) <= BrD5x5(16 * 16 - 1 downto 16 * 15);
	d3data(2)(0) <= BrD5x5(16 * 15 - 1 downto 16 * 14);
	d3data(2)(1) <= BrD5x5(16 * 14 - 1 downto 16 * 13);
	d3data(2)(2) <= BrD5x5(16 * 13 - 1 downto 16 * 12);
	d3data(2)(3) <= BrD5x5(16 * 12 - 1 downto 16 * 11);
	d3data(2)(4) <= BrD5x5(16 * 11 - 1 downto 16 * 10);
	d3data(3)(0) <= BrD5x5(16 * 10 - 1 downto 16 * 9);
	d3data(3)(1) <= BrD5x5(16 * 9 - 1 downto 16 * 8);
	d3data(3)(2) <= BrD5x5(16 * 8 - 1 downto 16 * 7);
	d3data(3)(3) <= BrD5x5(16 * 7 - 1 downto 16 * 6);
	d3data(3)(4) <= BrD5x5(16 * 6 - 1 downto 16 * 5);
	d3data(4)(0) <= BrD5x5(16 * 5 - 1 downto 16 * 4);
	d3data(4)(1) <= BrD5x5(16 * 4 - 1 downto 16 * 3);
	d3data(4)(2) <= BrD5x5(16 * 3 - 1 downto 16 * 2);
	d3data(4)(3) <= BrD5x5(16 * 2 - 1 downto 16 * 1);
	d3data(4)(4) <= BrD5x5(16 * 1 - 1 downto 16 * 0);

end architecture behavioral;
