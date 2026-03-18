/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  user.c                                                          */
/*    Date :  2022-10-11                                                      */
/*     Rev :  0.16                                                            */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design application-specific functions               */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2008-03-12  |  JP  |  Initial release                             */
/*  0.2  |  2011-10-13  |  JP  |  Acquisition mode made R/W                   */
/*  0.3  |  2013-01-07  |  JP  |  Networking functions moved to new file      */
/*  0.4  |  2013-02-26  |  JP  |  Fixed the action_trigger() function         */
/*  0.5  |  2015-08-11  |  MAS |  Corrected linepitch calculation             */
/*  0.6  |  2015-10-05  |  MAS |  Added StreamChannel Packetsize parameter    */
/*       |              |      |  read registers                              */
/*  0.7  |  2016-09-21  |  JP  |  New generic libgige user callback function  */
/*  0.8  |  2017-10-17  |  MAS |  Extended Chunk mode support added           */
/*  0.9  |  2017-11-20  |  MAS |  Chunk layout id dependent on frame parameter*/
/*  0.10 |  2017-12-12  |  AZ  |  Corrected chunk layout id generation        */
/*  0.11 |  2018-04-16  |  AZ  |  Formatting clean up                         */
/*  0.12 |  2018-07-02  |  MAS |  Add gige_set_acquisition_status function    */
/*       |              |      |  extended LIB_EVENTs                         */
/*  0.13 |  2019-11-27  |  MAS |  Authentication and evaluation status regs   */
/*  0.14 |  2020-09-25  | RW/AZ|  Add TestEventGenerate and EventTestTimestamp*/
/*       |              |      |  libgige update -> gige_send_message update  */
/*  0.15 |  2021-09-23  |  SS  |  Use new videotpg                            */
/*  0.16 |  2022-10-11  |  SS  |  Added video_tpg_mode register               */
/******************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <xparameters.h>
#include "func_printf.h"
#include "math.h"
#include "gige.h"
#include "user.h"
#include "flash.h"
#include "fpga_info.h"
#include "framebuf.h"
#include "phy.h"

#include "func_cmd.h"
#include "display.h"
#include "command.h"
#include "func_basic.h"

u32 user_avg_level = 0;
u8 user_cmd[32] = {0, };
// ---- Global variables -------------------------------------------------------
//
volatile u32 video_max_width;
volatile u32 video_max_height;
volatile u32 video_acq_mode;
volatile u32 video_max_offset;
volatile u32 video_max_gap;
volatile u32 video_chunk_enable   = 0;  // Chunk enable register, bit 0 = frame counter enable
volatile u64 event_test_timestamp = 0;

static u32 user_pixperclock = 1;


// ---- Local function prototypes ----------------------------------------------
//

static void  user_set_pixperclock(u32 pixfmt);


// ---- Read GigE Vision user-space bootstrap register -------------------------
//
//           This function must be always implemented!
//           It is called by the gige_callback() from libgige
//
// address = address of the register within GigE Vision manufacturer-specific
//           register address space (0x0000A000 - 0xFFFFFFFF)
// status  = return status value, should be one of following:
//           GEV_STATUS_SUCCESS         - read passed correctly
//           GEV_STATUS_INVALID_ADDRESS - register at 'address' does not exist
//           GEV_STATUS_LOCAL_PROBLEM   - problem while getting register value
//           GEV_STATUS_ERROR           - unspecified error
//
// return value = content of the register at 'address'
//
u32 get_user_reg(u32 address, u16 *status)
{
    float framerate;
    u32  *temp;
    u32   bpp;
    float fval;

    *status = GEV_STATUS_SUCCESS;
    switch (address)
    {
    	        case XML_OUT_EN         :  if (DEBUGXML_R)func_printf("--- get XML_OUT_EN (%d) $$$\r\n",func_out_en);            return func_out_en;
        case XML_WIDTH          :  if (DEBUGXML_R)func_printf("--- get XML_WIDTH (%d) $$$\r\n",func_width);              return func_width;
        case XML_HEIGHT         :  if (DEBUGXML_R)func_printf("--- get XML_HEIGHT (%d) $$$\r\n",func_height);            return func_height;
        case XML_OFFSETX        :  if (DEBUGXML_R)func_printf("--- get XML_OFFSETX (%d) $$$\r\n",func_offsetx);          return func_offsetx;
        case XML_OFFSETY        :  if (DEBUGXML_R)func_printf("--- get XML_OFFSETY (%d) $$$\r\n",func_offsety);          return func_offsety;
        case XML_LINEPITCH      :   bpp = (((func_pixfmt & 0x00FF0000) >> 16) + 7) / 8;        // NC
                                   if (DEBUGXML_R)func_printf("--- get XML_OFFSETY (%d) $$$\r\n",((func_width * bpp) + framebuf_pad_x));
                                                                                                                         return ((func_width * bpp) + framebuf_pad_x);
        case XML_PIXFMT         :  if (DEBUGXML_R)func_printf("--- get XML_PIXFMT (%d) $$$\r\n",func_pixfmt);            return func_pixfmt;
        case XML_WIDTH_MAX      :  if (DEBUGXML_R)func_printf("--- get XML_WIDTH_MAX (%d) $$$\r\n",MAX_WIDTH);           return MAX_WIDTH - func_offsetx;  // NC
        case XML_HEIGHT_MAX     :  if (DEBUGXML_R)func_printf("--- get XML_HEIGHT_MAX (%d) $$$\r\n",MAX_HEIGHT);         return MAX_HEIGHT - func_offsety; // NC
        case XML_PLOAD_SIZE     :  if (DEBUGXML_R)func_printf("--- get XML_PLOAD_SIZE (%d) $$$\r\n",framebuf_bpb);       return framebuf_bpb;
        case XML_ACQ_MODE       :  if (DEBUGXML_R)func_printf("--- get XML_ACQ_MODE (%d) $$$\r\n",ACQ_MODE_CONTINUOUS);  return ACQ_MODE_CONTINUOUS;       // NC
        case XML_ROW_DELAY      :  if (DEBUGXML_R)func_printf("--- get XML_ROW_DELAY (%d) $$$\r\n",0);                   return 0;                         // NC
        case XML_FRAME_DELAY    :  if (DEBUGXML_R)func_printf("--- get XML_FRAME_DELAY (%d) $$$\r\n",0);                 return 0;                         // NC
        case XML_FRATE          :   //func_printf("2. func_frate=%d\r\n", (u32)(func_frate*1000));
                                    temp = (u32*)&func_frate;
                                   if (DEBUGXML_R) {
                                       char DEBUG_MSG[16];
                                       memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG)); //#220502 1616 40fps acq/imge tab selecting makes async acc.
                                       sprintf(DEBUG_MSG,"%f", func_frate);
                                       gcvt(func_frate, 4, DEBUG_MSG); //# ???
                                       func_printf("--- get XML_FRATE (%s) $$$\r\n", DEBUG_MSG);
                                   }
                                    return(*temp);
        case XML_TEST_PATTERN   :  if (DEBUGXML_R)func_printf("--- get XML_TEST_PATTERN (%d) $$$\r\n",func_test_pattern);  return func_test_pattern;
        case XML_GEWT           :  //if (DEBUGXML_R)func_printf("--- get XML_GEWT (%d)(%d) $$$\r\n", func_rewt, func_gewt);
                                    //    if(func_shutter_mode == 0)    return func_rewt;
                                    // else                         return func_gewt;
                                    if (DEBUGXML_R)func_printf("--- get XML_GEWT (%d) $$$\r\n",func_gewt);
                                        return func_gewt;
        case XML_TRIG_MODE      :  if (DEBUGXML_R)func_printf("--- get XML_TRIG_MODE (%d) $$$\r\n",func_trig_mode);      return func_trig_mode;
        case XML_GAIN_CAL       :  if (DEBUGXML_R)func_printf("--- get XML_GAIN_CAL (%d) $$$\r\n",func_gain_cal);        return func_gain_cal;
        case XML_OFFSET_CAL     :  if (DEBUGXML_R)func_printf("--- get XML_OFFSET_CAL (%d) $$$\r\n",func_offset_cal);    return func_offset_cal;
        case XML_DEFECT_CAL     :  if (DEBUGXML_R)func_printf("--- get XML_DEFECT_CAL (%d) $$$\r\n",func_defect_cal);    return func_defect_cal;
        case XML_TABLE          :  if (DEBUGXML_R)func_printf("--- get XML_TABLE (%d) $$$\r\n",func_table);              return func_table;
        case XML_DGAIN          :  if (DEBUGXML_R)func_printf("--- get XML_DGAIN (%d) $$$\r\n",func_dgain);              return func_dgain;
        case XML_USERSET_NAME0  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME0 (%d) $$$\r\n",set_userset_data(func_table, 0));  return set_userset_data(func_table, 0);
        case XML_USERSET_NAME1  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME1 (%d) $$$\r\n",set_userset_data(func_table, 1));  return set_userset_data(func_table, 1);
        case XML_USERSET_NAME2  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME2 (%d) $$$\r\n",set_userset_data(func_table, 2));  return set_userset_data(func_table, 2);
        case XML_USERSET_NAME3  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME3 (%d) $$$\r\n",set_userset_data(func_table, 3));  return set_userset_data(func_table, 3);
        case XML_USERSET_NAME4  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME4 (%d) $$$\r\n",set_userset_data(func_table, 4));  return set_userset_data(func_table, 4);
        case XML_USERSET_NAME5  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME5 (%d) $$$\r\n",set_userset_data(func_table, 5));  return set_userset_data(func_table, 5);
        case XML_USERSET_NAME6  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME6 (%d) $$$\r\n",set_userset_data(func_table, 6));  return set_userset_data(func_table, 6);
        case XML_USERSET_NAME7  :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_NAME7 (%d) $$$\r\n",set_userset_data(func_table, 7));  return set_userset_data(func_table, 7);
        case XML_FPGA_VER0      :  if (DEBUGXML_R)func_printf("--- get XML_FPGA_VER0  (%s) $$$\r\n",&FPGA_VER[0]     );  return set_str_data(&FPGA_VER[0]);
        case XML_FPGA_VER1      :  if (DEBUGXML_R)func_printf("--- get XML_FPGA_VER1  (%s) $$$\r\n",&FPGA_VER[4]     );  return set_str_data(&FPGA_VER[4]);
        case XML_FPGA_VER2      :  if (DEBUGXML_R)func_printf("--- get XML_FPGA_VER2  (%s) $$$\r\n",&FPGA_VER[8]     );  return set_str_data(&FPGA_VER[8]);
        case XML_FPGA_VER3      :  if (DEBUGXML_R)func_printf("--- get XML_FPGA_VER3  (%s) $$$\r\n",&FPGA_VER[12]    );  return set_str_data(&FPGA_VER[12]);
        case XML_TFT_SER0       :  if (DEBUGXML_R)func_printf("--- get XML_TFT_SER0   (%s) $$$\r\n",&TFT_SERIAL[0]   );  return set_str_data(&TFT_SERIAL[0]);
        case XML_TFT_SER1       :  if (DEBUGXML_R)func_printf("--- get XML_TFT_SER1   (%s) $$$\r\n",&TFT_SERIAL[4]   );  return set_str_data(&TFT_SERIAL[4]);
        case XML_TFT_SER2       :  if (DEBUGXML_R)func_printf("--- get XML_TFT_SER2   (%s) $$$\r\n",&TFT_SERIAL[8]   );  return set_str_data(&TFT_SERIAL[8]);
        case XML_TFT_SER3       :  if (DEBUGXML_R)func_printf("--- get XML_TFT_SER3   (%s) $$$\r\n",&TFT_SERIAL[12]  );  return set_str_data(&TFT_SERIAL[12]);
        case XML_PANEL_SER0     :  if (DEBUGXML_R)func_printf("--- get XML_PANEL_SER0 (%s) $$$\r\n",&PANEL_SERIAL[0] );  return set_str_data(&PANEL_SERIAL[0]);
        case XML_PANEL_SER1     :  if (DEBUGXML_R)func_printf("--- get XML_PANEL_SER1 (%s) $$$\r\n",&PANEL_SERIAL[4] );  return set_str_data(&PANEL_SERIAL[4]);
        case XML_PANEL_SER2     :  if (DEBUGXML_R)func_printf("--- get XML_PANEL_SER2 (%s) $$$\r\n",&PANEL_SERIAL[8] );  return set_str_data(&PANEL_SERIAL[8]);
        case XML_PANEL_SER3     :  if (DEBUGXML_R)func_printf("--- get XML_PANEL_SER3 (%s) $$$\r\n",&PANEL_SERIAL[12]);  return set_str_data(&PANEL_SERIAL[12]);
        case XML_BWIDTH         :  fval = (func_width * func_height * 16 * func_frate) / 1048576.0;
                                   temp = (u32*)&fval;                    
                                   if (DEBUGXML_R){func_printf("--- get XML_BWIDTH (%d) $$$\r\n",(*temp));}                return (*temp);
        case XML_GEV_SPEED      :  if (DEBUGXML_R)func_printf("--- get XML_GEV_SPEED (%d) $$$\r\n",GEV_SPEED);           return GEV_SPEED;
        case XML_FRATE_MIN      :     temp = (u32*)&func_frate_min;        
                                   if (DEBUGXML_R) {
                                        char DEBUG_MSG[16];
                                         memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));  //#220502
                                         sprintf(DEBUG_MSG,"%f", func_frate_min);
                                          gcvt(func_frate, 4, DEBUG_MSG); //# ???
                                        func_printf("--- get XML_FRATE_MIN (%s) $$$\r\n", DEBUG_MSG);
                                   }
                                   return (*temp);
        case XML_FRATE_MAX      :  temp = (u32*)&func_frate_max;        
                                   if (DEBUGXML_R) {
                                        char DEBUG_MSG[16];
                                         memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));  //#220502
                                         sprintf(DEBUG_MSG,"%f", func_frate_max);
                                         gcvt(func_frate, 4, DEBUG_MSG); ///# ???
                                        func_printf("--- get XML_FRATE_MAX (%s) $$$\r\n", DEBUG_MSG);
                                   }
                                   return (*temp);
        case XML_GEWT_MIN       :  if (DEBUGXML_R)func_printf("--- get XML_GEWT_MIN (%d) $$$\r\n",func_gewt_min);                return func_gewt_min;
        case XML_GEWT_MAX       :  if (DEBUGXML_R)func_printf("--- get XML_GEWT_MAX (%d) $$$\r\n",func_gewt_max);                return func_gewt_max;
        case XML_RSND_PACKET    :  if (DEBUGXML_R)func_printf("--- get XML_RSND_PACKET (%d) $$$\r\n",framebuf_rsnd_ok);          return framebuf_rsnd_ok;
        case XML_WIDTH_MIN      :  if (DEBUGXML_R)func_printf("--- get XML_WIDTH_MIN (%d) $$$\r\n",MIN_WIDTH);                   return MIN_WIDTH;
        case XML_HEIGHT_MIN     :  if (DEBUGXML_R)func_printf("--- get XML_HEIGHT_MIN (%d) $$$\r\n",MIN_HEIGHT);                 return MIN_HEIGHT;
        case XML_OFFSETX_MIN    :  if (DEBUGXML_R)func_printf("--- get XML_OFFSETX_MIN (%d) $$$\r\n",MIN_OFFSETX);               return MIN_OFFSETX;
        case XML_OFFSETY_MIN    :  if (DEBUGXML_R)func_printf("--- get XML_OFFSETY_MIN (%d) $$$\r\n",MIN_OFFSETY);               return MIN_OFFSETY;
        case XML_OFFSETX_MAX    :  if (DEBUGXML_R)func_printf("--- get XML_OFFSETX_MAX (%d) $$$\r\n",MAX_WIDTH - func_width);    return MAX_WIDTH - func_width;
        case XML_OFFSETY_MAX    :  if (DEBUGXML_R)func_printf("--- get XML_OFFSETY_MAX (%d) $$$\r\n",MAX_HEIGHT - func_height);  return MAX_HEIGHT - func_height;
        case XML_INTERVALX      :  if (DEBUGXML_R)func_printf("--- get XML_INTERVALX (%d) $$$\r\n",INTERVALX);                   return INTERVALX;
        case XML_INTERVALY      :  if (DEBUGXML_R)func_printf("--- get XML_INTERVALY (%d) $$$\r\n",INTERVALY);                   return INTERVALY;
        case XML_DGAIN_MIN      :  if (DEBUGXML_R)func_printf("--- get XML_DGAIN_MIN (%d) $$$\r\n",MIN_DGAIN);                   return MIN_DGAIN;
        case XML_DGAIN_MAX      :  if (DEBUGXML_R)func_printf("--- get XML_DGAIN_MAX (%d) $$$\r\n",MAX_DGAIN);                   return MAX_DGAIN;
        case XML_RUNNING_TIME0  :  if (DEBUGXML_R)func_printf("--- get XML_RUNNING_TIME0 (%d) $$$\r\n",set_str_data(&RUNNING_TIME[0]) ); disp_cmd_rtime();   return set_str_data(&RUNNING_TIME[0]);
        case XML_RUNNING_TIME1  :  if (DEBUGXML_R)func_printf("--- get XML_RUNNING_TIME1 (%d) $$$\r\n",set_str_data(&RUNNING_TIME[4]) ); return set_str_data(&RUNNING_TIME[4]);
        case XML_RUNNING_TIME2  :  if (DEBUGXML_R)func_printf("--- get XML_RUNNING_TIME2 (%d) $$$\r\n",set_str_data(&RUNNING_TIME[8]) ); return set_str_data(&RUNNING_TIME[8]);
        case XML_RUNNING_TIME3  :  if (DEBUGXML_R)func_printf("--- get XML_RUNNING_TIME3 (%d) $$$\r\n",set_str_data(&RUNNING_TIME[12])); return set_str_data(&RUNNING_TIME[12]);
        case XML_IMG_AVG_DOSE0  :  if (DEBUGXML_R)func_printf("--- get XML_IMG_AVG_DOSE0 (%d) $$$\r\n",func_img_avg_dose0);      return func_img_avg_dose0;
        case XML_IMG_AVG_DOSE1  :  if (DEBUGXML_R)func_printf("--- get XML_IMG_AVG_DOSE1 (%d) $$$\r\n",func_img_avg_dose1);      return func_img_avg_dose1;
        case XML_IMG_AVG_DOSE2  :  if (DEBUGXML_R)func_printf("--- get XML_IMG_AVG_DOSE2 (%d) $$$\r\n",func_img_avg_dose2);      return func_img_avg_dose2;
        case XML_IMG_AVG_DOSE3  :  if (DEBUGXML_R)func_printf("--- get XML_IMG_AVG_DOSE3 (%d) $$$\r\n",func_img_avg_dose3);      return func_img_avg_dose3;
        case XML_IMG_AVG_DOSE4  :  if (DEBUGXML_R)func_printf("--- get XML_IMG_AVG_DOSE4 (%d) $$$\r\n",func_img_avg_dose4);      return func_img_avg_dose4;
        case XML_BINNING_MODE   :  if (DEBUGXML_R)func_printf("--- get XML_BINNING_MODE (%d) $$$\r\n",func_binning_mode);        return func_binning_mode;
//      case XML_DOT_NUMBER     :     return func_defect_cnt + func_defect_cnt2;
        case XML_DOT_NUMBER     :  if (DEBUGXML_R)func_printf("--- get XML_DOT_NUMBER (%d) $$$\r\n",func_defect_cnt + func_defect_cnt2 + func_defect_cnt3); 
                                       return func_defect_cnt + func_defect_cnt2 + func_defect_cnt3;    // dskim - 21.03.02 - factory map
        case XML_IMAGE_PROC     :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_PROC (%d) $$$\r\n",func_img_proc);                 return func_img_proc;
        case XML_ACCESS_AUTH    :  if (DEBUGXML_R)func_printf("--- get XML_ACCESS_AUTH (%d) $$$\r\n",func_access_level);            return func_access_level;
        case XML_PASSWORD       :  if (DEBUGXML_R)func_printf("--- get XML_PASSWORD (%d) $$$\r\n",0);                               return 0;
        case XML_USERSET_CMD    :  if (DEBUGXML_R)func_printf("--- get XML_USERSET_CMD (%d) $$$\r\n",0);                            return 0;
        case XML_ADDRESS_TABLE  :  if (DEBUGXML_R)func_printf("--- get XML_ADDRESS_TABLE (%d) $$$\r\n",func_addr_table);            return func_addr_table;
        case XML_ADDRESS0       :  if (DEBUGXML_R)func_printf("--- get XML_ADDRESS0 (%d) $$$\r\n",set_str_data(&func_reg_addr[0])); return set_str_data(&func_reg_addr[0]);
        case XML_ADDRESS1       :  if (DEBUGXML_R)func_printf("--- get XML_ADDRESS1 (%d) $$$\r\n",set_str_data(&func_reg_addr[4])); return set_str_data(&func_reg_addr[4]);
        case XML_ADDRESS2       :  if (DEBUGXML_R)func_printf("--- get XML_ADDRESS2 (%d) $$$\r\n",set_str_data(&func_reg_addr[8])); return set_str_data(&func_reg_addr[8]);
        case XML_DATA0          :  if (DEBUGXML_R)func_printf("--- get XML_DATA0 (%d) $$$\r\n"   ,set_str_data(&func_reg_data[0])); return set_str_data(&func_reg_data[0]);
        case XML_DATA1          :  if (DEBUGXML_R)func_printf("--- get XML_DATA1 (%d) $$$\r\n"   ,set_str_data(&func_reg_data[4])); return set_str_data(&func_reg_data[4]);
        case XML_DATA2          :  if (DEBUGXML_R)func_printf("--- get XML_DATA2 (%d) $$$\r\n"   ,set_str_data(&func_reg_data[8])); return set_str_data(&func_reg_data[8]);
        case XML_ERASE_CMD      :  if (DEBUGXML_R)func_printf("--- get XML_ERASE_CMD (%d) $$$\r\n",0);                              return 0;
        case XML_CALIB_MAP      :  if (DEBUGXML_R)func_printf("--- get XML_CALIB_MAP (%d) $$$\r\n",func_calib_map);                 return func_calib_map;
        case XML_CALIB_CMD      :  if (DEBUGXML_R)func_printf("--- get XML_CALIB_CMD (%d) $$$\r\n",func_calib_cmd);                 return func_calib_cmd;    // dskim - 22.01.13 - Write Defect 놓치는 현상 관련, API 동기화
        case XML_MANUAL_DOT_X   :  if (DEBUGXML_R)func_printf("--- get XML_MANUAL_DOT_X (%d) $$$\r\n",func_pointx);                 return func_pointx;
        case XML_MANUAL_DOT_Y   :  if (DEBUGXML_R)func_printf("--- get XML_MANUAL_DOT_Y (%d) $$$\r\n",func_pointy);                 return func_pointy;
        case XML_UPDATE_STATE   :  if (DEBUGXML_R)func_printf("--- get XML_UPDATE_STATE (%d) $$$\r\n",0);                           return 0;
        case XML_SHUTTER_MODE   :  if (DEBUGXML_R)func_printf("--- get XML_SHUTTER_MODE (%d) $$$\r\n",func_shutter_mode);           return func_shutter_mode;
        case XML_TEMP_BD0       :    read_ds1731_temp();
                                    temp = (u32*)&func_ds1731_temp[0];    
                                    return (*temp);
        case XML_TEMP_BD1       :    // read_ds1731_temp(); no need to read
                                    temp = (u32*)&func_ds1731_temp[1];    
                                    return (*temp);
        case XML_TEMP_FPGA      :    read_fpga_temp();
                                    temp = (u32*)&func_fpga_temp;        
                                    return (*temp);
        case XML_TEMP_PHY       :    read_phy_temp();
                                    return func_phy_temp;
                                    // TI_ROIC
//      case XML_IFS              :    return ROIC_MAT[1].data;
        case XML_IFS              :  if (DEBUGXML_R)func_printf("--- get XML_IFS (%d) $$$\r\n",ROIC_MAT[0].data);       return ROIC_MAT[0].data;    // dskim
        case XML_IFS_MIN          :  if (DEBUGXML_R)func_printf("--- get XML_IFS_MIN (%d) $$$\r\n",MIN_IFS);            return MIN_IFS;
        case XML_IFS_MAX          :  if (DEBUGXML_R)func_printf("--- get XML_IFS_MAX (%d) $$$\r\n",MAX_IFS);            return MAX_IFS;
        case XML_AVG_LEVEL        :  if (DEBUGXML_R)func_printf("--- get XML_AVG_LEVEL (%d) $$$\r\n",user_avg_level);   return user_avg_level;
        case XML_REBOOT           :  if (DEBUGXML_R)func_printf("--- get XML_REBOOT (%d) $$$\r\n",0);                   return 0;
//      case XML_BUSY             :  /* if (DEBUGXML_R)func_printf("--- get XML_BUSY (%d) $$$\r\n",func_busy); */       return func_busy;
        case XML_BUSY             :  /* if (DEBUGXML_R)func_printf("--- get XML_BUSY (%d) $$$\r\n",func_busy); */       return func_busy | REG(ADDR_FW_BUSY); //# 230322
        case XML_BUSY_TIME        :  if (DEBUGXML_R)func_printf("--- get XML_BUSY_TIME (%d) $$$\r\n",func_busy_time);   return func_busy_time;
        case XML_DEFECT_MAP       :  if (DEBUGXML_R)func_printf("--- get XML_DEFECT_MAP (%d) $$$\r\n",func_defect_map); return func_defect_map;
        case XML_HW_DEBUG         :  if (DEBUGXML_R)func_printf("--- get XML_HW_DEBUG (%d) $$$\r\n",func_hw_debug);     return func_hw_debug;
        case XML_UART_CMD0        :     return set_str_data(&user_cmd[0]);
        case XML_UART_CMD1        :     return set_str_data(&user_cmd[4]);
        case XML_UART_CMD2        :     return set_str_data(&user_cmd[8]);
        case XML_UART_CMD3        :     return set_str_data(&user_cmd[12]);
        case XML_UART_CMD4        :     return set_str_data(&user_cmd[16]);
        case XML_UART_CMD5        :     return set_str_data(&user_cmd[20]);
        case XML_UART_CMD6        :     return set_str_data(&user_cmd[24]);
        case XML_UART_CMD7        :     return set_str_data(&user_cmd[28]);
        case XML_BRIGHT           :  if (DEBUGXML_R)func_printf("--- get XML_BRIGHT (%d) $$$\r\n",func_bright);                   return func_bright;
        case XML_CONTRAST         :  if (DEBUGXML_R)func_printf("--- get XML_CONTRAST (%d) $$$\r\n",func_contrast);               return func_contrast;
        case XML_EXP_MODE         :  if (DEBUGXML_R)func_printf("--- get XML_EXP_MODE (%d) $$$\r\n",func_exp_mode);               return func_exp_mode;
        case XML_FRAME_NUM        :  if (DEBUGXML_R)func_printf("--- get XML_FRAME_NUM (%d) $$$\r\n",func_frame_num);             return func_frame_num;
        case XML_READ_DEFECT_SEL  :  if (DEBUGXML_R)func_printf("--- get XML_READ_DEFECT_SEL (%d) $$$\r\n",func_read_defect);     return func_read_defect;
        case XML_READ_DEFECT      :  if (DEBUGXML_R)func_printf("--- get XML_READ_DEFECT (%d) $$$\r\n",0);                        return 0;
        case XML_EXT_TRIG_VALID   :  if (DEBUGXML_R)func_printf("--- get XML_EXT_TRIG_VALID (%d) $$$\r\n",func_trig_valid);       return func_trig_valid;
        case XML_EXT_OUT_ACTIVE   :  if (DEBUGXML_R)func_printf("--- get XML_EXT_OUT_ACTIVE (%d) $$$\r\n",func_trig_out_active);  return func_trig_out_active;
        case XML_EXT_IN_ACTIVE    :  if (DEBUGXML_R)func_printf("--- get XML_EXT_IN_ACTIVE (%d) $$$\r\n",func_trig_in_active);    return func_trig_in_active;
        case XML_EXT_TRIG_DELAY   :  if (DEBUGXML_R)func_printf("--- get XML_EXT_TRIG_DELAY (%d) $$$\r\n",func_trig_delay);       return func_trig_delay;
        case XML_EXT_DELAY_MIN    :  if (DEBUGXML_R)func_printf("--- get XML_EXT_DELAY_MIN (%d) $$$\r\n",func_trig_delay_min);    return func_trig_delay_min;
        case XML_EXT_DELAY_MAX    :  if (DEBUGXML_R)func_printf("--- get XML_EXT_DELAY_MAX (%d) $$$\r\n",func_trig_delay_max);    return func_trig_delay_max;
        case XML_CHECK_CALIB      :  if (DEBUGXML_R)func_printf("--- get XML_CHECK_CALIB (%d) $$$\r\n",func_check_gain_calib);    return func_check_gain_calib;
        case XML_EDGE_CUT_LEFT    :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_LEFT (%d) $$$\r\n",0);                      return 0;
        case XML_EDGE_CUT_RIGHT   :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_RIGHT (%d) $$$\r\n",0);                     return 0;
        case XML_EDGE_CUT_BOTTOM  :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_BOTTOM (%d) $$$\r\n",0);                    return 0;
        case XML_EDGE_CUT_TOP     :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_TOP (%d) $$$\r\n",0);                       return 0;
        case XML_EDGE_CUT_VALUE   :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_VALUE (%d) $$$\r\n",0);                     return 0;
        case XML_EDGE_CUT_READ    :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_READ (%d) $$$\r\n",0);                      return 0;
        case XML_EDGE_CUT_SAVE    :  if (DEBUGXML_R)func_printf("--- get XML_EDGE_CUT_SAVE (%d) $$$\r\n",0);                      return 0;
        case XML_IMAGE_ACC        :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_ACC (%d) $$$\r\n",func_image_acc);             return func_image_acc;
        case XML_IMAGE_ACC_VALUE  :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_ACC_VALUE (%d) $$$\r\n",func_image_acc_value); return func_image_acc_value;
        case XML_IMAGE_EDGE       :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_EDGE (%d) $$$\r\n",0);                         return 0; // dskim - 21.10.20 - 실제사용하지 않음
        case XML_IMAGE_EDGE_VALUE :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_EDGE_VALUE (%d) $$$\r\n",0);                   return 0; // dskim - 21.10.20 - 실제사용하지 않음
        case XML_IMAGE_EDGE_OFFSET:  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_EDGE_OFFSET (%d) $$$\r\n",0);                  return 0; // dskim - 21.10.20 - 실제사용하지 않음
        case XML_IMAGE_DNR        :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_DNR (%d) $$$\r\n",func_image_dnr);             return func_image_dnr;
        case XML_IMAGE_DNR_VALUE  :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_DNR_VALUE (%d) $$$\r\n",func_image_dnr_value); return func_image_dnr_value;
        case XML_IMAGE_DNR_OFFSET :  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_DNR_OFFSET (%d) $$$\r\n",func_image_dnr_offset);   return func_image_dnr_offset;
        case XML_EXT_AUTO_OFFSET  :  if (DEBUGXML_R)func_printf("--- get XML_EXT_AUTO_OFFSET (%d) $$$\r\n",func_trig_auto_offset);    return func_trig_auto_offset;
        case XML_API_EXT_TRIG     :  if (DEBUGXML_R)func_printf("--- get XML_API_EXT_TRIG (%d) $$$\r\n",func_api_ext_trig);           return func_api_ext_trig;
        case XML_SW_DEBUG         :  if (DEBUGXML_R)func_printf("--- get XML_SW_DEBUG (%d) $$$\r\n",func_sw_debug);                   return func_sw_debug;
        case XML_EXPOSURE_TYPE    :  if (DEBUGXML_R)func_printf("--- get XML_EXPOSURE_TYPE (%d) $$$\r\n",func_exposure_type);         return func_exposure_type;
        case XML_STATIC_AVG_ENABLE:  if (DEBUGXML_R)func_printf("--- get XML_STATIC_AVG_ENABLE (%d) $$$\r\n",func_static_avg_enable); return func_static_avg_enable;
        case XML_RESET_DEVICE     :  if (DEBUGXML_R)func_printf("--- get XML_RESET_DEVICE (%d) $$$\r\n",0);                           return 0;

        case XML_SLEEP_MODE          :  if (DEBUGXML_R)func_printf("--- get XML_SLEEP_MODE (%d) $$$\r\n"           ,func_sleep_mode_enable);    return func_sleep_mode_enable;
        case XML_SLEEP_MODE_TIME     :  if (DEBUGXML_R)func_printf("--- get XML_SLEEP_MODE_TIME (%d) $$$\r\n"      ,func_sleep_mode_time);      return func_sleep_mode_time;
        case XML_IMAGE_ACC_AUTO_RESET:  if (DEBUGXML_R)func_printf("--- get XML_IMAGE_ACC_AUTO_RESET (%d) $$$\r\n" ,func_image_acc_auto_reset); return func_image_acc_auto_reset;
        case XML_GRAB_COUNT          :  if (DEBUGXML_R)func_printf("--- get XML_GRAB_COUNT (%d) $$$\r\n",func_grab_count);         return func_grab_count;
        case XML_BOOT_COUNT          :  if (DEBUGXML_R)func_printf("--- get XML_BOOT_COUNT (%d) $$$\r\n",func_boot_count);         return func_boot_count;
        case XML_OPERATING_TIME_H    :  if (DEBUGXML_R)func_printf("--- get XML_OPERATING_TIME_H (%d) $$$\r\n",func_oper_time_h);  return func_oper_time_h;
        case XML_OPERATING_TIME_M    :  if (DEBUGXML_R)func_printf("--- get XML_OPERATING_TIME_M (%d) $$$\r\n",func_oper_time_m);  return func_oper_time_m;
        case XML_TEMP_BD2            :    read_ds1731_temp();
                                        temp = (u32*)&func_ds1731_temp[2];
                                        return (*temp);
        case XML_TEMP_BD3            :    read_ds1731_temp();
                                        temp = (u32*)&func_ds1731_temp[3];
                                        return (*temp);
        case XML_SW_CALIB_MODE       :  if (DEBUGXML_R)func_printf("--- get XML_SW_CALIB_MODE (%d) $$$\r\n",func_sw_calibration_mode);    return func_sw_calibration_mode;
        case XML_LOAD_HW_CALIB       :  if (DEBUGXML_R)func_printf("--- get XML_LOAD_HW_CALIB (%d) $$$\r\n",is_load_hw_calibration);      return is_load_hw_calibration;
        //#
        case XML_HW_VER0        :  if (DEBUGXML_R)func_printf("--- get XML_HW_VER0  (%s) $$$\r\n",&HW_VER[0]     );  return set_str_data(&HW_VER[0]);
        case XML_HW_VER1        :  if (DEBUGXML_R)func_printf("--- get XML_HW_VER1  (%s) $$$\r\n",&HW_VER[4]     );  return set_str_data(&HW_VER[4]);
        case XML_HW_VER2        :  if (DEBUGXML_R)func_printf("--- get XML_HW_VER2  (%s) $$$\r\n",&HW_VER[8]     );  return set_str_data(&HW_VER[8]);
        case XML_HW_VER3        :  if (DEBUGXML_R)func_printf("--- get XML_HW_VER3  (%s) $$$\r\n",&HW_VER[12]    );  return set_str_data(&HW_VER[12]);

        case XML_FACTORY_MAP_MODE   :  if (DEBUGXML_R)func_printf("--- get XML_FACTORY_MAP_MODE (%d) $$$\r\n",is_factory_map_mode); return is_factory_map_mode;
        case XML_GAINREF_NUMLIM     :  if (DEBUGXML_R)func_printf("--- get XML_GAINREF_LIMIT (%d) $$$\r\n",func_gainref_numlim);    return func_gainref_numlim;

        case XML_IMAGE_TOPVALUE : if (DEBUGXML_R)func_printf("--- get XML_IMAGE_TOPVALUE (%d) $$$\r\n",func_image_topvalue); return func_image_topvalue;
        case XML_FPGA_BNC       : if (DEBUGXML_R)func_printf("--- get XML_FPGA_BNC       (%d) $$$\r\n",func_bnc); return func_bnc;
        case XML_FPGA_EQ        : if (DEBUGXML_R)func_printf("--- get XML_FPGA_EQ        (%d) $$$\r\n",func_eq); return func_eq;

        case XML_ABLE_BINN_NUM  : if (DEBUGXML_R)func_printf("--- get XML_ABLE_BINN_NUM (%d) $$$\r\n",func_able_binn_num); return func_able_binn_num;
        case XML_ABLE_GAIN_NUM  : if (DEBUGXML_R)func_printf("--- get XML_ABLE_GAIN_NUM (%d) $$$\r\n",func_able_gain_num); return func_able_gain_num;
        case XML_ABLE_DNR       : if (DEBUGXML_R)func_printf("--- get XML_ABLE_DNR (%d) $$$\r\n"     ,func_able_dnr);      return func_able_dnr;
        //$ 250627
        case XML_READ_DEFECT_STT : if (DEBUGXML_R)func_printf("--- get XML_READ_DEFECT_STT (%d) $$$\r\n",func_read_defect_stt); return func_read_defect_stt;
        case XML_READ_DEFECT_NUM : if (DEBUGXML_R)func_printf("--- get XML_READ_DEFECT_NUM (%d) $$$\r\n",func_read_defect_num); return func_read_defect_num;

        // Packet size margin
        case 0x10000000:    return SCPS_MIN + (gige_get_gev_version() == 2 ? 48 : 36);
        case 0x10000004:    return SCPS_MAX + (gige_get_gev_version() == 2 ? 48 : 36);
        case 0x10000008:    return SCPS_INC;
        // Authentication and evaluation status
        case 0x1000000C:    return (u32)gige_get_auth_status();
        case 0x10000010:    return (u32)gige_get_license_checksum();
        // Special memory areas
        default:            // Configuration EEPROM
                            if ((address >= 0xFBFF0000) && (address < 0xFBFF2000))
                                return eeprom_read_dword((u16)(address - 0xFBFF0000));
                            // SPI flash memory
                            if (address >= 0xFE000000){
                                #ifdef DEBUGXML_PRINT
                                    u32 tempread = flash_read_dword(address - 0xFE000000);
                                    func_printf("%c", (tempread>>24) & 0xff);
                                    func_printf("%c", (tempread>>16) & 0xff);
                                    func_printf("%c", (tempread>> 8) & 0xff);
                                    func_printf("%c", (tempread>> 0) & 0xff);
                                #endif
                                return flash_read_dword(address - 0xFE000000);
                            }
