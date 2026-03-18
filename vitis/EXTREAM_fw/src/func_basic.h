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
extern u32 func_rns_valid;		// 0.xx.07
extern u32 bcal_once;			//$ 250305

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
void ddr_init(void);
void pwr_init(void);
void roic_3256_init(Profile_Def *profile);
void roic_init(void);
//void roic_settimingprofile(u32 mclk, u32 str, u32 tirst, u32 tshr_lpf1, u32 tshs_lpf2, u32 tgate);
void roic_settimingfilter(Profile_Def *profile);
void roic_settimingprofile(Profile_Def *profile);	// dskim - 21.07.22
void temp_init(void);
u32 ds1731_init(void);
void phy_temp_init(void);
void xadc_init(void);
void bw_align(void);
void bw_align_fpga(u32 *bcalmid);
void tft_set(void);
void ext_trig_set(void);
u32 set_str_data(u8 *data);
void get_str_data(u32 value, u8 *data);
u32 set_userset_data(u32 table, u8 step);
void get_userset_data(u32 table, u32 value, u8 step);
void execute_user_cmd(void);
void execute_calib_cmd(void);
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
u32 atoi2(u8* arr);
void get_register(void);
void set_register(void);
// TI_ROIC
void update_roic_info(void);	// dskim
void read_ds1731_temp(void);
// TI_ROIC
void read_roic_temp(void);
void read_phy_temp(void);
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
