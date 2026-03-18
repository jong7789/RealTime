----------------------------------------------------------------------------------
-- Company: DRT
-- Engineer: BH.Moon
-- Create Date: 2021/09/28 10:27:28
-- Module Name: ACC_PROC - Behavioral
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use WORK.TOP_HEADER.ALL;

entity ACC_PROC is
    port (
        i_clk : in    std_logic;

        i_reg_width  : in    std_logic_vector(11 downto 0);
        i_reg_height : in    std_logic_vector(11 downto 0);
        i_regAccCtrl : in    std_logic_vector(16 - 1 downto 0);
        o_regAccStat : out   std_logic_vector(16 - 1 downto 0);

        i_MmrHsyn : in    std_logic;
        i_MmrVsyn : in    std_logic;
        i_MmrHcnt : in    std_logic_vector(12 - 1 downto 0);
        i_MmrVcnt : in    std_logic_vector(12 - 1 downto 0);
        i_MmrData : in    std_logic_vector(16 - 1 downto 0);

        i_LivHsyn : in    std_logic;
        i_LivVsyn : in    std_logic;
        i_LivHcnt : in    std_logic_vector(12 - 1 downto 0);
        i_LivVcnt : in    std_logic_vector(12 - 1 downto 0);
        i_LivData : in    std_logic_vector(16 - 1 downto 0);

        oacc_wen   : out   std_logic;
        oacc_waddr : out   std_logic_vector(11 downto 0);
        oacc_wdata : out   std_logic_vector(15 downto 0);
        oacc_wvcnt : out   std_logic_vector(11 downto 0);

        o_chgdet_osd_en : out   std_logic;
        o_chgdet_osd_da : out   std_logic_vector(16 - 1 downto 0);

        o_hsyn : out   std_logic;
        o_vsyn : out   std_logic;
        o_hcnt : out   std_logic_vector(12 - 1 downto 0);
        o_vcnt : out   std_logic_vector(12 - 1 downto 0);
        o_data : out   std_logic_vector(16 - 1 downto 0)
    );
end entity acc_proc;

