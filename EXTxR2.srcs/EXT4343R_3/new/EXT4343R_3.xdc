################################################################################
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
set_property BITSTREAM.CONFIG.TIMER_CFG 0x100000 [current_design]
################################################################################
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets osys_clk]

# █▀█ █▀█ █ █▀▀
# █▀▄ █▄█ █ █▄▄
set_property PACKAGE_PIN AA25 [get_ports {ROIC_DCLK_P[0]}]; # ROIC_DCLK1_1_P
set_property PACKAGE_PIN AD23 [get_ports {ROIC_DCLK_P[1]}]; # ROIC_DCLK1_12_P
set_property PACKAGE_PIN V23  [get_ports {ROIC_DCLK_P[2]}]; # ROIC_DCLK1_17_P

set_property PACKAGE_PIN Y25  [get_ports {ROIC_FCLK_P[0]}]; # ROIC_FCLK1_1_P
set_property PACKAGE_PIN AC23 [get_ports {ROIC_FCLK_P[1]}]; # ROIC_FCLK1_12_P
set_property PACKAGE_PIN U24  [get_ports {ROIC_FCLK_P[2]}]; # ROIC_FCLK1_17_P

set_property PACKAGE_PIN W25  [get_ports {ROIC_DOUT_P[0]}] ; # ROIC_DOUTA1_1_P
set_property PACKAGE_PIN AB26 [get_ports {ROIC_DOUT_P[1]}] ; # ROIC_DOUTA1_2_P
set_property PACKAGE_PIN M21  [get_ports {ROIC_DOUT_P[2]}] ; # ROIC_DOUTA1_3_P
set_property PACKAGE_PIN N21  [get_ports {ROIC_DOUT_P[3]}] ; # ROIC_DOUTA1_4_P
set_property PACKAGE_PIN R21  [get_ports {ROIC_DOUT_P[4]}] ; # ROIC_DOUTA1_5_P
set_property PACKAGE_PIN R22  [get_ports {ROIC_DOUT_P[5]}] ; # ROIC_DOUTA1_6_P
set_property PACKAGE_PIN T22  [get_ports {ROIC_DOUT_P[6]}] ; # ROIC_DOUTA1_7_P
set_property PACKAGE_PIN U22  [get_ports {ROIC_DOUT_P[7]}] ; # ROIC_DOUTA1_8_P
set_property PACKAGE_PIN V21  [get_ports {ROIC_DOUT_P[8]}] ; # ROIC_DOUTA1_9_P
set_property PACKAGE_PIN W23  [get_ports {ROIC_DOUT_P[9]}] ; # ROIC_DOUTA1_10_P
set_property PACKAGE_PIN Y23  [get_ports {ROIC_DOUT_P[10]}]; # ROIC_DOUTA1_11_P
set_property PACKAGE_PIN AA23 [get_ports {ROIC_DOUT_P[11]}]; # ROIC_DOUTA1_12_P
set_property PACKAGE_PIN M24  [get_ports {ROIC_DOUT_P[12]}]; # ROIC_DOUTA1_13_P
set_property PACKAGE_PIN N26  [get_ports {ROIC_DOUT_P[13]}]; # ROIC_DOUTA1_14_P
set_property PACKAGE_PIN P24  [get_ports {ROIC_DOUT_P[14]}]; # ROIC_DOUTA1_15_P
set_property PACKAGE_PIN R25  [get_ports {ROIC_DOUT_P[15]}]; # ROIC_DOUTA1_16_P
set_property PACKAGE_PIN T24  [get_ports {ROIC_DOUT_P[16]}]; # ROIC_DOUTA1_17_P

