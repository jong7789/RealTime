library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

    use WORK.TOP_HEADER.ALL;

entity MASK_OUT is
port (
    idata_clk   : in  std_logic;
    idata_rstn  : in  std_logic;

    ireg_width  : in  std_logic_vector(11 downto 0);
    ireg_height : in  std_logic_vector(11 downto 0);

    ihsync      : in  std_logic;
    ivsync      : in  std_logic;
    ivcnt       : in  std_logic_vector(11 downto 0);
    ihcnt       : in  std_logic_vector(11 downto 0);
    idata       : in  std_logic_vector(15 downto 0);

    ohsync_2x2  : out std_logic;
    ovsync_2x2  : out std_logic;
    ohcnt_2x2   : out std_logic_vector(11 downto 0);
    ovcnt_2x2   : out std_logic_vector(11 downto 0);

    odata_1x1   : out std_logic_vector(15 downto 0);
    odata_1x2   : out std_logic_vector(15 downto 0);
    odata_1x3   : out std_logic_vector(15 downto 0);
    odata_2x1   : out std_logic_vector(15 downto 0);
    odata_2x2   : out std_logic_vector(15 downto 0);
    odata_2x3   : out std_logic_vector(15 downto 0);
    odata_3x1   : out std_logic_vector(15 downto 0);
    odata_3x2   : out std_logic_vector(15 downto 0);
    odata_3x3   : out std_logic_vector(15 downto 0)
);
end MASK_OUT;

architecture Behavioral of MASK_OUT is

    -- component DPRAM_16x3072
    component DPRAM_16x4096 -- for 3840 width mbh210623
    port (
        clka  : in  std_logic;
        ena   : in  std_logic;
        wea   : in  std_logic;
        addra : in  std_logic_vector(11 downto 0);
        dina  : in  std_logic_vector(15 downto 0);
        clkb  : in  std_logic;
        enb   : in  std_logic;
        addrb : in  std_logic_vector(11 downto 0);
        doutb : out std_logic_vector(15 downto 0)
    );
    end component;

    type tstate_dpram is (
        s_IDLE,
        s_DATA,
        s_WAIT,
        s_WAIT2
    );

    signal state_dpram  : tstate_dpram;
    signal state_dpram2 : tstate_dpram;

    signal swidth  : std_logic_vector(11 downto 0);
    signal sheight : std_logic_vector(11 downto 0);

    signal sena   : std_logic;
    signal saddra : std_logic_vector(11 downto 0);
    signal sdina  : std_logic_vector(15 downto 0);
    signal senb   : std_logic;
    signal saddrb : std_logic_vector(11 downto 0);
    signal sdoutb : std_logic_vector(15 downto 0);

    signal sena2   : std_logic;
    signal saddra2 : std_logic_vector(11 downto 0);
    signal sdina2  : std_logic_vector(15 downto 0);
    signal senb2   : std_logic;
    signal saddrb2 : std_logic_vector(11 downto 0);
    signal sdoutb2 : std_logic_vector(15 downto 0);

    signal svsync : std_logic;
    signal svcnt  : std_logic_vector(11 downto 0);
    signal sdata  : std_logic_vector(15 downto 0);

    signal svcnt2     : std_logic_vector(11 downto 0);
    signal swait_cnt  : std_logic_vector(31 downto 0);
    signal swait_cnt2 : std_logic_vector(31 downto 0);

    -- Delay
    signal sena_1d    : std_logic;
    signal saddra_1d  : std_logic_vector(11 downto 0);
    signal sdina_1d   : std_logic_vector(15 downto 0);
    signal sena2_1d   : std_logic;
    signal saddra2_1d : std_logic_vector(11 downto 0);
    signal senb_1d    : std_logic;
    signal senb_2d    : std_logic;
    signal senb_3d    : std_logic;

    signal svsync_1d : std_logic;
    signal svsync_2d : std_logic;
    signal svsync_3d : std_logic;

    signal svcnt_1d : std_logic_vector(11 downto 0);
    signal svcnt_2d : std_logic_vector(11 downto 0);
    signal svcnt_3d : std_logic_vector(11 downto 0);

    signal saddrb_1d : std_logic_vector(11 downto 0);
    signal saddrb_2d : std_logic_vector(11 downto 0);
    signal saddrb_3d : std_logic_vector(11 downto 0);

    signal sdoutb2_1d : std_logic_vector(15 downto 0);
    signal sdoutb2_2d : std_logic_vector(15 downto 0);
    signal sdoutb_1d  : std_logic_vector(15 downto 0);
    signal sdoutb_2d  : std_logic_vector(15 downto 0);
    signal sdoutb_3d  : std_logic_vector(15 downto 0);

    signal sdata_1d : std_logic_vector(15 downto 0);
    signal sdata_2d : std_logic_vector(15 downto 0);
    signal sdata_3d : std_logic_vector(15 downto 0);
    signal sdata_4d : std_logic_vector(15 downto 0);

    signal sreg_width    : std_logic_vector(11 downto 0);
    signal sreg_width_1d : std_logic_vector(11 downto 0);
    signal sreg_width_2d : std_logic_vector(11 downto 0);
    signal sreg_width_3d : std_logic_vector(11 downto 0);

    signal sreg_height    : std_logic_vector(11 downto 0);
    signal sreg_height_1d : std_logic_vector(11 downto 0);
    signal sreg_height_2d : std_logic_vector(11 downto 0);
    signal sreg_height_3d : std_logic_vector(11 downto 0);

