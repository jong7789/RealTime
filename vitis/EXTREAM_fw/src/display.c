/*
 * display.c
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */
#include "display.h"

#include <stdio.h>
#include "func_printf.h"

#include "gige.h"
#include "flash.h"
#include "framebuf.h"

#include "func_cmd.h"
#include "command.h"
#include "func_basic.h"
#include "fpga_info.h"

//  static char *msg_ipmode             = "[00] IP Config:         ";
static char *msg_gev_speed          = "Connected at:           ";
static char *msg_tser               = "[00] TFT Serial:        ";
static char *msg_pser               = "[00] Panel Serial:      ";
static char *msg_dver               = "[00] FW Version:        ";
static char *msg_fver               = "[00] FPGA Version:      ";

static char *msg_bwidth             = "[00] GEV Bandwidth:     ";
static char *msg_rsnd               = "[00] Resending Packet:  ";
static char *msg_rtime              = "[00] Running Time:      ";
static char *msg_rtemp              = "[00] Temperature:       ";

static char *msg_us                 = "[00] Preset Table:      ";
static char *msg_usname             = "[00] Descriptions:      ";
static char *msg_roi                = "[00] Resolution:        ";
static char *msg_frate              = "[00] Frame Rate:        ";
static char *msg_ewt                = "[00] Total EWT:         ";
// TI_ROIC
static char *msg_again              = "[00] Analog Gain:       ";
static char *msg_dgain              = "[00] Digital Gain:      ";
static char *msg_smode              = "[00] Shutter Mode:      ";
static char *msg_tmode              = "[00] Trigger Mode:      ";
static char *msg_bmode              = "[00] Binning Mode:      ";

static char *msg_psel               = "[00] Test Pattern:      ";
static char *msg_gain               = "[00] Gain Calib Mode:   ";
static char *msg_offset             = "[00] Offset Calib Mode: ";
static char *msg_defect             = "[00] Defect Calib Mode: ";

static char *msg_two_lines          = "=============================================================";
static char *msg_help               = "  All of Commands ";
static char *msg_help_ipmode        = "  All of Discovery Mode ";
static char *msg_help_cddr          = "  All of Accessible DDR3 Map ";
static char *msg_help_rflash        = "  All of Accessible Flash Memory Map ";
static char *msg_help_erase         = "  All of Erase Mode";
static char *msg_detector_state     = "  Detector State ";
static char *msg_detector_config    = "  Detector Configuration ";

// TI_ROIC
//  static char *msg_droic              = "  Descriptions of ROIC Register ";
static char *msg_roic               = "  ROIC Register Setting ";
static char *msg_tft                = "  TFT Timing ";

u8 DEFAULT_NAME[32] = "None";
u8 USERSET_NAME[MAX_USERSET][32] = {"None", };
u8 RUNNING_TIME[16]  = "00:00:00";
char DEBUG_MSG[128];

void disp_err(u16 err_code) {
    if(err_code == CMD_OK) { func_printf("\r\nCMD>");   return; }

    func_printf("Access Rule Violation\r\n");

    switch (err_code) {
        case CMD_ERR1   :   func_printf("ERR1: Access Authority Error\r\n");                        break;
        case CMD_ERR2   :   func_printf("ERR2: Command Name Error\r\n");                            break;
        case CMD_ERR3   :   func_printf("ERR3: Number of Parameter Error\r\n");                     break;
        case CMD_ERR4   :   func_printf("ERR4: Parameter Value is Out of Range\r\n");               break;
        case CMD_ERR5   :   func_printf("ERR5: Can't Change in Image Acquisition\r\n");             break;
        case CMD_ERR6   :   func_printf("ERR6: Can't Change in Trigger Mode\r\n");                  break;
        case CMD_ERR7   :   func_printf("ERR7: NUC Parameter ACQ Process must be preceded\r\n");    break;
        case CMD_ERR8   :   func_printf("ERR8: Parameter Value is Only Unsigned Integer\r\n");      break;
        case CMD_ERR9   :   func_printf("ERR9: There is no Flash Data\r\n");                        break;
        case CMD_ERR10  :   func_printf("ERR10: There is no External Trigger\r\n");                 break;
        case CMD_ERR11  :   func_printf("ERR11: Resolution is out of Range\r\n");                   break;
        case CMD_ERR12  :   func_printf("ERR12: TFT is not operating currently\r\n");               break;
        case CMD_ERR13  :   func_printf("ERR13: Calibration Data is already loaded\r\n");           break;
    //  case CMD_ERR14  :   func_printf("ERR14: There is no Calibration Data\r\n");                 break;
        case CMD_ERR15  :   func_printf("ERR15: Can't Change in Rolling Shutter Mode\r\n");         break;
        case CMD_ERR16  :   func_printf("ERR16: There is no Reference Image\r\n");                  break;
        case CMD_ERR17  :   func_printf("ERR17: The Unit of Value is not Correct\r\n");             break;
        case CMD_ERR18  :   func_printf("ERR18: Time Value Error. (Refer to TFT Sequence)\r\n");    break;
        case CMD_ERR19  :   func_printf("ERR19: Invalid Defect Point (Can't be Added)\r\n");        break;
        case CMD_ERR20  :   func_printf("ERR20: Invalid Defect Point (Can't be Removed)\r\n");      break;
    }
    func_printf("\r\nCMD>");
}

void disp_cmd_h(void) {
    u32 i;
    u32 before = 0;

    sys_state.only_comment = 1;

    func_printf("%s\r\n", msg_two_lines);
    func_printf("%s", msg_help);        disp_cmd_auth();
    func_printf("%s\r\n", msg_two_lines);

    for (i = 0; i < MAX_CMD_NUM; i++) {
        if(CMD_MAT[i].access <= func_access_level) {
            if(before != CMD_MAT[i].access) func_printf("\r\n");
            func_printf("%s\t:  ", CMD_MAT[i].cmd);
            func_printf("%s\r\n", CMD_MAT[i].comment);
        }
        before = CMD_MAT[i].access;
    }

    sys_state.only_comment = 0;
}

void disp_cmd_auth(void) {
    if(sys_state.only_comment) {
        switch (func_access_level) {
            case 0  : func_printf("[USER Mode]\r\n");       break;
            case 1  : func_printf("[ENGINEER Mode]\r\n");   break;
            case 2  : func_printf("[SECRET Mode]\r\n");     break;
        }
    }
    else {
        switch (func_access_level) {
            case 0  : func_printf("0 [USER Mode]\r\n");     break;
            case 1  : func_printf("1 [ENGINEER Mode]\r\n"); break;
            case 2  : func_printf("2 [SECRET Mode]\r\n");   break;
        }
    }
}

