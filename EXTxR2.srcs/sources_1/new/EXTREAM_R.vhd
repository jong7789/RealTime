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

--library ieee;
--use     ieee.std_logic_1164.all;
--use     ieee.numeric_std.all;

--library unisim;
--use     unisim.vcomponents.all;

library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;
    use IEEE.STD_LOGIC_UNSIGNED.ALL;
    use IEEE.STD_LOGIC_ARITH.ALL;

library UNISIM;
    use UNISIM.VCOMPONENTS.ALL;
    use WORK.TOP_HEADER.ALL;

--------------------------------------------------------------------------------
--  XGVRD-TOP entity
--------------------------------------------------------------------------------

entity EXTREAM_R is
--    generic ( GNR_MODEL : string  := "EXT1616R" );
    generic ( GNR_MODEL : string  := "EXT3643R" );
    port   (
            SYSTEM_CLK_P : in    std_logic;
            SYSTEM_CLK_N : in    std_logic;
            
            ROIC_DCLK_P : in std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
            ROIC_DCLK_N : in std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0);
            ROIC_FCLK_P : in std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0);
            ROIC_FCLK_N : in std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0);
            ROIC_DOUT_P : in std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
            ROIC_DOUT_N : in std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0);
    
            
            TEMP_SCL   : out   std_logic;
            TEMP_SDA   : inout std_logic;
            EEPROM_SCL : out   std_logic;
            EEPROM_SDA : inout std_logic;
            
            GATE_SHIFT_CLK    : out std_logic;
            GATE_SHIFT_CLK1L  : out std_logic; -- 210127 added
            GATE_SHIFT_CLK2L  : out std_logic;
            GATE_SHIFT_CLK1R  : out std_logic;
            GATE_SHIFT_CLK2R  : out std_logic;
            GATE_START_PULSE1 : out std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0);
            GATE_START_PULSE2 : out std_logic_vector(GATE_NUM2(GNR_MODEL)-1 downto 0);
            GATE_OUT_EN1      : out std_logic;
            GATE_OUT_EN2      : out std_logic;
            GATE_OUT_EN1L     : out std_logic; -- 210127 added
            GATE_OUT_EN2L     : out std_logic;
            GATE_OUT_EN1R     : out std_logic;
            GATE_OUT_EN2R     : out std_logic;
            GATE_ALL_OUT      : out std_logic;
            GATE_ALL_OUT_R    : out std_logic;
            GATE_CONFIG       : out std_logic_vector(GATE_CONFIG_NUM(GNR_MODEL)-1 downto 0);
            GATE_VGH_RST      : out std_logic;
    
            STATUS_LED : out   std_logic_vector(1 downto 0);
            
            PWR_EN : out   std_logic_vector(PWR_NUM(GNR_MODEL)-1 downto 0);

            EXP_IN  : in  std_logic; -- mbh 210511 1616 v0.3
            EXT_IN  : in  std_logic;
            EXT_OUT : out std_logic;
         
            F_ROIC_MCLK   : out std_logic_vector(ROIC_MCLK_NUM(GNR_MODEL) - 1 downto 0);
            F_ROIC_SYNC   : out std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1 downto 0);
            F_ROIC_TP_SEL : out std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1 downto 0);
            F_ROIC_SCLK   : out std_logic_vector(ROIC_SCLK_NUM(GNR_MODEL) - 1 downto 0);
            F_ROIC_CS     : out std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1 downto 0);
            F_ROIC_SDI    : out std_logic_vector(ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1 downto 0);
            F_ROIC_SDO    : in  std_logic_vector(ROIC_SDI_NUM(GNR_MODEL)-1 downto 0);   
            
            F_GPIO1 : inout std_logic;
            F_GPIO2 : inout std_logic;
            F_GPIO3 : inout std_logic;
            F_GPIO4 : inout std_logic;
            
            tb_alignreq  : in  std_logic :='0';
            tb_aligndone : out std_logic;
            
-- █▀▀ █▀▀ █░█
-- █▄█ ██▄ ▀▄▀            
            -- RS232 UART
--            uart_rxd        : in    std_logic;
--            uart_txd        : out   std_logic;
            UART_RX : in    std_logic;
            UART_TX : out    std_logic;
            -- SPI flash memory
--          --spi_clk         : out   std_logic;  -- Connected internally using the STARTUP2 primitive
--            spi_cs0_n       : out   std_logic;
--            spi_mosi        : out   std_logic;
--            spi_miso        : in    std_logic;
            FLASH_FCS : inout std_logic;
            FLASH_D   : inout std_logic_vector(3 downto 0);
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
            ddr3_addr       : out   std_logic_vector(14 downto 0);
            ddr3_dm         : out   std_logic_vector( 3 downto 0);
            ddr3_dqs_p      : inout std_logic_vector( 3 downto 0);
            ddr3_dqs_n      : inout std_logic_vector( 3 downto 0);
            ddr3_dq         : inout std_logic_vector(31 downto 0);
            -- XAUI
            PHY_SIP   : out std_logic_vector(1 downto 0);
            PHY_SIN   : out std_logic_vector(1 downto 0);
            PHY_SOP   : in  std_logic_vector(1 downto 0);
            PHY_SON   : in  std_logic_vector(1 downto 0);
            PHY_CLK_P : in  std_logic;
            PHY_CLK_N : in  std_logic;
            
            PHY_RESET_N : out   std_logic;
            PHY_MDC     : out   std_logic;
            PHY_MDIO    : inout std_logic
--            fmc_reset_n     : out   std_logic;
--            fmc_mdc         : out   std_logic;
--            fmc_mdio        : inout std_logic
            );
end EXTREAM_R;


--------------------------------------------------------------------------------
--  XGVRD-TOP architecture
--------------------------------------------------------------------------------

architecture top of EXTREAM_R is

    type tdata_par                  is array (0 to ROIC_NUM(GNR_MODEL)-1) of std_logic_vector(15 downto 0);
    
-- █▀▀ █▀▀ █░█
-- █▄█ ██▄ ▀▄▀        
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


                
-- █▀▀ ▀▄▀ ▀█▀ █▀█
-- ██▄ █░█ ░█░ █▀▄    
--    signal axi_clk    : std_logic := '0';
    signal sui_clk     : std_logic := '0';
    signal sui_rstn  : std_logic := '0';
--    signal saxi_clk  : std_logic := '0';
--    signal saxi_rstn : std_logic := '0';

    signal sroic_dclk : std_logic_vector(ROIC_DCLK_NUM(GNR_MODEL)-1 downto 0) := (others => '0');
    signal sroic_fclk : std_logic_vector(ROIC_FCLK_NUM(GNR_MODEL)-1 downto 0) := (others => '0');
    signal sroic_data : std_logic_vector(ROIC_NUM(GNR_MODEL)-1 downto 0) := (others => '0');

    signal sgate_cpv  : std_logic := '0';
    signal sgate_dio1 : std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0) := (others => '0');
    signal sgate_dio2 : std_logic_vector(GATE_NUM(GNR_MODEL)-1 downto 0) := (others => '0');
    signal sgate_oe1  : std_logic := '0';
    signal sgate_oe2  : std_logic := '0';
    signal sgate_xon  : std_logic := '0';
    signal sgate_ind  : std_logic := '0';
    signal sgate_flk  : std_logic := '0';

    signal shsync_tft : std_logic := '0';
    signal svsync_tft : std_logic := '0';
    signal shcnt_tft  : std_logic_vector(9 downto 0) := (others => '0');
    signal svcnt_tft  : std_logic_vector(11 downto 0) := (others => '0');
    signal sdata_tft  : std_logic_vector(DDR_BIT_W0( (GNR_MODEL))-1 downto 0) := (others => '0');

    signal shsync_ddr3 : std_logic := '0';
    signal svsync_ddr3 : std_logic := '0';
    signal shcnt_ddr3  : std_logic_vector(11 downto 0) := (others => '0');
    signal svcnt_ddr3  : std_logic_vector(11 downto 0) := (others => '0');
    signal sdata_ddr3  : std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0) := (others => '0');

    signal stpc_wen   : std_logic;
    signal stpc_waddr : std_logic_vector(11 downto 0);
    signal stpc_wdata : std_logic_vector(DDR_BIT_W1( (GNR_MODEL))-1 downto 0); 
    signal stpc_wvcnt : std_logic_vector(11 downto 0);

    signal savg_wen   : std_logic;
    signal savg_waddr : std_logic_vector(11 downto 0);
    signal savg_winfo : std_logic_vector(DDR_BIT_W2( (GNR_MODEL))-1 downto 0);
    signal savg_wvcnt : std_logic_vector(11 downto 0);

    signal sacc_wen   : std_logic;
    signal sacc_waddr : std_logic_vector(11 downto 0);
    signal sacc_wdata : std_logic_vector(DDR_BIT_W4( (GNR_MODEL))-1 downto 0);
    signal sacc_wvcnt : std_logic_vector(11 downto 0);

    signal spix_rdata : std_logic_vector(DDR_BIT_R0(GNR_MODEL)-1 downto 0) ;
    signal stpc_rdata : std_logic_vector(DDR_BIT_R1(GNR_MODEL)-1 downto 0) ;
    signal savg_rinfo : std_logic_vector(DDR_BIT_R2(GNR_MODEL)-1 downto 0) ;
    signal sofs_rinfo : std_logic_vector(DDR_BIT_R3(GNR_MODEL)-1 downto 0) ;
    signal sacc_rdata : std_logic_vector(DDR_BIT_R4(GNR_MODEL)-1 downto 0) ;

    signal sreq_data_ddr3 : std_logic := '0';

    signal shsync_calib : std_logic := '0';
    signal svsync_calib : std_logic := '0';
    signal shcnt_calib    : std_logic_vector(11 downto 0) := (others => '0');
    signal svcnt_calib    : std_logic_vector(11 downto 0) := (others => '0');
    signal sdata_calib    : std_logic_vector(63 downto 0) := (others => '0');

    signal shsync_img_proc : std_logic := '0';
    signal svsync_img_proc : std_logic := '0';
    signal shcnt_img_proc  : std_logic_vector(11 downto 0) := (others => '0');
    signal svcnt_img_proc  : std_logic_vector(11 downto 0) := (others => '0');
    signal sdata_img_proc  : std_logic_vector(63 downto 0) := (others => '0');

    signal sfb_frame : std_logic := '0';
    signal sfb_dv     : std_logic := '0';
    signal sfb_data  : std_logic_vector(63 downto 0) := (others => '0');
    signal sfb_width : std_logic_vector( 2 downto 0) := (others => '0');

    signal scalib_gain     : std_logic_vector(31 downto 0) := (others => '0');
    signal scalib_offset : std_logic_vector(31 downto 0) := (others => '0');
    signal scalib_defect : std_logic_vector(7 downto 0) := (others => '0');

    signal chgdet_osd_en : std_logic;
    signal chgdet_osd_da : std_logic_vector(16 - 1 downto 0);


  -- Register
    signal sreg_pwr_mode       : std_logic := '0';
    signal sreg_grab_en        : std_logic := '0';
    signal sreg_grab_done      : std_logic := '0';
    signal sreg_gate_en        : std_logic_vector(7 downto 0) := (others => '0');
    signal sreg_img_mode       : std_logic_vector(2 downto 0) := (others => '0');
    signal sreg_timing_mode    : std_logic_vector(1 downto 0) := (others => '0');
    signal sreg_rst_mode       : std_logic_vector(1 downto 0) := (others => '0');
    signal sreg_rst_num        : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_shutter        : std_logic := '0';
    signal sreg_erase_en       : std_logic := '0';
    signal sreg_erase_time     : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_trig_mode      : std_logic_vector(1 downto 0) := (others => '0');
    signal sreg_trig_delay     : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_trig_filt      : std_logic_vector(7 downto 0) := (others => '0');
    signal sreg_trig_valid     : std_logic := '0';
    signal sreg_roic_shaazen   : std_logic := '0';
    signal sreg_roic_tp_sel    : std_logic := '0';
    signal sreg_roic_fa        : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_cds1      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_cds2      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_intrst    : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_sync_aclk : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_dead      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_mute      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_sync_dclk : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_afe_dclk  : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_gate_oe        : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_gate_xon       : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_gate_xon_flk   : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_gate_flk       : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_gate_rst_cycle : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sexp_time      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_exp_time       : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_frame_time     : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_frame_num      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_frame_val      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_frame_cnt      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_ext_exp_time   : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_ext_frame_time : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_width          : std_logic_vector(11 downto 0) := (others => '0');
    signal sreg_height         : std_logic_vector(11 downto 0) := (others => '0');
    signal sreg_offsetx        : std_logic_vector(11 downto 0) := (others => '0');
    signal sreg_offsety        : std_logic_vector(11 downto 0) := (others => '0');
    signal sreg_rev_x          : std_logic := '0';
    signal sreg_rev_y          : std_logic := '0';
    signal sreg_roic_en        : std_logic := '0';
    signal sreg_roic_addr      : std_logic_vector(7 downto 0) := (others => '0');
    signal sreg_roic_wdata     : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_roic_rdata     : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_req_align      : std_logic := '0';
    signal sreg_tp_mode        : std_logic := '0';
    signal sreg_tp_sel         : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_tp_dtime       : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_tp_value       : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_out_en         : std_logic := '0';
    signal sreg_out_mode       : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_ddr_ch_en      : std_logic_vector(7 downto 0) := (others => '0');
    signal sreg_ddr_base_addr  : std_logic_vector(31 downto 0) := (others => '0');

    --* jhkim 28 -> 29bit
    --  29->30b ddr8Gb
    signal sreg_ddr_ch0_waddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch1_waddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch2_waddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch3_waddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch4_waddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch0_raddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch1_raddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch2_raddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch3_raddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_ch4_raddr   : std_logic_vector(29 downto 0) := (others => '0');
    signal sreg_ddr_out         : std_logic_vector(2 downto 0) := (others => '0');
    signal sreg_line_time       : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_debug           : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_debug_mode      : std_logic := '0';
    signal sreg_gain_cal        : std_logic := '0';
    signal sreg_offset_cal      : std_logic := '0';
    signal sreg_defect_mode     : std_logic := '0';
    signal sreg_defect_map      : std_logic := '0';
    signal sreg_mpc_ctrl        : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_mpc_num         : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_mpc_point0      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_mpc_point1      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_mpc_point2      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_mpc_point3      : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_defect_wen      : std_logic := '0';
    signal sreg_defect_addr     : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_defect_wdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_defect_rdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_defect2_wen     : std_logic := '0';
    signal sreg_defect2_addr    : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_defect2_wdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_defect2_rdata   : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_ldefect_mode    : std_logic := '0';
    signal sreg_rdefect_wen     : std_logic := '0';
    signal sreg_rdefect_addr    : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_rdefect_wdata   : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_rdefect_rdata   : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_cdefect_wen     : std_logic := '0';
    signal sreg_cdefect_addr    : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_cdefect_wdata   : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_cdefect_rdata   : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_dgain           : std_logic_vector(10 downto 0) := (others => '0');
    signal sreg_avg_en          : std_logic := '0';
    signal sreg_avg_level       : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_avg_end         : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_iproc_mode      : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_bright          : std_logic_vector(16 downto 0) := (others => '0');
    signal sreg_contrast        : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_pwr_done        : std_logic := '0';
    signal sreg_erase_done      : std_logic := '0';
    signal sreg_align_done      : std_logic := '0';
    signal sreg_roic_done       : std_logic := '0';