/*    	
        // User registers
        case 0x0000A000:        return video_gcsr;
        case 0x0000A004:        return video_width;
        case 0x0000A008:        return video_height;
        case 0x0000A00C:        return video_offs_x;
        case 0x0000A010:        return video_offs_y;
        case 0x0000A014:        bpp = (((video_pixfmt & 0x00FF0000) >> 16) + 7) / 8;
                                return ((video_width * bpp) + framebuf_pad_x);
        case 0x0000A018:        return video_pixfmt;
        case 0x0000A01C:        return video_max_width;
        case 0x0000A020:        return video_max_height;
      //case 0x0000A024:        return framebuf_bpb;        // Replaced by SCMBSx bootstrap register
        case 0x0000A028:        return video_acq_mode;
        case 0x0000A02C:        return video_gap_x;
        case 0x0000A030:        return video_gap_y;
        case 0x0000A034:        framerate = ((float)VIDEO_CLK*user_pixperclock)/((video_width + video_gap_x)*(video_height + video_gap_y));
                                usleep(1000);               // Needed to get correct frame rate value
                                temp = (u32*)&framerate;    // Trick to transfer float value through u32 variable
                                return *temp;               // It might be needed to swap bytes in return value in case of endianess problems
        case 0x0000A100:        return video_chunk_ctrl;
        case 0x0000A104:        return video_chunk_enable;
        // EventTestTimestamp values
        case 0x0000A10C:        return (u32)(event_test_timestamp >> 32);
        case 0x0000A110:        return (u32)(event_test_timestamp & 0xFFFFFFFF);
        // Packet size margins
        case 0x10000000:        return SCPS_MIN + (gige_get_gev_version() == 2 ? 48 : 36);
        case 0x10000004:        return SCPS_MAX + (gige_get_gev_version() == 2 ? 48 : 36);
        case 0x10000008:        return SCPS_INC;
        // Authentication and evaluation status
        case 0x1000000C:        return (u32)gige_get_auth_status();
        case 0x10000010:        return (u32)gige_get_license_checksum();
        // Stream channel extended bootstrap registers (GEV 2.2)
//        case MAP_SCEBA + 0x00:  return 0;
        // Special memory areas
        default:                // Configuration EEPROM
                                if ((address >= MAP_EEPROM) && (address < (MAP_EEPROM + MAP_EEPROM_LEN)))
                                    return eeprom_read_dword((u16)(address - MAP_EEPROM));
                                // SPI flash memory
                                if (address >= MAP_FLASH)
                                    return flash_read_dword(address - MAP_FLASH);
*/
    }

    *status = GEV_STATUS_INVALID_ADDRESS;
    return 0;
}


