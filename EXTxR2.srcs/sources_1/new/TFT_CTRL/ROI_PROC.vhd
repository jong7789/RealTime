library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity ROI_PROC is
port (
    iui_clk           : in  std_logic;
    iui_rstn          : in  std_logic;

    ireg_img_mode     : in  std_logic_vector(2 downto 0);
    ireg_offsetx      : in  std_logic_vector(11 downto 0);
    ireg_offsety      : in  std_logic_vector(11 downto 0);
    ireg_width        : in  std_logic_vector(11 downto 0);
    ireg_height       : in  std_logic_vector(11 downto 0);

    ihsync            : in  std_logic;
    ivsync            : in  std_logic;
    ihcnt             : in  std_logic_vector(9 downto 0);
    ivcnt             : in  std_logic_vector(11 downto 0);
    idata             : in  std_logic_vector(63 downto 0);

    ohsync            : out std_logic;
    ovsync            : out std_logic;
    ohcnt             : out std_logic_vector(9 downto 0);
    ovcnt             : out std_logic_vector(11 downto 0);
    odata             : out std_logic_vector(63 downto 0);

    ostate_dpram_roi  : out tstate_dpram_roi
);
end ROI_PROC;

architecture Behavioral of ROI_PROC is

    component MULTI_16x15
    port (
        clk : in  std_logic;
        ce  : in  std_logic;
        --* a           : in    std_logic_vector(15 downto 0);
        --* p           : out   std_logic_vector(30 downto 0)
        --* jhkim
        a   : in  std_logic_vector(17 downto 0);
        p   : out std_logic_vector(32 downto 0)
    );
    end component;

    -- component DPRAM_64x768_256x192
    component DPRAM_64x960_256x240 -- 210623 for 3840 width
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(9 downto 0);
        dina  : in  std_logic_vector(63 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(7 downto 0);
        doutb : out std_logic_vector(255 downto 0)
    );
    end component;

--  type tstate_dpram_roi       is (
--                                      s_IDLE,
--                                      s_WAIT,
--                                      s_DATA
--                                  );

    signal state_dpram          : tstate_dpram_roi;

    signal sena                 : std_logic;
    signal saddra               : std_logic_vector(9 downto 0);
    signal sdina                : std_logic_vector(63 downto 0);

    signal senb                 : std_logic;
    signal saddrb               : std_logic_vector(7 downto 0);
    signal sdoutb               : std_logic_vector(255 downto 0) := (others => '0');
    --# 230515 data delay
    signal sdoutbx              : std_logic_vector(255 downto 0) := (others => '0');

    signal swr_end_trig         : std_logic;

    signal shsync               : std_logic;
    signal svsync               : std_logic;
    signal shcnt                : std_logic_vector(9 downto 0);
    signal svcnt                : std_logic_vector(11 downto 0);
    type tdata_sum              is array (0 to 3) of std_logic_vector(17 downto 0);
    --* jhkim
    type tdata_div              is array (0 to 3) of std_logic_vector(32 downto 0);
    signal sdata_sum_1x1_tmp    : tdata_sum;
    signal sdata_sum_2x2_tmp    : tdata_sum;
    signal sdata_sum_3x3_tmp    : tdata_sum;
    signal sdata_sum_4x4_tmp    : tdata_sum;
    signal sdata_sum_1x1        : tdata_sum;
    signal sdata_sum_2x2        : tdata_sum;
    signal sdata_sum_3x3        : tdata_sum;
    signal sdata_sum_4x4        : tdata_sum;

    signal smulti_p             : tdata_div;

    signal shsync_out           : std_logic;
    signal svsync_out           : std_logic;
    signal shcnt_out            : std_logic_vector(9 downto 0);
    signal svcnt_out            : std_logic_vector(11 downto 0);
    signal sdata_out            : std_logic_vector(63 downto 0);

    signal sreg_img_mode        : std_logic_vector(2 downto 0);
    signal sreg_offsetx         : std_logic_vector(9 downto 0);
    signal sreg_width           : std_logic_vector(9 downto 0);
    signal sreg_height          : std_logic_vector(11 downto 0);

    signal sena_1d              : std_logic;
    signal shsync_1d            : std_logic;
    signal shsync_2d            : std_logic;
    signal shsync_3d            : std_logic;
    signal shsync_4d            : std_logic;
    signal shsync_5d            : std_logic;
    signal shsync_6d            : std_logic;
    signal svsync_1d            : std_logic;
    signal svsync_2d            : std_logic;
    signal svsync_3d            : std_logic;
    signal svsync_4d            : std_logic;
    signal svsync_5d            : std_logic;
    signal svsync_6d            : std_logic;
    signal shcnt_1d             : std_logic_vector(9 downto 0);
    signal shcnt_2d             : std_logic_vector(9 downto 0);
    signal shcnt_3d             : std_logic_vector(9 downto 0);
    signal shcnt_4d             : std_logic_vector(9 downto 0);
    signal shcnt_5d             : std_logic_vector(9 downto 0);
    signal shcnt_6d             : std_logic_vector(9 downto 0);
    signal svcnt_1d             : std_logic_vector(11 downto 0);
    signal svcnt_2d             : std_logic_vector(11 downto 0);
    signal svcnt_3d             : std_logic_vector(11 downto 0);
    signal svcnt_4d             : std_logic_vector(11 downto 0);
    signal svcnt_5d             : std_logic_vector(11 downto 0);
    signal svcnt_6d             : std_logic_vector(11 downto 0);
    signal sdoutb_1d            : std_logic_vector(255 downto 0);
    signal sdata_sum_1x1_tmp_1d : tdata_sum;
    signal sdata_sum_2x2_tmp_1d : tdata_sum;
    signal sdata_sum_3x3_tmp_1d : tdata_sum;
    signal sdata_sum_4x4_tmp_1d : tdata_sum;
    signal sdata_sum_1x1_tmp_2d : tdata_sum;
    signal sdata_sum_2x2_tmp_2d : tdata_sum;
    signal sdata_sum_3x3_tmp_2d : tdata_sum;
    signal sdata_sum_4x4_tmp_2d : tdata_sum;
    signal sdata_sum_1x1_tmp_3d : tdata_sum;
    signal sdata_sum_2x2_tmp_3d : tdata_sum;
    signal sdata_sum_3x3_tmp_3d : tdata_sum;
    signal sdata_sum_4x4_tmp_3d : tdata_sum;

    signal vsync0               : std_logic;
    signal vsync1               : std_logic;
    signal vtrig                : std_logic;

    signal vtrig_latch          : std_logic;
    signal swr_end_trig_latch   : std_logic;

