-- v0.1 220203mbh
-- v0.2 component 220204mbh
-- v0.3 add chgdet_osd  220331mbh

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;
  -- use ieee.numeric_std.all;
    use WORK.TOP_HEADER.ALL;

entity osd is
generic ( GNR_MODEL : string  := "EXT1616R" );
    port (
        i_sclk          : in    std_logic; -- 100MHz
        i_ext_trig_in   : in    std_logic; -- external trig in
        i_reg_osd_ctrl  : in    std_logic_vector(16 - 1 downto 0);
        o_reg_trigcnt   : out   std_logic_vector(16 - 1 downto 0);
        o_reg_totrigcnt : out   std_logic_vector(16 - 1 downto 0);
        i_reg_sync_rcnt : in    std_logic_vector(32*3*10 - 1 downto 0);

        i_chgdet_osd_en : in    std_logic;
        i_chgdet_osd_da : in    std_logic_vector(16 - 1 downto 0);

        i_dclk : in    std_logic;
        i_hsyn : in    std_logic;
        i_vsyn : in    std_logic;
        i_hcnt : in    std_logic_vector(12 - 1 downto 0);
        i_vcnt : in    std_logic_vector(12 - 1 downto 0);
        i_data : in    std_logic_vector(16 - 1 downto 0);

        o_hsyn : out   std_logic;
        o_vsyn : out   std_logic;
        o_hcnt : out   std_logic_vector(12 - 1 downto 0);
        o_vcnt : out   std_logic_vector(12 - 1 downto 0);
        o_data : out   std_logic_vector(16 - 1 downto 0)
    );
end entity osd;

architecture behavioralosd of osd is

    constant addrWidth : integer := 8;
    constant dataWidth : integer := 8;
    constant TRIG_LINE_NUM : integer := 11;
    constant IMG_LINE_NUM : integer := 13;