--    signal sreg_roic_temp       : tdata_par := (others => (others => '0'));
    signal sreg_roic_temp       : std_logic_vector(ROIC_NUM(GNR_MODEL)*16-1 downto 0);
    signal sreg_i2c_mode        : std_logic := '0';
    signal sreg_i2c_wen         : std_logic := '0';
    signal sreg_i2c_wsize       : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_i2c_wdata       : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_i2c_ren         : std_logic := '0';
    signal sreg_i2c_rsize       : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_i2c_rdata0      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_i2c_rdata1      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_i2c_rdata2      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_i2c_rdata3      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_i2c_done        : std_logic := '0';
    signal sreg_temp_en         : std_logic := '0';
    signal sreg_device_temp     : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_sd_wen          : std_logic := '0';
    signal sreg_sd_ren          : std_logic := '0';
    signal sreg_sd_addr         : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sd_rw_end       : std_logic := '0';
    signal sreg_api_ext_trig    : std_logic_vector(3 downto 0) := (others => '0');
    signal sreg_ext_trig_high   : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_ext_trig_period : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_ext_trig_active : std_logic_vector(1 downto 0) := "00";
    signal sreg_clk_mclk        : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_clk_dclk        : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_clk_roicdclk    : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_clk_uiclk       : std_logic_vector(15 downto 0) := (others => '0'); --# 260123
    signal sreg_led_ctrl        : std_logic_vector(3 downto 0) := (others => '0');

    signal obd_mclk     : std_logic;
    signal obd_clk_lock : std_logic;
    signal obd_dclk     : std_logic;

    signal sreg_fla_ctrl    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_fla_addr    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_fla_data    : std_logic_vector(31 downto 0) := (others => '0');
    
    signal sreg_flaw_ctrl     : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_flaw_cmd      : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_flaw_addr     : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_flaw_wdata    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_flaw_rdata    : std_logic_vector(31 downto 0) := (others => '0');
     
    signal sreg_sync_rcnt     : std_logic_vector(32*30-1 downto 0) := (others => '0');
    signal sreg_sync_ctrl     : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt0    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt1    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt2    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt3    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt4    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt5    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt6    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt7    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt8    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rcnt9    : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn0 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn1 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn2 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn3 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn4 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn5 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn6 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn7 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn8 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_avcn9 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw0 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw1 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw2 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw3 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw4 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw5 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw6 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw7 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw8 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sync_rdata_bglw9 : std_logic_vector(31 downto 0) := (others => '0');
     
    signal sreg_sm_ctrl  : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data0 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data1 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data2 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data3 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data4 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data5 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data6 : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_sm_data7 : std_logic_vector(31 downto 0) := (others => '0');

    signal sreg_bcal_ctrl  : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_bcal_data  : std_logic_vector(31 downto 0) := (others => '0');
    
    signal sreg_mpc_posoffset  : std_logic_vector(15 downto 0) := (others => '0');

    signal sd2m_xray           : std_logic;
    signal sd2m_dark           : std_logic;
    signal sreg_d2m_en           : std_logic;
    signal sreg_d2m_exp_in       : std_logic;
    signal sreg_d2m_sexp_time  : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_d2m_frame_time : std_logic_vector(31 downto 0) := (others => '0');
    signal sreg_d2m_xrst_num   : std_logic_vector(15 downto 0) := (others => '0');
    signal sreg_d2m_drst_num   : std_logic_vector(15 downto 0) := (others => '0');

    signal sreg_fw_busy : std_logic := '0';
    signal sreg_toprst_ctrl : std_logic_vector(15 downto 0) := (others => '0'); 

    signal sReg_DnrCtrl     : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sreg_SobelCoeff0 : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sreg_SobelCoeff1 : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sreg_SobelCoeff2 : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sreg_BlurOffset  : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sReg_AccCtrl     : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sReg_AccStat     : std_logic_vector(15 downto 0) := (others => '0'); 

    signal sreg_ExtTrigEn      : std_logic := '0';
    signal sreg_ExtRst_MODE    : std_logic_vector(7 downto 0) := (others => '0'); 
    signal sreg_ExtRst_DetTime : std_logic_vector(31 downto 0) := (others => '0'); 
    signal sExtTrig_Srst       : std_logic := '0';
    signal sreg_trigcnt        : std_logic_vector(16-1 downto 0) := (others => '0'); 
    signal sreg_osd_ctrl       : std_logic_vector(16-1 downto 0) := (others => '0'); 
            
    signal sreg_pwdac_cmd       : std_logic_vector(16 - 1 downto 0);
    signal sreg_pwdac_ticktime  : std_logic_vector(32 - 1 downto 0);
    signal sreg_pwdac_tickinc   : std_logic_vector(12 - 1 downto 0);
    signal sreg_pwdac_trig      : std_logic;
    signal sreg_pwdac_currlevel : std_logic_vector(16 - 1 downto 0);

    signal sreg_testpoint1     : std_logic_vector(16 - 1 downto 0); 
    signal sreg_testpoint2     : std_logic_vector(16 - 1 downto 0); 
    signal sreg_testpoint3     : std_logic_vector(16 - 1 downto 0); 
    signal sreg_testpoint4     : std_logic_vector(16 - 1 downto 0); 
    
    signal sroic_mclk_div   : std_logic := '0';
    signal sroic_sync_div   : std_logic := '0';
    signal sroic_tp_sel_div : std_logic := '0';
    signal sroic_sck_div    : std_logic := '0';
    signal sroic_sdo_div    : std_logic := '0';
    signal sroic_cs_div     : std_logic := '0';

    signal sext_trig_tmp : std_logic := '0';
    signal sext_trig_in  : std_logic := '0';
    signal sext_trig_out : std_logic := '0';
    signal sext_trig_cnt : std_logic_vector(31 downto 0) := (others => '0');

    signal stft_state : std_logic_vector(15 downto 0);

  --* tft ctrl state
    signal oostate_tftd : tstate_tft;
    signal oostate_grab : tstate_grab;
    signal oostate_tft    : tstate_tft;
    signal oostate_roic : tstate_roic;
    signal oostate_gate : tstate_gate;
    signal oostate_roic_setting : tstate_roic_setting;
    signal oostate_dpram_data_align : tstate_dpram_data_align;
    signal oostate_dpram_roi  : tstate_dpram_roi;
    signal oostate_avg : tstate_avg;

    signal stb_alignreq  : std_logic; -- simulation port
    signal stb_aligndone : std_logic;

    signal spi_rtl_0_io0_i : std_logic;
    signal spi_rtl_0_io0_o : std_logic;
    signal spi_rtl_0_io0_t : std_logic;
    signal spi_rtl_0_io1_i : std_logic;
    signal spi_rtl_0_io1_o : std_logic;
    signal spi_rtl_0_io1_t : std_logic;
    signal spi_rtl_0_io2_i : std_logic;
    signal spi_rtl_0_io2_o : std_logic;
    signal spi_rtl_0_io2_t : std_logic;
    signal spi_rtl_0_io3_i : std_logic;
    signal spi_rtl_0_io3_o : std_logic;
    signal spi_rtl_0_io3_t : std_logic;
    signal spi_rtl_0_sck_i : std_logic;
    signal spi_rtl_0_sck_o : std_logic;
    signal spi_rtl_0_sck_t : std_logic;
    signal spi_rtl_0_ss_i  : std_logic;
    signal spi_rtl_0_ss_o  : std_logic;
    signal spi_rtl_0_ss_t  : std_logic; 

    constant dummy : std_logic_vector(32-1 downto 0):=(others=> '0');
    signal s_spi_rtl_0_io0_o : std_logic;
    signal s_spi_rtl_0_io0_t : std_logic;
    signal s_spi_rtl_0_io1_o : std_logic;
    signal s_spi_rtl_0_io1_t : std_logic;  

    signal rsreg_width      : std_logic_vector(11 downto 0) := (others => '0');
    signal rsreg_height     : std_logic_vector(11 downto 0) := (others => '0');
    signal rsreg_offsetx    : std_logic_vector(11 downto 0) := (others => '0');
    signal rsreg_offsety    : std_logic_vector(11 downto 0) := (others => '0');
    signal rsreg_sexp_time  : std_logic_vector(31 downto 0) := (others => '0');
    signal rsreg_exp_time   : std_logic_vector(31 downto 0) := (others => '0');
    signal rsreg_frame_time : std_logic_vector(31 downto 0) := (others => '0');
    signal rsreg_frame_num  : std_logic_vector(15 downto 0) := (others => '0');
    signal rsreg_frame_val  : std_logic_vector(15 downto 0) := (others => '0');

    signal trig_num0    : std_logic_vector(16-1 downto 0);
    signal trig_num1    : std_logic_vector(16-1 downto 0);
    signal trig_num_cnt : std_logic_vector(16-1 downto 0);
    signal sEXT_OUT     : std_logic;  
    
    signal sbd_clk_lock_1d : std_logic := '0';
    signal sbd_clk_lock_2d : std_logic := '0';
    signal sbd_clk_lock_3d : std_logic := '0';
    signal sbd_clk_lock    : std_logic_vector(15 downto 0) := (others => '0'); 
    signal sbd_mclk        : std_logic := '0';
    signal sbd_dclk        : std_logic := '0';
    signal sclock_cnt      : std_logic_vector(10-1 downto 0) := (others=>'0');    
    signal sPWR_EN         : std_logic_vector(PWR_NUM(GNR_MODEL)-1 downto 0);

    --# roic str clk ctrl 220901
    signal sreg_roic_str : std_logic_vector(7 downto 0) := (others => '0');

    signal sreg_edge_ctrl   : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_edge_value  : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_edge_top    : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_edge_left   : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_edge_right  : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_edge_bottom : std_logic_vector(16-1 downto 0) := (others => '0');

    signal sreg_bnc_ctrl    : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_bnc_high    : std_logic_vector(16-1 downto 0) := (others => '0');

    signal sreg_EqCtrl      : std_logic_vector(16-1 downto 0) := (others => '0');
    signal sreg_EqTopVal    : std_logic_vector(16-1 downto 0) := (others => '0');

    signal sreg_ofga_lim    : std_logic_vector(16-1 downto 0) := (others => '0');
 
    signal ireg_req_align_pm : std_logic;

    signal svsync_tft_1d : std_logic;
    signal svsync_tft_2d : std_logic;
    signal svsync_tft_3d : std_logic;
    signal svsync_tft_4d : std_logic;

    signal svsync_ddr_1d : std_logic;
    signal svsync_ddr_2d : std_logic;
    signal svsync_ddr_3d : std_logic;
    signal svsync_ddr_4d : std_logic;

    signal isreg_width      : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_height     : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_offsetx    : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_offsety    : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_sexp_time  : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_exp_time   : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_frame_time : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_frame_num  : std_logic_vector(15 downto 0) := (others => '0');
    signal isreg_frame_val  : std_logic_vector(15 downto 0) := (others => '0');
    signal isreg_line_time  : std_logic_vector(15 downto 0) := (others => '0');

    signal isreg_width_1d      : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_height_1d     : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_offsetx_1d    : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_offsety_1d    : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_sexp_time_1d  : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_exp_time_1d   : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_frame_time_1d : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_frame_num_1d  : std_logic_vector(15 downto 0) := (others => '0');
    signal isreg_frame_val_1d  : std_logic_vector(15 downto 0) := (others => '0');
    signal isreg_line_time_1d  : std_logic_vector(15 downto 0) := (others => '0');

    signal isreg_width_2d      : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_height_2d     : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_offsetx_2d    : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_offsety_2d    : std_logic_vector(11 downto 0) := (others => '0');
    signal isreg_sexp_time_2d  : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_exp_time_2d   : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_frame_time_2d : std_logic_vector(31 downto 0) := (others => '0');
    signal isreg_frame_num_2d  : std_logic_vector(15 downto 0) := (others => '0');
    signal isreg_frame_val_2d  : std_logic_vector(15 downto 0) := (others => '0');
    signal isreg_line_time_2d  : std_logic_vector(15 downto 0) := (others => '0');

    signal runningCnt     : std_logic_vector(48-1 downto 0) := (others => '0');
    signal frametimeLimit : std_logic_vector(48-1 downto 0) := (others => '0');
    signal stoppedTrig    : std_logic := '0'; -- _vector(48-1 downto 0) := (others => '0');

    signal tftBlankCnt    : std_logic_vector(48-1 downto 0) := (others => '0');
    signal tftBlankCntLat : std_logic_vector(48-1 downto 0) := (others => '0');
    signal tftBlankCenter : std_logic;
    signal ddrBlankCnt    : std_logic_vector(48-1 downto 0) := (others => '0');
    signal ddrBlankCntLat : std_logic_vector(48-1 downto 0) := (others => '0');
    signal ddrBlankCenter : std_logic;
    
    signal ich0_waddr_pm  : std_logic_vector(11 downto 0);
    
    signal sddr_rstn : std_logic := '0';
    signal sddr_rst  : std_logic := '1';
    signal sys_rstn  : std_logic := '0';
    signal ext_rst   : std_logic := '0'; --# not use
    
    signal sref_clk  : std_logic := '0';
    signal sddr_clk  : std_logic := '0';
    signal scalib_done    : std_logic; -- DDR3 Init Calibration Done.
    
    signal axi2_awid    : std_logic_vector(3 downto 0);
    signal axi2_awaddr  : std_logic_vector(31 downto 0);
    signal axi2_awlen   : std_logic_vector(7 downto 0);
    signal axi2_awsize  : std_logic_vector(2 downto 0);
    signal axi2_awburst : std_logic_vector(1 downto 0);
    signal axi2_awlock  : std_logic_vector(0 downto 0);
    signal axi2_awvalid : std_logic;
    signal axi2_awready : std_logic;
    signal axi2_wdata   : std_logic_vector(511 downto 0);
    signal axi2_wstrb   : std_logic_vector(63 downto 0);
    signal axi2_wlast   : std_logic;
    signal axi2_wvalid  : std_logic;
    signal axi2_wready  : std_logic;
    signal axi2_bid     : std_logic_vector(3 downto 0);
    signal axi2_bresp   : std_logic_vector(1 downto 0);
    signal axi2_bvalid  : std_logic;
    signal axi2_bready  : std_logic;
    signal axi2_arid    : std_logic_vector(3 downto 0);
    signal axi2_araddr  : std_logic_vector(31 downto 0);
    signal axi2_arlen   : std_logic_vector(7 downto 0);
    signal axi2_arsize  : std_logic_vector(2 downto 0);
    signal axi2_arburst : std_logic_vector(1 downto 0);
    signal axi2_arlock  : std_logic_vector(0 downto 0);
    signal axi2_arvalid : std_logic;
    signal axi2_arready : std_logic;
    signal axi2_rid     : std_logic_vector(3 downto 0);
    signal axi2_rdata   : std_logic_vector(511 downto 0);
    signal axi2_rresp   : std_logic_vector(1 downto 0);
    signal axi2_rlast   : std_logic;
    signal axi2_rvalid  : std_logic;
    signal axi2_rready  : std_logic;

    signal axil_reg_awaddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal axil_reg_awprot  : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal axil_reg_awvalid : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_awready : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_wdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal axil_reg_wstrb   : STD_LOGIC_VECTOR ( 3 downto 0 );
    signal axil_reg_wvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_wready  : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_bresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal axil_reg_bvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_bready  : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_araddr  : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal axil_reg_arprot  : STD_LOGIC_VECTOR ( 2 downto 0 );
    signal axil_reg_arvalid : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_arready : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_rdata   : STD_LOGIC_VECTOR ( 31 downto 0 );
    signal axil_reg_rresp   : STD_LOGIC_VECTOR ( 1 downto 0 );
    signal axil_reg_rvalid  : STD_LOGIC_VECTOR ( 0 to 0 );
    signal axil_reg_rready  : STD_LOGIC_VECTOR ( 0 to 0 );
    
    signal FLASH_CLK      : std_logic;
    signal ge_FLASH_CLK   : std_logic;
    signal ge_FLASH_FCS   : std_logic;
    signal ge_FLASH_D     : std_logic_vector(1 downto 0); 
    signal sFLASH_FCS    : std_logic;

    signal epc_rddata     : std_logic_vector(31 downto 0); -- Data from peripherals to CPU
    signal epc_wrdata     : std_logic_vector(31 downto 0); -- Data from CPU to peripheral
    signal epc_addr       : std_logic_vector(15 downto 0); -- Peripheral address
    signal epc_be         : std_logic_vector( 3 downto 0); -- Byte enables
    signal epc_rnw        : std_logic;                     -- Read/write command
    signal epc_rdy        : std_logic;                     -- Peripherals ready
    signal epc_cs_n       : std_logic;                     -- Peripheral chip selects

--%begin
begin

    gen_tbport : if(SIMULATION = "ON") generate
    begin
        tb_aligndone <= sreg_align_done;
        stb_alignreq <= tb_alignreq;
    end generate gen_tbport;
    PWR_EN <= sPWR_EN;

       
-- █ █▄░█
-- █ █░▀█
-- %in
 ireg_req_align_pm <= sreg_req_align or stb_alignreq;

    U0_TI_TFT_TOP : entity work.TI_TFT_TOP
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            iext_clk_p => SYSTEM_CLK_P,
            iext_clk_n => SYSTEM_CLK_N,
            iext_rst   => ext_rst,

            iui_clk    => sui_clk,
            iui_rstn   => sbd_clk_lock(1), -- sui_rstn,

            iroic_dclk => sroic_dclk,
            iroic_fclk => sroic_fclk,
            iroic_data => sroic_data,

            ibd_mclk     => sbd_mclk,
            ibd_dclk     => sbd_dclk,
            ibd_clk_lock => sbd_clk_lock(0), -- sbd_clk_lock

            oroic_mclk    => sroic_mclk_div,
            oroic_sync    => sroic_sync_div,
            oroic_tp_sel  => sroic_tp_sel_div,
            oroic_spi_sck => sroic_sck_div,
            oroic_spi_cs  => sroic_cs_div,
            oroic_spi_sdo => sroic_sdo_div,
            iroic_spi_sdi => F_ROIC_SDO,

            ogate_cpv  => sgate_cpv,
            ogate_dio1 => sgate_dio1,
            ogate_dio2 => sgate_dio2,
            ogate_oe1  => sgate_oe1,
            ogate_oe2  => sgate_oe2,
            ogate_xon  => sgate_xon,
            ogate_ind  => sgate_ind,
            ogate_flk  => sgate_flk,

            opwr_en => sPWR_EN,

            ireg_roic_str   => sreg_roic_str,
            ireg_pwr_mode   => sreg_pwr_mode,
            ireg_grab_en    => sreg_grab_en,
            ireg_gate_en    => sreg_gate_en,
            ireg_img_mode   => sreg_img_mode,
            ireg_rst_mode   => sreg_rst_mode,
            ireg_rst_num    => sreg_rst_num,
            ireg_shutter    => sreg_shutter,
            ireg_erase_en   => sreg_erase_en,
            ireg_erase_time => sreg_erase_time,

            ireg_trig_mode  => sreg_trig_mode,
            ireg_trig_delay => sreg_trig_delay,
            ireg_trig_filt  => sreg_trig_filt,
            ireg_trig_valid => sreg_trig_valid,

            ireg_roic_tp_sel    => sreg_roic_tp_sel,
            ireg_roic_cds1      => sreg_roic_cds1,
            ireg_roic_cds2      => sreg_roic_cds2,
            ireg_roic_intrst    => sreg_roic_intrst,
            ireg_gate_oe        => sreg_gate_oe,
            ireg_gate_xon       => sreg_gate_xon,
            ireg_gate_xon_flk   => sreg_gate_xon_flk,
            ireg_gate_flk       => sreg_gate_flk,
            ireg_gate_rst_cycle => sreg_gate_rst_cycle,

            ireg_timing_mode    => sreg_timing_mode,

            ireg_sexp_time      => rsreg_sexp_time, -- mbh 210415
            ireg_exp_time       => rsreg_exp_time,
            ireg_frame_time     => rsreg_frame_time,
            ireg_frame_num      => rsreg_frame_num,
            ireg_frame_val      => rsreg_frame_val,
            oreg_frame_cnt      => sreg_frame_cnt,
            oreg_ext_exp_time   => sreg_ext_exp_time,
            oreg_ext_frame_time => sreg_ext_frame_time,

            ireg_width   => rsreg_width, -- mbh 210415 
            ireg_height  => rsreg_height,
            ireg_offsetx => rsreg_offsetx,
            ireg_offsety => rsreg_offsety,

            ireg_roic_en    => sreg_roic_en,
            ireg_roic_addr  => sreg_roic_addr,
            ireg_roic_wdata => sreg_roic_wdata,
            oreg_roic_rdata => sreg_roic_rdata,

            ireg_req_align => ireg_req_align_pm, --#231117 sreg_req_align or stb_alignreq, -- mbh 210129

            ireg_tp_mode  => sreg_tp_mode,
            ireg_tp_sel   => sreg_tp_sel,
            ireg_tp_dtime => sreg_tp_dtime,
            ireg_tp_value => sreg_tp_value,

            oreg_pwr_done   => sreg_pwr_done,
            oreg_erase_done => sreg_erase_done,
            oreg_roic_done  => sreg_roic_done,
            oreg_align_done => sreg_align_done,
            oreg_grab_done  => sreg_grab_done,

            ireg_bcal_ctrl => sreg_bcal_ctrl,
            oreg_bcal_data => sreg_bcal_data, 

            --# d2m port 
            ireg_d2m_en         => sreg_d2m_en,
            ireg_d2m_exp_in     => sreg_d2m_exp_in,
            ireg_d2m_sexp_time  => sreg_d2m_sexp_time,
            ireg_d2m_frame_time => sreg_d2m_frame_time,
            ireg_d2m_xrst_num   => sreg_d2m_xrst_num,
            ireg_d2m_drst_num   => sreg_d2m_drst_num,
            od2m_xray           => sd2m_xray,
            od2m_dark           => sd2m_dark,

            ireg_ExtTrigEn      => sreg_ExtTrigEn,
            ireg_ExtRst_MODE    => sreg_ExtRst_MODE,
            ireg_ExtRst_DetTime => sreg_ExtRst_DetTime,
            oExtTrig_Srst       => sExtTrig_Srst ,
            ostate_tftd         => oostate_tftd,

            osys_clk    => sys_clk,
            osys_locked => sys_clk_lock,
            oref_clk    => sref_clk,
            oddr_clk    => sddr_clk,
            oddr_rstn   => sddr_rstn,

            iext_trig => sext_trig_in,
            oext_trig => sext_trig_out,

            ohsync => shsync_tft,
            ovsync => svsync_tft,
            ohcnt  => shcnt_tft,
            ovcnt  => svcnt_tft,
            odata  => sdata_tft,
            
            ireg_sync_ctrl   => sreg_sync_ctrl,
            oreg_sync_rcnt0  =>  sreg_sync_rcnt0,
            oreg_sync_rcnt1  =>  sreg_sync_rcnt1,
            oreg_sync_rdata_AVCN0 =>  sreg_sync_rdata_AVCN0,
            oreg_sync_rdata_AVCN1 =>  sreg_sync_rdata_AVCN1,
            oreg_sync_rdata_BGLW0 =>  sreg_sync_rdata_BGLW0,
            oreg_sync_rdata_BGLW1 =>  sreg_sync_rdata_BGLW1,

            ireg_pwdac_cmd       => sreg_pwdac_cmd     ,
            ireg_pwdac_ticktime  => sreg_pwdac_ticktime,
            ireg_pwdac_tickinc   => sreg_pwdac_tickinc ,
            ireg_pwdac_trig      => sreg_pwdac_trig    ,
            oreg_pwdac_currlevel => sreg_pwdac_currlevel,

  --* tft ctrl state
            ostate_grab             => oostate_grab,
            ostate_tft              => oostate_tft,
            ostate_roic             => oostate_roic,
            ostate_gate             => oostate_gate,
            ostate_roic_setting     => oostate_roic_setting,
            ostate_dpram_data_align => oostate_dpram_data_align,
            ostate_dpram_roi        => oostate_dpram_roi
        );
            
