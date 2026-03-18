/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  flash.h                                                         */
/*    Date :  2014-07-30                                                      */
/*     Rev :  0.2                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design SPI flash memory include file                */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2008-04-03  |  JP  |  Initial release                             */
/*  0.2  |  2014-07-30  |  JP  |  Support for 4B address mode                 */
/******************************************************************************/

#ifndef _FLASH_H_
#define _FLASH_H_

#include "fpga_info.h"      // dskim - 0.xx.08
// Flash memory organization
// Consult SPI flash datasheet to check the correct values!
#define SECTOR_SIZE_S2I (64 * 1024) // Flash sector size set in GEV Updater

// ---- SPI flash memory control registers -------------------------------------

// SPI controller base addresses
#define GIGE_SPI_REGS   (XPAR_M1_AXI_GEV_BASEADDR + 0x0000F000)
#define GIGE_SPI_WBUF   (XPAR_M1_AXI_GEV_BASEADDR + 0x0000F800)
#define GIGE_SPI_RBUF   (XPAR_M1_AXI_GEV_BASEADDR + 0x0000FC00)

// SPI flash memory controller registers
#define gige_spi_gcsr   (*(volatile u32 *)(GIGE_SPI_REGS + 0x0000))
#define gige_spi_addr   (*(volatile u32 *)(GIGE_SPI_REGS + 0x0004))
#define gige_spi_sn_h   (*(volatile u32 *)(GIGE_SPI_REGS + 0x0008))
#define gige_spi_sn_l   (*(volatile u32 *)(GIGE_SPI_REGS + 0x000C))

// SPI flash memory buffers
#define gige_spi_wbuf   ((volatile u32 *)GIGE_SPI_WBUF)
#define gige_spi_rbuf   ((volatile u32 *)GIGE_SPI_RBUF)

#define FLASH_BIT_BASEADDR          0x0000000
#define FLASH_BIT2ND_BASEADDR       0xF000000 //# 2nd bit 220915mbh
#define FLASH_BIT3RD_BASEADDR       0xF700000 //# 3rd bit 220919mbh
//#define FLASH_BIT_LEN             0x0700000
//#define FLASH_BIT_LEN               0x0661EF2
#define FLASH_BIT_LEN               0x0661EDA //# v2 vvd22 231208mbh
#define FLASH_ALLOC_BASEADDR        0x0C00000
#define FLASH_ALLOC_BIT_SIZE        0x0000000
#define FLASH_ALLOC_BIT_CHECKSUM    0x0000004
#define FLASH_ALLOC_BIT2ND_SIZE     0x0000008
#define FLASH_ALLOC_BIT2ND_CHECKSUM 0x000000c
// parameters                       0x0000010
//                                  0x0000014
#define FLASH_ALLOC_XML_SIZE        0x0000018
#define FLASH_ALLOC_XML_CHECKSUM    0x000001C
// reserved                         0x0000020
//                                  0x0000024
#define FLASH_ALLOC_APP_SIZE        0x0000028
#define FLASH_ALLOC_APP_CHECKSUM    0x000002C
#define FLASH_ALLOC_BIT3RD_SIZE     0x0000030 //new
#define FLASH_ALLOC_BIT3RD_CHECKSUM 0x0000034 //new
#define FLASH_ALLOC_APP2ND_SIZE     0x0000038
#define FLASH_ALLOC_APP2ND_CHECKSUM 0x000003C
#define FLASH_ALLOC_CALIB_SIZE      0x0000048
#define FLASH_ALLOC_CALIB_CHECKSUM  0x000004C
#define FLASH_ALLOC_LEN             0x0020000

#define FLASH_XML_BASEADDR          0x0C20000
#define FLASH_XML_LEN               0x00E0000
#define FLASH_APP_BASEADDR          0x0D00000
#define FLASH_APP2ND_BASEADDR       0xFE00000
#define FLASH_APP_LEN               0x00F0000       // Max Application Size = 0xF0000
#define FLASH_AL2ND_BASEADDR        0xFEF0000
#define FLASH_AL1ST_CHECKSUM        0xFF10000
#define FLASH_AL2ND_CHECKSUM        0xFF10004

#define FLASH_INFO_BASEADDR         0x0DF0000
#define FLASH_INFO_LEN              0x0010000