// ---- Write GigE Vision user-space bootstrap register ------------------------
//
//           This function must be always implemented!
//           It is called by the gige_callback() from libgige
//
// address = address of the register within GigE Vision manufacturer-specific
//           register address space (0x0000A000 - 0xFFFFFFFF)
// value   = data to be written
// status  = return status value, should be one of following:
//           GEV_STATUS_SUCCESS         - write passed correctly
//           GEV_STATUS_INVALID_ADDRESS - register at 'address' does not exist
//           GEV_STATUS_WRITE_PROTECT   - register at 'address' is read-only
//           GEV_STATUS_LOCAL_PROBLEM   - problem while setting register value
//           GEV_STATUS_ERROR           - unspecified error
//
#define DBG_setreg 0
void set_user_reg(u32 address, u32 value, u16 *status)
{
    int update_leader = 0, update_trailer = 0;
    u32 temp;
    u32 framedelay, rowdelay;
    u32 chunk_size;
    u32 chunk_layout_id = 0;            // Chunk layout id
    static u32 old_chunk_layout_id = 0;
    float framerate;
    float *f;

    float fval;
    float dividend, divider;
    u32 prev, curr;
    u32 offsetx, offsety, width, height;
    u32 grab  = func_grab_en;

    *status = GEV_STATUS_SUCCESS;
    switch (address)
    {
        // User registers
        case XML_OUT_EN            :     if (DEBUGXML_W)func_printf("$$$ set XML_OUT_EN (%d) $$$\r\n",value);
            //if(func_userset_cmd | func_flash_cmd | func_calib_cmd | func_busy)
                                    if(func_userset_cmd | func_flash_cmd | func_calib_cmd ) // remove busy checking for stop 211209mbh
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                    else {
//                                        if(func_sleep) //# The bw_align needs before showing image. 220510mbh
//                                            bw_align(); //# it makes loop in this cycle...

                                        REG(ADDR_OUT_EN) = value;
                                        gige_set_acquisition_status(0, value & 1);

                                        func_out_en = value; //# 220321mbh
                                    }
                                    break;
        case XML_WIDTH            :    if (DEBUGXML_W)func_printf("$$$ set XML_WIDTH (%d) $$$\r\n",value);
                                    if(REG(ADDR_OUT_EN)){ //# exception Acquiring
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                        break;
                                    }
//                                    else if(func_offsetx + value > MAX_WIDTH || value % INTERVALX){
////                                        *status = GEV_STATUS_INVALID_PARAMETER;
//
//                                    	value = (int)((MAX_WIDTH/func_binning - func_offsetx) / INTERVALX) * INTERVALX;
//                                    	func_printf("%d=(int)((%d/%d - %d) / %d) * %d \r\n",value, MAX_WIDTH,func_binning,func_offsetx,INTERVALX,INTERVALX );
//                                    }

                                    //# after intervalx 4->16, size response have a bug. do recalculate width.
                                    if(MAX_WIDTH/func_binning < value + func_offsetx) //# 231013 1800 except
                                    {
                                    	value = (int)((MAX_WIDTH/func_binning - func_offsetx) / INTERVALX) * INTERVALX; //# 231013
//                                    	func_printf("condition 1 \r\n");
                                    }
                                    else
                                    {
                                    	value = (int)(value / INTERVALX) * INTERVALX;
//                                    	func_printf("condition 2 \r\n");f
                                    }

//                                    func_printf("%d=((%d/%d - %d) / %d) * %d \r\n",value, MAX_WIDTH,func_binning,func_offsetx,INTERVALX,INTERVALX );
//                                    func_printf("func_offsetx(%d), func_offsety(%d), value(%d), func_height(%d) \r\n",func_offsetx, func_offsety, value, func_height);

                                        execute_cmd_grab(0);
                                        execute_cmd_roi(func_offsetx, func_offsety, value, func_height);
//                                        execute_cmd_fmax();
//                                        execute_cmd_frate((u32)(func_frate_max*1000));
                                        execute_cmd_fmax();
                                        execute_cmd_frate(0);
                                        execute_cmd_emax();
                                        execute_cmd_grab(grab);
    								    if(DBG_setreg)func_printf("#[DBG_setreg] func_width=%d \r\n",func_width);
    								    if(DBG_setreg)func_printf("#[DBG_setreg] func_height=%d \r\n",func_height);

                                    break;
        case XML_HEIGHT            :    if (DEBUGXML_W)func_printf("$$$ set XML_HEIGHT (%d) $$$\r\n",value);
                                    if(REG(ADDR_OUT_EN))
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                    else if(value % INTERVALY)
                                    	*status = GEV_STATUS_INVALID_PARAMETER;
                                    //$ 260220
                                    else{
                                    	if(ROIC_DUAL == 2){
                                    		u32 auto_offsety = ((MAX_HEIGHT / func_binning) - value) / 2;
                                    		auto_offsety = (auto_offsety / INTERVALY) * INTERVALY;

                                    		if(auto_offsety + value > MAX_HEIGHT){
                                    			*status = GEV_STATUS_INVALID_PARAMETER;
                                    			break;
                                    		}
                                    		execute_cmd_grab(0);
                                    		execute_cmd_roi(func_offsetx, auto_offsety, func_width, value);
                                    		execute_cmd_fmax();
                                    		execute_cmd_frate(0);
                                    		execute_cmd_emax();
                                    		execute_cmd_grab(grab);

                                    		func_printf("DUAL ROIC HEIGHT       = %d \r\n", func_height);
                                    		func_printf("DUAL ROIC auto offsety = %d \r\n", auto_offsety);
                                    	}

                                    	else{
                                    		if(func_offsety + value > MAX_HEIGHT)
                                    			*status = GEV_STATUS_INVALID_PARAMETER;
                                    		else{
                                        		execute_cmd_grab(0);
                                        		execute_cmd_roi(func_offsetx, func_offsety, func_width, value);
                                        		execute_cmd_fmax();
                                        		execute_cmd_frate(0);
                                        		execute_cmd_emax();
                                        		execute_cmd_grab(grab);
                                    		}
                                    	}
                                    }
//                                    else if(func_offsety + value > MAX_HEIGHT || value % INTERVALY)
//                                        *status = GEV_STATUS_INVALID_PARAMETER;
//                                    else {
//                                        execute_cmd_grab(0);
//                                        execute_cmd_roi(func_offsetx, func_offsety, func_width, value);
////                                        execute_cmd_fmax();
////                                        execute_cmd_frate((u32)(func_frate_max*1000));
//                                        execute_cmd_fmax();
//                                        execute_cmd_frate(0);
//                                        execute_cmd_emax();
//                                        execute_cmd_grab(grab);
//    								    if(DBG_setreg)func_printf("#[DBG_setreg] func_width=%d \r\n",func_width);
//    								    if(DBG_setreg)func_printf("#[DBG_setreg] func_height=%d \r\n",func_height);
//                                    }
                                    break;
        case XML_OFFSETX        :    if (DEBUGXML_W)func_printf("$$$ set XML_OFFSETX (%d) $$$\r\n",value);
                                    if(REG(ADDR_OUT_EN)){ //# exception Acquiring
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                        break;
                                    }
//                                    else if(value + func_width > MAX_WIDTH || value % INTERVALX)
//                                        *status = GEV_STATUS_INVALID_PARAMETER;
//                                    else {
//                                        execute_cmd_grab(0);
//                                        execute_cmd_roi(value, func_offsety, func_width, func_height);
////                                        execute_cmd_fmax();
////                                        execute_cmd_frate((u32)(func_frate_max*1000));
//                                        execute_cmd_fmax();
//                                        execute_cmd_frate(0);
//                                        execute_cmd_emax();
//                                        execute_cmd_grab(grab);
//                                    }
                                    //# after intervalx 4->16, size response have a bug. do recalculate width.
                                    value = (int)(value / OFFSINTVX) * OFFSINTVX; // offset by intervalx              //# 231013
									if(value + func_width > MAX_WIDTH/func_binning) // adjustment func_width          //# 231013
										func_width = (int)((MAX_WIDTH/func_binning - value) / INTERVALX) * INTERVALX; //# 231013

								    if(DBG_setreg)func_printf("#[DBG_setreg] func_width=%d \r\n",func_width);
								    if(DBG_setreg)func_printf("#[DBG_setreg] func_height=%d \r\n",func_height);
//                                	func_printf("%d=(int)((%d/%d - %d) / %d) * %d \r\n",func_width, MAX_WIDTH,func_binning,value,INTERVALX,INTERVALX );

									execute_cmd_grab(0);
									execute_cmd_roi(value, func_offsety, func_width, func_height);
									execute_cmd_fmax();
									execute_cmd_frate(0);
									execute_cmd_emax();
									execute_cmd_grab(grab);

                                    break;
        case XML_OFFSETY        :    if (DEBUGXML_W)func_printf("$$$ set XML_OFFSETY (%d) $$$\r\n",value);
        							//$ 260220
        							if(ROIC_DUAL == 2) break;
        							else {
        								if(REG(ADDR_OUT_EN))
        									*status = GEV_STATUS_ACCESS_DENIED;
        								else if(value + func_height > MAX_HEIGHT || value % INTERVALY)
        									*status = GEV_STATUS_INVALID_PARAMETER;
        								else {
        									execute_cmd_grab(0);
        									execute_cmd_roi(func_offsetx, value, func_width, func_height);
//                                        execute_cmd_fmax();
//                                        execute_cmd_frate((u32)(func_frate_max*1000));
        									execute_cmd_fmax();
        									execute_cmd_frate(0);
        									execute_cmd_emax();
        									execute_cmd_grab(grab);
    								    if(DBG_setreg)func_printf("#[DBG_setreg] func_width=%d \r\n",func_width);
    								    if(DBG_setreg)func_printf("#[DBG_setreg] func_height=%d \r\n",func_height);
        								}
        							}
                                     break;
        case XML_LINEPITCH      :    break;    // Read Only
        case XML_PIXFMT         :    break;    // Read Only
        case XML_WIDTH_MAX      :    break;    // Read Only
        case XML_HEIGHT_MAX     :    break;    // Read Only
        case XML_PLOAD_SIZE     :    *status = GEV_STATUS_WRITE_PROTECT;    break;
        case XML_ACQ_MODE       :    break;
        case XML_ROW_DELAY      :    break;
        case XML_FRAME_DELAY    :    break;
        case XML_FRATE          :
//                                    if (func_exposure_type==1){ // static mode use only EWT //# 221121 comment
//                                        if (DEBUGXML_W)func_printf("$$$ set XML_FRATE func_exposure_type==1 is DENIED $$$\r\n");
//                                        *status = GEV_STATUS_ACCESS_DENIED;
//                                    }
//                                    else if(func_trig_mode == 2){
                                    if(func_trig_mode == 2){
                                        if (DEBUGXML_W)func_printf("$$$ set XML_FRATE func_trig_mode==2 DENIED $$$\r\n");
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                    }
                                    else {
                                        temp = value;
                                        f = (float*)&temp;
                                        fval = *f;
                                        sys_state.float_state = 1;
                                        execute_cmd_frate2ewt((u32)(fval * 1000));
                                        if (DEBUGXML_W)func_printf("$$$ set XML_FRATE (%d) $$$\r\n",(u32)fval);
                                        sys_state.float_state = 0;
                                        execute_cmd_fmax();
                                        execute_cmd_frate(0);
                                        execute_cmd_emax();
                                    }
                                    break;
        case XML_TEST_PATTERN   :    if (DEBUGXML_W)func_printf("$$$ set XML_TEST_PATTERN (%d) $$$\r\n",value);
                                    execute_cmd_psel(value);                break;
//      case XML_GEWT           :    if(func_shutter_mode == 0 || func_trig_mode == 2)
        case XML_GEWT           :
//                                    if (func_shutter_mode==0){ // 220120mbh
//                                        if (DEBUGXML_W)func_printf("$$$ set XML_GEWT func_shutter_mode==0 DENIED $$$\r\n");
//                                        *status = GEV_STATUS_ACCESS_DENIED;
//                                    }
                                    if((func_shutter_mode==1)&&(func_trig_mode==2)) { // global-ext2 EWT is ctrl by EXT Triggger time. 220120mbh
                                        if (DEBUGXML_W)func_printf("$$$ set XML_GEWT func_trig_mode==2 DENIED $$$\r\n");
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                    }
                                    else {
                                        if (DEBUGXML_W)func_printf("$$$ set XML_GEWT (%d) $$$\r\n",value);
                                        execute_cmd_gewt(value);    // dskim - 21.10.20 - FreeRun, External2에서도 설정이 가능하도록 변경
                                        execute_cmd_fmax();
                                        execute_cmd_frate(0);
                                        execute_cmd_emax();
                                    }
                                    break;
        case XML_TRIG_MODE      :
                                    if (DEBUGXML_W)func_printf("$$$ set XML_TRIG_MODE (%d) $$$\r\n",value);
                                    if(func_trig_mode != value) {    // dskim - 2101.20
                                        execute_cmd_tmode(value);
//                                        execute_cmd_fmax();
//                                        execute_cmd_emax();
//                                        execute_cmd_frate_call();
//                                        execute_cmd_frate((u32)(func_frate*1000));
//                                        execute_cmd_gewt_calc();
                                        execute_cmd_fmax();
                                        execute_cmd_frate(0);
                                        execute_cmd_emax();

                                        execute_avaliable_check(); //# 230721
                                    }
                                   // func_trig_mode = value; //$ 250514 trig mode error debug
                                    break;
        case XML_GAIN_CAL       :   if (DEBUGXML_W)func_printf("$$$ set XML_GAIN_CAL (%d) $$$\r\n",value);
                                    if(value == 1 && func_ref_num < 2)
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                    else
                                        execute_cmd_gain(value);
                                    break;
        case XML_OFFSET_CAL     :   if (DEBUGXML_W)func_printf("$$$ set XML_OFFSET_CAL (%d) $$$\r\n",value);
                                    if(value == 1 && func_ref_num < 1)
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                    else
                                        execute_cmd_offset(value);
                                    break;
        case XML_DEFECT_CAL     :   if (DEBUGXML_W)func_printf("$$$ set XML_DEFECT_CAL (%d) $$$\r\n",value);
                                    execute_cmd_defect(value);               break;
        case XML_TABLE          :   if (DEBUGXML_W)func_printf("$$$ set XML_TABLE (%d) $$$\r\n",value);
                                    func_table = value;
                                    execute_cmd_wbs();
                                    break;
        case XML_DGAIN            :     if (DEBUGXML_W)func_printf("$$$ set XML_DGAIN (%d) $$$\r\n",value);
                                    execute_cmd_dgain(value);                break;
        case XML_USERSET_NAME0    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME0 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 0);  break;
        case XML_USERSET_NAME1    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME1 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 1);  break;
        case XML_USERSET_NAME2    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME2 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 2);  break;
        case XML_USERSET_NAME3    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME3 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 3);  break;
        case XML_USERSET_NAME4    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME4 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 4);  break;
        case XML_USERSET_NAME5    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME5 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 5);  break;
        case XML_USERSET_NAME6    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME6 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 6);  break;
        case XML_USERSET_NAME7    :     if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_NAME7 (%d) $$$\r\n",value);
                                    get_userset_data(func_table, value, 7);
                                    execute_cmd_wbs();
                                    break;
        case XML_FPGA_VER0        : break;
        case XML_FPGA_VER1        : break;
        case XML_FPGA_VER2        : break;
        case XML_FPGA_VER3        : break;
                                    // dskim - 22.01.13 - Secret mode에서만 입력이 가능하도록 변경
        case XML_TFT_SER0         :   if(func_access_level != 2)    *status = GEV_STATUS_ACCESS_DENIED;
                                    else {
                                        get_str_data(value, &TFT_SERIAL[0]);
                                        if (DEBUGXML_W)func_printf("$$$ set XML_TFT_SER0 (%s) $$$\r\n",&TFT_SERIAL[0]);
                                    }
                                    break;
        case XML_TFT_SER1         :     get_str_data(value, &TFT_SERIAL[4]);
                                    if (DEBUGXML_W)func_printf("$$$ set XML_TFT_SER1 (%s) $$$\r\n",&TFT_SERIAL[4]);
                                    break;
        case XML_TFT_SER2         :     get_str_data(value, &TFT_SERIAL[8]);
                                    if (DEBUGXML_W)func_printf("$$$ set XML_TFT_SER2 (%s) $$$\r\n",&TFT_SERIAL[8]);
                                    break;
        case XML_TFT_SER3         :     get_str_data(value, &TFT_SERIAL[12]);
                                    if (DEBUGXML_W)func_printf("$$$ set XML_TFT_SER3 (%s) $$$\r\n",&TFT_SERIAL[12]);
                                    execute_cmd_write_tft_sn();    // dskim - 22.01.13 - TFT(Panel) Serial Number 지워지지 않도록 변경
                                    break;
                                    // dskim - 21.05.13 - Secret mode에서만 입력이 가능하도록 변경
        case XML_PANEL_SER0       :     if(func_access_level != 2)    *status = GEV_STATUS_ACCESS_DENIED;
                                    else {
                                        get_str_data(value, &PANEL_SERIAL[0]);
                                        if (DEBUGXML_W)func_printf("$$$ set XML_PANEL_SER0 (%s) $$$\r\n",&PANEL_SERIAL[0]);
                                    }
                                    break;
        case XML_PANEL_SER1        :     get_str_data(value, &PANEL_SERIAL[4]);
                                    if (DEBUGXML_W)func_printf("$$$ set XML_PANEL_SER1 (%s) $$$\r\n",&PANEL_SERIAL[4]);
                                    break;
        case XML_PANEL_SER2        :     get_str_data(value, &PANEL_SERIAL[8]);
                                    if (DEBUGXML_W)func_printf("$$$ set XML_PANEL_SER2 (%d) $$$\r\n",&PANEL_SERIAL[8]);
                                    break;
        case XML_PANEL_SER3        :     get_str_data(value, &PANEL_SERIAL[12]);
                                    if (DEBUGXML_W)func_printf("$$$ set XML_PANEL_SER3 (%d) $$$\r\n",&PANEL_SERIAL[12]);
                                    execute_cmd_write_detector_sn();    // dskim - 21.05.13 - Serial Number 지워지지 않도록 변경
                                     break;
        case XML_BWIDTH            : break;
        case XML_GEV_SPEED         : break;
        case XML_FRATE_MIN         : break;
        case XML_FRATE_MAX         : break;
        case XML_GEWT_MIN          : break;
        case XML_GEWT_MAX          : break;
        case XML_RSND_PACKET       : break;
        case XML_WIDTH_MIN         : break;
        case XML_HEIGHT_MIN        : break;
        case XML_OFFSETX_MIN       : break;
        case XML_OFFSETY_MIN       : break;
        case XML_OFFSETX_MAX       : break;
        case XML_OFFSETY_MAX       : break;
        case XML_INTERVALX         : break;
        case XML_INTERVALY         : break;
        case XML_DGAIN_MIN         : break;
        case XML_DGAIN_MAX         : break;
        case XML_RUNNING_TIME0     : break;
        case XML_RUNNING_TIME1     : break;
        case XML_RUNNING_TIME2     : break;
        case XML_RUNNING_TIME3     : break;
        case XML_IMG_AVG_DOSE0     : break;
        case XML_IMG_AVG_DOSE1     : break;
        case XML_IMG_AVG_DOSE2     : break;
        case XML_IMG_AVG_DOSE3     : break;
        case XML_BINNING_MODE      : if (DEBUGXML_W)func_printf("$$$ set XML_BINNING_MODE (%d) $$$\r\n",value);
                                     if(REG(ADDR_OUT_EN)) {
                                        if (DEBUGXML_W)func_printf("$$$ set XML_BINNING_MODE ACCESS DENIED $$$\r\n");
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                     }
                                     else {
                                        prev = func_binning_mode;
                                        curr = value;

                                        if (prev == 0)       dividend = 1;
                                        else if (prev <= 3)  dividend = 2;
                                        else if (prev <= 5)  dividend = 3;
                                        else                 dividend = 4;

                                        if (curr == 0)        divider = 1;
                                        else if (curr <= 3)   divider = 2;
                                        else if (curr <= 5)   divider = 3;
                                        else                 divider = 4;

                                        func_binning = (int)divider; //# save binning multi value 231013

                                        offsetx = (u32)(func_offsetx    * (dividend/divider));
//                                        offsety = (u32)(func_offsety    * (dividend/divider));
                                        width   = (u32)(func_width      * (dividend/divider));
                                        height  = (u32)(func_height     * (dividend/divider));

                                        offsetx = (u32)(floor(offsetx   / (float)INTERVALX) * INTERVALX);
//                                        offsety = (u32)(floor(offsety   / (float)INTERVALY) * INTERVALY);
                                        width   = (u32)(floor(width     / (float)INTERVALX) * INTERVALX);
                                        height  = (u32)(floor(height    / (float)INTERVALY) * INTERVALY);

                                        //$ 260223
                                        if(ROIC_DUAL == 2){
                                        	offsety = ((MAX_HEIGHT / divider) - height) / 2;
                                        	offsety = (u32)(floor(offsety / (float)INTERVALY) * INTERVALY);
                                        }
                                        else{
                                        	offsety = (u32)(func_offsety    * (dividend/divider));
                                        	offsety = (u32)(floor(offsety   / (float)INTERVALY) * INTERVALY);
                                        }

                                        if(offsetx + width > MAX_WIDTH || offsetx + width < MIN_WIDTH)            // dskim - 21.02.15 - MIN_WIDTH
                                            *status = GEV_STATUS_INVALID_PARAMETER;
                                        else if(offsety + height > MAX_HEIGHT || offsety + height < MIN_HEIGHT)    // dskim - 21.02.15 - MIN_HEIGHT
                                            *status = GEV_STATUS_INVALID_PARAMETER;
                                        else {
                                            execute_cmd_grab(0);
                                            execute_cmd_bmode(value);
                                            execute_cmd_roi(offsetx, offsety, width, height);
//                                            execute_cmd_fmax();
//                                            execute_cmd_emax();
//                                            execute_cmd_frate_call();
//                                            execute_cmd_frate((u32)(func_frate*1000));
//                                            execute_cmd_gewt_calc();

                                            execute_cmd_fmax();
                                            execute_cmd_frate(0);
                                            execute_cmd_emax();

                                            execute_cmd_grab(grab);
                                        }
                                     }
                                     break;
        case XML_DOT_NUMBER        : break;
        case XML_IMAGE_PROC        : if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_PROC (%d) $$$\r\n",value);
                                    execute_cmd_iproc(value);                break;
        case XML_ACCESS_AUTH       : break;
        case XML_PASSWORD          : if (DEBUGXML_W)func_printf("$$$ set XML_PASSWORD (%d) $$$\r\n",value);
                                    execute_cmd_auth(value);                 break;
        case XML_USERSET_CMD       : if (DEBUGXML_W)func_printf("$$$ set XML_USERSET_CMD (%d) $$$\r\n",value);
                                     if(REG(ADDR_OUT_EN))
                                        *status = GEV_STATUS_ACCESS_DENIED;
                                     else
                                        func_userset_cmd = value;
                                     break;
        case XML_ADDRESS_TABLE     : if (DEBUGXML_W)func_printf("$$$ set XML_ADDRESS_TABLE (%d) $$$\r\n",value);
                                     if(func_access_level == 0)    *status = GEV_STATUS_ACCESS_DENIED;
                                     else                        func_addr_table = value;
                                     break;
        case XML_ADDRESS0          :    if (DEBUGXML_W)func_printf("$$$ set XML_ADDRESS0 (%d) $$$\r\n",value);
                                    if(func_access_level == 0)    *status = GEV_STATUS_ACCESS_DENIED;
                                    else                         get_str_data(value, &func_reg_addr[0]);
                                    break;
        case XML_ADDRESS1          : if (DEBUGXML_W)func_printf("$$$ set XML_ADDRESS1 (%d) $$$\r\n",value);
                                     get_str_data(value, &func_reg_addr[4]); break;
        case XML_ADDRESS2          : if (DEBUGXML_W)func_printf("$$$ set XML_ADDRESS2 (%d) $$$\r\n",value);
                                     get_str_data(value, &func_reg_addr[8]); get_register();    break;
        case XML_DATA0             : if (DEBUGXML_W)func_printf("$$$ set XML_DATA0 (%d) $$$\r\n",value);
                                     if(func_access_level == 0)    *status = GEV_STATUS_ACCESS_DENIED;
                                     else if(REG(ADDR_OUT_EN) && func_addr_table == 5)  *status = GEV_STATUS_ACCESS_DENIED;
                                     else get_str_data(value, &func_reg_data[0]);
                                     break;
        case XML_DATA1             : if (DEBUGXML_W)func_printf("$$$ set XML_DATA1 (%d) $$$\r\n",value);
                                    get_str_data(value, &func_reg_data[4]);  break;
        case XML_DATA2             : if (DEBUGXML_W)func_printf("$$$ set XML_DATA2 (%d) $$$\r\n",value);
                                    get_str_data(value, &func_reg_data[8]);  set_register();    break;
