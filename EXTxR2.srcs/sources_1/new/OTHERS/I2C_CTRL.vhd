library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
    use UNISIM.VCOMPONENTS.ALL;
    use WORK.TOP_HEADER.ALL;

--# 2608191217 Single I2C master, now serving two physical 2-wire buses:
--#   slaves 0..3 = temperature ICs (NCT175/DS1731, addr prefix "1001") on TEMP_SCL/TEMP_SDA
--#   slave  4    = SFP module DDM  (SFF-8472 A2h = 0x51, prefix "1010") on SFP_SCL/SFP_SDA
--# Only one bus is driven at a time (selected by si2c_scnt); the idle bus is held Hi-Z.
--# SFP_NUM=0 removes the SFP bus entirely, leaving the original 4-slave behavior untouched.
entity I2C_CTRL is
    generic (
        SLAVE_NUM   : integer;
        SFP_NUM     : integer := 0; --# 2608191217 1 = last slave (index 4) is the SFP DDM device
        SLAVE_ADDR0 : std_logic_vector(2 downto 0);
        SLAVE_ADDR1 : std_logic_vector(2 downto 0);
        SLAVE_ADDR2 : std_logic_vector(2 downto 0);
        SLAVE_ADDR3 : std_logic_vector(2 downto 0);
        SLAVE_ADDR4 : std_logic_vector(2 downto 0) := "001" --# 2608191217 SFP A2h -> 0x51
    );
    port (
        iui_clk         : in    std_logic;
        iui_rstn        : in    std_logic;

        ireg_i2c_mode   : in    std_logic;
        ireg_i2c_wen    : in    std_logic;
        ireg_i2c_wsize  : in    std_logic_vector(3 downto 0);
        ireg_i2c_wdata  : in    std_logic_vector(31 downto 0);
        ireg_i2c_ren    : in    std_logic;
        ireg_i2c_rsize  : in    std_logic_vector(3 downto 0);
        --# 2608191217 SFP slave control, both carried by ADDR_I2C_MODE (0x0140)
        ireg_i2c_sfp_en  : in   std_logic;                    --# MODE[1]    : include slave 4 in the sweep
        ireg_i2c_sfp_ptr : in   std_logic_vector(7 downto 0); --# MODE[15:8] : byte pointer sent to slave 4
        oreg_i2c_rdata0 : out   std_logic_vector(31 downto 0);
        oreg_i2c_rdata1 : out   std_logic_vector(31 downto 0);
        oreg_i2c_rdata2 : out   std_logic_vector(31 downto 0);
        oreg_i2c_rdata3 : out   std_logic_vector(31 downto 0);
        oreg_i2c_rdata4 : out   std_logic_vector(31 downto 0); --# 2608191217 SFP slave result
        oreg_i2c_done   : out   std_logic;

        oi2c_scl        : out   std_logic;
        ioi2c_sda       : inout std_logic;
        --# 2608191217 SFP 2-wire bus, null array when SFP_NUM=0
        oi2c_sfp_scl    : out   std_logic_vector(SFP_NUM - 1 downto 0);
        ioi2c_sfp_sda   : inout std_logic_vector(SFP_NUM - 1 downto 0)
    );
end I2C_CTRL;

architecture Behavioral of I2C_CTRL is

    --# 2608191932 SCL timing. Was: 11-bit counter (185MHz/2048 = 90.3kHz) with SCL high
    --# over counts 1280..1791, while SDA was captured at count 1024 - i.e. 1.38us BEFORE
    --# SCL even rose, with SCL still low. That left only 1280 counts (6.92us) for the
    --# pulled-up SDA line to settle after the previous SCL fall, and released '1' bits
    --# were occasionally read as '0' (NCT175 41.9C seen as 9.4C: bits 13 and 7 both 1->0).
    --# Now: 12-bit counter (185MHz/4096 = 45.2kHz), same high-phase ratio (0.625..0.875),
    --# and SDA sampled at the CENTRE of the SCL high pulse -> 3584 counts (19.4us) of
    --# settling, 2.8x the old margin. Still within the SFF-8472 100kHz limit.
    constant SCL_CNT_BITS : integer := 12;
    constant SCL_HI_START : integer := 2560; -- SCL rises  (0.625 * 4096)
    constant SCL_HI_END   : integer := 3584; -- SCL falls  (0.875 * 4096)
    constant SCL_SMP_CNT  : integer := 3072; -- SDA sample point, centre of the high pulse

    signal sclk     : std_logic;