#define FLASH_USER_BASEADDR         0x0E00000
#define FLASH_USER_LEN_EACH         0x0010000
#define FLASH_USER_LEN              (FLASH_USER_LEN_EACH * MAX_USERSET)     // UserSet MAX 10

// dskim - 21.05.13 - Serial Number 지워지지 않도록 변경
#define FLASH_DETECTOR_SN_BASEADDR  0x0EA0000
#define FLASH_DETECTOR_SN_LEN       0x0010000

// dskim - 22.01.13 - TFT(Panel) Serial Number 지워지지 않도록 변경
#define FLASH_TFT_SN_BASEADDR       0x0EB0000
#define FLASH_TFT_SN_LEN            0x0010000

#define FLASH_DEFECT_BASEADDR       0x0F00000
#define FLASH_DEFECT_LEN            0x0100000

#define FLASH_NUC_BASEADDR          0x1000000

#define FLASH_OPERATING_MODE_BASEADDR       0x0EE0000   // dskim - 22.09.21
#define FLASH_OPERATING_MODE_LEN            0x0010000

#define FLASH_OPERATING_TIME1_BASEADDR      0x0EC0000
#define FLASH_OPERATING_TIME1_LEN           0x0010000

#define FLASH_OPERATING_TIME2_BASEADDR      0x0ED0000
#define FLASH_OPERATING_TIME2_LEN           0x0010000

// 8 : Num of Ref Image, 2 : Use MSB Only
//#define FLASH_NUC_LEN				((DDR_CH2_BIT_DEPTH/8)*(8/2)*MAX_WIDTH_x32*MAX_HEIGHT)	// dskim - EXT1616R, EXT4343R 사이즈가 서로 다르므로 define 변경
//#ifdef GAIN_CALIB_SAVE_NUC_PARAM
//    #if defined(EXT4343R)
//        //  #define FLASH_NUC_INFO_BASEADDR 0x7DF0000   // dskim - Ref. Image 3��   // 1Gbit
//        //  #define FLASH_NUC_INFO_BASEADDR 0x59F0000   // dskim - Ref. Image 4��   // 2Gbit
//        #if defined(FLASH_1GBIT)
//            #define FLASH_NUC_INFO_BASEADDR 0x7EF0000   // dskim - 21.05.13 - 주소 변경
//            #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT) * 12)   // dskim - Ref. Image 3��           // 1Gbit
//        #else
//            #define FLASH_NUC_INFO_BASEADDR 0xA2F0000   // dskim - 21.05.13 - 주소 변경
//            #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT) * 16)   // dskim - Ref. Image 4��           // 2Gbit
//        #endif
//            #define FLASH_NUC_INFO_LEN      0x0010000
//            #define FLASH_IMG_BASEADDR      0x2E00000   // 사용하지 않음
//    #elif defined(EXT1616R)
//        #define FLASH_NUC_INFO_BASEADDR 0x39F0000
//        #define FLASH_NUC_INFO_LEN      0x0010000
//        #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT) * 16)   // dskim - (해상도*2Byte)*8 Ref IMG.	// 1Gbit
//        #define FLASH_IMG_BASEADDR      0x3A00000    // 사용하지 않음
//    #elif defined(EXT2832R)
//        #define FLASH_NUC_INFO_BASEADDR 0xA2F0000    // dskim - 21.10.26 - 주소 변경
//        #define FLASH_NUC_INFO_LEN      0x0010000
//        #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT) * 16)
//        #define FLASH_IMG_BASEADDR      0x3A00000
//    #else   // 예외처리
////      #define FLASH_NUC_INFO_BASEADDR 0x39F0000
////      #define FLASH_NUC_INFO_LEN      0x0010000
////      #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT) * 16)   // dskim - (해상도*2Byte)*8 Ref IMG.   // 1Gbit
////      #define FLASH_IMG_BASEADDR      0x3A00000
//        //# 2430 nuc data error at 0x39f0000 where nuc info writed, it should be calculated address.
//        #define FLASH_NUC_INFO_BASEADDR FLASH_NUC_BASEADDR + ((MAX_WIDTH_x32*MAX_HEIGHT) * 16)
//        #define FLASH_NUC_INFO_LEN      0x0010000
//        #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT) * 16)
//        #define FLASH_IMG_BASEADDR      FLASH_NUC_INFO_BASEADDR + FLASH_NUC_INFO_LEN
//    #endif
//#else   // GAIN_CALIB_SAVE_NUC_PARAM
//    #ifdef EXT4343R
//        #define FLASH_NUC_INFO_BASEADDR 0x59F0000   // dskim - 0.xx.09 - Ref. Image 4장
//        #define FLASH_NUC_INFO_LEN      0x0010000
//        #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT*2) * 4)  // dskim - 0.xx.09 - Ref. Image 4��         // 1Gbit
//        #define FLASH_IMG_BASEADDR      0x2E00000   // 사용하지 않음
//    #else
//        #define FLASH_NUC_INFO_BASEADDR 0x39F0000
//        #define FLASH_NUC_INFO_LEN      0x0010000
//        #define FLASH_NUC_LEN           ((MAX_WIDTH_x32*MAX_HEIGHT*2) * 8)  // dskim - 0.xx.08 - (�ػ�*2Byte)*8 Ref IMG.// 1Gbit
//    #define FLASH_IMG_BASEADDR      0x3A00000   // 사용하지 않음
//    #endif
//#endif


