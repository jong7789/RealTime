/*
 * uart_cmd.c
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#include "command.h"
#include <xparameters.h> //$ 260421 For XPAR_M1_AXI_GEV_BASEADDR
#include "func_printf.h"
#include "math.h"

#include "gige.h"
#include "phy.h"
#include "framebuf.h"
#include "func_basic.h"
#include "func_cmd.h"
#include "display.h"
#include "flash.h"
#include "user.h"

#include "clk_wiz_header.h" //mbh
//#include "xaxipmon.h"      //# 2605062100 APM driver for 'apm' command
//# 2605191537 Guard APM driver — axi_perf_mon_0 may be absent from BD
#ifdef XPAR_AXI_PERF_MON_0_DEVICE_ID
  #include "xaxipmon.h"
  #define APM_PRESENT 1
#else
  #define APM_PRESENT 0
#endif
#include "int.h"           //# 2605181144 fb_tx_dot_en / fb_err_msg_en runtime toggles

const CMD_STRUCT CMD_MAT[MAX_CMD_NUM] = {
    {"h"        , UART_CMD_h            , "Display All of Command Descriptions"        , 0 },
    {"auth"     , UART_CMD_auth         , "Select Access Authority"                    , 0 },
    {"stat"     , UART_CMD_stat         , "Display Current Status"                     , 0 },
    {"psel"     , UART_CMD_psel         , "Select Test Pattern"                        , 0 },
    {"bmode"    , UART_CMD_bmode        , "Control Binning Mode"                       , 0 },
    {"tmode"    , UART_CMD_tmode        , "Control Trigger Mode"                       , 0 },
    {"tdly"     , UART_CMD_tdly         , "Control Trigger Delay"                      , 0 },
    {"smode"    , UART_CMD_smode        , "Control Shutter Mode"                       , 0 },
    {"emode"    , UART_CMD_emode        , "Control EWT Mode"                           , 0 },
    {"roi"      , UART_CMD_roi          , "Control ROI"                                , 0 },
    {"frate"    , UART_CMD_frate        , "Control Frame Rate"                         , 0 },
    {"ewt"      , UART_CMD_ewt          , "Control Global Shutter EWT"                 , 0 },
    {"max"      , UART_CMD_max          , "Read Range of Frame Rate and Global EWT"    , 0 },
    {"gain"     , UART_CMD_gain         , "Control Gain Calibration Mode"              , 0 },
    {"offset"   , UART_CMD_offset       , "Control Offset Calibration Mode"            , 0 },
    {"defect"   , UART_CMD_defect       , "Control Defect Calibration Mode"            , 0 },
    {"dmap"     , UART_CMD_dmap         , "View Defect Map"                            , 0 },
    {"ghost"    , UART_CMD_ghost        , "Execute Ghost Reduction"                    , 0 },
    {"ifs"      , UART_CMD_ifs          , "Control Analog Gain"                        , 0 }, // dskim
    {"dgain"    , UART_CMD_dgain        , "Control Digital Gain"                       , 0 },
    {"iproc"    , UART_CMD_iproc        , "Select Image Processing Mode"               , 0 },
    {"wus"      , UART_CMD_wus          , "Write Current User Setting"                 , 0 },
    {"rus"      , UART_CMD_rus          , "Read Current User Setting"                  , 0 },
//    {"debug"    , UART_CMD_debug        , "Read Current User Setting(Debug)"           , 0 }, // dskim
    {"rus2"     , UART_CMD_rus2         , "Read User Setting + NUC Info (Debug)"       , 0 }, //# 2605201841 renamed from "debug"
    {"rtime"    , UART_CMD_rtime        , "Display Running Time"                       , 0 },
    {"rtemp"    , UART_CMD_rtemp        , "Read Temperature"                           , 0 },
    {"rtempraw" , UART_CMD_rtempraw     , "XML temp source: 0=set temp, 1=raw die"     , 0 }, //# 2608191842
    {"reboot"   , UART_CMD_reboot       , "Rebooting"                                  , 0 },
    {"edgec"    , UART_CMD_edge_cut     , "Edge Cut"                                   , 0 }, // dskim
    {"edges"    , UART_CMD_edge_save    , "Write Edge Value to Flash Memory"           , 0 }, // dskim
    {"rtp"      , UART_CMD_rtp          , "ROIC read timing profile "                  , 0 }, // mbh 210105
    {"gtp"      , UART_CMD_gtp          , "FPGA read timing profile "                  , 0 }, // mbh 210121
    {"atp"      , UART_CMD_atp          , "Assembled read timing profile "             , 0 }, // mbh 210129
    {"wtp"      , UART_CMD_wtp          , "ROIC write timing profile "                 , 0 }, // mbh 210118
    {"mclk"     , UART_CMD_mclk         , "Mclk setting for ROIC TG "                  , 0 }, // mbh 210114
    {"rclk"     , UART_CMD_rclk         , "Real clock read mclk, dclk and Roic dclk"   , 0 }, // mbh 210115
    {"diag"     , UART_CMD_diag         , "diagnosis of system"                        , 0 }, // mbh 210324
    {"wsm"      , UART_CMD_wsm          , "state machine read starter"                 , 0 }, // mbh 211214
    {"rsm"      , UART_CMD_rsm          , "read fpga state machine"                    , 0 }, // mbh 210406
    {"d2m"      , UART_CMD_d2m          , "d2 mode"                                    , 0 }, // mbh 210618
    {"edge"     , UART_CMD_edge         , "edge"                                       , 0 }, // mbh 210923
    {"dnr"      , UART_CMD_dnr          , "dnr"                                        , 0 }, // mbh 210923
    {"acc"      , UART_CMD_acc          , "acc"                                        , 0 }, // mbh 210928
    {"spc"      , UART_CMD_spc          , "short pixel cover"                          , 0 }, //$ 2607241407
    {"eao"      , UART_CMD_eao          , "1ernal Auto offset"                         , 0 }, // mbh 211025
    {"trig"     , UART_CMD_trig         , "API External Trigger"                       , 0 }, // mbh 211105
    {"rom"      , UART_CMD_rom          , "Flash rom, eeprom write ready command"      , 0 }, // mbh 211116
    {"fwtrig"   , UART_CMD_fwtrig       , "FW External Trigger"                        , 0 }, // mbh 211216
    {"extrst"   , UART_CMD_extrst       , "External reset mode, detect time"           , 0 }, // mbh 220105
//  {"racc"     , UART_CMD_racc         , "read acc"                                   , 0 }, // mbh 220329
    {"osd"      , UART_CMD_osd          , "debug osd"                                  , 0 }, // mbh 220404
    {"pwdac"    , UART_CMD_pwdac        , "EXT810R HV DAC driver"                      , 0 }, // mbh 220429
//  {"pixpos"   , UART_CMD_pixpos       , "diag pixel read position"                   , 0 }, // mbh 220524
    {"rstdev"   , UART_CMD_rstdev       , "phy reset device"                           , 0 }, // mbh 220525
    {"fch"      , UART_CMD_fch          , "flash check"                                , 0 }, // mbh 220919
    {"flashcheck",UART_CMD_fch          , "flash check"                                , 0 }, // mbh 220919
    {"fpdiff"   , UART_CMD_fpdiff       , "fpga diff"                                  , 0 }, // mbh 220921
    {"fwdiff"   , UART_CMD_fwdiff       , "fw diff"                                    , 0 }, // mbh 220921
    {"dmesg"    , UART_CMD_dmesg        , "boot log, diagnosis message"                , 0 }, // mbh 220928
    {"flash4b"  , UART_CMD_flash4b      , "flash 4bit comm set"                        , 0 }, // mbh 220930
    {"stop"     , UART_CMD_stop         , "fw stop"                                    , 0 }, // mbh 221021
    {"triglog"  , UART_CMD_triglog      , "external triglog on hwdebugger"             , 0 }, // mbh 230809
    {"topv"     , UART_CMD_topv         , "top value for gain, bnc, eq"                , 0 }, // mbh 230904
    {"bnc"      , UART_CMD_bnc          , "bright & contrast on/off"                   , 0 }, // mbh 230824
    {"eq"       , UART_CMD_eq           , "equalization 0~7"                           , 0 }, // mbh 230824
    {"able"     , UART_CMD_able         , "print function able list"                   , 0 }, // mbh 230926
	{"romdiag"  , UART_CMD_romdiag      , "rom diagnosis"                              , 0 }, // mbh 231017
	{"romread"  , UART_CMD_romread      , "rom read"                                   , 0 }, // mbh 231017
	{"ropertime", UART_CMD_ropertime    , "read operation time"                        , 0 }, // mbh 231121
	{"port"     , UART_CMD_port         , "Select PHY Port (0:Marvell 1:SFP)"          , 0 }, //# 260421 add port cmd
	{"m88deinit", UART_CMD_m88deinit    , "Manually run m88x33xx_deinit()"             , 0 }, //# 2605121343 manual M88X debug cmds
	{"m88initx" , UART_CMD_m88initx     , "Manually run m88x33xx_initx(RXAUI)"         , 0 }, //# 2605121343
	{"m88inity" , UART_CMD_m88inity     , "Manually run m88x33xx_inity(RXAUI)"         , 0 }, //# 2605121343
	{"m88init"  , UART_CMD_m88init      , "Manually run m88x33xx_init(RXAUI)"          , 0 }, //# 2605121343
	{"m88rst"   , UART_CMD_m88rst       , "Hard reset PHY (PHY_RESET_N pulse)"         , 0 }, //# 2605121451
	{"gigeinit" , UART_CMD_gigeinit     , "Run gige_init + set_data_rates/link/sceba"  , 0 }, //# 2605121447
//	{"apm"      , UART_CMD_apm          , "APM bandwidth [ms/dir] (default 200)"       , 0 }, //# 2605062100 APM bandwidth (Gbps + %)
//	{"apm"      , UART_CMD_apm          , "APM BW+stall [ms] (default 200, parallel)"  , 0 }, //# 2605071100 8-counter parallel: bytes+tran+avgLat+idle
	{"apm"      , UART_CMD_apm          , "APM 3-slot BW [ms] (default 200, seq)"      , 0 }, //# 2605071158 3 slots sequential: M00/GEV/Sensor
	{"ddrburst" , UART_CMD_ddrburst     , "DDR AXI burst [N] (32/64/128/256, runtime)" , 0 }, //# 2605071529 quantize-down then map to mode 0..3
	{"watch"    , UART_CMD_watch        , "REG watch: 1=on 0=off [+addrs to add/remove]", 0 }, //# 2605131158
	{"pwr"      , UART_CMD_pwr          , "opwr_en override: pwr / pwr 0 / pwr 1 <hex>", 0 }, //$ 2607141553

    {"tser"     , UART_CMD_tser         , "Access TFT Serial Number"                   , 0 },
    {"pser"     , UART_CMD_pser         , "Access Panel Serial Number"                 , 0 },
    {"ver"      , UART_CMD_ver          , "Read FPGA & FW Version"                     , 0 },
    {"reg"      , UART_CMD_reg          , "Access UI Register"                         , 0 },
    {"dreg"     , UART_CMD_dreg         , "Access DDR3 Register"                       , 0 },
    {"preg"     , UART_CMD_preg         , "Access PHY Register"                        , 0 },
    {"rreg"     , UART_CMD_rreg         , "Access ROIC Register"                       , 0 },
    {"xreg"     , UART_CMD_xreg         , "Access gige Register"                       , 0 },
    {"areg"     , UART_CMD_areg         , "Access All of FPGA Register"                , 0 },
    {"flash"    , UART_CMD_flash        , "Access Flash Memory"                        , 0 },
    {"rflash"   , UART_CMD_rflash       , "read Flash Memory"                          , 0 },
    {"eeprom"   , UART_CMD_eeprom       , "Access EEPROM"                              , 0 },
    {"erase"    , UART_CMD_erase        , "Erase Memory Data"                          , 2 },
    {"cddr"     , UART_CMD_cddr         , "Check DDR3 Data"                            , 0 },
    {"wddr"     , UART_CMD_wddr         , "Write Image to DDR3"                        , 0 },
    {"rddr"     , UART_CMD_rddr         , "read Image value from DDR3"                 , 0 },
    {"bcal"     , UART_CMD_bcal         , "HW bcal (direct bw_align, repeater)"        , 0 }, // 2604251300 route bcal -> UART_CMD_bcal (HW)
//  {"bcal"     , UART_CMD_bcal1        , "Bit align calibration repeater"             , 0 },
    {"bcal1"    , UART_CMD_bcal1        , "Bit align calibration repeater (token)"     , 0 },
    {"bcalfw"   , UART_CMD_bcalfw       , "FW-driven bit/word align (debug, verbose)"  , 0 }, // 2604242200
    {"bcalfwi"  , UART_CMD_bcalfwi      , "bcalfw init (enter fw_mode + ROIC test)"    , 0 }, // 2604250010
    {"bcalfwx"  , UART_CMD_bcalfwx      , "bcalfw exit (leave fw_mode + ROIC normal)"  , 0 }, // 2604250010
    {"bcalfws"  , UART_CMD_bcalfws      , "bcalfw stable [ch] (no ch = all ROIC_NUM)"  , 0 }, // 2604250010
    {"bcalfww"  , UART_CMD_bcalfww      , "bcalfw word [ch] (no ch = all ROIC_NUM)"    , 0 }, // 2604250010
    {"tempbcal" , UART_CMD_tempbcal     , "temp auto bcal off for testing"             , 0 },
    {"gcal"     , UART_CMD_gcal         , "Get Calibration Parameter"                  , 0 },
    {"ucal"     , UART_CMD_ucal         , "Update Calibration Parameter"               , 0 },
    {"dcal"     , UART_CMD_dcal         , "Find Defect"                                , 0 },
    {"sens"     , UART_CMD_sens         , "Select Defect Detection Sensitivity"        , 0 },
    {"wrdot"    , UART_CMD_wrdot        , "Write Row Defect Manually"                  , 0 },
    {"wcdot"    , UART_CMD_wcdot        , "Write Column Defect Manually"               , 0 },
    {"wdot"     , UART_CMD_wdot         , "Write Defect Manually"                      , 0 },
    {"rdot"     , UART_CMD_rdot         , "Read Defect"                                , 0 },
    {"cdot"     , UART_CMD_cdot         , "Clear Defect"                               , 0 },
    {"wns"      , UART_CMD_wns          , "Write NUC Parameter to Flash Memory"        , 0 },
    {"rns"      , UART_CMD_rns          , "Read NUC Parameter from Flash Memory"       , 0 },
    {"wds"      , UART_CMD_wds          , "Write Defect Parameter to Flash Memory"     , 0 },
    {"rds"      , UART_CMD_rds          , "Read Defect Parameter from Flash Memory"    , 0 },
    {"hwdbg"    , UART_CMD_hwdbg        , "Hardware Debugging Mode"                    , 0 },
    {"bright"   , UART_CMD_bright       , "Control Brightness"                         , 0 },
    {"contra"   , UART_CMD_contra       , "Control Contrast"                           , 0 },
    {"gmode"    , UART_CMD_gmode        , "Control Grab Mode"                          , 0 },
    {"wdotf"    , UART_CMD_wdot_factory , "Write Defect Manually(Factory)"             , 0 }, // dskim 테스트 목적
    {"wrdotf"   , UART_CMD_wrdot_factory, "Read Defect(Factory)"                       , 0 }, // dskim 테스트 목적
    {"wcdotf"   , UART_CMD_wcdot_factory, "Clear Defect(Factory)"                      , 0 }, // dskim 테스트 목적
    {"mac"      , UART_CMD_mac          , "Access MAC Address"                         , 0 },
    {"ip"       , UART_CMD_ip           , "Access IP Address"                          , 0 },
    {"smask"    , UART_CMD_smask        , "Access Subnet Mask"                         , 0 },
    {"gate"     , UART_CMD_gate         , "Access Default Gateway"                     , 0 },
    {"ipmode"   , UART_CMD_ipmode       , "Access IP Configuration Mode"               , 0 },
    {"pmode"    , UART_CMD_pmode        , "Select SYNC Source"                         , 0 },
    {"pdead"    , UART_CMD_pdead        , "Control Line Dead Time with Internal SYNC"  , 0 },
    {"fstat"    , UART_CMD_fstat        , "Display FrameBuffer Status"                 , 0 },
    {"finit"    , UART_CMD_finit        , "Initialize FrameBuffer"                     , 0 },
    {"fclr"     , UART_CMD_fclr         , "Clear FrameBuffer"                          , 0 },
    {"fov"      , UART_CMD_fov          , "Display FrameBuffer OVFLW summary"          , 0 },   //# 2605081100
    {"fdot"     , UART_CMD_fdot         , "Toggle FB TX-dot UART progress (0/1)"       , 0 },   //# 2605181144
    {"ferr"     , UART_CMD_ferr         , "Toggle FB overflow UART message (0/1)"      , 0 },   //# 2605181144
    {"pdbg"     , UART_CMD_pdbg         , "Select PHY Debug Mode"                      , 0 },
    {"prev"     , UART_CMD_prev         , "Display PHY Revision"                       , 0 },
    {"grab"     , UART_CMD_grab         , "TFT Operation Enable / Disable"             , 0 },
//  {"hroic"    , UART_CMD_hroic        , "Display All of ROIC Descriptions"           , 0 },
    {"tstat"    , UART_CMD_tstat        , "Display Current TFT Status"                 , 0 },
    {"intrst"   , UART_CMD_intrst       , "Access ROIC INTRST Time"                    , 0 },
    {"cds1"     , UART_CMD_cds1         , "Access ROIC CDS1 Time"                      , 0 },
    {"cds2"     , UART_CMD_cds2         , "Access ROIC CDS2 Time"                      , 0 },
//  {"fa"       , UART_CMD_fa           , "Access ROIC FA Time"                        , 0 },
//  {"dead"     , UART_CMD_dead         , "Access ROIC DEAD Time"                      , 0 },
//  {"mute"     , UART_CMD_mute         , "Access ROIC MUTE Time"                      , 0 },
    {"oe"       , UART_CMD_oe           , "Access GATE OE Time"                        , 0 },
    {"xon"      , UART_CMD_xon          , "Access GATE XON Time"                       , 0 },
    {"flk"      , UART_CMD_flk          , "Access GATE FLK Time (VGH Disable)"         , 0 },
    {"xonflk"   , UART_CMD_xonflk       , "Access GATE XON FLK Overlap Time"           , 0 },
    {"tseq"     , UART_CMD_tseq         , "Access TFT Operation Sequence"              , 0 },
    {"crmode"   , UART_CMD_crmode       , "Access Cycle Reset Mode"                    , 0 },
    {"srmode"   , UART_CMD_srmode       , "Access Start Reset Mode"                    , 0 },
    {"rcycle"   , UART_CMD_rcycle       , "Access Cycle Reset Period"                  , 0 },
//  {"roicval"  , UART_CMD_roicval      , "Read Current ROIC Register Value"           , 0 },
    {"timg"     , UART_CMD_timg         , "Transfer Image in Flash Memory to DDR3"     , 0 },
    {"tfrate"   , UART_CMD_tfrate       , "[TEST] Generate External Trigger Input"     , 0 },
    {"wake"     , UART_CMD_wake         , "ROIC, FPGA wake up"                         , 0 },
    {"sleep"    , UART_CMD_sleep        , "ROIC, FPGA go to sleep"                     , 0 },
    {"sleepmode", UART_CMD_sleepmode    , "Sleep mode setting"                         , 0 },
    {"swmode"   , UART_CMD_sw_gain_mode , "SW Gain Calibration Mode"                   , 0 },
    {"hwload"   , UART_CMD_load_hw_calibration  , "Load HW Calibration"                , 0 },
    {"fpgare"   , UART_CMD_fpgareboot  , "Load fpga reboot"                            , 0 },
    {"fre"      , UART_CMD_fpgareboot  , "Load fpga reboot"                            , 0 },
	{"doc"		, UART_CMD_doc			, "Control Digital Offset Correction"		   , 0 },
};

// TI_ROIC
ROIC_STRUCT ROIC_MAT[ROIC_REG_NUM] = {
    {"IFS"          , "IFS                  [IFS = Value * 0.6 pC]" ,0x5C , 11 ,5, 0, 0},   // [11:15]
	{"SEL_CFB"      , "SEL_CFB    [SEL_CFB = Value(pF)* 1.25 = pC]" ,0x82 ,  8 ,7, 0, 0}    //[14:8] & [6:0]
};

SYSTEM_STATE sys_state;

void command_execute(char *str) {
    u32 i;
    u32 num = 0;
    u32 data[MAX_ARG_NUM] = {0,};
    char cmd[MAX_CMD_LEN] = {0,};
    // TI_ROIC
//  char name[16] = {0,};

    num = rsscanf(str, "%s %n %n %n %n %n %n", cmd, &data[0], &data[1], &data[2], &data[3], &data[4], &data[5]);

    if(!rstrcmp(cmd, "tser"))       num = rsscanf(str, "%s %a", cmd, TFT_SERIAL);
    else if(!rstrcmp(cmd, "pser"))  num = rsscanf(str, "%s %a", cmd, PANEL_SERIAL);
    // TI_ROIC
//  else if(!rstrcmp(cmd, "roic"))  num = rsscanf(str, "%s %S %n", cmd, name, &data[0]);
    else if(!rstrcmp(cmd, "wus"))   num = rsscanf(str, "%s %n %a", cmd, &data[0], USERSET_NAME[data[0]]);

    if(num > 0) num--;
    else        { func_printf("CMD>");  return; }

    // TI_ROIC
//  if(rstrcmp(cmd, "roic")) {
//      for (i = 0; i < MAX_CMD_NUM; i++) {
//          if(rstrcmp(cmd, (char*)CMD_MAT[i].cmd) == 0) {
//              if (CMD_MAT[i].access > func_access_level) {
//                  disp_err(CMD_ERR1);
//                  return;
//              }
//              else {
//                  disp_err((*CMD_MAT[i].p)(num, data));
//                  return;
//              }
//          }
//      }
//  }
//  else {
//      if(num < 1 || num > 2)  { disp_err(CMD_ERR3);   return; }
//      else {
//          for (i = 0; i < ROIC_REG_NUM; i++) {
//              if(rstrcmp(name, (char*)ROIC_MAT[i].name) == 0) {
//                  func_printf("Name = %s\r\n", ROIC_MAT[i].name);
//                  func_printf("Description = %s\r\n", ROIC_MAT[i].commemt);
//                  if(num == 1) {
//                      func_printf("RData = 0x%04x\r\n", get_roic_data(i));
//                      func_printf("ROIC Addr = %d\t ROIC Data = 0x%04x\r\n", ROIC_MAT[i].addr, func_roic_data[ROIC_MAT[i].addr]);
//                  }
//                  else {
//                      set_roic_data(i, data[0]);
//
//                      func_printf("WData = 0x%04x\r\n", data[0]);
//                      func_printf("ROIC Addr = %d\t ROIC Data = 0x%04x\r\n", ROIC_MAT[i].addr, func_roic_data[ROIC_MAT[i].addr]);
//                  }
//                  disp_err(CMD_OK);
//                  return;
//              }
//          }
//      }
//  }
    for (i = 0; i < MAX_CMD_NUM; i++) {
        if(rstrcmp(cmd, (char*)CMD_MAT[i].cmd) == 0) {
            if (CMD_MAT[i].access > func_access_level) {
                disp_err(CMD_ERR1);
                return;
            }
            else {
                disp_err((*CMD_MAT[i].p)(num, data));
                return;
            }
        }
    }
    disp_err(CMD_ERR2);
}


u8 UART_CMD_h (u8 num, u32* data) {
    if (num == 0) {
//        func_printf("\033[2J"); //# 230630
//        func_printf("\033[0;0H");

        disp_cmd_h();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_auth (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_auth();
        return CMD_OK;
    }
    else if(num == 1) {
        execute_cmd_auth(data[0]);
        disp_cmd_auth();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

//# 2605191537 Whole APM impl gated on BD presence; falls back to stub when axi_perf_mon_0 absent
#if APM_PRESENT
//# 2605062100 APM bandwidth command on SLOT0 (axi_crossbar_0_M00_AXI, 256-bit @ sdram_0_ui_clk)
//   NUM_OF_COUNTERS=1 -> sequential R then W. byte counter is u32: window kept short to avoid wrap.
//#define APM_SLOT0_DATA_WIDTH    256U          //# bus width in bits (from cpu.hwh SLOT_0_AXI)
//#define APM_SLOT0_CLK_FREQ_HZ   187546887U    //# slot_0_axi_aclk = sdram_0_ui_clk
//#define APM_DEFAULT_MS          200U          //# 200ms x 2 dirs ~= 1.2GB/dir at peak (u32 safe)
//#define APM_MIN_MS              10U
//#define APM_MAX_MS              500U          //# >500ms risks u32 byte counter wrap at peak BW

//# 2605071100 APM upgraded to 8 parallel counters (R/W bytes + tran cnt + latency sum + idle) for stall diagnosis
//# 2605071158 APM extended to 3 slots (M00 / GEV TX read / Sensor write), measured sequentially per slot
#define APM_SLOT0_DATA_WIDTH    256U          //# bus width in bits (from cpu.hwh SLOT_x_AXI, all 3 slots same width)
#define APM_SLOT0_CLK_FREQ_HZ   187546887U    //# slot_x_axi_aclk = sdram_0_ui_clk (all 3 slots same domain)
#define APM_DEFAULT_MS          200U          //# per-slot window; 3 slots -> total ~600ms
#define APM_MIN_MS              10U
#define APM_MAX_MS              500U          //# total_lat = avg_lat * tran_cnt may wrap if window too long

//# 2605071100 APM per-slot counter index (8 counters on the slot under measurement)
#define APM_CNT_R_BYTES         0U
#define APM_CNT_W_BYTES         1U
#define APM_CNT_R_TRAN          2U
#define APM_CNT_W_TRAN          3U
#define APM_CNT_R_LATSUM        4U
#define APM_CNT_W_LATSUM        5U
#define APM_CNT_R_IDLE          6U
#define APM_CNT_W_IDLE          7U

//# 2605071158 APM slot mapping (BD: axi_perf_mon_0 SLOT_0/1/2)
#define APM_NUM_SLOTS           3U
static const struct {
    u8           id;
    const char  *name;
} apm_slot_map[APM_NUM_SLOTS] = {
    { 0U, "SLOT0 M00 (DDR3 agg)"     },
    { 1U, "SLOT1 GEV TX read (S02)"  },
    { 2U, "SLOT2 Sensor write (S03)" },
};

static XAxiPmon apm_inst;
static u8 apm_ready = 0;

static int apm_init_once(void) {
    XAxiPmon_Config *cfg;
    if (apm_ready) return 0;
    cfg = XAxiPmon_LookupConfig(XPAR_AXI_PERF_MON_0_DEVICE_ID);
    if (cfg == NULL) return -1;
    if (XAxiPmon_CfgInitialize(&apm_inst, cfg, cfg->BaseAddress) != XST_SUCCESS) return -1;
    apm_ready = 1;
    return 0;
}

//# 2605062100 sequential single-metric measure (deprecated by 2605071100)
/*
static void apm_measure(u8 metric, u32 ms, u32 *byte_cnt, u64 *clk_cnt) {
    u32 hi = 0, lo = 0;
    XAxiPmon_ResetMetricCounter(&apm_inst);
    XAxiPmon_ResetGlobalClkCounter(&apm_inst);
    XAxiPmon_SetMetrics(&apm_inst, 0, metric, 0);   //# slot=0, metric, counter=0
    XAxiPmon_EnableGlobalClkCounter(&apm_inst);     //# 2605062100 GCC must be enabled separately (CR bit 16)
    XAxiPmon_EnableMetricsCounter(&apm_inst);
    msdelay(ms);
    XAxiPmon_DisableMetricsCounter(&apm_inst);
    XAxiPmon_DisableGlobalClkCounter(&apm_inst);
    *byte_cnt = XAxiPmon_GetMetricCounter(&apm_inst, 0);
    XAxiPmon_GetGlobalClkCounter(&apm_inst, &hi, &lo);
    *clk_cnt = ((u64)hi << 32) | lo;
}
*/

