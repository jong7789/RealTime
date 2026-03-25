library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity AVG_PROC is
    port (
        idata_clk          : in std_logic;
        idata_rstn         : in std_logic;

        ireg_avg_en        : in std_logic;
        ireg_avg_level     : in std_logic_vector(3 downto 0);
        oreg_avg_end       : out std_logic_vector(15 downto 0);

        iavg_rinfo         : in std_logic_vector(31 downto 0);
        iofs_rinfo         : in std_logic_vector(31 downto 0);
        id2m_xray          : in std_logic;
        id2m_dark          : in std_logic;
        iExtTrig_Srst      : in std_logic;

        ireg_mpc_posoffset : in std_logic_vector(16 - 1 downto 0);

        ihsync             : in std_logic;
        ivsync             : in std_logic;
        ihcnt              : in std_logic_vector(11 downto 0);
        ivcnt              : in std_logic_vector(11 downto 0);
        idata              : in std_logic_vector(15 downto 0);

        ostate_avg         : out tstate_avg;
        oframe_cnt         : out std_logic_vector(11 - 1 downto 0);

        oavg_wen           : out std_logic;
        oavg_waddr         : out std_logic_vector(11 downto 0);
        oavg_winfo         : out std_logic_vector(31 downto 0);
        oavg_wvcnt         : out std_logic_vector(11 downto 0)
    );
end entity AVG_PROC;

architecture Behavioral of AVG_PROC is