architecture behavioral of acc_proc is

    component change_detector
        port (
            clk              : in    std_logic;
            i_reg_width      : in    std_logic_vector(11 downto 0);
            i_reg_height     : in    std_logic_vector(11 downto 0);
            i_reg_chgdet_en  : in    std_logic;
            i_reg_chgdet_md  : in    std_logic;
            i_reg_chgSense   : in    std_logic_vector(4 - 1 downto 0);
            i_reg_AccPageLim : in    std_logic_vector(16 - 1 downto 0);
            o_reg_chgdet     : out   std_logic_vector(8 - 1 downto 0);
            o_chgdet_osd_en  : out   std_logic;
            o_chgdet_osd_da  : out   std_logic_vector(16 - 1 downto 0);
            i_Hsyn           : in    std_logic;
            i_Vsyn           : in    std_logic;
            i_Hcnt           : in    std_logic_vector(12 - 1 downto 0);
            i_Vcnt           : in    std_logic_vector(12 - 1 downto 0);
            i_Data           : in    std_logic_vector(16 - 1 downto 0);
            o_change         : out   std_logic
        );
    end component;

    component blk_u16d64
        port (
            clka  : in    std_logic;
            wea   : in    std_logic_vector(0 downto 0);
            addra : in    std_logic_vector(5 downto 0);
            dina  : in    std_logic_vector(15 downto 0);
            clkb  : in    std_logic;
            addrb : in    std_logic_vector(5 downto 0);
            doutb : out   std_logic_vector(15 downto 0)
        );
    end component;

    component mult_u16xu16
        port (
            CLK : in    std_logic;
            A   : in    std_logic_vector(15 downto 0);
            B   : in    std_logic_vector(15 downto 0);
            CE  : in    std_logic;
            P   : out   std_logic_vector(31 downto 0)
        );
    end component;

    component add_U32plusU16zU33
        port (
            A   : in    std_logic_vector(31 downto 0);
            B   : in    std_logic_vector(15 downto 0);
            CLK : in    std_logic;
            CE  : in    std_logic;
            S   : out   std_logic_vector(32 downto 0)
        );
    end component;

    component div_U33DivU16z
        port (
            aclk                   : in    std_logic;
            s_axis_divisor_tvalid  : in    std_logic;
            s_axis_divisor_tdata   : in    std_logic_vector(15 downto 0);
            s_axis_dividend_tvalid : in    std_logic;
            s_axis_dividend_tdata  : in    std_logic_vector(39 downto 0);
            m_axis_dout_tvalid     : out   std_logic;
            m_axis_dout_tdata      : out   std_logic_vector(55 downto 0)
        );
    end component;

    component blk_42x64
        port (
            clka  : in    std_logic;
            wea   : in    std_logic_vector(0 downto 0);
            addra : in    std_logic_vector(5 downto 0);
            dina  : in    std_logic_vector(41 downto 0);
            clkb  : in    std_logic;
            addrb : in    std_logic_vector(5 downto 0);
            doutb : out   std_logic_vector(41 downto 0)
        );
    end component;

    component ila_acc
        port (
            clk     : in    std_logic;
            probe0  : in    std_logic_vector(0 downto 0);
            probe1  : in    std_logic_vector(0 downto 0);
            probe2  : in    std_logic_vector(11 downto 0);
            probe3  : in    std_logic_vector(11 downto 0);
            probe4  : in    std_logic_vector(15 downto 0);
            probe5  : in    std_logic_vector(0 downto 0);
            probe6  : in    std_logic_vector(0 downto 0);
            probe7  : in    std_logic_vector(11 downto 0);
            probe8  : in    std_logic_vector(11 downto 0);
            probe9  : in    std_logic_vector(15 downto 0);
            probe10 : in    std_logic_vector(0 downto 0);
            probe11 : in    std_logic_vector(0 downto 0);
            probe12 : in    std_logic_vector(11 downto 0);
            probe13 : in    std_logic_vector(11 downto 0);
            probe14 : in    std_logic_vector(15 downto 0);
            probe15 : in    std_logic_vector(15 downto 0);
            probe16 : in    std_logic_vector(5 downto 0);
            probe17 : in    std_logic_vector(15 downto 0);
            probe18 : in    std_logic_vector(0 downto 0);
            probe19 : in    std_logic_vector(0 downto 0);
            probe20 : in    std_logic_vector(0 downto 0);
            probe21 : in    std_logic_vector(11 downto 0);
            probe22 : in    std_logic_vector(11 downto 0);
            probe23 : in    std_logic_vector(15 downto 0);
            probe24 : in    std_logic_vector(15 downto 0)
        );
    end component;

