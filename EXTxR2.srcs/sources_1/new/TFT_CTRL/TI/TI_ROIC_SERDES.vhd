library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

LIBRARY	UNISIM;
USE	UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;

entity TI_ROIC_SERDES is
generic (
    geni : integer := 0
    );
port (
	iroic_clk		: in	std_logic; 
	iroic_rstn		: in	std_logic; 
	
	ireg_req_align  : in    std_logic;

	idata_ser		: in	std_logic; 
	odata_par		: out	std_logic_vector(23 downto 0); 
	odata_val		: out	std_logic; 
	odata_diff		: out	std_logic; 
	odata_ff00      : out	std_logic; 

    obitslipm : out   std_logic;
    obitslipc : out   std_logic_vector(4 downto 0);
    ocntvalue : out   std_logic_vector(4 downto 0);
    oser_cnt  : out   std_logic_vector(4 downto 0);
    
    sroic_dvalid_3d  : in	 std_logic; --# ila

	idly_ce			: in	std_logic; 
	idly_rst		: in	std_logic; 
	ibitslip		: in	std_logic
);
end TI_ROIC_SERDES;
	
architecture Behavioral of TI_ROIC_SERDES is

	signal sdata_ser_dly	: std_logic;

	signal sser_cnt			: integer range 0 to 23;
	signal sdata_par		: std_logic_vector(23 downto 0);
	signal sdata_par0		: std_logic_vector(23 downto 0);
	signal sdata_par1		: std_logic_vector(23 downto 0);
	signal sdata_par2		: std_logic_vector(23 downto 0);
	signal sdata_val		: std_logic;
	signal sshift_cnt		: integer range 0 to 23;

	signal sddr_q1			: std_logic := '0';
	signal sddr_q2			: std_logic := '0';
	signal sddr_q2_1d		: std_logic := '0';

	type tstate_serdes		is (
									s_IDLE,
									s_WAIT,
									s_DATA
								);

	signal state_serdes		: tstate_serdes;
	signal sbitslip_mode	: std_logic;

	signal ila_ser_cnt		: std_logic_vector(4 downto 0);
	signal sbitslip_cnt		: std_logic_vector(4 downto 0);
	
	constant  strain_word   : std_logic_vector(23 downto 0) := x"FFF000";
	signal svalid_data      : std_logic_vector(23 downto 0);
	signal  sslip_data      : std_logic_vector(23 downto 0);
	
	signal sdata_diff	    : std_logic;
	signal sdata_ff00       : std_logic;

	component ILA_ROIC_SERDES
	port (
		clk			: in std_logic;
	   probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	   probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	   probe2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0); 
	   probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	   probe4 : IN tstate_serdes; 
	   probe5 : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
	   probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
);
	end component;

begin
	U0_IDELAYE2 : IDELAYE2
	generic map (
		CINVCTRL_SEL 			=> "TRUE",			
		DELAY_SRC 				=> "IDATAIN",		
		HIGH_PERFORMANCE_MODE 	=> "TRUE",			
		IDELAY_TYPE 			=> "VARIABLE",		
		IDELAY_VALUE 			=> 0,				
		PIPE_SEL 				=> "FALSE",			
		REFCLK_FREQUENCY 		=> REF_CLK,			
		SIGNAL_PATTERN 			=> "DATA"			
	)
	port map (
		CNTVALUEOUT				=> ocntvalue,			
		DATAOUT 				=> sdata_ser_dly,	
		C 						=> iroic_clk,
		CE 						=> idly_ce,			
		CINVCTRL 				=> '0',				
		CNTVALUEIN 				=> "00000",			
		DATAIN 					=> '0',				
		IDATAIN 				=> idata_ser,		
		INC 					=> '1',				
		LD 						=> idly_rst,		
--		LD 						=> '0',
		LDPIPEEN 				=> '0',				
		REGRST 					=> '0'				
--		REGRST 					=> idly_rst	-- fail			
	);

	U0_IDDR : IDDR
	generic map (
		DDR_CLK_EDGE			=> "SAME_EDGE_PIPELINED",
		INIT_Q1					=> '0',
		INIT_Q2					=> '0',
		SRTYPE					=> "SYNC"
	)
	port map (
		d 						=> sdata_ser_dly,
		q1						=> sddr_q1,
		q2						=> sddr_q2,
		c 						=> iroic_clk,
		r 						=> '0',
		s 						=> '0',
		ce						=> iroic_rstn
	);

