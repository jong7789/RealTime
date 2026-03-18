-- ************************************************************************** --
-- *  GigE Vision NBASE-T Reference Design                                  * --
-- *------------------------------------------------------------------------* --
-- *  Module :  XGVRD-TOP                                                   * --
-- *    File :  xgvrd.vhd                                                   * --
-- *    Date :  2023-10-20                                                  * --
-- *     Rev :  0.13                                                        * --
-- *  Author :  JP                                                          * --
-- *------------------------------------------------------------------------* --
-- *  Top-level of the 10 GigE Vision reference design                      * --
-- *------------------------------------------------------------------------* --
-- *  0.1  |  2011-10-06  |  JP  |  Initial release                         * --
-- *  0.2  |  2011-10-31  |  JP  |  Extended test design                    * --
-- *  0.3  |  2012-04-23  |  JP  |  New XGigE core and updated framebuffer  * --
-- *  0.4  |  2012-05-02  |  JP  |  Modification for test pattern generator * --
-- *  0.5  |  2012-10-17  |  JP  |  AXI based CPU and framebuffer           * --
-- *  0.6  |  2013-02-20  |  JP  |  Modified for direct 10GBASE-R SFP+      * --
-- *  0.7  |  2015-02-18  |  JP  |  Modified for FMC with 10GBASE-T PHY     * --
-- *  0.8  |  2019-09-03  |  YH  |  Updated for current IP cores            * --
-- *  0.9  |  2020-08-11  |  PD  |  Updated for current IP cores            * --
-- *  0.10 |  2021-03-19  |  MAS |  Updated for current IP cores            * --
-- *  0.11 |  2022-02-10  |  SS  |  Updated cores, added MAC clk_en         * --
-- *  0.12 |  2022-02-10  |  AM  |  Updated cores, Direct entity            * --
-- *       |              |      |  instantiation                           * --
-- *  0.13 |  2023-10-20  |  AZ  |  Fixed CPU direct entity instantiation   * --
-- ************************************************************************** --

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;


--------------------------------------------------------------------------------
--  XGVRD-TOP entity
--------------------------------------------------------------------------------

entity xgvrd is
    port   (-- Global ports
            ext_rst         : in    std_logic;
            ext_clk_p       : in    std_logic;
            ext_clk_n       : in    std_logic;
            ref_clk_p       : in    std_logic;
            ref_clk_n       : in    std_logic;
            -- RS232 UART
            uart_rxd        : in    std_logic;
            uart_txd        : out   std_logic;
            -- SPI flash memory
          --spi_clk         : out   std_logic;  -- Connected internally using the STARTUP2 primitive
            spi_cs0_n       : out   std_logic;
            spi_mosi        : out   std_logic;
            spi_miso        : in    std_logic;
            -- DDR3 SDRAM
            ddr3_reset_n    : out   std_logic;
            ddr3_ck_p       : out   std_logic_vector( 0 downto 0);
            ddr3_ck_n       : out   std_logic_vector( 0 downto 0);
            ddr3_cke        : out   std_logic_vector( 0 downto 0);
            ddr3_cs_n       : out   std_logic_vector( 0 downto 0);
            ddr3_odt        : out   std_logic_vector( 0 downto 0);
            ddr3_ras_n      : out   std_logic;
            ddr3_cas_n      : out   std_logic;
            ddr3_we_n       : out   std_logic;
            ddr3_ba         : out   std_logic_vector( 2 downto 0);
            ddr3_addr       : out   std_logic_vector(13 downto 0);
            ddr3_dm         : out   std_logic_vector( 7 downto 0);
            ddr3_dqs_p      : inout std_logic_vector( 7 downto 0);
            ddr3_dqs_n      : inout std_logic_vector( 7 downto 0);
            ddr3_dq         : inout std_logic_vector(63 downto 0);
            -- XAUI
            rxaui_tx_l0_p    : out   std_logic;
            rxaui_tx_l0_n    : out   std_logic;
            rxaui_tx_l1_p    : out   std_logic;
            rxaui_tx_l1_n    : out   std_logic;
            rxaui_rx_l0_p    : in    std_logic;
            rxaui_rx_l0_n    : in    std_logic;
            rxaui_rx_l1_p    : in    std_logic;
            rxaui_rx_l1_n    : in    std_logic;
            -- FMC interface
            fmc_reset_n     : out   std_logic;
            fmc_int_n       : in    std_logic;
            fmc_clk_sel     : out   std_logic;
            fmc_rclk        : in    std_logic;
            fmc_clk_fpga_p  : out   std_logic;
            fmc_clk_fpga_n  : out   std_logic;
            fmc_scl         : out   std_logic;
            fmc_sda         : inout std_logic;
            fmc_mdc         : out   std_logic;
            fmc_mdio        : inout std_logic;
            fmc_gpio        : inout std_logic_vector( 5 downto 0);
            fmc_phy_gpio    : inout std_logic_vector( 5 downto 0);
            -- Cooling fan
            fan_pwm         : out   std_logic;
            fan_tach        : in    std_logic;
            -- GPIO DIP SW
            gpio_dip_sw     : in    std_logic_vector( 3 downto 0);
            -- GPIO LEDs
            gpio_led        : out   std_logic_vector( 7 downto 0));
end xgvrd;


--------------------------------------------------------------------------------
--  XGVRD-TOP architecture
--------------------------------------------------------------------------------