//# 2605071100 parallel 8-counter measure (single slot)
//# 2605071158 renamed apm_result_t -> apm_slot_t and parameterized by slot ID
typedef struct {
    u32 r_bytes;       //# Read Byte Count       (METRIC_SET_3)
    u32 w_bytes;       //# Write Byte Count      (METRIC_SET_2)
    u32 r_tran;        //# Read Transaction Cnt  (METRIC_SET_1)
    u32 w_tran;        //# Write Transaction Cnt (METRIC_SET_0)
    u32 r_latsum;      //# Total Read Latency    (METRIC_SET_5)  cycles
    u32 w_latsum;      //# Total Write Latency   (METRIC_SET_6)  cycles
    u32 r_idle;        //# Mst_Rd_Idle_Cnt       (METRIC_SET_8)  ARVALID idle cycles
    u32 w_idle;        //# Slv_Wr_Idle_Cnt       (METRIC_SET_7)  AWVALID idle cycles
    u64 total_clk;     //# Global clock counter (window length in cycles)
} apm_slot_t;

static void apm_measure_slot(u8 slot, u32 ms, apm_slot_t *r) {
    u32 hi = 0, lo = 0;
    XAxiPmon_ResetMetricCounter(&apm_inst);
    XAxiPmon_ResetGlobalClkCounter(&apm_inst);
    //# Counter 0..7 each tracking a different metric on the given slot
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_3, APM_CNT_R_BYTES);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_2, APM_CNT_W_BYTES);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_1, APM_CNT_R_TRAN);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_0, APM_CNT_W_TRAN);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_5, APM_CNT_R_LATSUM);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_6, APM_CNT_W_LATSUM);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_8, APM_CNT_R_IDLE);
    XAxiPmon_SetMetrics(&apm_inst, slot, XAPM_METRIC_SET_7, APM_CNT_W_IDLE);
    XAxiPmon_EnableGlobalClkCounter(&apm_inst);
    XAxiPmon_EnableMetricsCounter(&apm_inst);
    msdelay(ms);
    XAxiPmon_DisableMetricsCounter(&apm_inst);
    XAxiPmon_DisableGlobalClkCounter(&apm_inst);

    r->r_bytes  = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_R_BYTES);
    r->w_bytes  = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_W_BYTES);
    r->r_tran   = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_R_TRAN);
    r->w_tran   = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_W_TRAN);
    r->r_latsum = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_R_LATSUM);
    r->w_latsum = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_W_LATSUM);
    r->r_idle   = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_R_IDLE);
    r->w_idle   = XAxiPmon_GetMetricCounter(&apm_inst, APM_CNT_W_IDLE);
    XAxiPmon_GetGlobalClkCounter(&apm_inst, &hi, &lo);
    r->total_clk = ((u64)hi << 32) | lo;
}