void disp_cmd_stat(void) {
    sys_state.only_comment = 1;

    gige_print_header();
//  func_printf("%s", msg_ipmode);      disp_cmd_ipmode();  // IP Mode :
    print_speed(msg_gev_speed);
    print_setup();                                          // Other IP Config Data :
    func_printf("\r\n");                                        //
    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("%s\r\n", msg_detector_state);              // Detector State :
    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("%s", msg_tser);            disp_cmd_tser();    // TFT Serial :
    func_printf("%s", msg_pser);            disp_cmd_pser();    // PANEL Serial :
    func_printf("%s", msg_fver);            disp_cmd_fver();    // FPGA Version :
    func_printf("%s", msg_dver);            disp_cmd_dver();    // FW Version :
    func_printf("\r\n");                                        //
    func_printf("%s", msg_bwidth);      disp_cmd_bwidth();  // GEV Bandwidth:
    func_printf("%s", msg_rsnd);            disp_cmd_rsnd();    // Resending Packet:
    func_printf("%s", msg_rtime);       disp_cmd_rtime();   // Running Time :
    func_printf("%s", msg_rtemp);       execute_cmd_rtemp();
                                        disp_cmd_rtemp();   // Temperature :
    func_printf("\r\n");                                        //
    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("%s\r\n", msg_detector_config);             // Detector Configuration :
    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("%s", msg_us);          disp_cmd_us();      // Preset Table :
    func_printf("%s", msg_usname);      disp_cmd_usname();  // Descriptions :
    func_printf("\r\n");                                        //
    func_printf("%s", msg_roi);         disp_cmd_roi();     // Resolution :
    func_printf("%s", msg_frate);       disp_cmd_frate();   // Frame Rate :
    func_printf("%s", msg_ewt);         disp_cmd_ewt();     // Exposure Time :
    // TI_ROIC  // dskim
    func_printf("%s", msg_again);       disp_roic_ifs();    // Analog Gain :
    func_printf("%s", msg_dgain);       disp_cmd_dgain();   // Digital Gain :
    func_printf("%s", msg_smode);       disp_cmd_smode();   // Shutter Mode :
    func_printf("%s", msg_tmode);       disp_cmd_tmode();   // Trigger Mode :
    func_printf("%s", msg_bmode);       disp_cmd_bmode();   // Binning Mode :
    func_printf("\r\n");                                        //
    func_printf("%s", msg_psel);            disp_cmd_psel();    // Test Pattern :
    func_printf("%s", msg_gain);            disp_cmd_gain();    // GAIN Calibration :
    func_printf("%s", msg_offset);      disp_cmd_offset();  // OFFSET Calibration :
    func_printf("%s", msg_defect);      disp_cmd_defect();  // DOT Calibration :
    func_printf("%s\r\n", msg_two_lines);                   // ====

    sys_state.only_comment = 0;
}

void disp_cmd_ipmode(void) {
    u8 data = eeprom_read_byte(EEPROM_ADDR_IPMODE);

    if(sys_state.only_comment) {
        switch (data) {
            case 1: func_printf("1 [Static IP]\r\n");           break;
            case 2: func_printf("2 [DHCP]\r\n");                break;
            case 3: func_printf("3 [Static IP->DHCP]\r\n");     break;
            case 4: func_printf("4 [LLA]\r\n");                 break;
            case 5: func_printf("5 [Static IP->LLA]\r\n");      break;
            case 6: func_printf("6 [DHCP->LLA]\r\n");           break;
            case 7: func_printf("7 [Static IP->DHCP->LLA]\r\n");break;
        }
    }
    else {
        func_printf("%s\r\n", msg_two_lines);
        func_printf("%s\r\n", msg_help_ipmode);
        func_printf("%s\r\n", msg_two_lines);
        func_printf("1 [Static IP]\r\n");
        func_printf("2 [DHCP]\r\n");
        func_printf("3 [Static IP->DHCP]\r\n");
        func_printf("4 [LLA]\r\n");
        func_printf("5 [Static IP->LLA]\r\n");
        func_printf("6 [DHCP->LLA]\r\n");
        func_printf("7 [Static IP->DHCP->LLA]\r\n");
        func_printf("%s\r\n", msg_two_lines);
        func_printf("\r\n");

        func_printf("Current Value = %d\r\n", data);
    }
}

void disp_cmd_psel(void) {
    int sel = func_test_pattern; //# 230613 
    switch (sel) {
        case  0 : func_printf(" 0 [Test pattern OFF]\r\n");              if(sel !=0)break; 
        case  1 : func_printf(" 1 [Horizontal RAMP with CFPN]\r\n");     if(sel !=0)break;
        case  2 : func_printf(" 2 [Dark with CFPN]\r\n");                if(sel !=0)break;
        case  3 : func_printf(" 3 [Bright with CFPN]\r\n");              if(sel !=0)break;
        case  4 : func_printf(" 4 [Horizontal RAMP]\r\n");               if(sel !=0)break;
        case  5 : func_printf(" 5 [Horizontal RAMP, Shift L to R]\r\n"); if(sel !=0)break;
        case  6 : func_printf(" 6 [Vertical RAMP]\r\n");                 if(sel !=0)break;
        case  7 : func_printf(" 7 [Vertical RAMP, Shift U to D]\r\n");   if(sel !=0)break;
        case  8 : func_printf(" 8 [Horizontal + Vertical RAMP]\r\n");    if(sel !=0)break;
        case  9 : func_printf(" 9 [Horizontal RAMP with CFPN]\r\n");     if(sel !=0)break;
        case 10 : func_printf("10 [4000 with CFPN]\r\n");                if(sel !=0)break;
        case 11 : func_printf("11 [8000 with CFPN]\r\n");                if(sel !=0)break;
        case 12 : func_printf("12 [20000 with CFPN]\r\n");               if(sel !=0)break;
        case 13 : func_printf("13 [30000 with CFPN]\r\n");               if(sel !=0)break;
        case 14 : func_printf("14 [45000 with CFPN]\r\n");               if(sel !=0)break;
        case 15 : func_printf("15 [Custom flat value]\r\n");             if(sel !=0)break;
        case 16 : func_printf("16 [TI roic test pattern]\r\n");          if(sel !=0)break;
        default : func_printf("custom value TP ex) psel 15 (value) // psel 15 30000\r\n");
        		  func_printf("auto gain cal ex) psel (num) (dummy) // psel 4 0\r\n");
    }
}

void disp_cmd_gmode(void) {
    if(func_frame_num == 0)
        func_printf("Use Frame : %d - [Infinite]\r\n", func_frame_val);
    else
        func_printf("Use Frame : %d - %d\r\n", func_frame_val, func_frame_num + func_frame_val - 1);
}

void disp_cmd_roi(void) {
    func_printf("X:%04d Y:%04d W:%04d H:%04d\r\n", func_offsetx, func_offsety, func_width, func_height);
}

void disp_cmd_bmode(void) {
    switch (func_binning_mode) {
        case 0: func_printf("0 [Normal]\r\n");                      break;
        case 1: func_printf("1 [2x2 Analog Binning]\r\n");          break;
        case 2: func_printf("2 [2x2 Digital Binning (SUM)]\r\n");   break;
        case 3: func_printf("3 [2x2 Digital Binning (AVG)]\r\n");   break;
        case 4: func_printf("4 [3x3 Digital Binning (SUM)]\r\n");   break;
        case 5: func_printf("5 [3x3 Digital Binning (AVG)]\r\n");   break;
        case 6: func_printf("6 [4x4 Digital Binning (SUM)]\r\n");   break;
        case 7: func_printf("7 [4x4 Digital Binning (AVG)]\r\n");   break;
    }
}

void disp_cmd_tmode(void) {
    switch (func_trig_mode) {
        case 0: func_printf("0 [Free Running Mode]\r\n");           break;
        case 1: func_printf("1 [External Trigger Mode 1]\r\n");     break; // Mode 0 -> 1 expression change
        case 2: func_printf("2 [External Trigger Mode 2]\r\n");     break; // Mode 1 -> 2
    }
}

