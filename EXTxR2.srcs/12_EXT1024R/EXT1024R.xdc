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
# BANK 32 (2.5V, ROIC)
set_property PACKAGE_PIN AC18 [get_ports {ROIC_DCLK_P[0]}]
set_property PACKAGE_PIN AB17 [get_ports {ROIC_DCLK_P[1]}]
set_property PACKAGE_PIN AA17 [get_ports {ROIC_DCLK_P[2]}]
set_property PACKAGE_PIN T20 [get_ports {ROIC_DCLK_P[3]}]
set_property PACKAGE_PIN U17 [get_ports {ROIC_DCLK_P[4]}]
## FCLK
set_property PACKAGE_PIN M25 [get_ports {ROIC_FCLK_P[0]}]
set_property PACKAGE_PIN R26 [get_ports {ROIC_FCLK_P[1]}]
set_property PACKAGE_PIN M21 [get_ports {ROIC_FCLK_P[2]}]
set_property PACKAGE_PIN R21 [get_ports {ROIC_FCLK_P[3]}]
set_property PACKAGE_PIN U19 [get_ports {ROIC_FCLK_P[4]}]
##DOUT
set_property PACKAGE_PIN AF19 [get_ports {ROIC_DOUT_P[0]}]
set_property PACKAGE_PIN AD20 [get_ports {ROIC_DOUT_P[1]}]
set_property PACKAGE_PIN AA19 [get_ports {ROIC_DOUT_P[2]}]
set_property PACKAGE_PIN V18 [get_ports {ROIC_DOUT_P[3]}]
set_property PACKAGE_PIN V16 [get_ports {ROIC_DOUT_P[4]}]
# BANK 16 (3.3V, ROIC)
## SPI
set_property PACKAGE_PIN D11 [get_ports {F_ROIC_SDO[0]}]
set_property PACKAGE_PIN J11 [get_ports {F_ROIC_SDO[1]}]
set_property PACKAGE_PIN G10 [get_ports {F_ROIC_SDO[2]}]
set_property PACKAGE_PIN H12 [get_ports {F_ROIC_SDO[3]}]
set_property PACKAGE_PIN H13 [get_ports {F_ROIC_SDO[4]}]

set_property PACKAGE_PIN B12 [get_ports {F_ROIC_SDI[0]}]

set_property PACKAGE_PIN E10 [get_ports {F_ROIC_MCLK[0]}]
set_property PACKAGE_PIN D10 [get_ports {F_ROIC_SYNC[0]}]
set_property PACKAGE_PIN B11 [get_ports {F_ROIC_TP_SEL[0]}]
set_property PACKAGE_PIN C12 [get_ports {F_ROIC_SCLK[0]}]
set_property PACKAGE_PIN C13 [get_ports {F_ROIC_CS[0]}]


# █▀▀ ▄▀█ ▀█▀ █▀▀
# █▄█ █▀█ ░█░ ██▄ %gate
# BANK 14 (3.3V, GATE)
set_property PACKAGE_PIN A23 [get_ports GATE_SHIFT_CLK1L]
set_property PACKAGE_PIN H22 [get_ports GATE_SHIFT_CLK2L]
set_property PACKAGE_PIN D25 [get_ports GATE_SHIFT_CLK1R]
set_property PACKAGE_PIN B25 [get_ports GATE_SHIFT_CLK2R]
set_property PACKAGE_PIN K23 [get_ports {GATE_START_PULSE1[0]}]
set_property PACKAGE_PIN J23 [get_ports {GATE_START_PULSE1[1]}]
set_property PACKAGE_PIN J25 [get_ports {GATE_START_PULSE1[2]}]
set_property PACKAGE_PIN J26 [get_ports {GATE_START_PULSE1[3]}]
set_property PACKAGE_PIN J24 [get_ports {GATE_START_PULSE1[4]}]
set_property PACKAGE_PIN H26 [get_ports {GATE_START_PULSE1[5]}]
set_property PACKAGE_PIN H24 [get_ports {GATE_START_PULSE1[6]}]
set_property PACKAGE_PIN G24 [get_ports {GATE_START_PULSE1[7]}]
set_property PACKAGE_PIN H23 [get_ports {GATE_START_PULSE2[0]}]
set_property PACKAGE_PIN F23 [get_ports {GATE_START_PULSE2[1]}]
set_property PACKAGE_PIN F24 [get_ports {GATE_START_PULSE2[2]}]
set_property PACKAGE_PIN E23 [get_ports {GATE_START_PULSE2[3]}]
set_property PACKAGE_PIN E22 [get_ports {GATE_START_PULSE2[4]}]
set_property PACKAGE_PIN D24 [get_ports {GATE_START_PULSE2[5]}]
set_property PACKAGE_PIN D23 [get_ports {GATE_START_PULSE2[6]}]
set_property PACKAGE_PIN C24 [get_ports {GATE_START_PULSE2[7]}]
set_property PACKAGE_PIN F22 [get_ports GATE_OUT_EN1L]
set_property PACKAGE_PIN D21 [get_ports GATE_OUT_EN2L]
set_property PACKAGE_PIN G22 [get_ports GATE_OUT_EN1R]
set_property PACKAGE_PIN F25 [get_ports GATE_OUT_EN2R]
set_property PACKAGE_PIN C22 [get_ports GATE_ALL_OUT]
set_property PACKAGE_PIN A24 [get_ports {GATE_CONFIG[0]}]
set_property PACKAGE_PIN D26 [get_ports {GATE_CONFIG[2]}]
set_property PACKAGE_PIN D14 [get_ports GATE_VGH_RST]

