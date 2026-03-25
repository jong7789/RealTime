----------------------------------------------------------------------------------
-- Company: DRT
-- Engineer: mbh
--
-- Create Date: 08/18/2023 10:06:48 AM
-- Design Name:
-- Module Name: EQ_CTRL_1x1 - Behavioral
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
--    use WORK.TOP_HEADER.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity EQ_CTRL_1x1 is
    Port (
        clk  : in  std_logic;
        rstn : in  std_logic;

        i_regHActive  : in std_logic_vector(12-1 downto 0);
        i_regVActive  : in std_logic_vector(12-1 downto 0);
        i_regEqCtrl   : in std_logic_vector(16-1 downto 0);
        i_regEqTopVal : in std_logic_vector(16-1 downto 0);

        i_hsyn : in  std_logic;
        i_vsyn : in  std_logic;
        i_hcnt : in  std_logic_vector(12-1 downto 0);
        i_vcnt : in  std_logic_vector(12-1 downto 0);
        i_data : in  std_logic_vector(16-1 downto 0);

        o_hsyn : out std_logic;
        o_vsyn : out std_logic;
        o_hcnt : out std_logic_vector(12-1 downto 0);
        o_vcnt : out std_logic_vector(12-1 downto 0);
        o_data : out std_logic_vector(16-1 downto 0)
    );
end EQ_CTRL_1x1;

architecture Behavioral of EQ_CTRL_1x1 is

    component EQ_4096 is
        port (
            clk  : in  std_logic;
            rstn : in  std_logic;

            i_regHActive  : in std_logic_vector(12-1 downto 0);
            i_regVActive  : in std_logic_vector(12-1 downto 0);
            i_regEqCtrl   : in std_logic_vector(16-1 downto 0);
            i_regEqTopVal : in std_logic_vector(16-1 downto 0);

            i_hsbp : in  std_logic;
            i_vsbp : in  std_logic;

            i_hsyn : in  std_logic;
            i_vsyn : in  std_logic;
            i_hcnt : in  std_logic_vector(11 downto 0);
            i_vcnt : in  std_logic_vector(11 downto 0);
            i_data : in  std_logic_vector(15 downto 0);

            o_hsyn : out std_logic;
            o_vsyn : out std_logic;
            o_hcnt : out std_logic_vector(11 downto 0);
            o_vcnt : out std_logic_vector(11 downto 0);
            o_data : out std_logic_vector(15 downto 0)
        );
    end component;

    constant zero12 : std_logic_vector(12-1 downto 0) := (others => '0');

    signal HActStt : std_logic_vector(12-1 downto 0);
    signal VActStt : std_logic_vector(12-1 downto 0);
    signal HActEnd : std_logic_vector(12-1 downto 0);
    signal VActEnd : std_logic_vector(12-1 downto 0);

    signal ibp_hsyn : std_logic;
    signal ibp_vsyn : std_logic;
    signal iac_hsyn : std_logic;
    signal iac_vsyn : std_logic;
    signal iac_hcnt : std_logic_vector(12-1 downto 0);
    signal iac_vcnt : std_logic_vector(12-1 downto 0);
    signal iac_data : std_logic_vector(16-1 downto 0);

    signal oeq_hsyn : std_logic;
    signal oeq_vsyn : std_logic;
    signal oeq_hcnt : std_logic_vector(12-1 downto 0);
    signal oeq_vcnt : std_logic_vector(12-1 downto 0);
    signal oeq_data : std_logic_vector(16-1 downto 0);

    signal act_HActive : std_logic_vector(12-1 downto 0);
    signal act_VActive : std_logic_vector(12-1 downto 0);

begin

    --# Active area except Edge
    process(clk)
    begin
        if clk'event and clk = '1' then
            --
            -- EQ active area  6.25~94.75 %
            HActStt <= zero12 + i_regHActive(12-1 downto 4); --# 6.25%
            HActEnd <= zero12 + i_regHActive(12-1 downto 1) +
                                i_regHActive(12-1 downto 2) +
                                i_regHActive(12-1 downto 3) +
                                i_regHActive(12-1 downto 4); --# 94.75 %
            VActStt <= zero12 + i_regVActive(12-1 downto 4); --# 6.25%
            VActEnd <= zero12 + i_regVActive(12-1 downto 1) +
                                i_regVActive(12-1 downto 2) +
                                i_regVActive(12-1 downto 3) +
                                i_regVActive(12-1 downto 4); --# 94.75 %
            act_HActive <= zero12 + i_regHActive(12-1 downto 1) + -- 87.5%
                                    i_regHActive(12-1 downto 2) +
                                    i_regHActive(12-1 downto 3);
            act_VActive <= zero12 + i_regVActive(12-1 downto 1) +
                                    i_regVActive(12-1 downto 2) +
                                    i_regVActive(12-1 downto 3);

            -- Active H sync
            if HActStt <= i_hcnt and i_hcnt < HActEnd and
               VActStt <= i_vcnt and i_vcnt < VActEnd then
                iac_hsyn <= i_hsyn;
            else
                iac_hsyn <= '0';
            end if;
            iac_vsyn <= i_vsyn;
            iac_hcnt <= i_hcnt;
            iac_vcnt <= i_vcnt;
            iac_data <= i_data;

            ibp_hsyn <= i_hsyn;
            ibp_vsyn <= i_vsyn;

            --
        end if;
    end process;

    U0_EQ_4096 : EQ_4096
        port map (
            clk  => clk,
            rstn => rstn,

            i_regHActive  => act_HActive,
            i_regVActive  => act_VActive,
            i_regEqCtrl   => i_regEqCtrl,
            i_regEqTopVal => i_regEqTopVal,

            i_hsbp => ibp_hsyn,
            i_vsbp => ibp_vsyn,

            i_hsyn => iac_hsyn,
            i_vsyn => iac_vsyn,
            i_hcnt => iac_hcnt,
            i_vcnt => iac_vcnt,
            i_data => iac_data,

            o_hsyn => oeq_hsyn,
            o_vsyn => oeq_vsyn,
            o_hcnt => oeq_hcnt,
            o_vcnt => oeq_vcnt,
            o_data => oeq_data
        );

    o_hsyn <= oeq_hsyn;
    o_vsyn <= oeq_vsyn;
    o_hcnt <= oeq_hcnt;
    o_vcnt <= oeq_vcnt;
    o_data <= oeq_data;

end Behavioral;
