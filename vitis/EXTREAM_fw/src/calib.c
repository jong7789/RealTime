/*
 * calib.c
 *
 *  Created on: 2019. 10. 7.
 */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "xil_types.h"
#include "func_printf.h"

#include "gige.h"
#include "calib.h"
#include "fpga_info.h"
#include "func_basic.h"
#include "func_cmd.h"
#include "user.h"

u32 DDR_CH0_BIT_DEPTH   ;
u32 DDR_CH1_BIT_DEPTH   ;
u32 DDR_CH2_BIT_DEPTH   ;
u32 ADDR_NUC_DATA       ;
u32 ADDR_AVG_DATA_DOSE0 ;
u32 ADDR_AVG_DATA_DOSE1 ;
u32 ADDR_AVG_DATA_DOSE2 ;
u32 ADDR_AVG_DATA_DOSE3 ;
u32 ADDR_AVG_DATA_DOSE4 ;
u32 ADDR_AVG_DATA_DOSE5 ;
u32 ADDR_AVG_DATA_DOSE6 ;
u32 ADDR_FLASH_READ_TEMP;
u32 wait5sec_once=0;

void load_calib_def(void)
{

    if (def_gev_speed==10)
    {
        DDR_CH0_BIT_DEPTH =  16 ;
        DDR_CH1_BIT_DEPTH =  32 ;
        DDR_CH2_BIT_DEPTH =  16 ;
    }
    else
    {
        DDR_CH0_BIT_DEPTH =  16 ;
        DDR_CH1_BIT_DEPTH =  128;
        DDR_CH2_BIT_DEPTH =  32 ;
    }

    ADDR_NUC_DATA        = (ADDR_RAW_IMAGE      + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH0_BIT_DEPTH/DDR_BIT_DEPTH)*2));
    ADDR_AVG_DATA_DOSE0  = (ADDR_NUC_DATA       + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH1_BIT_DEPTH/DDR_BIT_DEPTH))); // offset
    ADDR_AVG_DATA_DOSE1  = (ADDR_AVG_DATA_DOSE0 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)));
    ADDR_AVG_DATA_DOSE2  = (ADDR_AVG_DATA_DOSE1 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)));
    ADDR_AVG_DATA_DOSE3  = (ADDR_AVG_DATA_DOSE2 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)));
    ADDR_AVG_DATA_DOSE4  = (ADDR_AVG_DATA_DOSE3 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)));
    ADDR_AVG_DATA_DOSE5  = (ADDR_AVG_DATA_DOSE4 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH)));
    ADDR_AVG_DATA_DOSE6  = (ADDR_AVG_DATA_DOSE5 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))); // acc
    ADDR_FLASH_READ_TEMP = (ADDR_AVG_DATA_DOSE6 + (MAX_WIDTH_x32*MAX_HEIGHT*(DDR_CH2_BIT_DEPTH/DDR_BIT_DEPTH))); // 0x7d3a000

}

void calib_init(void) 
{
    REG(ADDR_DDR_CH_EN)     = 0b00000000;

    REG(ADDR_DDR_BASE_ADDR) = FPGA_DDR_BASEADDR;
    REG(ADDR_DDR_CH0_WADDR) = ADDR_RAW_IMAGE;
    REG(ADDR_DDR_CH1_WADDR) = ADDR_NUC_DATA;
    REG(ADDR_DDR_CH2_WADDR) = ADDR_AVG_DATA_DOSE0;
    REG(ADDR_DDR_CH3_WADDR) = ADDR_AVG_DATA_DOSE5;
    REG(ADDR_DDR_CH4_WADDR) = ADDR_AVG_DATA_DOSE6; // acc
    REG(ADDR_DDR_CH0_RADDR) = ADDR_RAW_IMAGE;
    REG(ADDR_DDR_CH1_RADDR) = ADDR_NUC_DATA;
    REG(ADDR_DDR_CH2_RADDR) = ADDR_AVG_DATA_DOSE0;
    REG(ADDR_DDR_CH3_RADDR) = ADDR_AVG_DATA_DOSE5; // d2m avg ref:210727, reg5:210804
    REG(ADDR_DDR_CH4_RADDR) = ADDR_AVG_DATA_DOSE6; // acc

    REG(ADDR_LINE_TIME)     = (u32)((float)(FPGA_DATA_CLK) / (func_height * func_frate_max)) - 100;

    mpc_cal();
};

void reg_init(void)
{
    REG(ADDR_WIDTH) = func_width;
    REG(ADDR_HEIGHT) = func_height;
	execute_topvalue_set(func_image_topvalue);
};

#define DBG_calinit 0
void get_calib_init(void) 
{
    func_rns_valid = 0;
    // dskim - 21.02.16 - 일정시간(Max) 시간 동안 Busy // execute_cmd_wddr()+execute_cmd_gcal() + Margin
    func_busy = 1;

//#ifdef EXT4343R
//  func_busy_time = (u32)(((1 << (user_avg_level)) / func_frate) * 1000)+(func_ref_num*8000)+5000;
//#else
//  func_busy_time = (u32)(((1 << (user_avg_level)) / func_frate) * 1000)+(func_ref_num*5000)+5000;
//#endif

    func_busy_time = (u32)(((1 << (user_avg_level)) / func_frate) * 1000)+15000;
//  func_printf("\r\nGain Calibration time(+Margin) %d(ms)\r\n", func_busy_time);   // 불필요 로그 삭제

    u32 grab = func_grab_en;

    // dskim - 21.03.04 - 부팅 초기에 읽을 경우 DDR 쓰기 오류가 발생하는 것으로 보여, 부팅 시퀀스 변경
    execute_cmd_grab(0);
    if(DBG_calinit)func_printf("[DBG_calinit] # get_calib_init execute_cmd_grab\r\n");

    execute_cmd_brns();
    if(DBG_calinit)func_printf("[DBG_calinit] # get_calib_init execute_cmd_brns\r\n");

    // dskim - 21.03.04

//  u32 pd = get_roic_data(11);
//  set_roic_data(11, 0);
//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001; // read ch 0,1,2 On 210302
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;
    REG(ADDR_DDR_CH_EN) = 0b01010001;
    if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
    if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
    if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729
    msdelay(100);

    REG(ADDR_OUT_EN) = 1;
    gige_set_acquisition_status(0, 1 & 1);
    if(DBG_calinit)func_printf("[DBG_calinit] # get_calib_init gige_set_acquisition_status\r\n");

    execute_cmd_grab(1);

//### 1. default
//    msdelay(5000); //# what is this? # 241216
//### 2. only once wait
    if(!wait5sec_once) //# 241217 not sure needs 5sec wait, but avoid error happen.
    {
            for(int i=0; i<10; i++) //# 241217 insert GIGE connection.
            {
            	gige_callback(0);
            	msdelay(500);
            }
    	wait5sec_once = 1;
    }

//  execute_cmd_wddr(1, 7);     // dskim - 0.00.08 - 여러번 수행 하도록 변경
    if (func_shutter_mode==0){ // if global shutter mode save in flash, it makes API boot problem. 211027mbh
        execute_cmd_wddr(1, user_avg_level);        // dskim - 21.02.15
        func_calib_cmd = 0; //# prevent double getting offset 220519
    }
    msdelay(100);
#ifndef GAIN_CALIB_SAVE_NUC_PARAM
    execute_cmd_gcal();     // dskim - debug
#endif
    if(DBG_calinit)func_printf("[DBG_calinit] # get_calib_init func_shutter_mode\r\n");

    execute_cmd_grab(grab);
//  set_roic_data(11, pd);
    msdelay(100);

    REG(ADDR_OUT_EN) = 0;
    gige_set_acquisition_status(0, 0 & 1);
    if(DBG_calinit)func_printf("[DBG_calinit] # get_calib_init gige_set_acquisition_status\r\n");

    func_busy = 0;
    func_busy_time = 0;
    func_check_booting = 0; // dskim - 21.02.15 - 부팅 중 Gain Calibration 중에는 Grab하지 못하도록
    if(DBG_calinit)func_printf("[DBG_calinit] # get_calib_init func_check_booting\r\n");

}

void mpc_cal(void) 
{
    func_ref_num = 0;

    if(func_img_avg_dose0 > 0xFFFF) func_img_avg_dose0 = 0xFFFF;
    if(func_img_avg_dose1 > 0xFFFF) func_img_avg_dose1 = 0xFFFF;
    if(func_img_avg_dose2 > 0xFFFF) func_img_avg_dose2 = 0xFFFF;
    if(func_img_avg_dose3 > 0xFFFF) func_img_avg_dose3 = 0xFFFF;
    if(func_img_avg_dose4 > 0xFFFF) func_img_avg_dose4 = 0xFFFF;

    REG(ADDR_MPC_POINT0) = func_img_avg_dose1;
    REG(ADDR_MPC_POINT1) = func_img_avg_dose2;
    REG(ADDR_MPC_POINT2) = func_img_avg_dose3;
    REG(ADDR_MPC_POINT3) = func_img_avg_dose4;

    if(func_img_avg_dose0) { func_ref_num++; func_ref_avg_max = func_img_avg_dose0; }
    if(func_img_avg_dose1) { func_ref_num++; func_ref_avg_max = func_img_avg_dose1; }
    if(func_img_avg_dose2) { func_ref_num++; func_ref_avg_max = func_img_avg_dose2; }
    if(func_img_avg_dose3) { func_ref_num++; func_ref_avg_max = func_img_avg_dose3; }
    if(func_img_avg_dose4) { func_ref_num++; func_ref_avg_max = func_img_avg_dose4; }

    if(func_hw_debug == 1)  REG(ADDR_MPC_NUM) = 1;
    else                    REG(ADDR_MPC_NUM) = func_ref_num;
}

void defect_init(void) 
{
//  REG(ADDR_DEFECT_WEN) = 1;
//  REG(ADDR_DEFECT2_WEN) = 1;
//  REG(ADDR_RDEFECT_WEN) = 1;
//  REG(ADDR_CDEFECT_WEN) = 1;

    msdelay(10);

    REG(ADDR_DEFECT_ADDR)  = 0;
    REG(ADDR_DEFECT2_ADDR) = 0;
    REG(ADDR_RDEFECT_ADDR) = 0;
    REG(ADDR_CDEFECT_ADDR) = 0;

    REG(ADDR_DEFECT_WDATA)  = 0xFFFFFFFF;
    REG(ADDR_DEFECT2_WDATA) = 0xFFFFFFFF;
    REG(ADDR_RDEFECT_WDATA) = 0xFFF;
    REG(ADDR_CDEFECT_WDATA) = 0xFFF;

    // mbh 210405 move from front
    REG(ADDR_DEFECT_WEN)  = 1;
    REG(ADDR_DEFECT2_WEN) = 1;
    REG(ADDR_RDEFECT_WEN) = 1;
    REG(ADDR_CDEFECT_WEN) = 1;

    REG(ADDR_DEFECT_WEN)  = 0;
    REG(ADDR_DEFECT2_WEN) = 0;
    REG(ADDR_RDEFECT_WEN) = 0;
    REG(ADDR_CDEFECT_WEN) = 0;
};

