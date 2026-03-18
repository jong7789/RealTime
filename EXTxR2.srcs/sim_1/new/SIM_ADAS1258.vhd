library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;

entity SIM_ADAS1258 is
port (
	iroic_clk_p			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	iroic_clk_n			: in	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);

	iroic_sync			: in	std_logic;

	oroic_dclko_p		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	oroic_dclko_n		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	oroic_data1_p		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	oroic_data1_n		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	oroic_data2_p		: out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0);
	oroic_data2_n       : out	std_logic_vector(ROIC_NUM(MODEL)-1 downto 0)
);
end SIM_ADAS1258;
	
architecture Behavioral of SIM_ADAS1258 is

	type tstate_roic		is	(
									s_IDLE,
									s_SAMPLE,
									s_CONV,
									s_DELAY1,
									s_DELAY2,
									s_DELAY3,
									s_DELAY4,
									s_HEADER1,
									s_HEADER2,
									s_HEADER3,
									s_CONFIG,
									s_DUMMY2,
									s_DATA,
									s_MUTE
								);

	signal state_roic		: tstate_roic := s_IDLE;

	signal sroic_clk		: std_logic;
	signal shcnt			: std_logic_vector(6 downto 0) := (others => '0');
	signal svcnt			: std_logic_vector(11 downto 0) := (others => '0');
	signal sser_cnt			: integer range 0 to 15 := 0;
	signal swait_cnt		: std_logic_vector(7 downto 0) := (others => '0');
	signal sheader_cnt		: integer range 0 to 63 := 0;

	type tdata_arr			is array (0 to ROIC_NUM(MODEL)-1) of std_logic_vector(15 downto 0);		
	signal sdata_arr1		: tdata_arr := (others => (others => '0'));
	signal sdata_arr2		: tdata_arr := (others => (others => '0'));
	signal sroic_dclko		: std_logic := '0';
	signal sroic_data1		: std_logic_vector(ROIC_NUM(MODEL)-1 downto 0) := (others => '0');
	signal sroic_data2		: std_logic_vector(ROIC_NUM(MODEL)-1 downto 0) := (others => '0');

	signal sheader_data		: std_logic_vector(63 downto 0) := (others => '0');

	signal sconfig_cnt		: integer range 0 to 63 := 0;
	
