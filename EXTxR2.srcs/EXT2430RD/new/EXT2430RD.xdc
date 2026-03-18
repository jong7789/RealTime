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
# set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
# set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
# set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
# connect_debug_port dbg_hub/clk [get_nets osys_clk]

# █▀█ █▀█ █ █▀▀
# █▀▄ █▄█ █ █▄▄
set_property PACKAGE_PIN H14 [get_ports { F_ROIC_MCLK[0]   }]; # F_R1_MCLK IO_L5P_T0_16
set_property PACKAGE_PIN B14 [get_ports { F_ROIC_SCLK[0]   }]; # F_R1_SCLK IO_L21P_T3_DQS_16
set_property PACKAGE_PIN F13 [get_ports { F_ROIC_SDI[0]    }]; # F_R1_SDI IO_L15N_T2_DQS_16
set_property PACKAGE_PIN A14 [get_ports { F_ROIC_CS[0]     }]; # IF_R1_SEN O_L21N_T3_DQS_16
set_property PACKAGE_PIN A15 [get_ports { F_ROIC_SYNC[0]   }]; # F_R1_SYNC IO_L23N_T3_16
set_property PACKAGE_PIN C14 [get_ports { F_ROIC_TP_SEL[0] }]; # F_R1_TP_SEL IO_L19P_T3_16
set_property PACKAGE_PIN L25 [get_ports { ROIC_FCLK_N[0]   }]; # R1_FCLK1_M IO_L3N_T0_DQS_13
set_property PACKAGE_PIN M25 [get_ports { ROIC_FCLK_P[0]   }]; # R1_FCLK1_P IO_L3P_T0_DQS_13
set_property PACKAGE_PIN M26 [get_ports { ROIC_DCLK_N[0]   }]; # R1_DCLK1_M IO_L5N_T0_13
set_property PACKAGE_PIN N26 [get_ports { ROIC_DCLK_P[0]   }]; # R1_DCLK1_P IO_L5P_T0_13

set_property PACKAGE_PIN D14  [get_ports { F_ROIC_MCLK[1]   }]; # F_R2_MCLK  IO_L17P_T2_16
set_property PACKAGE_PIN E11  [get_ports { F_ROIC_SCLK[1]   }]; # F_R2_SCLK  IO_L14P_T2_SRCC_16
set_property PACKAGE_PIN B11  [get_ports { F_ROIC_SDI[1]    }]; # F_R2_SDI  IO_L20N_T3_16
set_property PACKAGE_PIN H11  [get_ports { F_ROIC_CS[1]     }]; # F_R2_SEN  IO_L6N_T0_VREF_16
set_property PACKAGE_PIN E13  [get_ports { F_ROIC_SYNC[1]   }]; # F_R2_SYNC  IO_L18P_T2_16
set_property PACKAGE_PIN F12  [get_ports { F_ROIC_TP_SEL[1] }]; # F_R2_TP_SEL IO_L16N_T2_16
set_property PACKAGE_PIN AF22 [get_ports { ROIC_FCLK_N[1]   }]; # R2_FCLK1_M IO_L24N_T3_12
set_property PACKAGE_PIN AE22 [get_ports { ROIC_FCLK_P[1]   }]; # R2_FCLK1_P IO_L24P_T3_12
set_property PACKAGE_PIN AE21 [get_ports { ROIC_DCLK_N[1]   }]; # R2_DCLK1_M IO_L19N_T3_VREF_12
set_property PACKAGE_PIN AD21 [get_ports { ROIC_DCLK_P[1]   }]; # R2_DCLK1_P IO_L19P_T3_12

set_property PACKAGE_PIN H9  [get_ports { F_ROIC_SDO[0]  }]; # F_R1_SDO_1 IO_L1P_T0_16
set_property PACKAGE_PIN J11 [get_ports { F_ROIC_SDO[1]  }]; # F_R1_SDO_2 IO_L4P_T0_16
set_property PACKAGE_PIN G10 [get_ports { F_ROIC_SDO[2]  }]; # F_R1_SDO_3 IO_L2P_T0_16
set_property PACKAGE_PIN H12 [get_ports { F_ROIC_SDO[3]  }]; # F_R1_SDO_4 IO_L6P_T0_16
set_property PACKAGE_PIN H13 [get_ports { F_ROIC_SDO[4]  }]; # F_R1_SDO_5 IO_L3N_T0_DQS_16
set_property PACKAGE_PIN B12 [get_ports { F_ROIC_SDO[5]  }]; # F_R1_SDO_6 IO_L20P_T3_16
set_property PACKAGE_PIN G12 [get_ports { F_ROIC_SDO[6]  }]; # F_R1_SDO_7 IO_L16P_T2_16
set_property PACKAGE_PIN H8  [get_ports { F_ROIC_SDO[7]  }]; # F_R2_SDO_1  IO_L1N_T0_16
set_property PACKAGE_PIN G9  [get_ports { F_ROIC_SDO[8]  }]; # F_R2_SDO_2  IO_L2N_T0_16
set_property PACKAGE_PIN F8  [get_ports { F_ROIC_SDO[9]  }]; # F_R2_SDO_3  IO_L7N_T1_16
set_property PACKAGE_PIN D8  [get_ports { F_ROIC_SDO[10] }]; # F_R2_SDO_4  IO_L8N_T1_16
set_property PACKAGE_PIN F9  [get_ports { F_ROIC_SDO[11] }]; # F_R2_SDO_5  IO_L7P_T1_16
set_property PACKAGE_PIN D10 [get_ports { F_ROIC_SDO[12] }]; # F_R2_SDO_6  IO_L12N_T1_MRCC_16
set_property PACKAGE_PIN J10 [get_ports { F_ROIC_SDO[13] }]; # F_R2_SDO_7  IO_L4N_T0_16

