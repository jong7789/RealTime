
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use WORK.TOP_HEADER.ALL;

entity AXI_IF is
    generic (
        GNR_MODEL : string := "EXT1616R"
    );
    port (
        -- Write
        ich0_wtrig : in    std_logic;
        ich0_waddr : in    std_logic_vector(31 downto 0);
        ich0_wdata : in    std_logic_vector(511 downto 0);
        ich1_wtrig : in    std_logic;
        ich1_waddr : in    std_logic_vector(31 downto 0);
        ich1_wdata : in    std_logic_vector(511 downto 0);
        ich2_wtrig : in    std_logic;
        ich2_waddr : in    std_logic_vector(31 downto 0);
        ich2_wdata : in    std_logic_vector(511 downto 0);
        ich3_wtrig : in    std_logic;
        ich3_waddr : in    std_logic_vector(31 downto 0);
        ich3_wdata : in    std_logic_vector(511 downto 0);
        ich4_wtrig : in    std_logic;
        ich4_waddr : in    std_logic_vector(31 downto 0);
        ich4_wdata : in    std_logic_vector(511 downto 0);

        -- Read
        ich0_rtrig : in    std_logic;
        ich0_raddr : in    std_logic_vector(31 downto 0);
        ich0_rvcnt : in    std_logic_vector(11 downto 0);
        ich1_rtrig : in    std_logic;
        ich1_raddr : in    std_logic_vector(31 downto 0);
        ich1_rvcnt : in    std_logic_vector(11 downto 0);
        ich2_rtrig : in    std_logic;
        ich2_raddr : in    std_logic_vector(31 downto 0);
        ich2_rvcnt : in    std_logic_vector(11 downto 0);
        ich3_rtrig : in    std_logic;
        ich3_raddr : in    std_logic_vector(31 downto 0);
        ich3_rvcnt : in    std_logic_vector(11 downto 0);
        ich4_rtrig : in    std_logic;
        ich4_raddr : in    std_logic_vector(31 downto 0);
        ich4_rvcnt : in    std_logic_vector(11 downto 0);

        -- From CPU
        iaxi_clk    : in    std_logic;
        iaxi_rstn   : in    std_logic;
        iaxi_rlast  : in    std_logic;
        iaxi_rvalid : in    std_logic;
        iaxi_rready : in    std_logic;
        iaxi_bready : in    std_logic;

        ireg_width : in    std_logic_vector(11 downto 0);

        -- For AXI MASTER IF
        oconv_wlen  : out   std_logic_vector(7 downto 0);
        oconv_wtrig : out   std_logic;
        oconv_waddr : out   std_logic_vector(31 downto 0);
        oconv_wdata : out   std_logic_vector(511 downto 0);
        iconv_wbusy : in    std_logic;
        oconv_rlen  : out   std_logic_vector(7 downto 0);
        oconv_rtrig : out   std_logic;
        oconv_raddr : out   std_logic_vector(31 downto 0);
        iconv_rdata : in    std_logic_vector(511 downto 0);
        oconv_rlast : out   std_logic;
        iconv_rbusy : in    std_logic;

        -- For Output
        iconv_clk   : in    std_logic;
        iconv_rstn  : in    std_logic;

        iconv_en    : in    std_logic;
        iconv_addr  : in    std_logic_vector(11 downto 0);
        iconv_vcnt  : in    std_logic_vector(11 downto 0);
        oconv_data0 : out   std_logic_vector(DDR_BIT_R0((GNR_MODEL)) - 1 downto 0);
        oconv_data1 : out   std_logic_vector(DDR_BIT_R1((GNR_MODEL)) - 1 downto 0);
        oconv_data2 : out   std_logic_vector(DDR_BIT_R2((GNR_MODEL)) - 1 downto 0);
        oconv_data3 : out   std_logic_vector(DDR_BIT_R3((GNR_MODEL)) - 1 downto 0);
        oconv_data4 : out   std_logic_vector(DDR_BIT_R4((GNR_MODEL)) - 1 downto 0);

        ostate_write : out tstate_write;
        owrite_ch    : out std_logic_vector(4 - 1 downto 0);
        ostate_read  : out tstate_read;
        oread_ch     : out std_logic_vector(4 - 1 downto 0)

    );
end entity axi_if;