begin

    --# Latch width/height parameters on vsync falling edge
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                swidth  <= (others => '0');
                sheight <= (others => '0');
            else
                if (svsync_3d = '0') then
                    swidth  <= sreg_width_3d - '1';
                    sheight <= sreg_height_3d - '1';
                end if;
            end if;
        end if;
    end process;

    --# DPRAM line buffer write control and read address generation (line 0)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                state_dpram <= s_IDLE;

                sena       <= '0';
                saddra     <= (others => '0');
                sdina      <= (others => '0');

                senb       <= '0';
                saddrb     <= (others => '0');

                svsync     <= '0';
                svcnt      <= (others => '0');
                swait_cnt  <= (others => '0');
                swait_cnt2 <= (others => '0');
            else
                sena   <= ihsync;
                saddra <= ihcnt;
                sdina  <= idata;

                case (state_dpram) is
                    when s_IDLE =>
                        if (ivcnt = 1 and ihsync = '1' and ihcnt = 0) then
                            state_dpram <= s_DATA;

                            senb   <= '1';
                            saddrb <= (others => '0');
                            svsync <= '1';
                        end if;
                    when s_DATA =>
                        if (saddrb = swidth) then
                            if (svcnt = sheight) then
                                state_dpram <= s_IDLE;
                                svcnt       <= (others => '0');
                                svsync      <= '0';
                            else
                                if (svcnt = sheight - 1) then
                                    state_dpram <= s_WAIT2;
                                else
                                    state_dpram <= s_WAIT;
                                    swait_cnt   <= (others => '0');
                                end if;
                                svcnt <= svcnt + '1';
                            end if;
                            senb   <= '0';
                            saddrb <= (others => '0');
                        else
                            senb   <= '1';
                            saddrb <= saddrb + '1';
                        end if;

                        sdina <= idata;
                    when s_WAIT =>
                        if (ihsync = '1' and ihcnt = 0) then
                            state_dpram <= s_DATA;

                            senb   <= '1';
                            saddrb <= (others => '0');
                        else
                            swait_cnt <= swait_cnt + '1';
                        end if;

                    when s_WAIT2 =>
                        if (swait_cnt2 = swait_cnt - 1) or
                           (swait_cnt = 0) then -- 0 move next state 210310 mbh
                            state_dpram <= s_DATA;

                            senb       <= '1';
                            saddrb     <= (others => '0');
                            swait_cnt2 <= (others => '0');
                        else
                            swait_cnt2 <= swait_cnt2 + '1';
                        end if;
                    when others =>
                        NULL;

                end case;
            end if;
        end if;
    end process;

    --# DPRAM line buffer write control and read address generation (line 1)
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                state_dpram2 <= s_IDLE;

                sena2   <= '0';
                saddra2 <= (others => '0');
                sdina2  <= (others => '0');

                senb2   <= '0';
                saddrb2 <= (others => '0');

                svcnt2 <= (others => '0');
            else
                sena2   <= senb;
                saddra2 <= saddrb;
                sdina2  <= sdoutb;

                case (state_dpram2) is
                    when s_IDLE =>
                        if (ivcnt = 2 and senb = '1' and saddrb = 0) then
                            state_dpram2 <= s_DATA;

                            senb2   <= '1';
                            saddrb2 <= (others => '0');
                        end if;
                    when s_DATA =>
                        if (saddrb2 = swidth) then
                            if (svcnt2 = sheight - 1) then
                                state_dpram2 <= s_IDLE;
                                svcnt2       <= (others => '0');
                            else
                                state_dpram2 <= s_WAIT;
                                svcnt2       <= svcnt2 + '1';
                            end if;
                            senb2   <= '0';
                            saddrb2 <= (others => '0');
                        else
                            senb2   <= '1';
                            saddrb2 <= saddrb2 + '1';
                        end if;

                    when s_WAIT =>
                        if (senb = '1' and saddrb = 0) then
                            state_dpram2 <= s_DATA;

                            senb2   <= '1';
                            saddrb2 <= (others => '0');
                        end if;
                    when others =>
                        NULL;

                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------------------
    -- First Line
    ----------------------------------------------------------------------------
    -- U0_DPRAM_16x3072 : DPRAM_16x3072
    U0_DPRAM_16x4096 : DPRAM_16x4096
    port map (
        clka  => idata_clk,
        ena   => sena_1d,
        wea   => '1',
        addra => saddra_1d,
        dina  => sdina_1d,

        clkb  => idata_clk,
        enb   => senb,
        addrb => saddrb,
        doutb => sdoutb
    );

    ----------------------------------------------------------------------------
    -- Second Line
    ----------------------------------------------------------------------------
    -- U1_DPRAM_16x3072 : DPRAM_16x3072
    U1_DPRAM_16x4096 : DPRAM_16x4096
    port map (
        clka  => idata_clk,
        ena   => sena2_1d,
        wea   => '1',
        addra => saddra2_1d,
        dina  => sdina2,

        clkb  => idata_clk,
        enb   => senb2,
        addrb => saddrb2,
        doutb => sdoutb2
    );

    --# 3x3 mask output assignment with boundary handling
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                ohsync_2x2 <= '0';
                ovsync_2x2 <= '0';
                ovcnt_2x2  <= (others => '0');
                ohcnt_2x2  <= (others => '0');

                odata_1x1 <= (others => '0');
                odata_1x2 <= (others => '0');
                odata_1x3 <= (others => '0');
                odata_2x1 <= (others => '0');
                odata_2x2 <= (others => '0');
                odata_2x3 <= (others => '0');
                odata_3x1 <= (others => '0');
                odata_3x2 <= (others => '0');
                odata_3x3 <= (others => '0');
            else
                ohsync_2x2 <= senb_3d;
                ovsync_2x2 <= svsync_3d;
                ovcnt_2x2  <= svcnt_3d;
                ohcnt_2x2  <= saddrb_3d;

                if (senb_3d = '0') then
                    odata_1x1 <= (others => '0');
                    odata_1x2 <= (others => '0');
                    odata_1x3 <= (others => '0');
                    odata_2x1 <= (others => '0');
                    odata_2x2 <= (others => '0');
                    odata_2x3 <= (others => '0');
                    odata_3x1 <= (others => '0');
                    odata_3x2 <= (others => '0');
                    odata_3x3 <= (others => '0');
                else
                    odata_1x1 <= sdoutb2_2d;
                    odata_1x2 <= sdoutb2_1d;
                    odata_1x3 <= sdoutb2;
                    odata_2x1 <= sdoutb_3d;
                    odata_2x2 <= sdoutb_2d;
                    odata_2x3 <= sdoutb_1d;
                    odata_3x1 <= sdata_4d;
                    odata_3x2 <= sdata_3d;
                    odata_3x3 <= sdata_2d;
                end if;
            end if;
        end if;
    end process;

    --# Pipeline delay registers for all signals
    process(idata_clk)
    begin
        if (idata_clk'event and idata_clk = '1') then
            if (idata_rstn = '0') then
                sena_1d    <= '0';
                saddra_1d  <= (others => '0');
                sdina_1d   <= (others => '0');
                sena2_1d   <= '0';
                saddra2_1d <= (others => '0');
                senb_1d    <= '0';
                senb_2d    <= '0';
                senb_3d    <= '0';
                svsync_1d  <= '0';
                svsync_2d  <= '0';
                svsync_3d  <= '0';
                svcnt_1d   <= (others => '0');
                svcnt_2d   <= (others => '0');
                svcnt_3d   <= (others => '0');
                saddrb_1d  <= (others => '0');
                saddrb_2d  <= (others => '0');
                saddrb_3d  <= (others => '0');
                sdoutb2_1d <= (others => '0');
                sdoutb2_2d <= (others => '0');
                sdoutb_1d  <= (others => '0');
                sdoutb_2d  <= (others => '0');
                sdoutb_3d  <= (others => '0');
                sdata_1d   <= (others => '0');
                sdata_2d   <= (others => '0');
                sdata_3d   <= (others => '0');
                sdata_4d   <= (others => '0');
                sreg_width     <= (others => '0');
                sreg_width_1d  <= (others => '0');
                sreg_width_2d  <= (others => '0');
                sreg_width_3d  <= (others => '0');
                sreg_height    <= (others => '0');
                sreg_height_1d <= (others => '0');
                sreg_height_2d <= (others => '0');
                sreg_height_3d <= (others => '0');
            else
                sena_1d    <= sena;
                saddra_1d  <= saddra;
                sdina_1d   <= sdina;
                sena2_1d   <= sena2;
                saddra2_1d <= saddra2;
                senb_1d    <= senb;
                senb_2d    <= senb_1d;
                senb_3d    <= senb_2d;
                svsync_1d  <= svsync;
                svsync_2d  <= svsync_1d;
                svsync_3d  <= svsync_2d;
                svcnt_1d   <= svcnt;
                svcnt_2d   <= svcnt_1d;
                svcnt_3d   <= svcnt_2d;
                saddrb_1d  <= saddrb;
                saddrb_2d  <= saddrb_1d;
                saddrb_3d  <= saddrb_2d;
                sdoutb2_1d <= sdoutb2;
                sdoutb2_2d <= sdoutb2_1d;
                sdoutb_1d  <= sdoutb;
                sdoutb_2d  <= sdoutb_1d;
                sdoutb_3d  <= sdoutb_2d;
                sdata      <= idata;
                sdata_1d   <= sdata;
                sdata_2d   <= sdata_1d;
                sdata_3d   <= sdata_2d;
                sdata_4d   <= sdata_3d;
                sreg_width     <= ireg_width;
                sreg_width_1d  <= sreg_width;
                sreg_width_2d  <= sreg_width_1d;
                sreg_width_3d  <= sreg_width_2d;
                sreg_height    <= ireg_height;
                sreg_height_1d <= sreg_height;
                sreg_height_2d <= sreg_height_1d;
                sreg_height_3d <= sreg_height_2d;
            end if;
        end if;
    end process;

end Behavioral;
