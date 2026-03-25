library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity TEST_PATTERN is
port (
    iui_clk        : in  std_logic;
    iui_rstn       : in  std_logic;

    ireg_grab_en   : in  std_logic;
    ireg_frame_num : in  std_logic_vector(15 downto 0);
    ireg_tp_mode   : in  std_logic;
    ireg_tp_sel    : in  std_logic_vector(3 downto 0);
    ireg_tp_dtime  : in  std_logic_vector(15 downto 0);
    ireg_tp_value  : in  std_logic_vector(15 downto 0); --# 230717

    ireg_width     : in  std_logic_vector(11 downto 0);
    ireg_height    : in  std_logic_vector(11 downto 0);
    id2m_dark      : in  std_logic;

    ihsync         : in  std_logic;
    ivsync         : in  std_logic;
    ihcnt          : in  std_logic_vector(9 downto 0);
    ivcnt          : in  std_logic_vector(11 downto 0);
    idata          : in  std_logic_vector(63 downto 0);

    ohsync         : out std_logic;
    ovsync         : out std_logic;
    ohcnt          : out std_logic_vector(9 downto 0);
    ovcnt          : out std_logic_vector(11 downto 0);
    odata          : out std_logic_vector(63 downto 0);
    ostate_data    : out tstate_data_tpat
);
end TEST_PATTERN;

architecture Behavioral of TEST_PATTERN is

    constant DN04000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(4000, 16);
    constant DN05000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(5000, 16);
    constant DN08000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(8000, 16);
    constant DN20000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(20000, 16);
    constant DN30000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(30000, 16);
    constant DN45000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(45000, 16);
    constant DN55000 : std_logic_vector(15 downto 0) := conv_std_logic_vector(55000, 16);

