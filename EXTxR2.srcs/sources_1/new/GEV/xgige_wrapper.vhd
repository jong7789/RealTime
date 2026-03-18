library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use WORK.TOP_HEADER.ALL;

ENTITY Xgige_Wrapper IS
  PORT (
    s0_axi_aclk : IN STD_LOGIC;
    s0_axi_aresetn : IN STD_LOGIC;
    s0_axi_awaddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s0_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s0_axi_awvalid : IN STD_LOGIC;
    s0_axi_awready : OUT STD_LOGIC;
    s0_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s0_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s0_axi_wvalid : IN STD_LOGIC;
    s0_axi_wready : OUT STD_LOGIC;
    s0_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s0_axi_bvalid : OUT STD_LOGIC;
    s0_axi_bready : IN STD_LOGIC;
    s0_axi_araddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s0_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s0_axi_arvalid : IN STD_LOGIC;
    s0_axi_arready : OUT STD_LOGIC;
    s0_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s0_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s0_axi_rvalid : OUT STD_LOGIC;
    s0_axi_rready : IN STD_LOGIC;
    sys_irq : OUT STD_LOGIC;
    sys_net_up : OUT STD_LOGIC;
    sys_uart_bypass : OUT STD_LOGIC;
    sys_gpo : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    sys_type : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    sys_mac_addr : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
    sys_time_stamp : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    action_trigger_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    action_trigger_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    i2c_scl : OUT STD_LOGIC;
    i2c_sda_o : OUT STD_LOGIC;
    i2c_sda_i : IN STD_LOGIC;
    spi_clk : OUT STD_LOGIC;
    spi_cs_n : OUT STD_LOGIC;
    spi_mosi : OUT STD_LOGIC;
    spi_miso : IN STD_LOGIC;
    tx_stm_clk : IN STD_LOGIC;
    mem_clk : IN STD_LOGIC;
    mem_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    mem_header : IN STD_LOGIC;
    mem_write : IN STD_LOGIC;
    mem_full : OUT STD_LOGIC;
    mem_scc : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    mem_max_len : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rsnd_req : OUT STD_LOGIC;
    rsnd_channel : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rsnd_blk_id : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rsnd_first_pkt_id : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rsnd_last_pkt_id : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rx_axis_aclk : IN STD_LOGIC;
    rx_axis_aresetn : IN STD_LOGIC;
    rx_axis_tvalid : OUT STD_LOGIC;
    rx_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rx_axis_tstrb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_axis_tlast : OUT STD_LOGIC;
    rx_axis_tid : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_axis_tuser : OUT STD_LOGIC_VECTOR(99 DOWNTO 0);
    mac_host_req : OUT STD_LOGIC;
    mac_host_miimsel : OUT STD_LOGIC;
    mac_host_opcode : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    mac_host_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    mac_host_wrdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    mac_host_rddata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    mac_host_miimrdy : IN STD_LOGIC;
    mac_tx_clk : IN STD_LOGIC;
    mac_tx_clk_en : IN STD_LOGIC;
    mac_tx_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    mac_tx_data_valid : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    mac_tx_start : OUT STD_LOGIC;
    mac_tx_underrun : OUT STD_LOGIC;
    mac_tx_ack : IN STD_LOGIC;
    mac_rx_clk : IN STD_LOGIC;
    mac_rx_clk_en : IN STD_LOGIC;
    mac_rx_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    mac_rx_data_valid : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    mac_rx_good_frame : IN STD_LOGIC;
    mac_rx_bad_frame : IN STD_LOGIC;
    phy_rst_n : OUT STD_LOGIC 
  );
END ENTITY;

ARCHITECTURE Behavioral OF Xgige_Wrapper IS
  -- Component instantiation for xgige_0
COMPONENT xgige_0
  PORT (
    s0_axi_aclk : IN STD_LOGIC;
    s0_axi_aresetn : IN STD_LOGIC;
    s0_axi_awaddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s0_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s0_axi_awvalid : IN STD_LOGIC;
    s0_axi_awready : OUT STD_LOGIC;
    s0_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s0_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s0_axi_wvalid : IN STD_LOGIC;
    s0_axi_wready : OUT STD_LOGIC;
    s0_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s0_axi_bvalid : OUT STD_LOGIC;
    s0_axi_bready : IN STD_LOGIC;
    s0_axi_araddr : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s0_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s0_axi_arvalid : IN STD_LOGIC;
    s0_axi_arready : OUT STD_LOGIC;
    s0_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s0_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s0_axi_rvalid : OUT STD_LOGIC;
    s0_axi_rready : IN STD_LOGIC;
    sys_irq : OUT STD_LOGIC;
    sys_net_up : OUT STD_LOGIC;
    sys_uart_bypass : OUT STD_LOGIC;
    sys_gpo : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    sys_type : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    sys_mac_addr : OUT STD_LOGIC_VECTOR(47 DOWNTO 0);
    sys_time_stamp : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    action_trigger_in : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    action_trigger_out : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    i2c_scl : OUT STD_LOGIC;
    i2c_sda_o : OUT STD_LOGIC;
    i2c_sda_i : IN STD_LOGIC;
    spi_clk : OUT STD_LOGIC;
    spi_cs_n : OUT STD_LOGIC;
    spi_mosi : OUT STD_LOGIC;
    spi_miso : IN STD_LOGIC;
    tx_stm_clk : IN STD_LOGIC;
    mem_clk : IN STD_LOGIC;
    mem_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    mem_header : IN STD_LOGIC;
    mem_write : IN STD_LOGIC;
    mem_full : OUT STD_LOGIC;
    mem_scc : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    mem_max_len : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    rsnd_req : OUT STD_LOGIC;
    rsnd_channel : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rsnd_blk_id : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rsnd_first_pkt_id : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rsnd_last_pkt_id : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    rx_axis_aclk : IN STD_LOGIC;
    rx_axis_aresetn : IN STD_LOGIC;
    rx_axis_tvalid : OUT STD_LOGIC;
    rx_axis_tdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rx_axis_tstrb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_axis_tlast : OUT STD_LOGIC;
    rx_axis_tid : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
    rx_axis_tuser : OUT STD_LOGIC_VECTOR(99 DOWNTO 0);
    mac_host_req : OUT STD_LOGIC;
    mac_host_miimsel : OUT STD_LOGIC;
    mac_host_opcode : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    mac_host_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    mac_host_wrdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    mac_host_rddata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    mac_host_miimrdy : IN STD_LOGIC;
    mac_tx_clk : IN STD_LOGIC;
    mac_tx_clk_en : IN STD_LOGIC;
    mac_tx_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    mac_tx_data_valid : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    mac_tx_start : OUT STD_LOGIC;
    mac_tx_underrun : OUT STD_LOGIC;
    mac_tx_ack : IN STD_LOGIC;
    mac_rx_clk : IN STD_LOGIC;
    mac_rx_clk_en : IN STD_LOGIC;
    mac_rx_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    mac_rx_data_valid : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    mac_rx_good_frame : IN STD_LOGIC;
    mac_rx_bad_frame : IN STD_LOGIC;
    phy_rst_n : OUT STD_LOGIC 
  );
