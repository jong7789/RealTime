library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity TI_HORIZONTAL_FLIP is
    generic (GNR_MODEL : string := "EXT1616R");
    port (
        iui_clk     : in    std_logic;
        iui_rstn    : in    std_logic;

        ihsync      : in    std_logic;
        ivsync      : in    std_logic;
        ihcnt       : in    std_logic_vector(9 downto 0);
        ivcnt       : in    std_logic_vector(11 downto 0);
        idata       : in    std_logic_vector(63 downto 0);

        ireg_width  : in    std_logic_vector(11 downto 0);
        ireg_height : in    std_logic_vector(11 downto 0);

        ohsync      : out   std_logic;
        ovsync      : out   std_logic;
        ohcnt       : out   std_logic_vector(9 downto 0);
        ovcnt       : out   std_logic_vector(11 downto 0);
        odata       : out   std_logic_vector(63 downto 0)
    );
end TI_HORIZONTAL_FLIP;

architecture Behavioral of TI_HORIZONTAL_FLIP is

    component DPRAM_16x768 is
        port (
            clka  : in    std_logic;
            wea   : in    std_logic;
            ena   : in    std_logic;
            addra : in    std_logic_vector(9 downto 0);
            dina  : in    std_logic_vector(15 downto 0);
            clkb  : in    std_logic;
            enb   : in    std_logic;
            addrb : in    std_logic_vector(9 downto 0);
            doutb : out   std_logic_vector(15 downto 0)
        );
    end component;

    type tstate_dpram is (
        s_IDLE,
        s_WAIT,
        s_DATA
    );
    signal state_dpram : tstate_dpram;

    signal sena   : std_logic;
    signal saddra : std_logic_vector(9 downto 0);
    signal sdina  : std_logic_vector(63 downto 0);

    signal swr_end_trig : std_logic;

    signal senb    : std_logic;
    signal saddrb0 : std_logic_vector(9 downto 0);
    signal saddrb1 : std_logic_vector(9 downto 0);
    signal saddrb2 : std_logic_vector(9 downto 0);
    signal saddrb3 : std_logic_vector(9 downto 0);
    signal sdoutb0 : std_logic_vector(15 downto 0);
    signal sdoutb1 : std_logic_vector(15 downto 0);
    signal sdoutb2 : std_logic_vector(15 downto 0);
    signal sdoutb3 : std_logic_vector(15 downto 0);

    signal shsync : std_logic;
    signal svsync : std_logic;
    signal shcnt  : std_logic_vector(9 downto 0);
    signal svcnt  : std_logic_vector(11 downto 0);

    signal sreg_width  : std_logic_vector(9 downto 0);
    signal sreg_height : std_logic_vector(11 downto 0);

    signal shsync_out : std_logic;
    signal svsync_out : std_logic;
    signal shcnt_out  : std_logic_vector(9 downto 0);
    signal svcnt_out  : std_logic_vector(11 downto 0);
    signal sdata_out  : std_logic_vector(63 downto 0);

    signal sena_1d   : std_logic;
    signal shsync_1d : std_logic;
    signal svsync_1d : std_logic;
    signal shcnt_1d  : std_logic_vector(9 downto 0);
    signal svcnt_1d  : std_logic_vector(11 downto 0);

    signal sena_2d   : std_logic;
    signal shsync_2d : std_logic;
    signal svsync_2d : std_logic;
    signal shcnt_2d  : std_logic_vector(9 downto 0);
    signal svcnt_2d  : std_logic_vector(11 downto 0);

    --### addr reverse ### 201231 mbh
--    constant MODE_LOWER_NORMAL : std_logic := '1';
        -- 0: nomal sequence
        -- 1: half lower line data seq reverse

--    constant end01          : integer := 3;
    constant end01 : integer := 0;
--    constant str01          : integer := 445;
    constant str01 : integer := (MAX_WIDTH(GNR_MODEL) / 4) + end01;
