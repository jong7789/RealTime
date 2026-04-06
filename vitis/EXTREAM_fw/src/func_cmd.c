/*
 * func_cmd.c

 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */
#include "func_printf.h"

#include <stdio.h>
#include "gige.h"
#include "framebuf.h"
#include "flash.h"

#include "func_cmd.h"
#include "func_basic.h"
#include "command.h"
#include "calib.h"
#include "display.h"
#include "user.h"
#include "math.h"
#include "fpga_info.h"

float afe_time_us       = 16.0;
float data_time_us      = 16.0;
float line_time_us      = 16.0;
float scan_time_us      = 0.0;
float trst_time_us      = 0.0;
float func_frate        = 0.0; // MAX_FRATE; //# 231023
float func_frate_max    = 0.0; // MAX_FRATE;
float func_frate_min    = MIN_FRATE;
float func_frate_error  = 0;

float func_frate_max_calc = 0.0;
float func_frate_calc     = 0.0;
//float ether_max_calc	  = 0.0; //#231017

float func_roll_frate     = 0.0; // MAX_FRATE; //220112mbh
float func_ext0_frate     = 0.0; // MAX_FRATE;
float func_ext1_frate     = 0.0; // MAX_FRATE;
float func_ext2_frate     = MAX_FRATE_EXT2;
float func_static_frate   = MAX_FRATE_STATIC; // init value

u32 func_trig_frate     = 0;
u32 func_trig_duty      = 50;

//u32 func_gewt         = MAX_EWT;
//u32 func_gewt_max     = MIN_EWT; //220112mbh MAX_EWT;
 u32 func_gewt          = MIN_EWT; // 220127mbh
 u32 func_gewt_max      = MAX_EWT;
u32 func_gewt_min       = MIN_EWT;
u32 func_rewt           = 0;

u32 func_acqmode    = ACQMODE_ROLL; //220111mbh
u32 func_roll_ewt   = MIN_EWT; //220111mbh
u32 func_ext0_ewt   = MIN_EWT;
u32 func_ext1_ewt   = MIN_EWT;
u32 func_ext2_ewt   = MAX_EWT_EXT2;
u32 func_static_ewt = MIN_EWT_STATIC;
u32 func_roicstr    = 256;

u32 func_out_en         = 0;
u32 func_width          = 0.0; // MAX_WIDTH;
u32 func_height         = 0.0; // MAX_HEIGHT;
u32 func_offsetx        = 0;
u32 func_offsety        = 0;
u32 func_pixfmt         = GVSP_PIX_MONO16;

u32 func_access_level   = 0;
u32 func_sync_source    = 0;
u32 func_intsync_ldead  = 300;
u32 func_test_pattern   = 0;
u32 func_grab_en        = 0;
u32 func_frame_num      = 0;
u32 func_frame_val      = 0;
u32 func_trig_mode      = 0;
u32 func_trig_delay     = 0;
u32 func_delay_unit     = 0;
u32 func_shutter_mode   = 0;
u32 func_exp_mode       = 0;
u32 func_ddr_out        = 0;
u32 func_gain_cal       = 0;
u32 func_offset_cal     = 0;
u32 func_defect_cal     = 0;
u32 func_defect_map     = 0;
u32 func_dgain          = 100;
u32 func_img_proc       = 0;
u32 func_binning_mode   = 0;
u32 func_binning        = 1;
u32 func_bright         = 0x8000;
//u32 func_contrast       = 4096;
u32 func_contrast       = 256; //# 230724 modified contrast value for HW bri & cont
u32 func_table          = 0;
float func_temp         = 0.0;
u32 func_read_defect    = 0;            // dskim - 0.xx.08
u32 func_trig_valid     = 0;            // dskim - 0.xx.08
u32 func_trig_out_active    = 0;        // dskim - 0.xx.08
u32 func_trig_in_active     = 1;        // dskim - 0.xx.08
u32 func_trig_delay_min     = 0;        // dskim - 0.xx.08
u32 func_trig_delay_max     = 65535;    // dskim - 0.xx.08
u32 func_d2m        = 0; // 210729 for d2m global

u32 func_image_acc          = 0;    // dskim - 21.10.20
u32 func_image_acc_value    = 0;
//u32 func_image_edge       = 0;
//u32 func_image_edge_value = 0;
//u32 func_image_edge_offset= 0;
u32 func_image_dnr          = 0;
u32 func_image_dnr_value    = 0;
u32 func_image_dnr_offset   = 0;
u32 func_trig_auto_offset   = 0;
u32 func_api_ext_trig       = 0;
u32 func_api_ext_trig_flag  = 0;
u32 func_apitrig_defence    = 0;
u32 func_hwload_flag        = 1; //# init config load 231222

u32 func_re_defect          = 0;    // dskim - 21.11.03

//u32 func_insert_rst_num = 10;
u32 func_insert_rst_num = 1; //# 221121mbh

u32 func_bcal1_token    = 0; // mbh 220117 for xml bcal1
u32 func_tempbcal       = 1; // mbh 220118 for tempbcal off for testing
u32 func_grabbcal       = 0; // grab enable make a bcal. 220222mbh

u32 func_sleepmode      = 3; // 0:non sleep 1:ether conn sleep 2:out_en sleep 3:auto out_en time sleep
u32 func_sleep          = 0; // 0:wake 1:sleep
u32 Token_wake          = 0; // 220318mbh
u32 Token_sleep         = 0; // 220318mbh
u32 func_ether_conn     = 0; // 0:disconnection 1:connected 220322mbh

u32 func_acc_read       = 0;

//u8 func_able_binn_num  = 0; //# 250909 cmmt
//u8 func_able_gain_num  = 0; //# 250909 cmmt
//u8 func_able_dnr   = 0;     //# 250909 cmmt

u8 func_bw_align_done = 0; //# 231226

// TI_ROIC
//#ifdef ADAS1258
//  // Normal Mode
////    u32 func_roic_data[16] = {0x80C5, 0x872C, 0x8805, 0x8C20, 0x900C, 0x9471, 0x9800, 0x9C03, 0xA246, 0xA425, 0xA800, 0xAC0F, 0xB000, 0xB400, 0xBA89, 0xBC08};
//  // Fast Low Noise Mode, Gate Charge Injection Debugging
////    u32 func_roic_data[16] = {0x82C7, 0x843C, 0x8A05, 0x8C20, 0x901C, 0x9491, 0x9800, 0x9C03, 0xA247, 0xA425, 0xA868, 0xAC0F, 0xB000, 0xB400, 0xBA89, 0xBC08};
//  // Normal Mode, Gate Charge Injection Debugging
//  u32 func_roic_data[16] = {0x80C7, 0x843C, 0x8805, 0x8C20, 0x900C, 0x9471, 0x9800, 0x9C03, 0xA246, 0xA4EE, 0xAA00, 0xAC0F, 0xB000, 0xB400, 0xBA89, 0xBC08};
//#elif defined ADAS1255
//  u32 func_roic_data[16] = {0x8007, 0x852C, 0x8825, 0x8D0C, 0x9082, 0x9414, 0x9857, 0x9C36, 0xA000, 0xA407, 0xA800, 0xAC18, 0xB002, 0xB423, 0xB82B, 0xBC08};
//#endif

//#ifdef EXT4343R
//u32 func_roic_data[16] = {0x2200};      // dskim
//#else
//u32 func_roic_data[16] = {0x1000};      // dskim - 21.04.12 - EXT1616R 기본 1.2pC으로 설정
//#endif
u32 func_roic_data[16];


float func_roic_intrst  = ROIC_INTRST;
float func_roic_cds1    = ROIC_CDS1;
float func_roic_cds2    = ROIC_CDS2;

// TI_ROIC
//float func_roic_fa        = ROIC_FA;
float func_roic_fa1     = ROIC_FA1;
float func_roic_fa2     = ROIC_FA2;
//float func_roic_dead  = ROIC_DEAD;
//float func_roic_mute  = ROIC_MUTE;
float func_gate_oe      = GATE_OE;
float func_gate_xon     = GATE_XON;
float func_gate_flk     = GATE_FLK;
float func_gate_xonflk  = GATE_XON_FLK;
float func_gate_rcycle  = GATE_TRST_PERIOD;
u32 func_erase_time     = ERASE_TIME;
u32 func_gate_crmode    = TOTAL_RESET;
u32 func_gate_srmode    = TOTAL_RESET;
u32 func_gate_rnum      = 0;
u32 func_sexp_time      = 0;
u32 func_tft_seq        = 0; //# 231024
u32 func_hw_debug       = 0;
u32 func_sw_debug       = 0;
//u32 func_sw_debug       = 1; //# 230809 for SEC

u32 func_img_avg_old    = 0;
u32 func_img_avg_dose0  = 0;
u32 func_img_avg_dose1  = 0;
u32 func_img_avg_dose2  = 0;
u32 func_img_avg_dose3  = 0;
u32 func_img_avg_dose4  = 0;
u32 func_img_avg_dose5  = 0;
u32 func_ref_avg_max    = 0;
u32 func_ref_num        = 0;
u32 func_defect_sens    = 5;

//#if defined(GEV2p5G)
//    u32 func_gainref_numlim = 4;
//#elif defined(GEV10G)
//    u32 func_gainref_numlim = 1; //# 230321
//#else
//    u32 func_gainref_numlim = 4;
//#endif

u32 func_defect[MAX_DEFECT][2]      = {0, };
u32 func_defect2[MAX_DEFECT][2]     = {0, };
u32 func_defect_cnt                 = 0;
u32 func_defect_cnt2                = 0;
u32 func_rdefect[MAX_LINE_DEFECT]   = {0, };
u32 func_cdefect[MAX_LINE_DEFECT]   = {0, };
u32 func_rdefect_cnt                = 0;
u32 func_cdefect_cnt                = 0;

// dskim - 21.03.02 - factory map
u32 func_defect3[MAX_DEFECT][2]     = {0, };
u32 func_defect_cnt3                = 0;
u32 func_rdefect3[MAX_LINE_DEFECT]  = {0, };
u32 func_cdefect3[MAX_LINE_DEFECT]  = {0, };
u32 func_rdefect_cnt3               = 0;
u32 func_cdefect_cnt3               = 0;

u32 func_busy           = 0;
u32 func_busy_time      = 0;

u32 func_check_gain_calib           = 0;        // 0.xx.09
u32 func_check_booting              = 0;        // dskim - 21.02.15

u32 func_offset_add_value           = DEFAULT_OFFSET_ADD_VALUE;
u32 func_stop_save_flash            = 0;        // dskim - 21.07.22

// dskim - 21.09.24
u32 func_edge_cut_left      = 0;    // 기본 값, Flash, API 통신에 사용된
u32 func_edge_cut_right     = 0;
u32 func_edge_cut_top       = 0;
u32 func_edge_cut_bottom    = 0;
s32 func_edge_cut_value     = -50000;

u32 func_edge_left          = 0;    // Binning 모드에 따라서 전역에 사용됨.
u32 func_edge_right         = 0;
u32 func_edge_top           = 0;
u32 func_edge_bottom        = 0;

u32 func_exposure_type      = 0;    // dskim - dynamic, static
u32 func_static_avg_enable  = 0;    // dskim - 2022.01.19

u32 func_osd_size = 0; // 0:1x 1:2x 2:4x
u32 func_osd_sel  = 1; // 0:off 1:sync_cnt 2:acc_diff

u32 func_sleep_mode_enable      = 1;    // dskim - 2022.04.27   // 기본 활성화
u32 func_sleep_mode_time        = 10;   // 분단위
u32 func_sleep_mode_time_m      = 600;  // 분 * 60
u32 func_image_acc_auto_reset   = 0;

volatile u32 func_boot_count    = 0;
volatile u32 func_grab_count    = 0;
u32 func_oper_time_h            = 0;
u32 func_oper_time_m            = 0;
u32 func_oper_time_s            = 0;
u32 func_oper_time_start        = 0;    // 동작 시작 시간
u32 func_oper_time_stop         = 0;    // 누적 동작 시간
u8  func_oper_time_select       = 0;

u8 func_sw_calibration_mode     = 0;
u8 is_load_hw_calibration       = 0;

u8 is_factory_map_mode          = 0;    // dskim - 22.12.07
u8 func_triglog_on              = 0;    //# 230809 for SEC

u32 func_bnc                    = 0;    //# 230824
u32 func_eq                     = 0;    //# 230824 intense 8bit, on 1bit
u32 func_image_topvalue         = 55000;

#define DBG_fcmd 0

u32 func_read_defect_stt		= 0;	//$ 250627
u32 func_read_defect_num        = 0;    //$ 250627

u32 func_ifs_index				= 0;	//$ 260224

void execute_func_cmd(void) {
    if(DBG_fcmd)func_printf("#[DBG] DBG_fcmd func_width=%d \r\n",func_width);
    if(DBG_fcmd)func_printf("#[DBG] DBG_fcmd func_height=%d \r\n",func_height);
	func_frate        = MAX_FRATE;
	func_frate_max    = MAX_FRATE;
	func_roll_frate   = MAX_FRATE; //220112mbh
	func_ext0_frate   = MAX_FRATE;
	func_ext1_frate   = MAX_FRATE;
	func_width        = MAX_WIDTH;
	func_height       = MAX_HEIGHT;
    if(DBG_fcmd)func_printf("#[DBG] DBG_fcmd func_width=%d \r\n",func_width);
    if(DBG_fcmd)func_printf("#[DBG] DBG_fcmd func_height=%d \r\n",func_height);

//	if(msame(mEXT4343R))
///	if(mEXT4343R_series)
//		func_roic_data[0] = 0x2200;      // dskim
//	else
//	    func_roic_data[0] = 0x1000;      // dskim - 21.04.12 - EXT1616R 기본 1.2pC으로 설정

//	func_roic_data[0] = 0x1000;          //$ 250620 All model default 1.2pC
//$ 251014
	if(AFE3256_series) func_roic_data[0] = 0x0808;
	else			   func_roic_data[0] = 0x1000;

	func_tft_seq        = TFT_TIMING_MODE;
}

void execute_cmd_auth(u32 data) {
    if(data == 1234)        func_access_level = 1;
    else if(data == 8546)   func_access_level = 2;
    else                    func_access_level = 0;
}
void execute_cmd_psel_val(u32 data, u32 val) {
    REG(ADDR_TP_SEL) = 15;
    REG(ADDR_TP_VALUE) = val;
    execute_cmd_wroic(0x10, 0); //# roic tp off
}

void execute_cmd_psel(u32 data) {
    func_test_pattern = data;

    //# added roic testpattern 221013
    switch (data) {
        case 0  : //# off
            REG(ADDR_TP_SEL) = 0;       //# fpga tp off
            execute_cmd_wroic(0x10, 0); //# roic tp off
            break;
        case 15 :
            REG(ADDR_TP_SEL) = 15;
            REG(ADDR_TP_VALUE) = 0;
            execute_cmd_wroic(0x10, 0); //# roic tp off
            break;
        case 16 : //# adc tp h/v ramp
            REG(ADDR_TP_SEL) = 0;       //# fpga tp off
            execute_cmd_wroic(0x10, 0x220); //# roic tp on!
            func_printf("roic test pattern ramp on\r\n");
            break;
        default :
            REG(ADDR_TP_SEL) = data;
            execute_cmd_wroic(0x10, 0); //# roic tp off
    }

    if((data != 0) && (func_access_level == 0)) {
        REG(ADDR_GAIN_CAL) = 0;
//      REG(ADDR_OFFSET_CAL) = 0;
        REG(ADDR_MPC_CTRL) = 0; // dskim - 21.03.08 - offset 먼저 subtraction 하도록 변경
        REG(ADDR_DEFECT_CAL) = 0;
        REG(ADDR_IPROC_MODE) = 0;
    }
    else {
        execute_cmd_gain(func_gain_cal);
        execute_cmd_offset(func_offset_cal);
        execute_cmd_defect(func_defect_cal);
        execute_cmd_iproc(func_img_proc);
    }
}

void execute_cmd_gmode(u32 num, u32 val) {
    func_frame_num = num;
    func_frame_val = val;

    REG(ADDR_FRAME_NUM) = num;
    REG(ADDR_FRAME_VAL) = val;
}

void execute_cmd_pmode(u32 data) {
    func_sync_source = data;
    REG(ADDR_TP_MODE) = data;
}

void execute_cmd_pdead(u32 data) {
    func_intsync_ldead = data;
    REG(ADDR_TP_DTIME) = data;
}

#define DBG_cmd_bmode 0
void execute_cmd_bmode(u32 data) {
    // TI_ROIC
//  float DCLK_MHz = FPGA_TFT_DATA_CLK / 1000000.0;
//  u32 ana2x2 = 12;

    execute_cmd_bmode_gain(data);   // dskim - 21.03.10 - Binning mode에 따라서 Gain 값 변경

    execute_cmd_bmode_edge_cut(data);   // dskim - 21.09.27

    func_binning_mode = data; //# 23101317

    //# 231013 ## init func_binning
    int divider;
    if (func_binning_mode == 0)      divider = 1;
    else if (func_binning_mode <= 3) divider = 2;
    else if (func_binning_mode <= 5) divider = 3;
    else                divider = 4;
    func_binning = (int)divider; //# save binning multi value 231013
    //############

    // TI_ROIC
//  if(data == 1)   {
//      set_roic_data(ana2x2, 1);
//      REG(ADDR_ROIC_MUTE) = (u32)(ROIC_MUTE_ANA2X2 * DCLK_MHz);
//  }
//  else {
//      set_roic_data(ana2x2, 0);
//      REG(ADDR_ROIC_MUTE) = (u32)(ROIC_MUTE * DCLK_MHz);
//  }
    if(DBG_cmd_bmode) func_printf("[DBG_cmd_bmode] set reg img_mode  r\n");
    REG(ADDR_IMG_MODE) = data;
}

//u32 execute_binningmodetoint(u32 data){
//  switch (data){
//  case 0:
//  case 1:
//      data = 1;
//      break;
//  case : 2;
//  case : 3;
//
//  }
//
//}

#define DBG_BGAIN 0 //# 230412 test
//void execute_cmd_bmode_gain(u32 data) { //# 221208
//  u32 ifs = get_roic_data(0) & 0x0F; //# upper 0.3 step not support
//  u32 ifs16 = get_roic_data(0) & 0x10;
//  u32 curr = (data+2) >> 1;
//  u32 prev = (func_binning_mode + 2) >> 1;
//  if(prev<1) prev =0; //# prevent
//  ifs = (u32)(ifs * ((float)curr/prev));
//  ifs = ifs16 | ifs; //# 230117
//  if(ifs < 1) ifs=1; //# under cut
//  set_roic_data(0, ifs);
//}

void execute_cmd_bmode_gain(u32 data) { //# 0.3 gain support 221208
    u32 curr = (data+2) >> 1;
    u32 prev = (func_binning_mode + 2) >> 1;

    //$ 260224 AFE3256 Analog Gain
    //if(AFE3256_series){
    //	u32 idx = func_ifs_index;
    //
    //	idx = (u32)((idx+1) * ((float)curr/prev));
    //
    //	//$ 260224 to prevent under/over flow
    //	if (idx <  1) idx =  1;
    //	idx = idx - 1;
    //	//if (idx > 39) idx = 39;
    //	if (idx > 11) idx = 11; //$ 260403 12 step
    //
    //	func_ifs_index = idx;
    //	set_roic_data(1, AFE3256_Cfb(idx));
    //	if(DBG_BGAIN) func_printf("[DBG_BGAIN] AFE3256 idx = %d \r\n", idx);
    //}
    //$ 260403 AFE3256 Analog Gain - QFS based scaling for 12 step
    if(AFE3256_series){
    	// QFS x16 table (integer): 0.3125*16=5, 0.625*16=10, ... 12.5*16=200
    	const u32 qfs_x16[12] = {5, 10, 20, 40, 60, 80, 100, 120, 140, 160, 180, 200};
    	u32 idx = func_ifs_index;
    	u32 target = qfs_x16[idx] * curr / prev;
    	u32 new_idx = 0;
    	u32 i;

    	for(i = 0; i < 12; i++){
    		if(qfs_x16[i] <= target) new_idx = i;
    		else break;
    	}

    	func_ifs_index = new_idx;
    	set_roic_data(1, AFE3256_Cfb(new_idx));
    	if(DBG_BGAIN) func_printf("[DBG_BGAIN] AFE3256 idx = %d \r\n", new_idx);
    }
    else { //$ AFE2256
    	u32 ifs = get_roic_data(0);

    	if(DBG_BGAIN)func_printf("[DBG_BGAIN] get ifs 0=%d\r\n",ifs);

    	if(ifs>=16) // 0.3 step
    		ifs = (ifs-16) *2 + 1;
    	else        // 0.6 step
    		ifs = ifs * 2;
    	if(DBG_BGAIN)func_printf("[DBG_BGAIN] get ifs 1=%d\r\n",ifs);

    	if(prev<1) prev =0; //# prevent
    	ifs = (u32)(ifs * ((float)curr/prev));
    	ifs = ifs / 2 ;

    	if     (ifs < 1 ) ifs=16; //# 0ifs gose to 0.3pc
    	else if(ifs > 15) ifs=15; //# ifs limit #230621
    	else              ; //ifs=ifs;
    	if(DBG_BGAIN)func_printf("[DBG_BGAIN] set ifs =%d\r\n",ifs);

    	set_roic_data(0, ifs);
	}
}
//# 221207
//void execute_cmd_bmode_gain(u32 data) {
////    u32 shift=0;
//  u32 ifs = get_roic_data(0);
//  if(DBG_BGAIN)func_printf("ifs=%d\r\n",ifs);
//  if (func_binning_mode > data) {
////        shift = ((func_binning_mode - data)>>1)+1; //# binn mode is 0 3 5 7
//      ifs = (u32)(ifs * ((float)data/func_binning_mode)) & 0xF;
//      if(ifs < 1) ifs=1; //# under cut
//      if(DBG_BGAIN)func_printf("shift right =%d\r\n",shift);
//  }
//  else if (data > func_binning_mode) {
//      shift = ((data - func_binning_mode)>>1)+1;
//      ifs = ifs * shift;
//      if(ifs > 15) ifs=15; //# upper cut
//      if(DBG_BGAIN)func_printf("shift left =%d\r\n",shift);
//  }
//  if(DBG_BGAIN)func_printf("ifs=%d\r\n",ifs);
////    execute_cmd_ifs(ifs)
//  set_roic_data(0, ifs);
//}

//void execute_cmd_bmode_gain(u32 data) {
//  if(func_binning_mode != data) {
//#ifdef EXT4343R
//      switch (data) {
//          case 0 :
//              execute_cmd_ifs(4); // 2.4pC
//              break;
//          case 1 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 2 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 3 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 4 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//          case 5 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//          case 6 :
//              execute_cmd_ifs(31);// 9.60pC
//              break;
//          case 7 :
//              execute_cmd_ifs(31);// 9.60pC
//              break;
//      }
//#else
//      // dskim - 21.04.12 - Binning mode에 따라서 Gain 값 변경
//      switch (data) {
//          case 0 :
//              execute_cmd_ifs(2); // 1.20pC
//              break;
//          case 1 :
//              execute_cmd_ifs(4); // 2.40pC
//              break;
//          case 2 :
//              execute_cmd_ifs(4); // 2.40pC
//              break;
//          case 3 :
//              execute_cmd_ifs(4); // 2.40pC
//              break;
//          case 4 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 5 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 6 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//          case 7 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//      }
//#endif
//  }
//}



// dskim - 22.06.02
// API SW Correction -> HW Correction 변경할 경우 User Preset을 호출하여 HW 초기화 함.
// 기존 Binning 모드는 변경이 없을 경우 Gain 값을 변경하지 않았으나,
// User Preset에서 불러올 때 강제로 Gain 값을 변경 해줘야 함
void execute_cmd_bmode_gain_force(u32 data) {
    u32 shift=0;
    u32 ifs = get_roic_data(0);
    if(DBG_BGAIN)func_printf("ifs=%d\r\n",ifs);
    if (func_binning_mode > data) {
        shift = (func_binning_mode - data)>>1; //# binn mode is 0 3 5 7
        ifs = (ifs >> shift) & 0xF;
        if(ifs < 1) ifs=1; //# under cut
        if(DBG_BGAIN)func_printf("shift right =%d\r\n",shift);
    }
    else if (data > func_binning_mode) {
        shift = (data - func_binning_mode)>>1;
        ifs = ifs << shift;
        if(ifs > 15) ifs=15; //# upper cut
        if(DBG_BGAIN)func_printf("shift left =%d\r\n",shift);
    }
    if(DBG_BGAIN)func_printf("ifs=%d\r\n",ifs);
//  execute_cmd_ifs(ifs)
    set_roic_data(0, ifs);
}
//void execute_cmd_bmode_gain_force(u32 data) {
//#ifdef EXT4343R
//      switch (data) {
//          case 0 :
//              execute_cmd_ifs(4); // 2.4pC
//              break;
//          case 1 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 2 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 3 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 4 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//          case 5 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//          case 6 :
//              execute_cmd_ifs(31);// 9.60pC
//              break;
//          case 7 :
//              execute_cmd_ifs(31);// 9.60pC
//              break;
//      }
//#else
//      // dskim - 21.04.12 - Binning mode에 따라서 Gain 값 변경
//      switch (data) {
//          case 0 :
//              execute_cmd_ifs(2); // 1.20pC
//              break;
//          case 1 :
//              execute_cmd_ifs(4); // 2.40pC
//              break;
//          case 2 :
//              execute_cmd_ifs(4); // 2.40pC
//              break;
//          case 3 :
//              execute_cmd_ifs(4); // 2.40pC
//              break;
//          case 4 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 5 :
//              execute_cmd_ifs(8); // 4.80pC
//              break;
//          case 6 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//          case 7 :
//              execute_cmd_ifs(12);// 7.20pC
//              break;
//      }
//#endif
//}

void execute_cmd_tmode(u32 data) {
	if (func_shutter_mode == 0){
	    	data = 0; //$ 250514 fix fps debug
	    }
    func_trig_mode = data;
    REG(ADDR_TRIG_MODE) = data;
}

void execute_avaliable_check() {

		execute_cmd_acc(0,func_image_acc_value);
}

void execute_cmd_tdly(u32 data) {
    func_trig_delay = data;
    REG(ADDR_TRIG_DELAY) = func_trig_delay;
}

void execute_cmd_smode(u32 data) {
    func_shutter_mode = data;
    REG(ADDR_SHUTTER_MODE)  = data;
//  REG(ADDR_SHUTTER_MODE)  = 0; // TI global shutter mode not using, 210512 mbh
    REG(ADDR_TRIG_VALID)    = data; // external output enable 201512 mbh
    func_trig_valid = data;         // dskim - xml에서 자동으로 표시되도록
    if(data == 0) {
        execute_cmd_crmode(1);
        execute_cmd_srmode(1, func_sexp_time);
        execute_cmd_tmode(0); //$ 250509 rolling shutter has only free run tmode
    }
    else {
//      execute_cmd_crmode(0);
//      execute_cmd_srmode(0, func_gate_rnum);
        // ### global mode use serial reset. 210511 mbh
        execute_cmd_crmode(1);
        execute_cmd_srmode(1, func_sexp_time);
    }
}

void execute_cmd_emode(u32 data) {
    func_exp_mode = data;
}

#define DBG_roi 0
void execute_cmd_roi(u32 offsetx, u32 offsety, u32 width, u32 height) {
    u32 offsety_fpga = offsety;
    u32 offsetx_fpga = offsetx;

    if(DBG_roi)func_printf("#[DBG_roi] offsetx=%d offsety=%d\r\n",offsetx, offsety);
    if(DBG_roi)func_printf("#[DBG_roi] width=%d height=%d\r\n",width, height);
    func_offsetx = offsetx;
    func_offsety = offsety;
    func_width = width;
    func_height = height;
    if(DBG_roi)func_printf("#[DBG_roi] func_offsetx=%d func_offsety=%d\r\n",func_offsetx, func_offsety);
    if(DBG_roi)func_printf("#[DBG_roi] func_width=%d func_height=%d\r\n",func_width, func_height);

    switch (func_binning_mode) {
        case 0  :
            offsetx_fpga = (offsetx * 1);
            offsety_fpga = (offsety * 1);
            break;
        case 1  :
            offsetx_fpga = (offsetx * 2);
            offsety_fpga = (offsety * 2);
            break;
        case 2  :
            offsetx_fpga = (offsetx * 2);
            offsety_fpga = (offsety * 2);
            break;
        case 3  :
            offsetx_fpga = (offsetx * 2);
            offsety_fpga = (offsety * 2);
            break;
        case 4  :
            offsetx_fpga = (offsetx * 3);
            offsety_fpga = (offsety * 3);
            break;
        case 5  :
            offsetx_fpga = (offsetx * 3);
            offsety_fpga = (offsety * 3);
            break;
        case 6  :
            offsetx_fpga = (offsetx * 4);
            offsety_fpga = (offsety * 4);
            break;
        case 7  :
            offsetx_fpga = (offsetx * 4);
            offsety_fpga = (offsety * 4);
            break;
    }
    // ### binning mode changing makes abnormal data in ddr nuc. 211210kds
    // ### added delay
//  flash_alloc_set();
//  msdelay(200);

//  REG(ADDR_OFFSETX) = offsetx;        // dskim - 21.02.10 - x값 y값과 동일하게 변경되도록 수정
    REG(ADDR_OFFSETX) = offsetx_fpga;
    REG(ADDR_OFFSETY) = offsety_fpga;


//  REG(ADDR_DDR_CH_EN) = 0b00000000; // 211213mbh preventing nuc gabage from wddr ch0 // --220106 rollback stop img--
//  This bug was founded at SEC field, 220114 when MBH, KDS visited. 
    if(DBG_roi)func_printf("#[DBG_roi] ADDR_WIDTH=%d \r\n",width);
    if(DBG_roi)func_printf("#[DBG_roi] ADDR_HEIGHT=%d \r\n",height);
    REG(ADDR_WIDTH) = width;
    REG(ADDR_HEIGHT) = height;
//### very critical ### v1.xx.57 221019mbh
//  flash_alloc_set();
//#####################

//  execute_cmd_re_defect();    // dskim - 21.03.02 - ROI를 변경하면  Defect도  rewrite해야 한다.
    // dskim - 21.11.03 - Defect 갯수가 많을 경우 연상 속도 이슈로 위치 옮김
    func_re_defect = 1;

//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b00110001;
//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001;   // read ch 0,1,2 On 210302
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;   // offset | gain |
//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110101;   // d2m need wavg
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;   //

    // Setup GVSP leader and trailer packets
//    framebuf_padding(func_pixfmt, func_width, func_height);
    framebuf_padding(func_pixfmt, func_width, func_height, 0); //# v2 chunk size
    framebuf_img_leader(func_pixfmt, func_width, func_height, func_offsetx, func_offsety);
//    framebuf_img_trailer(func_height);
    framebuf_img_trailer(func_height, 0); //# v2 chunk id

    if(DBG_roi)func_printf("#[DBG_roi] func_pixfmt=0x%08x\r\n",func_pixfmt);
    if(DBG_roi)func_printf("#[DBG_roi] func_width=%d\r\n",func_width);
    if(DBG_roi)func_printf("#[DBG_roi] func_height=%d\r\n",func_height);
//    if(DBG_roi)func_printf("#[DBG_roi] chunk_size=%d\r\n",chunk_size);
    if(DBG_roi)func_printf("#[DBG_roi] func_offsetx=%d\r\n",func_offsetx);
    if(DBG_roi)func_printf("#[DBG_roi] func_offsety=%d\r\n",func_offsety);
//    if(DBG_roi)func_printf("#[DBG_roi] chunk_layout_id=0x%08x\r\n",chunk_layout_id);
    if(DBG_roi)func_printf("#[DBG_roi] framebuf_bpb=0x%08x\r\n",framebuf_bpb);

    execute_cmd_edgemask_calc(); //# fpga edge mask 230215
}