void disp_cmd_tdly(void) {
    if(sys_state.only_comment)  func_printf("%d us", func_trig_delay);
    else                        func_printf("Trigger Delay = %d us", func_trig_delay);
}

void disp_cmd_smode(void) {
    switch (func_shutter_mode) {
        case 0: func_printf("0 [Rolling Shutter]\r\n");     break;
        case 1: func_printf("1 [Global Shutter]\r\n");      break;
    }
}

void disp_cmd_emode(void) {
    switch (func_exp_mode) {
        case 0: func_printf("0 [Standard Frame Rate]\r\n");     break;
        case 1: func_printf("1 [Standard Exposure Time]\r\n");  break;
    }
}


void disp_cmd_pmode(void) {
    switch (func_sync_source) {
        case 0: func_printf("0 [SYNC from TFT]\r\n");       break;
        case 1: func_printf("1 [SYNC from FPGA]\r\n");      break;
    }
}

void disp_cmd_pdead(void) {
    func_printf("LDEAD = %d\r\n", func_intsync_ldead);
}

void disp_cmd_grab(void) {
    switch (func_grab_en) {
        case 0: func_printf("0 [TFT Operation Disable]\r\n");   break;
        case 1: func_printf("1 [TFT Operation Enable]\r\n");    break;
    }
}

void disp_cmd_frate(void) {
//  if(sys_state.only_comment) {
//      float_printf(func_frate, 2); func_printf(" fps\r\n");
//  }
//  else {
//      func_printf("Frame Rate = "); float_printf(func_frate, 2); func_printf(" fps\r\n");
//  }
    func_printf("MAX Frame Rate = "); float_printf(MAX_FRATE     , 2); func_printf(" fps\r\n");
    func_printf("Frame Rate     = "); float_printf(func_frate    , 2); func_printf(" fps\r\n");
    func_printf("Frame Rate max = "); float_printf(func_frate_max, 2); func_printf(" fps\r\n");
    func_printf("Frame Rate min = "); float_printf(func_frate_min, 2); func_printf(" fps\r\n");

    func_printf("func_roll_frate   ="); float_printf(func_roll_frate  , 2); func_printf(" fps\r\n");
    func_printf("func_ext0_frate   ="); float_printf(func_ext0_frate  , 2); func_printf(" fps\r\n");
    func_printf("func_ext1_frate   ="); float_printf(func_ext1_frate  , 2); func_printf(" fps\r\n");
    func_printf("func_ext2_frate   ="); float_printf(func_ext2_frate  , 2); func_printf(" fps\r\n");
    func_printf("func_static_frate ="); float_printf(func_static_frate, 2); func_printf(" fps\r\n");
}

void disp_cmd_ewt(void) {
//  if(sys_state.only_comment)
//      func_printf("%d us \r\n", func_shutter_mode == 0 ? func_rewt : func_gewt);
//  else
//      func_printf("EWT = %d us\r\n", func_shutter_mode == 0 ? func_rewt : func_gewt);
    func_printf("func_gewt= %d us \r\n", func_gewt);
    func_printf("func_gewt_max= %d us \r\n", func_gewt_max);
    func_printf("func_gewt_min= %d us \r\n", func_gewt_min);

    func_printf("func_roll_ewt  = %d us \r\n", func_roll_ewt  );
    func_printf("func_ext0_ewt  = %d us \r\n", func_ext0_ewt  );
    func_printf("func_ext1_ewt  = %d us \r\n", func_ext1_ewt  );
    func_printf("func_ext2_ewt  = %d us \r\n", func_ext2_ewt  );
    func_printf("func_static_ewt= %d us \r\n", func_static_ewt);
}

void disp_cmd_gain(void) {
    switch (func_gain_cal) {
        case 0: func_printf("0 [OFF]\r\n");     break;
        case 1: func_printf("1 [ON]\r\n");      break;
    }
}

void disp_cmd_offset(void) {
    switch (func_offset_cal) {
        case 0: func_printf("0 [OFF]\r\n");     break;
        case 1: func_printf("1 [ON]\r\n");      break;
    }
}

void disp_cmd_defect(void) {
    switch (func_defect_cal) {
        case 0: func_printf("0 [OFF]\r\n");     break;
        case 1: func_printf("1 [ON]\r\n");      break;
    }
}

void disp_cmd_dmap(void) {
    switch (func_defect_map) {
        case 0: func_printf("0 [OFF]\r\n");     break;
        case 1: func_printf("1 [ON]\r\n");      break;
    }
}

void disp_cmd_ghost(void) {
    func_printf("Ghost Reduction Time : %d ms\r\n", func_erase_time);
}

void disp_cmd_dgain(void) {
    u32 data1, data2;

    data1 = func_dgain / 100;
    data2 = func_dgain % 100;

    if(sys_state.only_comment)  func_printf("x%d.%02d [%d]\r\n", data1, data2, func_dgain);
    else                        func_printf("Digital Gain = x%d.%02d [%d]\r\n", data1, data2, func_dgain);
}

void disp_cmd_iproc(void) {
    switch (func_img_proc) {
        case 0: func_printf("0 [None]\r\n");            break;
        case 1: func_printf("1 [Original]\r\n");        break;
        case 2: func_printf("2 [Embossing]\r\n");       break;
        case 3: func_printf("3 [Sharpening]\r\n");      break;
        case 4: func_printf("4 [Blurring]\r\n");        break;
    }
}

void disp_cmd_us(void) {
    if(sys_state.only_comment)
        func_printf("%d\r\n", func_table);
    else
        func_printf("User Setting Table = %d\r\n", func_table);
}

void disp_cmd_usname(void) {
    func_printf("%s\r\n", USERSET_NAME[func_table]);
}

void disp_cmd_tser(void) {
    if(sys_state.only_comment)
        func_printf("%s\r\n", TFT_SERIAL);
    else
        func_printf("TFT SERIAL = %s\r\n", TFT_SERIAL);
}

void disp_cmd_pser(void) {
    if(sys_state.only_comment)
        func_printf("%s\r\n", PANEL_SERIAL);
    else
        func_printf("PANEL SERIAL = %s\r\n", PANEL_SERIAL);
}

void disp_cmd_fver(void) {
    if(sys_state.only_comment)
        func_printf("%s\r\n", FPGA_VER);
    else
        func_printf("FPGA Version = %s\r\n", FPGA_VER);
        func_printf("\tFPGA date  = %s\r\n", FPGA_DATE);
}

void disp_cmd_fmodel(void) {
    if(sys_state.only_comment)
        func_printf("%s\r\n", FPGA_MODEL);
    else
        func_printf("\tFPGA Model = %s\r\n", FPGA_MODEL);
}

void disp_cmd_dver(void) {
    if(sys_state.only_comment)
        func_printf("%s\r\n", GIGE_DVER);
    else
    {
        func_printf("SET Version = %s\r\n", GIGE_DVER);
		func_printf("\tFW Vers = %s\r\n", FW_VER);
        func_printf("\tFW DATE = %s\r\n", FW_DATE);
    }
}

