/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  user.h                                                          */
/*    Date :  2022-10-11                                                      */
/*     Rev :  0.4                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design application-specific include file            */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2008-03-12  |  JP  |  Initial release                             */
/*  0.2  |  2017-10-16  |  JH  |  Extended chunk mode support added           */
/*  0.3  |  2021-09-23  |  SS  |  Use new videotpg                            */
/*  0.4  |  2022-10-11  |  SS  |  Added video_tpg_mode register               */
/******************************************************************************/

#ifndef _USER_H_
#define _USER_H_

// ---- Constants --------------------------------------------------------------
#define VIDEO_CLK       	1600000000      // 200MHz * 8 pixels/clock

#define XML_OUT_EN			0xA000
#define XML_WIDTH			0xA004
#define XML_HEIGHT			0xA008
#define XML_OFFSETX			0xA00C
#define XML_OFFSETY			0xA010
#define XML_LINEPITCH		0xA014
#define XML_PIXFMT			0xA018
#define XML_WIDTH_MAX		0xA01C
#define XML_HEIGHT_MAX		0xA020
#define XML_PLOAD_SIZE		0xA024
#define XML_ACQ_MODE		0xA028
#define XML_ROW_DELAY		0xA02C
#define XML_FRAME_DELAY		0xA030
#define XML_FRATE			0xA034
#define XML_TEST_PATTERN	0xA038
#define XML_GEWT			0xA03C
#define XML_TRIG_MODE		0xA040
#define XML_GAIN_CAL		0xA044
#define XML_DEFECT_CAL		0xA048
#define XML_TABLE			0xA04C
#define XML_DGAIN			0xA050
#define XML_USERSET_NAME0	0xA054
#define XML_USERSET_NAME1	0xA058
#define XML_USERSET_NAME2	0xA05C
#define XML_USERSET_NAME3	0xA060
#define XML_USERSET_NAME4	0xA064
#define XML_USERSET_NAME5	0xA068
#define XML_USERSET_NAME6	0xA06C
#define XML_USERSET_NAME7	0xA070
#define XML_FPGA_VER0		0xA074
#define XML_FPGA_VER1		0xA078
#define XML_FPGA_VER2		0xA07C
#define XML_FPGA_VER3		0xA080
#define XML_TFT_SER0		0xA084
#define XML_TFT_SER1		0xA088
#define XML_TFT_SER2		0xA08C
#define XML_TFT_SER3		0xA090
#define XML_PANEL_SER0		0xA094
#define XML_PANEL_SER1		0xA098
#define XML_PANEL_SER2		0xA09C
#define XML_PANEL_SER3		0xA0A0
#define XML_BWIDTH			0xA0A4
#define XML_GEV_SPEED		0xA0A8
#define XML_FRATE_MIN		0xA0AC
#define XML_FRATE_MAX		0xA0B0
#define XML_GEWT_MIN		0xA0B8
#define XML_GEWT_MAX		0xA0BC
#define XML_RSND_PACKET		0xA0C0
#define XML_WIDTH_MIN		0xA0C4
#define XML_HEIGHT_MIN		0xA0C8
#define XML_OFFSETX_MIN		0xA0CC
#define XML_OFFSETY_MIN		0xA0D0
#define XML_OFFSETX_MAX		0xA0D4
#define XML_OFFSETY_MAX		0xA0D8
#define XML_INTERVALX		0xA0DC
#define XML_INTERVALY		0xA0E0
#define XML_DGAIN_MIN		0xA0E4
#define XML_DGAIN_MAX		0xA0E8
#define XML_RUNNING_TIME0	0xA0EC
#define XML_RUNNING_TIME1	0xA0F0
#define XML_RUNNING_TIME2	0xA0F4
#define XML_RUNNING_TIME3	0xA0F8
#define XML_IMG_AVG_DOSE0	0xA0FC
#define XML_IMG_AVG_DOSE1	0xA100
#define XML_BINNING_MODE	0xA104
#define XML_DOT_NUMBER		0xA108
#define XML_IMAGE_PROC		0xA10C
#define XML_ACCESS_AUTH		0xA110
#define XML_PASSWORD		0xA114
#define XML_USERSET_CMD		0xA118
#define XML_ADDRESS_TABLE	0xA11C
#define XML_ADDRESS0		0xA120
#define XML_ADDRESS1		0xA124
#define XML_ADDRESS2		0xA128
#define XML_DATA0			0xA12C
#define XML_DATA1			0xA130
#define XML_DATA2			0xA134
#define XML_ERASE_CMD		0xA138
#define XML_CALIB_MAP		0xA13C
#define XML_CALIB_CMD		0xA140
#define XML_MANUAL_DOT_X	0xA144
#define XML_MANUAL_DOT_Y	0xA148
#define XML_UPDATE_STATE	0xA14C
#define XML_SHUTTER_MODE	0xA150
#define XML_TEMP_BD0		0xA154
#define XML_TEMP_BD1		0xA158
#define XML_TEMP_FPGA		0xA15C
#define XML_TEMP_PHY		0xA160
#define XML_IFS				0xA164
#define XML_IFS_MIN			0xA168
#define XML_IFS_MAX			0xA16C
#define XML_AVG_LEVEL		0xA170
#define XML_REBOOT			0xA174
#define XML_BUSY			0xA178
#define XML_BUSY_TIME		0xA17C
#define XML_OFFSET_CAL		0xA180
#define XML_DEFECT_MAP		0xA184
#define XML_IMG_AVG_DOSE2	0xA188
#define XML_IMG_AVG_DOSE3	0xA18C
#define XML_IMG_AVG_DOSE4	0xA190
#define XML_HW_DEBUG		0xA194
#define XML_UART_CMD0		0xA198
#define XML_UART_CMD1		0xA19C
#define XML_UART_CMD2		0xA1A0
#define XML_UART_CMD3		0xA1A4
#define XML_UART_CMD4		0xA1A8
#define XML_UART_CMD5		0xA1AC
#define XML_UART_CMD6		0xA1B0
#define XML_UART_CMD7		0xA1B4
#define XML_BRIGHT			0xA1B8
#define XML_CONTRAST		0xA1BC
#define XML_EXP_MODE		0xA1C0
#define XML_FRAME_NUM		0xA1C4
#define XML_READ_DEFECT_SEL	0xA1C8	// dskim - 0.00.08
#define XML_READ_DEFECT		0xA1CC	// dskim - 0.00.08
#define XML_EXT_TRIG_VALID	0xA1D0	// dskim - 0.00.08
#define XML_EXT_OUT_ACTIVE	0xA1D4	// dskim - 0.00.08
#define XML_EXT_IN_ACTIVE	0xA1D8	// dskim - 0.00.08
#define XML_EXT_TRIG_DELAY	0xA1DC	// dskim - 0.00.08
#define XML_EXT_DELAY_MIN	0xA1E0	// dskim - 0.00.08
#define XML_EXT_DELAY_MAX	0xA1E4	// dskim - 0.00.08
#define XML_CHECK_CALIB		0xA1E8	// dskim - 0.00.09