void execute_cmd_grab(u32 data) {
    u32 cnt = 0;
    u32 prev = func_grab_en;
    func_grab_en = data;
    REG(ADDR_GRAB_EN) = data;

    while((REG(ADDR_GRAB_DONE) == 0) && ((prev == 1 && data == 0))) {
        gige_callback(0);
//#if defined(EXT4343RR)    // 22.08.01
#if defined(EXT4343R_1) || defined(EXT4343R_2) || defined(EXT4343R_3) // why? #221018mbh
        msdelay(200);
#else
        msdelay(100);
#endif
//      msdelay(1000);  // protecting system down when disconnection 220722dskim msdelay(100);// Off
//      func_printf(" # grab wait # \r\n");

        cnt++;
//#if defined(EXT4343RR)
#if defined(EXT4343R_1) || defined(EXT4343R_2) || defined(EXT4343R_1) // model redefine #221018
        if (cnt > 4) {
#else
        if (cnt > 10){
#endif
            func_printf("\r\n # grab time out # \r\n");
            break;
        }
    }
}

//void execute_cmd_frate_call(void) {
//      if      (func_shutter_mode==0)                                                func_frate = func_roll_frate   ;
//      else if((func_shutter_mode==1)&&(func_trig_mode==0))                          func_frate = func_ext0_frate   ;
//      else if((func_shutter_mode==1)&&(func_trig_mode==1)&&(func_exposure_type==0)) func_frate = func_ext1_frate   ;
//      else if((func_shutter_mode==1)&&(func_trig_mode==2))                          func_frate = 0; //220120mbh func_ext2_frate   ;
//      else if((func_shutter_mode==1)&&(func_trig_mode==1)&&(func_exposure_type==1)) func_frate = func_static_frate ;
//}
//
void execute_cmd_Acqmode(void)
{
        if     ((func_shutter_mode==0)&&(func_trig_mode==0)&&(func_exposure_type==0)) func_acqmode = ACQMODE_ROLL  ;
        else if((func_shutter_mode==1)&&(func_trig_mode==0)&&(func_exposure_type==0)) func_acqmode = ACQMODE_EXT0  ;
        else if((func_shutter_mode==1)&&(func_trig_mode==1)&&(func_exposure_type==0)) func_acqmode = ACQMODE_EXT1  ;
        else if((func_shutter_mode==1)&&(func_trig_mode==2)&&(func_exposure_type==0)) func_acqmode = ACQMODE_EXT2  ;
        else if((func_shutter_mode==1)&&(func_trig_mode==1)&&(func_exposure_type==1)) func_acqmode = ACQMODE_STATIC;
        else                                                                          func_acqmode = ACQMODE_NULL  ;
}

void execute_cmd_tfrate(u32 frate, u32 duty, u32 num) {
    float frame_time = 0;
    float high_time = 0;
    u32 high_time_cut = 0;

    REG(ADDR_EXT_TRIG_HIGH) = 0;
    REG(ADDR_EXT_TRIG_PERIOD)   =0;
    usdelay(1);

    func_trig_frate = frate;
    func_trig_duty = duty;

    if(frate == 0)  frame_time = 0;
    else            frame_time = 1.0 / frate;

    high_time = (frame_time * duty) / 100;
    high_time_cut = (u32)(high_time * FPGA_SYS_CLK);

    if(65535 < high_time_cut)
        high_time_cut = 65535;


    REG(ADDR_EXT_TRIG_PERIOD)   = (u32)(frame_time * FPGA_SYS_CLK);
    REG(ADDR_EXT_TRIG_HIGH)     = (num << 16) + (high_time_cut & 0xFFFF);
}

void execute_cmd_frate2ewt(u32 data) {
    execute_cmd_Acqmode(); // mode set
    float dataf = data / 1000.0;
    float MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000.0;
    //### time calc ###
    line_time_us = 256 * (1.0 / MCLK_MHz);
//  line_time_us = func_roicstr * (1.0 / MCLK_MHz); //# 220901mbh

    u32 FDUMMY = GATE_DUMMY_LINE + (func_offsety % GATE_CH);
    u32 RDUMMY = ((func_offsety + func_height) % GATE_CH);
    RDUMMY = (RDUMMY == 0) ? GATE_CH : RDUMMY;
    RDUMMY = GATE_MAX_CH - RDUMMY;
  u32 offset_line = FDUMMY + RDUMMY + GATE_DUMMY_LINE; // # rollback 230516
//u32 offset_line = FDUMMY * 2 + 30; // 30 is a margin. mbh 220211
    float offset_time_us = (GATE_CPV_PERIOD * offset_line) + (GATE_DIO_CPV * 2);
//    float roic_time_us = ((func_height + ROIC_DUMMY_LINE) * line_time_us);
    float roic_time_us = (((func_height / ROIC_DUAL) + ROIC_DUMMY_LINE) * line_time_us);  //$ 251216 dual roic
    scan_time_us = roic_time_us + offset_time_us;

    if (dataf <= 0) //220120mbh exception
        func_frate = 0;
    else if (dataf > func_frate_max)
        func_frate = func_frate_max;
    else if (dataf < func_frate_min)
        func_frate = func_frate_min;
    else
        func_frate = dataf;

    float frame_time_us = 1000000 / func_frate;
//  float ewt_time = frame_time - scan_time;
//  func_gewt = frame_time_us - scan_time_us;
    int calc_gewt=0;
    // ### EWT CALC ###
    if     (func_acqmode==ACQMODE_ROLL  ) calc_gewt = (int)frame_time_us;
    else if(func_acqmode==ACQMODE_EXT0  ) calc_gewt = (int)(frame_time_us - scan_time_us);
    else if(func_acqmode==ACQMODE_EXT1  ) calc_gewt = (int)(frame_time_us - scan_time_us);
    else if(func_acqmode==ACQMODE_EXT2  ) calc_gewt = MAX_EWT_EXT2; // fix value
    else if(func_acqmode==ACQMODE_STATIC) calc_gewt = (int)(frame_time_us - scan_time_us);
    // ### minus ewt exception ### 220124mbh
    if(calc_gewt<0) func_gewt = 0;
    else            func_gewt = calc_gewt;
    if     (func_acqmode==ACQMODE_ROLL  ) func_roll_ewt   = func_gewt;
    else if(func_acqmode==ACQMODE_EXT0  ) func_ext0_ewt   = func_gewt;
    else if(func_acqmode==ACQMODE_EXT1  ) func_ext1_ewt   = func_gewt;
    else if(func_acqmode==ACQMODE_EXT2  ) func_ext2_ewt   = func_gewt;
    else if(func_acqmode==ACQMODE_STATIC) func_static_ewt = func_gewt;
    REG(ADDR_SEXP_TIME) = (u32)(MCLK_MHz * func_gewt);

    // ### EWT SAVE ###
//  func_printf("\r\nexecute_cmd_frate2ewt func_acqmode(%d)\r\n",func_acqmode);
//  func_printf("execute_cmd_frate2ewt func_roll_ewt(%d)  func_gewt(%d)\r\n",func_roll_ewt, func_gewt);
//    func_printf("[DEBUG]0 offset time = %d us\r\n", (u32)offset_time_us);
//    func_printf("[DEBUG]0 roic time = %d us\r\n", (u32)roic_time_us);
//    func_printf("[DEBUG]0 ewt time = %d us\r\n", (u32)func_gewt);
}
#define DBG_FMAX 0
void execute_cmd_fmax(void) {
//  func_printf("\r\n # execute_cmd_fmax # \r\n");
    execute_cmd_Acqmode(); // mode set
    float MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000.0;
//  func_printf("execute_cmd_fmax func_acqmode(%d)\r\n",func_acqmode);
//  func_printf("execute_cmd_fmax func_gewt(%d)  func_roll_ewt(%d)\r\n",func_gewt, func_roll_ewt);
    if     (func_acqmode==ACQMODE_ROLL  ) func_gewt = func_roll_ewt  ;
    else if(func_acqmode==ACQMODE_EXT0  ) func_gewt = func_ext0_ewt  ;
    else if(func_acqmode==ACQMODE_EXT1  ) func_gewt = func_ext1_ewt  ;
    else if(func_acqmode==ACQMODE_EXT2  ) func_gewt = func_ext2_ewt  ;
    else if(func_acqmode==ACQMODE_STATIC) func_gewt = func_static_ewt;
    REG(ADDR_SEXP_TIME) = (u32)(MCLK_MHz * func_gewt);
    //### time calc ###
//  line_time_us = 256 * (1.0 / MCLK_MHz);
//  line_time_us = func_roicstr * (1.0 / MCLK_MHz); //# 220901 allow roic_str
    line_time_us = 256 * (1.0 / MCLK_MHz); //# 220718 roic str is already calculated in FPGA_TFT_MAIN_CLK
    u32 FDUMMY = GATE_DUMMY_LINE + (func_offsety % GATE_CH);
    u32 RDUMMY = ((func_offsety + func_height) % GATE_CH);
    RDUMMY = (RDUMMY == 0) ? GATE_CH : RDUMMY;
    RDUMMY = GATE_MAX_CH - RDUMMY;
      u32 offset_line = FDUMMY + RDUMMY + GATE_DUMMY_LINE; // # rollback 230516
//    u32 offset_line = FDUMMY * 2 + 30; // 10 is a margin. mbh 220211
    float offset_time_us = (GATE_CPV_PERIOD * offset_line) + (GATE_DIO_CPV * 2);
//    float roic_time_us = ((func_height + ROIC_DUMMY_LINE) * line_time_us);
    float roic_time_us = (((func_height / ROIC_DUAL) + ROIC_DUMMY_LINE) * line_time_us); //$ 251216 dual roic
    scan_time_us = roic_time_us + offset_time_us;
    float frame_time_us = scan_time_us + func_gewt;
    trst_time_us = (func_gate_xon - func_gate_xonflk) + func_gate_flk;
    float ether_max_calc = ETHERSPEED_B / (func_width * func_height * 2);/*16bit 2byte*/ //# 231017
    float frate_max_calc = (1000000.0 / scan_time_us);

    func_frate_max_calc = (ether_max_calc < frate_max_calc) ? ether_max_calc : frate_max_calc;
    func_frate_calc     = (1000000.0 / frame_time_us);
    float func_frate_calc_roll     = (1000000.0 / func_gewt);

    if(DBG_FMAX) func_printf("[DEBUG] ether_max_calc = %d \r\n"     , (u32)     ether_max_calc);
    if(DBG_FMAX) func_printf("[DEBUG] frate_max_calc = %d \r\n"     , (u32)     frate_max_calc);
    if(DBG_FMAX) func_printf("[DEBUG] func_frate_max_calc = %d \r\n", (u32)func_frate_max_calc);

    if(DBG_FMAX) func_printf("[DEBUG] func_roicstr = %d \r\n"	    , (u32)		  func_roicstr);
    if(DBG_FMAX) func_printf("[DEBUG] FDUMMY = %d unit\r\n"  		, (u32)				FDUMMY);
    if(DBG_FMAX) func_printf("[DEBUG] RDUMMY = %d unit\r\n"			, (u32)				RDUMMY);
    if(DBG_FMAX) func_printf("[DEBUG] MCLK_MHz = %d \r\n"			, (u32)			  MCLK_MHz);
    if(DBG_FMAX) func_printf("[DEBUG] line time = %d us\r\n"		, (u32)		  line_time_us);
    if(DBG_FMAX) func_printf("[DEBUG] height = %d pixel\r\n"		, (u32)		   func_height);
    if(DBG_FMAX) func_printf("[DEBUG] offset time = %d us\r\n"		, (u32)		offset_time_us);
    if(DBG_FMAX) func_printf("[DEBUG] roic time = %d us\r\n"		, (u32)		  roic_time_us);
    if(DBG_FMAX) func_printf("[DEBUG] ewt time = %d us\r\n"			, (u32)    		 func_gewt);
    if(DBG_FMAX) func_printf("[DEBUG] frame time = %d us\r\n"		, (u32)		 frame_time_us);
    if(DBG_FMAX) func_printf("[DEBUG] trst time = %d us\r\n"		, (u32)		  trst_time_us);
    if(DBG_FMAX) func_printf("[DEBUG] func_frate_calc = %d \r\n"	, (u32)	   func_frate_calc);

    float heightDivide = (float)MAX_HEIGHT/func_height;
    float func_frate_max_model = heightDivide * MAX_FRATE;

    // ### MAX frame  ###
//  if      (func_acqmode==ACQMODE_ROLL  ) func_frate_max = func_frate_max_model;
    //### roll slower then EXT0.. ###
    if      (func_acqmode==ACQMODE_ROLL  ) func_frate_max = (func_frate_max_model>func_frate_max_calc) ? func_frate_max_calc : func_frate_max_model; //# 230517
    else if (func_acqmode==ACQMODE_EXT0  ) func_frate_max = (func_frate_max_model>func_frate_max_calc) ? func_frate_max_calc : func_frate_max_model;
//  else if (func_acqmode==ACQMODE_EXT0  ) func_frate_max = func_frate_max_calc; //# for test 230512
    else if (func_acqmode==ACQMODE_EXT1  ) func_frate_max = func_frate_max_calc;
    else if (func_acqmode==ACQMODE_EXT2  ) func_frate_max = func_frate_max_calc; 
    else if (func_acqmode==ACQMODE_STATIC) func_frate_max = func_frate_max_model;

    // ### Frame rate ###
    if      (func_acqmode==ACQMODE_ROLL  ) func_frate = func_frate_calc_roll; //not include ewt time
    else                                   func_frate = func_frate_calc;

    // ### Frame rate Limitation ###
    if      (func_frate <= 0)             func_frate = 0;
    else if (func_frate > func_frate_max) func_frate = func_frate_max;
    else if (func_frate < func_frate_min) func_frate = func_frate_min;
    else                                  ; //func_frate = func_frate;
}
#define DBG_FRATE 0
void execute_cmd_frate(u32 data) {
//  float dataf = data / 1000.0;
//  float dataf = func_frate_calc; //220120mbh
//  func_printf("execute_cmd_frate = %d/1000 \r\n", data);
    float frame_time = 1 / func_frate;
    float real_frame_time = (frame_time * FPGA_TFT_MAIN_CLK);
    u32 ft_ext2, ft_ext1, ft_roll; // frame_time
    u32 linetime_sel; // line_time

//    if (func_shutter_mode==1 && func_trig_mode==2) // global - ext2 220117 mbh exception
//        REG(ADDR_FRAME_TIME) = (u32)(FPGA_TFT_MAIN_CLK/MAX_FRATE * 256 / 256) -1;
//    else if (func_shutter_mode==1 && func_trig_mode==1) // global - ext1
//        REG(ADDR_FRAME_TIME) = (u32)(FPGA_TFT_MAIN_CLK/func_frate_max * 256 / 256) -1; // It prevent short bar noise at rolling 1fps 211230mbh
//    else
//        REG(ADDR_FRAME_TIME) = (u32)(real_frame_time * 256 / 256) -1; // It prevent short bar noise at rolling 1fps 211230mbh

    ft_ext2 = REG(ADDR_FRAME_TIME) = (u32)(FPGA_TFT_MAIN_CLK/MAX_FRATE * 256 / 256) -1;
    ft_ext1 = (u32)(FPGA_TFT_MAIN_CLK/func_frate_max * 256 / 256) -1; // It prevent short bar noise at rolling 1fps 211230mbh
    ft_roll = (u32)(real_frame_time * 256 / 256) -1; // It prevent short bar noise at rolling 1fps 211230mbh

    if (func_shutter_mode==1 && func_trig_mode==2)  // global - ext2 220117 mbh exception
    	REG(ADDR_FRAME_TIME) = ft_ext2;
	else if (func_shutter_mode==1 && func_trig_mode==1) // global - ext1
		REG(ADDR_FRAME_TIME) = ft_ext1;
	else
		REG(ADDR_FRAME_TIME) = ft_roll;

    if (func_shutter_mode==1 && func_trig_mode==2)  // global - ext2 220117 mbh exception
        linetime_sel = ft_ext2;
	else if (func_shutter_mode==1 && func_trig_mode==1) // global - ext1
		linetime_sel = ft_ext1;
	else
		linetime_sel = ft_roll;

    if(DBG_FRATE) func_printf("[DEBUG] ft_ext2 = %d \r\n", ft_ext2);
    if(DBG_FRATE) func_printf("[DEBUG] ft_ext1 = %d \r\n", ft_ext1);
    if(DBG_FRATE) func_printf("[DEBUG] ft_roll = %d \r\n", ft_roll);

    // ##########################
    // ##### Line Time Calc ##### 210422
//  float max_line_time =( real_frame_time / FPGA_TFT_MAIN_CLK * FPGA_DATA_CLK / func_height * 0.9 ); // roic 1 frame time / ddr time height
//  float max_line_time = (float)FPGA_DATA_CLK / func_frate / (func_height+2.0) - 0.5 ; // 2.0 for margin 211015 mbh
//    float max_line_time = (float)FPGA_DATA_CLK * REG(ADDR_FRAME_TIME) / FPGA_TFT_MAIN_CLK / (func_height) + 0.5 ; // 2.0 for margin 211015 mbh
    float max_line_time = (float)FPGA_DATA_CLK * linetime_sel / FPGA_TFT_MAIN_CLK / (func_height) + 0.5 ; //# 230728
    max_line_time = (0xffff <= max_line_time ) ? 0xffff : max_line_time; // 16bit cut

//#if defined(GEV10G)
//    float min_line_time = func_width / 4 * 0.98; // min time is width, 1.1 margin //# 1.02->0.98 230718
//#else
//    float min_line_time = func_width * 0.98; // min time is width, 1.1 margin //margin 1.1->1.02 # 230707, 2832 max fps 38.1 support at external 1 mode
//#endif
    float min_line_time;
	if (def_gev_speed == 10)
		min_line_time = func_width / 4 * 0.98; // min time is width, 1.1 margin //# 1.02->0.98 230718
	else
		min_line_time = func_width * 0.98; // min time is width, 1.1 margin //margin 1.1->1.02 # 230707, 2832 max fps 38.1 support at external 1 mode

    float sel_line_time = (min_line_time < max_line_time ) ? max_line_time : min_line_time;
//	float sel_line_time = (def_gev_speed == 10) ? (float)FPGA_DATA_CLK / MAX_FRATE / (func_height) + 0.5 :
//						  (min_line_time < max_line_time) ? max_line_time : min_line_time;

//    REG(ADDR_LINE_TIME)=(u32)sel_line_time;
    REG(ADDR_LINE_TIME)=1200;
    if(DBG_FRATE) func_printf("sel_line_time = %d \r\n",(int)sel_line_time);
    if(DBG_FRATE) func_printf("max_line_time = %d \r\n",(int)max_line_time);
    if(DBG_FRATE) func_printf("min_line_time = %d \r\n",(int)min_line_time);
    // #######################
    // ### save frame rate ###
    if      (func_acqmode==ACQMODE_ROLL  ) func_roll_frate   = func_frate;
    else if (func_acqmode==ACQMODE_EXT0  ) func_ext0_frate   = func_frate;
    else if (func_acqmode==ACQMODE_EXT1  ) func_ext1_frate   = func_frate;
    else if (func_acqmode==ACQMODE_EXT2  ) func_ext2_frate   = func_frate;
    else if (func_acqmode==ACQMODE_STATIC) func_static_frate = func_frate;

    //  execute_cmd_emax();
}


void execute_cmd_emax(void) {
    if(func_acqmode==ACQMODE_STATIC)
    {
//      func_gewt_min =    500000; // 500 ms
        func_gewt_min =    0; // 500 ms //# 221121
        func_gewt_max = 180000000;  // 180 sec - dskim - static mode
    }
    else if(func_acqmode==ACQMODE_ROLL) //220126mbh
    {
        func_gewt_min =   1000000/func_frate_max; // 220126mbh
        func_gewt_max =   2000000;
    }
    else
    {
        func_gewt_min =         0;
        func_gewt_max =   2000000;    // 2sec // 220120mbh
    }

    // ### EWT Limitation ###
    if      (func_gewt <= 0)            func_gewt = 0;
    else if (func_gewt > func_gewt_max) func_gewt = func_gewt_max;
    else if (func_gewt < func_gewt_min) func_gewt = func_gewt_min;
    else                                ; //func_gewt = func_gewt;

    // ### EWT save ###
//  func_printf("\r\nexecute_cmd_frate2ewt func_acqmode(%d)\r\n",func_acqmode);
//  func_printf("execute_cmd_fmax func_roll_ewt(%d)  func_gewt(%d)\r\n",func_roll_ewt, func_gewt);
    if      (func_acqmode==ACQMODE_ROLL  ) func_roll_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT0  ) func_ext0_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT1  ) func_ext1_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT2  ) func_ext2_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_STATIC) func_static_ewt = func_gewt;
}

void execute_cmd_fmax2(u32 MAIN_CLK) {
    float MCLK_MHz = MAIN_CLK / 1000000.0;

    float INTRST = func_roic_intrst;
    float CDS1 = func_roic_cds1;
    float CDS2 = func_roic_cds2;
    float OE = func_gate_oe;

    float afe_time_us = INTRST + CDS1 + OE + CDS2;
    float data_time_us = 256 * (1.0 / MCLK_MHz);

    line_time_us = afe_time_us > data_time_us ? afe_time_us : data_time_us;

    u32 FDUMMY = GATE_DUMMY_LINE + (func_offsety % GATE_CH);
    u32 RDUMMY = ((func_offsety + func_height) % GATE_CH);
    RDUMMY = (RDUMMY == 0) ? GATE_CH : RDUMMY;
    RDUMMY = GATE_MAX_CH - RDUMMY;

    u32 offset_line = FDUMMY + RDUMMY;

    float offset_time_us = (GATE_CPV_PERIOD * offset_line) + (GATE_DIO_CPV * 2);
    float roic_time_us = ((func_height + ROIC_DUMMY_LINE) * line_time_us);
    float frame_time_us = roic_time_us + offset_time_us;
    trst_time_us = (func_gate_xon - func_gate_xonflk) + func_gate_flk;

    if(func_shutter_mode == 0)  func_frate_max = (1000000 / frame_time_us);
    else                        func_frate_max = (1000000 / (frame_time_us + trst_time_us + MIN_EWT));

    REG(ADDR_LINE_TIME)     = (u32)((float)(FPGA_DATA_CLK) / (func_height * func_frate_max)) - 100;

    // dskim - 21.03.15 - HEIGH 따라서 강제로 frate max 변경
    // dskim - 21.04.06 - 컴파일 오류 수정
    float fMAX_HEIGHT = MAX_HEIGHT;
    float ffunc_height = func_height;
    float heightDivide = fMAX_HEIGHT/ffunc_height;
    func_frate_max = heightDivide * MAX_FRATE;

    //jhkim
    if(func_frate > func_frate_max)
        func_frate = func_frate_max;
}

void execute_cmd_gewt(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_gewt = data;
    // Each mode has an ewt value. 220111mbh
//  func_printf("\r\nexecute_cmd_gewt func_acqmode(%d)\r\n",func_acqmode);
//  func_printf("execute_cmd_gewt func_roll_ewt(%d)  func_gewt(%d)\r\n",func_roll_ewt, func_gewt);
    if      (func_acqmode==ACQMODE_ROLL  ) func_roll_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT0  ) func_ext0_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT1  ) func_ext1_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT2  ) func_ext2_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_STATIC) func_static_ewt = func_gewt;

    REG(ADDR_SEXP_TIME) = (u32)(MCLK_MHz * func_gewt);
}

void execute_cmd_gewt_calc(void) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;

    if  (func_shutter_mode==0) // rolling
        func_gewt = (1000000.0/func_frate);
    else if((func_shutter_mode==1)&&(func_trig_mode==2)) // ext2
        func_gewt = MAX_EWT;
    else
        func_gewt = (1000000.0/func_frate-scan_time_us);

    if (func_gewt < 0 || 1000000000 < func_gewt)
        func_gewt = 0;

//  func_printf("\r\nexecute_cmd_gewt_calc func_acqmode(%d)\r\n",func_acqmode);
//  func_printf("execute_cmd_gewt_calc func_roll_ewt(%d)  func_gewt(%d)\r\n",func_roll_ewt, func_gewt);
    if      (func_acqmode==ACQMODE_ROLL  ) func_roll_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT0  ) func_ext0_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT1  ) func_ext1_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_EXT2  ) func_ext2_ewt   = func_gewt;
    else if (func_acqmode==ACQMODE_STATIC) func_static_ewt = func_gewt;

    REG(ADDR_SEXP_TIME) = (u32)(MCLK_MHz * func_gewt);
}


//                              NUC Gain    NUC Offset  Sub Offset
//                              0x00CC      0x0050      0x023C
//  Gain 'Off' Offset 'On'      0           0           1
//  Gain 'On'  Offset 'On'      1           1           1
//  Gain 'On'  Offset 'Off'     1           1           0
//  Gain 'Off' Offset 'Off'     0           0           0
//
void execute_cmd_gain(u32 data) {
    func_gain_cal = data;
    REG(ADDR_GAIN_CAL) = data;
    REG(ADDR_OFFSET_CAL) = data;    // dskim - 21.03.08 - offset 먼저 subtraction 하도록 변경

//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b00110001;
//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001;   // read ch 0,1,2 On 210302
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;   // offset | gain |
//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110101;   // d2m need wavg
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;   //

    REG(ADDR_DDR_CH_EN) = 0b01010001;
if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729
}

void execute_cmd_offset(u32 data) {
    func_offset_cal = data;
//  REG(ADDR_OFFSET_CAL) = data;
    if(AFE3256_series){ //$ 260305 Digital Offset Correction
    	if(data)     		execute_cmd_wroic(0x51, 0x0306);
    	else	    		execute_cmd_wroic(0x51, 0x0006);
    }
    else REG(ADDR_MPC_CTRL) = data;  // dskim - 21.03.08 - offset 먼저 subtraction 하도록 변경
}

void execute_cmd_defect(u32 data) {
    func_defect_cal = data;
    REG(ADDR_DEFECT_CAL) = data;
    REG(ADDR_LDEFECT_CAL) = data;
}

void execute_cmd_dmap(u32 data) {
    func_defect_map = data;
    REG(ADDR_DEFECT_MAP) = data;
}

void execute_cmd_ghost(u32 data) {
    u32 MCLK_KHz = FPGA_TFT_MAIN_CLK / 1000;

    func_erase_time = data;
    REG(ADDR_GATE_RST_CYCLE)    = (u32)(1 * MCLK_KHz);
    REG(ADDR_ERASE_TIME)        = (u32)(data * MCLK_KHz);
    REG(ADDR_ERASE_EN)          = 1;
    msdelay(1);

    while(!ADDR_ERASE_DONE) {
        msdelay(100);
        gige_callback(0);
    }

    REG(ADDR_ERASE_EN)          = 0;
    REG(ADDR_GATE_RST_CYCLE)    = (u32)(func_gate_rcycle * MCLK_KHz);
}

//# Gain list #
//0   0.3
//1   0.6
//2   1.2
//3   1.8
//4   2.4
//5   3
//6   3.6
//7   4.2
//8   4.8
//9   5.4
//10   6
//11   6.6
//12   7.2
//13   7.8
//14   8.4
//15   9
//16   0.3
//17   0.9
//18   1.5
//19   2.1
//20   2.7
//21   3.3
//22   3.9
//23   4.5
//24   5.1
//25   5.7
//26   6.3
//27   6.9
//28   7.5
//29   8.1
//30   8.7
//31   9.3

// TI_ROIC
#define DEBUG_IFS 0
void execute_cmd_ifs(u32 data) {
//  u32 ifs = 1;
    u32 ifs = 0;    // dskim

//    if(data==0) data=16; //# 0 is 0.3 #221109

//    set_roic_data(ifs, data);
    //$ 251014
    if(AFE3256_series) {
    	func_ifs_index = data;
    	set_roic_data(1, AFE3256_Cfb(data)); //$ 260224
    }
    else{
        if(data==0) data=16;
    	set_roic_data(0, data);
    }

    //####################################################
     // 0.3pc roic gain set 220726mbh
    if(DEBUG_IFS)func_printf("execute_cmd_ifs 1\r\n");
    if(AFE3256_series == 0){
    	if(data == 0 || data > 15) //0.3step //# data>15 221108
    	{
    		if(DEBUG_IFS)func_printf("execute_cmd_ifs 2\r\n");
    		execute_cmd_wroic(0x12, 0); //essential bit2
    		execute_cmd_wroic(0x2c, 1); //essential bit8
//      	  execute_cmd_wroic(0x5c, 0x8000+data); // gain //# +data //# comment 221109
    		execute_cmd_wroic(0x62, 0x0100); // out of register map
    		func_printf("0.3pc roic gain set\r\n");
    	}
    	else
    	{
    		if(msame(mEXT810R)){
    			execute_cmd_wroic(0x12, 0x0000);                    // ESSENTIAL BIT2
    			execute_cmd_wroic(0x2c, 1); //# 810R integ down bug #230523
    		}
    		else if(msame(mEXT2430RD)){
    			execute_cmd_wroic(0x12, 0x0000);                    // ESSENTIAL BIT2
    			execute_cmd_wroic(0x2c, 1); //# 810R integ down bug #230523
    		}
    		else {
    			execute_cmd_wroic(0x12, 0x4000);                    // ESSENTIAL BIT2
    			execute_cmd_wroic(0x2c, 0);
    		}
    		execute_cmd_wroic(0x62, 0);
    	}
    }
    //####################################################
}

void execute_cmd_dgain(u32 data) {
    func_dgain = data;
    REG(ADDR_DGAIN) = data - 1;
}

void execute_cmd_iproc(u32 data) {
    func_img_proc = data;
    REG(ADDR_IPROC_MODE) = data;
}

void execute_cmd_reboot(void) {
    (*((void(*)())(0x00)))();
}

void execute_cmd_rtemp(void) {
    read_ds1731_temp();
    // TI_ROIC
    read_roic_temp();
    read_phy_temp();
    read_fpga_temp();
}