--     type tstate_avg                is    (
--                                         s_IDLE,
--                                         s_FWAIT,
--                                         s_LWAIT,
--                                         s_WAIT,
--                                         s_READY,
--                                         s_AVG,
--                                         s_CHECK
--                                     );

    signal state_avg : tstate_avg;

    signal sreg_avg_en_trig    : std_logic;
    signal sreg_avg_en_trigN   : std_logic;
    signal sreg_avg_en_trig_d1 : std_logic;

    signal sframe_cnt : std_logic_vector(10 downto 0);
    signal sframe_num : std_logic_vector(11 downto 0);

    signal squotient       : std_logic_vector(15 downto 0);
    signal sremainder      : std_logic_vector(15 downto 0);
    signal squotient_prev  : std_logic_vector(15 downto 0);
    signal sremainder_prev : std_logic_vector(15 downto 0);
    signal squotient_tmp   : std_logic_vector(16 downto 0);
    signal sremainder_tmp  : std_logic_vector(16 downto 0);
    signal squotient_curr  : std_logic_vector(16 downto 0);
    signal sremainder_curr : std_logic_vector(16 downto 0);

    signal savg_wen   : std_logic;
    signal savg_waddr : std_logic_vector(11 downto 0);
    signal savg_winfo : std_logic_vector(31 downto 0);

    signal sreg_avg_level    : std_logic_vector(3 downto 0);
    signal sreg_avg_level_1d : std_logic_vector(3 downto 0);
    signal sreg_avg_level_2d : std_logic_vector(3 downto 0);
    signal sreg_avg_level_3d : std_logic_vector(3 downto 0);

    signal sreg_avg_en    : std_logic;
    signal sreg_avg_en_1d : std_logic;
    signal sreg_avg_en_2d : std_logic;
    signal sreg_avg_en_3d : std_logic;

    signal savg_end : std_logic;

    signal squotient_prev_1d  : std_logic_vector(15 downto 0);
    signal sremainder_prev_1d : std_logic_vector(15 downto 0);
    signal squotient_prev_2d  : std_logic_vector(15 downto 0);
    signal sremainder_prev_2d : std_logic_vector(15 downto 0);
    signal squotient_prev_3d  : std_logic_vector(15 downto 0);
    signal sremainder_prev_3d : std_logic_vector(15 downto 0);
    signal squotient_prev_4d  : std_logic_vector(15 downto 0);
    signal sremainder_prev_4d : std_logic_vector(15 downto 0);

    signal shsync_1d : std_logic;
    signal shsync_2d : std_logic;
    signal shsync_3d : std_logic;
    signal shsync_4d : std_logic;
    signal shsync_5d : std_logic;
    signal shsync_6d : std_logic;
    signal shsync_7d : std_logic;
    signal svcnt_1d  : std_logic_vector(11 downto 0);
    signal svcnt_2d  : std_logic_vector(11 downto 0);
    signal svcnt_3d  : std_logic_vector(11 downto 0);
    signal svcnt_4d  : std_logic_vector(11 downto 0);
    signal svcnt_5d  : std_logic_vector(11 downto 0);
    signal svcnt_6d  : std_logic_vector(11 downto 0);
    signal svcnt_7d  : std_logic_vector(11 downto 0);
    signal svsync_1d : std_logic;
    signal svsync_2d : std_logic;
    signal svsync_3d : std_logic;
    signal svsync_4d : std_logic;
    signal svsync_5d : std_logic;
    signal svsync_6d : std_logic;
    signal svsync_7d : std_logic;

    signal sd2m_xray_1d : std_logic;
    signal sd2m_xray_2d : std_logic;
    signal sd2m_xray_3d : std_logic;
    signal sd2m_xray    : std_logic;
    signal sd2m_dark_1d : std_logic;
    signal sd2m_dark_2d : std_logic;
    signal sd2m_dark_3d : std_logic;
    signal sd2m_dark    : std_logic;
    signal sExtTrig_Srst_1d : std_logic;
    signal sExtTrig_Srst_2d : std_logic;
    signal sExtTrig_Srst_3d : std_logic;
    signal sExtTrig_Srst    : std_logic;

    signal sreg_mpc_posoffset_1d : std_logic_vector(16 - 1 downto 0);
    signal sreg_mpc_posoffset_2d : std_logic_vector(16 - 1 downto 0);
    signal sreg_mpc_posoffset_3d : std_logic_vector(16 - 1 downto 0);
    signal sreg_mpc_posoffset    : std_logic_vector(16 - 1 downto 0);

    signal sIdataOffset_d1 : std_logic_vector(17 - 1 downto 0);
    signal sdata_d1        : std_logic_vector(16 - 1 downto 0);
    signal sdata_d2        : std_logic_vector(16 - 1 downto 0);
    signal sSubdata_d2     : std_logic_vector(18 - 1 downto 0);
    signal sSubdataCut_d3  : std_logic_vector(16 - 1 downto 0);

    component ILA_AVG_PROC
    port (
        clk     : in STD_LOGIC;
        probe0  : in tstate_avg;
        probe1  : in STD_LOGIC_VECTOR(0 downto 0);
        probe2  : in STD_LOGIC_VECTOR(0 downto 0);
        probe3  : in STD_LOGIC_VECTOR(11 downto 0);
        probe4  : in STD_LOGIC_VECTOR(11 downto 0);
        probe5  : in STD_LOGIC_VECTOR(15 downto 0);
        probe6  : in STD_LOGIC_VECTOR(31 downto 0);
        probe7  : in STD_LOGIC_VECTOR(0 downto 0);
        probe8  : in STD_LOGIC_VECTOR(11 downto 0);
        probe9  : in STD_LOGIC_VECTOR(31 downto 0);
        probe10 : in STD_LOGIC_VECTOR(0 downto 0);
        probe11 : in STD_LOGIC_VECTOR(10 downto 0);
        probe12 : in STD_LOGIC_VECTOR(11 downto 0);
        probe13 : in STD_LOGIC_VECTOR(0 downto 0);
        probe14 : in STD_LOGIC_VECTOR(0 downto 0);
        probe15 : in STD_LOGIC_VECTOR(0 downto 0);
        probe16 : in STD_LOGIC_VECTOR(31 downto 0);
        probe17 : in STD_LOGIC_VECTOR(15 downto 0);
        probe18 : in STD_LOGIC_VECTOR(15 downto 0);
        probe19 : in STD_LOGIC_VECTOR(17 downto 0);
        probe20 : in STD_LOGIC_VECTOR(3 downto 0);
        probe21 : in STD_LOGIC_VECTOR(15 downto 0);
        probe22 : in STD_LOGIC_VECTOR(16 downto 0);
        probe23 : in STD_LOGIC_VECTOR(16 downto 0);
        probe24 : in STD_LOGIC_VECTOR(15 downto 0);
        probe25 : in STD_LOGIC_VECTOR(16 downto 0);
        probe26 : in STD_LOGIC_VECTOR(16 downto 0)
    );
    end component;

    component SUB_U17_U16
    port (
        A   : in  std_logic_vector(16 downto 0);
        B   : in  std_logic_vector(15 downto 0);
        CLK : in  std_logic;
        S   : out std_logic_vector(17 downto 0)
    );
    end component;