//# 2605071158 pretty-print one slot's metrics (extracted from old UART_CMD_apm body)
static void apm_print_slot(const char *name, const apm_slot_t *m) {
    u64 clk = (m->total_clk == 0) ? 1ULL : m->total_clk;
    u64 r_gbps_x100, w_gbps_x100;
    u32 r_util_x100, w_util_x100;
    u32 r_idle_x100, w_idle_x100;
    u32 r_avglat_x10, w_avglat_x10;

    r_gbps_x100  = ((u64)m->r_bytes * 8ULL * APM_SLOT0_CLK_FREQ_HZ / clk) / 10000000ULL;
    w_gbps_x100  = ((u64)m->w_bytes * 8ULL * APM_SLOT0_CLK_FREQ_HZ / clk) / 10000000ULL;
    r_util_x100  = (u32)(((u64)m->r_bytes * 10000ULL) / (clk * 32ULL));
    w_util_x100  = (u32)(((u64)m->w_bytes * 10000ULL) / (clk * 32ULL));
    r_idle_x100  = (u32)(((u64)m->r_idle  * 10000ULL) / clk);
    w_idle_x100  = (u32)(((u64)m->w_idle  * 10000ULL) / clk);
    r_avglat_x10 = (m->r_tran == 0) ? 0U : (u32)(((u64)m->r_latsum * 10ULL) / m->r_tran);
    w_avglat_x10 = (m->w_tran == 0) ? 0U : (u32)(((u64)m->w_latsum * 10ULL) / m->w_tran);

    func_printf(" %s  total=%u cyc\r\n", name, (u32)clk);
    func_printf("   R: %u B (%u tr) -> %u.%02u Gbps  util %u.%02u %%%%  idle %u.%02u %%%%  avgLat %u.%u cyc\r\n",
        m->r_bytes, m->r_tran,
        (u32)(r_gbps_x100/100), (u32)(r_gbps_x100%100),
        (u32)(r_util_x100/100), (u32)(r_util_x100%100),
        (u32)(r_idle_x100/100), (u32)(r_idle_x100%100),
        (u32)(r_avglat_x10/10), (u32)(r_avglat_x10%10));
    func_printf("   W: %u B (%u tr) -> %u.%02u Gbps  util %u.%02u %%%%  idle %u.%02u %%%%  avgLat %u.%u cyc\r\n",
        m->w_bytes, m->w_tran,
        (u32)(w_gbps_x100/100), (u32)(w_gbps_x100%100),
        (u32)(w_util_x100/100), (u32)(w_util_x100%100),
        (u32)(w_idle_x100/100), (u32)(w_idle_x100%100),
        (u32)(w_avglat_x10/10), (u32)(w_avglat_x10%10));
}

u8 UART_CMD_apm (u8 num, u32* data) {
    u32 ms = APM_DEFAULT_MS;
    apm_slot_t m;
    u64 max_bps;
    u32 max_int, max_frac;
    u32 i;

    if (num == 1)      ms = data[0];
    else if (num != 0) return CMD_ERR3;
    if (ms < APM_MIN_MS || ms > APM_MAX_MS) return CMD_ERR4;

    if (apm_init_once() < 0) {
        func_printf("APM init fail\r\n");
        return CMD_ERR2;
    }

    max_bps  = (u64)APM_SLOT0_DATA_WIDTH * APM_SLOT0_CLK_FREQ_HZ;
    max_int  = (u32)(max_bps / 1000000000ULL);
    max_frac = (u32)((max_bps / 1000000ULL) % 1000ULL);

    //# Note: %%%% renders as one '%' because func_printf double-parses (vsprintf -> xil_printf)
    func_printf("APM %u slots @ %u Hz, %u-bit, max %u.%03u Gbps each\r\n",
        APM_NUM_SLOTS, (u32)APM_SLOT0_CLK_FREQ_HZ, (u32)APM_SLOT0_DATA_WIDTH, max_int, max_frac);
    func_printf(" Window=%u ms x %u slots (sequential)\r\n", ms, APM_NUM_SLOTS);

    //# 2605071158 sequential per-slot measurement (each slot uses all 8 counters for full metrics)
    for (i = 0U; i < APM_NUM_SLOTS; i++) {
        apm_measure_slot(apm_slot_map[i].id, ms, &m);
        apm_print_slot(apm_slot_map[i].name, &m);
    }

    return CMD_OK;
}

#else /* !APM_PRESENT : axi_perf_mon_0 removed from BD */
//# 2605191537 Stub keeps 'apm' UART entry & prototype valid when APM IP is absent
u8 UART_CMD_apm (u8 num, u32* data) {
    (void)num; (void)data;
    func_printf("APM not present in this build (axi_perf_mon_0 removed from BD)\r\n");
    return CMD_ERR2;
}
#endif /* APM_PRESENT */

//# 2605071529 DDR AXI burst limit runtime selector (register 0x04A0, 2-bit mode)
//   Quantize input down to nearest power of 2 then map to mode 0..3.
//   Tier:  N <= 32 -> mode 0 (32),  N <= 64 -> mode 1 (64),
//          N <= 128 -> mode 2 (128), else      -> mode 3 (256).
u8 UART_CMD_ddrburst (u8 num, u32* data) {
    u32 mode, beats;
    static const u32 mode2beats[4] = {32U, 64U, 128U, 256U};

    if (num == 0) {
        mode  = REG(ADDR_DDR_BURST) & 0x3U;
        beats = mode2beats[mode];
        func_printf("DDR AXI burst limit = %u beats (mode %u)\r\n", beats, mode);
        return CMD_OK;
    }
    else if (num == 1) {
        if      (data[0] <= 32U)  mode = 0U;  //# -> 32 beats
        else if (data[0] <= 64U)  mode = 1U;  //# -> 64 beats
        else if (data[0] <= 128U) mode = 2U;  //# -> 128 beats
        else                      mode = 3U;  //# -> 256 beats
        REG(ADDR_DDR_BURST) = mode;
        beats = mode2beats[mode];
        func_printf("DDR AXI burst limit set to %u beats (mode %u). Effect: next AXI tx\r\n",
                    beats, mode);
        return CMD_OK;
    }
    return CMD_ERR3;
}

//$ 2607141553 opwr_en manual override via ADDR_PWR_CTRL.
//  Usage: pwr              -> print current override state and each bit value
//         pwr 0            -> disable override (bit31=0, sequencer resumes)
//         pwr 1 <hex>      -> enable override with opwr_en=<hex> (e.g. pwr 1 1FF)
//  Note: bit[31]=override_en, bit[10:0]=opwr_en pins (PWR_NUM varies per model)
u8 UART_CMD_pwr (u8 num, u32* data) {
    u32 regv, override_en, pins;
    int i;

    if (num == 0) {
        regv       = REG(ADDR_PWR_CTRL);
        override_en = (regv >> 31) & 0x1U;
        pins        = regv & 0x7FFU;
        func_printf("PWR_CTRL: 0x%08X  override=%s\r\n",
                    (unsigned int)regv, override_en ? "ON" : "OFF");
        func_printf("  opwr_en bits: ");
        for (i = 10; i >= 0; i--) {
            func_printf("[%2d]=%d ", i, (int)((pins >> i) & 0x1U));
        }
        func_printf("\r\n");
        return CMD_OK;
    }
    else if (num == 1) {
        if (data[0] == 0U) {
            REG(ADDR_PWR_CTRL) = 0U;
            func_printf("PWR_CTRL: override disabled (sequencer mode)\r\n");
            return CMD_OK;
        }
        return CMD_ERR3;
    }
    else if (num == 2) {
        if (data[0] == 1U) {
            pins = data[1] & 0x7FFU;
            REG(ADDR_PWR_CTRL) = (1U << 31) | pins;
            func_printf("PWR_CTRL: override ON  opwr_en=0x%03X\r\n", (unsigned int)pins);
            return CMD_OK;
        }
        return CMD_ERR3;
    }
    return CMD_ERR3;
}

//# 2605131158 REG() access watcher (simplified: add/remove + ALL on/off).
//             Pairs with the REG/FREG macro wrapper in fpga_info.h + dbg_watch_check()
//             in func_basic.c. Each occupied slot always runs R+W dual triggers.
// Usage:
//   watch                       -> print usage + current state.
//   watch 1                     -> ALL mode ON (sample every REG access, 1/DBG_WATCH_ALL_DIV).
//   watch 0                     -> ALL mode OFF (slots untouched).
//   watch 1 <addr> [addr...]    -> add each addr to the slot table (no-op if present).
//   watch 0 <addr> [addr...]    -> remove each addr from the slot table (no-op if absent).
u8 UART_CMD_watch (u8 num, u32* data) {
    if (num == 0) {                                                 //# list + usage
        disp_cmd_watch();
        return CMD_OK;
    }
    u32 flag = data[0];
    if (flag != 0 && flag != 1) {
        func_printf("[watch] first arg must be 0 (off/remove) or 1 (on/add)\r\n");
        return CMD_ERR4;
    }
    if (num == 1) {
        //# 1-arg form toggles ALL mode flag only; slots untouched.
        if (flag) {
            dbg_watch_flags |=  DBG_WATCH_FLAG_ALL;
            func_printf("[watch] ALL mode ON (sampled 1/%u). UART may flood.\r\n",
                        (unsigned)DBG_WATCH_ALL_DIV);
        } else {
            dbg_watch_flags &= ~DBG_WATCH_FLAG_ALL;
            func_printf("[watch] ALL mode OFF\r\n");
        }
        disp_cmd_watch();
        return CMD_OK;
    }
    //# num >= 2: data[0] = 0/1, data[1..num-1] = addrs to add/remove.
    for (u8 ai = 1; ai < num; ai++) {
        u32 a = data[ai];
        if (!a) {
            func_printf("[watch] skip addr=0 (sentinel for empty slot)\r\n");
            continue;
        }
        int found = -1;
        for (int i = 0; i < DBG_WATCH_MAX; i++) {
            if (dbg_watch_addr[i] == a) { found = i; break; }
        }
        if (flag) {                                                 //# add
            if (found >= 0) {
                func_printf("[watch] 0x%04x already in slot %d (no-op)\r\n",
                            (unsigned)a, found);
                continue;
            }
            int slot = -1;
            for (int i = 0; i < DBG_WATCH_MAX; i++) {
                if (!dbg_watch_addr[i]) { slot = i; break; }
            }
            if (slot < 0) {
                func_printf("[watch] no empty slot for 0x%04x (max %d)\r\n",
                            (unsigned)a, DBG_WATCH_MAX);
                return CMD_ERR4;
            }
            dbg_watch_addr[slot] = a;
            dbg_watch_prev[slot] = FREG(a);                         //# seed with current value
            func_printf("[watch] + slot %d  addr 0x%04x  seed 0x%08x %u\r\n",
                        slot, (unsigned)a,
                        (unsigned)dbg_watch_prev[slot], (unsigned)dbg_watch_prev[slot]);
        } else {                                                    //# remove
            if (found < 0) {
                func_printf("[watch] 0x%04x not in any slot (no-op)\r\n", (unsigned)a);
                continue;
            }
            dbg_watch_addr[found] = 0;
            dbg_watch_prev[found] = 0;
            func_printf("[watch] - slot %d  addr 0x%04x removed\r\n",
                        found, (unsigned)a);
        }
    }
    disp_cmd_watch();
    return CMD_OK;
}

//# 2605121343 Manual M88X33xx step commands (debug). Each runs a single stage
//             of the cold-boot sequence: deinit -> initx -> inity -> init.
//             Return code of underlying function is printed; CMD_OK is always
//             returned to UART parser so subsequent commands stay enabled.
u8 UART_CMD_m88deinit (u8 num, u32* data) {
    int ret = m88x33xx_deinit();
    func_printf("m88x33xx_deinit() -> %d\r\n", ret);
    return CMD_OK;
}

