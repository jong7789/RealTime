library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

ENTITY Xgmac_Wrapper IS
  PORT (
    reset : IN STD_LOGIC;
    ptp_pps : OUT STD_LOGIC;
    ptp_time : OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
    host_clk : IN STD_LOGIC;
    host_opcode : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    host_addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
    host_wr_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    host_rd_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    host_miim_sel : IN STD_LOGIC;
    host_req : IN STD_LOGIC;
    host_miim_rdy : OUT STD_LOGIC;
    host_irq : OUT STD_LOGIC;
    tx_clk_en : OUT STD_LOGIC;
    tx_clk : IN STD_LOGIC;
    tx_dcm_lock : IN STD_LOGIC;
    tx_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    tx_data_valid : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_start : IN STD_LOGIC;
    tx_underrun : IN STD_LOGIC;
    tx_ack : OUT STD_LOGIC;
    tx_ifg_delay : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    tx_pause_req : IN STD_LOGIC;
    tx_pause_val : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    rx_clk_en : OUT STD_LOGIC;
    rx_clk : IN STD_LOGIC;
    rx_dcm_lock : IN STD_LOGIC;
    rx_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    rx_data_valid : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    rx_good_frame : OUT STD_LOGIC;
    rx_bad_frame : OUT STD_LOGIC;
    mdc : OUT STD_LOGIC;
    mdio_in : IN STD_LOGIC;
    mdio_out : OUT STD_LOGIC;
    mdio_tri : OUT STD_LOGIC;
    xgmii_txd : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
    xgmii_txc : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    xgmii_rxd : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
    xgmii_rxc : IN STD_LOGIC_VECTOR(7 DOWNTO 0) 
  );
END ENTITY Xgmac_Wrapper;

ARCHITECTURE Behavioral OF Xgmac_Wrapper IS
  -- Component instantiation for xgmac_0
  COMPONENT xgmac_0
    PORT (
      reset : IN STD_LOGIC;
      ptp_pps : OUT STD_LOGIC;
      ptp_time : OUT STD_LOGIC_VECTOR(79 DOWNTO 0);
      host_clk : IN STD_LOGIC;
      host_opcode : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      host_addr : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
      host_wr_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      host_rd_data : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      host_miim_sel : IN STD_LOGIC;
      host_req : IN STD_LOGIC;
      host_miim_rdy : OUT STD_LOGIC;
      host_irq : OUT STD_LOGIC;
      tx_clk_en : OUT STD_LOGIC;
      tx_clk : IN STD_LOGIC;
      tx_dcm_lock : IN STD_LOGIC;
      tx_data : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      tx_data_valid : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      tx_start : IN STD_LOGIC;
      tx_underrun : IN STD_LOGIC;
      tx_ack : OUT STD_LOGIC;
      tx_ifg_delay : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      tx_pause_req : IN STD_LOGIC;
      tx_pause_val : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      rx_clk_en : OUT STD_LOGIC;
      rx_clk : IN STD_LOGIC;
      rx_dcm_lock : IN STD_LOGIC;
      rx_data : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      rx_data_valid : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      rx_good_frame : OUT STD_LOGIC;
      rx_bad_frame : OUT STD_LOGIC;
      mdc : OUT STD_LOGIC;
      mdio_in : IN STD_LOGIC;
      mdio_out : OUT STD_LOGIC;
      mdio_tri : OUT STD_LOGIC;
      xgmii_txd : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      xgmii_txc : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      xgmii_rxd : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      xgmii_rxc : IN STD_LOGIC_VECTOR(7 DOWNTO 0) 
    );
  END COMPONENT;

BEGIN
  -- Component instantiation
  xgmac_inst: xgmac_0
    PORT MAP (
      reset => reset,
      ptp_pps => ptp_pps,
      ptp_time => ptp_time,
      host_clk => host_clk,
      host_opcode => host_opcode,
      host_addr => host_addr,
      host_wr_data => host_wr_data,
      host_rd_data => host_rd_data,
      host_miim_sel => host_miim_sel,
      host_req => host_req,
      host_miim_rdy => host_miim_rdy,
      host_irq => host_irq,
      tx_clk_en => tx_clk_en,
      tx_clk => tx_clk,
      tx_dcm_lock => tx_dcm_lock,
      tx_data => tx_data,
      tx_data_valid => tx_data_valid,
      tx_start => tx_start,
      tx_underrun => tx_underrun,
      tx_ack => tx_ack,
      tx_ifg_delay => tx_ifg_delay,
      tx_pause_req => tx_pause_req,
      tx_pause_val => tx_pause_val,
      rx_clk_en => rx_clk_en,
      rx_clk => rx_clk,
      rx_dcm_lock => rx_dcm_lock,
      rx_data => rx_data,
      rx_data_valid => rx_data_valid,
      rx_good_frame => rx_good_frame,
      rx_bad_frame => rx_bad_frame,
      mdc => mdc,
      mdio_in => mdio_in,
      mdio_out => mdio_out,
      mdio_tri => mdio_tri,
      xgmii_txd => xgmii_txd,
      xgmii_txc => xgmii_txc,
      xgmii_rxd => xgmii_rxd,
      xgmii_rxc => xgmii_rxc
    );

END Behavioral;