void execute_cmd_wus(u32 data) {
    u32 i;
    // TI_ROIC
    u32 k;
    u32 size = 0x10000;
    u32 addr = FLASH_USER_BASEADDR + (data * size);

    func_table = data;

    func_printf("\r\nWrite User Preset to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    flash_buffer[0]     = (u32)(func_frate * 1000);
    flash_buffer[1]     = func_gewt;
    flash_buffer[2]     = func_width;
    flash_buffer[3]     = func_height;
    flash_buffer[4]     = func_offsetx;
    flash_buffer[5]     = func_offsety;
    flash_buffer[6]     = func_pixfmt;

//  flash_buffer[7]     = func_sync_source;
//  flash_buffer[8]     = func_intsync_ldead;
    flash_buffer[9]     = func_test_pattern;
    flash_buffer[10]    = func_trig_mode;
    flash_buffer[11]    = func_ddr_out;
    flash_buffer[12]    = func_gain_cal;
    flash_buffer[13]    = func_defect_cal;
    flash_buffer[14]    = func_dgain;
    flash_buffer[15]    = func_img_proc;
    flash_buffer[16]    = func_binning_mode;
    flash_buffer[17]    = (u32)(func_roic_intrst * 1000);
    flash_buffer[18]    = (u32)(func_roic_cds1 * 1000);
    flash_buffer[19]    = (u32)(func_roic_cds2 * 1000);
    flash_buffer[20]    = (u32)(func_roic_fa1 * 1000);
    flash_buffer[21]    = (u32)(func_roic_fa2 * 1000);
    // TI_ROIC
//  flash_buffer[19]    = (u32)(func_roic_fa * 1000);
//  flash_buffer[20]    = (u32)(func_roic_dead * 1000);
    flash_buffer[22]    = (u32)(func_gate_oe * 1000);
    flash_buffer[23]    = (u32)(func_gate_xon * 1000);
    flash_buffer[24]    = (u32)(func_gate_flk * 1000);
    flash_buffer[25]    = (u32)(func_gate_xonflk * 1000);
    flash_buffer[26]    = (u32)(func_gate_rcycle * 1000);
    flash_buffer[27]    = func_gate_crmode;
    flash_buffer[28]    = func_gate_srmode;
    flash_buffer[29]    = func_shutter_mode;
    flash_buffer[30]    = user_avg_level;
    flash_buffer[31]    = func_tft_seq;
    // TI_ROIC
//  flash_buffer[31]    = (u32)(func_roic_mute * 1000);
    flash_buffer[32]    = func_offset_cal;
    flash_buffer[33]    = func_hw_debug;
    flash_buffer[34]    = func_gate_rnum;
    flash_buffer[35]    = func_exp_mode;
    flash_buffer[36]    = (u32)(func_erase_time * 1000);

    // TI_ROIC
    k = 37;
    for(i = 0; i < 16; i++)     { flash_buffer[k] = func_roic_data[i];      k++; }

    // dskim - 21.09.24 - edge - 구버전 호환성
    flash_buffer[53]    = func_edge_cut_left;
    flash_buffer[54]    = func_edge_cut_right;
    flash_buffer[55]    = func_edge_cut_top;
    flash_buffer[56]    = func_edge_cut_bottom;
    flash_buffer[57]    = -func_edge_cut_value;
    // dskim - 21.09.24 - edge - 구버전 호환성
    flash_buffer[58]    = func_exposure_type;   // dskim - dynamic, static

    flash_write_block(addr, (u32*)flash_buffer, 65536);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

#define DBG_rus 0
u8 execute_cmd_rus(u32 data) {
    u32 i;
    // TI_ROIC
    u32 k;
    u32 size = 0x10000;
//  data = 1;           // dskim - 21.07.12 - test code 삭제
    u32 addr = FLASH_USER_BASEADDR + (data * size);
    u32 rdata[100];
    u32 flag_data = 0;
    u32 flag_edge = 0;

    func_table = data;  // dskim - 21.07.12 - execute_cmd_rus에서 설정

    func_printf("\r\nRead User Preset from Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    flash_read_dword(addr);

    for(i = 0; i < 100; i++) {
        rdata[i] = flash_read_dword(addr);
        addr += 4;
    }

    for(i = 0; i < 53; i++) {   // dskim - 21.09.24 - edge - 구버전 호환성
        if(flag_data == 0) {
            if(rdata[i] == 0xFFFFFFFF) {
                flag_data = 0;
            } else
                flag_data = 1;
        }
    }
    //# boot rus bug, ewt 0 or bitalign error 230227
//  if(rdata[0] == 0xFFFFFFFF) {
//      flag_data = 0;
//  } else
//      flag_data = 1;

    // dskim - 21.09.24 - edge - 구버전 호환성
    if(rdata[53] == 0xFFFFFFFF || rdata[53] >= MAX_WIDTH)
        flag_edge = 1;
    if(rdata[54] == 0xFFFFFFFF || rdata[54] >= MAX_WIDTH)
        flag_edge = 1;
    if(rdata[55] == 0xFFFFFFFF || rdata[55] >= MAX_HEIGHT)
        flag_edge = 1;
    if(rdata[56] == 0xFFFFFFFF || rdata[56] >= MAX_HEIGHT)
        flag_edge = 1;
    if(rdata[57] == 0xFFFFFFFF || rdata[57] >= 65536)
        flag_edge = 1;
    if(flag_edge == 0) {
        func_edge_cut_left   = rdata[53];
        func_edge_cut_right  = rdata[54];
        func_edge_cut_top    = rdata[55];
        func_edge_cut_bottom = rdata[56];
        func_edge_cut_value  = -rdata[57];
    }
    // dskim - 21.09.24 - edge

    if(rdata[58] != 0xFFFFFFFF)
        func_exposure_type   = rdata[58];       // dskim - dynamic, static

    if(!flag_data) { func_printf("\r\n");   return 1; }

    func_frate              = rdata[0] / 1000.0;
    func_gewt               = rdata[1];
    func_width              = rdata[2];
    func_height             = rdata[3];
    func_offsetx            = rdata[4];
    func_offsety            = rdata[5];
    func_pixfmt             = rdata[6];
//  func_sync_source        = rdata[7];
//  func_intsync_ldead      = rdata[8];
    func_test_pattern       = rdata[9];
    func_trig_mode          = rdata[10];
    func_ddr_out            = rdata[11];
    func_gain_cal           = rdata[12];
    func_defect_cal         = rdata[13];
    func_dgain              = rdata[14];
    func_img_proc           = rdata[15];
    func_binning_mode       = rdata[16];
    func_roic_intrst        = rdata[17] / 1000.0;
    func_roic_cds1          = rdata[18] / 1000.0;
    func_roic_cds2          = rdata[19] / 1000.0;
    func_roic_fa1           = rdata[20] / 1000.0;
    func_roic_fa2           = rdata[21] / 1000.0;
    // TI_ROIC
//  func_roic_fa            = rdata[19] / 1000.0;
//  func_roic_dead          = rdata[20] / 1000.0;
    func_gate_oe            = rdata[22] / 1000.0;
    func_gate_xon           = rdata[23] / 1000.0;
    func_gate_flk           = rdata[24] / 1000.0;
    func_gate_xonflk        = rdata[25] / 1000.0;
    func_gate_rcycle        = rdata[26] / 1000.0;
    func_gate_crmode        = rdata[27];
    func_gate_srmode        = rdata[28];
    func_shutter_mode       = rdata[29];
    user_avg_level          = rdata[30];
    func_tft_seq            = rdata[31];
    // TI_ROIC
//  func_roic_mute          = rdata[31] / 1000.0;
    func_offset_cal         = rdata[32];
    func_hw_debug           = rdata[33];
    func_gate_rnum          = rdata[34];
    func_exp_mode           = rdata[35];
    func_erase_time         = rdata[36];

    // TI_ROIC
    k = 37;
    for(i = 0; i < 16; i++)     { func_roic_data[i]     = rdata[k];     k++; }

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
    execute_cmd_gewt_calc(); // init ewt 220113mbh
    return 0;
}

u8 execute_cmd_rus2(u32 data) {
    u32 i;
    u32 size = 0x10000;
    u32 addr = FLASH_USER_BASEADDR + (data * size);
    u32 rdata[100];
    u8 DEBUG_Msg[64];
    u8 DEBUG_Str[64][64] =
                        {"func_frate",
                        "func_gewt",
                        "func_width",
                        "func_height",
                        "func_offsetx",
                        "func_offsety",
                        "func_pixfmt",
                        "not used",
                        "not used",
                        "func_test_pattern",
                        "func_trig_mode",
                        "func_ddr_out",
                        "func_gain_cal",
                        "func_defect_cal",
                        "func_dgain",
                        "func_img_proc",
                        "func_binning_mode",
                        "func_roic_intrst",
                        "func_roic_cds1",
                        "func_roic_cds2",
                        "func_roic_fa1",
                        "func_roic_fa2",
                        "func_gate_oe",
                        "func_gate_xon",
                        "func_gate_flk",
                        "func_gate_xonflk",
                        "func_gate_rcycle",
                        "func_gate_crmode",
                        "func_gate_srmode",
                        "func_shutter_mode",
                        "user_avg_level",
                        "func_tft_seq",
                        "func_offset_cal",
                        "func_hw_debug",
                        "func_gate_rnum",
                        "func_exp_mode",
                        "func_erase_time",  // 36"
                        "ROIC", // 37
                        "ROIC", // 38
                        "ROIC", // 39
                        "ROIC", // 40
                        "ROIC", // 41
                        "ROIC", // 42
                        "ROIC", // 43
                        "ROIC", // 44
                        "ROIC", // 45
                        "ROIC", // 46
                        "ROIC", // 47
                        "ROIC", // 48
                        "ROIC", // 50
                        "ROIC", // 51
                        "ROIC", // 52
                        "ROIC", // 53
                        };

    for(i = 0; i < 100; i++) {
        rdata[i] = flash_read_dword(addr);
        addr += 4;
    }

    memset(DEBUG_Msg, 0, sizeof(DEBUG_Msg));
    sprintf((char*)DEBUG_Msg, "Table: %d", (int)data);
    gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_Msg), (u8*)&DEBUG_Msg);

    for(i = 0; i < 53; i++) {
        memset(DEBUG_Msg, 0, sizeof(DEBUG_Msg));
        sprintf((char*)DEBUG_Msg, "%s: 0x%x", DEBUG_Str[i], (unsigned int)rdata[i]);
        gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_Msg), (u8*)&DEBUG_Msg);
    }

//  func_frate              = rdata[0] / 1000.0;
//  func_gewt               = rdata[1];
//  func_width              = rdata[2];
//  func_height             = rdata[3];
//  func_offsetx            = rdata[4];
//  func_offsety            = rdata[5];
//  func_pixfmt             = rdata[6];
////    func_sync_source        = rdata[7];
////    func_intsync_ldead      = rdata[8];
//  func_test_pattern       = rdata[9];
//  func_trig_mode          = rdata[10];
//  func_ddr_out            = rdata[11];
//  func_gain_cal           = rdata[12];
//  func_defect_cal         = rdata[13];
//  func_dgain              = rdata[14];
//  func_img_proc           = rdata[15];
//  func_binning_mode       = rdata[16];
//  func_roic_intrst        = rdata[17] / 1000.0;
//  func_roic_cds1          = rdata[18] / 1000.0;
//  func_roic_cds2          = rdata[19] / 1000.0;
//  func_roic_fa1           = rdata[20] / 1000.0;
//  func_roic_fa2           = rdata[21] / 1000.0;
//  // TI_ROIC
////    func_roic_fa            = rdata[19] / 1000.0;
////    func_roic_dead          = rdata[20] / 1000.0;
//  func_gate_oe            = rdata[22] / 1000.0;
//  func_gate_xon           = rdata[23] / 1000.0;
//  func_gate_flk           = rdata[24] / 1000.0;
//  func_gate_xonflk        = rdata[25] / 1000.0;
//  func_gate_rcycle        = rdata[26] / 1000.0;
//  func_gate_crmode        = rdata[27];
//  func_gate_srmode        = rdata[28];
//  func_shutter_mode       = rdata[29];
//  user_avg_level          = rdata[30];
//  func_tft_seq            = rdata[31];
//  // TI_ROIC
////    func_roic_mute          = rdata[31] / 1000.0;
//  func_offset_cal         = rdata[32];
//  func_hw_debug           = rdata[33];
//  func_gate_rnum          = rdata[34];
//  func_exp_mode           = rdata[35];
//  func_erase_time         = rdata[36];
//
//  // TI_ROIC
//  k = 37;
//  for(i = 0; i < 16; i++)     { func_roic_data[i]     = rdata[k];     k++; }


    return 0;
}