u8 UART_CMD_m88initx (u8 num, u32* data) {
    int ret = m88x33xx_initx(RXAUI);
    func_printf("m88x33xx_initx(RXAUI) -> %d\r\n", ret);
    return CMD_OK;
}

u8 UART_CMD_m88inity (u8 num, u32* data) {
    int ret = m88x33xx_inity(RXAUI);
    func_printf("m88x33xx_inity(RXAUI) -> %d\r\n", ret);
    return CMD_OK;
}

u8 UART_CMD_m88init (u8 num, u32* data) {
    int ret = m88x33xx_init(RXAUI);
    func_printf("m88x33xx_init(RXAUI) -> %d\r\n", ret);
    return CMD_OK;
}

//# 2605121451 Hard reset the external PHY chip via the PHY_RESET_N pin.
//             Use this when m88x33xx_init returns 0x1001 (PHY MCU app code not started)
//             and m88inity also fails to recover. After this command, re-run the init
//             sequence manually: m88inity -> gigeinit -> m88init.
//             Mirrors the pattern at tn80xx.c:30-32: set GCSR_RST_PHY, FPGA generates
//             the reset pulse, bit auto-clears when pulse completes, then 100ms settle.
u8 UART_CMD_m88rst (u8 num, u32* data) {
    func_printf("PHY hard reset (PHY_RESET_N pulse)...\r\n");
    gige_gcsr |= GCSR_RST_PHY;
    while (gige_gcsr & GCSR_RST_PHY) {}
    usleep(100000);   // 100ms PHY power-on settle
    func_printf("done. Recommended next: m88inity -> gigeinit -> m88init\r\n");
    return CMD_OK;
}

//# 2605121447 Manually run the GigE core init sequence (Marvell/RXAUI path).
//             Mirrors execute_cmd_port(0) NEW path block at func_cmd.c:360-366,
//             so it can be invoked standalone for debugging without going through
//             the full m88x_init gate.
u8 UART_CMD_gigeinit (u8 num, u32* data) {
    func_printf("gige_init(RXAUI/Marvell)...\r\n");
    gige_init(0, XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR, DEV_MODE_TX, XPAR_CPU_M_AXI_DP_FREQ_HZ,
                 PHY_NBASET_MRVL, 0, 2500000, 0, SCPS_MAX, DBG_ICMP);
    gige_set_data_rates(200, 10000);                    // tx_stm_clk = 200MHz, 10Gbps Ethernet link
    gige_set_link_config_cap(LINK_CONFIG_CAP_SL);       // Physical link configuration capabilities
    gige_set_link_config(LINK_CONFIG_SL);               // Current physical link configuration
    gige_set_sceba(0, MAP_SCEBA);                       // Stream channel extended bootstrap address
    func_printf("gige_init sequence done\r\n");
    return CMD_OK;
}

