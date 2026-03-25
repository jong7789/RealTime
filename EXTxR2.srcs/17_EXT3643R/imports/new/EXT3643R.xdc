##################################################################################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CONFIG_MODE SPIx1 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 1 [current_design]
set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE [current_design]
##### golden image #####;
# golden 1st image should be version 99
#set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 0xF000000 [current_design]
#########################
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.TIMER_CFG 32'h00100000 [current_design]
##################################################################################
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

# █▀█ █▀█ █ █▀▀
# █▀▄ █▄█ █ █▄▄ %roic
# BANK 13 & 15(2.5V, ROIC)
# DCLK
set_property PACKAGE_PIN R22 [get_ports {ROIC_DCLK_P[0]}]
set_property PACKAGE_PIN P23 [get_ports {ROIC_DCLK_P[1]}]
set_property PACKAGE_PIN N21 [get_ports {ROIC_DCLK_P[2]}]
set_property PACKAGE_PIN E18 [get_ports {ROIC_DCLK_P[3]}]
set_property PACKAGE_PIN F17 [get_ports {ROIC_DCLK_P[4]}]
# FCLK
set_property PACKAGE_PIN R21 [get_ports {ROIC_FCLK_P[0]}]
# DOUT
set_property PACKAGE_PIN T24 [get_ports {ROIC_DOUT_P[0]}]
set_property PACKAGE_PIN T22 [get_ports {ROIC_DOUT_P[1]}]
set_property PACKAGE_PIN R26 [get_ports {ROIC_DOUT_P[2]}]
set_property PACKAGE_PIN R25 [get_ports {ROIC_DOUT_P[3]}]
set_property PACKAGE_PIN M21 [get_ports {ROIC_DOUT_P[4]}]
set_property PACKAGE_PIN N19 [get_ports {ROIC_DOUT_P[5]}]
set_property PACKAGE_PIN N26 [get_ports {ROIC_DOUT_P[6]}]
set_property PACKAGE_PIN M25 [get_ports {ROIC_DOUT_P[7]}]
set_property PACKAGE_PIN K25 [get_ports {ROIC_DOUT_P[8]}]
set_property PACKAGE_PIN C19 [get_ports {ROIC_DOUT_P[9]}]
set_property PACKAGE_PIN C17 [get_ports {ROIC_DOUT_P[10]}]
set_property PACKAGE_PIN B17 [get_ports {ROIC_DOUT_P[11]}]
set_property PACKAGE_PIN C16 [get_ports {ROIC_DOUT_P[12]}]
set_property PACKAGE_PIN E15 [get_ports {ROIC_DOUT_P[13]}]
# SPI
set_property PACKAGE_PIN H21 [get_ports {F_ROIC_SDO[0]}]
set_property PACKAGE_PIN J25 [get_ports {F_ROIC_SDI[0]}]
set_property PACKAGE_PIN F23 [get_ports {F_ROIC_MCLK[0]}]
set_property PACKAGE_PIN F25 [get_ports {F_ROIC_SYNC[0]}]
set_property PACKAGE_PIN E25 [get_ports {F_ROIC_TP_SEL[0]}]
set_property PACKAGE_PIN F22 [get_ports {F_ROIC_SCLK[0]}]
set_property PACKAGE_PIN J26 [get_ports {F_ROIC_CS[0]}]