void set_ddr_raddr(u32 addr, u32 ch) 
{
    if(ch == 0)      REG(ADDR_DDR_CH0_RADDR) = addr;
    else if(ch == 1) REG(ADDR_DDR_CH1_RADDR) = addr;
    else if(ch == 2) REG(ADDR_DDR_CH2_RADDR) = addr;
    //$ 260402 WADDR -> RADDR
    // else if(ch == 3) REG(ADDR_DDR_CH3_WADDR) = addr;
    // else if(ch == 4) REG(ADDR_DDR_CH4_WADDR) = addr;
    else if(ch == 3) REG(ADDR_DDR_CH3_RADDR) = addr;
    else if(ch == 4) REG(ADDR_DDR_CH4_RADDR) = addr;
    usdelay(1);
}
void set_ddr_waddr(u32 addr, u32 ch) 
{
    if(ch == 0)      REG(ADDR_DDR_CH0_WADDR) = addr;
    else if(ch == 1) REG(ADDR_DDR_CH1_WADDR) = addr;
    else if(ch == 2) REG(ADDR_DDR_CH2_WADDR) = addr;
    else if(ch == 3) REG(ADDR_DDR_CH3_WADDR) = addr;
    else if(ch == 4) REG(ADDR_DDR_CH4_WADDR) = addr;
    usdelay(1);
}

#define DBG_pixelavg 0
int get_ddr_pixel_avg(u32 level) 
{
    float time;
    u32 frame_num = 1;
    u32 grab = func_grab_en;
    u32 timeoutcnt=0;
    int avgframenum = 0;
    u16 avgframecntnew = 0;
    u16 avgframecntold = 0;
    u8 outen0, outen1 =0;
    u16 avgoutcnt =0;

    frame_num = (1 << (level));

    execute_cmd_grab(1);
    REG(ADDR_AVG_LEVEL) = level;
    REG(ADDR_AVG_EN) = 0; // 210726
    REG(ADDR_AVG_EN) = 1;
    if(DBG_pixelavg)func_printf("[DBG_pixelavg] get_ddr_pixel_avg ADDR_AVG_EN\r\n");

    time = frame_num / func_frate;
    func_printf("Get Average Data of %d Frame\r\n", frame_num);
    func_printf("Required Time : "); float_printf(time, 2); func_printf("s\r\n");
    func_busy_time = time;

    // func_busy = 0; // ### Activation "STOP" Button. test 21.12.06  //dismiss 211209mbh
    func_printf("avg wait...\r\n");
    outen0 = REG(ADDR_OUT_EN)&1;
    if(DBG_pixelavg)func_printf("[DBG_pixelavg] # get_ddr_pixel_avg outen0\r\n");

    // execute_fw_ext_trig(frame_num); // 211220 test
    if(func_shutter_mode) 
    {
        if (func_trig_mode == 0) // Global-FreeRun: auto gain/offset 211230mbh
            REG(ADDR_API_EXT_TRIG)  = 1;
        else if (func_trig_mode == 1) // Global-ext1: auto gain/offset 211230mbh
            execute_fw_ext_trig_rst(frame_num, func_insert_rst_num); // 211221 test
        else; // Global-ext2
    }
    if(DBG_pixelavg)func_printf("[DBG_pixelavg] # get_ddr_pixel_avg func_shutter_mode\r\n");

    while(!(REG(ADDR_AVG_END)&1)) //1bit mask 211208 mbh
    {
        /* ### Average Cancel ### 211207mbh */
        func_calib_cmd = 0; // #xml addr_out_en access open
        gige_callback(0);
        outen1 = REG(ADDR_OUT_EN)&1;
//        if ( ((outen0==1)&&(outen1==0)) || uart_receive() || avgoutcnt > 256  ) // out_en falling 211209mbh uart input escape //$ 250617 64->8
		if ( ((outen0==1)&&(outen1==0)) || uart_receive() || avgoutcnt > 16  ) //# avgoutcnt 256 -> 16 #250930
        { // ### Acquisition STOP or Uart Keyboard Input
            func_printf("Average is Stopped ! \r\n");
            REG(ADDR_AVG_EN) = 0;
            REG(ADDR_AVG_LEVEL) = 0;
            REG(ADDR_API_EXT_TRIG)  = 0;
            execute_cmd_grab(grab);
            avgoutcnt = 0;
            return AVG_FAILURE;
        }
        func_calib_cmd = 1;
        /* ##################### */

        /* ### Wait Print ### 211208mbh */
        msdelay(10); // 100->10 dskim - 21.11.26 - Global Shutter, External1에서 UI 렉걸리는 현상
        timeoutcnt++;
        if (100 < timeoutcnt)
        {
            timeoutcnt=0;
            func_printf(".");
            avgoutcnt++;
        }

        // ### avg frame counter
        avgframenum = pow(2,REG(ADDR_AVG_LEVEL));
        avgframecntnew = (REG(ADDR_AVG_END) >> 5) & 0x07FF;
        if (avgframecntnew != avgframecntold)
        { // ### print frame count
            func_printf("\b\b\b\b\b\b\b\b\b\b%d/%d",avgframecntnew, avgframenum);
            avgframecntold = avgframecntnew;
        }
        /* ##################  */
    }
    if(DBG_pixelavg)func_printf("[DBG_pixelavg] # get_ddr_pixel_avg ADDR_AVG_END\r\n");
    func_printf("\r\n");
    REG(ADDR_AVG_EN) = 0;
    REG(ADDR_AVG_LEVEL) = 0;
    REG(ADDR_API_EXT_TRIG)  = 0;
    execute_cmd_grab(grab);
//  func_busy = 1;

    gige_callback(0);
//  func_printf("### AVG END ###\r\n");
    return AVG_SUCCESS;
}

u16 get_ddr_frame_avg(u32 addr, u32 width, u32 height) 
{
    u32 i, j;
    u32 sum = 0, avg = 0, data = 0;
    u32 data0, data1, datasum;
    float avg_line = 0;

    u32 addr_inc = addr;
    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;
    u32 line_test;

//#if defined(GEV10G)
if (def_gev_speed == 10){
    for(i = 0; i < height; i++) 
    {
        addr_inc = addr + (i * width_x32/2 * 4);
            for (j = 0; j < width/2; j++) 
            {
                data = DREG(addr_inc);
                data0 = (data & 0xFFFF);
                data1 = (data >> 16) & 0xFFFF;
                datasum = data0 + data1;
                //# except Edge for average calc 230327
                if(i >= func_edge_top && j >= func_edge_left && \
                   i <= (func_height-func_edge_bottom) && \
                   j <= (func_width-func_edge_right)) //# except edge 230327
                    sum += datasum;

                addr_inc += 4;
            }
        // avg_line += ((float)sum / width);
        avg_line += ((float)sum / (width-func_edge_left-func_edge_right)); //# except edge 230327

        sum = 0;
        if(!(i % (height / 24)))    gige_callback(0);
    }
}
//#else
else{
    for(i = 0; i < height; i++) 
    {
        addr_inc = addr + (i * width_x32 * 4);
            for (j = 0; j < width; j++) 
            {
                data = (DREG(addr_inc) & 0xFFFF0000) >> 16;
//                data = DREG(addr_inc);
//                data0 = (data & 0xFFFF);
//                data1 = (data >> 16) & 0xFFFF;
//                datasum = data0 + data1;
                //# except Edge for average calc 230327
                if(i >= func_edge_top && j >= func_edge_left && \
                   i <= (func_height-func_edge_bottom) && \
                   j <= (func_width-func_edge_right)) //# except edge 230327
                    sum += data; //$ 250903 roll back
                	//sum += datasum;
                addr_inc += 4;
            }
        // avg_line += ((float)sum / width);
        avg_line += ((float)sum / (width-func_edge_left-func_edge_right)); //# except edge 230327
        sum = 0;
        if(!(i % (height / 24)))    gige_callback(0);
    }
}
//#endif

    // avg = (u32)(avg_line / height);
    avg = (u32)(avg_line / (height-func_edge_top-func_edge_bottom)); //# except edge 230327

    return avg;
}

u16 get_ddr_frame_avg_offset(u32 addr, u32 width, u32 height) 
{
    u32 i, j;
    u32 sum = 0, avg = 0, data = 0;
    float avg_line = 0;

    u32 offset_addr = ADDR_AVG_DATA_DOSE0;
    u16 offset_data = 0;
    u32 addr_inc = addr;
    u32 offset_inc = addr;
    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    func_printf("\r\nOffset Data Subtraction\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(i = 0; i < height; i++) {
        addr_inc = addr + (i * width_x32 * 4);
        offset_inc = offset_addr + (i * width_x32 * 4);
        for (j = 0; j < width; j++) {
            offset_data = (DREG(offset_inc) & 0xFFFF0000) >> 16;        // dskim - 21.03.09 - offset address 연산 수정
            data = (((DREG(addr_inc) & 0xFFFF0000) >> 16) + func_offset_add_value) - offset_data;   // dskim - 21.04.09

            sum += data;
            addr_inc += 4;
            offset_inc += 4;
        }
        avg_line += ((float)sum / width);
        sum = 0;
        if(!(i % (func_height / 32)))  func_printf("*");
        gige_callback(0);
    }

    avg = (u32)(avg_line / height);

    return avg;
}

u16 get_ddr_frame_std(u32 avg, u32 addr, u32 width, u32 height) 
{
    u32 i, j;
    u32 sum = 0, std = 0, diff = 0, data = 0;
    float avg_line = 0;

    u32 addr_inc = addr;
    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    for(i = 0; i < height; i++) {
        addr_inc = addr + (i * width_x32 * 4);
        for (j = 0; j < width; j++) {
            data = (DREG(addr_inc) & 0xFFFF0000) >> 16;
            diff = data > avg ? data - avg : avg - data;
            sum += (diff * diff);
            addr_inc += 4;
        }
        avg_line += ((float)sum / width);
        sum = 0;
        if(!(i % (height / 24)))    gige_callback(0);
    }

    std = sqrt((u32)(avg_line / height));

    return std;
}

