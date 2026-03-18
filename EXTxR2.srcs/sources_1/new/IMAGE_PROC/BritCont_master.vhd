----------------------------------------------------------------------------------
-- Company: DRT NA
-- Engineer: mbh
-- 
-- Create Date: 07/21/2023 03:40:55 PM
-- Design Name: 
-- Module Name: BritCont_master - Behavioral
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
    use WORK.TOP_HEADER.ALL;

entity BritCont_master is
    Port 
    ( 
        i_clk   : in  std_logic;
        i_hsync : in  std_logic;
        i_vsync : in  std_logic;
        i_hcnt  : in  std_logic_vector(12-1 downto 0);
        i_vcnt  : in  std_logic_vector(12-1 downto 0);
        i_data  : in  std_logic_vector(16-1 downto 0);
              
        i_reg_width    : in  std_logic_vector(12-1 downto 0);
        i_reg_height   : in  std_logic_vector(12-1 downto 0);
        i_reg_BNC_high : in std_logic_vector(16-1 downto 0);

        o_brit  : out std_logic_vector(17-1 downto 0);
        o_cont  : out std_logic_vector(16-1 downto 0)
    );
end BritCont_master;

architecture Behavioral of BritCont_master is

signal clk : std_logic;

--COMPONENT div_u10u10
--  PORT (
--    aclk : IN STD_LOGIC;
--    s_axis_divisor_tvalid : IN STD_LOGIC;
--    s_axis_divisor_tready : OUT STD_LOGIC;
--    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--    s_axis_dividend_tvalid : IN STD_LOGIC;
--    s_axis_dividend_tready : OUT STD_LOGIC;
--    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
--    m_axis_dout_tvalid : OUT STD_LOGIC;
--    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
--  );
--END COMPONENT;

COMPONENT div_u10u10
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_divisor_tvalid : IN STD_LOGIC;
    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_dividend_tvalid : IN STD_LOGIC;
    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