architecture top of xgvrd is

    -- Components --------------------------------------------------------------


    -- Signals -----------------------------------------------------------------

    -- Clocks and resets
    signal xgmii_lock           : std_logic;                         -- GTX PLL locked
    signal xgmii_clk            : std_logic;                         -- Global Ethernet clock
    signal xgmii_rst            : std_logic;                         -- Ethernet clock domain reset
    signal sys_clk              : std_logic;                         -- System clock
    signal sys_clk_lock         : std_logic;                         -- System clock MMCM locked
    signal sys_rst              : std_logic;                         -- System clock domain reset
    signal clk_loop_in          : std_logic;                         -- External loopback input clock
    signal clk_loop_out         : std_logic;                         -- External loopback output clock

    -- CPU interrupts
    signal cpu_irq_0            : std_logic;                         -- GigE core interrupt request
    signal cpu_irq_1            : std_logic;                         -- Framebuffer interrupt request
    signal cpu_irq_2            : std_logic;                         -- Ethernet MAC interrupt request

    -- System control
    signal sys_net_up           : std_logic;                         -- Network is up and running
    signal sys_gpo              : std_logic_vector(  1 downto 0);    -- General-purpose outputs
    signal sys_time_stamp       : std_logic_vector( 63 downto 0);    -- Time stamp

    -- AXI4-Lite slave interface
    signal axi0_aresetn         : std_logic;
    --
    signal axi0_fb_awaddr       : std_logic_vector( 31 downto 0);
    signal axi0_fb_awprot       : std_logic_vector(  2 downto 0);
    signal axi0_fb_awvalid      : std_logic;
    signal axi0_fb_awready      : std_logic;
    signal axi0_fb_wdata        : std_logic_vector( 31 downto 0);
    signal axi0_fb_wstrb        : std_logic_vector(  3 downto 0);
    signal axi0_fb_wvalid       : std_logic;
    signal axi0_fb_wready       : std_logic;
    signal axi0_fb_bresp        : std_logic_vector(  1 downto 0);
    signal axi0_fb_bvalid       : std_logic;
    signal axi0_fb_bready       : std_logic;
    signal axi0_fb_araddr       : std_logic_vector( 31 downto 0);
    signal axi0_fb_arprot       : std_logic_vector(  2 downto 0);
    signal axi0_fb_arvalid      : std_logic;
    signal axi0_fb_arready      : std_logic;
    signal axi0_fb_rdata        : std_logic_vector( 31 downto 0);
    signal axi0_fb_rresp        : std_logic_vector(  1 downto 0);
    signal axi0_fb_rvalid       : std_logic;
    signal axi0_fb_rready       : std_logic;
    --
    signal axi1_gev_awaddr      : std_logic_vector( 31 downto 0);
    signal axi1_gev_awprot      : std_logic_vector(  2 downto 0);
    signal axi1_gev_awvalid     : std_logic;
    signal axi1_gev_awready     : std_logic;
    signal axi1_gev_wdata       : std_logic_vector( 31 downto 0);
    signal axi1_gev_wstrb       : std_logic_vector(  3 downto 0);
    signal axi1_gev_wvalid      : std_logic;
    signal axi1_gev_wready      : std_logic;
    signal axi1_gev_bresp       : std_logic_vector(  1 downto 0);
    signal axi1_gev_bvalid      : std_logic;
    signal axi1_gev_bready      : std_logic;
    signal axi1_gev_araddr      : std_logic_vector( 31 downto 0);
    signal axi1_gev_arprot      : std_logic_vector(  2 downto 0);
    signal axi1_gev_arvalid     : std_logic;
    signal axi1_gev_arready     : std_logic;
    signal axi1_gev_rdata       : std_logic_vector( 31 downto 0);
    signal axi1_gev_rresp       : std_logic_vector(  1 downto 0);
    signal axi1_gev_rvalid      : std_logic;
    signal axi1_gev_rready      : std_logic;
    --
    signal axi2_video_awaddr    : std_logic_vector( 31 downto 0);
    signal axi2_video_awprot    : std_logic_vector(  2 downto 0);
    signal axi2_video_awvalid   : std_logic;
    signal axi2_video_awready   : std_logic;
    signal axi2_video_wdata     : std_logic_vector( 31 downto 0);
    signal axi2_video_wstrb     : std_logic_vector(  3 downto 0);
    signal axi2_video_wvalid    : std_logic;
    signal axi2_video_wready    : std_logic;
    signal axi2_video_bresp     : std_logic_vector(  1 downto 0);
    signal axi2_video_bvalid    : std_logic;
    signal axi2_video_bready    : std_logic;
    signal axi2_video_araddr    : std_logic_vector( 31 downto 0);
    signal axi2_video_arprot    : std_logic_vector(  2 downto 0);
    signal axi2_video_arvalid   : std_logic;
    signal axi2_video_arready   : std_logic;
    signal axi2_video_rdata     : std_logic_vector( 31 downto 0);
    signal axi2_video_rresp     : std_logic_vector(  1 downto 0);
    signal axi2_video_rvalid    : std_logic;
    signal axi2_video_rready    : std_logic;

    -- Video processor to memory controller interface
    signal video_frame          : std_logic;                         -- Data frame valid
    signal video_dv             : std_logic;                         -- Current data valid
    signal video_data           : std_logic_vector(127 downto 0);    -- Video data
    signal video_fb_width       : std_logic_vector(  6 downto 0);    -- Data width

    -- AXI master interface
    signal axi_aclk             : std_logic;
    signal axi_aresetn          : std_logic;
    signal axi_rst              : std_logic;
    signal axi_awid             : std_logic_vector(  3 downto 0);
    signal axi_awlock           : std_logic_vector(  0 downto 0);
    signal axi_awaddr           : std_logic_vector( 31 downto 0);
    signal axi_awlen            : std_logic_vector(  7 downto 0);
    signal axi_awsize           : std_logic_vector(  2 downto 0);
    signal axi_awburst          : std_logic_vector(  1 downto 0);
    signal axi_awcache          : std_logic_vector(  3 downto 0);
    signal axi_awprot           : std_logic_vector(  2 downto 0);
    signal axi_awvalid          : std_logic;
    signal axi_awready          : std_logic;
    signal axi_wdata            : std_logic_vector(127 downto 0);
    signal axi_wstrb            : std_logic_vector( 15 downto 0);
    signal axi_wlast            : std_logic;
    signal axi_wvalid           : std_logic;
    signal axi_wready           : std_logic;
    signal axi_bid              : std_logic_vector(  3 downto 0) := (others => '0');
    signal axi_bresp            : std_logic_vector(  1 downto 0);
    signal axi_bvalid           : std_logic;
    signal axi_bready           : std_logic;
    signal axi_arid             : std_logic_vector(  3 downto 0);
    signal axi_arlock           : std_logic_vector(  0 downto 0);
    signal axi_araddr           : std_logic_vector( 31 downto 0);
    signal axi_arlen            : std_logic_vector(  7 downto 0);
    signal axi_arsize           : std_logic_vector(  2 downto 0);
    signal axi_arburst          : std_logic_vector(  1 downto 0);
    signal axi_arcache          : std_logic_vector(  3 downto 0);
    signal axi_arprot           : std_logic_vector(  2 downto 0);
    signal axi_arvalid          : std_logic;
    signal axi_arready          : std_logic;
    signal axi_rid              : std_logic_vector(  3 downto 0) := (others => '0');
    signal axi_rdata            : std_logic_vector(127 downto 0);
    signal axi_rresp            : std_logic_vector(  1 downto 0);
    signal axi_rlast            : std_logic;
    signal axi_rvalid           : std_logic;
    signal axi_rready           : std_logic;

    -- Write-read control interface
    signal wr_r_rsnd            : std_logic_vector( 31 downto 0);    -- Bottom address of memory area blocked for packet resend
    signal wr_r_bot             : std_logic_vector( 31 downto 0);    -- Bottom address of the currently read block
    signal wr_w_bot             : std_logic_vector( 31 downto 0);    -- Bottom address of the currently written block
    signal wr_w_top             : std_logic_vector( 31 downto 0);    -- Current AXI write addres
    signal wr_w_tstamp          : std_logic_vector( 63 downto 0);    -- Timestamp of the current block
    signal wr_w_bid             : std_logic_vector( 63 downto 0);    -- Block ID of the current block
    signal wr_w_active          : std_logic;                         -- Active block write
    signal wr_w_drop            : std_logic;                         -- Current block is being dropped
    signal wr_d_full            : std_logic;                         -- Block descriptor FIFO full
    signal wr_d_start           : std_logic_vector( 31 downto 0);    -- First address of the new block in memory
    signal wr_d_len             : std_logic_vector( 31 downto 0);    -- Total length of the new block
    signal wr_d_tstamp          : std_logic_vector( 63 downto 0);    -- Block timestamp
    signal wr_d_bid             : std_logic_vector( 63 downto 0);    -- Block ID
    signal wr_d_trail           : std_logic_vector( 15 downto 0);    -- Start address of the trailer
    signal wr_d_we              : std_logic;                         -- Block descriptor write enable

    -- Framebuffer to XGigE interface
    signal mem_data             : std_logic_vector( 63 downto 0);    -- Stream data
    signal mem_header           : std_logic;                         -- Header valid
    signal mem_write            : std_logic;                         -- Write enable
    signal mem_full             : std_logic;                         -- Data FIFO is full
    signal mem_scc              : std_logic;                         -- Stream channel is closed
    signal mem_max_len          : std_logic_vector( 23 downto 0);    -- Maximum packet length

    -- Packet resend interface
    signal rsnd_req             : std_logic;                         -- Resend request
    signal rsnd_blk_id          : std_logic_vector( 63 downto 0);    -- Block to be resent
    signal rsnd_first_pkt_id    : std_logic_vector( 31 downto 0);    -- First packet to resend
    signal rsnd_last_pkt_id     : std_logic_vector( 31 downto 0);    -- Last packet to resend

    -- MAC host interface
    signal mac_host_opcode      : std_logic_vector(  1 downto 0);
    signal mac_host_addr        : std_logic_vector(  9 downto 0);
    signal mac_host_wr_data     : std_logic_vector( 31 downto 0);
    signal mac_host_rd_data     : std_logic_vector( 31 downto 0);
    signal mac_host_miim_sel    : std_logic;
    signal mac_host_req         : std_logic;
    signal mac_host_miim_rdy    : std_logic;

    -- MDIO
    signal mac_mdc              : std_logic;                         -- Interface clock
    signal mac_mdio_in          : std_logic;                         -- MAC input data
    signal mac_mdio_out         : std_logic;                         -- MAC output data
    signal mac_mdio_tri         : std_logic;                         -- MAC tristate buffer control

    -- MAC transmit client
    signal mac_tx_data          : std_logic_vector( 63 downto 0);    -- Data
    signal mac_tx_data_valid    : std_logic_vector(  7 downto 0);    -- Data valid
    signal mac_tx_start         : std_logic;                         -- Start of frame
    signal mac_tx_underrun      : std_logic;                         -- Data underrun
    signal mac_tx_ack           : std_logic;                         -- First word acknowledge

    -- MAC receive client
    signal mac_rx_data          : std_logic_vector( 63 downto 0);    -- Data
    signal mac_rx_data_valid    : std_logic_vector(  7 downto 0);    -- Data valid
    signal mac_rx_good_frame    : std_logic;                         -- Frame correct
    signal mac_rx_bad_frame     : std_logic;                         -- Frame incorrect

    -- 64b XGMII
    signal xgmii_txd            : std_logic_vector( 63 downto 0);    -- Transmit data
    signal xgmii_txc            : std_logic_vector(  7 downto 0);    -- Transmit control
    signal xgmii_rxd            : std_logic_vector( 63 downto 0);    -- Receive data
    signal xgmii_rxc            : std_logic_vector(  7 downto 0);    -- Receive control

    -- RXAUI bridge control/status
    signal rxaui_signal_detect  : std_logic_vector(  1 downto 0);    -- Status from optical transceiver
    signal rxaui_align_status   : std_logic;                         -- Receiver lane alignment status
    signal rxaui_sync_status    : std_logic_vector(  3 downto 0);    -- Receiver synchronization status
    signal rxaui_mgt_tx_ready   : std_logic;                         -- Transmitter MGT status
    signal rxaui_config_vector  : std_logic_vector(  6 downto 0);    -- Configuration vector
    signal rxaui_status_vector  : std_logic_vector(  7 downto 0);    -- Status vector
    signal rxaui_rst            : std_logic;                         -- RXAUI bridge reset

    -- I2C bus signals
    signal fmc_sda_o            : std_logic;                         -- SDA output
    signal fmc_sda_i            : std_logic;                         -- SDA input
    signal fmc_scl_o            : std_logic;                         -- SCL output

    -- SPI bus internal signals
    signal spi_clk              : std_logic;                         -- SPI clock driving CCLK pin

    -- Action command trigger signals
    signal action_cmd_trig_out  : std_logic_vector(  3 downto 0);    -- ACTION cmd trigger out
    signal action_cmd_tgl       : std_logic_vector(  1 downto 0);    -- ACTION cmd toggle

