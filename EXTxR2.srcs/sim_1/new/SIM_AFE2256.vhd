library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;

entity SIM_AFE2256 is
  generic ( GNR_MODEL : string  := "EXT1616R" );
port (
	iroic_mclk			: in	std_logic;

	iroic_sync			: in	std_logic;
	iroic_tp_sel		: in	std_logic;
	ialign_done			: in	std_logic;

	oroic_data			: out	std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
	oroic_dclk			: out	std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
	oroic_fclk			: out	std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0)
);
end SIM_AFE2256;
	
architecture Behavioral of SIM_AFE2256 is

component tb_clk_roic_240
port
 (-- Clock in ports
  -- Clock out ports
  clk_out1          : out    std_logic;
  -- Status and control signals
  reset             : in     std_logic;
  locked            : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;

	type tstate_roic		is	(
									s_IDLE,
									s_AFE,
									s_WAIT,
									s_DATA
								);

	signal state_roic		: tstate_roic := s_IDLE;
	signal smain_clk		: std_logic := '0';
	signal sroic_fclk		: std_logic := '0';
	signal sdiv_cnt			: std_logic_vector(3 downto 0) := (others => '0');
	signal sroic_cnt		: std_logic_vector(7 downto 0) := (others => '0');
	type tdata_arr			is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(23 downto 0);		
	signal sdata_arr		: tdata_arr := (others => (others => '0'));
	--* jhkim
	type tdata_arr0			is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(15 downto 0);		
	signal sdata_arr0		: tdata_arr0 := (others => (others => '0'));
	signal sser_cnt			: integer range 0 to 23 := 23;

	signal salign_done		: std_logic := '0';
	signal sol				: std_logic := '0';
	signal swait_cnt		: std_logic_vector(3 downto 0) := (others => '0');
	signal svcnt			: std_logic_vector(11 downto 0) := (others => '0');

--	constant period_240m	: time := 4.166666667 ns;
--	constant period_240m	: time := 8.166666667 ns;
    signal roic_x : integer;
    signal iroic_clk : std_logic;
begin

u_tb_clk_roic_240 : tb_clk_roic_240
   port map ( 
   clk_out1 => iroic_clk,            
   reset => '0',
   locked => OPEN,
   clk_in1 => iroic_mclk
 );
smain_clk <= iroic_mclk;

	process(smain_clk)
	begin
		if(smain_clk'event and smain_clk = '1') then
			case state_roic is
				when s_IDLE		=>
									if(iroic_sync = '1') then
										state_roic		<= s_AFE;
										sroic_cnt		<= (others => '0');
									end if;
				when s_AFE		=>
									if(sroic_cnt = 255) then
										state_roic		<= s_WAIT;
										sroic_cnt		<= (others => '0');
										salign_done		<= ialign_done;
									else
										sroic_cnt		<= sroic_cnt + '1';
									end if;

				when s_WAIT		=>	
									if(swait_cnt = 1) then
										state_roic		<= s_DATA;
										swait_cnt		<= (others => '0');
										sol				<= '1';
									else
										swait_cnt		<= swait_cnt + '1';
									end if;
										
				when s_DATA		=> 
									if(sroic_cnt = 255) then
										sroic_cnt		<= (others => '0');
										if(svcnt = MAX_HEIGHT(GNR_MODEL) - ROIC_DUAL_BY_MODEL(GNR_MODEL)) then
											state_roic	<= s_IDLE;
											salign_done	<= ialign_done;
											svcnt		<= (others => '0');
										else
											svcnt		<= svcnt + ROIC_DUAL_BY_MODEL(GNR_MODEL);
										end if;
									else
										sroic_cnt		<= sroic_cnt + '1';
										if(sroic_cnt = 3) then
											sol				<= '0';
										end if;
									end if;
				when others 	=>
									NULL;
			end case;
		end if;
	end process;

--* --	ROIC_DATA_GEN : for i in 0 to ROIC_NUM(MODEL)-1 generate
--* --		sdata_arr(i)		<= 	x"FFF000" when salign_done = '0' else
--* --								x"00" & sroic_cnt(1 downto 0) & sroic_cnt(7 downto 2) & sol & "0000000";
--* --	end generate;
--* 	ROIC_DATA_GEN_upper : for i in 0 to ROIC_NUM(MODEL)/2-1 generate
--* 		sdata_arr(i)		<= 	x"FFF000" when salign_done = '0' else
--* --								x"00" & sroic_cnt(1 downto 0) & sroic_cnt(7 downto 2) & sol & "0000000";
--* 								x"89AB" & sol & "0000000";
--* 	end generate;
--* 	ROIC_DATA_GEN_lower : for i in ROIC_NUM(MODEL)/2 to ROIC_NUM(MODEL)-1 generate
--* 		sdata_arr(i)		<= 	x"FFF000" when salign_done = '0' else
--* --								x"FF" & sroic_cnt(1 downto 0) & sroic_cnt(7 downto 2) & sol & "0000000";
--* 								x"CDEF" & sol & "0000000";
--* --								x"FF" & x"ff" & sol & "0000000";
--* 	end generate;
	ROIC_DATA_GEN0 : for i in 0 to ROIC_NUM(GNR_MODEL)-1 generate
		sdata_arr0(i)		<= 	x"0000" when salign_done = '0' else
								x"00" & sroic_cnt(1 downto 0) & sroic_cnt(7 downto 2) + svcnt ;
	end generate;

	ROIC_DATA_GEN : for i in 0 to ROIC_NUM(GNR_MODEL)-1 generate
		sdata_arr(i)		<= 	x"FFF000" when salign_done = '0' else
								sdata_arr0(i) & sol & "0000000";
	end generate;

	roic_x <= ROIC_NUM(GNR_MODEL)/2;

	roic_ser_data_gen : for i in 0 to ROIC_DCLK_NUM(GNR_MODEL) - 1 generate
--		oroic_dclk(i)		<= transport (not iroic_clk) after (period_240m / 4);
		oroic_dclk(i)		<= not iroic_clk;
--		oroic_fclk(i)		<= sroic_fclk;
	end generate;
	roic_ser_data_gen0 : for i in 0 to ROIC_FCLK_NUM(GNR_MODEL) - 1 generate
--		oroic_dclk(i)		<= transport (not iroic_clk) after (period_240m / 4);
--		oroic_dclk(i)		<= not iroic_clk;
		oroic_fclk(i)		<= sroic_fclk;
	end generate;

	process(iroic_clk)
	begin
		if(iroic_clk'event) then
			sroic_fclk		<= smain_clk;
			if(state_roic = s_DATA) then
				if(sser_cnt = 0) then
					sser_cnt		<= 23;
				else
					sser_cnt		<= sser_cnt - 1;
				end if;

				for i in 0 to ROIC_NUM(GNR_MODEL)-1 loop
					oroic_data(i)	<= sdata_arr(i)(sser_cnt);
				end loop;
			else
			--	sser_cnt		<= 7;
				sser_cnt		<= 15;
				oroic_data		<= (others => '0');
			end if;
		end if;
	end process;
				

end Behavioral;