void disp_cmd_hwver(void) {
    if(sys_state.only_comment)
        func_printf("HW Version = %s\r\n", HW_VER); //# hw ver
    else
    {
        func_printf("HW Version = %s\r\n", HW_VER); //# hw ver
//                             0123456789ab
//      HW_VER    [16]      = "hw0.00.01_01";
        func_printf("\tTFT by  =");
        if     (HW_VER[4]=='0') func_printf("LG\r\n");
        else if(HW_VER[4]=='1') func_printf("INC\r\n");
        else                    func_printf("unknown\r\n");
        func_printf("\tTFT type=");
        if     (HW_VER[5]=='0') func_printf("IGZO\r\n");
        else if(HW_VER[5]=='1') func_printf("a-Si\r\n");
        else                    func_printf("unknown\r\n");
        func_printf("\tROIC by =");
        if     (HW_VER[7]=='0') func_printf("TI\r\n");
        else if(HW_VER[7]=='1') func_printf("ADI\r\n");
        else if(HW_VER[7]=='2') func_printf("TI dclk\r\n");
        else                    func_printf("unknown\r\n");
        func_printf("\tPitch   =");
        if     (HW_VER[8]=='0') func_printf("76um\r\n");
        else if(HW_VER[8]=='1') func_printf("100um\r\n");
        else if(HW_VER[8]=='2') func_printf("140um\r\n");
        else                    func_printf("unknown\r\n");
        func_printf("\tGate by =");
        if     (HW_VER[10]=='0') func_printf("Raydium\r\n");
        else if(HW_VER[10]=='1') func_printf("Novatech\r\n");
        else if(HW_VER[10]=='2') func_printf("Himax\r\n");
        else                     func_printf("unknown\r\n");
        func_printf("\tGate Ch =");
        if     (HW_VER[11]=='0') func_printf("256\r\n");
        else if(HW_VER[11]=='1') func_printf("512\r\n");
        else if(HW_VER[11]=='2') func_printf("450\r\n");
        else                     func_printf("unknown\r\n");
    }
}

void disp_cmd_fmax(void) {
    func_printf("Frame Rate Range = ");     float_printf(func_frate_min, 2);
    func_printf(" - ");                     float_printf(func_frate_max, 2);
    func_printf(" fps\r\n");
}

void disp_cmd_emax(void) {
//  if(func_shutter_mode == 0)
//      func_printf("EWT Range = %d us [Fixed]\r\n", func_rewt);
//  else
        func_printf("[EWT Range = %d - %d us] EWT = %d us\r\n", func_gewt_min, func_gewt_max, func_gewt);
}

void disp_cmd_rtime(void) {
    u32 runtime_msb, runtime_lsb;
    u32 runtime;
    u32 runtime_s = 0;
    u32 runtime_m = 0;
    u32 runtime_h = 0;

    char arr[16] = {0};
    u32 i = 0;

    float tick = 0.16777216;

    runtime_msb = AREG(0x43E0C020);
    runtime_lsb = AREG(0x43E0C024);

    runtime = ((runtime_msb << 8) & 0xFFFFFF00) | ((runtime_lsb >> 24) & 0x000000FF);

    runtime_s = (u32)(runtime * tick);
    runtime_m = (runtime_s / 60);
    runtime_h = (runtime_m / 60);

    if(sys_state.only_comment)  func_printf("%d:%02d:%02d\r\n", (runtime_h % 24), (runtime_m % 60), (runtime_s % 60));
    else                        func_printf("Runtime = %d:%02d:%02d\r\n", (runtime_h % 24), (runtime_m % 60), (runtime_s % 60));

    sprintf(arr, "%d:%2d:%2d\n", (int)(runtime_h % 24), (int)(runtime_m % 60), (int)(runtime_s % 60));
    for(i = 0; i < 16; i++)     RUNNING_TIME[i] = (u8)arr[i];
}

void disp_cmd_rtemp(void) {
    u32 i;

    float ds1731_sum = 0;
    float ds1731_avg = 0;
    // TI_ROIC
//  float roic_sum = 0;
//  float roic_avg = 0;

    for (i = 0; i < DS1731_NUM; i++)        ds1731_sum += func_ds1731_temp[i];
    ds1731_avg = ds1731_sum / DS1731_NUM;

    // TI_ROIC
//  for (i = 0; i < ROIC_NUM; i++)          roic_sum += func_roic_temp[i];
//  roic_avg = roic_sum / ROIC_NUM;

    if(sys_state.only_comment) {
        float_printf(ds1731_avg, 1);        func_printf(" C\t");
        // TI_ROIC
    //  float_printf(roic_avg, 1);          func_printf(" C\t");
        float_printf(func_fpga_temp, 1);    func_printf(" C\t");
        func_printf("%d.0 C\r\n", func_phy_temp);
    }
    else {
        for (i = 0; i < DS1731_NUM; i++) {
            func_printf("BD%2d   = ", i);   float_printf(func_ds1731_temp[i], 1);   func_printf(" C\r\n");
        }
        // TI_ROIC
//      for (i = 0; i < ROIC_NUM; i++) {
//          func_printf("ROIC%2d = ", i);   float_printf(func_roic_temp[i], 1);     func_printf(" C\r\n");
//      }
        	func_printf("ROIC   = ");		float_printf(func_roic_temp, 1);	func_printf(" C\r\n");
            func_printf("FPGA   = ");       float_printf(func_fpga_temp, 1);    func_printf(" C\r\n");
            func_printf("PHY    = %d.0 C\r\n", func_phy_temp);
    }
}


void disp_cmd_flash(void) {
    func_printf("%s\r\n", msg_two_lines);
    func_printf("%s\r\n", msg_help_rflash);
    func_printf("%s\r\n", msg_two_lines);
    func_printf("0x%06x - 0x%06x: Bitstream\r\n", FLASH_BIT_BASEADDR, FLASH_BIT_BASEADDR + FLASH_BIT_LEN-1);
    func_printf("0x%06x - 0x%06x: Allocation Table\r\n", FLASH_ALLOC_BASEADDR, FLASH_ALLOC_BASEADDR + FLASH_ALLOC_LEN-1);
    func_printf("0x%06x - 0x%06x: XML\r\n", FLASH_XML_BASEADDR, FLASH_XML_BASEADDR + FLASH_XML_LEN-1);
    func_printf("0x%06x - 0x%06x: Application\r\n", FLASH_APP_BASEADDR, FLASH_APP_BASEADDR + FLASH_APP_LEN-1);
    func_printf("0x%06x - 0x%06x: User Preset Data\r\n", FLASH_USER_BASEADDR, FLASH_USER_BASEADDR + FLASH_USER_LEN-1);
    func_printf("0x%06x - 0x%06x: Detector Serial Number\r\n", FLASH_DETECTOR_SN_BASEADDR, FLASH_DETECTOR_SN_BASEADDR + FLASH_DETECTOR_SN_LEN-1);
    func_printf("0x%06x - 0x%06x: Detector Info\r\n", FLASH_INFO_BASEADDR, FLASH_INFO_BASEADDR + FLASH_INFO_LEN-1);
    func_printf("0x%06x - 0x%06x: Defect Data\r\n", FLASH_DEFECT_BASEADDR, FLASH_DEFECT_BASEADDR + FLASH_DEFECT_LEN-1);
    func_printf("0x%06x - 0x%06x: NUC Data\r\n", FLASH_NUC_BASEADDR, FLASH_NUC_BASEADDR + FLASH_NUC_LEN-1);
    func_printf("0x%06x - 0x%06x: Bitstream 2nd\r\n", FLASH_BIT2ND_BASEADDR, FLASH_BIT2ND_BASEADDR + FLASH_BIT_LEN-1);
    func_printf("0x%06x - 0x%06x: Bitstream 3rd\r\n", FLASH_BIT3RD_BASEADDR, FLASH_BIT3RD_BASEADDR + FLASH_BIT_LEN-1);
    func_printf("0x%06x - 0x%06x: Application 2nd\r\n", FLASH_APP2ND_BASEADDR, FLASH_APP2ND_BASEADDR + FLASH_APP_LEN-1);
    func_printf("0x%06x - 0x%06x: Allocation Table\r\n", FLASH_AL2ND_BASEADDR, FLASH_AL2ND_BASEADDR + FLASH_ALLOC_LEN-1);
    func_printf("%s\r\n", msg_two_lines);
    func_printf("\r\n");
}