END COMPONENT;

BEGIN

u_xgige_0 : xgige_0
  PORT MAP (
    s0_axi_aclk => s0_axi_aclk,
    s0_axi_aresetn => s0_axi_aresetn,
    s0_axi_awaddr => s0_axi_awaddr,
    s0_axi_awprot => s0_axi_awprot,
    s0_axi_awvalid => s0_axi_awvalid,
    s0_axi_awready => s0_axi_awready,
    s0_axi_wdata => s0_axi_wdata,
    s0_axi_wstrb => s0_axi_wstrb,
    s0_axi_wvalid => s0_axi_wvalid,
    s0_axi_wready => s0_axi_wready,
    s0_axi_bresp => s0_axi_bresp,
    s0_axi_bvalid => s0_axi_bvalid,
    s0_axi_bready => s0_axi_bready,
    s0_axi_araddr => s0_axi_araddr,
    s0_axi_arprot => s0_axi_arprot,
    s0_axi_arvalid => s0_axi_arvalid,
    s0_axi_arready => s0_axi_arready,
    s0_axi_rdata => s0_axi_rdata,
    s0_axi_rresp => s0_axi_rresp,
    s0_axi_rvalid => s0_axi_rvalid,
    s0_axi_rready => s0_axi_rready,
    sys_irq => sys_irq,
    sys_net_up => sys_net_up,
    sys_uart_bypass => sys_uart_bypass,
    sys_gpo => sys_gpo,
    sys_type => sys_type,
    sys_mac_addr => sys_mac_addr,
    sys_time_stamp => sys_time_stamp,
    action_trigger_in => action_trigger_in,
    action_trigger_out => action_trigger_out,
    i2c_scl => i2c_scl,
    i2c_sda_o => i2c_sda_o,
    i2c_sda_i => i2c_sda_i,
    spi_clk => spi_clk,
    spi_cs_n => spi_cs_n,
    spi_mosi => spi_mosi,
    spi_miso => spi_miso,
    tx_stm_clk => tx_stm_clk,
    mem_clk => mem_clk,
    mem_data => mem_data,
    mem_header => mem_header,
    mem_write => mem_write,
    mem_full => mem_full,
    mem_scc => mem_scc,
    mem_max_len => mem_max_len,
    rsnd_req => rsnd_req,
    rsnd_channel => rsnd_channel,
    rsnd_blk_id => rsnd_blk_id,
    rsnd_first_pkt_id => rsnd_first_pkt_id,
    rsnd_last_pkt_id => rsnd_last_pkt_id,
    rx_axis_aclk => rx_axis_aclk,
    rx_axis_aresetn => rx_axis_aresetn,
    rx_axis_tvalid => rx_axis_tvalid,
    rx_axis_tdata => rx_axis_tdata,
    rx_axis_tstrb => rx_axis_tstrb,
    rx_axis_tlast => rx_axis_tlast,
    rx_axis_tid => rx_axis_tid,
    rx_axis_tuser => rx_axis_tuser,
    mac_host_req => mac_host_req,
    mac_host_miimsel => mac_host_miimsel,
    mac_host_opcode => mac_host_opcode,
    mac_host_addr => mac_host_addr,
    mac_host_wrdata => mac_host_wrdata,
    mac_host_rddata => mac_host_rddata,
    mac_host_miimrdy => mac_host_miimrdy,
    mac_tx_clk => mac_tx_clk,
    mac_tx_clk_en => mac_tx_clk_en,
    mac_tx_data => mac_tx_data,
    mac_tx_data_valid => mac_tx_data_valid,
    mac_tx_start => mac_tx_start,
    mac_tx_underrun => mac_tx_underrun,
    mac_tx_ack => mac_tx_ack,
    mac_rx_clk => mac_rx_clk,
    mac_rx_clk_en => mac_rx_clk_en,
    mac_rx_data => mac_rx_data,
    mac_rx_data_valid => mac_rx_data_valid,
    mac_rx_good_frame => mac_rx_good_frame,
    mac_rx_bad_frame => mac_rx_bad_frame,
    phy_rst_n => phy_rst_n
  );
  
END ARCHITECTURE Behavioral;