# █▀▀ ▄▀█ ▀█▀ █▀▀
# █▄█ █▀█ ░█░ ██▄ %gate
# BANK 14 & 16 (3.3V, GATE)
# CPV
set_property PACKAGE_PIN A12 [get_ports GATE_SHIFT_CLK1L];       #CPV1
set_property PACKAGE_PIN B11 [get_ports GATE_SHIFT_CLK2L];       #CPV2
set_property PACKAGE_PIN G11 [get_ports GATE_SHIFT_CLK1R];       ##### no use
set_property PACKAGE_PIN F10 [get_ports GATE_SHIFT_CLK2R];       ##### no use
# DIO1
set_property PACKAGE_PIN B15 [get_ports {GATE_START_PULSE1[0]}]; #DIO1_1
set_property PACKAGE_PIN A15 [get_ports {GATE_START_PULSE1[1]}]; #DIO1_2
set_property PACKAGE_PIN B20 [get_ports {GATE_START_PULSE1[2]}]; #DIO1_3
set_property PACKAGE_PIN A20 [get_ports {GATE_START_PULSE1[3]}]; #DIO1_4
set_property PACKAGE_PIN B21 [get_ports {GATE_START_PULSE1[4]}]; #DIO1_5
set_property PACKAGE_PIN C21 [get_ports {GATE_START_PULSE1[5]}]; #DIO1_6
set_property PACKAGE_PIN A23 [get_ports {GATE_START_PULSE1[6]}]; #DIO1_7
set_property PACKAGE_PIN A24 [get_ports {GATE_START_PULSE1[7]}]; #DIO1_8
set_property PACKAGE_PIN C22 [get_ports {GATE_START_PULSE1[8]}]; #DIO1_9
# DIO2
set_property PACKAGE_PIN D25 [get_ports {GATE_START_PULSE2[0]}]; #DIO2_1
set_property PACKAGE_PIN D21 [get_ports {GATE_START_PULSE2[1]}]; #DIO2_2
set_property PACKAGE_PIN E22 [get_ports {GATE_START_PULSE2[2]}]; #DIO2_3
set_property PACKAGE_PIN E21 [get_ports {GATE_START_PULSE2[3]}]; #DIO2_4
set_property PACKAGE_PIN E23 [get_ports {GATE_START_PULSE2[4]}]; #DIO2_5
set_property PACKAGE_PIN G22 [get_ports {GATE_START_PULSE2[5]}]; #DIO2_6
set_property PACKAGE_PIN H22 [get_ports {GATE_START_PULSE2[6]}]; #DIO2_7
set_property PACKAGE_PIN B9  [get_ports {GATE_START_PULSE2[7]}]; #DIO2_8
set_property PACKAGE_PIN A9  [get_ports {GATE_START_PULSE2[8]}]; #DIO2_9
# GOE
set_property PACKAGE_PIN A10 [get_ports GATE_OUT_EN1L];          #GOE1
set_property PACKAGE_PIN C9  [get_ports GATE_OUT_EN2L];          #GOE2
set_property PACKAGE_PIN G9  [get_ports GATE_OUT_EN1R];          ##### no use
set_property PACKAGE_PIN J13 [get_ports GATE_OUT_EN2R];          ##### no use
# XON
set_property PACKAGE_PIN B12 [get_ports GATE_ALL_OUT];           #XON
set_property PACKAGE_PIN J10 [get_ports GATE_ALL_OUT_R];         ##### no use
# IND
set_property PACKAGE_PIN A13 [get_ports {GATE_CONFIG[0]}];       #IND
set_property PACKAGE_PIN G14 [get_ports {GATE_CONFIG[1]}];       ##### no use
set_property PACKAGE_PIN H12 [get_ports {GATE_CONFIG[2]}];       ##### no use

set_property PACKAGE_PIN C13 [get_ports GATE_VGH_RST];           #VGH_FLK

# █▀▀ ▀█▀ █▀▀
# ██▄ ░█░ █▄▄
# CLK
set_property PACKAGE_PIN AA10 [get_ports SYSTEM_CLK_P];          #SYS_CLK
# PWR
set_property PACKAGE_PIN H26 [get_ports {PWR_EN[0]}];            #VBIAS_EN
set_property PACKAGE_PIN D14 [get_ports {PWR_EN[1]}];            #VGH_EN
set_property PACKAGE_PIN A8  [get_ports {PWR_EN[2]}];            #GATE_3V3
set_property PACKAGE_PIN D13 [get_ports {PWR_EN[3]}];            #VGL_EN
set_property PACKAGE_PIN J21 [get_ports {PWR_EN[4]}];            #ROIC_EN
set_property PACKAGE_PIN H24 [get_ports {PWR_EN[5]}];            #AVDD_EN
set_property PACKAGE_PIN J24 [get_ports {PWR_EN[6]}];            #VBIAS_SW
# EXT
set_property PACKAGE_PIN H23 [get_ports EXT_IN];                 #READY_IN_C
set_property PACKAGE_PIN K23 [get_ports EXT_OUT];                #READY_OUT_C
set_property PACKAGE_PIN J23 [get_ports EXP_IN];                 #EXPOSURE_IN_C
# COMMON
set_property PACKAGE_PIN B24 [get_ports {FLASH_D[0]}];           #FLASH_D0
set_property PACKAGE_PIN A25 [get_ports {FLASH_D[1]}];           #FLASH_D1
set_property PACKAGE_PIN B22 [get_ports {FLASH_D[2]}];           #FLASH_D2
set_property PACKAGE_PIN A22 [get_ports {FLASH_D[3]}];           #FLASH_D3
set_property PACKAGE_PIN C23 [get_ports FLASH_FCS];              #FLASH_FCS
set_property PACKAGE_PIN B26 [get_ports EEPROM_SDA];             #EEPROM_SDA
set_property PACKAGE_PIN C26 [get_ports EEPROM_SCL];             #EEPROM_SCL
set_property PACKAGE_PIN G24 [get_ports TEMP_SDA];               #TEMP_SDA
set_property PACKAGE_PIN F24 [get_ports TEMP_SCL];               #TEMP_SCL
set_property PACKAGE_PIN D23 [get_ports UART_TX];                #UART_TX
set_property PACKAGE_PIN D24 [get_ports UART_RX];                #UART_RX
# LED
set_property PACKAGE_PIN F8  [get_ports {STATUS_LED[0]}];        #FAULT_STATUS_LED
set_property PACKAGE_PIN C24 [get_ports {STATUS_LED[1]}];        #FPGA_STATUS_LED
# PHY
set_property PACKAGE_PIN P2  [get_ports {PHY_SIP[0]}]
set_property PACKAGE_PIN M2  [get_ports {PHY_SIP[1]}]
#set_property PACKAGE_PIN M2  [get_ports {PHY_SIP[2]}]
#set_property PACKAGE_PIN M2  [get_ports {PHY_SIP[3]}]
set_property PACKAGE_PIN H6  [get_ports PHY_CLK_P]
set_property PACKAGE_PIN D8  [get_ports PHY_RESET_N]
set_property PACKAGE_PIN D9  [get_ports PHY_MDC]
set_property PACKAGE_PIN B10 [get_ports PHY_MDIO]