void get_defect_param(u32 addr) 
{
    u32 i, j, n, m;
    u32 x, y;
    u32 size;

//#ifdef EXT1024R
//    u32 size = 32;
//#elif defined EXT1616R
//    u32 size = 50;
//#elif defined EXT4343R
//    u32 size = 32;
//#else
//    u32 size = 32;
//#endif
         if( mEXT1616R_series ) size = 50;
    else if( mEXT4343R_series ) size = 32;
    else                          size = 32;

    u32 size_x = size, size_y = size;
    u32 ddr_addr = 0;
    u32 avg = 0;
    u32 std = 0;
    u32 data = 0;
    u32 range_min = 0, range_max = 0;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    func_printf("\r\nMake Encoded Defect Parameter\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    for(i = 0; i < func_height; i+=size_y) 
    {
        size_y = (func_height - i < size) ? func_height - i : size;
        for(j = 0; j < width_x32; j+=size_x) 
        {
            size_x = (width_x32 - j < size) ? width_x32 - j : size;

            ddr_addr = addr + (((i * width_x32) + j) * 4);

            avg = get_ddr_frame_avg(ddr_addr, size_x, size_y);
            std = get_ddr_frame_std(avg, ddr_addr, size_x, size_y);
            std *= func_defect_sens;

            range_max = avg + std;
            range_min = avg > std ? avg - std : 0;

            for(n = 0; n < size_y; n++) 
            {
                ddr_addr = addr + ((((i + n) * width_x32) + j) * 4);
                for(m = 0; m < size_x; m++) 
                {
                    y = i + n;
                    x = j + m;

                    data = (DREG(ddr_addr) & 0xFFFF0000) >> 16;
                    ddr_addr += 4;

                    if(y != 0 && (data < range_min || data > range_max))
                        if(func_defect_cnt < MAX_DEFECT)
                            if(!check_same_defect(x, y, 0))
                                add_calib_defect(x, y, 0);
                }
            }
        }
        gige_callback(0); func_printf("*");
    }

    func_printf("\r\nFinished!\r\n");
}


void get_nuc_param(void) {
    u32 data_range[4] = {0, };
    u32 add_offset[4] = {0, };
    u32 ref_addr[5] = {ADDR_AVG_DATA_DOSE0, ADDR_AVG_DATA_DOSE1, ADDR_AVG_DATA_DOSE2, ADDR_AVG_DATA_DOSE3, ADDR_AVG_DATA_DOSE4};
    u32 ref_data[5] = {0, };
    u16 ref_data0 = 0;
    u32 nuc_addr = ADDR_NUC_DATA;
    u32 nuc_data = 0;
    u32 gain = 0;
    s32 offset = 0;
    u32 ref_cnt = 0;
    u32 i, j, k;
    u16 round0p5 =0;
//  u32 debug_percent = 0;
//  char DEBUG_MSG[128];

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    u32 func_img_avg_dose_offset0   = 0;
    u32 func_img_avg_dose_offset1   = 0;
    u32 func_img_avg_dose_offset2   = 0;
    u32 func_img_avg_dose_offset3   = 0;
    u32 func_img_avg_dose_offset4   = 0;

//  func_printf("func_img_avg_dose0  = [%d]\r\n", func_img_avg_dose0);
//  func_printf("func_img_avg_dose1  = [%d]\r\n", func_img_avg_dose1);
//  func_printf("func_img_avg_dose2  = [%d]\r\n", func_img_avg_dose2);
//  func_printf("func_img_avg_dose3  = [%d]\r\n", func_img_avg_dose3);
//  func_printf("func_img_avg_dose4  = [%d]\r\n", func_img_avg_dose4);

    // dskim - 21.03.24 - 삭제
//  if(func_ref_num > 0) {
//      func_img_avg_dose_offset0 = get_ddr_frame_avg_offset(ADDR_AVG_DATA_DOSE0, func_width, func_height);
//  }
//  if(func_ref_num > 1) {
//      func_img_avg_dose_offset1 = get_ddr_frame_avg_offset(ADDR_AVG_DATA_DOSE1, func_width, func_height);
//  }
//  if(func_ref_num > 2) {
//      func_img_avg_dose_offset2 = get_ddr_frame_avg_offset(ADDR_AVG_DATA_DOSE2, func_width, func_height);
//  }
//  if(func_ref_num > 3) {
//      func_img_avg_dose_offset3 = get_ddr_frame_avg_offset(ADDR_AVG_DATA_DOSE3, func_width, func_height);
//  }
//  if(func_ref_num > 4) {
//      func_img_avg_dose_offset4 = get_ddr_frame_avg_offset(ADDR_AVG_DATA_DOSE4, func_width, func_height);
//  }

    if(func_ref_num > 0) {
        func_img_avg_dose_offset0 = (func_img_avg_dose0 + func_offset_add_value) - func_img_avg_dose0;  // dskim - 21.04.09
    }
    if(func_ref_num > 1) {
        func_img_avg_dose_offset1 = (func_img_avg_dose1 + func_offset_add_value) - func_img_avg_dose0;
    }
    if(func_ref_num > 2) {
        func_img_avg_dose_offset2 = (func_img_avg_dose2 + func_offset_add_value) - func_img_avg_dose0;
    }
    if(func_ref_num > 3) {
        func_img_avg_dose_offset3 = (func_img_avg_dose3 + func_offset_add_value) - func_img_avg_dose0;
    }
    if(func_ref_num > 4) {
        func_img_avg_dose_offset4 = (func_img_avg_dose4 + func_offset_add_value) - func_img_avg_dose0;
    }

//  func_printf("\r\nfunc_img_avg_dose0  = [%d]\r\n", func_img_avg_dose_offset0);
//  func_printf("func_img_avg_dose1  = [%d]\r\n", func_img_avg_dose_offset1);
//  func_printf("func_img_avg_dose2  = [%d]\r\n", func_img_avg_dose_offset2);
//  func_printf("func_img_avg_dose3  = [%d]\r\n", func_img_avg_dose_offset3);
//  func_printf("func_img_avg_dose4  = [%d]\r\n", func_img_avg_dose_offset4);

    data_range[0] = (func_img_avg_dose_offset1 - func_img_avg_dose_offset0) << CALIB_PARAM_RESOLUTION;
    data_range[1] = (func_img_avg_dose_offset2 - func_img_avg_dose_offset1) << CALIB_PARAM_RESOLUTION;
    data_range[2] = (func_img_avg_dose_offset3 - func_img_avg_dose_offset2) << CALIB_PARAM_RESOLUTION;
    data_range[3] = (func_img_avg_dose_offset4 - func_img_avg_dose_offset3) << CALIB_PARAM_RESOLUTION;

    add_offset[0] = (func_img_avg_dose_offset0);
    add_offset[1] = (func_img_avg_dose_offset1);
    add_offset[2] = (func_img_avg_dose_offset2);
    add_offset[3] = (func_img_avg_dose_offset3);

    func_printf("\r\nMake NUC Parameter and Write to DDR3\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    REG(ADDR_DDR_CH_EN) = 0b00000000;
    msdelay(100);

    for (i = 0; i < func_height; i++) {
        for (j = 0; j < width_x32; j++) {
            ref_cnt = 0;
            ref_data0   = ((DREG(ref_addr[0])   & 0xFFFF0000) >> 16);
            for (k = 0; k < 4; k++) {
                ref_data[k]     = (((DREG(ref_addr[k])  & 0xFFFF0000) >> 16) + func_offset_add_value) - ref_data0;      // dskim - 21.04.09
                ref_data[k+1]   = (((DREG(ref_addr[k+1])    & 0xFFFF0000) >> 16) + func_offset_add_value) - ref_data0;  // dskim - 21.04.09

                gain    = (u32)(data_range[k] / (u32)(ref_data[k+1] - ref_data[k]));
//              offset  = ((gain * ref_data[k]) >> CALIB_PARAM_RESOLUTION);
//              offset  -= add_offset[k];
                round0p5 = ((gain * ref_data[k]) >> (CALIB_PARAM_RESOLUTION-1)) & 1; // 0.5 round , 210226 mbh
                offset  = ((gain * ref_data[k]) >> CALIB_PARAM_RESOLUTION) + round0p5 - add_offset[k];
//              offset  = -(add_offset[k+1] - ((gain * ref_data[k+1]) >> CALIB_PARAM_RESOLUTION));

//              if(offset > add_offset[k])  offset  -= add_offset[k];
//              else                        offset  = 0;

                // ### 16bit overflow cut mbh210113
                if (offset >= (1<<15)-1)
                    offset = (1<<15)-1;
                else if(offset <= -(1<<15))
                    offset = -(1<<15);

                // dskim - 21.09.24
//              if (i < func_edge_top || (func_height-func_edge_bottom) < i || j < func_edge_left || (func_width-func_edge_right) < j ) {

//              if ( 100<i && i <= 104)
//              {
//                  if( 100<j && j <= 104){
//                      func_printf("gain=%d  offset=%d \r\n", gain, offset);
//                  }
//              }

                if(GEN_NUC_EDGE)
                    if (i < func_edge_top || (func_height-func_edge_bottom) <= i || j < func_edge_left || (func_width-func_edge_right) <= j ) {
                        gain = 0;
                        offset = func_edge_cut_value;
                    }

                if(i != 0 && (gain > 0xF000 || offset > 61440 || offset < -61440 )) // mbh210113
                {
//                  if(i > EDGE_RANGE && j > EDGE_RANGE && i < (func_width-EDGE_RANGE) && j < (func_height-EDGE_RANGE)) // dskim - 21.09.09 - CSI Edge Cut
                    if(i >= func_edge_top && j >= func_edge_left && i <= (func_height-func_edge_bottom) && j <= (func_width-func_edge_right))   // dskim - 21.09.24
//                  if((i >= func_edge_top && j >= func_edge_left && i <= (func_height-func_edge_bottom) && j <= (func_width-func_edge_right)) || GEN_NUC_EDGE )    //# 230213
                        if(func_defect_cnt < MAX_DEFECT)
                            if(!check_same_defect(j, i, 0))
                                add_calib_defect(j, i, 0);
                }

#ifdef GAIN_CALIB_BIT_OFFSET_18
                nuc_data = ((gain & 0x3FFF) << 18) | (offset & 0x3FFFF);
#else
                nuc_data = ((gain & 0xFFFF) << 16) | (offset & 0xFFFF);
#endif
                DREG(nuc_addr) = nuc_data;

                nuc_addr += 4;
                if(++ref_cnt == func_ref_num-1) {
                    nuc_addr += (16 - (4*(func_ref_num-1)));
                    break;
                }
            }
            ref_addr[0] += 4;
            ref_addr[1] += 4;
            ref_addr[2] += 4;
            ref_addr[3] += 4;
            ref_addr[4] += 4;
        }

        if(!(i % (func_height / 32)))   func_printf("*");

//      if((i != 0) && !(i % (func_height / 10))) {
//          debug_percent += 10;
//          memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
//          sprintf((char*)DEBUG_MSG,"%d%%", (int)(debug_percent));
//          gige_send_message(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
//      }
        gige_callback(0);
    }
//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001;
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;

    REG(ADDR_DDR_CH_EN) = 0b01010001;
if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729

    func_printf("\r\nFinished!\r\n");
}

void get_nuc_para4(void) {
//  u32 data_range[4] = {0, };
//  u32 add_offset[4] = {0, };
//  u32 ref_addr = ADDR_AVG_DATA_DOSE0;
//  u32 ref_data;
//  u16 ref_data0 = 0;
//  u32 nuc_addr = ADDR_NUC_DATA;
//  u32 nuc_data = 0;
//  u32 gain = 0;
//  s32 offset = 0;
//  u32 ref_cnt = 0;
    u32 i, j;
//  u16 round0p5 =0;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;


    func_printf("\r\nMake NUC Parameter and Write to DDR3\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    u16 avgdose0;
    u16 avgdose1;
    u32 addrinc=0;
    u32 dose0;
    u32 dose1;
    u16 dark;
    u16 white;

//  u32 nuc_keep;
    u32 gain;
    u16 gaincut;
    u32 nuc_addr = ADDR_NUC_DATA;
    int offset;
    int offsetcut;

    avgdose0 = func_offset_add_value; // func_img_avg_dose0;
    avgdose1 = func_img_avg_dose1;
    u32 gaintarget = (avgdose1-avgdose0) << 12;

    REG(ADDR_DDR_CH_EN) = 0b00000000;
    msdelay(100);
    for (i = 0; i < func_height; i++) {

        for (j = 0; j < width_x32; j++) {
        	//### 24121414 addr4,2
        	//### address unit is 4, 2byte increase need to be distinguished upper and lower
        	if(j%2==0) {
            dose0 = (DREG(ADDR_AVG_DATA_DOSE0 + addrinc) & 0xFFFF);
            dose1 = (DREG(ADDR_AVG_DATA_DOSE1 + addrinc) & 0xFFFF);
        	} else {
				dose0 = ((DREG(ADDR_AVG_DATA_DOSE0 + addrinc)>>16) & 0xFFFF);
				dose1 = ((DREG(ADDR_AVG_DATA_DOSE1 + addrinc)>>16) & 0xFFFF);
			}
            dark  = func_offset_add_value; // DREG(ADDR_AVG_DATA_DOSE0 + addrinc) & 0xFFFF;
            white = dose1 + func_offset_add_value - dose0;

            gain = gaintarget / ( white  - dark );
            offset = ((gain * dark) >> 12) - avgdose0;

            //# gain 12bit
            if (gain>0xFFFF) gaincut = 0xFFFF;
            else             gaincut = gain;

            //# offset 10bit
            if      (offset >  (1<<15)-1) offsetcut =  (1<<15)-1;
            else if (offset < -(1<<15))   offsetcut = -(1<<15);
            else                          offsetcut = offset;

//          reg_gain[1] = (u16)(gain[1]) & 0xFFFF;
//          if (i==100 && 100<j && j<= 108) func_printf("%d $ %d ||| %d $ %d \r\n ",gain, offset , gaincut, offsetcut);
//          if (i==2100 && 2100<j && j<= 2108) func_printf("%d $ %d ||| %d $ %d \r\n ",gain, offset , gaincut, offsetcut);

            DREG(nuc_addr) = ((gaincut & 0xFFFF) <<16) + offsetcut;

            nuc_addr += 4;
            addrinc  += 2;
        }
        if(!(i % (func_height / 32)))   func_printf("*");
        gige_callback(0);
    }



    REG(ADDR_DDR_CH_EN) = 0b01010001;
if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729

    func_printf("\r\nFinished!\r\n");
}
/*
void get_nuc_para4x(void) {
//  u32 data_range[4] = {0, };
//  u32 add_offset[4] = {0, };
//  u32 ref_addr = ADDR_AVG_DATA_DOSE0;
//  u32 ref_data;
//  u16 ref_data0 = 0;
//  u32 nuc_addr = ADDR_NUC_DATA;
//  u32 nuc_data = 0;
//  u32 gain = 0;
//  s32 offset = 0;
//  u32 ref_cnt = 0;
    u32 i, j;
//  u16 round0p5 =0;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;


    func_printf("\r\nMake NUC Parameter and Write to DDR3\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    u16 avgdose0;
    u16 avgdose1;
    u32 addrinc=0;
    u32 dose0;
    u32 dose1;
    u16 dark[2];
    u16 white[2];

//  u32 nuc_keep;
    u32 gain[2];
    u16 gaincut[2];
    u32 nuc_addr = ADDR_NUC_DATA;
//  u32 ofs_addr = ADDR_AVG_DATA_DOSE0;
//  u32 ofs_data;
    int offset[2];
    int offsetcut[2];

    avgdose0 = func_img_avg_dose0;
    avgdose1 = func_img_avg_dose1;

    REG(ADDR_DDR_CH_EN) = 0b00000000;
    msdelay(100);
    for (i = 0; i < func_height; i++) {
//      for (k = 0; k < width_x32/2; k++) {
//      }
        for (j = 0; j < width_x32/2; j++) {
            dose0 = DREG(ADDR_AVG_DATA_DOSE0 + addrinc);
            dose1 = DREG(ADDR_AVG_DATA_DOSE1 + addrinc);
            dark[0]  = (dose0    ) & 0xFFFF;
            dark[1]  = (dose0>>16) & 0xFFFF;
            white[0] = (dose1    ) & 0xFFFF;
            white[1] = (dose1>>16) & 0xFFFF;
            gain[0] = (((u32)(avgdose1-avgdose0)) << 10) / ( white[0]  - dark[0] );
            gain[1] = (((u32)(avgdose1-avgdose0)) << 10) / ( white[1]  - dark[1] );
            offset[0] = ((gain[0] * dark[0]) >> 10) - avgdose0;
            offset[1] = ((gain[1] * dark[1]) >> 10) - avgdose0;
//          gain[0] = (((u32)(avgdose1))*4096) / ( white[0] + func_offset_add_value - dark[0] );
//          gain[1] = (((u32)(avgdose1))*4096) / ( white[1] + func_offset_add_value - dark[1] );
//          gain[0] = ((u32)avgdose1 * 4096 /  white[0] );
//          gain[1] = ((u32)avgdose1 * 4096 /  white[1] );

//          gain    = (u32)(data_range[k] / (u32)(ref_data[k+1] - ref_data[k]));
//          offset  = ((gain * ref_data[k]) >> CALIB_PARAM_RESOLUTION)  - add_offset[k];

            //# gain 12bit
            if (gain[0]>0x0FFF) gaincut[0] = 0x0FFF;
            else                gaincut[0] = gain[0];
            if (gain[1]>0x0FFF) gaincut[1] = 0x0FFF;
            else                gaincut[1] = gain[1];

            //# offset 10bit
            if      (offset[0] >  127) offsetcut[0] =  127;
            else if (offset[0] < -128) offsetcut[0] = -128;
            else                       offsetcut[0] = offset[0];
            if      (offset[1] >  127) offsetcut[1] =  127;
            else if (offset[1] < -128) offsetcut[1] = -128;
            else                       offsetcut[1] = offset[0];


//          --   offset = gainoffset6bit msb & offset10bit
//          --   gain   = gainoffset4bit lsb & gain12bit

//          reg_gain[1] = (u16)(gain[1]) & 0xFFFF;
            if (i==100 && 100<j && j<= 108) func_printf("%d $ %d ||| %d $ %d \r\n ",gaincut[0], offsetcut[0] , gaincut[1], offsetcut[1]);
            DREG(nuc_addr) = (((offsetcut[1]>>4)& 0xF)<<28) + ((gaincut[1]& 0xFFF)<<16) +\
                             (((offsetcut[0]>>4)& 0xF)<<12) + ((gaincut[0]& 0xFFF))  ;

//          ofs_data = DREG(ofs_addr);
//          ofs_data = (((offsetcut[1]>>4)& 0x3F)<<26) + (((ofs_data>>16)&0x3FF)<<16) +\
//                     (((offsetcut[0]>>4)& 0x3F)<<10) + ((ofs_data>>16)&0x3FF) ;
//          DREG(nuc_addr) = (1<<28) + (1<<12); //# default value
//          addrinc  += 2;
            nuc_addr += 4;
            addrinc  += 4;
//          ofs_addr += 4;
        }
        if(!(i % (func_height / 32)))   func_printf("*");
        gige_callback(0);
    }



    REG(ADDR_DDR_CH_EN) = 0b01010001;
if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729

    func_printf("\r\nFinished!\r\n");
}
*/

void update_nuc_param(void) {
    u32 cal_addr[4] = {ADDR_NUC_DATA, ADDR_NUC_DATA+4, ADDR_NUC_DATA+8, ADDR_NUC_DATA+12};
    u32 ref_addr = ADDR_AVG_DATA_DOSE0;
    u32 ref_data_before = 0, ref_data_after = 0;
    u32 gain_before[4] = {0, };
    u32 offset_before[4] = {0, };
    u32 offset_after[4] = {0, };
    u32 nuc_addr = ADDR_NUC_DATA;
    u32 nuc_data = 0;
    u32 ref_cnt = 0;
    u32 diff = 0;
    u32 i, j, k;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    func_printf("\r\nUpdate NUC Parameter and Write to DDR3\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    REG(ADDR_DDR_CH_EN) = 0b00000000;
    msdelay(100);

    for (i = 0; i < func_height; i++) {
        for (j = 0; j < width_x32; j++) {
            ref_cnt = 0;
            ref_data_after      = (DREG(ref_addr) & 0xFFFF0000) >> 16;
            ref_addr += 4;

#ifdef GAIN_CALIB_BIT_OFFSET_18
            gain_before[0]      = (DREG(cal_addr[0]) & 0xFFFC0000) >> 18;
            offset_before[0]    = (DREG(cal_addr[0]) & 0x0003FFFF) >> 0;
#else
            gain_before[0]      = (DREG(cal_addr[0]) & 0xFFFF0000) >> 16;
            offset_before[0]    = (DREG(cal_addr[0]) & 0x0000FFFF) >> 0;
#endif

            ref_data_before     = offset_before[0] + func_offset_add_value; // 사용하지 않음
            ref_data_before     = (ref_data_before << CALIB_PARAM_RESOLUTION);
            ref_data_before     = ref_data_before / gain_before[0];

            for (k = 0; k < 4; k++) {
#ifdef GAIN_CALIB_BIT_OFFSET_18
                gain_before[k]      = (DREG(cal_addr[k]) & 0xFFFC0000) >> 18;
                offset_before[k]    = (DREG(cal_addr[k]) & 0x0003FFFF) >> 0;
#else
                gain_before[k]      = (DREG(cal_addr[k]) & 0xFFFF0000) >> 16;
                offset_before[k]    = (DREG(cal_addr[k]) & 0x0000FFFF) >> 0;
#endif

                if(ref_data_after > ref_data_before)    offset_after[k] = offset_before[k] + (ref_data_after - ref_data_before);
                else                                    offset_after[k] = offset_before[k] - (ref_data_before - ref_data_after);

#ifdef GAIN_CALIB_BIT_OFFSET_18
                nuc_data = ((gain_before[k] & 0x3FFF) << 18) | (offset_after[k] & 0x3FFFF);
#else
                nuc_data = ((gain_before[k] & 0xFFFF) << 16) | (offset_after[k] & 0xFFFF);
#endif
                DREG(nuc_addr) = nuc_data;

                nuc_addr += 4;
                if(++ref_cnt == func_ref_num-1) {
                    nuc_addr += (16 - (4*func_ref_num));
                    break;
                }
            }
            cal_addr[0] += 16;
            cal_addr[1] += 16;
            cal_addr[2] += 16;
            cal_addr[3] += 16;
        }
        if(!(i % (func_height / 32)))  func_printf("*");
        gige_callback(0);
    }

    if(func_img_avg_dose0 > func_img_avg_old) {
        diff = (func_img_avg_dose0 - func_img_avg_old);
        if(func_img_avg_dose1)  func_img_avg_dose1 = func_img_avg_dose1 + diff;
        if(func_img_avg_dose2)  func_img_avg_dose2 = func_img_avg_dose2 + diff;
        if(func_img_avg_dose3)  func_img_avg_dose3 = func_img_avg_dose3 + diff;
        if(func_img_avg_dose4)  func_img_avg_dose4 = func_img_avg_dose4 + diff;
    }
    else {
        diff = (func_img_avg_old - func_img_avg_dose0);
        if(func_img_avg_dose1)  func_img_avg_dose1 = func_img_avg_dose1 - diff;
        if(func_img_avg_dose2)  func_img_avg_dose2 = func_img_avg_dose2 - diff;
        if(func_img_avg_dose3)  func_img_avg_dose3 = func_img_avg_dose3 - diff;
        if(func_img_avg_dose4)  func_img_avg_dose4 = func_img_avg_dose4 - diff;
    }

    mpc_cal();

//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001;
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;

    REG(ADDR_DDR_CH_EN) = 0b01010001;
if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729

    func_printf("\r\nFinished!\r\n");
}

void recover_offset_param(void) {
    u32 cal_addr = ADDR_NUC_DATA;
    u32 cal_gain = 0;
    u32 cal_offset = 0;
    u32 ref_addr = ADDR_AVG_DATA_DOSE0;
    u32 ref_data = 0;

    u32 i, j;

    u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;

    func_printf("\r\nRecover Offset Parameter and Write to DDR3\r\n");
    func_printf("Process |                                |");
    for(i = 0; i < 33; i ++) func_printf("\b");

    REG(ADDR_DDR_CH_EN) = 0b00000000;
    msdelay(100);

    for (i = 0; i < func_height; i++) {
        for (j = 0; j < width_x32; j++) {
            cal_gain    = (DREG(cal_addr) & 0xFFFF0000) >> 16;
            cal_offset  = (DREG(cal_addr) & 0x0000FFFF) >> 0;

            ref_data = cal_offset + func_offset_add_value;      // dskim - 21.04.09 - 사용하지 않음
            ref_data = (ref_data << CALIB_PARAM_RESOLUTION);
            ref_data = ref_data / cal_gain;

            ref_data = ((ref_data & 0xFFFF) << 16) | 0x0000;
            DREG(ref_addr) = ref_data;

            ref_addr += 4;
            cal_addr += 16;
        }
        if(!(i % (func_height / 32)))  func_printf("*");
        gige_callback(0);
    }

//  if(func_gain_cal)   REG(ADDR_DDR_CH_EN) = 0b01110001;
//  else                REG(ADDR_DDR_CH_EN) = 0b01010001;

    REG(ADDR_DDR_CH_EN) = 0b01010001;
if(func_gain_cal)             REG(ADDR_DDR_CH_EN)   = 0b01110001; // read ch 0,1,2 On 210302
if(func_d2m)                  REG(ADDR_DDR_CH_EN)   = 0b11010101; // d2m on write ch2 avg for ref minus 210729
if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)   = 0b11110101; // d2m on write ch2 avg for ref minus 210729

    func_printf("\r\nFinished!\r\n");
}

void set_calib_defect(u32 value) {
    u32 i;
//    u32 encode_defect[MAX_DEFECT] = {0, };
//    u32 defect[MAX_DEFECT][2]= {0, };
//    u32 defect_1d[MAX_DEFECT] = {0, };  // dskim - 21.08.18 - MAX_DEFECT까지

    //# v2 it makes over address, and change func_width..
    static u32 encode_defect[MAX_DEFECT] = {0, };
    static u32 defect[MAX_DEFECT][2]= {0, };
    static u32 defect_1d[MAX_DEFECT] = {0, };  // dskim - 21.08.18 - MAX_DEFECT까지

//  u32 defect_1d[100] = {0, };
//  u32 defect[100][2] = {0, };
//  u32 encode_defect[100] = {0, };
    u32 defect_cnt = 0;
    u32 wdata = 0, rdata = 0;

    u32 FPGA_DEFECT_WEN = 0;
    u32 FPGA_DEFECT_ADDR = 0;
    u32 FPGA_DEFECT_WDATA = 0;
    u32 FPGA_DEFECT_RDATA = 0;

    u32 defectX = 0;
    u32 defectY = 0;
    u32 defectX_pre = 0;
    u32 defectY_pre = 0;
    u32 defect_cnt_final = 0;
    u32 cnt = 0;

    msdelay(1);     // dskim - 21.03.02 - ROI 변경때마다 rewrite해야 한다. 약간의 딜레이를 추가함.
    if(DBGDFEC)func_printf("Defect5-1 value=%d, func_binning_mode=%d, func_defect_cnt=%d\r\n", value, func_binning_mode, func_defect_cnt);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_width=%d \r\n",func_width);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_height=%d \r\n",func_height);

    if(value == 0) {
        for (i = 0; i < func_defect_cnt; i++) {
            // 32bit 1차원 배열로 만듬 - 정렬때문에
            // 21.02.25 - dskim - binning mode에서 좌표값 나누기
            defectX = func_defect[i][0];
            defectY = func_defect[i][1];

            if (i % 32 == 0) gige_callback(0);
            switch (func_binning_mode) {
                case 0 :
                    break;
                case 1 :
                    defectX /= 2;
                    defectY /= 2;
                    break;
                case 2 :
                    defectX /= 2;
                    defectY /= 2;
                    break;
                case 3 :
                    defectX /= 2;
                    if(GATE_DUMMY_LINE%2) //# 230921 when the gate dummy is odd, it need a line calc '-1'.
                        defectY = (defectY-1)/2; //# 230921
                    else
                    	defectY /= 2;
                    if(DBGDFEC)func_printf("v0 2x2 %d, %d\r\n", defectX, defectY);
                    break;
                case 4 :
                    defectX /= 3;
                    defectY /= 3;
                    break;
                case 5 :
                    defectX /= 3;
                    defectY /= 3;
                    break;
                case 6 :
                    defectX /= 4;
                    defectY /= 4;
                    break;
                case 7 :
                    defectX /= 4;
                    if(GATE_DUMMY_LINE%2) //# 230921
                        defectY = (defectY-1)/4; //# 230921
                    else
                    	defectY /= 4;
                    break;
            }
			if(defectX >= func_offsetx && defectY >= func_offsety) {
                defectX = defectX - func_offsetx;
                defectY = defectY - func_offsety;
                defect_1d[defect_cnt] = ((defectY << 16) & 0xFFFF0000) | (defectX & 0x0000FFFF);
                defect_cnt++;
            }

        }
        FPGA_DEFECT_WEN     = ADDR_DEFECT_WEN;
        FPGA_DEFECT_ADDR    = ADDR_DEFECT_ADDR;
        FPGA_DEFECT_WDATA   = ADDR_DEFECT_WDATA;
        FPGA_DEFECT_RDATA   = ADDR_DEFECT_RDATA;
    }
    else if(value == 1) {
        for (i = 0; i < func_defect_cnt2; i++) {
            defectX = func_defect2[i][0];
            defectY = func_defect2[i][1];
            // 21.02.25 - dskim - binning mode에서 좌표값 나누기
            if (i % 32 == 0) gige_callback(0);
            switch (func_binning_mode) {
                case 0 :
                    break;
                case 1 :
                    defectX /= 2;
                    defectY /= 2;
                    break;
                case 2 :
                    defectX /= 2;
                    defectY /= 2;
                    break;
                case 3 :
                    defectX /= 2;
                    if(GATE_DUMMY_LINE%2) //# 230921 when the gate dummy is odd, it need a line calc '-1'.
                        defectY = (defectY-1)/2; //# 230921
                    else
                    	defectY /= 2; //# bug fix 231013
                    break;
                case 4 :
                    defectX /= 3;
                    defectY /= 3;
                    break;
                case 5 :
                    defectX /= 3;
                    defectY /= 3;
                    break;
                case 6 :
                    defectX /= 4;
                    defectY /= 4;
                    break;
                case 7 :
                    defectX /= 4;
                    if(GATE_DUMMY_LINE%2) //# 230921
                        defectY = (defectY-1)/4; //# 230921
                    else
                    	defectY /= 4;
                    break;
            }
            if(defectX >= func_offsetx && defectY >= func_offsety) {
                defectX = defectX - func_offsetx;
                defectY = defectY - func_offsety;
                defect_1d[defect_cnt] = ((defectY << 16) & 0xFFFF0000) | (defectX & 0x0000FFFF);
                defect_cnt++;
            }
        }
        if(DBGDFEC)func_printf("Defect5-2\r\n");
        if(DBGDFEC)func_printf("#[DBGDFEC] func_width=%d \r\n",func_width);
        if(DBGDFEC)func_printf("#[DBGDFEC] func_height=%d \r\n",func_height);

        // dskim - 21.03.02 - factory map
        for (i = 0; i < func_defect_cnt3; i++) {
            defectX = func_defect3[i][0];
            defectY = func_defect3[i][1];
            // 21.02.25 - dskim - binning mode에서 좌표값 나누기
            if (i % 32 == 0)  gige_callback(0);
            switch (func_binning_mode) {
                case 0 :
                    break;
                case 1 :
                    defectX /= 2;
                    defectY /= 2;
                    break;
                case 2 :
                    defectX /= 2;
                    defectY /= 2;
                    break;
                case 3 :
                    if(GATE_DUMMY_LINE%2) //# 230921 when the gate dummy is odd, it need a line calc '-1'.
                        defectY = (defectY-1)/2; //# 230921
                    else
                    	defectY /= 2; //# bug fix 231013
                    break;
                case 4 :
                    defectX /= 3;
                    defectY /= 3;
                    break;
                case 5 :
                    defectX /= 3;
                    defectY /= 3;
                    break;
                case 6 :
                    defectX /= 4;
                    defectY /= 4;
                    break;
                case 7 :
                    defectX /= 4;
                    if(GATE_DUMMY_LINE%2) //# 230921
                        defectY = (defectY-1)/4; //# 230921
                    else
                    	defectY /= 4;
                    break;
            }
            if(defectX >= func_offsetx && defectY >= func_offsety) {
                defectX = defectX - func_offsetx;
                defectY = defectY - func_offsety;
                defect_1d[defect_cnt] = ((defectY << 16) & 0xFFFF0000) | (defectX & 0x0000FFFF);
                defect_cnt++;
            }
        }

        FPGA_DEFECT_WEN     = ADDR_DEFECT2_WEN;
        FPGA_DEFECT_ADDR    = ADDR_DEFECT2_ADDR;
        FPGA_DEFECT_WDATA   = ADDR_DEFECT2_WDATA;
        FPGA_DEFECT_RDATA   = ADDR_DEFECT2_RDATA;
    }

    if(DBGDFEC)func_printf("Defect5-3\r\n");
    if(DBGDFEC)func_printf("#[DBGDFEC] func_width=%d \r\n",func_width);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_height=%d \r\n",func_height);

    // 순차적으로 비교하기 위해서
    qsort(defect_1d, defect_cnt, sizeof(u32), compare);

    // 2차원 배열로 만듬
    for (i = 0; i < defect_cnt; i++) {
        defectX = (defect_1d[i] & 0xFFFF);
        defectY = ((defect_1d[i] >> 16) & 0xFFFF);
//      if((defectX_pre != defectX) || (defectY_pre != defectY)) {
        if((defectX_pre == defectX) && (defectY_pre == defectY)) {
            ;
        } else {
            // dskim - ROI 계산
//          if((defectX >= func_offsetx) && (defectY >= func_offsety) && (defectX <= func_width) && (defectY <= func_height)) {
          if((defectX <= func_width) && (defectY <= func_height)) {
                defect[cnt][0] = defectX;
                defect[cnt][1] = defectY;
                defect_cnt_final++;
                cnt++;
            }
        }
        defectX_pre = defectX;
        defectY_pre = defectY;
    }
    if(DBGDFEC)func_printf("Defect5-4\r\n");
    if(DBGDFEC)func_printf("#[DBGDFEC] func_width=%d \r\n",func_width);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_height=%d \r\n",func_height);

    // Encoded Data and Setting to FPGA
    REG(ADDR_DEBUG_MODE) = 0;   usdelay(1);

    if(defect_cnt_final == 0) {
        REG(FPGA_DEFECT_ADDR) = 0;
        REG(FPGA_DEFECT_WDATA) = 0x00ffffff; // mbh 210405 not zero for init
        REG(FPGA_DEFECT_WEN) = 1;  // 210215
        REG(FPGA_DEFECT_WEN) = 0;  // 210215
    }
    else {
        for(i = 0; i <= defect_cnt_final; i++) {  // write 1 more address mbh 210215
            encode_defect[i] = encode_calib_defect(i, defect, defect_cnt_final);
//          func_printf("addr(%4x) wdata(%8x, %d,%d) \r\n", i, encode_defect[i], (encode_defect[i]>>12)&0xfff,encode_defect[i]&0xfff); // 220810debug
//          func_printf("addr(%4x), wdata(%4x), wen(%4x) \r\n",FPGA_DEFECT_ADDR,FPGA_DEFECT_WDATA,FPGA_DEFECT_WEN);
            REG(FPGA_DEFECT_ADDR) = i;
            REG(FPGA_DEFECT_WDATA) = encode_defect[i];
            REG(FPGA_DEFECT_WEN) = 1;   // 210215
            REG(FPGA_DEFECT_WEN) = 0;   // 210215
            gige_callback(0);           // dskim - 21.11.03 - Defect 갯수가 많을 경우 연상 속도 이슈로 위치 옮김
        }
    }
    REG(FPGA_DEFECT_WEN) = 0;   usdelay(1);
    if(DBGDFEC)func_printf("Defect5-5 %d \r\n", defect_cnt_final);
    if(DBGDFEC)func_printf("Defect5-5 %02x \r\n", FPGA_DEFECT_RDATA);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_width=%d \r\n",func_width);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_height=%d \r\n",func_height);
    // Check Data
//  REG(ADDR_DEBUG_MODE) = 1;   usdelay(1);
//  i = 0;
//  while(i < defect_cnt_final) {
//      REG(FPGA_DEFECT_ADDR) = i;
//      wdata = encode_defect[i];
//      rdata = REG(FPGA_DEFECT_RDATA);
//		if(DBGDFEC)func_printf("Defect5-6 %d %\r\n", defect_cnt_final);
//
//    	if(wdata == rdata){
//          i++;
//    	}
//      else {
//          REG(FPGA_DEFECT_WDATA) = wdata;
//          REG(FPGA_DEFECT_WEN) = 1;  // 210215
//          REG(FPGA_DEFECT_WEN) = 0;
//          i++; //# no check rdata 230106mbh
//          if(DBGDFEC)func_printf("Defect5-7 %08x\r\n", wdata);
//          if(DBGDFEC)func_printf("Defect5-8 %08x\r\n", rdata);
//      }
//  }
    REG(FPGA_DEFECT_WEN) = 0;   usdelay(1);
    REG(ADDR_DEBUG_MODE) = 0;   usdelay(1);
    if(DBGDFEC)func_printf("Defect5-9\r\n");
    if(DBGDFEC)func_printf("#[DBGDFEC] func_width=%d \r\n",func_width);
    if(DBGDFEC)func_printf("#[DBGDFEC] func_height=%d \r\n",func_height);

}


void set_calib_rdefect(void) {
    u32 i;
    u32 defect[MAX_LINE_DEFECT] = {0, };
    u32 defect_cnt = 0;
    u32 wdata = 0, rdata = 0;

    // dskim - 21.03.02 - factory map
    u32 defect_final[MAX_LINE_DEFECT] = {0, };
    u32 defect_row = 0;
    u32 defect_row_pre = 0;
    u32 defect_cnt_final = 0;
    u32 cnt = 0;
    // mbh 210817 - double line
    u32 defect_final_line[MAX_LINE_DEFECT] = {0, };

    for (i = 0; i < func_rdefect_cnt; i++) {
        defect_row = func_rdefect[i];
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
                defect_row /= 2;
                break;
            case 2 :
                defect_row /= 2;
                break;
            case 3 :
//                defect_row /= 2;
                defect_row = round(defect_row /2.0); //# 230921
                break;
            case 4 :
                defect_row /= 3;
                break;
            case 5 :
                defect_row /= 3;
                break;
            case 6 :
                defect_row /= 4;
                break;
            case 7 :
                defect_row /= 4;
                break;
        }
        if(defect_row >= func_offsety) {
            defect[defect_cnt] = defect_row - func_offsety;
            defect_cnt++;
        }
    }
    // dskim - 21.03.02 - factory map
    for (i = 0; i < func_rdefect_cnt3; i++) {
        defect_row = func_rdefect3[i];
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
                defect_row /= 2;
                break;
            case 2 :
                defect_row /= 2;
                break;
            case 3 :
                defect_row /= 2;
                break;
            case 4 :
                defect_row /= 3;
                break;
            case 5 :
                defect_row /= 3;
                break;
            case 6 :
                defect_row /= 4;
                break;
            case 7 :
                defect_row /= 4;
                break;
        }
        if(defect_row >= func_offsety) {
            defect[defect_cnt] = defect_row - func_offsety;
            defect_cnt++;
        }
    }

    qsort(defect, defect_cnt, sizeof(u32), compare);

    // 중복 제거
    for (i = 0; i < defect_cnt; i++) {
        defect_row = defect[i];
        if((defect_row_pre == defect_row)) {
            ;
        } else {
            // dskim - ROI 계산
//          if((defect_row >= func_offsety) && (defect_row <= func_width)) {
//          if((defect_row <= func_width)) {
            if((defect_row <= func_height)) {   // dskim - 21.10.27 - 좌표계산 오류 수정
                defect_final[cnt] = defect_row;
                defect_cnt_final++;
                cnt++;
            }
        }
        defect_row_pre = defect_row;
    }

    // ########## double line decode ##########
    u32 defect_row_center = 0;
    u32 defect_row_north  = 0;
    u32 defect_row_south  = 0;
    u32 news_enable  = 0;
    for (i = 0; i < defect_cnt_final; i++) { //$ 260402 defect_cnt -> defect_cnt_final
        //$ 260402 add ? condition
        defect_row_north  = (i > 0) ? defect_final[i-1] : 0;
        defect_row_center = defect_final[i];
        defect_row_south  = (i < defect_cnt_final - 1) ? defect_final[i+1] : 0;
        news_enable = 0;
//      func_printf("defect_row %d, %d, %d \r\n", defect_row_north, defect_row_center, defect_row_south);
        if (defect_row_north+1 == defect_row_center) // north detect
            news_enable  += 0x1;                     // south enable    //$ 260402 =+ -> +=
        if (defect_row_south-1 == defect_row_center) // south detect
            news_enable  += 0x8;                     // north enable    //$ 260402 =+ -> +=
        if ((defect_row_north+1 == defect_row_center) && // clear if both side
            (defect_row_south-1 == defect_row_center))
            news_enable  =  0;
        if (news_enable  > 8)
            func_printf("row defect %d Line has a both side defect\r\n", defect_final[i]);
        func_printf("row news_enable = (0x%1x) \r\n", news_enable);
        defect_final_line[i] = (news_enable <<12) + defect_final[i];
//      func_printf("defect_final_line[%d] = (%4x) \r\n",i , defect_final_line[i]);
    }
    // ###################################

    // Setting to FPGA
    REG(ADDR_DEBUG_MODE) = 0;

    if(defect_cnt_final == 0) { // dskim - 21.04.12 - Defect Row, Column 0일 경우 0x00ffffff 설정되도록 변경
        REG(ADDR_RDEFECT_ADDR) = 0;
        REG(ADDR_RDEFECT_WDATA) = 0x00ffffff;
        REG(ADDR_RDEFECT_WEN) = 1;
        REG(ADDR_RDEFECT_WEN) = 0;
    }
    else {
        for(i = 0; i <= defect_cnt_final; i++) { // write 1 more address mbh 210215
            REG(ADDR_RDEFECT_ADDR) = i;
            REG(ADDR_RDEFECT_WDATA) = defect_final_line[i];
            REG(ADDR_RDEFECT_WEN) = 1;  // 210215
            REG(ADDR_RDEFECT_WEN) = 0;  // 210215
        }
    }

    REG(ADDR_RDEFECT_WEN) = 0;  usdelay(1);

    //# Check Data
    //  REG(ADDR_DEBUG_MODE) = 1;   usdelay(1);
    //  i = 0;
    //  while(i < defect_cnt_final) {
    //      REG(ADDR_RDEFECT_ADDR) = i;
    ////        wdata = defect_final[i];
    //      wdata = defect_final_line[i];
    //      rdata = REG(ADDR_RDEFECT_RDATA);
    //
    //      if(wdata == rdata)
    //          i++;
    //      else {
    //          REG(ADDR_RDEFECT_WDATA) = wdata;
    //          REG(ADDR_RDEFECT_WEN) = 1;  // 210215
    //          REG(ADDR_RDEFECT_WEN) = 0;  // 210215
    //          i++; //# no check rdata 230106mbh
    //
    //      }
    //  }
    REG(ADDR_RDEFECT_WEN) = 0;  usdelay(1);
    REG(ADDR_DEBUG_MODE) = 0;   usdelay(1);
}

