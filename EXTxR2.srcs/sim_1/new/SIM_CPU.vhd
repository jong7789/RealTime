library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity SIM_CPU is
port (
	axi_clk  			: out	std_logic;
	axi_rst  			: out	std_logic;
	sys_rst  			: out	std_logic;

	axi_awid			: in	std_logic_vector(3 downto 0);		
	axi_awaddr			: in	std_logic_vector(31 downto 0);
	axi_awlen			: in	std_logic_vector(7 downto 0);		
	axi_awsize			: in	std_logic_vector(2 downto 0);		
	axi_awburst			: in	std_logic_vector(1 downto 0);		
	axi_awlock			: in	std_logic_vector(0 downto 0);		
	axi_awvalid			: in	std_logic;
	axi_awready			: out	std_logic := '0';
	
	axi_wdata			: in	std_logic_vector(511 downto 0);
	axi_wstrb			: in	std_logic_vector(63 downto 0);		
	axi_wlast			: in	std_logic;
	axi_wvalid			: in	std_logic;
	axi_wready			: out	std_logic := '0';
	
	axi_bid				: out	std_logic_vector(3 downto 0) := (others => '0');		
	axi_bresp			: out	std_logic_vector(1 downto 0) := (others => '0');		
	axi_bvalid			: out	std_logic := '0';
	axi_bready			: in	std_logic;
	
	axi_arid			: in	std_logic_vector(3 downto 0);		
	axi_araddr			: in	std_logic_vector(31 downto 0);
	axi_arlen			: in	std_logic_vector(7 downto 0);		
	axi_arsize			: in	std_logic_vector(2 downto 0);		
	axi_arburst			: in	std_logic_vector(1 downto 0);		
	axi_arlock			: in	std_logic_vector(0 downto 0);		
	axi_arvalid			: in	std_logic;
	axi_arready			: out	std_logic := '0';
	
	axi_rid				: out	std_logic_vector(3 downto 0) := (others => '0');		
	axi_rdata			: out	std_logic_vector(511 downto 0) := (others => '0');
	axi_rresp			: out	std_logic_vector(1 downto 0) := (others => '0');		
	axi_rlast			: out	std_logic := '0';							
	axi_rvalid			: out	std_logic := '0';
	axi_rready			: in	std_logic;
	
    bd_mclk             : out	std_logic;   
    bd_clk_lock         : out	std_logic;   
    bd_dclk             : out	std_logic   
);
end SIM_CPU;
	
architecture Behavioral of SIM_CPU is

	component RAM_512x2048
	port (
		clka 				: in	std_logic;
		ena					: in	std_logic;
		wea 				: in	std_logic;
		addra				: in	std_logic_vector(10 downto 0);
		dina 				: in	std_logic_vector(511 downto 0);
		clkb 				: in	std_logic;
		enb 				: in	std_logic;
		addrb 				: in	std_logic_vector(10 downto 0);
		doutb 				: out	std_logic_vector(511 downto 0)
	);
	end component;

	signal sclk_166m		: std_logic := '0';
	signal srstn			: std_logic := '0';

	type tstate_write		is (
									s_IDLE,
									s_READY,
									s_WWAIT,
									s_WRITE,
									s_BRESP
								);

	type tstate_read		is (
									s_IDLE,
									s_READY,
									s_RWAIT,
									s_DELAY,
									s_READ
								);

	signal state_write		: tstate_write := s_IDLE;
	signal state_read		: tstate_read := s_IDLE;

	signal sena				: std_logic := '0';
	signal saddra			: std_logic_vector(10 downto 0) := (others => '0');
	signal sdina			: std_logic_vector(511 downto 0) := (others => '0');
	signal senb				: std_logic := '0';
	signal saddrb			: std_logic_vector(10 downto 0) := (others => '0');
	signal sdoutb			: std_logic_vector(511 downto 0) := (others => '0');
	signal senb_1d			: std_logic := '0';
	signal swaddr_cnt		: std_logic_vector(10 downto 0) := (others => '0');
	signal sraddr_cnt		: std_logic_vector(10 downto 0) := (others => '0');
	
	signal mclkcnt		: std_logic_vector(10 downto 0) := (others => '0');
    signal sbd_mclk     : std_logic:= '0';
    signal sbd_dclk     : std_logic:= '0';