//# 260421 add port cmd (Marvell/SFP select)
u8 UART_CMD_port (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_port();
        return CMD_OK;
    }
    else if (num == 1) {
        if (data[0] > 1) return CMD_ERR4;
        if (data[0] == 1 && !mEXT3643R_series) {
            func_printf("SFP port is only available on EXT3643R.\r\n");
            return CMD_ERR4;
        }
        execute_cmd_port(data[0]);
        disp_cmd_port();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_stat (u8 num, u32* data) {
    if (num == 0) {
//        func_printf("\033[2J"); //# 230630
//        func_printf("\033[0;0H");

        disp_cmd_stat();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_psel (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_psel();
        return CMD_OK;
    }
    else if(num == 1) {
//      if(data[0] < 0 || data[0] > 15)         return CMD_ERR4;
        if(data[0] < 0 || data[0] > 255)        return CMD_ERR4; // dskim - 0.xx.09 - mbh 201216
        execute_cmd_psel(data[0]);
        disp_cmd_psel();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0]==15) // custom video data #230717
        {
            execute_cmd_psel_val(15,data[1]);
        }
        else
        {
            execute_cmd_auth(8546);
            for(u8 i=0; i<data[0]; i++)
            {
                execute_cmd_psel(i+10);
                disp_cmd_psel();
                msdelay(400);
                execute_cmd_wddr(i+1, 0);
                func_printf("psel=%d, wddr=%d \r\n",i+10, i+1);

            }
            execute_cmd_gcal();
        }
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_gmode (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_gmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 255)        return CMD_ERR4;
        execute_cmd_gmode(data[0], func_frame_val);
        disp_cmd_gmode();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 255)        return CMD_ERR4;
        if(data[1] < 0 || data[1] > 255)        return CMD_ERR4;
        execute_cmd_gmode(data[0], data[1]);
        disp_cmd_gmode();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

#define DBG_bmode 0
u8 UART_CMD_bmode (u8 num, u32* data) {
    u32 offsetx = 0, offsety = 0, width = 0, height = 0;

    u32 prev  = func_binning_mode;
    u32 curr  = data[0];
    u32 grab  = func_grab_en;
    float dividend, divider;

    if (prev == 0)      dividend = 1.0;
    else if (prev <= 3) dividend = 2.0;
    else if (prev <= 5) dividend = 3.0;
    else                dividend = 4.0;

    if (curr == 0)      divider = 1.0;
    else if (curr <= 3) divider = 2.0;
    else if (curr <= 5) divider = 3.0;
    else                divider = 4.0;

    func_binning = (int)divider; //# save binning multi value 231013

    offsetx = (u32)(func_offsetx    * (dividend/divider));
    offsety = (u32)(func_offsety    * (dividend/divider));
    width   = (u32)(func_width      * (dividend/divider));
    height  = (u32)(func_height     * (dividend/divider));

    offsetx = (u32)(floor(offsetx   / (float)INTERVALX) * INTERVALX);
    offsety = (u32)(floor(offsety   / (float)INTERVALY) * INTERVALY);
    width   = (u32)(floor(width     / (float)INTERVALX) * INTERVALX);
    height  = (u32)(floor(height    / (float)INTERVALY) * INTERVALY);

    if (num == 0) {
        disp_cmd_bmode();
        return CMD_OK;
    }
    else if(num == 1) {
//#ifdef EXT4343R
//        if(data[0] < 0  || data[0] > 7 || data[0] == 1)             return CMD_ERR4;
//#else
//        if(data[0] < 0  || data[0] > 7 || data[0] == 1)             return CMD_ERR4;
//#endif
//    if(msame(mEXT4343R))
//        if(data[0] < 0  || data[0] > 7 || data[0] == 1)             return CMD_ERR4;
//    else
        if(data[0] < 0  || data[0] > 7 || data[0] == 1)             return CMD_ERR4;

        if(DBG_bmode)func_printf("#DBG DBG_bmode MIN_WIDTH=%d MIN_WIDTH=%d\r\n",MAX_WIDTH, MAX_WIDTH);
        if(DBG_bmode)func_printf("#DBG DBG_bmode MIN_HEIGHT=%d MAX_HEIGHT=%d\r\n",MIN_HEIGHT, MAX_HEIGHT);
        if(offsetx + width > MAX_WIDTH   || offsetx + width < MIN_WIDTH)        return CMD_ERR11;   // dskim - 21.02.15 - MIN_WIDTH
        if(offsety + height > MAX_HEIGHT || offsety + height < MIN_HEIGHT)      return CMD_ERR11;   // dskim - 21.02.15 - MIN_HEIGHT
        if(REG(ADDR_OUT_EN))                                        return CMD_ERR5;
        execute_cmd_grab(0);

        execute_cmd_bmode(data[0]);
        if(DBG_bmode)func_printf("#DBG DBG_bmode offsetx=%d offsety=%d\r\n",offsetx, offsety);
        if(DBG_bmode)func_printf("#DBG DBG_bmode width=%d height=%d\r\n",width, height);
        execute_cmd_roi(offsetx, offsety, width, height);
//      execute_cmd_fmax();
//      execute_cmd_frate((u32)(func_frate*1000));
        execute_cmd_gewt(func_gewt); // 220121mbh
        execute_cmd_fmax();
        execute_cmd_frate(0);
        execute_cmd_emax();

        disp_cmd_bmode();
        disp_cmd_roi();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        execute_cmd_grab(grab);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_tmode (u8 num, u32* data) {
    u32 grab  = func_grab_en;

    if (num == 0) {
        disp_cmd_tmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 3)          return CMD_ERR4;
        execute_cmd_grab(0);

        execute_cmd_tmode(data[0]);
        execute_cmd_emax();

        disp_cmd_tmode();
        disp_cmd_emax();
        execute_cmd_grab(grab);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_tdly (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_tdly();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 60000)  return CMD_ERR4;
        execute_cmd_tdly(data[0]);
        disp_cmd_tdly();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_smode (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_smode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 1)          return CMD_ERR4;
        execute_cmd_smode(data[0]);
        execute_cmd_fmax();
        execute_cmd_frate(0);
        execute_cmd_emax();

        disp_cmd_smode();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_emode (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_emode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 1)          return CMD_ERR4;
        execute_cmd_emode(data[0]);
        disp_cmd_emode();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_roi (u8 num, u32* data) {
    u32 grab  = func_grab_en;
    u32 max_width   = MAX_WIDTH;
    u32 max_height  = MAX_HEIGHT;
    u32 min_width   = MIN_WIDTH;
    u32 min_height  = MIN_HEIGHT;
    float divider   = 1.0;

    switch (func_binning_mode) {
        case 0  :   divider = 1.0;  break;
        case 1  :   divider = 2.0;  break;
        case 2  :   divider = 2.0;  break;
        case 3  :   divider = 2.0;  break;
        case 4  :   divider = 3.0;  break;
        case 5  :   divider = 3.0;  break;
        case 6  :   divider = 4.0;  break;
        case 7  :   divider = 4.0;  break;
    }
    max_width   = (u32)(MAX_WIDTH   / divider);
    max_height  = (u32)(MAX_HEIGHT  / divider);
    min_width   = (u32)(MIN_WIDTH   / divider);
    min_height  = (u32)(MIN_HEIGHT  / divider);

    if (num == 0) {
        disp_cmd_roi();
        return CMD_OK;
    }
    else if (num == 4) {
        if(data[0] + data[2] > max_width || data[2] < min_width)    return CMD_ERR11;
        if(data[1] + data[3] > max_height|| data[3] < min_height)   return CMD_ERR11;
        if(data[0] % INTERVALX || data[2] % INTERVALX)              return CMD_ERR17;
        if(data[1] % INTERVALY || data[3] % INTERVALY)              return CMD_ERR17;
        if(REG(ADDR_OUT_EN))                                        return CMD_ERR5;
        execute_cmd_grab(0);

        execute_cmd_roi(data[0], data[1], data[2], data[3]);
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));
        disp_cmd_roi();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        execute_cmd_grab(grab);

        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_frate (u8 num, u32* data) {
    u8 err = 0;
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if (num == 0) {
        disp_cmd_frate();
        return CMD_OK;
    }
    else if (num == 1) {
        if(func_trig_mode > 0)          return CMD_ERR6;

        if(fval < func_frate_min)       { err = 1;  fval = func_frate_min; }
        else if(fval > func_frate_max)  { err = 1;  fval = func_frate_max; }

        func_frate =fval; //# 26043011 cmd frate input
        execute_cmd_frate(fval);
        disp_cmd_frate();
        disp_cmd_emax();

        if(err)     return CMD_ERR4;
        else        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_ewt (u8 num, u32* data) {
    u8 err = 0;
    u32 val;

    val = data[0];

    if (num == 0) {
        disp_cmd_ewt();

// #@ test code
//      execute_cmd_fmax();
//      execute_cmd_frate2ewt(func_frate*1000);
//      execute_cmd_frate(0);
//      execute_cmd_emax();

        return CMD_OK;
    }
    else if (num == 1) {
        if(func_trig_mode == 2)             return CMD_ERR6;
        if(func_shutter_mode == 0)          return CMD_ERR15;

        if(data[0] < func_gewt_min) {
            err = 1;    val = func_gewt_min;
        }
        if(func_exp_mode == 0 && data[0] > func_gewt_max)   {
            err = 1;    val = func_gewt_max;
        }

        execute_cmd_gewt(val);
        execute_cmd_fmax();
        execute_cmd_frate(0);
        execute_cmd_emax();
        disp_cmd_ewt();

        if(err)     return CMD_ERR4;
        else        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_max (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_fmax();
        disp_cmd_emax();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_gain (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_gain();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 1)          return CMD_ERR4;
        if(data[0] == 1 && func_ref_num < 2)    return CMD_ERR16;
        execute_cmd_gain(data[0]);
        disp_cmd_gain();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_offset (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_offset();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 1)          return CMD_ERR4;
        if(data[0] == 1 && func_ref_num < 1)    return CMD_ERR16;
        execute_cmd_offset(data[0]);
        disp_cmd_offset();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_defect (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_defect();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 1)  return CMD_ERR4;
        execute_cmd_defect(data[0]);
        disp_cmd_defect();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_dmap (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_dmap();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 1)  return CMD_ERR4;
        execute_cmd_dmap(data[0]);
        disp_cmd_dmap();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_ghost (u8 num, u32* data) {
    if (num == 0) {
        execute_cmd_ghost(func_erase_time);
        disp_cmd_ghost();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 60000)  return CMD_ERR4;
        execute_cmd_ghost(data[0]);
        disp_cmd_ghost();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

// TI_ROIC (Analog Gain 에 따른 추가 설계 필요)
u8 UART_CMD_ifs (u8 num, u32* data) {
    if (num == 0) {
        disp_roic_ifs();
        return CMD_OK;
    }
    else if (num == 1) {
    	//if(data[0] < 0 || data[0] > 39) return CMD_ERR4;
    		if(data[0] > 15) return CMD_ERR4;
        execute_cmd_ifs(data[0]);
        disp_roic_ifs();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_dgain (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_dgain();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 1 || data[0] > 1600)   return CMD_ERR4;
        execute_cmd_dgain(data[0]);
        disp_cmd_dgain();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_iproc (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_iproc();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 4)  return CMD_ERR4;
        execute_cmd_iproc(data[0]);
        disp_cmd_iproc();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wus (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_us();
        disp_cmd_usname();
        return CMD_OK;
    }
    else if (num == 1 || num == 2) {
        if(data[0] < 0 || data[0] > 3)  return CMD_ERR4;
        execute_cmd_wus(data[0]);
        execute_cmd_wbs();
        disp_cmd_us();
        disp_cmd_usname();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rus (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_us();
        disp_cmd_usname();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 3)  return CMD_ERR4;
        if(execute_cmd_rus(data[0]))    return CMD_ERR9;
        disp_cmd_us();
        disp_cmd_usname();
    //  TI_ROIC
    //  roic_init();
        tft_set();
        func_init();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

//# 2605201841 UART_CMD_debug -> UART_CMD_rus2 (also dumps NUC info via execute_cmd_rus2)
// Name aligned with execute_cmd_rus2() backend; reachable via UART "rus2".
// "rus2"        -> dump table func_table
// "rus2 1 N"    -> dump table N (0..3)
u8 UART_CMD_rus2 (u8 num, u32* data) {
    if (num == 0) {
        execute_cmd_rus2(func_table);
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 3)  return CMD_ERR4;
        if(execute_cmd_rus2(data[0]))   return CMD_ERR9;
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_rtemp (u8 num, u32* data) {
    if (num == 0) {
        execute_cmd_rtemp();
        disp_cmd_rtemp();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

/*# 2608191842 rtempraw: pick which FPGA/PHY/SFP temperature XML reports.
 * No arg prints the current mode; "rtempraw 0|1" sets it. RAM only, lost on reboot,
 * because raw die readings are for diagnosis and should not become the shipped default. */
u8 UART_CMD_rtempraw (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_rtempraw();
        return CMD_OK;
    }
    else if (num == 1) {
        if (data[0] > 1) return CMD_ERR4;
        execute_cmd_rtempraw(data[0]);
        disp_cmd_rtempraw();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rtime (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_rtime();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_reboot (u8 num, u32* data) {
    if (num == 0) {
        execute_cmd_reboot();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}




u8 UART_CMD_tser (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_tser();
        return CMD_OK;
    }
    else if (num == 1) {
        execute_cmd_wbs();
        disp_cmd_tser();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_pser (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_pser();
        return CMD_OK;
    }
    else if (num == 1) {
        execute_cmd_wbs();
        disp_cmd_pser();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_ver (u8 num, u32* data) {
    if (num == 0) {
//        load_fw_ver(); //# 230905 no meaning
        gige_print_header();
        disp_cmd_dver();
        disp_cmd_fver();
        disp_cmd_fmodel();
        disp_cmd_hwver();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_reg(u8 num, u32* data) {
    if(num == 0) {
        if(data[0] < 0 || data[0] > 0xFFFF || (data[0] % 4))    return CMD_ERR4;
        for(int i=0; i<256; i++) // fpga register bulk read , mbh 210325
            func_printf("Addr(0x%04x)= 0x%08x \t%d \r\n",(i*4),  REG(i*4), REG(i*4) );
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 0xFFFF || (data[0] % 4))    return CMD_ERR4;
        func_printf("RData: 0x%08x \t%d \r\n", REG(data[0]), REG(data[0]) ); // decimal 210115
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 0xFFFF || (data[0] % 4))    return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)                 return CMD_ERR4;
        REG(data[0]) = data[1];
        func_printf("WAddr: 0x%04x, WData : 0x%08x\r\n", data[0], data[1]);
        func_printf("WAddr: 0x%04x, WData : 0x%08x\r\n", data[0], REG(data[0]));
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}
u8 UART_CMD_xreg(u8 num, u32* data) {
    if(num == 0) {
        if(data[0] < 0 || data[0] > 0xFFFF || (data[0] % 4))    return CMD_ERR4;
        for(int i=0; i<256; i++) // fpga register bulk read , mbh 210325
            func_printf("Addr(0x%04x)= 0x%08x \t%d \r\n",(i*4),  XREG(i*4), XREG(i*4) );
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 0xFFFF || (data[0] % 4))    return CMD_ERR4;
        func_printf("RData: 0x%08x \t%d \r\n", XREG(data[0]), XREG(data[0]) ); // decimal 210115
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 0xFFFF || (data[0] % 4))    return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)                 return CMD_ERR4;
        XREG(data[0]) = data[1];
        func_printf("WAddr: 0x%04x, WData : 0x%08x\r\n", data[0], data[1]);
        func_printf("WAddr: 0x%04x, WData : 0x%08x\r\n", data[0], XREG(data[0]));
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}
u8 UART_CMD_rtp(u8 num, u32* data) {
    if(num == 1) { // read timing profile Alpha/Beta
        if(data[0] == 0 || data[0] == 1){

            REG(ADDR_ROIC_TP_SEL) = data[0];
//          execute_cmd_grab(0); // 210721 //210812 force trigger
//          execute_cmd_grab(1);
//          execute_cmd_grab(0);
            msdelay(100); // roic sync wait

            if (data[0] == 0)
                func_printf("TG Beta\r\n");
            else // if (data[0] == 1)
                func_printf("TG Alpha\r\n");

            execute_cmd_rtimingprofile();

            REG(ADDR_ROIC_TP_SEL) = 0; // TGbeta active
//          execute_cmd_grab(1); //210812 force trigger
            msdelay(100); // roic sync wait

            return CMD_OK;
        }
        else
            return CMD_ERR4;
    }
        return CMD_ERR3;
}


u8 UART_CMD_gtp(u8 num, u32* data) {
    if(num == 0) {

            execute_cmd_gtimingprofile();
            return CMD_OK;

    }
        return CMD_ERR3;
}

u8 UART_CMD_atp(u8 num, u32* data) {
    if(num == 0) {

            REG(ADDR_ROIC_TP_SEL) = 1; // read alpha
//          execute_cmd_grab(1); //210812 force trigger
            msdelay(1); // roic sync wait

            execute_cmd_atimingprofile();

            REG(ADDR_ROIC_TP_SEL) = 0; // active alpha
//          execute_cmd_grab(1); //210812 force trigger
            msdelay(1); // roic sync wait

            return CMD_OK;
    }
        return CMD_ERR3;
}

u8 UART_CMD_wtp(u8 num, u32* data) { // set timing profile
    //$ 2607061609 Block wtp while image output is active to avoid gate line
    if(num != 0 && (REG(ADDR_OUT_EN) & 1)) {
        func_printf("\r\n[WTP] blocked: OUT_EN is active. Stop streaming first.\r\n");
        return CMD_ERR6;
    }
    if(num == 0) {
        disp_cmd_wtp();
        return CMD_OK;
    }
    else if(num == 1) { //# 230329
        if (data[0]==0)
            REG(ADDR_ROIC_TP_SEL) = 0; // write to "Alpha"
        else
            REG(ADDR_ROIC_TP_SEL) = 1; // write to "beta"

        return CMD_OK;
    }
    else if(num == 6) {
            REG(ADDR_ROIC_TP_SEL) = 1; // write to "Alpha"
//          execute_cmd_grab(1); //210812 force trigger
            msdelay(1); // roic sync wait

            // roic_settimingprofile(u32 mclk, u32 str, u32 tirst, u32 tshr_lpf1, u32 tshs_lpf2, u32 tgate)
            execute_cmd_settimingprofile(data);
//          execute_cmd_rclk();

            REG(ADDR_ROIC_TP_SEL) = 0; // Aictive "Alpha"
//          execute_cmd_grab(1); //210812 force trigger
            msdelay(1); // roic sync wait

            return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_mclk(u8 num, u32* data)
{ // mbh 210114
    if(num == 2)
    {
        int Status;
        Status = ClkWiz_IntrExample(XPAR_CLK_WIZ_0_DEVICE_ID, data[0], data[1]);

//        func_grabbcal = 1; // call bcal with temperature setting.// 220727
        func_bcal1_token = 1; //# delete grabbcal #250626
          if (Status == 0) {
                execute_cmd_rclk();
          }
          return CMD_OK;
    }
    else
        return CMD_ERR3;
}

    u8 UART_CMD_rclk(u8 num, u32* data) { // mbh 210114
        if(num == 0)
        {
            execute_cmd_rclk();
                return CMD_OK;
        }
        return CMD_ERR3;
    }

u8 UART_CMD_diag(u8 num, u32* data) { // mbh 210324
    if(num == 0 || num == 1)
    {
        execute_cmd_diag(data[0]);
//      func_printf("m88x33xx_init\r\n");
//      m88x33xx_init(RXAUI); // dismiss 220726mbh

            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_wsm(u8 num, u32* data) { // mbh 210406
    if (num == 0)
    {
        execute_cmd_wsm(0);
        func_printf("wsm 100ms unit\r\n");
        func_printf("sm clear\r\n");
        func_printf("ex)wsm 100 : write sm to fifo for 100m second.\r\n");
        func_printf("ex)rsm 0 : read tft sm from fifo.\r\n");
        return CMD_OK;
    }
    else if(num == 1)
    {
        execute_cmd_wsm(data[0]);
            return CMD_OK;
    }
    return CMD_ERR3;
}
u8 UART_CMD_rsm(u8 num, u32* data) { // mbh 210406
    if (num == 0)
    {
        func_printf("rsm 0:tft 1:roic 2:gate 3:roSet 4:align 5:roi 6:avg\r\n");
        func_printf("ex)wsm 100 : write sm to fifo for 100m second.\r\n");
        func_printf("ex)rsm 0 : read tft sm from fifo.\r\n");
        return CMD_OK;
    }
    else if(num == 1)
    {
        execute_cmd_rsm(data[0]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_d2m(u8 num, u32* data) { // mbh 210618
    if(num == 0){ // on


        roic_settimingprofile(&profile.d2);
        roic_settimingfilter(&profile.d2);
//      msdelay(1000);


        for(u8 i=0; i<10; i++){
            msdelay(10);
            gige_callback(0);
        }

        roic_settimingprofile(&profile.d2);
        roic_settimingfilter(&profile.d2);

        // ### execute pre-trigger for hiding first image noise.
        // ### and it dose not give a output trigger signal
        REG(ADDR_TRIG_VALID)= 0;    // out trig_valid disable
        msdelay(1);
        REG(ADDR_D2M_EN    )=1;     // d2 mode enable
        REG(ADDR_D2M_EXP_IN    )=0; // d2 reg trigger
        REG(ADDR_D2M_EXP_IN    )=1;
        msdelay(10);
        REG(ADDR_D2M_EXP_IN    )=0;
        // ################################################
        func_printf("TOPRST END 1 \r\n");

        execute_cmd_d2m_set(&profile.d2);

        func_printf("TOPRST END 2 \r\n");
        return CMD_OK;
    }
    else if (num == 1)
    {
        if(data[0] == 0) // off
        {


            execute_cmd_d2m_dis();
            roic_settimingprofile(&profile.init); // 4343 set3 static
            roic_settimingfilter(&profile.init);


//          func_printf("TOPRST START 210806 \r\n");
//          REG(ADDR_TOPRST_CTRL)= 0xffff;
//          msdelay(1);
//          func_printf("TOPRST MID \r\n");
//          REG(ADDR_TOPRST_CTRL)= 0;
//          func_printf("TOPRST END \r\n");

                return CMD_OK;
        }
        else if(data[0] == 1) // wtp
        {
            roic_settimingprofile(&profile.d2);
            roic_settimingfilter(&profile.d2);
                return CMD_OK;
        }
        else if(data[0] == 2) // d2 set
        {
            execute_cmd_d2m_set(&profile.d2);
                return CMD_OK;
        }
        else if(data[0] == 3) // d2 dis
        {
            execute_cmd_d2m_dis();
                return CMD_OK;
        }
        else if(data[0] == 4) // trig
        {
            execute_cmd_d2m_en();
                return CMD_OK;
        }
        else if(data[0] == 5) // trig Dark
        {
            REG(ADDR_MPC_CTRL)= 0x4;
            execute_cmd_d2m_en();
            msdelay(5000);
            REG(ADDR_MPC_CTRL)= 0x0;
                return CMD_OK;
        }
        else if(data[0] == 6) // trig xray
        {
            REG(ADDR_MPC_CTRL)= 0x8;
            execute_cmd_d2m_en();
            msdelay(5000);
            REG(ADDR_MPC_CTRL)= 0x0;
                return CMD_OK;
        }
    }
    return CMD_ERR3;
}

u8 UART_CMD_edge(u8 num, u32* data) { // mbh 210923
    if(num == 1)
    {
        execute_cmd_edge(data[0], 0);
            return CMD_OK;
    }
    else if(num == 2)
    {
        execute_cmd_edge(data[0], data[1]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_dnr(u8 num, u32* data) { // mbh 210923
    if(num == 0)
    {
        disp_cmd_dnr();
           return CMD_OK;
    }
    else if(num == 1)
    {
        execute_cmd_dnr(data[0], 0);
            return CMD_OK;
    }
    else if(num == 2)
    {
        execute_cmd_dnr(data[0], data[1]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_acc(u8 num, u32* data) { // mbh 210923
    if(num == 0)
    {
        disp_cmd_acc();
        return CMD_OK;
    }
    else if(num == 1)
    {
        execute_cmd_acc(data[0], 0);
            return CMD_OK;
    }
    else if(num == 2)
    {
        execute_cmd_acc(data[0], data[1]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

//$ 2607241407 UART_CMD_spc: short pixel cover -> ADDR_SPC_CTRL(0x4A8)
// spc                            -> show help + current value
// spc <on>                       -> toggle bit0 only, keep other fields (RMW) //$ 2607241741
// spc <on> <dark> <rst> <sat>    -> full set (values mapped to reg nibble index)
u8 UART_CMD_spc(u8 num, u32* data) { //$ 2607241407
    if(num == 0)
    {
        disp_cmd_spc();
        return CMD_OK;
    }
    else if(num == 1)
    {
        execute_cmd_spc_en(data[0]); //$ 2607241741 bit0 RMW only
            return CMD_OK;
    }
    else if(num == 4)
    {
        execute_cmd_spc(data[0], data[1], data[2], data[3]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

//u8 UART_CMD_racc(u8 num, u32* data) { // mbh 210923
//  if(num == 1)
//  {
//      execute_cmd_racc(data[0]);
//          return CMD_OK;
//  }
//  return CMD_ERR3;
//}

//u8 UART_CMD_osd(u8 num, u32* data) { // mbh 210923
//  if(num == 0)
//  {
//      disp_cmd_osd();
//          return CMD_OK;
//  }
//  else if(num == 1)
//  {
//      execute_cmd_osd(data[0],0 , 0);
//          return CMD_OK;
//  }
//  else if(num == 3)
//  {
//      execute_cmd_osd(data[0], data[1], data[2]);
//          return CMD_OK;
//  }
//  return CMD_ERR3;
//}

u8 UART_CMD_osd(u8 num, u32* data) { // mbh 210923
    if(num == 0)
    {
        disp_cmd_osd();
            return CMD_OK;
    }
    else if(num == 1)
    {
        execute_cmd_osd(data[0],0 , 0);
            return CMD_OK;
    }
    else if(num == 3)
    {
        execute_cmd_osd(data[0], data[1], data[2]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_eao(u8 num, u32* data) { // mbh 211025
    if(num == 1)
    {
        execute_cmd_eao(data[0]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_trig(u8 num, u32* data) { // mbh 211105
    if(num == 1)
    {
        execute_api_ext_trig(data[0]);
            return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_fwtrig(u8 num, u32* data) { // mbh 211105
    if(num == 0)
    {
        if (func_apitrig_defence == 1)
        {
            func_apitrig_defence = 0;
            func_printf("func_fwtrig_defense 0 \r\n");
        }
        else
        {
            func_apitrig_defence = 1;
            func_printf("func_fwtrig_defense 1 \r\n");
        }
        return CMD_OK;
    }
    else if(num == 1)
    {
        execute_fw_ext_trig(data[0]);
            return CMD_OK;
    }
    else if(num == 2)
    {

        if (data[0]==0) // only rst_num save 211229mbh
        {
            func_insert_rst_num = data[1]; // srst insert value mbh 211224
            func_printf("set only func_insert_rst_num = %d \r\n",func_insert_rst_num);
        }
        else
            execute_fw_ext_trig_rst(data[0], func_insert_rst_num);

        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_extrst(u8 num, u32* data) { // mbh 211105
    if(num == 0)
    {
        func_printf("EXT_RST_MODE=(0:normal reset, 1:no reset, 2:time reset + detect time \r\n");
        func_printf("ex) exrst 2 100 (ms) = If not come in ext_trigger for 100msec it works like a normal reset. \r\n");
        func_printf("EXT_RST_MODE=%d , RST_DetTime=%dmsec \r\n",REG(ADDR_EXT_RST_MODE), REG(ADDR_EXT_RST_DetTime)*1000/FPGA_TFT_MAIN_CLK);
        return CMD_OK;
    }
    else if(num == 2)
    {
        execute_cmd_extrst(data[0], data[1]*1000); //ms * 1000
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rom(u8 num, u32* data) { // mbh 211105
    if(num == 0)
    {
        execute_cmd_rom();
        return CMD_OK;
    }

    else if(num == 1)
    {
        execute_cmd_romread();
        return CMD_OK;
    }
    return CMD_ERR3;
}

// ykkim
u8 UART_CMD_rreg(u8 num, u32* data) {
    if(num == 1) {
        if(data[0] < 0 || data[0] > 0xFF)           return CMD_ERR4;
        func_printf("RData : 0x%04X\r\n", execute_cmd_rroic(data[0]));
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 0xFF)           return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFF)         return CMD_ERR4;
        execute_cmd_wroic(data[0], data[1]);
        func_printf("WAddr: 0x%02x, WData : 0x%04x\r\n", data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_areg(u8 num, u32* data) {
    if(num == 1)    {
        if(data[0] < 0 || data[0] > 0xFFFFFFFF || (data[0] % 4))    return CMD_ERR4;
        func_printf("RData : 0x%08X\r\n", AREG(data[0]));
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 0xFFFFFFFF || (data[0] % 4))    return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)                     return CMD_ERR4;

        AREG(data[0]) = data[1];
        func_printf("WAddr : 0x%08X, WData : 0x%08X\r\n", data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_dreg(u8 num, u32* data) {
    if(num == 1) {
        if(data[0] < 0 || data[0] > 0xFFFFFFFF || (data[0] % 4))    return CMD_ERR4;    // dskim - 0.xx.08
        func_printf("RData : 0x%08x\r\n", DREG(data[0]));
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 0xFFFFFFFF || (data[0] % 4)) return CMD_ERR4;       // dskim - 0.xx.08
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)                 return CMD_ERR4;
        DREG(data[0]) = data[1];
        func_printf("WAddr : 0x%07x, WData : 0x%08x\r\n", data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_preg(u8 num, u32* data) {
    if(num == 2) {
        u16 rdata = mdio_read(data[0], data[1]);
        func_printf("RDevice : %d, RAddr : 0x%04x, RData : 0x%04x\r\n", data[0], data[1], rdata);
        return CMD_OK;
    }
    else if(num == 3) {
        mdio_write(data[0], data[1], data[2]);
        func_printf("WDevice : %d, WAddr : 0x%04x, WData : 0x%04x\r\n", data[0], data[1], data[2]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_pmode (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_pmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 1)      return CMD_ERR4;
        execute_cmd_pmode(data[0]);
        disp_cmd_pmode();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_pdead (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_pdead();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 10 || data[0] > 0xFFFF)    return CMD_ERR4;
        execute_cmd_pdead(data[0]);
        disp_cmd_pdead();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_grab (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_grab();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 1)  return CMD_ERR4;
        execute_cmd_grab(data[0]);
        disp_cmd_grab();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_fstat (u8 num, u32* data) {
    if (num == 0) {
        func_printf("@@@@ FRAMEBUFFER REGISTERS\r\n");
        framebuf_printregs();
        func_printf("\r\n");
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_finit (u8 num, u32* data) {
    if (num == 0) {
        func_printf("@@@@ INIT FRAMEBUFFER\r\n");
        func_printf("\r\n");
        framebuf_control = framebuf_control | FRAMEBUF_C_INIT;
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_fclr (u8 num, u32* data) {
    if (num == 0) {
        func_printf("@@@@ CLEAR STATISTICS\r\n");
        func_printf("\r\n");
        framebuf_control = framebuf_control | FRAMEBUF_C_CLRSTAT;
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

//# 2605081100 fov: one-line OVFLW summary, same format as [FBOV] auto-log in user_callback().
//# Use for quick polling without the full fstat dump. Run 'fclr' to clear sticky bits.
u8 UART_CMD_fov (u8 num, u32* data) {
    if (num == 0) {
        u32 s = framebuf_status;
        u32 ov = s & (FRAMEBUF_S_DF_OVFLW | FRAMEBUF_S_RF_OVFLW |
                      FRAMEBUF_S_IF_OVFLW | FRAMEBUF_S_TF_OVFLW);
        func_printf("[FBOV] framebuf_status=0x%08X (DF/RF/IF/TF=%c%c%c%c) %s\r\n",
                    (u32)s,
                    (s & FRAMEBUF_S_DF_OVFLW) ? 'D' : '-',
                    (s & FRAMEBUF_S_RF_OVFLW) ? 'R' : '-',
                    (s & FRAMEBUF_S_IF_OVFLW) ? 'I' : '-',
                    (s & FRAMEBUF_S_TF_OVFLW) ? 'T' : '-',
                    ov ? "[OVFLW SET - run fclr]" : "[OK]");
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

/* //# 2605181144 fdot (initial, superseded by 2605181217 mutex version below)
u8 UART_CMD_fdot (u8 num, u32* data) {
    if (num == 0) {
        func_printf("[FDOT] EN=%d\r\n", fb_tx_dot_en);
        return CMD_OK;
    }
    if (num == 1) {
        if (data[0] > 1) return CMD_ERR4;
        fb_tx_dot_en = (u8)data[0];
        func_printf("[FDOT] EN=%d\r\n", fb_tx_dot_en);
        return CMD_OK;
    }
    return CMD_ERR3;
}
//# 2605181144 ferr (initial, superseded by 2605181217 mutex version below)
u8 UART_CMD_ferr (u8 num, u32* data) {
    if (num == 0) {
        func_printf("[FERR] EN=%d\r\n", fb_err_msg_en);
        return CMD_OK;
    }
    if (num == 1) {
        if (data[0] > 1) return CMD_ERR4;
        fb_err_msg_en = (u8)data[0];
        func_printf("[FERR] EN=%d\r\n", fb_err_msg_en);
        return CMD_OK;
    }
    return CMD_ERR3;
}
*/

//# 2605181217 fdot: runtime toggle for ISR '.' progress (fb_tx_dot_en).
//# Mutex with ferr: turning fdot ON forces fb_err_msg_en=0 (other auto-OFF).
//# No arg = report both states. 1 arg (0/1) = set fdot.
u8 UART_CMD_fdot (u8 num, u32* data) {
    if (num == 0) {
        func_printf("[FDOT] EN=%d FERR=%d\r\n", fb_tx_dot_en, fb_err_msg_en);
        return CMD_OK;
    }
    if (num == 1) {
        if (data[0] > 1) return CMD_ERR4;
        fb_tx_dot_en = (u8)data[0];
        if (fb_tx_dot_en && fb_err_msg_en) {        // mutex: ON forces other OFF
            fb_err_msg_en = 0;
            func_printf("[FDOT] EN=1 (FERR auto-OFF)\r\n");
        } else {
            func_printf("[FDOT] EN=%d FERR=%d\r\n", fb_tx_dot_en, fb_err_msg_en);
        }
        return CMD_OK;
    }
    return CMD_ERR3;
}

//# 2605181217 ferr: runtime toggle for ISR overflow rising-edge msg (fb_err_msg_en).
//# Mutex with fdot: turning ferr ON forces fb_tx_dot_en=0 (other auto-OFF).
//# No arg = report both states. 1 arg (0/1) = set ferr.
u8 UART_CMD_ferr (u8 num, u32* data) {
    if (num == 0) {
        func_printf("[FERR] EN=%d FDOT=%d\r\n", fb_err_msg_en, fb_tx_dot_en);
        return CMD_OK;
    }
    if (num == 1) {
        if (data[0] > 1) return CMD_ERR4;
        fb_err_msg_en = (u8)data[0];
        if (fb_err_msg_en && fb_tx_dot_en) {        // mutex: ON forces other OFF
            fb_tx_dot_en = 0;
            func_printf("[FERR] EN=1 (FDOT auto-OFF)\r\n");
        } else {
            func_printf("[FERR] EN=%d FDOT=%d\r\n", fb_err_msg_en, fb_tx_dot_en);
        }
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_pdbg (u8 num, u32* data) {
    if (num == 1) {
        func_printf("@@@@ PHY DEBUG (select option number)\r\n");
        m88x33xx_debug(data[0]);
        func_printf("\r\n");
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_prev (u8 num, u32* data) {
    if (num == 0) {
        func_printf("@@@@ PHY REVISION\r\n");
        m88x33xx_revision();
        func_printf("\r\n");
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_flash(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_flash();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > (FLASH_SIZE - 1))   return CMD_ERR4;
        execute_cmd_rflash(data[0]);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > (FLASH_SIZE - 1))   return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)         return CMD_ERR4;
        execute_cmd_wflash(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rflash(u8 num, u32* data) { //# 220920
    if(num == 0) {
        disp_cmd_flash();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > (FLASH_SIZE - 1))   return CMD_ERR4;
        execute_cmd_rflash(data[0]);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > (FLASH_SIZE - 1))   return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)         return CMD_ERR4;
        for (int i=0; i<data[1]; i=i+4)
        {
            execute_cmd_rflash(data[0]+i);
        }
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}
u8 UART_CMD_eeprom(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_eeprom();

        for (u32 k = 0; k<0x2000; k=k+4)
            execute_cmd_reep(k);

        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > (EEPROM_SIZE - 1))  return CMD_ERR4;
        execute_cmd_reep(data[0]);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > (EEPROM_SIZE - 1))  return CMD_ERR4;
        if(data[1] < 0 || data[1] > 0xFFFFFFFF)         return CMD_ERR4;
        execute_cmd_weep(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_erase(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_erase();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 32)     return CMD_ERR4;
        execute_cmd_erase(data[0]);
        return CMD_OK;
    }
//  else if(num == 2) { //# 230206
//      if(data[0] < 0 || data[0] > 32)     return CMD_ERR4;
//      execute_cmd_flashrw(data[0]);
//      return CMD_OK;
//  }
    else
        return CMD_ERR3;
}

u8 UART_CMD_cddr(u8 num, u32* data) {
    u32 grab  = func_grab_en;

//if(DEBUGPRINT) // mbh 210108
//  func_printf("grab=%d\r\n",grab);


    if(num == 0) {
        disp_cmd_cddr();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 9)  return CMD_ERR4;
        execute_cmd_grab(0);
        execute_cmd_cddr(data[0]);
        execute_cmd_grab(grab);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wddr(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_wddr();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 1 || data[0] > 5)  return CMD_ERR4;
        execute_cmd_wddr(data[0], 0);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 1 || data[0] > 5)  return CMD_ERR4;
        if(data[1] < 0 || data[1] > 7)  return CMD_ERR4;
        execute_cmd_wddr(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rddr(u8 num, u32* data) {
    if(num == 0) {
//      disp_cmd_wddr();
        disp_cmd_rddr(); //# 2605141540 bare 'rddr' now prints dose0..5 cache
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 1 || data[0] > 5)  return CMD_ERR4;
        //execute_cmd_rddr(data[0], 0);
        func_rddr_token = data[0]; //$ 2607131936 deferred via token (execute_rddr_cmd in while loop)
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_tempbcal(u8 num, u32* data) { // 220118mbh
    if(num == 0) {
        if (func_tempbcal == 1)
            func_printf("Tempbcal read is ON \r\n");
        else
            func_printf("Tempbcal read is OFF \r\n");
        return CMD_OK;
    }
    else if(num == 1) {
        if (data[0] == 1){
            func_tempbcal = 1;
            func_printf("Tempbcal is ON \r\n");
        }
        else {
            func_tempbcal = 0;
            func_printf("Tempbcal is OFF \r\n");
        }
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_bcal1(u8 num, u32* data) {

    if(num == 0) {
    func_bcal1_token = 1;
    return CMD_OK;
}
    else if(num == 1) {
        if (data[0]==1){
            REG(ADDR_BCAL_CTRL) = 0x100; // bcal pass force /210820mbh
            func_bcal1_token = 1;
        }
        else {
            REG(ADDR_BCAL_CTRL) = 0;
            func_bcal1_token = 1;
        }
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_bcal(u8 num, u32* data) {

    func_printf("bacl debug mode (bcal pass) : ex) bcal 1 \r\n");
    func_printf("bacl repeat & interval      : ex) bcal 10 10"" \r\n");
    u32 keepx10 = execute_cmd_rroic(0x10);

    if(num == 0) {
        bw_align();
        execute_cmd_wroic(0x10,keepx10);
        execute_cmd_bcal_rdata();
        return CMD_OK;
    }
    else if(num == 1) {
//      for(u16 i=0; i<data[0]; i++){
        if (data[0]==1){
            REG(ADDR_BCAL_CTRL) = 0x100; // bcal pass force /210820mbh
            bw_align();
        }
        else {
            REG(ADDR_BCAL_CTRL) = 0;
            bw_align();
        }

//      }
        execute_cmd_wroic(0x10,keepx10);
        execute_cmd_bcal_rdata();
        return CMD_OK;
    }
    else if(num == 2) {
        for(u16 i=0; i<data[0]; i++){
            bw_align();
            msdelay(data[1]);
            gige_callback(0); // keep the line 211101
        }
        execute_cmd_wroic(0x10,keepx10);
        execute_cmd_bcal_rdata();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

// 2604242200 FW-driven bit-align command
//   bcalfw                 -> all ROIC_NUM channels (stable+word, verbose)
//   bcalfw <ch>            -> single channel, verbose=1 (full bit_stable + word_align)
//   bcalfw <ch> 1          -> bit_stable only
//   bcalfw <ch> 2          -> word_align only (uses current IDELAY)
//   bcalfw <ch> 3 <tap>    -> probe: set ch, RST then CE x tap, dump par/status
u8 UART_CMD_bcalfw(u8 num, u32* data) {
    BCALFW_DBG("[dbg] bcalfw enter num=%d\r\n", (int)num);

    if (num == 0) {
        // 2604250500 split big multi-string printf into short calls (long single
        //            call appears to trigger system error on this build)
        func_printf("bcalfw usage:\r\n");
        func_printf("  bcalfw                  : all ROIC ch (report only)\r\n");
        func_printf("  bcalfw <ch>             : single ch stable+word\r\n");
        func_printf("  bcalfw <ch> 1           : bit_stable only\r\n");
        func_printf("  bcalfw <ch> 2           : word_align only\r\n");
        func_printf("  bcalfw <ch> 3 <tap>     : probe (dump par/status)\r\n");
        func_printf("  ---- step-separated:\r\n");
        func_printf("  bcalfwi  bcalfws [ch]  bcalfww [ch]  bcalfwx\r\n");
        bw_align_fw_run_all(0);   // quiet sweep, prints summary report at end
        return CMD_OK;
    }

    if (data[0] >= ROIC_NUM) return CMD_ERR4;
    u8 ch = (u8)data[0];

    if (num == 1) {
        bcal_fw_full_result_t r;
        bw_align_fw_run_one_ch(ch, &r, 1);
        bw_align_fw_exit();
        return CMD_OK;
    }

    u32 mode = data[1];
    if (num == 2) {
        if (mode == 1) {
            bw_align_fw_init();
            bcal_fw_stable_result_t r;
            bw_align_fw_bit_stable(ch, &r, 1);
            bw_align_fw_exit();
            return CMD_OK;
        }
        if (mode == 2) {
            bw_align_fw_init();
            bcal_fw_word_result_t r;
            bw_align_fw_word_align(ch, &r, 1);
            bw_align_fw_exit();
            return CMD_OK;
        }
        return CMD_ERR4;
    }

    if (num == 3 && mode == 3) {
        if (data[2] > 31) return CMD_ERR4;
        u8 tap = (u8)data[2];
        bw_align_fw_init();
        bw_align_fw_set_ch(ch);
        bw_align_fw_pulse(BCAL_FW_PULSE_RST);
        usdelay(100);
        for (u8 i = 0; i < tap; i++) {
            bw_align_fw_pulse(BCAL_FW_PULSE_CE);
            usdelay(2);
        }
        usdelay(100);
        u32 par = bw_align_fw_read_par();
        u32 st  = bw_align_fw_read_status();
        func_printf("ch%2d tap=%2d  par=0x%06lX  diff=%lu ff00=%lu  ocnt=%lu\r\n",
                    ch, tap,
                    (unsigned long)(par & 0xFFFFFF),
                    (unsigned long)((par >> 24) & 1),
                    (unsigned long)((par >> 25) & 1),
                    (unsigned long)(st & 0x1F));
        bw_align_fw_exit();
        return CMD_OK;
    }
    return CMD_ERR3;
}

// 2604250010 step-separated commands for incremental debugging.
// Workflow: bcalfwi -> bcalfws [ch] -> bcalfww [ch] -> bcalfwx
// Each command prints results immediately (no accumulated storage).
u8 UART_CMD_bcalfwi(u8 num, u32* data) {
    (void)num; (void)data;
    bw_align_fw_init();
    func_printf("bcalfw init done (fw_mode ON)\r\n");
    return CMD_OK;
}

u8 UART_CMD_bcalfwx(u8 num, u32* data) {
    (void)num; (void)data;
    bw_align_fw_exit();
    func_printf("bcalfw exit done (fw_mode OFF, ROIC normal)\r\n");
    return CMD_OK;
}

u8 UART_CMD_bcalfws(u8 num, u32* data) {
    // 2604250230 no arg = run all ROIC channels (yield between for main-loop)
    if (num == 0) {
        for (u32 ch = 0; ch < ROIC_NUM; ch++) {
            bcal_fw_stable_result_t r;
            bw_align_fw_bit_stable((u8)ch, &r, 1);
            gige_callback(0); msdelay(20); gige_callback(0);
        }
        return CMD_OK;
    }
    if (num != 1)            return CMD_ERR3;
    if (data[0] >= ROIC_NUM) return CMD_ERR4;
    bcal_fw_stable_result_t r;
    bw_align_fw_bit_stable((u8)data[0], &r, 1);
    return CMD_OK;
}

u8 UART_CMD_bcalfww(u8 num, u32* data) {
    // 2604250230 no arg = run all ROIC channels (yield between for main-loop)
    if (num == 0) {
        for (u32 ch = 0; ch < ROIC_NUM; ch++) {
            bcal_fw_word_result_t r;
            bw_align_fw_word_align((u8)ch, &r, 1);
            gige_callback(0); msdelay(20); gige_callback(0);
        }
        return CMD_OK;
    }
    if (num != 1)            return CMD_ERR3;
    if (data[0] >= ROIC_NUM) return CMD_ERR4;
    bcal_fw_word_result_t r;
    bw_align_fw_word_align((u8)data[0], &r, 1);
    return CMD_OK;
}

u8 UART_CMD_gcal(u8 num, u32* data) {
    if(num == 0) {
        if(func_ref_num < 2)                    return CMD_ERR16;
        execute_cmd_gcal();
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 100 || data[0] > 65535)    return CMD_ERR4;
        if(data[1] < 100 || data[1] > 65535)    return CMD_ERR4;
        if(func_ref_num < 2)                    return CMD_ERR16;
            execute_cmd_gcal();
        disp_cmd_rdot();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_ucal(u8 num, u32* data) {
    if(num == 0) {
        if(func_ref_num < 1)                    return CMD_ERR16;
        execute_cmd_ucal();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_dcal(u8 num, u32* data) {
    if(num == 1) {
        execute_cmd_dcal(data[0]);
        disp_cmd_rdot();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_sens(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_sens();
        return CMD_OK;
    }
    else if(num == 1) {
        execute_cmd_sens(data[0]);
        disp_cmd_sens();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}



u8 UART_CMD_wdot(u8 num, u32* data) {
    u32 err = 0;
    int i ;

    if(num == 0) {
        execute_cmd_rdot(1);
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;
        if(data[1] < 0 || data[1] > MAX_HEIGHT)     return CMD_ERR4;

        err = execute_cmd_wdot(data[0], data[1], 0);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wdot(data[0], data[1], 0);
        return CMD_OK;
    }
    else if(num == 3) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;
        if(data[1] < 0 || data[1] > MAX_HEIGHT)     return CMD_ERR4;
        if(data[2] < 0 || data[2] > 1)              return CMD_ERR4;

        err = execute_cmd_wdot(data[0], data[1], data[2]);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wdot(data[0], data[1], data[2]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wrdot(u8 num, u32* data) {
    u32 err = 0;

    if(num == 0) {
        execute_cmd_rdot(2);    func_printf("\r\n");
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > MAX_HEIGHT)     return CMD_ERR4;

        err = execute_cmd_wrdot(data[0], 0);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wrdot(data[0], 0);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > MAX_HEIGHT)     return CMD_ERR4;
        if(data[1] < 0 || data[1] > 1)              return CMD_ERR4;

        err = execute_cmd_wrdot(data[0], data[1]);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wrdot(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wcdot(u8 num, u32* data) {
    u32 err = 0;

    if(num == 0) {
        execute_cmd_rdot(3);    func_printf("\r\n");
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;

        err = execute_cmd_wcdot(data[0], 0);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wcdot(data[0], 0);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;
        if(data[1] < 0 || data[1] > 1)              return CMD_ERR4;

        err = execute_cmd_wcdot(data[0], data[1]);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wcdot(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

// dskim - 21.09.24
u8 UART_CMD_wdot_factory(u8 num, u32* data) {
    u32 err = 0;

    if(num == 0) {
        execute_cmd_rdot(1);
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;
        if(data[1] < 0 || data[1] > MAX_HEIGHT)     return CMD_ERR4;

        err = execute_cmd_wdot_factory(data[0], data[1], 0);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wdot(data[0], data[1], 0);
        return CMD_OK;
    }
    else if(num == 3) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;
        if(data[1] < 0 || data[1] > MAX_HEIGHT)     return CMD_ERR4;
        if(data[2] < 0 || data[2] > 1)              return CMD_ERR4;

        err = execute_cmd_wdot_factory(data[0], data[1], data[2]);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wdot(data[0], data[1], data[2]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wrdot_factory(u8 num, u32* data) {
    u32 err = 0;

    if(num == 0) {
        execute_cmd_rdot(2);    func_printf("\r\n");
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > MAX_HEIGHT)     return CMD_ERR4;

        err = execute_cmd_wrdot_factory(data[0], 0);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wrdot(data[0], 0);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > MAX_HEIGHT)     return CMD_ERR4;
        if(data[1] < 0 || data[1] > 1)              return CMD_ERR4;

        err = execute_cmd_wrdot_factory(data[0], data[1]);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wrdot(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wcdot_factory(u8 num, u32* data) {
    u32 err = 0;

    if(num == 0) {
        execute_cmd_rdot(3);    func_printf("\r\n");
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;

        err = execute_cmd_wcdot_factory(data[0], 0);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wcdot(data[0], 0);
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > MAX_WIDTH)      return CMD_ERR4;
        if(data[1] < 0 || data[1] > 1)              return CMD_ERR4;

        err = execute_cmd_wcdot_factory(data[0], data[1]);
        if(err == 1)                                return CMD_ERR19;
        else if(err == 2)                           return CMD_ERR20;
        disp_cmd_wcdot(data[0], data[1]);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rdot(u8 num, u32* data) {

    if(num == 1) {
        if(data[0] < 0 || data[0] > 3)      return CMD_ERR4;
        execute_cmd_rdot(data[0]);
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0 || data[0] > 3)      return CMD_ERR4;
        execute_cmd_frdot(data[0], data[1]);
//      disp_cmd_rdot();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_cdot(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_rdot();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 3)      return CMD_ERR4;
        execute_cmd_cdot(data[0]);
        disp_cmd_rdot();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wns(u8 num, u32* data) {
    u32 grab = func_grab_en;

    if(num == 0) {
        if(REG(ADDR_OUT_EN))                return CMD_ERR5;

        execute_cmd_grab(0);
        execute_cmd_wns();
        execute_cmd_grab(grab);

        return CMD_OK;
    }
    else if(num == 1) {
        if(REG(ADDR_OUT_EN))                return CMD_ERR5;

        execute_cmd_grab(0);
//      func_ref_num = 5;
        if (data[0]==0)
            execute_cmd_bwns();
        else if (data[0]==1)
            execute_cmd_bwns1(); // erase
        else if (data[0]==2)
            execute_cmd_bwns2(); // erase check
        else if (data[0]==3)
            execute_cmd_bwns3(); // write
        else if (data[0]==4)
            execute_cmd_bwns4(); // write check


        execute_cmd_grab(grab);

        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rns(u8 num, u32* data) {
    u32 grab = func_grab_en;

    if(num == 0) {
//        if(REG(ADDR_OUT_EN))                return CMD_ERR5;
//
//        execute_cmd_grab(0);
//        if(execute_cmd_rns())               return CMD_ERR9;
//        execute_cmd_grab(grab);
        //# 2605211347 UART 'rns' (no arg) -> read-only rns_display() dump
        // Why: original path actually performs ROM->DDR load and hangs on
        //      corrupted headers (flash_ref_num=0). Replace with diagnostic
        //      dump only. brns (rns 1) and XML calib path keep original.
        (void)grab;
        rns_display();
        return CMD_OK;
    }

    //# 2606121641 FIX: num is ARGUMENT COUNT, value comes in data[0]
    //              ('rns 3' -> num=1, data[0]=3). Previous num==2/3 branches were
    //              unreachable and 'rns 2/3' fell into the sync full-load path.
    else if(num == 1) {
        switch(data[0]) {
        case 1 : // "rns 1" burst rns (legacy sync full load)
            if(REG(ADDR_OUT_EN))                return CMD_ERR5;
            //# 2606121417 UART rns1: reject while background NUC load in progress
            if(brns_bg_active())                return CMD_ERR5;    // busy: bg load running

            execute_cmd_grab(0);
            if(execute_cmd_brns())              return CMD_ERR9;
            execute_cmd_grab(grab);
            return CMD_OK;

        //# 2606121417 UART rns2: request background NUC reload (BRNS_BG_LOAD=1 only)
        case 2 :
#if BRNS_BG_LOAD
            brns_bg_request();
            func_printf("\r\n[BRNS-BG] reload requested\r\n");
            return CMD_OK;
#else
            return CMD_ERR3;    // not available in legacy build
#endif

        //# 2606121417 UART rns3: background NUC load status query
        case 3 :
#if BRNS_BG_LOAD
            //# 2606121543 rns3: extended dump incl. chunk sizes + timing stats
            brns_bg_disp_status();
            return CMD_OK;
#else
            return CMD_ERR3;
#endif

        default :
            return CMD_ERR3;
        }
    }
    else
        return CMD_ERR3;
}


u8 UART_CMD_wds(u8 num, u32* data) {
    if(num == 0) {
//      if(!(func_defect_cnt + func_defect_cnt2))   return CMD_ERR9;
        if(!(func_defect_cnt + func_defect_cnt2 + func_defect_cnt3))    return CMD_ERR9;
        execute_cmd_wds();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_rds(u8 num, u32* data) {
    if(num == 0) {
        if(execute_cmd_rds())       return CMD_ERR9;
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_hwdbg(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_hwdbg();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 2)  return CMD_ERR4;
        execute_cmd_hwdbg(data[0]);
        disp_cmd_hwdbg();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_bright(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_bright();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 0x1FFFF)    return CMD_ERR4;
        execute_cmd_bright(data[0]);
        disp_cmd_bright();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_contra(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_contra();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 65535)  return CMD_ERR4;
        execute_cmd_contra(data[0]);
        disp_cmd_contra();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

// TI_ROIC
//u8 UART_CMD_hroic(u8 num, u32* data) {
//  if (num == 0) {
//      func_printf("\033[2J");
//      func_printf("\033[0;0H");
//
//      disp_cmd_hroic();
//      return CMD_OK;
//  }
//  else
//      return CMD_ERR3;
//}

u8 UART_CMD_tstat(u8 num, u32* data) {
    if (num == 0) {
//        func_printf("\033[2J"); //# 230630
//        func_printf("\033[0;0H");

        disp_cmd_tstat();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_mac(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_mac();
        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0  || data[0] > 0xFFFF)        return CMD_ERR4;
        if(data[1] < 0  || data[1] > 0xFFFFFFFF)    return CMD_ERR4;
        execute_cmd_mac(data[0], data[1]);
        disp_cmd_mac();
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_ip(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_ip();
        //# 2605121743 Dump the 3 conditions used by check_sfp_stat to gate the deferred m88x init
        {
            u32 ip = XREG(XGIGE_ADDR_IP);
            func_printf("[ip cond] g_port_sel=%u  once88m=%d  XREG(IP)=0x%08x (nz=%u)\r\n",
                        (u32)g_port_sel, once88m, ip, (ip != 0));
            func_printf("[ip cond] combined ((port_sel==0)&&(once88m==0)&&(IP!=0)) = %u\r\n",
                        ((g_port_sel == 0) && (once88m == 0) && (ip != 0)));
        }
        return CMD_OK;
    }
    if(num == 1) {
        func_printf("m88x33xx_init\r\n");
        m88x33xx_init(RXAUI);
        return CMD_OK;
    }
    else if(num == 4) {
        if(data[0] < 0  || data[0] > 0xFF)      return CMD_ERR4;
        if(data[1] < 0  || data[1] > 0xFF)      return CMD_ERR4;
        if(data[2] < 0  || data[2] > 0xFF)      return CMD_ERR4;
        if(data[3] < 0  || data[3] > 0xFF)      return CMD_ERR4;

        execute_cmd_ip(data[0], data[1], data[2], data[3]);
        disp_cmd_ip();
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_smask(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_smask();
        return CMD_OK;
    }
    else if(num == 4) {
        if(data[0] < 0  || data[0] > 0xFF)      return CMD_ERR4;
        if(data[1] < 0  || data[1] > 0xFF)      return CMD_ERR4;
        if(data[2] < 0  || data[2] > 0xFF)      return CMD_ERR4;
        if(data[3] < 0  || data[3] > 0xFF)      return CMD_ERR4;
        execute_cmd_smask(data[0], data[1], data[2], data[3]);
        disp_cmd_smask();
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_gate(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_gate();
        return CMD_OK;
    }
    else if(num == 4) {
        if(data[0] < 0  || data[0] > 0xFF)      return CMD_ERR4;
        if(data[1] < 0  || data[1] > 0xFF)      return CMD_ERR4;
        if(data[2] < 0  || data[2] > 0xFF)      return CMD_ERR4;
        if(data[3] < 0  || data[3] > 0xFF)      return CMD_ERR4;

        execute_cmd_gate(data[0], data[1], data[2], data[3]);
        disp_cmd_gate();
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_ipmode(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_ipmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 1  || data[0] > 7)     return CMD_ERR4;
        execute_cmd_ipmode(data[0]);
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_intrst(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_intrst();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_intrst((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_intrst();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_cds1(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_cds1();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_cds1((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_cds1();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_cds2(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_cds2();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_cds2((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_cds2();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_fa(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_fa();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_fa((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_fa();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_dead(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_dead();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_dead((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_dead();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_mute(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_mute();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_mute((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_mute();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_oe(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_oe();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_oe((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_oe();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_xon(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_xon();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_xon((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_xon();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_flk(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_flk();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_flk((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_flk();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_xonflk(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_xonflk();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_xonflk((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_xonflk();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_rcycle(u8 num, u32* data) {
    float fval;

    if(sys_state.float_state)   fval = data[0] / 1000.0;
    else                        fval = (float) data[0];
    sys_state.float_state = 0;

    if(num == 0) {
        disp_cmd_rcycle();
        return CMD_OK;
    }
    else if(num == 1) {
        if(fval < 0     || fval > 1000)     return CMD_ERR4;

        execute_cmd_rcycle((u32)(fval * 1000));
        execute_cmd_fmax();
        execute_cmd_frate((u32)(func_frate*1000));

        disp_cmd_rcycle();
        disp_cmd_fmax();
        disp_cmd_emax();
        disp_cmd_frate();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

// TI_ROIC
//u8 UART_CMD_roicval(u8 num, u32* data) {
//  if(num == 0) {
//      disp_cmd_roicval();
//      return CMD_OK;
//  }
//  else {
//      return CMD_ERR3;
//  }
//}

u8 UART_CMD_timg(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_timg();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 1 || data[0] > 5)          return CMD_ERR4;
        execute_cmd_timg(data[0]);
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_tfrate(u8 num, u32* data) {
    if(num == 0) {
        disp_cmd_tfrate();
        execute_cmd_tfrate(0, 0, 0);
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0 || data[0] > 1000)       return CMD_ERR4;
        execute_cmd_tfrate(data[0], func_trig_duty, 1);
        disp_cmd_tfrate();
        return CMD_OK;
    }
    else if(num == 3) {
        if(data[0] < 0 || data[0] > 1000)       return CMD_ERR4;
        if(data[1] < 1 || data[1] > 99)         return CMD_ERR4;

        execute_cmd_tfrate(data[0], data[1], data[2]);
        disp_cmd_tfrate();
        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_crmode(u8 num, u32* data) {

    if(num == 0) {
        disp_cmd_crmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0  || data[0] > 1)         return CMD_ERR4;

        execute_cmd_crmode(data[0]);
        disp_cmd_crmode();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}


u8 UART_CMD_srmode(u8 num, u32* data) {

    if(num == 0) {
        disp_cmd_srmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0  || data[0] > 1)         return CMD_ERR4;

        if(data[0] == 0)    execute_cmd_srmode(data[0], func_gate_rnum);
        else                execute_cmd_srmode(data[0], func_sexp_time);
        disp_cmd_srmode();

        return CMD_OK;
    }
    else if(num == 2) {
        if(data[0] < 0  || data[0] > 1)         return CMD_ERR4;
        if(data[0] < 0  || data[0] > 8)         return CMD_ERR4;

        execute_cmd_srmode(data[0], data[1]);
        disp_cmd_srmode();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

u8 UART_CMD_tseq(u8 num, u32* data) {

    if(num == 0) {
        disp_cmd_tseq();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 0  || data[0] > 3)         return CMD_ERR4;

        execute_cmd_tseq(data[0]);
        disp_cmd_tseq();

        return CMD_OK;
    }
    else {
        return CMD_ERR3;
    }
}

//edge 0x1000000a
//edge 0x2000000a
//edge 0x3000000a
//edge 0x4000000a
//edge 0x5000c350
u8 UART_CMD_edge_cut (u8 num, u32* data) {  // dskim - 21.09.24
    if (num == 0) {
        disp_cmd_edge_cut();
        return CMD_OK;
    }
    else if (num == 1) {
        if(execute_cmd_parser(data[0])) return CMD_ERR4;
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_edge_save (u8 num, u32* data) { // dskim - 21.09.24
    if (num == 0) {
        execute_cmd_edge_cut_save(0);
        execute_cmd_edge_cut_save(1);
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_wake (u8 num, u32* data) {  //# 220318mbh
    if (num == 0) {
        execute_cmd_wake();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_sleep (u8 num, u32* data) { //# 220318mbh
    if (num == 0) {
        execute_cmd_sleep();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_sleepmode (u8 num, u32* data) { //# 220318mbh
    if (num == 0) {
        disp_cmd_sleepmode();
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] > 3)
            return CMD_ERR4;

        execute_cmd_sleep_mode(data[0]);

        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

u8 UART_CMD_pwdac(u8 num, u32* data) { // mbh 220429
    if (num == 0) {
        disp_cmd_pwdac();
        return CMD_OK;
    }
    else if(num == 1) {
        execute_cmd_pwdac(0, 0, 0);
        return CMD_OK;
    }
    else if(num == 3)
    {
        execute_cmd_pwdac(data[0], data[1], data[2]);
        return CMD_OK;
    }
    return CMD_ERR3;
}

//u8 UART_CMD_pixpos(u8 num, u32* data) { // mbh 220524
//  if (num == 0) {
//      disp_cmd_pixpos();
//      return CMD_OK;
//  }
//  else if(num == 1) {
//      execute_cmd_pixpos(0, 0, 0);
//      return CMD_OK;
//  }
//  else if(num == 3)
//  {
//      execute_cmd_pixpos(data[0], data[1], data[2]);
//      return CMD_OK;
//  }
//  return CMD_ERR3;
//}

u8 UART_CMD_rstdev(u8 num, u32* data) { // mbh 220524
    if (num == 0) {
        execute_cmd_reset_device();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_fch(u8 num, u32* data) { //# 220919mbh
    if (num == 0) {
        execute_cmd_flash_check();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_fpdiff(u8 num, u32* data) { //# 220919mbh
    if (num == 0) {
        execute_cmd_fpdiff();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_fwdiff(u8 num, u32* data) { //# 220919mbh
    if (num == 0) {
        execute_cmd_fwdiff();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_sw_gain_mode (u8 num, u32* data) {  //# 220928dskim
    if (num == 1) {
        execute_cmd_write_oper_mode(data[0]);
        return CMD_OK;
    } else
        return CMD_ERR3;
}

u8 UART_CMD_load_hw_calibration (u8 num, u32* data) {   //# 220928dskim
    if (num == 0) {
        execute_cmd_load_hw_calibration(1);
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_dmesg(u8 num, u32* data) { //# 210928
    if(num == 0)
    {
        //# dmesg
        for(u32 dmesgi=0; dmesgi<128; dmesgi++)
        {
            for(u32 dmesgj=0; dmesgj<128; dmesgj++)
            {
                func_printf("%c",temparr[dmesgi][dmesgj]);
    //          func_printf("%c%02x",temparr[dmesgi][dmesgj],temparr[dmesgi][dmesgj]); //# code print
            }
            func_printf("\n\r");
        }
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_flash4b(u8 num, u32* data) { //# 210928
    if(num == 0)
    {

        flash_enter4b();
        checker_rom();
        return CMD_OK;
    }
    return CMD_ERR3;
}


u8 UART_CMD_stop(u8 num, u32* data) { //# 210928
    if(num == 0)
    {
        fw_stop();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_triglog(u8 num, u32* data) { //# 210928
    if(num == 1)
    {
        execute_cmd_triglog(data[0]);
        return CMD_OK;
    }
    return CMD_ERR3;
}


u8 UART_CMD_topv(u8 num, u32* data) { //# 210928
    if(num == 0)
    {
        disp_cmd_topv();
    }
    else if(num == 1)
    {
        execute_topvalue_set(data[0]);
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_bnc(u8 num, u32* data) { //# 210928
    if(num == 0)
    {
        disp_cmd_bnc();
    }
    else if(num == 1)
    {
        execute_cmd_bnc(data[0]);
        return CMD_OK;
    }
    return CMD_ERR3;
}


u8 UART_CMD_eq(u8 num, u32* data) { //# 210928
    if(num == 0)
    {
        disp_cmd_eq();
    }
    else if(num == 1)
    {
        execute_cmd_eq(data[0]);
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_able(u8 num, u32* data) { //# 210928
    if(num == 0)
    {
    	get_able_func();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_romdiag(u8 num, u32* data) { //# 231017
    if(num == 0)
    {
    	disp_cmd_romdiag();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_romread(u8 num, u32* data) { //# 231017
    if(num == 0)
    {
    	disp_cmd_romread();
        return CMD_OK;
    }
    else if(num == 1)
    {
    	execute_cmd_rombulkcheck(data[0]);
        return CMD_OK;
    }

    else if(num == 2)
    {
    	execute_cmd_rombulkread(data[0], data[1]);
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_ropertime(u8 num, u32* data) { //# 231017
    if(num == 0)
    {
    	disp_cmd_ropertime();
        return CMD_OK;
    }
    return CMD_ERR3;
}

u8 UART_CMD_fpgareboot (u8 num, u32* data) {
    if (num == 0) {
        execute_cmd_fpgareboot();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}
u8 UART_CMD_doc (u8 num, u32* data) {
    if (num == 0) {
        disp_cmd_doc();
        return CMD_OK;
    }
    else if (num == 1) {
        if(data[0] < 0 || data[0] > 1)          return CMD_ERR4;
        if(data[0] == 1) execute_cmd_doc();
        else			 {execute_cmd_wroic(0x51, 0x0000); func_doc = 0;}
        disp_cmd_doc();
        return CMD_OK;
    }
    else
        return CMD_ERR3;
}