set_property PACKAGE_PIN AF22 [get_ports {F_ROIC_TP_SEL[0]}]; # F_ROIC_RESET_1
set_property PACKAGE_PIN AF24 [get_ports {F_ROIC_SCLK[0]}]  ; # F_ROIC_SCK_1
set_property PACKAGE_PIN AF25 [get_ports {F_ROIC_SDI[0]}]   ; # F_ROIC_SDI_1
set_property PACKAGE_PIN AE23 [get_ports {F_ROIC_CS[0]}]    ; # F_ROIC_CS_1
set_property PACKAGE_PIN AD26 [get_ports {F_ROIC_SDO[0]}]   ; # F_SDO1_1
set_property PACKAGE_PIN AD25 [get_ports {F_ROIC_SDO[1]}]   ; # F_SDO1_12
set_property PACKAGE_PIN AE26 [get_ports {F_ROIC_SDO[2]}]   ; # F_SDO1_17

set_property PACKAGE_PIN AE22 [get_ports {F_ROIC_MCLK[0]}]; # F_ROIC_ACLK_1_1_6
set_property PACKAGE_PIN AE21 [get_ports {F_ROIC_MCLK[1]}]; # F_ROIC_ACLK_1_7_12
set_property PACKAGE_PIN AF23 [get_ports {F_ROIC_SYNC[0]}]; # F_ROIC_SYNC_1

# █▀▀ ▀█▀ █▀▀
# ██▄ ░█░ █▄▄
set_property PACKAGE_PIN AB11 [get_ports SYSTEM_CLK_P]; # AB11 SYSTEM_CLK_P
set_property PACKAGE_PIN H21  [get_ports {PWR_EN[0]}]; # N_BIAS_AEN     Output - default : Low, Active : High
                                                       #                Output - Low : GND , High : VBIAS (Analog S/W)"
set_property PACKAGE_PIN K23  [get_ports {PWR_EN[1]}]; # PGATE_ON       Output - default : Low, Active : High
set_property PACKAGE_PIN J21  [get_ports {PWR_EN[2]}]; # VGL_EN         Output - default : Low, Active : High
set_property PACKAGE_PIN J23  [get_ports {PWR_EN[3]}]; # VGH_EN         Output - default : Low, Active : High
set_property PACKAGE_PIN AE25 [get_ports {PWR_EN[4]}]; # F_ROICPWR_EN_L Output - default : Low, active : High
set_property PACKAGE_PIN D8 [get_ports PHY_RESET_N]
set_property PACKAGE_PIN F10 [get_ports PHY_MDC]
set_property PACKAGE_PIN D9 [get_ports PHY_MDIO]
set_property PACKAGE_PIN P2 [get_ports {PHY_SIP[0]}]
set_property PACKAGE_PIN M2 [get_ports {PHY_SIP[1]}]
set_property PACKAGE_PIN H6 [get_ports PHY_CLK_P]
#tb_pin
set_property PACKAGE_PIN AE17 [get_ports tb_alignreq]
set_property PACKAGE_PIN AF17 [get_ports tb_aligndone]
set_property PACKAGE_PIN B24 [get_ports {FLASH_D[0]}]; # B24 FLASH_D0
set_property PACKAGE_PIN A25 [get_ports {FLASH_D[1]}]; # A25 FLASH_D1
set_property PACKAGE_PIN B22 [get_ports {FLASH_D[2]}]; # B22 FLASH_D2
set_property PACKAGE_PIN A22 [get_ports {FLASH_D[3]}]; # A22 FLASH_D3
set_property PACKAGE_PIN C23 [get_ports FLASH_FCS]   ; # C23 FLASH_CS#
# set_property PACKAGE_PIN C26 [get_ports FLASH_RESET]; # C26 FLASH_RESET#
set_property PACKAGE_PIN F24 [get_ports EEPROM_SCL]; # I2C1_SCL
set_property PACKAGE_PIN F23 [get_ports EEPROM_SDA]; # I2C1_SDA
set_property PACKAGE_PIN J24 [get_ports TEMP_SCL]; # I2C0_SCL
set_property PACKAGE_PIN J25 [get_ports TEMP_SDA]; # I2C0_SDA
set_property PACKAGE_PIN A23 [get_ports UART_TX]; # UART_TX
set_property PACKAGE_PIN A24 [get_ports UART_RX]; # UART_RX
set_property PACKAGE_PIN C22 [get_ports EXT_IN] ; # EXT_IN1  Input - default : High, Active : High
set_property PACKAGE_PIN B21 [get_ports EXT_OUT]; # EXT_OUT1 output - default : High, Active : Low
set_property PACKAGE_PIN A20 [get_ports EXP_IN] ; # EXT_IN2
set_property PACKAGE_PIN C21 [get_ports {STATUS_LED[0]}]; # LED_RDY/BUSY Output - default : Low, Active : High
set_property PACKAGE_PIN B20 [get_ports {STATUS_LED[1]}]; # LED_POWER  output - default : High, Active : High

