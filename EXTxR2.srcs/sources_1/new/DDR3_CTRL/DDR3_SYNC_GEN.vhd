library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.TOP_HEADER.ALL;

entity DDR3_SYNC_GEN is
generic ( GNR_MODEL : string  := "EXT1616R" );
port(
	idata_clk			: in	std_logic;
	idata_rstn			: in	std_logic;

	ireg_line_time		: in	std_logic_vector(15 downto 0);
	ireg_sd_wen			: in	std_logic;
	ireg_width			: in	std_logic_vector(11 downto 0);
	ireg_height			: in	std_logic_vector(11 downto 0);

	ireq_data			: in	std_logic;
    istate_tftd         : in tstate_tft;

	ihsync				: in	std_logic;
	ivsync				: in	std_logic;
	ihcnt				: in	std_logic_vector(9 downto 0);
	ivcnt				: in	std_logic_vector(11 downto 0);

	ohsync				: out	std_logic;
	ovsync				: out	std_logic;
	ohcnt				: out	std_logic_vector(11 downto 0);
	ovcnt				: out	std_logic_vector(11 downto 0);
	ostate_sync_ddr     : out   tstate_sync_ddr
);
end entity DDR3_SYNC_GEN;

architecture behavioral of DDR3_SYNC_GEN is

--	type tstate_sync_ddr 		is	(
--									s_IDLE,
--									s_DATA,
--									s_LWAIT,
--									s_FWAIT
--								);
	signal state_sync		: tstate_sync_ddr;
	
	signal sframe_end_trig	: std_logic;
	signal swait_cnt		: std_logic_vector(15 downto 0);

	signal shsync_out		: std_logic;
	signal svsync_out		: std_logic;
	signal shcnt_out		: std_logic_vector(11 downto 0);
	signal svcnt_out		: std_logic_vector(11 downto 0);

	signal sreg_line_time	: std_logic_vector(15 downto 0);
	signal sreg_sd_wen		: std_logic;
	signal sreg_width		: std_logic_vector(11 downto 0);
	signal sreg_height		: std_logic_vector(11 downto 0);

	signal sreq_data_1d		: std_logic;
	signal sreq_data_2d		: std_logic;
	signal sreq_data_3d		: std_logic;

	signal svsync_1d		: std_logic;
	signal svsync_2d		: std_logic;
	signal svsync_3d		: std_logic;

	--* debug
	signal ichk_cnt			: std_logic_vector(31 downto 0);
	signal ichk_cnt_v		: std_logic_vector(31 downto 0);

	signal ovsync_1d		: std_logic;
	signal ochk_cnt			: std_logic_vector(31 downto 0);
	signal ochk_cnt_v		: std_logic_vector(31 downto 0);
	
signal  sstate_tftd,
        sstate_tftd_d1,
        sstate_tftd_d2,
        sstate_tftd_d3 : tstate_tft;

begin

