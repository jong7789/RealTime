/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  flash.c                                                         */
/*    Date :  2014-07-30                                                      */
/*     Rev :  0.3                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design SPI flash memory functions                   */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2008-04-03  |  JP  |  Initial release                             */
/*  0.2  |  2009-05-13  |  JP  |  Flash write handles write protection        */
/*  0.3  |  2014-07-30  |  JP  |  Support for 4B address mode                 */
/******************************************************************************/

#include <stdio.h>
#include <xparameters.h>
#include <math.h>
#include "gige.h"
#include "flash.h"
#include <xuartlite_l.h>

#include "func_printf.h"
#include "func_cmd.h"
#include "command.h"
#include "func_basic.h"
// ---- Global variables -------------------------------------------------------
//
volatile u32 flash_buffer[FLASH_BUFFER_SIZE];

u32 FLASH_NUC_INFO_BASEADDR;
u32 FLASH_NUC_LEN;
u32 FLASH_NUC_INFO_LEN;
u32 FLASH_IMG_BASEADDR;
u32 FLASH_SIZE;

void flash_init(void)
{
//    if (msame(mEXT4343R)) {
	if (mEXT4343R_series) {
        if (FLASH_1GBIT==1){
            FLASH_NUC_INFO_BASEADDR = 0x7EF0000;  // dskim - 21.05.13 - 주소 변경
            FLASH_NUC_LEN           = ((MAX_WIDTH_x32*MAX_HEIGHT) * 12);  // dskim - Ref. Image 3��           // 1Gbit
        }
        else {
            FLASH_NUC_INFO_BASEADDR = 0xA2F0000;   // dskim - 21.05.13 - 주소 변경
            FLASH_NUC_LEN           = ((MAX_WIDTH_x32*MAX_HEIGHT) * 16);  // dskim - Ref. Image 4��           // 2Gbit
        }
        FLASH_NUC_INFO_LEN      = 0x0010000;
        FLASH_IMG_BASEADDR      = 0x2E00000;  // 사용하지 않음
    }
    else if (mEXT1616R_series) {
        FLASH_NUC_INFO_BASEADDR = 0x39F0000;
        FLASH_NUC_INFO_LEN      = 0x0010000;
        FLASH_NUC_LEN           = ((MAX_WIDTH_x32*MAX_HEIGHT) * 16);  // dskim - (해상도*2Byte)*8 Ref IMG.	// 1Gbit
        FLASH_IMG_BASEADDR      = 0x3A00000;   // 사용하지 않음
    }
    else if (mEXT2832R_series) {
        FLASH_NUC_INFO_BASEADDR = 0xA2F0000;   // dskim - 21.10.26 - 주소 변경
        FLASH_NUC_INFO_LEN      = 0x0010000;
        FLASH_NUC_LEN           = ((MAX_WIDTH_x32*MAX_HEIGHT) * 16);
        FLASH_IMG_BASEADDR      = 0x3A00000;
    }
	// 241014 jyp
    else if (mEXT1024_series) {
        FLASH_NUC_INFO_BASEADDR = 0x39F0000;
        FLASH_NUC_INFO_LEN      = 0x0010000;
        FLASH_NUC_LEN           = ((MAX_WIDTH_x32*MAX_HEIGHT) * 16);
        FLASH_IMG_BASEADDR      = 0x3A00000;
    }
	//
    else {
        //# 2430 nuc data error at 0x39f0000 where nuc info writed, it should be calculated address.
        FLASH_NUC_INFO_BASEADDR = FLASH_NUC_BASEADDR + ((MAX_WIDTH_x32*MAX_HEIGHT) * 16);
        FLASH_NUC_INFO_LEN      = 0x0010000;
        FLASH_NUC_LEN           = ((MAX_WIDTH_x32*MAX_HEIGHT) * 16);
        FLASH_IMG_BASEADDR      = FLASH_NUC_INFO_BASEADDR + FLASH_NUC_INFO_LEN;
    }

//    if( msame(mEXT4343R)) //? only 4343R?
	if( mEXT4343R_series)
    	 FLASH_SIZE =  0x8000000;
    else
    	 FLASH_SIZE = 0x10000000;
}
u8 flash_done(void)
{
    u32 brkcnt=0;
//    while (!(gige_spi_gcsr & 0x80000000)) {};
    while (!(gige_spi_gcsr & 0x80000000)) //# timeout 220929mbh
    {
        brkcnt++;
        if(brkcnt > 0x100000) //# 256M
        {
            func_printf("flash_done - time out!\r\n");
//          for(u32 x=1; x<0xffffffff; x++)
//          {
                gige_spi_gcsr = 0xffffffff;
                func_printf("gige_spi_gcsr = 0x%08x\r\n",gige_spi_gcsr);
//              execute_cmd_reboot();
//          }
//          func_printf("flash_done 0x00000000 - time out!\r\n");
//          gige_spi_gcsr = 0x80000000;
//          func_printf("flash_done 0x80000000 - time out!\r\n");
//          func_printf("0x%08x\r\n",gige_spi_gcsr);
            return ERROR;
        }
    };

    return OK;
}

