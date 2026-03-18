library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;

entity SIM_SDHC is
port (
	isd_sclk			: in	std_logic;
	isd_csn				: in	std_logic;
	isd_mosi			: in	std_logic;
	osd_miso			: out	std_logic
);
end SIM_SDHC;
	
architecture Behavioral of SIM_SDHC is

	type tstate_sdhc	is	(
								s_CMD_WRITE,
								s_CMD_RESP,
								s_CMD_READ,
								s_READY,
								s_WRITE,
								s_WRITE_RDY,
								s_READ_RDY,
								s_CRC,
								s_READ,
								s_RESP
							);

	signal state_sdhc	: tstate_sdhc := s_CMD_WRITE;

	signal ssd_miso		: std_logic := '0';
	signal stx_par		: std_logic_vector(31 downto 0) := (others => '0');
	signal srx_par		: std_logic_vector(47 downto 0) := (others => '0');
	signal sbit_cnt		: std_logic_vector(5 downto 0) := (others => '0');
	signal sbit_cnt_1d	: std_logic_vector(5 downto 0) := (others => '0');
	signal sbyte_cnt	: std_logic_vector(9 downto 0) := (others => '0');
	signal sbit_num		: integer range 0 to 47 := 47;
	signal scmd_num		: integer range 0 to 55 := 0;
	signal swait_cnt	: std_logic_vector(7 downto 0) := (others => '0');

	signal swr_en		: std_logic := '0';
	signal swr_addr		: std_logic_vector(13 downto 0) := (others => '0');
	signal swr_data		: std_logic_vector(7 downto 0) := (others => '0');
	signal sblock_addr	: std_logic_vector(31 downto 0) := (others => '0');
	signal srw_mode		: std_logic := '0';

