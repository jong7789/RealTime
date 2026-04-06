/*
 * uart_cmd.c
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#include "command.h"
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
    {"debug"    , UART_CMD_debug        , "Read Current User Setting(Debug)"           , 0 }, // dskim
    {"rtime"    , UART_CMD_rtime        , "Display Running Time"                       , 0 },
    {"rtemp"    , UART_CMD_rtemp        , "Read Temperature"                           , 0 },
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
//  {"bcal"     , UART_CMD_bcal         , "Bit align calibration repeater"             , 0 },
    {"bcal"     , UART_CMD_bcal1        , "Bit align calibration repeater"             , 0 },
    {"bcal1"    , UART_CMD_bcal1        , "Bit align calibration repeater"             , 0 },
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

        execute_cmd_frate((u32)(fval * 1000));
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
    	if(AFE3256_series){ //$ 260403 12 step
    		if(data[0] > 11) return CMD_ERR4;
    	} else {
    		if(data[0] > 15) return CMD_ERR4;
    	}
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

u8 UART_CMD_debug (u8 num, u32* data) {
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
        return CMD_OK;
    }
    else if(num == 1) {
        if(data[0] < 1 || data[0] > 5)  return CMD_ERR4;
        execute_cmd_rddr(data[0], 0);
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
        if(REG(ADDR_OUT_EN))                return CMD_ERR5;

        execute_cmd_grab(0);
        if(execute_cmd_rns())               return CMD_ERR9;
        execute_cmd_grab(grab);
        return CMD_OK;
    }

    else if(num == 1) { // "rns 1" burst rns
        if(REG(ADDR_OUT_EN))                return CMD_ERR5;

        execute_cmd_grab(0);
        if(execute_cmd_brns())              return CMD_ERR9;
        execute_cmd_grab(grab);
        return CMD_OK;
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

