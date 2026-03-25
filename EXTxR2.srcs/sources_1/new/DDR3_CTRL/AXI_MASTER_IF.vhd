library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;

    use WORK.TOP_HEADER.ALL;

entity AXI_MASTER_IF is
generic (   GNR_MODEL : string := "EXT4343RD");
port (
    iaxi_clk            : in  std_logic;
    iaxi_rstn           : in  std_logic;

    iconv_wlen          : in  std_logic_vector(7 downto 0);
    iconv_wtrig         : in  std_logic;
    iconv_waddr         : in  std_logic_vector(31 downto 0);
    iconv_wdata         : in  std_logic_vector(511 downto 0);
    oconv_wbusy         : out std_logic;
    iconv_rlen          : in  std_logic_vector(7 downto 0);
    iconv_rtrig         : in  std_logic;
    iconv_raddr         : in  std_logic_vector(31 downto 0);
    oconv_rdata         : out std_logic_vector(511 downto 0);
    oconv_rbusy         : out std_logic;

--$	axi_awid			: out	std_logic_vector(3 downto 0);
	axi_awid			: out	std_logic_vector(DDR_AXI2(GNR_MODEL) -1 downto 0);
    axi_awaddr          : out std_logic_vector(31 downto 0);
    axi_awlen           : out std_logic_vector(7 downto 0);
    axi_awsize          : out std_logic_vector(2 downto 0);
    axi_awburst         : out std_logic_vector(1 downto 0);
    axi_awlock          : out std_logic_vector(0 downto 0);
    axi_awvalid         : out std_logic;
    axi_awready         : in  std_logic;

    axi_wdata           : out std_logic_vector(511 downto 0);
    axi_wstrb           : out std_logic_vector(63 downto 0);
    axi_wlast           : out std_logic;
    axi_wvalid          : out std_logic;
    axi_wready          : in  std_logic;

--$	axi_bid				: in	std_logic_vector(3 downto 0);
	axi_bid				: in	std_logic_vector(DDR_AXI2(GNR_MODEL) -1 downto 0);
    axi_bresp           : in  std_logic_vector(1 downto 0);
    axi_bvalid          : in  std_logic;
    axi_bready          : out std_logic;

--$	axi_arid			: out	std_logic_vector(3 downto 0);
	axi_arid			: out	std_logic_vector(DDR_AXI2(GNR_MODEL) -1 downto 0);
    axi_araddr          : out std_logic_vector(31 downto 0);
    axi_arlen           : out std_logic_vector(7 downto 0);
    axi_arsize          : out std_logic_vector(2 downto 0);
    axi_arburst         : out std_logic_vector(1 downto 0);
    axi_arlock          : out std_logic_vector(0 downto 0);
    axi_arvalid         : out std_logic;
    axi_arready         : in  std_logic;

--$	axi_rid				: in	std_logic_vector(3 downto 0);
	axi_rid				: in	std_logic_vector(DDR_AXI2(GNR_MODEL) - 1 downto 0);
    axi_rdata           : in  std_logic_vector(511 downto 0);
    axi_rresp           : in  std_logic_vector(1 downto 0);
    axi_rlast           : in  std_logic;
    axi_rvalid          : in  std_logic;
    axi_rready          : out std_logic;
    ostate_write_ddr_mast : out tstate_write_ddr_mast;
    ostate_read_ddr_mast  : out tstate_read_ddr_mast
);
end AXI_MASTER_IF;

architecture Behavioral of AXI_MASTER_IF is

--  type tstate_write_ddr_mast  is  (
--                                  s_IDLE,
--                                  s_READY,
--                                  s_ADDR,
--                                  s_DATA,
--                                  s_CHECK,
--                                  s_BRESP
--                              );