void set_calib_cdefect(void){
    u32 i;
    u32 defect[MAX_LINE_DEFECT] = {0, };
    u32 defect_cnt = 0;
    u32 wdata = 0, rdata = 0;

    // dskim - 21.03.02 - factory map
    u32 defect_final[MAX_LINE_DEFECT] = {0, };
    u32 defect_col = 0;
    u32 defect_col_pre = 0;
    u32 defect_cnt_final = 0;
    u32 cnt = 0;

    //# mbh 210817 - double line
    u32 defect_final_line[MAX_LINE_DEFECT] = {0xffff, };

    //#230111 last data set to 0, it makes bug at 10G system.
    memset(defect_final_line, 0xffff, sizeof(defect_final_line)); //# 230111


    for (i = 0; i < func_cdefect_cnt; i++) {
        defect_col = func_cdefect[i];
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
                defect_col /= 2;
                break;
            case 2 :
                defect_col /= 2;
                break;
            case 3 :
                defect_col /= 2;
                break;
            case 4 :
                defect_col /= 3;
                break;
            case 5 :
                defect_col /= 3;
                break;
            case 6 :
                defect_col /= 4;
                break;
            case 7 :
                defect_col /= 4;
                break;
        }
        if(defect_col >= func_offsetx) {
            defect[defect_cnt] = defect_col - func_offsetx;
            defect_cnt++;
        }
    }
    for (i = 0; i < func_cdefect_cnt3; i++) {
        defect_col = func_cdefect3[i];
        switch (func_binning_mode) {
            case 0 :
                break;
            case 1 :
                defect_col /= 2;
                break;
            case 2 :
                defect_col /= 2;
                break;
            case 3 :
                defect_col /= 2;
                break;
            case 4 :
                defect_col /= 3;
                break;
            case 5 :
                defect_col /= 3;
                break;
            case 6 :
                defect_col /= 4;
                break;
            case 7 :
                defect_col /= 4;
                break;
        }
        if(defect_col >= func_offsetx) {
            defect[defect_cnt] = defect_col - func_offsetx;
            defect_cnt++;
        }
    }

    qsort(defect, defect_cnt, sizeof(u32), compare);

    // 중복 제거
    for (i = 0; i < defect_cnt; i++) {
        defect_col = defect[i];
        if((defect_col_pre == defect_col)) {
            ;
        } else {
            // dskim - ROI 계산
//          if((defect_col >= func_offsetx) && (defect_col <= func_height)) {
//          if((defect_col <= func_height)) {
            if((defect_col <= func_width)) {    // dskim - 21.10.27 - 좌표계산 오류 수정
                defect_final[cnt] = defect_col;
                defect_cnt_final++;
                cnt++;
            }
        }
        defect_col_pre = defect_col;
    }