#define XML_EDGE_CUT_LEFT		0xA1EC	// dskim - 21.10.20
#define XML_EDGE_CUT_RIGHT		0xA1F0
#define XML_EDGE_CUT_BOTTOM		0xA1F4
#define XML_EDGE_CUT_TOP		0xA1F8
#define XML_EDGE_CUT_VALUE		0xA1FC
#define XML_EDGE_CUT_READ		0xA200
#define XML_EDGE_CUT_SAVE		0xA204

#define XML_IMAGE_ACC			0xA208	// dskim - 21.10.20
#define XML_IMAGE_ACC_VALUE		0xA20C
#define XML_IMAGE_EDGE			0xA210	// dskim - 21.10.20 - 실제사용하지 않음
#define XML_IMAGE_EDGE_VALUE	0xA214	// dskim - 21.10.20 - 실제사용하지 않음
#define XML_IMAGE_EDGE_OFFSET	0xA218	// dskim - 21.10.20 - 실제사용하지 않음
#define XML_IMAGE_DNR			0xA21C
#define XML_IMAGE_DNR_VALUE		0xA220
#define XML_IMAGE_DNR_OFFSET	0xA224
#define XML_EXT_AUTO_OFFSET		0xA228
#define XML_API_EXT_TRIG		0xA22C