obitslipm <= sbitslip_mode;
oser_cnt  <= conv_std_logic_vector(sser_cnt,5);
obitslipc <= sbitslip_cnt;

	process(iroic_clk, iroic_rstn)
	begin	
		if(iroic_rstn = '0') then
			state_serdes	<= s_IDLE;

			sbitslip_mode	<= '0';
			sser_cnt		<= 11;
			sdata_par		<= (others => '0');
			sdata_par0		<= (others => '0');
			sdata_val		<= '0';
			sddr_q2_1d		<= '0';
			
		elsif(iroic_clk'event and iroic_clk = '1') then
		
			sddr_q2_1d		<= sddr_q2;

			if(sbitslip_mode = '0') then
				sdata_par((sser_cnt*2)+1)	<= sddr_q1;
				sdata_par((sser_cnt*2))		<= sddr_q2;
			else
				sdata_par((sser_cnt*2)+1)	<= sddr_q2_1d;
				sdata_par((sser_cnt*2))		<= sddr_q1;
			end if;
            
            sdata_par0 <= sdata_par;
            sdata_par1 <= sdata_par0;
            sdata_par2 <= sdata_par1;
            if sdata_par2 /= sdata_par then
                sdata_diff <= '1';
            else
                sdata_diff <= '0';
            end if;
            
            if(sdata_par2 = strain_word) then
                sdata_ff00 <= '1';
            else
                sdata_ff00 <= '0';
            end if;
            
            
			case state_serdes is
				when s_IDLE		=> 
									state_serdes	<= s_DATA;
				when s_DATA		=>
									if(ibitslip = '1') then				   
									   if sbitslip_cnt < 23 then
									       sbitslip_cnt <= sbitslip_cnt + '1';
									   else
									       sbitslip_cnt <= (others=>'0');
									   end if;
									   
										if(sser_cnt = 1) then
											sbitslip_mode	<= not sbitslip_mode;
											if(sbitslip_mode = '0') then
												sser_cnt	<= 11;
												sdata_val	<= '1';
												sslip_data  <= sdata_par;
											else
												sser_cnt	<= sser_cnt - 1;
												sdata_val	<= '0';
											end if;
										else
											state_serdes	<= s_WAIT;
											if(sser_cnt = 0) then
												sser_cnt	<= 11;
												sslip_data  <= sdata_par;
												sdata_val	<= '1';
											else
												sser_cnt	<= sser_cnt - 1;
												sdata_val	<= '0';
											end if;
										end if;
									else
										if(sser_cnt = 0) then
											sser_cnt		<= 11;
											sdata_val		<= '1';
											svalid_data     <= sdata_par;
										else
											sser_cnt		<= sser_cnt - 1;
											sdata_val		<= '0';
										end if;
									end if;
									
				when s_WAIT		=>
									if(sser_cnt = 1) then
										state_serdes	<= s_DATA;
										sbitslip_mode	<= not sbitslip_mode;
										if(sbitslip_mode = '0') then
											sser_cnt	<= 11;
											sdata_val	<= '1';
										else
											sser_cnt	<= sser_cnt - 1;
											sdata_val	<= '0';
										end if;
									else
										if(sser_cnt = 0) then
											sser_cnt		<= 11;
											sdata_val		<= '1';
										else
											sser_cnt		<= sser_cnt - 1;
											sdata_val		<= '0';
										end if;
									end if;
										
				when others		=>
									NULL;
			end case;
		end if;
	end process;

	odata_par		<= sdata_par;
	odata_val		<= sdata_val;
    odata_diff      <= sdata_diff;
    odata_ff00      <= sdata_ff00;
    
--	process(iroic_clk, iroic_rstn)
--	begin	
--		if(iroic_rstn = '0') then
--			sshift_cnt		<= 0;
--		elsif(iroic_clk'event and iroic_clk = '1') then
--			if(ibitslip = '1') then
--				if(sshift_cnt = 23) then
--					sshift_cnt		<= 0;
--				else
--					sshift_cnt		<= sshift_cnt + 1;
--				end if;
--			end if;
--		end if;
--	end process;

--	process(iroic_clk, iroic_rstn)
--	begin	
--		if(iroic_rstn = '0') then
--			odata_par		<= (others => '0');
--			odata_val		<= '0';
--		elsif(iroic_clk'event and iroic_clk = '1') then
--			odata_val		<= sdata_val;
--			if(sdata_val = '1') then
--				case sshift_cnt is 
--					when 0		=>	odata_par	<= sdata_par(23 downto 00);
--					when 1		=>	odata_par	<= sdata_par(22 downto 00) & sdata_par(23 downto 23);
--					when 2		=>	odata_par	<= sdata_par(21 downto 00) & sdata_par(23 downto 22);
--					when 3		=>	odata_par	<= sdata_par(20 downto 00) & sdata_par(23 downto 21);
--					when 4		=>	odata_par	<= sdata_par(19 downto 00) & sdata_par(23 downto 20);
--					when 5		=>	odata_par	<= sdata_par(18 downto 00) & sdata_par(23 downto 19);
--					when 6		=>	odata_par	<= sdata_par(17 downto 00) & sdata_par(23 downto 18);
--					when 7		=>	odata_par	<= sdata_par(16 downto 00) & sdata_par(23 downto 17);
--					when 8		=>	odata_par	<= sdata_par(15 downto 00) & sdata_par(23 downto 16);
--					when 9		=>	odata_par	<= sdata_par(14 downto 00) & sdata_par(23 downto 15);
--					when 10		=>	odata_par	<= sdata_par(13 downto 00) & sdata_par(23 downto 14);
--					when 11		=>	odata_par	<= sdata_par(12 downto 00) & sdata_par(23 downto 13);
--					when 12		=>	odata_par	<= sdata_par(11 downto 00) & sdata_par(23 downto 12);
--					when 13		=>	odata_par	<= sdata_par(10 downto 00) & sdata_par(23 downto 11);
--					when 14		=>	odata_par	<= sdata_par(09 downto 00) & sdata_par(23 downto 10);
--					when 15		=>	odata_par	<= sdata_par(08 downto 00) & sdata_par(23 downto 09);
--					when 16		=>	odata_par	<= sdata_par(07 downto 00) & sdata_par(23 downto 08);
--					when 17		=>	odata_par	<= sdata_par(06 downto 00) & sdata_par(23 downto 07);
--					when 18		=>	odata_par	<= sdata_par(05 downto 00) & sdata_par(23 downto 06);
--					when 19		=>	odata_par	<= sdata_par(04 downto 00) & sdata_par(23 downto 05);
--					when 20		=>	odata_par	<= sdata_par(03 downto 00) & sdata_par(23 downto 04);
--					when 21		=>	odata_par	<= sdata_par(02 downto 00) & sdata_par(23 downto 03);
--					when 22		=>	odata_par	<= sdata_par(01 downto 00) & sdata_par(23 downto 02);
--					when 23		=>	odata_par	<= sdata_par(00 downto 00) & sdata_par(23 downto 01);
--					when others	=>	NULL;
--				end case;
--			end if;
--		end if;
--	end process;
	
	ila_ser_cnt 	<= conv_std_logic_vector(sser_cnt, 5);
	
--	ILA_DEBUG : if(GEN_ILA_lvds_serdes = "ON" and  geni = 0 ) generate
	ILA_DEBUG : if(GEN_ILA_lvds_serdes = "ON" and  (geni = 3 or geni = 4 or geni = 10  or geni = 11 ) ) generate

		U0_ILA_ROIC_SERDES : ILA_ROIC_SERDES 
		port map (
			clk			=> iroic_clk,
			probe0(0)	=> sddr_q1,
			probe1(0)	=> sddr_q2,
			probe2		=> ila_ser_cnt,
			probe3(0)   => sdata_val,
			probe4		=> state_serdes,
			probe5		=> sdata_par,
			probe6(0)	=> sroic_dvalid_3d
		);
	end generate;
			

end Behavioral;
