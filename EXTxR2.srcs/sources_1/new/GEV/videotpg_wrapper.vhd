library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY videotpg_wrapper IS
  PORT (
    -- Clock and reset signals
    s_axi_aclk    : IN STD_LOGIC;
    s_axi_aresetn : IN STD_LOGIC;

    -- AXI Interface signals
    s_axi_awaddr  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axi_awprot  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_awvalid : IN STD_LOGIC;
    s_axi_awready : OUT STD_LOGIC;

    s_axi_wdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_wstrb   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s_axi_wvalid  : IN STD_LOGIC;
    s_axi_wready  : OUT STD_LOGIC;

    s_axi_bresp   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_bvalid  : OUT STD_LOGIC;
    s_axi_bready  : IN STD_LOGIC;

    s_axi_araddr  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axi_arprot  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s_axi_arvalid : IN STD_LOGIC;
    s_axi_arready : OUT STD_LOGIC;

    s_axi_rdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axi_rresp   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s_axi_rvalid  : OUT STD_LOGIC;
    s_axi_rready  : IN STD_LOGIC;

    -- Additional signals
    gpio_in       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    gpio_out      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    gev_scc       : IN STD_LOGIC;
    fb_clk        : IN STD_LOGIC;
    fb_rst        : IN STD_LOGIC;
    fb_frame      : OUT STD_LOGIC;
    fb_dv         : OUT STD_LOGIC;
    fb_data       : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    fb_width      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
  );
END ENTITY videotpg_wrapper;

ARCHITECTURE Behavioral OF videotpg_wrapper IS
  -- Instantiate the component
  COMPONENT videotpg_0
    PORT (
      s_axi_aclk    : IN STD_LOGIC;
      s_axi_aresetn : IN STD_LOGIC;
      s_axi_awaddr  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      s_axi_awprot  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_axi_awvalid : IN STD_LOGIC;
      s_axi_awready : OUT STD_LOGIC;
      s_axi_wdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axi_wstrb   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_axi_wvalid  : IN STD_LOGIC;
      s_axi_wready  : OUT STD_LOGIC;
      s_axi_bresp   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_bvalid  : OUT STD_LOGIC;
      s_axi_bready  : IN STD_LOGIC;
      s_axi_araddr  : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      s_axi_arprot  : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s_axi_arvalid : IN STD_LOGIC;
      s_axi_arready : OUT STD_LOGIC;
      s_axi_rdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_axi_rresp   : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s_axi_rvalid  : OUT STD_LOGIC;
      s_axi_rready  : IN STD_LOGIC;
      gpio_in       : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      gpio_out      : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      gev_scc       : IN STD_LOGIC;
      fb_clk        : IN STD_LOGIC;
      fb_rst        : IN STD_LOGIC;
      fb_frame      : OUT STD_LOGIC;
      fb_dv         : OUT STD_LOGIC;
      fb_data       : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      fb_width      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
  END COMPONENT;

  -- Connect the component to the signals
  SIGNAL internal_fb_data : STD_LOGIC_VECTOR(63 DOWNTO 0);

BEGIN
  -- Instantiate the component
  U1: videotpg_0
    PORT MAP (
      s_axi_aclk    => s_axi_aclk,
      s_axi_aresetn => s_axi_aresetn,
      s_axi_awaddr  => s_axi_awaddr,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      s_axi_wdata   => s_axi_wdata,
      s_axi_wstrb   => s_axi_wstrb,
      s_axi_wvalid  => s_axi_wvalid,
      s_axi_wready  => s_axi_wready,
      s_axi_bresp   => s_axi_bresp,
      s_axi_bvalid  => s_axi_bvalid,
      s_axi_bready  => s_axi_bready,
      s_axi_araddr  => s_axi_araddr,
      s_axi_arprot  => s_axi_arprot,
      s_axi_arvalid => s_axi_arvalid,
      s_axi_arready => s_axi_arready,
      s_axi_rdata   => s_axi_rdata,
      s_axi_rresp   => s_axi_rresp,
      s_axi_rvalid  => s_axi_rvalid,
      s_axi_rready  => s_axi_rready,
      gpio_in       => gpio_in,
      gpio_out      => gpio_out,
      gev_scc       => gev_scc,
      fb_clk        => fb_clk,
      fb_rst        => fb_rst,
      fb_frame      => fb_frame,
      fb_dv         => fb_dv,
      fb_data       => internal_fb_data,
      fb_width      => fb_width
    );

  -- Connect internal signal to the actual output signal
  fb_data <= internal_fb_data;

END Behavioral;