set_property PACKAGE_PIN E26 [get_ports F_GPIO1];                #TP9
set_property PACKAGE_PIN G25 [get_ports F_GPIO2];                #TP10
set_property PACKAGE_PIN G26 [get_ports F_GPIO3];                #TP11
set_property PACKAGE_PIN D26 [get_ports F_GPIO4];                #TP54
# SFP
#set_property PACKAGE_PIN E10 [get_ports SFP_SDA];                #SFP_I2C_SDA
#set_property PACKAGE_PIN D10 [get_ports SFP_SCL];                #SFP_I2C_SCL
#set_property PACKAGE_PIN E11 [get_ports SFP_LOS];                #SFP_LOS
#set_property PACKAGE_PIN D11 [get_ports SFP_DISABLE];            #SFP_TX_DISABLE
#set_property PACKAGE_PIN F2  [get_ports SFP_TX_P];               #SFP_TX_P
#set_property PACKAGE_PIN F1  [get_ports SFP_TX_N];               #SFP_TX_N

# █ █▀█
# █ █▄█
#############################################
# Pin Descriptions
#############################################
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO1]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO2]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO3]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO4]

set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports FLASH_FCS]
set_property IOSTANDARD LVCMOS33 [get_ports EEPROM_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports EEPROM_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports TEMP_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports TEMP_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]

set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK1L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK2L]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[8]}]

set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[8]}]

set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN1L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN2L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_ALL_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_ALL_OUT_R]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_VGH_RST]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {STATUS_LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {STATUS_LED[1]}]

set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[6]}]

set_property IOSTANDARD LVCMOS33 [get_ports EXT_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports EXT_IN]
set_property IOSTANDARD LVCMOS33 [get_ports EXP_IN]
set_property IOSTANDARD LVCMOS33 [get_ports PHY_RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports PHY_MDC]
set_property IOSTANDARD LVCMOS33 [get_ports PHY_MDIO]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_MCLK[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SYNC[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_TP_SEL[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SCLK[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_CS[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SDI[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SDO[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SDO[1]}]

set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[4]}]

set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[0]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[1]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[5]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[6]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[7]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[8]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[9]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[9]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[10]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[10]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[11]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[11]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[12]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[12]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_P[13]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DOUT_N[13]}]

# BANK 33 (1.5V, DDR3)
set_property IOSTANDARD DIFF_SSTL15 [get_ports SYSTEM_CLK_P]
#############################################
# Unused Pins
#############################################

set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK1R]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK2R]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN1R]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN2R]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2]
set_property IO_BUFFER_TYPE NONE [get_ports tb_aligndone]
set_property IO_BUFFER_TYPE NONE [get_ports tb_alignreq]
#set_property IOSTANDARD LVCMOS33 [get_ports SFP_SDA]
#set_property IOSTANDARD LVCMOS33 [get_ports SFP_SCL]
#set_property IOSTANDARD LVCMOS33 [get_ports SFP_LOS]
#set_property IOSTANDARD LVCMOS33 [get_ports SFP_DISABLE]
#set_property IO_BUFFER_TYPE NONE [get_ports SFP_TX_P]
#set_property IO_BUFFER_TYPE NONE [get_ports SFP_TX_N]