#define XML_SW_DEBUG			0xA230
#define XML_EXPOSURE_TYPE		0xA234
#define XML_STATIC_AVG_ENABLE	0xA238

#define XML_RESET_DEVICE		0xA23C

#define XML_SLEEP_MODE			0xA240
#define XML_SLEEP_MODE_TIME		0xA244
#define XML_IMAGE_ACC_AUTO_RESET	0xA248

#define XML_GRAB_COUNT			0xA24C
#define XML_BOOT_COUNT			0xA250
#define XML_OPERATING_TIME_H	0xA254
#define XML_OPERATING_TIME_M	0xA258

#define XML_TEMP_BD2			0xA25C
#define XML_TEMP_BD3			0xA260

#define XML_SW_CALIB_MODE		0xA264
#define XML_LOAD_HW_CALIB		0xA268

//#define reserve		0xA26C

#define XML_HW_VER0		0xA270
#define XML_HW_VER1		0xA274
#define XML_HW_VER2		0xA278
#define XML_HW_VER3		0xA27C

#define XML_FPGA_REBOOT 0xA300

#define XML_FACTORY_MAP_MODE	0xA304
#define XML_GAINREF_NUMLIM		0xA308

#define XML_IMAGE_TOPVALUE		0xA310
#define XML_FPGA_BNC     		0xA314
#define XML_FPGA_EQ     		0xA318

//$ 250627
#define XML_READ_DEFECT_STT	   0xA320
#define XML_READ_DEFECT_NUM    0xA324

//### ABLE ###
#define	XML_ABLE_BINN_NUM       0xA380
#define	XML_ABLE_GAIN_NUM       0xA384
#define	XML_ABLE_DNR            0xA388
// ---- Macros and constants ---------------------------------------------------

// Special GEV memory areas address map
#define MAP_SCEBA           0x20000000
#define MAP_EEPROM          0xFBFF0000
#define MAP_EEPROM_LEN      0x00002000
#define MAP_FLASH           0xFE000000

// Video TPG clock frequency
//#define VIDEO_CLK           200000000      // 200MHz Video clock


// ---- Video processor interface ----------------------------------------------

// Video processor base address
#define VIDEO_REGS          XPAR_M2_AXI_VIDEO_BASEADDR

// Offsets of the registers
#define video_gcsr          (*(volatile u32 *)(VIDEO_REGS + 0x0000))
#define video_width         (*(volatile u32 *)(VIDEO_REGS + 0x0004))
#define video_height        (*(volatile u32 *)(VIDEO_REGS + 0x0008))
#define video_offs_x        (*(volatile u32 *)(VIDEO_REGS + 0x000C))
#define video_offs_y        (*(volatile u32 *)(VIDEO_REGS + 0x0010))
#define video_pixfmt        (*(volatile u32 *)(VIDEO_REGS + 0x0018))
#define video_gap_x         (*(volatile u32 *)(VIDEO_REGS + 0x001C))
#define video_gap_y         (*(volatile u32 *)(VIDEO_REGS + 0x0020))
#define video_gpio_in       (*(volatile u32 *)(VIDEO_REGS + 0x0024))
#define video_gpio_out      (*(volatile u32 *)(VIDEO_REGS + 0x0028))
#define video_chunk_ctrl    (*(volatile u32 *)(VIDEO_REGS + 0x002C))
#define video_chunkid_img   (*(volatile u32 *)(VIDEO_REGS + 0x0030))
#define video_chunkid_fc    (*(volatile u32 *)(VIDEO_REGS + 0x0034))
#define video_tpg_mode      (*(volatile u32 *)(VIDEO_REGS + 0x0038))


// ---- Global variables -------------------------------------------------------

// Video processor software-only registers
extern volatile u32 video_max_width;
extern volatile u32 video_max_height;
extern volatile u32 video_total_bpf;
extern volatile u32 video_acq_mode;
extern volatile u32 video_max_offgap;
extern volatile u32 video_chunk_enable;

extern u32 user_avg_level;
extern u8 user_cmd[32];

// ---- Function prototypes ----------------------------------------------------

u32  get_user_reg(u32 address, u16 *status);
void set_user_reg(u32 address, u32 value, u16 *status);
void user_init(void);
void user_callback(void);


#endif