begin

	U_IBUFDS : IBUFDS
	port map (
		I		=> iroic_clk_p(0),
		IB		=> iroic_clk_n(0),
		O		=> sroic_clk
	);

	process(iroic_sync, sroic_clk)
	begin
		case (state_roic) is
			when s_IDLE		=> 
								if(iroic_sync'event and iroic_sync = '1') then
								--	state_roic		<= s_DELAY1;
									state_roic		<= s_DELAY3;
								end if;
			when s_DELAY1	=> 
								if(sroic_clk'event and sroic_clk = '0') then
									state_roic		<= s_HEADER1;
								end if;
			when s_HEADER1	=>
								if(sroic_clk'event and sroic_clk = '1') then
									if(sheader_cnt = ROIC_BURST(MODEL)-1) then 
										state_roic		<= s_SAMPLE;
										sheader_cnt		<= 0;
									else
										sheader_cnt		<= sheader_cnt + 1;
									end if;
								end if;

			when s_SAMPLE	=>
								if(iroic_sync'event and iroic_sync = '1') then
									state_roic		<= s_DELAY2;
								end if;
			when s_DELAY2	=> 
								if(sroic_clk'event and sroic_clk = '0') then
									state_roic		<= s_HEADER2;
								end if;
			when s_HEADER2	=>
								if(sroic_clk'event and sroic_clk = '1') then
									if(sheader_cnt = ROIC_BURST(MODEL)-1) then
										state_roic		<= s_CONV;
										sheader_cnt		<= 0;
									else
										sheader_cnt		<= sheader_cnt + 1;
									end if;
								end if;

			when s_CONV		=>
								if(iroic_sync'event and iroic_sync = '1') then
									state_roic		<= s_DELAY3;
								end if;
			when s_DELAY3	=> 
								if(sroic_clk'event and sroic_clk = '0') then
									state_roic		<= s_HEADER3;
								end if;
			when s_HEADER3	=>
								if(sroic_clk'event and sroic_clk = '1') then
									if(sheader_cnt = ROIC_BURST(MODEL)-1) then 
										state_roic		<= s_MUTE;
										sheader_cnt		<= 0;
										sser_cnt		<= 0;
									else
										sheader_cnt		<= sheader_cnt + 1;
									end if;
								end if;

			when s_DATA
							=>
								if(sroic_clk'event and sroic_clk = '1') then
									if(sser_cnt = PIXEL_DEPTH(MODEL) - 1) then		-- 1 Based
										sser_cnt 		<= 0;

										if(shcnt(1 downto 0) = "11") then
											if(shcnt = (ROIC_MAX_CH(MODEL) / 2) - 1) then
												if(svcnt = MAX_HEIGHT(MODEL) - 1) then
													state_roic		<= s_IDLE;	
													svcnt			<= (others => '0');
												else
													if(svcnt = GATE_CH(MODEL) - 1) then
														state_roic		<= s_IDLE;	
													else
														state_roic		<= s_DELAY4;	
													end if;
													svcnt			<= svcnt + '1';
												end if;
												shcnt			<= (others => '0');
											else
												state_roic		<= s_MUTE;	
												shcnt			<= shcnt + '1';
											end if;
										else
											shcnt			<= shcnt + '1';
										end if;
									else
										sser_cnt 	<= sser_cnt + 1;
									end if;
								end if;
			when s_DELAY4	=>
								if(sroic_clk'event and sroic_clk = '0') then
									state_roic		<= s_CONFIG;
								end if;

			when s_CONFIG	=>
								if(sroic_clk'event and sroic_clk = '1') then
									if(sconfig_cnt = ROIC_BURST(MODEL)-1) then 
										state_roic		<= s_DELAY3;
										sconfig_cnt		<= 0;
									else
										sconfig_cnt		<= sconfig_cnt + 1;
									end if;
								end if;

			when s_MUTE		=>
								if(sroic_clk'event and sroic_clk = '0') then
									state_roic		<= s_DATA;
									sser_cnt		<= 0;
								end if;
			when s_DUMMY2	=>
								if(sroic_clk'event and sroic_clk = '1') then
									if(swait_cnt = ROIC_BURST(MODEL) + ROIC_MUTE(MODEL) - 1) then
										state_roic		<= s_DATA;
										swait_cnt		<= (others => '0');
										sser_cnt		<= 0;
									else
										swait_cnt		<= swait_cnt + '1';
									end if;
								end if;
		end case;
	end process;
										
--	sdata_arr1(0)		<= svcnt(4 downto 0) & "000" & shcnt & '0';
--	sdata_arr2(0)		<= svcnt(4 downto 0) & "000" & shcnt & '1';
--	sdata_arr1(1)		<= svcnt(4 downto 0) & "001" & shcnt & '0';
--	sdata_arr2(1)		<= svcnt(4 downto 0) & "001" & shcnt & '1';
--	sdata_arr1(2)		<= svcnt(4 downto 0) & "010" & shcnt & '0';
--	sdata_arr2(2)		<= svcnt(4 downto 0) & "010" & shcnt & '1';
--	sdata_arr1(3)		<= svcnt(4 downto 0) & "011" & shcnt & '0';
--	sdata_arr2(3)		<= svcnt(4 downto 0) & "011" & shcnt & '1';
--	sdata_arr1(4)		<= svcnt(4 downto 0) & "100" & shcnt & '0';
--	sdata_arr2(4)		<= svcnt(4 downto 0) & "100" & shcnt & '1';
	
	ROIC_DATA_GEN : for i in 0 to ROIC_NUM(MODEL)-1 generate
		sdata_arr1(i)		<= (x"0" & conv_std_logic_vector(i, 4) & shcnt & '0') + (x"0" & svcnt);
		sdata_arr2(i)		<= (x"0" & conv_std_logic_vector(i, 4) & shcnt & '1') + (x"0" & svcnt);
	end generate;

	sheader_data(63 downto 48)		<= x"0A03";
	sheader_data(47 downto 32)		<= x"0000";


	roic_ser_data_gen : for i in 0 to ROIC_NUM(MODEL) - 1 generate
		sroic_data1(i)		<= 	sheader_data(63-sheader_cnt) 	when state_roic = s_HEADER1 else
								sheader_data(63-sheader_cnt)	when state_roic = s_HEADER2 else
								sheader_data(63-sheader_cnt)	when state_roic = s_HEADER3 else
								sdata_arr1(i)(15-sser_cnt)		when state_roic = s_DATA else 
								'1';

		sroic_data2(i)		<= 	sheader_data(63-sheader_cnt) 	when state_roic = s_HEADER1 else
								sheader_data(63-sheader_cnt)	when state_roic = s_HEADER2 else
								sheader_data(63-sheader_cnt)	when state_roic = s_HEADER3 else
								sdata_arr2(i)(15-sser_cnt)		when state_roic = s_DATA else 
								'1';
	end generate;

	roic_diff_conv : for i in 0 to ROIC_NUM(MODEL) - 1 generate
		U0_OBUFDS : OBUFDS
		port map (
			I		=> sroic_clk,
			O		=> oroic_dclko_p(i),
			OB		=> oroic_dclko_n(i)
		);

		U1_OBUFDS : OBUFDS
		port map (
			I		=> sroic_data1(i),
			O		=> oroic_data1_p(i),
			OB		=> oroic_data1_n(i)
		);

		U2_OBUFDS : OBUFDS
		port map (
			I		=> sroic_data2(i),
			O		=> oroic_data2_p(i),
			OB		=> oroic_data2_n(i)
		);
	end generate;

					
			
			
										
		

end Behavioral;
