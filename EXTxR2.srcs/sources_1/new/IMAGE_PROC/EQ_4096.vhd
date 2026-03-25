----------------------------------------------------------------------------------
-- Company: DRT
-- Engineer: mbh
--
-- Create Date: 07/28/2023 03:34:41 PM
-- Design Name:
-- Module Name: EQ - Behavioral
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

entity EQ_4096 is
    Port (
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
        i_hcnt : in  std_logic_vector(12-1 downto 0);
        i_vcnt : in  std_logic_vector(12-1 downto 0);
        i_data : in  std_logic_vector(16-1 downto 0);

        o_hsyn : out std_logic;
        o_vsyn : out std_logic;
        o_hcnt : out std_logic_vector(12-1 downto 0);
        o_vcnt : out std_logic_vector(12-1 downto 0);
        o_data : out std_logic_vector(16-1 downto 0)
    );
end EQ_4096;

architecture Behavioral of EQ_4096 is

COMPONENT mem_histo_4096x32b
    PORT (
        clka  : IN STD_LOGIC;
        wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        dina  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        clkb  : IN STD_LOGIC;
        web   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        dinb  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END COMPONENT;

COMPONENT u48_div_u24
    PORT (
        aclk                   : IN STD_LOGIC;
        s_axis_divisor_tvalid  : IN STD_LOGIC;
        s_axis_divisor_tdata   : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
        s_axis_dividend_tvalid : IN STD_LOGIC;
        s_axis_dividend_tdata  : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
        m_axis_dout_tvalid     : OUT STD_LOGIC;
        m_axis_dout_tdata      : OUT STD_LOGIC_VECTOR(71 DOWNTO 0)
    );
END COMPONENT;

COMPONENT mem_histo_4096x16b
    PORT (
        clka  : IN STD_LOGIC;
        wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        dina  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        clkb  : IN STD_LOGIC;
        web   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        dinb  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
END COMPONENT;

    constant shft : integer := 10;
    type t_shift_12b is array(shft-1 downto 0) of std_logic_vector(12-1 downto 0);
    type t_shift_16b is array(shft-1 downto 0) of std_logic_vector(16-1 downto 0);

    --# array
    signal hsbp_ar        : std_logic_vector(shft-1 downto 0);
    signal vsbp_ar        : std_logic_vector(shft-1 downto 0);
    signal hsyn_ar        : std_logic_vector(shft-1 downto 0);
    signal vsyn_ar        : std_logic_vector(shft-1 downto 0);
    signal hcnt_ar        : t_shift_12b;
    signal vcnt_ar        : t_shift_12b;
    signal data_ar        : t_shift_16b;
    signal regHActive_ar  : t_shift_12b;
    signal regVActive_ar  : t_shift_12b;
    signal regEqCtrl_ar   : t_shift_16b;
    signal regEqTopval_ar : t_shift_16b;

    --# latch
    signal hsyn  : std_logic;
    signal vsyn  : std_logic;
    signal hcnt  : std_logic_vector(12-1 downto 0);
    signal vcnt  : std_logic_vector(12-1 downto 0);
    signal data  : std_logic_vector(16-1 downto 0);

    signal regHActive  : std_logic_vector(12-1 downto 0);
    signal regVActive  : std_logic_vector(12-1 downto 0);
    signal regEqCtrl   : std_logic_vector(16-1 downto 0);
    signal regEqTopVal : std_logic_vector(16-1 downto 0);
    signal regEqEn     : std_logic;

    signal target    : std_logic_vector(16-1 downto 0) := conv_std_logic_vector(55000, 16);
    signal selTarget : std_logic_vector(16-1 downto 0);
    signal total     : std_logic_vector(24-1 downto 0) := conv_std_logic_vector(2304 * 2048, 24); --# 2832
    signal totalAdd  : std_logic_vector(36-1 downto 0);
    signal totalCut  : std_logic_vector(24-1 downto 0);

    signal histo_wea    : STD_LOGIC_VECTOR( 0 DOWNTO 0) := (others => '0');
    signal histo_addra  : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
    signal histo_dina   : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    signal histo_douta  : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    signal histo_web    : STD_LOGIC_VECTOR( 0 DOWNTO 0) := (others => '0');
    signal histo_addrb  : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
    signal histo_dinb   : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    signal histo_doutb  : STD_LOGIC_VECTOR(31 DOWNTO 0) := (others => '0');
    signal histo_addrb0 : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');

    signal cp_en       : std_logic;
    signal cp_en0      : std_logic;
    signal hisAcc_trig : std_logic;
    signal sm_hisCp    : STD_LOGIC_VECTOR(4-1 DOWNTO 0)  := (others => '0');
    signal regEqOfs    : STD_LOGIC_VECTOR(8-1 DOWNTO 0)  := (others => '0');
    signal EqOfs       : STD_LOGIC_VECTOR(24-1 DOWNTO 0) := (others => '0');

    signal Acc_wea   : std_logic;
    signal Acc_addra : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal Acc_dina  : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (others => '0');

    signal mul_wea   : std_logic;
    signal mul_addra : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal mul_dina  : STD_LOGIC_VECTOR(48-1 DOWNTO 0) := (others => '0');

    signal cut_wea   : std_logic;
    signal cut_addra : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal cut_dina  : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (others => '0');

    signal div_wea  : std_logic;
    signal div_data : STD_LOGIC_VECTOR(72-1 DOWNTO 0) := (others => '0');

    signal hisAccCnt  : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal hisAccCnt0 : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');

    signal hisAcc_wea   : STD_LOGIC_VECTOR( 0 DOWNTO 0) := (others => '0');
    signal hisAcc_addra : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
    signal hisAcc_dina  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
    signal hisAcc_douta : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
    signal hisAcc_web   : STD_LOGIC_VECTOR( 0 DOWNTO 0) := (others => '0');
    signal hisAcc_addrb : STD_LOGIC_VECTOR(11 DOWNTO 0) := (others => '0');
    signal hisAcc_dinb  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
    signal hisAcc_doutb : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');

    signal hisAcc_doutb_upper  : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal hisAcc_douta_lower  : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal hisAcc_douta_lower1 : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal hisAcc_douta_lower2 : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');

    signal w_hisAcc_wea   : std_logic;
    signal w_hisAcc_addra : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal w_hisAcc_dina  : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');

    signal w_sel_wea   : std_logic;
    signal w_sel_addra : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal w_sel_dina  : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');

    signal mul_p0    : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (others => '0');
    signal mul_p1    : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (others => '0');
    signal mul_p2    : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (others => '0');
    signal sum_p4    : STD_LOGIC_VECTOR(33-1 DOWNTO 0) := (others => '0');
    signal sum_p5    : STD_LOGIC_VECTOR(34-1 DOWNTO 0) := (others => '0');
    signal cut_p6    : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal mul_p2_p0 : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (others => '0');

    signal reg_eq_sel     : std_logic;
    signal reg_plus_coeff : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal reg_minuscoeff : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');

    signal lut_data_msb  : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal lut_data_lsb  : STD_LOGIC_VECTOR( 4-1 DOWNTO 0) := (others => '0');
    signal lut_data_lsb0 : STD_LOGIC_VECTOR( 4-1 DOWNTO 0) := (others => '0');
    signal lut_data_lsb1 : STD_LOGIC_VECTOR( 4-1 DOWNTO 0) := (others => '0');
    signal lut_data_lsb2 : STD_LOGIC_VECTOR( 4-1 DOWNTO 0) := (others => '0');

    signal diff      : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal diffDiv16 : STD_LOGIC_VECTOR(12-1 DOWNTO 0) := (others => '0');
    signal mult      : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');
    signal sum       : STD_LOGIC_VECTOR(16-1 DOWNTO 0) := (others => '0');

    signal ohs : std_logic;
    signal ovs : std_logic;
    signal ohc : std_logic_vector(12-1 downto 0);
    signal ovc : std_logic_vector(12-1 downto 0);
    signal oda : std_logic_vector(16-1 downto 0);

--# %begin
COMPONENT ila_eq
PORT (
    clk     : IN STD_LOGIC;
    probe0  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe1  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe2  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe3  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe4  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe5  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe6  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe7  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe8  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    probe9  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe10 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe11 : IN STD_LOGIC_VECTOR(47 DOWNTO 0);
    probe12 : IN STD_LOGIC_VECTOR(23 DOWNTO 0);
    probe13 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe14 : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
    probe15 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe16 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe17 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe18 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe19 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe20 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe21 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe22 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe23 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe24 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe25 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe26 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    probe27 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe28 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    probe29 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe30 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe31 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe32 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    probe33 : IN STD_LOGIC_VECTOR(32 DOWNTO 0);
    probe34 : IN STD_LOGIC_VECTOR(33 DOWNTO 0);
    probe35 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    probe36 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
);
END COMPONENT;

begin
--u_ila_eq : ila_eq
--PORT MAP (
--    clk        => clk            ,
--    probe0     => histo_addra    , -- 12
--    probe1     => histo_dina     , -- 32
--    probe2     => histo_douta    , -- 32
--    probe3     => histo_web      , --  1
--    probe4     => histo_addrb    , -- 12
--    probe5     => histo_dinb     , -- 32
--    probe6     => histo_doutb    , -- 32
--    probe7 (0) => hisAcc_trig    , --  1
--    probe8     => sm_hisCp       , --  4
--    probe9 (0) => cp_en          , --  1
--    probe10(0) => mul_wea        , --  1
--    probe11    => mul_dina       , -- 48
--    probe12    => total          , -- 24
--    probe13(0) => div_wea        , --  1
--    probe14    => div_data       , -- 72
--    probe15(0) => w_hisAcc_wea   , --  1
--    probe16    => w_hisAcc_dina  , -- 16
--    probe17    => w_hisAcc_addra , -- 12
--    probe18    => hisAcc_wea     , --  1
--    probe19    => hisAcc_addra   , -- 12
--    probe20    => hisAcc_dina    , -- 16
--    probe21    => hisAcc_douta   , -- 16
--    probe22    => hisAcc_addrb   , -- 12
--    probe23    => hisAcc_dinb    , -- 16
--    probe24    => hisAcc_doutb   , -- 16
--    probe25(0) => ohs            , --  1
--    probe26(0) => ovs            , --  1
--    probe27    => ohc            , -- 12
--    probe28    => ovc            , -- 12
--    probe29    => oda            , -- 16
--    probe30    => mul_p0         , -- 24
--    probe31    => mul_p1         , -- 24
--    probe32    => mul_p2         , -- 24
--    probe33    => sum_p4         , -- 25
--    probe34    => sum_p5         , -- 26
--    probe35    => cut_p6         , -- 16
--    probe36(0) => w_hisAcc_wea_p6  -- 1
--);

--# shift register array and latch
process(clk)
begin
    if clk'event and clk = '1' then
    --
        --# array
               hsbp_ar <=        hsbp_ar(       hsbp_ar'left-1 downto 0) & i_hsbp;
               vsbp_ar <=        vsbp_ar(       vsbp_ar'left-1 downto 0) & i_vsbp;
               hsyn_ar <=        hsyn_ar(       hsyn_ar'left-1 downto 0) & i_hsyn;
               vsyn_ar <=        vsyn_ar(       vsyn_ar'left-1 downto 0) & i_vsyn;
               hcnt_ar <=        hcnt_ar(       hcnt_ar'left-1 downto 0) & i_hcnt;
               vcnt_ar <=        vcnt_ar(       vcnt_ar'left-1 downto 0) & i_vcnt;
               data_ar <=        data_ar(       data_ar'left-1 downto 0) & i_data;
         regHActive_ar <=  regHActive_ar( regHActive_ar'left-1 downto 0) & i_regHActive;
         regVActive_ar <=  regVActive_ar( regVActive_ar'left-1 downto 0) & i_regVActive;
          regEqCtrl_ar <=   regEqCtrl_ar(  regEqCtrl_ar'left-1 downto 0) & i_regEqCtrl;
        regEqTopVal_ar <= regEqTopVal_ar(regEqTopVal_ar'left-1 downto 0) & i_regEqTopVal;
        --# latch
               hsyn <=        hsyn_ar(3);
               vsyn <=        vsyn_ar(3);
               hcnt <=        hcnt_ar(3);
               vcnt <=        vcnt_ar(3);
               data <=        data_ar(3);
         regHActive <=  regHActive_ar(3);
         regVActive <=  regVActive_ar(3);
            regEqEn <=   regEqCtrl_ar(3)(0);
           regEqOfs <=   regEqCtrl_ar(3)(16-1 downto 8);
        regEqTopVal <= regEqTopVal_ar(3);

        if regEqTopVal = 0 then
            selTarget <= target;
        else
            selTarget <= regEqTopVal;
        end if;
    --
    end if;
end process;

-- █░█ █ █▀ ▀█▀ █▀█ █▀▀ █▀█ ▄▀█ █▀▄▀█
-- █▀█ █ ▄█ ░█░ █▄█ █▄█ █▀▄ █▀█ █░▀░█
histo_wea(0) <= '0';
histo_addra  <= hisAccCnt when cp_en = '1' else data_ar(0)(16-1 downto 4);
histo_dina   <= (others => '0');

u_mem_histo_4096x32b : mem_histo_4096x32b
    PORT MAP (
        clka  => clk,
        wea   => histo_wea,   --# read
        addra => histo_addra,  --# read
        dina  => histo_dina,   --# read
        douta => histo_douta,  --# read -> used for increment and ACCumulation source
        clkb  => clk,
        web   => histo_web,    --# write
        addrb => histo_addrb,  --# write
        dinb  => histo_dinb,   --# write
        doutb => histo_doutb   --# write
    );

              --# clear                                  --# write
histo_web(0) <= '1'               when Acc_wea = '1' else hsyn_ar(1) and vsyn_ar(1);
histo_addrb  <= Acc_addra         when Acc_wea = '1' else data_ar(1)(16-1 downto 4);
histo_dinb   <= (others => '0')   when Acc_wea = '1' else
               --# avoiding same addres accessing
                histo_doutb + '1' when histo_addrb = histo_addrb0 else
                histo_douta + '1';

--# histogram accumulation trigger and state machine
process(clk)
begin
    if clk'event and clk = '1' then
        --
        histo_addrb0 <= histo_addrb;
        if vsyn_ar(1) = '1' and vsyn_ar(0) = '0' then --# V falling
            hisAcc_trig <= '1';
        else
            hisAcc_trig <= '0';
        end if;

        case sm_hisCp is
            when x"0" =>
                if hisAcc_trig = '1' then
                    sm_hisCp <= x"1";
                  --cp_en <= '1';
                end if;
            when x"1" =>
                if hisAccCnt < 2**12-1 then --# 4096 cnt
                    hisAccCnt <= hisAccCnt + '1';
                else
                    hisAccCnt <= (others => '0');
                    sm_hisCp  <= x"2";
                  --cp_en <= '0';
                end if;
            when x"2" =>
                sm_hisCp <= x"0";
            when others => NULL;
        end case;

        --
    end if;
end process;

cp_en <= '1' when sm_hisCp = x"1" else
         '0';

-- █▀▀ ▄▀█ █░░ █▀▀
-- █▄▄ █▀█ █▄▄ █▄▄
--# histogram calculation: accumulate, multiply, cut, divide
process(clk)
begin
    if clk'event and clk = '1' then
        --
        if hisAcc_trig = '1' then --# it's just for latch
            total <= (RegHActive * RegVActive); --# ofs *16*4096
        end if;

        case (regEqOfs) is
            when x"08"  => EqOfs <= (others => '0');
            when x"07"  => EqOfs <= x"0000" &         total(total'left downto 16);
            when x"06"  => EqOfs <= x"000"  & "000" & total(total'left downto 15);
            when x"05"  => EqOfs <= x"000"  & "00"  & total(total'left downto 14);
            when x"04"  => EqOfs <= x"000"  & "0"   & total(total'left downto 13);
            when x"03"  => EqOfs <= x"000"  &          total(total'left downto 12);
            when x"02"  => EqOfs <= x"00"   & "000" & total(total'left downto 11);
            when x"01"  => EqOfs <= x"00"   & "00"  & total(total'left downto 10);
            when x"00"  => EqOfs <= x"00"   & "0"   & total(total'left downto 9);
            when others => EqOfs <= (others => '0');
        end case;

        totalAdd <= total + (EqOfs & x"000"); --# ofs*4096
        if totalAdd(totalAdd'left downto 24) > 0 then
            totalCut <= (others => '1');
        else
            totalCut <= totalAdd(24-1 downto 0);
        end if;

        --phase0
        cp_en0     <= cp_en;
        hisAccCnt0 <= hisAccCnt;

        Acc_wea   <= cp_en0;
        Acc_addra <= hisAccCnt0;
        if cp_en0 = '1' then
            Acc_dina <= Acc_dina + histo_douta + EqOfs;
        else
            Acc_dina <= (others => '0');
        end if;
        --# data * target_val
        mul_wea   <= Acc_wea;
        mul_addra <= Acc_addra;
        mul_dina  <= Acc_dina * selTarget; -- 32b * 16
        --# cut
        cut_wea   <= mul_wea;
        cut_addra <= mul_addra;
        cut_dina  <= mul_dina(48-1 downto 0+16);

        --
    end if;
end process;

--# (vid_data * target_val(55000)) / pix_total
u_u48_div_u24 : u48_div_u24
    PORT MAP (
        aclk                   => clk,
        s_axis_dividend_tvalid => mul_wea,
        s_axis_dividend_tdata  => mul_dina,
        s_axis_divisor_tvalid  => mul_wea,
        s_axis_divisor_tdata   => totalCut,
        m_axis_dout_tvalid     => div_wea,
        m_axis_dout_tdata      => div_data
    );

--# divider output latch and address counter
process(clk)
begin
    if clk'event and clk = '1' then
        --
        w_hisAcc_wea <= div_wea;
        --# keep the value even not enable for last data
        if div_wea = '1' then
            w_hisAcc_dina <= div_data(24+16-1 downto 24);
        end if;

        if w_hisAcc_wea = '1' then
            w_hisAcc_addra <= w_hisAcc_addra + '1';
        else
            w_hisAcc_addra <= (others => '0');
        end if;
        --
    end if;
end process;

w_sel_wea   <= w_hisAcc_wea;
w_sel_addra <= w_hisAcc_addra;
w_sel_dina  <= W_hisAcc_dina;

-- █░░ █░█ ▀█▀ █░█ █▀█ █▀█ █▄▄
-- █▄▄ █▄█ ░█░ ▀▀█ █▄█ ▀▀█ █▄█
lut_data_msb <= data(16-1 downto 4);
lut_data_lsb <= data(4-1 downto 0);

hisAcc_wea(0) <= w_sel_wea;
hisAcc_addra  <= w_sel_addra when hisAcc_wea(0) = '1' else lut_data_msb;
hisAcc_dina   <= w_sel_dina;

u_mem_hisAcc_4096x16b : mem_histo_4096x16b
    PORT MAP (
        clka  => clk,
        wea   => hisAcc_wea,
        addra => hisAcc_addra,
        dina  => hisAcc_dina,
        douta => hisAcc_douta,
        clkb  => clk,
        web   => hisAcc_web,
        addrb => hisAcc_addrb,
        dinb  => hisAcc_dinb,
        doutb => hisAcc_doutb
    );

hisAcc_web(0)       <= '0';
hisAcc_addrb        <= lut_data_msb + '1';
hisAcc_dinb         <= (others => '0');
hisAcc_douta_lower  <= hisAcc_douta;
hisAcc_doutb_upper  <= hisAcc_doutb;

--# LUT interpolation and output mux
process(clk)
begin
    if clk'event and clk = '1' then
        --
        --# phase4
        lut_data_lsb0 <= lut_data_lsb;

        --# phase5
        lut_data_lsb1       <= lut_data_lsb0;
        diff                <= hisAcc_doutb_upper - hisAcc_douta_lower;
        hisAcc_douta_lower1 <= hisAcc_douta_lower;

        --# phase6
        lut_data_lsb2       <= lut_data_lsb1;
        diffDiv16           <= diff(diff'left downto 4); --# /16
        hisAcc_douta_lower2 <= hisAcc_douta_lower1;

        --# phase7
        mult <= diffDiv16 * lut_data_lsb2;

        --# phase8
        --# cut overflow 230808
        if ('0' & mult) + hisAcc_douta_lower2 < 2**16 then
            sum <= mult + hisAcc_douta_lower2;
        else
            sum <= (others => '1');
        end if;

        sum <= hisAcc_douta_lower2;

        --# phase9
        ovs <= vsbp_ar(9); --# bypass sync
        ohs <= hsbp_ar(9); --# bypass sync
        ovc <= vcnt_ar(9);
        ohc <= hcnt_ar(9);
        if regEqEn = '1' then
            oda <= sum;
        else
            oda <= data_ar(9);
        end if;
        --
    end if;
end process;

o_vsyn <= ovs;
o_hsyn <= ohs;
o_vcnt <= ovc;
o_hcnt <= ohc;
o_data <= oda;

end Behavioral;

--# unused signals (moved from architecture declaration)
--# signal regEqCtrl   : std_logic_vector(16-1 downto 0);
--# signal mul_p0      : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
--# signal mul_p1      : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
--# signal mul_p2      : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
--# signal sum_p4      : STD_LOGIC_VECTOR(33-1 DOWNTO 0);
--# signal sum_p5      : STD_LOGIC_VECTOR(34-1 DOWNTO 0);
--# signal cut_p6      : STD_LOGIC_VECTOR(16-1 DOWNTO 0);
--# signal mul_p2_p0   : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
--# signal reg_eq_sel  : std_logic;
--# signal reg_plus_coeff : STD_LOGIC_VECTOR(16-1 DOWNTO 0);
--# signal reg_minuscoeff : STD_LOGIC_VECTOR(16-1 DOWNTO 0);
--# signal cut_wea     : std_logic;
--# signal cut_addra   : STD_LOGIC_VECTOR(12-1 DOWNTO 0);
--# signal cut_dina    : STD_LOGIC_VECTOR(32-1 DOWNTO 0);
