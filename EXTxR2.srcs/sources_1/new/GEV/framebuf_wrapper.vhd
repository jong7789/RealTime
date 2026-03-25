library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

ENTITY Framebuf_Wrapper IS
    PORT (
        sys_en          : IN  STD_LOGIC;
        sys_tstamp      : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        sys_irq         : OUT STD_LOGIC;
        s0_axi_aclk    : IN  STD_LOGIC;
        s0_axi_aresetn  : IN  STD_LOGIC;
        s0_axi_awaddr   : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        s0_axi_awprot   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        s0_axi_awvalid  : IN  STD_LOGIC;
        s0_axi_awready  : OUT STD_LOGIC;
        s0_axi_wdata    : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        s0_axi_wstrb    : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        s0_axi_wvalid   : IN  STD_LOGIC;
        s0_axi_wready   : OUT STD_LOGIC;
        s0_axi_bresp    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s0_axi_bvalid   : OUT STD_LOGIC;
        s0_axi_bready   : IN  STD_LOGIC;
        s0_axi_araddr   : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        s0_axi_arprot   : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
        s0_axi_arvalid  : IN  STD_LOGIC;
        s0_axi_arready  : OUT STD_LOGIC;
        s0_axi_rdata    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        s0_axi_rresp    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        s0_axi_rvalid   : OUT STD_LOGIC;
        s0_axi_rready   : IN  STD_LOGIC;
        din_clk         : IN  STD_LOGIC;
        din_rst         : IN  STD_LOGIC;
        din_frame       : IN  STD_LOGIC;
        din_field       : IN  STD_LOGIC;
        din_line        : IN  STD_LOGIC;
        din_trailer     : IN  STD_LOGIC;
        din_width       : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        din_data        : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        din_busy        : OUT STD_LOGIC;
        din_idle        : OUT STD_LOGIC;
        wr_r_rsnd       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_r_bot        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_w_bot        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_w_top        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_w_tstamp     : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_w_bid        : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_w_active     : OUT STD_LOGIC;
        wr_w_drop       : OUT STD_LOGIC;
        wr_d_full       : IN  STD_LOGIC;
        wr_d_start      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_d_len        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        wr_d_tstamp     : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_d_bid        : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        wr_d_trail      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        wr_d_we         : OUT STD_LOGIC;
        rd_r_rsnd       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_r_bot        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_w_bot        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_w_top        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_w_tstamp     : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        rd_w_bid        : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        rd_w_active     : IN  STD_LOGIC;
        rd_w_drop       : IN  STD_LOGIC;
        rd_d_full       : OUT STD_LOGIC;
        rd_d_start      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_d_len        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rd_d_tstamp     : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        rd_d_bid        : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        rd_d_trail      : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        rd_d_we         : IN  STD_LOGIC;
        tx_scc          : IN  STD_LOGIC;
        tx_full         : IN  STD_LOGIC;
        tx_max_len      : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
        tx_write        : OUT STD_LOGIC;
        tx_header       : OUT STD_LOGIC;
        tx_data         : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
        rsnd_req        : IN  STD_LOGIC;
        rsnd_bid        : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
        rsnd_pid_f      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        rsnd_pid_l      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        m0_axi_aclk     : IN  STD_LOGIC;
        m0_axi_aresetn   : IN  STD_LOGIC;
        m0_axi_awid      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m0_axi_awaddr    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m0_axi_awlen     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m0_axi_awsize    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m0_axi_awburst   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m0_axi_awlock    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m0_axi_awcache   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m0_axi_awprot    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m0_axi_awvalid   : OUT STD_LOGIC;
        m0_axi_awready   : IN  STD_LOGIC;
        m0_axi_wdata     : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
        m0_axi_wstrb     : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        m0_axi_wlast     : OUT STD_LOGIC;
        m0_axi_wvalid    : OUT STD_LOGIC;
        m0_axi_wready    : IN  STD_LOGIC;
        m0_axi_bid       : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        m0_axi_bresp     : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        m0_axi_bvalid    : IN  STD_LOGIC;
        m0_axi_bready    : OUT STD_LOGIC;
        m0_axi_arid      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m0_axi_araddr    : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
        m0_axi_arlen     : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        m0_axi_arsize    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m0_axi_arburst   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
        m0_axi_arlock    : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
        m0_axi_arcache   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        m0_axi_arprot    : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
        m0_axi_arvalid   : OUT STD_LOGIC;
        m0_axi_arready   : IN  STD_LOGIC;
        m0_axi_rid       : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
        m0_axi_rdata     : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
        m0_axi_rresp     : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
        m0_axi_rlast     : IN  STD_LOGIC;
        m0_axi_rvalid    : IN  STD_LOGIC;
        m0_axi_rready    : OUT STD_LOGIC
    );