void disp_cmd_eeprom(void) {
    func_printf("0x%04x - 0x%04x: EEPROM\r\n", EEPROM_BASEADDR, EEPROM_BASEADDR + EEPROM_SIZE-1);
}

void disp_cmd_erase(void) {
    func_printf("%s\r\n", msg_two_lines);
    func_printf("%s\r\n", msg_help_erase);
    func_printf("%s\r\n", msg_two_lines);
    func_printf("0 [Bitstream]\r\n");
    func_printf("1 [Allocation Table]\r\n");
    func_printf("2 [XML]\r\n");
    func_printf("3 [Application]\r\n");
    func_printf("4 [User Preset]\r\n");
    func_printf("5 [Detector Info]\r\n");
    func_printf("6 [Defect Data]\r\n");
//  func_printf("7 [NUC Data]\r\n");
    func_printf("7 [NUC Information]\r\n");
    func_printf("8 [All of Flash Memory]\r\n");
    func_printf("9 [All of EEPROM]\r\n");
    func_printf("10 [NUC Data in DDR3]\r\n");
    func_printf("11 [All of Flash Memory(4~7)]\r\n");
    func_printf("20 [2nd Bitstream]\r\n"); //# 220915mbh
    func_printf("21 [3rd Bitstream]\r\n"); //# 220919mbh
    func_printf("22 [2nd Application]\r\n"); //# 220915mbh
    func_printf("23 [2nd Allocation Table]\r\n"); //# 220922mbh
    func_printf("%s\r\n", msg_two_lines);
    func_printf("\r\n");
}

void disp_cmd_cddr(void) {
    func_printf("%s\r\n", msg_two_lines);
    func_printf("%s\r\n", msg_help_cddr);
    func_printf("%s\r\n", msg_two_lines);
    func_printf("0 [None]\r\n");
    func_printf("1 [Ref Image 0]\r\n");
    func_printf("2 [Ref Image 1]\r\n");
    func_printf("3 [Ref Image 2]\r\n");
    func_printf("4 [Ref Image 3]\r\n");
    func_printf("5 [Ref Image 4]\r\n");
    func_printf("6 [Ref Image 5 d2 xray]\r\n");
    func_printf("7 [Calib Gain Data]\r\n");
    func_printf("8 [Calib Offset Data]\r\n");
//  func_printf("9 [Normal Data]\r\n");
    func_printf("9 [DEBUGGING]\r\n");
    func_printf("%s\r\n", msg_two_lines);
    func_printf("\r\n");

    func_printf("Current Value = %d\r\n", func_ddr_out);
}

void disp_cmd_wddr(void) {
    func_printf("0 [Normal Image]\r\n");
    func_printf("1 [Ref Image 0]\r\n");
    func_printf("2 [Ref Image 1]\r\n");
    func_printf("3 [Ref Image 2]\r\n");
    func_printf("4 [Ref Image 3]\r\n");
    func_printf("5 [Ref Image 4]\r\n");
}


void disp_cmd_wdot(u32 pointx, u32 pointy, u32 erase) {
    if(erase)
        func_printf("Erase Defect [%d, %d]\r\n", pointx, pointy);
    else
        func_printf("Add Defect [%d, %d]\r\n", pointx, pointy);
}

void disp_cmd_wrdot(u32 row, u32 erase) {
    if(erase)
        func_printf("Erase Row Defect [%d]\r\n", row);
    else
        func_printf("Add Row Defect [%d]\r\n", row);
}

void disp_cmd_wcdot(u32 col, u32 erase) {
    if(erase)
        func_printf("Erase Column Defect [%d]\r\n", col);
    else
        func_printf("Add Column Defect [%d]\r\n", col);
}

void disp_cmd_rdot(void) {
//  func_printf("The Number of Defect = %d (Auto = %d, Manual = %d)\r\n", func_defect_cnt + func_defect_cnt2, func_defect_cnt, func_defect_cnt2);
//  func_printf("The Number of Line Defect = %d (Row = %d, Column = %d)\r\n", func_rdefect_cnt + func_cdefect_cnt, func_rdefect_cnt, func_cdefect_cnt);
    func_printf("Total Defect = %d (Auto = %d, Manual = %d, Factory = %d)\r\n", func_defect_cnt + func_defect_cnt2 + func_defect_cnt3, func_defect_cnt, func_defect_cnt2, func_defect_cnt3);
    func_printf("Total Line Defect = %d (M.Row = %d, M.Column = %d) (F.Row = %d, F.Column = %d)\r\n", func_rdefect_cnt + func_cdefect_cnt + func_rdefect_cnt3 + func_cdefect_cnt3, func_rdefect_cnt, func_cdefect_cnt, func_rdefect_cnt3, func_cdefect_cnt3);
}

// TI_ROIC
//void disp_cmd_hroic(void) {
//  u32 i;
//  u32 size;
//
//  func_printf("%s\r\n", msg_two_lines);               // ====
//  func_printf("%s\r\n", msg_droic);                   // Descriptions of ROIC Register
//  func_printf("%s\r\n", msg_two_lines);               // ====
//
//  for (i = 0; i < ROIC_REG_NUM; i++) {
//      func_printf("%s\t", ROIC_MAT[i].name);
//      size = strlen((const char*)ROIC_MAT[i].name);
//      if(size < 8)    func_printf("\t: ");
//      else            func_printf(": ");
//      func_printf("%s\r\n", ROIC_MAT[i].comment);
//  }
//  func_printf("%s\r\n", msg_two_lines);
//}