--  constant sizex     : integer := 1;
    signal reg_sizex : std_logic_vector(2 - 1 downto 0) := (others=> '0');

    component fontROM is
  --generic(
  --  addrWidth: integer := 8;
  --  dataWidth: integer := 8
  --);
        port (
            clkA         : in    std_logic;
            writeEnableA : in    std_logic;
            addrA        : in    std_logic_vector(addrWidth - 1 downto 0);
            dataOutA     : out   std_logic_vector(dataWidth - 1 downto 0);
            dataInA      : in    std_logic_vector(dataWidth - 1 downto 0)
        );
    end component;

    component vec2dec is
        port (
            clk   : in    std_logic;
            i_vec : in    std_logic_vector(16 - 1 downto 0);
            o_dec : out   std_logic_vector(4*5 - 1 downto 0)
        );
    end component;

    component binary_bcd is
    -- generic(
    --     bitBin: positive := 16
    --     bitDec: positive := 5
    --   );
        port (
            clk   : in    std_logic;
            i_str : in    std_logic;
            i_bin : in    std_logic_vector(16 - 1 downto 0);
            o_bcd : out   std_logic_vector(5 * 4 - 1 downto 0)
        );
    end component;

    COMPONENT blk_mem_16bx256
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
      );
    END COMPONENT;
    signal frft_wea : std_logic := '0';
    signal frft_addra : std_logic_vector(8 -1 downto 0) := (others=> '0');
    signal frft_dina : std_logic_vector(16-1 downto 0) := (others=> '0');
    signal frft_addrb : std_logic_vector(8 -1 downto 0) := (others=> '0');
    signal frft_doutb : std_logic_vector(16-1 downto 0) := (others=> '0');

    COMPONENT blk_mem_32b_16x16
      PORT (
        clka : IN STD_LOGIC;
        ena : IN STD_LOGIC;
        wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        clkb : IN STD_LOGIC;
        enb : IN STD_LOGIC;
        addrb : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        doutb : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
      );
    END COMPONENT;
     signal bcd_wea : std_logic := '0';
     signal bcd_addra : std_logic_vector(8 -1 downto 0) := (others=> '0');
     signal bcd_dina : std_logic_vector(32-1 downto 0) := (others=> '0');
     signal bcd_addrb : std_logic_vector(8 -1 downto 0) := (others=> '0');
     signal bcd_doutb : std_logic_vector(32-1 downto 0) := (others=> '0');

    COMPONENT ila_osd
    PORT (
        clk : IN STD_LOGIC;
        probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe1 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe2 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe4 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe5 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe6 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe7 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe8 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe10 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe11 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe12 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe13 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe14 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe15 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe16 : IN STD_LOGIC_VECTOR(19 DOWNTO 0); 
        probe17 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe18 : IN STD_LOGIC_VECTOR(7 DOWNTO 0); 
        probe19 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe20 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe21 : IN STD_LOGIC_VECTOR(11 DOWNTO 0); 
        probe22 : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe23 : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;

    signal sclk : std_logic;
    signal dclk : std_logic;

    signal reg_osd_ctrl_d0 : std_logic_vector(16 - 1 downto 0):=(others=>'0');
    signal reg_osd_ctrl_d1 : std_logic_vector(16 - 1 downto 0):=(others=>'0');
    signal reg_osd_ctrl    : std_logic_vector(16 - 1 downto 0):=(others=>'0');
    signal reg_osd_en      : std_logic;
    signal reg_osd_sel     : std_logic_vector(2-1 downto 0) := (others=> '0');

    signal sext_trig_shft  : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal sext_trig_shft8 : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal sext_trig       : std_logic;
    signal strig1sCnt      : std_logic_vector(32 - 1 downto 0):=(others=>'0');

    signal strigCnt : std_logic_vector(16 - 1 downto 0):=(others=>'0');

    signal vsync_shft    : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal VsyncInterval : std_logic_vector(32 - 1 downto 0):=(others=>'0');

    signal Tcnt1             : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcnt10            : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcnt100           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcnt1000          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcnt10000         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcntd1            : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcntd10           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcntd100          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcntd1000         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Tcntd10000        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcnt1           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcnt10          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcnt100         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcnt1000        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcnt10000       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcntd1          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcntd10         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcntd100        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcntd1000       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal ToTcntd10000      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcnt1             : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcnt10            : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcnt100           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcnt1000          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcnt10000         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcntd1            : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcntd10           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcntd100          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcntd1000         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal Vcntd10000        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal THzCnt1           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal THzCnt10          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal THzCnt100         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal THzCnt1000        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal THzCnt10000       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal THzCnt100000      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCnt1       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCnt10      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCnt100     : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCnt1000    : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCnt10000   : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCnt100000  : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCntD1      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCntD10     : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCntD100    : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCntD1000   : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCntD10000  : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepTHzCntD100000 : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFr1           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFr10          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFr100         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFr1000        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFr10000       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFrd1          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFrd10         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFrd100        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFrd1000       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VcntFrd10000      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VHzCnt1           : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VHzCnt10          : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VHzCnt100         : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VHzCnt1000        : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VHzCnt10000       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal VHzCnt100000      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCnt1       : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCnt10      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCnt100     : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCnt1000    : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCnt10000   : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCnt100000  : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCntD1      : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCntD10     : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCntD100    : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCntD1000   : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCntD10000  : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal keepVHzCntD100000 : std_logic_vector(4 - 1 downto 0):=(others=>'0');

    signal shsyn : std_logic;
    signal svsyn : std_logic;
    signal shcnt : std_logic_vector(11 downto 0);
    signal svcnt : std_logic_vector(11 downto 0);
    signal sdata : std_logic_vector(15 downto 0);

    signal s0hsyn : std_logic;
    signal s0vsyn : std_logic;
    signal s0hcnt : std_logic_vector(11 downto 0);
    signal s0vcnt : std_logic_vector(11 downto 0);
    signal s0data : std_logic_vector(15 downto 0);

    signal s1hsyn : std_logic;
    signal s1vsyn : std_logic;
    signal s1hcnt : std_logic_vector(11 downto 0);
    signal s1vcnt : std_logic_vector(11 downto 0);
    signal s1data : std_logic_vector(15 downto 0);

    signal s2hsyn : std_logic;
    signal s2vsyn : std_logic;
    signal s2hcnt : std_logic_vector(11 downto 0);
    signal s2vcnt : std_logic_vector(11 downto 0);
    signal s2data : std_logic_vector(15 downto 0);

    signal ohsyn : std_logic;
    signal ovsyn : std_logic;
    signal ohcnt : std_logic_vector(11 downto 0);
    signal ovcnt : std_logic_vector(11 downto 0);
    signal odata : std_logic_vector(15 downto 0);

    signal font_addr : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal font_out  : std_logic_vector(8 - 1 downto 0):=(others=>'0');

    signal maskopen : std_logic;
    signal osdd     : std_logic;
    signal osdd_d0  : std_logic;
    signal osdd_d1  : std_logic;

    signal strigNull  : std_logic;
    signal s0trigNull : std_logic;
    signal s1trigNull : std_logic;

    signal tcnt      : std_logic_vector(16 - 1 downto 0):=(others=>'0');
    signal sreg_tcnt : std_logic_vector(16 - 1 downto 0):=(others=>'0');
    signal totcnt    : std_logic_vector(16 - 1 downto 0):=(others=>'0'); --# 240809

    signal oreg_trigcnt : std_logic_vector(16 - 1 downto 0);
    signal oreg_totrigcnt : std_logic_vector(16 - 1 downto 0);

    signal svsync0 : std_logic;
    signal svsync1 : std_logic;
    signal usCnt   : std_logic_vector(32 - 1 downto 0):= (others =>'0');
    signal vusCnt  : std_logic_vector(32 - 1 downto 0):= (others =>'0'); -- video micro sec cnt #230718


    signal reg_sync_rcnt_0 : std_logic_vector(32*30 - 1 downto 0);
    signal reg_sync_rcnt_1 : std_logic_vector(32*30 - 1 downto 0);
    signal reg_sync_rcnt   : std_logic_vector(32*30 - 1 downto 0);

    -- signal fcnt0 : std_logic_vector(16 - 1 downto 0);
    -- signal hcnt0 : std_logic_vector(16 - 1 downto 0);
    -- signal vcnt0 : std_logic_vector(16 - 1 downto 0);
    -- signal avg_0 : std_logic_vector(16 - 1 downto 0);
    -- signal cent0 : std_logic_vector(16 - 1 downto 0);
    -- signal high0 : std_logic_vector(16 - 1 downto 0);
    -- signal low_0 : std_logic_vector(16 - 1 downto 0);

    -- signal high0x    : std_logic_vector(16 - 1 downto 0);
    -- signal high0xx   : std_logic_vector(16 - 1 downto 0);
    -- signal high0xxx  : std_logic_vector(16 - 1 downto 0);
    -- signal high0xxxx : std_logic_vector(16 - 1 downto 0);

    signal wordHcnt : std_logic_vector(8 - 1 downto 0);
    signal wordVcnt : std_logic_vector(8 - 1 downto 0);
    signal fontHcnt : std_logic_vector(3 - 1 downto 0);
    signal fontVcnt : std_logic_vector(4 - 1 downto 0);

    signal fontHcnt_d0 : std_logic_vector(3 - 1 downto 0);
    signal fontHcnt_d1 : std_logic_vector(3 - 1 downto 0);
    signal fontHcnt_d2 : std_logic_vector(3 - 1 downto 0);

    signal high0_10000 : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal high0_1000  : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal high0_100   : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal high0_10    : std_logic_vector(4 - 1 downto 0):=(others=>'0');
    signal high0_1     : std_logic_vector(4 - 1 downto 0):=(others=>'0');

    type   stateswt_type is (stSWT_IDLE, stSWT_RDY, stSWT_INCR, stSWT_WORD, 
                             stSWT_ADDRINC, stSWT_ADDRINC0, stSWT_DONE);
    signal stateSWT      : stateswt_type;
    signal next_stateSWT : stateswt_type;
   -- signal <output>_i : std_logic;  -- example output signal

    -- type   type_256xb16 is array (0 to 256 - 1) of std_logic_vector(16 - 1 downto 0);
    -- signal binNum : type_256xb16;

    type   type_1024xb4 is array (0 to 128*16 - 1) of std_logic_vector(4 - 1 downto 0);
    signal bcd : type_1024xb4 := (others=> (others=> '1'));

    signal iBin     : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal oBcd     : std_logic_vector(20 - 1 downto 0) := (others => '0');
    signal incrCnt  : std_logic_vector(16 - 1 downto 0) := (others => '0');
    signal binStart : std_logic;
    signal smStart  : std_logic;
    signal wordCnt  : std_logic_vector(8 - 1 downto 0) := (others => '0');

    signal chgdet_osd_en : std_logic := '0';
    signal chgdet_osd_da : std_logic_vector(16-1 downto 0) := (others=> '0');
    signal chgdet_en_cnt : std_logic_vector(8-1 downto 0) := (others=> '0');

    signal SynCheckCntStart : std_logic := '0';
    signal SyncCheckDe : std_logic := '0';
    signal SyncCheckCnt : std_logic_vector(8-1 downto 0) := (others=> '0');

    signal osd_en_d0       : std_logic;
    signal osd_en_d1       : std_logic;
    --!osdbegin
begin
    sclk <= i_sclk;
    dclk <= i_dclk;
 
    --#################
    --### reg shift ###
    process(dclk)
    begin
        if dclk'event and dclk='1' then
            --
            reg_osd_ctrl_d0 <= i_reg_osd_ctrl;
            reg_osd_ctrl_d1 <= reg_osd_ctrl_d0;
            reg_osd_ctrl    <= reg_osd_ctrl_d1;
            reg_osd_en      <= reg_osd_ctrl(0);
            reg_osd_sel     <= reg_osd_ctrl(3 downto 2);
            reg_sizex       <= reg_osd_ctrl(5 downto 4);
            --
        end if;
    end process;

    process (sclk)
    begin
        if sclk'event and sclk='1' then
        --
            --##################
            --### trig shift ###
            sext_trig_shft <= sext_trig_shft(sext_trig_shft'left - 1 downto 0) & i_ext_trig_in;
            if  sext_trig_shft = x"FF" then
                sext_trig <= '1';
            else
                sext_trig <= '0';
            end if;
            sext_trig_shft8 <= sext_trig_shft8(sext_trig_shft8'left - 1 downto 0) & sext_trig;

            --#####################
            --### 1 sec counter ###
            if sext_trig_shft8(1)='0' and sext_trig_shft8(0) = '1' then
                strig1sCnt <= (others=>'0');
            else
                if  strig1sCnt < 100_000_000 then -- 100M
                    strig1sCnt <= strig1sCnt  + '1';
                end if;
            end if;

            --##################
            --### 1 sec idle ###
            if strig1sCnt =  100_000_000 then
                strigNull <= '1';
            else
                strigNull <= '0';
            end if;
            s0trigNull <= strigNull;
            s1trigNull <= s0trigNull;

            --###############################################
            --### trig counter latch for register reading ###
            sreg_tcnt <= tcnt;
            if s1trigNull='0' and  s0trigNull='1' then
                tcnt      <= (others=> '0');
            elsif sext_trig_shft8(5)='0' and sext_trig_shft8(4) = '1' then
                tcnt <= tcnt + '1';
            end if;
            oreg_trigcnt <= sreg_tcnt;

            if sext_trig_shft8(5)='0' and sext_trig_shft8(4) = '1' then --# 240809
                totcnt <= totcnt + '1';
            end if;
            oreg_totrigcnt <= totcnt;

            --###############################
            --### Trig Hz counter & latch ###
            if strigNull = '1' then --# 230718
                keepTHzCnt1      <= (others=>'0');
                keepTHzCnt10     <= (others=>'0');
                keepTHzCnt100    <= (others=>'0');
                keepTHzCnt1000   <= (others=>'0');
                keepTHzCnt10000  <= (others=>'0');
                keepTHzCnt100000 <= (others=>'0');
            elsif sext_trig_shft8(5)='0' and sext_trig_shft8(4) = '1' then
                usCnt            <= (others=>'0');
                keepTHzCnt1      <= THzCnt1;
                keepTHzCnt10     <= THzCnt10;
                keepTHzCnt100    <= THzCnt100;
                keepTHzCnt1000   <= THzCnt1000;
                keepTHzCnt10000  <= THzCnt10000;
                keepTHzCnt100000 <= THzCnt100000;
                THzCnt1          <= x"1"; -- (others=>'0');
                THzCnt10         <= (others=>'0');
                THzCnt100        <= (others=>'0');
                THzCnt1000       <= (others=>'0');
                THzCnt10000      <= (others=>'0');
                THzCnt100000     <= (others=>'0');
            else
                if usCnt < 100 then
                    usCnt <= usCnt + '1';
                else
                    usCnt <= (others =>'0');
                    if THzCnt1 < 10 - 1 then
                        THzCnt1 <= THzCnt1 +'1';
                    else
                        THzCnt1 <= (others=>'0');
                        if THzCnt10 < 10 - 1 then
                            THzCnt10 <= THzCnt10 +'1';
                        else
                            THzCnt10 <= (others=>'0');
                            if THzCnt100 < 10 - 1 then
                                THzCnt100 <= THzCnt100 +'1';
                            else
                                THzCnt100 <= (others=>'0');
                                if THzCnt1000 < 10 - 1 then
                                    THzCnt1000 <= THzCnt1000 +'1';
                                else
                                    THzCnt1000 <= (others=>'0');
                                    if THzCnt10000 < 10 - 1 then
                                        THzCnt10000 <= THzCnt10000 +'1';
                                    else
                                        THzCnt10000 <= (others=>'0');
                                        if THzCnt100000 < 10 - 1 then
                                            THzCnt100000 <= THzCnt100000 +'1';
                                        else
                                            THzCnt100000 <= (others=>'0');
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            -- ############################
            -- ### trig counter decimal ###
            if strigNull = '1' then
                Tcnt1     <= (others=>'0');
                Tcnt10    <= (others=>'0');
                Tcnt100   <= (others=>'0');
                Tcnt1000  <= (others=>'0');
                Tcnt10000 <= (others=>'0');
            elsif sext_trig_shft8(5)='0' and sext_trig_shft8(4) = '1' then
                if Tcnt1 < 10 - 1 then
                    Tcnt1 <= Tcnt1 +'1';
                else
                    Tcnt1 <= (others=>'0');
                    if Tcnt10 < 10 - 1 then
                        Tcnt10 <= Tcnt10 +'1';
                    else
                        Tcnt10 <= (others=>'0');
                        if Tcnt100 < 10 - 1 then
                            Tcnt100 <= Tcnt100 +'1';
                        else
                            Tcnt100 <= (others=>'0');
                            if Tcnt1000 < 10 - 1 then
                                Tcnt1000 <= Tcnt1000 +'1';
                            else
                                Tcnt1000 <= (others=>'0');
                                if Tcnt10000 < 10 - 1 then
                                    Tcnt10000 <= Tcnt10000 +'1';
                                else
                                    Tcnt10000 <= (others=>'0');
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            if sext_trig_shft8(5)='0' and sext_trig_shft8(4) = '1' then
                if ToTcnt1 < 10 - 1 then
                    ToTcnt1 <= ToTcnt1 +'1';
                else
                    ToTcnt1 <= (others=>'0');
                    if ToTcnt10 < 10 - 1 then
                        ToTcnt10 <= ToTcnt10 +'1';
                    else
                        ToTcnt10 <= (others=>'0');
                        if ToTcnt100 < 10 - 1 then
                            ToTcnt100 <= ToTcnt100 +'1';
                        else
                            ToTcnt100 <= (others=>'0');
                            if ToTcnt1000 < 10 - 1 then
                                ToTcnt1000 <= ToTcnt1000 +'1';
                            else
                                ToTcnt1000 <= (others=>'0');
                                if ToTcnt10000 < 10 - 1 then
                                    ToTcnt10000 <= ToTcnt10000 +'1';
                                else
                                    ToTcnt10000 <= (others=>'0');
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
            -- ##############################
            -- ### v sync coutner decimal ###
            svsync0 <= i_vsyn;
            svsync1 <= svsync0;
            if strigNull = '1' then
                Vcnt1     <= (others=>'0');
                Vcnt10    <= (others=>'0');
                Vcnt100   <= (others=>'0');
                Vcnt1000  <= (others=>'0');
                Vcnt10000 <= (others=>'0');
            elsif svsync1='0' and svsync0 = '1' then
                if Vcnt1 < 10 - 1 then
                    Vcnt1 <= Vcnt1 +'1';
                else
                    Vcnt1 <= (others=>'0');
                    if Vcnt10 < 10 - 1 then
                        Vcnt10 <= Vcnt10 +'1';
                    else
                        Vcnt10 <= (others=>'0');
                        if Vcnt100 < 10 - 1 then
                            Vcnt100 <= Vcnt100 +'1';
                        else
                            Vcnt100 <= (others=>'0');
                            if Vcnt1000 < 10 - 1 then
                                Vcnt1000 <= Vcnt1000 +'1';
                            else
                                Vcnt1000 <= (others=>'0');
                                if Vcnt10000 < 10 - 1 then
                                    Vcnt10000 <= Vcnt10000 +'1';
                                else
                                    Vcnt10000 <= (others=>'0');
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

            -- ######################################
            -- ### v sync coutner decimal freerun ###
--          svsync0 <= i_vsyn;
--          svsync1 <= svsync0;
--            if strigNull = '1' then
--                Vcnt1     <= (others=>'0');
--                Vcnt10    <= (others=>'0');
--                Vcnt100   <= (others=>'0');
--                Vcnt1000  <= (others=>'0');
--                Vcnt10000 <= (others=>'0');
--            elsif svsync1='0' and svsync0 = '1' then

            osd_en_d0 <= reg_osd_en;
            osd_en_d1 <= osd_en_d0;
            if osd_en_d1 = '0' then
                VcntFr1     <= (others=>'0');
                VcntFr10    <= (others=>'0');
                VcntFr100   <= (others=>'0');
                VcntFr1000  <= (others=>'0');
                VcntFr10000 <= (others=>'0');
            elsif svsync1='0' and svsync0 = '1' then
                if  VcntFr1     = 9 and -- 99999
                    VcntFr10    = 9 and
                    VcntFr100   = 9 and
                    VcntFr1000  = 9 and
                    VcntFr10000 = 9 then
                        VcntFr1     <= (others=>'0');
                        VcntFr10    <= (others=>'0');
                        VcntFr100   <= (others=>'0');
                        VcntFr1000  <= (others=>'0');
                        VcntFr10000 <= (others=>'0');
                else
                    if VcntFr1 < 10 - 1 then
                        VcntFr1 <= VcntFr1 +'1';
                    else
                        VcntFr1 <= (others=>'0');
                        if VcntFr10 < 10 - 1 then
                            VcntFr10 <= VcntFr10 +'1';
                        else
                            VcntFr10 <= (others=>'0');
                            if VcntFr100 < 10 - 1 then
                                VcntFr100 <= VcntFr100 +'1';
                            else
                                VcntFr100 <= (others=>'0');
                                if VcntFr1000 < 10 - 1 then
                                    VcntFr1000 <= VcntFr1000 +'1';
                                else
                                    VcntFr1000 <= (others=>'0');
                                    if VcntFr10000 < 10 - 1 then
                                        VcntFr10000 <= VcntFr10000 +'1';
                                    else
                                        VcntFr10000 <= (others=>'0');
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
            
            --###############################
            --### Image Hz counter & latch ###
            if svsync1='0' and svsync0 = '1' then
                vusCnt           <= (others=>'0');
                keepVHzCnt1      <= VHzCnt1;
                keepVHzCnt10     <= VHzCnt10;
                keepVHzCnt100    <= VHzCnt100;
                keepVHzCnt1000   <= VHzCnt1000;
                keepVHzCnt10000  <= VHzCnt10000;
                keepVHzCnt100000 <= VHzCnt100000;
                VHzCnt1          <= x"1"; -- (others=>'0');
                VHzCnt10         <= (others=>'0');
                VHzCnt100        <= (others=>'0');
                VHzCnt1000       <= (others=>'0');
                VHzCnt10000      <= (others=>'0');
                VHzCnt100000     <= (others=>'0');
            else
                if vusCnt < 100 then
                    vusCnt <= vusCnt + '1';
                else
                    vusCnt <= (others =>'0');
                    if VHzCnt1 < 10 - 1 then
                        VHzCnt1 <= VHzCnt1 +'1';
                    else
                        VHzCnt1 <= (others=>'0');
                        if VHzCnt10 < 10 - 1 then
                            VHzCnt10 <= VHzCnt10 +'1';
                        else
                            VHzCnt10 <= (others=>'0');
                            if VHzCnt100 < 10 - 1 then
                                VHzCnt100 <= VHzCnt100 +'1';
                            else
                                VHzCnt100 <= (others=>'0');
                                if VHzCnt1000 < 10 - 1 then
                                    VHzCnt1000 <= VHzCnt1000 +'1';
                                else
                                    VHzCnt1000 <= (others=>'0');
                                    if VHzCnt10000 < 10 - 1 then
                                        VHzCnt10000 <= VHzCnt10000 +'1';
                                    else
                                        VHzCnt10000 <= (others=>'0');
                                        if VHzCnt100000 < 10 - 1 then
                                            VHzCnt100000 <= VHzCnt100000 +'1';
                                        else
                                            VHzCnt100000 <= (others=>'0');
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                    end if;
                end if;
            end if;

     --
        end if;
    end process;

    process (dclk)
        variable int_word_hcnt_3bit : integer range 0 to 8-1 :=0;
    begin
        if dclk'event and dclk='1' then
    --

            Tcntd1            <= Tcnt1;
            Tcntd10           <= Tcnt10;
            Tcntd100          <= Tcnt100;
            Tcntd1000         <= Tcnt1000;
            Tcntd10000        <= Tcnt10000;
            ToTcntd1          <= ToTcnt1;
            ToTcntd10         <= ToTcnt10;
            ToTcntd100        <= ToTcnt100;
            ToTcntd1000       <= ToTcnt1000;
            ToTcntd10000      <= ToTcnt10000;
            Vcntd1            <= Vcnt1;
            Vcntd10           <= Vcnt10;
            Vcntd100          <= Vcnt100;
            Vcntd1000         <= Vcnt1000;
            Vcntd10000        <= Vcnt10000;
            keepTHzCntD1      <= keepTHzCnt1;
            keepTHzCntD10     <= keepTHzCnt10;
            keepTHzCntD100    <= keepTHzCnt100;
            keepTHzCntD1000   <= keepTHzCnt1000;
            keepTHzCntD10000  <= keepTHzCnt10000;
            keepTHzCntD100000 <= keepTHzCnt100000;
            VcntFrd1          <= VcntFr1;
            VcntFrd10         <= VcntFr10;
            VcntFrd100        <= VcntFr100;
            VcntFrd1000       <= VcntFr1000;
            VcntFrd10000      <= VcntFr10000;
            keepVHzCntD1      <= keepVHzCnt1;
            keepVHzCntD10     <= keepVHzCnt10;
            keepVHzCntD100    <= keepVHzCnt100;
            keepVHzCntD1000   <= keepVHzCnt1000;
            keepVHzCntD10000  <= keepVHzCnt10000;
            keepVHzCntD100000 <= keepVHzCnt100000;

            shsyn  <= i_hsyn;
            svsyn  <= i_vsyn;
            shcnt  <= i_hcnt;
            svcnt  <= i_vcnt;
            sdata  <= i_data;
            s0hsyn <= shsyn;
            s0vsyn <= svsyn;
            s0hcnt <= shcnt;
            s0vcnt <= svcnt;
            s0data <= sdata;
            s1hsyn <= s0hsyn;
            s1vsyn <= s0vsyn;
            s1hcnt <= s0hcnt;
            s1vcnt <= s0vcnt;
            s1data <= s0data;
            s2hsyn <= s1hsyn;
            s2vsyn <= s1vsyn;
            s2hcnt <= s1hcnt;
            s2vcnt <= s1vcnt;
            s2data <= s1data;
            --### 1x ###
            if GEV_SPEED_BY_MODEL(GNR_MODEL)="10G " then
                if reg_sizex = 0 then
                    fontHcnt <= shcnt(3     - 1 downto 0);                -- 3b
                    fontVcnt <= svcnt(4     - 1 downto 0);                -- 4b
                    wordHcnt <= shcnt(3 + 8 - 1 downto 3);                -- 8b
                    wordVcnt <= svcnt(4 + 8 - 1 downto 4);                -- 8b
                --### 2x ###
                elsif reg_sizex = 1 then
                    fontHcnt <= shcnt(3 + 0     - 1 downto 0 + 0); --# 10G 
                    fontVcnt <= svcnt(4 + 1     - 1 downto 0 + 1);
--                    wordHcnt <= shcnt(3 + 1 + 8 - 1 downto 3 + 1);
                    wordHcnt <= shcnt(3 + 8 - 1 downto 3);          --#@ bugfix 230224
                    wordVcnt <= '0' &  svcnt(4 + 1 + 8 - 2 downto 4 + 1); -- max 11
                --### 4x ###
                else
                    fontHcnt <= shcnt(3 + 0     - 1 downto 0 + 0); --# 10G
                    fontVcnt <= svcnt(4 + 2     - 1 downto 0 + 2);
--                    wordHcnt <= '0' & shcnt(3 + 2 + 8 - 1 - 1 downto 3 + 2); -- over bit
                    wordHcnt <= shcnt(3 + 8 - 1 downto 3);          --#@ bugfix 230224
                    wordVcnt <= "00" & svcnt(4 + 2 + 8 - 3 downto 4 + 2); -- max 11
                end if;
            else -- GEV_SPEED_BY_MODEL(GNR_MODEL)="2p5G" then 
                if reg_sizex = 0 then
                    fontHcnt <= shcnt(3     - 1 downto 0);                -- 3b
                    fontVcnt <= svcnt(4     - 1 downto 0);                -- 4b
                    wordHcnt <= shcnt(3 + 8 - 1 downto 3);                -- 8b
                    wordVcnt <= svcnt(4 + 8 - 1 downto 4);                -- 8b
                --### 2x ###
                elsif reg_sizex = 1 then
                    fontHcnt <= shcnt(3 + 1     - 1 downto 0 + 1);
                    fontVcnt <= svcnt(4 + 1     - 1 downto 0 + 1);
                    wordHcnt <= shcnt(3 + 1 + 8 - 1 downto 3 + 1);
                    wordVcnt <= '0' &  svcnt(4 + 1 + 8 - 2 downto 4 + 1); -- max 11
                --### 4x ###
                else
                    fontHcnt <= shcnt(3 + 2     - 1 downto 0 + 2);
                    fontVcnt <= svcnt(4 + 2     - 1 downto 0 + 2);
                    wordHcnt <= '0' & shcnt(3 + 2 + 8 - 1 - 1 downto 3 + 2); -- over bit
                    wordVcnt <= "00" & svcnt(4 + 2 + 8 - 3 downto 4 + 2); -- max 11
                end if;
            end if;

      -- #################
      -- ### addr call ###
            fontHcnt_d0 <= fontHcnt;
            fontHcnt_d1 <= fontHcnt_d0;
            fontHcnt_d2 <= fontHcnt_d1;
--            if wordVcnt = 16 then
            if wordVcnt = TRIG_LINE_NUM then --# move line position 230608
                if    wordHcnt = 02 then font_addr <= keepTHzCntD100000 & fontVcnt; --# trig time
                elsif wordHcnt = 03 then font_addr <= keepTHzCntD10000  & fontVcnt;
                elsif wordHcnt = 04 then font_addr <= keepTHzCntD1000   & fontVcnt;
                elsif wordHcnt = 05 then font_addr <= x"A"              & fontVcnt;
                elsif wordHcnt = 06 then font_addr <= keepTHzCntD100    & fontVcnt;
                elsif wordHcnt = 07 then font_addr <= keepTHzCntD10     & fontVcnt;
                elsif wordHcnt = 08 then font_addr <= keepTHzCntD1      & fontVcnt;
                --               09
                --               10
                elsif wordHcnt = 11 then font_addr <= Tcntd10000        & fontVcnt; --# trig cnt + 1s rst
                elsif wordHcnt = 12 then font_addr <= Tcntd1000         & fontVcnt;
                elsif wordHcnt = 13 then font_addr <= Tcntd100          & fontVcnt;
                elsif wordHcnt = 14 then font_addr <= Tcntd10           & fontVcnt;
                elsif wordHcnt = 15 then font_addr <= Tcntd1            & fontVcnt;
                --               16
                --               17
                elsif wordHcnt = 18 then font_addr <= ToTcntd10000      & fontVcnt; --# trig total cnt
                elsif wordHcnt = 19 then font_addr <= ToTcntd1000       & fontVcnt;
                elsif wordHcnt = 20 then font_addr <= ToTcntd100        & fontVcnt;
                elsif wordHcnt = 21 then font_addr <= ToTcntd10         & fontVcnt;
                elsif wordHcnt = 22 then font_addr <= ToTcntd1          & fontVcnt;

                else                     font_addr <= x"F"              & fontVcnt;
                end if;
            elsif wordVcnt = IMG_LINE_NUM then --# 230718
                if    wordHcnt = 02 then font_addr <= keepVHzCntD100000 & fontVcnt;  --# img time 
                elsif wordHcnt = 03 then font_addr <= keepVHzCntD10000  & fontVcnt;
                elsif wordHcnt = 04 then font_addr <= keepVHzCntD1000   & fontVcnt;
                elsif wordHcnt = 05 then font_addr <= x"A"              & fontVcnt;
                elsif wordHcnt = 06 then font_addr <= keepVHzCntD100    & fontVcnt;
                elsif wordHcnt = 07 then font_addr <= keepVHzCntD10     & fontVcnt;
                elsif wordHcnt = 08 then font_addr <= keepVHzCntD1      & fontVcnt;
                --               09
                --               10
                elsif wordHcnt = 11 then font_addr <= Vcntd10000        & fontVcnt;  --# img cnt + 1s rst
                elsif wordHcnt = 12 then font_addr <= Vcntd1000         & fontVcnt;
                elsif wordHcnt = 13 then font_addr <= Vcntd100          & fontVcnt;
                elsif wordHcnt = 14 then font_addr <= Vcntd10           & fontVcnt;
                elsif wordHcnt = 15 then font_addr <= Vcntd1            & fontVcnt;
                --               16
                --               17
                elsif wordHcnt = 18 then font_addr <= VcntFrd10000      & fontVcnt;  --# img total cnt
                elsif wordHcnt = 19 then font_addr <= VcntFrd1000       & fontVcnt;
                elsif wordHcnt = 20 then font_addr <= VcntFrd100        & fontVcnt;
                elsif wordHcnt = 21 then font_addr <= VcntFrd10         & fontVcnt;
                elsif wordHcnt = 22 then font_addr <= VcntFrd1          & fontVcnt;

                else                     font_addr <= x"F"              & fontVcnt;
                end if;
            else
                -- font_addr <= bcd(conv_integer(wordVcnt(4 - 1 downto 0) & wordHcnt(7 - 1 downto 0))) & fontVcnt;
                font_addr <= bcd_doutb(4*(int_word_hcnt_3bit+1)-1 downto 4*int_word_hcnt_3bit) & fontVcnt;
            end if;
            int_word_hcnt_3bit := conv_integer(wordHcnt(3-1 downto 0));
            --
        end if;
    end process;

    process(dclk)
    begin
        if dclk'event and dclk='1' then
            --
      -- ###################
      -- ### osd mapping ###
--          osdd <= font_out(conv_integer(not fontHcnt_d1));
            osdd <= font_out(conv_integer(not fontHcnt_d2));

      -- ############
      -- ### mask ###
          -- v start position = 128
          -- font v size = 16
          -- sizex = font magnification value
        case "00"&reg_osd_sel is
            when x"0" => maskopen <= '0';
            when x"1" => 
                      if (wordHcnt < 8*8) and
                      ((wordVcnt < 10) or 
--                       (wordVcnt = 16))then
                       (wordVcnt = TRIG_LINE_NUM) or   --# 230608 move line position 230608
                       (wordVcnt = IMG_LINE_NUM))  then --# 230718 IMG Hz
                          maskopen <= '1';
                      else
                          maskopen <= '0';
                      end if;
            when x"2" => 
                      if (wordHcnt < 8*16) and
                         (wordVcnt < 16) then
                          maskopen <= '1';
                      else
                          maskopen <= '0';
                      end if;
            when others => maskopen <= '0';
        end case;

      -- ### video out
            ohsyn <= s2hsyn;
            ovsyn <= s2vsyn;
            ohcnt <= s2hcnt;
            ovcnt <= s2vcnt;
            osdd_d0 <= osdd;
            osdd_d1 <= osdd_d0;
            if reg_osd_en = '1' and maskopen = '1' then
                if osdd_d0 = '0' and osdd = '1' then -- left inside 1px
                 -- odata <= x"8000";               -- bright gray
                    odata <= conv_std_logic_vector(30000,16);
                elsif osdd = '1' then
                 -- odata <= x"F000";               -- white
                    odata <= conv_std_logic_vector(60000,16);
                elsif osdd_d0 = '1' then             -- right outside 2px
                 -- odata <= x"0008";               -- Black
                    odata <= conv_std_logic_vector(00001,16);
                else
                    odata <= s2data;
                end if;
            else
                odata <= s2data;
            end if;

    --
        end if;
    end process;

    process (dclk)
        variable intLsb : integer range 0 to 8-1 := 0; 
        variable intMsb : integer range 0 to 16-1 := 0; 
    begin
        if dclk'event and dclk='1' then
      --
        reg_sync_rcnt_0 <= i_reg_sync_rcnt;
        reg_sync_rcnt_1 <= reg_sync_rcnt_0;
        reg_sync_rcnt   <= reg_sync_rcnt_1;

        SynCheckCntStart <= s2vsyn and (not s1vsyn); -- v fall
        if SynCheckCntStart = '1' then
            SyncCheckCnt <= (others =>'0');
            SyncCheckDe  <= '1';
        else
            if SyncCheckCnt < 256-1 then
               SyncCheckCnt <= SyncCheckCnt + '1';
               SyncCheckDe  <= '1';
            else
               SyncCheckDe  <= '0';
            end if;
        end if;

        chgdet_osd_en <= i_chgdet_osd_en;
        chgdet_osd_da <= i_chgdet_osd_da;
        if chgdet_osd_en = '1' then
            chgdet_en_cnt <= chgdet_en_cnt + '1';
        else
            chgdet_en_cnt <= (others => '0');
        end if;

         intLsb :=  conv_integer(SyncCheckCnt(3-1 downto 0));
         intMsb :=  conv_integer(SyncCheckCnt(7-1 downto 3));
        case reg_osd_sel is
            when "00" => -- binNum <= (others => (others=>'0')); --# others default
                      frft_wea   <= SyncCheckDe;
                      frft_addra <= SyncCheckCnt;
                      frft_dina  <= conv_std_logic_vector(0, 16);
            when "01" =>
                      frft_wea   <= SyncCheckDe;
--                    frft_addra <= SyncCheckCnt;
                      frft_addra <= SyncCheckCnt(8-2 downto 3) & '0' & SyncCheckCnt(3-1 downto 0); -- font space is 16x16, write space 8x10
                      case intLsb is
                          when 0 => frft_dina <= conv_std_logic_vector(intMsb, 16);  --# line number
                          when 1 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (30 - 1 - intMsb) + 00 + 12 - 1 downto 32 * (30 - 1 - intMsb) + 00); --# h num 12'b
                          when 2 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (30 - 1 - intMsb) + 12 + 12 - 1 downto 32 * (30 - 1 - intMsb) + 12); --# v num 12'b