begin

    ostate_avg <= state_avg;
    oframe_cnt <= sframe_cnt;

    --# for D2 mode, prev value dosen't need.
    squotient_prev  <= (others => '0') when sd2m_xray = '1' else -- d2 mode 210629 mbh
                       iavg_rinfo(31 downto 16) when sframe_cnt > 0 else
                       (others => '0');
    sremainder_prev <= (others => '0') when sd2m_xray = '1' else -- d2 mode 210629 mbh
                       iavg_rinfo(15 downto 0) when sframe_cnt > 0 else
                       (others => '0');

    -- ##########################
    -- ### D2 ref minus block ###
    --# phase 1 <= in: offset addition and data latch
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sIdataOffset_d1 <= (others => '0'); -- 17
            else
                sIdataOffset_d1 <= ('0' & iofs_rinfo(31 downto 16)) + sreg_mpc_posoffset;
                sdata_d1 <= idata(15 downto 0);
            end if;
        end if;
    end process;

    --# phase 2 <= 1: subtractor instance and data delay
    U_SUB_U17_U16 : SUB_U17_U16 -- # 1 delay
    port map (
        CLK => idata_clk,
        A   => sIdataOffset_d1, -- 17
        B   => sdata_d1,
        S   => sSubdata_d2
    );

    --# phase 2 data delay register
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            sdata_d2 <= sdata_d1;
        end if;
    end process;

    --# phase 3 <= 2: D2M dark subtraction with saturation
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sSubdataCut_d3 <= (others => '0'); -- 16
            else
                --
                if sd2m_dark = '1' then
                    if sSubdata_d2(18 - 1) = '1' then    -- minus to zero
                        sSubdataCut_d3 <= (others => '0');
                    elsif sSubdata_d2(17 - 1) = '1' then -- over 16b
                        sSubdataCut_d3 <= (others => '1');
                    else
                        sSubdataCut_d3 <= sSubdata_d2(16 - 1 downto 0);
                    end if;
                else
                    sSubdataCut_d3 <= sdata_d2; -- default
                end if;
                --
            end if;
        end if;
    end process;
    -- ############# d2m update 210727 ####################
    -- ----------------------------------------------------

    --# phase 4 <= 3: quotient/remainder bit-shift division (Sequence 1, +1 Delay)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                squotient  <= (others => '0');
                sremainder <= (others => '0');
            else
                if (shsync_3d = '1') then
                    if sd2m_xray = '1' then -- exception for d2 xray, 210805 mbh
                        squotient  <= sSubdataCut_d3(15 downto 0);
                        sremainder <= (others => '0');
                    else
                        case (sreg_avg_level) is
                            when "0000" => squotient  <= sSubdataCut_d3(15 downto 0);
                                           sremainder <= (others => '0');
                            when "0001" => squotient  <= '0' & sSubdataCut_d3(15 downto 1);
                                           sremainder <= "000000000000000" & sSubdataCut_d3(0);
                            when "0010" => squotient  <= "00" & sSubdataCut_d3(15 downto 2);
                                           sremainder <= "00000000000000" & sSubdataCut_d3(1 downto 0);
                            when "0011" => squotient  <= "000" & sSubdataCut_d3(15 downto 3);
                                           sremainder <= "0000000000000" & sSubdataCut_d3(2 downto 0);
                            when "0100" => squotient  <= "0000" & sSubdataCut_d3(15 downto 4);
                                           sremainder <= "000000000000" & sSubdataCut_d3(3 downto 0);
                            when "0101" => squotient  <= "00000" & sSubdataCut_d3(15 downto 5);
                                           sremainder <= "00000000000" & sSubdataCut_d3(4 downto 0);
                            when "0110" => squotient  <= "000000" & sSubdataCut_d3(15 downto 6);
                                           sremainder <= "0000000000" & sSubdataCut_d3(5 downto 0);
                            when "0111" => squotient  <= "0000000" & sSubdataCut_d3(15 downto 7);
                                           sremainder <= "000000000" & sSubdataCut_d3(6 downto 0);
                            when "1000" => squotient  <= "00000000" & sSubdataCut_d3(15 downto 8);
                                           sremainder <= "00000000" & sSubdataCut_d3(7 downto 0);
                            when "1001" => squotient  <= "000000000" & sSubdataCut_d3(15 downto 9);
                                           sremainder <= "0000000" & sSubdataCut_d3(8 downto 0);
                            when "1010" => squotient  <= "0000000000" & sSubdataCut_d3(15 downto 10);
                                           sremainder <= "000000" & sSubdataCut_d3(9 downto 0);
                            when others => NULL;
                        end case;
                    end if;
                else
                    squotient  <= (others => '0');
                    sremainder <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --# phase 5 <= 4: accumulate quotient/remainder (Sequence 2, +1 Delay)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                squotient_tmp  <= (others => '0');
                sremainder_tmp <= (others => '0');
            else
                if (shsync_4d = '1') then
                    squotient_tmp  <= ('0' & squotient) + ('0' & squotient_prev_4d);
                    sremainder_tmp <= ('0' & sremainder) + ('0' & sremainder_prev_4d);
                else
                    squotient_tmp  <= (others => '0');
                    sremainder_tmp <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --# phase 6 <= 5: remainder carry and saturation (Sequence 3, +1 Delay)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                squotient_curr  <= (others => '0');
                sremainder_curr <= (others => '0');
            else
                if (shsync_5d = '1') then
                    if (sremainder_tmp >= sframe_num) then
                        if (squotient_tmp >= 65535) then
                            squotient_curr <= (others => '1');
                        else
                            squotient_curr <= squotient_tmp + '1';
                        end if;
                        sremainder_curr <= sremainder_tmp - ("00000" & sframe_num);
                    else
                        squotient_curr  <= squotient_tmp;
                        sremainder_curr <= sremainder_tmp;
                    end if;
                else
                    squotient_curr  <= (others => '0');
                    sremainder_curr <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    sreg_avg_en_trig  <= '1' when (sd2m_xray_2d = '1' and sd2m_xray_3d = '0') else       -- xray rising
                         '1' when sreg_avg_en_2d = '1' and (sd2m_dark_2d = '1' and sd2m_dark_3d = '0') else -- avg '1' and drak rising 210804 mbh
                         '1' when (sreg_avg_en_2d = '1' and sreg_avg_en_3d = '0') else
                         '1' when sExtTrig_Srst_2d = '1' and sExtTrig_Srst_3d = '0' else   -- save offset img Srst
                         '0';

    sreg_avg_en_trigN <= '1' when (sreg_avg_en_2d = '0' and sreg_avg_en_3d = '1') else -- reg Falling
                         '0';

    --# phase 7 <= 6: averaging state machine
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                state_avg  <= s_IDLE;
                sframe_cnt <= (others => '0');
                savg_wen   <= '0';
                savg_waddr <= (others => '0');
                savg_winfo <= (others => '0');
                savg_end   <= '1';
                sframe_num <= (others => '0');
            else
                -- sreg_avg_en_trig_d1 <= sreg_avg_en_trig;
                if sreg_avg_en_trig = '1' then -- srset for exttrig 211020 mbh
                    sreg_avg_en_trig_d1 <= '1';
                elsif sreg_avg_en_trig_d1 = '1' and savg_end = '1' then -- 211026mbh idle next
                    sreg_avg_en_trig_d1 <= '0';
                -- elsif sreg_avg_en_trig_d1='1' and sreg_avg_en_trigN = '1' then -- "Calcel" 211208mbh
                --     sreg_avg_en_trig_d1 <= '0';
                end if;

                -- if(sreg_avg_en_trig = '1') then --# 210728mbh
                --     state_avg <= s_IDLE;
                -- else
                case (state_avg) is
                    when s_IDLE =>
                        if (sreg_avg_en_trig_d1 = '1') then --# 210805, 210728mbh
                            state_avg <= s_FWAIT;
                            --sframe_cnt <= (others => '0');
                            savg_end <= '0';
                            case (sreg_avg_level_3d) is
                                when "0000" => sframe_num <= x"001";
                                when "0001" => sframe_num <= x"002";
                                when "0010" => sframe_num <= x"004";
                                when "0011" => sframe_num <= x"008";
                                when "0100" => sframe_num <= x"010";
                                when "0101" => sframe_num <= x"020";
                                when "0110" => sframe_num <= x"040";
                                when "0111" => sframe_num <= x"080";
                                when "1000" => sframe_num <= x"100";
                                when "1001" => sframe_num <= x"200";
                                when "1010" => sframe_num <= x"400";
                                when others => NULL;
                            end case;
                        end if;

                    when s_FWAIT =>
                        sframe_cnt <= (others => '0');
                        if (svsync_6d = '0') then
                            if (savg_end = '1') then
                                state_avg  <= s_WAIT;
                                savg_wen   <= '0';
                                savg_waddr <= (others => '0');
                                savg_winfo <= (others => '0');
                            else
                                state_avg  <= s_READY;
                                savg_wen   <= '1';
                                savg_waddr <= (others => '0');
                                savg_winfo <= squotient_curr(15 downto 0) & sremainder_curr(15 downto 0);
                            end if;
                        end if;

                    when s_READY =>
                        if sreg_avg_en_trigN = '1' then -- "CANCEL" 211208mbh
                        -- if sreg_avg_en_trig_d1 = '0' then -- "CANCEL" 211208mbh
                            state_avg  <= s_IDLE;
                            sframe_cnt <= (others => '0');
                        elsif (svsync_6d = '1') then -- FWAIT//READY modified 211026mbh
                        -- if(svsync_6d = '1') then -- FWAIT//READY modified 211026mbh
                            state_avg <= s_AVG;
                        end if;
                        --# first pixel offset data bug, added uderneath line #231101
                        savg_winfo <= squotient_curr(15 downto 0) & sremainder_curr(15 downto 0);
                        --# first pixel offset data bug, added uderneath line #231102
                        if (shsync_6d = '0') then
                            savg_wen <= '0';
                        else
                            savg_wen <= '1';
                        end if;

                    when s_AVG =>
                        if (shsync_6d = '0') then
                            if (svsync_6d = '0') then
                                state_avg <= s_CHECK;
                            else
                                state_avg <= s_LWAIT;
                            end if;
                            savg_wen   <= '0';
                            savg_waddr <= (others => '0');
                            savg_winfo <= (others => '0');
                        else
                            savg_wen   <= '1';
                            savg_waddr <= savg_waddr + '1';
                            savg_winfo <= squotient_curr(15 downto 0) & sremainder_curr(15 downto 0);
                        end if;

                    when s_LWAIT =>
                        if (shsync_6d = '1') then
                            state_avg  <= s_AVG;
                            savg_wen   <= '1';
                            savg_waddr <= (others => '0');
                            savg_winfo <= squotient_curr(15 downto 0) & sremainder_curr(15 downto 0);
                        end if;

                    when s_WAIT =>
                        if (shsync_6d = '0') then
                            state_avg <= s_IDLE;
                        end if;

                    when s_CHECK =>
                        if sd2m_xray = '1' then -- except d2m xray