void execute_cmd_wbs(void) {
    u32 i, j, k = 0;
    u32 addr = FLASH_INFO_BASEADDR;

    func_printf("\r\nWrite Detector Info to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(i = 0; i < 16; i++) { flash_buffer[k] = TFT_SERIAL[i];      k++; }
    for(i = 0; i < 16; i++) { flash_buffer[k] = PANEL_SERIAL[i];    k++; }
    for(i = 0; i < MAX_USERSET; i++) {
        for(j = 0; j < 32; j++) {
            flash_buffer[k] = USERSET_NAME[i][j];
            k++;
        }
    }

    flash_buffer[k] = func_table;           k++;

    flash_write_block(addr, (u32*)flash_buffer, 65536);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

u8 execute_cmd_rbs(void) {
    u32 i, j, k = 0;
    u32 addr = FLASH_INFO_BASEADDR;
    u32 data[201];
    u32 flag_data = 0;

    func_printf("\r\nRead Detector Info from Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for (i = 0; i < 201; i++) {
        data[i] = flash_read_dword(addr);
        addr += 4;

        if(flag_data == 0) {
            if(data[i] == 0xFFFFFFFF)   flag_data = 0;
            else                        flag_data = 1;
        }
    }

    if(!flag_data) { func_printf("\r\n"); return 1; }

    for(i = 0; i < 16; i++) {
//      TFT_SERIAL[i] = (u8)data[k];    // dskim - 22.01.13 - TFT(Panel) Serial Number 지워지지 않도록 변경
        k++;
    }
    for(i = 0; i < 16; i++) {
//      PANEL_SERIAL[i] = (u8)data[k];  // dskim - 21.05.13 - Serial Number 지워지지 않도록 변경
        k++;
    }
    for(i = 0; i < MAX_USERSET; i++) {
        for(j = 0; j < 32; j++) {
            USERSET_NAME[i][j] = (u8)data[k];
            k++;
        }
    }
//  func_table          = data[k];  k++;
//  func_table          = 0;        k++;    // dskim - 21.07.12 - execute_cmd_rus에서 설정


    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");

    return 0;
}

u8 execute_cmd_rns_info(void) { // dskim - 21.03.24 - 단순 데이터 확인 용도.
    u32 i = 0;
    u32 flash_addr = 0;
    u32 data_info[13] = {0, };
    u8 flag_data = 0;
    u32 flash_width = 0;
    u32 flash_height = 0;
    u32 flash_ref_num = 0;

    REG(ADDR_FW_BUSY) = 1;

    flash_addr = FLASH_NUC_INFO_BASEADDR;
    func_printf("\r\nRead NUC Info from Flash Memory\r\n");
    func_printf("Process |             |");
    for(i = 0; i < 14; i ++) func_printf("\b");

    for (i = 0; i < 13; i++) {
        data_info[i] = flash_read_dword(flash_addr);
        flash_addr += 4;
        if(!flag_data) {
            if(data_info[i] == 0xFFFFFFFF)  flag_data = 0;
            else                            flag_data = 1;
        }
        if(!flag_data)   { func_printf("\r\n"); REG(ADDR_FW_BUSY) = 0; return 1; }
        func_printf("*");
    }

    func_img_avg_old    = data_info[0];
    // dskim - 0.xx.09
    flash_width     = data_info[10];
    flash_height    = data_info[11];
    flash_ref_num   = data_info[12];
if(mEXT4343R_series){
    if(flash_ref_num > 5)
        return 1;
}
else{
    if(flash_ref_num >= 9)
        return 1;
}

//  if(flash_ref_num > 0)                       // dskim - 0.00.10 - offset 값 저장되지 않도록 변경
//      func_img_avg_dose0  = data_info[1];
    if(flash_ref_num > 1)
        func_img_avg_dose1  = data_info[2];
    if(flash_ref_num > 2)
        func_img_avg_dose2  = data_info[3];
    if(flash_ref_num > 3)
        func_img_avg_dose3  = data_info[4];
    if(flash_ref_num > 4)
        func_img_avg_dose4  = data_info[5];
//  if(flash_ref_num > 5)
//      func_img_avg_dose5  = data_info[6];
//  if(flash_ref_num > 6)
//      func_img_avg_dose6  = data_info[7];
//  if(flash_ref_num > 7)
//      func_img_avg_dose7  = data_info[8];
//  if(flash_ref_num > 8)
//      func_img_avg_dose8  = data_info[9];

    if(flash_width >= MAX_WIDTH)
        flash_width = MAX_WIDTH;
    if(flash_height >= MAX_HEIGHT)
        flash_height = MAX_HEIGHT;

//  flash_width_x32 = (u32)(ceil(flash_width / 32.0)) * 32;

//  mpc_cal();

    func_printf("\r\nFinished!\r\n");

    REG(ADDR_FW_BUSY) = 0;

    return 0;
}

#ifdef GAIN_CALIB_SAVE_NUC_PARAM
void execute_cmd_wns(void) {
    u32 i, j;
    u32 size = 0x10000;
    u32 ddr_addr = 0;
    u32 flash_addr = 0;
    u32 repeat = 0;
    u32 nun_num = func_ref_num-1;
    u32 ref_cnt = 0;
    u32 debug_percent = 0;
    char DEBUG_MSG[128];

    REG(ADDR_FW_BUSY) = 1;

    func_stop_save_flash = 0;   // dskim - 21.07.22

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    repeat = ceil(width_x32 * func_height * ((nun_num*32) / 32) / (float)FLASH_BUFFER_SIZE);
//  repeat = ceil(width_x32 * func_height * (DDR_CH1_BIT_DEPTH / 32) / (float)FLASH_BUFFER_SIZE);

    ddr_addr    = ADDR_NUC_DATA;
    flash_addr  = FLASH_NUC_BASEADDR;

    func_printf("\r\nWrite NUC Parameter to Flash Memory\r\n");
    func_printf("Process |");
    for(i = 0; i < nun_num; i++)        func_printf(" ");
    func_printf("|");
    for(i = 0; i < (nun_num+1); i++)    func_printf("\b");

//  func_printf("repeat=%d \r\n",repeat); //# comment 220928

    for(i = 0; i < repeat; i++) {
        for(j = 0; j < FLASH_BUFFER_SIZE; j++) {
            flash_buffer[j] = DREG(ddr_addr);
            ddr_addr += 4;
            if(++ref_cnt == nun_num) {
                ref_cnt = 0;

//              ddr_addr += (16 - (4*(nun_num)));
//                #if defined(GEV10G)
//                //              ddr_addr += (16 - (4*(nun_num)));
//                #else
//                    ddr_addr += (16 - (4*(nun_num)));
//                #endif

					if (def_gev_speed == 10)
						;
					else
	                    ddr_addr += (16 - (4*(nun_num)));

            }
        }

        if(func_stop_save_flash == 1) {
            func_printf("\r\nStop writing NUC parameters to flash memory!\r\n");
            break;
        }

//      func_printf("flash_addr(%8x) <= ddr_addr(%8x) ddr_data(%8x) \r\n",flash_addr, ddr_addr, DREG(ddr_addr));
        flash_write_block(flash_addr, (u32*)flash_buffer, size);


        if(!(i % (repeat / nun_num))) func_printf("*");

//      if((i != 0) && !(i % (repeat / 10))) {  // dskim - 21.07.22
        if(!(i % (repeat / 10))) {
            memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
            sprintf((char*)DEBUG_MSG,"%d%%", (int)(debug_percent));
            gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
            debug_percent += 10;
        }

        flash_addr += size;
        gige_callback(0);
    }

    if(func_stop_save_flash == 0) {
        for(i = 0; i < 13; i++)
            flash_buffer[i] = 0;

        flash_addr  = FLASH_NUC_INFO_BASEADDR;
        flash_buffer[0] = func_img_avg_old;
        if(func_ref_num > 0)
            flash_buffer[1] = func_img_avg_dose0;
        if(func_ref_num > 1)
            flash_buffer[2] = func_img_avg_dose1;
        if(func_ref_num > 2)
            flash_buffer[3] = func_img_avg_dose2;
        if(func_ref_num > 3)
            flash_buffer[4] = func_img_avg_dose3;
        if(func_ref_num > 4)
            flash_buffer[5] = func_img_avg_dose4;
    //  if(func_ref_num > 5)
    //      flash_buffer[6] = func_img_avg_dose5;
    //  if(func_ref_num > 6)
    //      flash_buffer[7] = func_img_avg_dose6;
    //  if(func_ref_num > 7)
    //      flash_buffer[8] = func_img_avg_dose7;
    //  if(func_ref_num > 8)
    //      flash_buffer[9] = func_img_avg_dose8;

        flash_buffer[10] = func_width;      // dskim - 0.xx.09
        flash_buffer[11] = func_height;     // dskim - 0.xx.09
        flash_buffer[12] = func_ref_num;    // dskim - 0.xx.09

        flash_write_block(flash_addr, (u32*)flash_buffer, 65536);

        // dskim - 2021.02.15 - Gain Calibration 조건 Preset1에 저장하도록 변경
        execute_cmd_wus(1);

        func_printf("\r\nFinished!\r\n");
    }

    REG(ADDR_FW_BUSY) = 0;
}
#else
void execute_cmd_wns(void) {
    u32 i, j, a;
    u32 size = 0x10000;
    u32 ddr_addr[4] = {ADDR_AVG_DATA_DOSE1, ADDR_AVG_DATA_DOSE2, ADDR_AVG_DATA_DOSE3, ADDR_AVG_DATA_DOSE4};
    u32 ddr_data_m = 0;
    u32 ddr_data_l = 0;
    u32 flash_addr = 0;
    u32 repeat = 0;
    u32 repeat2 = 0;

    REG(ADDR_FW_BUSY) = 1;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    repeat = ceil(width_x32 * func_height * (DDR_CH2_BIT_DEPTH / 64.0) / (float)FLASH_BUFFER_SIZE);
    repeat2 = func_ref_num - 1;

    flash_addr  = FLASH_NUC_BASEADDR;

    func_printf("\r\nWrite NUC Ref Image to Flash Memory\r\n");
    func_printf("Process |");
    for(i = 0; i < repeat2; i++)        func_printf(" ");
    func_printf("|");
    for(i = 0; i < (repeat2+1); i++)    func_printf("\b");

    for(a = 0; a < repeat2; a++) {
        for(i = 0; i < repeat; i++) {
            for(j = 0; j < FLASH_BUFFER_SIZE; j++) {
                ddr_data_l = (DREG(ddr_addr[a]) >> 16) & 0xFFFF;
                ddr_addr[a] += 4;
                ddr_data_m = (DREG(ddr_addr[a]) >> 16) & 0xFFFF;
                ddr_addr[a] += 4;
                flash_buffer[j] = ((ddr_data_m << 16) | ddr_data_l);
            }
            flash_write_block(flash_addr, (u32*)flash_buffer, size);
            flash_addr += size;
            gige_callback(0);
        }
        func_printf("*");
    }

    for(i = 0; i < 13; i++)
        flash_buffer[i] = 0;

    flash_addr  = FLASH_NUC_INFO_BASEADDR;
    flash_buffer[0] = func_img_avg_old;
    if(func_ref_num > 0)
        flash_buffer[1] = func_img_avg_dose0;
    if(func_ref_num > 1)
        flash_buffer[2] = func_img_avg_dose1;
    if(func_ref_num > 2)
        flash_buffer[3] = func_img_avg_dose2;
    if(func_ref_num > 3)
        flash_buffer[4] = func_img_avg_dose3;
    if(func_ref_num > 4)
        flash_buffer[5] = func_img_avg_dose4;
//  if(func_ref_num > 5)
//      flash_buffer[6] = func_img_avg_dose5;
//  if(func_ref_num > 6)
//      flash_buffer[7] = func_img_avg_dose6;
//  if(func_ref_num > 7)
//      flash_buffer[8] = func_img_avg_dose7;
//  if(func_ref_num > 8)
//      flash_buffer[9] = func_img_avg_dose8;

    flash_buffer[10] = func_width;      // dskim - 0.xx.09
    flash_buffer[11] = func_height;     // dskim - 0.xx.09
    flash_buffer[12] = func_ref_num;    // dskim - 0.xx.09

    flash_write_block(flash_addr, (u32*)flash_buffer, 65536);

    // dskim - 2021.02.15 - Gain Calibration 조건 Preset1에 저장하도록 변경
    execute_cmd_wus(1);

    func_printf("\r\nFinished!\r\n");

    REG(ADDR_FW_BUSY) = 0;
}
#endif
void execute_cmd_bwns1(void) {

    u32 repeat_erase = 0;
    u32 repeat_write = 0;

    u32 nun_num = func_ref_num-1;

    REG(ADDR_FW_BUSY) = 1;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    repeat_erase = ceil(width_x32 * func_height * ((4*nun_num*32) / 32) / (float)FLASH_SECTORERASE_SIZE);
    repeat_write = ceil(width_x32 * func_height * ((4*nun_num*32) / 32) / (float)FLASH_WRITE_SIZE);
    if(DEBUGFLAW) func_printf("nun_num(%d)\r\n",nun_num);
    if(DEBUGFLAW) func_printf("repeat_erase(%d)\r\n",repeat_erase);
    if(DEBUGFLAW) func_printf("repeat_write(%d)\r\n",repeat_write);

    flaw_status_writeset(0);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear

    flaw_sector_erase(FLASH_NUC_BASEADDR, repeat_erase);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear

    return;
}

void execute_cmd_bwns2(void) {
    u32 i = 0;

    u32 nun_num = func_ref_num-1;
    u32 faddr = FLASH_NUC_BASEADDR;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;
    u32 repeatnum = ceil(width_x32 * func_height * ((4*nun_num*32) / 32)/4);
    u8  star_cnt = 32; // count of '*'
    u32 repeatnum_div = repeatnum/star_cnt;

    REG(ADDR_FW_BUSY) = 1;

    if(DEBUGFLAW) func_printf("# erase check(%d) # \r\n",repeatnum);

    func_printf("Process |");
    for(i = 0; i < star_cnt; i++)       func_printf(" ");
    func_printf("|");
    for(i = 0; i < (star_cnt+1); i++)   func_printf("\b");

    for (i=0; i<repeatnum; i++)
    {
        if(flash_read_dword(faddr)!= 0xffffffff)
            func_printf("cnt(%d),addr(%8x)=data(%8x) \r\n", i, faddr,flash_read_dword(faddr));

        if(i%repeatnum_div==0 )
            func_printf("*");
        faddr += 4;
    }
    func_printf("\r\n ### erase check end ### cnt(%d),addr(%8x)=data(%8x) \r\n", i, faddr,flash_read_dword(faddr));

}

void execute_cmd_bwns3(void) {
    u32 i = 0;
//  u32 repeat_erase = 0;
    u32 repeat_write = 0;
    u32 flash_addr = 0;

    u32 nun_num = func_ref_num-1;

    REG(ADDR_FW_BUSY) = 1;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

//  repeat_erase = ceil(width_x32 * func_height * ((4*nun_num*32) / 32) / (float)FLASH_SECTORERASE_SIZE);
    repeat_write = ceil(width_x32 * func_height * ((4*nun_num*32) / 32) / (float)FLASH_WRITE_SIZE);
//  if(DEBUGFLAW) func_printf("nun_num(%d)\r\n",nun_num);
//  if(DEBUGFLAW) func_printf("repeat_erase(%d)\r\n",repeat_erase);
    if(DEBUGFLAW) func_printf("210525a repeat_write(%d)\r\n",repeat_write);

    flaw_status_writeset(0);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear
//
//  flaw_sector_erase(FLASH_NUC_BASEADDR, repeat_erase);
//  REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear

    flaw_write(ADDR_NUC_DATA, FLASH_NUC_BASEADDR, repeat_write);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;

//  return;
    for(i = 0; i < 13; i++)
        flash_buffer[i] = 0;

    flash_addr  = FLASH_NUC_INFO_BASEADDR;
    flash_buffer[0] = func_img_avg_old;
    if(func_ref_num > 0)
        flash_buffer[1] = func_img_avg_dose0;
    if(func_ref_num > 1)
        flash_buffer[2] = func_img_avg_dose1;
    if(func_ref_num > 2)
        flash_buffer[3] = func_img_avg_dose2;
    if(func_ref_num > 3)
        flash_buffer[4] = func_img_avg_dose3;
    if(func_ref_num > 4)
        flash_buffer[5] = func_img_avg_dose4;
//  if(func_ref_num > 5)
//      flash_buffer[6] = func_img_avg_dose5;
//  if(func_ref_num > 6)
//      flash_buffer[7] = func_img_avg_dose6;
//  if(func_ref_num > 7)
//      flash_buffer[8] = func_img_avg_dose7;
//  if(func_ref_num > 8)
//      flash_buffer[9] = func_img_avg_dose8;

    flash_buffer[10] = func_width;      // dskim - 0.xx.09
    flash_buffer[11] = func_height;     // dskim - 0.xx.09
    flash_buffer[12] = func_ref_num;    // dskim - 0.xx.09

    flash_write_block(flash_addr, (u32*)flash_buffer, 65536);

    // dskim - 2021.02.15 - Gain Calibration 조건 Preset1에 저장하도록 변경
    execute_cmd_wus(1);

    func_printf("\r\nFinished!\r\n");

    REG(ADDR_FW_BUSY) = 0;

}

void execute_cmd_bwns4(void) {
    u32 i = 0;

    u32 nun_num = func_ref_num-1;
    u32 faddr = FLASH_NUC_BASEADDR;
    u32 daddr = ADDR_NUC_DATA;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;
    u32 repeatnum = ceil(width_x32 * func_height * ((4*nun_num*32) / 32)/4);
    u8  star_cnt = 32; // count of '*'
    u32 repeatnum_div = repeatnum/star_cnt;

    u32 breakcnt = 0;
    u32 ref_cnt = 0;

    REG(ADDR_FW_BUSY) = 1;

    func_printf("# write check(%d) # \r\n",repeatnum);
    func_printf("Process |");
    for(i = 0; i < star_cnt; i++)       func_printf(" ");
    func_printf("|");
    for(i = 0; i < (star_cnt+1); i++)   func_printf("\b");

    for (i=0; i<repeatnum; i++)
    {
        if(flash_read_dword(faddr)!= DREG(daddr))
        {
            func_printf("i(%d) flash a%8x(d%8x)= ddr a%8x(d%8x) \r\n", i, faddr,flash_read_dword(faddr),daddr, DREG(daddr));
            breakcnt++;
        }

        if (32<breakcnt) return;

        if(i%repeatnum_div==0 )
            func_printf("*");

        faddr += 4;
        daddr += 4;
        if(++ref_cnt == nun_num)
        {
            ref_cnt = 0;
            daddr += (16 - (4*(nun_num)));
        }
    }

    func_printf("\r\n ### check end ### i(%d) flash a%8x(d%8x)= ddr a%8x(d%8x) \r\n", i, faddr,flash_read_dword(faddr),daddr, DREG(daddr));

}

void execute_cmd_bwns(void) {
    u32 i = 0;
//  u32 size = 0x10000;
//  u32 ddr_addr = 0;
    u32 flash_addr = 0;
//  u32 repeat = 0;
    u32 repeat_erase = 0;
    u32 repeat_write = 0;

    u32 nun_num = func_ref_num-1;
//  u32 ref_cnt = 0;
//  u32 debug_percent = 0;
//  char DEBUG_MSG[128];

    REG(ADDR_FW_BUSY) = 1;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;


//  repeat = ceil(width_x32 * func_height * ((nun_num*32) / 32) / (float)FLASH_BUFFER_SIZE);
    repeat_erase = ceil(width_x32 * func_height * ((4*nun_num*32) / 32) / (float)FLASH_SECTORERASE_SIZE);
    repeat_write = ceil(width_x32 * func_height * ((4*nun_num*32) / 32) / (float)FLASH_WRITE_SIZE);
    if(DEBUGFLAW) func_printf("repeat_erase(%d)\r\n",repeat_erase);
    if(DEBUGFLAW) func_printf("repeat_write(%d)\r\n",repeat_write);

// ### STATUS Write SET
    flaw_status_writeset(0);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear

// ### Erase Sector is 65536Byte
// ### increasement by 0x10000 address  at ones.
    flaw_sector_erase(FLASH_NUC_BASEADDR, repeat_erase);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear

// ### WRITE 256byte repeat
    flaw_write(ADDR_NUC_DATA, FLASH_NUC_BASEADDR, repeat_write);
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;
//  return;
// ############### END ##################
// ###########################################

//  ddr_addr    = ADDR_NUC_DATA;
//  flash_addr  = FLASH_NUC_BASEADDR;
//
//  func_printf("\r\nWrite NUC Parameter to Flash Memory\r\n");
//  func_printf("Process |");
//  for(i = 0; i < nun_num; i++)        func_printf(" ");
//  func_printf("|");
//  for(i = 0; i < (nun_num+1); i++)    func_printf("\b");
//
//  for(i = 0; i < repeat; i++) {
//      for(j = 0; j < FLASH_BUFFER_SIZE; j++) {
//          flash_buffer[j] = DREG(ddr_addr);
//          ddr_addr += 4;
//          if(++ref_cnt == nun_num) {
//              ref_cnt = 0;
//              ddr_addr += (16 - (4*(nun_num)));
//          }
//      }
//      flash_write_block(flash_addr, (u32*)flash_buffer, size);
//
//      if(!(i % (repeat / nun_num))) func_printf("*");
//
//
//      flash_addr += size;
//      gige_callback(0);
//  }

    for(i = 0; i < 13; i++)
        flash_buffer[i] = 0;

    flash_addr  = FLASH_NUC_INFO_BASEADDR;
    flash_buffer[0] = func_img_avg_old;
    if(func_ref_num > 0)
        flash_buffer[1] = func_img_avg_dose0;
    if(func_ref_num > 1)
        flash_buffer[2] = func_img_avg_dose1;
    if(func_ref_num > 2)
        flash_buffer[3] = func_img_avg_dose2;
    if(func_ref_num > 3)
        flash_buffer[4] = func_img_avg_dose3;
    if(func_ref_num > 4)
        flash_buffer[5] = func_img_avg_dose4;
//  if(func_ref_num > 5)
//      flash_buffer[6] = func_img_avg_dose5;
//  if(func_ref_num > 6)
//      flash_buffer[7] = func_img_avg_dose6;
//  if(func_ref_num > 7)
//      flash_buffer[8] = func_img_avg_dose7;
//  if(func_ref_num > 8)
//      flash_buffer[9] = func_img_avg_dose8;

    flash_buffer[10] = func_width;      // dskim - 0.xx.09
    flash_buffer[11] = func_height;     // dskim - 0.xx.09
    flash_buffer[12] = func_ref_num;    // dskim - 0.xx.09

    flash_write_block(flash_addr, (u32*)flash_buffer, 65536);

    // dskim - 2021.02.15 - Gain Calibration 조건 Preset1에 저장하도록 변경
    execute_cmd_wus(1);

    func_printf("\r\nFinished!\r\n");

    REG(ADDR_FW_BUSY) = 0;
}

#define DBG_BRNS 0
#ifdef GAIN_CALIB_SAVE_NUC_PARAM
u8 execute_cmd_brns(void) {
    u32 i = 0;
    u32 ddr_addr = 0;
    u32 flash_addr = 0;
    u32 data_info[13] = {0, };
    u8 flag_data = 0;
    u32 repeat = 0;
    // dskim - 0.xx.09
    u32 flash_width_x32 = 0;
    u32 flash_width = 0;
    u32 flash_height = 0;
    u32 flash_ref_num = 0;
    u32 nun_num = 0;
    u32 ref_cnt = 0;
    // dskim - 0.xx.09

    REG(ADDR_FW_BUSY) = 1;

    flash_addr = FLASH_NUC_INFO_BASEADDR;

    for (i = 0; i < 13; i++) {
        data_info[i] = flash_read_dword(flash_addr);
        flash_addr += 4;
        if(!flag_data) {
            if(data_info[i] == 0xFFFFFFFF)  flag_data = 0;
            else                            flag_data = 1;
        }
        if(!flag_data)   { func_printf("\r\n"); REG(ADDR_FW_BUSY) = 0; return 1; }
    }

    func_img_avg_old    = data_info[0];
    // dskim - 0.xx.09
    flash_width     = data_info[10];
    flash_height    = data_info[11];
    flash_ref_num   = data_info[12];
if( mEXT4343R_series){
    if(flash_ref_num > 5)
        return 1;
}
else{
    if(flash_ref_num >= 9)
        return 1;
}


//  if(flash_ref_num > 0)                       // dskim - 0.00.10 - offset 값 저장되지 않도록 변경
//      func_img_avg_dose0  = data_info[1];
    if(flash_ref_num > 1)
        func_img_avg_dose1  = data_info[2];
    if(flash_ref_num > 2)
        func_img_avg_dose2  = data_info[3];
    if(flash_ref_num > 3)
        func_img_avg_dose3  = data_info[4];
    if(flash_ref_num > 4)
        func_img_avg_dose4  = data_info[5];
//  if(flash_ref_num > 5)
//      func_img_avg_dose5  = data_info[6];
//  if(flash_ref_num > 6)
//      func_img_avg_dose6  = data_info[7];
//  if(flash_ref_num > 7)
//      func_img_avg_dose7  = data_info[8];
//  if(flash_ref_num > 8)
//      func_img_avg_dose8  = data_info[9];

    if(flash_width >= MAX_WIDTH)
        flash_width = MAX_WIDTH;
    if(flash_height >= MAX_HEIGHT)
        flash_height = MAX_HEIGHT;
    flash_width_x32 = (u32)(ceil(flash_width / 32.0)) * 32;
    // dskim - 0.xx.09

    mpc_cal();
//---------------------------------------------------------------------------
    if (flash_ref_num == 0) // prevent 0-1 211123 mbh
        nun_num = 0;
    else
        nun_num = flash_ref_num - 1;

    repeat = flash_width_x32 * flash_height * ((nun_num*32) / 32);
//  repeat = flash_width_x32 * flash_height * (DDR_CH1_BIT_DEPTH / 32);

    ddr_addr    = ADDR_NUC_DATA;
    flash_addr  = FLASH_NUC_BASEADDR;
    if(DBG_BRNS)func_printf("230320 ADDR_NUC_DATA=0x%08x\r\n",ADDR_NUC_DATA);
    if(DBG_BRNS)func_printf("FLASH_NUC_BASEADDR=0x%08x\r\n",FLASH_NUC_BASEADDR);

    // NUC existence check
    if(flash_read_dword(flash_addr)==0xFFFFFFFF) {
        REG(ADDR_FW_BUSY) = 0;
        return 1;
    }

    REG(ADDR_FLA_ADDR) = flash_addr;    // addr setup flash_addr
    REG(ADDR_FLA_CTRL) = 1;             // read start(0)
    //# The auto increment might have a bug. It loose an 32bit data and make nuc gain dose switch.
//  REG(ADDR_FLA_CTRL) = 0b101;         // read start(0) + auto address increment(2)

    func_printf("\r\nRead NUC Parameter from Flash Memory\r\n");
    func_printf("Process |");
//  for(i = 0; i < nun_num; i++)        func_printf(" ");
//  func_printf("|");
//  for(i = 0; i < (nun_num+1); i++)    func_printf("\b");
    for(i = 0; i < (repeat>>20)+1; i++)         func_printf(" ");
    func_printf("|");
    for(i = 0; i < (repeat>>20)+2; i++)     func_printf("\b");

    msdelay(1);

//  for(i = 0; i < repeat; i++) {
//      DREG(ddr_addr) = REG(ADDR_FLA_DATA);
//      ddr_addr += 4;
//      //# manual address increment change 220512mbh
//      REG(ADDR_FLA_CTRL) = 0b11; // manual address increment(2)
//      REG(ADDR_FLA_CTRL) = 0b01;
//      if(++ref_cnt == nun_num) {
//          ref_cnt = 0;
//          DREG(ddr_addr) = 0;
//          ddr_addr += (16 - (4*(nun_num)));
//      }
//      if(!(i % (repeat / nun_num))) func_printf("*");
//  }

    for(i = 0; i < repeat; i++) {
        DREG(ddr_addr) = REG(ADDR_FLA_DATA);
        if(DBG_BRNS)if(i<100)func_printf("DREG(0x%08x)=FLASH 0x%08x,0x%08x \r\n",ddr_addr,ADDR_FLA_DATA,REG(ADDR_FLA_DATA));
        ddr_addr += 4;
        //# manual address increment change 220512mbh
        REG(ADDR_FLA_CTRL) = 0b11; // manual address increment(2)
        REG(ADDR_FLA_CTRL) = 0b01; //# 1.5sec
        if(++ref_cnt == nun_num) { //# 1sec
            ref_cnt = 0;
            DREG(ddr_addr) = 0;

//            #if defined(GEV10G)
////              ddr_addr += (16 - (4*(nun_num)));
//            #else
//                ddr_addr += (16 - (4*(nun_num)));
//            #endif

			if (def_gev_speed == 10)
				;
			else
                ddr_addr += (16 - (4*(nun_num)));
        }
//      if(!(i % (repeat / nun_num)))

//      if((i & 0xFFFFF)==0) //# 1sec
        if((i & 0x3FFFF)==0) //# 250ms //#221021
        {
            func_printf("*");
            gige_callback(0);
        }
    }

//# 1, 2 = 12
//# 1 = 7.2
//# 2 = 7
//# 6.45
//# 2, cb = 10.7

    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss
    func_printf("\r\nFinished! \r\n");
//  func_printf("Done\r\n");

    REG(ADDR_FW_BUSY) = 0;

    return 0;
}
#else
u8 execute_cmd_brns(void) {
    u32 i, a;
    u32 ddr_addr[8] = {ADDR_AVG_DATA_DOSE1, ADDR_AVG_DATA_DOSE2, ADDR_AVG_DATA_DOSE3, ADDR_AVG_DATA_DOSE4};
    u32 flash_addr = 0;
    u32 data_info[13] = {0, };
    u32 data = 0;
    u8 flag_data = 0;
    u32 repeat = 0;
    u32 repeat2 = 0;
    // dskim - 0.xx.09
    u32 flash_width_x32 = 0;
    u32 flash_width = 0;
    u32 flash_height = 0;
    u32 flash_ref_num = 0;
    // dskim - 0.xx.09

    REG(ADDR_FW_BUSY) = 1;

    flash_addr = FLASH_NUC_INFO_BASEADDR;

    for (i = 0; i < 13; i++) {
        data_info[i] = flash_read_dword(flash_addr);
        flash_addr += 4;
        if(!flag_data) {
            if(data_info[i] == 0xFFFFFFFF)  flag_data = 0;
            else                            flag_data = 1;
        }
        if(!flag_data)   { func_printf("\r\n"); REG(ADDR_FW_BUSY) = 0; return 1; }
    }

    func_img_avg_old    = data_info[0];
    // dskim - 0.xx.09
    flash_width     = data_info[10];
    flash_height    = data_info[11];
    flash_ref_num   = data_info[12];
if (mEXT4343_series)
    if(flash_ref_num > 5)
        return 0;
else
    if(flash_ref_num >= 9)
        return 0;

//  if(flash_ref_num > 0)                       // dskim - 0.00.10 - offset 값 저장되지 않도록 변경
//      func_img_avg_dose0  = data_info[1];
    if(flash_ref_num > 1)
        func_img_avg_dose1  = data_info[2];
    if(flash_ref_num > 2)
        func_img_avg_dose2  = data_info[3];
    if(flash_ref_num > 3)
        func_img_avg_dose3  = data_info[4];
    if(flash_ref_num > 4)
        func_img_avg_dose4  = data_info[5];
//  if(flash_ref_num > 5)
//      func_img_avg_dose5  = data_info[6];
//  if(flash_ref_num > 6)
//      func_img_avg_dose6  = data_info[7];
//  if(flash_ref_num > 7)
//      func_img_avg_dose7  = data_info[8];
//  if(flash_ref_num > 8)
//      func_img_avg_dose8  = data_info[9];

    if(flash_width >= MAX_WIDTH)
        flash_width = MAX_WIDTH;
    if(flash_height >= MAX_HEIGHT)
        flash_height = MAX_HEIGHT;
    flash_width_x32 = (u32)(ceil(flash_width / 32.0)) * 32;
    // dskim - 0.xx.09

    mpc_cal();

    repeat = (ceil(flash_width_x32 * flash_height * (DDR_CH2_BIT_DEPTH / 64.0) / (float)FLASH_BUFFER_SIZE)) * FLASH_BUFFER_SIZE;    // dskim - 0.xx.09
    repeat2 = flash_ref_num - 1;

    flash_addr  = FLASH_NUC_BASEADDR;

     // NUC existence check
    if(flash_read_dword(flash_addr)==0xFFFFFFFF) {
        REG(ADDR_FW_BUSY) = 0;
        return 1;
    }

//  for(a = 0; a < repeat2; a++) {
//      for(i = 0; i < repeat; i++) {
//          data = flash_read_dword(flash_addr);
//
//          if(!flag_data) {
//              if(data == 0xFFFFFFFF)  flag_data = 0;
//              else                    flag_data = 1;
//          }
//          if(!flag_data)   { func_printf("\r\n"); REG(ADDR_FW_BUSY) = 0; return 1; }
//
//          DREG(ddr_addr[a]) = (data & 0xFFFF) << 16;
//          ddr_addr[a] += 4;
//          DREG(ddr_addr[a]) = ((data >> 16) & 0xFFFF) << 16;
//          ddr_addr[a] += 4;
//          flash_addr += 4;
//      }
//      func_printf("*");
//  }

    REG(ADDR_FLA_ADDR) = flash_addr; // addr setup flash_addr
    REG(ADDR_FLA_CTRL) = 1; // read start(0)
    REG(ADDR_FLA_CTRL) = 0b101; // read start(0) + auto address increment(2)

    func_printf("\r\nRead NUC Ref Image from Flash Memory\r\n");
    func_printf("Process |");
    for(i = 0; i < repeat2; i++)        func_printf(" ");
    func_printf("|");
    for(i = 0; i < (repeat2+1); i++)    func_printf("\b");

    msdelay(1);

    for(a = 0; a < repeat2; a++) {
        for(i = 0; i < repeat; i++) {
            data = REG(ADDR_FLA_DATA);
            DREG(ddr_addr[a]) = (data & 0xFFFF) << 16;
//              if(i<4) func_printf("a=%x, ddr_addr=%x <== %x under=%x upper=%x \r\n", a, ddr_addr[a], data, (data & 0xFFFF) << 16, ((data >> 16) & 0xFFFF) << 16 );
            ddr_addr[a] += 4;
            DREG(ddr_addr[a]) = ((data >> 16) & 0xFFFF) << 16;
            ddr_addr[a] += 4;
//              REG(ADDR_FLA_CTRL) = 0b11; // manual increase address
//              REG(ADDR_FLA_CTRL) = 0b01; //
        }
        func_printf("*");
    }

    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss
    func_printf("\r\nFinished! brns \r\n");

    REG(ADDR_FW_BUSY) = 0;

    return 0;
}
#endif

u8 execute_cmd_rns(void) {
    u32 i, a;
    u32 ddr_addr[8] = {ADDR_AVG_DATA_DOSE1, ADDR_AVG_DATA_DOSE2, ADDR_AVG_DATA_DOSE3, ADDR_AVG_DATA_DOSE4};
    u32 flash_addr = 0;
    u32 data_info[13] = {0, };
    u32 data = 0;
    u8 flag_data = 0;
    u32 repeat = 0;
    u32 repeat2 = 0;
    // dskim - 0.xx.09
    u32 flash_width_x32 = 0;
    u32 flash_width = 0;
    u32 flash_height = 0;
    u32 flash_ref_num = 0;
    // dskim - 0.xx.09

    REG(ADDR_FW_BUSY) = 1;

    flash_addr = FLASH_NUC_INFO_BASEADDR;

    for (i = 0; i < 13; i++) {
        data_info[i] = flash_read_dword(flash_addr);
        flash_addr += 4;
        if(!flag_data) {
            if(data_info[i] == 0xFFFFFFFF)  flag_data = 0;
            else                            flag_data = 1;
        }
        if(!flag_data)   { func_printf("\r\n"); REG(ADDR_FW_BUSY) = 0; return 1; }
    }

    func_img_avg_old    = data_info[0];
    // dskim - 0.xx.09
    flash_width     = data_info[10];
    flash_height    = data_info[11];
    flash_ref_num   = data_info[12];

#ifdef EXT4343R
    if(flash_ref_num > 5)
        return 0;
#else
    if(flash_ref_num >= 9)
        return 0;
#endif
//  if(flash_ref_num > 0)                       // dskim - 0.00.10 - offset 값 저장되지 않도록 변경
//      func_img_avg_dose0  = data_info[1];
    if(flash_ref_num > 1)
        func_img_avg_dose1  = data_info[2];
    if(flash_ref_num > 2)
        func_img_avg_dose2  = data_info[3];
    if(flash_ref_num > 3)
        func_img_avg_dose3  = data_info[4];
    if(flash_ref_num > 4)
        func_img_avg_dose4  = data_info[5];
//  if(flash_ref_num > 5)
//      func_img_avg_dose5  = data_info[6];
//  if(flash_ref_num > 6)
//      func_img_avg_dose6  = data_info[7];
//  if(flash_ref_num > 7)
//      func_img_avg_dose7  = data_info[8];
//  if(flash_ref_num > 8)
//      func_img_avg_dose8  = data_info[9];

    if(flash_width >= MAX_WIDTH)
        flash_width = MAX_WIDTH;
    if(flash_height >= MAX_HEIGHT)
        flash_height = MAX_HEIGHT;
    flash_width_x32 = (u32)(ceil(flash_width / 32.0)) * 32;
    // dskim - 0.xx.09

    mpc_cal();

    repeat = (ceil(flash_width_x32 * flash_height * (DDR_CH2_BIT_DEPTH / 64.0) / (float)FLASH_BUFFER_SIZE)) * FLASH_BUFFER_SIZE;    // dskim - 0.xx.09
    repeat2 = flash_ref_num - 1;

    flash_addr  = FLASH_NUC_BASEADDR;

    func_printf("\r\nRead NUC Ref Image from Flash Memory\r\n");
    func_printf("Process |");
    for(i = 0; i < repeat2; i++)        func_printf(" ");
    func_printf("|");
    for(i = 0; i < (repeat2+1); i++)    func_printf("\b");

    for(a = 0; a < repeat2; a++) {
        for(i = 0; i < repeat; i++) {
            data = flash_read_dword(flash_addr);

            if(!flag_data) {
                if(data == 0xFFFFFFFF)  flag_data = 0;
                else                    flag_data = 1;
            }
            if(!flag_data)   { func_printf("\r\n"); REG(ADDR_FW_BUSY) = 0; return 1; }

            DREG(ddr_addr[a]) = (data & 0xFFFF) << 16;
            ddr_addr[a] += 4;
            DREG(ddr_addr[a]) = ((data >> 16) & 0xFFFF) << 16;
            ddr_addr[a] += 4;
            flash_addr += 4;
        }
        func_printf("*");
    }

    func_printf("\r\nFinished!\r\n");

    REG(ADDR_FW_BUSY) = 0;

    return 0;
}

void execute_cmd_wds(void) {
    u32 i, j, k;
    u32 size = 0x10000;
    u32 addr = FLASH_DEFECT_BASEADDR;

    func_printf("\r\nWrite Defect Parameter to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(j = 0; j < func_defect_cnt; j++)    // Auto Defect
        for(k = 0; k < 2; k++)
            flash_buffer[(0*MAX_DEFECT)+(j*2)+k] = func_defect[j][k];

    for(j = 0; j < func_defect_cnt2; j++)   // Manual Defect
        for(k = 0; k < 2; k++)
            flash_buffer[(1*MAX_DEFECT)+(j*2)+k] = func_defect2[j][k];

    for(j = 0; j < func_defect_cnt3; j++)   // dskim - 21.03.02 - factory map
        for(k = 0; k < 2; k++)
            flash_buffer[(2*MAX_DEFECT)+(j*2)+k] = func_defect3[j][k];

    for(j = 0; j < func_rdefect_cnt; j++)   // dskim - 21.02.08 - SW0.xx.11
        flash_buffer[(3*MAX_DEFECT)+ (0*MAX_LINE_DEFECT)+j] = func_rdefect[j];

    for(j = 0; j < func_cdefect_cnt; j++)
        flash_buffer[(3*MAX_DEFECT)+ (1*MAX_LINE_DEFECT)+j] = func_cdefect[j];

    for(j = 0; j < func_rdefect_cnt3; j++)  // dskim - 21.03.02 - factory map
        flash_buffer[(3*MAX_DEFECT)+ (2*MAX_LINE_DEFECT)+j] = func_rdefect3[j];

    for(j = 0; j < func_cdefect_cnt3; j++)
        flash_buffer[(3*MAX_DEFECT)+ (3*MAX_LINE_DEFECT)+j] = func_cdefect3[j];

    flash_buffer[16377] = func_defect_cnt3;     // dskim - 21.03.02 - factory map
    flash_buffer[16378] = func_rdefect_cnt3;
    flash_buffer[16379] = func_cdefect_cnt3;

    flash_buffer[16380] = func_defect_cnt;
    flash_buffer[16381] = func_defect_cnt2;
    flash_buffer[16382] = func_rdefect_cnt;
    flash_buffer[16383] = func_cdefect_cnt;

    flash_write_block(addr, (u32*)flash_buffer, size);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

// dskim - 22.12.07 - factory map 다시 쓰도록 - erase 구간에서 호출
void execute_cmd_wds_factory(void) {
    u32 i, j, k;
    u32 size = 0x10000;
    u32 addr = FLASH_DEFECT_BASEADDR;

    func_printf("\r\nWrite Defect Parameter to Flash Memory(Factory)\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(j = 0; j < func_defect_cnt; j++)    // 지우기
        for(k = 0; k < 2; k++)
            func_defect[j][k] = 0;
    func_defect_cnt = 0;

    for(j = 0; j < func_defect_cnt2; j++)   // 지우기
        for(k = 0; k < 2; k++)
            func_defect2[j][k] = 0;
    func_defect_cnt2 = 0;

    for(j = 0; j < func_defect_cnt3; j++)
        for(k = 0; k < 2; k++)
            flash_buffer[(2*MAX_DEFECT)+(j*2)+k] = func_defect3[j][k];


    for(j = 0; j < func_rdefect_cnt; j++)   // 지우기
        func_rdefect[j] = 0;
    func_rdefect_cnt = 0;

    for(j = 0; j < func_cdefect_cnt; j++)   // 지우기
        func_cdefect[j] = 0;
    func_cdefect_cnt = 0;

    for(j = 0; j < func_rdefect_cnt3; j++)
        flash_buffer[(3*MAX_DEFECT)+ (2*MAX_LINE_DEFECT)+j] = func_rdefect3[j];

    for(j = 0; j < func_cdefect_cnt3; j++)
        flash_buffer[(3*MAX_DEFECT)+ (3*MAX_LINE_DEFECT)+j] = func_cdefect3[j];

    flash_buffer[16377] = func_defect_cnt3;
    flash_buffer[16378] = func_rdefect_cnt3;
    flash_buffer[16379] = func_cdefect_cnt3;

    flash_buffer[16380] = func_defect_cnt;
    flash_buffer[16381] = func_defect_cnt2;
    flash_buffer[16382] = func_rdefect_cnt;
    flash_buffer[16383] = func_cdefect_cnt;

    flash_write_block(addr, (u32*)flash_buffer, size);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

void execute_cmd_wds_manual(void) {
    u32 i, j, k;
    u32 size = 0x10000;
    u32 addr = FLASH_DEFECT_BASEADDR;

    func_printf("\r\nWrite Defect Parameter to Flash Memory(Manual)\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(j = 0; j < func_defect_cnt; j++)
        for(k = 0; k < 2; k++)
            flash_buffer[(0*MAX_DEFECT)+(j*2)+k] = func_defect[j][k];

    for(j = 0; j < func_defect_cnt2; j++)
        for(k = 0; k < 2; k++)
            flash_buffer[(1*MAX_DEFECT)+(j*2)+k] = func_defect2[j][k];

    for(j = 0; j < func_defect_cnt3; j++)   // 지우기
        for(k = 0; k < 2; k++)
            func_defect3[j][k] = 0;
    func_defect_cnt3 = 0;

    for(j = 0; j < func_rdefect_cnt; j++)
        flash_buffer[(3*MAX_DEFECT)+ (0*MAX_LINE_DEFECT)+j] = func_rdefect[j];

    for(j = 0; j < func_cdefect_cnt; j++)
        flash_buffer[(3*MAX_DEFECT)+ (1*MAX_LINE_DEFECT)+j] = func_cdefect[j];

    for(j = 0; j < func_rdefect_cnt3; j++)  // 지우기
        func_rdefect3[j] = 0;
    func_rdefect_cnt3 = 0;

    for(j = 0; j < func_cdefect_cnt3; j++)
        func_cdefect3[j] = 0;
    func_cdefect_cnt3 = 0;

    flash_buffer[16377] = func_defect_cnt3;
    flash_buffer[16378] = func_rdefect_cnt3;
    flash_buffer[16379] = func_cdefect_cnt3;

    flash_buffer[16380] = func_defect_cnt;
    flash_buffer[16381] = func_defect_cnt2;
    flash_buffer[16382] = func_rdefect_cnt;
    flash_buffer[16383] = func_cdefect_cnt;

    flash_write_block(addr, (u32*)flash_buffer, size);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

#define DBG_rds 0
u8 execute_cmd_rds(void) {
    u32 i, j, k;
    u32 addr = FLASH_DEFECT_BASEADDR;
    u32 size = 0x10000;
    u32 data[10];

    func_printf("\r\nRead Defect Parameter from Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    data[0] = flash_read_dword(addr + size - 28);
    data[1] = flash_read_dword(addr + size - 24);
    data[2] = flash_read_dword(addr + size - 20);
    data[3] = flash_read_dword(addr + size - 16);

    data[4] = flash_read_dword(addr + size - 12);
    data[5] = flash_read_dword(addr + size - 8);
    data[6] = flash_read_dword(addr + size - 4);

//  for(i = 0; i < 4; i++)      // dskim - 21.08.18 - CsI Defect 이슈로 예외처리 해제
//      if(data[i] > MAX_DEFECT)        return 1;
//  for(i = 4; i < 7; i++)
//      if(data[i] > MAX_LINE_DEFECT)   return 1;

    // dskim - 21.08.18 - flash 쓰레기 데이터가 있을 경우 예외 처리
    if((data[0] == 0xFFFFFFFF) || (data[3] == 0xFFFFFFFF) || (data[4] == 0xFFFFFFFF))
        return 1;
    if((data[1] > MAX_LINE_DEFECT) || (data[2] > MAX_LINE_DEFECT) || (data[5] > MAX_LINE_DEFECT) || (data[6] > MAX_LINE_DEFECT))
        return 1;

    func_defect_cnt3    = data[0];
    func_rdefect_cnt3   = data[1];
    func_cdefect_cnt3   = data[2];

    func_defect_cnt     = data[3];
    func_defect_cnt2    = data[4];
    func_rdefect_cnt    = data[5];
    func_cdefect_cnt    = data[6];

    if(DBG_rds)func_printf("#[DBG_rds] 0 func_width=%d \r\n",func_width);
    if(DBG_rds)func_printf("#[DBG_rds] func_height=%d \r\n",func_height);
    addr = FLASH_DEFECT_BASEADDR;
    for(j = 0; j < func_defect_cnt; j++) {
        for(k = 0; k < 2; k++) {
            func_defect[j][k] = flash_read_dword(addr);
            addr += 4;
        }
    }

    addr = FLASH_DEFECT_BASEADDR + (1 * MAX_DEFECT * 4);
    for(j = 0; j < func_defect_cnt2; j++) {
        for(k = 0; k < 2; k++) {
            func_defect2[j][k] = flash_read_dword(addr);
            addr += 4;
        }
    }

    // dskim - 21.03.02 - factory map
    addr = FLASH_DEFECT_BASEADDR + (2 * MAX_DEFECT * 4);
    for(j = 0; j < func_defect_cnt3; j++) {
        for(k = 0; k < 2; k++) {
            func_defect3[j][k] = flash_read_dword(addr);
            addr += 4;
        }
    }

    addr = FLASH_DEFECT_BASEADDR + (3 * MAX_DEFECT * 4);
    for(j = 0; j < func_rdefect_cnt; j++) {
        func_rdefect[j] = flash_read_dword(addr);
        addr += 4;
    }

    addr = FLASH_DEFECT_BASEADDR + (3 * MAX_DEFECT * 4) + (1 * MAX_LINE_DEFECT * 4);
    for(j = 0; j < func_cdefect_cnt; j++) {
        func_cdefect[j] = flash_read_dword(addr);
        addr += 4;
    }

    // dskim - 21.03.02 - factory map
    addr = FLASH_DEFECT_BASEADDR + (3 * MAX_DEFECT * 4) + (2 * MAX_LINE_DEFECT * 4);
    for(j = 0; j < func_rdefect_cnt3; j++) {
        func_rdefect3[j] = flash_read_dword(addr);
        addr += 4;
    }

    addr = FLASH_DEFECT_BASEADDR + (3 * MAX_DEFECT * 4) + (3 * MAX_LINE_DEFECT * 4);
    for(j = 0; j < func_cdefect_cnt3; j++) {
        func_cdefect3[j] = flash_read_dword(addr);
        addr += 4;
    }

    set_calib_defect(0);
    set_calib_defect(1);
    set_calib_rdefect();    // dskim - Row Defect 초기 반영되도록 수정
    set_calib_cdefect();    // dskim - Column Defect 초기 반영되도록 수정

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
    return 0;
}

void execute_cmd_rflash(u32 addr) {
    func_printf("flash  addr = 0x%08x, rdata = 0x%08x\r\n", addr, flash_read_dword(addr));
}

void execute_cmd_hwdbg(u32 data) {
    func_hw_debug = data;
    static u32 prev_calib_map = 0;

    switch(func_hw_debug) {
        case 0  :   execute_cmd_offset(func_offset_cal);
                    func_calib_map = prev_calib_map;
                    break;
        case 1  :
//                  REG(ADDR_OFFSET_CAL) = 1;
                    REG(ADDR_MPC_CTRL) = 1; // dskim - 21.03.08 - offset 먼저 subtraction 하도록 변경
                    prev_calib_map = func_calib_map;
                    func_calib_map = 1;
                    break;
        case 2  :   prev_calib_map = func_calib_map;
                    func_calib_map = 0;
                    execute_cmd_cddr(8);
                    break;
    }
}

void execute_cmd_swdbg(u32 data) {
    func_sw_debug = data;
    char DEBUG_MSG[128];
    switch(func_sw_debug) {
        case 0  :
                    memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
                    sprintf((char*)DEBUG_MSG,"Software Debugging Mode Off\r\n");
                    gige_send_message4(GEV_EVENT_SW_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
                    break;
        case 1  :
                    memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
                    sprintf((char*)DEBUG_MSG,"Software Debugging Mode On\r\n");
                    gige_send_message4(GEV_EVENT_SW_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
                    break;
    }
}

void execute_cmd_bright(u32 data) {
    u32 val = 0;
    func_bright = data;
    if(func_bright < 0x8000)    val = (1 << 16) | (0x8000 - (func_bright & 0x7FFF));
    else                        val = (0 << 16) | (func_bright & 0x7FFF);
    REG(ADDR_BRIGHT) = val;
}

void execute_cmd_contra(u32 data) {
    func_contrast = data;
    REG(ADDR_CONTRAST) = data;
}


void execute_cmd_wflash(u32 addr, u32 data) {
    u32 i;
    u32 base_addr = addr & 0xFFFF0000;
    for(i = 0; i < 16384; i++)  flash_buffer[i] = flash_read_dword(base_addr + (i*4));
    flash_buffer[(addr & 0xFFFF)/4] = data;
    flash_write_block(base_addr, (u32*)flash_buffer, 65536);
    if(!sys_state.only_comment)     func_printf("addr = 0x%08x, wdata = 0x%08x\r\n", addr, data);
}

void execute_cmd_reep(u32 addr) {
    if(!sys_state.only_comment)     func_printf("eeprom addr = 0x%08x, rdata = 0x%08x\r\n", addr, eeprom_read_dword(addr));
}

void execute_cmd_weep(u32 addr, u32 data) {
    eeprom_write_dword(addr, data);
    if(!sys_state.only_comment)     func_printf("addr = 0x%08x, wdata = 0x%08x\r\n", addr, data);
}

//void execute_cmd_flashrw(u32 data) {
////    u32 flash_interval = 0x10000;
////    u32 eeprom_interval = 4;
//  u32 addr = 0, length = 0;
//  u32 i;
//  u32 frdata;
//  u32 keep;
////    interval = (data == 9 ? eeprom_interval : flash_interval);
//
//  switch(data) {
//      case 0 : addr = FLASH_BIT_BASEADDR;     length = FLASH_BIT_LEN;         break;
//      case 1 : addr = FLASH_ALLOC_BASEADDR;   length = FLASH_ALLOC_LEN;       break;
//      case 2 : addr = FLASH_XML_BASEADDR;     length = FLASH_XML_LEN;         break;
//      case 3 : addr = FLASH_APP_BASEADDR;     length = FLASH_APP_LEN;         break;
//      case 4 : addr = FLASH_USER_BASEADDR;    length = FLASH_USER_LEN;        break;
//      case 5 : addr = FLASH_INFO_BASEADDR;    length = FLASH_INFO_LEN;        break;
//      case 6 : addr = FLASH_DEFECT_BASEADDR;  length = FLASH_DEFECT_LEN;      break;
////        case 7 : addr = FLASH_NUC_BASEADDR;     length = FLASH_NUC_LEN;         break;
//      case 7 : addr = FLASH_NUC_INFO_BASEADDR;    length = FLASH_NUC_INFO_LEN;        break;
//      case 8 : addr = 0;                      length = FLASH_SIZE;            break;
//      case 9 : addr = 0;                      length = EEPROM_SIZE;           break;
//      case 10:                                                                break;
//      case 11:                                                                break;
//      case 12:                                                                break;  // dskim -22.07.27
//      case 13:                                                                break;  // dskim -22.12.07
//      case 14:                                                                break;  // dskim -22.12.07
//      case 15:                                                                break;  // dskim -22.12.07
//      case 20 : addr = FLASH_BIT2ND_BASEADDR;     length = FLASH_BIT_LEN;     break; //# 2209xx
//      case 21 : addr = FLASH_BIT3RD_BASEADDR;     length = FLASH_BIT_LEN;     break;
//      case 22 : addr = FLASH_APP2ND_BASEADDR;     length = FLASH_APP_LEN;     break;
//      case 23 : addr = FLASH_AL2ND_BASEADDR;      length = FLASH_ALLOC_LEN;   break; //# 220922
//  }
//
//  for (i = 0; i < length; i += 4){
//      keep = flash_read_dword(addr+i);
//      execute_cmd_wflash(addr+i, 0xFFFFFFFF);
//      execute_cmd_wflash(addr+i, 0x00000000);
//      frdata = flash_read_dword(addr+i);
//      if(frdata!=0)
//          func_printf("Error ADDR = %08x DATA = %08x \r\n", addr+i, frdata);
//      if(i%4096==0)
//          func_printf("checking ADDR = %08x // length = %d \r\n", addr+i, length);
//      }
//  func_printf("execute_cmd_flashrw FLASH CHECK OVER \r\n");
//
//}

#define OP_CALLB 0

void execute_cmd_erase(u32 data) {
    u32 flash_interval = 0x10000;
    u32 eeprom_interval = 4;
    u32 addr = 0, length = 0, interval = 0;
    u32 i;

    interval = (data == 9 ? eeprom_interval : flash_interval);

    switch(data) {
        case 0 : addr = FLASH_BIT_BASEADDR;     length = FLASH_BIT_LEN;         break;
        case 1 : addr = FLASH_ALLOC_BASEADDR;   length = FLASH_ALLOC_LEN;       break;
        case 2 : addr = FLASH_XML_BASEADDR;     length = FLASH_XML_LEN;         break;
        case 3 : addr = FLASH_APP_BASEADDR;     length = FLASH_APP_LEN;         break;
        case 4 : addr = FLASH_USER_BASEADDR;    length = FLASH_USER_LEN;        break;
        case 5 : addr = FLASH_INFO_BASEADDR;    length = FLASH_INFO_LEN;        break;
        case 6 : addr = FLASH_DEFECT_BASEADDR;  length = FLASH_DEFECT_LEN;      break;
//      case 7 : addr = FLASH_NUC_BASEADDR;     length = FLASH_NUC_LEN;         break;
        case 7 : addr = FLASH_NUC_INFO_BASEADDR;    length = FLASH_NUC_INFO_LEN;        break;
        case 8 : addr = 0;                      length = FLASH_SIZE;            break;
        case 9 : addr = 0;                      length = EEPROM_SIZE;           break;
        case 10:                                                                break;
        case 11:                                                                break;
        case 12:                                                                break;  // dskim -22.07.27
        case 13:                                                                break;  // dskim -22.12.07
        case 14:                                                                break;  // dskim -22.12.07
        case 15:                                                                break;  // dskim -22.12.07
        case 20 : addr = FLASH_BIT2ND_BASEADDR;     length = FLASH_BIT_LEN;     break; //# 2209xx
        case 21 : addr = FLASH_BIT3RD_BASEADDR;     length = FLASH_BIT_LEN;     break;
        case 22 : addr = FLASH_APP2ND_BASEADDR;     length = FLASH_APP_LEN;     break;
        case 23 : addr = FLASH_AL2ND_BASEADDR;      length = FLASH_ALLOC_LEN;   break; //# 220922
    }

    if( data == 8 )
    {
        u32 repeat_write = ceil(FLASH_SIZE / (float)65536);
        flaw_sector_erase(0, repeat_write);
        return;
    }

    if(data == 10) {
        func_img_avg_old    = 0;
        func_img_avg_dose0  = 0;
        func_img_avg_dose1  = 0;
        func_img_avg_dose2  = 0;
        func_img_avg_dose3  = 0;
        func_img_avg_dose4  = 0;

        func_check_gain_calib = 0;  // 0.xx.09

        mpc_cal();
        return;
    }

    for (i = 0; i < length; i += interval){
        if(data == 9) {
            eeprom_write_dword(i, 0xFFFFFFFF);
            if(OP_CALLB) gige_callback(0);
            if(!(i % 0x200)) func_printf("Erase Addr: 0x%04x [Interval 4]\r\n", i);
        }
        else {
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }
    }

    // 사용하지 않지만 호환성을 위해서
    if(data == 6) {
        // 일반 사용자가 6번으로 지울 경우 factory map은 지우지 않도록
        if(is_factory_map_mode == 0) {
            // dskim - 22.12.07 - factory map은 지우지 않도록
            execute_cmd_wds_factory();
        }
    }

    if(data == 7) {
        addr = FLASH_NUC_INFO_BASEADDR;
        length = FLASH_NUC_INFO_LEN;

        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }
    }

    if(data == 11) {
        addr = FLASH_USER_BASEADDR;
        length = FLASH_USER_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }

        addr = FLASH_INFO_BASEADDR;
        length = FLASH_INFO_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }

        addr = FLASH_DEFECT_BASEADDR;
        length = FLASH_DEFECT_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }

        addr = FLASH_NUC_BASEADDR;
        length = FLASH_NUC_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }

        addr = FLASH_NUC_INFO_BASEADDR;
        length = FLASH_NUC_INFO_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }

        // dskim - 22.12.07 - 일반 유저일 경우, factory map은 지우지 않도록
        if(is_factory_map_mode == 0) {
            execute_cmd_wds_factory();
        }
    }

    // dskim - 22.07.27
    if(data == 12) {
        addr = FLASH_OPERATING_TIME1_BASEADDR;
        length = FLASH_OPERATING_TIME1_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }

        addr = FLASH_OPERATING_TIME2_BASEADDR;
        length = FLASH_OPERATING_TIME2_LEN;
        for (i = 0; i < length; i += interval){
            flash_erase_block(addr+i);
            if(OP_CALLB) gige_callback(0);
            func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
        }
    }

    // dskim - 22.12.07 - manual map만 지우기
    if(data == 13) {
        {
            addr = FLASH_DEFECT_BASEADDR;
            length = FLASH_DEFECT_LEN;
            for (i = 0; i < length; i += interval){
                flash_erase_block(addr+i);
                if(OP_CALLB) gige_callback(0);
                func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
            }
        }
        // dskim - 22.12.07 - 일반 유저일 경우, factory map은 지우지 않도록
        execute_cmd_wds_factory();
    }

    // dskim - 22.12.07 - factory map만 지우기
    if(data == 14) {
        if(is_factory_map_mode == 1) {
            addr = FLASH_DEFECT_BASEADDR;
            length = FLASH_DEFECT_LEN;
            for (i = 0; i < length; i += interval){
                flash_erase_block(addr+i);
                if(OP_CALLB) gige_callback(0);
                func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
            }

            execute_cmd_wds_manual();
        }
    }

    // dskim - 22.12.07 - factory map 포함 모두 지우기
    if(data == 15) {
        if(is_factory_map_mode == 1) {
            addr = FLASH_DEFECT_BASEADDR;
            length = FLASH_DEFECT_LEN;
            for (i = 0; i < length; i += interval){
                flash_erase_block(addr+i);
                if(OP_CALLB) gige_callback(0);
                func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr+i);
            }
        }
    }

    func_printf("Finished!\r\n");
}

void execute_cmd_cddr(u32 data) {
    func_ddr_out = data;

    switch(data) {
        case 0 :    REG(ADDR_DDR_OUT) = 0;
                    msdelay(100);
                    func_printf("0 [None]\r\n");
//                  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001;
//                  else                REG(ADDR_DDR_CH_EN) = 0b01010001;
                    REG(ADDR_DDR_CH_EN) = 0b01010001;
                    if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
                    if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
                    if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729
                    break;
        case 1 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE0, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("1 [Ref Image 0]\r\n");
                    break;
        case 2 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE1, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("2 [Ref Image 1]\r\n");
                    break;
        case 3 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE2, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("3 [Ref Image 2]\r\n");
                    break;
        case 4 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE3, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("4 [Ref Image 3]\r\n");
                    break;
        case 5 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE4, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("5 [Ref Image 4]\r\n");
                    break;
        case 6 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE5, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("6 [Ref Image 5 d2m x-ray]\r\n");
                    break;
        case 7 :    REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_AVG_DATA_DOSE6, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("7 [Ref Image 6 acc]\r\n");
                    break;
        case 8 :    REG(ADDR_DDR_OUT) = 2;
                    msdelay(100);
                    REG(ADDR_DDR_CH_EN) = 0b00100000;
                    func_printf("8 [Calib Gain Data]\r\n");
                    break;
        case 9 :    REG(ADDR_DDR_OUT) = 3;
                    msdelay(100);
                    REG(ADDR_DDR_CH_EN) = 0b00100000;
                    func_printf("9 [Calib Offset Data]\r\n");
                    break;
//      case 8 :    break;
        case 10 :   REG(ADDR_DDR_OUT) = 4;
                    msdelay(100);
                    set_ddr_raddr(ADDR_NUC_DATA, 2);
                    REG(ADDR_DDR_CH_EN) = 0b01000000;
                    func_printf("10 [DEBUGGING]\r\n");
                    break;
    }
}

#define DBG_wddr 0
void execute_cmd_wddr(u32 data, u32 level) {
//#if defined(EXT4343R) && defined(GAIN_CALIB_SAVE_NUC_PARAM) && defined(FLASH_1GBIT)
//    if(data == 5) {
//        func_printf("NUC Parameter(wddr5) cannot be used in 1GBit Flash.\r\n");
//        return;
//    }
//#endif
    u32 addr = 0, avg = 0;
    int avg_status = 0;
    REG(ADDR_FW_BUSY) = 1;
//    REG(ADDR_FW_BUSY) = 0; // test 210730

    switch(data) {
        case 0 :                                    break;
        case 1 : addr = ADDR_AVG_DATA_DOSE0; if(DBG_wddr)func_printf("[DBG_wddr] AVG DOSE 0\r\n "); break;
        case 2 : addr = ADDR_AVG_DATA_DOSE1; if(DBG_wddr)func_printf("[DBG_wddr] AVG DOSE 1\r\n ");  break;
        case 3 : addr = ADDR_AVG_DATA_DOSE2; if(DBG_wddr)func_printf("[DBG_wddr] AVG DOSE 2\r\n ");  break;
        case 4 : addr = ADDR_AVG_DATA_DOSE3; if(DBG_wddr)func_printf("[DBG_wddr] AVG DOSE 3\r\n ");  break;
        case 5 : addr = ADDR_AVG_DATA_DOSE4; if(DBG_wddr)func_printf("[DBG_wddr] AVG DOSE 4\r\n ");  break;
    }
    if(DBG_wddr)func_printf("[DBG_wddr] addr = 0x%8x\r\n",addr);
    set_ddr_waddr(addr, 2);
    set_ddr_raddr(addr, 2);

//  REG(ADDR_DDR_CH_EN) = 0b01010101;
    REG(ADDR_DDR_CH_EN) = 0b11010101; // read ch3 en 210728mbh
    if(DBG_wddr)func_printf("[DBG_wddr] func_width=%d\r\n",func_width);
    if(DBG_wddr)func_printf("[DBG_wddr] func_height=%d\r\n",func_height);
    if(DBG_wddr)func_printf("[DBG_wddr] reg_width=%d\r\n",REG(ADDR_WIDTH));
    if(DBG_wddr)func_printf("[DBG_wddr] reg_height=%d\r\n",REG(ADDR_HEIGHT));
    if(DBG_wddr)func_printf("[DBG_wddr] reg_ADDR_IMG_MODE=%d\r\n",REG(ADDR_IMG_MODE));
    if(DBG_wddr)func_printf("[DBG_wddr] reg0=%d\r\n",REG(0));
    if(DBG_wddr)func_printf("[DBG_wddr] level=%d\r\n",level);
    avg_status = get_ddr_pixel_avg(level);
    if(DBG_wddr)func_printf("[DBG_wddr] avg_status = %d\r\n",avg_status);

    if(avg_status==AVG_FAILURE) // 211207mbh
    {
        func_printf("AVG_FAILURE ! \r\n");
        set_ddr_waddr(ADDR_AVG_DATA_DOSE0, 2);
        set_ddr_raddr(ADDR_AVG_DATA_DOSE0, 2);
        REG(ADDR_FW_BUSY) = 0;
        return;
    }
    if(func_hw_debug != 1)  avg = get_ddr_frame_avg(addr, func_width, func_height);

                                  REG(ADDR_DDR_CH_EN)   = 0b01010001;
    if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
    if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
    if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729

    func_ref_num = 0;
    func_ref_avg_max = 0;

    switch(data) {
        case 0 :                                                                        break;
        case 1 :                                            func_img_avg_dose0 = avg;   break;
        case 2 :    if(avg > func_img_avg_dose0)            func_img_avg_dose1 = avg;   break;
        case 3 :    if(avg > func_img_avg_dose1)            func_img_avg_dose2 = avg;   break;
        case 4 :    if(avg > func_img_avg_dose2)            func_img_avg_dose3 = avg;   break;
        case 5 :    if(avg > func_img_avg_dose3)            func_img_avg_dose4 = avg;   break;
    }

    mpc_cal();
    if(DBG_wddr)func_printf("[DBG_wddr] mpc_cal\r\n");

    if(func_hw_debug != 1)  func_printf("Image Average = %d\r\n", avg);

    set_ddr_waddr(ADDR_AVG_DATA_DOSE0, 2);
    set_ddr_raddr(ADDR_AVG_DATA_DOSE0, 2);

    REG(ADDR_FW_BUSY) = 0;
    if(DBG_wddr)func_printf("[DBG_wddr] ADDR_FW_BUSY\r\n");

}

void execute_cmd_rddr(u32 data, u32 level) {
    u32 addr = 0, avg = 0;
    switch(data) {
        case 0 :                                    break;
        case 1 : addr = ADDR_AVG_DATA_DOSE0; if(DEBUG)func_printf(" AVG DOSE 0\r\n "); break;
        case 2 : addr = ADDR_AVG_DATA_DOSE1; if(DEBUG)func_printf(" AVG DOSE 1\r\n ");  break;
        case 3 : addr = ADDR_AVG_DATA_DOSE2; if(DEBUG)func_printf(" AVG DOSE 2\r\n ");  break;
        case 4 : addr = ADDR_AVG_DATA_DOSE3; if(DEBUG)func_printf(" AVG DOSE 3\r\n ");  break;
        case 5 : addr = ADDR_AVG_DATA_DOSE4; if(DEBUG)func_printf(" AVG DOSE 4\r\n ");  break;
        case 6 : addr = ADDR_AVG_DATA_DOSE5; if(DEBUG)func_printf(" AVG DOSE 5\r\n ");  break;
    }

    avg = get_ddr_frame_avg(addr, func_width, func_height);

    func_printf("\r\n read avg = %d \r\n ",avg);

    func_printf(" AVG DOSE 0 test %d \r\n ",func_img_avg_dose0);
    func_printf(" AVG DOSE 1 test %d \r\n ",func_img_avg_dose1);
    func_printf(" AVG DOSE 2 test %d \r\n ",func_img_avg_dose2);
    func_printf(" AVG DOSE 3 test %d \r\n ",func_img_avg_dose3);
    func_printf(" AVG DOSE 4 test %d \r\n ",func_img_avg_dose4);
    func_printf(" AVG DOSE 5 test %d \r\n ",func_img_avg_dose5);
    }

void execute_cmd_gcal(void) {
    REG(ADDR_FW_BUSY) = 1;

    if(func_img_avg_dose0 > 0 && func_ref_num > 1) {    // dskim - 21.04.06 - gain calibration 예외 처리
        execute_cmd_cdot(0);

//#if defined(GEV10G)
//        get_nuc_para4();
//#else
//        get_nuc_param();
//#endif
		if (def_gev_speed == 10)
	        get_nuc_para4();
		else
	        get_nuc_param();

        // 200924 (need to update)
        func_img_avg_old = func_img_avg_dose0;

//      if(func_defect_cnt == MAX_DEFECT) { // dskim - 21.08.18 - CsI Defect 이슈로 예외처리 해제
//          func_printf("Exceed the Max Number of Defect\r\n");
//          REG(ADDR_FW_BUSY) = 0;
//          return;
//      }
        set_calib_defect(0);

        func_check_gain_calib = 1;  // 0.xx.09
        is_load_hw_calibration = 1; // dskim - 22.09.27

    }

    REG(ADDR_FW_BUSY) = 0;
}

// 200924 (need to update)
void execute_cmd_ucal(void) {
    REG(ADDR_FW_BUSY) = 1;
    update_nuc_param();
    func_img_avg_old = func_img_avg_dose0;
    REG(ADDR_FW_BUSY) = 0;
}

void execute_cmd_sens(u32 data) {
    func_defect_sens = data;
}

void execute_cmd_dcal(u32 data) {
    REG(ADDR_FW_BUSY) = 1;

    switch(data)  {
        case 0  : get_defect_param(ADDR_AVG_DATA_DOSE0);    break;
        case 1  : get_defect_param(ADDR_AVG_DATA_DOSE1);    break;
        case 2  : get_defect_param(ADDR_AVG_DATA_DOSE2);    break;
        case 3  : get_defect_param(ADDR_AVG_DATA_DOSE3);    break;
        case 4  : get_defect_param(ADDR_AVG_DATA_DOSE4);    break;
    }

    if(func_defect_cnt == MAX_DEFECT) {
        func_printf("Exceed the Max Number of Defect\r\n");
        REG(ADDR_FW_BUSY) = 0;
        return;
    }
    set_calib_defect(0);

    REG(ADDR_FW_BUSY) = 0;
}

u32 execute_cmd_wdot(u32 pointx, u32 pointy, u32 erase) {
    // dskim - 21.03.02 - factory map
    // dskim - 22.12.07 - factory map 다시 사용하도록 변경
    if(DBGDFEC)func_printf("Defect0\r\n");
    if(is_factory_map_mode == 1) {
        if(DBGDFEC)func_printf("Defect1\r\n");
        return execute_cmd_wdot_factory(pointx, pointy, erase);
    }
    // dskim - 22.12.07 - factory map 다시 사용하도록 변경
    if(DBGDFEC)func_printf("Defect2\r\n");
    if(!erase) {
        if(DBGDFEC)func_printf("Defect3\r\n");
        if(check_same_defect(pointx, pointy, 1))    return 1;
        if(func_defect_cnt2 >= MAX_DEFECT)          return 1;   // dskim - 21.09.24
        add_calib_defect(pointx, pointy, 1);
    }
    else {
        if(DBGDFEC)func_printf("Defect4\r\n");
        // dskim - 21.09.23 - old fw 호환성을 위해서 factory 영역도 지워줌
//      if(!check_same_defect(pointx, pointy, 2)) {
        if(check_same_defect(pointx, pointy, 2)) {  // dskim - 22.09.19 - factory map 지워지지 않는 버그 수정
            erase_calib_defect_factory(pointx, pointy);
        }
        if(!check_same_defect(pointx, pointy, 1))   return 2;
        erase_calib_defect(pointx, pointy);
    }
    if(DBGDFEC)func_printf("Defect5\r\n");
    set_calib_defect(1);
    if(DBGDFEC)func_printf("Defect6\r\n");
    return 0;
}



u32 execute_cmd_wrdot(u32 row, u32 erase) {
    // dskim - 21.03.02 - factory map
    // dskim - 22.12.07 - factory map 다시 사용하도록 변경
    if(is_factory_map_mode == 1) {
        return execute_cmd_wrdot_factory(row, erase);
    }
    // dskim - 22.12.07 - factory map 다시 사용하도록 변경
    if(!erase) {
        if(check_same_rdefect(row, 0))          return 1;
        if(check_error_rdefect(row, 0))         return 1;   // dskim - 21.09.24
        if(func_rdefect_cnt >= MAX_LINE_DEFECT) return 1;   // dskim - 21.09.24
        add_calib_rdefect(row, 0);
    }
    else {
        // dskim - 21.09.23 - old fw 호환성을 위해서 factory 영역도 지워줌
        if(check_same_rdefect(row, 1))
            erase_calib_rdefect_factory(row);

        if(!check_same_rdefect(row, 0))         return 2;
        erase_calib_rdefect(row);
    }
    set_calib_rdefect();
    return 0;
}

u32 execute_cmd_wcdot(u32 col, u32 erase) {
    // dskim - 21.03.02 - factory map
    // dskim - 22.12.07 - factory map 다시 사용하도록 변경
    if(is_factory_map_mode == 1) {
        return execute_cmd_wcdot_factory(col, erase);
    }
    // dskim - 22.12.07 - factory map 다시 사용하도록 변경
    if(!erase) {
        if(check_same_cdefect(col, 0))          return 1;
        if(check_error_cdefect(col, 0))         return 1;   // dskim - 21.09.24
        if(func_cdefect_cnt >= MAX_LINE_DEFECT) return 1;   // dskim - 21.09.24
        add_calib_cdefect(col, 0);
    }
    else {
        // dskim - 21.09.23 - old fw 호환성을 위해서 factory 영역도 지워줌
        if(check_same_cdefect(col, 1))
            erase_calib_cdefect_factory(col);

        if(!check_same_cdefect(col, 0))         return 2;
        erase_calib_cdefect(col);
    }
    set_calib_cdefect();
    return 0;
}

void execute_cmd_rdot(u32 data) {
    u32 i = 0;

    switch(data) {
    case 0:
        for (i = 0; i < func_defect_cnt; i++)
            func_printf("A.(%d %d)\r\n", func_defect[i][0], func_defect[i][1]);
        break;
    case 1:
        for (i = 0; i < func_defect_cnt2; i++)
            func_printf("M.(%d %d)\r\n", func_defect2[i][0], func_defect2[i][1]);
        func_printf("----------Binning Mode Calculation----------\r\n");
        for (i = 0; i < func_defect_cnt2; i++)
            execute_cmd_rdot_binning(1, func_defect2[i][0], func_defect2[i][1]);
        func_printf("\r\n");
        for (i = 0; i < func_defect_cnt3; i++)
            func_printf("F.(%d %d)\r\n", func_defect3[i][0], func_defect3[i][1]);
        func_printf("----------Binning Mode Calculation----------\r\n");
        for (i = 0; i < func_defect_cnt3; i++)
            execute_cmd_rdot_binning(4, func_defect3[i][0], func_defect3[i][1]);
        break;
    case 2:
        for (i = 0; i < func_rdefect_cnt; i++)
            func_printf("M.Row = %d\r\n", func_rdefect[i]);
        func_printf("----------Binning Mode Calculation----------\r\n");
        for (i = 0; i < func_rdefect_cnt; i++)
            execute_cmd_rdot_binning(2, func_rdefect[i], 0);
        func_printf("\r\n");
        for (i = 0; i < func_rdefect_cnt3; i++)
            func_printf("F.Row = %d\r\n", func_rdefect3[i]);
        func_printf("----------Binning Mode Calculation----------\r\n");
        for (i = 0; i < func_rdefect_cnt3; i++)
            execute_cmd_rdot_binning(5, func_rdefect3[i], 0);

        break;
    case 3:
        for (i = 0; i < func_cdefect_cnt; i++)
            func_printf("M.Column = %d\r\n", func_cdefect[i]);
        func_printf("----------Binning Mode Calculation----------\r\n");
        for (i = 0; i < func_cdefect_cnt; i++)
            execute_cmd_rdot_binning(3, 0, func_cdefect[i]);
        func_printf("\r\n");
        for (i = 0; i < func_cdefect_cnt3; i++)
            func_printf("F.Column = %d\r\n", func_cdefect3[i]);
        func_printf("----------Binning Mode Calculation----------\r\n");
        for (i = 0; i < func_cdefect_cnt3; i++)
            execute_cmd_rdot_binning(6, 0, func_cdefect3[i]);
        break;
    default:
        break;

    }
}

void execute_cmd_frdot(u32 target, u32 num) { // 210405 mbh
    u32 read = 0;
    int i = 0;

    REG(ADDR_DEBUG_MODE) = 1; // ##### SET Debug mode

    if(target == 0){

        for (i = 0; i < num; i++){
            REG(ADDR_DEFECT_ADDR) = i;
            read = REG(ADDR_DEFECT_RDATA);
            func_printf("FPGA Read auto defect dot = %d , %d\r\n", (read>>12)&0xfff, (read)&0xfff);
        }

    }
    else if(target == 1){

        for (i = 0; i < num; i++){
            REG(ADDR_DEFECT2_ADDR) = i;
            read = REG(ADDR_DEFECT2_RDATA);
            func_printf("FPGA Read manual defect dot = %d , %d\r\n", (read>>12)&0xfff, (read)&0xfff);
        }

    }
    else if(target == 2){

        for (i = 0; i < num; i++){
            REG(ADDR_RDEFECT_ADDR) = i;
            read = REG(ADDR_RDEFECT_RDATA);
            func_printf("FPGA Read manual defect row = %d , %d\r\n", (read>>12)&0xfff, (read)&0xfff);
        }

    }
    else if(target == 3){

        for (i = 0; i < num; i++){
            REG(ADDR_CDEFECT_ADDR) = i;
            read = REG(ADDR_CDEFECT_RDATA);
            func_printf("FPGA Read manual defect column = %d , %d\r\n", (read>>12)&0xfff, (read)&0xfff);
        }

    }


    REG(ADDR_DEBUG_MODE) = 0;  // ##### CLEAR Debug mode
}

void execute_cmd_rdot_binning(u32 mode, u32 x_row, u32 y_col) {
    switch (func_binning_mode) {
        case 0 :
            break;
        case 1 :
            x_row /= 2;
            y_col /= 2;
            break;
        case 2 :
            x_row /= 2;
            y_col /= 2;
            break;
        case 3 :
            x_row /= 2;
            y_col /= 2;
            break;
        case 4 :
            x_row /= 3;
            y_col /= 3;
            break;
        case 5 :
            x_row /= 3;
            y_col /= 3;
            break;
        case 6 :
            x_row /= 4;
            y_col /= 4;
            break;
        case 7 :
            x_row /= 4;
            y_col /= 4;
            break;
    }

    if(mode == 1) {
        func_printf("M.(%d %d)\r\n", x_row, y_col);
    }
    else if (mode == 2) {
        func_printf("M.Row = %d\r\n", x_row);
    }
    else if (mode == 3) {
        func_printf("M.Column = %d\r\n", y_col);
    }
    else if (mode == 4) {
        func_printf("F.(%d %d)\r\n", x_row, y_col);
    }
    else if (mode == 5) {
        func_printf("F.Row = %d\r\n", x_row);
    }
    else if (mode == 6) {
        func_printf("F.Column = %d\r\n", y_col);
    }
}

void execute_cmd_cdot(u32 data) {
    u32 i = 0;

    switch(data) {
        case 0:
            for (i = 0; i < func_defect_cnt; i++) {
                func_defect[i][0] = 0;
                func_defect[i][1] = 0;
                REG(ADDR_DEFECT_ADDR) = i;
                REG(ADDR_DEFECT_WDATA) = 0;
                REG(ADDR_DEFECT_WEN) = 1;   // 210215 mbh
                REG(ADDR_DEFECT_WEN) = 0;   // 210215 mbh
            }
            REG(ADDR_DEFECT_WEN) = 0;
            func_defect_cnt = 0;

            break;
        case 1:
            execute_cmd_cdot_fpga(1);       // 지우고
            for (i = 0; i < func_defect_cnt2; i++) {
                func_defect2[i][0] = 0;
                func_defect2[i][1] = 0;
            }
            func_defect_cnt2 = 0;

            for (i = 0; i < func_defect_cnt3; i++) {
                func_defect3[i][0] = 0;
                func_defect3[i][1] = 0;
            }
            func_defect_cnt3 = 0;
            set_calib_defect(1);            // 다시 쓰기

            break;
        case 2:
            execute_cmd_cdot_fpga(2);       // 지우고
            for (i = 0; i < func_rdefect_cnt; i++) {
                func_rdefect[i] = 0;
            }
            func_rdefect_cnt = 0;

            for (i = 0; i < func_rdefect_cnt3; i++) {
                func_rdefect3[i] = 0;
            }
            func_rdefect_cnt3 = 0;
            set_calib_rdefect();            // 다시 쓰기
            break;
        case 3:
            execute_cmd_cdot_fpga(3);       // 지우고
            for (i = 0; i < func_cdefect_cnt; i++) {
                func_cdefect[i] = 0;
            }
            func_cdefect_cnt = 0;

            for (i = 0; i < func_cdefect_cnt3; i++) {
                func_cdefect3[i] = 0;
            }
            func_cdefect_cnt3 = 0;
            set_calib_cdefect();            // 다시 쓰기
            break;
        default:
            break;
    }
}

void execute_cmd_cdot_fpga(u32 data) {
    u32 i = 0;

    msdelay(1);     // dskim - 21.03.02 - ROI 변경떄마다 rewrite해야 한다. 약간의 딜레이를 추가함.

    if(data == 0) {
        for (i = 0; i < func_defect_cnt; i++) {
            REG(ADDR_DEFECT_ADDR) = i;
            REG(ADDR_DEFECT_WDATA) = 0x00FFFFFF; //;
            REG(ADDR_DEFECT_WEN) = 1;
            REG(ADDR_DEFECT_WEN) = 0;
        }
        REG(ADDR_DEFECT_WEN) = 0;
    }
    else if(data == 1) {    // Manual + Factory 모두 지우기
        for (i = 0; i < (func_defect_cnt2 + func_defect_cnt3); i++) {
            REG(ADDR_DEFECT2_ADDR) = i;
            REG(ADDR_DEFECT2_WDATA) = 0x00FFFFFF; // 210405 mbh
            REG(ADDR_DEFECT2_WEN) = 1;
            REG(ADDR_DEFECT2_WEN) = 0;
            if(i >= MAX_DEFECT) // 예외
                break;
        }
        REG(ADDR_DEFECT2_WEN) = 0;
    }
    else if(data == 2) {    // Manual + Factory 모두 지우기
        for (i = 0; i < (func_rdefect_cnt + func_rdefect_cnt3); i++) {
            REG(ADDR_RDEFECT_ADDR) = i;
            REG(ADDR_RDEFECT_WDATA) = 0x00FFFFFF; //;
            REG(ADDR_RDEFECT_WEN) = 1;
            REG(ADDR_RDEFECT_WEN) = 0;
            if(i >= MAX_LINE_DEFECT) // 예외
                break;
        }
        REG(ADDR_RDEFECT_WEN) = 0;
    }
    else if(data == 3) {    // Manual + Factory 모두 지우기
        for (i = 0; i < (func_cdefect_cnt + func_cdefect_cnt3); i++) {
            REG(ADDR_CDEFECT_ADDR) = i;
            REG(ADDR_CDEFECT_WDATA) = 0x00FFFFFF; //;
            REG(ADDR_CDEFECT_WEN) = 1;
            REG(ADDR_CDEFECT_WEN) = 0;
            if(i >= MAX_LINE_DEFECT) // 예외
                break;
        }
        REG(ADDR_CDEFECT_WEN) = 0;
    }
}

void execute_cmd_wroic(u32 addr, u32 data) {
    // TI_ROIC
//  func_roic_data[addr]    = data;

    // 200912
    REG(ADDR_ROIC_ADDR)     = 0;
    REG(ADDR_ROIC_WDATA)    = 0; // write mode
    REG(ADDR_ROIC_EN)       = 1;
    msdelay(1);
    REG(ADDR_ROIC_EN)       = 0;

    REG(ADDR_ROIC_ADDR)     = addr;
    REG(ADDR_ROIC_WDATA)    = data;
    REG(ADDR_ROIC_EN)       = 1;
    msdelay(1);
    REG(ADDR_ROIC_EN)       = 0;
}

u32 execute_cmd_rroic(u32 addr) {
    // TI_ROIC
//  func_roic_data[addr]    = data;

    // ykkim
//  execute_cmd_wroic(0x00, 0x0002); mbh

    // mbh
    REG(ADDR_ROIC_ADDR)     = 0;
    REG(ADDR_ROIC_WDATA)    = 2; // read mode
    REG(ADDR_ROIC_EN)       = 1;
    msdelay(1);
    REG(ADDR_ROIC_EN)       = 0;

    REG(ADDR_ROIC_ADDR)     = addr;
    REG(ADDR_ROIC_EN)       = 1;
    msdelay(1);
    REG(ADDR_ROIC_EN)       = 0;
//  func_printf("ADDR : 0x%04X\r\n", REG(ADDR_ROIC_ADDR));
//  func_printf("En1 : 0x%04X\r\n", REG(ADDR_ROIC_EN));
//  func_printf("En0 : 0x%04X\r\n", REG(ADDR_ROIC_EN));

//  func_printf("RData1 : 0x%04X\r\n", REG(ADDR_ROIC_RDATA));
//  func_printf("RData2 : 0x%04X\r\n", REG(ADDR_ROIC_RDATA));
//  func_printf("RData3 : 0x%04X\r\n", REG(ADDR_ROIC_RDATA));
//  func_printf("RData1133 : 0x%04X\r\n", REG(ADDR_ROIC_RDATA));

    return REG(ADDR_ROIC_RDATA);
}

void execute_cmd_mac(u32 addr_h, u32 addr_l) {
    XREG(XGIGE_ADDR_MAC_H) = addr_h;
    XREG(XGIGE_ADDR_MAC_L) = addr_l;
    eeprom_write_word(EEPROM_ADDR_MAC, addr_h);
    eeprom_write_dword(EEPROM_ADDR_MAC+2, addr_l);
}

void execute_cmd_ip(u32 data0, u32 data1, u32 data2, u32 data3) {
    u32 data = ((data0 << 24) | (data1 << 16) | (data2 << 8) | data3);
    XREG(XGIGE_ADDR_IP) = data;
    eeprom_write_dword(EEPROM_ADDR_IP, data);
}

void execute_cmd_smask(u32 data0, u32 data1, u32 data2, u32 data3) {
    u32 data = ((data0 << 24) | (data1 << 16) | (data2 << 8) | data3);
    eeprom_write_dword(EEPROM_ADDR_SUBNET, data);
}

void execute_cmd_gate(u32 data0, u32 data1, u32 data2, u32 data3) {
    u32 data = ((data0 << 24) | (data1 << 16) | (data2 << 8) | data3);
    eeprom_write_dword(EEPROM_ADDR_GATEWAY, data);
}

void execute_cmd_ipmode(u32 data) {
    eeprom_write_byte(EEPROM_ADDR_IPMODE, (data & 0xFF));

    switch (data) {
        case 1: func_printf("1 [Static IP]\r\n");           break;
        case 2: func_printf("2 [DHCP]\r\n");                    break;
        case 3: func_printf("3 [Static IP->DHCP]\r\n");     break;
        case 4: func_printf("4 [LLA]\r\n");                 break;
        case 5: func_printf("5 [Static IP->LLA]\r\n");      break;
        case 6: func_printf("6 [DHCP->LLA]\r\n");           break;
        case 7: func_printf("7 [Static IP->DHCP->LLA]\r\n");    break;
    }
}

void execute_cmd_intrst(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_roic_intrst = data / 1000.0;
    REG(ADDR_ROIC_INTRST) = MCLK_MHz * func_roic_intrst;
}

void execute_cmd_cds1(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_roic_cds1 = data / 1000.0;
    REG(ADDR_ROIC_CDS1) = MCLK_MHz * func_roic_cds1;
}

void execute_cmd_cds2(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_roic_cds2 = data / 1000.0;
    REG(ADDR_ROIC_CDS2) = MCLK_MHz * func_roic_cds2;
}

// TI_ROIC
//void execute_cmd_fa(u32 data) {
//  u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
//  func_roic_fa = data / 1000.0;
//  if(func_roic_fa >= func_roic_cds) func_roic_fa = func_roic_cds - 1;
//  REG(ADDR_ROIC_FA) = MCLK_MHz * func_roic_fa;
//}
void execute_cmd_fa1(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_roic_fa1 = data / 1000.0;
    if(func_roic_fa1 >= func_roic_cds1) func_roic_fa1 = func_roic_cds1 - 1;
//  REG(ADDR_ROIC_FA) = MCLK_MHz * func_roic_fa;
}

void execute_cmd_fa2(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_roic_fa2 = data / 1000.0;
    if(func_roic_fa2 >= func_roic_cds2) func_roic_fa2 = func_roic_cds2 - 1;
//  REG(ADDR_ROIC_FA) = MCLK_MHz * func_roic_fa;
}


// TI_ROIC
//void execute_cmd_dead(u32 data) {
//  u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
//  func_roic_dead = data / 1000.0;
//  REG(ADDR_ROIC_DEAD) = MCLK_MHz * func_roic_dead;
//}

// TI_ROIC
//void execute_cmd_mute(u32 data) {
//  u32 MCLK_MHz = FPGA_TFT_DATA_CLK / 1000000;
//  func_roic_mute = data / 1000.0;
//  REG(ADDR_ROIC_MUTE) = MCLK_MHz * func_roic_mute;
//}

void execute_cmd_oe(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_gate_oe = data / 1000.0;
    REG(ADDR_GATE_OE) = MCLK_MHz * func_gate_oe;
}

void execute_cmd_xon(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_gate_xon = data / 1000.0;
    REG(ADDR_GATE_XON) = MCLK_MHz * func_gate_xon;
}

void execute_cmd_flk(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_gate_flk = data / 1000.0;
    REG(ADDR_GATE_FLK) = MCLK_MHz * func_gate_flk;
}

void execute_cmd_xonflk(u32 data) {
    u32 MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000;
    func_gate_xonflk = data / 1000.0;
    REG(ADDR_GATE_XON_FLK) = MCLK_MHz * func_gate_xonflk;
}

void execute_cmd_rcycle(u32 data) {
    u32 MCLK_KHz = FPGA_TFT_MAIN_CLK / 1000;
    func_gate_rcycle = data / 1000.0;
    REG(ADDR_GATE_RST_CYCLE) = MCLK_KHz * func_gate_rcycle;
}

void execute_cmd_crmode(u32 data) {
    func_gate_crmode = data;
    REG(ADDR_RST_MODE) = (func_gate_srmode << 1) | func_gate_crmode;
}

void execute_cmd_srmode(u32 data, u32 num) {
    func_gate_srmode = data;
    REG(ADDR_RST_MODE) = (func_gate_srmode << 1) | func_gate_crmode;
    if(data == 0)   {
        func_gate_rnum      = num;
        REG(ADDR_RST_NUM)   = func_gate_rnum;
    }
    else {
        func_sexp_time      = num;
        REG(ADDR_SEXP_TIME) = func_sexp_time;
    }
}

void execute_cmd_tseq(u32 data) {
    func_tft_seq = data;
    REG(ADDR_TIMING_MODE) = func_tft_seq;
}

void execute_cmd_timg(u32 data) {
    u32 i, j;
    u32 flash_start_addr = FLASH_IMG_BASEADDR;
    u32 flash_addr = 0;
    u32 flash_data = 0;
    u32 ddr_start_addr = 0;
    u32 ddr_addr = 0;
    u32 ddr_data0 = 0;
    u32 ddr_data1 = 0;

    u32 addr = 0, avg = 0;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    switch (data) {
        case 0 :                                        break;
        case 1 : ddr_start_addr = ADDR_AVG_DATA_DOSE0;  break;
        case 2 : ddr_start_addr = ADDR_AVG_DATA_DOSE1;  break;
        case 3 : ddr_start_addr = ADDR_AVG_DATA_DOSE2;  break;
        case 4 : ddr_start_addr = ADDR_AVG_DATA_DOSE3;  break;
        case 5 : ddr_start_addr = ADDR_AVG_DATA_DOSE4;  break;
    }

    func_printf("\r\nTransfer Image Data from Flash Memory to DDR3\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for (i = 0; i < func_height; i++) {
        flash_addr = flash_start_addr + (i * func_width * 2);
        ddr_addr = ddr_start_addr + (i * width_x32 * 4);
        for (j = 0; j < (func_width / 2); j++) {
            flash_data = flash_read_dword(flash_addr);
            flash_addr += 4;
            ddr_data0 = (flash_data & 0xFF000000) >> 24;
            ddr_data1 = (flash_data & 0x00FF0000) >> 16;
            DREG(ddr_addr) = (ddr_data1 << 24) | (ddr_data0 << 16);
            ddr_addr += 4;
            ddr_data0 = (flash_data & 0x0000FF00) >> 8;
            ddr_data1 = (flash_data & 0x000000FF);
            DREG(ddr_addr) = (ddr_data1 << 24) | (ddr_data0 << 16);
            ddr_addr += 4;
        }
        if(!(i % (func_height / 32)))  func_printf("*");
        gige_callback(0);
    }

    switch(data) {
        case 0 :                                    break;
        case 1 : addr = ADDR_AVG_DATA_DOSE0;        break;
        case 2 : addr = ADDR_AVG_DATA_DOSE1;        break;
        case 3 : addr = ADDR_AVG_DATA_DOSE2;        break;
        case 4 : addr = ADDR_AVG_DATA_DOSE3;        break;
        case 5 : addr = ADDR_AVG_DATA_DOSE4;        break;
    }

    avg = get_ddr_frame_avg(addr, func_width, func_height);

    func_ref_num = 0;
    func_ref_avg_max = 0;

    switch(data) {
        case 0 :                                                                        break;
        case 1 :                                            func_img_avg_dose0 = avg;   break;
        case 2 :    if(avg > func_img_avg_dose0)            func_img_avg_dose1 = avg;   break;
        case 3 :    if(avg > func_img_avg_dose1)            func_img_avg_dose2 = avg;   break;
        case 4 :    if(avg > func_img_avg_dose2)            func_img_avg_dose3 = avg;   break;
        case 5 :    if(avg > func_img_avg_dose3)            func_img_avg_dose4 = avg;   break;
    }

    mpc_cal();

    func_printf("Image Average = %d\r\n", avg);
    func_printf("Finished!\r\n");
}

void execute_cmd_rclk()
{
func_printf("REAL Mclk= %d.%d \t Dclk= %d.%d \t Roic Dclk= %d.%d  \t DDR uiclk= %d.%d \r\n" \
        , REG(ADDR_CLK_MCLK)/100, REG(ADDR_CLK_MCLK)%100 \
        , REG(ADDR_CLK_DCLK)/100, REG(ADDR_CLK_DCLK)%100 \
        , REG(ADDR_CLK_ROICDCLK)/100, REG(ADDR_CLK_ROICDCLK)%100 \
        , REG(ADDR_CLK_UICLK)/100, REG(ADDR_CLK_UICLK)%100 \
		);
//bw_align(); // mbh 210330
}

void execute_cmd_diag(u32 data)
{

    if (data==0){

    func_printf("################### \r\n");
    func_printf("##### Version ##### \r\n");
    //# Version 230630
    gige_print_header();
	disp_cmd_dver();
	disp_cmd_fver();
	disp_cmd_fmodel();
	disp_cmd_hwver();

    func_printf("\r\n");
    func_printf("################ \r\n");
    func_printf("##### FPGA ##### \r\n");
    func_printf("\tGegEV Out En  = ");  execute_cmd_fpgajudge(ADDR_OUT_EN, 1, 1);
    func_printf("\tVideo Width   = ");  execute_cmd_fpgajudge(ADDR_WIDTH, MAX_WIDTH-1, MAX_WIDTH+1);
    func_printf("\tVideo HEIGHT  = ");  execute_cmd_fpgajudge(ADDR_HEIGHT, MAX_HEIGHT-1, MAX_HEIGHT+1);
    func_printf("\tVideo OffsetX = ");  execute_cmd_fpgajudge(ADDR_OFFSETX, 0, 0);
    func_printf("\tVideo OffsetY = ");  execute_cmd_fpgajudge(ADDR_OFFSETY, 0, 0);
    func_printf("\tGrab En       = ");  execute_cmd_fpgajudge(ADDR_GRAB_EN, 1, 1);
    func_printf("\tGate En       = ");  execute_cmd_fpgajudge(ADDR_GATE_EN, 1, 1);
    func_printf("\tImage mode    = ");  execute_cmd_fpgajudge(ADDR_IMG_MODE, 0, 0);
    func_printf("\tNUC offset    = ");  execute_cmd_fpgajudge(ADDR_OFFSET_CAL, 1, 1);
    func_printf("\tNUC gain      = ");  execute_cmd_fpgajudge(ADDR_GAIN_CAL, 1, 1);
    disp_cmd_acc();
    disp_cmd_dnr();
    func_printf("##### FPGA-ROIC Time ##### \r\n");
    func_printf("\tROIC INTRST   = ");  execute_cmd_fpgajudge(ADDR_ROIC_INTRST, 1, 1);
    func_printf("\tROIC CD1      = ");  execute_cmd_fpgajudge(ADDR_ROIC_CDS1, 1, 1);
    func_printf("\tROIC CD2      = ");  execute_cmd_fpgajudge(ADDR_ROIC_CDS2, 1, 1);
    func_printf("\tROIC DEAD     = ");  execute_cmd_fpgajudge(ADDR_ROIC_DEAD, 1, 1);
    func_printf("\tROIC MUTE     = ");  execute_cmd_fpgajudge(ADDR_ROIC_MUTE, 1, 1);
    func_printf("##### FPGA-GATE Time ##### \r\n");
    func_printf("\tGATE OE       = ");  execute_cmd_fpgajudge(ADDR_GATE_OE, 1, 1);
    func_printf("\tGATE XON      = ");  execute_cmd_fpgajudge(ADDR_GATE_XON, 1, 1);
    func_printf("\tGATE XON_FLK  = ");  execute_cmd_fpgajudge(ADDR_GATE_XON_FLK, 1, 1);
    func_printf("\tGATE FLK      = ");  execute_cmd_fpgajudge(ADDR_GATE_FLK, 1, 1);
    func_printf("##### FPGA-FRAME Time ##### \r\n");
    func_printf("\tFrame Time    = ");  execute_cmd_fpgajudge(ADDR_FRAME_TIME, 1, 1);
    func_printf("\tLine Time     = ");  execute_cmd_fpgajudge(ADDR_LINE_TIME, 1, 1);
    func_printf("##### FPGA-DDR ##### \r\n");
    func_printf("\tDDR CH EN     = ");  func_printf("Write Roic = %d ", REG(ADDR_DDR_CH_EN)>>0 & 1);
                                        func_printf("NUC = %d",         REG(ADDR_DDR_CH_EN)>>1 & 1);
                                        func_printf("AVG = %d \r\n",        REG(ADDR_DDR_CH_EN)>>2 & 1);
                                        func_printf("\t\t\t");
                                        func_printf("Read Roic = %d ",  REG(ADDR_DDR_CH_EN)>>4 & 1);
                                        func_printf("NUC = %d",         REG(ADDR_DDR_CH_EN)>>5 & 1);
                                        func_printf("AVG = %d \r\n",        REG(ADDR_DDR_CH_EN)>>6 & 1);
    func_printf("\tDDR BASE           =");  func_printf("0x%08x\r\n",REG(ADDR_DDR_BASE_ADDR));
    func_printf("\tDDR CH0 W ADDR     =");  func_printf("0x%08x\r\n",REG(ADDR_DDR_CH0_WADDR));
    func_printf("\tDDR CH0 R ADDR ROIC=");  func_printf("0x%08x\r\n",REG(ADDR_DDR_CH0_RADDR));
    func_printf("\tDDR CH1 R ADDR NUC =");  func_printf("0x%08x\r\n",REG(ADDR_DDR_CH1_RADDR));
    func_printf("\tDDR CH2 R ADDR AVG =");  func_printf("0x%08x\r\n",REG(ADDR_DDR_CH2_RADDR));
    func_printf("\r\n");

    func_printf("##################### \r\n");
    func_printf("##### bit align ##### \r\n");
    execute_cmd_bcal_rdata();
    func_printf("\r\n");
    }
    func_printf("################# \r\n");
    func_printf("##### video ##### \r\n");
    func_printf("\t                     ___HCnt__VCnt_Frame__avg___cent____max___low\r\n");
    func_printf("\tTI_TFT-DATA_ALIGN OUT::"); execute_cmd_read_video(ADDR_SYNC_RCNT0,ADDR_SYNC_RDATA_AVCN0,ADDR_SYNC_RDATA_BGLW0);
    func_printf("\tTI_TFT-ROI_PROC OUT  ::"); execute_cmd_read_video(ADDR_SYNC_RCNT1,ADDR_SYNC_RDATA_AVCN1,ADDR_SYNC_RDATA_BGLW1);
    func_printf("\tTI_TFT-TP OUT        ::"); execute_cmd_read_video(ADDR_SYNC_RCNT2,ADDR_SYNC_RDATA_AVCN2,ADDR_SYNC_RDATA_BGLW2); 
    func_printf("\tDDR3 OUT             ::"); execute_cmd_read_video(ADDR_SYNC_RCNT3,ADDR_SYNC_RDATA_AVCN3,ADDR_SYNC_RDATA_BGLW3); 
    func_printf("\tCALIV-TPC OUT        ::"); execute_cmd_read_video(ADDR_SYNC_RCNT4,ADDR_SYNC_RDATA_AVCN4,ADDR_SYNC_RDATA_BGLW4); 
    func_printf("\tCALIV-DGAIN OUT      ::"); execute_cmd_read_video(ADDR_SYNC_RCNT5,ADDR_SYNC_RDATA_AVCN5,ADDR_SYNC_RDATA_BGLW5); 
    func_printf("\tCALIV-Dot DFEC01 OUT ::"); execute_cmd_read_video(ADDR_SYNC_RCNT6,ADDR_SYNC_RDATA_AVCN6,ADDR_SYNC_RDATA_BGLW6); 
    func_printf("\tCALIB-Line DFEC OUT  ::"); execute_cmd_read_video(ADDR_SYNC_RCNT7,ADDR_SYNC_RDATA_AVCN7,ADDR_SYNC_RDATA_BGLW7); 
    func_printf("\tIMG PROC             ::"); execute_cmd_read_video(ADDR_SYNC_RCNT8,ADDR_SYNC_RDATA_AVCN8,ADDR_SYNC_RDATA_BGLW8); 
    func_printf("\tIMG OUT              ::"); execute_cmd_read_video(ADDR_SYNC_RCNT9,ADDR_SYNC_RDATA_AVCN9,ADDR_SYNC_RDATA_BGLW9); 

    func_printf("\r\n");
    func_printf("################# \r\n");
    func_printf("##### clock ##### \r\n");
    func_printf("\t");
    execute_cmd_rclk();

}


void execute_cmd_fpgajudge(u32 addr, u32 truedown, u32 trueup)
{

//    if( truedown <= REG(addr) && REG(addr) <= trueup )
//    {
//        func_printf("\033[32m"); // green
//        func_printf("%d", REG(addr));
//        func_printf("\033[0m \r\n"); // default
//    }
//    else
//    {
//        func_printf("\033[31m"); // RED
//        func_printf("%d", REG(addr));
//        func_printf("\033[0m \r\n"); // default
//    }

	//# no color 230630
    func_printf("%d", REG(addr));
    func_printf("\r\n"); // default
}

void execute_cmd_read_video(u32 cnt_addr, u32 avcn_addr, u32 bglw_addr)
{
   u32 cnt = REG(cnt_addr); // read cnt register
   u16 hcnt = cnt  & 0xFFF;
//   u16 hdead = (cnt >>15) & 1;
   u16 vcnt = (cnt >>12) & 0xFFF;
//   u16 vdead = (cnt >>31) & 1;
   u16 frame = (cnt >>24) & 0xFF;
   //#### 230515 for high frame
   	   if( (frame>>7)&1 ) //# if msb is 1
   		   frame = (frame & 0x7F) * 8;
   //###
   u32 avcn = REG(avcn_addr);
   u16 avg  = (avcn >>16) & 0xFFFF;
   u16 cen  = avcn  & 0xFFFF;
   u32 bglw = REG(bglw_addr);
   u16 big  = (bglw >>16) & 0xFFFF;
   u16 low = bglw  & 0xFFFF;

        func_printf("%5d ", hcnt);
        func_printf("%5d ", vcnt);
        func_printf("%5d ", frame);
        func_printf("%5d ", avg);
        func_printf("%5d ", cen); // data
        func_printf("%5d ", big); // data
        func_printf("%5d ", low); // data
        func_printf("\r\n");
}

void execute_cmd_rtimingprofile()
{
    u32 IRST_r, SHR_r , SHS_r , LPF1_r, LPF2_r, TDEF_r, GATE_r = 0;
    u32 IRST_f, SHR_f , SHS_f , LPF1_f, LPF2_f, TDEF_f, GATE_f = 0;
    IRST_r = execute_cmd_rroic(0x40)>>8;
     SHR_r = execute_cmd_rroic(0x42)>>8;
     SHS_r = execute_cmd_rroic(0x43)>>8;
    LPF1_r = execute_cmd_rroic(0x46)>>8;
    LPF2_r = execute_cmd_rroic(0x47)>>8;
    TDEF_r = execute_cmd_rroic(0x4A)>>8;
    GATE_r = execute_cmd_rroic(0x4B)>>8;
    IRST_f = execute_cmd_rroic(0x40) & 0x00FF;
     SHR_f = execute_cmd_rroic(0x42) & 0x00FF;
     SHS_f = execute_cmd_rroic(0x43) & 0x00FF;
    LPF1_f = execute_cmd_rroic(0x46) & 0x00FF;
    LPF2_f = execute_cmd_rroic(0x47) & 0x00FF;
    TDEF_f = execute_cmd_rroic(0x4A) & 0x00FF;
    GATE_f = execute_cmd_rroic(0x4B) & 0x00FF;

    func_printf("ROIC 0x40 IRST:%2x%2x %3d~%3d \t",IRST_r,IRST_f,IRST_r,IRST_f);  execute_cmd_tp_graph(IRST_r,IRST_f);
    func_printf("ROIC 0x42 SHR :%2x%2x %3d~%3d \t", SHR_r, SHR_f, SHR_r, SHR_f);  execute_cmd_tp_graph( SHR_r, SHR_f);
    func_printf("ROIC 0x46 LPF1:%2x%2x %3d~%3d \t",LPF1_r,LPF1_f,LPF1_r,LPF1_f);  execute_cmd_tp_graph(LPF1_r,LPF1_f);
//  func_printf("ROIC 0x4B GATE:%2x%2x %3d~%3d \t",GATE_r,GATE_f,GATE_r,GATE_f);  execute_cmd_tp_graph(GATE_r,GATE_f);
    func_printf("ROIC 0x43 SHS :%2x%2x %3d~%3d \t", SHS_r, SHS_f, SHS_r, SHS_f);  execute_cmd_tp_graph( SHS_r, SHS_f);
    func_printf("ROIC 0x47 LPF2:%2x%2x %3d~%3d \t",LPF2_r,LPF2_f,LPF2_r,LPF2_f);  execute_cmd_tp_graph(LPF2_r,LPF2_f);
    func_printf("\r\n");
//  func_printf("Read 0x4A TDEF: %d~%d \t",TDEF_r,TDEF_f);  execute_cmd_tp_graph(TDEF_r,TDEF_f);
}

void execute_cmd_gtimingprofile()
{
    u32 IRST, CDS1 , CDS2 , GATE = 0;
    u32 IRST_r, CDS1_r , CDS2_r , GATE_r = 0;
    u32 IRST_f, CDS1_f , CDS2_f , GATE_f = 0;
    IRST = REG(ADDR_ROIC_INTRST)-1;
    CDS1 = REG(ADDR_ROIC_CDS1)-1;
    CDS2 = REG(ADDR_ROIC_CDS2)-1;
    GATE = REG(ADDR_GATE_OE)-1;
    IRST_r = 1;
    IRST_f = IRST_r + IRST;
    CDS1_r = IRST_f + 1 + 1; // gate_open 1 clk
    CDS1_f = CDS1_r + CDS1;
    CDS2_r = CDS1_f + 1;
    CDS2_f = CDS2_r + CDS2;
    GATE_r = CDS1_f + 1;
    GATE_f = GATE_r + GATE;

    func_printf("FPGA 0x54 IRST:%3d %3d~%3d \t",IRST,IRST_r,IRST_f);  execute_cmd_tp_graph(IRST_r,IRST_f);
    func_printf("FPGA 0x4C CDS1:%3d %3d~%3d \t",CDS1,CDS1_r,CDS1_f);  execute_cmd_tp_graph(CDS1_r,CDS1_f);

    func_printf("FPGA 0x58 GATE:%3d %3d~%3d \t",GATE,GATE_r,GATE_f);
//    func_printf("\033[33m"); // yellow
    execute_cmd_tp_graph(GATE_r,GATE_f);
//    func_printf("\033[0m"); // default
    func_printf("FPGA 0x7C CDS2:%3d %3d~%3d \t",CDS2,CDS2_r,CDS2_f);  execute_cmd_tp_graph(CDS2_r,CDS2_f);
    func_printf("\r\n");
}

void execute_cmd_atimingprofile()
{
    // ### read ROIC reg
    u32 IRST_r, SHR_r , SHS_r , LPF1_r, LPF2_r, TDEF_r, GATE_r = 0;
    u32 IRST_f, SHR_f , SHS_f , LPF1_f, LPF2_f, TDEF_f, GATE_f = 0;
    // ### read FPGA reg
    u32 F_IRST  , F_CDS1   , F_CDS2   , F_GATE   = 0;
    u32 F_IRST_r, F_CDS1_r , F_CDS2_r , F_GATE_r = 0;
    u32 F_IRST_f, F_CDS1_f , F_CDS2_f , F_GATE_f = 0;
    F_IRST = REG(ADDR_ROIC_INTRST)-1;
    F_CDS1 = REG(ADDR_ROIC_CDS1)-1;
    F_CDS2 = REG(ADDR_ROIC_CDS2)-1;
    F_GATE = REG(ADDR_GATE_OE)-1;
    F_IRST_r = 1;
    F_IRST_f = F_IRST_r + F_IRST;
    F_CDS1_r = F_IRST_f + 1 + 1; // gate_open 1 clk
    F_CDS1_f = F_CDS1_r + F_CDS1;
    F_CDS2_r = F_CDS1_f + 1;
    F_CDS2_f = F_CDS2_r + F_CDS2;
    F_GATE_r = F_CDS1_f + 1;
    F_GATE_f = F_GATE_r + F_GATE;

    //$ 3256 timing
    if(AFE3256_series){
    	u32 N_irst, N_shr, N_shs, N_lpf, N_shr_lpf1, N_shs_lpf2, N_gate;
    	N_irst 		= REG(ADDR_ROIC_INTRST);
    	N_shr  		= REG(ADDR_ROIC_CDS1  );
    	N_shs  		= REG(ADDR_ROIC_CDS2  );
    	N_gate		= REG(ADDR_GATE_OE	  );
    	N_lpf       = execute_cmd_rroic(0x3E) & 0x3FF;
    	N_shr_lpf1 = N_shr - N_lpf;
    	N_shs_lpf2 = N_shs - N_lpf;

    	IRST_r = 1;
    	IRST_f = IRST_r + N_irst;
    	SHR_r  = IRST_f + 1;
    	SHR_f  = SHR_r  + N_shr;
    	LPF1_r = SHR_r  + N_shr_lpf1;
    	LPF1_f = SHR_f;
    	SHS_r  = SHR_f  + 1;
    	SHS_f  = SHS_r  + N_shs;
    	LPF2_r = SHS_r  + N_shs_lpf2;
    	LPF2_f = SHS_f;

    	GATE_r = SHR_f + 1;
    	GATE_f = GATE_r + N_gate;

    	func_printf("ROIC 0x3A IRST:%3d %3d~%3d \t",N_irst,IRST_r,IRST_f);  	execute_cmd_tp_graph(IRST_r,IRST_f);
        func_printf("ROIC 0x3B SHR :%3d %3d~%3d \t",N_shr, SHR_r, SHR_f );  	execute_cmd_tp_graph( SHR_r, SHR_f);
        func_printf("ROIC 0x3E LPF1:%3d %3d~%3d \t",N_lpf ,LPF1_r,LPF1_f);  	execute_cmd_tp_graph(LPF1_r,LPF1_f);
        func_printf("FPGA 0x58 GATE:%3d %3d~%3d \t",N_gate,GATE_r,GATE_f );		execute_cmd_tp_graph(GATE_r,GATE_f);
        func_printf("ROIC 0x3D SHS :%3d %3d~%3d \t",N_shs, SHS_r, SHS_f );  	execute_cmd_tp_graph( SHS_r, SHS_f);
        func_printf("ROIC 0x3E LPF2:%3d %3d~%3d \t",N_lpf ,LPF2_r,LPF2_f);  	execute_cmd_tp_graph(LPF2_r,LPF2_f);
        func_printf("\r\n");
    }
    else{
        IRST_r = execute_cmd_rroic(0x40)>>8;
         SHR_r = execute_cmd_rroic(0x42)>>8;
         SHS_r = execute_cmd_rroic(0x43)>>8;
        LPF1_r = execute_cmd_rroic(0x46)>>8;
        LPF2_r = execute_cmd_rroic(0x47)>>8;
        IRST_f = execute_cmd_rroic(0x40) & 0x00FF;
         SHR_f = execute_cmd_rroic(0x42) & 0x00FF;
         SHS_f = execute_cmd_rroic(0x43) & 0x00FF;
        LPF1_f = execute_cmd_rroic(0x46) & 0x00FF;
        LPF2_f = execute_cmd_rroic(0x47) & 0x00FF;

        func_printf("ROIC 0x40 IRST:%2x%2x %3d~%3d \t",IRST_r,IRST_f,IRST_r,IRST_f);  execute_cmd_tp_graph(IRST_r,IRST_f);
        func_printf("ROIC 0x42 SHR :%2x%2x %3d~%3d \t", SHR_r, SHR_f, SHR_r, SHR_f);  execute_cmd_tp_graph( SHR_r, SHR_f);
        func_printf("ROIC 0x46 LPF1:%2x%2x %3d~%3d \t",LPF1_r,LPF1_f,LPF1_r,LPF1_f);  execute_cmd_tp_graph(LPF1_r,LPF1_f);
//    	func_printf("\033[33m"); // yellow
        func_printf("FPGA 0x58 GATE:%3d %3d~%3d \t",F_GATE,F_GATE_r,F_GATE_f);       execute_cmd_tp_graph(F_GATE_r,F_GATE_f);
//    	func_printf("\033[0m"); // default
        func_printf("ROIC 0x43 SHS :%2x%2x %3d~%3d \t", SHS_r, SHS_f, SHS_r, SHS_f);  execute_cmd_tp_graph( SHS_r, SHS_f);
        func_printf("ROIC 0x47 LPF2:%2x%2x %3d~%3d \t",LPF2_r,LPF2_f,LPF2_r,LPF2_f);  execute_cmd_tp_graph(LPF2_r,LPF2_f);
        func_printf("\r\n");
    }
}

void execute_cmd_tp_graph(u32 rising,u32 falling)
{
    u32 apdi = 0;
    u32 div = 4;
    u32 rise = rising / div;
    u32 fall = falling / div;
    u32 end = 256 / div;
    /* ERR */ if (falling < rising)
    {
        func_printf("ERR: graph error bigger rising \r\n");
        return;
    }

    u32 mclk = REG(ADDR_CLK_MCLK); // read real mclk
    u32 nclk = 100000/mclk;

    for(u32 i=0; i<rise; i++)
        func_printf(" ");
    for(u32 i=0; i<fall-rise; i++)
        func_printf("_");
    for(u32 i=0; i<end-fall; i++)
        {func_printf(" ");}
    
        func_printf("\r\n");
        func_printf("                               ");

    for(u32 i=0; i<rise; i++)
        {func_printf("_");}
        func_printf("|");
    for(u32 i=0; i<fall-rise; i++)
        {func_printf(" ");}
        func_printf("|");
    for(u32 i=0; i<end-fall; i++)
        {func_printf("_");}

        func_printf("\r\n");
        func_printf("                            ");

    for(u32 i=0; i<rise; i++)
        {func_printf(" ");}
        func_printf("%3d",rising);

    if ( 14 < fall-rise )
        apdi = ((fall-rise)-14)/2;
    else
        apdi = 1;

    for(u32 i=0; i<apdi; i++) // ap
            {func_printf(" ");}

        func_printf("~%d.%3dus,%d~",(falling-rising)*nclk/1000,(falling-rising)*nclk%1000,(falling-rising));

    for(u32 i=0; i<apdi; i++) // di
            {func_printf(" ");}

        func_printf("%3d",falling);

        func_printf("\r\n");
        func_printf("\r\n");
}


const char tstate_tft[16][10] = {
    {"IDLE"},   // 0
    {"TRST"},   // 1
    {"SRST"},   // 2
    {"EWT"},    // 3
    {"SCAN"},   // 4
    {"FINISH"}, // 5
    {"GRST"},   // 6
    {"RstFIN"}, // 7
    {"ScFrWa"}, // 8
    {"RsFrWa"}, // 9
	{"a"},      // A
	{"b"},      // B
	{"c"},      // C
	{"d"},      // D
	{"Trig !"}, // E
	{"f"},      // F
};
const char tstate_roic[9][10] = {
    {"IDLE"},
    {"OFFSET"},
    {"DUMMY"},
    {"INTRST"},
    {"CDS1"},
    {"GaOpen"},
    {"CDS2"},
    {"LDEAD"},
    {"FWAIT"},
};
const char tstate_gate[13][10] = {
    {"IDLE"},
    {"DUMMY"},
    {"READY"},
    {"DIO_CPV"},
    {"CPV"},
    {"XON"},
    {"OE"},
    {"XON_FLK"},
    {"FLK"},
    {"CHECK"},
    {"OE_READY"},
    {"LWAIT"},
    {"FWAIT"},
};
const char tstate_roic_set[6][10] = {
    {"s_IDLE  "},
    {"s_READY "},
    {"s_CS,   "},
    {"s_DATA  "},
    {"s_WAIT  "},
    {"s_FINISH"},
};
const char tstate_data_align[6][12] = {
    {"s_IDLE     "},
    {"s_READY    "},
    {"s_WAIT_ODD "},
    {"s_DATA_ODD "},
    {"s_WAIT_EVEN"},
    {"s_DATA_EVEN"},
};
const char tstate_roi[3][10] = {
    {"s_IDLE"},
    {"s_WAIT"},
    {"s_DATA"},
};

const char tstate_avg [7][10] = { 
    {"s_IDLE"},
    {"s_FWAIT"},
    {"s_LWAIT"},
    {"s_WAIT"},
    {"s_READY"},
    {"s_AVG"},
    {"s_CHECK"},
};

const char tstate_grab[3][10] = { 
    {"s_IDLE"},
    {"s_DATA"},
    {"s_WAIT"},
};

void execute_cmd_bcal_rdata()
{
    u32 keep = 0;
    u32 data = 0;
    keep = REG(ADDR_BCAL_CTRL);
    func_printf("\t ___eye_start___mid___end__pass \r\n");
//  func_printf("ROIC_NUM= %d \r\n",ROIC_NUM);
//  func_printf("ROIC_NUM= %d \r\n", ((float)(1648 / 236 + 0.499) * 1000) );
//  func_printf("ROIC_NUM= %d \r\n", (int)((float)(1648 / 236 + 0.499) * 1000) );
    for(u32 i=0; i<ROIC_NUM; i++){
        REG(ADDR_BCAL_CTRL) = keep + i;
        msdelay(10);
        data = REG(ADDR_BCAL_DATA);
        func_printf("\troic(%2d)= %4d, %4d, %4d ", i, data&0xff, (data>>8)&0xff, (data>>16)&0xff );
        if((data>>24) & 1)
            func_printf("success \r\n");
        else
            func_printf("error \r\n");
    }
    REG(ADDR_BCAL_CTRL) = keep; // value return
}

void execute_cmd_wsm(u32 time100ms)
{
/*  -- ##### Write reg #####
      -- ### (0)     : Read Enable
      -- ### (1)     : Read Trigger
      -- ### (2)     : Read data "Page" 32bit selection
      -- ### (31:16) : write time
*/
    // --------------------------------- sm ready set 
    if(time100ms == 0) {
        REG(ADDR_SM_CTRL) = 0; // clear
        return;
    }
    else
        REG(ADDR_SM_CTRL) = 1; 
    // --------------------------------- write time set 
    REG(ADDR_SM_CTRL) = ((time100ms & 0xFFFF) << 16) | 1; 
}

void execute_cmd_rsm(u32 smsel)
{
    u32 addrsel;
    u32 data;
    u32 stopped, datacnt;
    u32 writecnt;

    u32 readreg;
    u32 keepreadreg;
    u8  sm;
    u32 smcnt;
    u32 smtime;
    u32 smtimeint;
    u32 smtimefrac;

    keepreadreg = REG(ADDR_SM_CTRL);
    readreg = keepreadreg + (smsel<<4);
    REG(ADDR_SM_CTRL) = readreg;
    switch(smsel){
    case 0 : addrsel=ADDR_SM_DATA0; break;
    case 1 : addrsel=ADDR_SM_DATA1; break;
    case 2 : addrsel=ADDR_SM_DATA2; break;
    case 3 : addrsel=ADDR_SM_DATA3; break;
    case 4 : addrsel=ADDR_SM_DATA4; break;
    case 5 : addrsel=ADDR_SM_DATA5; break;
    case 6 : addrsel=ADDR_SM_DATA6; break;
    case 7 : addrsel=ADDR_SM_DATA7; break;
    }

    data = REG(addrsel);
    stopped  = (data >> 0)  & 0x0001;
    datacnt  = (data >> 5)  & 0x03FF;
    writecnt = (data >> 16) & 0xFFFF;
    if (stopped) func_printf("sm not working !!! \r\n");
    func_printf("=== %d state catched ===\r\n", datacnt);
    if (writecnt > 0)
    {
        func_printf("=== sm is writing, pleas WAIT = %d === \r\n", writecnt);
        return;
    }

/*  -- ##### Write reg #####
      -- ### (0)     : Read Enable
      -- ### (1)     : Read Trigger
      -- ### (2)     : Read data "Page" 32bit selection
      -- ### (31:16) : write time
      -- ##### Read reg #####
      -- ### "Page 0"
        -- ### (0)     : sm stop flag
        -- ### (4:1)   : sm name
        -- ### (14:5)  : sm fifo count
        -- ### (31:16) : write time counter
      -- ### "Page 1"
        -- ### (31:0 ) : sm time counted value
*/

    for(u32 i=0; i<datacnt; i++)
    {

        // --- fifo read toggle
        REG(ADDR_SM_CTRL) = readreg + 2; // toggle (1)bit
        usdelay(4);
        REG(ADDR_SM_CTRL) = readreg;
        usdelay(4);
            data = REG(addrsel);
            sm = ( data>> 1) & 0xf;
        REG(ADDR_SM_CTRL) = readreg + 4; // next page 
        usdelay(4);
            data = REG(addrsel);
            smcnt = data+1; // 0=1
        REG(ADDR_SM_CTRL) = readreg; // page back  

//      smtime = smcnt * 0.050;
        smtime    = smcnt  / (FPGA_TFT_MAIN_CLK / 1000000);
        smtimeint = smcnt  / (FPGA_TFT_MAIN_CLK /    1000);
        smtimefrac = smtime - (smtimeint*1000);
        switch(smsel)
        {
        case 0 : func_printf("sm_tft  %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_tft[sm],        smcnt, smtimeint, smtimefrac); break;
        case 1 : func_printf("sm_roic %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_roic[sm],       smcnt, smtimeint, smtimefrac); break;
        case 2 : func_printf("sm_gate %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_gate[sm],       smcnt, smtimeint, smtimefrac); break;
        case 3 : func_printf("sm_rset %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_roic_set[sm],   smcnt, smtimeint, smtimefrac); break;
        case 4 : func_printf("sm_alig %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_data_align[sm], smcnt, smtimeint, smtimefrac); break;
        case 5 : func_printf("sm_roi  %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_roi[sm],        smcnt, smtimeint, smtimefrac); break;
        case 6 : func_printf("sm_avg  %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_avg[sm],        smcnt, smtimeint, smtimefrac); break;
        case 7 : func_printf("sm_grab %2d %8s = %10d cnt | %3d.%03d ms \r\n",sm, tstate_grab[sm],       smcnt, smtimeint, smtimefrac); break;
        }

        if(i%16==0) // gige keeping
            gige_callback(0);
    }

    data = REG(addrsel);
    datacnt  = (data >> 5)  & 0x03FF;
    REG(ADDR_SM_CTRL) = keepreadreg; // data back
    func_printf("=== end remain fifo data count = %d === \r\n", datacnt);

}

//void execute_cmd_d2m_set()
void execute_cmd_d2m_set(Profile_Def *profile)
{
    func_d2m = 1;
    u32 cmdstr = profile->cmdstr;
    u32 strdiv = 1; // shuld not be a zero 210811mbh
    switch(cmdstr){
        case 256  : strdiv =1; break;
        case 512  : strdiv =2; break;
        case 1024 : strdiv =4; break;
        case 2048 : strdiv =8; break;
        default   : strdiv =1;
    }

    execute_cmd_grab(1); // it is for external exp in.


    set_ddr_waddr(ADDR_AVG_DATA_DOSE0, 2); // avg ddr address set
    set_ddr_raddr(ADDR_AVG_DATA_DOSE0, 2);

    REG(ADDR_AVG_EN)    = 0;
    REG(ADDR_AVG_LEVEL) = 0;

    REG(ADDR_DDR_CH_EN) = 0b11010101; // ddr avg ch enable
    REG(ADDR_TRIG_VALID)= 1;          // out trig_valid enable
    u8 MCLK_ns = 1000000000 / profile->m_clock; // 50ns
    // ### 4343 rc D ### str 1024= /4 time
    REG(ADDR_GATE_RST_CYCLE) =  100000 * 1000 / MCLK_ns / strdiv; // 0x160 us
    REG(ADDR_GATE_XON)       =     350 * 1000 / MCLK_ns / strdiv; // 0x5c
    REG(ADDR_GATE_XON_FLK)   =      50 * 1000 / MCLK_ns / strdiv; // 0x60
    REG(ADDR_GATE_FLK)       =     160 * 1000 / MCLK_ns / strdiv; // 0x64
    REG(ADDR_D2M_SEXP_TIME )=5 * profile->m_clock;  // 5sec exp_time limit
    REG(ADDR_D2M_FRAME_TIME)=100;       // frame time
    REG(ADDR_D2M_XRST_NUM  )=20;        // xray trst number
    REG(ADDR_D2M_DRST_NUM  )=10;        // dark trst number
    REG(ADDR_D2M_EN        )=1;         // d2 mode enable
}

void execute_cmd_d2m_en()
{
    REG(ADDR_D2M_EXP_IN    )=0;         // d2 reg trigger 
    REG(ADDR_D2M_EXP_IN    )=1;
    msdelay(30);
    REG(ADDR_D2M_EXP_IN    )=0;
}

void execute_cmd_d2m_dis()
{
    func_d2m = 0;
    REG(ADDR_DDR_CH_EN) = 0b01110001;   // ddr avg ch enable
    REG(ADDR_D2M_EN        )=0;         // d2 mode disable
    execute_cmd_grab(1);
}

void execute_cmd_edge(u32 edge, u32 offset)
{
    REG(ADDR_DNR_SOBELCOEFF0    )= 0; // ((1<<12)-1)/32*offset;
    REG(ADDR_DNR_SOBELCOEFF1    )= ((1<<15)-1)/32*edge;
    REG(ADDR_DNR_SOBELCOEFF2    )= ((1<<14)-1)/32*edge;
    REG(ADDR_DNR_BLUROFFSET     )= ((1<<16)-1)/32*offset;
    if (edge==0)
        REG(ADDR_DNR_CTRL    )=0; // off
    else
        REG(ADDR_DNR_CTRL    )=1; // edge
}

void execute_cmd_dnr(u32 edge, u32 offset)
{
    int edgeRev, offsetRev;
    offsetRev = 31-offset; // 211026 dnr value reverse
    edgeRev = 31; // 32-edge;
//  offsetRev = offset;
//  edgeRev = edge;
    REG(ADDR_DNR_SOBELCOEFF0    )= 0; //  ((1<<12)-1)/32*offsetRev;
    REG(ADDR_DNR_SOBELCOEFF1    )= ((1<<15)-1)/32*edgeRev;
    REG(ADDR_DNR_SOBELCOEFF2    )= ((1<<15)-1)/32*edgeRev; // same with coe1 cause prevent duplication line
    REG(ADDR_DNR_BLUROFFSET     )= ((1<<16)-1)/32*offsetRev; // 0xFFFF/25*calc; // it makes some not linear vlaue.
    if (offset==0) // off
        REG(ADDR_DNR_CTRL    )=0; // off
    else
        REG(ADDR_DNR_CTRL    )= 2; // dnr
}

// 0 = off
// 1 = edge on
// 2 = dnr on
void execute_cmd_dnr_setting(u32 dnr, u32 edge, u32 offset) {
//  func_printf("dnr(%d), edge(%d), offset(%d)", dnr, edge, offset);
    execute_cmd_dnr(0, offset);
//  switch(dnr) {
//  case 0:
//      execute_cmd_dnr(dnr, offset);
//      break;
//  case 1:
//      execute_cmd_edge(edge, offset);
//      break;
//  case 2:
//      execute_cmd_dnr(edge, offset);
//      break;
//  }
}

u32 func_acc_value; //# 230721 acc value save, acc not support at global EXT1 mode

void execute_cmd_acc(u32 enable, u32 pagelimit)
{

    static int save_pagelimit;
    set_ddr_waddr(ADDR_AVG_DATA_DOSE6, 4); // avg ddr address set
    set_ddr_raddr(ADDR_AVG_DATA_DOSE6, 4);

    // on/off ctrl 211027mbh
    u32 on=0;
//  u32 auto_rst = 1;
    u32 auto_rst = func_image_acc_auto_reset;   // dskim - 22.04.27 - auto reset 적용
    u32 acc_osd_sel = 1; //  0:avg, 1:diff
    u32 sense_ofs = 1; //sensitive <-- 0:16 1:32 2:64 3:128 --> insensitive //diff of video
    u32 sense_per = 1; //sensitive <-- 0:12% 1:25% 2:50% 3:100% --> insensitive
    u32 sense_thres = 3; //sensitive <-- 0:4 1:8 2:16 3:32 4:64 5:1024 6:2048 7:4096 --> insensitive

//  if (enable==0 || pagelimit==0)
    if (func_static_avg_enable) //# 231114 acc support for static mode
        on = 1;
    else if (func_trig_mode == 1) //# 230721
    {
        on = 0;
		func_printf("execute_cmd_acc: ACC disabled by ext 1 trig_mode \r\n");
    }
    else if ( pagelimit==0 )
        on = 0;
    else
        on = 1;
//  auto_rst = on; // disable always on auto_rst 220502mbh

    if ( pagelimit!=save_pagelimit )
        REG(ADDR_ACC_CTRL    )= 0; // page cnt reset 211022mbh
     //# added acc auto_reset 220329mbh
    REG(ADDR_ACC_CTRL    )= (pagelimit << 8) | \
                            ((sense_per & 3) <<6) | \
                            ((sense_ofs & 3) <<4) | \
                            ((acc_osd_sel & 1) <<3) | \
                            ((auto_rst & 1) <<2) | \
                            ((on & 1) <<1) | \
                            (on & 1); // (1)bit: ddr ch enable
//  REG(ADDR_ACC_CTRL    )= (pagelimit << 8) | \
//                          ((sense_thres & 0xf) <<4) | \
//                          ((auto_rst & 1) <<2) | \
//                          ((on & 1) <<1) | \
//                          (on & 1); // (1)bit: ddr ch enable
    save_pagelimit = pagelimit;
}

void execute_cmd_racc(u32 enable)
{
    func_acc_read = enable;
}


void execute_cmd_osd(u32 on, u32 mode, u32 size)
{

    u32 osd_size = size; // 0:1x 1:2x 2:4x
    u32 osd_sel = 0; // 0:off 1:sync_cnt 2:acc_diff
    u32 accdet_mode = 0; //0: sync 1:avg 2:diff
    switch(mode){
        case 0: osd_sel=1;  accdet_mode=0; break; // osd sync
        case 1: osd_sel=2;  accdet_mode=0; break; // osd avg
        case 2: osd_sel=2;  accdet_mode=1; break; // osd diff
        default : osd_sel=0; accdet_mode=0;
    }

    func_printf("read ADDR_ACC_CTRL 0x400 = 0x%04x \r\n", REG(ADDR_ACC_CTRL));
    u32 read_reg_acc_ctrl = REG(ADDR_ACC_CTRL);
    REG(ADDR_ACC_CTRL) = (read_reg_acc_ctrl & 0xFFF7) | ((accdet_mode & 1) << 3); //bit3
    REG(ADDR_OSD_CTRL) = (osd_size & 3) << 4 | (osd_sel & 3) << 2 | (on & 1); //220404mbh

    func_printf("read ADDR_ACC_CTRL 0x400 = 0x%04x \r\n", REG(ADDR_ACC_CTRL));
    func_printf("read ADDR_OSD_CTRL 0x424 = 0x%04x \r\n", REG(ADDR_OSD_CTRL));

}

void execute_cmd_eao(u32 enable)
{

    set_ddr_waddr(ADDR_AVG_DATA_DOSE0, 2); // avg ddr address set
    set_ddr_raddr(ADDR_AVG_DATA_DOSE0, 2);

    REG(ADDR_AVG_LEVEL) = 0; // avg_level init 0
    REG(ADDR_DDR_CH_EN) = 0b01010101;
    if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01111101; // read ch 0,1,2 On 210302
    if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
    if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729
    msdelay(100);

    REG(ADDR_MPC_CTRL) =  enable & 1;   // force offset 211025mbh

    REG(ADDR_EXT_TRIG_EN)   = enable & 1;

}

void execute_api_ext_trig(u32 enable)
{
    REG(ADDR_API_EXT_TRIG)  = 0; //### api trigger toggle. 211210 kds
    msdelay(1); //# delay #230517
    REG(ADDR_API_EXT_TRIG)  = enable & 1;
}

void execute_fw_ext_trig(u32 num)
{
    u16 regcnt = 0;
    u16 cnt_limit=0;
//  u8 cnt = 0;
    regcnt = REG(ADDR_FRAME_CNT) & 0xFFFF;
    cnt_limit = regcnt + num;
    REG(ADDR_FRAME_NUM)= cnt_limit; // up to
    func_printf("a frame cnt = %d to %d \r\n", regcnt, cnt_limit);

    REG(ADDR_API_EXT_TRIG)  = 0;
    REG(ADDR_API_EXT_TRIG)  = 1;
    msdelay(10);

//  do
//  {
//      regcnt = REG(ADDR_FRAME_CNT);
//      if(regcnt != regcnt0)
//      {
//          func_printf("b frame cnt = %d \r\n",regcnt);
//          regcnt0=regcnt;
//      }
//      REG(ADDR_API_EXT_TRIG)  = 0;
//      REG(ADDR_API_EXT_TRIG)  = 1;
//      msdelay(10);
//      gige_callback(0);
//
//      if (uart_receive())
//      {
//          func_printf("Stopped ! \r\n");
//          break;
//      }
//  }
//  while(regcnt < cnt_limit-1 );

    REG(ADDR_API_EXT_TRIG)  = 0;
    func_printf("trig end ! \r\n");

}

void execute_fw_ext_trig_rst(u32 scannum, u32 rstnum)
{
    u32 scancnt=0;
    u32 rststartcnt=0;
    u32 rstcnt=0;
    u32 framecnt=0;
    u32 whilecnt=0; //# 221121
    u32 freeruncnt;
    u32 freerunfra;
//  REG(ADDR_FRAME_NUM)= 0; // up to
//  REG(ADDR_FRAME_VAL)= 0;
    if(func_static_avg_enable == 1) // dskim - 22.01.19
        execute_cmd_acc(0, 7);

    func_printf("## debug ## for scancnt(%d)<scannum(%d), rstnum(%d)\r\n", scancnt, scannum, rstnum);

    freeruncnt = REG(ADDR_FREERUN_CNT);
    freerunfra = freeruncnt % 100000 / 100;
    freeruncnt = freeruncnt / 100000;
    func_printf("start1 %d.%d\r\n",freeruncnt, freerunfra);

    for(scancnt=0; scancnt<scannum; scancnt++)
    {

        if (REG(ADDR_OUT_EN)==0) // out_en stop 220111mbh
        {
            func_printf("REG(ADDR_OUT_EN)=0 STOP!\r\n");
            return;
        }

        // ### scan trigger ###
        REG(ADDR_API_EXT_TRIG)  = 0;
        usdelay(1);//#################################################### delay
        REG(ADDR_API_EXT_TRIG)  = 1;
        whilecnt =0; //# 221121
        do // wait rstcnt 0
        {
            rstcnt = (REG(ADDR_FRAME_CNT)>>16) & 0xFFFF;
            if ((rstcnt-rststartcnt)%10==9){ //# if over counted rstcnt, retriggering! 220524mbh
                REG(ADDR_API_EXT_TRIG)  = 0;
                usdelay(1); //#################################################### delay
                REG(ADDR_API_EXT_TRIG)  = 1;
            }

            if(uart_receive()==1)// || REG(ADDR_OUT_EN)==0 ) // out_en stop 220111mbh
            {
                func_printf("0 count escape !!! rstcnt(%d) \r\n",rstcnt);
                break;
            }
            if((whilecnt&0xff) == 0)gige_callback(0);
            whilecnt++;
        } while(rstcnt != 0);

        whilecnt =0; //# 221121
        do // wait rstcnt 10
        {
            if(uart_receive()==1)// || REG(ADDR_OUT_EN)==0 ) // out_en stop 220111mbh
            {
                func_printf("trig escape !!! rstcnt(%d) \r\n",rstcnt);
                break;
            }

            if((whilecnt&0xff) == 0) gige_callback(0);

            if(whilecnt == 0)
            {
                framecnt = REG(ADDR_FRAME_CNT) & 0xFFFF;
                rstcnt = (REG(ADDR_FRAME_CNT)>>16) & 0xFFFF;
//              func_printf("framecnt= %d  // rstcnt = %d\r\n", framecnt, rstcnt);
                func_printf("ScanCnt = %d/%d rstnum= %d\r\n", scancnt,scannum, rstnum);
//              func_printf("# rstcnt = %d\r\n", (REG(ADDR_FRAME_CNT)>>16) & 0xFFFF);
//              func_printf("grab_state=%d \r\n",(REG(ADDR_FRAME_CNT) & 0x000F)>>0);
//              func_printf("tft_state=%d \r\n",(REG(ADDR_FRAME_CNT) & 0x00F0)>>4);
//              func_printf("roic_state=%d \r\n",(REG(ADDR_FRAME_CNT) & 0x0F00)>>8);
//              func_printf("gate_state=%d \r\n\r\n",(REG(ADDR_FRAME_CNT) & 0xF000)>>12);
            }
            rstcnt = (REG(ADDR_FRAME_CNT)>>16) & 0xFFFF;
            whilecnt++;
        } while(rstcnt < rstnum);
    } //scan cnt

    if(func_static_avg_enable == 1) // dskim - 22.01.19
        execute_cmd_acc(0, 0);

    freeruncnt = REG(ADDR_FREERUN_CNT);
    freerunfra = freeruncnt % 100000 / 100;
    freeruncnt = freeruncnt / 100000;
    func_printf("end2 %d.%03d\r\n",freeruncnt, freerunfra);
    func_printf("ScanCnt done.\r\n", scancnt,scannum);
    REG(ADDR_API_EXT_TRIG)  = 0;
}

void execute_cmd_extrst(u32 mode, u32 detectime_us)
{
    REG(ADDR_EXT_RST_MODE)  = mode; // 0:reset_mode 1: non_reset_mode 2: timer_reset_mode
    REG(ADDR_EXT_RST_DetTime)   = detectime_us*(FPGA_TFT_MAIN_CLK/1000000);
//  func_printf("REG(ADDR_EXT_RST_DetTime)(%d) = mode(%d) detectime_us(%d)\r\n",REG(ADDR_EXT_RST_DetTime), mode, detectime_us);
}


void execute_cmd_rom()
{
    u32 read = 0;
    u32 read0 = 0;

    // ### FLASH LIVE CHECK ###
//  REG(ADDR_FLAW_CMD)  = FLAW_CMD_READSTATUS;
//  REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1R1;
//  msdelay(50); //
//  read = REG(ADDR_FLAW_RDATA);
//  read = read >> 16 & 0xff;
//  REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;
//  if (read == 0xff)
//      return CMD_ERR9;


    // ### RESET  ###
//  REG(ADDR_FLAW_CMD) = FLAW_CMD_RESETENABLE; // Write Enable
//  REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1;
//  usdelay(1); //
//  REG(ADDR_FLAW_CMD) = FLAW_CMD_RESETMEMORY; // Write Enable
//  REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1;
//  usdelay(1); //
//  flaw_status_writeset(0);
//  REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear

    // ##############################
    // ##### flash addr 0 check #####
    read = flash_read_dword(0);
    read0 = read;
    if (read == 0 ||
        read == 0xFFFFFFFF)
    {
        execute_cmd_wflash(0, 0xAAAA5555);
        msdelay(10);
        read = flash_read_dword(0);
        if (read == 0xAAAA5555)
        {
            func_printf("flash checked and ready \r\n");
//          flash_write_dword(0, read0);
            execute_cmd_wflash(0, read0);
        }
        else
        {
            func_printf("\033[31m"); //red
            execute_cmd_rflash(0);
            func_printf("flash is not ready !!! \r\n");
            func_printf("\033[0m"); // default
//            return CMD_OK;
        }
    }
    // ###############################
    // ##### eeprom addr 0 check #####
    read = eeprom_read_dword(0);
    read0 = read;
    if (read == 0 ||
        read == 0xFFFFFFFF)
    {
        eeprom_write_dword(0, 0xAAAA5555);
        msdelay(10);
        read = eeprom_read_dword(0);
        if (read == 0xAAAA5555)
        {
            func_printf("eeprom checked and ready \r\n");
            eeprom_write_dword(0, read0);
        }
        else
        {
            func_printf("\033[31m"); // red
            execute_cmd_reep(0);
            func_printf("eeprom is not ready !!! \r\n");
            func_printf("\033[0m"); // default
//            return CMD_OK;
        }
    }

    func_printf("flash/eeprom write init"); //  ... done \r\n");
    func_printf("\033[32m"); // green
    func_printf(" ... done \r\n");
    func_printf("\033[0m"); // default

}

void execute_cmd_romread()
{

    execute_cmd_rflash(0x00000000);
    execute_cmd_rflash(0x00c00000);
    execute_cmd_rflash(0x00C20000);
    execute_cmd_rflash(0x00D00000);
    execute_cmd_reep(0x00000000);

}
void execute_cmd_settimingprofile(u32* data)
{
    Profile_Def profile_data;
    profile_data.mclk = data[0];
    profile_data.cmdstr = data[1];
    profile_data.tirst = data[2] * 100; //# 240122 1000->100, 230118 wtp command length reduce
    profile_data.tshr_lpf1 = data[3] * 100;
    profile_data.tshs_lpf2 = data[4] * 100;
    profile_data.tgate = data[5] * 100;
    if(AFE3256_series) 	roic_3256_init(&profile_data); //$ 251121
    else				roic_settimingprofile(&profile_data);
//  roic_settimingprofile(data[0], data[1], data[2], data[3], data[4], data[5]);
}

void execute_cmd_read_defect(u32 data) {
    char buffer[32] = {0};
    u32 i = 0;
    u32 read_defect = func_read_defect;
    u32 read_defect_stt = func_read_defect_stt;
    u32 read_defect_num = func_read_defect_num;

    if(is_factory_map_mode == 1) {
        // factory
        switch(read_defect) {
        case 0:
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"p");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_defect_cnt2));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = read_defect_stt; i < read_defect_stt + read_defect_num ; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d,%d", (int)func_defect2[i][0], (int)func_defect2[i][1]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }

            // factory
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"fp");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_defect_cnt3));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_defect_cnt3; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d,%d", (int)func_defect3[i][0], (int)func_defect3[i][1]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }
            break;

        case 1:
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"r");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_rdefect_cnt));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_rdefect_cnt; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d", (int)func_rdefect[i]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }

            // factory
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"fr");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_rdefect_cnt3));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_rdefect_cnt3; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d", (int)func_rdefect3[i]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }
            break;

        case 2:
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"c");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_cdefect_cnt));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_cdefect_cnt; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d", (int)func_cdefect[i]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }

            // factory
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"fc");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_cdefect_cnt3));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_cdefect_cnt3; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d", (int)func_cdefect3[i]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }
            break;

        default:
            break;
        }

        // Manual
    } else {
        switch(read_defect) {
        case 0:
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"p");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_defect_cnt2));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            //$ 250630 backward compatibility
            if(read_defect_num == 0)
            	read_defect_num = (int)(func_defect_cnt2);

            if(read_defect_stt + read_defect_num > (int)(func_defect_cnt2))
            	read_defect_num = (int)(func_defect_cnt2) - read_defect_stt;

            for (i = read_defect_stt; i < read_defect_stt + read_defect_num ; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d,%d", (int)func_defect2[i][0], (int)func_defect2[i][1]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }
            break;
        case 1:
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"r");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_rdefect_cnt));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_rdefect_cnt; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d", (int)func_rdefect[i]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }
            break;
        case 2:
            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"c");
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            memset(buffer, 0, sizeof(buffer));
            sprintf(buffer,"%d", (int)(func_cdefect_cnt));
            gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);

            for (i = 0; i < func_cdefect_cnt; i++) {
                memset(buffer, 0, sizeof(buffer));
                sprintf(buffer,"%d", (int)func_cdefect[i]);
                gige_send_message4(GEV_EVENT_READ_DEFECT, 0, sizeof(buffer), (u8*)&buffer);
            }
            break;
        default:
            break;
        }
    }
}