//  func_printf("defect_cnt=%d \r\n",defect_cnt);
//  func_printf("defect_cnt_final=%d \r\n",defect_cnt_final);

    // ########## double line decode ##########
    u32 defect_col_center = 0;
    u32 defect_col_west   = 0;
    u32 defect_col_east   = 0;
    u32 news_enable  = 0;
    for (i = 0; i < defect_cnt_final; i++) { //$ 260402 defect_cnt -> defect_cnt_final
        //$ 260402 add ? condition
        defect_col_west   = (i > 0) ? defect_final[i-1] : 0;
        defect_col_center = defect_final[i];
        defect_col_east   = (i < defect_cnt_final -1) ? defect_final[i+1] : 0;
        news_enable = 0;
        if (defect_col_west+1 == defect_col_center) // west detect
            news_enable  += 0x4;                    // east enable  //$ 260402 =+ -> +=
        if (defect_col_east-1 == defect_col_center) // east detect
            news_enable  += 0x2;                    // west enable  //$ 260402 =+ -> +=
        if ((defect_col_west+1 == defect_col_center) && // clear if both side
            (defect_col_east-1 == defect_col_center))
            news_enable  =  0;
        if (news_enable  > 4)
            func_printf("col defect %d Line has a both side defect\r\n", defect_final[i]);
//      func_printf("col news_enable = (0x%1x) \r\n", news_enable);
        defect_final_line[i] = (news_enable<<12) + defect_final[i];
//      func_printf("defect_final_line[%d] = (%4x) \r\n",i , defect_final_line[i]);
    }
    // ###################################


    // Setting to FPGA
    REG(ADDR_DEBUG_MODE) = 0;

    if(defect_cnt_final == 0) { // dskim - 21.04.12 - Defect Row, Column 0일 경우 0x00ffffff 설정되도록 변경
        REG(ADDR_CDEFECT_ADDR) = 0;
        REG(ADDR_CDEFECT_WDATA) = 0x00ffffff;
        REG(ADDR_CDEFECT_WEN) = 1;
        REG(ADDR_CDEFECT_WEN) = 0;
    }
    else {
        for(i = 0; i <= defect_cnt_final; i++) {  // write 1 more address mbh 210215
            REG(ADDR_CDEFECT_ADDR) = i;
//          REG(ADDR_CDEFECT_WDATA) = defect_final[i];
            REG(ADDR_CDEFECT_WDATA) = defect_final_line[i]; // 210817
            REG(ADDR_CDEFECT_WEN) = 1;  // 210215
            REG(ADDR_CDEFECT_WEN) = 0;  // 210215
//          func_printf("defect_final_line[%d]=%d\r\n",i,  defect_final_line[i]);
        }
    }

    REG(ADDR_CDEFECT_WEN) = 0;  usdelay(1);

    // Check Data