begin

    ostate_dpram_roi <= state_dpram;

    --# Input data latch and vsync edge detect
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sena   <= '0';
                saddra <= (others => '0');
                sdina  <= (others => '0');
            else
                sena   <= ihsync;
                saddra <= ihcnt;
                sdina  <= idata;
                --# v sync involve
                vsync0 <= ivsync;
                vsync1 <= vsync0;
            end if;
        end if;
    end process;

    -- U0_DPRAM_64x768_256x192 : DPRAM_64x768_256x192
    U0_DPRAM_64x960_256x240 : DPRAM_64x960_256x240
    port map (
        clka  => iui_clk,
        ena   => sena,
        wea   => '1',
        addra => saddra,
        dina  => sdina,
        clkb  => iui_clk,
        enb   => senb,
        addrb => saddrb,
        doutb => sdoutbx
    );

    swr_end_trig <= not sena and sena_1d;
    vtrig        <= vsync0 and not vsync1;

    --# DPRAM read state machine: IDLE -> WAIT -> DATA cycle
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                state_dpram <= s_IDLE;

                senb        <= '0';
                saddrb      <= (others => '0');

                shsync      <= '0';
                svsync      <= '0';
                shcnt       <= (others => '0');
                svcnt       <= (others => '0');
            else
                if(vtrig = '1') then
                    vtrig_latch <= '1';
                end if;

                if(swr_end_trig = '1') then
                    swr_end_trig_latch <= '1';
                end if;

                case (state_dpram) is
                    when s_IDLE  =>
--                                    if (vtrig = '1') then --# v sync Syncronizing #230919
                        if(vtrig_latch = '1') then --# v sync Syncronizing #230919
                            state_dpram <= s_WAIT;
                            vtrig_latch <= '0';
                        end if;

                    when s_WAIT  =>
