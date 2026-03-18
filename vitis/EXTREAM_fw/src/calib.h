/*
 * calib.h
 *
 *  Created on: 2019. 10. 7.
 *      Author: ykkim90
 */

#ifndef SRC_CALIB_H_
#define SRC_CALIB_H_
#include "fpga_info.h"                // dskim - 0.xx.08
#define DDR_BIT_DEPTH            8

extern u32 DDR_CH0_BIT_DEPTH   ;
extern u32 DDR_CH1_BIT_DEPTH   ;
extern u32 DDR_CH2_BIT_DEPTH   ;
extern u32 ADDR_NUC_DATA       ;
extern u32 ADDR_AVG_DATA_DOSE0 ;
extern u32 ADDR_AVG_DATA_DOSE1 ;
extern u32 ADDR_AVG_DATA_DOSE2 ;
extern u32 ADDR_AVG_DATA_DOSE3 ;
extern u32 ADDR_AVG_DATA_DOSE4 ;
extern u32 ADDR_AVG_DATA_DOSE5 ;
extern u32 ADDR_AVG_DATA_DOSE6 ;
extern u32 ADDR_FLASH_READ_TEMP;

//#if defined(GEV10G)
//    #define DDR_CH0_BIT_DEPTH    16
//    #define DDR_CH1_BIT_DEPTH    32
//    #define DDR_CH2_BIT_DEPTH    16
//#else
//    #define DDR_CH0_BIT_DEPTH    16
//    #define DDR_CH1_BIT_DEPTH    128
//    #define DDR_CH2_BIT_DEPTH    32
//#endif

#define ADDR_RAW_IMAGE            0

//#define ADDR_AVG_DATA_DOSE0        (ADDR_NUC_DATA             + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))) 210108 mbh

//#define ADDR_NUC_DATA        (ADDR_RAW_IMAGE      + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH0_BIT_DEPTH/DDR_BIT_DEPTH)*2))
//#define ADDR_AVG_DATA_DOSE0  (ADDR_NUC_DATA       + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH1_BIT_DEPTH/DDR_BIT_DEPTH))) // offset
//#define ADDR_AVG_DATA_DOSE1  (ADDR_AVG_DATA_DOSE0 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
//#define ADDR_AVG_DATA_DOSE2  (ADDR_AVG_DATA_DOSE1 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
//#define ADDR_AVG_DATA_DOSE3  (ADDR_AVG_DATA_DOSE2 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
//#define ADDR_AVG_DATA_DOSE4  (ADDR_AVG_DATA_DOSE3 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
//#define ADDR_AVG_DATA_DOSE5  (ADDR_AVG_DATA_DOSE4 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
//#define ADDR_AVG_DATA_DOSE6  (ADDR_AVG_DATA_DOSE5 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))) // acc
//#define ADDR_FLASH_READ_TEMP (ADDR_AVG_DATA_DOSE6 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))) // 0x7d3a000

// //#define ADDR_NUC_DATA        (ADDR_RAW_IMAGE      + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH0_BIT_DEPTH/DDR_BIT_DEPTH)*2))
// //#define ADDR_AVG_DATA_DOSE0  (ADDR_NUC_DATA       + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH1_BIT_DEPTH/DDR_BIT_DEPTH))) // offset
// //#define ADDR_AVG_DATA_DOSE6  (ADDR_AVG_DATA_DOSE0 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))) // acc
// //#define ADDR_AVG_DATA_DOSE1  (ADDR_AVG_DATA_DOSE6 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
// //#define ADDR_AVG_DATA_DOSE2  (ADDR_AVG_DATA_DOSE1 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
// //#define ADDR_AVG_DATA_DOSE3  (ADDR_AVG_DATA_DOSE2 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
// //#define ADDR_AVG_DATA_DOSE4  (ADDR_AVG_DATA_DOSE3 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
// //#define ADDR_AVG_DATA_DOSE5  (ADDR_AVG_DATA_DOSE4 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)))
// //#define ADDR_FLASH_READ_TEMP (ADDR_AVG_DATA_DOSE5 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))) // 0x7d3a000

#define MAX_DEFECT                4000
#define MAX_LINE_DEFECT            16

#define DEFAULT_OFFSET_ADD_VALUE    400        // dskim - 21.04.09 - Value to add offset.

#define AVG_SUCCESS 0L
#define AVG_FAILURE 1L

void load_calib_def(void);
void calib_init(void);
void reg_init(void);
void get_calib_init(void);
void mpc_cal(void);
void defect_init(void);
void set_ddr_raddr(u32 addr, u32 ch);
void set_ddr_waddr(u32 addr, u32 ch);
int get_ddr_pixel_avg(u32 level);
u16 get_ddr_frame_avg(u32 addr, u32 width, u32 height);
u16 get_ddr_frame_avg_offset(u32 addr, u32 width, u32 height);
u16 get_ddr_frame_std(u32 avg, u32 addr, u32 width, u32 height);
void get_defect_param(u32 addr);
void get_nuc_param(void);
void get_nuc_para4(void);
void update_nuc_param(void);
void recover_offset_param(void);
void set_calib_defect(u32 value);
void set_calib_rdefect(void);
void set_calib_cdefect(void);
int compare(const void *a, const void *b);
u32 encode_calib_defect(u32 addr, u32 defect[MAX_DEFECT][2], u32 defect_cnt);
u8 check_same_defect(u32 pointx, u32 pointy, u32 mode);
u8 check_same_rdefect(u32 row, u32 mode);
u8 check_same_cdefect(u32 col, u32 mode);
u8 check_error_rdefect(u32 row, u32 mode); // dskim - 21.09.24
u8 check_error_cdefect(u32 col, u32 mode); // dskim - 21.09.24
void add_calib_defect(u32 pointx, u32 pointy, u32 mode);
void add_calib_rdefect(u32 row, u32 mode);
void add_calib_cdefect(u32 col, u32 mode);
void erase_calib_defect(u32 pointx, u32 pointy);
void erase_calib_rdefect(u32 row);
void erase_calib_cdefect(u32 col);
void erase_calib_defect_factory(u32 pointx, u32 pointy);
void erase_calib_rdefect_factory(u32 row);
void erase_calib_cdefect_factory(u32 col);

#endif /* SRC_CALIB_H_ */