//  REG(ADDR_DEBUG_MODE) = 1;   usdelay(1);
//  usdelay(1);
//  i = 0;
//  while(i < defect_cnt_final) {
//      REG(ADDR_CDEFECT_ADDR) = i;
////        wdata = defect_final[i];
//      wdata = defect_final_line[i];
//      rdata = REG(ADDR_CDEFECT_RDATA);
//
//      if(wdata == rdata)
//          i++;
//      else {
//          REG(ADDR_CDEFECT_WDATA) = wdata;
//          REG(ADDR_CDEFECT_WEN) = 1;  // 210215
//          REG(ADDR_CDEFECT_WEN) = 0;
//          i++; //# no check rdata 230106mbh
//
//      }
//  }
    REG(ADDR_CDEFECT_WEN) = 0;  usdelay(1);
    REG(ADDR_DEBUG_MODE) = 0;   usdelay(1);
}

int compare(const void *a, const void *b) {
    u32 num1 = *(int*)a;
    u32 num2 = *(int*)b;
    if(num1 < num2)     return -1;
    if(num1 > num2)     return 1;
    return 0;
}

    u8 pos_type = 0;
u32 encode_calib_defect(u32 addr, u32 defect[MAX_DEFECT][2], u32 defect_cnt) {
    u32 i = addr, j = 0;
    u32 encoded_data = 0;
    u32 cluster = 255;

    if      (defect[i][0] == 0              &&  defect[i][1] == 0)              pos_type = 0;   // 0, 0
    else if (defect[i][0] == MAX_WIDTH-1    &&  defect[i][1] == 0)              pos_type = 1;   // 1279, 0
    else if (defect[i][0] == 0              &&  defect[i][1] == MAX_HEIGHT-1)   pos_type = 2;   // 0, 3071
    else if (defect[i][0] == MAX_WIDTH-1    &&  defect[i][1] == MAX_HEIGHT-1)   pos_type = 3;   // 1279, 3071
    else if (defect[i][0] == 0)                                                 pos_type = 4;   // 0 Column
    else if (                                   defect[i][1] == 0)              pos_type = 5;   // 0 Row
    else if (defect[i][0] == MAX_WIDTH-1)                                       pos_type = 6;   // 1279 Column
    else if (                                   defect[i][1] == MAX_HEIGHT-1)   pos_type = 7;   // 3071 Row
    else                                                                        pos_type = 8;   // Others

    switch(pos_type) {
        case 0 :
            for(j = 0; j < defect_cnt; j++)  {
                if((defect[j][0] <= 1) && (defect[j][1] <= 1)) {
                    if      ((defect[i][0]+1 == defect[j][0])   && (defect[i][1]   == defect[j][1]))    cluster -= 16;
                    else if ((defect[i][0]   == defect[j][0])   && (defect[i][1]+1 == defect[j][1]))    cluster -= 64;
                    else if ((defect[i][0]+1 == defect[j][0])   && (defect[i][1]+1 == defect[j][1]))    cluster -= 128;
                }
            }
            cluster -= 47;  // (1+2+4+8+32)
            break;

        case 1 :
            for(j = 0; j < defect_cnt; j++)  {
                if((defect[j][0] >= MAX_WIDTH-2) && (defect[j][1] <= 1)) {
                    if      ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 8;
                    else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 32;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 64;

                }
            }
            cluster -= 151; // (1+2+4+16+128)
            break;

        case 2 :
            for(j = 0; j < defect_cnt; j++)  {
                if((defect[j][0] <= 1) && (defect[j][1] >= MAX_HEIGHT-2)) {
                    if      ((defect[i][0]   == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 2;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 4;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 16;

                }
            }
            cluster -= 233; // (1+8+32+64+128)
            break;

        case 3 :
            for(j = 0; j < defect_cnt; j++)  {
                if((defect[j][0] >= MAX_WIDTH-2) && (defect[j][1] >= MAX_HEIGHT-2)) {
                    if      ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 1;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 2;
                    else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 8;
                }
            }
            cluster -= 244; // (4+16+32+64+128)
            break;

        case 4 :
            for(j = 0; j < defect_cnt; j++)  {
                if(defect[j][0] <= 1) {
                    if      ((defect[i][0]   == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 2;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 4;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 16;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 64;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 128;
                }
            }
            cluster -= 41;  // (1+8+32)
            break;

        case 5 :
            for(j = 0; j < defect_cnt; j++)  {
                if(defect[j][1] <= 1) {
                    if      ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 8;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 16;
                    else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 32;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 64;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 128;
                }
            }
            cluster -= 7;   // (1+2+4)
            break;

        case 6 :
            for(j = 0; j < defect_cnt; j++)  {
                if(defect[j][0] >= MAX_WIDTH-2) {
                    if      ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 1;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 2;
                    else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 8;
                    else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 32;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))      cluster -= 64;

                }
            }
            cluster -= 148; // (4+16+128)
            break;

        case 7 :
            for(j = 0; j < defect_cnt; j++)  {
                if(defect[j][1] >= MAX_HEIGHT-2) {
                    if      ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 1;
                    else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 2;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))      cluster -= 4;
                    else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 8;
                    else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))      cluster -= 16;
                }
            }
            cluster -= 224; // (32+64+128)
            break;

        default :
            for(j = 0; j < defect_cnt; j++) {
                if      ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))          cluster -= 1;
                else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))          cluster -= 2;
                else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]-1 == defect[j][1]))          cluster -= 4;
                else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))          cluster -= 8;
                else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]   == defect[j][1]))          cluster -= 16;
                else if ((defect[i][0]-1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))          cluster -= 32;
                else if ((defect[i][0]   == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))          cluster -= 64;
                else if ((defect[i][0]+1 == defect[j][0]) && (defect[i][1]+1 == defect[j][1]))          cluster -= 128;
            }
            break;
    }

    encoded_data = ((cluster & 0x000000FF) << 24) | ((defect[i][1] & 0x00000FFF) << 12) | (defect[i][0] & 0x00000FFF);
