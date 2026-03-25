library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity GEV_DATA_CONV is
    port (
        idata_clk  : in  std_logic;
        idata_rstn : in  std_logic;
        igev_clk   : in  std_logic;
        igev_rstn  : in  std_logic;

        ireg_width  : in  std_logic_vector(11 downto 0);
        ireg_height : in  std_logic_vector(11 downto 0);

        ihsync : in  std_logic;
        ivsync : in  std_logic;
        ihcnt  : in  std_logic_vector(11 downto 0);
        ivcnt  : in  std_logic_vector(11 downto 0);
        idata  : in  std_logic_vector(15 downto 0);

        ohsync : out std_logic;
        ovsync : out std_logic;
        ohcnt  : out std_logic_vector(9 downto 0);
        ovcnt  : out std_logic_vector(11 downto 0);
        odata  : out std_logic_vector(63 downto 0)
    );
end GEV_DATA_CONV;

architecture Behavioral of GEV_DATA_CONV is

    component DPRAM_16x3072_64x768
        port (
            clka  : in  std_logic;
            ena   : in  std_logic;
            wea   : in  std_logic;
            addra : in  std_logic_vector(11 downto 0);
            dina  : in  std_logic_vector(15 downto 0);
            clkb  : in  std_logic;
            enb   : in  std_logic;
            addrb : in  std_logic_vector(9 downto 0);
            doutb : out std_logic_vector(63 downto 0)
        );
    end component;

    type tstate_dpram is (
        s_IDLE,
        s_DATA,
        s_WAIT
    );

    signal state_dpram : tstate_dpram;

    signal sena       : std_logic;
    signal sena_odd   : std_logic;
    signal sena_even  : std_logic;
    signal sdina      : std_logic_vector(15 downto 0);
    signal senb_odd   : std_logic;
    signal senb_even  : std_logic;
    signal sdoutb_odd  : std_logic_vector(63 downto 0);
    signal sdoutb_even : std_logic_vector(63 downto 0);

    signal stoggle_porta    : std_logic;
    signal stoggle_portb    : std_logic;
    signal stoggle_portb_1d : std_logic;

    signal swr_end_trig : std_logic;

    signal shsync_conv : std_logic;
    signal svsync_conv : std_logic;
    signal shcnt_conv  : std_logic_vector(9 downto 0);
    signal svcnt_conv  : std_logic_vector(11 downto 0);

    signal sreg_width  : std_logic_vector(11 downto 0);
    signal sreg_height : std_logic_vector(11 downto 0);

    signal sena_1d         : std_logic;
    signal sena_2d         : std_logic;
    signal shsync_1d       : std_logic;
    signal shsync_2d       : std_logic;
    signal shsync_3d       : std_logic;
    signal shsync_conv_1d  : std_logic;
    signal svsync_conv_1d  : std_logic;
    signal shcnt_conv_1d   : std_logic_vector(9 downto 0);
    signal svcnt_conv_1d   : std_logic_vector(11 downto 0);

    --# Preventing image vertical rotation, syncronize V, 231212
    signal svsync_1d        : std_logic;
    signal svsync_2d        : std_logic;
    signal svsync_3d        : std_logic;
    signal ver_stt_trig      : std_logic;
    signal ver_stt_trig_keep : std_logic;