set_property PACKAGE_PIN K26  [get_ports { ROIC_DOUT_N[0]  }]; # R1_DOUT1_M IO_L1N_T0_13
set_property PACKAGE_PIN K25  [get_ports { ROIC_DOUT_P[0]  }]; # R1_DOUT1_P IO_L1P_T0_13
set_property PACKAGE_PIN N24  [get_ports { ROIC_DOUT_N[1]  }]; # R1_DOUT2_M IO_L4N_T0_13
set_property PACKAGE_PIN P24  [get_ports { ROIC_DOUT_P[1]  }]; # R1_DOUT2_P IO_L4P_T0_13
set_property PACKAGE_PIN P26  [get_ports { ROIC_DOUT_N[2]  }]; # R1_DOUT3_M IO_L2N_T0_13
set_property PACKAGE_PIN R26  [get_ports { ROIC_DOUT_P[2]  }]; # R1_DOUT3_P IO_L2P_T0_13
set_property PACKAGE_PIN T25  [get_ports { ROIC_DOUT_N[3]  }]; # R1_DOUT4_M IO_L15N_T2_DQS_13
set_property PACKAGE_PIN T24  [get_ports { ROIC_DOUT_P[3]  }]; # R1_DOUT4_P IO_L15P_T2_DQS_13
set_property PACKAGE_PIN M20  [get_ports { ROIC_DOUT_N[4]  }]; # R1_DOUT5_M IO_L7N_T1_13
set_property PACKAGE_PIN N19  [get_ports { ROIC_DOUT_P[4]  }]; # R1_DOUT5_P IO_L7P_T1_13
set_property PACKAGE_PIN M22  [get_ports { ROIC_DOUT_N[5]  }]; # R1_DOUT6_M IO_L10N_T1_13
set_property PACKAGE_PIN M21  [get_ports { ROIC_DOUT_P[5]  }]; # R1_DOUT6_P IO_L10P_T1_13
set_property PACKAGE_PIN N22  [get_ports { ROIC_DOUT_N[6]  }]; # R1_DOUT7_M IO_L12N_T1_MRCC_13
set_property PACKAGE_PIN N21  [get_ports { ROIC_DOUT_P[6]  }]; # R1_DOUT7_P IO_L12P_T1_MRCC_13
set_property PACKAGE_PIN P20  [get_ports { ROIC_DOUT_N[7]  }]; # R1_DOUT8_M IO_L9N_T1_DQS_13
set_property PACKAGE_PIN P19  [get_ports { ROIC_DOUT_P[7]  }]; # R1_DOUT8_P IO_L9P_T1_DQS_13
set_property PACKAGE_PIN P21  [get_ports { ROIC_DOUT_N[8]  }]; # R1_DOUT9_M IO_L13N_T2_MRCC_13
set_property PACKAGE_PIN R21  [get_ports { ROIC_DOUT_P[8]  }]; # R1_DOUT9_P IO_L13P_T2_MRCC_13
set_property PACKAGE_PIN R20  [get_ports { ROIC_DOUT_N[9]  }]; # R1_DOUT10_M IO_L16N_T2_13
set_property PACKAGE_PIN T20  [get_ports { ROIC_DOUT_P[9]  }]; # R1_DOUT10_P IO_L16P_T2_13
set_property PACKAGE_PIN T19  [get_ports { ROIC_DOUT_N[10] }]; # R1_DOUT11_M IO_L19N_T3_VREF_13
set_property PACKAGE_PIN T18  [get_ports { ROIC_DOUT_P[10] }]; # R1_DOUT11_P IO_L19P_T3_13
set_property PACKAGE_PIN U20  [get_ports { ROIC_DOUT_N[11] }]; # R1_DOUT12_M IO_L18N_T2_13
set_property PACKAGE_PIN U19  [get_ports { ROIC_DOUT_P[11] }]; # R1_DOUT12_P IO_L18P_T2_13
set_property PACKAGE_PIN T17  [get_ports { ROIC_DOUT_N[12] }]; # R1_DOUT13_M IO_L23N_T3_13
set_property PACKAGE_PIN U17  [get_ports { ROIC_DOUT_P[12] }]; # R1_DOUT13_P IO_L23P_T3_13
set_property PACKAGE_PIN N23  [get_ports { ROIC_DOUT_N[13] }]; # R1_DOUT14_M IO_L11N_T1_SRCC_13
set_property PACKAGE_PIN P23  [get_ports { ROIC_DOUT_P[13] }]; # R1_DOUT14_P IO_L11P_T1_SRCC_13
set_property PACKAGE_PIN R23  [get_ports { ROIC_DOUT_N[14] }]; # R1_DOUT15_M IO_L14N_T2_SRCC_13
set_property PACKAGE_PIN R22  [get_ports { ROIC_DOUT_P[14] }]; # R1_DOUT15_P IO_L14P_T2_SRCC_13
set_property PACKAGE_PIN T23  [get_ports { ROIC_DOUT_N[15] }]; # R1_DOUT16_M IO_L17N_T2_13
set_property PACKAGE_PIN T22  [get_ports { ROIC_DOUT_P[15] }]; # R1_DOUT16_P IO_L17P_T2_13
set_property PACKAGE_PIN W21  [get_ports { ROIC_DOUT_N[16] }]; # R1_DOUT17_M IO_L6N_T0_VREF_12
set_property PACKAGE_PIN V21  [get_ports { ROIC_DOUT_P[16] }]; # R1_DOUT17_P IO_L6P_T0_12
set_property PACKAGE_PIN Y21  [get_ports { ROIC_DOUT_N[17] }]; # R1_DOUT18_M IO_L15N_T2_DQS_12
set_property PACKAGE_PIN W20  [get_ports { ROIC_DOUT_P[17] }]; # R1_DOUT18_P IO_L15P_T2_DQS_12
set_property PACKAGE_PIN AA22 [get_ports { ROIC_DOUT_N[18] }]; # R1_DOUT19_M IO_L13N_T2_MRCC_12
set_property PACKAGE_PIN Y22  [get_ports { ROIC_DOUT_P[18] }]; # R1_DOUT19_P IO_L13P_T2_MRCC_12