END ENTITY Framebuf_Wrapper;

ARCHITECTURE Behavioral OF Framebuf_Wrapper IS

    -- Component declaration for framebuf_0
    COMPONENT framebuf_0
        PORT (
            sys_en          : IN  STD_LOGIC;
            sys_tstamp      : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            sys_irq         : OUT STD_LOGIC;
            s0_axi_aclk     : IN  STD_LOGIC;
            s0_axi_aresetn   : IN  STD_LOGIC;
            s0_axi_awaddr    : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            s0_axi_awprot    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            s0_axi_awvalid   : IN  STD_LOGIC;
            s0_axi_awready   : OUT STD_LOGIC;
            s0_axi_wdata     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            s0_axi_wstrb     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            s0_axi_wvalid    : IN  STD_LOGIC;
            s0_axi_wready    : OUT STD_LOGIC;
            s0_axi_bresp     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            s0_axi_bvalid    : OUT STD_LOGIC;
            s0_axi_bready    : IN  STD_LOGIC;
            s0_axi_araddr    : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            s0_axi_arprot    : IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
            s0_axi_arvalid   : IN  STD_LOGIC;
            s0_axi_arready   : OUT STD_LOGIC;
            s0_axi_rdata     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            s0_axi_rresp     : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            s0_axi_rvalid    : OUT STD_LOGIC;
            s0_axi_rready    : IN  STD_LOGIC;
            din_clk          : IN  STD_LOGIC;
            din_rst          : IN  STD_LOGIC;
            din_frame        : IN  STD_LOGIC;
            din_field        : IN  STD_LOGIC;
            din_line         : IN  STD_LOGIC;
            din_trailer      : IN  STD_LOGIC;
            din_width        : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
            din_data         : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            din_busy         : OUT STD_LOGIC;
            din_idle         : OUT STD_LOGIC;
            wr_r_rsnd        : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_r_bot         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_w_bot         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_w_top         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_w_tstamp      : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            wr_w_bid         : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            wr_w_active      : OUT STD_LOGIC;
            wr_w_drop        : OUT STD_LOGIC;
            wr_d_full        : IN  STD_LOGIC;
            wr_d_start       : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_d_len         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            wr_d_tstamp      : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            wr_d_bid         : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            wr_d_trail       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            wr_d_we          : OUT STD_LOGIC;
            rd_r_rsnd        : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd_r_bot         : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd_w_bot         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd_w_top         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd_w_tstamp      : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            rd_w_bid         : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            rd_w_active      : IN  STD_LOGIC;
            rd_w_drop        : IN  STD_LOGIC;
            rd_d_full        : OUT STD_LOGIC;
            rd_d_start       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd_d_len         : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            rd_d_tstamp      : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            rd_d_bid         : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            rd_d_trail       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            rd_d_we          : IN  STD_LOGIC;
            tx_scc           : IN  STD_LOGIC;
            tx_full          : IN  STD_LOGIC;
            tx_max_len       : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
            tx_write         : OUT STD_LOGIC;
            tx_header        : OUT STD_LOGIC;
            tx_data          : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
            rsnd_req         : IN  STD_LOGIC;
            rsnd_bid         : IN  STD_LOGIC_VECTOR(63 DOWNTO 0);
            rsnd_pid_f       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            rsnd_pid_l       : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            m0_axi_aclk      : IN  STD_LOGIC;
            m0_axi_aresetn    : IN  STD_LOGIC;
            m0_axi_awid       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m0_axi_awaddr     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m0_axi_awlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            m0_axi_awsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m0_axi_awburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            m0_axi_awlock     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
            m0_axi_awcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m0_axi_awprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m0_axi_awvalid    : OUT STD_LOGIC;
            m0_axi_awready    : IN  STD_LOGIC;
            m0_axi_wdata      : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
            m0_axi_wstrb      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            m0_axi_wlast      : OUT STD_LOGIC;
            m0_axi_wvalid     : OUT STD_LOGIC;
            m0_axi_wready     : IN  STD_LOGIC;
            m0_axi_bid        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            m0_axi_bresp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            m0_axi_bvalid     : IN  STD_LOGIC;
            m0_axi_bready     : OUT STD_LOGIC;
            m0_axi_arid       : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m0_axi_araddr     : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
            m0_axi_arlen      : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            m0_axi_arsize     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m0_axi_arburst    : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
            m0_axi_arlock     : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
            m0_axi_arcache    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            m0_axi_arprot     : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
            m0_axi_arvalid    : OUT STD_LOGIC;
            m0_axi_arready    : IN  STD_LOGIC;
            m0_axi_rid        : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            m0_axi_rdata      : IN  STD_LOGIC_VECTOR(127 DOWNTO 0);
            m0_axi_rresp      : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
            m0_axi_rlast      : IN  STD_LOGIC;
            m0_axi_rvalid     : IN  STD_LOGIC;
            m0_axi_rready     : OUT STD_LOGIC
        );
    END COMPONENT;

