----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date: 2021/09/28 11:49:02
-- Design Name:
-- Module Name: tb_ACC_PROC - Behavioral
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
    -- use WORK.TOP_HEADER.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity tb_ACC_PROC is
--  Port ( );
end entity tb_acc_proc;

architecture behavioral of tb_acc_proc is

    component ACC_PROC is
        port (
            i_clk : in    std_logic;

            i_regAccCtrl : in    std_logic_vector(16 - 1 downto 0);

            i_MmrHsyn : in    std_logic;
            i_MmrVsyn : in    std_logic;
            i_MmrVcnt : in    std_logic_vector(12 - 1 downto 0);
            i_MmrHcnt : in    std_logic_vector(12 - 1 downto 0);
            i_MmrData : in    std_logic_vector(16 - 1 downto 0);

            i_LivHsyn : in    std_logic;
            i_LivVsyn : in    std_logic;
            i_LivVcnt : in    std_logic_vector(12 - 1 downto 0);
            i_LivHcnt : in    std_logic_vector(12 - 1 downto 0);
            i_LivData : in    std_logic_vector(16 - 1 downto 0);

            o_hsyn : out   std_logic;
            o_vsyn : out   std_logic;
            o_vcnt : out   std_logic_vector(12 - 1 downto 0);
            o_hcnt : out   std_logic_vector(12 - 1 downto 0);
            o_data : out   std_logic_vector(16 - 1 downto 0)
        );
    end component acc_proc;

    constant period_clk : time := 10 ns;
    signal   clk        : std_logic;

    signal i_clk : std_logic;

    signal i_regAccCtrl : std_logic_vector(16 - 1 downto 0) := x"0000";

    signal i_MmrHsyn : std_logic;
    signal i_MmrVsyn : std_logic;
    signal i_MmrVcnt : std_logic_vector(12 - 1 downto 0);
    signal i_MmrHcnt : std_logic_vector(12 - 1 downto 0);
    signal i_MmrData : std_logic_vector(16 - 1 downto 0);

    signal i_LivHsyn : std_logic;
    signal i_LivVsyn : std_logic;
    signal i_LivVcnt : std_logic_vector(12 - 1 downto 0);
    signal i_LivHcnt : std_logic_vector(12 - 1 downto 0);
    signal i_LivData : std_logic_vector(16 - 1 downto 0);

    signal o_hsyn : std_logic;
    signal o_vsyn : std_logic;
    signal o_vcnt : std_logic_vector(12 - 1 downto 0);
    signal o_hcnt : std_logic_vector(12 - 1 downto 0);
    signal o_data : std_logic_vector(16 - 1 downto 0);

    signal StartCnt : std_logic_vector(16 - 1 downto 0):=(others=>'0');

    -- signal hsyn  : std_logic;
    -- signal vsyn  : std_logic;
    signal htcnt : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal vtcnt : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal pagecnt : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal data  : std_logic_vector(16 - 1 downto 0);

    signal hsyn0  : std_logic;
    signal vsyn0  : std_logic;
    signal htcnt0 : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal vtcnt0 : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal data0  : std_logic_vector(16 - 1 downto 0);

    signal hsyn1  : std_logic;
    signal vsyn1  : std_logic;
    signal htcnt1 : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal vtcnt1 : std_logic_vector(12 - 1 downto 0):=(others=>'0');
    signal data1  : std_logic_vector(16 - 1 downto 0);

    signal start : std_logic;

    type type_32d16b is array (32 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);

    type type_32d12b is array (32 - 1 downto 0) of std_logic_vector(12 - 1 downto 0);

    signal htcnt_shft : type_32d12b;
    signal vtcnt_shft : type_32d12b;
    signal hsyn_shft  : std_logic_vector(32 - 1 downto 0);
    signal vsyn_shft  : std_logic_vector(32 - 1 downto 0);
    signal data_shft  : type_32d16b;
-- !begin

begin

    CLK_GEN : process
    begin
        clk <= '0';    wait for period_clk / 2;
        clk <= '1';    wait for period_clk / 2;
    end process;

    i_clk <= clk;
    u_ACC_PROC : ACC_PROC
        port map (
            i_clk        => i_clk,
            i_regAccCtrl => i_regAccCtrl,
            i_MmrHsyn    => i_MmrHsyn,
            i_MmrVsyn    => i_MmrVsyn,
            i_MmrVcnt    => i_MmrVcnt,
            i_MmrHcnt    => i_MmrHcnt,
            i_MmrData    => i_MmrData,
            i_LivHsyn    => i_LivHsyn,
            i_LivVsyn    => i_LivVsyn,
            i_LivVcnt    => i_LivVcnt,
            i_LivHcnt    => i_LivHcnt,
            i_LivData    => i_LivData,
            o_hsyn       => o_hsyn,
            o_vsyn       => o_vsyn,
            o_vcnt       => o_vcnt,
            o_hcnt       => o_hcnt,
            o_data       => o_data
        );

    process (clk)
    begin
        if clk'event and clk='1' then
      --

            if StartCnt < x"ffff" then
                StartCnt <= StartCnt + '1';
            end if;

            if 1000 < StartCnt  then
				 i_regAccCtrl <= x"0001";
            end if;

            if 100 < StartCnt then
                start <= '1';
            else
                start <= '0';
            end if;

            if start = '0' then
                htcnt <= (others=> '1');
                vtcnt <= (others=> '1');
            elsif htcnt < 200 then
                htcnt <= htcnt + '1';
            else
                htcnt <= (others=> '0');
                if vtcnt < 100 then
                    vtcnt <= vtcnt + '1';
                else
                    vtcnt <= (others=> '0');
                    pagecnt <= pagecnt + '1';
                end if;
            end if;

            htcnt0 <= htcnt;
            vtcnt0 <= vtcnt;
            if htcnt < 128 then
                hsyn0 <= '1';
            else
                hsyn0 <= '0';
            end if;

            if vtcnt < 64 then
                vsyn0 <= '1';
            else
                vsyn0 <= '0';
            end if;

            htcnt1 <= htcnt0;
            vtcnt1 <= vtcnt0;
			hsyn1 <= hsyn0;
			vsyn1 <= vsyn0;
            if (hsyn0 = '1' and vsyn0 = '1') then
                data1 <= vtcnt0(8 - 1 downto 0) & htcnt0(8 - 1 downto 0);
            else
                data1 <= (others=>'1');
            end if;

            hsyn_shft  <= hsyn_shft(hsyn_shft'high - 1 downto 0) & hsyn1;
            vsyn_shft  <= vsyn_shft(vsyn_shft'high - 1 downto 0) & vsyn1;
            htcnt_shft <= htcnt_shft(htcnt_shft'high - 1 downto 0) & htcnt1;
            vtcnt_shft <= vtcnt_shft(vtcnt_shft'high - 1 downto 0) & vtcnt1;
            data_shft  <= data_shft(data_shft'high - 1 downto 0) & (data1+pagecnt);
      --
        end if;
    end process;

    i_MmrHsyn <= hsyn1;
    i_MmrVsyn <= vsyn1;
    i_MmrHcnt <= htcnt1;
    i_MmrVcnt <= vtcnt1;
    i_MmrData <= data1;

    i_LivHsyn <= hsyn_shft (18);
    i_LivVsyn <= vsyn_shft (18);
    i_LivHcnt <= htcnt_shft(18);
    i_LivVcnt <= vtcnt_shft(18);
    i_LivData <= data_shft (18);

end architecture behavioral;