set_property PACKAGE_PIN AF23 [get_ports { ROIC_DOUT_N[19] }]; # R2_DOUT1_M IO_L22N_T3_12
set_property PACKAGE_PIN AE23 [get_ports { ROIC_DOUT_P[19] }]; # R2_DOUT1_P IO_L22P_T3_12
set_property PACKAGE_PIN AC21 [get_ports { ROIC_DOUT_N[20] }]; # R2_DOUT2_M IO_L18N_T2_12
set_property PACKAGE_PIN AB21 [get_ports { ROIC_DOUT_P[20] }]; # R2_DOUT2_P IO_L18P_T2_12
set_property PACKAGE_PIN AC22 [get_ports { ROIC_DOUT_N[21] }]; # R2_DOUT3_M IO_L17N_T2_12
set_property PACKAGE_PIN AB22 [get_ports { ROIC_DOUT_P[21] }]; # R2_DOUT3_P IO_L17P_T2_12
set_property PACKAGE_PIN AD24 [get_ports { ROIC_DOUT_N[22] }]; # R2_DOUT4_M IO_L16N_T2_12
set_property PACKAGE_PIN AD23 [get_ports { ROIC_DOUT_P[22] }]; # R2_DOUT4_P IO_L16P_T2_12
set_property PACKAGE_PIN AA24 [get_ports { ROIC_DOUT_N[23] }]; # R2_DOUT5_M IO_L12N_T1_MRCC_12
set_property PACKAGE_PIN Y23  [get_ports { ROIC_DOUT_P[23] }]; # R2_DOUT5_P IO_L12P_T1_MRCC_12
set_property PACKAGE_PIN AB24 [get_ports { ROIC_DOUT_N[24] }]; # R2_DOUT6_M IO_L11N_T1_SRCC_12
set_property PACKAGE_PIN AA23 [get_ports { ROIC_DOUT_P[24] }]; # R2_DOUT6_P IO_L11P_T1_SRCC_12
set_property PACKAGE_PIN Y26  [get_ports { ROIC_DOUT_N[25] }]; # R2_DOUT7_M IO_L10N_T1_12
set_property PACKAGE_PIN Y25  [get_ports { ROIC_DOUT_P[25] }]; # R2_DOUT7_P IO_L10P_T1_12
set_property PACKAGE_PIN AC24 [get_ports { ROIC_DOUT_N[26] }]; # R2_DOUT8_M IO_L14N_T2_SRCC_12
set_property PACKAGE_PIN AC23 [get_ports { ROIC_DOUT_P[26] }]; # R2_DOUT8_P IO_L14P_T2_SRCC_12
set_property PACKAGE_PIN AC26 [get_ports { ROIC_DOUT_N[27] }]; # R2_DOUT9_M IO_L9N_T1_DQS_12
set_property PACKAGE_PIN AB26 [get_ports { ROIC_DOUT_P[27] }]; # R2_DOUT9_P IO_L9P_T1_DQS_12
set_property PACKAGE_PIN AB25 [get_ports { ROIC_DOUT_N[28] }]; # R2_DOUT10_M IO_L7N_T1_12
set_property PACKAGE_PIN AA25 [get_ports { ROIC_DOUT_P[28] }]; # R2_DOUT10_P IO_L7P_T1_12
set_property PACKAGE_PIN AE25 [get_ports { ROIC_DOUT_N[29] }]; # R2_DOUT11_M IO_L23N_T3_12
set_property PACKAGE_PIN AD25 [get_ports { ROIC_DOUT_P[29] }]; # R2_DOUT11_P IO_L23P_T3_12
set_property PACKAGE_PIN AF25 [get_ports { ROIC_DOUT_N[30] }]; # R2_DOUT12_M IO_L20N_T3_12
set_property PACKAGE_PIN AF24 [get_ports { ROIC_DOUT_P[30] }]; # R2_DOUT12_P IO_L20P_T3_12
set_property PACKAGE_PIN AE26 [get_ports { ROIC_DOUT_N[31] }]; # R2_DOUT13_M IO_L21N_T3_DQS_12
set_property PACKAGE_PIN AD26 [get_ports { ROIC_DOUT_P[31] }]; # R2_DOUT13_P IO_L21P_T3_DQS_12
set_property PACKAGE_PIN V22  [get_ports { ROIC_DOUT_N[32] }]; # R2_DOUT14_M IO_L1N_T0_12
set_property PACKAGE_PIN U22  [get_ports { ROIC_DOUT_P[32] }]; # R2_DOUT14_P IO_L1P_T0_12
set_property PACKAGE_PIN V24  [get_ports { ROIC_DOUT_N[33] }]; # R2_DOUT15_M IO_L3N_T0_DQS_12
set_property PACKAGE_PIN V23  [get_ports { ROIC_DOUT_P[33] }]; # R2_DOUT15_P IO_L3P_T0_DQS_12
set_property PACKAGE_PIN U25  [get_ports { ROIC_DOUT_N[34] }]; # R2_DOUT16_M IO_L2N_T0_12
set_property PACKAGE_PIN U24  [get_ports { ROIC_DOUT_P[34] }]; # R2_DOUT16_P IO_L2P_T0_12
set_property PACKAGE_PIN W26  [get_ports { ROIC_DOUT_N[35] }]; # R2_DOUT17_M IO_L5N_T0_12
set_property PACKAGE_PIN W25  [get_ports { ROIC_DOUT_P[35] }]; # R2_DOUT17_P IO_L5P_T0_12
set_property PACKAGE_PIN W24  [get_ports { ROIC_DOUT_N[36] }]; # R2_DOUT18_M IO_L8N_T1_12
set_property PACKAGE_PIN W23  [get_ports { ROIC_DOUT_P[36] }]; # R2_DOUT18_P IO_L8P_T1_12
set_property PACKAGE_PIN V26  [get_ports { ROIC_DOUT_N[37] }]; # R2_DOUT19_M IO_L4N_T0_12
set_property PACKAGE_PIN U26  [get_ports { ROIC_DOUT_P[37] }]; # R2_DOUT19_P IO_L4P_T0_12
# █▀▀ ▄▀█ ▀█▀ █▀▀
# █▄█ █▀█ ░█░ ██▄
set_property PACKAGE_PIN J24 [get_ports { GATE_SHIFT_CLK1L  }]; # CPV1L O_L22P_T3_A05_D21_14
set_property PACKAGE_PIN H24 [get_ports { GATE_SHIFT_CLK2L  }]; # CPV1R O_L20N_T3_A07_D23_14
set_property PACKAGE_PIN D25 [get_ports { GATE_SHIFT_CLK1R  }]; # CPV2L O_L15N_T2_DQS_DOUT_CSO_B_14
set_property PACKAGE_PIN A24 [get_ports { GATE_SHIFT_CLK2R  }]; # CPV2R O_L4N_T0_D05_14
set_property PACKAGE_PIN F24 [get_ports { GATE_START_PULSE1[5]   }]; # DIO1 IO_L14N_T2_SRCC_14
set_property PACKAGE_PIN F23 [get_ports { GATE_START_PULSE1[4]   }]; # DIO1  IO_L13N_T2_MRCC_14
set_property PACKAGE_PIN E23 [get_ports { GATE_START_PULSE1[3]   }]; # DIO1  IO_L12N_T1_MRCC_14
set_property PACKAGE_PIN E22 [get_ports { GATE_START_PULSE1[2]   }]; # DIO1  IO_L9N_T1_DQS_D13_14
set_property PACKAGE_PIN D24 [get_ports { GATE_START_PULSE1[1]   }]; # DIO1  IO_L11N_T1_SRCC_14
set_property PACKAGE_PIN D23 [get_ports { GATE_START_PULSE1[0]   }]; # DIO1  IO_L11P_T1_SRCC_14
set_property PACKAGE_PIN G17 [get_ports { GATE_START_PULSE1[6]   }]; # DIO1  IO_L11P_T1_SRCC_AD12P_15
set_property PACKAGE_PIN G19 [get_ports { GATE_START_PULSE1[7]   }]; # DIO1  IO_L16P_T2_A28_15
set_property PACKAGE_PIN G20 [get_ports { GATE_START_PULSE1[8]   }]; # DIO1  IO_L18N_T2_A23_15
set_property PACKAGE_PIN F19 [get_ports { GATE_START_PULSE1[9]   }]; # DIO1  IO_L17P_T2_A26_15
set_property PACKAGE_PIN E20 [get_ports { GATE_START_PULSE1[10]  }]; # DIO1  IO_L17N_T2_A25_15
set_property PACKAGE_PIN E18 [get_ports { GATE_START_PULSE1[11]  }]; # DIO1  IO_L13P_T2_MRCC_15
set_property PACKAGE_PIN D21 [get_ports { GATE_START_PULSE2[5]   }]; # DIO2 IO_L7P_T1_D09_14
set_property PACKAGE_PIN C21 [get_ports { GATE_START_PULSE2[4]   }]; # DIO2 IO_L10P_T1_D14_14
set_property PACKAGE_PIN B21 [get_ports { GATE_START_PULSE2[3]   }]; # DIO2 IO_L10N_T1_D15_14
set_property PACKAGE_PIN G21 [get_ports { GATE_START_PULSE2[2]   }]; # DIO2 IO_L19N_T3_A09_D25_VREF_14
set_property PACKAGE_PIN H21 [get_ports { GATE_START_PULSE2[1]   }]; # DIO2 IO_L19P_T3_A10_D26_14
set_property PACKAGE_PIN J21 [get_ports { GATE_START_PULSE2[0]   }]; # DIO2 IO_L21P_T3_DQS_14
set_property PACKAGE_PIN D20 [get_ports { GATE_START_PULSE2[6]   }]; # DIO2 IO_L15N_T2_DQS_ADV_B_15
#set_property PACKAGE_PIN D19 [get_ports { GATE_START_PULSE2[7]   }]; # DIO2 IO_L15P_T2_DQS_15
#set_property PACKAGE_PIN F18 [get_ports { GATE_START_PULSE2[8]   }]; # DIO2 IO_L11N_T1_SRCC_AD12N_15
#set_property PACKAGE_PIN F17 [get_ports { GATE_START_PULSE2[9]   }]; # DIO2 IO_L12P_T1_MRCC_AD5P_15
#set_property PACKAGE_PIN G16 [get_ports { GATE_START_PULSE2[10]  }]; # DIO2 IO_L7N_T1_AD10N_15
#set_property PACKAGE_PIN G15 [get_ports { GATE_START_PULSE2[11]  }]; # DIO2 IO_L8P_T1_AD3P_15
set_property PACKAGE_PIN A23 [get_ports { GATE_OUT_EN1L  }]; # OE1L O_L4P_T0_D04_14
set_property PACKAGE_PIN F22 [get_ports { GATE_OUT_EN2L  }]; # OE1R O_L12P_T1_MRCC_14
set_property PACKAGE_PIN G22 [get_ports { GATE_OUT_EN1R  }]; # OE2L O_L13P_T2_MRCC_14
set_property PACKAGE_PIN F25 [get_ports { GATE_OUT_EN2R  }]; # OE2R O_L17P_T2_A14_D30_14
set_property PACKAGE_PIN C22 [get_ports { GATE_ALL_OUT   }]; # XONL IO_L7N_T1_D10_14
set_property PACKAGE_PIN H23 [get_ports { GATE_ALL_OUT_R }]; # XONR IO_L20P_T3_A08_D24_14
set_property PACKAGE_PIN H22 [get_ports { GATE_CONFIG[0] }]; # INDL/R IO_L21N_T3_DQS_A06_D22_14
set_property PACKAGE_PIN G24 [get_ports { GATE_CONFIG[1] }]; # FB  IO_L14P_T2_SRCC_14
set_property PACKAGE_PIN C24 [get_ports { GATE_CONFIG[2] }]; # UD  IO_L6N_T0_D08_VREF_14
set_property PACKAGE_PIN E10 [get_ports { GATE_VGH_RST   }]; # VGH_FLK IO_L12P_T1_MRCC_16