begin

	process(isd_sclk)
	begin
		if(isd_sclk'event and isd_sclk = '1') then
			if(isd_csn = '1') then
				sbit_cnt		<= (others => '0');
				sbyte_cnt		<= (others => '0');
				swait_cnt		<= (others => '0');
			else
				sbit_cnt_1d		<= sbit_cnt;
				case (state_sdhc) is
					when s_CMD_WRITE =>
										if(sbit_cnt = 47) then
											state_sdhc	<= s_CMD_RESP;
											sbit_cnt	<= (others => '0');
											if(scmd_num = 0) then
												stx_par(7 downto 0)		<= x"01";
											elsif(scmd_num = 41) then
												stx_par(7 downto 0)		<= x"00";
											else
												stx_par(7 downto 0)		<= x"AA";
											end if;
										else
											sbit_cnt 	<= sbit_cnt + '1';
										end if;

										srx_par   	<= srx_par(46 downto 0) & isd_mosi;
					when s_CMD_RESP	=>
										if(sbit_cnt = 7) then
											if(scmd_num = 0) then
												state_sdhc	<= s_CMD_WRITE;
												scmd_num	<= 8;
											elsif(scmd_num = 8) then
												state_sdhc	<= s_CMD_READ;
												stx_par		<= x"12345678";
											elsif(scmd_num = 55) then
												state_sdhc	<= s_CMD_WRITE;
												scmd_num	<= 41;
											elsif(scmd_num = 41) then
												state_sdhc	<= s_READY;
												scmd_num	<= 0;
											end if;
											sbit_cnt	<= (others => '0');
										else
											sbit_cnt 	<= sbit_cnt + '1';
										end if;

										ssd_miso  			<= stx_par(7);
										stx_par(7 downto 0) <= stx_par(6 downto 0) & '1';

					when s_CMD_READ	=>
										if(sbit_cnt = 31) then
											state_sdhc	<= s_CMD_WRITE;
											scmd_num	<= 55;
											sbit_cnt	<= (others => '0');
										else
											sbit_cnt 	<= sbit_cnt + '1';
										end if;

										ssd_miso  	<= stx_par(31);
										stx_par    	<= stx_par(30 downto 0) & '1';

					when s_READY	=>
										if(sbit_cnt = 47) then
											state_sdhc			<= s_RESP;
											sbit_cnt			<= (others => '0');
											stx_par(7 downto 0)	<= x"7F";
										else
											sbit_cnt		<= sbit_cnt + '1';
										end if;

										srx_par   	<= srx_par(46 downto 0) & isd_mosi;

					when s_WRITE_RDY =>		
										if(sbit_cnt = 7) then
											if(sbyte_cnt = 1) then
												state_sdhc		<= s_WRITE;
												sbyte_cnt		<= (others => '0');
											else
												sbyte_cnt		<= sbyte_cnt + '1';
											end if;
											sbit_cnt		<= (others => '0');
										else
											sbit_cnt		<= sbit_cnt + '1';
										end if;

										ssd_miso  			<= '0';
										stx_par(7 downto 0)	<= stx_par(6 downto 0) & isd_mosi;
										
					when s_WRITE	=>
										if(sbit_cnt = 7) then
											if(sbyte_cnt = 511) then
												state_sdhc		<= s_CRC;
												sbyte_cnt		<= (others => '0');
											else
												sbyte_cnt		<= sbyte_cnt + '1';
											end if;
											sbit_cnt		<= (others => '0');
										else
											sbit_cnt		<= sbit_cnt + '1';
										end if;

										ssd_miso  			<= '0';
										stx_par(7 downto 0)	<= stx_par(6 downto 0) & isd_mosi;
					when s_CRC		=>
										if(sbit_cnt = 7) then
											if(sbyte_cnt = 1) then
												if(srw_mode = '0') then
													state_sdhc			<= s_RESP;
													stx_par(7 downto 0)	<= "00000101";
												else
													state_sdhc			<= s_READY;
												end if;
												sbyte_cnt			<= (others => '0');
											else
												sbyte_cnt		<= sbyte_cnt + '1';
											end if;
											sbit_cnt		<= (others => '0');
										else
											sbit_cnt		<= sbit_cnt + '1';
										end if;

										ssd_miso  			<= '1';

					when s_READ_RDY	=>		
										if(sbit_cnt = 7) then
											state_sdhc			<= s_READ;
											sbit_cnt			<= (others => '0');
											sbyte_cnt			<= sbyte_cnt + '1';
											stx_par(7 downto 0) <= (others => '0');
										else
											sbit_cnt			<= sbit_cnt + '1';
											stx_par(7 downto 0) <= stx_par(6 downto 0) & '1';
										end if;

										ssd_miso			<= stx_par(7);

					when s_READ		=>
										if(sbit_cnt = 7) then
											if(sbyte_cnt = 512) then
												state_sdhc			<= s_CRC;
												sbyte_cnt			<= (others => '0');
											else
												sbyte_cnt			<= sbyte_cnt + '1';
											end if;
											sbit_cnt		<= (others => '0');
										else
											sbit_cnt		<= sbit_cnt + '1';
										end if;

										ssd_miso  			<= stx_par(7);
										if(sbit_cnt = 7) then
											stx_par(7 downto 0)	<= sbyte_cnt(7 downto 0);
										else
											stx_par(7 downto 0) <= stx_par(6 downto 0) & '1';
										end if;

					when s_RESP		=>	
										if(sbit_cnt = 7) then
											if(srx_par(47 downto 40) = x"51") then
												state_sdhc				<= s_READ_RDY;
												srx_par(47 downto 40)	<= (others => '0');
												sblock_addr				<= srx_par(39 downto 8);
												srw_mode				<= '1';
											elsif(srx_par(47 downto 40) = x"58") then
												state_sdhc				<= s_WRITE_RDY;
												srx_par(47 downto 40)	<= (others => '0');
												sblock_addr				<= srx_par(39 downto 8);
												srw_mode				<= '0';
											else
												state_sdhc		<= s_READY;
											end if;
											sbit_cnt	<= (others => '0');
										else
											sbit_cnt 	<= sbit_cnt + '1';
										end if;


										ssd_miso  			<= stx_par(7);
										if(sbit_cnt = 7 and srx_par(47 downto 40) = x"51") then
											stx_par(7 downto 0)		<= x"FE";
										else
											stx_par(7 downto 0) 	<= stx_par(6 downto 0) & '1';
										end if;
					when others		=>
										NULL;
										
				end case;
			end if;
		end if;
	end process;


	process(isd_sclk)
	begin
		if(isd_sclk'event and isd_sclk = '1') then
			if(isd_csn = '1') then
				swr_en			<= '0';
				swr_addr		<= (others => '0');
			else
				if(state_sdhc = s_WRITE) then
					swr_en		<= '1';
					swr_addr	<= sblock_addr(4 downto 0) & sbyte_cnt(8 downto 0);
				else
					swr_en		<= '0';
					swr_addr	<= (others => '0');
				end if;
			end if;
		end if;
	end process;

	process(isd_sclk)
	begin
		if(isd_sclk'event and isd_sclk = '0') then
			if(isd_csn = '1') then
				swr_data		<= (others => '0');
			else
				if(swr_en = '1') then
					if(sbit_cnt_1d = 7) then
						swr_data	<= stx_par(7 downto 0);
					end if;
				else
					swr_data	<= (others => '0');
				end if;
			end if;
		end if;
	end process;

--	swr_en					<= '1'						when (state_sdhc = s_WRITE)						else '0';
--	swr_addr(13 downto 9)	<= sblock_addr(4 downto 0);
--	swr_addr(8 downto 0)	<= sbyte_cnt(8 downto 0) 	when state_sdhc = s_WRITE 						else (others => '0');
--	swr_data				<= stx_par(7 downto 0) 		when (sbit_cnt = 0 and state_sdhc = s_WRITE);
						
	osd_miso		<= ssd_miso;

end Behavioral;