--  type tstate_read_ddr_mast   is  (
--                                  s_IDLE,
--                                  s_START,
--                                  s_READ,
--                                  s_CHECK
--                              );

    signal saxi_wcnt    : std_logic_vector(7 downto 0);
    signal saxi_rcnt    : std_logic_vector(7 downto 0);
    signal state_write  : tstate_write_ddr_mast;
    signal state_read   : tstate_read_ddr_mast;

    signal saxi_awaddr  : std_logic_vector(31 downto 0);
    signal saxi_awvalid : std_logic;

    signal saxi_wlast   : std_logic;
    signal saxi_wbusy   : std_logic;
    signal saxi_wvalid  : std_logic;

    signal saxi_bready  : std_logic;

    signal saxi_araddr  : std_logic_vector(31 downto 0);
    signal saxi_arvalid : std_logic;

    signal saxi_rdata   : std_logic_vector(511 downto 0);
    signal saxi_rbusy   : std_logic;
    signal saxi_rready  : std_logic;

    signal sconv_rlen   : std_logic_vector(7 downto 0);

    component ILA_AXI_MASTER_IF
    port (
        clk     : in  std_logic;

        probe0  : in  tstate_write_ddr_mast;
        probe1  : in  tstate_read_ddr_mast;
        probe2  : in  std_logic;
        probe3  : in  std_logic;
        probe4  : in  std_logic;
        probe5  : in  std_logic;
        probe6  : in  std_logic;
        probe7  : in  std_logic;
        probe8  : in  std_logic;
        probe9  : in  std_logic;
        probe10 : in  std_logic;
        probe11 : in  std_logic;
        probe12 : in  std_logic;
        probe13 : in  std_logic;
        probe14 : in  std_logic;
        probe15 : in  std_logic;
        probe16 : in  std_logic_vector(31 downto 0);
        probe17 : in  std_logic_vector(31 downto 0);
        probe18 : in  std_logic_vector(31 downto 0)
    );
    end component;

begin