//      case XML_ERASE_CMD         : if(func_access_level == 0)    *status = GEV_STATUS_ACCESS_DENIED;
//                                   else                         func_flash_cmd = value;
//                                   break;
        case XML_ERASE_CMD         : if (DEBUGXML_W)func_printf("$$$ set XML_ERASE_CMD (%d) $$$\r\n",value);
                                     func_flash_cmd = value;            // dskim - v0.xx.02 - 20.10.08
                                     break;
        case XML_CALIB_MAP         : if (DEBUGXML_W)func_printf("$$$ set XML_CALIB_MAP (%d) $$$\r\n",value);
                                     func_calib_map = value; break;
//      case XML_CALIB_CMD         : func_calib_cmd = value; break;
        case XML_CALIB_CMD         :
                                    if (DEBUGXML_W)func_printf("$$$ set XML_CALIB_CMD (%d) $$$\r\n",value);
                                    switch(value) {
                                    case 5:  // execute_cmd_wdot(0)
                                    case 6:  // execute_cmd_wdot(1)
                                    case 8:  // execute_cmd_wcdot(0)
                                    case 9:  // execute_cmd_wcdot(1)
                                    case 10: // execute_cmd_wrdot(0)
                                    case 11: // execute_cmd_wrdot(1)
                                        if(REG(ADDR_OUT_EN)) {
                                            *status = GEV_STATUS_ACCESS_DENIED;
                                        } else {
                                            if(func_binning_mode == 0)
                                                func_calib_cmd = value;
                                            else
                                                *status = GEV_STATUS_ERROR;
                                        }
                                        break;
                                        // dskim - 21.03.31 - Unicomp. Clear Reference -> Save to memory 동작 예외 처리.
                                    case 12:
                                        if(func_check_gain_calib == 0) {
                                            *status = GEV_STATUS_ACCESS_DENIED;
                                        } else {
                                            func_calib_cmd = value;
                                        }
                                        break;
                                    default:
                                        func_calib_cmd = value;
                                        break;
                                    }
                                    break;
        case XML_MANUAL_DOT_X    :    if (DEBUGXML_W)func_printf("$$$ set XML_MANUAL_DOT_X (%d) $$$\r\n",value);
                                    func_pointx = value;            break;
        case XML_MANUAL_DOT_Y    :    if (DEBUGXML_W)func_printf("$$$ set XML_MANUAL_DOT_Y (%d) $$$\r\n",value);
                                    func_pointy = value;            break;
        case XML_UPDATE_STATE    :    if (DEBUGXML_W)func_printf("$$$ set XML_UPDATE_STATE (%d) $$$\r\n",value);
                                    // dskim - 21.07.22
                                    switch(value) {
                                    // Type은 무조건 0으로 보내줘야 함
                                    case 0x1:
                                        func_stop_save_flash = 1;
                                        break;
                                    // dskim - 21.09.24 - Edge Cut 관련 업데이트
                                    case 0x2:
                                        execute_cmd_read_edge_cut();
                                        break;
                                    case 0x3:
                                        execute_cmd_edge_cut_save(0);
                                        execute_cmd_edge_cut_save(1);
                                        break;
                                    default:
                                        execute_cmd_parser(value);
                                    // dskim - 21.09.24 - Edge Cut 관련 업데이트
                                        break;
                                    }
                                    value = 0;
                                    break;
        case XML_SHUTTER_MODE    :   if (DEBUGXML_W)func_printf("$$$ set XML_SHUTTER_MODE (%d) $$$\r\n",value); 
        {
                                    execute_cmd_smode(value);
                                    if (value==0) // if rolling shutter mode set freerun. 220121mbh
                                        execute_cmd_tmode(0);
//                                    execute_cmd_fmax();
//                                    execute_cmd_emax();
//                                    execute_cmd_frate_call();
//                                    execute_cmd_frate((u32)(func_frate*1000));
//                                    execute_cmd_gewt_calc();

                                    execute_cmd_fmax();
                                    execute_cmd_frate(0);
                                    execute_cmd_emax();
        }
                                   break;
        case XML_TEMP_BD0        : break;
        case XML_TEMP_BD1        : break;
        case XML_TEMP_FPGA       : break;
        case XML_TEMP_PHY        : break;
        case XML_IFS             : if (DEBUGXML_W)func_printf("$$$ set XML_IFS (%d) $$$\r\n",value);
