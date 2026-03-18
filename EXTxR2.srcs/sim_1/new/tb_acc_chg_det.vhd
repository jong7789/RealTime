----------------------------------------------------------------------------------
-- Company: drt
-- Engineer: mbh
--
-- Create Date: 2022/03/24 11:58:54
-- Design Name:
-- Module Name: tb_acc_chg_det - Behavioral
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
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

entity tb_acc_chg_det is
--  Port ( );
end entity tb_acc_chg_det;

architecture behavioral of tb_acc_chg_det is

    component change_detector is
        port (
            clk             : in    std_logic;
            i_reg_width     : in    std_logic_vector(12 - 1 downto 0);
            i_reg_height    : in    std_logic_vector(12 - 1 downto 0);
            i_reg_chgdet_en : in    std_logic;
            i_reg_chgdet_md : in    std_logic;
            i_reg_chgSense  : in    std_logic_vector( 2 - 1 downto 0);
            o_reg_chgdet    : out   std_logic_vector( 8 - 1 downto 0);
            i_Hsyn          : in    std_logic;
            i_Vsyn          : in    std_logic;
            i_Hcnt          : in    std_logic_vector(12 - 1 downto 0);
            i_Vcnt          : in    std_logic_vector(12 - 1 downto 0);
            i_Data          : in    std_logic_vector(16 - 1 downto 0);
            o_change        : out   std_logic
        );
    end component;

    constant clk_period : time := 5 ns;

    signal clk             : std_logic := '0';
    signal i_reg_width     : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal i_reg_height    : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal i_reg_chgdet_en : std_logic := '0';
    signal i_reg_chgdet_md : std_logic := '0';
    signal i_reg_chgSense  : std_logic_vector(2 - 1 downto 0) := (others=>'0');
    signal o_reg_chgdet    : std_logic_vector(8 - 1 downto 0) := (others=>'0');
    signal i_Hsyn          : std_logic := '0';
    signal i_Vsyn          : std_logic := '0';
    signal i_Hcnt          : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal i_Vcnt          : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal i_Data          : std_logic_vector(16 - 1 downto 0) := (others=>'0');
    signal o_change        : std_logic := '0';

    signal reg_width     : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal reg_height    : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal reg_chgdet_en : std_logic := '0';
    signal reg_chgdet_md : std_logic := '0';
    signal reg_chgSense  : std_logic_vector(2 - 1 downto 0) := (others=>'0');
    signal Hsyn          : std_logic := '0';
    signal Vsyn          : std_logic := '0';
    signal Hsyn0         : std_logic := '0';
    signal Vsyn0         : std_logic := '0';
    signal Hcnt          : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal Hcnt_p1       : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal Vcnt          : std_logic_vector(12 - 1 downto 0) := (others=>'0');
    signal Data          : std_logic_vector(16 - 1 downto 0) := (others=>'0');
    signal Fcnt          : std_logic_vector(12 - 1 downto 0) := (others=>'0');

    signal cnt   : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal vtrig : std_logic := '0';

                        signal bx_cnt : std_logic_vector(8-1 downto 0) := (others=> '0');
                        signal by_cnt : std_logic_vector(8-1 downto 0) := (others=> '0');
                        signal bx_addr : std_logic_vector(8-1 downto 0) := (others=> '0');
                        signal by_addr : std_logic_vector(8-1 downto 0) := (others=> '0');
                        signal bxy_addr : std_logic_vector(8-1 downto 0) := (others=> '0');

--! begin

begin

    p_clk : process
    begin
        clk <= not clk;
        wait for clk_period;
    end process;

    process (clk)
    begin
        if clk'event and clk='1' then
            --
            --### !set
            reg_width     <= conv_std_logic_vector(100, 12);
            reg_height    <= conv_std_logic_vector(60, 12);
            reg_chgdet_en <= '1';
            reg_chgSense  <= "00";

            --### !cnt
            cnt <= cnt + '1';

            if cnt(14 downto 0) = 100 then
                vtrig <= '1';
            else
                vtrig <= '0';
            end if;

            --### !video cnt
            if vtrig = '1' then
                Hcnt <= (others=>'0');
                Vcnt <= (others=>'0');
                Fcnt <= Fcnt + '1';
            else
                if Hcnt < 128 and Vcnt < 64 then
                    Hcnt <= Hcnt + '1';
                else
                    Hcnt <= (others=>'0');
                    if Vcnt < 64 then
                        Vcnt <= Vcnt + '1';
                    end if;
                end if;
            end if;

            --### !syn
            if 0< Hcnt and Hcnt <= 100 then
                Hsyn <= '1';
            else
                Hsyn <= '0';
            end if;
            if 0< Vcnt and Vcnt <= 60 then
                Vsyn <= '1';
            else
                Vsyn <= '0';
            end if;
            Hcnt_p1 <= Hcnt;

Hsyn0 <= Hsyn;
Vsyn0 <= Vsyn;
            -- ### brick x address ###
            if Hsyn='1' and Vsyn='1' then
                if bx_cnt < reg_width(12-1 downto 4) - 1 then
                    bx_cnt <= bx_cnt + '1';
                else
                    bx_cnt  <= (others=> '0');
                    bx_addr <= bx_addr + '1';
                end if;
            else
                bx_cnt  <= (others=> '0');
                bx_addr <= (others=> '0');
            end if;

            -- ### y address ###
            if Vsyn='1' then
                if Hsyn0='1' and Hsyn='0' then --# fall edge
                    if by_cnt < reg_height(12-1 downto 4) - 1 then
                        by_cnt <= by_cnt + '1';
                    else
                        by_cnt  <= (others=> '0');
                        by_addr <= by_addr + '1';
                    end if;
                end if;
            else
                by_cnt  <= (others=> '0');
                by_addr <= (others=> '0');
            end if;

            --### data
            if Fcnt < 10 then
                --data <= x"0000" + hcnt_p1 + vcnt;
                Data <= bxy_addr & x"ff";
            elsif Fcnt < 20 then
                Data <= conv_std_logic_vector(1000, 16);
            elsif Fcnt < 30 then
                Data <= conv_std_logic_vector(4000, 16);
            else
                Data <= conv_std_logic_vector(8000, 16);
            end if;

            --
        end if;
    end process;

    bxy_addr <= by_addr(4-1 downto 0) & bx_addr(4-1 downto 0);

    i_reg_width     <= reg_width;
    i_reg_height    <= reg_height;
    i_reg_chgdet_en <= reg_chgdet_en;
    i_reg_chgdet_md <= reg_chgdet_md;
    i_reg_chgSense  <= reg_chgSense;
    i_Hsyn          <= Hsyn;
    i_Vsyn          <= Vsyn;
    i_Hcnt          <= Hcnt;
    i_Vcnt          <= Vcnt;
    i_Data          <= Data;

    u_ChgDet : change_detector
        port map (
            clk             => clk,
            i_reg_width     => i_reg_width,
            i_reg_height    => i_reg_height,
            i_reg_chgdet_en => i_reg_chgdet_en,
            i_reg_chgdet_md => i_reg_chgdet_md,
            i_reg_chgSense  => i_reg_chgSense,
            o_reg_chgdet    => o_reg_chgdet,
            i_Hsyn          => i_Hsyn,
            i_Vsyn          => i_Vsyn,
            i_Hcnt          => i_Hcnt,
            i_Vcnt          => i_Vcnt,
            i_Data          => i_Data,
            o_change        => o_change -- change detected
        );

end architecture behavioral;
