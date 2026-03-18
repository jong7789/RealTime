library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

use WORK.TOP_HEADER.all;

entity DDR3_TOP is
generic ( GNR_MODEL : string  := "EXT1616R" );
    port
    (
        iui_clk             : in std_logic;
        iui_rstn            : in std_logic;
        idata_clk           : in std_logic;
        idata_rstn          : in std_logic;
        isyncgen_rstn       : in std_logic;

        ireg_ddr_acc_ch_en  : in std_logic;
        ireg_ddr_ch_en      : in std_logic_vector(7 downto 0);
        ireg_ddr_base_addr  : in std_logic_vector(31 downto 0);

        ireg_ddr_ch0_waddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch1_waddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch2_waddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch3_waddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch4_waddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch0_raddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch1_raddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch2_raddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch3_raddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_ch4_raddr  : in std_logic_vector(29 downto 0);
        ireg_ddr_out        : in std_logic_vector(2 downto 0);
        ireg_line_time      : in std_logic_vector(15 downto 0);
        ireg_sd_wen         : in std_logic;
        ireg_width          : in std_logic_vector(11 downto 0);
        ireg_height         : in std_logic_vector(11 downto 0);
         
        istate_tftd : in tstate_tft;

        ihsync              : in std_logic;
        ivsync              : in std_logic;
        ihcnt               : in std_logic_vector(9 downto 0);
        ivcnt               : in std_logic_vector(11 downto 0);
        idata               : in std_logic_vector(DDR_BIT_W0( (GNR_MODEL))-1 downto 0);

        ohsync              : out std_logic;
        ovsync              : out std_logic;
        ohcnt               : out std_logic_vector(11 downto 0);
        ovcnt               : out std_logic_vector(11 downto 0);
        odata               : out std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0);

        ireq_data           : in std_logic;

        ich0_wen            : in std_logic;
        ich0_waddr          : in std_logic_vector(11 downto 0);
        ich0_wvcnt          : in std_logic_vector(11 downto 0);
        ich0_wdata          : in std_logic_vector(DDR_BIT_W0( (GNR_MODEL))-1 downto 0);
        ich1_wen            : in std_logic;
        ich1_waddr          : in std_logic_vector(11 downto 0);
        ich1_wvcnt          : in std_logic_vector(11 downto 0);
        ich1_wdata          : in std_logic_vector(DDR_BIT_W1( (GNR_MODEL))-1 downto 0);
        ich2_wen            : in std_logic;
        ich2_waddr          : in std_logic_vector(11 downto 0);
        ich2_wvcnt          : in std_logic_vector(11 downto 0);
        ich2_wdata          : in std_logic_vector(DDR_BIT_W2( (GNR_MODEL))-1 downto 0);
        id2m_xray           : in std_logic;
        ich3_wen            : in std_logic;
        ich3_waddr          : in std_logic_vector(11 downto 0);
        ich3_wvcnt          : in std_logic_vector(11 downto 0);
        ich3_wdata          : in std_logic_vector(DDR_BIT_W3( (GNR_MODEL))-1 downto 0);
        ich4_wen            : in std_logic;
        ich4_waddr          : in std_logic_vector(11 downto 0);
        ich4_wvcnt          : in std_logic_vector(11 downto 0);
        ich4_wdata          : in std_logic_vector(DDR_BIT_W4( (GNR_MODEL))-1 downto 0);

        och0_rdata          : out std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0);
        och1_rdata          : out std_logic_vector(DDR_BIT_R1( (GNR_MODEL))-1 downto 0);
        och2_rdata          : out std_logic_vector(DDR_BIT_R2( (GNR_MODEL))-1 downto 0);
        och3_rdata          : out std_logic_vector(DDR_BIT_R3( (GNR_MODEL))-1 downto 0);
        och4_rdata          : out std_logic_vector(DDR_BIT_R4( (GNR_MODEL))-1 downto 0);

        axi_awid            : out std_logic_vector(3 downto 0);
        axi_awaddr          : out std_logic_vector(31 downto 0);
        axi_awlen           : out std_logic_vector(7 downto 0);
        axi_awsize          : out std_logic_vector(2 downto 0);
        axi_awburst         : out std_logic_vector(1 downto 0);
        axi_awlock          : out std_logic_vector(0 downto 0);
        axi_awvalid         : out std_logic;
        axi_awready         : in std_logic;

        axi_wdata           : out std_logic_vector(511 downto 0);
        axi_wstrb           : out std_logic_vector(63 downto 0);
        axi_wlast           : out std_logic;
        axi_wvalid          : out std_logic;
        axi_wready          : in std_logic;

        axi_bid             : in std_logic_vector(3 downto 0);
        axi_bresp           : in std_logic_vector(1 downto 0);
        axi_bvalid          : in std_logic;
        axi_bready          : out std_logic;

        axi_arid            : out std_logic_vector(3 downto 0);
        axi_araddr          : out std_logic_vector(31 downto 0);
        axi_arlen           : out std_logic_vector(7 downto 0);
        axi_arsize          : out std_logic_vector(2 downto 0);
        axi_arburst         : out std_logic_vector(1 downto 0);
        axi_arlock          : out std_logic_vector(0 downto 0);
        axi_arvalid         : out std_logic;
        axi_arready         : in std_logic;

        axi_rid             : in std_logic_vector(3 downto 0);
        axi_rdata           : in std_logic_vector(511 downto 0);
        axi_rresp           : in std_logic_vector(1 downto 0);
        axi_rlast           : in std_logic;
        axi_rvalid          : in std_logic;
        axi_rready          : out std_logic;

        ostate_sync_ddr     : out tstate_sync_ddr;
        ostate_ddr_sub      : out tstate_ddr_sub;
        ostate_write_if     : out tstate_write;
        ostate_read_if      : out tstate_read
    );