--  signal sclk_cnt : std_logic_vector(11 - 1 downto 0);
    signal sclk_cnt : std_logic_vector(SCL_CNT_BITS - 1 downto 0); --# 2608191932
    signal sclk_smp : std_logic; --# 2608191932 one iui_clk strobe at SCL_SMP_CNT

    signal si2c_clk  : std_logic;
    signal si2c_rstn : std_logic;

    type tstate_i2c is (
        s_IDLE,   -- 0
        s_READY,  -- 1
        s_START,  -- 2
        s_STOP,   -- 3
        s_CTRL,   -- 4
        s_WDATA,  -- 5
        s_RDATA,  -- 6
        s_ACK_S,  -- 7
        s_ACK_M,  -- 8
        s_NACK_M, -- 9
        s_WAIT    -- 10
    );

    signal state_i2c : tstate_i2c;

    signal si2c_mode  : std_logic;
    signal si2c_wen   : std_logic;
    signal si2c_ren   : std_logic;
    signal si2c_wsize : std_logic_vector(3 downto 0);
    signal si2c_rsize : std_logic_vector(3 downto 0);
    signal si2c_done  : std_logic;
    signal si2c_ctrl  : std_logic_vector(7 downto 0);
    signal si2c_wdata : std_logic_vector(31 downto 0);
    signal si2c_rdata : std_logic_vector(31 downto 0);

    signal si2c_rdata0 : std_logic_vector(31 downto 0);
    signal si2c_rdata1 : std_logic_vector(31 downto 0);
    signal si2c_rdata2 : std_logic_vector(31 downto 0);
    signal si2c_rdata3 : std_logic_vector(31 downto 0);
    signal si2c_rdata4 : std_logic_vector(31 downto 0); --# 2608191217 SFP slave result

    --# 2608191217 SFP slave (index SLAVE_NUM-1 when SFP_NUM=1) control and bus routing
    signal si2c_sfp_en     : std_logic;
    signal si2c_sfp_ptr    : std_logic_vector(7 downto 0);
    signal si2c_bus_sfp    : std_logic;                     -- current slave sits on the SFP bus
    signal si2c_last_slave : integer range 0 to 7;          -- sweep wrap point (SFP slave optional)
    signal si2c_wdata_eff  : std_logic_vector(31 downto 0); -- wdata with SFP pointer substituted
    signal si2c_scl_temp   : std_logic;
    signal si2c_scl_sfp    : std_logic;
    signal si2c_t_temp     : std_logic;
    signal si2c_t_sfp      : std_logic;
    signal si2c_sfp_iobuf_o : std_logic;

    signal si2c_bcnt   : integer range 0 to 7;
    signal si2c_wcnt   : integer range 0 to 7;
    signal si2c_rcnt   : integer range 0 to 7;
    signal si2c_scnt   : integer range 0 to 7;
    signal si2c_rw     : std_logic;
    signal si2c_rw_end : std_logic;

    signal si2c_scl_en : std_logic;
    signal si2c_scl    : std_logic;
    signal si2c_sda_i  : std_logic;
    signal si2c_sda_o  : std_logic;

    signal si2c_iobuf_i : std_logic;
    signal si2c_iobuf_o : std_logic;
    signal si2c_iobuf_t : std_logic;

    signal swait_cnt  : std_logic_vector(31 downto 0);
    signal swait_time : std_logic_vector(31 downto 0);

    signal state_i2c_1d : tstate_i2c;
    signal si2c_bcnt_1d : integer range 0 to 7;
    signal si2c_rcnt_1d : integer range 0 to 7;
    signal si2c_wen_1d  : std_logic;
    signal si2c_wen_2d  : std_logic;
    signal si2c_wen_3d  : std_logic;
    signal si2c_wen_4d  : std_logic;
    signal si2c_ren_1d  : std_logic;
    signal si2c_ren_2d  : std_logic;
    signal si2c_ren_3d  : std_logic;
    signal si2c_ren_4d  : std_logic;

    signal debugnum  : std_logic_vector(8 - 1 downto 0);
    signal ila_clk   : std_logic;
    signal sclk0     : std_logic;
    signal sclk1     : std_logic;
    signal sclk_cnt0 : std_logic_vector(12 - 1 downto 0);

    component ILA_IC_CTRL
        port (
            clk    : in    std_logic;
            probe0 : in    std_logic;
            probe1 : in    std_logic;
            probe2 : in    std_logic;
            probe3 : in    tstate_i2c
        );
    end component;

    COMPONENT ila_i2c
        PORT (
            clk     : IN STD_LOGIC;
            probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe2  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe3  : IN tstate_i2c; -- STD_LOGIC_VECTOR(3 DOWNTO 0);
            probe4  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            probe5  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            probe6  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            probe7  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
            probe8  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe9  : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe10 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe11 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe12 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe13 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            probe14 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe15 : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            probe16 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            probe17 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
        );
    END COMPONENT;