//                                    if(REG(ADDR_OUT_EN))    // dskim //# comment 221109
//                                        *status = GEV_STATUS_ACCESS_DENIED;
//                                    else
                                        execute_cmd_ifs(value);
                                   break;
        case XML_IFS_MIN         : break;
        case XML_IFS_MAX         : break;
        case XML_AVG_LEVEL       : if (DEBUGXML_W)func_printf("$$$ set XML_AVG_LEVEL (%d) $$$\r\n",value);
                                   user_avg_level = value;     break;
        case XML_REBOOT          : if (DEBUGXML_W)func_printf("$$$ set XML_REBOOT (%d) $$$\r\n",value);
                                    execute_cmd_reboot();         break;
        case XML_BUSY            : break;
        case XML_BUSY_TIME       : break;
        case XML_DEFECT_MAP      : if (DEBUGXML_W)func_printf("$$$ set XML_DEFECT_MAP (%d) $$$\r\n",value);
                                   execute_cmd_dmap(value);    break;
        case XML_HW_DEBUG        : if (DEBUGXML_W)func_printf("$$$ set XML_HW_DEBUG (%d) $$$\r\n",value);
                                   execute_cmd_hwdbg(value);    break;
        case XML_UART_CMD0       :
                                   if(func_access_level == 0)    *status = GEV_STATUS_ACCESS_DENIED;
                                   else                         get_str_data(value, &user_cmd[0]);
                                   break;
        case XML_UART_CMD1       : get_str_data(value, &user_cmd[4]);  break;
        case XML_UART_CMD2       : get_str_data(value, &user_cmd[8]);  break;
        case XML_UART_CMD3       : get_str_data(value, &user_cmd[12]); break;
        case XML_UART_CMD4       : get_str_data(value, &user_cmd[16]); break;
        case XML_UART_CMD5       : get_str_data(value, &user_cmd[20]); break;
        case XML_UART_CMD6       : get_str_data(value, &user_cmd[24]); break;
        case XML_UART_CMD7       : get_str_data(value, &user_cmd[28]);
                                   command_execute((char*)user_cmd);   break;
        case XML_BRIGHT          : if (DEBUGXML_W)func_printf("$$$ set XML_BRIGHT (%d) $$$\r\n",value);
                                   execute_cmd_bright(value);          break;
        case XML_CONTRAST        : if (DEBUGXML_W)func_printf("$$$ set XML_CONTRAST (%d) $$$\r\n",value);
                                   execute_cmd_contra(value);          break;
        case XML_EXP_MODE        : if (DEBUGXML_W)func_printf("$$$ set XML_EXP_MODE (%d) $$$\r\n",value);
                                   execute_cmd_emode(value);           break;
        case XML_FRAME_NUM       : if (DEBUGXML_W)func_printf("$$$ set XML_FRAME_NUM (%d) $$$\r\n",value);
                                   if (REG(ADDR_OUT_EN))
                                      *status = GEV_STATUS_ACCESS_DENIED;
                                   else
                                      execute_cmd_gmode(value, 0);
                                   break;
        case XML_READ_DEFECT_SEL : if (DEBUGXML_W)func_printf("$$$ set XML_READ_DEFECT_SEL (%d) $$$\r\n",value);
                                       func_read_defect = value;    break;
        case XML_READ_DEFECT     : if (DEBUGXML_W)func_printf("$$$ set XML_READ_DEFECT (%d) $$$\r\n",value);
                                   if(func_access_level == 0 || REG(ADDR_OUT_EN)) *status = GEV_STATUS_ACCESS_DENIED;
                                   else                                            execute_cmd_read_defect(value);
                                   break;
        case XML_EXT_TRIG_VALID  : if (DEBUGXML_W)func_printf("$$$ set XML_EXT_TRIG_VALID (%d) $$$\r\n",value);
                                   if(REG(ADDR_OUT_EN))    *status = GEV_STATUS_ACCESS_DENIED;
                                   else                    execute_cmd_trig_valid(value);
                                   break;
        case XML_EXT_OUT_ACTIVE  : if (DEBUGXML_W)func_printf("$$$ set XML_EXT_OUT_ACTIVE (%d) $$$\r\n",value);
                                   if(REG(ADDR_OUT_EN))    *status = GEV_STATUS_ACCESS_DENIED;
                                   else                    execute_cmd_trig_active(value, 1);    // 1 == out
                                   break;
        case XML_EXT_IN_ACTIVE   : if (DEBUGXML_W)func_printf("$$$ set XML_EXT_IN_ACTIVE (%d) $$$\r\n",value);
                                   if(REG(ADDR_OUT_EN))    *status = GEV_STATUS_ACCESS_DENIED;
                                   else                    execute_cmd_trig_active(value, 0);    // 0 == in
                                   break;
        case XML_EXT_TRIG_DELAY  : if (DEBUGXML_W)func_printf("$$$ set XML_EXT_TRIG_DELAY (%d) $$$\r\n",value);
                                   if(REG(ADDR_OUT_EN))     *status = GEV_STATUS_ACCESS_DENIED;
                                   else                    execute_cmd_tdly(value);
                                   break;
        case XML_CHECK_CALIB     : break;    // 0.xx.09
        // dskim - 21.10.20
        case XML_EDGE_CUT_LEFT   : break;
        case XML_EDGE_CUT_RIGHT  : break;
        case XML_EDGE_CUT_BOTTOM : break;
        case XML_EDGE_CUT_TOP    : break;
        case XML_EDGE_CUT_VALUE  : break;
        case XML_EDGE_CUT_READ   : break;
        case XML_EDGE_CUT_SAVE   : break;
        case XML_IMAGE_ACC       :
                                   if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_ACC (%d) $$$\r\n",value);
                                   func_image_acc = value;
                                   execute_cmd_acc(func_image_acc, func_image_acc_value);
                                   break;
        case XML_IMAGE_ACC_VALUE :
                                   if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_ACC_VALUE (%d) $$$\r\n",value);
                                   func_image_acc_value = value;
                                   execute_cmd_acc(func_image_acc, func_image_acc_value);
                                     break;
        case XML_IMAGE_EDGE        : break;
        case XML_IMAGE_EDGE_VALUE  : break;
        case XML_IMAGE_EDGE_OFFSET : break;
        case XML_IMAGE_DNR         :
            if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_DNR (%d) $$$\r\n",value);
            func_image_dnr = value;
            execute_cmd_dnr_setting(func_image_dnr, func_image_dnr_value, func_image_dnr_offset);
            break;
        case XML_IMAGE_DNR_VALUE   :
            if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_DNR_VALUE (%d) $$$\r\n",value);
            func_image_dnr_value = value;
            execute_cmd_dnr_setting(func_image_dnr, func_image_dnr_value, func_image_dnr_offset);
            break;
        case XML_IMAGE_DNR_OFFSET  :
            if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_DNR_OFFSET (%d) $$$\r\n",value);
            func_image_dnr_offset = value;
            execute_cmd_dnr_setting(func_image_dnr, func_image_dnr_value, func_image_dnr_offset);
            break;
        case XML_EXT_AUTO_OFFSET   : if (DEBUGXML_W)func_printf("$$$ set XML_EXT_AUTO_OFFSET (%d) $$$\r\n",value);
                                     func_trig_auto_offset = value;
