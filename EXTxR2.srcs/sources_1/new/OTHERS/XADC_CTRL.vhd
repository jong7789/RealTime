library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;

-- From MIS 
entity XADC_CTRL is
port(
	iui_clk				: in	std_logic;
	iui_rstn			: in	std_logic;

	ireg_temp_en		: in	std_logic;
	oreg_device_temp	: out	std_logic_vector(15 downto 0)
);
end XADC_CTRL;

architecture Behavioral of XADC_CTRL is
	
	constant T_1MS				: integer := 100000;
	constant T_1US				: integer := 10;
	signal swait_time			: integer := T_1MS;

	type tstate_xadc			is (
										INIT_IDLE,
										REQUEST_READ_TEMP,
										WAIT_FOR_READ,      
										READ
									);
	signal tempmon_state		: tstate_xadc := INIT_IDLE;
	signal tempmon_next_state	: tstate_xadc := INIT_IDLE;

	signal sample_timer 		: std_logic_vector(31 downto 0) := (others => '0');
	signal sample_timer_en     	: std_logic := '0';
	signal sample_timer_clr    	: std_logic := '0';
	signal sample_en           	: std_logic := '0';

	signal xadc_den         	: std_logic := '0';
	signal xadc_drdy        	: std_logic;                         
	signal xadc_do          	: std_logic_vector(15 downto 0);
	signal xadc_drdy_r      	: std_logic := '0';
	signal xadc_do_r        	: std_logic_vector(15 downto 0) := (others => '0');

	signal temperature      	: std_logic_vector(15 downto 0) := (others => '0');

begin
	
	swait_time 		<= T_1MS when SIMULATION = "OFF" else T_1US;

	-- XADC polling interval timer
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
	    	sample_timer 	<= (others => '0');
		elsif(iui_clk'event and iui_clk = '1') then
			if(sample_timer_clr = '1') then
				sample_timer	<= (others => '0');
			elsif(sample_timer_en = '1') then
	    		sample_timer 	<= sample_timer + '1';
			end if;
		end if;
	end process;

	-- XADC sampler state transition
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
	    	tempmon_state 	<= INIT_IDLE;
		elsif(iui_clk'event and iui_clk = '1') then
	    	tempmon_state 	<= tempmon_next_state;
		end if;
	end process;

	-- Sample enable
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			sample_en		<= '0';
		elsif(iui_clk'event and iui_clk = '1') then
			if(sample_timer = swait_time) then
				sample_en		<= '1';
			else
				sample_en		<= '0';
			end if;
		end if;
	end process;

	-- XADC sampler next state transition
	process(tempmon_state, sample_en, xadc_drdy_r) 
	begin
		tempmon_next_state 	<= tempmon_state;
		
		case (tempmon_state) is
			when INIT_IDLE 			=>	if(sample_en = '1') then
		   									tempmon_next_state 	<= REQUEST_READ_TEMP;
										end if;

			when REQUEST_READ_TEMP 	=>	tempmon_next_state	<= WAIT_FOR_READ;

		  	when WAIT_FOR_READ 		=>	if(xadc_drdy_r = '1') then
		      								tempmon_next_state	<= READ;
										end if;

		  	when READ 				=>	tempmon_next_state	<= INIT_IDLE;
		  	when others 			=>	tempmon_next_state	<= INIT_IDLE;
		end case;
	end process;

	-- Sample timer clear
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			sample_timer_clr 	<= '0';
		elsif(iui_clk'event and iui_clk = '1') then
			if(tempmon_state = WAIT_FOR_READ) then
				sample_timer_clr 	<= '0';
			elsif(tempmon_state = REQUEST_READ_TEMP) then
				sample_timer_clr 	<= '1';
			end if;
		end if;
	end process;

	-- Sample timer enable
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			sample_timer_en 	<= '0';
		elsif(iui_clk'event and iui_clk = '1') then
			if(tempmon_state = REQUEST_READ_TEMP) then
				sample_timer_en 	<= '0';
			elsif(tempmon_state = INIT_IDLE or tempmon_state = READ) then
          		sample_timer_en 	<= '1';
			end if;
		end if;
	end process;

	-- XADC enable
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			xadc_den 	<= '0';
		elsif(iui_clk'event and iui_clk = '1') then
        	if(tempmon_state = WAIT_FOR_READ) then
				xadc_den 	<= '0';
        	elsif(tempmon_state = REQUEST_READ_TEMP) then
          		xadc_den 	<= '1';
			end if;
		end if;
	end process;

	-- Register XADC outputs
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			xadc_drdy_r 	<= '0';
			xadc_do_r 		<= (others => '0');
		elsif(iui_clk'event and iui_clk = '1') then
			xadc_drdy_r 	<= xadc_drdy;
			xadc_do_r 		<= xadc_do;
		end if;
	end process;

	-- Store current read value
	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
	    	temperature 	<= (others => '0');
		elsif(iui_clk'event and iui_clk = '1') then
	  		if(tempmon_state = READ) then
	    		temperature 	<= xadc_do_r;
			end if;
		end if;
	end process;

	U0_XADC : XADC 
	generic map (
		INIT_40			=> x"1000",
		INIT_41			=> x"2FFF",
		INIT_42			=> x"0800",
		INIT_48			=> x"0101",
		INIT_49			=> x"0000",
		INIT_4A			=> x"0100",
		INIT_4B			=> x"0000",
		INIT_4C			=> x"0000",
		INIT_4D			=> x"0000",
		INIT_4E			=> x"0000",
		INIT_4F			=> x"0000",
		INIT_50			=> x"B5ED",
		INIT_51			=> x"57E4",
		INIT_52			=> x"A147",
		INIT_53			=> x"CA33",
		INIT_54			=> x"A93A",
		INIT_55			=> x"52C6",
		INIT_56			=> x"9555",
		INIT_57			=> x"AE4E",
		INIT_58			=> x"5999",
		INIT_5C			=> x"5111",
		SIM_DEVICE		=> "7SERIES"
	)
	port map (
		ALM				=> open,
		OT				=> open,
		DO				=> xadc_do,   
		DRDY			=> xadc_drdy, 
		BUSY			=> open,
		CHANNEL			=> open,
		EOC				=> open,
		EOS				=> open,
		JTAGBUSY		=> open,
		JTAGLOCKED		=> open,
		JTAGMODIFIED	=> open,
		MUXADDR			=> open,
		VAUXN			=> x"0000",
		VAUXP			=> x"0000",
		CONVST			=> '0',
		CONVSTCLK		=> '0',
		RESET			=> '0',
		VN				=> '0',
		VP				=> '0',
		DADDR			=> "0000000",
		DCLK			=> iui_clk,
		DEN				=> xadc_den,  
		DI				=> x"0000",
		DWE				=> '0'
	);

	oreg_device_temp		<= temperature;

end Behavioral;