--                                    if(swr_end_trig = '1') then
                        if(swr_end_trig_latch = '1') then
                            state_dpram        <= s_DATA;
                            swr_end_trig_latch <= '0';

                            senb    <= '1';
                            saddrb  <= sreg_offsetx(9 downto 2);

                            shsync  <= '1';
                            svsync  <= '1';
                            shcnt   <= (others => '0');
                        end if;

                    when s_DATA  =>
                        if(shcnt >= sreg_width - 1) then -- ">=" prevent stuck 211123
                            if(svcnt >= sreg_height - 1) then -- ">=" prevent stuck 211123
                                state_dpram <= s_IDLE;
                                svsync      <= '0';
                                svcnt       <= (others => '0');
                            else
                                state_dpram <= s_WAIT;
                                svcnt       <= svcnt + '1';
                            end if;

                            senb   <= '0';
                            saddrb <= (others => '0');

                            shsync <= '0';
                            shcnt  <= (others => '0');
                        else
                            shcnt <= shcnt + '1';
                            if(sreg_img_mode(2 downto 1) = 0 and shcnt(1 downto 0) = 3) then
                                saddrb <= saddrb + '1';
                            elsif(sreg_img_mode(2 downto 1) = 1 and shcnt(0) = '1') then
                                saddrb <= saddrb + '1';
                            elsif(sreg_img_mode(2 downto 1) = 2 and shcnt(1 downto 0) /= 3) then
                                saddrb <= saddrb + '1';
                            elsif(sreg_img_mode(2 downto 1) = 3) then
                                saddrb <= saddrb + '1';
                            end if;
                        end if;
                    when others  =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    --# Pixel sum calculation for 1x1/2x2/3x3/4x4 binning modes
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sdata_sum_1x1_tmp <= (others => (others => '0'));
                sdata_sum_2x2_tmp <= (others => (others => '0'));
                sdata_sum_3x3_tmp <= (others => (others => '0'));
                sdata_sum_4x4_tmp <= (others => (others => '0'));
            else
                sdoutb <= sdoutbx; --# datat dalay for compile 230515
                -- if(shcnt_1d(1 downto 0) = 0) then
                if(shcnt_2d(1 downto 0) = 0) then --# datat dalay for compile 230515
                    sdata_sum_1x1_tmp(0) <= ("00" & sdoutb(015 downto 000));
                    sdata_sum_1x1_tmp(1) <= ("00" & sdoutb(031 downto 016));
                    sdata_sum_1x1_tmp(2) <= ("00" & sdoutb(047 downto 032));
                    sdata_sum_1x1_tmp(3) <= ("00" & sdoutb(063 downto 048));

                    sdata_sum_2x2_tmp(0) <= ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_2x2_tmp(1) <= ("00" & sdoutb(063 downto 048)) + ("00" & sdoutb(047 downto 032));
                    sdata_sum_2x2_tmp(2) <= ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    sdata_sum_2x2_tmp(3) <= ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096));

                    sdata_sum_3x3_tmp(0) <= ("00" & sdoutb(047 downto 032)) + ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_3x3_tmp(1) <= ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064)) + ("00" & sdoutb(063 downto 048));
                    sdata_sum_3x3_tmp(2) <= ("00" & sdoutb(143 downto 128)) + ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096));
                    sdata_sum_3x3_tmp(3) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160)) + ("00" & sdoutb(159 downto 144));

                    sdata_sum_4x4_tmp(0) <= ("00" & sdoutb(063 downto 048)) + ("00" & sdoutb(047 downto 032)) + ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_4x4_tmp(1) <= ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096)) + ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    sdata_sum_4x4_tmp(2) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160)) + ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128));
                    sdata_sum_4x4_tmp(3) <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224)) + ("00" & sdoutb(223 downto 208)) + ("00" & sdoutb(207 downto 192));
                elsif(shcnt_2d(1 downto 0) = 1) then --# datat dalay for compile 230515
                    sdata_sum_1x1_tmp(0) <= ("00" & sdoutb(079 downto 064));
                    sdata_sum_1x1_tmp(1) <= ("00" & sdoutb(095 downto 080));
                    sdata_sum_1x1_tmp(2) <= ("00" & sdoutb(111 downto 096));
                    sdata_sum_1x1_tmp(3) <= ("00" & sdoutb(127 downto 112));

                    sdata_sum_2x2_tmp(0) <= ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128));
                    sdata_sum_2x2_tmp(1) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160));
                    sdata_sum_2x2_tmp(2) <= ("00" & sdoutb(223 downto 208)) + ("00" & sdoutb(207 downto 192));
                    sdata_sum_2x2_tmp(3) <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224));

                    sdata_sum_3x3_tmp(0) <= ("00" & sdoutb_1d(239 downto 224)) + ("00" & sdoutb_1d(223 downto 208)) + ("00" & sdoutb_1d(207 downto 192));
                    sdata_sum_3x3_tmp(1) <= ("00" & sdoutb(031 downto 016))    + ("00" & sdoutb(015 downto 000))    + ("00" & sdoutb_1d(255 downto 240));
                    sdata_sum_3x3_tmp(2) <= ("00" & sdoutb(079 downto 064))    + ("00" & sdoutb(063 downto 048))    + ("00" & sdoutb(047 downto 032));
                    sdata_sum_3x3_tmp(3) <= ("00" & sdoutb(127 downto 112))    + ("00" & sdoutb(111 downto 096))    + ("00" & sdoutb(095 downto 080));

                    sdata_sum_4x4_tmp(0) <= ("00" & sdoutb(063 downto 048)) + ("00" & sdoutb(047 downto 032)) + ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_4x4_tmp(1) <= ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096)) + ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    sdata_sum_4x4_tmp(2) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160)) + ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128));
                    sdata_sum_4x4_tmp(3) <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224)) + ("00" & sdoutb(223 downto 208)) + ("00" & sdoutb(207 downto 192));
                elsif(shcnt_2d(1 downto 0) = 2) then --# datat dalay for compile 230515
                    sdata_sum_1x1_tmp(0) <= ("00" & sdoutb(143 downto 128));
                    sdata_sum_1x1_tmp(1) <= ("00" & sdoutb(159 downto 144));
                    sdata_sum_1x1_tmp(2) <= ("00" & sdoutb(175 downto 160));
                    sdata_sum_1x1_tmp(3) <= ("00" & sdoutb(191 downto 176));

                    sdata_sum_2x2_tmp(0) <= ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_2x2_tmp(1) <= ("00" & sdoutb(063 downto 048)) + ("00" & sdoutb(047 downto 032));
                    sdata_sum_2x2_tmp(2) <= ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    sdata_sum_2x2_tmp(3) <= ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096));

                    sdata_sum_3x3_tmp(0) <= ("00" & sdoutb_1d(175 downto 160)) + ("00" & sdoutb_1d(159 downto 144)) + ("00" & sdoutb_1d(143 downto 128));
                    sdata_sum_3x3_tmp(1) <= ("00" & sdoutb_1d(223 downto 208)) + ("00" & sdoutb_1d(207 downto 192)) + ("00" & sdoutb_1d(191 downto 176));
                    sdata_sum_3x3_tmp(2) <= ("00" & sdoutb(015 downto 000))    + ("00" & sdoutb_1d(255 downto 240)) + ("00" & sdoutb_1d(239 downto 224));
                    sdata_sum_3x3_tmp(3) <= ("00" & sdoutb(063 downto 048))    + ("00" & sdoutb(047 downto 032))    + ("00" & sdoutb(031 downto 016));

                    sdata_sum_4x4_tmp(0) <= ("00" & sdoutb(063 downto 048)) + ("00" & sdoutb(047 downto 032)) + ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_4x4_tmp(1) <= ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096)) + ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    sdata_sum_4x4_tmp(2) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160)) + ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128));
                    sdata_sum_4x4_tmp(3) <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224)) + ("00" & sdoutb(223 downto 208)) + ("00" & sdoutb(207 downto 192));
                else
                    sdata_sum_1x1_tmp(0) <= ("00" & sdoutb(207 downto 192));
                    sdata_sum_1x1_tmp(1) <= ("00" & sdoutb(223 downto 208));
                    sdata_sum_1x1_tmp(2) <= ("00" & sdoutb(239 downto 224));
                    sdata_sum_1x1_tmp(3) <= ("00" & sdoutb(255 downto 240));

                    sdata_sum_2x2_tmp(0) <= ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128));
                    sdata_sum_2x2_tmp(1) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160));
                    sdata_sum_2x2_tmp(2) <= ("00" & sdoutb(223 downto 208)) + ("00" & sdoutb(207 downto 192));
                    sdata_sum_2x2_tmp(3) <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224));

                    --* org
                    --* sdata_sum_3x3_tmp(0)    <= ("00" & sdoutb(111 downto 096)) + ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    --* sdata_sum_3x3_tmp(1)    <= ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128)) + ("00" & sdoutb(127 downto 112));
                    --* sdata_sum_3x3_tmp(2)    <= ("00" & sdoutb(207 downto 192)) + ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160));
                    --* sdata_sum_3x3_tmp(3)    <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224)) + ("00" & sdoutb(223 downto 208));

                    --* jhkim
                    sdata_sum_3x3_tmp(0) <= ("00" & sdoutb_1d(111 downto 096)) + ("00" & sdoutb_1d(095 downto 080)) + ("00" & sdoutb_1d(079 downto 064));
                    sdata_sum_3x3_tmp(1) <= ("00" & sdoutb_1d(159 downto 144)) + ("00" & sdoutb_1d(143 downto 128)) + ("00" & sdoutb_1d(127 downto 112));
                    sdata_sum_3x3_tmp(2) <= ("00" & sdoutb_1d(207 downto 192)) + ("00" & sdoutb_1d(191 downto 176)) + ("00" & sdoutb_1d(175 downto 160));
                    sdata_sum_3x3_tmp(3) <= ("00" & sdoutb_1d(255 downto 240)) + ("00" & sdoutb_1d(239 downto 224)) + ("00" & sdoutb_1d(223 downto 208));

                    sdata_sum_4x4_tmp(0) <= ("00" & sdoutb(063 downto 048)) + ("00" & sdoutb(047 downto 032)) + ("00" & sdoutb(031 downto 016)) + ("00" & sdoutb(015 downto 000));
                    sdata_sum_4x4_tmp(1) <= ("00" & sdoutb(127 downto 112)) + ("00" & sdoutb(111 downto 096)) + ("00" & sdoutb(095 downto 080)) + ("00" & sdoutb(079 downto 064));
                    sdata_sum_4x4_tmp(2) <= ("00" & sdoutb(191 downto 176)) + ("00" & sdoutb(175 downto 160)) + ("00" & sdoutb(159 downto 144)) + ("00" & sdoutb(143 downto 128));
                    sdata_sum_4x4_tmp(3) <= ("00" & sdoutb(255 downto 240)) + ("00" & sdoutb(239 downto 224)) + ("00" & sdoutb(223 downto 208)) + ("00" & sdoutb(207 downto 192));
                end if;
            end if;
        end if;
    end process;

    MUL_DATA_GEN : for i in 0 to 3 generate
    begin
        U0_MULTI_16x15 : MULTI_16x15
        port map (
            clk => iui_clk,
            ce  => iui_rstn,
            --* a           => sdata_sum_3x3_tmp(i)(15 downto 0),
            --# a           => sdata_sum_3x3_tmp_1d(i)(17 downto 0),
            --# retiming 230515
            a   => sdata_sum_3x3_tmp(i)(17 downto 0),
            p   => smulti_p(i)
        );

    end generate;

    --# Binning sum output register
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sdata_sum_1x1 <= (others => (others => '0'));
                sdata_sum_2x2 <= (others => (others => '0'));
                sdata_sum_3x3 <= (others => (others => '0'));
                sdata_sum_4x4 <= (others => (others => '0'));
            else
                -- sdata_sum_1x1       <= sdata_sum_1x1_tmp_3d;
                -- sdata_sum_2x2       <= sdata_sum_2x2_tmp_3d;
                -- sdata_sum_3x3       <= sdata_sum_3x3_tmp_3d;
                -- sdata_sum_4x4       <= sdata_sum_4x4_tmp_3d;
                --# 230515
                sdata_sum_1x1 <= sdata_sum_1x1_tmp_2d;
                sdata_sum_2x2 <= sdata_sum_2x2_tmp_2d;
                sdata_sum_3x3 <= sdata_sum_3x3_tmp_2d;
                sdata_sum_4x4 <= sdata_sum_4x4_tmp_2d;
            end if;
        end if;
    end process;

    --# Binning sum pipeline delay
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sdata_sum_1x1_tmp_1d <= (others => (others => '0'));
                sdata_sum_1x1_tmp_2d <= (others => (others => '0'));
                sdata_sum_1x1_tmp_3d <= (others => (others => '0'));
                sdata_sum_2x2_tmp_1d <= (others => (others => '0'));
                sdata_sum_2x2_tmp_2d <= (others => (others => '0'));
                sdata_sum_2x2_tmp_3d <= (others => (others => '0'));
                sdata_sum_3x3_tmp_1d <= (others => (others => '0'));
                sdata_sum_3x3_tmp_2d <= (others => (others => '0'));
                sdata_sum_3x3_tmp_3d <= (others => (others => '0'));
                sdata_sum_4x4_tmp_1d <= (others => (others => '0'));
                sdata_sum_4x4_tmp_2d <= (others => (others => '0'));
                sdata_sum_4x4_tmp_3d <= (others => (others => '0'));
            else
                sdata_sum_1x1_tmp_1d <= sdata_sum_1x1_tmp;
                sdata_sum_1x1_tmp_2d <= sdata_sum_1x1_tmp_1d;
                sdata_sum_1x1_tmp_3d <= sdata_sum_1x1_tmp_2d;
                sdata_sum_2x2_tmp_1d <= sdata_sum_2x2_tmp;
                sdata_sum_2x2_tmp_2d <= sdata_sum_2x2_tmp_1d;
                sdata_sum_2x2_tmp_3d <= sdata_sum_2x2_tmp_2d;
                sdata_sum_3x3_tmp_1d <= sdata_sum_3x3_tmp;
                sdata_sum_3x3_tmp_2d <= sdata_sum_3x3_tmp_1d;
                sdata_sum_3x3_tmp_3d <= sdata_sum_3x3_tmp_2d;
                sdata_sum_4x4_tmp_1d <= sdata_sum_4x4_tmp;
                sdata_sum_4x4_tmp_2d <= sdata_sum_4x4_tmp_1d;
                sdata_sum_4x4_tmp_3d <= sdata_sum_4x4_tmp_2d;
            end if;
        end if;
    end process;

    --# Output data mux: select binning mode output with saturation
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                shcnt_out  <= (others => '0');
                svcnt_out  <= (others => '0');
                sdata_out  <= (others => '0');
            else
                shsync_out <= shsync_6d;
                svsync_out <= svsync_6d;
                shcnt_out  <= shcnt_6d;
                svcnt_out  <= svcnt_6d;

                case (sreg_img_mode) is
                    when "000"  =>
                        for i in 0 to 3 loop
                            sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_1x1(i)(15 downto 0);
                        end loop;
                    when "001"  =>
                        for i in 0 to 3 loop
                            sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_1x1(i)(15 downto 0);
                        end loop;
                    when "010"  =>
                        for i in 0 to 3 loop
                            if(sdata_sum_2x2(i)(17 downto 16) > 0) then
                                sdata_out(((16 * i) + 15) downto (16 * i)) <= x"FFFF";
                            else
                                sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_2x2(i)(15 downto 0);
                            end if;
                        end loop;
                    when "011"  =>
                        for i in 0 to 3 loop
                            sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_2x2(i)(16 downto 1);
                        end loop;
                    when "100"  =>
                        for i in 0 to 3 loop
                            if(sdata_sum_3x3(i)(17 downto 16) > 0) then
                                sdata_out(((16 * i) + 15) downto (16 * i)) <= x"FFFF";
                            else
                                sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_3x3(i)(15 downto 0);
                            end if;
                        end loop;
                    when "101"  =>
                        for i in 0 to 3 loop
                            --* sdata_out(((16*i)+15) downto (16*i))    <= ('0' & smulti_p(i)(30 downto 16));
                            sdata_out(((16 * i) + 15) downto (16 * i)) <= (smulti_p(i)(31 downto 16));
                        end loop;
                    when "110"  =>
                        for i in 0 to 3 loop
                            if(sdata_sum_4x4(i)(17 downto 16) > 0) then
                                sdata_out(((16 * i) + 15) downto (16 * i)) <= x"FFFF";
                            else
                                sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_4x4(i)(15 downto 0);
                            end if;
                        end loop;
                    when "111"  =>
                        for i in 0 to 3 loop
                            sdata_out(((16 * i) + 15) downto (16 * i)) <= sdata_sum_4x4(i)(17 downto 2);
                        end loop;
                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ohcnt  <= shcnt_out;
    ovcnt  <= svcnt_out;
    odata  <= sdata_out when shsync_out = '1' else (others => '0');

    --# Register latch on vsync inactive
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sreg_img_mode <= (others => '0');
                sreg_offsetx  <= (others => '0');
                sreg_width    <= (others => '0');
                sreg_height   <= (others => '0');
            else