void execute_cmd_trig_valid(u32 data) {
    if(data == 0 || data == 1) {
        func_trig_valid = data;
        REG(ADDR_TRIG_VALID) = func_trig_valid;
    }
}

void execute_cmd_trig_active(u32 data, u32 inout) {
    u32 trig_active = 0;

    if(inout == 0) {
        func_trig_in_active = data;
    } else {
        func_trig_out_active = data;
    }

    trig_active = ((func_trig_out_active & 0x1) << 1) | (func_trig_in_active & 0x1);

    REG(ADDR_EXT_TRIG_ACTIVE)   = trig_active;
}

void execute_cmd_re_defect(void) {
    REG(ADDR_FW_BUSY) = 1; //# busy 220524

    execute_cmd_cdot_fpga(0);
    execute_cmd_cdot_fpga(1);
    execute_cmd_cdot_fpga(2);
    execute_cmd_cdot_fpga(3);

    set_calib_defect(0);
    set_calib_defect(1);
    set_calib_rdefect();
    set_calib_cdefect();
    REG(ADDR_FW_BUSY) = 0; //# busy 220524
}

u8 execute_cmd_brns_old(void) { // burst rns
    u32 i;
    u32 ddr_addr = 0;
    u32 flash_addr = 0;
    u32 repeat = 0;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;
//    repeat = width_x32 * func_height * (DDR_CH1_BIT_DEPTH / 32);
    repeat = width_x32 * func_height * (DDR_CH1_BIT_DEPTH / 32);
    ddr_addr    = ADDR_NUC_DATA;
    flash_addr  = FLASH_NUC_BASEADDR;

     // NUC existence check
    if(flash_read_dword(flash_addr)==0xFFFFFFFF) {
        REG(ADDR_FW_BUSY) = 0;
        return 1;
    }

    REG(ADDR_FW_BUSY) = 1;
    REG(ADDR_FLA_ADDR) = flash_addr; // addr setup flash_addr
//  REG(ADDR_FLA_CTRL) = 1; // read start(0)
    REG(ADDR_FLA_CTRL) = 0b101; // read start(0) + auto address increment(2)

    // need a little delay
    func_printf("\r\nWrite NUC Parameter to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(i = 0; i < repeat; i++) {
        DREG(ddr_addr) = REG(ADDR_FLA_DATA);
        ddr_addr += 4;
    }

    flash_addr  = FLASH_NUC_INFO_BASEADDR;
    func_img_avg_old    = flash_read_dword(flash_addr); flash_addr += 4;
    func_img_avg_dose0  = flash_read_dword(flash_addr); flash_addr += 4;
    func_img_avg_dose1  = flash_read_dword(flash_addr); flash_addr += 4;
    func_img_avg_dose2  = flash_read_dword(flash_addr); flash_addr += 4;
    func_img_avg_dose3  = flash_read_dword(flash_addr); flash_addr += 4;
    func_img_avg_dose4  = flash_read_dword(flash_addr); flash_addr += 4;

    for(i = 0; i < 32; i++) func_printf("*"); // write "*" at once
    func_printf("\r\nFinished!\r\n");

    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss
    REG(ADDR_FW_BUSY) = 0;

    return 0;
}