//  func_printf("cluster=%02x y=%d, x=%d \r\n", cluster, defect[i][1], defect[i][0]);
    return encoded_data;
}

u8 check_same_defect(u32 pointx, u32 pointy, u32 mode) {
    u32 i;

    if(mode == 0) {
        for (i = 0; i < func_defect_cnt; i++)
            if(func_defect[i][0] == pointx && func_defect[i][1] == pointy)
                return 1;
    }
    else if(mode == 1) {
        for (i = 0; i < func_defect_cnt2; i++)
            if(func_defect2[i][0] == pointx && func_defect2[i][1] == pointy)
                return 1;
    }
    // dskim - 21.03.02 - factory map
    // dskim - 21.09.24 - 사용 하지 않음
    else {
        for (i = 0; i < func_defect_cnt3; i++) {
            if(func_defect3[i][0] == pointx && func_defect3[i][1] == pointy)
                return 1;
        }
    }

    return 0;
}

//u8 check_outarea_defect(u32 pointx, u32 pointy, u32 mode) {
//    u32 i;
//
//    if(mode == 0) {
//        for (i = 0; i < func_defect_cnt; i++)
//            if(func_defect[i][0] == pointx && func_defect[i][1] == pointy)
//                return 1;
//    }
//    else if(mode == 1) {
//        for (i = 0; i < func_defect_cnt2; i++)
//            if(func_defect2[i][0] == pointx && func_defect2[i][1] == pointy)
//                return 1;
//    }
//    // dskim - 21.03.02 - factory map
//    // dskim - 21.09.24 - 사용 하지 않음
//    else {
//        for (i = 0; i < func_defect_cnt3; i++) {
//            if(func_defect3[i][0] == pointx && func_defect3[i][1] == pointy)
//                return 1;
//        }
//    }
//
//    return 0;
//}