-- !comp
    signal clk : std_logic;

    type   type_reg16b is array (3 - 1 downto 0) of std_logic_vector(16 - 1 downto 0);
    signal regAccCtrlShft : type_reg16b;

    signal regAccCtrl    : std_logic_vector(15 downto 0);
    signal AccEn         : std_logic;
    signal AccPageLim    : std_logic_vector(15 downto 0);
    signal RegAccPageLim : std_logic_vector(15 downto 0);
    signal AccEn_Chg     : std_logic; -- # 220325mbh

    signal MmrData0  : std_logic_vector(15 downto 0);
    signal MmrData1  : std_logic_vector(15 downto 0);
    signal bm_addra1 : std_logic_vector(5 downto 0);

    signal bm_wea   : std_logic_vector(0 downto 0);
    signal bm_addra : std_logic_vector(5 downto 0);
    signal bm_dina  : std_logic_vector(15 downto 0);
    signal bm_addrb : std_logic_vector(5 downto 0);
    signal bm_doutb : std_logic_vector(15 downto 0);

    signal MmrVsyn0  : std_logic;
    signal MmrVsyn1  : std_logic;
    signal LivVsyn0  : std_logic;
    signal LivVsyn1  : std_logic;
    signal MmrVpCnt  : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal MmrVpCnt0 : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal MmrVpCnt1 : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal MmrVpCnt2 : std_logic_vector(8 - 1 downto 0):=(others=>'0');
    signal KeepVpCnt : std_logic_vector(6 - 1 downto 0):=(others=>'0');

    signal d0LivHsyn : std_logic;
    signal d0LivVsyn : std_logic;
    signal d0LivVcnt : std_logic_vector(12 - 1 downto 0);
    signal d0LivHcnt : std_logic_vector(12 - 1 downto 0);
    signal d0LivData : std_logic_vector(16 - 1 downto 0);
    signal d0MmrData : std_logic_vector(16 - 1 downto 0);

    signal d1LivHsyn : std_logic;
    signal d1LivVsyn : std_logic;
    signal d1LivVcnt : std_logic_vector(12 - 1 downto 0);
    signal d1LivHcnt : std_logic_vector(12 - 1 downto 0);
    signal d1LivData : std_logic_vector(16 - 1 downto 0);
    signal d1MmrData : std_logic_vector(16 - 1 downto 0);

    signal d2LivData : std_logic_vector(16 - 1 downto 0);

    signal LatAccEn              : std_logic;
    signal pageCnt               : std_logic_vector(16 - 1 downto 0);
    signal pageCntPlus           : std_logic_vector(16 - 1 downto 0);
    signal d2MmrPageData         : std_logic_vector(32 - 1 downto 0);
    signal d3MmrAddLivData       : std_logic_vector(33 - 1 downto 0);
    signal d38DivData            : std_logic_vector(56 - 1 downto 0);
    signal s_axis_dividend_tdata : std_logic_vector(39 downto 0);

    signal d39LivHsyn : std_logic;
    signal d39LivVsyn : std_logic;
    signal d39LivHcnt : std_logic_vector(12 - 1 downto 0);
    signal d39LivVcnt : std_logic_vector(12 - 1 downto 0);
    signal d39LivData : std_logic_vector(16 - 1 downto 0);
    signal d39AccData : std_logic_vector(16 - 1 downto 0);

    signal d40LivHsyn : std_logic;
    signal d40LivVsyn : std_logic;
    signal d40LivHcnt : std_logic_vector(12 - 1 downto 0);
    signal d40LivVcnt : std_logic_vector(12 - 1 downto 0);
    signal d40LivData : std_logic_vector(16 - 1 downto 0);
    signal d40AccData : std_logic_vector(16 - 1 downto 0);

    signal d38DivValid : std_logic;

    signal LivDly_addra : std_logic_vector( 6 - 1 downto 0):= (others=> '0');
    signal LivDly_dina  : std_logic_vector(42 - 1 downto 0):= (others=> '0');
    signal LivDly_addrb : std_logic_vector( 6 - 1 downto 0):= (others=> '0');
    signal LivDly_doutb : std_logic_vector(42 - 1 downto 0):= (others=> '0');

    signal AccEn_d0     : std_logic;
    signal AccEnChanged : std_logic;

    signal regChgDetEn : std_logic;
    signal regChgDetMd : std_logic;
    signal regChgSense : std_logic_vector(4 - 1 downto 0):= (others=> '0');
    signal chgdet      : std_logic;
    signal chgdet_d0   : std_logic;
    signal reg_chgdet  : std_logic_vector(8 - 1 downto 0):= (others=> '0');
    signal reg_AccStat : std_logic_vector(8 - 1 downto 0):= (others=> '0');

-- !begin

begin

    clk <= i_clk;
            