# █▀▀ ▀█▀ █▀▀
# ██▄ ░█░ █▄▄
set_property PACKAGE_PIN M2   [get_ports { PHY_SIP[1]    }]
set_property PACKAGE_PIN P2   [get_ports { PHY_SIP[0]    }]
set_property PACKAGE_PIN H6   [get_ports { PHY_CLK_P     }]
set_property PACKAGE_PIN C26  [get_ports { EEPROM_SCL    }]; # IO_L5N_T0_D07_14
set_property PACKAGE_PIN B26  [get_ports { EEPROM_SDA    }]; # IO_L3N_T0_DQS_EMCCLK_14
set_property PACKAGE_PIN B9   [get_ports { EXT_OUT       }];
#set_property PACKAGE_PIN C9   [get_ports { EXT_IN        }]; # EXPOSURE_IN_C?? IO_L10P_T1_16
set_property PACKAGE_PIN A8   [get_ports { EXT_IN        }]; # #230531
set_property PACKAGE_PIN AB10 [get_ports { SYSTEM_CLK_N  }]; # IO_L14N_T2_SRCC_33
set_property PACKAGE_PIN AA10 [get_ports { SYSTEM_CLK_P  }]; # IO_L14P_T2_SRCC_33
set_property PACKAGE_PIN B20  [get_ports { TEMP_SCL      }]; # IO_L8P_T1_D11_14
set_property PACKAGE_PIN A20  [get_ports { TEMP_SDA      }]; # IO_L8N_T1_D12_14
set_property PACKAGE_PIN J23  [get_ports { UART_RX       }]; # IO_L24N_T3_A00_D16_14
set_property PACKAGE_PIN K23  [get_ports { UART_TX       }]; # IO_L24P_T3_A01_D17_14
set_property PACKAGE_PIN E21  [get_ports { STATUS_LED[0] }]; # FPGA_STATUS_LED IO_L9P_T1_DQS_14
set_property PACKAGE_PIN A10  [get_ports { STATUS_LED[1] }]; # FAULT_STATUS_LED IO_L22N_T3_16
# ETH PHY
set_property PACKAGE_PIN C11 [get_ports { PHY_INTN    }]; # IO_L13N_T2_MRCC_16
set_property PACKAGE_PIN G14 [get_ports { PHY_RESET_N }]; # PHY_#RESETN IO_L5N_T0_16
set_property PACKAGE_PIN D9  [get_ports { PHY_MDC     }]; # IO_L8P_T1_16
set_property PACKAGE_PIN B10 [get_ports { PHY_MDIO    }]; # IO_L22P_T3_16
# PWR
set_property PACKAGE_PIN D11 [get_ports { PWR_EN[0]  }]; # VGH_EN   IO_L14N_T2_SRCC_16
set_property PACKAGE_PIN C12 [get_ports { PWR_EN[1]  }]; # VBIAS_EN  #UR ADC_ADI ##################
set_property PACKAGE_PIN L22 [get_ports { PWR_EN[2]  }]; # GATE_3.3V_EN IO_L23P_T3_A03_D19_14
set_property PACKAGE_PIN F10 [get_ports { PWR_EN[3]  }]; # VGL_EN   IO_L11N_T1_SRCC_16
set_property PACKAGE_PIN F14 [get_ports { PWR_EN[4]  }]; # ROIC_EN   IO_L15P_T2_DQS_16
set_property PACKAGE_PIN C13 [get_ports { PWR_EN[5]  }]; # R1_AVDD1_EN  IO_L19N_T3_VREF_16
set_property PACKAGE_PIN B15 [get_ports { PWR_EN[6]  }]; # R1_AVDD2_EN  IO_L23P_T3_16
set_property PACKAGE_PIN E12 [get_ports { PWR_EN[7]  }]; # #UR ADC_SCLK ###########################
set_property PACKAGE_PIN D13 [get_ports { PWR_EN[8]  }]; # #UR ADC_nSYNQ ##########################
set_property PACKAGE_PIN F17 [get_ports { PWR_EN[9]  }]; # #UR HV_SW ##############################
set_property PACKAGE_PIN F18 [get_ports { PWR_EN[10] }]; # #UR HVR_SW #############################
# FLASH 
set_property PACKAGE_PIN B24 [get_ports { FLASH_D[0]   }]; # IO_L1P_T0_D00_MOSI_14
set_property PACKAGE_PIN A25 [get_ports { FLASH_D[1]   }]; # IO_L1N_T0_D01_DIN_14
set_property PACKAGE_PIN B22 [get_ports { FLASH_D[2]   }]; # IO_L2P_T0_D02_14
set_property PACKAGE_PIN A22 [get_ports { FLASH_D[3]   }]; # IO_L2N_T0_D03_14
set_property PACKAGE_PIN C23 [get_ports { FLASH_FCS    }]; # IO_L6P_T0_FCS_B_14
set_property PACKAGE_PIN B16 [get_ports { FLASH_2_CLK  }]; # IO_L1N_T0_AD0N_15
set_property PACKAGE_PIN A19 [get_ports { FLASH_2_D[0] }]; # IO_L2N_T0_AD8N_15
set_property PACKAGE_PIN B17 [get_ports { FLASH_2_D[1] }]; # IO_L3P_T0_DQS_AD1P_15
set_property PACKAGE_PIN A17 [get_ports { FLASH_2_D[2] }]; # IO_L3N_T0_DQS_AD1N_15
set_property PACKAGE_PIN C19 [get_ports { FLASH_2_D[3] }]; # IO_L4P_T0_AD9P_15
set_property PACKAGE_PIN A18 [get_ports { FLASH_2_FCS  }]; # IO_L2P_T0_AD8P_15