//                                   func_printf("input ext auto offset = %d \r\n", func_trig_auto_offset);
                                     execute_cmd_eao(func_trig_auto_offset);
                                     break;
        case XML_API_EXT_TRIG      : if (DEBUGXML_W)func_printf("$$$ set XML_API_EXT_TRIG (%d) $$$\r\n",value);
                                     if (func_apitrig_defence == 0) // for debug
                                     {
                                        if (value==0 || value==1)
                                            execute_api_ext_trig(value);
                                        else
                                        {// it calls update_fwtrig(); in main while
                                            func_api_ext_trig_flag = 1;
                                            func_api_ext_trig = value;
                                        }
                                     }
                                     break;
        case XML_SW_DEBUG          : if (DEBUGXML_W)func_printf("$$$ set XML_SW_DEBUG (%d) $$$\r\n",value);
                                     execute_cmd_swdbg(value);         break;
        case XML_EXPOSURE_TYPE     : if (DEBUGXML_W)func_printf("$$$ set XML_EXPOSURE_TYPE (%d) $$$\r\n",value);
                                     execute_cmd_exposure_type(value); break;
        case XML_STATIC_AVG_ENABLE : if (DEBUGXML_W)func_printf("$$$ set XML_STATIC_AVG_ENABLE (%d) $$$\r\n",value);
                                     func_static_avg_enable = value;   break;
        case XML_RESET_DEVICE      : if (DEBUGXML_W)func_printf("$$$ set XML_RESET_DEVICE (%d) $$$\r\n",value);
                                     execute_cmd_reset_device();       break;

        case XML_SLEEP_MODE        : if (DEBUGXML_W)func_printf("$$$ set XML_SLEEP_MODE (%d) $$$\r\n" ,value);
                                     func_sleep_mode_enable = value;
                                     if(func_sleep_mode_enable == 1) {
                                         func_sleepmode = 3;
                                     } else {
                                         func_sleepmode = 0;
                                     }
                                     break;
        case XML_SLEEP_MODE_TIME   : if (DEBUGXML_W)func_printf("$$$ set XML_SLEEP_MODE_TIME (%d) $$$\r\n" ,value);
                                     func_sleep_mode_time = value;        // 분단위
                                     if(func_sleep_mode_time >= 60) {
                                         func_sleep_mode_time = 60;
                                     }