-- █▀█ █▀▀ █▀▀
-- █▀▄ ██▄ █▄█
    process (clk)
    begin
        if clk'event and clk='1' then
    --
            regAccCtrlShft <= regAccCtrlShft(regAccCtrlShft'high - 1 downto 0) & i_regAccCtrl;
            regAccCtrl     <= regAccCtrlShft(regAccCtrlShft'high);
            AccEn          <= regAccCtrl(0);
        --  AccDdrch       <= regAccCtrl(1);
            regChgDetEn    <= regAccCtrl(2);
            regChgDetMd    <= regAccCtrl(3);
            regChgSense    <= regAccCtrl(8 - 1 downto 4);

            case regAccCtrl(16 - 1 downto 8) is
                when x"00" =>  AccPageLim <= x"0000"; -- 0
                when x"01" =>  AccPageLim <= x"0001"; -- 2
                when x"02" =>  AccPageLim <= x"0003"; -- 4
                when x"03" =>  AccPageLim <= x"0007"; -- 8
                when x"04" =>  AccPageLim <= x"000F"; -- 16
                when x"05" =>  AccPageLim <= x"001F"; -- 32
                when x"06" =>  AccPageLim <= x"003F"; -- 64
                when x"07" =>  AccPageLim <= x"007F"; -- 128
                when x"08" =>  AccPageLim <= x"00FF"; -- 256
                when x"09" =>  AccPageLim <= x"01FF"; -- 512
                when x"0A" =>  AccPageLim <= x"03FF"; -- 1024
                when x"0B" =>  AccPageLim <= x"07FF"; -- 2048
                when x"0C" =>  AccPageLim <= x"0FFF"; -- 4096
                when x"0D" =>  AccPageLim <= x"1FFF"; -- 8192
                when x"0E" =>  AccPageLim <= x"3FFF"; -- 16384
                when x"0F" =>  AccPageLim <= x"7FFF"; -- 32768
                when others => AccPageLim <= x"FFFF"; -- 65535
            end case;

    --
        end if;
    end process;
                                                              
-- █▀▀ █░█ ▄▀█ █▄░█ █▀▀ █▀▀ ░ █▀▄ █▀▀ ▀█▀ █▀▀ █▀▀ ▀█▀ █ █▀█ █▄░█
-- █▄▄ █▀█ █▀█ █░▀█ █▄█ ██▄ ▄ █▄▀ ██▄ ░█░ ██▄ █▄▄ ░█░ █ █▄█ █░▀█
    RegAccPageLim <= AccPageLim;
    u_ChgDet : change_detector
        port map (
            clk              => clk,
            i_reg_width      => i_reg_width,
            i_reg_height     => i_reg_height,
            i_reg_chgdet_en  => regChgDetEn,
            i_reg_chgdet_md  => regChgDetMd,
            i_reg_chgSense   => regChgSense,
            i_reg_accPageLim => RegAccPageLim,
            o_reg_chgdet     => reg_chgdet,
            o_chgdet_osd_en  => o_chgdet_osd_en,
            o_chgdet_osd_da  => o_chgdet_osd_da,
            i_Hsyn           => i_LivHsyn,
            i_Vsyn           => i_LivVsyn,
            i_Hcnt           => i_LivHcnt,
            i_Vcnt           => i_LivVcnt,
            i_Data           => i_LivData,
            o_change         => chgdet -- change detected
        );
    o_regAccStat  <= reg_AccStat & reg_chgdet;

                   
-- ▄▀█ █░░ █ █▀▀ █▄░█
-- █▀█ █▄▄ █ █▄█ █░▀█
    process (clk)
    begin
        if clk'event and clk='1' then
    --
        -- # d0 <= in
            MmrVsyn0 <= i_MmrVsyn;
            LivVsyn0 <= i_LivVsyn;
            MmrData0 <= i_MmrData;

        -- # d1 <= d0
            MmrVsyn1 <= MmrVsyn0;
            LivVsyn1 <= LivVsyn0;
            if MmrVsyn1='0' and MmrVsyn0='1' then
                bm_addra1 <= (others=> '0');
            else
                bm_addra1 <= bm_addra1 + '1';
            end if;
            MmrData1 <= MmrData0;

    --
        end if;
    end process;

    bm_addra  <= bm_addra1;
    bm_dina   <= MmrData1;
    bm_wea(0) <= '1';
    u_blk_dataDelay : blk_u16d64
        port map (
            clka  => clk,
            wea   => bm_wea,
            addra => bm_addra,
            dina  => bm_dina,
            clkb  => clk,
            addrb => bm_addrb,
            doutb => bm_doutb
        );

    process (clk)
    begin
        if clk'event and clk='1' then
    --
            if MmrVsyn1='0' and MmrVsyn0='1' then
                MmrVpCnt <= (others=>'0');
            else
                if MmrVpCnt < x"FF" then
                    MmrVpCnt <= MmrVpCnt + '1';
                end if;
            end if;

            MmrVpCnt0 <= MmrVpCnt;
            MmrVpCnt1 <= MmrVpCnt0;
            MmrVpCnt2 <= MmrVpCnt1;
            if LivVsyn1='0' and LivVsyn0='1' then
                KeepVpCnt <= MmrVpCnt2(6 - 1 downto 0);
            end if;

            if MmrVpCnt = KeepVpCnt then
                bm_addrb <= (others => '0');
            else
                bm_addrb <= bm_addrb + '1';
            end if;

    --
        end if;
    end process;

-- ▄▀█ █▀▀ █▀▀
-- █▀█ █▄▄ █▄▄
    process (clk)
    begin
        if clk'event and clk='1' then
    --
         --# d0 <= in : aligned
            d0LivHsyn <= i_LivHsyn;
            d0LivVsyn <= i_LivVsyn;
            d0LivHcnt <= i_LivHcnt;
            d0LivVcnt <= i_LivVcnt;
            d0LivData <= i_LivData;
            d0MmrData <= bm_doutb;

         --# d1 <= d0 : page count
            d1LivHsyn <= d0LivHsyn;
            d1LivVsyn <= d0LivVsyn;
            d1LivHcnt <= d0LivHcnt;
            d1LivVcnt <= d0LivVcnt;
            d1LivData <= d0LivData;
            d2LivData <= d1LivData;
            d1MmrData <= d0MmrData;

-- mistake code 220405 mbh
--            AccEn_d0  <= AccEn;
--            if chgdet = '1' then
--                AccEnChanged <= '1';
--            elsif AccEn_d0='1' and  AccEn_Chg='0' then
--                AccEnChanged <= '1';
--            elsif d1LivVsyn='0' and d0LivVsyn='1' then
--                AccEnChanged <= '0';
--            end if;

--            if d1LivVsyn='0' and d0LivVsyn='1' then
--                LatAccEn <= AccEn_Chg;
--                if (LatAccEn = '0' and AccEn_Chg='1') or
--                    AccEnChanged = '1' then                 --# first page
--                    pageCnt <= x"0000";
--                elsif LatAccEn = '1' and AccEn_Chg='1' then --# incr page
--                    --if pageCnt < x"FFFE" then
--                    if pageCnt < AccPageLim then
--                        pageCnt <= pageCnt + '1';
--                    end if;
--                else
--                    pageCnt <= x"0000";
--                end if;
--            end if;
--            pageCntPlus <= pageCnt + '1';            
            
            
            AccEn_d0 <= AccEn;
            chgdet_d0 <= chgdet;
            if chgdet_d0='0' and chgdet = '1' then
                AccEnChanged <= '1';
            elsif AccEn_d0='1' and  AccEn='0' then
                AccEnChanged <= '1';
            elsif d1LivVsyn='0' and d0LivVsyn='1' then
                AccEnChanged <= '0';
            end if;
            
            if d1LivVsyn='0' and d0LivVsyn='1' then
                LatAccEn <= AccEn;
--                if (LatAccEn = '0' and AccEn='1') or
--                   AccEnChanged = '1' then    --# first page
                if  AccEnChanged = '1' then    --# first page
                    pageCnt <= x"0000";
                elsif LatAccEn = '1' and AccEn='1' then --# incr page
                    --if pageCnt < x"FFFE" then
                    if pageCnt < AccPageLim then
                        pageCnt <= pageCnt + '1';
                    end if;
                else
                    pageCnt <= x"0000";
                end if;
            end if;
            pageCntPlus <= pageCnt + '1';        
    --
        end if;
    end process;

  --# d2 <= d1 : MmrData x page
    u_MmrPage : mult_u16xu16
        port map (
            CLK => clk,
            A   => d1MmrData,
            B   => pageCnt,
            CE  => LatAccEn,
            P   => d2MmrPageData
        );

  --# d3 <= d2 : MmrPage + Live
    u_MmrAddLive : add_U32plusU16zU33
        port map (
            A   => d2MmrPageData,
            B   => d2LivData,
            CLK => clk,
            CE  => LatAccEn,
            S   => d3MmrAddLivData
        );

  --# d38 <= d3 : 35delay Sum div by pagePlus
    s_axis_dividend_tdata <= b"000_0000" & d3MmrAddLivData;
    u_sumDivPage : div_U33DivU16z
        port map (
            aclk                   => clk,
            s_axis_divisor_tvalid  => LatAccEn,
            s_axis_divisor_tdata   => pageCntPlus,
            s_axis_dividend_tvalid => LatAccEn,
            s_axis_dividend_tdata  => s_axis_dividend_tdata,
            m_axis_dout_tvalid     => d38DivValid,
            m_axis_dout_tdata      => d38DivData
        );
        
-- █▀▄ █▀▀ █░░ ▄▀█ █▄█
-- █▄▀ ██▄ █▄▄ █▀█ ░█░
    process (clk)
    begin
        if clk'event and clk='1' then
    --
            LivDly_addra <= LivDly_addra + '1';
            LivDly_dina  <= i_LivHsyn & i_LivVsyn & i_LivHcnt & i_LivVcnt & i_LivData;
            if LivDly_addra = 38 - 2 then
                LivDly_addrb <= (others=> '0');
            else
                LivDly_addrb <= LivDly_addrb + '1';
            end if;
    --
        end if;
    end process;

    u_LiveDelay : blk_42x64
        port map (
            clka   => clk,
            wea(0) => '1',
            addra  => LivDly_addra,
            dina   => LivDly_dina,
            clkb   => clk,
            addrb  => LivDly_addrb,
            doutb  => LivDly_doutb
        );
            
-- █▀█ █░█ ▀█▀
-- █▄█ █▄█ ░█░
    process (clk)
    begin
        if clk'event and clk='1' then
    --
      --# d39 <= d38
            d39LivHsyn <= LivDly_doutb(16 + 12 + 12 + 1);
            d39LivVsyn <= LivDly_doutb(16 + 12 + 12);
            d39LivHcnt <= LivDly_doutb(16 + 12 + 12 - 1 downto 16 + 12);
            d39LivVcnt <= LivDly_doutb(16 + 12 - 1 downto 16);
            d39LivData <= LivDly_doutb(16 - 1 downto 0);
            --# 220502 round process
            if d38DivData(16 - 1 downto 0) >= pageCntPlus(16-1 downto 1) then
                d39AccData <= d38DivData(16+16 - 1 downto 16) + '1';
            else
                d39AccData <= d38DivData(16+16 - 1 downto 16);
            end if;

      --# d40 <= d39 : selection
            if LatAccEn = '1' then
                d40LivHsyn <= d39LivHsyn;
                d40LivVsyn <= d39LivVsyn;
                d40LivHcnt <= d39LivHcnt;
                d40LivVcnt <= d39LivVcnt;
                d40LivData <= d39AccData;
            else
                d40LivHsyn <= d39LivHsyn;
                d40LivVsyn <= d39LivVsyn;
                d40LivHcnt <= d39LivHcnt;
                d40LivVcnt <= d39LivVcnt;
                d40LivData <= d39LivData;
            end if;

      --# out
            o_hsyn <= d40LivHsyn;
            o_vsyn <= d40LivVsyn;
            o_hcnt <= d40LivHcnt;
            o_vcnt <= d40LivVcnt;
            o_data <= d40LivData;

            oacc_wen   <= d40LivHsyn and LatAccEn;
            oacc_waddr <= d40LivHcnt;
            oacc_wdata <= d40LivData;
            oacc_wvcnt <= d40LivVcnt;

        --
        end if;
    end process;

--     u_ila_acc : ila_acc
--         port map (
--             clk        => clk,        --
--             probe0 (0) => i_MmrHsyn,  --
--             probe1 (0) => i_MmrVsyn,  --
--             probe2     => i_MmrHcnt,  -- 12
--             probe3     => i_MmrVcnt,  -- 12
--             probe4     => i_MmrData,  -- 16
--             probe5 (0) => i_LivHsyn,  --
--             probe6 (0) => i_LivVsyn,  --
--             probe7     => i_LivHcnt,  -- 12
--             probe8     => i_LivVcnt,  -- 12
--             probe9     => i_LivData,  -- 16
--             probe10(0) => d40LivHsyn, --
--             probe11(0) => d40LivVsyn, --
--             probe12    => d40LivHcnt, --  12
--             probe13    => d40LivVcnt, --  12
--             probe14    => d40LivData, --  16
--             probe15    => d40AccData, --  16
--             probe16    => KeepVpCnt,  --  6
--             probe17    => pageCnt,    --  16
--             probe18(0) => LatAccEn,   --
--             probe19(0) => d0LivHsyn,  --
--             probe20(0) => d0LivVsyn,  --
--             probe21    => d0LivVcnt,  -- 12
--             probe22    => d0LivHcnt,  -- 12
--             probe23    => d0LivData,  -- 16
--             probe24    => d0MmrData   -- 16
--         );

end architecture behavioral;
