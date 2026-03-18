library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity MASKING_PROC is
port (
	idata_clk			: in	std_logic;
	idata_rstn			: in	std_logic;

	ireg_iproc_mode		: in	std_logic_vector(3 downto 0);

	ireg_width			: in	std_logic_vector(11 downto 0);
	ireg_height			: in	std_logic_vector(11 downto 0);

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
end MASKING_PROC;

architecture Behavioral of MASKING_PROC is

	component MASK_OUT
	port (
		idata_clk		: in	std_logic;
		idata_rstn		: in	std_logic;

		ireg_width		: in	std_logic_vector(11 downto 0);
		ireg_height		: in	std_logic_vector(11 downto 0);

		ihsync			: in	std_logic;
		ivsync			: in	std_logic;
		ihcnt			: in	std_logic_vector(11 downto 0);
		ivcnt			: in	std_logic_vector(11 downto 0);
		idata			: in	std_logic_vector(15 downto 0);

		ohsync_2x2		: out	std_logic;
		ovsync_2x2		: out	std_logic;
		ohcnt_2x2		: out	std_logic_vector(11 downto 0);
		ovcnt_2x2		: out	std_logic_vector(11 downto 0);

		odata_1x1		: out	std_logic_vector(15 downto 0);
		odata_1x2		: out	std_logic_vector(15 downto 0);
		odata_1x3		: out	std_logic_vector(15 downto 0);
		odata_2x1		: out	std_logic_vector(15 downto 0);
		odata_2x2		: out	std_logic_vector(15 downto 0);
		odata_2x3		: out	std_logic_vector(15 downto 0);
		odata_3x1		: out	std_logic_vector(15 downto 0);
		odata_3x2		: out	std_logic_vector(15 downto 0);
		odata_3x3		: out	std_logic_vector(15 downto 0)
	);
	end component;

	component MASKING_FILTER 
	port(
		idata_clk		: in	std_logic;
		idata_rstn		: in	std_logic;
	
		idata_arr		: in	std_logic_vector(143 downto 0);
		imask_arr		: in	std_logic_vector(36 downto 0);

		odata			: out	std_logic_vector(15 downto 0)
	);
	end component;

	signal shsync_2x2			: std_logic;
	signal svsync_2x2			: std_logic;
	signal shcnt_2x2			: std_logic_vector(11 downto 0);
	signal svcnt_2x2			: std_logic_vector(11 downto 0);

	signal sdata_1x1			: std_logic_vector(15 downto 0);
	signal sdata_1x2			: std_logic_vector(15 downto 0);
	signal sdata_1x3			: std_logic_vector(15 downto 0);
	signal sdata_2x1			: std_logic_vector(15 downto 0);
	signal sdata_2x2			: std_logic_vector(15 downto 0);
	signal sdata_2x3			: std_logic_vector(15 downto 0);
	signal sdata_3x1			: std_logic_vector(15 downto 0);
	signal sdata_3x2			: std_logic_vector(15 downto 0);
	signal sdata_3x3			: std_logic_vector(15 downto 0);

	signal sdata_arr			: std_logic_vector(143 downto 0);
	signal smask_arr			: std_logic_vector(36 downto 0);
	signal sdata_masking_proc	: std_logic_vector(15 downto 0);

	signal sreg_iproc_mode		: std_logic_vector(3 downto 0);
	signal sreg_iproc_mode_1d	: std_logic_vector(3 downto 0);
	signal sreg_iproc_mode_2d	: std_logic_vector(3 downto 0);
	signal sreg_iproc_mode_3d	: std_logic_vector(3 downto 0);
	signal sreg_iproc_mode_4d	: std_logic_vector(3 downto 0);
	signal sreg_iproc_mode_5d	: std_logic_vector(3 downto 0);
	signal sreg_iproc_mode_6d	: std_logic_vector(3 downto 0);

	signal shsync_2x2_1d		: std_logic;
	signal svsync_2x2_1d		: std_logic;
	signal svcnt_2x2_1d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_1d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_1d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_2d		: std_logic;
	signal svsync_2x2_2d		: std_logic;
	signal svcnt_2x2_2d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_2d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_2d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_3d		: std_logic;
	signal svsync_2x2_3d		: std_logic;
	signal svcnt_2x2_3d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_3d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_3d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_4d		: std_logic;
	signal svsync_2x2_4d		: std_logic;
	signal svcnt_2x2_4d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_4d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_4d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_5d		: std_logic;
	signal svsync_2x2_5d		: std_logic;
	signal svcnt_2x2_5d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_5d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_5d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_6d		: std_logic;
	signal svsync_2x2_6d		: std_logic;
	signal svcnt_2x2_6d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_6d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_6d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_7d		: std_logic;
	signal svsync_2x2_7d		: std_logic;
	signal svcnt_2x2_7d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_7d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_7d			: std_logic_vector(15 downto 0);
	signal shsync_2x2_8d		: std_logic;
	signal svsync_2x2_8d		: std_logic;
	signal svcnt_2x2_8d			: std_logic_vector(11 downto 0);
	signal shcnt_2x2_8d			: std_logic_vector(11 downto 0);
	signal sdata_2x2_8d			: std_logic_vector(15 downto 0);
begin

	U0_MASK_OUT : MASK_OUT
	port map (
		idata_clk		=> idata_clk,
		idata_rstn		=> idata_rstn,		
                                           
		ireg_width		=> ireg_width,		
		ireg_height		=> ireg_height,		
                                           
		ihsync			=> ihsync,			
		ivsync			=> ivsync,			
		ihcnt			=> ihcnt,
		ivcnt			=> ivcnt,		
		idata			=> idata,			
		                   
		ohsync_2x2		=> shsync_2x2,		
		ovsync_2x2		=> svsync_2x2,		
		ohcnt_2x2		=> shcnt_2x2,	
		ovcnt_2x2		=> svcnt_2x2,	

		odata_1x1		=> sdata_1x1,		
		odata_1x2		=> sdata_1x2,		
		odata_1x3		=> sdata_1x3,		
		odata_2x1		=> sdata_2x1,		
		odata_2x2		=> sdata_2x2,		
		odata_2x3		=> sdata_2x3,		
		odata_3x1		=> sdata_3x1,		
		odata_3x2		=> sdata_3x2,		
		odata_3x3		=> sdata_3x3		
	);

	
	process(idata_clk, idata_rstn) 
	begin
		if(idata_rstn = '0') then
			smask_arr		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			case (sreg_iproc_mode_3d) is 
				when "0001" 	=> 	smask_arr	<= "0" & "0000" & "0000" & "0000" & "0000" & "0001" & "0000" & "0000" & "0000" & "0000";	-- Raw Image2
				when "0010" 	=> 	smask_arr	<= "0" & "1001" & "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0000" & "0001";	-- Embossing
				when "0011"		=> 	smask_arr	<= "0" & "0000" & "1001" & "0000" & "1001" & "0101" & "1001" & "0000" & "1001" & "0000";	-- Sharpning
				when "0100"		=> 	smask_arr	<= "1" & "0001" & "0001" & "0001" & "0001" & "0001" & "0001" & "0001" & "0001" & "0001";	-- Blurring 
				when others 	=> 	NULL;
			end case;
		end if;
	end process;

	process(idata_clk, idata_rstn) 
	begin
		if(idata_rstn = '0') then
			sdata_arr		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			if(shsync_2x2 = '1') then
				if(svcnt_2x2 = 0) then
					sdata_arr		<= sdata_3x3 & sdata_3x2 & sdata_3x1 & sdata_2x3 & sdata_2x2 & sdata_2x1 & sdata_2x3 & sdata_2x2 & sdata_2x1;
				elsif(svcnt_2x2 = ireg_height - 1) then
					sdata_arr		<= sdata_2x3 & sdata_2x2 & sdata_2x1 & sdata_2x3 & sdata_2x2 & sdata_2x1 & sdata_1x3 & sdata_1x2 & sdata_1x1;
				else
					if(shcnt_2x2 = 0) then
						sdata_arr	<= sdata_3x3 & sdata_3x2 & sdata_3x2 & sdata_2x3 & sdata_2x2 & sdata_2x2 & sdata_1x3 & sdata_1x2 & sdata_1x2;
					elsif(shcnt_2x2 = ireg_width - 1) then
						sdata_arr	<= sdata_3x2 & sdata_3x2 & sdata_3x1 & sdata_2x2 & sdata_2x2 & sdata_2x1 & sdata_1x2 & sdata_1x2 & sdata_1x1;
					else
						sdata_arr	<= sdata_3x3 & sdata_3x2 & sdata_3x1 & sdata_2x3 & sdata_2x2 & sdata_2x1 & sdata_1x3 & sdata_1x2 & sdata_1x1;
					end if;
				end if;
			else
				sdata_arr		<= (others => '0');
			end if;
		end if;
	end process;

	U0_MASKING_FILTER : MASKING_FILTER 
	port map (
		idata_clk			=> idata_clk,
		idata_rstn			=> idata_rstn,
	
		idata_arr			=> sdata_arr,
		imask_arr			=> smask_arr,

		odata				=> sdata_masking_proc
	);


	process(idata_clk, idata_rstn) 
	begin
		if(idata_rstn = '0') then
			ohsync		<= '0';
			ovsync		<= '0';
			ovcnt		<= (others => '0');
			ohcnt		<= (others => '0');
			odata		<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			ohsync		<= shsync_2x2_8d;
			ovsync		<= svsync_2x2_8d;
			ohcnt		<= shcnt_2x2_8d;
			ovcnt		<= svcnt_2x2_8d;

            -- if (sreg_iproc_mode_3d = 0) then
            --     odata <= sdata_2x2_5d;
            if (sreg_iproc_mode_6d = 0) then
                odata <= sdata_2x2_8d;
            else
                odata <= sdata_masking_proc;
            end if;
        end if;
    end process;




	process(idata_clk, idata_rstn) 
	begin
		if(idata_rstn = '0') then
			shsync_2x2_1d		<= '0';
			svsync_2x2_1d		<= '0';
			svcnt_2x2_1d		<= (others => '0');
			shcnt_2x2_1d		<= (others => '0');
			sdata_2x2_1d		<= (others => '0');
			shsync_2x2_2d		<= '0';
			svsync_2x2_2d		<= '0';
			svcnt_2x2_2d		<= (others => '0');
			shcnt_2x2_2d		<= (others => '0');
			sdata_2x2_2d		<= (others => '0');
			shsync_2x2_3d		<= '0';
			svsync_2x2_3d		<= '0';
			svcnt_2x2_3d		<= (others => '0');
			shcnt_2x2_3d		<= (others => '0');
			sdata_2x2_3d		<= (others => '0');
			shsync_2x2_4d		<= '0';
			svsync_2x2_4d		<= '0';
			svcnt_2x2_4d		<= (others => '0');
			shcnt_2x2_4d		<= (others => '0');
			sdata_2x2_4d		<= (others => '0');
			shsync_2x2_5d		<= '0';
			svsync_2x2_5d		<= '0';
			svcnt_2x2_5d		<= (others => '0');
			shcnt_2x2_5d		<= (others => '0');
			sdata_2x2_5d		<= (others => '0');
			shsync_2x2_6d		<= '0';
			svsync_2x2_6d		<= '0';
			svcnt_2x2_6d		<= (others => '0');
			shcnt_2x2_6d		<= (others => '0');
			sdata_2x2_6d		<= (others => '0');
			shsync_2x2_7d		<= '0';
			svsync_2x2_7d		<= '0';
			svcnt_2x2_7d		<= (others => '0');
			shcnt_2x2_7d		<= (others => '0');
			sdata_2x2_7d		<= (others => '0');
			shsync_2x2_8d		<= '0';
			svsync_2x2_8d		<= '0';
			svcnt_2x2_8d		<= (others => '0');
			shcnt_2x2_8d		<= (others => '0');
			sdata_2x2_8d		<= (others => '0');
			sreg_iproc_mode		<= (others => '0');
			sreg_iproc_mode_1d	<= (others => '0');
			sreg_iproc_mode_2d	<= (others => '0');
			sreg_iproc_mode_3d	<= (others => '0');
			sreg_iproc_mode_4d	<= (others => '0');
			sreg_iproc_mode_5d	<= (others => '0');
			sreg_iproc_mode_6d	<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			shsync_2x2_1d		<= shsync_2x2;	
			svsync_2x2_1d		<= svsync_2x2;	
			svcnt_2x2_1d		<= svcnt_2x2;	
			shcnt_2x2_1d		<= shcnt_2x2;
			sdata_2x2_1d		<= sdata_2x2;
			shsync_2x2_2d		<= shsync_2x2_1d;	
			svsync_2x2_2d		<= svsync_2x2_1d;	
			svcnt_2x2_2d		<= svcnt_2x2_1d;	
			shcnt_2x2_2d		<= shcnt_2x2_1d;
			sdata_2x2_2d		<= sdata_2x2_1d;
			shsync_2x2_3d		<= shsync_2x2_2d;	
			svsync_2x2_3d		<= svsync_2x2_2d;
			svcnt_2x2_3d		<= svcnt_2x2_2d;	
			shcnt_2x2_3d		<= shcnt_2x2_2d;
			sdata_2x2_3d		<= sdata_2x2_2d;
			shsync_2x2_4d		<= shsync_2x2_3d;	
			svsync_2x2_4d		<= svsync_2x2_3d;	
			svcnt_2x2_4d		<= svcnt_2x2_3d;	
			shcnt_2x2_4d		<= shcnt_2x2_3d;
			sdata_2x2_4d		<= sdata_2x2_3d;
			shsync_2x2_5d		<= shsync_2x2_4d;	
			svsync_2x2_5d		<= svsync_2x2_4d;	
			svcnt_2x2_5d		<= svcnt_2x2_4d;	
			shcnt_2x2_5d		<= shcnt_2x2_4d;
			sdata_2x2_5d		<= sdata_2x2_4d;
			shsync_2x2_6d		<= shsync_2x2_5d;	
			svsync_2x2_6d		<= svsync_2x2_5d;	
			svcnt_2x2_6d		<= svcnt_2x2_5d;	
			shcnt_2x2_6d		<= shcnt_2x2_5d;
			sdata_2x2_6d		<= sdata_2x2_5d;
			shsync_2x2_7d		<= shsync_2x2_6d;	
			svsync_2x2_7d		<= svsync_2x2_6d;	
			svcnt_2x2_7d		<= svcnt_2x2_6d;	
			shcnt_2x2_7d		<= shcnt_2x2_6d;
			sdata_2x2_7d		<= sdata_2x2_6d;
			shsync_2x2_8d		<= shsync_2x2_7d;	
			svsync_2x2_8d		<= svsync_2x2_7d;	
			svcnt_2x2_8d		<= svcnt_2x2_7d;	
			shcnt_2x2_8d		<= shcnt_2x2_7d;
			sdata_2x2_8d		<= sdata_2x2_7d;
			sreg_iproc_mode		<= ireg_iproc_mode;
			sreg_iproc_mode_1d	<= sreg_iproc_mode;
			sreg_iproc_mode_2d	<= sreg_iproc_mode_1d;
			sreg_iproc_mode_3d	<= sreg_iproc_mode_2d;
			sreg_iproc_mode_4d	<= sreg_iproc_mode_3d;
			sreg_iproc_mode_5d	<= sreg_iproc_mode_4d;
			sreg_iproc_mode_6d	<= sreg_iproc_mode_5d;
		end if;
	end process;




end Behavioral;