--                        when 3 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (30 - 1 - intMsb) + 24 + 08 - 1 downto 32 * (30 - 1 - intMsb) + 24); --# frame cnt 8'b
                          when 3 => 
                                    if reg_sync_rcnt(32 * (30 - 1 - intMsb) + 24 + 08 - 1)='0' then -- under 128 
                                        frft_dina <= x"0000" + reg_sync_rcnt(32 * (30 - 1 - intMsb) + 24 + 07 - 1 downto 32 * (30 - 1 - intMsb) + 24); --# frame cnt 8'b
                                    else  -- over 128 multy 8 #230608
                                        frft_dina <= x"0000" + (reg_sync_rcnt(32 * (30 - 1 - intMsb) + 24 + 07 - 1 downto 32 * (30 - 1 - intMsb) + 24) & "000"); --# x8 #230608
                                    end if;                                    
                          when 4 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (20 - 1 - intMsb) + 16 + 16 - 1 downto 32 * (20 - 1 - intMsb) + 16); --# average 16'b
                          when 5 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (20 - 1 - intMsb) + 00 + 16 - 1 downto 32 * (20 - 1 - intMsb) + 00); --# center 16'b
                          when 6 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (10 - 1 - intMsb) + 00 + 16 - 1 downto 32 * (10 - 1 - intMsb) + 00); --# smallest 16'b
                          when 7 => frft_dina <= x"0000" + reg_sync_rcnt(32 * (10 - 1 - intMsb) + 16 + 16 - 1 downto 32 * (10 - 1 - intMsb) + 16); --# biggest 16'b
                          when others => 
                      end case;
            when "10" =>
                      frft_wea   <= chgdet_osd_en;
                      frft_addra <= chgdet_en_cnt;
                      frft_dina  <= chgdet_osd_da;
            when others=>  -- 3 all 'F" write
                      frft_wea   <= SyncCheckDe;
                      frft_addra <= SyncCheckCnt;
                      frft_dina  <= (others=> '1'); -- conv_std_logic_vector(0, 16);
        end case;

        --
      end if;
    end process;

 bram_frame_font: blk_mem_16bx256
  PORT MAP (
    clka   => dclk,
    ena    => '1', --- reg_osd_en,
    wea(0) => frft_wea,
    addra  => frft_addra,
    dina   => frft_dina,
    clkb   => dclk,
    enb    => reg_osd_en,
    addrb  => frft_addrb,
    doutb  => frft_doutb
  );
    frft_addrb <= wordCnt;
   -- ####################################
   -- ### conversion BCD state machine ###
    SYNC_PROC : process (dclk)
    begin
        if (dclk'event and dclk = '1') then
    --
            stateSWT <= next_stateSWT;

            smStart <= s2vsyn and (not s1vsyn); -- v fall

            if stateSWT = stSWT_INCR then
                if incrCnt < x"FFFF" then
                    incrCnt <= incrCnt + '1';
                end if;
            else
                incrCnt <= (others => '0');
            end if;

            if stateSWT = stSWT_RDY then
                -- iBin     <= binNum(conv_integer(wordCnt));
                iBin     <= frft_doutb;
                binStart <= '1';
            else
                binStart <= '0';
            end if;

            if stateSWT = stSWT_ADDRINC then
                wordCnt <= wordCnt + '1';
            elsif stateSWT = stSWT_DONE then
                wordCnt <= (others=> '0'); -- it s for pre '+'.
            end if;

            if stateSWT = stSWT_WORD then
                bcd_wea <= '1';
                bcd_addra <= wordCnt;
                bcd_dina <= x"F" & 
                            oBcd(4 * 1 - 1 downto 4 * 0)&
                            oBcd(4 * 2 - 1 downto 4 * 1)&
                            oBcd(4 * 3 - 1 downto 4 * 2)&
                            oBcd(4 * 4 - 1 downto 4 * 3)&
                            oBcd(4 * 5 - 1 downto 4 * 4)&
                            x"F" & 
                            x"F" ;
            else
                bcd_wea   <= '0';
--              bcd_addra <= (others => '0');
--              bcd_dina  <= (others => '1'); 
                bcd_addra <=bcd_addra;
                bcd_dina  <= bcd_dina;
            end if;

    --
        end if;
    end process;

    OUTPUT_DECODE : process (stateSWT)
    begin
        if stateSWT = stSWT_DONE then
        -- <output>_i <= '1';
        end if;
    end process;

    NEXT_STATE_DECODE : process (stateSWT, smStart, incrCnt, wordCnt)
    begin
        next_stateSWT <= stateSWT;

        case (stateSWT) is
            when stSWT_IDLE =>
                if smStart = '1' then
                    next_stateSWT <= stSWT_RDY;
                end if;
            when stSWT_RDY =>
                next_stateSWT <= stSWT_INCR;
            when stSWT_INCR =>
                if  32 <= incrCnt then
                    next_stateSWT <= stSWT_WORD;
                end if;
            when stSWT_WORD =>
                if wordCnt < 256-1 then -- 8_value * 10_line
                    next_stateSWT <= stSWT_ADDRINC;
                else
                    next_stateSWT <= stSWT_DONE;
                end if;
            when stSWT_ADDRINC =>
                 next_stateSWT <= stSWT_ADDRINC0;
            when stSWT_ADDRINC0 =>
                 next_stateSWT <= stSWT_RDY;
            when stSWT_DONE =>
                next_stateSWT <= stSWT_IDLE;
            when others =>
                next_stateSWT <= stSWT_IDLE;
        end case;

    end process;

   -- ####################################
  -- u_VEC2DEC : vec2dec -- 1600 logic
  --   port map(
  --      clk   => dclk,
  --      i_vec => iBin,
  --      o_dec => oBcd
  --    );
    u_VEC2DEC : binary_bcd -- 600 logic
        port map (
            clk   => dclk,
            i_str => binStart,
            i_bin => iBin,
            o_bcd => oBcd
        );

bram_bcd : blk_mem_32b_16x16
  PORT MAP (
    clka  => dclk,
    ena   => reg_osd_en,
    wea(0)=> bcd_wea,
    addra => bcd_addra,
    dina  => bcd_dina,
    clkb  => dclk,
    enb   => reg_osd_en,
    addrb => bcd_addrb,
    doutb => bcd_doutb
  );
bcd_addrb <= wordVcnt(4 - 1 downto 0) & wordHcnt(7 - 1 downto 3);

    u_FONTROM : fontROM
        port map (
            clkA         => dclk,
            writeEnableA => '0',
            addrA        => font_addr,
            dataOutA     => font_out,
            dataInA      => (others=>'0')
        );

  --################
  --### out port ###
    o_reg_trigcnt   <= oreg_trigcnt;
    o_reg_totrigcnt <= oreg_totrigcnt;

    o_hsyn <= ohsyn;
    o_vsyn <= ovsyn;
    o_hcnt <= ohcnt;
    o_vcnt <= ovcnt;
    o_data <= odata;

  --##########
  --### ila###
--u_ila_osd : ila_osd
--PORT MAP (
--	clk        => dclk         ,
--	probe0 (0) => SyncCheckDe  , -- 1   
--	probe1     => SyncCheckCnt , -- 8   
--	probe2 (0) => chgdet_osd_en, -- 1   
--	probe3     => chgdet_en_cnt, -- 8   
--	probe4 (0) => frft_wea     , -- 1   
--	probe5     => frft_addra   , -- 8   
--	probe6     => frft_dina    , -- 16  
--	probe7     => frft_addrb   , -- 8   
--	probe8     => frft_doutb   , -- 16  
--	probe9 (0) => bcd_wea      , -- 1   
--	probe10    => bcd_addra    , -- 8   
--	probe11    => bcd_dina     , -- 32  
--	probe12    => bcd_addrb    , -- 8   
--	probe13    => bcd_doutb    , -- 32  
--	probe14(0) => binStart     , -- 1   
--	probe15    => iBin         , -- 16  
--	probe16    => oBcd         , -- 20  
--	probe17    => font_addr    , -- 8   
--	probe18    => font_out     , -- 8   
--	probe19(0) => ohsyn        , -- 1   
--	probe20(0) => ovsyn        , -- 1   
--	probe21    => ohcnt        , -- 12  
--	probe22    => ovcnt        , -- 12  
--	probe23    => odata          -- 16  
--);

end architecture behavioralosd;

--####################################################################################################
--####################################################################################################
--####################################################################################################

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.std_logic_arith.all;

entity binary_bcd is
    generic (
        bitbin : positive := 16;
        bitdec : positive := 5
    );
    port (
        clk   : in    std_logic;
        i_str : in    std_logic;
        i_bin : in    std_logic_vector(bitBin - 1 downto 0);
        o_bcd : out   std_logic_vector(bitDec * 4 - 1 downto 0)
    );
end entity binary_bcd;

architecture behaviour of binary_bcd is

    type   states is (start, shift, done);
    signal state      : states;
    signal state_next : states;

    signal binary      : std_logic_vector(bitBin - 1 downto 0);
    signal binary_next : std_logic_vector(bitBin - 1 downto 0);
    signal bcds        : std_logic_vector(19 downto 0);
    signal bcds_reg    : std_logic_vector(19 downto 0);
    signal bcds_next   : std_logic_vector(19 downto 0);
    -- output register keep output constant during conversion
    signal bcds_out_reg      : std_logic_vector(19 downto 0);
    signal bcds_out_reg_next : std_logic_vector(19 downto 0);
  -- need to keep track of shifts
    signal shift_counter      : natural range 0 to bitBin;
    signal shift_counter_next : natural range 0 to bitBin;
    signal str_0              : std_logic;
    signal str                : std_logic;
    signal bcds_zero          : std_logic_vector(19 downto 0);

begin

    process (clk)
    begin
        if clk'event and clk='1' then
            binary        <= binary_next;
            bcds          <= bcds_next;
            state         <= state_next;
            bcds_out_reg  <= bcds_out_reg_next;
            shift_counter <= shift_counter_next;
            str_0         <= i_str;
            if bcds_out_reg(5 * 4 - 1 downto 4 * 4) = x"0" then
            bcds_zero(5 * 4 - 1 downto 4 * 4) <= x"F"; else
                bcds_zero(5 * 4 - 1 downto 4 * 4) <= bcds_out_reg(5 * 4 - 1 downto 4 * 4);
            end if;
            if bcds_out_reg(5 * 4 - 1 downto 4 * 4) = x"0" and
         bcds_out_reg(4 * 4 - 1 downto 3 * 4) = x"0" then
            bcds_zero(4 * 4 - 1 downto 3 * 4) <= x"F"; else
                bcds_zero(4 * 4 - 1 downto 3 * 4) <= bcds_out_reg(4 * 4 - 1 downto 3 * 4);
            end if;
            if bcds_out_reg(5 * 4 - 1 downto 4 * 4) = x"0" and
         bcds_out_reg(4 * 4 - 1 downto 3 * 4) = x"0" and
         bcds_out_reg(3 * 4 - 1 downto 2 * 4) = x"0" then
            bcds_zero(3 * 4 - 1 downto 2 * 4) <= x"F"; else
                bcds_zero(3 * 4 - 1 downto 2 * 4) <= bcds_out_reg(3 * 4 - 1 downto 2 * 4);
            end if;
            if bcds_out_reg(5 * 4 - 1 downto 4 * 4) = x"0" and
         bcds_out_reg(4 * 4 - 1 downto 3 * 4) = x"0" and
         bcds_out_reg(3 * 4 - 1 downto 2 * 4) = x"0" and
         bcds_out_reg(2 * 4 - 1 downto 1 * 4) = x"0" then
            bcds_zero(2 * 4 - 1 downto 1 * 4) <= x"F"; else
                bcds_zero(2 * 4 - 1 downto 1 * 4) <= bcds_out_reg(2 * 4 - 1 downto 1 * 4);
            end if;
            bcds_zero(1 * 4 - 1 downto 0 * 4) <= bcds_out_reg(1 * 4 - 1 downto 0 * 4);
        end if;
    end process;

    str <= (not str_0) and i_str;

    process (state, binary, i_bin, bcds, bcds_reg, shift_counter)
    begin
        state_next         <= state;
        bcds_next          <= bcds;
        binary_next        <= binary;
        shift_counter_next <= shift_counter;

        case state is
            when start =>
                if str = '1' then
                    state_next <= shift;
                end if;
                binary_next        <= i_bin;
                bcds_next          <= (others => '0');
                shift_counter_next <= 0;
            when shift =>
                if shift_counter = bitBin then
                    state_next <= done;
                else
                    binary_next        <= binary(bitBin - 2 downto 0) & 'L';
                    bcds_next          <= bcds_reg(18 downto 0) & binary(bitBin - 1);
                    shift_counter_next <= shift_counter + 1;
                end if;
            when done =>
                state_next <= start;
        end case;

    end process;

    bcds_reg(19 downto 16) <= bcds(19 downto 16) + 3 when bcds(19 downto 16) > 4 else
                              bcds(19 downto 16);
    bcds_reg(15 downto 12) <= bcds(15 downto 12) + 3 when bcds(15 downto 12) > 4 else
                              bcds(15 downto 12);
    bcds_reg(11 downto  8) <= bcds(11 downto  8) + 3 when bcds(11 downto  8) > 4 else
                              bcds(11 downto  8);
    bcds_reg( 7 downto  4) <= bcds( 7 downto  4) + 3 when bcds( 7 downto  4) > 4 else
                              bcds( 7 downto  4);
    bcds_reg( 3 downto  0) <= bcds( 3 downto  0) + 3 when bcds( 3 downto  0) > 4 else
                              bcds( 3 downto  0);

    bcds_out_reg_next <= bcds when state = done else
                         bcds_out_reg;

    -- o_bcd <= bcds_out_reg;
    o_bcd <= bcds_zero;

end architecture behaviour;

--####################################################################################################
--######## https://allaboutfpga.com/vhdl-code-for-binary-to-bcd-converter/ ###########################
--####################################################################################################
--# 220210mbh

--library ieee;
--    use ieee.std_logic_1164.all;
--    use ieee.std_logic_unsigned.all;
--    use ieee.std_logic_arith.all;

--entity vec2dec is
--    port (
--        clk   : in    std_logic;
--        i_vec : in    std_logic_vector(16 - 1 downto 0);
--        o_dec : out   std_logic_vector(4*5 - 1 downto 0)
--    );
--end entity vec2dec;

--architecture behavioralvec2dec of vec2dec is

--    signal vec_d0  : std_logic_vector(16 - 1 downto 0);
--    signal vec_d1  : std_logic_vector(16 - 1 downto 0);
--    signal vec     : std_logic_vector(16 - 1 downto 0);
--    signal vecx    : std_logic_vector(16 - 1 downto 0);
--    signal vecxx   : std_logic_vector(16 - 1 downto 0);
--    signal vecxxx  : std_logic_vector(16 - 1 downto 0);
--    signal vecxxxx : std_logic_vector(16 - 1 downto 0);

--    signal dec_10000 : std_logic_vector(4 - 1 downto 0);
--    signal dec_1000  : std_logic_vector(4 - 1 downto 0);
--    signal dec_100   : std_logic_vector(4 - 1 downto 0);
--    signal dec_10    : std_logic_vector(4 - 1 downto 0);
--    signal dec_1     : std_logic_vector(4 - 1 downto 0);

--begin

--    process (clk)
--    begin
--        if clk'event and clk='1' then
--    --
--            vec_d0 <= i_vec;
--            vec_d1 <= vec_d0;
--            vec    <= vec_d1;
--     --
--        end if;
--    end process;

--    process (clk)
--    begin
--        if clk'event and clk='1' then
--    --
--            if    60000 <= vec then      dec_10000 <=x"6"; vecx    <= vec - 60000;
--            elsif 50000 <= vec then      dec_10000 <=x"5"; vecx    <= vec - 50000;
--            elsif 40000 <= vec then      dec_10000 <=x"4"; vecx    <= vec - 40000;
--            elsif 30000 <= vec then      dec_10000 <=x"3"; vecx    <= vec - 30000;
--            elsif 20000 <= vec then      dec_10000 <=x"2"; vecx    <= vec - 20000;
--            elsif 10000 <= vec then      dec_10000 <=x"1"; vecx    <= vec - 10000;
--            else                         dec_10000 <=x"F"; vecx    <= vec - 00000;
--            end if;

--            if    9000  <= vecx then     dec_1000  <=x"9"; vecxx   <= vecx - 9000;
--            elsif 8000  <= vecx then     dec_1000  <=x"8"; vecxx   <= vecx - 8000;
--            elsif 7000  <= vecx then     dec_1000  <=x"7"; vecxx   <= vecx - 7000;
--            elsif 6000  <= vecx then     dec_1000  <=x"6"; vecxx   <= vecx - 6000;
--            elsif 5000  <= vecx then     dec_1000  <=x"5"; vecxx   <= vecx - 5000;
--            elsif 4000  <= vecx then     dec_1000  <=x"4"; vecxx   <= vecx - 4000;
--            elsif 3000  <= vecx then     dec_1000  <=x"3"; vecxx   <= vecx - 3000;
--            elsif 2000  <= vecx then     dec_1000  <=x"2"; vecxx   <= vecx - 2000;
--            elsif 1000  <= vecx then     dec_1000  <=x"1"; vecxx   <= vecx - 1000;
--            else                                           vecxx   <= vecx - 0000;
--                if dec_10000 = x"F" then dec_1000  <=x"F"; else
--                dec_1000 <= x"0"; end if;
--            end if;

--            if    900   <= vecxx then    dec_100   <=x"9"; vecxxx  <= vecxx - 900;
--            elsif 800   <= vecxx then    dec_100   <=x"8"; vecxxx  <= vecxx - 800;
--            elsif 700   <= vecxx then    dec_100   <=x"7"; vecxxx  <= vecxx - 700;
--            elsif 600   <= vecxx then    dec_100   <=x"6"; vecxxx  <= vecxx - 600;
--            elsif 500   <= vecxx then    dec_100   <=x"5"; vecxxx  <= vecxx - 500;
--            elsif 400   <= vecxx then    dec_100   <=x"4"; vecxxx  <= vecxx - 400;
--            elsif 300   <= vecxx then    dec_100   <=x"3"; vecxxx  <= vecxx - 300;
--            elsif 200   <= vecxx then    dec_100   <=x"2"; vecxxx  <= vecxx - 200;
--            elsif 100   <= vecxx then    dec_100   <=x"1"; vecxxx  <= vecxx - 100;
--            else                                           vecxxx  <= vecxx - 000;
--                if dec_1000  = x"F" then dec_100   <=x"F"; else
--                dec_100 <= x"F"; end if;
--            end if;

--            if    90    <= vecxxx then   dec_10    <=x"9"; vecxxxx <= vecxxx - 90;
--            elsif 80    <= vecxxx then   dec_10    <=x"8"; vecxxxx <= vecxxx - 80;
--            elsif 70    <= vecxxx then   dec_10    <=x"7"; vecxxxx <= vecxxx - 70;
--            elsif 60    <= vecxxx then   dec_10    <=x"6"; vecxxxx <= vecxxx - 60;
--            elsif 50    <= vecxxx then   dec_10    <=x"5"; vecxxxx <= vecxxx - 50;
--            elsif 40    <= vecxxx then   dec_10    <=x"4"; vecxxxx <= vecxxx - 40;
--            elsif 30    <= vecxxx then   dec_10    <=x"3"; vecxxxx <= vecxxx - 30;
--            elsif 20    <= vecxxx then   dec_10    <=x"2"; vecxxxx <= vecxxx - 20;
--            elsif 10    <= vecxxx then   dec_10    <=x"1"; vecxxxx <= vecxxx - 10;
--            else                                           vecxxxx <= vecxxx - 00;
--                if dec_100   = x"F" then dec_10    <=x"F"; else
--                dec_10 <= x"F"; end if;
--            end if;

--            if    9     <= vecxxxx then  dec_1    <=x"9";
--            elsif 8     <= vecxxxx then  dec_1    <=x"8";
--            elsif 7     <= vecxxxx then  dec_1    <=x"7";
--            elsif 6     <= vecxxxx then  dec_1    <=x"6";
--            elsif 5     <= vecxxxx then  dec_1    <=x"5";
--            elsif 4     <= vecxxxx then  dec_1    <=x"4";
--            elsif 3     <= vecxxxx then  dec_1    <=x"3";
--            elsif 2     <= vecxxxx then  dec_1    <=x"2";
--            elsif 1     <= vecxxxx then  dec_1    <=x"1";
--            else                         dec_1    <=x"0";
--            end if;
--    --
--        end if;
--    end process;

--    o_dec <= dec_10000 & dec_1000 & dec_100 & dec_10 & dec_1;

--end architecture behavioralvec2dec;

--####################################################################################################
--###### https://github.com/tibor-electronics/vga_generator/blob/master/vga_text/font_rom.vhd ########
--####################################################################################################
-- ROM with synchonous read (inferring Block RAM)
-- character ROM
--   - 8-by-16 (8-by-2^4) font
--   - 128 (2^7) characters
--   - ROM size: 512-by-8 (2^11-by-8) bits
--               16K bits: 1 BRAM

-- Original Source: https://github.com/thelonious/vga_generator/tree/master/vga_text
-- NOTE: This is not the original. Cleaned up by MLM

-- VHDL'93 supports the full table of ISO-8859-1 characters (0x00 through 0xFF(255))
-- ISO-8859-1 Table: http://kireji.com/reference/iso88591.html

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

    -- Uncomment the following library declaration if using
    -- arithmetic functions with Signed or Unsigned values
    use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- note this line.The package is compiled to this directory by default.
-- so don't forget to include this directory.
-- library work;
-- this line also is must.This includes the particular package into your program.
-- use work.commonPak.all;

-- It is a ROM, but whatever.. you can write to it....

entity fontROM is
    generic (
        addrwidth : integer := 8;
        datawidth : integer := 8
    );
    port (
        clkA         : in    std_logic;
        writeEnableA : in    std_logic;
        addrA        : in    std_logic_vector(addrWidth - 1 downto 0);
        dataOutA     : out   std_logic_vector(dataWidth - 1 downto 0);
        dataInA      : in    std_logic_vector(dataWidth - 1 downto 0)
    );
end entity fontrom;

architecture behavioralfontrom of fontrom is

    type rom_type is array (0 to 2 ** addrWidth - 1) of std_logic_vector(dataWidth - 1 downto 0);

  signal ROM: rom_type := ( -- 2^11-by-8
  -- 0: code x30
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "01111100", -- 3  *****
  "11000110", -- 4 **   **
  "11000110", -- 5 **   **
  "11001110", -- 6 **  ***
  "11011110", -- 7 ** ****
  "11110110", -- 8 **** **
  "11100110", -- 9 ***  **
  "11000110", -- a **   **
  "11000110", -- b **   **
  "01111100", -- c  *****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- 1: code x31
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00011000", -- 3
  "00111000", -- 4
  "01111000", -- 5    **
  "00011000", -- 6   ***
  "00011000", -- 7  ****
  "00011000", -- 8    **
  "00011000", -- 9    **
  "00011000", -- a    **
  "00011000", -- b    **
  "01111110", -- c    **
  "00000000", -- d    **
  "00000000", -- e  ******
  "00000000", -- f
  -- 2: code x32
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "01111100", -- 3  *****
  "11000110", -- 4 **   **
  "00000110", -- 5      **
  "00001100", -- 6     **
  "00011000", -- 7    **
  "00110000", -- 8   **
  "01100000", -- 9  **
  "11000000", -- a **
  "11000110", -- b **   **
  "11111110", -- c *******
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- 3: code x33
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "01111100", -- 3  *****
  "11000110", -- 4 **   **
  "00000110", -- 5      **
  "00000110", -- 6      **
  "00111100", -- 7   ****
  "00000110", -- 8      **
  "00000110", -- 9      **
  "00000110", -- a      **
  "11000110", -- b **   **
  "01111100", -- c  *****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- 4: code x34
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00001100", -- 3     **
  "00011100", -- 4    ***
  "00111100", -- 5   ****
  "01101100", -- 6  ** **
  "11001100", -- 7 **  **
  "11111110", -- 8 *******
  "00001100", -- 9     **
  "00001100", -- a     **
  "00001100", -- b     **
  "00011110", -- c    ****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x35
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "11111110", -- 3 *******
  "11000000", -- 4 **
  "11000000", -- 5 **
  "11000000", -- 6 **
  "11111100", -- 7 ******
  "00000110", -- 8      **
  "00000110", -- 9      **
  "00000110", -- a      **
  "11000110", -- b **   **
  "01111100", -- c  *****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x36
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00111000", -- 3   ***
  "01100000", -- 4  **
  "11000000", -- 5 **
  "11000000", -- 6 **
  "11111100", -- 7 ******
  "11000110", -- 8 **   **
  "11000110", -- 9 **   **
  "11000110", -- a **   **
  "11000110", -- b **   **
  "01111100", -- c  *****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x37
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "11111110", -- 3 *******
  "11000110", -- 4 **   **
  "00000110", -- 5      **
  "00000110", -- 6      **
  "00001100", -- 7     **
  "00011000", -- 8    **
  "00110000", -- 9   **
  "00110000", -- a   **
  "00110000", -- b   **
  "00110000", -- c   **
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x38
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "01111100", -- 3  *****
  "11000110", -- 4 **   **
  "11000110", -- 5 **   **
  "11000110", -- 6 **   **
  "01111100", -- 7  *****
  "11000110", -- 8 **   **
  "11000110", -- 9 **   **
  "11000110", -- a **   **
  "11000110", -- b **   **
  "01111100", -- c  *****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x39
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "01111100", -- 3  *****
  "11000110", -- 4 **   **
  "11000110", -- 5 **   **
  "11000110", -- 6 **   **
  "01111110", -- 7  ******
  "00000110", -- 8      **
  "00000110", -- 9      **
  "00000110", -- a      **
  "00001100", -- b     **
  "01111000", -- c  ****
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x20
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00000000", -- 3
  "00000000", -- 4
  "00000000", -- 5
  "00000000", -- 6
  "00000000", -- 7
  "00000000", -- 8
  "00000000", -- 9
  "00011000", -- a
  "00111100", -- b
  "00011000", -- c point
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x20
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00000000", -- 3
  "00000000", -- 4
  "00000000", -- 5
  "00000000", -- 6
  "00000000", -- 7
  "00000000", -- 8
  "00000000", -- 9
  "00000000", -- a
  "00000000", -- b
  "00000000", -- c
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x20
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00000000", -- 3
  "00000000", -- 4
  "00000000", -- 5
  "00000000", -- 6
  "00000000", -- 7
  "00000000", -- 8
  "00000000", -- 9
  "00000000", -- a
  "00000000", -- b
  "00000000", -- c
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x20
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00000000", -- 3
  "00000000", -- 4
  "00000000", -- 5
  "00000000", -- 6
  "00000000", -- 7
  "00000000", -- 8
  "00000000", -- 9
  "00000000", -- a
  "00000000", -- b
  "00000000", -- c
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x20
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00000000", -- 3
  "00000000", -- 4
  "00000000", -- 5
  "00000000", -- 6
  "00000000", -- 7
  "00000000", -- 8
  "00000000", -- 9
  "00000000", -- a
  "00000000", -- b
  "00000000", -- c
  "00000000", -- d
  "00000000", -- e
  "00000000", -- f
  -- code x20
  "00000000", -- 0
  "00000000", -- 1
  "00000000", -- 2
  "00000000", -- 3
  "00000000", -- 4
  "00000000", -- 5
  "00000000", -- 6
  "00000000", -- 7
  "00000000", -- 8
  "00000000", -- 9
  "00000000", -- a
  "00000000", -- b
  "00000000", -- c
  "00000000", -- d
  "00000000", -- e
  "00000000"  -- f
  );

begin

  -- addr register to infer block RAM
    setRegA : process (clkA)
    begin
        if clkA'event and clkA = '1' then
      -- Write to rom
            if(writeEnableA = '1') then
                ROM(to_integer(unsigned(addrA))) <= dataInA;
            end if;
      -- Read from it
            dataOutA <= ROM(to_integer(unsigned(addrA)));
        end if;
    end process;

end architecture behavioralfontrom;