// ---- Enter 4B address mode --------------------------------------------------
//
u8 flash_enter4b()
{
    u32 brkcnt=0;
    gige_spi_gcsr = 0x00000800;
    while (!(gige_spi_gcsr & 0x80000000)) {
        brkcnt++;
        if(brkcnt > 0x100000) //# 256M
        {
            func_printf("flash_done - time out!\r\n");
//          {
                gige_spi_gcsr = 0xffffffff;
                func_printf("flash_enter4b gige_spi_gcsr = 0x%08x\r\n",gige_spi_gcsr);
            return ERROR;
        }
    }; //# 231127 test

    flash_done(); //# 220929


    return CMD_OK;
}


// ---- Read double-word from SPI flash memory ---------------------------------
//
// address      = address within the SPI flash memory address space
//
// return value = contents of four consecutive bytes starting at 'address'
//
u32 flash_read_dword(u32 address)
{
    u32 brkcnt=0;
    gige_spi_addr = address;
    gige_spi_gcsr = 0x00000203;
//    while (!(gige_spi_gcsr & 0x80000000)) {};
    flash_done(); //# 220929

    return gige_spi_rbuf[0];
}


// ---- Write data block into SPI flash memory ---------------------------------
//
//           The function erases 64 kB memory block and writes new data into it
//           Maximum block length is 65536 bytes
//           The address is adjusted to start at 64 kB block boundary
//
// address = start address within the SPI flash memory
// *buffer = pointer to a dword data buffer
// length  = number of bytes to write
//
#define DEBUG_FWB 0
#define DELAY_FWB 1
void flash_write_block(u32 address, u32 *buffer, u32 length)
{
    u32 burst, blen, i, brkcnt=0;

    // Adjust address to 64 kB boundaries and limit length to 64 kB
    address &= 0xFFFF0000;
    length   = minimum(length, 65536);

    if(DEBUG_FWB) func_printf("f0 ");
    if(DELAY_FWB) usdelay(10);

    // Enable flash write access
    gige_spi_wbuf[0] = 0x00000000;
    gige_spi_gcsr    = 0x00000600;
//    while (!(gige_spi_gcsr & 0x80000000)) {};
    flash_done(); //# 220929

    if(DEBUG_FWB) func_printf("f1 ");
    if(DELAY_FWB) usdelay(10);

    // Erase block and set big-endian mode
    gige_spi_addr = address;
    gige_spi_gcsr = 0x00000500;
//    while (!(gige_spi_gcsr & 0x80000000)) {};
    flash_done(); //# 220929

    if(DEBUG_FWB) func_printf("f2 ");
    if(DELAY_FWB) usdelay(10);

    // Write block
    for (burst = 0; (burst * 256) < length; burst++)
    {
        blen = minimum(length - (burst * 256), 256);
        for (i = 0; (i * 4) < blen; i++)
            gige_spi_wbuf[i] = *buffer++;
        gige_spi_addr = address + (burst * 256);
        gige_spi_gcsr = 0x00000100 | ((blen - 1) & 0xFF);
        // while (!(gige_spi_gcsr & 0x80000000)) {};
        if(ERROR == flash_done())
        {
            func_printf("flash write error RETURN! \r\n");
            return;//# 221005
    }
    }
    brkcnt=0;

    if(DEBUG_FWB) func_printf("f3 ");
    if(DELAY_FWB) usdelay(1);

    // Flash write protection
    gige_spi_wbuf[0] = 0x1C000000;
    gige_spi_gcsr    = 0x00000600;
    // while (!(gige_spi_gcsr & 0x80000000)) {};
    flash_done(); //# 220929

    if(DEBUG_FWB) func_printf("f4 ");

    return;
}