# █▀▀ ▄▀█ ▀█▀ █▀▀
# █▄█ █▀█ ░█░ ██▄
set_property PACKAGE_PIN H23 [get_ports {GATE_SHIFT_CLK}];
set_property PACKAGE_PIN D23 [get_ports {GATE_START_PULSE1[0]}];
set_property PACKAGE_PIN E22 [get_ports {GATE_START_PULSE1[1]}];
set_property PACKAGE_PIN D21 [get_ports {GATE_START_PULSE1[2]}];
set_property PACKAGE_PIN E20 [get_ports {GATE_START_PULSE1[3]}];
set_property PACKAGE_PIN F22 [get_ports {GATE_START_PULSE1[4]}];
set_property PACKAGE_PIN E21 [get_ports {GATE_START_PULSE1[5]}];
set_property PACKAGE_PIN E23 [get_ports {GATE_START_PULSE1[6]}];
set_property PACKAGE_PIN E26 [get_ports {GATE_START_PULSE1[7]}];
set_property PACKAGE_PIN E25 [get_ports {GATE_START_PULSE1[8]}];
set_property PACKAGE_PIN F25 [get_ports {GATE_START_PULSE1[9]}];
set_property PACKAGE_PIN G25 [get_ports {GATE_START_PULSE1[10]}];
set_property PACKAGE_PIN G26 [get_ports {GATE_START_PULSE1[11]}];
set_property PACKAGE_PIN C19 [get_ports {GATE_START_PULSE2[0]}]; # F_DIO2_6
set_property PACKAGE_PIN D26 [get_ports {GATE_CONFIG[0]}];
set_property PACKAGE_PIN C24 [get_ports {GATE_OUT_EN1}];
set_property PACKAGE_PIN G21 [get_ports {GATE_OUT_EN2}];
#set_property PACKAGE_PIN C26 [get_ports {GATE_ALL_OUT}];
set_property PACKAGE_PIN G22 [get_ports {GATE_ALL_OUT}];
#set_property PACKAGE_PIN H22 [get_ports {GATE_ALL_OUT_R}];
set_property PACKAGE_PIN K22 [get_ports {GATE_VGH_RST}]; # VGH_FLK Output - Low : VGH , High : GND (Analog S/W)

# █ █▀█
# █ █▄█
# Unused output port
#set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK]
#set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1  ]
#set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2  ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_ALL_OUT_R      ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1L       ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1R       ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2L       ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2R       ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK1L    ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK1R    ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK2L    ]
 set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK2R    ]
## set_property IO_BUFFER_TYPE NONE [get_ports {GATE_START_PULSE2[0]}]
## set_property IO_BUFFER_TYPE NONE [get_ports PWR_EN[5]           ]
# set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
# set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]

set_property SLEW FAST [get_ports {F_ROIC_MCLK[1]}]
set_property SLEW FAST [get_ports {F_ROIC_MCLK[0]}]
set_property SLEW FAST [get_ports {F_ROIC_SYNC[0]}]
set_property DRIVE 16 [get_ports {F_ROIC_MCLK[1]}]
set_property DRIVE 16 [get_ports {F_ROIC_MCLK[0]}]
set_property DRIVE 16 [get_ports {F_ROIC_SYNC[0]}]