##################
##### config #####
# set_property PACKAGE_PIN J7  [get_ports { FPGA_DONE   }]; # DONE_0
# set_property PACKAGE_PIN G7  [get_ports { FPGA_INIT_B }]; # INIT_B_0
# set_property PACKAGE_PIN P6  [get_ports { FPGA_PROG_B }]; # PROGRAM_B_0
# set_property PACKAGE_PIN B25 [get_ports { FPGA_PUDC_B }]; # IO_L3P_T0_DQS_PUDC_B_14
# set_property PACKAGE_PIN V13 [get_ports { HP SPARE    }]; # IO_0_VRN_32
# set_property PACKAGE_PIN L8  [get_ports { JTAG_TCK    }]; # TCK_0
# set_property PACKAGE_PIN R6  [get_ports { JTAG_TDI    }]; # TDI_0
# set_property PACKAGE_PIN R7  [get_ports { JTAG_TDO    }]; # TDO_0
# set_property PACKAGE_PIN N8  [get_ports { JTAG_TMS    }]; # TMS_0
# set_property PACKAGE_PIN T5  [get_ports { MODE_0      }]; # M0_0
# set_property PACKAGE_PIN T2  [get_ports { MODE_1      }]; # M1_0
# set_property PACKAGE_PIN P5  [get_ports { MODE_2      }]; # M2_0