//                                   func_sleep_mode_time_m = value * 60;
                                     // Sleep 모드 상태가 아닐 경우에만 반영하도록
                                     if(func_sleep == 0) {
                                         func_sleep_mode_time_m = value * 60;
                                     }
                                     if(func_sleep_mode_time == 0) {
                                         func_sleep_mode_enable = 0;
                                     }
                                     break;
        case XML_IMAGE_ACC_AUTO_RESET : if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_ACC_AUTO_RESET (%d) $$$\r\n"    ,value);
                                        func_image_acc_auto_reset = value;
                                        execute_cmd_acc(func_image_acc, func_image_acc_value); //acc_auto_rst check could run 220502mbh
                                        break;
        case XML_TEMP_BD2             : break;
        case XML_TEMP_BD3             : break;

        case XML_SW_CALIB_MODE        : if (DEBUGXML_W)func_printf("$$$ set XML_SW_CALIB_MODE (%d) $$$\r\n",value);
                                        execute_cmd_write_oper_mode(value);
                                        break;
        case XML_LOAD_HW_CALIB        : if (DEBUGXML_W)func_printf("$$$ set XML_LOAD_HW_CALIB (%d) $$$\r\n",value);
//                                      execute_cmd_load_hw_calibration(value);
                                        func_hwload_flag = value;
                                        break;
        case XML_FPGA_REBOOT          : if (DEBUGXML_W)func_printf("$$$ set XML_FPGA_REBOOT (%d) $$$\r\n",value);
                                        execute_cmd_fpgareboot();
                                        break;
        case XML_FACTORY_MAP_MODE     : // factory map
                                        if (DEBUGXML_W)func_printf("$$$ set XML_FACTORY_MAP_MODE (%d) $$$\r\n",value);
                                        is_factory_map_mode = value;
                                        break;
        case XML_GAINREF_NUMLIM       : break; //# 230327

        case XML_IMAGE_TOPVALUE       : // factory map
                                        if (DEBUGXML_W)func_printf("$$$ set XML_IMAGE_TOPVALUE (%d) $$$\r\n",value);
                                        execute_topvalue_set(value);
                                        break;
        case XML_FPGA_BNC             : if (DEBUGXML_W)func_printf("$$$ set XML_FPGA_BNC (%d) $$$\r\n",value);
                                        execute_cmd_bnc(value);
                                        break;
        case XML_FPGA_EQ              : if (DEBUGXML_W)func_printf("$$$ set XML_FPGA_EQ (%d) $$$\r\n",value);
                                        execute_cmd_eq(value);
                                        break;
        //$ 250627
        case XML_READ_DEFECT_STT	  : if (DEBUGXML_W)func_printf("$$$ set XML_READ_DEFECT_STT (%d) $$$\r\n",value);
        								func_read_defect_stt = value;
        								break;
        case XML_READ_DEFECT_NUM	  : if (DEBUGXML_W)func_printf("$$$ set XML_READ_DEFECT_NUM (%d) $$$\r\n",value);
        								func_read_defect_num = value;
        								break;
        // Packet size margins
        case 0x10000000:
        case 0x10000004:
        case 0x10000008:    if (DEBUGXML_W)func_printf("$$$ set 0x10000008 (%d) $$$\r\n",value);
                            *status = GEV_STATUS_WRITE_PROTECT;
                            break;
        // Authentication and evaluation status
        case 0x1000000C:
        case 0x10000010:    if (DEBUGXML_W)func_printf("$$$ set 0x10000010 (%d) $$$\r\n",value);
                            *status = GEV_STATUS_WRITE_PROTECT;
                            break;

        // Special memory areas
        default:            //if (DEBUGXML)func_printf("$$$ set default (%d) $$$\r\n",value);
                            // Configuration EEPROM
                            if ((address >= 0xFBFF0000) && (address < 0xFBFF2000)) {
                                eeprom_write_dword((u16)(address - 0xFBFF0000), value);
                                break;
                            }
                            // SPI flash memory
                            if (address >= 0xFE000000) {
                                if (address < 0xFE010000) {
                                    flash_buffer[(address - 0xFE000000) / 4] = value;
                                }
                                else {
                                    if (address == 0xFE010000)
                                        flash_write_block(value, (u32*)flash_buffer, 65536);
                                    else                                        // Read-only space
                                        *status = GEV_STATUS_WRITE_PROTECT;
                                }
                                break;
                            }
                            // Undefined address space
                            *status = GEV_STATUS_INVALID_ADDRESS;
                            break;
    }
    	/*
        // User registers
        case 0x0000A000:        video_gcsr = value;
                                gige_set_acquisition_status(0, value & 1);
                                break;
        case 0x0000A004:        if ((value > 0) && (value <= video_max_width))
                                {
                                    video_width   = value;
                                    update_leader = 1;
                                    if (video_chunk_ctrl & 0x80000000)
                                        update_trailer = 1;
                                }
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A008:        if ((value > 0) && (value <= video_max_height))
                                {
                                    video_height   = value;
                                    update_leader  = 1;
                                    update_trailer = 1;
                                }
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A00C:        if (value <= video_max_offset)
                                {
                                    video_offs_x  = value;
                                    update_leader = 1;
                                }
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A010:        if (value <= video_max_offset)
                                {
                                    video_offs_y  = value;
                                    update_leader = 1;
                                }
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A014:        *status = GEV_STATUS_WRITE_PROTECT;
                                break;
        case 0x0000A018:        video_pixfmt    = value;
                                user_set_pixperclock(value);
                                update_leader   = 1;
                                update_trailer  = 1;
                                break;
        case 0x0000A01C:
        case 0x0000A020:        *status = GEV_STATUS_WRITE_PROTECT;
                                break;
      //case 0x0000A024:        *status = GEV_STATUS_WRITE_PROTECT; // Replaced by SCMBSx bootstrap register
      //                        break;
        case 0x0000A028:        video_acq_mode = value;
                                break;
        case 0x0000A02C:        if (value <= video_max_gap)
                                    video_gap_x = value;
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A030:        if (value <= video_max_gap)
                                    video_gap_y = value;
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A034:        temp = value;
                                f = (float*)&temp;
                                framedelay = 1; // video_gap_y has to be greater than 0 due to chunk data generation in TPG
                                do
                                {
                                    framerate = *f;
                                    usleep(1);    // Needed to get correct framerate value
                                    if ((user_pixperclock*VIDEO_CLK)/(framerate*(video_height + framedelay)) < video_width)
                                        rowdelay = 0;
                                    else
                                        rowdelay = (u32)(((user_pixperclock*VIDEO_CLK)/(framerate*(video_height + framedelay))) - video_width);
                                    framedelay = framedelay + 10;
                                    if (framedelay > video_max_gap) break;
                                }
                                while (rowdelay > video_max_gap);

                                if (framedelay > video_max_gap)
                                    video_gap_y = video_max_gap;
                                else
                                    video_gap_y = framedelay - 10;
                                if (rowdelay > video_max_gap)
                                    video_gap_x = video_max_gap;
                                else
                                    video_gap_x = rowdelay;
                                break;
        case 0x0000A100:        temp = value >> 31;
                                if (temp <= 1)
                                {
                                    if (temp == 0)
                                        video_chunk_ctrl = video_chunk_ctrl & ~0x80000000;
                                    else
                                        video_chunk_ctrl = video_chunk_ctrl | 0x80000000;
                                    update_trailer = 1;
                                    update_leader  = 1;
                                } else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        case 0x0000A104:        if (value <= 1)
                                {
                                    video_chunk_enable = value;
                                    update_trailer = 1;
                                    update_leader = 1;
                                }
                                else
                                    *status = GEV_STATUS_INVALID_PARAMETER;
                                break;
        // TestEventTimestamp
        case 0x0000A108:        gige_send_message(0x9001, 0, 0, NULL, (u64*)&event_test_timestamp);
                                break;
        case 0x0000A10C:
        case 0x0000A110:        *status = GEV_STATUS_WRITE_PROTECT;
                                break;
        // Packet size margins
        case 0x10000000:
        case 0x10000004:
        case 0x10000008:        *status = GEV_STATUS_WRITE_PROTECT;
                                break;
        // Authentication and evaluation status
        case 0x1000000C:
        case 0x10000010:        *status = GEV_STATUS_WRITE_PROTECT;
                                break;
        // Stream channel extended bootstrap registers (GEV 2.2)
//        case MAP_SCEBA + 0x00:
//                                break;
        // Special memory areas
        default:                // Configuration EEPROM
                                if ((address >= MAP_EEPROM) && (address < (MAP_EEPROM + MAP_EEPROM_LEN)))
                                {
                                    eeprom_write_dword((u16)(address - MAP_EEPROM), value);
                                    break;
                                }
                                // SPI flash memory
                                if (address >= MAP_FLASH)
                                {
                                    if (address < (MAP_FLASH + SECTOR_SIZE_S2I))            // SECTOR_SIZE_S2I kB write buffer
                                    {
                                        flash_buffer[(address - MAP_FLASH) / 4] = value;
                                    }
                                    else
                                    {
                                        if (address == (MAP_FLASH + SECTOR_SIZE_S2I))       // Write address
                                            flash_write_block(value, (u32 *)flash_buffer, SECTOR_SIZE_S2I);
                                        else                                                // Read-only space
                                            *status = GEV_STATUS_WRITE_PROTECT;
                                    }
                                    break;
                                }
                                // Undefined address space
                                *status = GEV_STATUS_INVALID_ADDRESS;
                                break;
    }
*/

    //# 231221 no need, payload packet error reseted
    /*
    if ((video_chunk_ctrl & 0x80000000) == 0)       // Check if extended chunk mode is activated
    {
        chunk_size      = 0;
        chunk_layout_id = 0;
    }
    else
    {
        if (video_chunk_enable == 0)                // Check if framecounter chunk is activated
        {
            chunk_size      = 8;                    // Additional bytes to describe image chunk only (4 byte id, 4 byte size)
            chunk_layout_id = video_chunkid_img |
                              video_pixfmt      |
                              video_width       |
                              video_height;         // Set chunk layout id
        }
        else
        {
            chunk_size      = 20;                   // Additional bytes to describe image chunk (8 bytes) and frame counter chunk (4 bytes data, 4 bytes id, 4 bytes size)
            chunk_layout_id = video_chunkid_img |
                              video_chunkid_fc  |
                              video_pixfmt      |
                              video_width       |
                              video_height;         // Set chunk layout id
        }

        // Verify that chunk_layout_id gets changed when chunk layout changes
        if (update_trailer == 1)
        {
            if (chunk_layout_id == old_chunk_layout_id)
                chunk_layout_id++;
            old_chunk_layout_id = chunk_layout_id;
        }
    }

    // Adjust padding and total bytes per block


    if (DEBUGXML_W)func_printf("[DEBUGXML_W] framebuf_padding (%d)(%d) $$$\r\n",video_width,video_height );
    framebuf_padding(video_pixfmt, video_width, video_height, chunk_size);
    gige_set_scmbs(0, framebuf_bpb);

    // Set Payload Type
    if ((video_chunk_ctrl & 0x80000000) == 0)
        framebuf_set_pld_type(PLD_IMAGE);
    else
        framebuf_set_pld_type(PLD_IMAGE | PLD_EXTCHUNK_MODE);

    // Update leader/trailer
    if (update_leader)
        framebuf_img_leader(video_pixfmt, video_width, video_height, video_offs_x, video_offs_y);
    if (update_trailer)
        framebuf_img_trailer(video_height, chunk_layout_id);
	*/
    return;
}