void flash_erase_block(u32 address)
{
    static u32 flash_buffer_rst[FLASH_BUFFER_SIZE];
    static u32 rst_done;
    u32 i = 0;

    if(!rst_done) 
    {
        for(i = 0; i < FLASH_BUFFER_SIZE; i++) 
        {
            flash_buffer_rst[i] = 0xFFFFFFFF;
        }
        rst_done = 1;
    }

    flash_write_block(address, (u32*)flash_buffer_rst, 65536);
}

// ### critical code - it makes problem at FLASH ###
//void flash_alloc_set(void) {
//  u32 width_x32 = (u32)(ceil(func_width / 32.0)) * 32;
//  u32 addr = FLASH_ALLOC_BASEADDR + FLASH_ALLOC_CALIB_SIZE;
//  u32 data = (2 * width_x32 * func_height);
//  sys_state.only_comment = 1;
//  execute_cmd_wflash(addr, data);
//  sys_state.only_comment = 0;
//}

void flaw_status_writeset(u32 data)
{
    flaw_writeenable();
    flaw_writeenable_check();

     // ### status set ###
    REG(ADDR_FLAW_CMD)   = FLAW_CMD_WRITESTAUS; // Write status
    REG(ADDR_FLAW_WDATA) = data; // Write 0 ???
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W2;
    usdelay(1); //
    while((REG(ADDR_FLAW_RDATA) & 1)==0);
    // #################

    flaw_busy_check();
    // REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;
}

void flaw_sector_erase(u32 address, u32 repeatnum){
    u32 i = 0;
    u32 flash_addr_incr = address;
    u8  star_cnt = 32; // count of '*'
    u32 repeatnum_div = repeatnum/star_cnt;
    u32 debug_percent = 0;
    char DEBUG_MSG[128];

    memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
    sprintf((char*)DEBUG_MSG,"erase memory");
    gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG); //# nconsole debug down 220922

//  func_printf("### erase start ### ");
    func_printf("Process |");
    for(i = 0; i < star_cnt; i++)       func_printf(" ");
    func_printf("|");
    for(i = 0; i < (star_cnt+1); i++)   func_printf("\b");

//  func_printf("Erase repeat = %d\r\n", repeatnum);
    for ( i=0; i<repeatnum; i++) 
    {
        if(func_stop_save_flash == 1) 
        {
            func_printf("\r\nStop erase to flash memory!\r\n");
            break;
        }

// comment #230613
//        for(u32 j=0; j<32; j++)
//            func_printf("\b");

//      func_printf("address = 0x%08x", flash_addr_incr);

        flaw_writeenable();

        flaw_writeenable_check();

        // ### Erase cmd ###
        REG(ADDR_FLAW_CMD)  = FLAW_CMD_SECTORERASE; 
        REG(ADDR_FLAW_ADDR) = flash_addr_incr;
        REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1A4;
        usdelay(1); //
        while((REG(ADDR_FLAW_RDATA) & 1)==0);
        // REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;
        // #################

        flaw_busy_check();

        flash_addr_incr += 0x10000;

        REG(ADDR_FLAW_CMD)  = 0;
        usdelay(1); //

        if(i % repeatnum_div == 0) func_printf("*");

        if(!(i % (repeatnum / 10))) {
            memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
            sprintf((char*)DEBUG_MSG,"%d%%", (int)(debug_percent));
            gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG); //# nconsole debug down 220922
            debug_percent += 10;
        }
    }

    func_printf("\r\n### erase done from 0x%8x to 0x%8x  ### \r\n",address ,flash_addr_incr);
}