void disp_cmd_tstat(void) {
    // TI_ROIC
//  u32 i;
//  u32 size;
//  u32 count = 0;

    sys_state.only_comment = 1;

    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("%s\r\n", msg_roic);                            // ROIC Register Setting
    func_printf("%s\r\n", msg_two_lines);                   // ====

    // TI_ROIC
//  for (i = 0; i < ROIC_REG_NUM; i++) {
//      func_printf("%s\t", ROIC_MAT[i].name);
//      size = strlen((const char*)ROIC_MAT[i].name);
//      if(size < 8)    func_printf("\t: ");
//      else            func_printf(": ");
//      func_printf("%d", ROIC_MAT[i].data);
//      if(count == 1)  { count = 0; func_printf("\r\n"); }
//      else            { count = 1; func_printf("\t");   }
//  }
//  func_printf("\r\n");                                        //
//  func_printf("\r\n%s\r\n", msg_two_lines);               // ====
//  func_printf("  ROIC Key Specification\r\n");                // ROIC Key Specification
//  func_printf("%s\r\n", msg_two_lines);                   // ====
//  func_printf("PWR Mode        : ");  disp_roic_pwr();
//  func_printf("LPF             : ");  disp_roic_lpf();
    func_printf("IFS             : ");  disp_roic_ifs();
//  func_printf("REFDAC          : ");  disp_roic_refdac();
//  func_printf("\r\n");
//  func_printf("\r\n");                                        //
    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("%s\r\n", msg_tft);                         // TFT Timing
    func_printf("%s\r\n", msg_two_lines);                   // ====
    func_printf("TFT SEQUENCE    : ");  disp_cmd_tseq();
    func_printf("CYCLE RESET     : ");  disp_cmd_crmode();
    func_printf("START RESET     : ");  disp_cmd_srmode();
    func_printf("RESET CYCLE     : ");  disp_cmd_rcycle();
    func_printf("AFE TIME        : ");  disp_cmd_afe();
    func_printf("BURST TIME      : ");  disp_cmd_burst();
    func_printf("\r\n");
    func_printf("ROIC INTRST     : ");  disp_cmd_intrst();
    // TI_ROIC
    func_printf("ROIC FA1        : ");  disp_cmd_fa1();
    func_printf("ROIC FA2        : ");  disp_cmd_fa2();
    func_printf("ROIC CDS1       : ");  disp_cmd_cds1();
    func_printf("ROIC CDS2       : ");  disp_cmd_cds2();
    // TI_ROIC
//  func_printf("ROIC DEAD       : ");  disp_cmd_dead();
//  func_printf("ROIC MUTE       : ");  disp_cmd_mute();
    func_printf("GATE OE         : ");  disp_cmd_oe();
    func_printf("GATE XON        : ");  disp_cmd_xon();
    func_printf("GATE XON_FLK    : ");  disp_cmd_xonflk();
    func_printf("GATE FLK        : ");  disp_cmd_flk();

    func_printf("\r\n%s\r\n", msg_two_lines);

    sys_state.only_comment = 0;
}

void disp_cmd_mac(void) {
    u32 addr_h = XREG(XGIGE_ADDR_MAC_H);
    u32 addr_l = XREG(XGIGE_ADDR_MAC_L);
    u8 arr[6] = {0, };

    arr[5] = (addr_h & 0xFF00) >> 8;
    arr[4] = (addr_h & 0x00FF) >> 0;
    arr[3] = (addr_l & 0xFF000000) >> 24;
    arr[2] = (addr_l & 0x00FF0000) >> 16;
    arr[1] = (addr_l & 0x0000FF00) >> 8;
    arr[0] = (addr_l & 0x000000FF) >> 0;

    func_printf("MAC Address : %02x:%02x:%02x:%02x:%02x:%02x\r\n", arr[5], arr[4], arr[3], arr[2], arr[1], arr[0]);
}

void disp_cmd_ip(void) {
    u32 addr = XREG(XGIGE_ADDR_IP);
    u8 arr[4] = {0, };

    arr[3] = (addr & 0xFF000000) >> 24;
    arr[2] = (addr & 0x00FF0000) >> 16;
    arr[1] = (addr & 0x0000FF00) >> 8;
    arr[0] = (addr & 0x000000FF) >> 0;

    func_printf("IP Address : %d.%d.%d.%d\r\n", arr[3], arr[2], arr[1], arr[0]);
}

void disp_cmd_smask(void) {
    u32 addr = eeprom_read_dword(EEPROM_ADDR_SUBNET);
    u8 arr[4] = {0, };

    arr[3] = (addr & 0xFF000000) >> 24;
    arr[2] = (addr & 0x00FF0000) >> 16;
    arr[1] = (addr & 0x0000FF00) >> 8;
    arr[0] = (addr & 0x000000FF) >> 0;

    func_printf("Subnet Mask : %d.%d.%d.%d\r\n", arr[3], arr[2], arr[1], arr[0]);
}

void disp_cmd_gate(void) {
    u32 addr = eeprom_read_dword(EEPROM_ADDR_GATEWAY);
    u8 arr[4] = {0, };

    arr[3] = (addr & 0xFF000000) >> 24;
    arr[2] = (addr & 0x00FF0000) >> 16;
    arr[1] = (addr & 0x0000FF00) >> 8;
    arr[0] = (addr & 0x000000FF) >> 0;

    func_printf("Default Gateway : %d.%d.%d.%d\r\n", arr[3], arr[2], arr[1], arr[0]);
}

void disp_cmd_bwidth(void) {
    float bwidth;
    float bwidth_per;
    u32 bwidth_max = 2500;      // Mbps
    u8 percent = '%';

    bwidth = (func_width * func_height * 16 * func_frate) / 1048576.0;
    bwidth_per = (bwidth / bwidth_max) * 100;

    float_printf(bwidth, 1);        func_printf(" Mbps [");
    float_printf(bwidth_per, 1);    func_printf("%c]\r\n", percent);
}

void disp_cmd_rsnd(void) {
    u32 resend_req = framebuf_rsnd_wr;
    u32 resend_ok = framebuf_rsnd_ok;
    u32 resend_nok = resend_req - resend_ok;
    float error = 0;
    u8 percent = '%';

    if(resend_req)
        error = (resend_nok / (float)resend_req) * 100;

    func_printf("%d [ERR ", resend_ok);
    float_printf(error, 1);
    func_printf("%c]\r\n", percent);
}

// TI_ROIC
//void disp_roic_pwr(void) {
//  u32 i;
//  u32 cnt = 0;
//
//  for(i = 0; i < ROIC_REG_NUM; i++)
//      if(rstrcmp((char*)ROIC_MAT[i].name, "PWR") == 0)
//          cnt = i;
//
//  switch (ROIC_MAT[cnt].data) {
//      case 0  : func_printf("0 [Low Power 3 Mode]\r\n");      break;
//      case 1  : func_printf("1 [Low Power 2 Mode]\r\n");      break;
//      case 2  : func_printf("2 [Low Power 1 Mode]\r\n");      break;
//      case 3  : func_printf("3 [Normal Mode]\r\n");           break;
//      case 11 : func_printf("11 [Fast Low Noise Mode]\r\n");  break;
//      case 12 : func_printf("12 [Fast Low Power Mode]\r\n");  break;
//  }
//}

// TI_ROIC
//void disp_roic_lpf(void) {
//  u32 i;
//  u32 cnt = 0;
//
//  for(i = 0; i < ROIC_REG_NUM; i++)
//      if(rstrcmp((char*)ROIC_MAT[i].name, "LPF") == 0)
//          cnt = i;
//
//  switch (ROIC_MAT[cnt].data) {
//      case 0  : func_printf("0 [1.00 us]\r\n");   break;
//      case 1  : func_printf("1 [1.25 us]\r\n");   break;
//      case 2  : func_printf("2 [1.50 us]\r\n");   break;
//      case 3  : func_printf("3 [2.00 us]\r\n");   break;
//      case 4  : func_printf("4 [2.50 us]\r\n");   break;
//      case 5  : func_printf("5 [3.00 us]\r\n");   break;
//      case 6  : func_printf("6 [4.00 us]\r\n");   break;
//      case 7  : func_printf("7 [6.00 us]\r\n");   break;
//  }
//}