end DDR3_TOP;

architecture Behavioral of DDR3_TOP is

    component DDR3_SYNC_GEN
        generic ( GNR_MODEL : string  := "EXT1616R" );
        port
        (
            idata_clk        : in std_logic;
            idata_rstn       : in std_logic;

            ireg_line_time   : in std_logic_vector(15 downto 0);
            ireg_sd_wen      : in std_logic;
            ireg_width       : in std_logic_vector(11 downto 0);
            ireg_height      : in std_logic_vector(11 downto 0);

            ireq_data        : in std_logic;
            istate_tftd      : in tstate_tft;

            ihsync           : in std_logic;
            ivsync           : in std_logic;
            ihcnt            : in std_logic_vector(9 downto 0);
            ivcnt            : in std_logic_vector(11 downto 0);

            ohsync           : out std_logic;
            ovsync           : out std_logic;
            ohcnt            : out std_logic_vector(11 downto 0);
            ovcnt            : out std_logic_vector(11 downto 0);

            ostate_sync_ddr  : out tstate_sync_ddr
        );
    end component;

    component AXI_SUB_IF
    generic ( GNR_MODEL : string  := "EXT1616R" );
        port
        (
            iui_clk             : in std_logic;
            iui_rstn            : in std_logic;
            iaxi_clk            : in std_logic;
            iaxi_rstn           : in std_logic;
            idata_clk           : in std_logic;
            idata_rstn          : in std_logic;

            ireg_ddr_acc_ch_en  : in std_logic;
            ireg_ddr_ch_en      : in std_logic_vector(7 downto 0);
            ireg_ddr_base_addr  : in std_logic_vector(31 downto 0);

            --* jhkim 28 -> 29bit
            ireg_ddr_ch0_waddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch1_waddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch2_waddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch3_waddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch4_waddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch0_raddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch1_raddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch2_raddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch3_raddr  : in std_logic_vector(29 downto 0);
            ireg_ddr_ch4_raddr  : in std_logic_vector(29 downto 0);

            ireg_width          : in std_logic_vector(11 downto 0);
            ireg_height         : in std_logic_vector(11 downto 0);

            iaxi_wready         : in std_logic;
            iaxi_bready         : in std_logic;

            iconv_rlast         : in std_logic;
            iconv_hsync         : in std_logic;
            iconv_vcnt          : in std_logic_vector(11 downto 0);

            ich0_wen            : in std_logic;
            ich0_waddr          : in std_logic_vector(11 downto 0);
            ich0_wvcnt          : in std_logic_vector(11 downto 0);
            ich0_wdata          : in std_logic_vector(DDR_BIT_W0( (GNR_MODEL))-1 downto 0);
            ich1_wen            : in std_logic;
            ich1_waddr          : in std_logic_vector(11 downto 0);
            ich1_wvcnt          : in std_logic_vector(11 downto 0);
            ich1_wdata          : in std_logic_vector(DDR_BIT_W1( (GNR_MODEL))-1 downto 0);
            ich2_wen            : in std_logic;
            ich2_waddr          : in std_logic_vector(11 downto 0);
            ich2_wvcnt          : in std_logic_vector(11 downto 0);
            ich2_wdata          : in std_logic_vector(DDR_BIT_W2( (GNR_MODEL))-1 downto 0);
            id2m_xray           : in std_logic;
            ich3_wen            : in std_logic;
            ich3_waddr          : in std_logic_vector(11 downto 0);
            ich3_wvcnt          : in std_logic_vector(11 downto 0);
            ich3_wdata          : in std_logic_vector(DDR_BIT_W3( (GNR_MODEL))-1 downto 0);
            ich4_wen            : in std_logic;
            ich4_waddr          : in std_logic_vector(11 downto 0);
            ich4_wvcnt          : in std_logic_vector(11 downto 0);
            ich4_wdata          : in std_logic_vector(DDR_BIT_W4( (GNR_MODEL))-1 downto 0); 

            och0_wtrig          : out std_logic;
            och0_waddr          : out std_logic_vector(31 downto 0);
            och0_wdata          : out std_logic_vector(511 downto 0);
            och1_wtrig          : out std_logic;
            och1_waddr          : out std_logic_vector(31 downto 0);
            och1_wdata          : out std_logic_vector(511 downto 0);
            och2_wtrig          : out std_logic;
            och2_waddr          : out std_logic_vector(31 downto 0);
            och2_wdata          : out std_logic_vector(511 downto 0);
            och3_wtrig          : out std_logic;
            och3_waddr          : out std_logic_vector(31 downto 0);
            och3_wdata          : out std_logic_vector(511 downto 0);
            och4_wtrig          : out std_logic;
            och4_waddr          : out std_logic_vector(31 downto 0);
            och4_wdata          : out std_logic_vector(511 downto 0);
            och0_rtrig          : out std_logic;
            och0_raddr          : out std_logic_vector(31 downto 0);
            och0_rvcnt          : out std_logic_vector(11 downto 0);
            och1_rtrig          : out std_logic;
            och1_raddr          : out std_logic_vector(31 downto 0);
            och1_rvcnt          : out std_logic_vector(11 downto 0);
            och2_rtrig          : out std_logic;
            och2_raddr          : out std_logic_vector(31 downto 0);
            och2_rvcnt          : out std_logic_vector(11 downto 0);
            och3_rtrig          : out std_logic;
            och3_raddr          : out std_logic_vector(31 downto 0);
            och3_rvcnt          : out std_logic_vector(11 downto 0);
            och4_rtrig          : out std_logic;
            och4_raddr          : out std_logic_vector(31 downto 0);
            och4_rvcnt          : out std_logic_vector(11 downto 0);

            ostate_ddr_sub      : out tstate_ddr_sub
        );
    end component;

    component AXI_IF is
    generic ( GNR_MODEL : string  := "EXT1616R" );
        port
        (
            -- Write
            ich0_wtrig    : in std_logic;
            ich0_waddr    : in std_logic_vector(31 downto 0);
            ich0_wdata    : in std_logic_vector(511 downto 0);
            ich1_wtrig    : in std_logic;
            ich1_waddr    : in std_logic_vector(31 downto 0);
            ich1_wdata    : in std_logic_vector(511 downto 0);
            ich2_wtrig    : in std_logic;
            ich2_waddr    : in std_logic_vector(31 downto 0);
            ich2_wdata    : in std_logic_vector(511 downto 0);
            ich3_wtrig    : in std_logic;
            ich3_waddr    : in std_logic_vector(31 downto 0);
            ich3_wdata    : in std_logic_vector(511 downto 0);
            ich4_wtrig    : in std_logic;
            ich4_waddr    : in std_logic_vector(31 downto 0);
            ich4_wdata    : in std_logic_vector(511 downto 0);

            -- Read
            ich0_rtrig    : in std_logic;
            ich0_raddr    : in std_logic_vector(31 downto 0);
            ich0_rvcnt    : in std_logic_vector(11 downto 0);
            ich1_rtrig    : in std_logic;
            ich1_raddr    : in std_logic_vector(31 downto 0);
            ich1_rvcnt    : in std_logic_vector(11 downto 0);
            ich2_rtrig    : in std_logic;
            ich2_raddr    : in std_logic_vector(31 downto 0);
            ich2_rvcnt    : in std_logic_vector(11 downto 0);
            ich3_rtrig    : in std_logic;
            ich3_raddr    : in std_logic_vector(31 downto 0);
            ich3_rvcnt    : in std_logic_vector(11 downto 0);
            ich4_rtrig    : in std_logic;
            ich4_raddr    : in std_logic_vector(31 downto 0);
            ich4_rvcnt    : in std_logic_vector(11 downto 0);

            -- From CPU
            iaxi_clk      : in std_logic;
            iaxi_rstn     : in std_logic;
            iaxi_rlast    : in std_logic;
            iaxi_rvalid   : in std_logic;
            iaxi_rready   : in std_logic;
            iaxi_bready   : in std_logic;

            -- size
            ireg_width    : in std_logic_vector(11 downto 0);

            -- For AXI MASTER IF
            oconv_wlen    : out std_logic_vector(7 downto 0);
            oconv_wtrig   : out std_logic;
            oconv_waddr   : out std_logic_vector(31 downto 0);
            oconv_wdata   : out std_logic_vector(511 downto 0);
            iconv_wbusy   : in std_logic;
            oconv_rlen    : out std_logic_vector(7 downto 0);
            oconv_rtrig   : out std_logic;
            oconv_raddr   : out std_logic_vector(31 downto 0);
            iconv_rdata   : in std_logic_vector(511 downto 0);
            oconv_rlast   : out std_logic;
            iconv_rbusy   : in std_logic;

            -- For Output
            iconv_clk     : in std_logic;
            iconv_rstn    : in std_logic;

            iconv_en      : in std_logic;
            iconv_addr    : in std_logic_vector(11 downto 0);
            iconv_vcnt    : in std_logic_vector(11 downto 0);
            oconv_data0   : out std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0);
            oconv_data1   : out std_logic_vector(DDR_BIT_R1( (GNR_MODEL))-1 downto 0);
            oconv_data2   : out std_logic_vector(DDR_BIT_R2( (GNR_MODEL))-1 downto 0);
            oconv_data3   : out std_logic_vector(DDR_BIT_R3( (GNR_MODEL))-1 downto 0);
            oconv_data4   : out std_logic_vector(DDR_BIT_R4( (GNR_MODEL))-1 downto 0);

            ostate_write  : out tstate_write;
            owrite_ch     : out std_logic_vector(4 - 1 downto 0);
            ostate_read   : out tstate_read;
            oread_ch      : out std_logic_vector(4 - 1 downto 0)
        );
    end component;

    component AXI_MASTER_IF is
    generic ( GNR_MODEL : string  := "EXT1616R" );
        port
        (
            iaxi_clk     : in std_logic;
            iaxi_rstn    : in std_logic;

            iconv_wlen   : in std_logic_vector(7 downto 0);
            iconv_wtrig  : in std_logic;
            iconv_waddr  : in std_logic_vector(31 downto 0);
            iconv_wdata  : in std_logic_vector(511 downto 0);
            oconv_wbusy  : out std_logic;
            iconv_rlen   : in std_logic_vector(7 downto 0);
            iconv_rtrig  : in std_logic;
            iconv_raddr  : in std_logic_vector(31 downto 0);
            oconv_rdata  : out std_logic_vector(511 downto 0);
            oconv_rbusy  : out std_logic;

            axi_awid     : out std_logic_vector(3 downto 0);
            axi_awaddr   : out std_logic_vector(31 downto 0);
            axi_awlen    : out std_logic_vector(7 downto 0);
            axi_awsize   : out std_logic_vector(2 downto 0);
            axi_awburst  : out std_logic_vector(1 downto 0);
            axi_awlock   : out std_logic_vector(0 downto 0);
            axi_awvalid  : out std_logic;
            axi_awready  : in std_logic;

            axi_wdata    : out std_logic_vector(511 downto 0);
            axi_wstrb    : out std_logic_vector(63 downto 0);
            axi_wlast    : out std_logic;
            axi_wvalid   : out std_logic;
            axi_wready   : in std_logic;

            axi_bid      : in std_logic_vector(3 downto 0);
            axi_bresp    : in std_logic_vector(1 downto 0);
            axi_bvalid   : in std_logic;
            axi_bready   : out std_logic;

            axi_arid     : out std_logic_vector(3 downto 0);
            axi_araddr   : out std_logic_vector(31 downto 0);
            axi_arlen    : out std_logic_vector(7 downto 0);
            axi_arsize   : out std_logic_vector(2 downto 0);
            axi_arburst  : out std_logic_vector(1 downto 0);
            axi_arlock   : out std_logic_vector(0 downto 0);
            axi_arvalid  : out std_logic;
            axi_arready  : in std_logic;

            axi_rid      : in std_logic_vector(3 downto 0);
            axi_rdata    : in std_logic_vector(511 downto 0);
            axi_rresp    : in std_logic_vector(1 downto 0);
            axi_rlast    : in std_logic;
            axi_rvalid   : in std_logic;
            axi_rready   : out std_logic
        );
    end component;

    signal saxi_awid : std_logic_vector(3 downto 0);
    signal saxi_awaddr : std_logic_vector(31 downto 0);
    signal saxi_awlen : std_logic_vector(7 downto 0);
    signal saxi_awsize : std_logic_vector(2 downto 0);
    signal saxi_awburst : std_logic_vector(1 downto 0);
    signal saxi_awlock : std_logic_vector(0 downto 0);
    signal saxi_awvalid : std_logic;
    signal saxi_awready : std_logic;

    signal saxi_wdata : std_logic_vector(511 downto 0);
    signal saxi_wstrb : std_logic_vector(63 downto 0);
    signal saxi_wlast : std_logic;
    signal saxi_wvalid : std_logic;
    signal saxi_wready : std_logic;

    signal saxi_bid : std_logic_vector(3 downto 0);
    signal saxi_bresp : std_logic_vector(1 downto 0);
    signal saxi_bvalid : std_logic;
    signal saxi_bready : std_logic;

    signal saxi_arid : std_logic_vector(3 downto 0);
    signal saxi_araddr : std_logic_vector(31 downto 0);
    signal saxi_arlen : std_logic_vector(7 downto 0);
    signal saxi_arsize : std_logic_vector(2 downto 0);
    signal saxi_arburst : std_logic_vector(1 downto 0);
    signal saxi_arlock : std_logic_vector(0 downto 0);
    signal saxi_arvalid : std_logic;
    signal saxi_arready : std_logic;

    signal saxi_rid : std_logic_vector(3 downto 0);
    signal saxi_rdata : std_logic_vector(511 downto 0);
    signal saxi_rresp : std_logic_vector(1 downto 0);
    signal saxi_rlast : std_logic;
    signal saxi_rvalid : std_logic;
    signal saxi_rready : std_logic;
    ---------------------------------------------------------

    signal sreg_ddr_out : std_logic_vector(2 downto 0);

    signal sch0_wtrig : std_logic;
    signal sch0_waddr : std_logic_vector(31 downto 0);
    signal sch0_wdata : std_logic_vector(511 downto 0);
    signal sch1_wtrig : std_logic;
    signal sch1_waddr : std_logic_vector(31 downto 0);
    signal sch1_wdata : std_logic_vector(511 downto 0);
    signal sch2_wtrig : std_logic;
    signal sch2_waddr : std_logic_vector(31 downto 0);
    signal sch2_wdata : std_logic_vector(511 downto 0);
    signal sch3_wtrig : std_logic;
    signal sch3_waddr : std_logic_vector(31 downto 0);
    signal sch3_wdata : std_logic_vector(511 downto 0);
    signal sch4_wtrig : std_logic;
    signal sch4_waddr : std_logic_vector(31 downto 0);
    signal sch4_wdata : std_logic_vector(511 downto 0);
    signal sch0_rtrig : std_logic;
    signal sch0_raddr : std_logic_vector(31 downto 0);
    signal sch0_rvcnt : std_logic_vector(11 downto 0);
    signal sch1_rtrig : std_logic;
    signal sch1_raddr : std_logic_vector(31 downto 0);
    signal sch1_rvcnt : std_logic_vector(11 downto 0);
    signal sch2_rtrig : std_logic;
    signal sch2_raddr : std_logic_vector(31 downto 0);
    signal sch2_rvcnt : std_logic_vector(11 downto 0);
    signal sch3_rtrig : std_logic;
    signal sch3_raddr : std_logic_vector(31 downto 0);
    signal sch3_rvcnt : std_logic_vector(11 downto 0);
    signal sch4_rtrig : std_logic;
    signal sch4_raddr : std_logic_vector(31 downto 0);
    signal sch4_rvcnt : std_logic_vector(11 downto 0);

    signal sconv_wlen : std_logic_vector(7 downto 0);
    signal sconv_wtrig : std_logic;
    signal sconv_waddr : std_logic_vector(31 downto 0);
    signal sconv_wdata : std_logic_vector(511 downto 0);
    signal sconv_wbusy : std_logic;
    signal sconv_rlen : std_logic_vector(7 downto 0);
    signal sconv_rtrig : std_logic;
    signal sconv_raddr : std_logic_vector(31 downto 0);
    signal sconv_rlast : std_logic;
    signal sconv_rbusy : std_logic;
    signal sconv_rdata : std_logic_vector(511 downto 0);

    signal sconv_hsync : std_logic;
    signal sconv_vsync : std_logic;
    signal sconv_hcnt : std_logic_vector(11 downto 0);
    signal sconv_vcnt : std_logic_vector(11 downto 0);

    signal shsync_out : std_logic;
    signal svsync_out : std_logic;
    signal shcnt_out : std_logic_vector(11 downto 0);
    signal svcnt_out : std_logic_vector(11 downto 0);
    signal sdata_out : std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0);

    signal sconv_data0 : std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0);
    signal sconv_data1 : std_logic_vector(DDR_BIT_R1( (GNR_MODEL))-1 downto 0);
    signal sconv_data2 : std_logic_vector(DDR_BIT_R2( (GNR_MODEL))-1 downto 0);
    signal sconv_data3 : std_logic_vector(DDR_BIT_R3( (GNR_MODEL))-1 downto 0);
    signal sconv_data4 : std_logic_vector(DDR_BIT_R4( (GNR_MODEL))-1 downto 0);

    signal sch0_rdata : std_logic_vector(DDR_BIT_R0( (GNR_MODEL))-1 downto 0);
    signal sch1_rdata : std_logic_vector(DDR_BIT_R1( (GNR_MODEL))-1 downto 0);
    signal sch2_rdata : std_logic_vector(DDR_BIT_R2( (GNR_MODEL))-1 downto 0);
    signal sch3_rdata : std_logic_vector(DDR_BIT_R3( (GNR_MODEL))-1 downto 0);
    signal sch4_rdata : std_logic_vector(DDR_BIT_R4( (GNR_MODEL))-1 downto 0);

    signal sconv_hsync_1d : std_logic;
    signal sconv_vsync_1d : std_logic;
    signal sconv_hcnt_1d : std_logic_vector(11 downto 0);
    signal sconv_vcnt_1d : std_logic_vector(11 downto 0);

    -- signal saxi_rready : std_logic;
    -- signal saxi_bready : std_logic;

    signal sreg_width_x32 : std_logic_vector(11 downto 0);

    signal sstate_write : tstate_write;
    signal swrite_ch : std_logic_vector(4 - 1 downto 0);
    signal sstate_read : tstate_read;
    signal sread_ch : std_logic_vector(4 - 1 downto 0);

    signal i_data_rstn_sync : std_logic;
