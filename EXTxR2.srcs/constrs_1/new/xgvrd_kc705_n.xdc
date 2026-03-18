################################################################################
#  10GigE Vision Reference Design                                              #
#------------------------------------------------------------------------------#
#  Module :  CONSTRAINTS                                                       #
#    File :  xgvrd_kc705.xdc                                                   #
#    Date :  2019-09-03                                                        #
#     Rev :  0.2                                                               #
#  Author :  JP                                                                #
#------------------------------------------------------------------------------#
#  Xilinx design constraints for the Kintex-7 10GigE Vision reference design   #
#  based on the Xilinx KC705 development board                                 #
#------------------------------------------------------------------------------#
#  0.1  |  2015-01-23  |  JP  |  Initial release                               #
#  0.2  |  2019-09-03  |  YH  |  Timing constraints updated for new IP cores   #
################################################################################


## Physical constraints ########################################################

# Configuration options
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

# External reset
set_property PACKAGE_PIN AB7         [get_ports ext_rst]
set_property IOSTANDARD  LVCMOS15    [get_ports ext_rst]

# Clock inputs
set_property PACKAGE_PIN AD12        [get_ports ext_clk_p]
set_property PACKAGE_PIN AD11        [get_ports ext_clk_n]
set_property IOSTANDARD  DIFF_SSTL15 [get_ports {ext_clk_p ext_clk_n}]

# USB UART interface
set_property PACKAGE_PIN M19      [get_ports uart_rxd]
set_property PACKAGE_PIN K24      [get_ports uart_txd]
set_property IOSTANDARD  LVCMOS25 [get_ports {uart_rxd uart_txd}]

# KC705 I2C bus to the I2C multiplexer
#set_property PACKAGE_PIN L21      [get_ports i2c_sda]
#set_property PACKAGE_PIN K21      [get_ports i2c_scl]
#set_property IOSTANDARD  LVCMOS25 [get_ports {i2c_sda i2c_scl}]

# FPGA cooling fan
set_property PACKAGE_PIN L26      [get_ports fan_pwm]
set_property PACKAGE_PIN U22      [get_ports fan_tach]
set_property IOSTANDARD  LVCMOS25 [get_ports {fan_pwm fan_tach}]

# GPIO LEDs
set_property PACKAGE_PIN AB8      [get_ports gpio_led[0]]
set_property PACKAGE_PIN AA8      [get_ports gpio_led[1]]
set_property PACKAGE_PIN AC9      [get_ports gpio_led[2]]
set_property PACKAGE_PIN AB9      [get_ports gpio_led[3]]
set_property PACKAGE_PIN AE26     [get_ports gpio_led[4]]
set_property PACKAGE_PIN G19      [get_ports gpio_led[5]]
set_property PACKAGE_PIN E18      [get_ports gpio_led[6]]
set_property PACKAGE_PIN F16      [get_ports gpio_led[7]]
set_property IOSTANDARD  LVCMOS15 [get_ports {gpio_led[0] gpio_led[1] gpio_led[2] gpio_led[3]}]
set_property IOSTANDARD  LVCMOS25 [get_ports {gpio_led[4] gpio_led[5] gpio_led[6] gpio_led[7]}]
set_property SLEW        SLOW     [get_ports {gpio_led[*]}]
set_property DRIVE       12       [get_ports {gpio_led[*]}]

#GPIO DIP SW
set_property PACKAGE_PIN Y28      [get_ports {gpio_dip_sw[0]}]
set_property PACKAGE_PIN AA28     [get_ports {gpio_dip_sw[1]}]
set_property PACKAGE_PIN W29      [get_ports {gpio_dip_sw[2]}]
set_property PACKAGE_PIN Y29      [get_ports {gpio_dip_sw[3]}]
set_property IOSTANDARD LVCMOS25  [get_ports {gpio_dip_sw[*]}]

# SPI flash
set_property PACKAGE_PIN U19      [get_ports spi_cs0_n]
set_property PACKAGE_PIN P24      [get_ports spi_mosi]
set_property PACKAGE_PIN R25      [get_ports spi_miso]
set_property IOSTANDARD  LVCMOS25 [get_ports {spi_cs0_n spi_mosi spi_miso}]
#set_property PULLUP      TRUE     [get_ports spi_miso]

# PHY FMC GTX reference clock
set_property PACKAGE_PIN C8       [get_ports ref_clk_p]
set_property PACKAGE_PIN C7       [get_ports ref_clk_n]