begin

	bd_dclk_GEN : process
	begin
		sbd_dclk		<= '1'; 		wait for 2.082 ns;
		sbd_dclk		<= '0'; 		wait for 2.082 ns;
	end process;
	
	process(sbd_dclk)
	begin
		if(sbd_dclk'event and sbd_dclk = '1') then
		--
              if mclkcnt < 5 then
                  mclkcnt <= mclkcnt + '1';
              else
                  mclkcnt <= (others => '0');
        		  sbd_mclk <= not sbd_mclk;
              end if;
         --
		 end if;
    end process;
     		 
    bd_mclk <= sbd_mclk;
    bd_dclk <= sbd_dclk;
	bd_clk_lock <= '1';	
		
	CLK_166M_GEN : process
	begin
		sclk_166m		<= '1'; 		wait for 3.000 ns;
		sclk_166m		<= '0'; 		wait for 3.000 ns;
	end process;

	RST_GEN : process
	begin
		srstn			<= '0'; 		wait for 50.00 ns;
		srstn			<= '1';			wait;
	end process;

	U0_RAM_512x2048 : RAM_512x2048
	port map (
		clka 			=> sclk_166m,
		ena				=> sena,
		wea 			=> '1',
		addra			=> saddra,
		dina 			=> sdina,
		clkb 			=> sclk_166m,
		enb 			=> senb,
		addrb 			=> saddrb,
		doutb 			=> sdoutb
	);

	axi_clk			<= sclk_166m;
	axi_rst			<= not srstn;
	sys_rst			<= not srstn;

	-- Write
	process(sclk_166m)
	begin
		if(sclk_166m'event and sclk_166m = '1') then
			senb_1d		<= senb;
			case (state_write) is
				when s_IDLE		=>
									if(axi_awvalid = '1') then
										state_write		<= s_READY;
										axi_awready		<= '1';

										saddra		<= axi_awaddr(16 downto 6);
										swaddr_cnt	<= (others => '0');
									else
										axi_awready		<= '0';
									end if;

									axi_bvalid		<= '0';
	
				when s_READY	=> 
									state_write		<= s_WWAIT;
									axi_awready		<= '0';

				when s_WWAIT	=> 
									if(axi_wvalid = '1') then
										axi_wready		<= '1';
										sena			<= '1';
										sdina			<= axi_wdata;

										if(axi_wlast = '1') then
											state_write		<= s_BRESP;
										else
											state_write		<= s_WRITE;
										end if;
									else
										axi_wready		<= '0';
									end if;

				when s_WRITE	=> 
									axi_wready		<= '0';
									sena			<= '0';

									if(swaddr_cnt = axi_awlen) then
										state_write		<= s_BRESP;
										saddra			<= (others => '0');
										swaddr_cnt		<= (others => '0');
									else
										state_write		<= s_WWAIT;
										saddra			<= saddra + '1';
										swaddr_cnt		<= swaddr_cnt + '1';
									end if;

				when s_BRESP	=> 
									if(axi_bready = '1') then
										state_write		<= s_IDLE;
										axi_bvalid		<= '1';
										axi_wready		<= '0';
										sena			<= '0';
										saddra			<= (others => '0');
										sdina			<= (others => '0');
										swaddr_cnt		<= (others => '0');
									end if;


				when others		=> 
									NULL;
			end case;
		end if;
	end process;



	-- Read
	process(sclk_166m)
	begin
		if(sclk_166m'event and sclk_166m = '1') then
			case (state_read) is
				when s_IDLE		=>
									if(axi_arvalid = '1') then
										state_read		<= s_READY;
										axi_arready		<= '1';

										saddrb			<= axi_araddr(16 downto 6);
										sraddr_cnt		<= (others => '0');
									else
										axi_arready		<= '0';
									end if;

									axi_rvalid			<= '0';
									axi_rlast			<= '0';
	
				when s_READY	=> 
									state_read			<= s_RWAIT;
									axi_arready			<= '0';

				when s_RWAIT	=> 
									if(axi_rready = '1') then
										state_read		<= s_DELAY;
										senb			<= '1';
									end if;
									axi_rvalid		<= '0';

				when s_DELAY	=> 
									state_read		<= s_READ;
									
				when s_READ		=> 
									if(sraddr_cnt = axi_arlen) then
										state_read		<= s_IDLE;
										senb			<= '0';
										saddrb			<= (others => '0');
										sraddr_cnt		<= (others => '0');
										axi_rlast		<= '1';
									else
										state_read		<= s_RWAIT;
										senb			<= '1';
										saddrb			<= saddrb + '1';
										sraddr_cnt		<= sraddr_cnt + '1';
										axi_rlast		<= '0';
									end if;

									axi_rvalid		<= '1';
									axi_rdata		<= sdoutb;

				when others		=> 
									NULL;
			end case;
		end if;
	end process;

end Behavioral;
