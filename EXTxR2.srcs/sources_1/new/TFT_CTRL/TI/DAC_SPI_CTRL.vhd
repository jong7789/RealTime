----------------------------------------------------------------------------------
-- Company: DRTech
-- Engineer: mbh
-- Create Date: 2022/04/28 11:49:41
-- Module Name: DAC_SPI_CTRL - Behavioral
-- Project Name: AD5621 spi driver
----------------------------------------------------------------------------------

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
--  use WORK.TOP_HEADER.ALL;

library UNISIM;
    use UNISIM.VComponents.all;

entity DAC_SPI_CTRL is
    port (
        i_clk  : in    std_logic; -- 100 MHz
        i_rstn : in    std_logic;

        i_reg_pwdac_cmd       : in    std_logic_vector(16 - 1 downto 0);
        i_reg_pwdac_ticktime  : in    std_logic_vector(32 - 1 downto 0);
        i_reg_pwdac_tickinc   : in    std_logic_vector(12 - 1 downto 0);
        i_reg_pwdac_trig      : in    std_logic;
        o_reg_pwdac_currlevel : out   std_logic_vector(16 - 1 downto 0);

        o_clk   : out   std_logic;
        o_syncn : out   std_logic;
        o_data  : out   std_logic
    );
end entity dac_spi_ctrl;

architecture behavioral of dac_spi_ctrl is

    signal clk         : std_logic := '0';
    signal rstn        : std_logic := '0';
    signal clk_cnt     : std_logic_vector(2 - 1 downto 0) := (others=> '0');
    signal clken       : std_logic := '0';
    signal cmd_clkmode : std_logic := '0';

    type   state_type is (st_idle, st_ready, st_cmd, st_wait, st_judge, st_end);
    signal sm_dac      : state_type;
    signal next_sm_dac : state_type;

    signal reg_pwdac_cmd      : std_logic_vector(16 - 1 downto 0);
    signal reg_pwdac_ticktime : std_logic_vector(32 - 1 downto 0);
    signal reg_pwdac_tickinc  : std_logic_vector(12 - 1 downto 0);

    signal cmd0    : std_logic_vector(16 - 1 downto 0);
    signal cmd1    : std_logic_vector(16 - 1 downto 0);
    signal cmd     : std_logic_vector(16 - 1 downto 0);
    signal cmd_pd  : std_logic_vector(2 - 1 downto 0) := (others=> '0');
    signal cmd_d12 : std_logic_vector(12 - 1 downto 0) := (others=> '0');
    signal cur_d12 : std_logic_vector(12 - 1 downto 0) := (others=> '0');

    signal ticktime0 : std_logic_vector(32 - 1 downto 0);
    signal ticktime1 : std_logic_vector(32 - 1 downto 0);
    signal ticktime  : std_logic_vector(32 - 1 downto 0);

    signal tickinc0 : std_logic_vector(12 - 1 downto 0);
    signal tickinc1 : std_logic_vector(12 - 1 downto 0);
    signal tickinc  : std_logic_vector(12 - 1 downto 0);

    signal trig0      : std_logic := '0';
    signal trig1      : std_logic := '0';
    signal start_trig : std_logic := '0';

    signal ready_done : std_logic := '0';
    signal wait_done  : std_logic := '0';
    signal judge_done : std_logic := '0';
    signal cmd_done   : std_logic := '0';
    signal end_done   : std_logic := '0';

    signal sm_ready_cnt : std_logic_vector(4 - 1 downto 0) := (others=> '0');
    signal sm_cmd_cnt   : std_logic_vector(4 - 1 downto 0) := (others=> '0');
    signal sm_wait_cnt  : std_logic_vector(32 - 1 downto 0) := (others=> '0');
    signal sm_end_cnt   : std_logic_vector(4 - 1 downto 0) := (others=> '0');

    signal sm_timeout_cnt : std_logic_vector(28 - 1 downto 0) := (others=> '0');

    signal timeout : std_logic := '0';

    signal sync : std_logic := '0';
    signal data : std_logic := '0';

    signal trigi       : std_logic := '0';
    signal trigi_shift : std_logic_vector(16 - 1 downto 0) := (others=> '0');
    signal trig_shft   : std_logic_vector(8 - 1 downto 0) := (others=> '0');

    component ila_pwdac0
        port (
            clk     : in    std_logic;
            probe0  : in    state_type; -- STD_LOGIC_VECTOR(1 DOWNTO 0);
            probe1  : in    std_logic_vector(1 downto 0);
            probe2  : in    std_logic_vector(11 downto 0);
            probe3  : in    std_logic_vector(11 downto 0);
            probe4  : in    std_logic_vector(15 downto 0);
            probe5  : in    std_logic_vector(11 downto 0);
            probe6  : in    std_logic_vector(0 downto 0);
            probe7  : in    std_logic_vector(0 downto 0);
            probe8  : in    std_logic_vector(0 downto 0);
            probe9  : in    std_logic_vector(0 downto 0);
            probe10 : in    std_logic_vector(0 downto 0);
            probe11 : in    std_logic_vector(0 downto 0)
        );
    end component;