#define FLASH_IMG_LEN               (16/8)*MAX_WIDTH_x32*MAX_HEIGHT)    // 사용하지 않음

//#ifdef EXT4343R
//#define FLASH_SIZE                  0x8000000
//#else
//#define FLASH_SIZE                  0x10000000
//#endif

#define EEPROM_BASEADDR             0x0000
#define EEPROM_SIZE                 0x2000

#define FLASH_BUFFER_SIZE           16384
#define FLASH_SECTORERASE_SIZE      65536
#define FLASH_WRITE_SIZE            256

// ### micron mt25ql01g command set ###
#define FLAW_CMD_RESETENABLE        0x66
#define FLAW_CMD_RESETMEMORY        0x99
#define FLAW_CMD_ENTER4BYTE         0xB7
#define FLAW_CMD_EXIT4BYTE          0xE9

#define FLAW_CMD_WRITESTAUS         0x01
#define FLAW_CMD_READSTATUS         0x05
#define FLAW_CMD_WRITEDISABLE       0x04
#define FLAW_CMD_WRITEENABLE        0x06
#define FLAW_CMD_SECTORERASE        0xD8
#define FLAW_CMD_QUADPROGRAM        0x32
#define FLAW_CMD_READREGISTER       0xC8

// ### FPGA Flash write command set ###
// ### W1 means write 1byte,R:read , A:address, D:data
#define FPGA_FLAWCMD_CLEAR          0x000
#define FPGA_FLAWCMD_READY          0x001
#define FPGA_FLAWCMD_W1             0x011
#define FPGA_FLAWCMD_W1R1           0x021
#define FPGA_FLAWCMD_W2             0x041
#define FPGA_FLAWCMD_W1A4           0x081
#define FPGA_FLAWCMD_W1D256         0x101
#define FPGA_FLAWCMD_FIFOWRITE      0x10001

// ---- General-purpose macros -------------------------------------------------

// Get minimum of two values
#define minimum(a, b)   (a < b ? a : b)


// ---- Global variables -------------------------------------------------------

extern volatile u32 flash_buffer[FLASH_BUFFER_SIZE];

extern u32 FLASH_NUC_INFO_BASEADDR;
extern u32 FLASH_NUC_LEN;
extern u32 FLASH_NUC_INFO_LEN;
extern u32 FLASH_IMG_BASEADDR;
extern u32 FLASH_SIZE;

// ---- Function prototypes ----------------------------------------------------
u8 flash_done(void);
u8 flash_enter4b();
u32  flash_read_dword(u32 address);
void flash_write_block(u32 address, u32 *buffer, u32 length);
void flash_erase_block(u32 address);
//void flash_alloc_set(void);

void flaw_status_writeset(u32 data);
void flaw_sector_erase(u32 address, u32 repeatnum);
void flaw_write(u32 ddr_address, u32 flash_address, u32 repeatnum);
void flaw_writeenable();
void flaw_writeenable_check();
void flaw_busy_check();


#endif
