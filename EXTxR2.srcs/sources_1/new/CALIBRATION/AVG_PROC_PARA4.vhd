library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

use WORK.TOP_HEADER.ALL;

entity AVG_PROC_PARA4 is
port (
    clk  : in  std_logic;
    rstn : in  std_logic;

    i_reg_avg_en  : in  std_logic;
    i_reg_avg_lv  : in  std_logic_vector( 4-1 downto 0);
    o_reg_avg_end : out std_logic_vector(16-1 downto 0);

    i_hsyn        : in  std_logic;
    i_vsyn        : in  std_logic;
    i_hcnt        : in  std_logic_vector(12-1 downto 0);
    i_vcnt        : in  std_logic_vector(12-1 downto 0);
    i_data        : in  std_logic_vector(64-1 downto 0);
    i_mdata       : in  std_logic_vector(64-1 downto 0);

    o_avg_wen     : out std_logic;
    o_avg_waddr   : out std_logic_vector(12-1 downto 0); --# hcnt
    o_avg_wvcnt   : out std_logic_vector(12-1 downto 0); --# vcnt
    o_avg_winfo   : out std_logic_vector(64-1 downto 0)
);
end AVG_PROC_PARA4;

architecture Behavioral_AVG_PROC_PARA4 of AVG_PROC_PARA4 is

    constant SHF_REG_NUM : integer := 3;
    constant SHF_VID_NUM : integer := 40;

    component AVG_CALC_PARA4 is
        port (
            clk      : in  std_logic;

            i_en     : in  std_logic;
            i_cdata  : in  std_logic_vector(16-1 downto 0);
            i_mdata  : in  std_logic_vector(16-1 downto 0);
            i_frmcnt : in  std_logic_vector(11-1 downto 0);
            o_en     : out std_logic;
            o_data   : out std_logic_vector(16-1 downto 0)
        );
    end component AVG_CALC_PARA4;

    type type_sm_avg_en is (
            sm_IDLE, -- 0
            sm_STR,  -- 1
            sm_ACT,  -- 2
            sm_END   -- 3
        );
    signal SM_AVG_EN: type_sm_avg_en;

    type type_reg_shf3b  is array (SHF_REG_NUM-1 downto 0) of std_logic_vector( 4-1 downto 0);
    type type_reg_shf16b is array (SHF_REG_NUM-1 downto 0) of std_logic_vector(16-1 downto 0);

    signal shf_reg_avg_en : std_logic_vector(SHF_REG_NUM-1 downto 0);
    signal shf_reg_avg_lv : type_reg_shf3b;

    type type_vid_shf12b is array (SHF_VID_NUM-1 downto 0) of std_logic_vector(12-1 downto 0);
    type type_vid_shf64b is array (SHF_VID_NUM-1 downto 0) of std_logic_vector(64-1 downto 0);

    signal shf_ihsyn : std_logic_vector(SHF_VID_NUM-1 downto 0);
    signal shf_ivsyn : std_logic_vector(SHF_VID_NUM-1 downto 0);
    signal shf_ihcnt : type_vid_shf12b;
    signal shf_ivcnt : type_vid_shf12b;
    signal shf_idata : type_vid_shf64b;
    signal shf_mdata : type_vid_shf64b;

    signal reg_avg_en  : std_logic;
    signal reg_avg_en1 : std_logic;
    signal reg_avg_en2 : std_logic;
    signal reg_avg_lv  : std_logic_vector(4-1 downto 0);
    signal reg_avg_num : integer range 0 to 1024 := 0;
    signal rat_avg_num : integer range 0 to 1024 := 0;
     
    signal avg_done   : std_logic;
    signal frm_avg_en : std_logic;
    signal frm_cnt    : std_logic_vector(11-1 downto 0) := (others => '0');
                       
    signal acc_en   : std_logic_vector(4-1 downto 0);  
    signal acc_data : std_logic_vector(64-1 downto 0); 

    signal avg_wen     : std_logic;
    signal avg_waddr   : std_logic_vector(12-1 downto 0);
    signal avg_wvcnt   : std_logic_vector(12-1 downto 0);
    signal avg_winfo   : std_logic_vector(64-1 downto 0);
    
    signal acc_i_en     : std_logic;

    COMPONENT ila_avg_para4
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe3 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe4 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe5 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
        probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe7 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe8 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe9 : IN STD_LOGIC_VECTOR(63 DOWNTO 0)
    );
    END COMPONENT;