####################
##### not used #####
# set_property PACKAGE_PIN G25 [get_ports { COMP1_EN  }]; # IO_L16P_T2_CSI_B_14
# set_property PACKAGE_PIN G26 [get_ports { COMP3_EN  }]; # IO_L16N_T2_A15_D31_14

# set_property PACKAGE_PIN E26 [get_ports { F_GPIO1  }]; # was DAC IO_L17N_T2_A13_D29_14
# set_property PACKAGE_PIN J26 [get_ports { F_GPIO2  }]; # was DAC IO_L18P_T2_A12_D28_14
# set_property PACKAGE_PIN H26 [get_ports { F_GPIO3  }]; # was DAC IO_L18N_T2_A11_D27_14
# set_property PACKAGE_PIN J25 [get_ports { F_GPIO4  }]; # was DAC IO_L22N_T3_A04_D20_14

# set_property PACKAGE_PIN D26 [get_ports { TP54   }]; # IO_L5P_T0_D06_14
# set_property PACKAGE_PIN A13 [get_ports { TP65   }]; # IO_L24P_T3_16
# set_property PACKAGE_PIN A12 [get_ports { TP66   }]; # IO_L24N_T3_16
# set_property PACKAGE_PIN E25 [get_ports { TP8   }]; # IO_L15P_T2_DQS_RDWR_B_14
# set_property PACKAGE_PIN P7 [get_ports { VDD   }]; # CFGBVS_0
# set_property PACKAGE_PIN M5 [get_ports { VDD_1.2V  }]; # MGTAVTTRCAL_115
# set_property PACKAGE_PIN M6 [get_ports { VDD_1.2V  }]; # MGTRREF_115
# set_property PACKAGE_PIN M12 [get_ports { VDD_1.8V  }]; # VCCADC_0
# set_property PACKAGE_PIN E8 [get_ports { VDD_1.8V  }]; # VCCBATT_0
# set_property PACKAGE_PIN W4 [get_ports { VREF   }]; # IO_L6N_T0_VREF_34
# set_property PACKAGE_PIN AD3 [get_ports { VREF   }]; # IO_L19N_T3_VREF_34

# █ █▀█
# █ █▄█
# Unused output port
set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1]
set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2]
set_property IO_BUFFER_TYPE NONE [get_ports tb_aligndone]
set_property IO_BUFFER_TYPE NONE [get_ports tb_alignreq]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_ALL_OUT_R      ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1L       ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN1R       ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2L       ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_OUT_EN2R       ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK1L    ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK1R    ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK2L    ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_SHIFT_CLK2R    ]
# set_property IO_BUFFER_TYPE NONE [get_ports GATE_START_PULSE2[0]]
set_property IO_BUFFER_TYPE NONE [get_ports PWR_EN[5]           ]
# set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]
# set_property BITSTREAM.General.UnconstrainedPins {Allow} [current_design]