// TI_ROIC
void disp_roic_ifs(void) {
    u32 i;
    u32 cnt = 0;
    u32 val1 = 0;
    u32 val2 = 0;
    float val;
	float cfb = 0;

//  INPUT_CHARGE_RANGE bits = 00001b 0.6 pC
//  INPUT_CHARGE_RANGE bits = 00010b 1.2 pC
//  INPUT_CHARGE_RANGE bits = 00100b 2.4 pC
//  INPUT_CHARGE_RANGE bits = 01000b 4.8 pC
//  INPUT_CHARGE_RANGE bits = 10000b 0.6 pC
//  INPUT_CHARGE_RANGE bits = 01100b 7.2 pC
//  INPUT_CHARGE_RANGE bits = 11111b 9.6 pC

//    for(i = 0; i <= ROIC_REG_NUM; i++)
//        if(rstrcmp((char*)ROIC_MAT[i].name, "IFS") == 0)
//        	cnt = i;

    //$ 260224
    if(AFE3256_series)	cnt = 1;
    else				cnt = 0;

    if(AFE3256_series){
    	u32 d = ROIC_MAT[cnt].data & 0x7F;

    	if(d & 0x40) cfb += 4.0;
    	if(d & 0x20) cfb += 2.0;
    	if(d & 0x10) cfb += 2.0;
    	if(d & 0x08) cfb += 1.0;
    	if(d & 0x04) cfb += 0.5;
    	if(d & 0x02) cfb += 0.25;
    	if(d & 0x01) cfb += 0.25;

    	val = cfb * 1.25;
    }
    else{
//  	val = (ROIC_MAT[cnt].data + 1) * 0.0625;
    	val1 = (ROIC_MAT[cnt].data & 0xF);
    	val2 = (ROIC_MAT[cnt].data & 0x10)>>4;
    	val = (val1 * 0.6) + (val2 * 0.3);
    }


    if(sys_state.only_comment)  { func_printf("%d [", ROIC_MAT[cnt].data); float_printf(val, 4), func_printf(" pC]\r\n"); }
    else{
    	if(AFE3256_series){
    		func_printf("SEL_CFB = %d [", func_ifs_index); float_printf(val, 4), func_printf(" ]pC\r\n");
    	}
    	else{
    		func_printf("IFS = %d [", ROIC_MAT[cnt].data); float_printf(val, 4), func_printf(" ]pC\r\n");
    	}
    }

    if(func_access_level == 2) {
        memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
        sprintf(DEBUG_MSG,"IFS = %d [%f]pC", ROIC_MAT[cnt].data, val);
		gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
    }
}


// TI_ROIC
//void disp_roic_refdac(void) {
//  u32 i;
//  u32 cnt = 0;
//  float val;
//
//  for(i = 0; i < ROIC_REG_NUM; i++)
//      if(rstrcmp((char*)ROIC_MAT[i].name, "REFDAC") == 0)
//          cnt = i;
//
//  val = 0.5 + (ROIC_MAT[cnt].data * 0.015625);
//  float_printf(val, 4), func_printf(" V\r\n");
//}

void disp_cmd_intrst(void)  { float_printf(func_roic_intrst, 2);    func_printf(" us\r\n"); }
void disp_cmd_cds1(void)    { float_printf(func_roic_cds1, 2);      func_printf(" us\r\n"); }
void disp_cmd_cds2(void)    { float_printf(func_roic_cds2, 2);      func_printf(" us\r\n"); }
void disp_cmd_fa1(void)     { float_printf(func_roic_fa1, 2);       func_printf(" us\r\n"); }
void disp_cmd_fa2(void)     { float_printf(func_roic_fa2, 2);       func_printf(" us\r\n"); }
// TI_ROIC
//void disp_cmd_fa(void)        { float_printf(func_roic_fa, 2);        func_printf(" us\r\n"); }
//void disp_cmd_dead(void)  { float_printf(func_roic_dead, 2);      func_printf(" us\r\n"); }
//void disp_cmd_mute(void)  { float_printf(func_roic_mute, 2);      func_printf(" us\r\n"); }
void disp_cmd_oe(void) {
    switch (func_tft_seq) {
        case 0 :    float_printf(func_gate_oe, 2);                  func_printf(" us\r\n");     break;
        case 1 :    float_printf(func_gate_oe, 2);                  func_printf(" us\r\n");     break;
        case 2 :    float_printf(func_gate_oe + func_roic_cds2, 2); func_printf(" us\r\n");     break;
        case 3 :    float_printf(line_time_us, 2);                  func_printf(" us\r\n");     break;
    }
}
void disp_cmd_xon(void)     { float_printf(func_gate_xon, 2);       func_printf(" us\r\n"); }
void disp_cmd_flk(void)     { float_printf(func_gate_flk, 2);       func_printf(" us\r\n"); }
void disp_cmd_xonflk(void)  { float_printf(func_gate_xonflk, 2);    func_printf(" us\r\n"); }
void disp_cmd_rcycle(void)  { float_printf(func_gate_rcycle, 2);    func_printf(" ms\r\n"); }
void disp_cmd_afe(void)     { float_printf(afe_time_us, 2);         func_printf(" us\r\n"); }
void disp_cmd_burst(void)   { float_printf(data_time_us, 2);        func_printf(" us\r\n"); }

void disp_cmd_crmode(void)  {
    switch (func_gate_crmode) {
        case 0: func_printf("0 [TOTAL RESET]\r\n");     break;
        case 1: func_printf("1 [SERIAL RESET]\r\n");    break;
    }
}
void disp_cmd_srmode(void)  {
    switch (func_gate_srmode) {
        case 0: func_printf("0 [TOTAL RESET], %d ea\r\n", func_gate_rnum);  break;
        case 1: func_printf("1 [SERIAL RESET], %d us\r\n", func_sexp_time); break;
    }
}
// TI_ROIC
//void disp_cmd_roicval(void) { for(int i = 0; i < 16; i++)             func_printf("%d = 0x%04x\r\n", i, func_roic_data[i]); }

void disp_cmd_tseq(void) {
    switch (func_tft_seq) {
        case 0 :    func_printf("0 [CDS1 > OE > CDS2]\r\n");            break;
        case 1 :    func_printf("1 [CDS1 > (OE+CDS2) > CDS2]\r\n");     break;
        case 2 :    func_printf("2 [CDS1 > OE > (OE+CDS2)]\r\n");       break;
        case 3 :    func_printf("3 [(OE+CDS1) > OE > (OE+CDS2)]\r\n");  break;
    }
}

void disp_cmd_timg(void) {
    func_printf("0 [Reference 0 Image]\r\n");
    func_printf("1 [Reference 1 Image]\r\n");
    func_printf("2 [Reference 2 Image]\r\n");
    func_printf("3 [Reference 3 Image]\r\n");
    func_printf("4 [Reference 4 Image]\r\n");
}

void disp_cmd_tfrate(void) {
    u8 percent = '%';
    func_printf("Trig Freq %d Hz [Duty = %d %c]\r\n", func_trig_frate, func_trig_duty, percent);
    func_printf("execute_cmd_tfrate(u32 frate, u32 duty, u32 num)");
    func_printf("ex) tfrate 30 50 300 = 30Hz 50duty 300pulse it works for10sec");
}

void disp_cmd_hwdbg(void) {
    switch (func_hw_debug) {
        case 0: func_printf("0 [Normal]\r\n");                      break;
        case 1: func_printf("1 [Image Noise Debugging]\r\n");       break;
        case 2: func_printf("2 [Output Image AVG]\r\n");            break;
    }
}

void disp_cmd_bright(void) {
    if(func_bright < 0x10000)   func_printf("BRIGHT = -%d\r\n", (0xFFFF - (func_bright & 0xFFFF)));
    else                        func_printf("BRIGHT = %d\r\n", (func_bright & 0xFFFF));
}