# PHY FMC XAUI
set_property PACKAGE_PIN D2       [get_ports rxaui_tx_l0_p]
set_property PACKAGE_PIN D1       [get_ports rxaui_tx_l0_n]
set_property PACKAGE_PIN C4       [get_ports rxaui_tx_l1_p]
set_property PACKAGE_PIN C3       [get_ports rxaui_tx_l1_n]
#set_property PACKAGE_PIN B2       [get_ports xaui_tx_l2_p]
#set_property PACKAGE_PIN B1       [get_ports xaui_tx_l2_n]
#set_property PACKAGE_PIN A4       [get_ports xaui_tx_l3_p]
#set_property PACKAGE_PIN A3       [get_ports xaui_tx_l3_n]
set_property PACKAGE_PIN E4       [get_ports rxaui_rx_l0_p]
set_property PACKAGE_PIN E3       [get_ports rxaui_rx_l0_n]
set_property PACKAGE_PIN D6       [get_ports rxaui_rx_l1_p]
set_property PACKAGE_PIN D5       [get_ports rxaui_rx_l1_n]
#set_property PACKAGE_PIN B6       [get_ports xaui_rx_l2_p]
#set_property PACKAGE_PIN B5       [get_ports xaui_rx_l2_n]
#set_property PACKAGE_PIN A8       [get_ports xaui_rx_l3_p]
#set_property PACKAGE_PIN A7       [get_ports xaui_rx_l3_n]

# PHY FMC MDIO
set_property PACKAGE_PIN H25      [get_ports fmc_mdio]
set_property PACKAGE_PIN H24      [get_ports fmc_mdc]
set_property IOSTANDARD  LVCMOS25 [get_ports {fmc_mdio fmc_mdc}]

# PHY FMC I2C
set_property PACKAGE_PIN B30      [get_ports fmc_sda]
set_property PACKAGE_PIN A30      [get_ports fmc_scl]
set_property IOSTANDARD  LVCMOS25 [get_ports {fmc_sda fmc_scl}]

# PHY FMC reset, clock, interrupt
set_property PACKAGE_PIN H26      [get_ports fmc_reset_n]
set_property PACKAGE_PIN E28      [get_ports fmc_clk_fpga_p]
set_property PACKAGE_PIN D28      [get_ports fmc_clk_fpga_n]
set_property PACKAGE_PIN E29      [get_ports fmc_clk_sel]
set_property PACKAGE_PIN H27      [get_ports fmc_int_n]
set_property PACKAGE_PIN D27      [get_ports fmc_rclk]
set_property IOSTANDARD  LVCMOS25 [get_ports {fmc_reset_n fmc_int_n fmc_clk_sel fmc_clk_fpga_p fmc_clk_fpga_n fmc_rclk}]

# PHY FMC GPIO
set_property PACKAGE_PIN D29      [get_ports fmc_gpio[0]]
set_property PACKAGE_PIN C30      [get_ports fmc_gpio[1]]
set_property PACKAGE_PIN B28      [get_ports fmc_gpio[2]]
set_property PACKAGE_PIN A28      [get_ports fmc_gpio[3]]
set_property PACKAGE_PIN F21      [get_ports fmc_gpio[4]]
set_property PACKAGE_PIN E21      [get_ports fmc_gpio[5]]
set_property PACKAGE_PIN G28      [get_ports fmc_phy_gpio[0]]
set_property PACKAGE_PIN F28      [get_ports fmc_phy_gpio[1]]
set_property PACKAGE_PIN F20      [get_ports fmc_phy_gpio[2]]
set_property PACKAGE_PIN F30      [get_ports fmc_phy_gpio[3]]
set_property PACKAGE_PIN H30      [get_ports fmc_phy_gpio[4]]
set_property PACKAGE_PIN G30      [get_ports fmc_phy_gpio[5]]
set_property IOSTANDARD  LVCMOS25 [get_ports {fmc_gpio[*] fmc_phy_gpio[*]}]


## Timing constraints ##########################################################

# RXAUI bridge asynchronous paths
set_max_delay -to [get_pins RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r1_reg/S] 6.4
set_max_delay -to [get_pins RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r2_reg/S] 6.4
set_max_delay -to [get_pins RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r3_reg/S] 6.4
set_property ASYNC_REG true [get_cells RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r1_reg]
set_property ASYNC_REG true [get_cells RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r2_reg]
set_property ASYNC_REG true [get_cells RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r3_reg]

set_max_delay -to [get_pins {RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXPD[*]}]     6.4
set_max_delay -to [get_pins {RXAUI_INST/U0/rxaui_block_i/gt1_wrapper_i/gtxe2_i/TXPD[*]}]     6.4
set_max_delay -to [get_pins {RXAUI_INST/U0/rxaui_block_i/uclk_sync_counter_reg[*]/R}]        6.4
set_max_delay -to [get_pins {*rxaui_rst_cnt_reg[*]/CE}]                                      6.4
set_max_delay -to [get_pins {*rxaui_rst_cnt_reg[*]/PRE}]                                     6.4
set_max_delay -to [get_pins rxaui_rst_reg/PRE]                                               6.4

set_max_delay -datapath_only -from [get_pins rxaui_rst_reg/C] -to [get_pins RXAUI_INST/U0/rxaui_block_i/mgt_powerdown_r_reg/D]            6.4
set_max_delay -datapath_only -from [get_pins rxaui_rst_reg/C] -to [get_pins RXAUI_INST/U0/rxaui_block_i/uclk_mgt_powerdown_falling_reg/D] 6.4


# Asynchronous inputs
set_false_path -from [get_ports ext_rst]
