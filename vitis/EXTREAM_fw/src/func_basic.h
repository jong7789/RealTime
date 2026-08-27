/*
 * function.h

 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#include "fpga_info.h"

#ifndef SRC_FUNC_BASIC_H_
#define SRC_FUNC_BASIC_H_

extern u32 func_userset_cmd;
extern u32 func_calib_cmd;
extern u32 func_rddr_token;  //$ 2607131936 deferred rddr token (DOSE number, 0=idle)
extern u32 func_ddrchen_last_written; //$ 2607141159 set_ddr_ch_en cache (invalidate with 0xFFFFFFFF)
extern u32 func_flash_cmd;
extern u32 func_calib_map;
extern u32 func_addr_table;
extern u8 func_reg_addr[12];
extern u8 func_reg_data[12];
extern u32 func_pointx;
extern u32 func_pointy;
extern float func_ds1731_temp[DS1731_NUM];
// TI_ROIC
extern float func_roic_temp;
extern float func_fpga_temp;
extern u32 func_phy_temp;
extern u32 func_phy_valid; //# 2608201543 0 = Marvell temp sensor off / not answering
//# 2608191733 uncorrected die readings + the IC->set temperature mapping
extern float func_fpga_temp_raw;
extern float func_phy_temp_raw;
extern float func_sfp_temp_raw;
extern u32   func_temp_raw_mode; //# 2608191842 1 = XML reports raw die temps ("rtempraw 1")
//# 2608191856 label for the DBG_XMLTEMP traces (see fpga_info.h)
#define XMLTEMP_MODE_STR (func_temp_raw_mode ? "raw" : "set")
float ic_to_set_temp(float t_ic);
float round_away(float v);
float fabs_f(float v); //# 2608191920 local float abs (BD outlier filter)
//# 2608191217 SFP module DDM temperature (SFF-8472 A2h 96-97)
extern float func_sfp_temp;
extern u32   func_sfp_valid;
extern int once88m; //# 2605121743 one-shot flag for deferred m88x33xx_init in check_sfp_stat
extern u32 func_rns_valid;		// 0.xx.07
extern u32 bcal_once;			//$ 250305
//# 2606151121 OFFSET_AFTER_ETH: defer boot offset grab until ethernet connected
//             0 = legacy (immediate grab in get_calib_init, may be unstable)
//             1 = grab offset only after func_ether_conn (sensor stabilized
//                 during link/discovery; image is only viewed post-connect)
//#ifndef OFFSET_AFTER_ETH
//#define OFFSET_AFTER_ETH 0 //# 2606171733
//#endif
//extern u32 func_offset_after_eth;	//# 2606151121 pending deferred offset grab
//void check_offset_after_eth(void);	//# 2606151121 main-loop watcher
//$ 2606171840 OFFSET_AFTER_TMR: defer boot offset grab by a fixed delay.
//  Replaces ETH-trigger -> sensor stabilizes during boot-fixed window, no
//  ethernet dependency. Uses ADDR_FREERUN_CNT (100MHz, wraps ~42.9s) so
//  TMR_MS must stay below 42_000.
#ifndef OFFSET_AFTER_TMR
#define OFFSET_AFTER_TMR    1            //$ 2606171840 1=enable timer-based deferred grab
#endif
//#define OFFSET_AFTER_TMR_MS  18000u                          //$ 2606171840 delay [ms] after arm
//#define OFFSET_AFTER_TMR_MS  34000u                          //$ 2607011220 18 sec-> 24 cause 1st offset gate dancha
#define OFFSET_AFTER_TMR_MS_DEFAULT  18000u                    //$ 2607061533 default for most models
#define OFFSET_AFTER_TMR_MS_3643R    10000u                    //$ 2607061533 EXT3643R needs longer settle
extern u32 func_offset_after_tmr_cnt; //$ 2607061533 runtime FREERUN threshold (model-dependent)
extern u32 func_offset_after_tmr;     //$ 2606171840 1=pending deferred offset grab
extern u32 func_offset_after_tmr_t0;  //$ 2606171840 FREERUN snapshot at arm time
void check_offset_after_tmr(void);    //$ 2606171840 main-loop watcher (fires at t0+TMR_MS)

//$ 2607151427 OFFSET_REPEAT: after the boot offset timer fires, keep re-grabbing
//  offset every INTERVAL_MS until ethernet connects (func_ether_conn), up to
//  WINDOW_MS total. Count-based window (WINDOW/INTERVAL) keeps a >42.9s total
//  wrap-safe; each interval diff stays < 42.9s (FREERUN wrap period).
#ifndef OFFSET_REPEAT_EN
#define OFFSET_REPEAT_EN           1        //$ 2607151427 1=enable periodic re-grab, 0=disable
#endif
#define OFFSET_REPEAT_INTERVAL_MS  10000u   //$ 2607151427 re-grab period [ms] (keep < 42000)
#define OFFSET_REPEAT_WINDOW_MS    90000u   //$ 2607151427 total window [ms]; max = WINDOW/INTERVAL
extern u32 func_offset_repeat;              //$ 2607151427 1=periodic re-grab active
extern u32 func_offset_repeat_last;         //$ 2607151427 FREERUN at last re-grab
extern u32 func_offset_repeat_n;            //$ 2607151427 re-grabs done this window
void check_offset_repeat(void);             //$ 2607151427 main-loop watcher (periodic pre-eth)

extern Profile_HandleDef profile;		// dskim - 21.07.22


void gige_send_message4(u16 event, u16 channel, u16 data_len, u8 *data);

int uart_receive();
void uart_command(void);
int rsscanf(const char* str, const char* format, ...);
int rstrcmp(char *a, char *b);
void float_printf(float val, u8 digits);
void usdelay(u32 usecond);
void msdelay(u32 msecond);

void func_init(void);
void reset_default(void);
void save_fw_ver(void);
void load_fw_ver(void);
//void load_fpga_model(void);
void load_flash(void);
void fpga_init(void);
//$ 2604291730 Boot-time ROI register init to apply BASE_OFFSETX/Y
void roi_init(void);
void ddr_init(void);
void set_ddr_ch_en(void);                                   //$ 2604301700 ADDR_DDR_CH_EN composer
void pwr_init(void);
void roic_3256_init(void);
void roic_3256_settingprofile(Profile_Def *profile);
void roic_init(void);
//void roic_settimingprofile(u32 mclk, u32 str, u32 tirst, u32 tshr_lpf1, u32 tshs_lpf2, u32 tgate);
void roic_settimingfilter(Profile_Def *profile);
void roic_settimingprofile(Profile_Def *profile);	// dskim - 21.07.22
void temp_init(void);
u32 ds1731_init(void);
void phy_temp_init(void);
u32  sfp_temp_init(void); //# 2608191217 enable I2C slave 4 + set SFP byte pointer via ADDR_I2C_MODE
void xadc_init(void);
void bw_align(void);
void bw_align_fpga(u32 *bcalmid);
// 2604242200 FW-driven bit-align (separated bit_stable + word_align stages)
// 2604250030 DBG_BCALFW compile-time switch: 0=quiet (only user-friendly lines)
//                                            1=verbose (low-level dbg traces)
#ifndef DBG_BCALFW
#define DBG_BCALFW 0
#endif

#if DBG_BCALFW
#define BCALFW_DBG(...) func_printf(__VA_ARGS__)
#else
#define BCALFW_DBG(...) ((void)0)
#endif

// 2604250600 Boot/temp-triggered alignment selector (in update_image()):
//             0 = legacy HW FSM (bw_align)
//             1 = FW-driven (bw_align_fw_run_all)
#ifndef BOOT_BCAL_USE_FW
#define BOOT_BCAL_USE_FW 1
#endif

// 2604251000 Double-pass mode for bcalfw run_all:
//             0 = single sweep (uses BCAL_FW_STABLE_WAIT_US_FAST = 1us)
//             1 = run twice (FAST then SLOW) for stable_map comparison
#ifndef BCAL_FW_DOUBLE_PASS
#define BCAL_FW_DOUBLE_PASS 0
#endif

// per-tap settle time options (us). Runtime variable bcalfw_wait_us picks one.
#define BCAL_FW_STABLE_WAIT_US_FAST 1
#define BCAL_FW_STABLE_WAIT_US_SLOW 10000

extern u32 bcalfw_wait_us;   // current per-tap wait (set by run_all/cmds)

typedef enum {
    BCAL_FW_PULSE_CE = 0,
    BCAL_FW_PULSE_RST,
    BCAL_FW_PULSE_BS,
    BCAL_FW_PULSE_PROBE
} bcal_fw_pulse_t;

typedef struct {
    int  eye_start;        // -1 if not found
    int  eye_end;          // -1 if not found
    int  eye_mid;          // -1 if not found
    int  eye_width;
    u32  par_log[32];      // sdata_par snapshot per tap
    u8   stable_map[32];   // 1=stable, 0=unstable
    u8   ff00_map[32];     // 1=ff00 detected on this tap
    int  status;           // 0=ok, -1=fail
} bcal_fw_stable_result_t;

typedef struct {
    int  bitslip_count;    // 0..95, -1 if fail
    u32  par_at_match;
    int  status;           // 0=ok, -1=fail
} bcal_fw_word_result_t;

typedef struct {
    bcal_fw_stable_result_t stable;
    bcal_fw_word_result_t   word;
    int                     overall_status; // 0=ok, 1=stable_fail, 2=word_fail
} bcal_fw_full_result_t;

void bw_align_fw_init(void);
void bw_align_fw_exit(void);
void bw_align_fw_set_ch(u8 ch);
void bw_align_fw_pulse(bcal_fw_pulse_t type);
u32  bw_align_fw_read_par(void);
u32  bw_align_fw_read_status(void);
int  bw_align_fw_bit_stable(u8 ch, bcal_fw_stable_result_t *res, u8 verbose);
int  bw_align_fw_word_align(u8 ch, bcal_fw_word_result_t *res, u8 verbose);
int  bw_align_fw_run_one_ch(u8 ch, bcal_fw_full_result_t *res, u8 verbose);
void bw_align_fw_run_all(u8 verbose);

//$ 2606021620 BCAL_FW_PAR_TARGET moved here so func_cmd.c can use it
#define BCAL_FW_PAR_TARGET       0xFFF000u

//$ 2606021620 Snapshot struct/globals for execute_cmd_bcalfw_rdata in func_cmd.c
typedef struct {
    int s_mid; int s_width; int s_start; int s_end; int s_status;
    int w_bs;  u32 w_par;   int w_status;
    u8  stable_map[32];
} bcalfw_snap_t;
#define BCALFW_SNAP_MAX  32
extern bcalfw_snap_t  bcalfw_snap[BCALFW_SNAP_MAX];
extern u32            bcalfw_snap_cnt;
extern u32            bcalfw_snap_wait_us;

void tft_set(void);
void ext_trig_set(void);
u32 set_str_data(u8 *data);
void get_str_data(u32 value, u8 *data);
u32 set_userset_data(u32 table, u8 step);
void get_userset_data(u32 table, u32 value, u8 step);
void execute_user_cmd(void);
void execute_calib_cmd(void);
void execute_rddr_cmd(void);   //$ 2607131936 deferred rddr token handler
void execute_flash_cmd(void);
void genicam_command(void);
void update_image(void);
void update_bcal1(void);
void update_trig(void);
void update_acc(void);
void update_data(void);
void update_sleep(void);
void update_fwtrig(void);
void update_hwload(void);
void checker_rom(void);
void update_defect(void);
void check_sfp_stat(void);   // 2604221600 SFP/RXAUI auto-switch polling
//$ 2606111729 Gate SFP polling to EXT3643R; add check_lan_stat for LAN-only
void check_lan_stat(void);   // deferred full Marvell PHY init for LAN-only models
u32 atoi2(u8* arr);
void get_register(void);
void set_register(void);
// TI_ROIC
void update_roic_info(void);	// dskim
void read_ds1731_temp(void);
// TI_ROIC
void read_roic_temp(void);
void read_phy_temp(void);
void read_sfp_temp(void); //# 2608191217 decode SFP DDM temperature from ADDR_I2C_RDATA4
u32  xml_phy_temp(void);  //# 2608191647 XML_TEMP_PHY value: SFP temp on SFP link, else Marvell
u32  xml_fpga_temp(void); //# 2608191842 XML_TEMP_FPGA value (float bits), honours rtempraw
void read_fpga_temp(void);
// TI_ROIC
//u32 get_roic_data(u32 num);
void set_roic_data(u32 num, u32 data);	// dskim
u8 get_roic_data(u32 num);
void firmware_reset(void);
void system_config(void);
void roic_set_wake();
void roic_set_sleep();
void fpga_set_wake();
void fpga_set_sleep();
void set_sleepmode(u32 data);
u32 get_run_time();
void set_pwdac(u32 en, u32 volt, u32 time);
void set_pixpos(u32 en, u32 pos_h, u32 pos_v);

u32 flash_allo_check(u32 addr);
u32 flash_allo_check_1st(void);
u32 flash_allo_check_2nd(void);

u32 flash_fpga_check_2nd(void);
u32 flash_fpga_check_3rd(void);
u32 flash_fw_check_1st(void);
u32 flash_fw_check_2nd(void);
u32 flash_calc_sum(u32 baseaddr, u32 lenth);
u32 flash_compare(u32 aaddr, u32 baddr, u32 lenth);
u32 flash_bulk_read(u32 baseaddr, u32 lenth);
u32 flash_bulk_checksum(u32 baseaddr, u32 lenth);
void wflash(u32 addr, u32 data);

//void write_allo1st_checksum(void);
void cp_allo1st_to_allo2nd(void);
void cp_allo2nd_to_allo1st(void);

void cp_fpga2nd_to_fpga3rd(void);
void cp_fpga3rd_to_fpga2nd(void);
void cp_fw1st_to_fw2nd(void);
void cp_fw2nd_to_fw1st(void);
void flash_cp(u32 sourceaddr, u32 targetaddr, u32 cplength);
void flash_fpdiff(void);
void flash_fwdiff(void);
void fw_stop(void);
void set_able_func(void);
void get_able_func(void);

typedef struct {
	u8      model[32];
    u8      able_binn_num;
    u8      able_gain_num;
    u8      able_dnr;
} str_model_func_able;

#define MAX_MODEL_NUM 16

#endif /* SRC_FUNC_BASIC_H_ */