process (idata_clk) -- stream disable when serial reset 211020 mbh
begin
    if (idata_clk'EVENT and idata_clk = '1') then
        --
        sstate_tftd_d1 <= istate_tftd;
        sstate_tftd_d2 <= sstate_tftd_d1;
        sstate_tftd_d3 <= sstate_tftd_d2;
        sstate_tftd <= sstate_tftd_d3;

--        if sreg_shutter = '0' then -- rolling
--            stream_tpc_en <= '1';
--        elsif ivsync0 = '0' and ivsync = '1' then -- global
--            if sstate_tftd = s_SCAN then
--                stream_tpc_en <= '1';
--            else
--                stream_tpc_en <= '0';
--            end if;
--        end if;
        --
    end if;
end process;

    ostate_sync_ddr <= state_sync;

--	sframe_end_trig		<= not svsync_2d and svsync_3d;
	sframe_end_trig		<= not svsync_2d and svsync_3d when  sstate_tftd_d2 = s_SCAN else '0'; --# 230717

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			state_sync		<= s_IDLE;
			swait_cnt		<= (others => '0');

			shsync_out		<= '0';
			svsync_out		<= '0';
			shcnt_out		<= (others => '0');
			svcnt_out		<= (others => '0');

		elsif(idata_clk'event and idata_clk = '1') then
			case (state_sync) is
				when s_IDLE		=>	
									if(sframe_end_trig = '1') then
										state_sync		<= s_DATA;

										shsync_out		<= '1';
										svsync_out		<= '1';
										shcnt_out		<= (others => '0');
										svcnt_out		<= (others => '0');

										swait_cnt		<= (others => '0');

									end if;

				when s_DATA		=>
									if(shcnt_out = sreg_width - 1) then
										if(svcnt_out = sreg_height - 1) then
											state_sync		<= s_FWAIT;
											svsync_out		<= '0';
											svcnt_out		<= (others => '0');
										else
											state_sync		<= s_LWAIT;
											svsync_out		<= '1';
											svcnt_out		<= svcnt_out + '1';
										end if;

										shsync_out		<= '0';
										shcnt_out		<= (others => '0');
									else
										shcnt_out		<= shcnt_out + '1';
									end if;

									swait_cnt		<= swait_cnt + '1';

				when s_FWAIT	=> 
									if(	(sreg_sd_wen = '1' and sreq_data_3d = '1') or
										(sreg_sd_wen = '0' and sframe_end_trig = '1')) then
										state_sync		<= s_DATA;

										shsync_out		<= '1';
										svsync_out		<= '1';
										shcnt_out		<= (others => '0');
										svcnt_out		<= (others => '0');

										swait_cnt		<= (others => '0');
									end if;

				when s_LWAIT	=>
									if(sreg_sd_wen = '1') then
										if(sreq_data_3d = '1') then
											state_sync		<= s_DATA;
											shsync_out		<= '1';
											svsync_out		<= '1';
											shcnt_out		<= (others => '0');
										end if;
									else
										if(swait_cnt >= sreg_line_time - 1) then 
											state_sync		<= s_DATA;
											swait_cnt		<= (others => '0');

											shsync_out		<= '1';
											shcnt_out		<= (others => '0');
										else
											swait_cnt		<= swait_cnt + '1';
										end if;
									end if;
				when others		=> 
									NULL;
			end case;
		end if;
	end process;

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			sreg_line_time		<= (others => '0');
			sreg_sd_wen			<= '0';
			sreg_width			<= (others => '0');
			sreg_height			<= (others => '0');
		elsif(idata_clk'event and idata_clk = '1') then
			if(svsync_out = '0') then
				sreg_line_time	<= ireg_line_time;
				sreg_sd_wen		<= ireg_sd_wen;
--				sreg_width		<= ireg_width; 
				if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") then --# 221221mbh
    				sreg_width		<= "00" & ireg_width(12-1 downto 0 + 2);
    			else 
    			    sreg_width		<= ireg_width;
    			end if;
				sreg_height		<= ireg_height;
			end if;
		end if;
	end process;

	ohsync			<= shsync_out;	
	ovsync			<= svsync_out;	
	ohcnt			<= shcnt_out;	
	ovcnt			<= svcnt_out;	

--* 	ichk_cnt	<= '0' when (ivsync & not svsync_1d) 
--* 					else ichk_cnt <= ichk_cnt +1;	

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			ochk_cnt 	<= (others => '0');
			ochk_cnt_v	<= (others => '0');

		elsif(idata_clk'event and idata_clk = '1') then
			if( svsync_out = '1' and ovsync_1d = '0') then
				ochk_cnt 	<= (others =>'0');
				ochk_cnt_v	<= ochk_cnt; 
			else
				ochk_cnt <= ochk_cnt + '1';
			end if;
		end if;	
	end process;

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			ichk_cnt 	<= (others => '0');
			ichk_cnt_v	<= (others => '0');

		elsif(idata_clk'event and idata_clk = '1') then
			if( ivsync = '1' and svsync_1d = '0') then
				ichk_cnt 	<= (others =>'0');
				ichk_cnt_v	<= ichk_cnt; 
			else
				ichk_cnt <= ichk_cnt + '1';
			end if;
		end if;	
	end process;

	process(idata_clk, idata_rstn)
	begin
		if(idata_rstn = '0') then
			svsync_1d		<= '0';
			svsync_2d		<= '0';
			svsync_3d		<= '0';
			sreq_data_1d	<= '0';
			sreq_data_2d	<= '0';
			sreq_data_3d	<= '0';
			ovsync_1d		<= '0';
		elsif(idata_clk'event and idata_clk = '1') then
			svsync_1d		<= ivsync;
			svsync_2d		<= svsync_1d;
			svsync_3d		<= svsync_2d;
			sreq_data_1d	<= ireq_data;
			sreq_data_2d	<= sreq_data_1d;
			sreq_data_3d	<= sreq_data_2d;
			ovsync_1d		<= svsync_out;
		end if;
	end process;
	
	ILA_DEBUG1 : if(GEN_ILA_ddr_sync_gen = "ON") generate
	component ILA_DDR_SYNC_GEN
	port(
		clk					: in	std_logic						; 
		
		probe0				: in	std_logic						;

		probe1				: in	std_logic						;
		probe2				: in	std_logic_vector(31 downto 0)	;
		probe3				: in	std_logic_vector(31 downto 0)	;

		probe4				: in	std_logic		 	 			;
		probe5				: in	std_logic_vector(31 downto 0)	;
		probe6				: in	std_logic_vector(31 downto 0)	;
		
		probe7              : in    tstate_sync_ddr                 ;
		probe8              : in    std_logic_vector(15 downto 0)   ;
		probe9              : in    std_logic_vector(15 downto 0)   ;
		
		probe10             : in    std_logic;
		probe11             : in    std_logic;
		probe12             : in    std_logic_vector(11 downto 0)   ;
		probe13             : in    std_logic_vector(11 downto 0)   ;
		
		probe14             : in    std_logic                       ;
		probe15             : in    std_logic                       ;
		probe16             : in    std_logic_vector(11 downto 0)   ;
		probe17             : in    std_logic_vector( 9 downto 0)
		
	);
	end component;
	begin
		U0_ILA_DDR_SYNC_GEN : ILA_DDR_SYNC_GEN
		port map(
			clk					=>	idata_clk			, 
			
			probe0				=>	sframe_end_trig		,

			probe1				=>	svsync_1d			,
			probe2				=>	ichk_cnt			,
			probe3				=>	ichk_cnt_v			,

			probe4				=>	ovsync_1d			,
			probe5				=>	ochk_cnt 			,
			probe6				=>	ochk_cnt_v			,
			
			probe7				=>	state_sync			,
			probe8				=>	sreg_line_time		,
			probe9				=>	swait_cnt			,
			
			probe10				=>	svsync_out			,
			probe11				=>	shsync_out			,
			probe12				=>	svcnt_out			,
			probe13				=>	shcnt_out			,
			
			probe14				=>	ivsync			    ,
			probe15				=>	ihsync			    ,
			probe16				=>	ivcnt      			,
			probe17				=>	ihcnt  		
		);
	end generate;
end architecture behavioral;