void execute_cmd_write_detector_sn(void) {
    u32 i, k = 0;
    u32 addr = FLASH_DETECTOR_SN_BASEADDR;

    func_printf("\r\nWrite Detector Serial Number to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(i = 0; i < 16; i++) {
        flash_buffer[k] = PANEL_SERIAL[i];
        k++;
    }

    flash_write_block(addr, (u32*)flash_buffer, 65536);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

u8 execute_cmd_read_detector_sn(void) {
    u32 i, k = 0;
    u32 addr = FLASH_DETECTOR_SN_BASEADDR;
    u32 data[100];
    u32 flag_data = 0;

    func_printf("\r\nRead Detector Serial Number from Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for (i = 0; i < 100; i++) {
        data[i] = flash_read_dword(addr);
        addr += 4;

        if(flag_data == 0) {
            if(data[i] == 0xFFFFFFFF)   flag_data = 0;
            else                        flag_data = 1;
        }
    }

    if(!flag_data) { func_printf("\r\n"); return 1; }

    for(i = 0; i < 16; i++) {
        PANEL_SERIAL[i] = (u8)data[k];  // dskim - 21.05.13 - Serial Number 지워지지 않도록 변경
        k++;
    }

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");

    return 0;
}

void execute_cmd_write_tft_sn(void) {
    u32 i, k = 0;
    u32 addr = FLASH_TFT_SN_BASEADDR;

    func_printf("\r\nWrite TFT(Panel) Serial Number to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(i = 0; i < 16; i++) {
        flash_buffer[k] = TFT_SERIAL[i];
        k++;
    }

    flash_write_block(addr, (u32*)flash_buffer, 65536);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
}

u8 execute_cmd_read_tft_sn(void) {
    u32 i, k = 0;
    u32 addr = FLASH_TFT_SN_BASEADDR;
    u32 data[100];
    u32 flag_data = 0;

    func_printf("\r\nRead TFT(Panel) Serial Number from Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for (i = 0; i < 100; i++) {
        data[i] = flash_read_dword(addr);
        addr += 4;

        if(flag_data == 0) {
            if(data[i] == 0xFFFFFFFF)   flag_data = 0;
            else                        flag_data = 1;
        }
    }

    if(!flag_data) { func_printf("\r\n"); return 1; }

    for(i = 0; i < 16; i++) {
        TFT_SERIAL[i] = (u8)data[k];    // dskim - 21.05.13 - Serial Number 지워지지 않도록 변경
        k++;
    }

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");

    return 0;
}

#define DBG_EDGE 1
u8 execute_cmd_parser(u32 data) {
    u32 type  = 0;
    u32 temp  = 0;

    type = (data >> 26) & 0x3F; // 명령어

//  func_printf("\r\n data = 0x%x\r\n", data);

    switch(type) {
    case 0:
        break;
    case 1:
        // func_edge_cut_left;  // 기본 값, Flash, API 통신에 사용된
        // func_edge_left;      // Binning 모드에 따라서 전역에 사용됨.
        temp = data & 0x3FFFFFF;
        if((temp + func_edge_right) >= func_width)
            return 1;
        func_edge_cut_left = func_edge_left = temp;
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
            case 2 :
            case 3 :
                func_edge_cut_left *= 2;
                break;
            case 4 :
            case 5 :
                func_edge_cut_left *= 3;
                break;
            case 6 :
            case 7 :
                func_edge_cut_left *= 4;
                break;
        }
        break;
    case 2:
        temp = data & 0x3FFFFFF;
        if((temp + func_edge_left) >= func_width)
            return 1;
        func_edge_cut_right = func_edge_right = temp;
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
            case 2 :
            case 3 :
                func_edge_cut_right *= 2;
                break;
            case 4 :
            case 5 :
                func_edge_cut_right *= 3;
                break;
            case 6 :
            case 7 :
                func_edge_cut_right *= 4;
                break;
        }
        break;
    case 3:
        temp = data & 0x3FFFFFF;
        if((temp + func_edge_bottom) >= func_height)
            return 1;
        func_edge_cut_top = func_edge_top = temp;
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
            case 2 :
            case 3 :
                func_edge_cut_top *= 2;
                break;
            case 4 :
            case 5 :
                func_edge_cut_top *= 3;
                break;
            case 6 :
            case 7 :
                func_edge_cut_top *= 4;
                break;
        }
        break;
    case 4:
        temp = data & 0x3FFFFFF;
        if((temp + func_edge_top) >= func_height)
            return 1;
        func_edge_cut_bottom = func_edge_bottom = temp;
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
            case 2 :
            case 3 :
                func_edge_cut_bottom *= 2;
                break;
            case 4 :
            case 5 :
                func_edge_cut_bottom *= 3;
                break;
            case 6 :
            case 7 :
                func_edge_cut_bottom *= 4;
                break;
        }
        break;
    case 5:
        temp = data & 0x3FFFFFF;
        if(temp >= 65536)
            return 1;
        func_edge_cut_value = -temp;
        break;

    case 6:
        break;

    default:
        break;

    }

    if(DBG_EDGE)func_printf("left=%d\r\n",func_edge_cut_left );
    if(DBG_EDGE)func_printf("right=%d\r\n",func_edge_cut_right );
    if(DBG_EDGE)func_printf("top=%d\r\n",func_edge_cut_top );
    if(DBG_EDGE)func_printf("bottom=%d\r\n",func_edge_cut_bottom );
    if(DBG_EDGE)func_printf("value=%d\r\n",func_edge_cut_value );

    execute_cmd_edgemask_calc(); //# fpga edge mask 230215
    return 0;
}