COMPONENT div_u16u16
  PORT (
    aclk : IN STD_LOGIC;
    s_axis_divisor_tvalid : IN STD_LOGIC;
    s_axis_divisor_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_dividend_tvalid : IN STD_LOGIC;
    s_axis_dividend_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

COMPONENT ila_temp_britcont
PORT (
	clk : IN STD_LOGIC;
	probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
	probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe2 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
	probe4 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe5 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe6 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
	probe7 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
	probe8 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
);
END COMPONENT  ;

 constant DIFFMIN:integer:=256;
-- This just makes it darker.
--constant DIFFMIN:integer:=512+256;

constant MAX16B :std_logic_vector(16-1 downto 0):=(others=>'1'); 

signal hsyn  : std_logic;                      
signal vsyn  : std_logic;                      
signal hcnt  : std_logic_vector(12-1 downto 0);
signal vcnt  : std_logic_vector(12-1 downto 0);
signal data  : std_logic_vector(16-1 downto 0);

signal hsyn0 : std_logic;                      
signal vsyn0 : std_logic;                      
signal hcnt0 : std_logic_vector(12-1 downto 0);
signal vcnt0 : std_logic_vector(12-1 downto 0);
signal data0 : std_logic_vector(16-1 downto 0);

signal max : std_logic_vector(16-1 downto 0);
signal min : std_logic_vector(16-1 downto 0);
signal max_keep  : std_logic_vector(16-1 downto 0);
signal min_keep  : std_logic_vector(16-1 downto 0);
signal min_minus : std_logic_vector(16-1 downto 0);
signal diff : std_logic_vector(16-1 downto 0);
signal diff_min : std_logic_vector(16-1 downto 0);
signal reg_bnc_high : std_logic_vector(16-1 downto 0);
signal div_data : STD_LOGIC_VECTOR(31 DOWNTO 0);

signal max_margin : std_logic_vector(16-1 downto 0);
signal min_margin : std_logic_vector(16-1 downto 0);
signal diff_margin : std_logic_vector(16-1 downto 0);

signal phase : std_logic;                      
signal phase0 : std_logic;                      
signal phase1 : std_logic;                      
signal phase2 : std_logic;                      
signal phase3 : std_logic;                      
signal phase4 : std_logic;                      
signal phase5 : std_logic;                      

signal brit : std_logic_vector(17-1 downto 0);
signal cont : std_logic_vector(16-1 downto 0);

signal reg_width    : std_logic_vector(12-1 downto 0);
signal reg_height   : std_logic_vector(12-1 downto 0);

--# quarter 25%
signal qtr_width  : std_logic_vector(12-1 downto 0);
signal qtr_height : std_logic_vector(12-1 downto 0);
signal str_width  : std_logic_vector(12-1 downto 0);
signal end_width  : std_logic_vector(12-1 downto 0);
signal str_height : std_logic_vector(12-1 downto 0);
signal end_height : std_logic_vector(12-1 downto 0);
signal active_en  : std_logic;                      


type t_10shift_12b is array(10-1 downto 0) of std_logic_vector(12-1 downto 0);
type t_10shift_16b is array(10-1 downto 0) of std_logic_vector(16-1 downto 0);


signal hsyn_array : std_logic_vector(10-1 downto 0);
signal vsyn_array : std_logic_vector(10-1 downto 0); 
signal hcnt_array : t_10shift_12b;
signal vcnt_array : t_10shift_12b; 
signal data_array : t_10shift_16b; 

signal data_sum : std_logic_vector(16+3-1 downto 0);
signal data_div : std_logic_vector(16-1 downto 0);
signal bit10_divisor  : std_logic_vector(16-1 downto 0);
signal bit10_dividend : std_logic_vector(16-1 downto 0);

signal bit16_divisor  : std_logic_vector(16-1 downto 0);
signal bit16_dividend : std_logic_vector(16-1 downto 0);
 
 
begin

clk <=  i_clk;


   process(clk)
   begin
       if clk'event and clk='1' then
       --
           hsyn_array <= hsyn_array(10-2 downto 0) & i_hsync;
           vsyn_array <= vsyn_array(10-2 downto 0) & i_vsync;
           hcnt_array <= hcnt_array(10-2 downto 0) & i_hcnt ;
           vcnt_array <= vcnt_array(10-2 downto 0) & i_vcnt ;
           data_array <= data_array(10-2 downto 0) & i_data ;
   
           -- phase 4
           data_sum <= "000" & data_array(7) +
                               data_array(6) +
                               data_array(5) +
                               data_array(4) +
                               data_array(3) +
                               data_array(2) +
                               data_array(1) +
                               data_array(0) ;
   
           -- phase 5
           data_div <= data_sum(16+3-1 downto 3);
   
           -- phase 6
           hsyn <= hsyn_array(6-1);
           vsyn <= vsyn_array(6-1);
           hcnt <= hcnt_array(6-1);
           vcnt <= vcnt_array(6-1);
           data <= data_div;
       --
       end if;
   end process;


process(clk)
begin
    if clk'event and clk='1' then
    --
        hsyn0 <= hsyn; -- hsyn <= i_hsync;
        vsyn0 <= vsyn; -- vsyn <= i_vsync;
        hcnt0 <= hcnt; -- hcnt <= i_hcnt ;
        vcnt0 <= vcnt; -- vcnt <= i_vcnt ;
        data0 <= data; -- data <= i_data ;

        -- catch active 75%
        reg_width  <= i_reg_width ;
        reg_height <= i_reg_height;
        --qtr_width  <= "000"&reg_width(12-1 downto 3);
        --qtr_height <= "000"&reg_height(12-1 downto 3);
        str_width  <= x"000" + reg_width(12-1 downto 3); --12.5 %
        end_width  <= x"000" + reg_width(12-1 downto 1) + reg_width(12-1 downto 2) + reg_width(12-1 downto 3); --87.5 %
        str_height <= x"000" + reg_height(12-1 downto 3); --12.5 %
        end_height <= x"000" + reg_height(12-1 downto 1) + reg_height(12-1 downto 2) + reg_height(12-1 downto 3); --87.5 %

        if  str_width  < hcnt0 and hcnt0 < end_width  and
            str_height < vcnt0 and vcnt0 < end_height then
            active_en <= '1';
        else
            active_en <= '0';
        end if;

        --# maximum
        if vsyn0='1' and vsyn='0' then --# v fall
            max_keep <= max;
            max      <= (others=>'0');
        elsif hsyn='1' and vsyn='1' and active_en='1' then
            if max < data then
                max <= data;
            end if;
        end if;

        --# minimum
        if vsyn0='1' and vsyn='0' then --# v fall
            min_keep <= min;
            min      <= (others=>'1');
        elsif hsyn='1' and vsyn='1' and active_en='1' then
            if min > data then
                min <= data;
            end if;
        end if;

        if vsyn0='1' and vsyn='0' then
            phase    <= '1';
        else
            phase    <= '0';
        end if;

        --# minus min
        phase0 <= phase;
        min_minus <= (not min_keep) + '1';

        phase1 <= phase0;
        if min_keep < max_keep then
--          diff   <= max_keep + min_minus;
            diff   <= max_keep - min_keep;
        else
            diff   <= (others=> '0');
        end if;

        phase2 <= phase1; --# 12.5% margin
        if '0'&max_keep + diff(diff'left downto 3) <= MAX16B then
            max_margin <= max_keep + diff(diff'left downto 3);
        else
            max_margin <= (others=>'1');
        end if;
        if diff(diff'left downto 3) < min_keep then
         -- min_margin <= min_keep + ((not diff(diff'left-3))+'1'); --min-diff12%
--          min_margin <= min_keep + (not ("000"&diff(diff'left downto 3))); --min-diff12%
            min_margin <= min_keep - diff(diff'left downto 3);
        else
            min_margin <= (others=>'0');
        end if;

        phase3 <= phase2;
        if min_margin < max_margin then
            diff_margin <= max_margin - min_margin;
        else
            diff_margin <= (others=> '0');
        end if;

        phase4 <= phase3;
        if diff_margin < DIFFMIN then
            diff_min <= conv_std_logic_vector(DIFFMIN,16);
        else
            diff_min <= diff_margin;
        end if;
        reg_bnc_high <= i_reg_BNC_high;
    --
    end if;
end process;

--  bit10_divisor  <= b"00_0000"&diff_min(16-1 downto 6);
--  bit10_dividend <= b"00_0000"&reg_bnc_high(16-1 downto 6);
--  u_div_u10u10 : div_u10u10
--    PORT MAP (
--      aclk => clk,
--      s_axis_divisor_tvalid  => phase4,
--      s_axis_divisor_tdata   => bit10_divisor,
--      s_axis_dividend_tvalid => phase4,
--      s_axis_dividend_tdata  => bit10_dividend,
--      m_axis_dout_tvalid     => phase5,
--      m_axis_dout_tdata      => div_data
--    );

bit16_divisor  <= diff_min;
bit16_dividend <= reg_bnc_high;
    u_div_u16u16 : div_u16u16
      PORT MAP (
        aclk => clk,
        s_axis_divisor_tvalid  => phase4,           
        s_axis_divisor_tdata   => bit16_divisor,    
        s_axis_dividend_tvalid => phase4,           
        s_axis_dividend_tdata  => bit16_dividend,   
        m_axis_dout_tvalid     => phase5,           
        m_axis_dout_tdata      => div_data          
      );
process(clk)
begin
if clk'event and clk='1' then
--
    if phase5 = '1' then 
        brit <= '1' & min_margin;
        if div_data(31 downto 16+8)=0 then
            cont <= div_data(16+8-1 downto 8);
        else
            cont <= (others=>'1'); 
        end if;
    end if;
--
end if;
end process;
o_brit <= brit;
o_cont <= cont;

--u_ila_temp_britcont : ila_temp_britcont
--PORT MAP (
--  clk      => clk        ,
--  probe0(0)=> phase5     , -- 1
--  probe1   => min_keep   , -- 16
--  probe2   => max_keep   , -- 16
--  probe3   => div_data   , -- 32
--  probe4   => cont       , -- 16
--  probe5   => brit(16-1 downto 0), -- 16
--  probe6   => min_margin , -- 16
--  probe7   => max_margin , -- 16
--  probe8   => diff_margin  -- 16
--);
         

end Behavioral;