--!begin

begin

--  u_ila_pwdac0 : ila_pwdac0
--  PORT MAP (
--    clk        => clk        , --
--    probe0     => sm_dac     , -- 2
--    probe1     => cmd_pd     , -- 2
--    probe2     => cmd_d12    , -- 12
--    probe3     => cur_d12    , -- 12
--    probe4     => ticktime(16-1 downto 0)   , -- 16
--    probe5     => tickinc    , -- 12
--    probe6 (0) => start_trig , -- 1
--    probe7 (0) => cmd_done   , -- 1
--    probe8 (0) => wait_done  , -- 1
--    probe9 (0) => judge_done , -- 1
--    probe10(0) => sync       , -- 1
--    probe11(0) => data         -- 1
--  );

--#######################
--### 100Mhz -> 25Mhz ###
--    process (i_clk)
--    begin
--        if i_clk'event and i_clk='1' then
--            --
--            clk_cnt     <= clk_cnt + '1';
--            trigi_shift <= trigi_shift(trigi_shift'LEFT - 1 downto 0) & i_reg_pwdac_trig;
--            if trigi_shift = 0 then
--                trigi <= '0';
--            else
--                trigi <= '1';
--            end if;
--            --
--        end if;
--    end process;

--    u_bufg25Mhz : BUFG
--        port map (
--            I => clk_cnt(1),
--            O => clk -- 25Mhz
--        );
--    rstn <= i_rstn;

--##############
--### mclk ###
    clk   <= i_clk;
    trigi <= i_reg_pwdac_trig;
    rstn  <= i_rstn;

--#################
--### registers ###

    process (clk)
    begin
        if clk'event and clk='1' then
            --
            trig_shft  <= trig_shft(trig_shft'left - 1 downto 0) & trigi; -- 1 clk catched trig --# 220503
            start_trig <= (not trig_shft(trig_shft'left)) and trig_shft(trig_shft'left - 1);
            if start_trig = '1' then
                reg_pwdac_cmd      <= i_reg_pwdac_cmd;
                reg_pwdac_ticktime <= i_reg_pwdac_ticktime;
                reg_pwdac_tickinc  <= i_reg_pwdac_tickinc;
            end if;

            cmd0        <= reg_pwdac_cmd;
            cmd1        <= cmd0;
            cmd_pd      <= cmd1(15 downto 14); --# powerdown mode 0:normal 
            cmd_d12     <= cmd1(13 downto 2);  --# 12bit dac data
--            cmd_clkmode <= start_trig; --# mis matching signal 220524mbh -- cmd1(0);            
                --# 0:clk working during active 1: always

            ticktime0 <= reg_pwdac_ticktime;
            ticktime1 <= ticktime0;
            --# underlimit 32
            if ticktime1 < 32 then
                ticktime <= conv_std_logic_vector(32, 32);
            else
                ticktime <= ticktime1; --# 1 command wating time
            end if;

            tickinc0 <= reg_pwdac_tickinc;
            tickinc1 <= tickinc0;
            tickinc  <= tickinc1 +'1'; --# not allow all'F'

                --
        end if;
    end process;

-- #####################
-- ### state machine ###
    SYNC_PROC : process (clk)
    begin
        if (clk'event and clk = '1') then
            --
            if rstn = '0' then
                sm_dac <= st_idle;
            elsif timeout = '1' then
                sm_dac <= st_idle;
            else
                sm_dac <= next_sm_dac;
            end if;

            if sm_dac = st_idle then
                sm_timeout_cnt <= (others=> '0');
            else
                sm_timeout_cnt <= sm_timeout_cnt + '1';
            end if;

            if sm_dac = st_ready then
                sm_ready_cnt <= sm_ready_cnt + '1';
            else
                sm_ready_cnt <= (others=> '0');
            end if;

            if sm_dac = st_cmd then
                sm_cmd_cnt <= sm_cmd_cnt + '1';
            else
                sm_cmd_cnt <= (others=> '0');
            end if;

            if sm_dac = st_cmd or
               sm_dac = st_wait then
                sm_wait_cnt <= sm_wait_cnt + '1';
            else
                sm_wait_cnt <= (others=> '0');
            end if;

            if sm_dac = st_judge then
                if cur_d12 + tickinc < cmd_d12 then
                    cur_d12 <= cur_d12 + tickinc;
                elsif cur_d12 > cmd_d12 + tickinc then
                    cur_d12 <= cur_d12 - tickinc;
                else
                    cur_d12 <= cmd_d12;
                end if;
            end if;

            if sm_dac = st_end then
                sm_end_cnt <= sm_end_cnt + '1';
            else
                sm_end_cnt <= (others=> '0');
            end if;

            cmd <= cmd_pd & cur_d12 & "00";

            --
        end if;
    end process;

    OUTPUT_DECODE : process (sm_timeout_cnt, sm_dac,
                             sm_cmd_cnt, sm_wait_cnt,
                             sm_ready_cnt, sm_end_cnt,
                             cmd_d12, cur_d12)
    begin
        --# timeout time = 2**28/25MHz = 10 sec
        if sm_timeout_cnt = x"FFF_FFFF" then
            timeout <= '1';
        else
            timeout <= '0';
        end if;

        if sm_dac = st_cmd and
           sm_cmd_cnt >= 16 - 1 then
            cmd_done <= '1';
        else
            cmd_done <= '0';
        end if;

        if sm_dac = st_wait and
           sm_wait_cnt + 2 >= ticktime then
           --# +2 need gap for 0 start and state judge time
            wait_done <= '1';
        else
            wait_done <= '0';
        end if;

        if sm_dac = st_cmd then
            sync <= '1';
        else
            sync <= '0';
        end if;

        --### making SPI data ###
        if sm_dac = st_cmd then
            data <= cmd(conv_integer(not sm_cmd_cnt));
        else
            data <= '0';
        end if;

        if sm_dac = st_judge then
            if cmd_d12 = cur_d12 then
                judge_done <= '1';
            else
                judge_done <= '0';
            end if;
        end if;

        if sm_dac = st_ready and
           sm_ready_cnt = 4-1 then
            ready_done <= '1';
        else
            ready_done <= '0';
        end if;

        if sm_dac = st_end and
           sm_end_cnt = 4-1 then
            end_done <= '1';
        else
            end_done <= '0';
        end if;

--        if cmd_clkmode = '1' then
        if start_trig = '1' then --# 220524mbh
            clken <= '1';
        elsif sm_dac = st_idle then
            clken <= '0';
        else
            clken <= '1';
        end if;

    end process;

    NEXT_STATE_DECODE : process (sm_dac, start_trig,
                                 ready_done, end_done,
                                 cmd_done, wait_done, judge_done)
    begin
        next_sm_dac <= sm_dac;

        case (sm_dac) is
            when st_idle =>
                if start_trig = '1' then
                    next_sm_dac <= st_ready;
                end if;
            when st_ready =>
                if ready_done = '1' then
                    next_sm_dac <= st_cmd;
                end if;
            when st_cmd =>
                if cmd_done = '1' then
                    next_sm_dac <= st_wait;
                end if;
            when st_wait =>
                if wait_done = '1' then
                    next_sm_dac <= st_judge;
                end if;
            when st_judge =>
                if judge_done = '1' then
                    next_sm_dac <= st_end;
                else
                    next_sm_dac <= st_cmd;
                end if;
            when st_end =>
                if end_done = '1' then
                    next_sm_dac <= st_idle;
                end if;
            when others =>
                next_sm_dac <= st_idle;
        end case;

    end process;

--###########
--### out ###
    o_reg_pwdac_currlevel <= x"0" & cur_d12;
    o_clk                 <= clk when clken = '1' else '0';
    o_syncn               <= not sync;
    o_data                <= data;

end architecture behavioral;