begin
--           _____      _____      _____      _____
--          |     |    |     |    |     |    |     |
-- sclk  ----     ------     ------     ------     -
--            ___        ___        ___        ___
--            | |        | |        | |        | |
-- sclk1 -----   --------   --------   --------   --
    SYNTH : if(SIMULATION = "OFF") generate
    begin
        swait_time <= conv_std_logic_vector(32, 32); -- about 1 ms

        --# clock divider process (iui_clk -> sclk)
        process (iui_clk)
        begin
            if iui_clk'event and iui_clk = '1' then
                if iui_rstn = '0' then
                    sclk     <= '0';
                    sclk_cnt <= (others => '0');
                    sclk_smp <= '0'; --# 2608191932
                else
                    -- iui_clk = 185MHz
--                  -- sclk = 185M/2048 = 90KHz
                    --# 2608191932 sclk = 185M/4096 = 45KHz
                    sclk_cnt <= sclk_cnt + '1'; -- 12b, 0 to 4095

                    -- # cutted clk
--                  if    sclk_cnt = 1024 + 256 then
--                      sclk1 <= '1';
--                  elsif sclk_cnt = 1024 + 256 + 512 then
--                      sclk1 <= '0';
--                  end if;
                    --# 2608191932 same high-phase ratio (0.625..0.875), doubled period
                    if    sclk_cnt = SCL_HI_START then
                        sclk1 <= '1';
                    elsif sclk_cnt = SCL_HI_END then
                        sclk1 <= '0';
                    end if;

                    --# 2608191932 SDA sample strobe at the centre of the SCL high pulse.
                    --# It is also the point furthest from both sclk edges (0 and 2048), so
                    --# the sclk-domain signals read by the capture process are stable there.
                    if sclk_cnt = SCL_SMP_CNT then
                        sclk_smp <= '1';
                    else
                        sclk_smp <= '0';
                    end if;

                    sclk    <= sclk_cnt(sclk_cnt'left);
                    ila_clk <= sclk_cnt(6);
                end if;
            end if;
        end process;

        si2c_clk <= sclk;
    end generate;

    SIM : if(SIMULATION = "ON") generate
        swait_time <= conv_std_logic_vector(32, 32);
        si2c_clk   <= iui_clk;
        --# 2608191932 si2c_clk = iui_clk here, so hold the sample strobe asserted:
        --# the capture process then behaves exactly as the old si2c_clk-edge version.
        sclk_smp   <= '1';
    end generate;

    si2c_rstn <= iui_rstn;

    --# I2C main state machine process (falling edge)
    process (si2c_clk)
    begin
        if si2c_clk'event and si2c_clk = '0' then
            if si2c_rstn = '0' then
                state_i2c   <= s_IDLE;

                si2c_rdata0 <= (others => '0');
                si2c_rdata1 <= (others => '0');
                si2c_rdata2 <= (others => '0');
                si2c_rdata3 <= (others => '0');
                si2c_rdata4 <= (others => '0'); --# 2608191217

                si2c_done   <= '0';
                si2c_ctrl   <= (others => '0');

                si2c_bcnt   <= 7;
                si2c_wcnt   <= 0;
                si2c_rcnt   <= 0;
                si2c_scnt   <= 0;
                si2c_rw     <= '0';
                si2c_rw_end <= '0';
                swait_cnt   <= (others => '0');

                si2c_scl_en <= '0';
                si2c_sda_i  <= '1';
            else
                case (state_i2c) is
                    when s_IDLE =>
                        if si2c_mode = '0' then
                            if si2c_wen_3d = '1' and si2c_wen_4d = '0' then
                                debugnum    <= x"01";
                                state_i2c   <= s_READY;
                                si2c_rw     <= '0';
                                si2c_done   <= '0';
                            elsif si2c_ren_3d = '1' and si2c_ren_4d = '0' then
                                debugnum    <= x"02";
                                state_i2c   <= s_READY;
                                si2c_rw     <= '1';
                                si2c_done   <= '0';
                            else
                                debugnum    <= x"03";
                                state_i2c   <= s_IDLE;
                                si2c_done   <= '1';
                            end if;
                        else
                            debugnum    <= x"04";
                            state_i2c   <= s_READY;
                            si2c_rw     <= not si2c_rw;
                            si2c_done   <= '1';
                        end if;

                        si2c_scl_en <= '0';
                        si2c_sda_i  <= '1';

                    when s_READY =>
                        debugnum    <= x"05";
                        state_i2c   <= s_START;

                        si2c_bcnt   <= 7;
                        si2c_wcnt   <= conv_integer(si2c_wsize) - 1;
                        si2c_rcnt   <= conv_integer(si2c_rsize) - 1;
                        si2c_rw_end <= '0';

                        --# 2608191217 Slave 4 is the SFP DDM device: prefix "1010" (0x50/0x51),
                        --# slaves 0..3 keep the temperature-IC prefix "1001" (0x48-0x4F)
                        case (si2c_scnt) is
                            when 0      => si2c_ctrl <= "1001" & SLAVE_ADDR0 & '0';
                            when 1      => si2c_ctrl <= "1001" & SLAVE_ADDR1 & '0';
                            when 2      => si2c_ctrl <= "1001" & SLAVE_ADDR2 & '0';
                            when 3      => si2c_ctrl <= "1001" & SLAVE_ADDR3 & '0';
                            when 4      => si2c_ctrl <= "1010" & SLAVE_ADDR4 & '0';
                            when others => NULL;
                        end case;

                        si2c_scl_en <= '0';
                        si2c_sda_i  <= '1';

                    when s_START =>
                        debugnum    <= x"06";
                        state_i2c   <= s_CTRL;

                        si2c_scl_en <= '0';
                        si2c_sda_i  <= '0';

                    when s_CTRL =>
                        if si2c_bcnt = 0 then
                            debugnum    <= x"07";
                            state_i2c   <= s_ACK_S;
                            si2c_bcnt   <= 7;
                            si2c_sda_i  <= si2c_rw;
                        else
                            si2c_bcnt   <= si2c_bcnt - 1;
                            si2c_sda_i  <= si2c_ctrl(si2c_bcnt);
                        end if;

                        si2c_scl_en <= '1';

                    when s_WDATA =>
                        if si2c_bcnt = 0 then
                            debugnum    <= x"08";
                            state_i2c   <= s_ACK_S;
                            si2c_bcnt   <= 7;
                            if si2c_wcnt = 0 then
                                si2c_wcnt   <= conv_integer(si2c_wsize) - 1;
                                si2c_rw_end <= '1';
                            else
                                si2c_wcnt   <= si2c_wcnt - 1;
                                si2c_rw_end <= '0';
                            end if;
                        else
                            si2c_bcnt <= si2c_bcnt - 1;
                        end if;

                        si2c_scl_en <= '1';
                        --# 2608191217 si2c_wdata_eff substitutes the SFP byte pointer on slave 4
                        si2c_sda_i  <= si2c_wdata_eff((si2c_wcnt * 8) + si2c_bcnt);

                    when s_RDATA =>
                        if si2c_bcnt = 0 then
                            si2c_bcnt <= 7;
                            if si2c_rcnt = 0 then
                                debugnum    <= x"09";
                                state_i2c   <= s_NACK_M;
                                si2c_rcnt   <= conv_integer(si2c_rsize) - 1;
                                si2c_rw_end <= '1';
                            else
                                debugnum    <= x"10";
                                state_i2c   <= s_ACK_M;
                                si2c_rcnt   <= si2c_rcnt - 1;
                                si2c_rw_end <= '0';
                            end if;
                        else
                            si2c_bcnt <= si2c_bcnt - 1;
                        end if;

                        si2c_scl_en <= '1';

                    when s_ACK_S =>
                        if si2c_rw = '0' then
                            if si2c_rw_end = '1' then
                                debugnum  <= x"11";
                                state_i2c <= s_STOP;
                            else
                                debugnum  <= x"12";
                                state_i2c <= s_WDATA;
                            end if;
                        else
                            debugnum  <= x"13";
                            state_i2c <= s_RDATA;
                        end if;

                        si2c_bcnt   <= 7;

                        si2c_scl_en <= '1';
                        si2c_sda_i  <= '0';

                    when s_ACK_M =>
                        debugnum    <= x"14";
                        state_i2c   <= s_RDATA;

                        si2c_scl_en <= '1';
                        si2c_sda_i  <= '0';

                    when s_NACK_M =>
                        debugnum    <= x"15";
                        state_i2c   <= s_STOP;

                        si2c_scl_en <= '1';
                        si2c_sda_i  <= '1';

                    when s_STOP =>
                        if swait_cnt = 1 then
                            debugnum    <= x"16";
                            state_i2c   <= s_WAIT;
                            swait_cnt   <= (others => '0');

                            si2c_sda_i  <= '1';
                            si2c_scl_en <= '0';
                        else
                            si2c_sda_i  <= '0';
                            si2c_scl_en <= '1';
                            swait_cnt   <= swait_cnt + '1';
                        end if;

                    when s_WAIT =>
                        if swait_cnt = swait_time - 1 then
                            swait_cnt <= (others => '0');

                            if si2c_mode = '0' then
                                --# 2608191217 wrap on si2c_last_slave (drops slave 4 when SFP is off)
                                if si2c_scnt = si2c_last_slave then
                                    debugnum  <= x"17";
                                    state_i2c <= s_IDLE;
                                    si2c_scnt <= 0;
                                    si2c_done <= '1';
                                else
                                    debugnum  <= x"18";
                                    state_i2c <= s_READY;
                                    si2c_scnt <= si2c_scnt + 1;
                                    si2c_done <= '0';
                                end if;
                            else
                                debugnum  <= x"19";
                                state_i2c <= s_IDLE;
--                                if si2c_rw = '1' then
--                                    -- if(si2c_scnt = SLAVE_NUM - 1) then
--                                    --     si2c_scnt       <= 0;
--                                    --     si2c_rdata1     <= si2c_rdata;
--                                    if si2c_scnt = 3 then
                                    --     si2c_scnt       <= 0;
--                                        si2c_rdata3 <= si2c_rdata;
--                                    elsif si2c_scnt = 2 then
--                                        si2c_scnt   <= si2c_scnt + 1;
--                                        si2c_rdata2 <= si2c_rdata;
--                                    elsif si2c_scnt = 1 then
--                                        si2c_scnt   <= si2c_scnt + 1;
                                    --     si2c_rdata1     <= si2c_rdata;
--                                    else
--                                        si2c_scnt   <= si2c_scnt + 1;
--                                        si2c_rdata0 <= si2c_rdata;
--                                    end if;
--                                end if;
                                --# 2608191217 Auto-mode slave sweep now honors si2c_last_slave (was hardcoded 0..3).
                                --# SFP_NUM=0 -> last_slave stays 3, so the original NCT175 behavior is unchanged.
                                --# SFP_NUM=1 + sfp_en -> slave 4 (SFP A2h 0x51) joins the round-robin.
                                if si2c_rw = '1' then
                                    case (si2c_scnt) is
                                        when 0      => si2c_rdata0 <= si2c_rdata;
                                        when 1      => si2c_rdata1 <= si2c_rdata;
                                        when 2      => si2c_rdata2 <= si2c_rdata;
                                        when 3      => si2c_rdata3 <= si2c_rdata;
                                        when 4      => si2c_rdata4 <= si2c_rdata;
                                        when others => NULL;
                                    end case;

                                    if si2c_scnt = si2c_last_slave then
                                        si2c_scnt   <= 0;
                                    else
                                        si2c_scnt   <= si2c_scnt + 1;
                                    end if;
                                end if;
                            end if;
                        else
                            swait_cnt <= swait_cnt + '1';

                            -- ### i2c abnormal clear, force start, stop
                            -- if probe_out0 = '1' then
                            --     if swait_cnt = 64 then
                            --       si2c_sda_i      <= '0';
                            --     elsif swait_cnt = 128 then
                            --       si2c_sda_i      <= '1';
                            --     end if;
                            -- end if;

                        end if;

                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

--    --# I2C read data capture process (rising edge)
--    process (si2c_clk)
--    begin
--        if si2c_clk'event and si2c_clk = '1' then
--            if si2c_rstn = '0' then
--                si2c_rdata <= (others => '0');
--            else
--                if state_i2c_1d = s_RDATA then
--                    si2c_rdata((si2c_rcnt_1d * 8) + si2c_bcnt_1d) <= si2c_sda_o;
--                end if;
--            end if;
--        end if;
--    end process;
    --# 2608191932 I2C read data capture, now on iui_clk gated by sclk_smp.
    --# The old version sampled on the si2c_clk rising edge = count 1024, which is 256
    --# counts BEFORE SCL rises - SDA was read while SCL was still low, cutting the
    --# pulled-up line's settling budget. sclk_smp fires at the centre of the SCL high
    --# pulse instead. state_i2c_1d / si2c_rcnt_1d / si2c_bcnt_1d belong to the sclk
    --# domain but sclk is a synchronous divide of iui_clk and its edges sit 1024 counts
    --# away from SCL_SMP_CNT, so they are stable when sampled here.
    process (iui_clk)
    begin
        if iui_clk'event and iui_clk = '1' then
            if si2c_rstn = '0' then
                si2c_rdata <= (others => '0');
            else
                if sclk_smp = '1' and state_i2c_1d = s_RDATA then
                    si2c_rdata((si2c_rcnt_1d * 8) + si2c_bcnt_1d) <= si2c_sda_o;
                end if;
            end if;
        end if;
    end process;

    si2c_scl <= '1' when si2c_scl_en = '0'     else
                sclk when state_i2c_1d = s_STOP else -- exception
                sclk1; -- cutted clock

    si2c_iobuf_t <= '1' when (state_i2c_1d = s_RDATA or state_i2c_1d = s_ACK_S) else
                    '0';

    si2c_iobuf_i <= si2c_sda_i;

    --# 2608191217 Two-bus routing. si2c_scnt only changes inside s_WAIT (both buses idle),
    --# so the select is stable for a whole START..STOP transaction.
    --# The inactive bus is forced Hi-Z (T='1') so it is never driven by the other bus's traffic.
    si2c_bus_sfp <= '1' when (SFP_NUM > 0 and si2c_scnt = SLAVE_NUM - 1) else '0';

    --# 2608191217 Sweep wrap point: slave 4 only joins when the SFP bus exists and FW enabled it
    si2c_last_slave <= SLAVE_NUM - 1 when (SFP_NUM > 0 and si2c_sfp_en = '1') else
                       SLAVE_NUM - 1 - SFP_NUM;

    --# 2608191217 Slave 4 sends the SFP byte pointer (MODE[15:8]) instead of the temp-IC command
    si2c_wdata_eff <= (x"000000" & si2c_sfp_ptr) when si2c_bus_sfp = '1' else si2c_wdata;

    si2c_scl_temp <= '1' when si2c_bus_sfp = '1' else si2c_scl;
    si2c_scl_sfp  <= '1' when si2c_bus_sfp = '0' else si2c_scl;
    si2c_t_temp   <= '1' when si2c_bus_sfp = '1' else si2c_iobuf_t;
    si2c_t_sfp    <= '1' when si2c_bus_sfp = '0' else si2c_iobuf_t;

    si2c_sda_o    <= si2c_sfp_iobuf_o when si2c_bus_sfp = '1' else si2c_iobuf_o;

    SDA_IOBUF : IOBUF
        port map (
            I  => si2c_iobuf_i,
            IO => ioi2c_sda,
            O  => si2c_iobuf_o,
            T  => si2c_t_temp
        );

    U0_OBUF : OBUF
        port map (
            I => si2c_scl_temp,
            O => oi2c_scl
        );

    --# 2608191217 SFP bus pads, instantiated only when the model has an SFP cage
    GEN_SFP_BUS : if (SFP_NUM > 0) generate
        SFP_SDA_IOBUF : IOBUF
            port map (
                I  => si2c_iobuf_i,
                IO => ioi2c_sfp_sda(0),
                O  => si2c_sfp_iobuf_o,
                T  => si2c_t_sfp
            );

        U1_OBUF : OBUF
            port map (
                I => si2c_scl_sfp,
                O => oi2c_sfp_scl(0)
            );
    end generate GEN_SFP_BUS;

    GEN_NO_SFP_BUS : if (SFP_NUM = 0) generate
        si2c_sfp_iobuf_o <= '1'; -- open-drain idle, never selected because si2c_bus_sfp = '0'
    end generate GEN_NO_SFP_BUS;

    oreg_i2c_rdata0 <= si2c_rdata0;
    oreg_i2c_rdata1 <= si2c_rdata1;
    oreg_i2c_rdata2 <= si2c_rdata2;
    oreg_i2c_rdata3 <= si2c_rdata3;
    oreg_i2c_rdata4 <= si2c_rdata4;
    oreg_i2c_done   <= si2c_done;

    --# I2C input register and delay chain process (falling edge)
    process (si2c_clk)
    begin
        if si2c_clk'event and si2c_clk = '0' then
            if si2c_rstn = '0' then
                si2c_mode    <= '0';
                si2c_wen     <= '0';
                si2c_ren     <= '0';
                si2c_wdata   <= (others => '0');
                si2c_wsize   <= (others => '0');
                si2c_rsize   <= (others => '0');
                si2c_sfp_en  <= '0';            --# 2608191217
                si2c_sfp_ptr <= (others => '0'); --# 2608191217

                state_i2c_1d <= s_IDLE;
                si2c_bcnt_1d <= 7;
                si2c_rcnt_1d <= 0;

                si2c_wen_1d  <= '0';
                si2c_wen_2d  <= '0';
                si2c_wen_3d  <= '0';
                si2c_wen_4d  <= '0';
                si2c_ren_1d  <= '0';
                si2c_ren_2d  <= '0';
                si2c_ren_3d  <= '0';
                si2c_ren_4d  <= '0';
            else
                if state_i2c = s_IDLE then
                    si2c_mode  <= ireg_i2c_mode;
                    si2c_wen   <= ireg_i2c_wen;
                    si2c_ren   <= ireg_i2c_ren;
                    si2c_wdata <= ireg_i2c_wdata;
                    si2c_wsize <= ireg_i2c_wsize;
                    si2c_rsize <= ireg_i2c_rsize;
                    --# 2608191217 latch SFP slave control alongside the other mode fields
                    si2c_sfp_en  <= ireg_i2c_sfp_en;
                    si2c_sfp_ptr <= ireg_i2c_sfp_ptr;
                end if;

                state_i2c_1d <= state_i2c;
                si2c_bcnt_1d <= si2c_bcnt;
                si2c_rcnt_1d <= si2c_rcnt;

                si2c_wen_1d  <= si2c_wen;
                si2c_wen_2d  <= si2c_wen_1d;
                si2c_wen_3d  <= si2c_wen_2d;
                si2c_wen_4d  <= si2c_wen_3d;
                si2c_ren_1d  <= si2c_ren;
                si2c_ren_2d  <= si2c_ren_1d;
                si2c_ren_3d  <= si2c_ren_2d;
                si2c_ren_4d  <= si2c_ren_3d;
            end if;
        end if;
    end process;

--    U0_ILA_IC_CTRL : ILA_IC_CTRL
--    port map (
--        clk    => si2c_clk,
--        probe0 => si2c_iobuf_i,
--        probe1 => si2c_iobuf_o,
--        probe2 => si2c_iobuf_t,
--        probe3 => state_i2c
--    );
-- u_ila_i2c : ila_i2c
-- PORT MAP (
--     clk        => ila_clk     ,
--     probe0 (0) => si2c_scl    , -- 1
--     probe1 (0) => si2c_iobuf_i, -- 1
--     probe2 (0) => si2c_scl_en , -- 1
--     probe3     => state_i2c   , -- 4 tstate_i2c
--     probe4     => conv_std_logic_vector(si2c_bcnt, 3), -- 3 int
--     probe5     => conv_std_logic_vector(si2c_wcnt, 3), -- 3 int
--     probe6     => conv_std_logic_vector(si2c_rcnt, 3), -- 3 int
--     probe7     => conv_std_logic_vector(si2c_scnt, 3), -- 3 int
--     probe8     => si2c_wdata  , -- 32
--     probe9     => si2c_rdata  , -- 32
--     probe10    => si2c_rdata0 , -- 32
--     probe11    => si2c_rdata1 , -- 32
--     probe12    => si2c_rdata2 , -- 32
--     probe13    => si2c_rdata3 , -- 32
--     probe14(0) => si2c_iobuf_o, -- 1
--     probe15    => debugnum    , -- 8
--     probe16(0) => si2c_iobuf_t , -- 1
--     probe17(0) => si2c_clk       -- 1
-- );
end Behavioral;