set_property IOSTANDARD DIFF_SSTL15 [get_ports { SYSTEM_CLK_N }]; # IO_L14N_T2_SRCC_33
set_property IOSTANDARD DIFF_SSTL15 [get_ports { SYSTEM_CLK_P }]; # IO_L14P_T2_SRCC_33
set_property IOSTANDARD LVCMOS33 [get_ports { EEPROM_SCL  }]; # IO_L5N_T0_D07_14
set_property IOSTANDARD LVCMOS33 [get_ports { EEPROM_SDA  }]; # IO_L3N_T0_DQS_EMCCLK_14
set_property IOSTANDARD LVCMOS33 [get_ports { EXT_OUT  }];
set_property IOSTANDARD LVCMOS33 [get_ports { EXT_IN   }]; # EXPOSURE_IN_C?? IO_L10P_T1_16
set_property IOSTANDARD LVCMOS33 [get_ports { TEMP_SCL  }]; # IO_L8P_T1_D11_14
set_property IOSTANDARD LVCMOS33 [get_ports { TEMP_SDA  }]; # IO_L8N_T1_D12_14
set_property IOSTANDARD LVCMOS33 [get_ports { UART_RX  }]; # IO_L24N_T3_A00_D16_14
set_property IOSTANDARD LVCMOS33 [get_ports { UART_TX  }]; # IO_L24P_T3_A01_D17_14
set_property IOSTANDARD LVCMOS33 [get_ports { STATUS_LED[0] }]; # FPGA_STATUS_LED IO_L9P_T1_DQS_14
set_property IOSTANDARD LVCMOS33 [get_ports { STATUS_LED[1] }]; # FAULT_STATUS_LED IO_L22N_T3_16

set_property IOSTANDARD LVCMOS33 [get_ports { GATE_SHIFT_CLK1L      }]; # CPV1L O_L22P_T3_A05_D21_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_SHIFT_CLK2L      }]; # CPV1R O_L20N_T3_A07_D23_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_SHIFT_CLK1R      }]; # CPV2L O_L15N_T2_DQS_DOUT_CSO_B_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_SHIFT_CLK2R      }]; # CPV2R O_L4N_T0_D05_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[0]  }]; # DIO1 IO_L14N_T2_SRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[1]  }]; # DIO1  IO_L13N_T2_MRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[2]  }]; # DIO1  IO_L12N_T1_MRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[3]  }]; # DIO1  IO_L9N_T1_DQS_D13_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[4]  }]; # DIO1  IO_L11N_T1_SRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[5]  }]; # DIO1  IO_L11P_T1_SRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[6]  }]; # DIO1  IO_L11P_T1_SRCC_AD12P_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[7]  }]; # DIO1  IO_L16P_T2_A28_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[8]  }]; # DIO1  IO_L18N_T2_A23_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[9]  }]; # DIO1  IO_L17P_T2_A26_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[10] }]; # DIO1  IO_L17N_T2_A25_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE1[11] }]; # DIO1  IO_L13P_T2_MRCC_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[0]  }]; # DIO2 IO_L7P_T1_D09_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[1]  }]; # DIO2 IO_L10P_T1_D14_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[2]  }]; # DIO2 IO_L10N_T1_D15_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[3]  }]; # DIO2 IO_L19N_T3_A09_D25_VREF_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[4]  }]; # DIO2 IO_L19P_T3_A10_D26_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[5]  }]; # DIO2 IO_L21P_T3_DQS_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[6]  }]; # DIO2 IO_L15N_T2_DQS_ADV_B_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[7]  }]; # DIO2 IO_L15P_T2_DQS_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[8]  }]; # DIO2 IO_L11N_T1_SRCC_AD12N_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[9]  }]; # DIO2 IO_L12P_T1_MRCC_AD5P_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[10] }]; # DIO2 IO_L7N_T1_AD10N_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_START_PULSE2[11] }]; # DIO2 IO_L8P_T1_AD3P_15
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_OUT_EN1L         }]; # OE1L O_L4P_T0_D04_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_OUT_EN2L         }]; # OE1R O_L12P_T1_MRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_OUT_EN1R         }]; # OE2L O_L13P_T2_MRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_OUT_EN2R         }]; # OE2R O_L17P_T2_A14_D30_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_ALL_OUT          }]; # XONL IO_L7N_T1_D10_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_ALL_OUT_R        }]; # XONR IO_L20P_T3_A08_D24_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_CONFIG[0]        }]; # INDL/R IO_L21N_T3_DQS_A06_D22_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_CONFIG[1]        }]; # FB  IO_L14P_T2_SRCC_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_CONFIG[2]        }]; # UD  IO_L6N_T0_D08_VREF_14
set_property IOSTANDARD LVCMOS33 [get_ports { GATE_VGH_RST          }]; # VGH_FLK IO_L12P_T1_MRCC_16

set_property IOSTANDARD LVCMOS33 [get_ports { PHY_INTN    }]; # IO_L13N_T2_MRCC_16
set_property IOSTANDARD LVCMOS33 [get_ports { PHY_RESET_N }]; # PHY_#RESETN IO_L5N_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { PHY_MDC     }]; # IO_L8P_T1_16
set_property IOSTANDARD LVCMOS33 [get_ports { PHY_MDIO    }]; # IO_L22P_T3_16