BEGIN

    -- Instantiate the component
    u_framebuf_0 : framebuf_0
        PORT MAP (
            sys_en          => sys_en,
            sys_tstamp      => sys_tstamp,
            sys_irq         => sys_irq,
            s0_axi_aclk     => s0_axi_aclk,
            s0_axi_aresetn   => s0_axi_aresetn,
            s0_axi_awaddr    => s0_axi_awaddr,
            s0_axi_awprot    => s0_axi_awprot,
            s0_axi_awvalid   => s0_axi_awvalid,
            s0_axi_awready   => s0_axi_awready,
            s0_axi_wdata     => s0_axi_wdata,
            s0_axi_wstrb     => s0_axi_wstrb,
            s0_axi_wvalid    => s0_axi_wvalid,
            s0_axi_wready    => s0_axi_wready,
            s0_axi_bresp     => s0_axi_bresp,
            s0_axi_bvalid    => s0_axi_bvalid,
            s0_axi_bready    => s0_axi_bready,
            s0_axi_araddr    => s0_axi_araddr,
            s0_axi_arprot    => s0_axi_arprot,
            s0_axi_arvalid   => s0_axi_arvalid,
            s0_axi_arready   => s0_axi_arready,
            s0_axi_rdata     => s0_axi_rdata,
            s0_axi_rresp     => s0_axi_rresp,
            s0_axi_rvalid    => s0_axi_rvalid,
            s0_axi_rready    => s0_axi_rready,
            din_clk          => din_clk,
            din_rst          => din_rst,
            din_frame        => din_frame,
            din_field        => din_field,
            din_line         => din_line,
            din_trailer      => din_trailer,
            din_width        => din_width,
            din_data         => din_data,
            din_busy         => din_busy,
            din_idle         => din_idle,
            wr_r_rsnd        => wr_r_rsnd,
            wr_r_bot         => wr_r_bot,
            wr_w_bot         => wr_w_bot,
            wr_w_top         => wr_w_top,
            wr_w_tstamp      => wr_w_tstamp,
            wr_w_bid         => wr_w_bid,
            wr_w_active      => wr_w_active,
            wr_w_drop        => wr_w_drop,
            wr_d_full        => wr_d_full,
            wr_d_start       => wr_d_start,
            wr_d_len         => wr_d_len,
            wr_d_tstamp      => wr_d_tstamp,
            wr_d_bid         => wr_d_bid,
            wr_d_trail       => wr_d_trail,
            wr_d_we          => wr_d_we,
            rd_r_rsnd        => rd_r_rsnd,
            rd_r_bot         => rd_r_bot,
            rd_w_bot         => rd_w_bot,
            rd_w_top         => rd_w_top,
            rd_w_tstamp      => rd_w_tstamp,
            rd_w_bid         => rd_w_bid,
            rd_w_active      => rd_w_active,
            rd_w_drop        => rd_w_drop,
            rd_d_full        => rd_d_full,
            rd_d_start       => rd_d_start,
            rd_d_len         => rd_d_len,
            rd_d_tstamp      => rd_d_tstamp,
            rd_d_bid         => rd_d_bid,
            rd_d_trail       => rd_d_trail,
            rd_d_we          => rd_d_we,
            tx_scc           => tx_scc,
            tx_full          => tx_full,
            tx_max_len       => tx_max_len,
            tx_write         => tx_write,
            tx_header        => tx_header,
            tx_data          => tx_data,
            rsnd_req         => rsnd_req,
            rsnd_bid         => rsnd_bid,
            rsnd_pid_f       => rsnd_pid_f,
            rsnd_pid_l       => rsnd_pid_l,
            m0_axi_aclk      => m0_axi_aclk,
            m0_axi_aresetn    => m0_axi_aresetn,
            m0_axi_awid       => m0_axi_awid,
            m0_axi_awaddr     => m0_axi_awaddr,
            m0_axi_awlen      => m0_axi_awlen,
            m0_axi_awsize     => m0_axi_awsize,
            m0_axi_awburst    => m0_axi_awburst,
            m0_axi_awlock     => m0_axi_awlock,
            m0_axi_awcache    => m0_axi_awcache,
            m0_axi_awprot     => m0_axi_awprot,
            m0_axi_awvalid    => m0_axi_awvalid,
            m0_axi_awready    => m0_axi_awready,
            m0_axi_wdata      => m0_axi_wdata,
            m0_axi_wstrb      => m0_axi_wstrb,
            m0_axi_wlast      => m0_axi_wlast,
            m0_axi_wvalid     => m0_axi_wvalid,
            m0_axi_wready     => m0_axi_wready,
            m0_axi_bid        => m0_axi_bid,
            m0_axi_bresp      => m0_axi_bresp,
            m0_axi_bvalid     => m0_axi_bvalid,
            m0_axi_bready     => m0_axi_bready,
            m0_axi_arid       => m0_axi_arid,
            m0_axi_araddr     => m0_axi_araddr,
            m0_axi_arlen      => m0_axi_arlen,
            m0_axi_arsize     => m0_axi_arsize,
            m0_axi_arburst    => m0_axi_arburst,
            m0_axi_arlock     => m0_axi_arlock,
            m0_axi_arcache    => m0_axi_arcache,
            m0_axi_arprot     => m0_axi_arprot,
            m0_axi_arvalid    => m0_axi_arvalid,
            m0_axi_arready    => m0_axi_arready,
            m0_axi_rid        => m0_axi_rid,
            m0_axi_rdata      => m0_axi_rdata,
            m0_axi_rresp      => m0_axi_rresp,
            m0_axi_rlast      => m0_axi_rlast,
            m0_axi_rvalid     => m0_axi_rvalid,
            m0_axi_rready     => m0_axi_rready
        );

END Behavioral;
