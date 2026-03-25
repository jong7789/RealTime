----------------------------------------------------------------------------------
-- Company: drtech
-- Engineer: .mbh
--
-- Create Date: 2021/01/13 12:01:05
-- Design Name:
-- Module Name: clk_counter - Behavioral
-- Project Name:
-- Target Devices:
-- Tool Versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_arith.ALL;
    use IEEE.STD_LOGIC_unsigned.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity clk_counter is
    generic (
        sysclkhz : integer   := 100000000;
        vio      : std_logic := '1'
    );
    port (
        ISYSCLK : in    std_logic; -- 200 Mhz
        ICLK    : in    std_logic;
        OCLKCNT : out   std_logic_vector(16 - 1 downto 0)
    );
end entity clk_counter;

architecture behavioral of clk_counter is

    component vio_clkcnt
        port (
            clk       : in    std_logic;
            probe_in0 : in    std_logic_vector(0 downto 0);
            probe_in1 : in    std_logic_vector(15 downto 0)
        );
    end component;

    constant sys100n : integer := sysclkhz / 10000; -- 100ns

    signal ToggleSys   : std_logic := '0';
    signal ToggleSys00 : std_logic := '0';
    signal sysclkCnt   : std_logic_vector(16 - 1 downto 0) := (others => '0');

    signal ToggleSys0     : std_logic := '0';
    signal ToggleSys1     : std_logic := '0';
    signal ToggleSys2     : std_logic := '0';
    signal ToggleCnt      : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal ToggleCnt0     : std_logic := '0';
    signal ToggleCnt1     : std_logic := '0';
    signal ToggleCnt2     : std_logic := '0';
    signal Die            : std_logic := '0';
    signal DieCnt         : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal SaveToggleCnt  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal SaveToggleCnt0 : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal SaveToggleCnt1 : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal SaveToggleCnt2 : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal SaveClkCnt     : std_logic_vector(16 - 1 downto 0) := (others => '0');

begin

    --# make 100ns toggle and die check in ISYSCLK domain
    process (ISYSCLK)
    begin
        if ISYSCLK'event and ISYSCLK = '1' then
            --
            -- ### make 100ns toggle
            if sysclkCnt < sys100n then
                sysclkCnt <= sysclkCnt + '1';
            else
                sysclkCnt <= (others => '0');
                ToggleSys <= not ToggleSys;
            end if;
            ToggleSys00 <= ToggleSys;

            -- ### die check
            ToggleCnt0 <= ToggleCnt(7);
            ToggleCnt1 <= ToggleCnt0;
            ToggleCnt2 <= ToggleCnt1;
            if ToggleCnt2 /= ToggleCnt1 then
                DieCnt <= (others => '0');
            else
                if DieCnt < 2 ** 16 - 1 then
                    DieCnt <= DieCnt + '1';
                end if;
            end if;
            if 2 ** 16 - 1 <= DieCnt then
                Die <= '1';
            else
                Die <= '0';
            end if;
            SaveToggleCnt0 <= SaveToggleCnt;
            SaveToggleCnt1 <= SaveToggleCnt0;
            SaveToggleCnt2 <= SaveToggleCnt1;
            if Die = '1' then
                SaveClkCnt <= (others => '0');
            else
                SaveClkCnt <= SaveToggleCnt2;
            end if;

            --
        end if;
    end process;

    OCLKCNT <= SaveClkCnt;

    --# count toggle edges in ICLK domain
    -- ### set
    process (ICLK)
    begin
        if ICLK'event and ICLK = '1' then
            --
            ToggleSys0 <= ToggleSys00;
            ToggleSys1 <= ToggleSys0;
            ToggleSys2 <= ToggleSys1;

            if ToggleSys2 /= ToggleSys1 then
                ToggleCnt     <= (others => '0');
                SaveToggleCnt <= ToggleCnt;
            else
                if ToggleCnt < x"FFFF" then
                    ToggleCnt <= ToggleCnt + '1';
                end if;
            end if;
            --
        end if;
    end process;

    gen_vio : if (vio = '1') generate
    begin
        --
        u_vio_clkcnt : vio_clkcnt
            port map (
                clk          => ISYSCLK,
                probe_in0(0) => Die,
                probe_in1    => SaveClkCnt
            );
        --
    end generate gen_vio;

end architecture behavioral;