set_property IOSTANDARD DIFF_SSTL135 [get_ports SYSTEM_CLK_P]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_CS[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_MCLK[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_MCLK[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_TP_SEL[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_SCLK[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_SDI[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_SDO[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_SDO[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {F_ROIC_SYNC[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {FLASH_D[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports FLASH_FCS]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_ALL_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_ALL_OUT_R]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN1]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN2]
 set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK]
# set_property IOSTANDARD LVCMOS18 [get_ports {GATE_START_PULSE2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_VGH_RST]
set_property IOSTANDARD LVCMOS33 [get_ports F_NBIAS_CTRL]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {PWR_EN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports TEMP_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports TEMP_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports UART_RX]
set_property IOSTANDARD LVCMOS33 [get_ports UART_TX]
set_property IOSTANDARD LVCMOS33 [get_ports EEPROM_SCL]
set_property IOSTANDARD LVCMOS33 [get_ports EEPROM_SDA]
set_property IOSTANDARD LVCMOS33 [get_ports EXT_IN]
set_property IOSTANDARD LVCMOS33 [get_ports EXT_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports {STATUS_LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {STATUS_LED[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports PHY_MDC]
set_property IOSTANDARD LVCMOS25 [get_ports PHY_MDIO]
set_property IOSTANDARD LVCMOS25 [get_ports PHY_RESET_N]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports tb_aligndone]
set_property IOSTANDARD LVCMOS18 [get_ports tb_alignreq]

set_property IOSTANDARD LVCMOS33 [get_ports EXP_IN]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_OUT_EN1L}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_OUT_EN1R}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_OUT_EN2L}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_OUT_EN2R}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_SHIFT_CLK1L}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_SHIFT_CLK1R}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_SHIFT_CLK2L}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_SHIFT_CLK2R}]

# ▀█▀ █ █▀▄▀█ █▀▀
# ░█░ █ █░▀░█ ██▄ %time
create_clock -period 5.000 [get_ports SYSTEM_CLK_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets TP_1_OBUF]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sroic_dclk_0]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -min -add_delay 0.0 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -max -add_delay 0.4 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -min -add_delay 0.0 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -max -add_delay 0.4 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -min -add_delay 0.0 [get_ports {ROIC_DOUT_P[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -max -add_delay 0.4 [get_ports {ROIC_DOUT_P[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -min -add_delay 0.0 [get_ports {ROIC_DOUT_P[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -max -add_delay 0.4 [get_ports {ROIC_DOUT_P[*]}]
# RXAUI bridge asynchronous paths
set_max_delay -to [get_pins SYNTH.RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r1_reg/S] 6.400
set_max_delay -to [get_pins SYNTH.RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r2_reg/S] 6.400
set_max_delay -to [get_pins SYNTH.RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r3_reg/S] 6.400
set_property ASYNC_REG true [get_cells SYNTH.RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r1_reg]
set_property ASYNC_REG true [get_cells SYNTH.RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r2_reg]
set_property ASYNC_REG true [get_cells SYNTH.RXAUI_INST/U0/rxaui_block_i/rxaui_cl_resets_i/reset156_r3_reg]
# ASYNC Signal
set_false_path -from [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/DDR_RSTN_GEN/srstn_reg/C]
set_false_path -from [get_clocks clk_out1_PLL_20M_100M_200M_250M] -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_out1_PLL_20M_100M_200M_250M] -to [get_clocks clk_out1_PLL_240M]
set_false_path -from [get_clocks clk_out1_PLL_20M_100M_200M_250M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_out2_PLL_20M_100M_200M_250M] -to [get_clocks clk_out1_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_out2_PLL_20M_100M_200M_250M] -to [get_clocks clk_out1_PLL_240M]
set_false_path -from [get_clocks clk_out2_PLL_20M_100M_200M_250M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_out4_PLL_20M_100M_200M_250M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_out1_PLL_240M]               -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_out1_PLL_240M]               -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_pll_i]                       -to [get_clocks clk_out1_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_pll_i]                       -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_pll_i]                       -to [get_clocks clk_out1_PLL_240M]
set_false_path -from [get_clocks SYNTH.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks SYNTH.G_rxaui_2p5G.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK]
set_clock_groups -asynchronous -group [get_clocks SYNTH.G_rxaui_2p5G.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]

# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]

#v2
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]