architecture behavioral of axi_if is

    component AXI_RDATA_CONV is
        generic (
            data_depth : integer
        );
        port (
            iwr_clk  : in   std_logic;
            iwr_rstn : in   std_logic;

            iwr_en   : in   std_logic;
            iwr_addr : in   std_logic_vector(11 downto 0);
            iwr_vcnt : in   std_logic_vector(11 downto 0);
            iwr_data : in   std_logic_vector(511 downto 0);

            ird_clk  : in   std_logic;
            ird_rstn : in   std_logic;

            ird_en   : in   std_logic;
            ird_addr : in   std_logic_vector(11 downto 0);
            ird_vcnt : in   std_logic_vector(11 downto 0);
            ord_data : out  std_logic_vector(DATA_DEPTH - 1 downto 0)
        );
    end component;

--  type tstate_write is (
--      s_IDLE,
--      s_READY,
--      s_WAIT,
--      s_WRITE,
--      s_CHECK
--  );
--
--  type tstate_read is (
--      s_IDLE,
--      s_READY,
--      s_WAIT,
--      s_READ,
--      s_CHECK
--  );

    signal state_write : tstate_write;
    signal state_read  : tstate_read;

    signal swrite_ch : integer range 0 to 4;

    signal swaddr : std_logic_vector(31 downto 0);
    signal sraddr : std_logic_vector(31 downto 0);

    signal sch0_rbusy     : std_logic;
    signal sch1_rbusy     : std_logic;
    signal sch2_rbusy     : std_logic;
    signal sch3_rbusy     : std_logic;
    signal sch4_rbusy     : std_logic;
    signal sddr_ch0_wen   : std_logic;
    signal sddr_ch1_wen   : std_logic;
    signal sddr_ch2_wen   : std_logic;
    signal sddr_ch3_wen   : std_logic;
    signal sddr_ch4_wen   : std_logic;
    signal sddr_ch0_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch1_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch2_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch3_waddr : std_logic_vector(11 downto 0);
    signal sddr_ch4_waddr : std_logic_vector(11 downto 0);

    signal swlen     : std_logic_vector(11 downto 0);
    signal srlen     : std_logic_vector(11 downto 0);
    signal sch0_wlen : std_logic_vector(11 downto 0);
    signal sch1_wlen : std_logic_vector(11 downto 0);
    signal sch2_wlen : std_logic_vector(11 downto 0);
    signal sch3_wlen : std_logic_vector(11 downto 0);
    signal sch4_wlen : std_logic_vector(11 downto 0);
    signal sch0_rlen : std_logic_vector(11 downto 0);
    signal sch1_rlen : std_logic_vector(11 downto 0);
    signal sch2_rlen : std_logic_vector(11 downto 0);
    signal sch3_rlen : std_logic_vector(11 downto 0);
    signal sch4_rlen : std_logic_vector(11 downto 0);

    signal sconv_wlen  : std_logic_vector(7 downto 0);
    signal sconv_wtrig : std_logic;
    signal sconv_waddr : std_logic_vector(31 downto 0);
    signal sconv_rlen  : std_logic_vector(7 downto 0);
    signal sconv_rtrig : std_logic;
    signal sconv_raddr : std_logic_vector(31 downto 0);
    signal sconv_rlast : std_logic;

    signal sburst_wnum : std_logic_vector(3 downto 0);
    signal sburst_wcnt : std_logic_vector(7 downto 0);
    signal sburst_rnum : std_logic_vector(3 downto 0);
    signal sburst_rcnt : std_logic_vector(7 downto 0);

    signal saxi_rvalid_1d : std_logic;
    signal sch0_wtrig     : std_logic;
    signal sch1_wtrig     : std_logic;
    signal sch2_wtrig     : std_logic;
    signal sch3_wtrig     : std_logic;
    signal sch4_wtrig     : std_logic;
    signal sch0_rtrig     : std_logic;
    signal sch1_rtrig     : std_logic;
    signal sch2_rtrig     : std_logic;
    signal sch3_rtrig     : std_logic;
    signal sch4_rtrig     : std_logic;

    signal sconv_data0 : std_logic_vector(DDR_BIT_R0((GNR_MODEL)) - 1 downto 0);
    signal sconv_data1 : std_logic_vector(DDR_BIT_R1((GNR_MODEL)) - 1 downto 0);
    signal sconv_data2 : std_logic_vector(DDR_BIT_R2((GNR_MODEL)) - 1 downto 0);
    signal sconv_data3 : std_logic_vector(DDR_BIT_R3((GNR_MODEL)) - 1 downto 0);
    signal sconv_data4 : std_logic_vector(DDR_BIT_R4((GNR_MODEL)) - 1 downto 0);