begin

    sena  <= ihsync;
    sdina <= idata(7 downto 0) & idata(15 downto 8);

    sena_odd  <= sena       when stoggle_porta = '0' else '0';
    sena_even <= sena       when stoggle_porta = '1' else '0';
    senb_odd  <= shsync_conv when stoggle_portb = '0' else '0';
    senb_even <= shsync_conv when stoggle_portb = '1' else '0';

    U0_DPRAM_16x3072_64x768 : DPRAM_16x3072_64x768
    port map (
        clka  => idata_clk,
        ena   => sena_odd,
        wea   => '1',
        addra => ihcnt,
        dina  => sdina,

        clkb  => igev_clk,
        enb   => senb_odd,
        addrb => shcnt_conv,
        doutb => sdoutb_odd
    );

    U1_DPRAM_16x3072_64x768 : DPRAM_16x3072_64x768
    port map (
        clka  => idata_clk,
        ena   => sena_even,
        wea   => '1',
        addra => ihcnt,
        dina  => sdina,

        clkb  => igev_clk,
        enb   => senb_even,
        addrb => shcnt_conv,
        doutb => sdoutb_even
    );

    swr_end_trig <= not shsync_2d and     shsync_3d;
    ver_stt_trig <=     svsync_2d and not svsync_3d; --# 231212

    --# Toggle porta on falling edge of sena
    process(idata_clk)
    begin
        if(idata_clk'event and idata_clk = '1') then
            if(idata_rstn = '0') then
                sena_1d       <= '0';
                sena_2d       <= '0';
                stoggle_porta <= '0';
            else
                sena_1d       <= sena;
                sena_2d       <= sena_1d;
                if(sena_1d = '0' and sena_2d = '1') then
                    stoggle_porta <= not stoggle_porta;
                end if;
            end if;
        end if;
    end process;

    --# DPRAM read state machine, GEV clock domain
    process(igev_clk)
    begin
        if(igev_clk'event and igev_clk = '1') then
            if(igev_rstn = '0') then
                state_dpram <= s_IDLE;

                stoggle_portb <= '0';

                shsync_conv <= '0';
                svsync_conv <= '0';
                shcnt_conv  <= (others => '0');
                svcnt_conv  <= (others => '0');
            else
                if(ver_stt_trig = '1') then       --# ignored ver_stt_trig at 2832 30fps, 240130
                    ver_stt_trig_keep <= '1';      --# bufferd signal keep the FPS.
                elsif(state_dpram = s_WAIT) then
                    ver_stt_trig_keep <= '0';
                end if;

                case (state_dpram) is
                    when s_IDLE =>
                        if(ver_stt_trig_keep = '1') then --# 231212
                            state_dpram <= s_WAIT;
                        end if;

                    when s_WAIT =>
                        if(swr_end_trig = '1') then
                            state_dpram <= s_DATA;

                            shsync_conv <= '1';
                            svsync_conv <= '1';
                            shcnt_conv  <= (others => '0');
                        else
                            shsync_conv <= '0';
                        end if;

                    when s_DATA =>
                        if(shcnt_conv = sreg_width(11 downto 2) - 1) then
                            if(svcnt_conv = sreg_height - 1) then
                                state_dpram <= s_IDLE;

                                svsync_conv <= '0';
                                svcnt_conv  <= (others => '0');
                            else
                                state_dpram <= s_WAIT;

                                svsync_conv <= '1';
                                svcnt_conv  <= svcnt_conv + '1';
                            end if;

                            shsync_conv   <= '0';
                            shcnt_conv    <= (others => '0');
                            stoggle_portb <= not stoggle_portb;
                        else
                            shcnt_conv <= shcnt_conv + '1';
                        end if;

                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    --# Latch register width/height when vsync is inactive
    process(igev_clk)
    begin
        if(igev_clk'event and igev_clk = '1') then
            if(igev_rstn = '0') then
                sreg_width  <= (others => '0');
                sreg_height <= (others => '0');
            else
                if(svsync_conv_1d = '0') then
                    sreg_width  <= ireg_width;
                    sreg_height <= ireg_height;
                end if;
            end if;
        end if;
    end process;

    ohsync <= shsync_conv_1d;
    ovsync <= svsync_conv_1d;
    ovcnt  <= svcnt_conv_1d;
    ohcnt  <= shcnt_conv_1d;
    odata  <= sdoutb_odd when stoggle_portb_1d = '0' else sdoutb_even;

    --# Delay pipeline for sync/count signals in GEV clock domain
    process(igev_clk)
    begin
        if(igev_clk'event and igev_clk = '1') then
            if(igev_rstn = '0') then
                shsync_1d       <= '0';
                shsync_2d       <= '0';
                shsync_3d       <= '0';
                svsync_1d       <= '0';
                svsync_2d       <= '0';
                svsync_3d       <= '0';

                shsync_conv_1d  <= '0';
                svsync_conv_1d  <= '0';
                shcnt_conv_1d   <= (others => '0');
                svcnt_conv_1d   <= (others => '0');
                stoggle_portb_1d <= '0';
            else
                shsync_1d       <= ihsync;
                shsync_2d       <= shsync_1d;
                shsync_3d       <= shsync_2d;
                svsync_1d       <= ivsync;
                svsync_2d       <= svsync_1d;
                svsync_3d       <= svsync_2d;

                shsync_conv_1d  <= shsync_conv;
                svsync_conv_1d  <= svsync_conv;
                shcnt_conv_1d   <= shcnt_conv;
                svcnt_conv_1d   <= svcnt_conv;
                stoggle_portb_1d <= stoggle_portb;
            end if;
        end if;
    end process;

end Behavioral;