# SFP+ interface
set_property PACKAGE_PIN D6 [get_ports sfp_ref_clk_p[0]]
set_property PACKAGE_PIN G3 [get_ports sfp_rx_n[0]]
set_property PACKAGE_PIN G4 [get_ports sfp_rx_p[0]]
set_property PACKAGE_PIN F1 [get_ports sfp_tx_n[0]]
set_property PACKAGE_PIN F2 [get_ports sfp_tx_p[0]]
set_property PACKAGE_PIN E11 [get_ports sfp_los[0]]
set_property PACKAGE_PIN D11 [get_ports sfp_tx_dis_n[0]]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_los[0]]
set_property IOSTANDARD LVCMOS33 [get_ports sfp_tx_dis_n[0]]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets GEV_RXAUI/U1/U0/rxaui_gt_common_i/qplloutclk_out]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets GEV_RXAUI/U1/U0/rxaui_block_i/rxaui_cl_clocking_i/clk156_bufh_i_0]

# ▀█▀ █ █▀▄▀█ █▀▀
# ░█░ █ █░▀░█ ██▄
create_clock -period 5.000 [get_ports SYSTEM_CLK_P]
create_clock -period 2.778 -name ROIC_DCLK_P0 [get_ports {ROIC_DCLK_P[0]}]
create_clock -period 2.778 -name ROIC_DCLK_P1 [get_ports {ROIC_DCLK_P[1]}]
create_clock -period 2.778 -name ROIC_DCLK_P2 [get_ports {ROIC_DCLK_P[2]}]
create_clock -period 2.778 -name ROIC_DCLK_P3 [get_ports {ROIC_DCLK_P[3]}]
create_clock -period 2.778 -name ROIC_DCLK_P4 [get_ports {ROIC_DCLK_P[4]}]

set_clock_groups -asynchronous -group [get_clocks ROIC_DCLK_P0] -group [get_clocks ROIC_DCLK_P1] -group [get_clocks ROIC_DCLK_P2] -group [get_clocks ROIC_DCLK_P3] -group [get_clocks ROIC_DCLK_P4]


##########################################
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sroic_dclk_0]
# set input delay (per-DCLK, rising + falling edge, P + N)

# RXAUI bridge asynchronous paths
# set_false_path
set_false_path -from [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/DDR_RSTN_GEN/srstn_reg/C]
## Clock Domain Crossing - async clock groups (replaces individual set_false_path)
set_clock_groups -asynchronous \
  -group [get_clocks clk_out1_PLL_20M_100M_200M_250M] \
  -group [get_clocks clk_out2_PLL_20M_100M_200M_250M] \
  -group [get_clocks clk_out3_PLL_20M_100M_200M_250M] \
  -group [get_clocks clk_out4_PLL_20M_100M_200M_250M] \
  -group [get_clocks clk_out1_PLL_240M] \
  -group [get_clocks clk_pll_i]
  
set_clock_groups -asynchronous -group [get_clocks {ROIC_DCLK_P0 ROIC_DCLK_P1 ROIC_DCLK_P2 ROIC_DCLK_P3 ROIC_DCLK_P4}] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks {ROIC_DCLK_P0 ROIC_DCLK_P1 ROIC_DCLK_P2 ROIC_DCLK_P3 ROIC_DCLK_P4}] -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks {ROIC_DCLK_P0 ROIC_DCLK_P1 ROIC_DCLK_P2 ROIC_DCLK_P3 ROIC_DCLK_P4}] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks {ROIC_DCLK_P0 ROIC_DCLK_P1 ROIC_DCLK_P2 ROIC_DCLK_P3 ROIC_DCLK_P4}] -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks GEV_RXAUI/U1/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU0.CPU_2DDR/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]

# SFP async
set_clock_groups -asynchronous -group [get_clocks GEV_RXAUI/U1/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks sfp_ref_clk_p]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks sfp_ref_clk_p]
set_clock_groups -asynchronous -group [get_clocks {sfp_ref_clk_p[0]}] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]