void disp_cmd_contra(void) {
    float fval = func_contrast / 4096.0;
    func_printf("CONTRAST = x"); float_printf(fval, 2); func_printf("\r\n");
}

void disp_cmd_sens(void) {
    func_printf("Sensitivity = %d\r\n", func_defect_sens);
}

void disp_cmd_edge_cut(void) {
    func_printf("func_edge_left = %d\r\n", func_edge_left);
    func_printf("func_edge_right = %d\r\n", func_edge_right);
    func_printf("func_edge_top = %d\r\n", func_edge_top);
    func_printf("func_edge_bottom = %d\r\n", func_edge_bottom);
    func_printf("func_edge_cut_value = %d\r\n", -func_edge_cut_value);
    func_printf("func_edge_cut_left(1x1) = %d\r\n", func_edge_left);
    func_printf("func_edge_cut_right(1x1) = %d\r\n", func_edge_cut_right);
    func_printf("func_edge_cut_top(1x1) = %d\r\n", func_edge_cut_top);
    func_printf("func_edge_cut_bottom(1x1) = %d\r\n", func_edge_cut_bottom);
}


void disp_cmd_sleepmode(void) {
    switch (func_sleepmode) {
        case 0: func_printf("current non sleep mode, ");                break;
        case 1: func_printf("current ethernet sleep mode, ");           break;
        case 2: func_printf("current out_en sleep mode, ");             break;
        case 3: func_printf("current out_en auto-time sleep mode, ");   break;
        }
    if (func_sleep)
        func_printf("sleeping\r\n");
    else
        func_printf("stay awake\r\n");

    func_printf("\r\n* List *\r\n");
    func_printf("0 : Non sleep mode\r\n");
    func_printf("1 : Ethernet connection sleep mode\r\n");
    func_printf("2 : Continuous sleep-mode\r\n");
    func_printf("3 : Continuous auto-time sleep-mode\r\n");
}

void disp_cmd_osd(void) {
    func_printf(" osd (enable:0,1) (sel:0=sync, 1=16x16avg, 2=16x16diff) (size:0=1x,1=2x,2=4x)\r\n");
}

void disp_cmd_pwdac(void) {
    func_printf("pwdac (enable:0_off_1KGnd,1_on,2_100kGnd,3_Z) (level: volt/0 to 4095) (total time: mSec)");
    func_printf("ex) pwdac 1 4095 100");
    func_printf("Time(mSec), Level is 12 bit, clk is 25MHz \r\n");
}

void disp_cmd_dnr(void) {
    func_printf(" DNR ON/OFF=%d \r\n",REG(ADDR_DNR_CTRL)&2);
}

void disp_cmd_acc(void) {
    func_printf(" ACC ON/OFF=%d \r\n",REG(ADDR_ACC_CTRL)&1);
}

void disp_cmd_topv(void) {
    func_printf(" func topvalue = %d \r\n",func_image_topvalue);
    func_printf(" ADDR_BNC_HIGH =%d \r\n",REG(ADDR_BNC_HIGH));
    func_printf(" ADDR_OFGA_LIM =%d \r\n",REG(ADDR_OFGA_LIM));
    func_printf(" ADDR_EQ_TOPVAL =%d \r\n",REG(ADDR_EQ_TOPVAL));
}

void disp_cmd_bnc(void) {
    func_printf(" func B&C ON/OFF=%d \r\n",func_bnc);
    func_printf(" B&C ON/OFF=%d \r\n",REG(ADDR_BNC_CTRL)&1);
}

void disp_cmd_eq(void) {
    func_printf(" func EQ = %d \r\n",func_eq);
    func_printf(" EQ = %d \r\n",REG(ADDR_EQ_CTRL)&1);
}

void disp_cmd_romdiag(void) {

    u32 calcsum=flash_calc_sum(FLASH_BIT2ND_BASEADDR,FLASH_BIT_LEN);
    u32 readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_CHECKSUM);
    func_printf("FPGA2nd calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
        calcsum=flash_calc_sum(FLASH_BIT3RD_BASEADDR,FLASH_BIT_LEN);
        readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT3RD_CHECKSUM);
    func_printf("FPGA3rd calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);

    func_printf("\r\n");
    u32 flash_app_len = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_SIZE);
    func_printf("flash_fw_check_1st flash_app_len=%d \r\n",flash_app_len);
        flash_app_len = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_SIZE);
    func_printf("flash_fw_check_2nd flash_app_len=%d \r\n",flash_app_len);

    //func_printf(" FLASH_ALLOC_APP_CHECKSUM = 0x%08x \r\n",flash_read_dword(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_APP_CHECKSUM ));
        calcsum=flash_calc_sum(FLASH_APP_BASEADDR,flash_app_len);
        readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_CHECKSUM);
    func_printf("FW1st calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
        calcsum=flash_calc_sum(FLASH_APP2ND_BASEADDR,flash_app_len);
        readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_CHECKSUM);
    func_printf("FW2nd calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);

    func_printf("\r\n");
        flash_app_len = flash_read_dword(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_XML_SIZE);
    func_printf("xml flash_app_len=%d \r\n",flash_app_len);
        calcsum=flash_calc_sum(FLASH_XML_BASEADDR,flash_app_len);
        readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_XML_CHECKSUM);
    func_printf("xml calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
}

void disp_cmd_romread(void) {
    func_printf(" 1. FPGA 1st \r\n");
    func_printf(" 2. FPGA 2nd \r\n");
    func_printf(" 3. FPGA 3nd \r\n");
    func_printf(" 4. APP  1st \r\n");
    func_printf(" 5. APP  2nd \r\n");
    func_printf(" 6. XML      \r\n");

    func_printf(" read bulk ex) romread 0x1000(addr) 0x1000(length) \r\n");
    func_printf(" Use ""flash4b"" command when replacing the ROM board\r\n");
}

void disp_cmd_ropertime(void) {
    func_printf(" %d:%d,%d \r\n",func_oper_time_h,func_oper_time_m,func_oper_time_s);
}

void disp_cmd_wtp(void){
    func_printf("Ex 1616/2832  ) wtp 200 256 20 20 80 20 \r\n");
    func_printf("Ex 4343       ) wtp 125 256 30 30 140 20 \r\n");
    func_printf("Ex 4343_3 a-si) wtp 125 512 20 40 120 100 \r\n");
    func_printf("Ex 810  direct) wtp 200 1024 20 20 80 20 \r\n");
    func_printf("timing profile sel) wtp 0 // wtp 1(default) \r\n");
    func_printf("==================================\r\n");
    func_printf("%s mclk str rst shr shs  oe\r\n",FPGA_MODEL);
    func_printf("  Init  : %d  %d  %d  %d  %d  %d\r\n",profile.init.mclk
										     	 	  ,profile.init.cmdstr
													  ,profile.init.tirst/100
													  ,profile.init.tshr_lpf1/100
													  ,profile.init.tshs_lpf2/100
													  ,profile.init.tgate/100);

}

//void disp_cmd_pixpos(void){
//  u32 readreg = REG(ADDR_SYNCCHECKPOS);
//  if (readreg & 1)
//      func_printf("enable\t");
//  else
//      func_printf("disable\t");
//
//  func_printf(" h_position : %d \t//\t", (readreg >> 1) & 0xfff );
//  func_printf(" v_position : %d", (readreg >> 13) & 0xfff);
//}