set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[0]  }]; # VGH_EN   IO_L14N_T2_SRCC_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[1]  }]; # VBIAS_EN  IO_L13P_T2_MRCC_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[2]  }]; # GATE_3.3V_EN IO_L23P_T3_A03_D19_14
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[3]  }]; # VGL_EN   IO_L11N_T1_SRCC_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[4]  }]; # ROIC_EN   IO_L15P_T2_DQS_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[5]  }]; # R1_AVDD1_EN  IO_L19N_T3_VREF_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[6]  }]; # R1_AVDD2_EN  IO_L23P_T3_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[7]  }]; # R2_AVDD1_EN  IO_L18N_T2_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[8]  }]; # R2_AVDD2_EN  IO_L17N_T2_16
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[9]  }]; # UR HV_SW
set_property IOSTANDARD LVCMOS33 [get_ports { PWR_EN[10] }]; # UR HVR_SW

# set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_#RESET }]; # IO_L23N_T3_A02_D18_14
# set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_CLK  }]; # CCLK_0
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_D[0]   }]; # IO_L1P_T0_D00_MOSI_14
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_D[1]   }]; # IO_L1N_T0_D01_DIN_14
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_D[2]   }]; # IO_L2P_T0_D02_14
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_D[3]   }]; # IO_L2N_T0_D03_14
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_FCS    }]; # IO_L6P_T0_FCS_B_14
# set_property IOSTANDARD LVCMOS33  [get_ports { FLASH_2_#RESET }]; # IO_L1P_T0_AD0P_15
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_2_CLK  }]; #  IO_L1N_T0_AD0N_15
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_2_D[0] }]; # IO_L2N_T0_AD8N_15
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_2_D[1] }]; # IO_L3P_T0_DQS_AD1P_15
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_2_D[2] }]; # IO_L3N_T0_DQS_AD1N_15
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_2_D[3] }]; # IO_L4P_T0_AD9P_15
set_property IOSTANDARD LVCMOS33 [get_ports { FLASH_2_FCS  }]; # IO_L2P_T0_AD8P_15

set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_MCLK[0]   }]; # F_R1_MCLK IO_L5P_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SCLK[0]   }]; # F_R1_SCLK IO_L21P_T3_DQS_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDI[0]    }]; # F_R1_SDI IO_L15N_T2_DQS_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_CS[0]     }]; # IF_R1_SEN O_L21N_T3_DQS_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SYNC[0]   }]; # F_R1_SYNC IO_L23N_T3_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_TP_SEL[0] }]; # F_R1_TP_SEL IO_L19P_T3_16

set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_MCLK[1]   }]; # F_R2_MCLK  IO_L17P_T2_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SCLK[1]   }]; # F_R2_SCLK  IO_L14P_T2_SRCC_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDI[1]    }]; # F_R2_SDI  IO_L20N_T3_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_CS[1]     }]; # F_R2_SEN  IO_L6N_T0_VREF_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SYNC[1]   }]; # F_R2_SYNC  IO_L18P_T2_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_TP_SEL[1] }]; # F_R2_TP_SEL IO_L16N_T2_16

set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[0]  }]; # F_R1_SDO_1 IO_L1P_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[1]  }]; # F_R1_SDO_2 IO_L4P_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[2]  }]; # F_R1_SDO_3 IO_L2P_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[3]  }]; # F_R1_SDO_4 IO_L6P_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[4]  }]; # F_R1_SDO_5 IO_L3N_T0_DQS_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[5]  }]; # F_R1_SDO_6 IO_L20P_T3_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[6]  }]; # F_R1_SDO_7 IO_L16P_T2_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[7]  }]; # F_R2_SDO_1  IO_L1N_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[8]  }]; # F_R2_SDO_2  IO_L2N_T0_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[9]  }]; # F_R2_SDO_3  IO_L7N_T1_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[10] }]; # F_R2_SDO_4  IO_L8N_T1_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[11] }]; # F_R2_SDO_5  IO_L7P_T1_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[12] }]; # F_R2_SDO_6  IO_L12N_T1_MRCC_16
set_property IOSTANDARD LVCMOS33 [get_ports { F_ROIC_SDO[13] }]; # F_R2_SDO_7  IO_L4N_T0_16

# GPIO 230922 #
set_property PACKAGE_PIN E26 [get_ports F_GPIO1]
set_property PACKAGE_PIN J26 [get_ports F_GPIO2]
set_property PACKAGE_PIN H26 [get_ports F_GPIO3]
set_property PACKAGE_PIN J25 [get_ports F_GPIO4]

set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO1]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO2]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO3]
set_property IOSTANDARD LVCMOS33 [get_ports F_GPIO4]

# ▀█▀ █ █▀▄▀█ █▀▀
# ░█░ █ █░▀░█ ██▄
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

set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks SYNTH.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
# #230417
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks SYNTH.G_rxaui_2p5G.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks SYNTH.G_rxaui_2p5G.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks SYNTH.G_rxaui_2p5G.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK]

#set_clock_groups -asynchronous \
#-group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/ROIC_CLK_GEN/inst/plle2_adv_inst/CLKOUT0]] \
#-group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] \
#-group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
#-group [get_clocks SYNTH.G_rxaui_2p5G.RXAUI_INST/U0/rxaui_block_i/gt0_wrapper_i/gtxe2_i/TXOUTCLK] \

# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]] -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/mig_7series_0/u_cpu_mig_7series_0_1_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
# set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] -group [get_clocks -of_objects [get_pins SYNTH.GEN_CPU_14.CPU_INST/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]

#v2
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/sdram_0/u_cpu_sdram_0_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT0]]
set_clock_groups -asynchronous -group [get_clocks -of_objects [get_pins U0_TI_TFT_TOP/U0_TI_CLOCK_MANAGER/CLK_GEN/inst/plle2_adv_inst/CLKOUT1]] 
                               -group [get_clocks -of_objects [get_pins GEV_CPU/cpu_i/clk_wiz_0/inst/CLK_CORE_DRP_I/clk_inst/mmcm_adv_inst/CLKOUT1]]