-- █▄▄ █▀▀ █▄░█
-- █▄█ █▄█ █░▀█ %begin %bgn
begin

--    u_ila_avg_para4 : ila_avg_para4
--    PORT MAP (
--        clk       => clk,
--        probe0(0) => i_hsyn                  , -- 1 
--        probe1(0) => i_vsyn                  , -- 1 
--        probe2    => i_hcnt                  , -- 12
--        probe3    => i_vcnt                  , -- 12
--        probe4    => i_data   (64-1 downto 0), -- 16
--        probe5    => i_mdata  (64-1 downto 0), -- 16
--        probe6(0) => avg_wen                 , -- 1 
--        probe7    => avg_waddr               , -- 12
--        probe8    => avg_wvcnt               , -- 12
--        probe9    => avg_winfo(64-1 downto 0)  -- 16
--    );

process(clk, rstn)
begin
    if(clk'event and clk='1') then
    --
        shf_reg_avg_en <= shf_reg_avg_en(shf_reg_avg_en'left-1 downto 0) & i_reg_avg_en;
        shf_reg_avg_lv <= shf_reg_avg_lv(shf_reg_avg_lv'left-1 downto 0) & i_reg_avg_lv;
        reg_avg_en     <= shf_reg_avg_en(shf_reg_avg_en'left);
        reg_avg_en1    <= reg_avg_en;
        reg_avg_en2    <= reg_avg_en1;
        reg_avg_lv     <= shf_reg_avg_lv(shf_reg_avg_lv'left);

        case(reg_avg_lv) is
            when "0000"   => reg_avg_num <=    1;
            when "0001"   => reg_avg_num <=    2;
            when "0010"   => reg_avg_num <=    4;
            when "0011"   => reg_avg_num <=    8;
            when "0100"   => reg_avg_num <=   16;
            when "0101"   => reg_avg_num <=   32;
            when "0110"   => reg_avg_num <=   64;
            when "0111"   => reg_avg_num <=  128;
            when "1000"   => reg_avg_num <=  256;
            when "1001"   => reg_avg_num <=  512;
            when "1010"   => reg_avg_num <= 1024;
            when others => reg_avg_num <=   1;
        end case;

        shf_ihsyn <= shf_ihsyn(shf_ihsyn'left-1 downto 0) & i_hsyn;
        shf_ivsyn <= shf_ivsyn(shf_ivsyn'left-1 downto 0) & i_vsyn;
        shf_ihcnt <= shf_ihcnt(shf_ihcnt'left-1 downto 0) & i_hcnt;
        shf_ivcnt <= shf_ivcnt(shf_ivcnt'left-1 downto 0) & i_vcnt;
        shf_idata <= shf_idata(shf_idata'left-1 downto 0) & i_data;
        shf_mdata <= shf_mdata(shf_mdata'left-1 downto 0) & i_mdata;
    --
    end if;
end process;

-- █▀ █▀▄▀█
-- ▄█ █░▀░█ %sm %state
process(clk, rstn)
begin
    if(clk'event and clk='1') then
    --
        case(SM_AVG_EN) is
            when sm_IDLE =>
                if  reg_avg_en2 = '0' and reg_avg_en1 = '1' then -- en trig
                    SM_AVG_EN <= sm_STR;
                    avg_done <= '0';
                    frm_cnt <= (others => '0');
                    rat_avg_num  <= reg_avg_num;
                else
                    frm_avg_en <= '0';
                end if;
            when sm_STR =>
                if shf_ivsyn(0)='0' and i_vsyn='1' then -- v rise
                   SM_AVG_EN <= sm_ACT;
                end if;
            when sm_ACT =>
                   frm_avg_en <= '1';
                if shf_ivsyn(0)='1' and i_vsyn='0' then -- v fall
                   SM_AVG_EN  <= sm_END;
                   frm_cnt    <= frm_cnt + '1';
                end if;
            when sm_END =>
                if  frm_cnt  < rat_avg_num then -- cnt check
                   SM_AVG_EN  <= sm_STR;
                else
                   SM_AVG_EN  <= sm_IDLE;
                   avg_done <= '1';
                   -- frm_cnt <= (others => '0');
                end if;
            when others=> NULL;
        end case;
    --
    end if;
end process;

-- ▄▀█ █▀▀ █▀▀
-- █▀█ █▄▄ █▄▄ %acc
   gen_acc4 : for i in 0 to 3 generate
   begin
        acc_i_en <= (frm_avg_en and shf_ihsyn(1));
       u_acc_calc : AVG_CALC_PARA4
       port map (
           clk      => clk,
           i_en     => acc_i_en,
--         i_cdata => shf_idata(1)(16*(i+1)-1 downto 16*i),
--         i_mdata => shf_mdata(1)(16*(i+1)-1 downto 16*i),
--         i_mdata => b"000_0000" & shf_mdata(1)(16*(i+1)-1 downto 16*i),
           i_cdata => shf_idata(1)(16*(i+1)-1 downto 16*i),
           i_mdata => shf_mdata(1)(16*(i+1)-1 downto 16*i),
--         i_cdata  => shf_idata(SHF_VID_NUM-1)(16*(i+1)-1 downto 16*i),
--         i_mdata  => shf_mdata(SHF_VID_NUM-1)(16*(i+1)-1 downto 16*i),
           i_frmcnt => frm_cnt,
           o_en     => acc_en(i),
           o_data   => acc_data (16*(i+1)-1 downto 16*i)
           );
   end generate gen_acc4;


process(clk, rstn)
begin
    if(clk'event and clk='1') then
    --
--    avg_wen   <= shf_ihsyn(shf_ihsyn'left); --and acc_en;
      avg_wen   <= acc_en(0);
      avg_waddr <= shf_ihcnt(shf_ihcnt'left)(12-1 downto 0);
      avg_wvcnt <= shf_ivcnt(shf_ivcnt'left)(12-1 downto 0);
    avg_winfo <= acc_data;
                    
      ---- 6bit(gainoffset) + 10bit(offset) --# fail
--      avg_winfo <= shf_mdata(1+38)(16*(3+1)-1 downto 16*3+10) & acc_data(16*3+10-1 downto 16*3) &
--                   shf_mdata(1+38)(16*(2+1)-1 downto 16*2+10) & acc_data(16*2+10-1 downto 16*2) &
--                   shf_mdata(1+38)(16*(1+1)-1 downto 16*1+10) & acc_data(16*1+10-1 downto 16*1) &
--                   shf_mdata(1+38)(16*(0+1)-1 downto 16*0+10) & acc_data(16*0+10-1 downto 16*0) ;
    --
    end if;
end process;
 o_reg_avg_end <= frm_cnt & b"0000" & avg_done;

 o_avg_wen   <= avg_wen  ;
 o_avg_waddr <= avg_waddr;
 o_avg_wvcnt <= avg_wvcnt;
 o_avg_winfo <= avg_winfo;

end architecture Behavioral_AVG_PROC_PARA4;

-- █████╗  ██████╗ ██████╗     ██████╗ █████╗ ██╗      ██████╗
--██╔══██╗██╔════╝██╔════╝    ██╔════╝██╔══██╗██║     ██╔════╝
--███████║██║     ██║         ██║     ███████║██║     ██║     
--██╔══██║██║     ██║         ██║     ██╔══██║██║     ██║     
--██║  ██║╚██████╗╚██████╗    ╚██████╗██║  ██║███████╗╚██████╗
--╚═╝  ╚═╝ ╚═════╝ ╚═════╝     ╚═════╝╚═╝  ╚═╝╚══════╝ ╚═════╝ %acc
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity AVG_CALC_PARA4 is
    port (
        clk      : in  std_logic;

        i_en     : in  std_logic;
        i_cdata  : in  std_logic_vector(16-1 downto 0);
        i_mdata  : in  std_logic_vector(16-1 downto 0);
        i_frmcnt : in  std_logic_vector(11-1 downto 0);

        o_en     : out std_logic;
        o_data   : out std_logic_vector(16-1 downto 0)
    );
end entity AVG_CALC_PARA4;

architecture behavioral of AVG_CALC_PARA4 is

    component mult_u16xu16
        port (
            CLK : in  std_logic;
            A   : in  std_logic_vector(15 downto 0);
            B   : in  std_logic_vector(15 downto 0);
            CE  : in  std_logic;
            P   : out std_logic_vector(31 downto 0)
        );
    end component;

    component add_U32plusU16zU33
        port (
            A   : in  std_logic_vector(31 downto 0);
            B   : in  std_logic_vector(15 downto 0);
            CLK : in  std_logic;
            CE  : in  std_logic;
            S   : out std_logic_vector(32 downto 0)
        );
    end component;

    component div_U33DivU16z
        port (
            aclk                   : in  std_logic;
            s_axis_divisor_tvalid  : in  std_logic;
            s_axis_divisor_tdata   : in  std_logic_vector(15 downto 0);
            s_axis_dividend_tvalid : in  std_logic;
            s_axis_dividend_tdata  : in  std_logic_vector(39 downto 0);
            m_axis_dout_tvalid     : out std_logic;
            m_axis_dout_tdata      : out std_logic_vector(55 downto 0)
        );
    end component;

    signal en0             : std_logic := '0';
    signal en1             : std_logic := '0';
    signal cdata0          : std_logic_vector(16-1 downto 0) := (others=>'0');
    signal cdata1          : std_logic_vector(16-1 downto 0) := (others=>'0');
    signal mdata_mult      : std_logic_vector(32-1 downto 0) := (others=>'0');
    signal add_mdata_cdata : std_logic_vector(33-1 downto 0) := (others=>'0');
    signal DivValid        : std_logic := '0';
    signal DivData         : std_logic_vector(56-1 downto 0) := (others=>'0');
    signal divisor         : std_logic_vector(16-1 downto 0) := (others=>'0');
    signal dividend        : std_logic_vector(40-1 downto 0) := (others=>'0');
    signal mult_B : std_logic_vector(16-1 downto 0) := (others=>'0');

begin
                                    
-- █▀▄▀█ █▀▄▀█ █▀█   ▀▄▀   █▀█ ▄▀█ █▀▀ █▀▀
-- █░▀░█ █░▀░█ █▀▄   █░█   █▀▀ █▀█ █▄█ ██▄
    mult_B  <= (b"0000_0"&i_frmcnt); 
    u_MmrPage : mult_u16xu16 -- delay 1
        port map (
            CLK => clk,
            A   => i_mdata,
            B   => mult_B,
            CE  => i_en,
            P   => mdata_mult
        );
    process (clk)
    begin
        if clk'event and clk='1' then
        --
            cdata0 <= i_cdata;
            en0    <= i_en;
        --
    end if;
    end process;
                                      
-- █▀▄▀█ █░█ █░░ ▀█▀ ▄█▄ █▀▀ █░█ █▀█ █▀█
-- █░▀░█ █▄█ █▄▄ ░█░ ░▀░ █▄▄ █▄█ █▀▄ █▀▄
    u_MmrAddLive : add_U32plusU16zU33 -- delay 1
        port map (
            A   => mdata_mult,
            B   => cdata0,
            CLK => clk,
            CE  => en0,
            S   => add_mdata_cdata
        );
    process (clk)
    begin
        if clk'event and clk='1' then
        --
            en1    <= en0;
        --
    end if;
    end process;
                          
-- █▀▄ █ █░█   █▀█ ▄▀█ █▀▀ █▀▀
-- █▄▀ █ ▀▄▀   █▀▀ █▀█ █▄█ ██▄
    dividend <= b"000_0000" & add_mdata_cdata;
     divisor <=  i_frmcnt+x"0001";
    u_sumDivPage : div_U33DivU16z  -- delay 35
        port map (
            aclk                   => clk,
            s_axis_divisor_tvalid  => en1,
            s_axis_divisor_tdata   => divisor,
            s_axis_dividend_tvalid => en1,
            s_axis_dividend_tdata  => dividend,
            m_axis_dout_tvalid     => DivValid,
            m_axis_dout_tdata      => DivData
        );

    process (clk)
    begin
        if clk'event and clk='1' then
        --
            o_en   <= DivValid;
            o_data <= divData(16+16 - 1 downto 16) + divData(15);
    --      if divData(16 - 1 downto 0) >= pageCntPlus(16-1 downto 1) then
    --          o_data <= divData(16+16 - 1 downto 16) + '1';
    --      else
    --          o_data <= divData(16+16 - 1 downto 16);
    --      end if
            
        --
        end if;
    end process;

end architecture behavioral;