u8 check_same_rdefect(u32 row, u32 mode) {
    u32 i;
//  u32 err_min = row > 0 ? row - 1 : 0;
//  u32 err_max = row + 1;

    if(mode == 0) {
        for (i = 0; i < func_rdefect_cnt; i++)
//          if(func_rdefect[i] >= err_min && func_rdefect[i] <= err_max)
            if(func_rdefect[i] == row) // compare only same 210817mbh
                return 1;
    }
    // dskim - 21.09.24 - 사용 하지 않음
    else {
        for (i = 0; i < func_rdefect_cnt3; i++)
//          if(func_rdefect3[i] >= err_min && func_rdefect3[i] <= err_max)
            if(func_rdefect3[i] == row) // compare only same
                return 1;
    }

    return 0;
}

u8 check_same_cdefect(u32 col, u32 mode) {
    u32 i;
//  u32 err_min = col > 0 ? col - 1 : 0;
//  u32 err_max = col + 1;

    if(mode == 0) {
        for (i = 0; i < func_cdefect_cnt; i++)
//          if(func_cdefect[i] >= err_min && func_cdefect[i] <= err_max)
            if(func_cdefect[i] == col) // compare only same
                return 1;
    }
    // dskim - 21.09.24 - 사용 하지 않음
    else {
        for (i = 0; i < func_cdefect_cnt3; i++)
//          if(func_cdefect3[i] >= err_min && func_cdefect3[i] <= err_max)
            if(func_cdefect3[i] == col) // compare only same
                return 1;
    }

    return 0;
}

// dskim - 21.09.24 - 3줄 이상 인접한 라인은 보정 불가.
u8 check_error_rdefect(u32 row, u32 mode) {
    u32 i = 0;
    u32 defect[MAX_LINE_DEFECT] = {0, };
    u32 defect_cnt = 0;

    u32 data = 0;
    u32 d1 = 0;
    u32 d2 = 0;

    for (i = 0; i < func_rdefect_cnt; i++) {
        defect[i] = func_rdefect[i];
    }
    defect[func_rdefect_cnt] = row;

    defect_cnt = func_rdefect_cnt + 1;

    qsort(defect, defect_cnt, sizeof(u32), compare);

    if(defect_cnt > 2) {
        for(i = 2; i < defect_cnt; i++) {
            data = defect[i];
            d1 = defect[i-1];
            d2 = defect[i-2];
            if(d1 == (data-1) && d2 == (data-2)) {
                return 1;
            }
        }
    }

    return 0;
}

u8 check_error_cdefect(u32 col, u32 mode) {
    u32 i = 0;
    u32 defect[MAX_LINE_DEFECT] = {0, };
    u32 defect_cnt = 0;

    u32 data = 0;
    u32 d1 = 0;
    u32 d2 = 0;

    for (i = 0; i < func_cdefect_cnt; i++) {
        defect[i] = func_cdefect[i];
    }
    defect[func_cdefect_cnt] = col;

    defect_cnt = func_cdefect_cnt + 1;

    qsort(defect, defect_cnt, sizeof(u32), compare);

    if(defect_cnt > 2) {
        for(i = 2; i < defect_cnt; i++) {
            data = defect[i];
            d1 = defect[i-1];
            d2 = defect[i-2];
            if(d1 == (data-1) && d2 == (data-2)) {
                return 1;
            }
        }
    }

    return 0;
}

void add_calib_defect(u32 pointx, u32 pointy, u32 mode){
    if(mode == 0) {
        func_defect[func_defect_cnt][0] = pointx;
        func_defect[func_defect_cnt][1] = pointy;
        func_defect_cnt++;
    }
    else if(mode == 1) {    // Manual
        func_defect2[func_defect_cnt2][0] = pointx;
        func_defect2[func_defect_cnt2][1] = pointy;
        func_defect_cnt2++;
    }
    else {                  // dskim - 21.03.02 - factory map
        func_defect3[func_defect_cnt3][0] = pointx;
        func_defect3[func_defect_cnt3][1] = pointy;
        func_defect_cnt3++;
    }
}

void add_calib_rdefect(u32 row, u32 mode) {
    if(mode == 0) {
        func_rdefect[func_rdefect_cnt] = row;
        func_rdefect_cnt++;
    }
    else {
        // dskim - 21.09.24 - 사용 하지 않음
        func_rdefect3[func_rdefect_cnt3] = row;
        func_rdefect_cnt3++;
    }
}

void add_calib_cdefect(u32 col, u32 mode) {
    if(mode == 0) {
        func_cdefect[func_cdefect_cnt] = col;
        func_cdefect_cnt++;
    }
    else {
        func_cdefect3[func_cdefect_cnt3] = col;
        func_cdefect_cnt3++;
    }
}

void erase_calib_defect(u32 pointx, u32 pointy) {
    u32 i;
    u8 state = 0;

    for (i = 0; i < func_defect_cnt2; i++) {
        if(!state) {
            if(func_defect2[i][0] == pointx && func_defect2[i][1] == pointy) {
                func_defect_cnt2--;
                if(i == func_defect_cnt2)   return;
                state = 1;
            }
        }
        if(state) {
            func_defect2[i][0] = func_defect2[i+1][0];
            func_defect2[i][1] = func_defect2[i+1][1];
        }
    }
}

void erase_calib_defect_factory(u32 pointx, u32 pointy) {
    u32 i;
    u8 state = 0;

    for (i = 0; i < func_defect_cnt3; i++) {
        if(!state) {
            if(func_defect3[i][0] == pointx && func_defect3[i][1] == pointy) {
                func_defect_cnt3--;
                if(i == func_defect_cnt3)   return;
                state = 1;
            }
        }
        if(state) {
            func_defect3[i][0] = func_defect3[i+1][0];
            func_defect3[i][1] = func_defect3[i+1][1];
        }
    }
}

void erase_calib_rdefect(u32 row) {
    u32 i;
    u8 state = 0;

    for (i = 0; i < func_rdefect_cnt; i++) {
        if(!state) {
            if(func_rdefect[i] == row) {
                func_rdefect_cnt--;
                if(i == func_rdefect_cnt)   return;
                state = 1;
            }
        }
        if(state)
            func_rdefect[i] = func_rdefect[i+1];
    }
}

void erase_calib_rdefect_factory(u32 row) {
    u32 i;
    u8 state = 0;

    for (i = 0; i < func_rdefect_cnt3; i++) {
        if(!state) {
            if(func_rdefect3[i] == row) {
                func_rdefect_cnt3--;
                if(i == func_rdefect_cnt3)  return;
                state = 1;
            }
        }
        if(state)
            func_rdefect3[i] = func_rdefect3[i+1];
    }
}

void erase_calib_cdefect(u32 col) {
    u32 i;
    u8 state = 0;

    for (i = 0; i < func_cdefect_cnt; i++) {
        if(!state) {
            if(func_cdefect[i] == col) {
                func_cdefect_cnt--;
                if(i == func_cdefect_cnt)   return;
                state = 1;
            }
        }
        if(state)
            func_cdefect[i] = func_cdefect[i+1];
    }
}

void erase_calib_cdefect_factory(u32 col) {
    u32 i;
    u8 state = 0;

    for (i = 0; i < func_cdefect_cnt3; i++) {
        if(!state) {
            if(func_cdefect3[i] == col) {
                func_cdefect_cnt3--;
                if(i == func_cdefect_cnt3)  return;
                state = 1;
            }
        }
        if(state)
            func_cdefect3[i] = func_cdefect3[i+1];
    }
}