begin
    sreg_width_x32 <= (ireg_width(11 downto 5) + (ireg_width(4)
        or ireg_width(3)
        or ireg_width(2)
        or ireg_width(1)
        or ireg_width(0))) & "00000";

i_data_rstn_sync <= idata_rstn and isyncgen_rstn; --# 231117

        U0_DDR3_SYNC_GEN : DDR3_SYNC_GEN
        generic map( GNR_MODEL => GNR_MODEL)
        port map
        (
            idata_clk        => idata_clk,
            idata_rstn       => i_data_rstn_sync, -- idata_rstn and isyncgen_rstn, --# 220910 prevent system down

            ireg_line_time   => ireg_line_time,
            ireg_sd_wen      => ireg_sd_wen,
            ireg_width       => ireg_width,
            ireg_height      => ireg_height,
            
            istate_tftd      => istate_tftd,
            ireq_data        => ireq_data,

            ihsync           => ihsync,
            ivsync           => ivsync,
            ihcnt            => ihcnt,
            ivcnt            => ivcnt,

            ohsync           => sconv_hsync,
            ovsync           => sconv_vsync,
            ohcnt            => sconv_hcnt,
            ovcnt            => sconv_vcnt,

            ostate_sync_ddr  => ostate_sync_ddr
    );

    U0_AXI_SUB_IF : AXI_SUB_IF
    generic map( GNR_MODEL => GNR_MODEL)
    port map
    (
        iui_clk             => iui_clk,
        iui_rstn            => iui_rstn,
        iaxi_clk            => iui_clk,
        iaxi_rstn           => iui_rstn,
        idata_clk           => idata_clk,
        idata_rstn          => idata_rstn,

        ireg_ddr_acc_ch_en  => ireg_ddr_acc_ch_en,
        ireg_ddr_ch_en      => ireg_ddr_ch_en,
        ireg_ddr_base_addr  => ireg_ddr_base_addr,
        ireg_ddr_ch0_waddr  => ireg_ddr_ch0_waddr,
        ireg_ddr_ch1_waddr  => ireg_ddr_ch1_waddr,
        ireg_ddr_ch2_waddr  => ireg_ddr_ch2_waddr,
        ireg_ddr_ch3_waddr  => ireg_ddr_ch3_waddr,
        ireg_ddr_ch4_waddr  => ireg_ddr_ch4_waddr,
        ireg_ddr_ch0_raddr  => ireg_ddr_ch0_raddr,
        ireg_ddr_ch1_raddr  => ireg_ddr_ch1_raddr,
        ireg_ddr_ch2_raddr  => ireg_ddr_ch2_raddr,
        ireg_ddr_ch3_raddr  => ireg_ddr_ch3_raddr,
        ireg_ddr_ch4_raddr  => ireg_ddr_ch4_raddr,

        ireg_width          => sreg_width_x32,
        ireg_height         => ireg_height,

        iaxi_wready         => axi_wready,
        iaxi_bready         => saxi_bready,

        iconv_rlast         => sconv_rlast,
        iconv_hsync         => sconv_hsync,
        iconv_vcnt          => sconv_vcnt,

        ich0_wen            => ich0_wen,
        ich0_waddr          => ich0_waddr,
        ich0_wvcnt          => ich0_wvcnt,
        ich0_wdata          => ich0_wdata,
        ich1_wen            => ich1_wen,
        ich1_waddr          => ich1_waddr,
        ich1_wvcnt          => ich1_wvcnt,
        ich1_wdata          => ich1_wdata,
        ich2_wen            => ich2_wen,
        ich2_waddr          => ich2_waddr,
        ich2_wvcnt          => ich2_wvcnt,
        ich2_wdata          => ich2_wdata,
        id2m_xray           => id2m_xray,
        ich3_wen            => ich3_wen,
        ich3_waddr          => ich3_waddr,
        ich3_wvcnt          => ich3_wvcnt,
        ich3_wdata          => ich3_wdata,
        ich4_wen            => ich4_wen,
        ich4_waddr          => ich4_waddr,
        ich4_wvcnt          => ich4_wvcnt,
        ich4_wdata          => ich4_wdata,

        och0_wtrig          => sch0_wtrig,
        och0_waddr          => sch0_waddr,
        och0_wdata          => sch0_wdata,
        och1_wtrig          => sch1_wtrig,
        och1_waddr          => sch1_waddr,
        och1_wdata          => sch1_wdata,
        och2_wtrig          => sch2_wtrig,
        och2_waddr          => sch2_waddr,
        och2_wdata          => sch2_wdata,
        och3_wtrig          => sch3_wtrig,
        och3_waddr          => sch3_waddr,
        och3_wdata          => sch3_wdata,
        och4_wtrig          => sch4_wtrig,
        och4_waddr          => sch4_waddr,
        och4_wdata          => sch4_wdata,
        och0_rtrig          => sch0_rtrig,
        och0_raddr          => sch0_raddr,
        och0_rvcnt          => sch0_rvcnt,
        och1_rtrig          => sch1_rtrig,
        och1_raddr          => sch1_raddr,
        och1_rvcnt          => sch1_rvcnt,
        och2_rtrig          => sch2_rtrig,
        och2_raddr          => sch2_raddr,
        och2_rvcnt          => sch2_rvcnt,
        och3_rtrig          => sch3_rtrig,
        och3_raddr          => sch3_raddr,
        och3_rvcnt          => sch3_rvcnt,
        och4_rtrig          => sch4_rtrig,
        och4_raddr          => sch4_raddr,
        och4_rvcnt          => sch4_rvcnt
    );
    U0_AXI_IF : AXI_IF
    generic map( GNR_MODEL => GNR_MODEL)
    port map
    (
        -- WRITE
        ich0_wtrig    => sch0_wtrig,
        ich0_waddr    => sch0_waddr,
        ich0_wdata    => sch0_wdata,
        ich1_wtrig    => sch1_wtrig,
        ich1_waddr    => sch1_waddr,
        ich1_wdata    => sch1_wdata,
        ich2_wtrig    => sch2_wtrig,
        ich2_waddr    => sch2_waddr,
        ich2_wdata    => sch2_wdata,
        ich3_wtrig    => sch3_wtrig,
        ich3_waddr    => sch3_waddr,
        ich3_wdata    => sch3_wdata,
        ich4_wtrig    => sch4_wtrig,
        ich4_waddr    => sch4_waddr,
        ich4_wdata    => sch4_wdata,

        -- READ
        ich0_rtrig    => sch0_rtrig,
        ich0_raddr    => sch0_raddr,
        ich0_rvcnt    => sch0_rvcnt,
        ich1_rtrig    => sch1_rtrig,
        ich1_raddr    => sch1_raddr,
        ich1_rvcnt    => sch1_rvcnt,
        ich2_rtrig    => sch2_rtrig,
        ich2_raddr    => sch2_raddr,
        ich2_rvcnt    => sch2_rvcnt,
        ich3_rtrig    => sch3_rtrig,
        ich3_raddr    => sch3_raddr,
        ich3_rvcnt    => sch3_rvcnt,
        ich4_rtrig    => sch4_rtrig,
        ich4_raddr    => sch4_raddr,
        ich4_rvcnt    => sch4_rvcnt,

        -- From CPU
        iaxi_clk      => iui_clk,
        iaxi_rstn     => iui_rstn,
        iaxi_rlast    => axi_rlast,
        iaxi_rvalid   => axi_rvalid,
        iaxi_rready   => saxi_rready,
        iaxi_bready   => saxi_bready,

        ireg_width    => sreg_width_x32,

        -- For AXI MASTER IF
        oconv_wlen    => sconv_wlen,
        oconv_wtrig   => sconv_wtrig,
        oconv_waddr   => sconv_waddr,
        oconv_wdata   => sconv_wdata,
        iconv_wbusy   => sconv_wbusy,
        oconv_rlen    => sconv_rlen,
        oconv_rtrig   => sconv_rtrig,
        oconv_raddr   => sconv_raddr,
        iconv_rdata   => sconv_rdata,
        oconv_rlast   => sconv_rlast,
        iconv_rbusy   => sconv_rbusy,

        -- For Output
        iconv_clk     => idata_clk,
        iconv_rstn    => idata_rstn,

        iconv_en      => sconv_hsync,
        iconv_addr    => sconv_hcnt,
        iconv_vcnt    => sconv_vcnt,
        oconv_data0   => sconv_data0,
        oconv_data1   => sconv_data1,
        oconv_data2   => sconv_data2,
        oconv_data3   => sconv_data3,
        oconv_data4   => sconv_data4,

        ostate_write  => sstate_write,
        owrite_ch     => swrite_ch,
        ostate_read   => sstate_read,
        oread_ch      => sread_ch
    );
    ostate_write_if <= sstate_write;
    ostate_read_if <= sstate_read;

    U0_AXI_MASTER_IF : AXI_MASTER_IF
    generic map( GNR_MODEL => GNR_MODEL)
    port map
    (
        iaxi_clk     => iui_clk,
        iaxi_rstn    => iui_rstn,

        iconv_wlen   => sconv_wlen,
        iconv_wtrig  => sconv_wtrig,
        iconv_waddr  => sconv_waddr,
        iconv_wdata  => sconv_wdata,
        oconv_wbusy  => sconv_wbusy,
        iconv_rlen   => sconv_rlen,
        iconv_rtrig  => sconv_rtrig,
        iconv_raddr  => sconv_raddr,
        oconv_rdata  => sconv_rdata,
        oconv_rbusy  => sconv_rbusy,

        axi_awid     => saxi_awid,
        axi_awaddr   => saxi_awaddr,
        axi_awlen    => saxi_awlen,
        axi_awsize   => saxi_awsize,
        axi_awburst  => saxi_awburst,
        axi_awlock   => saxi_awlock,
        axi_awvalid  => saxi_awvalid,
        axi_awready  => saxi_awready,

        axi_wdata    => saxi_wdata,
        axi_wstrb    => saxi_wstrb,
        axi_wlast    => saxi_wlast,
        axi_wvalid   => saxi_wvalid,
        axi_wready   => saxi_wready,

        axi_bid      => saxi_bid,
        axi_bresp    => saxi_bresp,
        axi_bvalid   => saxi_bvalid,
        axi_bready   => saxi_bready,

        axi_arid     => saxi_arid,
        axi_araddr   => saxi_araddr,
        axi_arlen    => saxi_arlen,
        axi_arsize   => saxi_arsize,
        axi_arburst  => saxi_arburst,
        axi_arlock   => saxi_arlock,
        axi_arvalid  => saxi_arvalid,
        axi_arready  => saxi_arready,

        axi_rid      => saxi_rid,
        axi_rdata    => saxi_rdata,
        axi_rresp    => saxi_rresp,
        axi_rlast    => saxi_rlast,
        axi_rvalid   => saxi_rvalid,
        axi_rready   => saxi_rready
    );
    axi_awid <= saxi_awid; -- out
    axi_awaddr <= saxi_awaddr; -- out
    axi_awlen <= saxi_awlen; -- out
    axi_awsize <= saxi_awsize; -- out
    axi_awburst <= saxi_awburst; -- out
    axi_awlock <= saxi_awlock; -- out
    axi_awvalid <= saxi_awvalid; -- out
    saxi_awready <= axi_awready; -- in

    axi_wdata <= saxi_wdata; -- out
    axi_wstrb <= saxi_wstrb; -- out
    axi_wlast <= saxi_wlast; -- out
    axi_wvalid <= saxi_wvalid; -- out
    saxi_wready <= axi_wready; -- in

    saxi_bid <= axi_bid; -- in
    saxi_bresp <= axi_bresp; -- in
    saxi_bvalid <= axi_bvalid; -- in
    axi_bready <= saxi_bready; -- out

    axi_arid <= saxi_arid; -- out
    axi_araddr <= saxi_araddr; -- out
    axi_arlen <= saxi_arlen; -- out
    axi_arsize <= saxi_arsize; -- out
    axi_arburst <= saxi_arburst; -- out
    axi_arlock <= saxi_arlock; -- out
    axi_arvalid <= saxi_arvalid; -- out
    saxi_arready <= axi_arready; -- in

    saxi_rid <= axi_rid; -- in
    saxi_rdata <= axi_rdata; -- in
    saxi_rresp <= axi_rresp; -- in
    saxi_rlast <= axi_rlast; -- in
    saxi_rvalid <= axi_rvalid; -- in
    axi_rready <= saxi_rready; -- out

    process (idata_clk, idata_rstn)
    begin
        if (idata_rstn = '0') then
            sreg_ddr_out <= (others => '0');
        elsif (idata_clk'EVENT and idata_clk = '1') then
            if (sconv_vsync = '0') then
                sreg_ddr_out <= ireg_ddr_out;
            end if;
        end if;
    end process;
    process (idata_clk, idata_rstn)
        begin
            if (idata_rstn = '0') then
                shsync_out <= '0';
                svsync_out <= '0';
                shcnt_out <= (others => '0');
                svcnt_out <= (others => '0');
                sdata_out <= (others => '0');

                sch0_rdata <= (others => '0');
                sch1_rdata <= (others => '0');
                sch2_rdata <= (others => '0');
                sch3_rdata <= (others => '0');
                sch4_rdata <= (others => '0');
            elsif (idata_clk'EVENT and idata_clk = '1') then
                shsync_out <= sconv_hsync_1d;
                svsync_out <= sconv_vsync_1d;
                shcnt_out <= sconv_hcnt_1d;
                svcnt_out <= sconv_vcnt_1d;

                sch0_rdata <= sconv_data0;
                sch1_rdata <= sconv_data1;
                sch2_rdata <= sconv_data2;
                sch3_rdata <= sconv_data3;
                sch4_rdata <= sconv_data4;

                if (sconv_hsync_1d = '1') then
                    case (sreg_ddr_out) is
                        when "000" => sdata_out <= sconv_data0;
                        when "001" => sdata_out <= sconv_data0;
                        when "010" => sdata_out(15 downto 0) <= sconv_data1(31 downto 16);
                        when "011" => sdata_out(15 downto 0) <= sconv_data1(15 downto 0);
                        when "100" => sdata_out(15 downto 0) <= sconv_data2(31 downto 16);
                        when "101" => sdata_out(15 downto 0) <= sconv_data2(15 downto 0);
                        when others => null;
                    end case;
                else
                    sdata_out <= (others => '0');
                end if;
            end if;
        end process;

        -- axi_rready <= saxi_rready;
        -- axi_bready <= saxi_bready;

        ohsync <= shsync_out;
        ovsync <= svsync_out;
        ohcnt <= shcnt_out;
        ovcnt <= svcnt_out;
        odata <= sdata_out;

        och0_rdata <= sch0_rdata;
        och1_rdata <= sch1_rdata;
        och2_rdata <= sch2_rdata;
        och3_rdata <= sch3_rdata;
        och4_rdata <= sch4_rdata;
        process (idata_clk, idata_rstn)
        begin
            if (idata_rstn = '0') then
                sconv_hsync_1d <= '0';
                sconv_vsync_1d <= '0';
                sconv_hcnt_1d <= (others => '0');
                sconv_vcnt_1d <= (others => '0');
            elsif (idata_clk'EVENT and idata_clk = '1') then
                sconv_hsync_1d <= sconv_hsync;
                sconv_vsync_1d <= sconv_vsync;
                sconv_hcnt_1d <= sconv_hcnt;
                sconv_vcnt_1d <= sconv_vcnt;
            end if;
        end process;

ila_debug_ddr3 : if GEN_ILA_ddr3_top = "ON" generate

component ila_ddr3_topa
    port
    (
    clk : in STD_LOGIC;
    probe0 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe1 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe2 : in STD_LOGIC_VECTOR(9 downto 0);
    probe3 : in STD_LOGIC_VECTOR(11 downto 0);
    probe4 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe5 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe6 : in STD_LOGIC_VECTOR(11 downto 0);
    probe7 : in STD_LOGIC_VECTOR(11 downto 0);
    probe8 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe9 : in STD_LOGIC_VECTOR(11 downto 0);
    probe10 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe11 : in STD_LOGIC_VECTOR(11 downto 0);
    probe12 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe13 : in STD_LOGIC_VECTOR(11 downto 0);
    probe14 : in tstate_write; --STD_LOGIC_VECTOR(2 DOWNTO 0);
    probe15 : in STD_LOGIC_VECTOR(4 downto 0);
    probe16 : in tstate_read; --STD_LOGIC_VECTOR(2 DOWNTO 0);
    probe17 : in STD_LOGIC_VECTOR(4 downto 0);
    probe18 : in STD_LOGIC_VECTOR(3 downto 0);
    probe19 : in STD_LOGIC_VECTOR(7 downto 0);
    probe20 : in STD_LOGIC_VECTOR(2 downto 0);
    probe21 : in STD_LOGIC_VECTOR(1 downto 0);
    probe22 : in STD_LOGIC_VECTOR(0 downto 0);
    probe23 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe24 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe25 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe26 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe27 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe28 : in STD_LOGIC_VECTOR(3 downto 0);
    probe29 : in STD_LOGIC_VECTOR(1 downto 0);
    probe30 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe31 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe32 : in STD_LOGIC_VECTOR(3 downto 0);
    probe33 : in STD_LOGIC_VECTOR(7 downto 0);
    probe34 : in STD_LOGIC_VECTOR(2 downto 0);
    probe35 : in STD_LOGIC_VECTOR(1 downto 0);
    probe36 : in STD_LOGIC_VECTOR(0 downto 0);
    probe37 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe38 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe39 : in STD_LOGIC_VECTOR(3 downto 0);
    probe40 : in STD_LOGIC_VECTOR(1 downto 0);
    probe41 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe42 : in STD_LOGIC; -- _VECTOR(0 DOWNTO 0);
    probe43 : in STD_LOGIC -- _VECTOR(0 DOWNTO 0)
    );
end component;
    signal pmap_5b_0 : STD_LOGIC_VECTOR(5-1 downto 0); --# 231117
    signal pmap_5b_1 : STD_LOGIC_VECTOR(5-1 downto 0);
begin
    pmap_5b_0 <= '0' & swrite_ch;
    pmap_5b_1 <= '0' & sread_ch;
    u_ila_ddr3_topa : ila_ddr3_topa
    port map
    (
        clk      => idata_clk,
        probe0   => ihsync, --
        probe1   => ivsync, --
        probe2   => ihcnt, -- 10
        probe3   => ivcnt, -- 12
        probe4   => sconv_hsync, --
        probe5   => sconv_vsync, --
        probe6   => sconv_hcnt, -- 12
        probe7   => sconv_vcnt, -- 12
        probe8   => sch0_rtrig, --
        probe9   => sch0_rvcnt, -- 12
        probe10  => sch1_rtrig, --
        probe11  => sch1_rvcnt, -- 12
        probe12  => sch2_rtrig, --
        probe13  => sch2_rvcnt, -- 12
        probe14  => sstate_write, -- 3
        probe15  => pmap_5b_0, -- '0' & swrite_ch, -- 5
        probe16  => sstate_read, -- 3
        probe17  => pmap_5b_1, -- '0' & sread_ch, -- 5
        probe18  => saxi_awid, -- 4
        probe19  => saxi_awlen, -- 8
        probe20  => saxi_awsize, -- 3
        probe21  => saxi_awburst, -- 2
        probe22  => saxi_awlock, --
        probe23  => saxi_awvalid, --
        probe24  => saxi_awready, --
        probe25  => saxi_wlast, --
        probe26  => saxi_wvalid, --
        probe27  => saxi_wready, --
        probe28  => saxi_bid, -- 4
        probe29  => saxi_bresp, -- 2
        probe30  => saxi_bvalid, --
        probe31  => saxi_bready, --
        probe32  => saxi_arid, -- 4
        probe33  => saxi_arlen, -- 8
        probe34  => saxi_arsize, -- 3
        probe35  => saxi_arburst, -- 2
        probe36  => saxi_arlock, --
        probe37  => saxi_arvalid, --
        probe38  => saxi_arready, --
        probe39  => saxi_rid, -- 4
        probe40  => saxi_rresp, -- 2
        probe41  => saxi_rlast, --
        probe42  => saxi_rvalid, --
        probe43  => saxi_rready --
    );

end generate ila_debug_ddr3;

end Behavioral;