-- █▀▄ █▀▄ █▀█
-- █▄▀ █▄▀ █▀▄
-- %ddr
 ich0_waddr_pm <= ("00" & shcnt_tft);
    U0_DDR3_TOP : entity work.DDR3_TOP
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            iui_clk            => sui_clk,
            iui_rstn           => sbd_clk_lock(2), -- sui_rstn,
            idata_clk          => sui_clk,
            --# if this use as a sleep, axi protocol makes system down.
            idata_rstn         => sbd_clk_lock(2), 
            --# it only stop sync generation block. 220510mbh
            isyncgen_rstn      => sbd_clk_lock(3),

            ireg_ddr_acc_ch_en => sreg_AccCtrl(1),  
            ireg_ddr_ch_en     => sreg_ddr_ch_en,
            ireg_ddr_base_addr => sreg_ddr_base_addr,
            ireg_ddr_ch0_waddr => sreg_ddr_ch0_waddr,
            ireg_ddr_ch1_waddr => sreg_ddr_ch1_waddr,
            ireg_ddr_ch2_waddr => sreg_ddr_ch2_waddr,
            ireg_ddr_ch3_waddr => sreg_ddr_ch3_waddr,
            ireg_ddr_ch4_waddr => sreg_ddr_ch4_waddr,
            ireg_ddr_ch0_raddr => sreg_ddr_ch0_raddr,
            ireg_ddr_ch1_raddr => sreg_ddr_ch1_raddr,
            ireg_ddr_ch2_raddr => sreg_ddr_ch2_raddr,
            ireg_ddr_ch3_raddr => sreg_ddr_ch3_raddr,
            ireg_ddr_ch4_raddr => sreg_ddr_ch4_raddr,
            ireg_ddr_out       => sreg_ddr_out,
            ireg_line_time     => sreg_line_time,
            ireg_sd_wen        => sreg_sd_wen,
            ireg_width         => sreg_width,
            ireg_height        => sreg_height,

            istate_tftd => oostate_tftd,

            ihsync => shsync_tft,
            ivsync => svsync_tft,
            ihcnt  => shcnt_tft,
            ivcnt  => svcnt_tft,
            idata  => sdata_tft,

            ohsync => shsync_ddr3,
            ovsync => svsync_ddr3,
            ohcnt  => shcnt_ddr3,
            ovcnt  => svcnt_ddr3,
            odata  => sdata_ddr3,

            ireq_data => sreq_data_ddr3,

            ich0_wen   => shsync_tft,
            ich0_waddr => ich0_waddr_pm, --# ("00" & shcnt_tft),
            ich0_wvcnt => svcnt_tft,
            ich0_wdata => sdata_tft,
            ich1_wen   => stpc_wen,
            ich1_waddr => stpc_waddr,
            ich1_wvcnt => stpc_wvcnt,
            ich1_wdata => stpc_wdata,
            ich2_wen   => savg_wen,
            ich2_waddr => savg_waddr,
            ich2_wvcnt => savg_wvcnt,
            ich2_wdata => savg_winfo,
            id2m_xray  => sd2m_xray,
            ich3_wen   => '0',
            ich3_waddr => (others =>'0'),
            ich3_wvcnt => (others =>'0'),
            ich3_wdata => (others =>'0'),
            ich4_wen   => sacc_wen,
            ich4_waddr => sacc_waddr,
            ich4_wvcnt => sacc_wvcnt,
            ich4_wdata => sacc_wdata,

            och0_rdata => open,
            och1_rdata => stpc_rdata,
            och2_rdata => savg_rinfo,
            och3_rdata => sofs_rinfo,
            och4_rdata => sacc_rdata,

            axi_awid    => axi2_awid,
            axi_awaddr  => axi2_awaddr,
            axi_awlen   => axi2_awlen,
            axi_awsize  => axi2_awsize,
            axi_awburst => axi2_awburst,
            axi_awlock  => axi2_awlock,
            axi_awvalid => axi2_awvalid,
            axi_awready => axi2_awready,
            axi_wdata   => axi2_wdata,
            axi_wstrb   => axi2_wstrb,
            axi_wlast   => axi2_wlast,
            axi_wvalid  => axi2_wvalid,
            axi_wready  => axi2_wready,
            axi_bid     => axi2_bid,
            axi_bresp   => axi2_bresp,
            axi_bvalid  => axi2_bvalid,
            axi_bready  => axi2_bready,
            axi_arid    => axi2_arid,
            axi_araddr  => axi2_araddr,
            axi_arlen   => axi2_arlen,
            axi_arsize  => axi2_arsize,
            axi_arburst => axi2_arburst,
            axi_arlock  => axi2_arlock,
            axi_arvalid => axi2_arvalid,
            axi_arready => axi2_arready,
            axi_rid     => axi2_rid,
            axi_rdata   => axi2_rdata,
            axi_rresp   => axi2_rresp,
            axi_rlast   => axi2_rlast,
            axi_rvalid  => axi2_rvalid,
            axi_rready  => axi2_rready
        );
            
-- █▀▀ ▄▀█ █░░
-- █▄▄ █▀█ █▄▄
-- %cal
G_CAL_2G: if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "2p5G") generate
begin
    U0_CALIB_TOP : entity work.CALIB_TOP
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            isys_clk   => sys_clk,
            idata_clk  => sui_clk,
            idata_rstn => sbd_clk_lock(4), -- sui_rstn,

            ireg_debug_mode   => sreg_debug_mode,
            ireg_gain_cal     => sreg_gain_cal,
            ireg_offset_cal   => sreg_offset_cal,
            ireg_ofga_lim     => sreg_ofga_lim,

            ireg_defect_mode  => sreg_defect_mode,
            ireg_ldefect_mode => sreg_ldefect_mode,
            ireg_defect_map   => sreg_defect_map,

            ireg_mpc_ctrl      => sreg_mpc_ctrl,
            ireg_mpc_num       => sreg_mpc_num,
            ireg_mpc_point0    => sreg_mpc_point0,
            ireg_mpc_point1    => sreg_mpc_point1,
            ireg_mpc_point2    => sreg_mpc_point2,
            ireg_mpc_point3    => sreg_mpc_point3,
            ireg_mpc_posoffset => sreg_mpc_posoffset,
            
            ireg_rdefect_wen   => sreg_rdefect_wen,
            ireg_rdefect_addr  => sreg_rdefect_addr,
            ireg_rdefect_wdata => sreg_rdefect_wdata,
            oreg_rdefect_rdata => sreg_rdefect_rdata,
            ireg_cdefect_wen   => sreg_cdefect_wen,
            ireg_cdefect_addr  => sreg_cdefect_addr,
            ireg_cdefect_wdata => sreg_cdefect_wdata,
            oreg_cdefect_rdata => sreg_cdefect_rdata,

            ireg_defect_wen    => sreg_defect_wen,
            ireg_defect_addr   => sreg_defect_addr,
            ireg_defect_wdata  => sreg_defect_wdata,
            oreg_defect_rdata  => sreg_defect_rdata,
            ireg_defect2_wen   => sreg_defect2_wen,
            ireg_defect2_addr  => sreg_defect2_addr,
            ireg_defect2_wdata => sreg_defect2_wdata,
            oreg_defect2_rdata => sreg_defect2_rdata,
            ireg_dgain         => sreg_dgain,
            ireg_avg_en        => sreg_avg_en,
            ireg_avg_level     => sreg_avg_level,
            oreg_avg_end       => sreg_avg_end,
            ireg_width         => sreg_width,
            ireg_height        => sreg_height,

            iReg_AccCtrl       => sreg_AccCtrl,
            oReg_AccStat       => sreg_AccStat,

            id2m_xray     => sd2m_xray,
            id2m_dark     => sd2m_dark,
            iExtTrig_Srst => sExtTrig_Srst,
            ireg_shutter  => sreg_shutter,

            itpc_rdata => stpc_rdata,
            iavg_rinfo => savg_rinfo,
            iofs_rinfo => sofs_rinfo,
            iacc_rdata => sacc_rdata,

            oavg_wen   => savg_wen,
            oavg_waddr => savg_waddr,
            oavg_winfo => savg_winfo,
            oavg_wvcnt => savg_wvcnt,
            
            oacc_wen   => sacc_wen,
            oacc_waddr => sacc_waddr,
            oacc_wdata => sacc_wdata,
            oacc_wvcnt => sacc_wvcnt,

            o_chgdet_osd_en => chgdet_osd_en,
            o_chgdet_osd_da => chgdet_osd_da,

            ireg_sync_ctrl         => sreg_sync_ctrl       ,
            oreg_sync_rcnt4        => sreg_sync_rcnt4      ,
            oreg_sync_rcnt5        => sreg_sync_rcnt5      ,
            oreg_sync_rcnt6        => sreg_sync_rcnt6      ,
            oreg_sync_rdata_AVCN4  => sreg_sync_rdata_AVCN4,
            oreg_sync_rdata_AVCN5  => sreg_sync_rdata_AVCN5,
            oreg_sync_rdata_AVCN6  => sreg_sync_rdata_AVCN6,
            oreg_sync_rdata_BGLW4  => sreg_sync_rdata_BGLW4,
            oreg_sync_rdata_BGLW5  => sreg_sync_rdata_BGLW5,
            oreg_sync_rdata_BGLW6  => sreg_sync_rdata_BGLW6,

            istate_tftd => oostate_tftd,
            ostate_avg  => oostate_avg,

            ihsync => shsync_ddr3,
            ivsync => svsync_ddr3,
            ihcnt  => shcnt_ddr3,
            ivcnt  => svcnt_ddr3,
            idata  => sdata_ddr3(16-1 downto 0), -- 2p5G

            ohsync => shsync_calib,
            ovsync => svsync_calib,
            ohcnt  => shcnt_calib,
            ovcnt  => svcnt_calib,
            odata  => sdata_calib(16-1 downto 0)
        );
end generate G_CAL_2G;

G_CAL_10G: if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") generate
begin
    U0_CALIB_TOP_PARA4 : entity work.CALIB_TOP_PARA4
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            isys_clk   => sys_clk,
            idata_clk  => sui_clk,
            idata_rstn => sbd_clk_lock(4), -- sui_rstn,

            ireg_debug_mode   => sreg_debug_mode,
            ireg_gain_cal     => sreg_gain_cal,
            ireg_offset_cal   => sreg_offset_cal,
            ireg_defect_mode  => sreg_defect_mode,
            ireg_ldefect_mode => sreg_ldefect_mode,
            ireg_defect_map   => sreg_defect_map,

            ireg_mpc_ctrl      => sreg_mpc_ctrl,
            ireg_mpc_num       => sreg_mpc_num,
            ireg_mpc_point0    => sreg_mpc_point0,
            ireg_mpc_point1    => sreg_mpc_point1,
            ireg_mpc_point2    => sreg_mpc_point2,
            ireg_mpc_point3    => sreg_mpc_point3,
            ireg_mpc_posoffset => sreg_mpc_posoffset,
            
            ireg_rdefect_wen   => sreg_rdefect_wen,
            ireg_rdefect_addr  => sreg_rdefect_addr,
            ireg_rdefect_wdata => sreg_rdefect_wdata,
            oreg_rdefect_rdata => sreg_rdefect_rdata,
            ireg_cdefect_wen   => sreg_cdefect_wen,
            ireg_cdefect_addr  => sreg_cdefect_addr,
            ireg_cdefect_wdata => sreg_cdefect_wdata,
            oreg_cdefect_rdata => sreg_cdefect_rdata,

            ireg_defect_wen    => sreg_defect_wen,
            ireg_defect_addr   => sreg_defect_addr,
            ireg_defect_wdata  => sreg_defect_wdata,
            oreg_defect_rdata  => sreg_defect_rdata,
            ireg_defect2_wen   => sreg_defect2_wen,
            ireg_defect2_addr  => sreg_defect2_addr,
            ireg_defect2_wdata => sreg_defect2_wdata,
            oreg_defect2_rdata => sreg_defect2_rdata,
            ireg_dgain         => sreg_dgain,
            ireg_avg_en        => sreg_avg_en,
            ireg_avg_level     => sreg_avg_level,
            oreg_avg_end       => sreg_avg_end,
            ireg_width         => sreg_width,
            ireg_height        => sreg_height,

            iReg_AccCtrl       => sreg_AccCtrl,
            oReg_AccStat       => sreg_AccStat,

            id2m_xray     => sd2m_xray,
            id2m_dark     => sd2m_dark,
            iExtTrig_Srst => sExtTrig_Srst,
            ireg_shutter  => sreg_shutter,

            itpc_rdata => stpc_rdata,
            iavg_rinfo => savg_rinfo,
            iofs_rinfo => sofs_rinfo,
            iacc_rdata => sacc_rdata,

            oavg_wen   => savg_wen,
            oavg_waddr => savg_waddr,
            oavg_winfo => savg_winfo,
            oavg_wvcnt => savg_wvcnt,
            
            oacc_wen   => sacc_wen,
            oacc_waddr => sacc_waddr,
            oacc_wdata => sacc_wdata,
            oacc_wvcnt => sacc_wvcnt,

            o_chgdet_osd_en => chgdet_osd_en,
            o_chgdet_osd_da => chgdet_osd_da,

            ireg_sync_ctrl         => sreg_sync_ctrl,
            oreg_sync_rcnt4        => sreg_sync_rcnt4      ,
            oreg_sync_rcnt5        => sreg_sync_rcnt5      ,
            oreg_sync_rcnt6        => sreg_sync_rcnt6      ,
            oreg_sync_rdata_AVCN4  => sreg_sync_rdata_AVCN4,
            oreg_sync_rdata_AVCN5  => sreg_sync_rdata_AVCN5,
            oreg_sync_rdata_AVCN6  => sreg_sync_rdata_AVCN6,
            oreg_sync_rdata_BGLW4  => sreg_sync_rdata_BGLW4,
            oreg_sync_rdata_BGLW5  => sreg_sync_rdata_BGLW5,
            oreg_sync_rdata_BGLW6  => sreg_sync_rdata_BGLW6,

            istate_tftd => oostate_tftd,
            ostate_avg  => oostate_avg,

            ihsync => shsync_ddr3,
            ivsync => svsync_ddr3,
            ihcnt  => shcnt_ddr3,
            ivcnt  => svcnt_ddr3,
            idata  => sdata_ddr3, -- 10G

            ohsync => shsync_calib,
            ovsync => svsync_calib,
            ohcnt  => shcnt_calib,
            ovcnt  => svcnt_calib,
            odata  => sdata_calib
        );
end generate G_CAL_10G;
                 
-- █▀█ █▀█ █▀█ █▀▀
-- █▀▀ █▀▄ █▄█ █▄▄
-- %proc
GEN_PROC_2p5: if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "2p5G") generate
begin
    U0_IMG_PROC_TOP : entity work.IMG_PROC_TOP
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            idata_clk        => sui_clk,
            idata_rstn       => sbd_clk_lock(5),

            ireg_width       => sreg_width,
            ireg_height      => sreg_height,

            ireg_iproc_mode  => sreg_iproc_mode,
            ireg_bright      => sreg_bright,
            ireg_contrast    => sreg_contrast,
            iReg_DnrCtrl     => sreg_DnrCtrl    ,
            ireg_SobelCoeff0 => sreg_SobelCoeff0,
            ireg_SobelCoeff1 => sreg_SobelCoeff1,
            ireg_SobelCoeff2 => sreg_SobelCoeff2,
            ireg_BlurOffset  => sreg_BlurOffset ,

            isys_clk         => sys_clk,
            iext_trig_in     => sext_trig_in,
            ireg_osd_ctrl    => sreg_osd_ctrl,
            oreg_trigcnt     => sreg_trigcnt,
            ireg_sync_rcnt   => sreg_sync_rcnt,

            ichgdet_osd_en   => chgdet_osd_en,
            ichgdet_osd_da   => chgdet_osd_da,

            ireg_edge_ctrl   => sreg_edge_ctrl,
            ireg_edge_value  => sreg_edge_value,
            ireg_edge_top    => sreg_edge_top,
            ireg_edge_left   => sreg_edge_left,
            ireg_edge_right  => sreg_edge_right,
            ireg_edge_bottom => sreg_edge_bottom,

            ireg_bnc_ctrl    => sreg_bnc_ctrl,
            ireg_bnc_high    => sreg_bnc_high,

            ireg_EqCtrl      => sreg_EqCtrl  ,
            ireg_EqTopVal    => sreg_EqTopVal,

            ihsync => shsync_calib,
            ivsync => svsync_calib,
            ihcnt  => shcnt_calib,
            ivcnt  => svcnt_calib,
            idata  => sdata_calib(16-1 downto 0),

            ohsync => shsync_img_proc,
            ovsync => svsync_img_proc,
            ohcnt  => shcnt_img_proc,
            ovcnt  => svcnt_img_proc,
            odata  => sdata_img_proc(16-1 downto 0)
        );
end generate GEN_PROC_2p5;

GEN_PROC_10g : if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") generate
begin
    U0_IMG_PROC_PARA4: entity work.IMG_PROC_PARA4
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            idata_clk  => sui_clk,
            idata_rstn => sbd_clk_lock(5), -- sui_rstn,

            ireg_width     => sreg_width,
            ireg_height    => sreg_height,

            ireg_iproc_mode  => sreg_iproc_mode,
            ireg_bright      => sreg_bright,
            ireg_contrast    => sreg_contrast,
            iReg_DnrCtrl     => sreg_DnrCtrl    ,
            ireg_SobelCoeff0 => sreg_SobelCoeff0,
            ireg_SobelCoeff1 => sreg_SobelCoeff1,
            ireg_SobelCoeff2 => sreg_SobelCoeff2,
            ireg_BlurOffset  => sreg_BlurOffset ,

            isys_clk       => sys_clk,
            iext_trig_in   => sext_trig_in,
            ireg_osd_ctrl  => sreg_osd_ctrl,
            oreg_trigcnt   => sreg_trigcnt,
            ireg_sync_rcnt => sreg_sync_rcnt,

            ichgdet_osd_en => chgdet_osd_en,
            ichgdet_osd_da => chgdet_osd_da,

            ireg_edge_ctrl   => sreg_edge_ctrl,
            ireg_edge_value  => sreg_edge_value,
            ireg_edge_top    => sreg_edge_top,
            ireg_edge_left   => sreg_edge_left,
            ireg_edge_right  => sreg_edge_right,
            ireg_edge_bottom => sreg_edge_bottom,

            ireg_bnc_ctrl    => sreg_bnc_ctrl,
            ireg_bnc_high    => sreg_bnc_high,

            ireg_EqCtrl      => sreg_EqCtrl  ,
            ireg_EqTopVal    => sreg_EqTopVal,

            ihsync => shsync_calib,
            ivsync => svsync_calib,
            ihcnt  => shcnt_calib,
            ivcnt  => svcnt_calib,
            idata  => sdata_calib,

            ohsync => shsync_img_proc,
            ovsync => svsync_img_proc,
            ohcnt  => shcnt_img_proc,
            ovcnt  => svcnt_img_proc,
            odata  => sdata_img_proc
        );
