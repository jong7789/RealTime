/*
 * func_cmd.h
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#ifndef SRC_FUNC_CMD_H_
#define SRC_FUNC_CMD_H_

#include "xil_types.h"
#include "calib.h"
#include "fpga_info.h"

//#ifdef EXT1024R // 241014 jyp
//  #define MAX_FRATE            25.0     // fps 15->25 (2.5G -> 10G)
//  #define MAX_EWT            2000000    // us
//#elif defined EXT1616R
//    #if defined EXT1616RL
//        #define MAX_FRATE        30.0   // fps
//    #else
//        #define MAX_FRATE        40.0   // fps
//    #endif
//    #define MAX_EWT            2000000  // 2sec us
//#elif defined EXT4343R
//    #ifdef defined EXT4343R_1
//        #define MAX_FRATE        15.0   // fps
//    #elif defined EXT4343R_2
//        #define MAX_FRATE        15.0   // fps
//    #elif defined EXT4343R_3
//        #define MAX_FRATE        7.0    // fps
//	  #elif defined EXT4343R_4
//		  #define MAX_FRATE		   15.0   // fps
//    #elif defined EXT4343RC
//        #define MAX_FRATE        15.0   // fps
//    #elif defined EXT4343RC_1
//        #define MAX_FRATE        15.0   // fps
//    #elif defined EXT4343RC_2
//        #define MAX_FRATE        15.0   // fps
//    #elif defined EXT4343RC_3
//        #define MAX_FRATE        7.0    // fps a-si
//    #elif defined EXT4343RCL
//        #define MAX_FRATE        8.0    // fps
//    #elif defined EXT4343RCL_1
//        #define MAX_FRATE        8.0    // fps
//    #elif defined EXT4343RCL_2
//        #define MAX_FRATE        8.0    // fps
//    #elif defined EXT4343RCL_3
//        #define MAX_FRATE        4.0    // fps a-si
//    #elif defined EXT4343RI_2
//        #define MAX_FRATE        20.0   // 28able 30.0 // fps
//	  #elif defined EXT4343RI_4
//		  #define MAX_FRATE		   20.0	  // 28able 30.0 // fpgs
//    #elif defined EXT4343RCI_1
//        #define MAX_FRATE        20.0   // 28able 30.0 // fps
//    #elif defined EXT4343RCI_2
//        #define MAX_FRATE        20.0   // 28able 30.0 // fps
//    #else
//        #define MAX_FRATE        15.0   // fps
//    #endif
//  #define MAX_EWT            2000000    // us
//#elif defined EXT2430R
//    #if defined EXT2430RI
//        #define MAX_FRATE        25.0   // fps 10G
//        #define MAX_EWT      2000000    // us
//    #else
//        #define MAX_FRATE        12.0   // fps
//        #define MAX_EWT      2000000    // us
//    #endif
//#elif defined EXT2832R
//    #define MAX_FRATE            30.0   // fps
//    #define MAX_EWT          2000000    // us
//#elif defined EXT810R
//    #define MAX_FRATE            10.0   // fps
//    #define MAX_EWT          2000000    // us
//#elif defined EXT2430RD
//    #define MAX_FRATE            10.0   // fps
//    #define MAX_EWT          2000000    // us
//#endif

#define MAX_EWT          2000000    // us

#define MAX_FRATE_EXT2      0           // 220120 mbh
#define MAX_FRATE_STATIC    2           // 220120 mbh
#define MIN_FRATE_STATIC    0.0055      // 220120 mbh

#define MAX_EWT_EXT2      2000000       // 220120 mbh
#define MAX_EWT_STATIC    180000000     // 180 sec 220121mbh
#define MIN_EWT_STATIC       500000     // 500 msec 220121mbh
//#define MAX_FRATE_RCL_BINNING        7.5    // fps

#define MIN_FRATE            0.1
#define MIN_EWT                0        // 1ms
#define MAX_USERSET            4

typedef enum {
    ACQMODE_ROLL,
    ACQMODE_EXT0,
    ACQMODE_EXT1,
    ACQMODE_EXT2,
    ACQMODE_STATIC,
    ACQMODE_NULL,
} ACQMODE_ENUM;
extern u32 func_acqmode; //220121mbh

extern float afe_time_us;
extern float data_time_us;
extern float line_time_us;
extern float scan_time_us;
extern float trst_time_us;
extern float func_frate;
extern float func_frate_max;
extern float func_frate_min;

extern float func_frate_max_calc;
extern float func_frate_calc    ;
//extern float ether_max_calc; //#231017

extern float func_roll_frate; //220112mbh
extern float func_ext0_frate;
extern float func_ext1_frate;
extern float func_ext2_frate;
extern float func_static_frate;


extern u32 func_gewt;
extern u32 func_gewt_max;
extern u32 func_gewt_min;
extern u32 func_rewt;


extern u32 func_roll_ewt  ; //220111mbh
extern u32 func_ext0_ewt  ;
extern u32 func_ext1_ewt  ;
extern u32 func_ext2_ewt  ;
extern u32 func_static_ewt;
extern u32 func_roicstr;

extern u32 func_trig_frate;
extern u32 func_trig_duty;

extern u32 func_out_en;
extern u32 func_width;
extern u32 func_height;
extern u32 func_offsetx;
extern u32 func_offsety;
extern u32 func_pixfmt;

extern u32 func_access_level;
extern u32 func_sync_source;
extern u32 func_intsync_ldead;
extern u32 func_test_pattern;
extern u32 func_grab_en;
extern u32 func_frame_num;
extern u32 func_frame_val;
extern u32 func_trig_mode;
extern u32 func_trig_delay;
extern u32 func_delay_unit;
extern u32 func_shutter_mode;
extern u32 func_exp_mode;
extern u32 func_ddr_out;
extern u32 func_gain_cal;
extern u32 func_d2m;
extern u32 func_offset_cal;
extern u32 func_defect_cal;
extern u32 func_defect_map;
extern u32 func_dgain;
extern u32 func_img_proc;
extern u32 func_binning_mode;
extern u32 func_binning;
extern u32 func_bright;
extern u32 func_contrast;
extern u32 func_table;
extern float func_temp;
// TI_ROIC
extern u32 func_roic_data[16];    // dskim

extern float func_roic_intrst;
extern float func_roic_cds1;
extern float func_roic_cds2;
extern float func_roic_fa1;
extern float func_roic_fa2;
// TI_ROIC
//extern float func_roic_fa;
//extern float func_roic_dead;
//extern float func_roic_mute;
extern float func_gate_oe;

extern float func_gate_xon;
extern float func_gate_flk;
extern float func_gate_xonflk;
extern float func_gate_rcycle;
extern u32 func_erase_time;
extern u32 func_gate_crmode;
extern u32 func_gate_srmode;
extern u32 func_gate_rnum;
extern u32 func_sexp_time;
extern u32 func_tft_seq;
extern u32 func_hw_debug;
extern u32 func_sw_debug;

extern u32 func_img_avg_old;
extern u32 func_img_avg_dose0;
extern u32 func_img_avg_dose1;
extern u32 func_img_avg_dose2;
extern u32 func_img_avg_dose3;
extern u32 func_img_avg_dose4;
extern u32 func_ref_avg_max;
extern u32 func_ref_num;
extern u32 func_defect_sens;
extern u32 func_gainref_numlim; //#230327

extern u32 func_defect[MAX_DEFECT][2];
extern u32 func_defect2[MAX_DEFECT][2];
extern u32 func_defect_cnt;
extern u32 func_defect_cnt2;
extern u32 func_rdefect[MAX_LINE_DEFECT];
extern u32 func_cdefect[MAX_LINE_DEFECT];
extern u32 func_rdefect_cnt;
extern u32 func_cdefect_cnt;

// dskim - 21.03.02 - factory map
extern u32 func_defect3[MAX_DEFECT][2];
extern u32 func_defect_cnt3;
extern u32 func_rdefect3[MAX_LINE_DEFECT];
extern u32 func_cdefect3[MAX_LINE_DEFECT];
extern u32 func_rdefect_cnt3;
extern u32 func_cdefect_cnt3;

extern u32 func_busy;
extern u32 func_busy_time;

extern u32 func_read_defect;      // dskim - 0.xx.08
extern u32 func_trig_valid;       // dskim - 0.xx.08
extern u32 func_trig_out_active;  // dskim - 0.xx.08
extern u32 func_trig_in_active;   // dskim - 0.xx.08
extern u32 func_trig_delay_min;   // dskim - 0.xx.08
extern u32 func_trig_delay_max;   // dskim - 0.xx.08

extern u32 func_check_gain_calib;
extern u32 func_check_booting;    // dskim - 21.02.15

extern u32 func_offset_add_value; // dskim - 21.04.09
extern u32 func_stop_save_flash;  // dskim - 21.07.22

extern u32 func_edge_cut_left;
extern u32 func_edge_cut_right;
extern u32 func_edge_cut_top;
extern u32 func_edge_cut_bottom;
extern s32 func_edge_cut_value;

extern u32 func_edge_left;
extern u32 func_edge_right;
extern u32 func_edge_top;
extern u32 func_edge_bottom;

extern u32 func_image_acc;        // dskim - 21.10.20
extern u32 func_image_acc_value;
//extern u32 func_image_edge;
//extern u32 func_image_edge_value;
//extern u32 func_image_edge_offset;
extern u32 func_image_dnr;
extern u32 func_image_dnr_value;
extern u32 func_image_dnr_offset;
extern u32 func_trig_auto_offset;
extern u32 func_api_ext_trig;
extern u32 func_api_ext_trig_flag;
extern u32 func_apitrig_defence;
extern u32 func_hwload_flag;      //# 221021

extern u32 func_re_defect;        // dskim - 21.11.03

extern u32 func_exposure_type;        // dskim - dynamic, static
extern u32 func_static_avg_enable;    // dskim - 22.01.19

extern u32 func_insert_rst_num;
extern u32 func_bcal1_token;
extern u32 func_tempbcal;
extern u32 func_grabbcal; // When grab enabled, BCAL/temperature is updated. //220222mbh

extern u32 func_sleepmode;
extern u32 func_sleep;
extern u32 Token_wake;
extern u32 Token_sleep;
extern u32 func_ether_conn;
extern u32 func_acc_read;

extern u32 func_sleep_mode_enable; // dskim - 2022.04.04
extern u32 func_sleep_mode_time;
extern u32 func_sleep_mode_time_m;
extern u32 func_image_acc_auto_reset;

extern volatile u32 func_boot_count;
extern volatile u32 func_grab_count;
extern u32 func_oper_time_h;
extern u32 func_oper_time_m;
extern u32 func_oper_time_s;
extern u32 func_oper_time_start;
extern u32 func_oper_time_stop;
extern u8  func_oper_time_select;

extern u8 func_sw_calibration_mode;
extern u8 is_load_hw_calibration;

extern u8 is_factory_map_mode;
extern u8 func_gainmap_limit;

extern u32 func_acc_value;
extern u8 func_triglog_on;

extern u32 func_image_topvalue;
extern u32 func_bnc;
extern u32 func_eq;

extern u32 func_read_defect_stt; //$ 250627
extern u32 func_read_defect_num; //$ 250627
extern u32 func_ifs_index;		 //$ 260224

//extern u8 func_able_binn_num; //# 230926
//extern u8 func_able_gain_num;
//extern u8 func_able_dnr; //# 250909 cmmt

extern u8 func_bw_align_done; //# 231226

void execute_func_cmd(void);

void execute_cmd_auth(u32 data);
void execute_cmd_psel(u32 data);
void execute_cmd_psel_val(u32 data, u32 val);
void execute_cmd_gmode(u32 num, u32 val);
void execute_cmd_pmode(u32 data);
void execute_cmd_pdead(u32 data);
void execute_cmd_bmode(u32 data);
void execute_cmd_bmode_gain(u32 data);
void execute_cmd_bmode_gain_force(u32 data);
void execute_cmd_tmode(u32 data);
void execute_cmd_tdly(u32 data);
void execute_cmd_smode(u32 data);
void execute_cmd_emode(u32 data);
void execute_cmd_roi(u32 offsetx, u32 offsety, u32 width, u32 height);
void execute_cmd_grab(u32 data);
void execute_cmd_frate2ewt(u32 data);
void execute_cmd_frate(u32 data);
//void execute_cmd_frate_call(void);
void execute_cmd_Acqmode(void);
void execute_cmd_tfrate(u32 frate, u32 duty, u32 num);
void execute_cmd_fmax(void);
void execute_cmd_fmax2(u32 MAIN_CLK);    // dskim
void execute_cmd_gewt(u32 data);
void execute_cmd_gewt_calc(void);
void execute_cmd_emax(void);
void execute_cmd_gain(u32 data);
void execute_cmd_offset(u32 data);
void execute_cmd_defect(u32 data);
void execute_cmd_dmap(u32 data);
void execute_cmd_ghost(u32 data);
// TI_ROIC
void execute_cmd_ifs(u32 data);        // dskim
void execute_cmd_dgain(u32 data);
void execute_cmd_iproc(u32 data);
void execute_cmd_reboot(void);
void execute_cmd_rtemp(void);
void execute_cmd_wus(u32 data);
u8 execute_cmd_rus(u32 data);
u8 execute_cmd_rus2(u32 data);        // dskim
void execute_cmd_wbs(void);
u8 execute_cmd_rbs(void);
void execute_cmd_wns(void);
void execute_cmd_bwns(void);
void execute_cmd_bwns1(void);
void execute_cmd_bwns2(void);
void execute_cmd_bwns3(void);
void execute_cmd_bwns4(void);
u8 execute_cmd_rns_info(void);
u8 execute_cmd_rns(void);
u8 execute_cmd_brns(void);
u8 execute_cmd_brns_old(void);
void execute_cmd_wds(void);
void execute_cmd_wds_factory(void);
void execute_cmd_wds_manual(void);
u8 execute_cmd_rds(void);
void execute_cmd_rflash(u32 addr);
void execute_cmd_hwdbg(u32 data);
void execute_cmd_swdbg(u32 data);
void execute_cmd_bright(u32 data);
void execute_cmd_contra(u32 data);
void execute_cmd_wflash(u32 addr, u32 data);
void execute_cmd_reep(u32 addr);
void execute_cmd_weep(u32 addr, u32 data);
void execute_cmd_erase(u32 data);
void execute_cmd_flashrw(u32 data);
void execute_cmd_cddr(u32 data);
void execute_cmd_wddr(u32 data, u32 level);
void execute_cmd_rddr(u32 data, u32 level);
void execute_cmd_gcal(void);
void execute_cmd_ucal(void);
void execute_cmd_sens(u32 data);
void execute_cmd_dcal(u32 data);
u32 execute_cmd_wdot(u32 pointx, u32 pointy, u32 erase);
u32 execute_cmd_wcdot(u32 col, u32 erase);
u32 execute_cmd_wrdot(u32 row, u32 erase);
void execute_cmd_rdot(u32 data);
void execute_cmd_frdot(u32 target, u32 num);
void execute_cmd_rdot_binning(u32 mode, u32 x_row, u32 y_col);
void execute_cmd_cdot(u32 data);
void execute_cmd_cdot_fpga(u32 data);        // dskim - 21.02.25
void execute_cmd_wroic(u32 addr, u32 data);
u32 execute_cmd_rroic(u32 addr);
void execute_cmd_mac(u32 addr_h, u32 addr_l);
void execute_cmd_ip(u32 data0, u32 data1, u32 data2, u32 data3);
void execute_cmd_smask(u32 data0, u32 data1, u32 data2, u32 data3);
void execute_cmd_gate(u32 data0, u32 data1, u32 data2, u32 data3);
void execute_cmd_ipmode(u32 data);
void execute_cmd_intrst(u32 data);
void execute_cmd_cds1(u32 data);
void execute_cmd_cds2(u32 data);
void execute_cmd_fa(u32 data);
void execute_cmd_fa1(u32 data);
void execute_cmd_fa2(u32 data);
void execute_cmd_dead(u32 data);
void execute_cmd_mute(u32 data);
void execute_cmd_oe(u32 data);
void execute_cmd_xon(u32 data);
void execute_cmd_flk(u32 data);
void execute_cmd_xonflk(u32 data);
void execute_cmd_rcycle(u32 data);
void execute_cmd_crmode(u32 data);
void execute_cmd_srmode(u32 data, u32 num);
void execute_cmd_tseq(u32 data);
void execute_cmd_timg(u32 data);
void execute_cmd_rclk();
void execute_cmd_diag(u32 data);
void execute_cmd_bcal_rdata();
void execute_cmd_wsm(u32 time100ms);
void execute_cmd_rsm(u32 smsel);
void execute_cmd_d2m_set(Profile_Def *profile);
void execute_cmd_d2m_en();
void execute_cmd_d2m_dis();
void execute_cmd_edge(u32 edge, u32 offset);
void execute_cmd_dnr(u32 edge, u32 offset);
void execute_cmd_dnr_setting(u32 dnr, u32 edge, u32 offset);    // dskim - 21.10.20
void execute_cmd_acc(u32 enable, u32 pagelimit);
void execute_cmd_racc(u32 enable);
void execute_cmd_osd(u32 on, u32 size, u32 mode);
void execute_cmd_eao(u32 enable);
void execute_api_ext_trig(u32 enable);
void execute_fw_ext_trig(u32 num);
void execute_fw_ext_trig_rst(u32 scannum, u32 rstnum);
void execute_cmd_extrst(u32 mode, u32 detectime_us);
void execute_cmd_rom(void);
void execute_cmd_romread();
void execute_cmd_fpgajudge(u32 addr, u32 truedown, u32 trueup);
void execute_cmd_read_video(u32 cnt_addr, u32 avcn_addr, u32 bglw_addr);
void execute_cmd_rtimingprofile();
void execute_cmd_gtimingprofile();
void execute_cmd_atimingprofile();
void excute_cmd_tp_graph();
void execute_cmd_settimingprofile(u32* data);
void execute_cmd_read_defect(u32 data);            // dskim - 0.xx.08
void execute_cmd_trig_valid(u32 data);             // dskim - 0.xx.08
void execute_cmd_trig_active(u32 data, u32 inout); // dskim - 0.xx.08
void execute_cmd_re_defect(void);                  // dskim - 21.02.25
void execute_cmd_write_detector_sn(void);
u8 execute_cmd_read_detector_sn(void);
void execute_cmd_write_tft_sn(void);               // dskim - 22.01.03
u8 execute_cmd_read_tft_sn(void);                  // dskim - 22.01.03
u8 execute_cmd_parser(u32 data);
u8 execute_cmd_edgemask_calc();
u8 execute_cmd_edge_cut_save(u32 data);
void execute_cmd_bmode_edge_cut(u32 data);
void execute_cmd_read_edge_cut(void);
u32 execute_cmd_wdot_factory(u32 pointx, u32 pointy, u32 erase);
u32 execute_cmd_wcdot_factory(u32 col, u32 erase);
u32 execute_cmd_wrdot_factory(u32 row, u32 erase);
void execute_cmd_exposure_type(u32 data);
void execute_cmd_reset_device(void);
void execute_cmd_wake();
void execute_cmd_sleep();
void execute_cmd_sleep_mode(u32 data);
u32 execute_cmd_check_acq_stop_timeover(u32 break_sign);
void execute_cmd_pwdac(u32 en, u32 volt, u32 time);
void execute_cmd_pixpos(u32 en, u32 pos_h, u32 pos_v );
void set_cmd_op_boot_count(u32 count);
void set_cmd_op_grab_count(u32 count);
void execute_cmd_op_boot_count(void);
void execute_cmd_op_grab_count(void);
void execute_cmd_op_acq_start(void);
void execute_cmd_op_acq_stop(void);
void execute_cmd_write_oper_time(void);
u8 execute_cmd_read_oper_time(void);
void execute_cmd_write_oper_mode(u32 value);
u8 execute_cmd_read_oper_mode(void);
void execute_cmd_flash_check(void);                //# 220919
void execute_cmd_fpdiff(void);
void execute_cmd_fwdiff(void);
u8 execute_cmd_load_hw_calibration(u32 data);
void execute_cmd_fpgareboot(void);
void execute_avaliable_check(void);                //# 230721
void execute_cmd_triglog(u8 value);
void execute_cmd_doc(void);						   //$ 260305

void execute_cmd_bnc(u8 data);
void execute_cmd_eq(u8 data);
void execute_topvalue_set(u16 data);
void execute_cmd_rombulkcheck(u8 data);
void execute_cmd_rombulkread(u32 addr, u32 len);

typedef struct {
    u8         smsel;
    u8         smname[10];
} SM_STRUCT;

#endif /* SRC_FUNC_CMD_H_ */

