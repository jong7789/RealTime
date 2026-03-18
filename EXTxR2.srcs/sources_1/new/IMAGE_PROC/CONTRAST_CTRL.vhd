library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity CONTRAST_CTRL is
port (
	idata_clk			: in	std_logic;
	idata_rstn			: in	std_logic;

	ireg_contrast		: in	std_logic_vector(15 downto 0);

	ihsync				: in	std_logic;
	ivsync				: in	std_logic;
	ihcnt				: in	std_logic_vector(11 downto 0);
	ivcnt				: in	std_logic_vector(11 downto 0);
	idata				: in	std_logic_vector(15 downto 0);

	ohsync				: out	std_logic;
	ovsync				: out	std_logic;
	ohcnt				: out	std_logic_vector(11 downto 0);
	ovcnt				: out	std_logic_vector(11 downto 0);
	odata				: out	std_logic_vector(15 downto 0)
);
end CONTRAST_CTRL;

architecture Behavioral of CONTRAST_CTRL is

	component MULTI_16x16 		-- 3 Delay
	port (
		clk 			: in	std_logic;
		ce				: in	std_logic;
		a				: in	std_logic_vector(15 downto 0);
		b				: in	std_logic_vector(15 downto 0);
		p				: out	std_logic_vector(31 downto 0)
	);
	end component;

	signal smulti_data		: std_logic_vector(31 downto 0);

	signal shsync_cal		: std_logic;
	signal svsync_cal		: std_logic;
	signal shcnt_cal		: std_logic_vector(11 downto 0);
	signal svcnt_cal		: std_logic_vector(11 downto 0);
	signal sdata_cal		: std_logic_vector(15 downto 0);

	signal shsync_1d		: std_logic;
	signal shsync_2d		: std_logic;
	signal shsync_3d		: std_logic;
	signal svsync_1d		: std_logic;
	signal svsync_2d		: std_logic;
	signal svsync_3d		: std_logic;
	signal shcnt_1d			: std_logic_vector(11 downto 0);
	signal shcnt_2d			: std_logic_vector(11 downto 0);
	signal shcnt_3d			: std_logic_vector(11 downto 0);
	signal svcnt_1d			: std_logic_vector(11 downto 0);
	signal svcnt_2d			: std_logic_vector(11 downto 0);
	signal svcnt_3d			: std_logic_vector(11 downto 0);
	signal sreg_contrast_1d	: std_logic_vector(15 downto 0);
	signal sreg_contrast_2d	: std_logic_vector(15 downto 0);
	signal sreg_contrast_3d	: std_logic_vector(15 downto 0);
--COMPONENT ila_temp_britcont
--PORT (
--	clk : IN STD_LOGIC;
--	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
--	probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
--	probe2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
--	probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
--	probe4 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
--);
--END COMPONENT  ;    
begin
--u_ila_temp_britcont : ila_temp_britcont
--PORT MAP (
--	clk      => idata_clk       ,      
--	probe0(0)=> svsync_cal      , -- 1 
--	probe1   => idata           , --16
--	probe2   => sreg_contrast_3d, --16
--	probe3   => smulti_data     , --32
--	probe4   => sdata_cal         --16
--);

	U0_MULTI_16x16 : MULTI_16x16
	port map (
		clk 			=> idata_clk,
		ce				=> idata_rstn,
		a				=> idata,
		b				=> sreg_contrast_3d,
		p				=> smulti_data
	);

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			shsync_cal		<= '0';
			svsync_cal		<= '0';
			shcnt_cal		<= (others => '0');
			svcnt_cal		<= (others => '0');
			sdata_cal		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			shsync_cal		<= shsync_3d;
			svsync_cal		<= svsync_3d;
			shcnt_cal		<= shcnt_3d;
			svcnt_cal		<= svcnt_3d;
--			if(smulti_data(31 downto 28) = 0) then
--				sdata_cal	<= smulti_data(27 downto 12);
--			else
--				sdata_cal	<= x"FFFF";
--			end if;
            --# 230721
			if(smulti_data(31 downto 24) = 0) then
				sdata_cal	<= smulti_data(24-1 downto 8);
			else
				sdata_cal	<= x"FFFF";
			end if;
		end if;
	end process;

	ohsync				<= shsync_cal;	
	ovsync				<= svsync_cal;	
	ohcnt				<= shcnt_cal;	
	ovcnt				<= svcnt_cal;	
	odata				<= sdata_cal;	

	
	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			shsync_1d			<= '0';
			shsync_2d			<= '0';
			shsync_3d			<= '0';
			svsync_1d			<= '0';
			svsync_2d			<= '0';
			svsync_3d			<= '0';
			shcnt_1d			<= (others => '0');
			shcnt_2d			<= (others => '0');
			shcnt_3d			<= (others => '0');
			svcnt_1d			<= (others => '0');
			svcnt_2d			<= (others => '0');
			svcnt_3d			<= (others => '0');
			sreg_contrast_1d	<= (others => '0');
			sreg_contrast_2d	<= (others => '0');
			sreg_contrast_3d	<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			shsync_1d			<= ihsync;
			shsync_2d			<= shsync_1d;
			shsync_3d			<= shsync_2d;
			svsync_1d			<= ivsync; 
			svsync_2d			<= svsync_1d;
			svsync_3d			<= svsync_2d;
			shcnt_1d			<= ihcnt;
			shcnt_2d			<= shcnt_1d;
			shcnt_3d			<= shcnt_2d;
			svcnt_1d			<= ivcnt;
			svcnt_2d			<= svcnt_1d;
			svcnt_3d			<= svcnt_2d;
			sreg_contrast_1d	<= ireg_contrast;
			sreg_contrast_2d	<= sreg_contrast_1d;
			sreg_contrast_3d	<= sreg_contrast_2d;
		end if;
	end process;

end Behavioral;