--  type tstate_data_tpat is (
--      s_IDLE,
--      s_DATA,
--      s_LWAIT,
--      s_FWAIT
--  );

    signal state_data          : tstate_data_tpat := s_IDLE;

    signal sreg_grab_en        : std_logic;
    signal sreg_frame_num      : std_logic_vector(15 downto 0);
    signal sframe_grab_enable  : std_logic;

    signal sreg_tp_mode        : std_logic;
    signal sreg_tp_sel         : std_logic_vector(3 downto 0);
    signal sreg_tp_dtime       : std_logic_vector(15 downto 0);

    signal sreg_width          : std_logic_vector(9 downto 0);
    signal sreg_height         : std_logic_vector(11 downto 0);

    signal shsync2             : std_logic;
    signal svsync2             : std_logic;
    signal shcnt2              : std_logic_vector(9 downto 0);
    signal svcnt2              : std_logic_vector(11 downto 0);
    signal svsync_trig         : std_logic;

    signal swait_cnt           : std_logic_vector(15 downto 0);
    signal sframe_num_cnt      : std_logic_vector(15 downto 0);
    signal sframe_cnt          : std_logic_vector(15 downto 0);

    signal shsync              : std_logic;
    signal svsync              : std_logic;
    signal shcnt               : std_logic_vector(9 downto 0);
    signal svcnt               : std_logic_vector(11 downto 0);
    signal sramp_data0         : std_logic_vector(63 downto 0);
    signal sramp_data1         : std_logic_vector(63 downto 0);
    signal sramp_data2         : std_logic_vector(63 downto 0);
    signal sramp_data3         : std_logic_vector(63 downto 0);
    signal sramp_data4         : std_logic_vector(63 downto 0);
    signal sramp_data5         : std_logic_vector(63 downto 0);
    signal sramp_data6         : std_logic_vector(63 downto 0);
    signal window_data0        : std_logic_vector(15 downto 0);
    signal window_data1        : std_logic_vector(15 downto 0);

    signal sdata_tp            : std_logic_vector(63 downto 0);

    signal shsync_1d           : std_logic;
    signal svsync_1d           : std_logic;
    signal shcnt_1d            : std_logic_vector(9 downto 0);
    signal svcnt_1d            : std_logic_vector(11 downto 0);
    signal sdata_1d            : std_logic_vector(63 downto 0);
    signal shsync_2d           : std_logic;
    signal svsync_2d           : std_logic;
    signal shcnt_2d            : std_logic_vector(9 downto 0);
    signal svcnt_2d            : std_logic_vector(11 downto 0);
    signal sdata_2d            : std_logic_vector(63 downto 0);
    signal svsync_3d           : std_logic;
    signal sreg_grab_en_1d     : std_logic;

    signal reg_tp_value_1d     : std_logic_vector(15 downto 0);
    signal reg_tp_value_2d     : std_logic_vector(15 downto 0);
    signal reg_tp_value_3d     : std_logic_vector(15 downto 0);

    COMPONENT ila_tp
    PORT (
        clk     : IN STD_LOGIC;
        probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe2  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe3  : IN tstate_data_tpat;                  -- STD_LOGIC_VECTOR(1 DOWNTO 0);
        probe4  : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        probe5  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe6  : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        probe7  : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
        probe8  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe9  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe10 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe13 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe14 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
    END COMPONENT;

begin
--### debug for free tp sync 220503mbh
--u_ila_tp : ila_tp
--PORT MAP (
--  clk        => iui_clk            ,         -- 1
--  probe0(0)  => ireg_grab_en       ,         -- 1
--  probe1(0)  => svsync_3d          ,         -- 1
--  probe2(0)  => sframe_grab_enable ,         -- 1
--  probe3     => state_data         ,         -- 2
--  probe4     => sreg_width         ,         -- 10
--  probe5     => sreg_height        ,         -- 12
--  probe6     => shcnt2             ,         -- 10
--  probe7     => svcnt2             ,         -- 12
--  probe8     => swait_cnt          ,         -- 16
--  probe9     => sreg_tp_dtime      ,         -- 16
--  probe10(0) => shsync2            ,         -- 1
--  probe11(0) => svsync2            ,         -- 1
--  probe12(0) => sreg_tp_mode       ,         -- 1
--  probe13(0) => shsync             ,         -- 1
--  probe14(0) => svsync                       -- 1
--);

    ostate_data <= state_data;

    --# Register synchronization: latch config registers on vsync inactive
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sreg_grab_en   <= '0';
                sreg_frame_num <= (others => '0');
                sreg_tp_mode   <= '1';
                sreg_tp_sel    <= (others => '0');
                sreg_tp_dtime  <= (others => '0');
                sreg_width     <= (others => '0');
                sreg_height    <= (others => '0');
            else
                if(svsync_3d = '0') then
                    sreg_grab_en   <= ireg_grab_en;
                    sreg_frame_num <= ireg_frame_num;
                    sreg_tp_mode   <= ireg_tp_mode;
                    if ireg_tp_sel /= 0 and id2m_dark = '1' then -- It's for d2m test, mbh210809
                        sreg_tp_sel <= x"A";
                    else
                        sreg_tp_sel <= ireg_tp_sel;
                    end if;
                    sreg_tp_dtime  <= ireg_tp_dtime;
                    sreg_width     <= ireg_width(11 downto 2);
                    sreg_height    <= ireg_height;
                end if;
            end if;
        end if;
    end process;

    --# Test pattern state machine: IDLE -> DATA -> LWAIT/FWAIT cycle
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                state_data         <= s_IDLE;
                sframe_grab_enable <= '0';
                sframe_num_cnt     <= (others => '0');
                shsync2            <= '0';
                svsync2            <= '0';
                shcnt2             <= (others => '0');
                svcnt2             <= (others => '0');
                swait_cnt          <= (others => '0');
            else
                if(sreg_grab_en = '1' and sreg_grab_en_1d = '0') then
                    sframe_grab_enable <= '1';
                end if;

                case (state_data) is
                    when s_IDLE  =>
                        if(sframe_grab_enable = '1') then
                            state_data <= s_DATA;
                            shsync2    <= '1';
                            svsync2    <= '1';
                        else
                            shsync2    <= '0';
                            svsync2    <= '0';
                        end if;
                        shcnt2    <= (others => '0');
                        svcnt2    <= (others => '0');
                        swait_cnt <= (others => '0');

                    when s_DATA  =>
                        if(shcnt2 = sreg_width - 1) then
                            if(svcnt2 = sreg_height - 1) then
                                state_data <= s_FWAIT;
                                shsync2    <= '0';
                                svsync2    <= '0';
                                shcnt2     <= (others => '0');
                                svcnt2     <= (others => '0');
                            else
                                state_data <= s_LWAIT;
                                shsync2    <= '0';
                                svsync2    <= '1';
                                shcnt2     <= (others => '0');
                                svcnt2     <= svcnt2 + '1';
                            end if;
                        else
                            shsync2 <= '1';
                            svsync2 <= '1';
                            shcnt2  <= shcnt2 + '1';
                        end if;

                    when s_LWAIT =>
                        if(swait_cnt = sreg_tp_dtime - 1) then
                            state_data <= s_DATA;
                            swait_cnt  <= (others => '0');
                            shsync2    <= '1';
                        else
                            swait_cnt <= swait_cnt + '1';
                            shsync2   <= '0';
                        end if;

                    when s_FWAIT =>
                        if(swait_cnt = sreg_width + sreg_tp_dtime - 1) then
                            if(sreg_frame_num = 0) then
                                if(sreg_grab_en = '1') then
                                    sframe_grab_enable <= '1';
                                else
                                    sframe_grab_enable <= '0';
                                end if;
                            else
                                if(sframe_num_cnt = sreg_frame_num - 1) then
                                    sframe_num_cnt     <= (others => '0');
                                    sframe_grab_enable <= '0';
                                else
                                    sframe_num_cnt     <= sframe_num_cnt + '1';
                                end if;
                            end if;
                            state_data <= s_IDLE;
                            swait_cnt  <= (others => '0');
                        else
                            swait_cnt <= swait_cnt + '1';
                        end if;
                end case;
            end if;
        end if;
    end process;

    --# Sync mux: select between external sync and internal test pattern sync
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                shsync <= '0';
                svsync <= '0';
                shcnt  <= (others => '0');
                svcnt  <= (others => '0');
            else
                if(sreg_tp_mode = '0') then
                    shsync <= ihsync;
                    svsync <= ivsync;
                    shcnt  <= ihcnt;
                    svcnt  <= ivcnt;
                else
                    shsync <= shsync2;
                    svsync <= svsync2;
                    shcnt  <= shcnt2;
                    svcnt  <= svcnt2;
                end if;
            end if;
        end if;
    end process;

    svsync_trig <= not svsync and svsync_1d;

    --# Ramp/window test pattern data generation
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sramp_data0 <= (others => '0');
                sramp_data1 <= (others => '0');
                sramp_data2 <= (others => '0');
                sramp_data3 <= (others => '0');
                sramp_data4 <= (others => '0');
                sramp_data5 <= (others => '0');
            else
                sramp_data0 <= (("0000" & svcnt) + ("00" & shcnt & "11"))
                             & (("0000" & svcnt) + ("00" & shcnt & "10"))
                             & (("0000" & svcnt) + ("00" & shcnt & "01"))
                             & (("0000" & svcnt) + ("00" & shcnt & "00"));

                sramp_data1 <= (shcnt(7 downto 0) & "11" & "000000")
                             & (shcnt(7 downto 0) & "10" & "000000")
                             & (shcnt(7 downto 0) & "01" & "000000")
                             & (shcnt(7 downto 0) & "00" & "000000");

                sramp_data2 <= ((sframe_cnt(7 downto 0) & x"00") + (shcnt(7 downto 0) & "11" & "000000"))
                             & ((sframe_cnt(7 downto 0) & x"00") + (shcnt(7 downto 0) & "10" & "000000"))
                             & ((sframe_cnt(7 downto 0) & x"00") + (shcnt(7 downto 0) & "01" & "000000"))
                             & ((sframe_cnt(7 downto 0) & x"00") + (shcnt(7 downto 0) & "00" & "000000"));

                sramp_data3 <= (svcnt(7 downto 0) & x"00")
                             & (svcnt(7 downto 0) & x"00")
                             & (svcnt(7 downto 0) & x"00")
                             & (svcnt(7 downto 0) & x"00");

                sramp_data4 <= ((sframe_cnt(7 downto 0) & x"00") + (svcnt(7 downto 0) & x"00"))
                             & ((sframe_cnt(7 downto 0) & x"00") + (svcnt(7 downto 0) & x"00"))
                             & ((sframe_cnt(7 downto 0) & x"00") + (svcnt(7 downto 0) & x"00"))
                             & ((sframe_cnt(7 downto 0) & x"00") + (svcnt(7 downto 0) & x"00"));

                sramp_data5 <= (shcnt(8 downto 0) & "11" & "00000")
                             & (shcnt(8 downto 0) & "10" & "00000")
                             & (shcnt(8 downto 0) & "01" & "00000")
                             & (shcnt(8 downto 0) & "00" & "00000");

                if shcnt = 32 / 4 and svcnt = 100 then
                    sramp_data6 <= (others => '0');
                elsif svcnt = 100 then                     -- continuous line 100,101/200,202
                    sramp_data6 <= (others => '0');
                elsif svcnt = 101 then
                    sramp_data6 <= (others => '0');
                elsif svcnt = 200 then
                    sramp_data6 <= (others => '0');
                elsif svcnt = 202 then
                    sramp_data6 <= (others => '0');
                elsif shcnt = 100 / 4 then
                    sramp_data6 <= x"FFFF" & x"0000" & x"FFFF" & x"0000";
                elsif shcnt = 200 / 4 then
                    sramp_data6 <= x"FFFF" & x"0000" & x"0000" & x"FFFF";
                else
                    sramp_data6 <= (others => '1');
                end if;

                if 500 < svcnt and svcnt < 1000 and
                   500 / 4 < shcnt and shcnt < 1000 / 4 then
                    window_data0 <= conv_std_logic_vector(4444, 16);
                else
                    window_data0 <= conv_std_logic_vector(2222, 16);
                end if;

                if svcnt = shcnt then
                    window_data1 <= conv_std_logic_vector(1111, 16);
                elsif 500 < svcnt and svcnt < 1000 and
                   500 / 4 < shcnt and shcnt < 1000 / 4 then
                    window_data1 <= conv_std_logic_vector(8888, 16);
                else
                    window_data1 <= conv_std_logic_vector(4444, 16);
                end if;
            end if;
        end if;
    end process;

    --# Test pattern selector: frame counter and tp_sel mux
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sframe_cnt <= (others => '0');
                sdata_tp   <= (others => '0');
            else
                if(svsync_trig = '1') then
                    sframe_cnt <= sframe_cnt + '1';
                end if;

                case (sreg_tp_sel) is
                    when x"0"   => sdata_tp <= sdata_2d;
                    when x"1"   => sdata_tp <= (DN30000 + x"0800") & (DN30000 + x"0400") & (DN30000 + x"0200") & (DN30000 + x"0000");
                    when x"2"   => sdata_tp <= (DN05000 + x"0800") & (DN05000 + x"0400") & (DN05000 + x"0200") & (DN05000 + x"0000");
                    when x"3"   => sdata_tp <= (DN55000 + x"0800") & (DN55000 + x"0400") & (DN55000 + x"0200") & (DN55000 + x"0000");
                    when x"4"   => sdata_tp <= sramp_data1;
                    when x"5"   => sdata_tp <= sramp_data2;
                    when x"6"   => sdata_tp <= sramp_data3;
                    when x"7"   => sdata_tp <= sramp_data4;
                    when x"8"   => sdata_tp <= sramp_data6;                    -- 210811mbh test; sramp_data0;
                    when x"9"   => sdata_tp <= (sramp_data5(63 downto 48) + x"0200") & (sramp_data5(47 downto 32) + x"0100") & (sramp_data5(31 downto 16) + x"0080") & (sramp_data5(15 downto 0) + x"0040");
                    when x"A"   => sdata_tp <= (DN04000 + x"0200") & (DN04000 + x"0100") & (DN04000 + x"0080") & (DN04000 + x"0040");
                    when x"B"   => sdata_tp <= (DN08000 + x"0200") & (DN08000 + x"0100") & (DN08000 + x"0080") & (DN08000 + x"0040");
                    when x"C"   => sdata_tp <= (DN20000 + x"0200") & (DN20000 + x"0100") & (DN20000 + x"0080") & (DN20000 + x"0040");
                    when x"D"   => sdata_tp <= (DN30000 + x"0200") & (DN30000 + x"0100") & (DN30000 + x"0080") & (DN30000 + x"0040");
--                  when x"A"   => sdata_tp <= (DN04000 + x"0000") & (DN04000 + x"0000") & (DN04000 + x"0000") & (DN04000 + x"0000");
--                  when x"B"   => sdata_tp <= (DN08000 + x"0000") & (DN08000 + x"0000") & (DN08000 + x"0000") & (DN08000 + x"0000");
--                  when x"C"   => sdata_tp <= (DN20000 + x"0000") & (DN20000 + x"0000") & (DN20000 + x"0000") & (DN20000 + x"0000");
--                  when x"D"   => sdata_tp <= (DN30000 + x"0000") & (DN30000 + x"0000") & (DN30000 + x"0000") & (DN30000 + x"0000");
--                  when x"E"   => sdata_tp <= (DN45000 + x"0200") & (DN45000 + x"0100") & (DN45000 + x"0080") & (DN45000 + x"0040");
--                  when x"D"   => sdata_tp <= x"0190019001900190";
--                  when x"E"   => sdata_tp <= window_data0 & window_data0 & window_data0 & window_data0;
                    when others => sdata_tp <= reg_tp_value_3d & reg_tp_value_3d & reg_tp_value_3d & reg_tp_value_3d;
                end case;
            end if;
        end if;
    end process;

    ohsync <= shsync_2d;
    ovsync <= svsync_2d;
    ohcnt  <= shcnt_2d;
    ovcnt  <= svcnt_2d;
    odata  <= sdata_tp;

    --# Pipeline delay: 2-stage sync/data delay and register edge detect
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                shsync_1d       <= '0';
                svsync_1d       <= '0';
                shcnt_1d        <= (others => '0');
                svcnt_1d        <= (others => '0');
                sdata_1d        <= (others => '0');
                shsync_2d       <= '0';
                svsync_2d       <= '0';
                shcnt_2d        <= (others => '0');
                svcnt_2d        <= (others => '0');
                sdata_2d        <= (others => '0');
                svsync_3d       <= '0';
                sreg_grab_en_1d <= '0';
                reg_tp_value_1d <= (others => '0');
                reg_tp_value_2d <= (others => '0');
                reg_tp_value_3d <= (others => '0');
            else
                shsync_1d       <= shsync;
                svsync_1d       <= svsync;
                shcnt_1d        <= shcnt;
                svcnt_1d        <= svcnt;
                sdata_1d        <= idata;
                shsync_2d       <= shsync_1d;
                svsync_2d       <= svsync_1d;
                shcnt_2d        <= shcnt_1d;
                svcnt_2d        <= svcnt_1d;
                sdata_2d        <= sdata_1d;
                svsync_3d       <= svsync_2d;
                sreg_grab_en_1d <= sreg_grab_en;
                reg_tp_value_1d <= ireg_tp_value;
                reg_tp_value_2d <= reg_tp_value_1d;
                reg_tp_value_3d <= reg_tp_value_2d;
            end if;
        end if;
    end process;

end Behavioral;