--          if(svsync_out = '0') then
                if(ivsync = '0') then -- 220408mbh bug fix
                    sreg_img_mode <= ireg_img_mode;
                    sreg_offsetx  <= ireg_offsetx(11 downto 2);
                    sreg_width    <= ireg_width(11 downto 2);
                    sreg_height   <= ireg_height;
                end if;
            end if;
        end if;
    end process;

    --# Sync/data pipeline delay chain (6 stages)
    process(iui_clk)
    begin
        if(iui_clk'event and iui_clk = '1') then
            if(iui_rstn = '0') then
                sena_1d   <= '0';

                shsync_1d <= '0';
                shsync_2d <= '0';
                shsync_3d <= '0';
                shsync_4d <= '0';
                shsync_5d <= '0';
                shsync_6d <= '0';
                svsync_1d <= '0';
                svsync_2d <= '0';
                svsync_3d <= '0';
                svsync_4d <= '0';
                svsync_5d <= '0';
                svsync_6d <= '0';
                shcnt_1d  <= (others => '0');
                shcnt_2d  <= (others => '0');
                shcnt_3d  <= (others => '0');
                shcnt_4d  <= (others => '0');
                shcnt_5d  <= (others => '0');
                svcnt_1d  <= (others => '0');
                svcnt_2d  <= (others => '0');
                svcnt_3d  <= (others => '0');
                svcnt_4d  <= (others => '0');
                svcnt_5d  <= (others => '0');

                sdoutb_1d <= (others => '0');
            else
                sena_1d   <= sena;

                shsync_1d <= shsync;
                shsync_2d <= shsync_1d;
                shsync_3d <= shsync_2d;
                shsync_4d <= shsync_3d;
                shsync_5d <= shsync_4d;
                shsync_6d <= shsync_5d;
                svsync_1d <= svsync;
                svsync_2d <= svsync_1d;
                svsync_3d <= svsync_2d;
                svsync_4d <= svsync_3d;
                svsync_5d <= svsync_4d;
                svsync_6d <= svsync_5d;
                shcnt_1d  <= shcnt;
                shcnt_2d  <= shcnt_1d;
                shcnt_3d  <= shcnt_2d;
                shcnt_4d  <= shcnt_3d;
                shcnt_5d  <= shcnt_4d;
                shcnt_6d  <= shcnt_5d;
                svcnt_1d  <= svcnt;
                svcnt_2d  <= svcnt_1d;
                svcnt_3d  <= svcnt_2d;
                svcnt_4d  <= svcnt_3d;
                svcnt_5d  <= svcnt_4d;
                svcnt_6d  <= svcnt_5d;

                sdoutb_1d <= sdoutb;
            end if;
        end if;
    end process;

ila_debug_roi : if(GEN_ILA_roi = "ON") generate
    COMPONENT ila_roi
    PORT (
        clk     : in std_logic;
        probe0  : in tstate_dpram_roi;
        probe1  : in std_logic;
        probe2  : in std_logic;
        probe3  : in std_logic_vector(11 downto 0);
        probe4  : in std_logic_vector( 9 downto 0);
        probe5  : in std_logic_vector(63 downto 0);

        probe6  : in std_logic;
        probe7  : in std_logic;
        probe8  : in std_logic_vector(11 downto 0);
        probe9  : in std_logic_vector( 9 downto 0);
        probe10 : in std_logic_vector(63 downto 0);

        probe11 : in std_logic_vector( 7 downto 0);
        probe12 : in std_logic;
        probe13 : in std_logic
    );
    END COMPONENT;
begin
    u_ila_roi : ila_roi
    PORT MAP (
        clk     => iui_clk,
        probe0  => state_dpram,
        probe1  => ivsync,
        probe2  => ihsync,
        probe3  => ivcnt,
        probe4  => ihcnt,
        probe5  => idata,

        probe6  => svsync_out,
        probe7  => shsync_out,
        probe8  => svcnt_out,
        probe9  => shcnt_out,
        probe10 => sdata_out,

        probe11 => saddrb,
        probe12 => vtrig_latch,
        probe13 => swr_end_trig_latch
    );
end generate ila_debug_roi;

end Behavioral;