end generate GEN_PROC_10g;
-- █▀█ █░█ ▀█▀
-- █▄█ █▄█ ░█░
-- %out
GEN_IMGOUT_10G: if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "10G ") generate
begin

    process(sui_clk, sbd_clk_lock(6))
    begin
        if(sbd_clk_lock(6) = '0') then
            sfb_frame        <= '0';
            sfb_dv           <= '0';
            sfb_data         <= (others => '0');
            sfb_width        <= (others => '0');
        elsif(sui_clk'event and sui_clk = '1') then
--          if(sreg_out_en = '1') then
--              sfb_frame        <= svsync_ddr3;
--              sfb_dv           <= shsync_ddr3;
--              sfb_data         <= sdata_ddr3( 8-1 downto  0) & sdata_ddr3(16-1 downto  8) &
--                                  sdata_ddr3(24-1 downto 16) & sdata_ddr3(32-1 downto 24) &
--                                  sdata_ddr3(40-1 downto 32) & sdata_ddr3(48-1 downto 40) &
--                                  sdata_ddr3(56-1 downto 48) & sdata_ddr3(64-1 downto 56) ;
--              sfb_width        <= "111";
--          else
--          if(sreg_out_en = '1') then
--              sfb_frame        <= svsync_calib;
--              sfb_dv           <= shsync_calib;
--              sfb_data         <= sdata_calib( 8-1 downto  0) & sdata_calib(16-1 downto  8) &
--                                  sdata_calib(24-1 downto 16) & sdata_calib(32-1 downto 24) &
--                                  sdata_calib(40-1 downto 32) & sdata_calib(48-1 downto 40) &
--                                  sdata_calib(56-1 downto 48) & sdata_calib(64-1 downto 56) ;
--              sfb_width        <= "111";
            if(sreg_out_en = '1') then
                sfb_frame        <= svsync_img_proc;
                sfb_dv           <= shsync_img_proc;
                sfb_data         <= sdata_img_proc( 8-1 downto  0) & sdata_img_proc(16-1 downto  8) &
                                    sdata_img_proc(24-1 downto 16) & sdata_img_proc(32-1 downto 24) &
                                    sdata_img_proc(40-1 downto 32) & sdata_img_proc(48-1 downto 40) &
                                    sdata_img_proc(56-1 downto 48) & sdata_img_proc(64-1 downto 56) ;
                sfb_width        <= "111";
            else
                sfb_frame        <= '0';
                sfb_dv           <= '0';
                sfb_data         <= (others => '0');
                sfb_width        <= (others => '0');
            end if;
        end if;
    end process;

end generate GEN_IMGOUT_10G;
 
GEN_IMGOUT_2p5: if(GEV_SPEED_BY_MODEL(GNR_MODEL) = "2p5G") generate
begin

    U0_IMG_OUT_TOP : entity work.IMG_OUT_TOP
        port map (
            idata_clk  => sui_clk,
            idata_rstn => sbd_clk_lock(6), -- sui_rstn,
            igev_clk   => sui_clk,
            igev_rstn  => sbd_clk_lock(7), -- sui_rstn,

            ireg_out_en   => sreg_out_en,
            ireg_out_mode => sreg_out_mode,
            ireg_width    => sreg_width,
            ireg_height   => sreg_height,

            ihsync => shsync_img_proc,
            ivsync => svsync_img_proc,
            ihcnt  => shcnt_img_proc,
            ivcnt  => svcnt_img_proc,
            idata  => sdata_img_proc(16-1 downto 0),

            ofb_frame => sfb_frame,
            ofb_dv    => sfb_dv,
            ofb_data  => sfb_data,
            ofb_width => sfb_width
        );
end generate GEN_IMGOUT_2p5;
         
-- █ ▀█ █▀▀
-- █ █▄ █▄▄
    U0_I2C_CTRL : entity work.I2C_CTRL
        generic map (
            slave_num    => 4,
            slave_addr0 => "010",
            slave_addr1 => "011",
            slave_addr2 => "100",
            slave_addr3 => "101"
        )
        port map (
            iui_clk  => sui_clk,
            iui_rstn => sbd_clk_lock(8), -- sui_rstn,

            ireg_i2c_mode   => sreg_i2c_mode,
            ireg_i2c_wen    => sreg_i2c_wen,
            ireg_i2c_wsize  => sreg_i2c_wsize,
            ireg_i2c_wdata  => sreg_i2c_wdata,
            ireg_i2c_ren    => sreg_i2c_ren,
            ireg_i2c_rsize  => sreg_i2c_rsize,
            oreg_i2c_rdata0 => sreg_i2c_rdata0,
            oreg_i2c_rdata1 => sreg_i2c_rdata1,
            oreg_i2c_rdata2 => sreg_i2c_rdata2,
            oreg_i2c_rdata3 => sreg_i2c_rdata3,
            oreg_i2c_done    => sreg_i2c_done,

            oi2c_scl  => TEMP_SCL,
            ioi2c_sda => TEMP_SDA
        );

    U0_XADC_CTRL : entity work.XADC_CTRL
        port map (
            iui_clk  => sui_clk,
            iui_rstn => sbd_clk_lock(9), -- sui_rstn,

            ireg_temp_en     => sreg_temp_en,
            oreg_device_temp => sreg_device_temp
        );

    U0_LED_CTRL : entity work.LED_CTRL
        port map (
            iui_clk  => sui_clk,
            iui_rstn => sbd_clk_lock(10), -- sui_rstn,

            ireg_align_done => sreg_align_done,
            ireg_grab_en    => sreg_grab_en,
            ireg_out_en     => sreg_out_en,
            ireg_shutter    => sreg_shutter,
            iext_trig       => sext_trig_out,
            ireg_led_ctrl   => sreg_led_ctrl,

            ostate_led => STATUS_LED
        );

  ----------------------------------------------------------
  -- ROIC Port Buffer
  ----------------------------------------------------------

    diff_proc1_dclk : for i in 0 to ROIC_DCLK_NUM(GNR_MODEL)-1 generate

        U0_IBUFDS : IBUFDS
            generic map (
                diff_term  => TRUE,
                iostandard => "LVDS_25"
            )
            port map (
                I  => ROIC_DCLK_P(i),
                IB => ROIC_DCLK_N(i),
                O  => sroic_dclk(i)
            );

    end generate diff_proc1_dclk;
    
    diff_proc1_fclk : for i in 0 to ROIC_FCLK_NUM(GNR_MODEL)-1 generate
        U1_IBUFDS : IBUFDS
            generic map (
                diff_term  => TRUE,
                iostandard => "LVDS_25"
            )
            port map (
                I  => ROIC_FCLK_P(i),
                IB => ROIC_FCLK_N(i),
                O  => sroic_fclk(i)
            );
    end generate diff_proc1_fclk;

diff_proc1 : for i in 0 to ROIC_NUM(GNR_MODEL)-1 generate
        U2_IBUFDS : IBUFDS
            generic map (
                diff_term  => TRUE,
                iostandard => "LVDS_25"
            )
            port map (
                I  => ROIC_DOUT_P(i),
                IB => ROIC_DOUT_N(i),
                O  => sroic_data(i)
            );

    end generate diff_proc1;

    
    roic_sig_gen : for i in 0 to ROIC_DUAL_BY_MODEL(GNR_MODEL) - 1 generate
--        F_ROIC_MCLK(i)     <= sroic_mclk_div;
--        F_ROIC_SCLK(i)     <= sroic_sck_div;
        F_ROIC_SYNC(i)     <= sroic_sync_div;
        F_ROIC_TP_SEL(i) <= sroic_tp_sel_div;
        F_ROIC_CS(i)     <= sroic_cs_div;
        F_ROIC_SDI(i)     <= sroic_sdo_div;
    end generate roic_sig_gen;

  ----------------------------------------------------------
  -- Allocate Signal for Each MODEL
  ----------------------------------------------------------
    roic_sig_gen_ti_mclk : for i in 0 to ROIC_MCLK_NUM(GNR_MODEL) -1 generate
        F_ROIC_MCLK(i)     <= sroic_mclk_div;
    end generate roic_sig_gen_ti_mclk; 
    roic_sig_gen_ti_sclk : for i in 0 to ROIC_SCLK_NUM(GNR_MODEL) -1 generate
        F_ROIC_SCLK(i)     <= sroic_sck_div;
    end generate roic_sig_gen_ti_sclk; 
  ----------------------------------------------------------
  -- Gate Port Mapping
  ----------------------------------------------------------

    ver1_gate_sig_mapping : if(GATE_BY_MODEL(GNR_MODEL) = "NT39530 ") generate

        signal GATE_CH_MODE    : std_logic_vector(1 downto 0);
        signal GATE_SHIFT_DIR  : std_logic;

    begin

        GATE_SHIFT_CLK      <= sgate_cpv;        -- CPV
        GATE_START_PULSE1 <= sgate_dio1;    -- STV1
        GATE_START_PULSE2 <= (others => '0');
        GATE_OUT_EN1      <= not sgate_oe1; -- OE1
        GATE_OUT_EN2      <= not sgate_oe2; -- OE2
        GATE_ALL_OUT      <= sgate_xon;        -- XAO

        GATE_CH_MODE   <= "00"; -- MODE[1:0](257CH)
        GATE_SHIFT_DIR <= '1';    -- LR(8->263)

        GATE_VGH_RST <= sgate_flk; -- FLK

  -- Unknown
        GATE_CONFIG(0) <= '0'; -- GATE_CH_MODE(1);
        -- GATE_CONFIG(0) <= GATE_CH_MODE(1);
        -- GATE_CONFIG(1) <= GATE_CH_MODE(0);
        -- GATE_CONFIG(2) <= GATE_SHIFT_DIR;
        -- GATE_CONFIG(3) <= GATE_SHIFT_DIR when ROIC_DUAL_BY_MODEL(GNR_MODEL) = 1 else not GATE_SHIFT_DIR;
    end generate ver1_gate_sig_mapping;

    ver5_gate_sig_mapping : if(GATE_BY_MODEL(GNR_MODEL) = "NT39565 ") generate

        signal GATE_CHIP_SEL  : std_logic_vector(1 downto 0);
        signal GATE_CH_MODE    : std_logic_vector(1 downto 0);
        signal GATE_SHIFT_DIR  : std_logic_vector(1 downto 0);
        signal GATE_OE_PRESCAN    : std_logic;
        signal GATE_STV_MODE  : std_logic;
        signal GATE_OUT_MODE  : std_logic;

    begin

        GATE_SHIFT_CLK      <= sgate_cpv;        -- CPV
        GATE_START_PULSE1 <= sgate_dio1;    -- STV1
        GATE_START_PULSE2 <= (others => '0');
        GATE_OUT_EN1      <= not sgate_oe1; -- OE1
        GATE_OUT_EN2      <= not sgate_oe2; -- OE2
        GATE_ALL_OUT      <= sgate_xon;        -- XAO

        GATE_CHIP_SEL    <= "10" when sgate_ind = '0' else "01"; -- CHIP_SEL[1:0]
        GATE_CH_MODE    <= "10";                                -- MODE (512CH)
        GATE_SHIFT_DIR    <= "01";                                -- [1]:UD [0]:LR(1->512)
        GATE_OE_PRESCAN <= '0';                                    -- OEPSN (No OE Mask)
        GATE_STV_MODE    <= '0';                                    -- STV_MODE(Normal STV)
        GATE_OUT_MODE    <= '0';                                    -- SEL(Two Pulse Delay[?])

        GATE_VGH_RST <= sgate_flk; -- FLK

        GATE_CONFIG(0) <= GATE_STV_MODE;
        GATE_CONFIG(1) <= GATE_OUT_MODE;
        GATE_CONFIG(2) <= GATE_OE_PRESCAN;
        GATE_CONFIG(3) <= GATE_CHIP_SEL(1);
        GATE_CONFIG(4) <= GATE_CHIP_SEL(0);
        GATE_CONFIG(5) <= GATE_CH_MODE(1);
        GATE_CONFIG(6) <= GATE_CH_MODE(0);
        GATE_CONFIG(7) <= GATE_SHIFT_DIR(1);
        GATE_CONFIG(8) <= GATE_SHIFT_DIR(0);
        GATE_CONFIG(9) <= GATE_SHIFT_DIR(0) when ROIC_DUAL_BY_MODEL(GNR_MODEL) = 1 else not GATE_SHIFT_DIR(0);
    end generate ver5_gate_sig_mapping;    

    ver6_gate_sig_mapping : if(GATE_BY_MODEL(GNR_MODEL) = "NT39565D") generate

        signal F_NBIAS_CTRL  : std_logic;
        signal VGH_EN  : std_logic;
        signal VGL_EN  : std_logic;
        signal N_BIAS_AEN  : std_logic;
        signal PGATE_ON  : std_logic;
        
    begin

        GATE_SHIFT_CLK      <= sgate_cpv;        -- CPV
        GATE_START_PULSE1 <= sgate_dio1;    -- STV1
        GATE_START_PULSE2 <= (others => '0');
        GATE_OUT_EN1      <= not sgate_oe1; -- OE1
        GATE_OUT_EN2      <= not sgate_oe2; -- OE2
        GATE_ALL_OUT      <= sgate_xon;        -- XAO

        GATE_VGH_RST <= sgate_flk; -- FLK

        F_NBIAS_CTRL <= '0'; -- D25  F_NBIAS_CTRL -- gboard u2.6/7 in1/2 : normal low                    
        VGH_EN       <= '1'; -- F23  VGH_EN -- gate vgh ldo : 15v    : normal high                       
        VGL_EN       <= '1'; -- G24  VGL_EN -- gate vgl ldo : -15v   : normal high                       
        N_BIAS_AEN   <= '1'; -- F24  N_BIAS_AEN -- NC resistor to vbias negative ldo : -5v : normal high 
        PGATE_ON     <= '1'; -- J23  PGATE_ON -- pulldown gate & vbias & buff ldo : 3.3v   : normal high 
        
        GATE_CONFIG(0) <= F_NBIAS_CTRL;
--        GATE_CONFIG(1) <= VGH_EN      ;
--        GATE_CONFIG(2) <= VGL_EN      ;
--        GATE_CONFIG(3) <= N_BIAS_AEN  ;
--        GATE_CONFIG(4) <= PGATE_ON    ;

   end generate ver6_gate_sig_mapping;

    ver2_gate_sig_mapping : if(GATE_BY_MODEL(GNR_MODEL) = "NT61303 ") generate

        signal GATE_CHIP_SEL  : std_logic_vector(1 downto 0);
        signal GATE_CH_MODE    : std_logic;
        signal GATE_SHIFT_DIR  : std_logic_vector(1 downto 0);
        signal GATE_OE_PRESCAN    : std_logic;
        signal GATE_STV_MODE  : std_logic;
        signal GATE_OUT_MODE  : std_logic;

    begin

        GATE_SHIFT_CLK      <= sgate_cpv;        -- CPV
        GATE_START_PULSE1 <= sgate_dio1;    -- STV1
        GATE_START_PULSE2 <= (others => '0');
        GATE_OUT_EN1      <= not sgate_oe1; -- OE1
        GATE_OUT_EN2      <= not sgate_oe2; -- OE2
        GATE_ALL_OUT      <= sgate_xon;        -- XAO

        GATE_CHIP_SEL    <= "10" when sgate_ind = '0' else "01"; -- CHIP_SEL[1:0]
        GATE_CH_MODE    <= '1';                                    -- MODE(385CH)
        GATE_SHIFT_DIR    <= "01";                                -- [1]:UD [0]:LR(1->385)
        GATE_OE_PRESCAN <= '0';                                    -- OEPSN(No OE Mask)
        GATE_STV_MODE    <= '0';                                    -- STV_MODE(Normal STV)
        GATE_OUT_MODE    <= '0';                                    -- SEL(Two Pulse Delay[?])

        GATE_VGH_RST <= sgate_flk; -- FLK

        GATE_CONFIG(0) <= GATE_STV_MODE;
        GATE_CONFIG(1) <= GATE_OUT_MODE;
        GATE_CONFIG(2) <= GATE_OE_PRESCAN;
        GATE_CONFIG(3) <= GATE_CHIP_SEL(1);
        GATE_CONFIG(4) <= GATE_SHIFT_DIR(0);
        GATE_CONFIG(5) <= GATE_SHIFT_DIR(1);
        GATE_CONFIG(6) <= GATE_CH_MODE;
        GATE_CONFIG(7) <= GATE_CHIP_SEL(0);
        GATE_CONFIG(8) <= GATE_SHIFT_DIR(0) when ROIC_DUAL_BY_MODEL(GNR_MODEL) = 1 else not GATE_SHIFT_DIR(0);

    end generate ver2_gate_sig_mapping;

-- ..%%%%...........%%%%%...%%...%%..%%%%%%....%%....%%..%%...%%%%....%%%%..
-- .%%..............%%..%%..%%%.%%%.....%%....%%.....%%..%%..%%..%%..%%..%%.
-- .%%.%%%..........%%%%%...%%.%.%%....%%....%%%%%...%%..%%...%%%%....%%%%..
-- .%%..%%..........%%..%%..%%...%%...%%.....%%..%%..%%..%%..%%..%%....%%...
-- ..%%%%...%%%%%%..%%..%%..%%...%%..%%.......%%%%....%%%%....%%%%....%%....
-- !rm76....................................................................
ver3_gate_sig_mapping : if(GATE_BY_MODEL(GNR_MODEL) = "RM76U89 ") generate
    -- signal GATE_CH_MODE    : std_logic_vector(2 downto 0);
    signal GATE_SHIFT_DIR  : std_logic_vector(1 downto 0);
    signal GateL0R1 : std_logic;
begin
    GateL0R1 <= '0' when GNR_MODEL = "EXT1024R"    else -- jyp 241010
                '1' when GNR_MODEL = "EXT1616R"    else
                '0' when GNR_MODEL = "EXT2430R"    else
                '0' when GNR_MODEL = "EXT2430RI"    else
                '1' when GNR_MODEL = "EXT2832R"    else
                '0' when GNR_MODEL = "EXT2832R_2"  else
--              '1' when GNR_MODEL = "EXT4343R"    else
                '1' when GNR_MODEL = "EXT4343R_1"  else
--              '1' when GNR_MODEL = "EXT4343R_2"  else
                '0' when GNR_MODEL = "EXT4343R_2"  else
                '0' when GNR_MODEL = "EXT4343R_4"  else
--              '1' when GNR_MODEL = "EXT4343R_3"  else
--              '1' when GNR_MODEL = "EXT4343RC"   else
                '1' when GNR_MODEL = "EXT4343RC_1" else
                '0' when GNR_MODEL = "EXT4343RC_2" else
--              '1' when GNR_MODEL = "EXT4343RC_3" else
                '0' when GNR_MODEL = "EXT4343RI_2"  else
                '0' when GNR_MODEL = "EXT4343RI_4"  else
                '1' when GNR_MODEL = "EXT4343RCI_1" else
--                '1' when GNR_MODEL = "EXT4343RCI_2" else --# gate does not work.
                '0' when GNR_MODEL = "EXT4343RCI_2" else   --# LR 1-> 0 #241023 
                '0' when GNR_MODEL = "EXT4343RD"	else
                '0' when GNR_MODEL = "EXT3643R" 	else
                '1'; 

    GATE_SHIFT_CLK1L  <= sgate_cpv when GateL0R1='0' else '0'; -- CPV 210127
    GATE_SHIFT_CLK2L  <= sgate_cpv when GateL0R1='0' else '0'; -- CPV
    GATE_SHIFT_CLK1R  <= sgate_cpv when GateL0R1='1' else '0'; -- CPV
    GATE_SHIFT_CLK2R  <= sgate_cpv when GateL0R1='1' else '0'; -- CPV
    GATE_START_PULSE1 <= sgate_dio1;                           -- DIO1
    GATE_START_PULSE2 <= sgate_dio2;                           -- DIO2
    GATE_OUT_EN1L     <= sgate_oe1 when GateL0R1='0' else '0'; -- OE1
    GATE_OUT_EN2L     <= sgate_oe2 when GateL0R1='0' else '0'; -- OE2
    GATE_OUT_EN1R     <= sgate_oe1 when GateL0R1='1' else '0'; -- OE1
    GATE_OUT_EN2R     <= sgate_oe2 when GateL0R1='1' else '0'; -- OE2
    GATE_ALL_OUT      <= sgate_xon when GateL0R1='0' else '1'; -- XON '0': All gate, '1':normal
    GATE_ALL_OUT_R    <= sgate_xon when GateL0R1='1' else '1'; -- XON
    GATE_SHIFT_DIR    <= "00" when GNR_MODEL = "EXT1024R"    else -- [1]:UD, [0]:FB -- jyp 241010
                         "00" when GNR_MODEL = "EXT1616R"    else  -- [1]:UD, [0]:FB 
                         "11" when GNR_MODEL = "EXT2430RI"   else -- [1]:UD, [0]:FB 
                         "11" when GNR_MODEL = "EXT2430R"    else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT2832R"    else -- [1]:UD, [0]:FB 
                         "11" when GNR_MODEL = "EXT2832R_2"  else -- [1]:UD, [0]:FB 
--                       "00" when GNR_MODEL = "EXT4343R"    else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT4343R_1"  else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT4343R_2"  else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT4343R_4"  else -- [1]:UD, [0]:FB 
--                       "00" when GNR_MODEL = "EXT4343R_3"  else -- [1]:UD, [0]:FB 
--                       "00" when GNR_MODEL = "EXT4343RC"   else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT4343RC_1" else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT4343RC_2" else -- [1]:UD, [0]:FB 
--                       "00" when GNR_MODEL = "EXT4343RC_3" else -- [1]:UD, [0]:FB 
                         "00" when GNR_MODEL = "EXT4343RI_2"  else -- [1]:UD, [0]:FB  
                         "00" when GNR_MODEL = "EXT4343RI_4"  else -- [1]:UD, [0]:FB  
                         "00" when GNR_MODEL = "EXT4343RCI_1" else -- [1]:UD, [0]:FB
                         "00" when GNR_MODEL = "EXT4343RCI_2" else -- [1]:UD, [0]:FB
                         "00" when GNR_MODEL = "EXT4343RD"	 else  -- [1]:UD, [0]:FB
                         "00" when GNR_MODEL = "EXT3643R"	 else  -- [1]:UD, [0]:FB
                         "00";          
    GATE_CONFIG(0) <= sgate_ind;          -- '0':1,2,3,4 // '1':1,3,5,7
    GATE_CONFIG(1) <= GATE_SHIFT_DIR(0);  -- '0':Right input // '1':Left input
    GATE_CONFIG(2) <= GATE_SHIFT_DIR(1);  -- '0': 1 to 600 // '1': 600 to 1

    GATE_VGH_RST      <= not sgate_flk when GNR_MODEL = "EXT1024R"    else -- FLK -- jyp 241010
                         not sgate_flk when GNR_MODEL = "EXT1616R"    else -- FLK 
                         not sgate_flk when GNR_MODEL = "EXT2430RI"   else -- FLK 
                         not sgate_flk when GNR_MODEL = "EXT2430R"    else -- FLK 
                         not sgate_flk when GNR_MODEL = "EXT2832R"    else -- FLK 
                         not sgate_flk when GNR_MODEL = "EXT2832R_2"  else -- FLK 
--                           sgate_flk when GNR_MODEL = "EXT4343R"    else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343R_1"  else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343R_2"  else -- FLK 
--                           sgate_flk when GNR_MODEL = "EXT4343R_3"  else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343R_4"  else -- FLK 
--                           sgate_flk when GNR_MODEL = "EXT4343RC"   else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343RC_1" else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343RC_2" else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343RC_4" else -- FLK 
--                           sgate_flk when GNR_MODEL = "EXT4343RC_3" else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343RI_2"  else -- FLK  
                             sgate_flk when GNR_MODEL = "EXT4343RI_4"  else -- FLK  
                             sgate_flk when GNR_MODEL = "EXT4343RCI_1" else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343RCI_2" else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT4343RD"    else -- FLK 
                             sgate_flk when GNR_MODEL = "EXT3643R"     else -- FLK 
                         not sgate_flk; 

end generate ver3_gate_sig_mapping;
-- -------------------------------------------------------------------------

    ver4_gate_sig_mapping : if(GATE_BY_MODEL(GNR_MODEL) = "HX8698  ") generate

        signal GATE_CHIP_SEL   : std_logic_vector(1 downto 0);
        signal GATE_CH_MODE    : std_logic;
        signal GATE_SHIFT_DIR  : std_logic;
        signal GATE_OE_SEL     : std_logic;
        signal GATE_OE_PRESCAN : std_logic;

    begin

        GATE_SHIFT_CLK    <= sgate_cpv;          -- CPV
        GATE_START_PULSE1 <= sgate_dio1;      -- STV1
--      GATE_START_PULSE2 <= (others => '0'); -- STV2 -- 4343ti
        GATE_OUT_EN1      <= not sgate_oe1;   -- OE1
        GATE_OUT_EN2      <= not sgate_oe2;   -- OE2
        GATE_ALL_OUT      <= sgate_xon;          -- XAO

        GATE_CHIP_SEL   <= '0' & sgate_ind; -- [1]:IND_MODE, [0]:IND
        GATE_CH_MODE    <= '0';                -- MODE (512CH)
        GATE_SHIFT_DIR  <= '1';                -- LR (1->512)
        GATE_OE_SEL     <= '0';                -- OESEL (OE Active Low)
        GATE_OE_PRESCAN <= '0';                -- OEPSN (No OE Mask)

        GATE_VGH_RST   <= sgate_flk; -- FLK

        GATE_CONFIG(0) <= GATE_CHIP_SEL(1);
        GATE_CONFIG(1) <= GATE_CHIP_SEL(0);
        GATE_CONFIG(2) <= GATE_CH_MODE;
        GATE_CONFIG(3) <= GATE_SHIFT_DIR;
        GATE_CONFIG(4) <= GATE_OE_SEL;
        GATE_CONFIG(5) <= GATE_OE_PRESCAN;
--        GATE_CONFIG(6) <= GATE_SHIFT_DIR when ROIC_DUAL_BY_MODEL(GNR_MODEL) = 1 else not GATE_SHIFT_DIR;  -- 4343ti

--        ##### unused output port #####
--      GATE_ALL_OUT_R       <= 'Z';
--      GATE_OUT_EN1L        <= 'Z';
--      GATE_OUT_EN1R        <= 'Z';
--      GATE_OUT_EN2L        <= 'Z';
--      GATE_OUT_EN2R        <= 'Z';
--      GATE_SHIFT_CLK1L     <= 'Z';
--      GATE_SHIFT_CLK1R     <= 'Z';
--      GATE_SHIFT_CLK2L     <= 'Z';
--      GATE_SHIFT_CLK2R     <= 'Z';
--      GATE_START_PULSE2(0) <= 'Z';
--      PWR_EN(5)            <= 'Z';
        
    end generate ver4_gate_sig_mapping;

  ----------------------------------------------------------
  -- External Trigger
  ----------------------------------------------------------
    process (sys_clk, sys_rst)
    begin
        if(sys_rst = '1') then
            sext_trig_cnt <= (others => '0');
--            sext_trig_tmp <= '0';
        elsif (sys_clk'event and sys_clk = '1') then
            -- ### reg_ext_trig_high upper 16bits were used as trigger number 
            -- ### when it changed, internal trigger restart
             trig_num0 <= sreg_ext_trig_high(32-1 downto 16);
             trig_num1 <= trig_num0;
            if trig_num1 /= trig_num0 then
                trig_num_cnt <= (others => '0');
            elsif (trig_num_cnt < trig_num1) then
                    if(sext_trig_cnt >= sreg_ext_trig_period) then
                        sext_trig_cnt <= (others => '0');
                        trig_num_cnt <= trig_num_cnt + '1';
                    else
                        sext_trig_cnt <= sext_trig_cnt + '1';
                     end if;
             end if;             
             
            if(0 < sext_trig_cnt and sext_trig_cnt <= sreg_ext_trig_high(15 downto 0)) then -- mbh 210506
                sext_trig_tmp <= '1';
            else
                sext_trig_tmp <= '0';
            end if;
             
       --
        end if;
    end process;
    
--    F_GPIO3 <= sext_trig_tmp; -- TP out
--    F_GPIO4 <= '0';

    sext_trig_in  <=
                    --### API Input ###
                    '1'               when sreg_api_ext_trig(0) = '1' else 
                    --### REG Input ###
                    not sext_trig_tmp when 0 < trig_num0 and sreg_ext_trig_active(0) = '1' else
                        sext_trig_tmp when 0 < trig_num0 and sreg_ext_trig_active(0) = '0' else  
                    --### Ext Input ###
                        EXT_IN        when sreg_ext_trig_active(0) = '1' else 
                    not EXT_IN;
    sEXT_OUT <= sext_trig_out when sreg_ext_trig_active(1) = '1' else not sext_trig_out;
    EXT_OUT  <= sEXT_OUT;

-------------------
-- Test Point 
-------------------

 TP_EXT: if(GNR_MODEL = "EXT810R" or 
            GNR_MODEL = "EXT1024R" or -- jyp 241010 
            GNR_MODEL = "EXT1616R" or 
            GNR_MODEL = "EXT4343RC_1" or --# 241213 gpio 
            GNR_MODEL = "EXT2832R" or 
            GNR_MODEL = "EXT2430RI" or 
            GNR_MODEL = "EXT2430RD") generate
    signal gpio : std_logic_vector(1 to 4);
    type type_4x16b is array (1 to 4) of std_logic_vector(16-1 downto 0); 
    signal sreg_testpoint : type_4x16b;
    signal tstate_tft_vec : std_logic_vector(4-1 downto 0);
begin
--    tstate_tft_vec <=  conv_std_logic_vector(oostate_tft,4);
    sreg_testpoint <= (sreg_testpoint1, sreg_testpoint2, sreg_testpoint3, sreg_testpoint4);
    gen4 : for i in 1 to 4 generate
        gpio(i) <= 
--                 spwr_en(9)     when sreg_testpoint(i) = x"0001" else 
                   sroic_sync_div when sreg_testpoint(i) = x"0001" else 
                   sgate_cpv      when sreg_testpoint(i) = x"0002" else 
                   sgate_dio1(0)  when sreg_testpoint(i) = x"0003" else 
                   sgate_oe1      when sreg_testpoint(i) = x"0004" else 
                   sgate_xon      when sreg_testpoint(i) = x"0005" else 
                   sgate_flk      when sreg_testpoint(i) = x"0006" else 

                   '1' when sreg_testpoint(i) = x"1111" else 
                   '0' when sreg_testpoint(i) = x"0000" else 
                   
                   '1' when sreg_testpoint(i) = x"0010" and  oostate_tft=s_IDLE       else 
                   '1' when sreg_testpoint(i) = x"0011" and  oostate_tft=s_TRST       else 
                   '1' when sreg_testpoint(i) = x"0012" and  oostate_tft=s_SRST       else 
                   '1' when sreg_testpoint(i) = x"0013" and  oostate_tft=s_EWT        else 
                   '1' when sreg_testpoint(i) = x"0014" and  oostate_tft=s_SCAN       else 
                   '1' when sreg_testpoint(i) = x"0015" and  oostate_tft=s_FINISH     else 
                   '1' when sreg_testpoint(i) = x"0016" and  oostate_tft=s_GRST       else 
                   '1' when sreg_testpoint(i) = x"0017" and  oostate_tft=s_RstFINISH  else 
                   '1' when sreg_testpoint(i) = x"0018" and  oostate_tft=s_ScanFrWait else 
                   '1' when sreg_testpoint(i) = x"0019" and  oostate_tft=s_RstFrWait  else 

                   '1' when sreg_testpoint(i) = x"0020" and  oostate_roic=s_IDLE      else 
                   '1' when sreg_testpoint(i) = x"0021" and  oostate_roic=s_OFFSET    else 
                   '1' when sreg_testpoint(i) = x"0022" and  oostate_roic=s_DUMMY     else 
                   '1' when sreg_testpoint(i) = x"0023" and  oostate_roic=s_INTRST    else 
                   '1' when sreg_testpoint(i) = x"0024" and  oostate_roic=s_CDS1      else 
                   '1' when sreg_testpoint(i) = x"0025" and  oostate_roic=s_GATE_OPEN else 
                   '1' when sreg_testpoint(i) = x"0026" and  oostate_roic=s_CDS2      else 
                   '1' when sreg_testpoint(i) = x"0027" and  oostate_roic=s_LDEAD     else 
                   '1' when sreg_testpoint(i) = x"0028" and  oostate_roic=s_FWAIT     else 

                   '1' when sreg_testpoint(i) = x"0030" and  oostate_gate=s_IDLE      else 
                   '1' when sreg_testpoint(i) = x"0031" and  oostate_gate=s_DUMMY     else 
                   '1' when sreg_testpoint(i) = x"0032" and  oostate_gate=s_READY     else 
                   '1' when sreg_testpoint(i) = x"0033" and  oostate_gate=s_DIO_CPV   else 
                   '1' when sreg_testpoint(i) = x"0034" and  oostate_gate=s_CPV       else 
                   '1' when sreg_testpoint(i) = x"0035" and  oostate_gate=s_XON       else 
                   '1' when sreg_testpoint(i) = x"0036" and  oostate_gate=s_OE        else 
                   '1' when sreg_testpoint(i) = x"0037" and  oostate_gate=s_XON_FLK   else 
                   '1' when sreg_testpoint(i) = x"0038" and  oostate_gate=s_FLK       else 
                   '1' when sreg_testpoint(i) = x"0039" and  oostate_gate=s_CHECK     else 
                   '1' when sreg_testpoint(i) = x"003A" and  oostate_gate=s_OE_READY  else 
                   '1' when sreg_testpoint(i) = x"003B" and  oostate_gate=s_LWAIT     else 
                   '1' when sreg_testpoint(i) = x"003C" and  oostate_gate=s_FWAIT     else 
                   '1' when sreg_testpoint(i) = x"003D" and  oostate_gate=s_GRST_G    else 
                   '1' when sreg_testpoint(i) = x"003E" and  oostate_gate=s_GRST_GEnd else 
                   '0';
    end generate gen4;

    F_GPIO1 <= gpio(1); --# 0440
    F_GPIO2 <= gpio(2); --# 0444
    F_GPIO3 <= gpio(3); --# 0448
    F_GPIO4 <= gpio(4); --# 044C
end generate TP_EXT;
    
    
--    F_GPIO1 <= sroic_mclk_div;
--    F_GPIO2 <= sys_clk;
--    F_GPIO3 <= axi_aclk; -- sys_rst;
--    F_GPIO4 <= scalib_done;

                    


    
--    sim : if(SIMULATION = "ON") generate

--    component SIM_CPU
--        port (
--            axi_clk     : out std_logic;
--            axi_rst     : out std_logic;
--            sys_rst     : out std_logic;

--            axi_awid    : in  std_logic_vector(3 downto 0);
--            axi_awaddr  : in  std_logic_vector(31 downto 0);
--            axi_awlen   : in  std_logic_vector(7 downto 0);
--            axi_awsize  : in  std_logic_vector(2 downto 0);
--            axi_awburst : in  std_logic_vector(1 downto 0);
--            axi_awlock  : in  std_logic_vector(0 downto 0);
--            axi_awvalid : in  std_logic;
--            axi_awready : out std_logic;

--            axi_wdata   : in  std_logic_vector(511 downto 0);
--            axi_wstrb   : in  std_logic_vector(63 downto 0);
--            axi_wlast   : in  std_logic;
--            axi_wvalid  : in  std_logic;
--            axi_wready  : out std_logic;

--            axi_bid     : out std_logic_vector(3 downto 0);
--            axi_bresp   : out std_logic_vector(1 downto 0);
--            axi_bvalid  : out std_logic;
--            axi_bready  : in  std_logic;

--            axi_arid    : in  std_logic_vector(3 downto 0);
--            axi_araddr  : in  std_logic_vector(31 downto 0);
--            axi_arlen   : in  std_logic_vector(7 downto 0);
--            axi_arsize  : in  std_logic_vector(2 downto 0);
--            axi_arburst : in  std_logic_vector(1 downto 0);
--            axi_arlock  : in  std_logic_vector(0 downto 0);
--            axi_arvalid : in  std_logic;
--            axi_arready : out std_logic;

--            axi_rid     : out std_logic_vector(3 downto 0);
--            axi_rdata   : out std_logic_vector(511 downto 0);
--            axi_rresp   : out std_logic_vector(1 downto 0);
--            axi_rlast   : out std_logic;
--            axi_rvalid  : out std_logic;
--            axi_rready  : in  std_logic;

--            bd_mclk     : out std_logic;
--            bd_clk_lock : out std_logic;
--            bd_dclk     : out std_logic
--        );
--    end component;

--    signal swait_cnt  : std_logic_vector(15 downto 0);

--begin

--    U0_SIM_CPU : SIM_CPU
--        port map (
--            axi_clk => axi_clk,
--            axi_rst => axi_rst,
--            sys_rst => sys_rst,

--            axi_awid    => axi2_awid,
--            axi_awaddr  => axi2_awaddr,
--            axi_awlen   => axi2_awlen,
--            axi_awsize  => axi2_awsize,
--            axi_awburst => axi2_awburst,
--            axi_awlock  => axi2_awlock,
--            axi_awvalid => axi2_awvalid,
--            axi_awready => axi2_awready,

--            axi_wdata  => axi2_wdata,
--            axi_wstrb  => axi2_wstrb,
--            axi_wlast  => axi2_wlast,
--            axi_wvalid => axi2_wvalid,
--            axi_wready => axi2_wready,

--            axi_bid    => axi2_bid,
--            axi_bresp  => axi2_bresp,
--            axi_bvalid => axi2_bvalid,
--            axi_bready => axi2_bready,

--            axi_arid    => axi2_arid,
--            axi_araddr  => axi2_araddr,
--            axi_arlen   => axi2_arlen,
--            axi_arsize  => axi2_arsize,
--            axi_arburst => axi2_arburst,
--            axi_arlock  => axi2_arlock,
--            axi_arvalid => axi2_arvalid,
--            axi_arready => axi2_arready,

--            axi_rid    => axi2_rid,
--            axi_rdata  => axi2_rdata,
--            axi_rresp  => axi2_rresp,
--            axi_rlast  => axi2_rlast,
--            axi_rvalid => axi2_rvalid,
--            axi_rready => axi2_rready,

--            bd_mclk     => obd_mclk,
--            bd_clk_lock => obd_clk_lock,
--            bd_dclk     => obd_dclk

--        );

--    sreg_out_en      <= '1';
--    sreg_width       <= conv_std_logic_vector(MAX_WIDTH(GNR_MODEL), 12);
--    sreg_height      <= conv_std_logic_vector(MAX_HEIGHT(GNR_MODEL), 12);
--    sreg_offsetx     <= x"000";
--    sreg_offsety     <= x"000";
--    sreg_tp_sel      <= "1000";
--    sreg_tp_mode     <= '0';
--    sreg_tp_dtime    <= x"0200";
--    sreg_tp_value    <= x"0000";
--    sreg_pwr_mode    <= '0';
--    sreg_gate_en     <= '1';
--    sreg_img_mode    <= (others => '0');
--    sreg_timing_mode <= "00";
--    sreg_rst_mode    <= "11"; -- serial reset -- (others => '0');
--    sreg_rst_num     <= x"0";
--    sreg_shutter     <= '0';
--    sreg_erase_en    <= '0';
--    sreg_erase_time  <= conv_std_logic_vector(SIM_GATE_ERASE(GNR_MODEL), 32);
--    sreg_trig_mode   <= "00";
--    sreg_trig_delay  <= conv_std_logic_vector(0, 16);
--    sreg_trig_filt   <= conv_std_logic_vector(0, 8);

--    sreg_roic_shaazen   <= '0';
----    sreg_roic_mute      <= conv_std_logic_vector(ROIC_MUTE(GNR_MODEL), 16);
----    sreg_roic_afe_dclk  <= conv_std_logic_vector(ROIC_AFE_DCLK(GNR_MODEL), 16);
--    sreg_roic_sync_dclk <= conv_std_logic_vector(ROIC_SYNC_DCLK(GNR_MODEL), 16);
--    sreg_roic_sync_aclk <= conv_std_logic_vector(ROIC_SYNC_ACLK(GNR_MODEL), 16);
--    sreg_roic_dead      <= conv_std_logic_vector(ROIC_DEAD(GNR_MODEL), 16);
--    sreg_roic_fa        <= conv_std_logic_vector(ROIC_FA(GNR_MODEL), 16);
--    sreg_roic_cds1      <= conv_std_logic_vector(ROIC_CDS1(GNR_MODEL), 16);
--    sreg_roic_cds2      <= conv_std_logic_vector(ROIC_CDS2(GNR_MODEL), 16);
--    sreg_roic_intrst    <= conv_std_logic_vector(ROIC_INTRST(GNR_MODEL), 16);
--    sreg_roic_tp_sel    <= '0';

--    sreg_gate_oe        <= conv_std_logic_vector(GATE_OE(GNR_MODEL), 16);
--    sreg_gate_xon       <= conv_std_logic_vector(SIM_GATE_XON(GNR_MODEL), 32);
--    sreg_gate_xon_flk   <= conv_std_logic_vector(SIM_GATE_XON_FLK(GNR_MODEL), 32);
--    sreg_gate_flk       <= conv_std_logic_vector(SIM_GATE_FLK(GNR_MODEL), 32);
--    sreg_gate_rst_cycle <= conv_std_logic_vector(SIM_GATE_TRST_PERIOD(GNR_MODEL), 32);

--    sreg_sexp_time      <= conv_std_logic_vector(1000, 32);
--    sreg_exp_time       <= conv_std_logic_vector(0, 32);
--    sreg_frame_time     <= conv_std_logic_vector(0, 32);
--    sreg_frame_num      <= conv_std_logic_vector(0, 16);
--    sreg_frame_val      <= conv_std_logic_vector(0, 16);
--    sreg_roic_en        <= '0';
--    sreg_roic_addr      <= (others => '0');
--    sreg_roic_wdata     <= x"82CF";
--    sreg_req_align      <= '0';
--    sreg_out_mode       <= (others => '0');
--    sreg_ddr_ch_en      <= x"FF";
--    sreg_ddr_base_addr  <= x"A0000000";

--    --* jhim 28 -> 29bit
--    sreg_ddr_ch0_waddr <= ("00" & x"0000000");
--    sreg_ddr_ch1_waddr <= ("00" & x"0040000");
--    sreg_ddr_ch2_waddr <= ("00" & x"0080000");
--    sreg_ddr_ch3_waddr <= ("00" & x"0080000");
--    sreg_ddr_ch4_waddr <= ("00" & x"0080000");
--    sreg_ddr_ch0_raddr <= ("00" & x"0200000");
--    sreg_ddr_ch1_raddr <= ("00" & x"0400000");
--    sreg_ddr_ch2_raddr <= ("00" & x"0800000");
--    sreg_ddr_ch3_raddr <= ("00" & x"0800000");
--    sreg_ddr_ch4_raddr <= ("00" & x"0800000");
--    sreg_ddr_out       <= (others => '0');
--    --# added read ch3 for d2m ref minus, it needs a more bandwidth and line time.
--    --# but it just for simulation. Real is not use nuc data and d2ref simultineously.
--    sreg_line_time     <= x"0F00"; -- x"0CAC";
--    sreg_debug_mode    <= '0';
--    sreg_gain_cal      <= '0';
--    sreg_offset_cal    <= '0';
--    sreg_ofga_lim      <= conv_std_logic_vector(65000, 16);
--    sreg_mpc_ctrl      <= (others => '0');
--    sreg_mpc_num       <= (others => '0');
--    sreg_mpc_point0    <= conv_std_logic_vector(8000, 16);
--    sreg_mpc_point1    <= conv_std_logic_vector(20000, 16);
--    sreg_mpc_point2    <= conv_std_logic_vector(30000, 16);
--    sreg_mpc_point3    <= conv_std_logic_vector(45000, 16);
--    sreg_mpc_posoffset <= conv_std_logic_vector(400, 16);
    
--    sreg_defect_mode   <= '0';
--    sreg_defect_wen    <= '0';
--    sreg_defect_addr   <= (others => '0');
--    sreg_defect_wdata  <= (others => '0');
--    sreg_defect2_wen   <= '0';
--    sreg_defect2_addr  <= (others => '0');
--    sreg_defect2_wdata <= (others => '0');
--    sreg_ldefect_mode  <= '0';
--    sreg_rdefect_wen   <= '0';
--    sreg_rdefect_addr  <= (others => '0');
--    sreg_rdefect_wdata <= (others => '0');
--    sreg_cdefect_wen   <= '0';
--    sreg_cdefect_addr  <= (others => '0');
--    sreg_cdefect_wdata <= (others => '0');
--    sreg_defect_map    <= '0';
--    sreg_dgain         <= conv_std_logic_vector(99, 11);
--    sreg_avg_en        <= '0';
--    sreg_avg_level     <= conv_std_logic_vector(0, 3);
--    sreg_iproc_mode    <= (others => '0');
--    sreg_bright        <= (others => '0');
----  sreg_contrast      <= x"0100"; -- ??? 211122mbh
--    sreg_contrast      <= x"1000";

--    sreg_i2c_mode  <= '0';
--    sreg_i2c_wsize <= conv_std_logic_vector(1, 4);
--    sreg_i2c_rsize <= conv_std_logic_vector(2, 4);
--    sreg_i2c_wdata <= x"0000C3A5";

--    sreg_temp_en <= '1';

--    sreg_sd_wen  <= '0';
--    sreg_sd_ren  <= '0';
--    sreg_sd_addr <= (others => '0');

--    sreg_ext_trig_high   <= x"00000500";
--    sreg_ext_trig_period <= x"00000A00";
--    sreg_ext_trig_active <= "11";

--    sreg_fw_busy <= '0';
--    sreg_toprst_ctrl <= (others => '0'); 

--    sReg_DnrCtrl     <= (others => '0');
--    sreg_SobelCoeff0 <= (others => '0');
--    sreg_SobelCoeff1 <= (others => '0');
--    sreg_SobelCoeff2 <= (others => '0');
--    sreg_BlurOffset  <= (others => '0');
--    sReg_AccCtrl     <= (others => '0');

--    sreg_ExtTrigEn       <= '0';
--    sreg_ExtRst_MODE     <= conv_std_logic_vector(2, 8); 
--    sreg_ExtRst_DetTime  <= conv_std_logic_vector(100, 32); 

--    sreg_debug <= (others => '0');

--     sreg_d2m_en          <= '0';
--     sreg_d2m_exp_in      <= '0';
--     sreg_d2m_sexp_time   <= (others=> '0');
--     sreg_d2m_frame_time  <= (others=> '0');
--     sreg_d2m_xrst_num    <= (others=> '0');
--     sreg_d2m_drst_num    <= (others=> '0');
--     sd2m_xray            <= '0';
--     sd2m_dark            <= '0';

--    process (sys_clk, sys_rst)
--    begin
--        if(sys_rst = '1') then
--            sreg_grab_en <= '0';
--            swait_cnt    <= (others => '0');
--        elsif (sys_clk'event and sys_clk = '1') then
--            if(swait_cnt = 1000) then
--                sreg_grab_en <= '1';
--            else
--                swait_cnt <= swait_cnt + '1';
--            end if;
--        end if;
--    end process;

--    -- ### for simulation  210727mbh 
--    rsreg_width      <= sreg_width  ;
--    rsreg_height     <= sreg_height ;
--    rsreg_offsetx    <= sreg_offsetx;
--    rsreg_offsety    <= sreg_offsety;
--    rsreg_sexp_time  <= sreg_sexp_time ;
--    rsreg_exp_time   <= sreg_exp_time  ;
--    rsreg_frame_time <= sreg_frame_time;
--    rsreg_frame_num  <= sreg_frame_num ;
--    rsreg_frame_val  <= sreg_frame_val ;

--end generate sim;

    -- ######################################################
    -- ##### image size register latch by tft out vsync #####
    -- mbh 210415
     process(sui_clk)
     begin
         if sui_clk'event and sui_clk='1' then
        --
           svsync_tft_1d <= svsync_tft;
           svsync_tft_2d <= svsync_tft_1d;
           svsync_tft_3d <= svsync_tft_2d;
           svsync_tft_4d <= svsync_tft_3d;

           svsync_ddr_1d <= svsync_ddr3;
           svsync_ddr_2d <= svsync_ddr_1d;
           svsync_ddr_3d <= svsync_ddr_2d;
           svsync_ddr_4d <= svsync_ddr_3d;

           isreg_width_1d        <= isreg_width     ;
           isreg_height_1d      <= isreg_height    ;
           isreg_offsetx_1d     <= isreg_offsetx   ;
           isreg_offsety_1d     <= isreg_offsety   ;
           isreg_sexp_time_1d   <= isreg_sexp_time ;
           isreg_exp_time_1d    <= isreg_exp_time  ;
           isreg_frame_time_1d  <= isreg_frame_time;  
           isreg_frame_num_1d   <= isreg_frame_num ;
           isreg_frame_val_1d   <= isreg_frame_val ;
           isreg_line_time_1d   <= isreg_line_time ;

           isreg_width_2d   <= isreg_width_1d  ;
           isreg_height_2d  <= isreg_height_1d ;
           isreg_offsetx_2d <=isreg_offsetx_1d ;
           isreg_offsety_2d <=isreg_offsety_1d ;
           isreg_sexp_time_2d <= isreg_sexp_time_1d ;
           isreg_exp_time_2d  <= isreg_exp_time_1d  ;
           isreg_frame_time_2d<= isreg_frame_time_1d;
           isreg_frame_num_2d <= isreg_frame_num_1d ;
           isreg_frame_val_2d <= isreg_frame_val_1d ;
           isreg_line_time_2d <= isreg_line_time_1d ;
           
            frametimeLimit(5+32-1 downto 0)  <= isreg_frame_time_2d & b"0_0000"; -- *32
            
            -- #### tft blank counter
            if (svsync_tft_4d='0' and svsync_tft_3d='1') then
                tftBlankCnt <= (others=> '0');
                tftBlankCntLat <= tftBlankCnt;
            elsif  svsync_tft_3d='0' then
                tftBlankCnt <= tftBlankCnt + '1';
            end if;
            -- #### tft blank center
            if tftBlankCntLat(tftBlankCntLat'left downto 1) = tftBlankCnt then
                tftBlankCenter <= '1';
            else
                tftBlankCenter <= '0';
            end if;
            
            -- #### ddr blank counter
            if (svsync_ddr_4d='0' and svsync_ddr_3d='1') then
                ddrBlankCnt <= (others=> '0');
                ddrBlankCntLat <= ddrBlankCnt;
            elsif svsync_ddr_3d='0' then
                ddrBlankCnt <= ddrBlankCnt + '1';
            end if;
            -- #### ddr blank center
            if ddrBlankCntLat(ddrBlankCntLat'left downto 1) = ddrBlankCnt then
                ddrBlankCenter <= '1';
            else
                ddrBlankCenter <= '0';
            end if;

            -- #### detect sync stop
            if (svsync_tft_4d='1' and svsync_tft_3d='0') or
                (svsync_ddr_4d='1' and svsync_ddr_3d='0') then
                runningCnt <= (others=> '0');
                stoppedTrig <= '0';
            elsif frametimeLimit < runningCnt then
                runningCnt <= (others=> '0');
                stoppedTrig <= '1';
            else
                runningCnt <= runningCnt + '1';
                stoppedTrig <= '0';
            end if;

            -- #### tft register latch
            if tftBlankCenter='1' or stoppedTrig = '1' then
                rsreg_width      <= isreg_width_2d  ;
                rsreg_height     <= isreg_height_2d ;
                rsreg_offsetx    <= isreg_offsetx_2d;
                rsreg_offsety    <= isreg_offsety_2d;
                rsreg_sexp_time  <= isreg_sexp_time_2d ;
                rsreg_exp_time   <= isreg_exp_time_2d  ;
                rsreg_frame_time <= isreg_frame_time_2d;
                rsreg_frame_num  <= isreg_frame_num_2d ;
                rsreg_frame_val  <= isreg_frame_val_2d ;
           end if;

            -- #### ddr register latch
            if ddrBlankCenter = '1' or stoppedTrig = '1' then
                sreg_width     <= isreg_width_2d  ;
                sreg_height    <= isreg_height_2d ;
                sreg_line_time <= isreg_line_time_2d;
           end if;
        --
        end if;
    end process;

-- #### BYPASS
--     rsreg_width     <= isreg_width     ;
--     rsreg_height    <= isreg_height    ;
--     rsreg_offsetx   <= isreg_offsetx   ;
--     rsreg_offsety   <= isreg_offsety   ;
--     rsreg_sexp_time <= isreg_sexp_time ;
--     rsreg_exp_time  <= isreg_exp_time  ;
--     rsreg_frame_time<= isreg_frame_time;
--     rsreg_frame_num <= isreg_frame_num ;
--     rsreg_frame_val <= isreg_frame_val ;
--     rsreg_line_time <= isreg_line_time ;
--     sreg_width      <= isreg_width     ;
--     sreg_height     <= isreg_height    ;

    U0_REG_TOP : entity work.REG_TOP
        generic map( GNR_MODEL => GNR_MODEL)
        port map (
            isys_clk  => sys_clk,
            isys_rstn => sys_rstn,

            iepc_addr  => epc_addr,
            iepc_wdata => epc_wrdata,
            oepc_rdata => epc_rddata,
            iepc_cs_n  => epc_cs_n,
            iepc_we_n  => epc_rnw,
            oepc_rdy   => epc_rdy,

            axil_reg_awaddr   => axil_reg_awaddr ,
            axil_reg_awprot   => axil_reg_awprot ,
            axil_reg_awvalid  => axil_reg_awvalid,
            axil_reg_awready  => axil_reg_awready,
            axil_reg_wdata    => axil_reg_wdata  ,
            axil_reg_wstrb    => axil_reg_wstrb  ,
            axil_reg_wvalid   => axil_reg_wvalid ,
            axil_reg_wready   => axil_reg_wready ,
            axil_reg_bresp    => axil_reg_bresp  ,
            axil_reg_bvalid   => axil_reg_bvalid ,
            axil_reg_bready   => axil_reg_bready ,
            axil_reg_araddr   => axil_reg_araddr ,
            axil_reg_arprot   => axil_reg_arprot ,
            axil_reg_arvalid  => axil_reg_arvalid,
            axil_reg_arready  => axil_reg_arready,
            axil_reg_rdata    => axil_reg_rdata  ,
            axil_reg_rresp    => axil_reg_rresp  ,
            axil_reg_rvalid   => axil_reg_rvalid ,
            axil_reg_rready   => axil_reg_rready ,

            oreg_out_en   => sreg_out_en,
            oreg_width    => isreg_width,
            oreg_height   => isreg_height,
            oreg_offsetx  => isreg_offsetx,
            oreg_offsety  => isreg_offsety,
            oreg_rev_x    => open,
            oreg_rev_y    => open,
            oreg_tp_sel   => sreg_tp_sel,
            oreg_tp_mode  => sreg_tp_mode,
            oreg_tp_dtime => sreg_tp_dtime,
            oreg_tp_value => sreg_tp_value,

            oreg_pwr_mode       => sreg_pwr_mode,
            oreg_grab_en        => sreg_grab_en,
            oreg_gate_en        => sreg_gate_en,
            oreg_img_mode       => sreg_img_mode,
            oreg_timing_mode    => sreg_timing_mode,
            oreg_rst_mode       => sreg_rst_mode,
            oreg_rst_num        => sreg_rst_num,
            oreg_shutter        => sreg_shutter,
            oreg_erase_en       => sreg_erase_en,
            oreg_erase_time     => sreg_erase_time,
            oreg_trig_mode      => sreg_trig_mode,
            oreg_trig_delay     => sreg_trig_delay,
            oreg_trig_filt      => sreg_trig_filt,
            oreg_trig_valid     => sreg_trig_valid,
            oreg_roic_shaazen   => sreg_roic_shaazen,
            oreg_roic_tp_sel    => sreg_roic_tp_sel,
            oreg_roic_fa        => sreg_roic_fa,
            oreg_roic_cds1      => sreg_roic_cds1,
            oreg_roic_cds2      => sreg_roic_cds2,
            oreg_roic_intrst    => sreg_roic_intrst,
            oreg_roic_sync_aclk => sreg_roic_sync_aclk,
            oreg_roic_dead      => sreg_roic_dead,
            oreg_roic_mute      => sreg_roic_mute,
            oreg_roic_sync_dclk => sreg_roic_sync_dclk,
            oreg_roic_afe_dclk  => sreg_roic_afe_dclk,
            oreg_gate_oe        => sreg_gate_oe,
            oreg_gate_xon       => sreg_gate_xon,
            oreg_gate_xon_flk   => sreg_gate_xon_flk,
            oreg_gate_flk       => sreg_gate_flk,
            oreg_gate_rst_cycle => sreg_gate_rst_cycle,
            oreg_sexp_time      => isreg_sexp_time,
            oreg_exp_time       => isreg_exp_time,
            oreg_frame_time     => isreg_frame_time,
            oreg_frame_num      => isreg_frame_num,
            oreg_frame_val      => isreg_frame_val,
            ireg_frame_cnt      => sreg_frame_cnt,
            ireg_ext_exp_time   => sreg_ext_exp_time,
            ireg_ext_frame_time => sreg_ext_frame_time,
            oreg_roic_en        => sreg_roic_en,
            oreg_roic_addr      => sreg_roic_addr,
            oreg_roic_wdata     => sreg_roic_wdata,
            ireg_roic_rdata     => sreg_roic_rdata,
            oreg_req_align      => sreg_req_align,
            oreg_out_mode       => sreg_out_mode,

            oreg_ddr_ch_en     => sreg_ddr_ch_en,
            oreg_ddr_base_addr => sreg_ddr_base_addr,
            oreg_ddr_ch0_waddr => sreg_ddr_ch0_waddr,
            oreg_ddr_ch1_waddr => sreg_ddr_ch1_waddr,
            oreg_ddr_ch2_waddr => sreg_ddr_ch2_waddr,
            oreg_ddr_ch3_waddr => sreg_ddr_ch3_waddr,
            oreg_ddr_ch4_waddr => sreg_ddr_ch4_waddr,
            oreg_ddr_ch0_raddr => sreg_ddr_ch0_raddr,
            oreg_ddr_ch1_raddr => sreg_ddr_ch1_raddr,
            oreg_ddr_ch2_raddr => sreg_ddr_ch2_raddr,
            oreg_ddr_ch3_raddr => sreg_ddr_ch3_raddr,
            oreg_ddr_ch4_raddr => sreg_ddr_ch4_raddr,
            oreg_ddr_out       => sreg_ddr_out,
            oreg_line_time     => isreg_line_time,
            oreg_debug_mode    => sreg_debug_mode,
            oreg_gain_cal      => sreg_gain_cal,
            oreg_offset_cal    => sreg_offset_cal,
            oreg_mpc_ctrl      => sreg_mpc_ctrl,
            oreg_mpc_num       => sreg_mpc_num,
            oreg_mpc_point0    => sreg_mpc_point0,
            oreg_mpc_point1    => sreg_mpc_point1,
            oreg_mpc_point2    => sreg_mpc_point2,
            oreg_mpc_point3    => sreg_mpc_point3,
            
            oreg_defect_mode   => sreg_defect_mode,
            oreg_defect_wen    => sreg_defect_wen,
            oreg_defect_addr   => sreg_defect_addr,
            oreg_defect_wdata  => sreg_defect_wdata,
            ireg_defect_rdata  => sreg_defect_rdata,
            oreg_defect2_wen   => sreg_defect2_wen,
            oreg_defect2_addr  => sreg_defect2_addr,
            oreg_defect2_wdata => sreg_defect2_wdata,
            ireg_defect2_rdata => sreg_defect2_rdata,
            oreg_ldefect_mode  => sreg_ldefect_mode,
            oreg_rdefect_wen   => sreg_rdefect_wen,
            oreg_rdefect_addr  => sreg_rdefect_addr,
            oreg_rdefect_wdata => sreg_rdefect_wdata,
            ireg_rdefect_rdata => sreg_rdefect_rdata,
            oreg_cdefect_wen   => sreg_cdefect_wen,
            oreg_cdefect_addr  => sreg_cdefect_addr,
            oreg_cdefect_wdata => sreg_cdefect_wdata,
            ireg_cdefect_rdata => sreg_cdefect_rdata,
            oreg_defect_map    => sreg_defect_map,
            oreg_dgain         => sreg_dgain,
            oreg_avg_en        => sreg_avg_en,
            oreg_avg_level     => sreg_avg_level,
            ireg_avg_end       => sreg_avg_end,
            oreg_iproc_mode    => sreg_iproc_mode,
            oreg_bright        => sreg_bright,
            oreg_contrast      => sreg_contrast,
            ireg_pwr_done      => sreg_pwr_done,
            ireg_erase_done    => sreg_erase_done,
            ireg_align_done    => sreg_align_done,
            ireg_roic_done     => sreg_roic_done,
            ireg_grab_done     => sreg_grab_done,
            ireg_calib_done    => scalib_done,
            ireg_roic_temp     => sreg_roic_temp,

            oreg_i2c_mode   => sreg_i2c_mode,
            oreg_i2c_wen    => sreg_i2c_wen,
            oreg_i2c_wsize  => sreg_i2c_wsize,
            oreg_i2c_wdata  => sreg_i2c_wdata,
            oreg_i2c_ren    => sreg_i2c_ren,
            oreg_i2c_rsize  => sreg_i2c_rsize,
            ireg_i2c_rdata0 => sreg_i2c_rdata0,
            ireg_i2c_rdata1 => sreg_i2c_rdata1,
            ireg_i2c_rdata2 => sreg_i2c_rdata2,
            ireg_i2c_rdata3 => sreg_i2c_rdata3,
            ireg_i2c_done   => sreg_i2c_done,

            oreg_temp_en     => sreg_temp_en,
            ireg_device_temp => sreg_device_temp,

            oreg_sd_wen    => sreg_sd_wen,
            oreg_sd_ren    => sreg_sd_ren,
            oreg_sd_addr   => sreg_sd_addr,
            ireg_sd_rw_end => sreg_sd_rw_end,

            oreg_api_ext_trig    => sreg_api_ext_trig,
            oreg_ext_trig_high   => sreg_ext_trig_high,
            oreg_ext_trig_period => sreg_ext_trig_period,
            oreg_ext_trig_active => sreg_ext_trig_active,

            ireg_clk_mclk      => sreg_clk_mclk,
            ireg_clk_dclk      => sreg_clk_dclk,
            ireg_clk_roicdclk  => sreg_clk_roicdclk,
            ireg_clk_uiclk     => sreg_clk_uiclk,

            oreg_fla_ctrl  => sreg_fla_ctrl,
            oreg_fla_addr  => sreg_fla_addr,
            ireg_fla_data  => sreg_fla_data,

            oreg_flaw_ctrl  => sreg_flaw_ctrl ,
            oreg_flaw_cmd   => sreg_flaw_cmd  ,
            oreg_flaw_addr  => sreg_flaw_addr ,
            oreg_flaw_wdata => sreg_flaw_wdata,
            ireg_flaw_rdata => sreg_flaw_rdata,

            oreg_d2m_en         => sreg_d2m_en        , -- d2 mode 210628 mbh
            oreg_d2m_exp_in     => sreg_d2m_exp_in    ,
            oreg_d2m_sexp_time  => sreg_d2m_sexp_time ,
            oreg_d2m_frame_time => sreg_d2m_frame_time,
            oreg_d2m_xrst_num   => sreg_d2m_xrst_num  ,
            oreg_d2m_drst_num   => sreg_d2m_drst_num  ,

            oreg_sync_ctrl        => sreg_sync_ctrl,
            ireg_sync_rcnt0       => sreg_sync_rcnt0,
            ireg_sync_rcnt1       => sreg_sync_rcnt1,
            ireg_sync_rcnt2       => sreg_sync_rcnt2,
            ireg_sync_rcnt3       => sreg_sync_rcnt3,
            ireg_sync_rcnt4       => sreg_sync_rcnt4,
            ireg_sync_rcnt5       => sreg_sync_rcnt5,
            ireg_sync_rcnt6       => sreg_sync_rcnt6,
            ireg_sync_rcnt7       => sreg_sync_rcnt7,
            ireg_sync_rcnt8       => sreg_sync_rcnt8,
            ireg_sync_rcnt9       => sreg_sync_rcnt9,
            ireg_sync_rdata_avcn0 => sreg_sync_rdata_avcn0,
            ireg_sync_rdata_avcn1 => sreg_sync_rdata_avcn1,
            ireg_sync_rdata_avcn2 => sreg_sync_rdata_avcn2,
            ireg_sync_rdata_avcn3 => sreg_sync_rdata_avcn3,
            ireg_sync_rdata_avcn4 => sreg_sync_rdata_avcn4,
            ireg_sync_rdata_avcn5 => sreg_sync_rdata_avcn5,
            ireg_sync_rdata_avcn6 => sreg_sync_rdata_avcn6,
            ireg_sync_rdata_avcn7 => sreg_sync_rdata_avcn7,
            ireg_sync_rdata_avcn8 => sreg_sync_rdata_avcn8,
            ireg_sync_rdata_avcn9 => sreg_sync_rdata_avcn9,
            ireg_sync_rdata_bglw0 => sreg_sync_rdata_bglw0,
            ireg_sync_rdata_bglw1 => sreg_sync_rdata_bglw1,
            ireg_sync_rdata_bglw2 => sreg_sync_rdata_bglw2,
            ireg_sync_rdata_bglw3 => sreg_sync_rdata_bglw3,
            ireg_sync_rdata_bglw4 => sreg_sync_rdata_bglw4,
            ireg_sync_rdata_bglw5 => sreg_sync_rdata_bglw5,
            ireg_sync_rdata_bglw6 => sreg_sync_rdata_bglw6,
            ireg_sync_rdata_bglw7 => sreg_sync_rdata_bglw7,
            ireg_sync_rdata_bglw8 => sreg_sync_rdata_bglw8,
            ireg_sync_rdata_bglw9 => sreg_sync_rdata_bglw9,

            oreg_sm_ctrl  => sreg_sm_ctrl ,
            ireg_sm_data0 => sreg_sm_data0,
            ireg_sm_data1 => sreg_sm_data1,
            ireg_sm_data2 => sreg_sm_data2,
            ireg_sm_data3 => sreg_sm_data3,
            ireg_sm_data4 => sreg_sm_data4,
            ireg_sm_data5 => sreg_sm_data5,
            ireg_sm_data6 => sreg_sm_data6,
            ireg_sm_data7 => sreg_sm_data7,

            oreg_bcal_ctrl => sreg_bcal_ctrl,
            ireg_bcal_data => sreg_bcal_data, 
            
            oreg_mpc_posoffset => sreg_mpc_posoffset,
            
            oreg_fw_busy     => sreg_fw_busy,
            oreg_toprst_ctrl => sreg_toprst_ctrl,

            oreg_DnrCtrl     => sreg_DnrCtrl    ,
            oreg_SobelCoeff0 => sreg_SobelCoeff0,
            oreg_SobelCoeff1 => sreg_SobelCoeff1,
            oreg_SobelCoeff2 => sreg_SobelCoeff2,
            oreg_BlurOffset  => sreg_BlurOffset ,
            oreg_AccCtrl     => sreg_AccCtrl    ,
            ireg_AccStat     => sreg_AccStat    ,

            oreg_ExtTrigEn      => sreg_ExtTrigEn,
            oreg_ExtRst_MODE    => sreg_ExtRst_MODE,
            oreg_ExtRst_DetTime => sreg_ExtRst_DetTime,

            oreg_led_ctrl       => sreg_led_ctrl,
            ireg_trigcnt        => sreg_trigcnt,
            oreg_osd_ctrl       => sreg_osd_ctrl,

            oreg_pwdac_cmd       => sreg_pwdac_cmd      ,
            oreg_pwdac_ticktime  => sreg_pwdac_ticktime ,
            oreg_pwdac_tickinc   => sreg_pwdac_tickinc  ,
            oreg_pwdac_trig      => sreg_pwdac_trig     ,
            ireg_pwdac_currlevel => sreg_pwdac_currlevel,

            oreg_testpoint1     => sreg_testpoint1,
            oreg_testpoint2     => sreg_testpoint2,
            oreg_testpoint3     => sreg_testpoint3,
            oreg_testpoint4     => sreg_testpoint4,

            oreg_roic_str       => sreg_roic_str,

            oreg_edge_ctrl      => sreg_edge_ctrl  ,
            oreg_edge_value     => sreg_edge_value ,
            oreg_edge_top       => sreg_edge_top   ,
            oreg_edge_left      => sreg_edge_left  ,
            oreg_edge_right     => sreg_edge_right ,
            oreg_edge_bottom    => sreg_edge_bottom,

            oreg_bnc_ctrl       => sreg_bnc_ctrl,
            oreg_bnc_high       => sreg_bnc_high,
            oreg_ofga_lim       => sreg_ofga_lim,

            oreg_EqCtrl         => sreg_EqCtrl  ,
            oreg_EqTopVal       => sreg_EqTopVal,

            oreg_debug => sreg_debug
        );

--# for osd 220209mbh
 sreg_sync_rcnt <= 
    sreg_sync_rcnt0       &
    sreg_sync_rcnt1       &
    sreg_sync_rcnt2       &
    sreg_sync_rcnt3       &
    sreg_sync_rcnt4       &
    sreg_sync_rcnt5       &
    sreg_sync_rcnt6       &
    sreg_sync_rcnt7       &
    sreg_sync_rcnt8       &
    sreg_sync_rcnt9       &
    sreg_sync_rdata_avcn0 &
    sreg_sync_rdata_avcn1 &
    sreg_sync_rdata_avcn2 &
    sreg_sync_rdata_avcn3 &
    sreg_sync_rdata_avcn4 &
    sreg_sync_rdata_avcn5 &
    sreg_sync_rdata_avcn6 &
    sreg_sync_rdata_avcn7 &
    sreg_sync_rdata_avcn8 &
    sreg_sync_rdata_avcn9 &
    sreg_sync_rdata_bglw0 &
    sreg_sync_rdata_bglw1 &
    sreg_sync_rdata_bglw2 &
    sreg_sync_rdata_bglw3 &
    sreg_sync_rdata_bglw4 &
    sreg_sync_rdata_bglw5 &
    sreg_sync_rdata_bglw6 &
    sreg_sync_rdata_bglw7 &
    sreg_sync_rdata_bglw8 &
    sreg_sync_rdata_bglw9 ;
            
-- █▀▀ █▀▀ █░█
-- █▄█ ██▄ ▀▄▀ 

  ----------------------------------------------------------
  -- Share Clock & Reset
  ----------------------------------------------------------
    sui_clk  <= axi_aclk;
--    axi_aclk  <= axi_clk;
    sddr_rst <= not sddr_rstn;
    sys_rstn <= not sys_rst;
    
    sbd_clk_lock <= not sreg_toprst_ctrl;
    sbd_mclk <=  obd_mclk;
    sbd_dclk <=  obd_dclk;
    
    -- Instantiation of components ---------------------------------------------

    -- CPU system
--    CPU_INST: entity work.cpu
    GEV_CPU: entity work.cpu_wrapper
        port map   ( -- Clocks and resets
--                  ext_clk_p               => ext_clk_p,
--                  ext_clk_n               => ext_clk_n,
--                  ext_rst                 => ext_rst,
                    ddr_clk => sddr_clk, -- in ddr gen clk
                    ref_clk => sref_clk, -- 200M ddrclk
                    ddr_rst => sddr_rst,
                    calib_done => scalib_done,
--                    axi_clk => axi_clk,
                    sys_clk                 => sys_clk,
                    sys_rst(0)              => sys_rst,
                    sys_locked              => sys_clk_lock,
                    -- Interrupt inputs
                    cpu_irq_0               => cpu_irq_0,
                    cpu_irq_1               => cpu_irq_1,
                    cpu_irq_2               => cpu_irq_2,
                    -- UART
--                    uart_rxd                => uart_rxd,
--                    uart_txd                => uart_txd,
                    uart_rxd                => uart_rx,
                    uart_txd                => uart_tx,
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
                    s0_axi_rready           => axi_rready,
                    
                    axi2_arregion           => (others => '0'), --# smartconn->widthconv+crossbar 231213
                    s0_axi_arregion         => (others => '0'),
                    s0_axi_awregion         => (others => '0'),

                    -- AXI4 slave (to connect external master)
--                    axi2_aclk             => axi2_aclk,
--                    axi2_aresetn(0)       => axi2_aresetn,
                    axi2_awid             => axi2_awid,
                    axi2_awlock           => axi2_awlock,
                    axi2_awqos            => (others => '0'),
                    axi2_awaddr           => axi2_awaddr,
                    axi2_awlen            => axi2_awlen,
                    axi2_awsize           => axi2_awsize,
                    axi2_awburst          => axi2_awburst,
                    axi2_awcache          => (others => '0'),--# axi2_awcache,
                    axi2_awprot           => (others => '0'),--# axi2_awprot,
                    axi2_awvalid          => axi2_awvalid,
                    axi2_awready          => axi2_awready,
                    axi2_wdata            => axi2_wdata,
                    axi2_wstrb            => axi2_wstrb,
                    axi2_wlast            => axi2_wlast,
                    axi2_wvalid           => axi2_wvalid,
                    axi2_wready           => axi2_wready,
                    axi2_bid              => axi2_bid,
                    axi2_bresp            => axi2_bresp,
                    axi2_bvalid           => axi2_bvalid,
                    axi2_bready           => axi2_bready,
                    axi2_arid             => axi2_arid,
                    axi2_arlock           => axi2_arlock,
                    axi2_arqos            => (others => '0'),
                    axi2_araddr           => axi2_araddr,
                    axi2_arlen            => axi2_arlen,
                    axi2_arsize           => axi2_arsize,
                    axi2_arburst          => axi2_arburst,
                    axi2_arcache          => (others => '0'),--# axi2_arcache,
                    axi2_arprot           => (others => '0'),--# axi2_arprot,
                    axi2_arvalid          => axi2_arvalid,
                    axi2_arready          => axi2_arready,
                    axi2_rid              => axi2_rid,
                    axi2_rdata            => axi2_rdata,
                    axi2_rresp            => axi2_rresp,
                    axi2_rlast            => axi2_rlast,
                    axi2_rvalid           => axi2_rvalid,
                    axi2_rready           => axi2_rready,
                    axi2_awregion => (others => '0'), --# it's added after inserting width changer 231201

                    m_axil_reg_awaddr     => axil_reg_awaddr  ,
                    m_axil_reg_awprot     => axil_reg_awprot  ,
                    m_axil_reg_awvalid    => axil_reg_awvalid ,
                    m_axil_reg_awready    => axil_reg_awready ,
                    m_axil_reg_wdata      => axil_reg_wdata   ,
                    m_axil_reg_wstrb      => axil_reg_wstrb   ,
                    m_axil_reg_wvalid     => axil_reg_wvalid  ,
                    m_axil_reg_wready     => axil_reg_wready  ,
                    m_axil_reg_bresp      => axil_reg_bresp   ,
                    m_axil_reg_bvalid     => axil_reg_bvalid  ,
                    m_axil_reg_bready     => axil_reg_bready  ,
                    m_axil_reg_araddr     => axil_reg_araddr  ,
                    m_axil_reg_arprot     => axil_reg_arprot  ,
                    m_axil_reg_arvalid    => axil_reg_arvalid ,
                    m_axil_reg_arready    => axil_reg_arready ,
                    m_axil_reg_rdata      => axil_reg_rdata   ,
                    m_axil_reg_rresp      => axil_reg_rresp   ,
                    m_axil_reg_rvalid     => axil_reg_rvalid  ,
                    m_axil_reg_rready     => axil_reg_rready  ,
                       
                    epc_addr     => epc_addr  ,
                    epc_be       => epc_be    ,
                    epc_cs_n(0)  => epc_cs_n  ,
                    epc_rdata    => epc_rddata ,
                    epc_rdy(0)   => epc_rdy   ,
                    epc_rnw      => epc_rnw   ,
                    epc_wdata    => epc_wrdata ,
      
                    bd_mclk     => obd_mclk     ,
                    bd_clk_lock => obd_clk_lock ,
                    bd_dclk     => obd_dclk
                    );

    -- Video test pattern generator
  -- GEV_VIDEO: entity work.videotpg_0
     GEV_VIDEO: entity work.videotpg_wrapper
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
                    gpio_in(3 downto 0)     => (others => '0'), -- gpio_dip_sw,
                    gpio_out                => open,
                    gev_scc                 => mem_scc,
                    fb_clk                  => axi_aclk,
                    fb_rst                  => axi_rst
--                    fb_frame                => video_frame,
--                    fb_dv                   => video_dv,
--                    fb_data                 => video_data(63 downto 0),
--                    fb_width                => video_fb_width
                    );

    video_frame    <= sfb_frame;
    video_dv       <= sfb_dv;
    video_fb_width <= "0000" & sfb_width;
    video_data     <= LOWV(128-1 downto 64) &  sfb_data when sreg_fw_busy = '0' else (others => '1');
    
    -- AXI framebuffer
     GEV_FRAMEBUF: entity work.framebuf_wrapper
        port map   (
                    sys_en                  => sys_net_up,
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
     GEV_GIGE: entity work.xgige_wrapper
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
--                    spi_clk                 => spi_clk,
--                    spi_cs_n                => spi_cs0_n,
--                    spi_mosi                => spi_mosi,
--                    spi_miso                => spi_miso,
                    spi_clk            => ge_FLASH_CLK,  --#
                    spi_cs_n           => ge_FLASH_FCS,  --#
                    spi_mosi           => ge_FLASH_D(0), --#
                    spi_miso           => ge_FLASH_D(1), --#
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
     GEV_XGMAC: entity work.xgmac_wrapper
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
     GEV_RXAUI: entity work.rxaui_wrapper
        port map   (reset                   => sys_rst,
                    dclk                    => sys_clk,
                    clk156_out              => xgmii_clk,
                    clk156_lock             => xgmii_lock,
                    refclk_out              => open,
--                    refclk_p                => ref_clk_p,
--                    refclk_n                => ref_clk_n,
                    refclk_p             => PHY_CLK_P, --# 
                    refclk_n             => PHY_CLK_N, --#
                    qplloutclk_out          => open,
                    qplllock_out            => open,
                    qplloutrefclk_out       => open,
                    xgmii_txd               => xgmii_txd,
                    xgmii_txc               => xgmii_txc,
                    xgmii_rxd               => xgmii_rxd,
                    xgmii_rxc               => xgmii_rxc,
                    rxaui_tx_l0_p           => PHY_SIP(0), -- rxaui_tx_l0_p,
                    rxaui_tx_l0_n           => PHY_SIN(0), -- rxaui_tx_l0_n,
                    rxaui_tx_l1_p           => PHY_SIP(1), -- rxaui_tx_l1_p,
                    rxaui_tx_l1_n           => PHY_SIN(1), -- rxaui_tx_l1_n,
                    rxaui_rx_l0_p           => PHY_SOP(0), -- rxaui_rx_l0_p,
                    rxaui_rx_l0_n           => PHY_SON(0), -- rxaui_rx_l0_n,
                    rxaui_rx_l1_p           => PHY_SOP(1), -- rxaui_rx_l1_p,
                    rxaui_rx_l1_n           => PHY_SON(1), -- rxaui_rx_l1_n,
                    signal_detect           => rxaui_signal_detect,
                    debug(5)                => rxaui_align_status,  -- Align status
                    debug(4 downto 1)       => rxaui_sync_status,   -- Synchronization status
                    debug(0)                => rxaui_mgt_tx_ready,  -- TX phase align complete
                    configuration_vector    => rxaui_config_vector,
                    status_vector           => rxaui_status_vector);


    -- KC705 platform specific logic -------------------------------------------

--    -- Fan PWM
--    FAN_PWM_PROC: process (sys_clk)
--        variable div    : unsigned(11 downto 0);
--    begin
--        if rising_edge(sys_clk) then
--            if (sys_rst = '1') then
--                fan_pwm <= '1';
--                div     := (others => '0');
--            else
--                if (div(11 downto 10) = "00") then
--                    fan_pwm <= '1';
--                elsif (div(11 downto 10) = unsigned(sys_gpo)) then
--                    fan_pwm <= '0';
--                end if;
--                div := div + 1;
--            end if;
--        end if;
--    end process FAN_PWM_PROC;

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
--                    USRCCLKO        => spi_clk,     -- 1-bit input: User CCLK input
                    USRCCLKO        => FLASH_CLK,     -- 1-bit input: User CCLK input
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
--                    IO  => fmc_mdio);
                    IO  => PHY_MDIO);
--    fmc_mdc <= mac_mdc;
    PHY_MDC <= mac_mdc;

    -- I2C bus
    I2C_SDA_IOBUF_INST: IOBUF
        port map   (I   => '0',
                    O   => fmc_sda_i,
                    T   => fmc_sda_o,
--                    IO  => fmc_sda);
                    IO  => EEPROM_SDA);
--    fmc_scl <= fmc_scl_o;
    EEPROM_SCL <= fmc_scl_o;

    -- FMC card reset
--    fmc_reset_n <= not xgmii_rst;
    PHY_RESET_N <= not xgmii_rst;
    
    axi_rst                   <= not axi_aresetn;       -- Synchronous reset
    video_data(127 downto 64) <= (others => '0');


    -- Test points -------------------------------------------------------------

    -- GPIO LEDs
--    gpio_led(0) <= action_cmd_tgl(0);
--    gpio_led(1) <= action_cmd_tgl(1);
--    gpio_led(2) <= '0';
--    gpio_led(3) <= '0';
--    gpio_led(4) <= '0';
--    gpio_led(5) <= '0';
--    gpio_led(6) <= '0';
--    gpio_led(7) <= '0';

--    fmc_clk_sel    <= '0';
--    fmc_clk_fpga_p <= '0';
--    fmc_clk_fpga_n <= '0';
--    fmc_gpio       <= (others => '0');
--    fmc_phy_gpio   <= (others => '0');

-- ################################################################################
    FLASH_CLK <= spi_rtl_0_sck_o when sreg_fla_ctrl(0)='1' else
                 spi_rtl_0_sck_o when sreg_flaw_ctrl(0)='1' else
                 ge_FLASH_CLK;
-- ### spi_cs
--    sFLASH_FCS <= ge_FLASH_FCS when sreg_fla_ctrl(0)='0' else 
--                 spi_rtl_0_ss_o when spi_rtl_0_ss_t='0' else
--                 '1';
    sFLASH_FCS <= spi_rtl_0_ss_o when sreg_fla_ctrl(0)='1' else 
                  spi_rtl_0_ss_o when sreg_flaw_ctrl(0)='1' else 
                  ge_FLASH_FCS ;
    FLASH_FCS <= sFLASH_FCS;

    s_spi_rtl_0_io0_o <= spi_rtl_0_io0_o when sreg_fla_ctrl(0)='1' else
                         spi_rtl_0_io0_o when sreg_flaw_ctrl(0)='1' else
                         ge_FLASH_D(0);
    s_spi_rtl_0_io0_t <= spi_rtl_0_io0_t when sreg_fla_ctrl(0)='1' else
                         spi_rtl_0_io0_t when sreg_flaw_ctrl(0)='1' else
                         '0';
    spi_rtl_0_io0_iobuf: component IOBUF
         port map (
          I => s_spi_rtl_0_io0_o,
          IO => FLASH_D(0),
          O => spi_rtl_0_io0_i,
          T => s_spi_rtl_0_io0_t
        );
-- ### spi_data 1
    s_spi_rtl_0_io1_o <= spi_rtl_0_io1_o when sreg_fla_ctrl(0)='1' else 
                         spi_rtl_0_io1_o when sreg_flaw_ctrl(0)='1' else 
                         '0';
    s_spi_rtl_0_io1_t <= spi_rtl_0_io1_t when sreg_fla_ctrl(0)='1' else 
                         spi_rtl_0_io1_t when sreg_flaw_ctrl(0)='1' else 
                         '1';
    spi_rtl_0_io1_iobuf: component IOBUF
         port map (
          I => s_spi_rtl_0_io1_o,
          IO => FLASH_D(1),
          O => spi_rtl_0_io1_i,
          T => s_spi_rtl_0_io1_t
        );

    ge_FLASH_D(1) <= '0' when sreg_fla_ctrl(0)='1' else
                     '0' when sreg_flaw_ctrl(0)='1' else
                     spi_rtl_0_io1_i;

spi_rtl_0_io2_iobuf: component IOBUF
     port map (
      I => spi_rtl_0_io2_o,
      IO => FLASH_D(2),
      O => spi_rtl_0_io2_i,
      T => spi_rtl_0_io2_t
    );
spi_rtl_0_io3_iobuf: component IOBUF
     port map (
      I => spi_rtl_0_io3_o,
      IO => FLASH_D(3),
      O => spi_rtl_0_io3_i,
      T => spi_rtl_0_io3_t
    );      

    u_flash_ctrl : entity work.flash_ctrl
    port map(
     irst          => '0', -- irst ,
     isysclk       => sys_clk      ,
     ireg_fla_ctrl => sreg_fla_ctrl,
     ireg_fla_addr => sreg_fla_addr,
     oreg_fla_data => sreg_fla_data,
     iepc_cs_n     => epc_cs_n,
     
     ireg_flaw_ctrl  => sreg_flaw_ctrl ,
     ireg_flaw_cmd   => sreg_flaw_cmd  ,
     ireg_flaw_addr  => sreg_flaw_addr ,
     ireg_flaw_wdata => sreg_flaw_wdata,
     oreg_flaw_rdata => sreg_flaw_rdata,

     ispi_io0_i => spi_rtl_0_io0_i,
     ospi_io0_o => spi_rtl_0_io0_o,
     ospi_io0_t => spi_rtl_0_io0_t,
     ispi_io1_i => spi_rtl_0_io1_i,
     ospi_io1_o => spi_rtl_0_io1_o,
     ospi_io1_t => spi_rtl_0_io1_t,
     ispi_io2_i => spi_rtl_0_io2_i,
     ospi_io2_o => spi_rtl_0_io2_o,
     ospi_io2_t => spi_rtl_0_io2_t,
     ispi_io3_i => spi_rtl_0_io3_i,
     ospi_io3_o => spi_rtl_0_io3_o,
     ospi_io3_t => spi_rtl_0_io3_t,
     ispi_sck_i => spi_rtl_0_sck_i,
     ospi_sck_o => spi_rtl_0_sck_o,
     ospi_sck_t => spi_rtl_0_sck_t,
     ispi_css_i => spi_rtl_0_ss_i ,
     ospi_css_o => spi_rtl_0_ss_o ,
     ospi_css_t => spi_rtl_0_ss_t 
 );
 
u_probe_top : entity work.probe_top 
    port map(
        sys_clk    => sys_clk   ,
        sbd_mclk   => sbd_mclk  ,
        sbd_dclk   => sbd_dclk  ,
        sui_clk    => sui_clk   ,
        sroic_dclk => sroic_dclk(0),
    --####################
    --### CLK COUNTER ###
        sreg_clk_mclk => sreg_clk_mclk,
        sreg_clk_dclk => sreg_clk_dclk,
        sreg_clk_roicdclk => sreg_clk_roicdclk,
        sreg_clk_uiclk => sreg_clk_uiclk,

    --####################
    --### SYNC COUNTER ###
        svsync_tft => svsync_tft,
        shsync_tft => shsync_tft,
        sdata_tft => sdata_tft,

        svsync_ddr3 => svsync_ddr3,
        shsync_ddr3 => shsync_ddr3,
        sdata_ddr3 => sdata_ddr3(16-1 downto 0),

        shsync_calib => shsync_calib,
        svsync_calib => svsync_calib,
        sdata_calib => sdata_calib(16-1 downto 0),

        shsync_img_proc => shsync_img_proc,
        svsync_img_proc => svsync_img_proc,
        sdata_img_proc => sdata_img_proc(16-1 downto 0),

        sfb_frame => sfb_frame,
        sfb_dv => sfb_dv,
        sfb_data => sfb_data,

        sreg_sync_ctrl => sreg_sync_ctrl,

        sreg_sync_rcnt2 => sreg_sync_rcnt2,
        sreg_sync_rcnt3 => sreg_sync_rcnt3,
        sreg_sync_rcnt7 => sreg_sync_rcnt7,
        sreg_sync_rcnt8 => sreg_sync_rcnt8,
        sreg_sync_rcnt9 => sreg_sync_rcnt9,

        sreg_sync_rdata_avcn2 => sreg_sync_rdata_avcn2,
        sreg_sync_rdata_avcn3 => sreg_sync_rdata_avcn3,
        sreg_sync_rdata_avcn7 => sreg_sync_rdata_avcn7,
        sreg_sync_rdata_avcn8 => sreg_sync_rdata_avcn8,
        sreg_sync_rdata_avcn9 => sreg_sync_rdata_avcn9,

        sreg_sync_rdata_bglw2 => sreg_sync_rdata_bglw2,
        sreg_sync_rdata_bglw3 => sreg_sync_rdata_bglw3,
        sreg_sync_rdata_bglw7 => sreg_sync_rdata_bglw7,
        sreg_sync_rdata_bglw8 => sreg_sync_rdata_bglw8,
        sreg_sync_rdata_bglw9 => sreg_sync_rdata_bglw9,

    --################
    --### SM PROBE ###
        oostate_tft => oostate_tft,
        oostate_roic => oostate_roic,
        oostate_gate => oostate_gate,
        oostate_roic_setting => oostate_roic_setting,
        oostate_dpram_data_align => oostate_dpram_data_align,
        oostate_dpram_roi => oostate_dpram_roi,
        oostate_avg => oostate_avg,
        oostate_grab => oostate_grab, 

        sroic_mclk_div => sroic_mclk_div,
        sreg_sm_ctrl   => sreg_sm_ctrl,
        sreg_sm_data0  => sreg_sm_data0,
        sreg_sm_data1  => sreg_sm_data1,
        sreg_sm_data2  => sreg_sm_data2,
        sreg_sm_data3  => sreg_sm_data3,
        sreg_sm_data4  => sreg_sm_data4,
        sreg_sm_data5  => sreg_sm_data5,
        sreg_sm_data6  => sreg_sm_data6,
        sreg_sm_data7  => sreg_sm_data7
    );

--    ila_debug_spi : if(GEN_ILA_TOP_SPI = "ON") generate

----        COMPONENT ila_top_spi
----        PORT (
----            clk     : IN STD_LOGIC;
----            probe0  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
----            probe1  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
----            probe2  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
----            probe3  : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
----            probe4  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe5  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe6  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe7  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe8  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe9  : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe10 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
----            probe11 : IN STD_LOGIC_VECTOR(7 DOWNTO 0) 
----        );
----        END COMPONENT  ;

--    begin
         
--        u_ila_top_spi : entity work.ila_top_spi
--        PORT MAP (
--            clk        => sys_clk, -- 100 Mhz 
--            probe0(0)  => FLASH_CLK,          
--            probe1(0)  => sFLASH_FCS,         
--            probe2(0)  => spi_rtl_0_io0_i,    
--            probe3(0)  => spi_rtl_0_io1_i,    
--            probe4(0)  => spi_rtl_0_io2_i,    
--            probe5(0)  => spi_rtl_0_io3_i,    
--            probe6(0)  => s_spi_rtl_0_io0_t,
--            probe7(0)  => s_spi_rtl_0_io1_t,
--            probe8(0)  => spi_rtl_0_io2_t,
--            probe9(0)  => spi_rtl_0_io3_t,
--            probe10(0) => dummy(0),
--            probe11    => dummy(8-1 downto 0)
     
--        );      
--    end generate ila_debug_spi;    

 
  ----------------------------------------------------------
  -- DDR3 Update Timing for each Channel
  ----------------------------------------------------------

ila_debug : if(GEN_ILA_TOP = "ON") generate

    component ILA_TOP
        port (
            clk     : in std_logic;
            probe0  : in std_logic;
            probe1  : in std_logic;
            probe2  : in std_logic_vector(9 downto 0);
            probe3  : in std_logic_vector(11 downto 0);
            probe4  : in std_logic_vector(63 downto 0);
            probe5  : in std_logic;
            probe6  : in std_logic;
            probe7  : in std_logic_vector(11 downto 0);
            probe8  : in std_logic_vector(11 downto 0);
            probe9  : in std_logic_vector(63 downto 0)
--            probe10 : in std_logic;
--            probe11 : in std_logic;
--            probe12 : in std_logic_vector(11 downto 0);
--            probe13 : in std_logic_vector(11 downto 0);
--            probe14 : in std_logic_vector(63 downto 0)
--            probe15 : in std_logic;
--            probe16 : in std_logic;
--            probe17 : in std_logic_vector(11 downto 0);
--            probe18 : in std_logic_vector(11 downto 0);
--            probe19 : in std_logic_vector(63 downto 0)
        );
    end component;

begin
    U0_ILA_TOP : ILA_TOP
        port map (
            clk     => sui_clk,
            probe0  => shsync_tft,
            probe1  => svsync_tft,
            probe2  => shcnt_tft,
            probe3  => svcnt_tft,
            probe4  => sdata_tft,
            probe5  => shsync_ddr3,
            probe6  => svsync_ddr3,
            probe7  => shcnt_ddr3,
            probe8  => svcnt_ddr3,
            probe9  => sdata_ddr3
--            probe10 => shsync_calib,
--            probe11 => svsync_calib,
--            probe12 => shcnt_calib,
--            probe13 => svcnt_calib,
--            probe14 => sdata_calib,
--            probe10 => shsync_img_proc,
--            probe11 => svsync_img_proc,         
--            probe12 => shcnt_img_proc,
--            probe13 => svcnt_img_proc,
--            probe14 => sdata_img_proc
        );
end generate ila_debug;

ila_debug2 : if(GEN_ILA_top_roic = "ON") generate

    component ILA_TOP_ROIC
        port (
            clk     : in std_logic;

  --* gate
            probe0  : in std_logic;
            probe1  : in std_logic_vector( 5 downto 0);
            probe2  : in std_logic_vector( 5 downto 0);
            probe3  : in std_logic;
            probe4  : in std_logic;
            probe5  : in std_logic;
            probe6  : in std_logic;

  --* roic
            probe7  : in std_logic;
            probe8  : in std_logic;
            probe9  : in std_logic;
            probe10 : in std_logic;
            probe11 : in std_logic;
            probe12 : in std_logic;
            probe13 : in std_logic;
            probe14 : in std_logic;
            probe15 : in std_logic;

  --* tft ctrl state
            probe16 : in tstate_grab;
            probe17 : in tstate_tft;
            probe18 : in tstate_roic;
            probe19 : in tstate_gate; 
            
            probe20 : in std_logic_vector( 10-1 downto 0);
            probe21 : in std_logic_vector( 12-1 downto 0);
            probe22 : in std_logic_vector( 16-1 downto 0);
            
            probe23 : in std_logic;
            probe24 : in std_logic;

            probe25 : in tstate_roic_setting;
            probe26 : in tstate_dpram_data_align;
            probe27 : in tstate_dpram_roi
        );
    end component;
signal probe1_pm : std_logic_vector( 5 downto 0);
signal probe2_pm : std_logic_vector( 5 downto 0);
begin

probe1_pm <= "00" & sgate_dio1(4-1 downto 0);
probe2_pm <= "00" & sgate_dio2(4-1 downto 0);
    U0_ILA_TOP : ILA_TOP_ROIC
        port map (
            clk => sroic_mclk_div,
    --* gate
            probe0 => sgate_cpv,
            probe1 => probe1_pm, -- "00" & sgate_dio1(4-1 downto 0),
            probe2 => probe2_pm, -- "00" & sgate_dio2(4-1 downto 0),
            probe3 => sgate_oe1,
            probe4 => sgate_oe2,
            probe5 => sgate_xon,
            probe6 => sgate_flk,
    --* roic
            probe7  => '0', -- sroic_mclk_div, it's a clock!
            probe8  => sroic_sync_div,
            probe9  => sroic_tp_sel_div,
            probe10 => sroic_sck_div,
            probe11 => sroic_cs_div,
            probe12 => sroic_sdo_div,
            probe13 => F_ROIC_SDO(0),
            probe14 => sreg_roic_en,
            probe15 => sreg_grab_en,
    --* tft ctrl state
            probe16 => oostate_grab,
            probe17 => oostate_tft,
            probe18 => oostate_roic,
            probe19 => oostate_gate,
            
            probe20 => shcnt_tft,
            probe21 => svcnt_tft,
            probe22 => sdata_tft(16-1 downto 0),

            probe23 => sext_trig_in,
            probe24 => sEXT_OUT,

            probe25 => oostate_roic_setting,     -- 3
            probe26 => oostate_dpram_data_align, -- 3
            probe27 => oostate_dpram_roi         -- 2

        );
end generate ila_debug2;

end top;
