library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;

use WORK.TOP_HEADER.ALL;

entity LED_CTRL is
port(
	iui_clk				: in	std_logic;
	iui_rstn			: in	std_logic;

	ireg_align_done		: in	std_logic;
	ireg_grab_en		: in	std_logic;
	ireg_out_en			: in	std_logic;
	ireg_shutter		: in	std_logic;
	iext_trig			: in	std_logic;
	ireg_led_ctrl       : in    std_logic_vector(3 downto 0); -- 220118mbh

	ostate_led			: out	std_logic_vector(1 downto 0)
);
end LED_CTRL;

architecture Behavioral of LED_CTRL is

	signal sewt_state		: std_logic;
	signal scon_state		: std_logic;
	signal clkcnt  		: std_logic_vector(32-1 downto 0) :=(others=>'0');
	signal sreg_led_ctrl, sreg_led_ctrl_d0, sreg_led_ctrl_d1 : std_logic_vector(3 downto 0);
begin

	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			sewt_state		<= '0';
		elsif(iui_clk'event and iui_clk = '1') then
		    clkcnt <= clkcnt + '1';
		    sreg_led_ctrl_d0 <= ireg_led_ctrl;
		    sreg_led_ctrl_d1 <= sreg_led_ctrl_d0;
		    sreg_led_ctrl    <= sreg_led_ctrl_d1;
		    case sreg_led_ctrl is
                when x"0" => sewt_state <= '1';
                when x"1" => sewt_state <= '0';
                when x"2" => sewt_state <= clkcnt(25);
                when x"3" => sewt_state <= clkcnt(26);
                when x"4" => sewt_state <= clkcnt(27);
                when others => sewt_state <= '0';
		    end case;
		end if;
	end process;

--	process(iui_clk, iui_rstn)
--	begin
--		if(iui_rstn = '0') then
--			sewt_state		<= '0';
--		elsif(iui_clk'event and iui_clk = '1') then
--		    clkcnt <= clkcnt + '1';
--			if(ireg_align_done = '1') then
--				if(ireg_out_en = '1') then -- always 1
--					if(ireg_shutter = '0') then
--						sewt_state		<= '0';
--					else
--						sewt_state		<= iext_trig;
--					end if;
--				else
--					sewt_state		<= '1';
--				end if;
--			else
--				sewt_state		<= clkcnt(27);
--			end if;
--		end if;
--	end process;      

	process(iui_clk, iui_rstn)
	begin
		if(iui_rstn = '0') then
			scon_state		<= '0';
		elsif(iui_clk'event and iui_clk = '1') then
			if(ireg_align_done = '1') then
				scon_state		<= '1';
			else
				scon_state		<= '0';
			end if;
		end if;
	end process;

--	ostate_led(1)		<= scon_state;
--	ostate_led(0)		<= '0';
--    --## default
--	ostate_led(0)		<= sewt_state; 
--	ostate_led(1)		<= not iext_trig  ; -- red means "ERROR" , 210512 mbh
	--## 1st boot golden indicator
	ostate_led(0)		<= clkcnt(23) when FPGA_VER(7 downto 0)=x"99" else sewt_state; 
	ostate_led(1)		<= clkcnt(23) when FPGA_VER(7 downto 0)=x"99" else not iext_trig; -- red means "ERROR" , 210512 mbh

end Behavioral;