#define DBG_EDGEMASK 0
u8 execute_cmd_edgemask_calc() {

    u32 binnmulti=1;
    u32 func_edge_mask_top   ;
    u32 func_edge_mask_left  ;
    u32 func_edge_mask_right ;
    u32 func_edge_mask_bottom;

    //# binn mode size re-define
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
            case 2 :
            case 3 :
                binnmulti = 2;
                break;
            case 4 :
            case 5 :
                binnmulti = 3;
                break;
            case 6 :
            case 7 :
                binnmulti = 4;
                break;
        }

    u32 binn_edge_cut_top    = func_edge_cut_top    / binnmulti;
    u32 binn_edge_cut_left   = func_edge_cut_left   / binnmulti;
    u32 binn_edge_cut_right  = func_edge_cut_right  / binnmulti;
    u32 binn_edge_cut_bottom = func_edge_cut_bottom / binnmulti;
    u32 binn_max_width       = MAX_WIDTH            / binnmulti;
    u32 binn_max_height      = MAX_HEIGHT           / binnmulti;

    //# top
    if(binn_edge_cut_top > func_offsety)
            func_edge_mask_top = binn_edge_cut_top - func_offsety;
        else
            func_edge_mask_top = 0;
    //# left
    if(binn_edge_cut_left > func_offsetx)
        func_edge_mask_left = binn_edge_cut_left - func_offsetx;
    else
        func_edge_mask_left = 0;
    //# right
    if((binn_max_width-binn_edge_cut_right) < (func_offsetx+func_width) )
        func_edge_mask_right = (func_offsetx+func_width) - (binn_max_width-binn_edge_cut_right);
    else
        func_edge_mask_right = 0;
    func_edge_mask_right = func_width-func_edge_mask_right;
    //# bottom
    if((binn_max_height-binn_edge_cut_bottom) < (func_offsety+func_height) )
            func_edge_mask_bottom = (func_offsety+func_height) - (binn_max_height-binn_edge_cut_bottom);
        else
            func_edge_mask_bottom = 0;
    func_edge_mask_bottom = func_height-func_edge_mask_bottom;

    if(DBG_EDGEMASK) func_printf("func_width=%d \r\n", func_width);
    if(DBG_EDGEMASK) func_printf("func_height=%d\r\n", func_height);
    if(DBG_EDGEMASK) func_printf("func_offsetx=%d \r\n", func_offsetx);
    if(DBG_EDGEMASK) func_printf("func_offsety=%d \r\n", func_offsety);

    if(DBG_EDGEMASK) func_printf("binn_edge_cut_top    =%d \r\n", binn_edge_cut_top   );
    if(DBG_EDGEMASK) func_printf("binn_edge_cut_left   =%d \r\n", binn_edge_cut_left  );
    if(DBG_EDGEMASK) func_printf("binn_edge_cut_right  =%d \r\n", binn_edge_cut_right );
    if(DBG_EDGEMASK) func_printf("binn_edge_cut_bottom =%d \r\n", binn_edge_cut_bottom);

    if(DBG_EDGEMASK) func_printf("func_edge_mask_top    =%d \r\n", func_edge_mask_top   );
    if(DBG_EDGEMASK) func_printf("func_edge_mask_left   =%d \r\n", func_edge_mask_left  );
    if(DBG_EDGEMASK) func_printf("func_edge_mask_right  =%d \r\n", func_edge_mask_right );
    if(DBG_EDGEMASK) func_printf("func_edge_mask_bottom =%d \r\n", func_edge_mask_bottom);
    if(DBG_EDGEMASK) func_printf("func_edge_cut_value   =%d \r\n", func_edge_cut_value  );

    //REG(ADDR_EDGE_CTRL  ) = (func_edge_cut_top || func_edge_cut_left || func_edge_cut_right || func_edge_cut_bottom) ? 1 : 0;
    //$ 250102 10G Edge cut
    u32 remainder_arry_left[]   = {0b0, 0b1, 0b11, 0b111};
    u32 remainder_arry_right[]  = {0b0, 0b111, 0b11, 0b1};

    u32 remainder_edge_left  = remainder_arry_left [binn_edge_cut_left  % 4];
    u32 remainder_edge_right = remainder_arry_right[binn_edge_cut_right % 4];
    u32 edge_ctrl_en	     = (func_edge_cut_top || func_edge_cut_left || func_edge_cut_right || func_edge_cut_bottom) ? 1 : 0;
    u32 edge_ctrl_value      = (remainder_edge_left << 5) | (remainder_edge_right << 1) | (edge_ctrl_en << 0);

    REG(ADDR_EDGE_CTRL)   = edge_ctrl_value;
    REG(ADDR_EDGE_VALUE ) = -func_edge_cut_value;
    REG(ADDR_EDGE_TOP   ) = func_edge_mask_top   ;
    REG(ADDR_EDGE_BOTTOM) = func_edge_mask_bottom;

    //#if defined(GEV10G)
