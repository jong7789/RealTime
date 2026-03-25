library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity GATE_SETTING is
port (
    imain_clk    : in  std_logic;
    imain_rstn   : in  std_logic;

    ireg_img_mode : in  std_logic_vector(2 downto 0);

    itft_busy    : in  std_logic;

    ogate_ind    : out std_logic
);
end GATE_SETTING;

architecture Behavioral of GATE_SETTING is

    signal sgate_ind : std_logic;

begin

    --# Gate indicator control: select odd/even channel output mode
    process(imain_clk)
    begin
        if(imain_clk'event and imain_clk = '1') then
            if(imain_rstn = '0') then
                sgate_ind <= '0';
            else
                if(itft_busy = '0') then
                    if(ireg_img_mode = 0 or ireg_img_mode(2 downto 1) = "10") then
                        sgate_ind <= '0';        -- All Channel Out
                    else
                        sgate_ind <= '1';        -- Odd / Even Channel Out
                    end if;
                end if;
            end if;
        end if;
    end process;

    ogate_ind <= sgate_ind; -- Individually Control Odd/Even [0: All Out, 1: Odd/Even Out]

end Behavioral;