begin

    ila_debug : if GEN_ILA_axi_if = "ON" generate

    component ila_axi_if_read
        port (
            clk     : in    std_logic;
            probe0  : in    std_logic;                      --_vector(0 downto 0);
            probe1  : in    std_logic_vector(11 downto 0);
            probe2  : in    std_logic_vector(11 downto 0);
            probe3  : in    std_logic_vector(15 downto 0);
            probe4  : in    std_logic;                      -- _vector(0 downto 0);
            probe5  : in    std_logic_vector(11 downto 0);
            probe6  : in    std_logic_vector(11 downto 0);

            probe7  : in    std_logic_vector(7 downto 0);
            probe8  : in    std_logic_vector(3 downto 0);
            probe9  : in    tstate_write;
            probe10 : in    std_logic;
            probe11 : in    std_logic_vector(31 downto 0)
        );
    end component;

    begin
    u_ila_axi_if_read : ila_axi_if_read
        port map (
            clk     => iaxi_clk,
            probe0  => sddr_ch1_wen,                    -- 1
            probe1  => sddr_ch1_waddr,                  -- 12
            probe2  => ich1_rvcnt,                      -- 12
            probe3  => iconv_rdata(16 - 1 downto 0),   -- 16/512/32
            probe4  => iconv_en,                        -- 1
            probe5  => iconv_addr,                      -- 12
            probe6  => iconv_vcnt,                      -- 12

            probe7  => sburst_rcnt,                     -- 8
            probe8  => sburst_rnum,                     -- 4
            probe9  => state_write,                     -- 3
            probe10 => sconv_rlast,                     -- 1
            probe11 => sraddr                           -- 32

        );

    end generate ila_debug;

    GEN_10G_LEN : if (GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") generate
    begin
        sch0_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch0_waddr = 0 else sch0_wlen; -- 512 / 16 bit = 2^5
--      sch1_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch1_waddr = 0 else sch1_wlen; -- 512 / 16 bit = 2^5
        sch1_wlen <= ("0000" & ireg_width(11 downto 4)) when sddr_ch1_waddr = 0 else sch1_wlen;  -- 512 / 32 bit = 2^4
        sch2_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch2_waddr = 0 else sch2_wlen; -- 512 / 16 bit = 2^5
        sch3_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch3_waddr = 0 else sch3_wlen; -- 512 / 16 bit = 2^5
        sch4_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch4_waddr = 0 else sch4_wlen; -- 512 / 16 bit = 2^5

        sch0_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch0_waddr = 0 else sch0_rlen; -- 512 / 16 bit = 2^5
--      sch1_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch1_waddr = 0 else sch1_rlen; -- 512 / 16 bit = 2^5
        sch1_rlen <= ("0000" & ireg_width(11 downto 4)) when sddr_ch1_waddr = 0 else sch1_rlen;  -- 512 / 32 bit = 2^4
        sch2_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch2_waddr = 0 else sch2_rlen; -- 512 / 16 bit = 2^5
        sch3_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch3_waddr = 0 else sch3_rlen; -- 512 / 16 bit = 2^5
        sch4_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch4_waddr = 0 else sch4_rlen; -- 512 / 16 bit = 2^5
    end generate GEN_10G_LEN;

    GEN_2p5G_LEN : if (GEV_SPEED_BY_MODEL(GNR_MODEL) = "2p5G") generate
    begin
        sch0_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch0_waddr = 0 else sch0_wlen; -- 512 / 16 bit = 2^5
        sch1_wlen <= ("00" & ireg_width(11 downto 2)) when sddr_ch1_waddr = 0 else sch1_wlen;    -- 512 / 128 bit = 2^2
        sch2_wlen <= ("0000" & ireg_width(11 downto 4)) when sddr_ch2_waddr = 0 else sch2_wlen;  -- 512 / 32 bit = 2^4
        sch3_wlen <= ("0000" & ireg_width(11 downto 4)) when sddr_ch3_waddr = 0 else sch3_wlen;  -- 512 / 32 bit = 2^4
        sch4_wlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch4_waddr = 0 else sch4_wlen; -- 512 / 16 bit = 2^5

        sch0_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch0_waddr = 0 else sch0_rlen; -- 512 / 16 bit = 2^5
        sch1_rlen <= ("00" & ireg_width(11 downto 2)) when sddr_ch1_waddr = 0 else sch1_rlen;    -- 512 / 128 bit = 2^2
        sch2_rlen <= ("0000" & ireg_width(11 downto 4)) when sddr_ch2_waddr = 0 else sch2_rlen;  -- 512 / 32 bit = 2^4
        sch3_rlen <= ("0000" & ireg_width(11 downto 4)) when sddr_ch3_waddr = 0 else sch3_rlen;  -- 512 / 32 bit = 2^4
        sch4_rlen <= ("00000" & ireg_width(11 downto 5)) when sddr_ch4_waddr = 0 else sch4_rlen; -- 512 / 16 bit = 2^5
    end generate GEN_2p5G_LEN;

    --# Write state machine: arbitrate write channels and burst to AXI
    process (iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                state_write <= s_IDLE;

                sconv_wlen  <= (others => '0');
                sconv_wtrig <= '0';
                sconv_waddr <= (others => '0');

                swaddr      <= (others => '0');
                swlen       <= (others => '0');
                swrite_ch   <= 0;

                sburst_wnum <= (others => '0');
                sburst_wcnt <= (others => '0');
            else

                case state_write is
                    when s_IDLE =>
                        if (sch0_wtrig = '1') then
                            state_write <= s_READY;
                            swaddr      <= ich0_waddr;
                            swlen       <= sch0_wlen - '1';
                            swrite_ch   <= 0;
                        elsif (sch1_wtrig = '1') then
                            state_write <= s_READY;
                            swaddr      <= ich1_waddr;
                            swlen       <= sch1_wlen - '1';
                            swrite_ch   <= 1;
                        elsif (sch2_wtrig = '1') then
                            state_write <= s_READY;
                            swaddr      <= ich2_waddr;
                            swlen       <= sch2_wlen - '1';
                            swrite_ch   <= 2;
                        elsif (sch3_wtrig = '1') then
                            state_write <= s_READY;
                            swaddr      <= ich3_waddr;
                            swlen       <= sch3_wlen - '1';
                            swrite_ch   <= 3;
                        elsif (sch4_wtrig = '1') then
                            state_write <= s_READY;
                            swaddr      <= ich4_waddr;
                            swlen       <= sch4_wlen - '1';
                            swrite_ch   <= 4;
                        end if;

                        sconv_wtrig <= '0';

                    when s_READY =>
                        state_write <= s_WAIT;

                        if (swlen(11 downto 8) /= 0) then
                            sburst_wnum <= swlen(11 downto 8);
                            sconv_wlen  <= x"FF";
                        else
                            sburst_wnum <= (others => '0');
                            sconv_wlen  <= swlen(7 downto 0);
                        end if;

                    when s_WAIT =>
                        if (iconv_wbusy = '0') then
                            state_write <= s_WRITE;
                            sconv_wtrig <= '1';
                            sconv_waddr <= swaddr;
                        end if;

                    when s_WRITE =>
                        if (iaxi_bready = '1') then
                            state_write <= s_CHECK;
                        end if;

                        sconv_wtrig <= '0';

                    when s_CHECK =>
                        if (sburst_wnum = 0) then
                            state_write <= s_IDLE;
                            sburst_wcnt <= (others => '0');
                        else
                            if (sburst_wcnt >= sburst_wnum) then
                                state_write <= s_IDLE;
                                sburst_wcnt <= (others => '0');
                            else
                                state_write <= s_WAIT;
                                sburst_wcnt <= sburst_wcnt + '1';
                                swaddr      <= swaddr + x"4000"; -- 256 * (512 / 8)

                                if (sburst_wcnt = sburst_wnum - 1) then
                                    sconv_wlen <= swlen(7 downto 0);
                                else
                                    sconv_wlen <= x"FF";
                                end if;
                            end if;
                        end if;

                    when others =>
                        NULL;
                end case;

            end if;
        end if;
    end process;

    --# Read state machine: arbitrate read channels and burst from AXI
    process (iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                state_read <= s_IDLE;

                sconv_rlen  <= (others => '0');
                sconv_rtrig <= '0';
                sconv_raddr <= (others => '0');
                sconv_rlast <= '0';

                sraddr     <= (others => '0');
                srlen      <= (others => '0');
                sch0_rbusy <= '0';
                sch1_rbusy <= '0';
                sch2_rbusy <= '0';
                sch3_rbusy <= '0';
                sch4_rbusy <= '0';

                sburst_rnum <= (others => '0');
                sburst_rcnt <= (others => '0');
            else

                case state_read is
                    when s_IDLE =>
                        if (sch0_rtrig = '1') then
                            state_read <= s_READY;
                            sraddr     <= ich0_raddr;
                            srlen      <= sch0_rlen - '1';
                            sch0_rbusy <= '1';
                        elsif (sch1_rtrig = '1') then
                            state_read <= s_READY;
                            sraddr     <= ich1_raddr;
                            srlen      <= sch1_rlen - '1';
                            sch1_rbusy <= '1';
                        elsif (sch2_rtrig = '1') then
                            state_read <= s_READY;
                            sraddr     <= ich2_raddr;
                            srlen      <= sch2_rlen - '1';
                            sch2_rbusy <= '1';
                        elsif (sch3_rtrig = '1') then
                            state_read <= s_READY;
                            sraddr     <= ich3_raddr;
                            srlen      <= sch3_rlen - '1';
                            sch3_rbusy <= '1';
                        elsif (sch4_rtrig = '1') then
                            state_read <= s_READY;
                            sraddr     <= ich4_raddr;
                            srlen      <= sch4_rlen - '1';
                            sch4_rbusy <= '1';
                        end if;

                        sconv_rtrig <= '0';
                        sconv_rlast <= '0';

                    when s_READY =>
                        state_read <= s_WAIT;

                        if (srlen(11 downto 8) /= 0) then
                            sburst_rnum <= srlen(11 downto 8);
                            sconv_rlen  <= x"FF";
                        else
                            sburst_rnum <= (others => '0');
                            sconv_rlen  <= srlen(7 downto 0);
                        end if;

                    when s_WAIT =>
                        if (iconv_rbusy = '0') then
                            state_read  <= s_READ;
                            sconv_rtrig <= '1';
                            sconv_raddr <= sraddr;
                        end if;

                    when s_READ =>
                        if (iaxi_rvalid = '1' and iaxi_rready = '1') then
                            if (iaxi_rlast = '1') then
                                state_read <= s_CHECK;
                            end if;
                        end if;

                        sconv_rtrig <= '0';

                    when s_CHECK =>
                        if (sburst_rnum = 0) then
                            state_read  <= s_IDLE;
                            sburst_rcnt <= (others => '0');
                            sconv_rlast <= '1';
                            sch0_rbusy  <= '0';
                            sch1_rbusy  <= '0';
                            sch2_rbusy  <= '0';
                            sch3_rbusy  <= '0';
                            sch4_rbusy  <= '0';
                        else
                            if (sburst_rcnt >= sburst_rnum) then
                                state_read  <= s_IDLE;
                                sburst_rcnt <= (others => '0');
                                sconv_rlast <= '1';
                                sch0_rbusy  <= '0';
                                sch1_rbusy  <= '0';
                                sch2_rbusy  <= '0';
                                sch3_rbusy  <= '0';
                                sch4_rbusy  <= '0';
                            else
                                state_read  <= s_WAIT;
                                sburst_rcnt <= sburst_rcnt + '1';
                                sraddr      <= sraddr + x"4000"; -- 256 * (512 / 8)

                                if (sburst_rcnt = sburst_rnum - 1) then
                                    sconv_rlen <= srlen(7 downto 0);
                                else
                                    sconv_rlen <= x"FF";
                                end if;
                            end if;
                        end if;

                    when others =>
                        NULL;
                end case;

            end if;
        end if;
    end process;

    --# Delay: register input triggers and rvalid
    process (iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                saxi_rvalid_1d <= '0';
                sch0_wtrig     <= '0';
                sch1_wtrig     <= '0';
                sch2_wtrig     <= '0';
                sch3_wtrig     <= '0';
                sch4_wtrig     <= '0';
                sch0_rtrig     <= '0';
                sch1_rtrig     <= '0';
                sch2_rtrig     <= '0';
                sch3_rtrig     <= '0';
                sch4_rtrig     <= '0';
            else
                saxi_rvalid_1d <= iaxi_rvalid;
                sch0_wtrig     <= ich0_wtrig;
                sch1_wtrig     <= ich1_wtrig;
                sch2_wtrig     <= ich2_wtrig;
                sch3_wtrig     <= ich3_wtrig;
                sch4_wtrig     <= ich4_wtrig;
                sch0_rtrig     <= ich0_rtrig;
                sch1_rtrig     <= ich1_rtrig;
                sch2_rtrig     <= ich2_rtrig;
                sch3_rtrig     <= ich3_rtrig;
                sch4_rtrig     <= ich4_rtrig;
            end if;
        end if;
    end process;

    sddr_ch0_wen <= sch0_rbusy and saxi_rvalid_1d;
    sddr_ch1_wen <= sch1_rbusy and saxi_rvalid_1d;
    sddr_ch2_wen <= sch2_rbusy and saxi_rvalid_1d;
    sddr_ch3_wen <= sch3_rbusy and saxi_rvalid_1d;
    sddr_ch4_wen <= sch4_rbusy and saxi_rvalid_1d;

    U0_AXI_RDATA_CONV : AXI_RDATA_CONV
        generic map (
            data_depth => DDR_BIT_R0((GNR_MODEL))
        )
        port map (
            iwr_clk  => iaxi_clk,
            iwr_rstn => iaxi_rstn,

            iwr_en   => sddr_ch0_wen,
            iwr_addr => sddr_ch0_waddr,
            iwr_vcnt => ich0_rvcnt,
            iwr_data => iconv_rdata,

            ird_clk  => iconv_clk,
            ird_rstn => iconv_rstn,

            ird_en   => iconv_en,
            ird_addr => iconv_addr,
            ird_vcnt => iconv_vcnt,
            ord_data => sconv_data0
        );
    oconv_data0 <= sconv_data0; -- for ila

    U1_AXI_RDATA_CONV : AXI_RDATA_CONV
        generic map (
            data_depth => DDR_BIT_R1((GNR_MODEL))
        )
        port map (
            iwr_clk  => iaxi_clk,
            iwr_rstn => iaxi_rstn,

            iwr_en   => sddr_ch1_wen,
            iwr_addr => sddr_ch1_waddr,
            iwr_vcnt => ich1_rvcnt,
            iwr_data => iconv_rdata,

            ird_clk  => iconv_clk,
            ird_rstn => iconv_rstn,

            ird_en   => iconv_en,
            ird_addr => iconv_addr,
            ird_vcnt => iconv_vcnt,
            ord_data => sconv_data1
        );
    oconv_data1 <= sconv_data1;

    U2_AXI_RDATA_CONV : AXI_RDATA_CONV
        generic map (
            data_depth => DDR_BIT_R2((GNR_MODEL))
        )
        port map (
            iwr_clk  => iaxi_clk,
            iwr_rstn => iaxi_rstn,

            iwr_en   => sddr_ch2_wen,
            iwr_addr => sddr_ch2_waddr,
            iwr_vcnt => ich2_rvcnt,
            iwr_data => iconv_rdata,

            ird_clk  => iconv_clk,
            ird_rstn => iconv_rstn,

            ird_en   => iconv_en,
            ird_addr => iconv_addr,
            ird_vcnt => iconv_vcnt,
            ord_data => sconv_data2
        );
    oconv_data2 <= sconv_data2;

    U3_AXI_RDATA_CONV : AXI_RDATA_CONV --# r ch3
        generic map (
            data_depth => DDR_BIT_R3((GNR_MODEL))
        )
        port map (
            iwr_clk  => iaxi_clk,
            iwr_rstn => iaxi_rstn,

            iwr_en   => sddr_ch3_wen,
            iwr_addr => sddr_ch3_waddr,
            iwr_vcnt => ich3_rvcnt,
            iwr_data => iconv_rdata,

            ird_clk  => iconv_clk,
            ird_rstn => iconv_rstn,

            ird_en   => iconv_en,
            ird_addr => iconv_addr,
            ird_vcnt => iconv_vcnt,
            ord_data => sconv_data3
        );
    oconv_data3 <= sconv_data3;

    U4_AXI_RDATA_CONV : AXI_RDATA_CONV --# r ch4
        generic map (
            data_depth => DDR_BIT_R4((GNR_MODEL))
        )
        port map (
            iwr_clk  => iaxi_clk,
            iwr_rstn => iaxi_rstn,

            iwr_en   => sddr_ch4_wen,
            iwr_addr => sddr_ch4_waddr,
            iwr_vcnt => ich4_rvcnt,
            iwr_data => iconv_rdata,

            ird_clk  => iconv_clk,
            ird_rstn => iconv_rstn,

            ird_en   => iconv_en,
            ird_addr => iconv_addr,
            ird_vcnt => iconv_vcnt,
            ord_data => sconv_data4
        );
    oconv_data4 <= sconv_data4;

    --# DDR read data write address counter per channel
    process (iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                sddr_ch0_waddr <= (others => '0');
                sddr_ch1_waddr <= (others => '0');
                sddr_ch2_waddr <= (others => '0');
                sddr_ch3_waddr <= (others => '0');
                sddr_ch4_waddr <= (others => '0');
            else
                if (sddr_ch0_wen = '1') then
                    if (sddr_ch0_waddr = sch0_rlen - 1) then
                        sddr_ch0_waddr <= (others => '0');
                    else
                        sddr_ch0_waddr <= sddr_ch0_waddr + '1';
                    end if;
                end if;

                if (sddr_ch1_wen = '1') then
                    if (sddr_ch1_waddr = sch1_rlen - 1) then
                        sddr_ch1_waddr <= (others => '0');
                    else
                        sddr_ch1_waddr <= sddr_ch1_waddr + '1';
                    end if;
                end if;

                if (sddr_ch2_wen = '1') then
                    if (sddr_ch2_waddr = sch2_rlen - 1) then
                        sddr_ch2_waddr <= (others => '0');
                    else
                        sddr_ch2_waddr <= sddr_ch2_waddr + '1';
                    end if;
                end if;

                if (sddr_ch3_wen = '1') then
                    if (sddr_ch3_waddr = sch3_rlen - 1) then
                        sddr_ch3_waddr <= (others => '0');
                    else
                        sddr_ch3_waddr <= sddr_ch3_waddr + '1';
                    end if;
                end if;

                if (sddr_ch4_wen = '1') then
                    if (sddr_ch4_waddr = sch4_rlen - 1) then
                        sddr_ch4_waddr <= (others => '0');
                    else
                        sddr_ch4_waddr <= sddr_ch4_waddr + '1';
                    end if;
                end if;

            end if;
        end if;
    end process;

    oconv_wlen  <= sconv_wlen;
    oconv_wtrig <= sconv_wtrig;
    oconv_waddr <= sconv_waddr;
    oconv_wdata <= ich0_wdata when swrite_ch = 0 else
                   ich1_wdata when swrite_ch = 1 else
                   ich2_wdata when swrite_ch = 2 else
                   ich3_wdata when swrite_ch = 3 else
                   ich4_wdata when swrite_ch = 4 else
                   (others => '0');

    oconv_rlen  <= sconv_rlen;
    oconv_rtrig <= sconv_rtrig;
    oconv_raddr <= sconv_raddr;
    oconv_rlast <= sconv_rlast;

    --# for debug
    ostate_write <= state_write;
    owrite_ch    <= x"0" when swrite_ch = 0 else
                    x"1" when swrite_ch = 1 else
                    x"2" when swrite_ch = 2 else
                    x"3" when swrite_ch = 3 else
                    x"4" when swrite_ch = 4 else
                    x"0";
    ostate_read  <= state_read;
    oread_ch     <= x"0" when sch0_rbusy = '1' else
                    x"1" when sch1_rbusy = '1' else
                    x"2" when sch2_rbusy = '1' else
                    x"3" when sch3_rbusy = '1' else
                    x"4" when sch4_rbusy = '1' else
                    x"0";

end architecture behavioral;

--# Unused signals (removed from architecture):
--# constant PARA_BITS : integer := 64;