//    REG(ADDR_EDGE_LEFT  ) = func_edge_mask_left/4  ;
//    REG(ADDR_EDGE_RIGHT ) = func_edge_mask_right/4 ;
//#else//(2.5G)
//    REG(ADDR_EDGE_LEFT  ) = func_edge_mask_left  ;
//    REG(ADDR_EDGE_RIGHT ) = func_edge_mask_right ;
//#endif

	if (def_gev_speed == 10){
		REG(ADDR_EDGE_LEFT  ) = func_edge_mask_left/4  ;
		REG(ADDR_EDGE_RIGHT ) = func_edge_mask_right/4 ;
	}
	else{
	    REG(ADDR_EDGE_LEFT  ) = func_edge_mask_left  ;
	    REG(ADDR_EDGE_RIGHT ) = func_edge_mask_right ;
	}
    return 0;
}

u8 execute_cmd_edge_cut_save(u32 data) {
    u32 i;
    u32 size = 0x10000;
    u32 waddr = FLASH_USER_BASEADDR + (data * size);
    u32 raddr = FLASH_USER_BASEADDR + (data * size);

    // 모든 설정 영역에 기록한다.
    func_printf("\r\nWrite Edge Value to Flash Memory\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    flash_read_dword(raddr);

    // 기본 Flash 데이터를 그대로 읽는다.
    for(i = 0; i < 100; i++) {
        flash_buffer[i] = flash_read_dword(raddr);
        raddr += 4;
    }

    // edge 값만 새로 작성
    flash_buffer[53]    = func_edge_cut_left;
    flash_buffer[54]    = func_edge_cut_right;
    flash_buffer[55]    = func_edge_cut_top;
    flash_buffer[56]    = func_edge_cut_bottom;
    flash_buffer[57]    = -func_edge_cut_value;

    // 기본 Flash 영역에 새롭게 쓴다.
    flash_write_block(waddr, (u32*)flash_buffer, 65536);

    for(i = 0; i < 32; i ++) func_printf("*");

    func_printf("\r\nFinished!\r\n");
    return 0;
}

void execute_cmd_bmode_edge_cut(u32 data) {
    if(func_binning_mode != data) {
        func_edge_left   = func_edge_cut_left;
        func_edge_right  = func_edge_cut_right;
        func_edge_top    = func_edge_cut_top;
        func_edge_bottom = func_edge_cut_bottom;
        switch (data) {
            case 0 :
                break;
            case 1 :
            case 2 :
            case 3 :
                func_edge_left   /= 2;
                func_edge_right  /= 2;
                func_edge_top    /= 2;
                func_edge_bottom /= 2;
                break;
            case 4 :
            case 5 :
                func_edge_left   /= 3;
                func_edge_right  /= 3;
                func_edge_top    /= 3;
                func_edge_bottom /= 3;
                break;
            case 6 :
            case 7 :
                func_edge_left   /= 4;
                func_edge_right  /= 4;
                func_edge_top    /= 4;
                func_edge_bottom /= 4;
                break;
        }
    }
}

void execute_cmd_read_edge_cut(void) {
    char buffer[32] = {0};
    u32 type = 0;
    u32 value = 0;
    u32 temp = 0;

    type = 0x1;
    value = func_edge_left;
    temp = ((type & 0x0000003F) << 26) | (value & 0x3FFFFFF);
    memset(buffer, 0, sizeof(buffer));
    sprintf(buffer,"%d", (int)(temp));
    gige_send_message4(GEV_EVENT_READ_EDGE, 0, sizeof(buffer), (u8*)&buffer);

    type = 0x2;
    value = func_edge_right;
    temp = ((type & 0x0000003F) << 26) | (value & 0x3FFFFFF);
    memset(buffer, 0, sizeof(buffer));
    sprintf(buffer,"%d", (int)(temp));
    gige_send_message4(GEV_EVENT_READ_EDGE, 0, sizeof(buffer), (u8*)&buffer);

    type = 0x3;
    value = func_edge_top;
    temp = ((type & 0x0000003F) << 26) | (value & 0x3FFFFFF);
    memset(buffer, 0, sizeof(buffer));
    sprintf(buffer,"%d", (int)(temp));
    gige_send_message4(GEV_EVENT_READ_EDGE, 0, sizeof(buffer), (u8*)&buffer);
    type = 0x4;
    value = func_edge_bottom;
    temp = ((type & 0x0000003F) << 26) | (value & 0x3FFFFFF);
    memset(buffer, 0, sizeof(buffer));
    sprintf(buffer,"%d", (int)(temp));
    gige_send_message4(GEV_EVENT_READ_EDGE, 0, sizeof(buffer), (u8*)&buffer);

    type = 0x5;
    value = -func_edge_cut_value;
    temp = ((type & 0x0000003F) << 26) | (value & 0x3FFFFFF);
    memset(buffer, 0, sizeof(buffer));
    sprintf(buffer,"%d", (int)(temp));
    gige_send_message4(GEV_EVENT_READ_EDGE, 0, sizeof(buffer), (u8*)&buffer);
}


// dskim - 21.03.02 - factory map
u32 execute_cmd_wdot_factory(u32 pointx, u32 pointy, u32 erase) {
    if(!erase) {
        if(check_same_defect(pointx, pointy, 2))    return 1;
        add_calib_defect(pointx, pointy, 2);
    }
    else {
        if(!check_same_defect(pointx, pointy, 2))   return 2;
        erase_calib_defect_factory(pointx, pointy);
    }
    set_calib_defect(1);
    return 0;
}

// dskim - 21.03.02 - factory map
// dskim - 21.09.24 - 사용하지 않음
u32 execute_cmd_wrdot_factory(u32 row, u32 erase) {
    if(!erase) {
        if(check_same_rdefect(row, 1))  return 1;
        add_calib_rdefect(row, 1);
    }
    else {
        if(!check_same_rdefect(row, 1))     return 2;
        erase_calib_rdefect_factory(row);
    }
    set_calib_rdefect();
    return 0;
}

// dskim - 21.09.24 - 사용하지 않음
u32 execute_cmd_wcdot_factory(u32 col, u32 erase) {
    if(!erase) {
        if(check_same_cdefect(col, 1))  return 1;
        add_calib_cdefect(col, 1);
    }
    else {
        if(!check_same_cdefect(col, 1))     return 2;
        erase_calib_cdefect_factory(col);
    }
    set_calib_cdefect();
    return 0;
}

void execute_cmd_exposure_type(u32 data) {
        func_exposure_type = data;
//      func_exposure_type = 0; //# not use exposure_type

    // ### Ext1 mode do not tft-reset immediatly, if not comming trigger in time do tft-reset. ###
//  if (func_shutter_mode==1 && func_trig_mode==1 && func_exposure_type==0) //  dynamic/normal mode // 220111 static check

    if (func_exposure_type==0)
//  if (data==0)
        execute_cmd_extrst(2, 1000000); // 1sec for SEC
    else // static
        // execute_cmd_extrst(0, 0); // no effect
        execute_cmd_extrst(2, (int)((float)1000000 / func_frate)); //# static no seral-reset for 100sec 221121

//  execute_cmd_extrst(2, 1000000); // 1sec for SEC only use this
}

void execute_cmd_reset_device(void) {
    m88x33xx_deinit();
}

void execute_cmd_wake() {
    if(!func_sleep)
        return;
    roic_set_wake();
    fpga_set_wake();
    func_sleep = 0;
    func_printf("Good morning!\r\n");
    gige_send_message4(GEV_EVENT_SLEEP_MODE, 0, 1, (u8*)SLEEP_MODE_AWAKE);
    //$ 241120jyp a-Si bit align 1s delay
    if(msame(mEXT4343R_3 ) || msame(mEXT4343RC_3) || msame(mEXT4343RCL_3))
    	msdelay(1000);

//    func_grabbcal = 1; // bcal //# The bcal is processed in out_en user.c. #220510mbh, rollback
    func_bcal1_token = 1; //# delete grabbcal #250926
}

void execute_cmd_sleep() {
    if(func_sleep)
        return;
    bcal_once = 0; //$ 250305 bcal debug
    fpga_set_sleep();
    roic_set_sleep();
    func_sleep = 1;
    func_printf("Good night!\r\n");
    gige_send_message4(GEV_EVENT_SLEEP_MODE, 0, 1, (u8*)SLEEP_MODE_SLEEP);
    // dskim - 디버그
    {
        u32 run_time = get_run_time();
        func_printf("save_stop_time = %d:%02d:%02d\r\n",\
                (run_time /60 /60 %24), (run_time /60 %60), (run_time % 60));
    }
}

void execute_cmd_sleep_mode(u32 data) {
    set_sleepmode(data);

}

u32 execute_cmd_check_acq_stop_timeover(u32 break_sign) {
//  u32 run_time = get_run_time();  // dskim - grab 도중에는 읽지 않도록
    static u32 save_stop_time = 0;

    if (break_sign == 0) {
        save_stop_time = 0;
    } else if (break_sign == 1 && save_stop_time ==0) {
        // Sleep 초기 계산시간이 반영됨
        func_sleep_mode_time_m = func_sleep_mode_time * 60;     // 시간이 변경되었을 경우 이부분에서 재설정되어야 함. Sleep 모드상태에서 시간이 변경되어도 Awake하지 않도록
//      save_stop_time = run_time;  // dskim - grab 도중에는 읽지 않도록
        save_stop_time = get_run_time();
        func_printf("save_stop_time = %d:%02d:%02d\r\n",\
                (save_stop_time /60 /60 %24), (save_stop_time /60 %60), (save_stop_time % 60));
    }

    if (save_stop_time == 0) {
        return 0;
    } else {
        //  else if (run_time > save_stop_time + (60*5)) //# time check : if acq stop over 5 minute
        //  else if (run_time > (save_stop_time + SLEEP_TIMEOVER)) //# for test short 10 second
        if (get_run_time() > (save_stop_time + func_sleep_mode_time_m)) { // dskim - 22.04.27 - API 연동, 분 단위 동작
//      if (get_run_time() > (save_stop_time + 20)) { // test short time
            return 1; //over
        }
    }

    return 0;
}

void execute_cmd_pwdac(u32 en, u32 volt, u32 time ) {
    set_pwdac( en,  volt,  time );
}

void execute_cmd_pixpos(u32 en, u32 pos_h, u32 pos_v ) {
    set_pixpos( en,  pos_h,  pos_v );
}

inline void set_cmd_op_boot_count(u32 count) {
    func_boot_count = count;
}

inline void set_cmd_op_grab_count(u32 count) {
    func_grab_count = count;
}

inline void execute_cmd_op_boot_count(void) {
    func_boot_count++;
}

inline void execute_cmd_op_grab_count(void) {
    func_grab_count++;
}

void execute_cmd_op_acq_start(void) {
    func_oper_time_start = get_run_time();
}

void execute_cmd_op_acq_stop(void) {
    u32 oper_time_stop = 0; // Stop 시간
    u32 oper_time_calc = 0; // 동작 시간
    u32 oper_time_calc_h = 0;
    u32 oper_time_calc_m = 0;
    u32 oper_time_calc_s = 0;

    // 동작 시간 계산
    oper_time_stop = get_run_time();    // 동작시간

    // 곧바로 종료 했을 경우
    if(func_oper_time_start == oper_time_stop) {
        return;
    }

    // 동작 횟수, 곧바로 멈추는 경우는 제외
    execute_cmd_op_grab_count();

    // *동작 누적시간 계산
    // 동작 시간 = Stop 시간 - Start 시간
    oper_time_calc = oper_time_stop - func_oper_time_start;

    // (B)누적 동작 시간  = (A)동작시간 + (B)누적 동작 시작
    func_oper_time_stop = func_oper_time_stop + oper_time_calc;

    oper_time_calc_h = (func_oper_time_stop /60 /60 %24);
    oper_time_calc_m = (func_oper_time_stop /60 %60);
    oper_time_calc_s = (func_oper_time_stop %60);

    func_printf("func_oper_time_stop = %d:%02d:%02d\r\n",\
            (func_oper_time_stop /60 /60 %24), (func_oper_time_stop /60 %60), (func_oper_time_stop % 60));  // 베타이후 삭제

    if(func_oper_time_stop >= OPER_TIME_OVERTIME) {
        func_oper_time_h += oper_time_calc_h;
        func_oper_time_m += oper_time_calc_m;
        func_oper_time_s += oper_time_calc_s;
        if(func_oper_time_s >= 60) {
            func_oper_time_m += 1;
            func_oper_time_s -= 60;
        }
        if(func_oper_time_m >= 60) {    // 버그 // 22.07.27 - 계산오류 수정
            func_oper_time_h += 1;
            func_oper_time_m -= 60;
        }
//        func_printf("func_oper_time_h = %d\r\n",func_oper_time_h);  // 베타이후 삭제
//        func_printf("func_oper_time_m = %d\r\n",func_oper_time_m);
//        func_printf("func_oper_time_s = %d\r\n",func_oper_time_s);

        execute_cmd_write_oper_time();

        func_oper_time_stop = 0;    // 초기화
    }
}

void execute_cmd_write_oper_time(void) {
    u32 addr = FLASH_OPERATING_TIME1_BASEADDR;

    if(func_oper_time_select == 1) {
        addr = FLASH_OPERATING_TIME2_BASEADDR;
        func_oper_time_select = 0;
        func_printf("\r\nWrite Detector Operating Time to Flash Memory(2)\r\n");
    } else {
        addr = FLASH_OPERATING_TIME1_BASEADDR;
        func_oper_time_select = 1;
        func_printf("\r\nWrite Detector Operating Time to Flash Memory(1)\r\n");
    }

    flash_buffer[0] = func_grab_count;
    flash_buffer[1] = func_boot_count;
    flash_buffer[2] = func_oper_time_h;
    flash_buffer[3] = func_oper_time_m;
    flash_buffer[4] = func_oper_time_s;

    flash_write_block(addr, (u32*)flash_buffer, 65536);


    func_printf("\r\nFinished!\r\n");
}

u8 execute_cmd_read_oper_time(void) {
    volatile u32 addr = FLASH_OPERATING_TIME1_BASEADDR;
    u32 temp_grab_count1 = 0;
    u32 temp_grab_count2 = 0;

    temp_grab_count1 = flash_read_dword(FLASH_OPERATING_TIME1_BASEADDR);
    temp_grab_count2 = flash_read_dword(FLASH_OPERATING_TIME2_BASEADDR);

    if(temp_grab_count1 == 0xFFFFFFFF && temp_grab_count2 == 0xFFFFFFFF) {
        return 1;
    }

    if(temp_grab_count2 > temp_grab_count1) {
        addr = FLASH_OPERATING_TIME2_BASEADDR;
        func_oper_time_select = 0;
        func_printf("\r\nRead Detector Operating Time from Flash Memory(2)");
    } else {
        addr = FLASH_OPERATING_TIME1_BASEADDR;
        func_oper_time_select = 1;
        func_printf("\r\nRead Detector Operating Time from Flash Memory(1)");
    }

    func_grab_count  = flash_read_dword(addr);  addr += 4;
    func_boot_count  = flash_read_dword(addr);  addr += 4;
    func_oper_time_h = flash_read_dword(addr);  addr += 4;
    func_oper_time_m = flash_read_dword(addr);  addr += 4;
    func_oper_time_s = flash_read_dword(addr);  addr += 4;

    func_printf("\r\nFinished!\r\n");

    return 0;
}

// dskim - 동작 모드에 관련된 사항은 모두 여기에 기록하도록 함
void execute_cmd_write_oper_mode(u32 value) {
    u32 addr = FLASH_OPERATING_MODE_BASEADDR;
    // 불필요한 동작 하지 않도록
    if(func_sw_calibration_mode != value) {
        // ****************************************
        // 동작모드가 추가된다면 read 후 write 해야함
        // ****************************************
        func_sw_calibration_mode = value;

        flash_buffer[0] = func_sw_calibration_mode;

        flash_write_block(addr, (u32*)flash_buffer, 65536);

        func_printf("\r\nFinished!\r\n");
    }
}

u8 execute_cmd_read_oper_mode(void) {
    u32 addr = FLASH_OPERATING_MODE_BASEADDR;
    u32 temp = 0;

    {
        temp = flash_read_dword(addr);
        if(temp == 0xFFFFFFFF) {
            return 1;
        } else {
            if(temp == 1) { // 1 이외 값은 모두 쓰레기 값으로 처리함
                func_sw_calibration_mode = 1;
                func_printf("\r\nSW Gain Calibration Mode\r\n");    // dskim - 2022.09.21
            }
            else
                func_sw_calibration_mode = 0;
        }

        // 동작 모드에 관련된 사항은 모두 여기에 기록하도록 함
    }
    return 0;
}
#define DBG_hwcal 0
u8 execute_cmd_load_hw_calibration(u32 value) {
    u32 grab = func_grab_en;    // 만약을 대비해서
    func_busy = 1;

//    //# rus shoud come before getting offset #231226
//    if(DBG_hwcal) func_printf("[DBG_hwcal] execute_cmd_rus ################### \r\n");
//    // HW Gain 조건으로 초기화!!!
//    if(execute_cmd_rus(1)) {
//        func_busy = 0;
//        func_printf("\r\nNo Flash Memory Data - User Preset\r\n");
//        return CMD_ERR9;
//    }

    // 불필요한 동작 하지 않도록
    if(REG(ADDR_OUT_EN)) {
        func_busy = 0;
        return CMD_ERR5;
    }

//# move to before get_calib_init(); (first offset) #231226
    if(DBG_hwcal) func_printf("[DBG_hwcal] execute_cmd_rus ################### \r\n");
    // HW Gain 조건으로 초기화!!!
    if(execute_cmd_rus(1)) {
        func_busy = 0;
        func_printf("\r\nNo Flash Memory Data - User Preset\r\n");
        return CMD_ERR9;
    }

    update_roic_info();
    tft_set();
    func_init();

    execute_cmd_grab(0);
    //get_calib_init() Offset 까지 얻을지...?
    if(is_load_hw_calibration == 0) {
        is_load_hw_calibration = value;
//      if(execute_cmd_brns()) { // #221021
//          func_busy = 0;
//          return CMD_ERR9;
//      }
        if(DBG_hwcal)func_printf("[DBG_hwcal] get_calib_init ###################### \r\n");
        get_calib_init(); //# get offset after hwcal mode changed
    } else {
        if(execute_cmd_rns_info()) {
            func_busy = 0;
            func_printf("\r\nNo Flash Memory Data - NUC Data\r\n");
            return CMD_ERR9;
        }
    }
    // HW Gain 조건으로 초기화!!!
    if(execute_cmd_rus(1)) {
        func_busy = 0;
        func_printf("\r\nNo Flash Memory Data - User Preset\r\n");
        return CMD_ERR9;
    }


    system_config(); //$
    if(AFE3256_series) 	roic_3256_init(&profile.init);
    else				roic_settimingprofile(&profile.init);
//    roic_settimingprofile(&profile.init); //$
//    update_roic_info(); //$
//    tft_set(); //$
    func_init();
    execute_cmd_grab(grab);
    // HW Gain 조건으로 초기화!!!

    func_busy = 0;
    return 0;
}

#define DBG_flashcheck 0
void execute_cmd_flash_check(void) {
    //##### Allocation CHECK #####
    func_printf("ROM Allocation check...\t");
    u32 allo1st = flash_allo_check_1st();
    u32 allo2nd = flash_allo_check_2nd();
    if ((allo1st != 0) && (allo1st == allo2nd)){
        func_printf("Done\r\n");
    }
    else if (allo1st){
        func_printf("\033[32m"); // green
        func_printf("allo 2nd error! copy from 1st!\r\n");
        func_printf("\033[0m \r\n"); // default
        cp_allo1st_to_allo2nd();
    }
    else if (allo2nd){
        func_printf("\033[32m"); // green
        func_printf("allo 1st error! copy from 2nd!\r\n");
        func_printf("\033[0m \r\n"); // default
        cp_allo2nd_to_allo1st();
    }
    else
    {
        func_printf("\033[31m"); // RED
        func_printf("allo 1st, 2nd error!!!\r\n");
        func_printf("allo DOWNLOAD NEED!!!\r\n");
        func_printf("\033[0m \r\n"); // default
//      write_allo1st_checksum();
        cp_allo1st_to_allo2nd();
    }

    //##### FPGA BITSTREAM CHECK #####
    func_printf("ROM FPGA check...\t");
    u32 fpga2nd = flash_fpga_check_2nd();
    u32 fpga3rd = flash_fpga_check_3rd();
    if(DBG_flashcheck) func_printf("[DBG_flashcheck] fpga2nd = 0x%08x , fpga3rd = 0x%08x\r\n",fpga2nd ,fpga3rd);
    if ((fpga2nd != 0) && (fpga2nd == fpga3rd)){
        func_printf("Done\r\n");
    }
    else if (fpga2nd){
        func_printf("\033[32m"); // green
        func_printf("FPGA 3rd error! copy from 2nd!\r\n");
        func_printf("\033[0m \r\n"); // default
        cp_fpga2nd_to_fpga3rd();
    }
    else if (fpga3rd){
        func_printf("\033[32m"); // green
        func_printf("FPGA 2nd error! copy from 3rd!\r\n");
        func_printf("\033[0m \r\n"); // default
        cp_fpga3rd_to_fpga2nd();
    }
    else
    {
        func_printf("\033[31m"); // RED
        func_printf("FPGA 2nd, 3rd  error!!!\r\n");
        func_printf("FPGA DOWNLOAD NEED!!!\r\n");
        func_printf("\033[0m \r\n"); // default
    }

    //##### FW APPLICATION CHECK #####
    func_printf("ROM FW check...\t");
    u32 fw1st = flash_fw_check_1st();
    u32 fw2nd = flash_fw_check_2nd();
    if ((fw1st != 0) && (fw1st == fw2nd)){
        func_printf("Done\r\n");
    }
    else if (fw1st){
        func_printf("\033[32m"); // green
        func_printf("FW 2nd error! copy from 1st!\r\n");
        func_printf("\033[0m \r\n"); // default
        cp_fw1st_to_fw2nd();
    }
    else if (fw2nd){
        func_printf("\033[32m"); // green
        func_printf("FW 1st error! copy from 2nd!\r\n");
        func_printf("\033[0m \r\n"); // default
        cp_fw2nd_to_fw1st();
    }
    else
    {
        func_printf("\033[31m"); // RED
        func_printf("FW 1st, 2nd error!!!\r\n");
        func_printf("FW DOWNLOAD NEED!!!\r\n");
        func_printf("\033[0m \r\n"); // default
    }

//  write_allo1st_checksum(); //# its for update after.
}


void execute_cmd_triglog(u8 value) {
	func_triglog_on = value;
    func_printf("func_triglog_on = %d\r\n",func_triglog_on);
}

void execute_cmd_fpdiff(void) {
    flash_fpdiff();
}

void execute_cmd_fwdiff(void) {
    flash_fwdiff();
}

void execute_fw_stop(void) {
    fw_stop();
}

void execute_cmd_bnc(u8 value) {
	func_bnc = value;
	REG(ADDR_BNC_CTRL)=func_bnc;
    func_printf("func_bnc = %d\r\n",func_bnc);
}

void execute_cmd_eq(u8 value) {
	func_eq = value;
	u16 reg_eq = func_eq << 8 | (0!=func_eq) ;
	REG(ADDR_EQ_CTRL)=reg_eq;
    func_printf("func_eq = %d\r\n",func_eq);
}

void execute_topvalue_set(u16 value){
	func_image_topvalue = value;
    REG(ADDR_BNC_HIGH)  = func_image_topvalue; // HW B&C data high value
    REG(ADDR_OFGA_LIM)  = func_image_topvalue; // HW offset,gain high value
    REG(ADDR_EQ_TOPVAL) = func_image_topvalue; // HW EQ high value
    func_printf("func_topvalue = %d\r\n",func_image_topvalue);
}

void execute_cmd_rombulkcheck(u8 value) {
    u32 flash_addr, flash_len =0;

    switch (value) {
        case 1 :
        	flash_addr = FLASH_BIT_BASEADDR;
        	flash_len  = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT_SIZE);
            break;
        case 2 :
        	flash_addr = FLASH_BIT2ND_BASEADDR;
        	flash_len  = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_SIZE);
            break;
        case 3 :
        	flash_addr = FLASH_BIT3RD_BASEADDR;
        	flash_len  = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_SIZE);
            break;
        case 4 :
        	flash_addr = FLASH_APP_BASEADDR;
        	flash_len  = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_SIZE);
            break;
        case 5 :
        	flash_addr = FLASH_APP2ND_BASEADDR;
        	flash_len  = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_SIZE);
            break;
        case 6 :
        	break;
        case 7 :
            break;
    }
//	flash_bulk_read(flash_addr, flash_len); // app
	flash_bulk_checksum(flash_addr, flash_len);

}

void execute_cmd_rombulkread(u32 addr, u32 len) {

	flash_bulk_read(addr, len); // app

}
void execute_cmd_fpgareboot(void) {
    REG(ADDR_FPGA_REBOOT) = 0b01;
}
void execute_cmd_doc(void){ //$ 260305
   	u32 timeoutcnt = 0;
    u32 grab = func_grab_en;

   	func_printf("Digital Offset Correction...");

    REG(ADDR_FW_BUSY) = 1;
    execute_cmd_grab(0);
    msdelay(50);

	execute_cmd_wroic(0x0D,  0x4800);
    execute_cmd_wroic(0x94,  0x8001);
    execute_cmd_wroic(0x89,  0x3230);
    execute_cmd_wroic(0x80,  0x082D);
    execute_cmd_wroic(0x4C,  0x0005);
    execute_cmd_wroic(0x51,  0x0306);
    execute_cmd_wroic(0x4B,  0x8003);

    while(!(execute_cmd_rroic(0x4B) >> 14 & 0x1)){
    	msdelay(10);
    	timeoutcnt++;
    	if(10 < timeoutcnt){
    		func_printf("Digital Offset FAIL !!\r\n");
    		break;
    	}
    }

    execute_cmd_wroic(0x4B,  0x0003);
    execute_cmd_wroic(0x4C,  0x8005);
    execute_cmd_wroic(0x0D,  0x0000);
    execute_cmd_wroic(0x94,  0x0001);
    execute_cmd_wroic(0x89,  0x3000);
    execute_cmd_wroic(0x80,  0x080D);

    execute_cmd_grab(grab);
    REG(ADDR_FW_BUSY) = 0;

    func_printf("\t DONE \r\n");
}