begin

    -- Instantiation of components ---------------------------------------------

    -- CPU system
    CPU_INST: entity work.cpu
        port map   (-- Clocks and resets
                    ext_clk_p               => ext_clk_p,
                    ext_clk_n               => ext_clk_n,
                    ext_rst                 => ext_rst,
                    sys_clk                 => sys_clk,
                    sys_rst(0)              => sys_rst,
                    sys_locked              => sys_clk_lock,
                    -- Interrupt inputs
                    cpu_irq_0               => cpu_irq_0,
                    cpu_irq_1               => cpu_irq_1,
                    cpu_irq_2               => cpu_irq_2,
                    -- UART
                    uart_rxd                => uart_rxd,
                    uart_txd                => uart_txd,
                    -- AXI4-Lite masters (to connect external slaves)
                    m0_axi_aresetn(0)       => axi0_aresetn,
                    --
                    m0_axi_fb_awaddr        => axi0_fb_awaddr,
                    m0_axi_fb_awprot        => axi0_fb_awprot,
                    m0_axi_fb_awvalid(0)    => axi0_fb_awvalid,
                    m0_axi_fb_awready(0)    => axi0_fb_awready,
                    m0_axi_fb_wdata         => axi0_fb_wdata,
                    m0_axi_fb_wstrb         => axi0_fb_wstrb,
                    m0_axi_fb_wvalid(0)     => axi0_fb_wvalid,
                    m0_axi_fb_wready(0)     => axi0_fb_wready,
                    m0_axi_fb_bresp         => axi0_fb_bresp,
                    m0_axi_fb_bvalid(0)     => axi0_fb_bvalid,
                    m0_axi_fb_bready(0)     => axi0_fb_bready,
                    m0_axi_fb_araddr        => axi0_fb_araddr,
                    m0_axi_fb_arprot        => axi0_fb_arprot,
                    m0_axi_fb_arvalid(0)    => axi0_fb_arvalid,
                    m0_axi_fb_arready(0)    => axi0_fb_arready,
                    m0_axi_fb_rdata         => axi0_fb_rdata,
                    m0_axi_fb_rresp         => axi0_fb_rresp,
                    m0_axi_fb_rvalid(0)     => axi0_fb_rvalid,
                    m0_axi_fb_rready(0)     => axi0_fb_rready,
                    --
                    m1_axi_gev_awaddr       => axi1_gev_awaddr,
                    m1_axi_gev_awprot       => axi1_gev_awprot,
                    m1_axi_gev_awvalid(0)   => axi1_gev_awvalid,
                    m1_axi_gev_awready(0)   => axi1_gev_awready,
                    m1_axi_gev_wdata        => axi1_gev_wdata,
                    m1_axi_gev_wstrb        => axi1_gev_wstrb,
                    m1_axi_gev_wvalid(0)    => axi1_gev_wvalid,
                    m1_axi_gev_wready(0)    => axi1_gev_wready,
                    m1_axi_gev_bresp        => axi1_gev_bresp,
                    m1_axi_gev_bvalid(0)    => axi1_gev_bvalid,
                    m1_axi_gev_bready(0)    => axi1_gev_bready,
                    m1_axi_gev_araddr       => axi1_gev_araddr,
                    m1_axi_gev_arprot       => axi1_gev_arprot,
                    m1_axi_gev_arvalid(0)   => axi1_gev_arvalid,
                    m1_axi_gev_arready(0)   => axi1_gev_arready,
                    m1_axi_gev_rdata        => axi1_gev_rdata,
                    m1_axi_gev_rresp        => axi1_gev_rresp,
                    m1_axi_gev_rvalid(0)    => axi1_gev_rvalid,
                    m1_axi_gev_rready(0)    => axi1_gev_rready,
                    --
                    m2_axi_video_awaddr     => axi2_video_awaddr,
                    m2_axi_video_awprot     => axi2_video_awprot,
                    m2_axi_video_awvalid(0) => axi2_video_awvalid,
                    m2_axi_video_awready(0) => axi2_video_awready,
                    m2_axi_video_wdata      => axi2_video_wdata,
                    m2_axi_video_wstrb      => axi2_video_wstrb,
                    m2_axi_video_wvalid(0)  => axi2_video_wvalid,
                    m2_axi_video_wready(0)  => axi2_video_wready,
                    m2_axi_video_bresp      => axi2_video_bresp,
                    m2_axi_video_bvalid(0)  => axi2_video_bvalid,
                    m2_axi_video_bready(0)  => axi2_video_bready,
                    m2_axi_video_araddr     => axi2_video_araddr,
                    m2_axi_video_arprot     => axi2_video_arprot,
                    m2_axi_video_arvalid(0) => axi2_video_arvalid,
                    m2_axi_video_arready(0) => axi2_video_arready,
                    m2_axi_video_rdata      => axi2_video_rdata,
                    m2_axi_video_rresp      => axi2_video_rresp,
                    m2_axi_video_rvalid(0)  => axi2_video_rvalid,
                    m2_axi_video_rready(0)  => axi2_video_rready,
                    -- DDR3 SDRAM
                    ddr3_reset_n            => ddr3_reset_n,
                    ddr3_ck_p               => ddr3_ck_p,
                    ddr3_ck_n               => ddr3_ck_n,
                    ddr3_cke                => ddr3_cke,
                    ddr3_cs_n               => ddr3_cs_n,
                    ddr3_odt                => ddr3_odt,
                    ddr3_ras_n              => ddr3_ras_n,
                    ddr3_cas_n              => ddr3_cas_n,
                    ddr3_we_n               => ddr3_we_n,
                    ddr3_ba                 => ddr3_ba,
                    ddr3_addr               => ddr3_addr,
                    ddr3_dm                 => ddr3_dm,
                    ddr3_dqs_p              => ddr3_dqs_p,
                    ddr3_dqs_n              => ddr3_dqs_n,
                    ddr3_dq                 => ddr3_dq,
                    -- AXI4 slave (to connect external master)
                    s0_axi_aclk             => axi_aclk,
                    s0_axi_aresetn(0)       => axi_aresetn,
                    s0_axi_awid             => axi_awid,
                    s0_axi_awlock           => axi_awlock,
                    s0_axi_awqos            => (others => '0'),
                    s0_axi_awaddr           => axi_awaddr,
                    s0_axi_awlen            => axi_awlen,
                    s0_axi_awsize           => axi_awsize,
                    s0_axi_awburst          => axi_awburst,
                    s0_axi_awcache          => axi_awcache,
                    s0_axi_awprot           => axi_awprot,
                    s0_axi_awvalid          => axi_awvalid,
                    s0_axi_awready          => axi_awready,
                    s0_axi_wdata            => axi_wdata,
                    s0_axi_wstrb            => axi_wstrb,
                    s0_axi_wlast            => axi_wlast,
                    s0_axi_wvalid           => axi_wvalid,
                    s0_axi_wready           => axi_wready,
                    s0_axi_bid              => axi_bid,
                    s0_axi_bresp            => axi_bresp,
                    s0_axi_bvalid           => axi_bvalid,
                    s0_axi_bready           => axi_bready,
                    s0_axi_arid             => axi_arid,
                    s0_axi_arlock           => axi_arlock,
                    s0_axi_arqos            => (others => '0'),
                    s0_axi_araddr           => axi_araddr,
                    s0_axi_arlen            => axi_arlen,
                    s0_axi_arsize           => axi_arsize,
                    s0_axi_arburst          => axi_arburst,
                    s0_axi_arcache          => axi_arcache,
                    s0_axi_arprot           => axi_arprot,
                    s0_axi_arvalid          => axi_arvalid,
                    s0_axi_arready          => axi_arready,
                    s0_axi_rid              => axi_rid,
                    s0_axi_rdata            => axi_rdata,
                    s0_axi_rresp            => axi_rresp,
                    s0_axi_rlast            => axi_rlast,
                    s0_axi_rvalid           => axi_rvalid,
                    s0_axi_rready           => axi_rready);

    -- Video test pattern generator
    VIDEO_INST: entity work.videotpg_0
        port map   (s_axi_aclk              => sys_clk,
                    s_axi_aresetn           => axi0_aresetn,
                    s_axi_awaddr            => axi2_video_awaddr(15 downto 0),
                    s_axi_awprot            => axi2_video_awprot,
                    s_axi_awvalid           => axi2_video_awvalid,
                    s_axi_awready           => axi2_video_awready,
                    s_axi_wdata             => axi2_video_wdata,
                    s_axi_wstrb             => axi2_video_wstrb,
                    s_axi_wvalid            => axi2_video_wvalid,
                    s_axi_wready            => axi2_video_wready,
                    s_axi_bresp             => axi2_video_bresp,
                    s_axi_bvalid            => axi2_video_bvalid,
                    s_axi_bready            => axi2_video_bready,
                    s_axi_araddr            => axi2_video_araddr(15 downto 0),
                    s_axi_arprot            => axi2_video_arprot,
                    s_axi_arvalid           => axi2_video_arvalid,
                    s_axi_arready           => axi2_video_arready,
                    s_axi_rdata             => axi2_video_rdata,
                    s_axi_rresp             => axi2_video_rresp,
                    s_axi_rvalid            => axi2_video_rvalid,
                    s_axi_rready            => axi2_video_rready,
                    gpio_in(31 downto 4)    => (others => '0'),
                    gpio_in(3 downto 0)     => gpio_dip_sw,
                    gpio_out                => open,
                    gev_scc                 => mem_scc,
                    fb_clk                  => axi_aclk,
                    fb_rst                  => axi_rst,
                    fb_frame                => video_frame,
                    fb_dv                   => video_dv,
                    fb_data                 => video_data(63 downto 0),
                    fb_width                => video_fb_width);

    -- AXI framebuffer
    FRAMEBUF_INST: entity work.framebuf_0
        port map   (sys_en                  => sys_net_up,
                    sys_tstamp              => sys_time_stamp,
                    sys_irq                 => cpu_irq_1,
                    s0_axi_aclk             => sys_clk,
                    s0_axi_aresetn          => axi0_aresetn,
                    s0_axi_awaddr           => axi0_fb_awaddr(15 downto 0),
                    s0_axi_awprot           => axi0_fb_awprot,
                    s0_axi_awvalid          => axi0_fb_awvalid,
                    s0_axi_awready          => axi0_fb_awready,
                    s0_axi_wdata            => axi0_fb_wdata,
                    s0_axi_wstrb            => axi0_fb_wstrb,
                    s0_axi_wvalid           => axi0_fb_wvalid,
                    s0_axi_wready           => axi0_fb_wready,
                    s0_axi_bresp            => axi0_fb_bresp,
                    s0_axi_bvalid           => axi0_fb_bvalid,
                    s0_axi_bready           => axi0_fb_bready,
                    s0_axi_araddr           => axi0_fb_araddr(15 downto 0),
                    s0_axi_arprot           => axi0_fb_arprot,
                    s0_axi_arvalid          => axi0_fb_arvalid,
                    s0_axi_arready          => axi0_fb_arready,
                    s0_axi_rdata            => axi0_fb_rdata,
                    s0_axi_rresp            => axi0_fb_rresp,
                    s0_axi_rvalid           => axi0_fb_rvalid,
                    s0_axi_rready           => axi0_fb_rready,
                    din_clk                 => axi_aclk,
                    din_rst                 => axi_rst,
                    din_frame               => video_frame,
                    din_field               => '0',
                    din_line                => video_dv,
                    din_trailer             => '0',
                    din_width               => video_fb_width,
                    din_data                => video_data,
                    din_busy                => open,
                    din_idle                => open,
                    wr_r_rsnd               => wr_r_rsnd,
                    wr_r_bot                => wr_r_bot,
                    wr_w_bot                => wr_w_bot,
                    wr_w_top                => wr_w_top,
                    wr_w_tstamp             => wr_w_tstamp,
                    wr_w_bid                => wr_w_bid,
                    wr_w_active             => wr_w_active,
                    wr_w_drop               => wr_w_drop,
                    wr_d_full               => wr_d_full,
                    wr_d_start              => wr_d_start,
                    wr_d_len                => wr_d_len,
                    wr_d_tstamp             => wr_d_tstamp,
                    wr_d_bid                => wr_d_bid,
                    wr_d_trail              => wr_d_trail,
                    wr_d_we                 => wr_d_we,
                    rd_r_rsnd               => wr_r_rsnd,
                    rd_r_bot                => wr_r_bot,
                    rd_w_bot                => wr_w_bot,
                    rd_w_top                => wr_w_top,
                    rd_w_tstamp             => wr_w_tstamp,
                    rd_w_bid                => wr_w_bid,
                    rd_w_active             => wr_w_active,
                    rd_w_drop               => wr_w_drop,
                    rd_d_full               => wr_d_full,
                    rd_d_start              => wr_d_start,
                    rd_d_len                => wr_d_len,
                    rd_d_tstamp             => wr_d_tstamp,
                    rd_d_bid                => wr_d_bid,
                    rd_d_trail              => wr_d_trail,
                    rd_d_we                 => wr_d_we,
                    tx_scc                  => mem_scc,
                    tx_full                 => mem_full,
                    tx_max_len              => mem_max_len,
                    tx_write                => mem_write,
                    tx_header               => mem_header,
                    tx_data                 => mem_data,
                    rsnd_req                => rsnd_req,
                    rsnd_bid                => rsnd_blk_id,
                    rsnd_pid_f              => rsnd_first_pkt_id,
                    rsnd_pid_l              => rsnd_last_pkt_id,
                    m0_axi_aclk             => axi_aclk,
                    m0_axi_aresetn          => axi_aresetn,
                    m0_axi_awid             => axi_awid,
                    m0_axi_awaddr           => axi_awaddr,
                    m0_axi_awlen            => axi_awlen,
                    m0_axi_awsize           => axi_awsize,
                    m0_axi_awburst          => axi_awburst,
                    m0_axi_awlock           => axi_awlock,
                    m0_axi_awcache          => axi_awcache,
                    m0_axi_awprot           => axi_awprot,
                    m0_axi_awvalid          => axi_awvalid,
                    m0_axi_awready          => axi_awready,
                    m0_axi_wdata            => axi_wdata,
                    m0_axi_wstrb            => axi_wstrb,
                    m0_axi_wlast            => axi_wlast,
                    m0_axi_wvalid           => axi_wvalid,
                    m0_axi_wready           => axi_wready,
                    m0_axi_bid              => axi_bid(3 downto 0),
                    m0_axi_bresp            => axi_bresp,
                    m0_axi_bvalid           => axi_bvalid,
                    m0_axi_bready           => axi_bready,
                    m0_axi_arid             => axi_arid,
                    m0_axi_araddr           => axi_araddr,
                    m0_axi_arlen            => axi_arlen,
                    m0_axi_arsize           => axi_arsize,
                    m0_axi_arburst          => axi_arburst,
                    m0_axi_arlock           => axi_arlock,
                    m0_axi_arcache          => axi_arcache,
                    m0_axi_arprot           => axi_arprot,
                    m0_axi_arvalid          => axi_arvalid,
                    m0_axi_arready          => axi_arready,
                    m0_axi_rid              => axi_rid(3 downto 0),
                    m0_axi_rdata            => axi_rdata,
                    m0_axi_rresp            => axi_rresp,
                    m0_axi_rlast            => axi_rlast,
                    m0_axi_rvalid           => axi_rvalid,
                    m0_axi_rready           => axi_rready);

    -- GigE Vision core
    GIGE_INST: entity work.xgige_0
        port map   (-- AXI4-Lite slave interface
                    s0_axi_aclk             => sys_clk,
                    s0_axi_aresetn          => axi0_aresetn,
                    s0_axi_awaddr           => axi1_gev_awaddr(15 downto 0),
                    s0_axi_awprot           => axi1_gev_awprot,
                    s0_axi_awvalid          => axi1_gev_awvalid,
                    s0_axi_awready          => axi1_gev_awready,
                    s0_axi_wdata            => axi1_gev_wdata,
                    s0_axi_wstrb            => axi1_gev_wstrb,
                    s0_axi_wvalid           => axi1_gev_wvalid,
                    s0_axi_wready           => axi1_gev_wready,
                    s0_axi_bresp            => axi1_gev_bresp,
                    s0_axi_bvalid           => axi1_gev_bvalid,
                    s0_axi_bready           => axi1_gev_bready,
                    s0_axi_araddr           => axi1_gev_araddr(15 downto 0),
                    s0_axi_arprot           => axi1_gev_arprot,
                    s0_axi_arvalid          => axi1_gev_arvalid,
                    s0_axi_arready          => axi1_gev_arready,
                    s0_axi_rdata            => axi1_gev_rdata,
                    s0_axi_rresp            => axi1_gev_rresp,
                    s0_axi_rvalid           => axi1_gev_rvalid,
                    s0_axi_rready           => axi1_gev_rready,
                    -- Global ports
                    sys_irq                 => cpu_irq_0,
                    sys_net_up              => sys_net_up,
                    sys_uart_bypass         => open,
                    sys_gpo                 => sys_gpo,
                    sys_type                => open,
                    sys_mac_addr            => open,
                    sys_time_stamp          => sys_time_stamp,
                    -- ACTION_CMD trigger interface
                    action_trigger_in       => (others => '0'),
                    action_trigger_out      => action_cmd_trig_out,
                    -- I2C bus
                    i2c_scl                 => fmc_scl_o,
                    i2c_sda_o               => fmc_sda_o,
                    i2c_sda_i               => fmc_sda_i,
                    -- SPI bus
                    spi_clk                 => spi_clk,
                    spi_cs_n                => spi_cs0_n,
                    spi_mosi                => spi_mosi,
                    spi_miso                => spi_miso,
                    -- Memory controller interface
                    tx_stm_clk              => axi_aclk,
                    mem_clk                 => axi_aclk,
                    mem_data                => mem_data,
                    mem_header              => mem_header,
                    mem_write               => mem_write,
                    mem_scc(0)              => mem_scc,
                    mem_full                => mem_full,
                    mem_max_len             => mem_max_len(15 downto 0),
                    rsnd_req                => rsnd_req,
                    rsnd_channel            => open,
                    rsnd_blk_id             => rsnd_blk_id,
                    rsnd_first_pkt_id       => rsnd_first_pkt_id,
                    rsnd_last_pkt_id        => rsnd_last_pkt_id,
                    -- Received stream channel output (AXI4-Stream)
                    rx_axis_aclk            => '0',
                    rx_axis_aresetn         => '0',
                    rx_axis_tvalid          => open,
                    rx_axis_tdata           => open,
                    rx_axis_tstrb           => open,
                    rx_axis_tlast           => open,
                    rx_axis_tid             => open,
                    rx_axis_tuser           => open,
                    -- MAX host interface
                    mac_host_req            => mac_host_req,
                    mac_host_miimsel        => mac_host_miim_sel,
                    mac_host_opcode         => mac_host_opcode,
                    mac_host_addr           => mac_host_addr,
                    mac_host_wrdata         => mac_host_wr_data,
                    mac_host_rddata         => mac_host_rd_data,
                    mac_host_miimrdy        => mac_host_miim_rdy,
                    -- MAC TX interface
                    mac_tx_clk              => xgmii_clk,
                    mac_tx_clk_en           => '1',
                    mac_tx_data             => mac_tx_data,
                    mac_tx_data_valid       => mac_tx_data_valid,
                    mac_tx_start            => mac_tx_start,
                    mac_tx_underrun         => mac_tx_underrun,
                    mac_tx_ack              => mac_tx_ack,
                    -- MAC RX interface
                    mac_rx_clk              => xgmii_clk,
                    mac_rx_clk_en           => '1',
                    mac_rx_data             => mac_rx_data,
                    mac_rx_data_valid       => mac_rx_data_valid,
                    mac_rx_good_frame       => mac_rx_good_frame,
                    mac_rx_bad_frame        => mac_rx_bad_frame,
                    -- PHY interface
                    phy_rst_n               => open);
                    mem_max_len(23 downto 16) <= x"00";

    -- 10Gbps Ethernet MAC
    XGMAC_INST: entity work.xgmac_0
        port map   (reset                   => xgmii_rst,
                    ptp_pps                 => open,
                    ptp_time                => open,
                    tx_underrun             => mac_tx_underrun,
                    tx_data                 => mac_tx_data,
                    tx_data_valid           => mac_tx_data_valid,
                    tx_start                => mac_tx_start,
                    tx_ack                  => mac_tx_ack,
                    tx_ifg_delay            => (others => '0'),
                    tx_pause_val            => (others => '0'),
                    tx_pause_req            => '0',
                    rx_data                 => mac_rx_data,
                    rx_data_valid           => mac_rx_data_valid,
                    rx_good_frame           => mac_rx_good_frame,
                    rx_bad_frame            => mac_rx_bad_frame,
                    host_clk                => sys_clk,
                    host_opcode             => mac_host_opcode,
                    host_addr               => mac_host_addr,
                    host_wr_data            => mac_host_wr_data,
                    host_rd_data            => mac_host_rd_data,
                    host_miim_sel           => mac_host_miim_sel,
                    host_req                => mac_host_req,
                    host_miim_rdy           => mac_host_miim_rdy,
                    host_irq                => cpu_irq_2,
                    mdc                     => mac_mdc,
                    mdio_in                 => mac_mdio_in,
                    mdio_out                => mac_mdio_out,
                    mdio_tri                => mac_mdio_tri,
                    tx_clk                  => xgmii_clk,
                    tx_clk_en               => open,
                    tx_dcm_lock             => rxaui_mgt_tx_ready,  -- Can be tied to '1'
                    xgmii_txd               => xgmii_txd,
                    xgmii_txc               => xgmii_txc,
                    rx_clk                  => xgmii_clk,
                    rx_clk_en               => open,
                    rx_dcm_lock             => rxaui_align_status,  -- Can be tied to '1'
                    xgmii_rxd               => xgmii_rxd,
                    xgmii_rxc               => xgmii_rxc);

    -- RXAUI bridge
    RXAUI_INST: entity work.rxaui_0
        port map   (reset                   => sys_rst,
                    dclk                    => sys_clk,
                    clk156_out              => xgmii_clk,
                    clk156_lock             => xgmii_lock,
                    refclk_out              => open,
                    refclk_p                => ref_clk_p,
                    refclk_n                => ref_clk_n,
                    qplloutclk_out          => open,
                    qplllock_out            => open,
                    qplloutrefclk_out       => open,
                    xgmii_txd               => xgmii_txd,
                    xgmii_txc               => xgmii_txc,
                    xgmii_rxd               => xgmii_rxd,
                    xgmii_rxc               => xgmii_rxc,
                    rxaui_tx_l0_p           => rxaui_tx_l0_p,
                    rxaui_tx_l0_n           => rxaui_tx_l0_n,
                    rxaui_tx_l1_p           => rxaui_tx_l1_p,
                    rxaui_tx_l1_n           => rxaui_tx_l1_n,
                    rxaui_rx_l0_p           => rxaui_rx_l0_p,
                    rxaui_rx_l0_n           => rxaui_rx_l0_n,
                    rxaui_rx_l1_p           => rxaui_rx_l1_p,
                    rxaui_rx_l1_n           => rxaui_rx_l1_n,
                    signal_detect           => rxaui_signal_detect,
                    debug(5)                => rxaui_align_status,  -- Align status
                    debug(4 downto 1)       => rxaui_sync_status,   -- Synchronization status
                    debug(0)                => rxaui_mgt_tx_ready,  -- TX phase align complete
                    configuration_vector    => rxaui_config_vector,
                    status_vector           => rxaui_status_vector);


    -- KC705 platform specific logic -------------------------------------------

    -- Fan PWM
    FAN_PWM_PROC: process (sys_clk)
        variable div    : unsigned(11 downto 0);
    begin
        if rising_edge(sys_clk) then
            if (sys_rst = '1') then
                fan_pwm <= '1';
                div     := (others => '0');
            else
                if (div(11 downto 10) = "00") then
                    fan_pwm <= '1';
                elsif (div(11 downto 10) = unsigned(sys_gpo)) then
                    fan_pwm <= '0';
                end if;
                div := div + 1;
            end if;
        end if;
    end process FAN_PWM_PROC;

    -- Kintex-7 startup block for SPI clock
    STARTUPE2_INST: STARTUPE2
        generic map(PROG_USR        => "FALSE",     -- Activate program event security feature. Requires encrypted bitstreams.
                    SIM_CCLK_FREQ   => 10.0)        -- Set the Configuration Clock Frequency(ns) for simulation.
        port map   (CFGCLK          => open,        -- 1-bit output: Configuration main clock output
                    CFGMCLK         => open,        -- 1-bit output: Configuration internal oscillator clock output
                    EOS             => open,        -- 1-bit output: Active high output signal indicating the End Of Startup.
                    PREQ            => open,        -- 1-bit output: PROGRAM request to fabric output
                    CLK             => '0',         -- 1-bit input: User start-up clock input
                    GSR             => '0',         -- 1-bit input: Global Set/Reset input (GSR cannot be used for the port name)
                    GTS             => '0',         -- 1-bit input: Global 3-state input (GTS cannot be used for the port name)
                    KEYCLEARB       => '0',         -- 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM)
                    PACK            => '0',         -- 1-bit input: PROGRAM acknowledge input
                    USRCCLKO        => spi_clk,     -- 1-bit input: User CCLK input
                    USRCCLKTS       => '0',         -- 1-bit input: User CCLK 3-state enable input
                    USRDONEO        => '1',         -- 1-bit input: User DONE pin output control
                    USRDONETS       => '1');        -- 1-bit input: User DONE 3-state enable output


    -- Various glue logic ------------------------------------------------------

    -- Ethernet clock domain reset and phy reset
    XGMII_RST_PROC: process (xgmii_clk, ext_rst, xgmii_lock)
        variable shreg  : unsigned(7 downto 0) := (others => '1');
    begin
        if (ext_rst = '1') or (xgmii_lock = '0') then
            xgmii_rst <= '1';
            shreg     := (others => '1');
        elsif rising_edge(xgmii_clk) then
            xgmii_rst <= shreg(shreg'left);
            shreg     := shreg(shreg'left - 1 downto 0) & '0';
        end if;
    end process XGMII_RST_PROC;

    -- XAUI reset (wait 1.31ms for align)
    XAUI_RST_PROC: process (sys_clk, xgmii_rst)
        variable rxaui_rst_cnt  : unsigned(17 downto 0) := (others => '1');
    begin
        if (xgmii_rst = '1') then
            rxaui_rst     <= '1';
            rxaui_rst_cnt := (others => '1');
        elsif rising_edge(sys_clk) then
            rxaui_rst <= rxaui_rst_cnt(rxaui_rst_cnt'left);
            if rxaui_rst_cnt(rxaui_rst_cnt'left) = '1' or rxaui_align_status = '0' then
                rxaui_rst_cnt := rxaui_rst_cnt - 1;
            end if;
        end if;
    end process XAUI_RST_PROC;

    -- Action command
    ACT_TGL_PROC: process(sys_clk)
    begin
        if rising_edge(sys_clk) then
            if action_cmd_trig_out(0) = '1' then
                action_cmd_tgl(0) <= not action_cmd_tgl(0);
            end if;
            if action_cmd_trig_out(1) = '1' then
                action_cmd_tgl(1) <= not action_cmd_tgl(1);
            end if;
        end if;
    end process ACT_TGL_PROC;

    -- XAUI bridge configuration/status inputs
    rxaui_config_vector <= "00000" & rxaui_rst & "0";   -- Configuration vector
    rxaui_signal_detect <= "11";                        -- Optical transceiver status

    -- PHY MDIO
    MDIO_IOBUF_INST: IOBUF
        port map   (I   => mac_mdio_out,
                    O   => mac_mdio_in,
                    T   => mac_mdio_tri,
                    IO  => fmc_mdio);
    fmc_mdc <= mac_mdc;

    -- I2C bus
    I2C_SDA_IOBUF_INST: IOBUF
        port map   (I   => '0',
                    O   => fmc_sda_i,
                    T   => fmc_sda_o,
                    IO  => fmc_sda);
    fmc_scl <= fmc_scl_o;

    -- FMC card reset
    fmc_reset_n <= not xgmii_rst;
    
    axi_rst                   <= not axi_aresetn;       -- Synchronous reset
    video_data(127 downto 64) <= (others => '0');


    -- Test points -------------------------------------------------------------

    -- GPIO LEDs
    gpio_led(0) <= action_cmd_tgl(0);
    gpio_led(1) <= action_cmd_tgl(1);
    gpio_led(2) <= '0';
    gpio_led(3) <= '0';
    gpio_led(4) <= '0';
    gpio_led(5) <= '0';
    gpio_led(6) <= '0';
    gpio_led(7) <= '0';

    fmc_clk_sel    <= '0';
    fmc_clk_fpga_p <= '0';
    fmc_clk_fpga_n <= '0';
    fmc_gpio       <= (others => '0');
    fmc_phy_gpio   <= (others => '0');

end top;