--                            state_avg <= s_FWAIT; -- 210806 mbh
                            state_avg  <= s_IDLE;
                            savg_end   <= '0';
                            sframe_cnt <= sframe_cnt; -- not incre
                        elsif (sframe_cnt >= sframe_num - 1) then -- default, include d2m result
                            state_avg  <= s_FWAIT;
                            savg_end   <= '1';
                            --sframe_cnt <= (others => '0');
                        else
                            state_avg  <= s_READY;
                            sframe_cnt <= sframe_cnt + '1';
                        end if;

                    when others =>
                        NULL;
                end case;
                -- end if;
            --
            end if;
        end if;
    end process;

    -- ### phase 8 <= 7;
    oavg_wen   <= savg_wen;
    oavg_waddr <= savg_waddr;
    oavg_winfo <= savg_winfo;
    oavg_wvcnt <= svcnt_7d;

    oreg_avg_end <= sframe_cnt & b"0000" & savg_end;

    --# delay pipeline and CDC synchronizers
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                squotient_prev_1d  <= (others => '0');
                sremainder_prev_1d <= (others => '0');

                sreg_avg_en    <= '0';
                sreg_avg_en_1d <= '0';
                sreg_avg_en_2d <= '0';
                sreg_avg_en_3d <= '0';
                sreg_avg_level    <= (others => '0');
                sreg_avg_level_1d <= (others => '0');
                sreg_avg_level_2d <= (others => '0');
                sreg_avg_level_3d <= (others => '0');

                shsync_1d <= '0';
                shsync_2d <= '0';
                shsync_3d <= '0';
                shsync_4d <= '0';
                shsync_5d <= '0';
                shsync_6d <= '0';
                shsync_7d <= '0';
                svcnt_1d  <= (others => '0');
                svcnt_2d  <= (others => '0');
                svcnt_3d  <= (others => '0');
                svcnt_4d  <= (others => '0');
                svcnt_5d  <= (others => '0');
                svcnt_6d  <= (others => '0');
                svcnt_7d  <= (others => '0');
                svsync_1d <= '0';
                svsync_2d <= '0';
                svsync_3d <= '0';
                svsync_4d <= '0';
                svsync_5d <= '0';
                svsync_6d <= '0';
                svsync_7d <= '0';

                sreg_mpc_posoffset_1d <= (others => '0');
                sreg_mpc_posoffset_2d <= (others => '0');
                sreg_mpc_posoffset_3d <= (others => '0');
                sreg_mpc_posoffset    <= (others => '0');

            else
                squotient_prev_1d  <= squotient_prev;
                sremainder_prev_1d <= sremainder_prev;
                squotient_prev_2d  <= squotient_prev_1d;
                sremainder_prev_2d <= sremainder_prev_1d;
                squotient_prev_3d  <= squotient_prev_2d;
                sremainder_prev_3d <= sremainder_prev_2d;
                squotient_prev_4d  <= squotient_prev_3d;
                sremainder_prev_4d <= sremainder_prev_3d;

                -- ### d2 mode ###
                sd2m_xray_1d <= id2m_xray;
                sd2m_xray_2d <= sd2m_xray_1d;
                sd2m_xray_3d <= sd2m_xray_2d;
                sd2m_xray    <= sd2m_xray_3d;
                sd2m_dark_1d <= id2m_dark;
                sd2m_dark_2d <= sd2m_dark_1d;
                sd2m_dark_3d <= sd2m_dark_2d;
                sd2m_dark    <= sd2m_dark_3d;

                sExtTrig_Srst_1d <= iExtTrig_Srst;
                sExtTrig_Srst_2d <= sExtTrig_Srst_1d;
                sExtTrig_Srst_3d <= sExtTrig_Srst_2d;
                sExtTrig_Srst    <= sExtTrig_Srst_3d;

                sreg_avg_en    <= ireg_avg_en;
                sreg_avg_en_1d <= sreg_avg_en;
                sreg_avg_en_2d <= sreg_avg_en_1d;
                sreg_avg_en_3d <= sreg_avg_en_2d;
                sreg_avg_level    <= ireg_avg_level;
                sreg_avg_level_1d <= sreg_avg_level;
                sreg_avg_level_2d <= sreg_avg_level_1d;
                sreg_avg_level_3d <= sreg_avg_level_2d;

                shsync_1d <= ihsync;
                shsync_2d <= shsync_1d;
                shsync_3d <= shsync_2d;
                shsync_4d <= shsync_3d;
                shsync_5d <= shsync_4d;
                shsync_6d <= shsync_5d;
                shsync_7d <= shsync_6d;
                svcnt_1d  <= ivcnt;
                svcnt_2d  <= svcnt_1d;
                svcnt_3d  <= svcnt_2d;
                svcnt_4d  <= svcnt_3d;
                svcnt_5d  <= svcnt_4d;
                svcnt_6d  <= svcnt_5d;
                svcnt_7d  <= svcnt_6d;
                svsync_1d <= ivsync;
                svsync_2d <= svsync_1d;
                svsync_3d <= svsync_2d;
                svsync_4d <= svsync_3d;
                svsync_5d <= svsync_4d;
                svsync_6d <= svsync_5d;
                svsync_7d <= svsync_6d;

                sreg_mpc_posoffset_1d <= ireg_mpc_posoffset;
                sreg_mpc_posoffset_2d <= sreg_mpc_posoffset_1d;
                sreg_mpc_posoffset_3d <= sreg_mpc_posoffset_2d;
                sreg_mpc_posoffset    <= sreg_mpc_posoffset_3d;

            end if;
        end if;
    end process;

    SYNTH : if (GEN_ILA_avg = "ON") generate

        U0_ILA_AVG_PROC : ILA_AVG_PROC
        port map (
            clk        => idata_clk,
            probe0     => state_avg,
            probe1(0)  => ihsync,
            probe2(0)  => sreg_avg_en_trig, -- ivsync, mbh210712 test
            probe3     => ihcnt,
            probe4     => ivcnt,
            probe5     => idata,
            probe6     => iavg_rinfo,
            probe7(0)  => savg_wen,
            probe8     => savg_waddr,
            probe9     => iofs_rinfo,       -- 210727mbh
            probe10(0) => savg_end,
            probe11    => sframe_cnt,
            probe12    => sframe_num,
            probe13(0) => id2m_xray,        -- 1
            probe14(0) => id2m_dark,         -- 1
            probe15(0) => shsync_2d,         -- 1
            probe16    => savg_winfo,        -- 32
            probe17    => sdata_d2,          -- 16
            probe18    => sSubdataCut_d3,    -- 16
            probe19    => sSubdata_d2,       -- 18
            probe20    => sreg_avg_level,    -- 4
            probe21    => squotient,         -- 16
            probe22    => squotient_tmp,     -- 17
            probe23    => squotient_curr,    --
            probe24    => sremainder,        -- 16
            probe25    => sremainder_tmp,    -- 17
            probe26    => sremainder_curr    -- 17
        );

    end generate;

end Behavioral;
