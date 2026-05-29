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

    --# 2605081600 Per-channel AXI ID inputs (Stage 1: enable MIG reorder)
    iconv_wid           : in  std_logic_vector(2 downto 0);
    iconv_rid           : in  std_logic_vector(2 downto 0);

    --# 2605082100 Stage2-a Read multi-outstanding: idle indicator (high when no outstanding reads)
    oconv_r_idle        : out std_logic;

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
    ostate_read_ddr_mast  : out tstate_read_ddr_mast;
    
    axi_wcnt            : out std_logic_vector(7 downto 0)      --$ 260518 for ila
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
    signal sconv_wlen   : std_logic_vector(7 downto 0);  --# 2605071454 latch iconv_wlen at AW handshake (mirror sconv_rlen pattern)

    --# 2605081600 Latched AXI IDs (held stable for the entire burst transaction; zero-extended to DDR_AXI2 width)
    signal saxi_awid_reg : std_logic_vector(DDR_AXI2(GNR_MODEL) - 1 downto 0);
    signal saxi_arid_reg : std_logic_vector(DDR_AXI2(GNR_MODEL) - 1 downto 0);

    --# 2605082100 Stage2-a Read multi-outstanding signals
    constant MAX_R_OUTSTANDING : integer := 8;
    signal saxi_r_outstanding : std_logic_vector(3 downto 0);  -- counts 0..15, gated to MAX_R_OUTSTANDING
    signal saxi_arlen_reg     : std_logic_vector(7 downto 0);  -- latched AR length (held during arvalid)
    signal sr_inc_pulse       : std_logic;                     -- AR handshake pulse (+1 outstanding)
    signal sr_dec_pulse       : std_logic;                     -- R last beat handshake pulse (-1 outstanding)

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

                sconv_wlen   <= (others => '0');  --# 2605071454
                saxi_awid_reg <= (others => '0'); --# 2605081600 reset latched AWID
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
                            --# 2605081600 latch AWID from channel index (zero-extended to AXI ID width)
                            saxi_awid_reg <= conv_std_logic_vector(conv_integer(iconv_wid), DDR_AXI2(GNR_MODEL));
                        end if;

                        saxi_wcnt <= (others => '0');

                    when s_ADDR =>
                        if (axi_awready = '1') then
                            state_write  <= s_DATA;
                            saxi_awvalid <= '0';
                            saxi_wvalid  <= '1';
                            saxi_bready  <= '1';
                            sconv_wlen   <= iconv_wlen;  --# 2605071454 latch wlen at AW handshake to avoid mid-burst race
							--$ 260518 init wlast: '1' only for 1-beat burst (wlen=0), else '0'
							if (iconv_wlen = x"00") then
								saxi_wlast <= '1';
							else
								saxi_wlast <= '0';
							end if;
                        end if;
                    when s_DATA =>
--                        if (axi_wready = '1') then
--                            saxi_wvalid <= '0';
--
----                            if (saxi_wcnt = iconv_wlen) then
--                            if (saxi_wcnt = sconv_wlen) then  --# 2605071454 use latched wlen
--                                state_write <= s_BRESP;
--                                saxi_wlast  <= '0';
--                            else
--                               state_write <= s_CHECK;
--                                saxi_wbusy  <= '1';
--                                saxi_wcnt   <= saxi_wcnt + '1';
--                            end if;
--                        end if;
                        --$ 260518 keep wvalid=1 throughout burst
						if (axi_wready = '1') then
							if (saxi_wcnt = sconv_wlen) then
								state_write <= s_BRESP;
								saxi_wvalid <= '0';
								saxi_wlast  <= '0';
							else
								saxi_wcnt   <= saxi_wcnt + '1';
								if (saxi_wcnt + '1' = sconv_wlen) then
									saxi_wlast <= '1';       --$ 260518 pre-set wlast one beat early
								else
									saxi_wlast <= '0';
								end if;
							end if;
						end if;
				    --$ 260518
                    when s_CHECK =>