// ---- Process the action signals ---------------------------------------------
//
//   This function must be always implemented!
//   It is called by the gige_callback() from libgige
//   The function is not allowed to block execution!
//
//   sig  = array of four 32b bit fields identifying particular triggered signals
//   type = source of the trigger (see TRIGGER_* macros in gige.h)
//
void action_trigger(u32 *sig, u32 type)
{
    int i;

    switch (type)
    {
        case TRIGGER_IMMEDIATE:
            printf("ACTION_CMD: immediate action triggered\r\n");
            break;
        case TRIGGER_SCHEDULED:
            printf("ACTION_CMD: scheduled action triggered\r\n");
            break;
        case TRIGGER_PAST:
            printf("ACTION_CMD: action scheduled in the past\r\n");
            break;
        default:
            printf("ACTION_CMD: unknown action trigger\r\n");
            break;
    }

    for (i = 0; i < 128; i++)
        if (sig[i / 32] & (0x80000000 >> (i % 32)))
            printf("ACTION_CMD: triggered signal %d\r\n", i);

    return;
}


// ---- Initialize custom part of the device -----------------------------------
//
//   This function should initialize the rest of the device which is not under
//   control of the GigE library
//
#define DBG_user_init 0
void user_init(void)
{
    // Chunk parameters
    u32 chunk_size;
    u32 chunk_layout_id = 0;    // Chunk layout id

    // Set the default video parameters
    video_width         = func_width; //# 1024;
    video_height        = func_height; //# 1024;
    video_offs_x        = func_offsetx; //# 0;
    video_offs_y        = func_offsety; //# 0;
//    video_pixfmt        = GVSP_PIX_MONO8;
    video_pixfmt        = GVSP_PIX_MONO16;
    video_max_width     = func_width; //# 4096;
    video_max_height    = func_height; //# 4096;
    video_acq_mode      = ACQ_MODE_CONTINUOUS;
    video_gap_x         = 2000;
    video_gap_y         = 2000;
    video_max_offset    = 4000;
    video_max_gap       = 4000;

    user_set_pixperclock(video_pixfmt);

    if ((video_chunk_ctrl & 0x80000000) == 0)       // Check if extended chunk mode is activated
    {
        chunk_size      = 0;
        chunk_layout_id = 0;
        if(DBG_user_init)func_printf("#[DBG_user_init] DBG_fcmd video_chunk_ctrl=%d \r\n",video_chunk_ctrl & 0x80000000);
    }
    else
    {
        if (video_chunk_enable == 0)                // Check if framecounter chunk is activated
        {
            chunk_size      = 8;                    // Additional bytes to describe image chunk only (4 byte id, 4 byte size)
            chunk_layout_id = video_chunkid_img |
                              video_pixfmt      |
                              video_width       |
                              video_height;         // Set chunk layout id
        }
        else
        {
            chunk_size      = 20;                   // Additional bytes to describe image chunk (8 bytes) and frame counter chunk (4 bytes data, 4 bytes id, 4 bytes size)
            chunk_layout_id = video_chunkid_img |
                              video_chunkid_fc  |
                              video_pixfmt      |
                              video_width       |
                              video_height;         // Set chunk layout id
        }
    }

    // Setup GVSP leader and trailer packets
//    framebuf_padding(video_pixfmt, video_width, video_height, chunk_size);
//    framebuf_img_leader(video_pixfmt, video_width, video_height, video_offs_x, video_offs_y);
//    framebuf_img_trailer(video_height, chunk_layout_id);
//    gige_set_scmbs(0, framebuf_bpb);

    // Setup GVSP leader and trailer packets //# V2
    framebuf_padding(func_pixfmt, func_width, func_height, chunk_size);
    framebuf_img_leader(func_pixfmt, func_width, func_height, func_offsetx, func_offsety);
//    framebuf_img_leader(func_pixfmt, func_width, func_height, 4, func_offsety);  //# 231201 critical test=blink
    framebuf_img_trailer(func_height, chunk_layout_id);
    gige_set_scmbs(0, framebuf_bpb);

    if(DBG_user_init)func_printf("#[DBG_user_init] func_pixfmt=0x%08x\r\n",func_pixfmt);
    if(DBG_user_init)func_printf("#[DBG_user_init] func_width=%d\r\n",func_width);
    if(DBG_user_init)func_printf("#[DBG_user_init] func_height=%d\r\n",func_height);
    if(DBG_user_init)func_printf("#[DBG_user_init] chunk_size=%d\r\n",chunk_size);
    if(DBG_user_init)func_printf("#[DBG_user_init] func_offsetx=%d\r\n",func_offsetx);
    if(DBG_user_init)func_printf("#[DBG_user_init] func_offsety=%d\r\n",func_offsety);
    if(DBG_user_init)func_printf("#[DBG_user_init] chunk_layout_id=0x%08x\r\n",chunk_layout_id);
    if(DBG_user_init)func_printf("#[DBG_user_init] framebuf_bpb=0x%08x\r\n",framebuf_bpb);

    // Reset GCSR to default state
    video_gcsr = 0x00000000;
    REG(ADDR_OUT_EN)    = 0x00000000;
    gige_set_acquisition_status(0, 0);

    // Set KC705 fan PWM (sys_gpo outputs of the GigE core)
//    gige_gcsr = (gige_gcsr & 0x3FFFFFFF) | (((u32)pwm) << 30);

    // Enter SPI flash 4B address mode
    //flash_enter4b();    // Not on KC705 platform

    return;
}


// ---- User callback function -------------------------------------------------
//
//   This function should be used as an entry point for application-specific
//   code except interaction with a GigE Vision application which is handled
//   using the get_user_reg(), set_user_reg(), and send_message() functions
//   defined in the user.c file
//
//   Example shows sending asynchronous messages to the GigE Vision application
//
void user_callback(void)
{
    static u32 old_gcsr = 0;
    static u32 prev = 0, curr = 0;
//    static u32 prev = -1, curr = -1; // init checking 220118

/*
    // Send messages after start and stop of image acquisition
    if ((video_gcsr & 0x00000001) != (old_gcsr & 0x00000001))
    {
        if (video_gcsr & 0x00000001)
            gige_send_message(GEV_EVENT_START_OF_TRANSFER, 0, 0, NULL, NULL);
        else
            gige_send_message(GEV_EVENT_END_OF_TRANSFER, 0, 0, NULL, NULL);
        old_gcsr = video_gcsr;
    }
*/
    // dskim - 21.02.15 - ���� �� Gain Calibration �߿��� Grab���� ���ϵ���
    if ((REG(ADDR_OUT_EN) & 0x00000001) != (old_gcsr & 0x00000001) && (func_check_booting != 1))
    {
        if (REG(ADDR_OUT_EN) & 0x00000001) {
            execute_cmd_op_acq_start();
            gige_send_message4(GEV_EVENT_START_OF_TRANSFER, 0, 0, NULL);
            execute_cmd_grab(1);
            switch (func_hw_debug) {
                case 1 :                             break;
                case 2 :
                            execute_cmd_wddr(0, 7);
                            execute_cmd_cddr(8);    break;
            }
        }
        else {
            execute_cmd_op_acq_stop();
            gige_send_message4(GEV_EVENT_END_OF_TRANSFER, 0, 0, NULL);
            switch (func_hw_debug) {
                case 1 :     func_calib_cmd = 1;
                    break;
                case 2 :       execute_cmd_cddr(0);    break;
            }
            execute_cmd_grab(0);
        }
        old_gcsr = REG(ADDR_OUT_EN);
    }

    curr = gige_gcsr & 0x03;
    func_ether_conn = (curr == 3)? 1:0;

    if(prev != curr) {
//        func_printf("user_callback func_ether_conn=%d curr=%d\r\n", func_ether_conn, curr);
        switch(curr) {
            case 0 :    func_printf("\r\nStatus = Physical Link Disconnected\r\n");
                        REG(ADDR_DDR_CH_EN)        = 0b00010001;
                        REG(ADDR_LED_CTRL) = LED_CTRL_ON; // fault LED 221018 mbh
                        break;
            case 1 :
                        // dskim - 22.07.26 - 프로그램이 종료될 때 안정적으로 종료될 수 있도록.
                        // 프로그램이 종료 될 때, 시스템이 다운되는 현상 디버깅 중...
                        if(REG(ADDR_OUT_EN) != 0) {
                            REG(ADDR_OUT_EN) = 0;
                            gige_set_acquisition_status(0, 0);
                            func_out_en = 0;
                        }
                        //
                        func_printf("\r\nStatus = No Device Discovery\r\n");
                        REG(ADDR_DDR_CH_EN)        = 0b00010001;
                        REG(ADDR_LED_CTRL) = LED_CTRL_OFF; // fault LED 221018 mbh
                        break;
            case 2 :    func_printf("\r\nStatus = Physical Link Disconnected\r\n");
                        REG(ADDR_DDR_CH_EN)        = 0b00010001;
                        REG(ADDR_LED_CTRL) = LED_CTRL_ON; // fault LED 221018 mbh
                        break;
            case 3 :    func_printf("\r\nStatus = Device Discovery Success\r\n");
                        REG(ADDR_DDR_CH_EN)    = 0b01010001;
                        if(func_gain_cal)              REG(ADDR_DDR_CH_EN)    = 0b01110001; // read ch 0,1,2 On 210302
                        if(func_d2m)                  REG(ADDR_DDR_CH_EN)    = 0b11010101; // d2m on write ch2 avg for ref minus 210729
                        if(func_gain_cal && func_d2m) REG(ADDR_DDR_CH_EN)    = 0b11110101; // d2m on write ch2 avg for ref minus 210729
                        REG(ADDR_LED_CTRL) = LED_CTRL_OFF; // fault LED 221018 mbh
//                        func_grabbcal = 1; //# bcal after ethernet connected. 220321mbh
                        break;
        }
    }
    prev = curr;

    return;
}


// ---- Generic libgige user callback ------------------------------------------
//
//          This function is called by the libgige library when some of the
//          predefined events occurs.
//
// id     = identifier of the event
// param  = 32b parameter of the event
// data   = various extended data can be passed to/from the function
//
// return value = event specific
//
u32 gige_event(u32 id, u32 param, __attribute__((unused)) void *data)
{
    u32 ret = 0;

    switch (id)
    {
        // No event
        case LIB_EVENT_NONE:
            break;

        // Write access into the GVCP configuration register
        //      param = value written by a GEV application
        //      data  = unused
        case LIB_EVENT_GVCP_CONFIG_WRITE:
            if ((param & 4) || (gige_get_gev_version() == 2))   // ES bit set or GEV 2.x with extended IDs
                framebuf_control |= FRAMEBUF_C_EXTSTAT;         // Enable extended GVSP status codes
            else
                framebuf_control &= ~FRAMEBUF_C_EXTSTAT;        // Disable extended GVSP status codes
            break;

        // Open or close stream channel
        //      param = bit mask of open channels (channel 0 = bit 0, etc.)
        //      data  = unused
        case LIB_EVENT_STREAM_OPEN_CLOSE:
            if (param == 0)                                     // No more open stream channels
            {
                framebuf_control |= FRAMEBUF_C_INIT;            // Clear framebuffer
                video_gcsr        = 0x00000000;                 // Reset video in module
                REG(ADDR_OUT_EN)        = 0x00000000;                 // Reset video in module
                gige_set_acquisition_status(0, 0);              // Acquisition off
            }
            break;

        // Write access into the stream channel configuration register
        //      param = value written by a GEV application
        //      data  = pointer to the stream channel index (u32)
        case LIB_EVENT_SCCFG_WRITE:
            break;

        // Application closed the control channel
        //      param = index of the (X)GigE core
        //      data  = unused
        case LIB_EVENT_APP_DISCONNECT:
            if (param == 0)                                     // No more open stream channels
            {
                video_gcsr        = 0x00000000;                 // Reset video in module
                gige_set_acquisition_status(0, 0);              // Acquisition off
            }
            break;

        // Physical link disconnected
        //      param = index of the (X)GigE core
        //      data  = unused
        case LIB_EVENT_LINK_DOWN:
            video_gcsr = 0x00000000;                            // Reset video in module
            REG(ADDR_OUT_EN) = 0x00000000;                            // Reset video in module
            gige_set_acquisition_status(0, 0);                  // Acquisition off
            break;

        // Write access to the physical link configuration register
        //      param = value written by a GEV application
        //      data  = unused
        case LIB_EVENT_LINK_CONFIG_WRITE:
            break;

        // A new trigger has been scheduled after reception of a valid scheduled action command.
        //      param = index of the action signal(0..127)
        //      data  =  pointer to a 64b unsigned integer with trigger time of the action
        case LIB_EVENT_SCHEDULED_ACTION:
            //{
            //    u64 *timestamp = (u64*)data;
            //    printf("Scheduled ACTION_CMD: signal %ld, timestamp %" PRIu64 "\r\n", param, *timestamp);
            //}
            break;

        // Undefined event
        default:
            break;
    }

    return ret;
}



// ---- Local function prototypes ----------------------------------------------


// ---- Set pixel per clock cycle ----------------------------------------------
//
//          user_pixperclock: Number of pixel generated by the
//          videotpg per clock cycle
//
// pixfmt = pixel format
//
static void user_set_pixperclock(u32 pixfmt)
{
    if(video_tpg_mode == 1)
    {
        switch(pixfmt)
        {
        case GVSP_PIX_MONO8:
            user_pixperclock = 8;
            break;
        case GVSP_PIX_MONO16:
            user_pixperclock = 4;
            break;
        case GVSP_PIX_RGB8_PACKED:
            user_pixperclock = 2;
            break;
        default:
            user_pixperclock = 1;
            break;
        }
    }
    else
    {
        user_pixperclock = 1;
    }
}