# █▀▀ ▀█▀ █▀▀
# ██▄ ░█░ █▄▄
# BANK 16 (3.3V)
## CLK
set_property PACKAGE_PIN AA10 [get_ports SYSTEM_CLK_P]
## PWR
set_property PACKAGE_PIN C14 [get_ports {PWR_EN[0]}]
set_property PACKAGE_PIN B15 [get_ports {PWR_EN[1]}]
set_property PACKAGE_PIN A15 [get_ports {PWR_EN[2]}]
set_property PACKAGE_PIN L22 [get_ports {PWR_EN[3]}]
set_property PACKAGE_PIN D13 [get_ports {PWR_EN[4]}]
set_property PACKAGE_PIN A14 [get_ports {PWR_EN[5]}]
set_property PACKAGE_PIN B14 [get_ports {PWR_EN[6]}]
set_property PACKAGE_PIN E12 [get_ports {PWR_EN[7]}]
## EXT
set_property PACKAGE_PIN A8 [get_ports EXT_IN]
set_property PACKAGE_PIN B9 [get_ports EXT_OUT]
set_property PACKAGE_PIN C9 [get_ports EXP_IN]
## DAC
# BANK 14 (3.3V)
## COMM
set_property PACKAGE_PIN B24 [get_ports {FLASH_D[0]}]
set_property PACKAGE_PIN A25 [get_ports {FLASH_D[1]}]
set_property PACKAGE_PIN B22 [get_ports {FLASH_D[2]}]
set_property PACKAGE_PIN A22 [get_ports {FLASH_D[3]}]
set_property PACKAGE_PIN C23 [get_ports FLASH_FCS]
set_property PACKAGE_PIN B26 [get_ports EEPROM_SDA]
set_property PACKAGE_PIN C26 [get_ports EEPROM_SCL]
set_property PACKAGE_PIN B21 [get_ports TEMP_SDA]
set_property PACKAGE_PIN C21 [get_ports TEMP_SCL]
set_property PACKAGE_PIN B20 [get_ports UART_TX]
set_property PACKAGE_PIN A20 [get_ports UART_RX]
## LED
set_property PACKAGE_PIN A10 [get_ports {STATUS_LED[0]}]
set_property PACKAGE_PIN E21 [get_ports {STATUS_LED[1]}]
## PHY
set_property PACKAGE_PIN M2 [get_ports {PHY_SIP[1]}]
set_property PACKAGE_PIN P2 [get_ports {PHY_SIP[0]}]
set_property PACKAGE_PIN H6 [get_ports PHY_CLK_P]
set_property PACKAGE_PIN D8 [get_ports PHY_RESET_N]
set_property PACKAGE_PIN D9 [get_ports PHY_MDC]
set_property PACKAGE_PIN B10 [get_ports PHY_MDIO]

# GPIO 230922 #
set_property PACKAGE_PIN E26 [get_ports F_GPIO1]