--                        state_write <= s_DATA;
--                        saxi_wvalid <= '1';
--
----                        if (saxi_wcnt = iconv_wlen) then
--                        if (saxi_wcnt = sconv_wlen) then  --# 2605071454 use latched wlen
--                            saxi_wlast <= '1';
--                        else
--                           saxi_wlast <= '0';
--                        end if;
							NULL;
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

    --# 2605082100 Stage2-a AR-issue FSM: accepts back-to-back rtrig while outstanding < MAX
    --#   States used: s_IDLE (ready/gated), s_START (arvalid driven, wait arready)
    --#   s_READ/s_CHECK: vestigial (kept in enum for ILA compat); routed back to s_IDLE
    process(iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                state_read   <= s_IDLE;
                saxi_arvalid <= '0';
                saxi_araddr  <= (others => '0');
                saxi_arid_reg <= (others => '0');
                saxi_arlen_reg <= (others => '0');
                saxi_rcnt     <= (others => '0'); -- unused in Stage2-a; kept for ILA stability
                sconv_rlen    <= (others => '0'); -- unused in Stage2-a; kept for symmetry
            else
                case state_read is
                    when s_IDLE =>
                        --# Accept new AR only if queue not full
                        if (iconv_rtrig = '1') and (saxi_r_outstanding < conv_std_logic_vector(MAX_R_OUTSTANDING, 4)) then
                            state_read <= s_START;
                            saxi_arvalid   <= '1';
                            saxi_araddr    <= iconv_raddr;
                            saxi_arid_reg  <= conv_std_logic_vector(conv_integer(iconv_rid), DDR_AXI2(GNR_MODEL));
                            saxi_arlen_reg <= iconv_rlen;
                        else
                            saxi_arvalid <= '0';
                        end if;

                    when s_START =>
                        --# Hold arvalid until arready handshake, then return to s_IDLE for next push
                        if (axi_arready = '1') then
                            state_read   <= s_IDLE;
                            saxi_arvalid <= '0';
                        end if;

                    when others =>
                        --# s_READ, s_CHECK: vestigial; should not be entered in Stage2-a
                                state_read <= s_IDLE;
                        saxi_arvalid <= '0';
                end case;
            end if;
        end if;
    end process;

    --# 2605082100 Stage2-a R-data handler: capture axi_rdata into saxi_rdata each rvalid beat
    process(iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                saxi_rdata  <= (others => '0');
                saxi_rready <= '0';
                                saxi_rbusy <= '0';
                            else
                --# Always-ready strategy: assume downstream AXI_RDATA_CONV (BRAM-based) absorbs all beats
                saxi_rready <= '1';
                if (axi_rvalid = '1' and saxi_rready = '1') then
                    saxi_rdata <= axi_rdata;
                end if;
                --# Legacy saxi_rbusy (used by some debug paths): high while any AR outstanding
                if (saxi_r_outstanding /= "0000") then
                    saxi_rbusy <= '1';
                else
                    saxi_rbusy <= '0';
                end if;
                            end if;
                        end if;
    end process;

    --# 2605082100 Stage2-a Outstanding-AR counter: +1 on AR handshake, -1 on R last-beat handshake
    sr_inc_pulse <= saxi_arvalid and axi_arready;
    sr_dec_pulse <= axi_rvalid and saxi_rready and axi_rlast;

    process(iaxi_clk)
    begin
        if (iaxi_clk'event and iaxi_clk = '1') then
            if (iaxi_rstn = '0') then
                saxi_r_outstanding <= (others => '0');
            else
                if (sr_inc_pulse = '1' and sr_dec_pulse = '0') then
                    saxi_r_outstanding <= saxi_r_outstanding + '1';
                elsif (sr_inc_pulse = '0' and sr_dec_pulse = '1') then
                    saxi_r_outstanding <= saxi_r_outstanding - '1';
                --# else: no change (both 0 or both 1 / cancel)
                end if;
            end if;
        end if;
    end process;

    oconv_wbusy     <= saxi_wbusy;
    oconv_rdata     <= saxi_rdata;
--# 2605082100 Stage2-a oconv_rbusy: '1' when (queue full) OR (AR currently being issued)
--#   The s_START term prevents race where AXI_IF advances on stale iconv_rbusy='0' while
--#   a previous AR handshake is in flight (which would cause the new rtrig pulse to be lost
--#   if outstanding hits MAX exactly at that handshake edge).
    oconv_rbusy     <= '1' when (saxi_r_outstanding >= conv_std_logic_vector(MAX_R_OUTSTANDING, 4))
                              or (state_read = s_START)
                      else '0';
    oconv_r_idle    <= '1' when (saxi_r_outstanding =  "0000") else '0';

--# 2605081600 axi_awid  <= conv_std_logic_vector(1, DDR_AXI2(GNR_MODEL)); -- fixed ID=1 (Stage 1: per-channel ID)
	axi_awid  			<= saxi_awid_reg;
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
--# 2605081600 axi_arid <= conv_std_logic_vector(1, DDR_AXI2(GNR_MODEL)); -- fixed ID=1 (Stage 1: per-channel ID)
	axi_arid 			<= saxi_arid_reg;
    axi_araddr      <= saxi_araddr;
--# 2605082100 Stage2-a axi_arlen <= iconv_rlen; -- combinational; broke when next iconv_rlen changes mid-arvalid
    axi_arlen       <= saxi_arlen_reg;
    axi_arsize      <= "110";          -- 512 bit
    axi_arburst     <= "01";           -- INCR
    axi_arlock(0)   <= '0';
    axi_arvalid     <= saxi_arvalid;

    axi_rready      <= saxi_rready;
    
    axi_wcnt        <= saxi_wcnt; --$ 260518 for ila

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
--            probe16 => iconv_wdata(31 downto 0), -- 32
--            probe17 => axi_rdata(31 downto 0),  -- 32
--            probe18 => saxi_rdata(31 downto 0)  -- 32
            probe16 => saxi_rdata(511 downto 480), -- 32
            probe17 => saxi_rdata(255 downto 224), --32
            probe18 => saxi_rdata(31 downto 0)  -- 32
        );
    end generate;

end behavioral;

--# Unused signals removed from architecture:
--# signal saxi_wburst : std_logic_vector(1 downto 0);
