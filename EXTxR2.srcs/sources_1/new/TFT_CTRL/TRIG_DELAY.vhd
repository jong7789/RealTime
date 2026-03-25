library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity TRIG_DELAY is
    port (
        imain_clk       : in    std_logic;
        imain_rstn      : in    std_logic;

        ireg_grab_en    : in    std_logic;
        ireg_trig_delay : in    std_logic_vector(15 downto 0);
        ireg_trig_filt  : in    std_logic_vector(7 downto 0);

        itft_busy       : in    std_logic;

        iext_trig       : in    std_logic;
        oext_trig       : out   std_logic
    );
end TRIG_DELAY;

architecture Behavioral of TRIG_DELAY is

    component FIFO_1x65536 is
        port (
            clk   : in    std_logic;
            srst  : in    std_logic;
            din   : in    std_logic;
            wr_en : in    std_logic;
            rd_en : in    std_logic;
            dout  : out   std_logic;
            full  : out   std_logic;
            empty : out   std_logic
        );
    end component;

    signal sgrab_en       : std_logic;
    signal strig_delay    : std_logic_vector(15 downto 0);
    signal strig_filter   : std_logic_vector(7 downto 0);
    signal sext_trig_cnt  : std_logic_vector(7 downto 0);

    signal slow_clk       : std_logic;
    signal slow_rstn      : std_logic;
    signal slow_cnt       : std_logic_vector(7 downto 0);

    type tstate_delay is (
        s_IDLE,
        s_DELAY,
        s_DATA
    );

    signal state_delay    : tstate_delay := s_IDLE;

    signal sfifo_din      : std_logic;
    signal sfifo_wr_en    : std_logic;
    signal sfifo_srst     : std_logic;
    signal sfifo_rd_en    : std_logic;
    signal sfifo_dout     : std_logic;
    signal sfifo_empty    : std_logic;
    signal sfifo_full     : std_logic;

    signal sdelay_cnt     : std_logic_vector(15 downto 0);

    signal sext_trig2     : std_logic;

    signal sext_trig_1d   : std_logic;
    signal sext_trig2_1d  : std_logic;

begin

    --# trigger filter process
    process(imain_clk)
    begin
        if imain_clk'event and imain_clk = '1' then
            if imain_rstn = '0' then
                sext_trig2    <= '0';
                strig_filter  <= (others => '0');
                sext_trig_cnt <= (others => '0');
            else
                if iext_trig = sext_trig_1d then
                    if sext_trig_cnt >= strig_filter then
                        sext_trig2    <= iext_trig;
                        strig_filter  <= ireg_trig_filt;
                    else
                        sext_trig_cnt <= sext_trig_cnt + '1';
                    end if;
                else
                    sext_trig_cnt <= (others => '0');
                end if;
            end if;
        end if;
    end process;

    --# slow clock divider process
    process(imain_clk)
    begin
        if imain_clk'event and imain_clk = '1' then
            if imain_rstn = '0' then
                slow_clk <= '0';
                slow_cnt <= (others => '0');
            else
                if SIMULATION = "OFF" then
                    if slow_cnt = 24 then
                        slow_clk <= not slow_clk;
                        slow_cnt <= (others => '0');
                    else
                        slow_cnt <= slow_cnt + '1';
                    end if;
                else
                    slow_clk <= not slow_clk;
                end if;
            end if;
        end if;
    end process;

    slow_rstn  <= imain_rstn;
    sfifo_srst <= not imain_rstn;

    U0_FIFO_1x65536 : FIFO_1x65536
        port map (
            clk   => slow_clk,
            srst  => sfifo_srst,
            din   => sfifo_din,
            wr_en => sfifo_wr_en,
            rd_en => sfifo_rd_en,
            dout  => sfifo_dout,
            full  => sfifo_full,
            empty => sfifo_empty
        );

    --# fifo write control process
    process(slow_clk)
    begin
        if slow_clk'event and slow_clk = '1' then
            if slow_rstn = '0' then
                sfifo_din   <= '0';
                sfifo_wr_en <= '0';
            else
                if sgrab_en = '0' then
                    sfifo_wr_en <= '0';
                elsif sfifo_empty = '1' then
                    if sext_trig2 = '1' and sext_trig2_1d = '0' then
                        sfifo_wr_en <= '1';
                    end if;
                end if;
                sfifo_din <= sext_trig2;
            end if;
        end if;
    end process;

    --# delay state machine process
    process(slow_clk)
    begin
        if slow_clk'event and slow_clk = '1' then
            if slow_rstn = '0' then
                state_delay <= s_IDLE; -- added, ext_in dose not work after "wtp" -> rstn -- 210720mbh
                sfifo_rd_en <= '1';
                sdelay_cnt  <= (others => '0');
                strig_delay <= (others => '0');
            else
                case (state_delay) is
                    when s_IDLE =>
                        if sfifo_wr_en = '1' then
                            state_delay <= s_DELAY;

                            sfifo_rd_en <= '0';
                            sdelay_cnt  <= (others => '0');
                            strig_delay <= ireg_trig_delay;
                        end if;

                    when s_DELAY =>
                        if sfifo_wr_en = '1' then
                            if sdelay_cnt >= strig_delay then
                                state_delay <= s_DATA;
                                sfifo_rd_en <= '1';
                            else
                                sdelay_cnt <= sdelay_cnt + '1';
                            end if;
                        else
                            state_delay <= s_DATA;
                            sfifo_rd_en <= '1';
                        end if;

                    when s_DATA =>
                        if sfifo_empty = '1' then
                            state_delay <= s_IDLE;
                            sfifo_rd_en <= '0';
                        end if;

                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    -- oext_trig		<= sfifo_dout;
    oext_trig <= iext_trig; -- dont use tri_delay at all. 211028

    --# trigger 1-cycle delay and grab enable latch process
    process(imain_clk)
    begin
        if imain_clk'event and imain_clk = '1' then
            if imain_rstn = '0' then
                sext_trig_1d <= '0';
            else
                sext_trig_1d <= iext_trig;
                if itft_busy = '0' then
                    sgrab_en <= ireg_grab_en;
                end if;
            end if;
        end if;
    end process;

    --# trigger2 1-cycle delay process
    process(slow_clk)
    begin
        if slow_clk'event and slow_clk = '1' then
            if slow_rstn = '0' then
                sext_trig2_1d <= '0';
            else
                sext_trig2_1d <= sext_trig2;
            end if;
        end if;
    end process;

end Behavioral;