set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO1]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO2]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO3]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO4]
#############################################
# Pin Descriptions
#############################################
# BANK 14 (3.3V, GATE, ETC)
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
# unuse pin GATE_SHIFT_CLK, GATE_OUT_EN1, GATE_OUT_EN2
set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2]
set_property IO_BUFFER_TYPE NONE [get_ports tb_aligndone]
set_property IO_BUFFER_TYPE NONE [get_ports tb_alignreq]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK1L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK2L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK1R]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_SHIFT_CLK2R]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN1L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN2L]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN1R]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_OUT_EN2R]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_ALL_OUT]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_ALL_OUT_R]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_CONFIG[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {STATUS_LED[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[2]}]
# BANK 16 (3.3V, POWER, EXT, PHY, ROIC_CTRL)
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[8]}]
set_property IOSTANDARD LVCMOS33 [get_ports GATE_VGH_RST]
set_property IOSTANDARD LVCMOS33 [get_ports {STATUS_LED[1]}]
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
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SDO[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SDO[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {F_ROIC_SDO[4]}]
# BANK 33 & BANK 34 (1.5V, DDR3)
set_property IOSTANDARD DIFF_SSTL15 [get_ports SYSTEM_CLK_P]

# ▀█▀ █ █▀▄▀█ █▀▀
# ░█░ █ █░▀░█ ██▄
create_clock -period 5.000 [get_ports SYSTEM_CLK_P]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets sroic_dclk_0]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -min -add_delay 0.000 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -max -add_delay 0.400 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -min -add_delay 0.000 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -max -add_delay 0.400 [get_ports {ROIC_DOUT_N[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -min -add_delay 0.000 [get_ports {ROIC_DOUT_P[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -clock_fall -max -add_delay 0.400 [get_ports {ROIC_DOUT_P[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -min -add_delay 0.000 [get_ports {ROIC_DOUT_P[*]}]
set_input_delay -clock [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -max -add_delay 0.400 [get_ports {ROIC_DOUT_P[*]}]
# RXAUI bridge asynchronous paths
create_clock -period 4.000 -name {ROIC_DCLK_P[0]} -waveform {0.000 2.000} [get_ports {ROIC_DCLK_P[0]}]
create_clock -period 4.000 -name {ROIC_DCLK_P[1]} -waveform {0.000 2.000} [get_ports {ROIC_DCLK_P[1]}]
create_clock -period 4.000 -name {ROIC_DCLK_P[2]} -waveform {0.000 2.000} [get_ports {ROIC_DCLK_P[2]}]

set_clock_groups -asynchronous \
-group [get_clocks {ROIC_DCLK_P[0]}] \
-group [get_clocks {ROIC_DCLK_P[1]}] \
-group [get_clocks {ROIC_DCLK_P[2]}] \
-group [get_clocks clk_out2_PLL_20M_100M_200M_250M] \
-group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] \
-group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] \
-group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]

set_false_path -from [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/DDR_RSTN_GEN/srstn_reg/C]
set_false_path -from [get_clocks clk_out1_PLL_20M_100M_200M_250M] -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_out1_PLL_20M_100M_200M_250M] -to [get_clocks clk_out1_PLL_240M]
set_false_path -from [get_clocks clk_out1_PLL_20M_100M_200M_250M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_out2_PLL_20M_100M_200M_250M] -to [get_clocks clk_out1_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_out2_PLL_20M_100M_200M_250M] -to [get_clocks clk_out1_PLL_240M]
set_false_path -from [get_clocks clk_out2_PLL_20M_100M_200M_250M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_out4_PLL_20M_100M_200M_250M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_out1_PLL_240M] -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_out1_PLL_240M] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_pll_i] -to [get_clocks clk_out1_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_pll_i] -to [get_clocks clk_out2_PLL_20M_100M_200M_250M]
set_false_path -from [get_clocks clk_pll_i] -to [get_clocks clk_out1_PLL_240M]

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
# #230417
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKOUT0]]


set_property IOSTANDARD LVDS [get_ports {ROIC_DCLK_P[0]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DCLK_N[0]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DCLK_P[1]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DCLK_N[1]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DCLK_P[2]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DCLK_N[2]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[4]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_P[3]}]
set_property IOSTANDARD LVDS_25 [get_ports {ROIC_DCLK_N[3]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_P[0]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_N[0]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_P[1]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_N[1]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_P[2]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_N[2]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_P[3]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_N[3]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_P[4]}]
set_property IOSTANDARD LVDS [get_ports {ROIC_DOUT_N[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE1[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {GATE_START_PULSE2[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[9]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[10]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[11]}]
set_property IOSTANDARD LVCMOS33 [get_ports {PWR_EN[12]}]
set_property PACKAGE_PIN F8 [get_ports {PWR_EN[8]}]
set_property PACKAGE_PIN F9 [get_ports {PWR_EN[9]}]
set_property PACKAGE_PIN H8 [get_ports {PWR_EN[10]}]
set_property PACKAGE_PIN J8 [get_ports {PWR_EN[11]}]
set_property PACKAGE_PIN J10 [get_ports {PWR_EN[12]}]
set_property PACKAGE_PIN K21 [get_ports F_GPIO2]
set_property PACKAGE_PIN L23 [get_ports F_GPIO3]
set_property PACKAGE_PIN K22 [get_ports F_GPIO4]
set_property PACKAGE_PIN J21 [get_ports {GATE_CONFIG[1]}]
set_property PACKAGE_PIN E25 [get_ports GATE_ALL_OUT_R]


set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk]

#v2
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]