ostate_write_ddr_mast <= state_write;
ostate_read_ddr_mast  <= state_read;

    --# AXI write channel state machine (sync reset)
    process(iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                state_write  <= s_IDLE;
                saxi_wcnt    <= (others => '0');
                saxi_awaddr  <= (others => '0');
                saxi_awvalid <= '0';
                saxi_wvalid  <= '0';
                saxi_wlast   <= '0';
                saxi_wbusy   <= '1';
                saxi_bready  <= '0';
            else
                case state_write is
                    when s_IDLE =>
                        state_write <= s_READY;
                        saxi_wbusy  <= '0';
                        saxi_wcnt   <= (others => '0');

                    when s_READY =>
                        if (iconv_wtrig = '1') then
                            state_write  <= s_ADDR;
                            saxi_awaddr  <= iconv_waddr;
                            saxi_awvalid <= '1';
                            saxi_wbusy   <= '1';
                        end if;

                        saxi_wcnt <= (others => '0');

                    when s_ADDR =>
                        if (axi_awready = '1') then
                            state_write  <= s_DATA;
                            saxi_awvalid <= '0';
                            saxi_wvalid  <= '1';
                            saxi_bready  <= '1';
                        end if;

                    when s_DATA =>
                        if (axi_wready = '1') then
                            saxi_wvalid <= '0';

                            if (saxi_wcnt = iconv_wlen) then
                                state_write <= s_BRESP;
                                saxi_wlast  <= '0';
                            else
                                state_write <= s_CHECK;
                                saxi_wbusy  <= '1';
                                saxi_wcnt   <= saxi_wcnt + '1';
                            end if;
                        end if;

                    when s_CHECK =>
                        state_write <= s_DATA;
                        saxi_wvalid <= '1';

                        if (saxi_wcnt = iconv_wlen) then
                            saxi_wlast <= '1';
                        else
                            saxi_wlast <= '0';
                        end if;

                    when s_BRESP =>
                        if (axi_bvalid = '1') then
                            state_write <= s_READY;
                            saxi_bready <= '0';
                            saxi_wbusy  <= '0';
                        end if;
                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    --# AXI read channel state machine (sync reset)
    process(iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                state_read   <= s_IDLE;
                saxi_arvalid <= '0';
                saxi_araddr  <= (others => '0');
                saxi_rdata   <= (others => '0');
                saxi_rready  <= '0';
                saxi_rbusy   <= '0';
                saxi_rcnt    <= (others => '0');

                sconv_rlen   <= (others => '0');
            else
                case state_read is
                    when s_IDLE =>
                        if (iconv_rtrig = '1') then
                            state_read <= s_START;
                        else
                            state_read <= s_IDLE;
                        end if;

                        saxi_arvalid <= '0';
                        saxi_rbusy   <= '0';
                        saxi_rready  <= '0';
                        saxi_rcnt    <= (others => '0');

                    when s_START =>
                        state_read   <= s_READ;

                        saxi_arvalid <= '1';
                        saxi_araddr  <= iconv_raddr;
                        saxi_rbusy   <= '1';
                        saxi_rready  <= '0';

                    when s_READ =>
                        if (axi_arready = '1') then
                            state_read   <= s_CHECK;
                            saxi_arvalid <= '0';
                            saxi_rready  <= '1';
                            sconv_rlen   <= iconv_rlen;
                        end if;

                    when s_CHECK =>
                        if (axi_rvalid = '1') then
                            if (saxi_rcnt = sconv_rlen) then
                                state_read <= s_IDLE;
                                saxi_rbusy <= '0';
                            else
                                saxi_rcnt <= saxi_rcnt + '1';
                            end if;
                            saxi_rdata <= axi_rdata;
                        end if;
                    when others =>
                        NULL;
                end case;
            end if;
        end if;
    end process;

    oconv_wbusy     <= saxi_wbusy;
    oconv_rdata     <= saxi_rdata;
    oconv_rbusy     <= saxi_rbusy;

	axi_awid  			<= conv_std_logic_vector(1, DDR_AXI2(GNR_MODEL));
    axi_awaddr      <= saxi_awaddr;
    axi_awlen       <= iconv_wlen;
    axi_awsize      <= "110";          -- 512 bit
    axi_awburst     <= "01";           -- INCR
    axi_awlock(0)   <= '0';
    axi_awvalid     <= saxi_awvalid;

    axi_wdata       <= iconv_wdata;
    axi_wstrb       <= (others => '1');
    axi_wlast       <= saxi_wlast;
    axi_wvalid      <= saxi_wvalid;

    axi_bready      <= saxi_bready;

--$	axi_arid 			<= "0001";
	axi_arid 			<= conv_std_logic_vector(1, DDR_AXI2(GNR_MODEL));
    axi_araddr      <= saxi_araddr;
    axi_arlen       <= iconv_rlen;
    axi_arsize      <= "110";          -- 512 bit
    axi_arburst     <= "01";           -- INCR
    axi_arlock(0)   <= '0';
    axi_arvalid     <= saxi_arvalid;

    axi_rready      <= saxi_rready;

    SYNTH : if (GEN_ILA_axi_master_if = "ON") generate
    begin
        U0_ILA_AXI_MASTER_IF : ILA_AXI_MASTER_IF
        port map (
            clk     => iaxi_clk,

            probe0  => state_write,             -- 3
            probe1  => state_read,              -- 2
            probe2  => saxi_awvalid,            -- 1
            probe3  => axi_awready,             -- 1
            probe4  => axi_wready,              -- 1
            probe5  => saxi_wvalid,             -- 1
            probe6  => saxi_wlast,              -- 1
            probe7  => saxi_bready,             -- 1
            probe8  => axi_bvalid,              -- 1
            probe9  => saxi_arvalid,            -- 1
            probe10 => axi_arready,             -- 1
            probe11 => saxi_rready,             -- 1
            probe12 => axi_rvalid,              -- 1
            probe13 => axi_rlast,               -- 1
            probe14 => saxi_wbusy,              -- 1
            probe15 => saxi_rbusy,              -- 1
            probe16 => iconv_wdata(31 downto 0), -- 32
            probe17 => axi_rdata(31 downto 0),  -- 32
            probe18 => saxi_rdata(31 downto 0)  -- 32
        );
    end generate;

end behavioral;

--# Unused signals removed from architecture:
--# signal saxi_wburst : std_logic_vector(1 downto 0);