#define DBG_FLAW 0
void flaw_write(u32 ddr_address, u32 flash_address, u32 repeatnum)
{
    u32 i = 0;
    u32 ddr_addr_incr = ddr_address;
    u32 flash_addr_incr = flash_address;
    u32 nun_num = func_ref_num-1;
    u32 ref_cnt = 0;
    u8  star_cnt = 32; // count of '*'
    u32 repeatnum_div = repeatnum/star_cnt;

    u32 debug_percent = 0;
    char DEBUG_MSG[128];

    memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
    sprintf((char*)DEBUG_MSG,"write memory");
    gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);

    func_printf("### write start ### ");
    func_printf("Process |");
    for(i = 0; i < star_cnt; i++)       func_printf(" ");
    func_printf("|");
    for(i = 0; i < (star_cnt+1); i++)   func_printf("\b");

    for (u32 i=0; i<repeatnum; i++) {
//      debug_cnt++;
//      if(debug_cnt%2048==0) func_printf("flash_addr_incr(%8x) <= ddr_addr_incr(%8x) ddr_data(%8x)  \r\n",flash_addr_incr, ddr_addr_incr, DREG(ddr_addr_incr));
        if(func_stop_save_flash == 1) {
            func_printf("\r\nStop writing NUC parameters to flash memory!\r\n");
            break;
        }

            // #####################
            // ### write to fifo, it should be 256 byte ###
        REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_READY;
            for(u16 j=0; j<256/4; j++)
            {
                if(DBG_FLAW)if(i==0)func_printf("ddr_addr=0x%08x // data=0x%08x\r\n",ddr_addr_incr, DREG(ddr_addr_incr)); //# 230320
                REG(ADDR_FLAW_WDATA) = DREG(ddr_addr_incr);
                REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_FIFOWRITE;
                REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_READY;
                ddr_addr_incr += 4;

                if(++ref_cnt == nun_num) 
                {
                    ref_cnt = 0;
//                  ddr_addr_incr += (16 - (4*(nun_num)));
//                    #if defined(GEV10G)
//                    //              ddr_addr_incr += (16 - (4*(nun_num)));
//                    #else
//                        ddr_addr_incr += (16 - (4*(nun_num)));
//                    #endif


					if (def_gev_speed == 10)
						;
					else
						ddr_addr_incr += (16 - (4*(nun_num)));

                }
            }

            flaw_writeenable();

            flaw_writeenable_check();

            // ### real write ###
            REG(ADDR_FLAW_CMD)  = FLAW_CMD_QUADPROGRAM; // Write data
            REG(ADDR_FLAW_ADDR) = flash_addr_incr;
            REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1D256;
            usdelay(1);
            while((REG(ADDR_FLAW_RDATA)&1)==0);
            REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear
            // ###################

            flaw_busy_check();

            flash_addr_incr += 0x00100; // flash has a 256 byte buffer
//          gige_callback(0); // #### keep connection with GEV
            if(i % repeatnum_div == 0) func_printf("*");

        if(!(i % (repeatnum / 10))) {
            memset(DEBUG_MSG, 0, sizeof(DEBUG_MSG));
            sprintf((char*)DEBUG_MSG,"%d%%", (int)(debug_percent));
            gige_send_message4(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
            debug_percent += 10;
        }
    }
    func_printf("\r\n### Flash write done ### Last ADDR ddr(%8x) => flash(%8x) \r\n",ddr_addr_incr, flash_addr_incr);
}

void flaw_writeenable()
{
        // ### Write Enable ###
        REG(ADDR_FLAW_CMD) = FLAW_CMD_WRITEENABLE; // Write Enable
        REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1;
        usdelay(1); //
        while((REG(ADDR_FLAW_RDATA) & 1)==0);
        // REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear
}

void flaw_writeenable_check()
{
        // ### read status ###
        u32 rdata = 0;
        u32 whilecnt = 0;
        while (1)
        {
            REG(ADDR_FLAW_CMD)  = FLAW_CMD_READSTATUS;
            REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1R1;
            usdelay(1); //
            while((REG(ADDR_FLAW_RDATA) & 1)==0);
//          REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;

//          rdata = (REG(ADDR_FLAW_RDATA)>>16)&3;
//          if (rdata == 2) // (1):write set (0):busy
            rdata = (REG(ADDR_FLAW_RDATA)>>16)&1;
            if (rdata == 0) // (1):write set (0):busy
            {
                gige_callback(0);
                break;
            }
            else if (whilecnt > 1024) // 1M
            {
                func_printf("error WE check status 0 = %8x \r\n", REG(ADDR_FLAW_RDATA));
                break;
            }
            whilecnt++;
        }
}

void flaw_busy_check()
{
        // ### read status ###
        u32 rdata = 0;
        u32 whilecnt = 0;
        while (1)
        {
            REG(ADDR_FLAW_CMD)  = FLAW_CMD_READSTATUS;
            REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1R1;
            usdelay(1); //
            while((REG(ADDR_FLAW_RDATA) & 1)==0);
            REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR;

            rdata = (REG(ADDR_FLAW_RDATA)>>16)&1;
            if (rdata == 0)
            {
                // func_printf("Erase= %d \r\n", whilecnt);
                break; // busy=1 check
            }
            else if (whilecnt > 100000) // 1M
            {
                func_printf("error BUSY status 0 = %8x \r\n", REG(ADDR_FLAW_RDATA));
                break;
            }
            whilecnt++;
            gige_callback(0); // #### keep connection with GEV
//          usdelay(1);
        }
}