--    constant end23          : integer := 2;
    constant end23 : integer := 0;
--    constant str23          : integer := 444;
    constant str23 : integer := (MAX_WIDTH(GNR_MODEL) / 4) + end23;
    signal senb_ud    : std_logic;
    signal saddrb0_ud : std_logic_vector(9 downto 0);
    signal saddrb1_ud : std_logic_vector(9 downto 0);
    signal saddrb2_ud : std_logic_vector(9 downto 0);
    signal saddrb3_ud : std_logic_vector(9 downto 0);
    --######
begin

    --# input latch process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                sena   <= '0';
                saddra <= (others => '0');
                sdina  <= (others => '0');
            else
                sena   <= ihsync;
                saddra <= ihcnt;
                sdina  <= idata;
            end if;
        end if;
    end process;

    U0_DPRAM_16x768 : DPRAM_16x768
        port map (
            clka  => iui_clk,
            wea   => '1',
            ena   => sena,
            addra => saddra,
            dina  => sdina(15 downto 0),
            clkb  => iui_clk,
            enb   => senb_ud,
            addrb => saddrb0_ud,
            doutb => sdoutb0
        );
    U1_DPRAM_16x768 : DPRAM_16x768
        port map (
            clka  => iui_clk,
            wea   => '1',
            ena   => sena,
            addra => saddra,
            dina  => sdina(31 downto 16),
            clkb  => iui_clk,
            enb   => senb_ud,
            addrb => saddrb1_ud,
            doutb => sdoutb1
        );
    U2_DPRAM_16x768 : DPRAM_16x768
        port map (
            clka  => iui_clk,
            wea   => '1',
            ena   => sena,
            addra => saddra,
            dina  => sdina(47 downto 32),
            clkb  => iui_clk,
            enb   => senb_ud,
            addrb => saddrb2_ud,
            doutb => sdoutb2
        );
    U3_DPRAM_16x768 : DPRAM_16x768
        port map (
            clka  => iui_clk,
            wea   => '1',
            ena   => sena,
            addra => saddra,
            dina  => sdina(63 downto 48),
            clkb  => iui_clk,
            enb   => senb_ud,
            addrb => saddrb3_ud,
            doutb => sdoutb3
        );

    swr_end_trig <= not sena and sena_1d;

    --# DPRAM read state machine process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                state_dpram <= s_IDLE;
                senb    <= '0';
                saddrb0 <= (others => '0');
                saddrb1 <= (others => '0');
                saddrb2 <= (others => '0');
                saddrb3 <= (others => '0');

                shsync <= '0';
                svsync <= '0';
                shcnt  <= (others => '0');
                svcnt  <= (others => '0');
            else
                case (state_dpram) is
                    when s_IDLE =>
                        state_dpram <= s_WAIT;

                    when s_WAIT =>
                        if (swr_end_trig = '1') then
                            state_dpram <= s_DATA;

                            senb    <= '1';
                            saddrb0 <= conv_std_logic_vector(0, 10); -- 10/4 + 1
                            saddrb1 <= conv_std_logic_vector(0, 10); -- 10/4 + 1
                            saddrb2 <= conv_std_logic_vector(0, 10); -- 10/4
                            saddrb3 <= conv_std_logic_vector(0, 10); -- 10/4

                            shsync <= '1';
                            svsync <= '1';
                            shcnt  <= (others => '0');
                        end if;

                    when s_DATA =>
                        if (shcnt = sreg_width - 1) then
                            if (svcnt = sreg_height - 1) then
                                state_dpram <= s_IDLE;
                                svsync      <= '0';
                                svcnt       <= (others => '0');
                            else
                                state_dpram <= s_WAIT;
                                svcnt       <= svcnt + '1';
                            end if;

                            senb    <= '0';
                            saddrb0 <= conv_std_logic_vector(0, 10);
                            saddrb1 <= conv_std_logic_vector(0, 10);
                            saddrb2 <= conv_std_logic_vector(0, 10);
                            saddrb3 <= conv_std_logic_vector(0, 10);
                            shsync  <= '0';
                            shcnt   <= (others => '0');
                        else
                            shcnt   <= shcnt + '1';
                            saddrb0 <= saddrb0 + '1';
                            saddrb1 <= saddrb1 + '1';
                            saddrb2 <= saddrb2 + '1';
                            saddrb3 <= saddrb3 + '1';
                            -- -- ROIC MAX NUM = 12
                            -- if(saddrb0 = 64-3) then       -- ROIC0
                            --  saddrb0 <= conv_std_logic_vector(64+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(64+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(64+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(64+2, 10);
                            -- elsif(saddrb0 = 128-3) then   -- ROIC1
                            --  saddrb0 <= conv_std_logic_vector(128+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(128+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(128+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(128+2, 10);
                            -- elsif(saddrb0 = 192-3) then   -- ROIC2
                            --  saddrb0 <= conv_std_logic_vector(192+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(192+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(192+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(192+2, 10);
                            -- elsif(saddrb0 = 256-3) then   -- ROIC3
                            --  saddrb0 <= conv_std_logic_vector(256+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(256+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(256+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(256+2, 10);
                            -- elsif(saddrb0 = 320-3) then   -- ROIC4
                            --  saddrb0 <= conv_std_logic_vector(320+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(320+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(320+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(320+2, 10);
                            -- elsif(saddrb0 = 384-3) then   -- ROIC5
                            --  saddrb0 <= conv_std_logic_vector(384+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(384+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(384+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(384+2, 10);
                            -- elsif(saddrb0 = 448-3) then   -- ROIC6
                            --  saddrb0 <= conv_std_logic_vector(448+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(448+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(448+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(448+2, 10);
                            -- elsif(saddrb0 = 512-3) then   -- ROIC7
                            --  saddrb0 <= conv_std_logic_vector(512+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(512+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(512+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(512+2, 10);
                            -- elsif(saddrb0 = 576-3) then   -- ROIC8
                            --  saddrb0 <= conv_std_logic_vector(576+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(576+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(576+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(576+2, 10);
                            -- elsif(saddrb0 = 640-3) then   -- ROIC9
                            --  saddrb0 <= conv_std_logic_vector(640+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(640+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(640+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(640+2, 10);
                            -- elsif(saddrb0 = 704-3) then   -- ROIC10
                            --  saddrb0 <= conv_std_logic_vector(704+3, 10);
                            --  saddrb1 <= conv_std_logic_vector(704+3, 10);
                            --  saddrb2 <= conv_std_logic_vector(704+2, 10);
                            --  saddrb3 <= conv_std_logic_vector(704+2, 10);
                        --  -- elsif(saddrb0 = 768-3) then   -- ROIC11
                        --  --  saddrb0 <= conv_std_logic_vector(768+3, 10);
                        --  --  saddrb1 <= conv_std_logic_vector(768+3, 10);
                        --  --  saddrb2 <= conv_std_logic_vector(768+2, 10);
                        --  --  saddrb3 <= conv_std_logic_vector(768+2, 10);
                            -- else
                            --  saddrb0 <= saddrb0 + '1';
                            --  saddrb1 <= saddrb1 + '1';
                            --  saddrb2 <= saddrb2 + '1';
                            --  saddrb3 <= saddrb3 + '1';
                            -- end if;
                        end if;
                    when others =>
                        state_dpram <= s_IDLE;
                end case;
            end if;
        end if;
    end process;

    --# register width/height latch process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                sreg_width  <= (others => '0');
                sreg_height <= (others => '0');
            else
                if (svsync_out = '0') then
                    sreg_width  <= conv_std_logic_vector(MAX_WIDTH(GNR_MODEL) / 4, 10);
                    sreg_height <= ireg_height;
                end if;
            end if;
        end if;
    end process;

    --### select up/down line
    --# address reverse for horizontal flip process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            saddrb0_ud <= (not saddrb0) + conv_std_logic_vector(str01 + end01, 10);
            saddrb1_ud <= (not saddrb1) + conv_std_logic_vector(str01 + end01, 10);
            saddrb2_ud <= (not saddrb2) + conv_std_logic_vector(str23 + end23, 10);
            saddrb3_ud <= (not saddrb3) + conv_std_logic_vector(str23 + end23, 10);

-- --            if MODE_LOWER_NORMAL = '1' then
--             if ROIC_DUAL = 1 then
--                 saddrb0_ud <= saddrb0;
--                 saddrb1_ud <= saddrb1;
--                 saddrb2_ud <= saddrb2;
--                 saddrb3_ud <= saddrb3;
--             elsif svcnt_1d(0) = '0' then -- upper
--                 saddrb0_ud <= saddrb0;
--                 saddrb1_ud <= saddrb1;
--                 saddrb2_ud <= saddrb2;
--                 saddrb3_ud <= saddrb3;
--             else -- lower
--                 -- reverse addr b
--                 saddrb0_ud <= (not saddrb0) + conv_std_logic_vector(str01+end01+1,10);
--                 saddrb1_ud <= (not saddrb1) + conv_std_logic_vector(str01+end01+1,10);
--                 saddrb2_ud <= (not saddrb2) + conv_std_logic_vector(str23+end23+1,10);
--                 saddrb3_ud <= (not saddrb3) + conv_std_logic_vector(str23+end23+1,10);
--             end if;

            -- phase 2
            senb_ud   <= senb;
            sena_2d   <= sena_1d;
            shsync_2d <= shsync_1d;
            svsync_2d <= svsync_1d;
            shcnt_2d  <= shcnt_1d;
            svcnt_2d  <= svcnt_1d;
        end if;
    end process;

    --# output register process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                shcnt_out  <= (others => '0');
                svcnt_out  <= (others => '0');
                sdata_out  <= (others => '0');
            else
--          shsync_out <= shsync_1d;
--          svsync_out <= svsync_1d;
--          shcnt_out  <= shcnt_1d;
--          svcnt_out  <= svcnt_1d;
--          sdata_out  <= sdoutb1 & sdoutb0 & sdoutb3 & sdoutb2;
                shsync_out <= shsync_2d;
                svsync_out <= svsync_2d;
                shcnt_out  <= shcnt_2d;
                svcnt_out  <= svcnt_2d;
                sdata_out  <= sdoutb0 & sdoutb1 & sdoutb2 & sdoutb3;
--          if ROIC_DUAL = 1 then
-- --            if MODE_LOWER_NORMAL = '1' then
--                 sdata_out <= sdoutb1 & sdoutb0 & sdoutb3 & sdoutb2;
--             elsif svcnt_2d(0) = '0' then -- upper
--                 sdata_out <= sdoutb1 & sdoutb0 & sdoutb3 & sdoutb2;
--             else
--                 sdata_out <= sdoutb2 & sdoutb3 & sdoutb0 & sdoutb1;
--             end if;
            end if;
        end if;
    end process;

    ohsync <= shsync_out;
    ovsync <= svsync_out;
    ohcnt  <= shcnt_out;
    ovcnt  <= svcnt_out;
    odata  <= sdata_out;

    --# 1-clock delay process
    process (iui_clk)
    begin
        if (iui_clk'event and iui_clk = '1') then
            if (iui_rstn = '0') then
                sena_1d   <= '0';
                shsync_1d <= '0';
                svsync_1d <= '0';
                shcnt_1d  <= (others => '0');
                svcnt_1d  <= (others => '0');
            else
                sena_1d   <= sena;
                shsync_1d <= shsync;
                svsync_1d <= svsync;
                shcnt_1d  <= shcnt;
                svcnt_1d  <= svcnt;
            end if;
        end if;
    end process;

end Behavioral;
