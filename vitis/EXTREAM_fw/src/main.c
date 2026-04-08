/******************************************************************************/
/*  10 GigE Vision Reference Design                                           */
/*----------------------------------------------------------------------------*/
/*    File :  main.c                                                          */
/*    Date :  2023-10-24                                                      */
/*     Rev :  0.11                                                            */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  10 GigE Vision reference design firmware                                  */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2011-10-07  |  JP  |  Initial release                             */
/*  0.2  |  2011-11-02  |  JP  |  Various 10G related modifications           */
/*  0.3  |  2016-01-07  |  JP  |  Updated for latest IP cores and 10GBASE-T   */
/*  0.4  |  2019-02-11  |  JP  |  Cleaned up, updated according to current    */
/*       |              |      |  libgige, ready for NBASE-T                  */
/*  0.5  |  2020-08-12  |  PD  |  Updated for latest IP cores                 */
/*  0.6  |  2021-03-23  |  MAS |  Parameter for timestamp in gige_send_message*/
/*                             |  Updates for latest validation suite         */
/*  0.7  |  2022-02-10  |  SS  |  Core and version update                     */
/*  0.8  |  2022-10-11  |  SS  |  Core and version update                     */
/*  0.9  |  2023-01-23  |  SS  |  Core and version update                     */
/*  0.10 |  2023-01-26  |  AZ  |  Added LinkConfiguration, corrected comments */
/*  0.11 |  2023-10-24  | AM/AZ|  Core and version update                     */
/******************************************************************************/

#include <xparameters.h>
#include <mb_interface.h>
#include <xuartlite_l.h>
#include <stdio.h>

#include "func_printf.h"
#include "func_basic.h"
#include "gige.h"
#include "user.h"
#include "framebuf.h"
#include "phy.h"
#include "int.h"
#include "flash.h"
#include "func_cmd.h"
#include "display.h"
#include "calib.h"
#include "fpga_info.h"

/******************************************************************************

	v2.xx.01
		01. comments. malfunction
			"sprintf(result, format, val); //# v2 231127 stuck here
		02. checking for xray
		03. comments -> uncomments, heap error clear.
			gcvt(func_frate, 4, DEBUG_MSG); //# ???
		04. binning mode packet error.
			it might be trouble of payload size. DBG_fbPadding
			"//# 231221 no need, payload packet error reseted
		05. '2'binning gain save, power on img size is '1'binning
			"fpga_init(); //# position after load_flash;
		06. edgec call at init
			execute_cmd_edgemask_calc(); //# 231221 edge cut call
		07. problem of getting fist offset if binning mode is saved as a gain calibration.
			//# rus shoud come before getting offset #231226
			//#  if(func_hwload_flag && func_bw_align_done){ //# bcal after
		08. wtp 1000 unit to 100 unit
			" profile_data.tirst = data[2] * 100; //# 240122 1000->100
		09. OverExpos make data lower under 65535 at DIC HATA, need to increase IntRST time.
        	" profile.init.tirst = TIRST_2000; //# overExpos 240130
			  v1.xx.71
				  1. 4343R_3 a-si use CHARGE INJECTION #240110
					-. else if (msame(mEXT4343R_3)){ //# a-si
					-. //# 240110 use charge injection

			  v1.xx.72
				  1. 4343R_2 OverExposure problem from DIC HATA
					   -. when Overexposure make data under 55000 at roic.
					   -. it cause intrst time is short, 1->2 change
					   -. system_config "profile.init.tirst = TIRST_2000; //# 240123 overExposure problem
  	   rreg 0x5d 0x02F0 -> 208

	SW2.01.02      2025.09.09 16:00 : update from r1 250904

	SW2.xx.03
		01. //$ 260220 Dual ROIC - XML_HEIGHT & XML_OFFSETY
		02. //$ 260223 Dual ROIC - XML_BINNING_MODE
		03. //$ 260224 Dual ROIC - Analog Gain
		04. //$ 260303 AFE3256 ROIC TEMP Sensor
		05. //$ 260305 AFE3256 Digital Offset Correction
		06. //$ 260317 EXT3643R Model ADD
        07. //$ 260401 SFP & LAN
        08. //$ 260402
        09. //$ 260403 Analog Gain 40 -> 12 step
*****************************************************************************/

u8  GIGE_DVER   [16] = "SW2.08.03      "; // SW1.SUB.MAIN version
u8  FW_DATE     [20] = "2026.04.07 11:20";

/****************************************************************************
timing profile => system_config
menu-xilinx-launch shall
    make clean; make xml; make; make prog; make run;
    make clean; make xml; make;
                          make; make prog; make run;
*****************************************************************************/
// ---- Global constants and variables -----------------------------------------

// MDIO device addresses
const u8  GIGE_PHY_ADDR         = 0x00;     // Ethernet Marvell NBaset-T PHY

// I2C device addresses
const u8  I2C_DEV_EEPROM        = 0xA0;     // 24C64 I2C EEPROM
const u8  I2C_DEV_SENSOR        = 0xB8;     // Image sensor (unused)

// Location of the shared external memory within address space
// Legacy declarations needed for compatibility purposes only!
const u32 MPMC_NUM_INSTANCES    = 0;
const u32 MPMC_BASEADDR         = 0;
const u32 MPMC_HIGHADDR         = 0;

// Device description registers
//const u8  GIGE_MANUF[32]        = "DRT 231124 1430 Sensor to Image GmbH\0";
//const u8  GIGE_MODEL[32]        = "XGVRD-KC705-N\0";
//const u8  GIGE_DVER [32]        = "2.7.0\0";
//const u8 GIGE_MINFO[48]        = "NBASE-T GigE Vision Reference Design for KC705\0";
//u8 GIGE_MINFO[48]        = "NBASE-T GigE Vision Reference Design for KC705\0";

// Stream channel packet size margins
// The values represent net GVSP payload length without IP/UDP/GVSP headers!
const u32 SCPS_MIN =  512;
const u32 SCPS_MAX = 8192;
const u32 SCPS_INC =   16;  // AXI data width in bytes

// Unused simulated EEPROM image
// NOTE: Uncomment the following line and remove eeprom.c if physical EEPROM is used
volatile u8 *EEPROM;

u8  TFT_SERIAL  [16] = "No Data";
u8  PANEL_SERIAL[16] = "No Data";
u8  FPGA_VER    [16] = "No Data";
//u8  FPGA_MODEL  [16] = "No Data";
u8  FPGA_DATE   [16] = "No Data";
u8  FW_VER      [16]; // copy GIGE_DVER
// Device description registers
const u8  GIGE_MANUF[32]    = "DRTECH\0";
#ifdef EXT1024R
    const u8  GIGE_MODEL[32]  = "EXT1024R\0";
    const u8  HW_VER    [16]  = "hw9.99.99_99\0";
#elif defined EXT1616R
    #if defined EXT1616RL
        const u8  GIGE_MODEL[32] = "EXT1616RL\0";
        const u8  HW_VER    [16] = "HW2.10.01_02\0";
    #else
        const u8  GIGE_MODEL[32] = "EXT1616R\0";
        const u8  HW_VER    [16] = "HW2.10.01_02\0";
    #endif
#elif defined EXT4343R
    #if defined EXT4343R_1
      const u8  GIGE_MODEL[32] = "EXT4343R\0";   // DDR8G, FLASH2G, 15fps, LG igzo
      const u8  HW_VER    [16] = "HW2.00.02_01\0";
    #elif defined EXT4343R_2
      const u8  GIGE_MODEL[32] = "EXT4343R\0";   // DDR8G, FLASH2G, 15fps, innoc igzo
      const u8  HW_VER    [16] = "HW2.10.02_01\0";
    #elif defined EXT4343R_3
      const u8  GIGE_MODEL[32] = "EXT4343R\0";   // DDR8G, FLASH2G, 7fps, innoc a-si
      const u8  HW_VER    [16] = "HW2.11.02_10\0";
    // #elif defined EXT4343RC
    //   const u8  GIGE_MODEL[32] = "EXT4343RC\0";   // DDR8G, FLASH2G, 15fps , DDR_A14
    //   const u8  HW_VER    [16] = "hw2.10.00_02\0";
    #elif defined EXT4343RC_1
      const u8  GIGE_MODEL[32] = "EXT4343RC\0";  // DDR8G, FLASH2G, 15fps
      const u8  HW_VER[16]     = "HW2.00.02_01\0";
//            u8  HW_VER[16]     = "HW0.00.02_01\0"; //# warning cause const
    #elif defined EXT4343RC_2
      const u8  GIGE_MODEL[32] = "EXT4343RC\0";  // DDR8G, FLASH2G, 7fps
      const u8  HW_VER    [16] = "HW2.10.02_01\0";
    #elif defined EXT4343RC_3
      const u8  GIGE_MODEL[32] = "EXT4343RC\0";  // DDR8G, FLASH2G, 7fps
      const u8  HW_VER    [16] = "HW2.11.02_10\0";
    // #elif defined EXT4343RCL
    //   const u8  GIGE_MODEL[32] = "EXT4343RCL\0";  // DDR8G, FLASH2G,  8fps , DDR_A14
    //   const u8  HW_VER    [16] = "hw2.00.01_01\0";
    #elif defined EXT4343RCL_1
      const u8  GIGE_MODEL[32] = "EXT4343RCL\0"; // DDR8G, FLASH2G,  8fps
      const u8  HW_VER    [16] = "HW2.00.02_01\0";
    #elif defined EXT4343RCL_2
      const u8  GIGE_MODEL[32] = "EXT4343RCL\0"; // DDR8G, FLASH2G,  8fps
      const u8  HW_VER    [16] = "HW2.10.02_01\0";
    #elif defined EXT4343RCL_3
      const u8  GIGE_MODEL[32] = "EXT4343RCL\0"; // DDR8G, FLASH2G,  8fps
      const u8  HW_VER    [16] = "HW2.11.02_10\0";
    #elif defined EXT4343RI_2
      const u8  GIGE_MODEL[32] = "EXT4343RI\0";   // DDR8G, FLASH2G, 25fps, innoc igzo 10G
      const u8  HW_VER    [16] = "HW2.10.02_01\0";
    #elif defined EXT4343RCI_1
      const u8  GIGE_MODEL[32] = "EXT4343RCI\0";  // DDR8G, FLASH2G, 25fps, 10G
      const u8  HW_VER[16]     = "HW2.00.02_01\0";
    #elif defined EXT4343RCI_2
      const u8  GIGE_MODEL[32] = "EXT4343RCI\0";  // DDR8G, FLASH2G, 25fps, 10G
      const u8  HW_VER[16]     = "HW2.10.02_01\0";
    #endif
#elif defined EXT2430RI
    const u8  GIGE_MODEL[32] = "EXT2430RI\0";
    const u8  HW_VER    [16] = "HW2.10.00_02\0";
#elif defined EXT2430R
    const u8  GIGE_MODEL[32] = "EXT2430R\0";
    const u8  HW_VER    [16] = "HW2.10.00_02\0";
#elif defined EXT2832R
    #if defined EXT2832R_2
        const u8  GIGE_MODEL[32] = "EXT2832R\0";
        const u8  HW_VER    [16] = "HW2.10.02_01\0";
    #else
        const u8  GIGE_MODEL[32] = "EXT2832R\0";
        const u8  HW_VER    [16] = "HW2.00.02_01\0";
    #endif
#elif defined EXT810R
    const u8  GIGE_MODEL[32]  = "EXT810R\0";
    const u8  HW_VER    [16]  = "HW2.32.01_10\0";
#elif defined EXT2430RD
    const u8  GIGE_MODEL[32]  = "EXT2430RD\0";
    const u8  HW_VER    [16]  = "HW2.32.01_10\0"; //?? needs check
#elif defined EXT4343RD
    const u8  GIGE_MODEL[32]  = "EXT4343RD\0";
    const u8  HW_VER    [16]  = "HW2.10.22_01\0";
#endif

//#if defined(GEV10G)
//     u8  GIGE_MINFO[48] = "10G GigE Vision\0";
//#else
//     u8  GIGE_MINFO[48] = "2.5G GigE Vision\0";
//#endif
// ---- Main program -----------------------------------------------------------
//
#define DBG_main 0
//#ifndef ROMDOWNLOADER
int main(void)
{
    int ret            = 0;
    // Initialize and enable CPU caches
    microblaze_invalidate_icache();
    microblaze_enable_icache();
    microblaze_invalidate_dcache();
    microblaze_enable_dcache();

    // Set EEPROM access mode
    // - I2C_ACC_NONE   = no EEPROM device available, use emulated EEPROM
    // - I2C_ACC_COMMON = use physical EEPROM (eeprom.c is not needed)
    eeprom_access_mode = I2C_ACC_COMMON;

    // Initialize (X)GigE core
//    gige_init(0, XPAR_M1_AXI_GEV_BASEADDR, DEV_MODE_TX, XPAR_CPU_M_AXI_DP_FREQ_HZ,
//              PHY_NBASET_MRVL, GIGE_PHY_ADDR, 2500000, 0, SCPS_MAX, DBG_ICMP);
    gige_init(0, XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR, DEV_MODE_TX, XPAR_CPU_M_AXI_DP_FREQ_HZ,
              PHY_NBASET_MRVL, GIGE_PHY_ADDR, 2500000, 0, SCPS_MAX, DBG_ICMP);

    gige_set_data_rates(200, 10000);                    // f(tx_stm_clk) = 200MHz, 10Gbps Ethernet link
    gige_set_link_config_cap(LINK_CONFIG_CAP_SL);       // Physical link configuration capabilities
    gige_set_link_config(LINK_CONFIG_SL);               // Current physical link configuration
    gige_set_sceba(0, MAP_SCEBA);                       // Set stream channel extended bootstrap address
 //#######################################################################
    // Initialize Marvell NBase-T PHY
//    ret = m88x33xx_init(RXAUI);
//    if (ret)
//        xil_printf("m88x33xx_init FAILED with ERROR code %d\r\n", ret);
//    if(DBG_main)func_printf("[DBG_main] m88x33xx_init(RXAUI) 1ST \r\n");
    func_printf("Ethernet m88x33xx_inity set...");
    m88x33xx_inity(RXAUI); //# 231208
    func_printf("Done\r\n");
    //#######################################################################
    load_fpga_model(); //# 231023 no_model_def
//    execute_func_cmd(); //# 231023 fps max set //# 231128 dont need it in load_fpga_model
    // GIGE_DVER FPGA 버전 읽어서 중간 값으로 표시하도록 변경해야함
    load_fw_ver();
    //#######################################################################

    // Initialize framebuffer and set GEV version
//    if ((video_gpio_in & 0x00000001) == 0)
	if (0) //# v2
    {
        gige_set_gev_version(1);                        // GEV 1.x (SW11 switch 1 position "OFF")
        framebuf_init(1, 0, 1, 0x04000000);             // Low latency, progressive-scan, GEV 1.x, buffer size
        framebuf_control &= ~FRAMEBUF_C_EXTSTAT;        // Disable extended GVSP status codes
        func_printf("[UU] Running in GEV 1.2 mode\r\n");
    }
    else
    {
        gige_set_gev_version(2);                        // GEV 2.x (SW11 switch 1 position "ON")
#if 0
        gige_force_gev_version(0x00020002);             // Force GEV spec version to 2.2
#endif
//        framebuf_init(1, 0, 0,0x04000000);              // Low latency, progressive-scan, GEV 2.x, buffer size
        framebuf_init(1, 0, 0,0x06000000); //# v2 legacy
        framebuf_control |= FRAMEBUF_C_EXTSTAT;         // Enable extended GVSP status codes
        func_printf("[UU] Running in GEV 2.x mode\r\n");
    }

    load_fpga_model(); //# 231023 no_model_def
    execute_func_cmd(); //# 231023 fps max set
    //int_init();
    // Print device information to std_out
    //    gige_print_header();
    // Endless main program loop
    //##########################################################################################
    // GIGE_DVER FPGA 버전 읽어서 중간 값으로 표시하도록 변경해야함
    load_fw_ver();

    framebuf_control |= FRAMEBUF_C_EXTSTAT;
//    func_printf("[UU] Running in GEV 2.1 mode\r\n");
    REG(ADDR_LED_CTRL) = LED_CTRL_BLINK_0P5S; // boot led blinking 1/2sec 221018 mbh
    gige_print_header();
    execute_cmd_grab(0);

    execute_cmd_psel(func_test_pattern); // dskim - 21.03.19 - "wtp" 명령어 이후 수행될 경우 v 이미지 일부 반전되는 현상 발생
    execute_cmd_pmode(func_sync_source); // dskim - 21.03.19 - "wtp" 명령어 이후 수행될 경우 v 이미지 일부 반전되는 현상 발생
    execute_cmd_smode(func_shutter_mode);   // preventing bcal fail during init 211101mbh
    REG(ADDR_FRAME_TIME) = 0; // 211101
    flash_enter4b(); //###################################### no works ################
    if(DBG_main)func_printf("#[DBG_main] load_flash\r\n");
    load_flash();
    if(DBG_main)func_printf("#[DBG_main] fpga_init\r\n");
    fpga_init(); //# position after load_flash; //# added reg_init 230824
    if(DBG_main)func_printf("#[DBG_main] user_init\r\n");
    user_init(); //#
//    if(DBG_main)func_printf("#[DBG_main] update_hwload\r\n");
//    update_hwload(); //# 231222
//    disp_cmd_rtime();
    execute_cmd_op_boot_count();
    execute_cmd_flash_check();
    u16 once = 0;

//    if(DBG_main)print_setup();
    // Initialize Marvell NBase-T PHY
//    ret = m88x33xx_init(RXAUI);
//    if (ret)
//        xil_printf("m88x33xx_init FAILED with ERROR code %d\r\n", ret);
//    if(DBG_main)func_printf("[DBG_main] m88x33xx_init(RXAUI) 1ST \r\n");
//    if(DBG_main)func_printf("[DBG_main] print_setup\r\n");
//    if(DBG_main)print_setup();
    if(DBG_main)func_printf("#[DBG_main] func_width=%d\r\n",func_width);
    if(DBG_main)func_printf("#[DBG_main] func_height=%d\r\n",func_height);
    if(DBG_main)func_printf("#[DBG_main] func_width=%d\r\n",REG(ADDR_WIDTH));
    if(DBG_main)func_printf("#[DBG_main] func_height=%d\r\n",REG(ADDR_HEIGHT));

    while (1)
    {
        gige_callback(0);           // Networking callback function
        user_callback();            // User callback

        gige_callback(0);
        user_callback();
        uart_command();
        genicam_command();
        update_defect();
//        if(DBG_main)func_printf("[DBG_main] update_data &&&&&&&&&&&&&&&&&&&&&&\r\n");
        update_data(); //# bit align
//        update_sleep(); //temp #v2 231127
        update_fwtrig();
        update_acc(); //# for test 220329mbh
//        if(DBG_main)func_printf("[DBG_main] update_hwload &&&&&&&&&&&&&&&&&&&&&\r\n");
//        update_hwload();
//        if(DBG_main)func_printf("#[DBG_main] update_hwload\r\n");
//        update_hwload(); //# 231226
        if (once == 4 )
        {
//             m88x33xx_inity(RXAUI); //# 220628mbh
//             disp_cmd_rtime();
             once++;
             if(DBG_main)func_printf("[DBG_main] m88x33xx_inity(RXAUI)\r\n");
        }
        else if (once == 5)
        {
            u32 gige_status = (gige_gcsr & 0x03);
            if (gige_status==1 || gige_status==3)
                REG(ADDR_LED_CTRL) = LED_CTRL_OFF; // boot led off 221018 mbh
            else
                REG(ADDR_LED_CTRL) = LED_CTRL_ON;
            once++;
//            disp_cmd_rtime();
            if(DBG_main)func_printf("[DBG_main] disp_cmd_rtime\r\n");
        }
        else if (once == 7)
        {
            if (XREG(XGIGE_ADDR_IP))
            {
                once++;
                 if(DBG_main)func_printf("[DBG_main] XREG(XGIGE_ADDR_IP)=0x%08x\r\n",XREG(XGIGE_ADDR_IP));
                 if(DBG_main)func_printf("[DBG_main] XREG(XGIGE_ADDR_MAC_H)=0x%08x\r\n",XREG(XGIGE_ADDR_MAC_H));
                 if(DBG_main)func_printf("[DBG_main] XREG(XGIGE_ADDR_MAC_L)=0x%08x\r\n",XREG(XGIGE_ADDR_MAC_L));
                 if(DBG_main)print_setup();
//                 m88x33xx_initx(RXAUI);
            }
        }
//        else if (once == 10000)
//        else if (once == 5000)
        else if (once == 100)
        {
           if (XREG(XGIGE_ADDR_IP))
            {
               if(DBG_main)print_setup();//# test 231214
        	   ret=m88x33xx_init(RXAUI); //# 220628mbh
               once++;
               if(DBG_main)func_printf("[DBG_main] m88x33xx_init(RXAUI)\r\n");
               disp_cmd_rtime();
            }

           if (ret)
        	   func_printf("m88x33xx_init FAILED with ERROR code %d\r\n", ret);

//           // Initialize framebuffer and set GEV version
//           if ((video_gpio_in & 0x00000001) == 0)
//           {
//               gige_set_gev_version(1);                        // GEV 1.x (SW11 switch 1 position "OFF")
//               framebuf_init(1, 0, 1, 0x04000000);             // Low latency, progressive-scan, GEV 1.x, buffer size
//               framebuf_control &= ~FRAMEBUF_C_EXTSTAT;        // Disable extended GVSP status codes
//               func_printf("[UU] Running in GEV 1.2 mode\r\n");
//           }
//           else
//           {
//               gige_set_gev_version(2);                        // GEV 2.x (SW11 switch 1 position "ON")
//       #if 0
//               gige_force_gev_version(0x00020002);             // Force GEV spec version to 2.2
//       #endif
//               framebuf_init(1, 0, 0,0x04000000);              // Low latency, progressive-scan, GEV 2.x, buffer size
//               framebuf_control |= FRAMEBUF_C_EXTSTAT;         // Enable extended GVSP status codes
//               func_printf("[UU] Running in GEV 2.x mode\r\n");
//           }
//           execute_cmd_load_hw_calibration(1); //# 231226
           if(DBG_main)func_printf("#[DBG_main] func_width=%d\r\n",func_width);
           if(DBG_main)func_printf("#[DBG_main] func_height=%d\r\n",func_height);
           if(DBG_main)func_printf("#[DBG_main] func_width=%d\r\n",REG(ADDR_WIDTH));
           if(DBG_main)func_printf("#[DBG_main] func_height=%d\r\n",REG(ADDR_HEIGHT));
        }
        else if (once<1024)
        {
            once++; //220118mbh

        }
/*
// ================================================================== DEBUG ====
        if (!XUartLite_IsReceiveEmpty(XPAR_UARTLITE_0_BASEADDR))
            switch (XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR))
            {
//-------------- Framebuffer test ------------------------ start ---------------
                case 'f':
                case 'F':
                        xil_printf("@@@@ FRAMEBUFFER REGISTERS\r\n");
                        framebuf_printregs();
                        xil_printf("\r\n");
                        break;
                case 'i':
                case 'I':
                        xil_printf("@@@@ INIT FRAMEBUFFER\r\n");
                        xil_printf("\r\n");
                        framebuf_control |= FRAMEBUF_C_INIT;
                        break;
                case 'c':
                case 'C':
                        xil_printf("@@@@ CLEAR STATISTICS\r\n");
                        xil_printf("\r\n");
                        framebuf_control |= FRAMEBUF_C_CLRSTAT;
                        break;
//-------------- Framebuffer test ------------------------ end -----------------
//-------------- Autentication/License ------------------- start ---------------
                case 'a':
                case 'A':
                        xil_printf("@@@@ GIGE AUTH STATUS\r\n");
                        xil_printf("GigE Auth Status = 0x%02X\r\n",gige_get_auth_status());
                        break;
                case 'l':
                case 'L':
                        xil_printf("@@@@ GIGE LIC CHECKSUM\r\n");
                        xil_printf("GigE Lic Checksum = 0x%02X\r\n",gige_get_license_checksum());
                        break;
//-------------- Autentication/License ------------------- end -----------------
//-------------- ETH PHY test ---------------------------- start ---------------
                case 'x':
                        // Print Copper Specific Status Register 1 0x8008
                        // Speed, Copper Link, Duplex ... information
                        xil_printf("mdio_read(0, 0x8008) = 0x%04X\r\n" ,mdio_read(3, 0x8008));
                        break;
                case 'd':
                case 'D':
                        xil_printf("@@@@ PHY DEBUG (select option number)\r\n");
                        while (XUartLite_IsReceiveEmpty(XPAR_UARTLITE_0_BASEADDR)) {};
                        m88x33xx_debug((XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR) - '0'));
                        xil_printf("\r\n");
                        break;
                case 'r':
                case 'R':
                        xil_printf("@@@@ PHY REVISION\r\n");
                        m88x33xx_revision();
                        xil_printf("\r\n");
                        break;
//-------------- ETH PHY test ---------------------------- end -----------------
            }
// ================================================================== DEBUG ====
 */
    }

    // Never reached exit
    microblaze_disable_dcache();
    microblaze_invalidate_dcache();
    microblaze_disable_icache();
    microblaze_invalidate_icache();
    return 0;
}
//#else
//int main(void) // ROM downloader. Added checker_rom(); and without some functions.
//{
//    microblaze_invalidate_icache();
//    microblaze_enable_icache();
//    microblaze_invalidate_dcache();
//    microblaze_enable_dcache();
//
//    eeprom_access_mode = I2C_ACC_COMMON;
//
//    gige_init(0, XPAR_EPC_0_PRH0_BASEADDR, DEV_MODE_TX, XPAR_CPU_M_AXI_DP_FREQ_HZ,
//              PHY_NBASET_MRVL, 0x00, 2500000, 0, SCPS_MAX, DBG_ICMP);
//
//    gige_set_gev_version(2);
//    framebuf_init(1, 0, 0, 0x06000000);
//    framebuf_control |= FRAMEBUF_C_EXTSTAT;
//    func_printf("[UU] Running in GEV 2.1 mode\r\n");
//
//    gige_print_header();
//    execute_cmd_psel(func_test_pattern); // dskim - 21.03.19 - "wtp" 명령어 이후 수행될 경우 v 이미지 일부 반전되는 현상 발생
//    execute_cmd_pmode(func_sync_source); // dskim - 21.03.19 - "wtp" 명령어 이후 수행될 경우 v 이미지 일부 반전되는 현상 발생
//    execute_cmd_smode(func_shutter_mode);   // preventing bcal fail during init 211101mbh
//    REG(ADDR_FRAME_TIME) = 0; // 211101
//
//    flash_enter4b();
//    // load_flash();
//    // fpga_init();
//    // func_init();
//    // user_init();
//    disp_cmd_rtime();
//
//    u32 once = 0;
//    while (1)
//    {
//        gige_callback(0);
//        user_callback();
//        uart_command();
//        checker_rom(); //  if putout the rom board, flash_enter4b() gige_spi_gcsr dose not give a response. 211116
//        if (once == 4 )
//        {
//            m88x33xx_inity(RXAUI); //# 220628mbh
//            disp_cmd_rtime();
//            once++;
//        }
//        else if (once == 5)
//        {
//            u32 gige_status = (gige_gcsr & 0x03);
//            if (gige_status==1 || gige_status==3)
//                REG(ADDR_LED_CTRL) = LED_CTRL_OFF; // boot led off 221018 mbh
//            else
//                REG(ADDR_LED_CTRL) = LED_CTRL_ON;
//            once++;
//            disp_cmd_rtime();
//        }
//        else if (once == 7)
//        {
//           if (XREG(XGIGE_ADDR_IP))
//            {
//            once++;
//            // func_printf("ip connetec!\r\n");
//            }
//        }
//        else if (once == 5000)
//        {
//           if (XREG(XGIGE_ADDR_IP))
//           {
//                m88x33xx_init(RXAUI); //# 220628mbh
//                once++;
//           }
//        }
//                else if (once<60000)
//                 once++; //220118mbh
//    }
//
//    // Never reached exit
//    microblaze_disable_dcache();
//    microblaze_invalidate_dcache();
//    microblaze_disable_icache();
//    microblaze_invalidate_icache();
//    return 0;
//}
//#endif;

/******************************************************************************/
// 수정사항
// v1.00.02 - 2020.10.28
// -. ADI 1차 반영
//
// v1.09.02 - 2021.03.09
// 1. offset 먼저 subtraction 하도록 변경 - FPGA
// 2. ADI v0.07.13 까지 반영
//         NUC Gain  NUC Offset Sub Offset
//         0x00CC  0x0050  0x023C
//  Gain 'Off' Offset 'On'  0   0   1
//  Gain 'On'  Offset 'On'  1   1   1
//  Gain 'On'  Offset 'Off'  1   1   0
//  Gain 'Off' Offset 'Off'  0   0   0
// 3. get_ddr_frame_avg_offset() 함수 버그 수정
// -. Offset Address 연산 수정
// 4. Gain Calibration 연산 시 Offset 값 업데이트 되지 않도록 수정
//
// v1.11.03 - 2021.03.25
// 1. EXT4343R, EXT1616R TI 버전 Merge.
// 2. 부팅시 "wtp" 명령어에 의해서 roic 설정이 되도록 변경함
// 3. roic_settimingprofile() 함수에 gain 값 초기화 되지 않도록 변경
// 4. func_test_pattern, func_sync_source 초기화 하도록 변경, v 틀어지는 현상 개선
// 5. NUC, Ref. Image 선택하여 저장할 수 있도록 Define 추가.
// 6. 부팅 시퀀스 변경. Flash 데이터를 초기에 읽을 경우 DDR 쓰기 오류 현상 발생.(원인은 파악 못함)
// 7. GEV_EVENT_DEBUG_MSG 메시지 추가.
// 8. get_nuc_param() 함수에서 Offset 빼지않고, 전체 평균 데이터를 빼도록 변경.(추가 테스트 필요)
// 9. defect map 지워지지 않도록 수정함
// 10. execute_cmd_read_defect() factory map 읽는 동작 버그 수정
//
// mbh 2021.04.02
// 1. diag, bcal 명령어 추가
// 2. diag용 fpga 레지스터 다수 추가
// 3. 고온에이징 용으로 온도변화시에도 bit align 안하도록 수정
// 4. defect initial value : 0->ff
// 5. fpga defect read from bram : "cdot 1 10"
//
// v1.13.05 - 2021.04.08
// 1. Unicomp. Clear Reference -> Save to memory 동작 예외 처리.
// 2. func_frate_max 계산 관련 컴파일 오류 수정
// 3. Read Defect(Manual) 버그 수정
// 4. Gain Calibration 예외 처리
//
// v1.13.06 - 21.04.09
// 1. Offset 연산 값을 100에서 400으로 변경함.
// -. 기본 값을 400으로 하였으며, 전역 변수 처리하여 확장성을 고려함.
//
// v1.13.07 - 21.04.12
// 1. Defect Row, Column 0일 경우 0x00ffffff 설정되도록 변경
// 2. Binning mode에 따라서 Gain 값 변경
// 3. EXT1616R 기본 1.2pC으로 설정
//
// v1.13.08 - 21.04.14
// 1. Factory Map 저장 오류 수정
//
// v1.14.08 - 210423 mbh
// 1. DIC extr1616r 2대, 1616rm 2대 출하
//
// v1.15.09 - 210512 mbh
// 1. DIC ext1616r"L" 버전 2대 출하용
// 2. Global shutter & Trigger mode
//     Total reset을 사용하지 않고 serial reset을 사용하도록함
//     reg_ext_trig_active를 0으로 수정하여 입출력이 active high 동작하도록 설정함
//     trigger가 일단 HW,FPGA 검증되었고 FW, EXTR 수정해야 할 부분이 있음
//
// v1.15.10 - 210512 mbh
// 1. global shutter reg를 셋팅안하도록함
//  void execute_cmd_smode(u32 data) REG(ADDR_SHUTTER_MODE)=0;
// v1.15.11 - 210526 mbh
//  1. write flash by fpga, use function execute_cmd_bwns
//  2. global time setting to reg_sext(0x21c), use function execute_cmd_gewt
//
// v1.16.12 - 210708 dskim
// 1. EXT4343RC/EXT4343RCL 파생 모델
//
// v1.16.13 - 210712
// 1. UART_CMD_debug() 함수 추가.
// -. Read Current User Setting(Debug)
//
// v1.16.14 - 210722
// 1. roic_settimingprofile() 설정이 가능하도록 Profile_Def 구조체 추가.
// 2. execute_cmd_wns() 진행률 표시되도록 함. 버그수정
// 3. flash 기록 도중 stop 기능 추가. 추후 API 연동 필요.
//
// v1.16.15 - 210817 bhmoon
// 1. 연속 line defect 가능하도록 추가.
// 2. CsI Defect 이슈로 예외처리 해제 - 21.08.18
//
// v1.16.16 - 210909 dskim
// 1. CSI는 Auto Defect에서 Edge Cut 적용
// 2. Ver. 체계 변경
// -.  V1.xx.xx = TI GADOX
// -.  V2.xx.xx = TI CSI
//
// v1.16.17 - 210924 dskim
// 1. Edge Cut 적용
// 2. Defect 연속된 3줄 적용시 에러 처리
// 3. Defect 최대 저장 값을 벗어날 경우 에러 처리.
// 4. Factory Map 영역 사용하지 않도록 수정
//
// v1.17.18 - 211007 dskim
// 1. EXT2832R 프로젝트 통합
// 2. DNR, ACC 기능 추가 -  문책임님
//
// v1.17.19 - 211020 dskim
// 1. ACC, Edge, DNR XML 연동
// 2. Edge Cut XML 연동
//
// v1.17.19 - 21.10.25 dskim
// 1. Global Shutter MIN, MAX EWT 수정
//
// v1.17.19 - 21.10.26 dskim
// 1. Edge cut bottom, right 1필셀 누락 오류 수정
// 2. EXT2832R NUC info 주소 변경
//
// v1.17.19 - 21.10.27 dskim
// 1. Row, Column Defect 좌표계산 오류 수정
//
// v1.18.20 - 21.11.03 dskim
// 1. Defect 갯수가 많을 경우 연상 속도 이슈로 위치 옮김
//
// v1.18.21 - 21.11.04 bhmoon
// 1. 부팅시 먼저 ethernet conn되는 문제로 ether를 나중에 붙도록 변경
//
// v1.18.22 - 21.11.05 bhmoon
// 1. 국내 쎄크 요청, api_ext_trigger fpga, xml 추가
//
// v1.18.23 - 21.11.10 bhmoon
// 1. 온도 ic 변경 지원
//  DS1731 -> NCT175
//
// v1.18.24 - 21.11.17 bhmoon
// 1. flash, eeprom hotswap 초기화 명령어 추가
//  "ROM" & "ROM 1"
// 2. ROMDOWNLOADER select main()
//
// v1.18.25 - 21.11.23 bhmoon
// 1. 부팅시 비디오가 roi에서 안도는 버그 검토
//    "rsm" 3,4,5 추가
//     ila추가한 FPGA에서는 증상이 재현이 안됨
// 2. execute_cmd_brns에서 prevent 0-1
//
// v1.18.26 - 21.12.01 dskim
// 1. xil_printf wrapping 함수
// 2. SW Debug MSG On/Off xml 연동
//
// v1.18.27 - 21.12.06 dskim
// 1. Dynamic, Static Mode 추가
//
// v1.18.28 - 21.12.07 bhmoon
// 1. printf \n\r -> \r\n
// 2. tfrate : ext 시그날 테스트 커맨드 num 추가
// 3. AVG시 busy 해제, Calibe시 Acquisition stop 활성화.
//    - FPGA가 EWT중에도 stop으로 동작 해제가능
//
// v1.18.28 - 21.12.08 bhmoon
// 1. Added average frame counter read
// 2. Modified avg printf
// 3. rsm 6 avg
//
// v1.18.29 - 21.12.08 bhmoon
// 1. avg stop condition changed for getting offset err at booting ((outen0==1)&&(outen1==0))
//
// v1.18.30 - 21.12.10 bhmoon
// 1. flash_alloc_set(); position change at roi
// 2. api trigger toggle.
// 3. xml name update. kds
//
// v1.18.31 - 21.12.10 bhmoon
// 1. fpga nuc bit cut error fix -- 211210
// 2. api_trigger ->  force 0    -- 211210
// 3. FPGA wddr ch0 over address bug fix.  -- 211213
// 4. ddr ch0 disable when changing size.  -- 211213
// 5. advanced rsm -- 211214
// 6. fpga roic_cnt change --211216
// 7. bcal print, 4343r ROIC_NUM:13->12
// 8. bcal value check
//
// v1.18.32 - 22.01.05 dskim
// 1. global shutter 모드에서는 frate, gewt가 계산되도록 변경 (dskim 미완성..)
//
// v1.18.33- 22.1.5 bhmoon
// 1. added function execute_cmd_extrst. it for SEC.
// 2. Improving FPS at global EXT1-mode for SEC.
// 3. EXT1-mode can take a value of EWT or FPS.
//
// v1.18.34- 22.1.11 bhmoon
// 1. Ext1 - Timer reset mode check static mode --  func_exposure_type
// 1. Each shutter/trigger mode have an EWT/FPS and keeping.
//
// v1.18.34 - 22.01.13 dskim
// 1. TFT(Panel) SN 초기화 되지 않도록 Flash 영역 별도로 분리함.
// 2. XML_CALIB_CMD 레지스터 리턴 값 변경. func_calib_cmd
//  -. Write Defect 놓치는 현상 관련, API 동기화
//
// v1.18.34 - 22.01.13 bhmoon
// 1. 부팅후 trig_mode 변경이 안되는 fw버그 수정
//   -. 초기모드는  rom부팅값으로 trig1인데 trig_prev는 초기 0 으로 생기는 문제
//   -. 쎄크에서 발생하여 v1.18.33_r0로 다시 업데이트함
// 2. SEC에서 발생한 DDR_CH_EN 0 문제 수정 220114
//  -. func_cmd.c - execute_cmd_roi - reg(ADDR_DDR_CH_EN)=0; 주석
//
// v1.18.34 - 22.01.13 bhmoon
// 1. static모드 트리거 동작중에 중지 시키면 시간이 0으로 리렛되는 문제 수정
//   -. out_en을 체크해서 빠져나오도록 추가
//   -. execute_fw_ext_trig_rst - if (REG(ADDR_OUT_EN)==0)
//
// v1.18.35 - 22.01.18 bhmoon
// 1. extr에서 bcal명령어를 하면 반복오류남.
//  -. bcal1 명령어를 만듦
// 2. 온도 10도 변화시만다 bcal 하는것을 명령으로 안하도록 추가
//  -. tempbcal 0:off 1:on -- default 1
// 3. Fault LED를 fw가 조정하도록 변경
//  -. 초기 부팅시 깜박거리고 ethernet케이블 연결 여부에따라 on/off 함 ADDR_LED_CTRL
// -. main , user_callback 함수에 추가
//
// v1.18.36 - 22.01.19 dskim
// 1. Static Mode에서 AVG 활성화 기능 추가.
//  -. 기존에는 API에서 자동으로 활성화 하였으나 FW에서 하도록 변경
// 2. frame, ewt 동작변경 220120mbh
//  -. API에서 초기값을 가지고 있으나 값을 fw가 모드별로 값을 가지도록 변경
//  -. frame rate버튼이나 비활성 apply에서는 xml에서 입력이 denied 되도록 추가함
// 3. Frate계산 -> ewt계산으로 변경
// 4. smode를 rolling했을때 강제로 tmode 0 freerun으로 셋팅함
// 5. binning+roi 작은화면 했을때 frame rate 계산하면 -ewt가 나오는 부분 보완 calc_gewt  220124mbh
// 6. execute_cmd_frate2ewt에도 scan_time_us 계산부분 추가
// 7. roi offset 했을때 시간 계산 안맞는 부분 일부 조정 220211mbh
//
// v1.18.37 - 22.02.22 bhmoon
// 1. 2832세트에서 bcal로 회복되는 반작이 노이즈 발생
//    -. grab일때 bcal 하도록 추가
//    -. bcal 온돈 범위를 10도에서 8도로 조정
//
// v1.18.38 - 22.03.18 bhmoon
// 1. sleep, wake
//    -. 온도 최적화를 위한 sleep, wake 추가
//    -. 이더넷 connect 상태로 wake, sleep 결정 func_sleep
// 2. fpga. acc auto reset update
/******************************************************************************/

// v1.xx.40 - 22.04.40 dskim
// 1. Sleep Mode API 연동
// 2. FW Version 관리 변경. 부팅시 FPGA Version 확인하여 병합함.
//
// v1.xx.41 - 22.04.41 bhmoon
// 1. 810R 모델 추가
// 2. 810R에서 사용하는 DAC 명령어 추가
// 3. acc빠른 프레임에서 acq탭을 누르면 acc화면이 갈라지는 문제 개선 //# 220402 bhmoon
// 4. acc탭누를때마다 커맨드가 와서 acc리셋되는 문제 개선
// 5. acc auto reset 체크하고 프레임을 눌러줘야 업데이트 되는 문제 개선
// 6. brns를 auto로 하지 않고 트리거 줘서 해야할 듯
//  -. //# manual address increment change //# 220512mbh
// 7. xml 프린트 디버깅용 DEBUGXML_PRINT //# 220516
// 8. bw_align()을 sleep에서 나올때 하는데 화면에 가비지 나오는 문제 개선
// 9. bw_align() 속도개선은 FPGA에서 wait time 안하도록 함
//
// v1.xx.42 -- 220517dskim
// 1. API에서 GEVInitXml() 에러 발생시 phy reset 하도록 변경
// -. XML_RESET_DEVICE 호출
// -. xml 에 XML_RESET_DEVICE이 추가되면서 먼저있던 XML_SLEEP_MODE, XML_IMAGE_ACC_AUTO_RESET 주소밀림
// 2. 부팅시 offset 두번 잡는 문제 수정
// -. func_calib_cmd = 0; //# prevent double getting offset 220519
// 3. 810 roic 64 pixel reverse execute_cmd_wroic(0x11, 0x8400);
// 4. pwdac high limite, level -> volt
// 5. add "rstdev" command for phy ic reset.
// 6. 810r init str system_config(void)
// 7. m88x33xx_deinit(); //# force phy init again //#220530
//
// ** 출하가 있을 경우에만 펌웨어 버전 증가하도록 변경
// ** 베타 버전일 경우 b1.. b2로 표기하도록 변경
// ** 최종 검증이 되면 fw 버전 증가하도록 !!
//
// v1.xx.40b1 -- 220602dskim
// 1. 고객이 동영상 디텍터를 얼마나 사용하는지 정량적으로 확인하기 위함.
//  1) 부팅 횟수
// -. API 연결하지 않아도 부팅 후 1회 증가.
//  2) 촬영 횟수
//  -. Grab, Stop 1회 증가
//  3) 촬영 시간
//  -. Grab, Stop 후 시간 증가
// 2. SW Correction에서 HW Correction으로 변경할 경우 Gain 값 초기화되지 않는 현상 수정
//
// v1.xx.40b2 -- 220603bhmoon
// 1. sleep command mistake
//   - fpga_set_sleep() REG(ADDR_TOPRST_CTRL) = 8;
//
// v1.xx.41.03 -- 220609bhmoon
// 1. fw sub version added
// 2. bcal result display bug fix
//
// v1.xx.41.04 -- 220613bhmoon
// 1. release 41.41
//
// v1.xx.42.01 -- 220620bhmoon
// 1. Ethernet connection xml error complement
//  1) 부팅 후 처음 ip올라온 후에 커넥션 리셋을 한번함
//  2) 4초정도 시간이 추가됨
//  3) API에서는 구조적으로 보완이 어려움

// v1.xx.43.03 -- 220620bhmoon
// 1. GigE license 체크해서 version에 표기
// 2. if(gige_get_license_checksum()==0xFFFF)
// 3. Ethernet Reconnection process changed //# 220628
//
// v1.xx.44.04 -- dskim -- 22.07.18
// 1. execute_cmd_bmode_gain_force(func_binning_mode); 주석처리.
// -. API SW Correction 기능으로 추가되었으나, NUC 저장 후 Gain이 되돌아가는 현상으로 기능 제거, API 업데이트 필요
//
// v1.xx.45.01 -- bhmoon -- 22.07.26
// 1. roic gain 0.3pc를 0값으로 할당, execute_cmd_ifs
// 2. diag후에 eth phy ic셋팅 제거 -> ex> ip 1 에서 phy ic 셋팅
//
// v1.xx.46.01 -- dskim -- 22.07.28
// 1. HW/SW Correction 변경시 Analog Gain변경되지 않는 이슈 수정
// 2. 누적 동작시간 기능, 분 계산오류 수정
// 3. 프로그램 종료 시 안정화 기능 추가. 테스트 중
//
// v1.xx.46.02 -- bhmoon -- 22.07.28
// --# 디버깅용 마이너 업데이트
// 1. mclk명령 후 bcal 하도록 추가.
//
// v1.xx.47.01 -- dskim -- 22.07.28
// 1. execute_cmd_grab msdelay(100);=> msdelay(1000);
//     4343r 냉간부팅후 디스커넥션했을때 fw다운되는 문제 방지
//      커넥션 끈겼을때 callback을 여러번도는것이 문제로 추정
//
// v1.xx.48 -- dskim -- 22.09.01
// 1. execute_cmd_grab 딜레이를 1000ms 변경할 경우 1fps 이하에서 커넥션 타임아웃이 발생함.
// gige_callback() 함수를 늦게 호출하여 발생하는 이슈.
// 시스템 다운되는 EXT4343R 모델에만 딜레이를 변경하고, 이전 모델은 원안대로 복원함
//
// v1.xx.49 -- bhmoon -- 22.08.09
// 1. width 스핑크스, API로 변경 안되는 문제
//     #define MIN_WIDTH  1->128 아마 테스트용으로 '1'로 되었던거같은데 128로 돌림
//     #define MIN_HEIGHT 1-> 128 왜 4의배수여야하는지는 확실지 않지만 gige에서 계산하는듯
//
// v1.xx.50 -- bhmoon -- 22.09.01
// 1. 4343RC Novatech gate
//     roic_str setting register added at fpga
//     timing value modified by roic_str
//
// v1.xx.50 -- dskim -- 22.08.09 - SVN:rev111
// 1. 온도 센서 2개 추가. - XML 추가
//     SVN Commit 실수로 내용 기입 못함
//
// v1.xx.51 -- dskim -- 22.09.19
// 1. factory map 지워지지 않는 문제 수정
//    21까지는 factory map를 사용했으나, Manual map으로 모두 통합함.
//    호환성을 위하여 factory map도 지워지도록 하였으나, check 함수 버그로 지워지지 않았음. 수정완.
//
// v1.xx.52 -- dskim -- 22.09.21
// 1. XML_SW_CALIB_MODE 기능 추가
//
// v1.xx.53 -- 220923mbh
// 1. Flash recovery func add
//  command "fch" is key
//  bootloader also edited
//
// v1.xx.54 -- 220927dskim
// 1. SW Gain을 사용할 경우 NUC 정보 불러오지 않도록 수정.
// 2. HW Gain 정보를 불러오는XML 프로토콜 추가
//     Gain 정보를 불러올 경우, fw에서 callback 응답을 할 수 없음. 네트워크 연결해제되는 현상발생.
//     API에서 네트워크 연결 해제되지 않도록 요첨.
//
// v1.xx.55 -- 220928mbh
// 1. Flash brns optimazation
//  time check.
// 2. "dmesg" boot log
// 3. execute_cmd_brns() 두번 이상 호출하지 않도로 수정 - dskim - 22.09.29
// 4. Boot fail by flash hang. //# 220929mbh
//     flash copy error -> DELAY_FWB; added delay
//     flash_done(); can not make recover flash error
// 5. added command flash4b for rom write  //# 220930
// 6. fail write block -> return ; ERROR == flash_done()  //# 220930
//
// v1.xx.56 -- 221013mbh
// 1. added roic test pattern  in "psel 16" command. - execute_cmd_psel
// 2. added preview2 command "-" is prepre "=" is pre.
//
// v1.xx.57 -- 221018mbh
// 1. added ROIC test pattern list on XML
// 2. removed flash_alloc_set() function in execute_cmd_roi().  --############### FLASH #####################
//  it might be a kill point.
// 3. cali hw load abnormal debugging. #221021
// 4. reduce callback time while reading NUC. sv03
//  execute_cmd_brns if((i & 0x3FFFF)==0) //# 250ms //#221021
//
// v1.xx.58 -- 221020mbh
// 1. model name list change

/*
 " Old history moved to end of page " 230510mbh
######### version ########
v1.xx.60 -- 221104
 1. version system changed
 2. HW version added
 3. 0.3 step gain for SEC, execute_cmd_ifs #221109
 4. cmd "fpgareboot"  #221110
 5. static mode min 500ms -> 0ms; execute_cmd_emax
  execute_fw_ext_trig_rst
      func_insert_rst_num 10-> 1
  execute_cmd_exposure_type

v1.xx.61 -- 221207
 1. factory map mode chuga. dskim
 2. acc momory address position changed : ADDR_AVG_DATA_DOSE6 -- rollback #
 3. gain value shift, it was table : execute_cmd_bmode_gain #
 4. gain shift -> * / for 3x3. execute_cmd_bmode_gain #

v1.xx.62 -- 230117
 1. 10G gain - get_nuc_para4

v1.xx.63 -- 230203
 1. 10:30 2430T - 10g model generation completed.
 2. 16:00 810R volt limit 1000V->1200
 3. boot on, ewt 0 calc.

v1.xx.64 -- 230317
 1.  FLASH_NUC_INFO_BASEADDR 0x39F0000 -> calculated address
  - symptoms : get NUC, save and power reset then some long black line exist at gain nuc.
 2. flash.c lin331 flash_addr_incr += (16 - (4*(nun_num))); => ddr_addr_incr
 3. case XML_BUSY : return func_busy | REG(ADDR_FW_BUSY); //# 230322
  ui check busy also fpga fw busy.

v1.xx.65 -- 230327
 1. except edge for average data.
  get_ddr_frame_avg
 2. xml read for XML_GAINREF_NUMLIM, 2p5G is 4, 10G is 1
  func_gainref_numlim
 3. added command "wtp 1" is timig profile selection //# 230329
 4. 0.3p gain load error when boot 230411
 //# ifs set all routine. #230411
 5. binn mode gain support 0.3 value

v1.xx.66 -- 230512
 1. hoseo univ. res.270x220 fps error #230512
     reduce gate dummy cpv time
      GATE_CPV_PERIOD  3.36 => 0.55
 2. "func_frate_max_calc; //# test 230512" test for ext1 fps check
 3. execute_cmd_frate2ewt //# 230516
 4. "(func_frate_max_model>func_frate_max_calc) ? func_frate_max_calc : func_frate_max_model;"
 5. ext trig delay add
      " execute_api_ext_trig "
      " msdelay(1); //# delay #230517 "
 6. integ mode & 0.3 gain BUG #230523.11
      execute_cmd_wroic(0x2c, 1); //# 810R integ down bug #230523

v1.xx.67 -- 230621
 1. gain error by changing binning mode
      binn1x1 gain2.4 => binn4x4 gain0.0
      else if(ifs > 15) ifs=15; //# ifs limit #230621
 2. FW_VER added sub fw version.
 3. binning mode access denied message.
 4. diag message remove color, add version
 5. sm_tft =+ Trig ! for SEC debug #230707
 6. release to SEC
 7. execute_cmd_psel_val for test pattern #230717
 8. auth level change to 0, erase is only 2
 9. flat dark roll back, nothing in FW #230721
 10. External1,2 prevent ACC
 11. ADDR_BNC_CTRL add fpga reg
 12. ADDR_OFGA_LIM add fpga reg

 v1.xx.68 --
  1. func_triglog_on 1, for debug log #230809 sec triglog
  2. IMAGE_DATA_HIGH=55000 #230824
  3. command UART_CMD_bnc, UART_CMD_eq
  4. XML_IMAGE_TOPVALUE, XML_FPGA_BNC, XML_FPGA_EQ conn to xml
  5. func_sw_debug = 0, "1" makes HW, FPGA version unreadable.
  6. added UART_CMD_topv
  7. Fix ver XLic malfunction
  8. code clean

 v1.xx.69
 	 0. 10G binn change image vertical rotate, 2430 binn defect bug fix
 	 	 version up 69 for Release version
 	 1. the defect binning line should calculate at fw.
 	  	  hw binning is always divided by 2. 2430 gate dummy is 33
         Cause the gate dummy is odd, an additional calculation is needed to account for the delay in V count when using gate binning.
         " if(GATE_DUMMY_LINE%2) "
     2. oe time reduce for 3x3 binn 10G model, but dont know why
     	 profile.init.tgate = TGATE_1500; //# 230925
     3. added gain, binn, function(acc, dnr) available list
     	 MODEL_FUNC_ABLE
     4. v1.69.69 beta release
     5. 2430RD init volt limit 2000
     6. #23101312 INTERVALX 4->16 FPGA ROI Limit
     7. #23101313 binn calc error fix
         " defectY /= 2; //# bug fix 231013"
     8. #23101313 INTERVALX 16 side effect - not working img size
     	 " value = (int)((MAX_WIDTH/func_binning - func_offsetx) / INTERVALX) * INTERVALX; //# 231013
     	 " func_width = (int)((MAX_WIDTH/func_binning - value) / INTERVALX) * INTERVALX; //# 231013
	 9. #23101313 bug
		"if(MAX_WIDTH/func_binning < value + func_offsetx)
	10. #231017 frame rate limitation by ethernet link
		"ETHERSPEED_B
	11. #231019 Added "romread" command for debuging rom data

  v1.xx.70
  	  1. model define to model read from FPGA.
  	  2. 0x22c => ADDR_ROIC_TP_SEL and " roic_init " REG(ADDR_ROIC_TP_SEL) = 1;
  	  3. init gain value error
  	  	  u32 func_roic_data[16]={0x2200}; -> func_roic_data[0] = 0x2200;
	  4. ext1 mode cann't use ACC but static need to use ACC
	  	  "" if (func_static_avg_enable) //# 231114 acc support for static mode
	  5. INTERVALX-> 16 to 4; 16 has a some problem when changing binning.
	  	  "" #define OFFSINTVX      16 //# 231115

  v1.xx.73
  	  1. all model TIRST_1000 => 2000
  	  2. serial number is removed by blank set.
  	     editing XML fix bug.

  v1.xx.74
  	  1. CDS timing control -> EXT4343RC_2 cross talk
  	  	  => wtp timing 2 2 15 2 -> 3 3 14 2
  	  	  => //$ 241024 cross talk

  v1.xx.75
  	  1. Add 4343R a-Si bit align 1s delay when sleep to wake
		-. msdelay(1000);

  v1.xx.76
  	  1. 1024R use CHARGE INJECTION $241128
  	    -. else if (msame(mEXT1024   )){ //$ 241128 jyp add EXT 1024R to compensate cap.

   v1.xx.77
  	  1. 4343RI_2 change wtp timing
  	    -. //$ 241213 jyp
  	  2. //$ 241213 11 jyp mclk change 200 -> 160
  	  3. 10G gain cal problem. !!!
  	  	  -. //### 24121414 addr4,2

   v1.xx.78
  	  1. hw/sw cali selecting error
  	  	  -. if(!wait5sec_once) //# 241217 not sure needs 5sec wait, but avoid error happen.

   v1.xx.79
  	  1. 1024R is connected 3 roic dclk, excluded from tempbcal.
  	  	  //# 241202 add condition def_tempbcal
  	  	  //# 24120216 load_tempbcal
	  2. //# 24120916 bunri condition
	  3. //# 241230 1024R dclk need bcal once at booting.
	  4. mistake bcal_once position.
	  5. 10G Edge cut error
	  	//$ 250102 10G Edge cut

	v1.xx.80
	  1. //$ 250219 dclk use x => have to debug

	v1.xx.81
	  1. #25031719 //# 250317 load_func_able, 4343r_3 no binning(NT gate) func_able_binn_num F->1
	  2. //# 250317 25->20 :: 10g 25->20 fps, insufficient bandwidth for gain
	  3. SW1.06.81 => //$ 250430 EXT2430RI 0.3pC Data 0 => COMP1 0.045pF
	  4. SW1.07.81 => //$ 250507 EXT2430RI 0.045pF -> 0.122pF
	  5. SW1.08.81 => //$ 250509 EXT1024R 3x3, 4x4 binning X
	  6. SW1.09.81 => //$ 250509 EXT2832R Rolling shutter debug
	  7. SW1.10.81 => //$ 250509 EXT1024R update_data() timing

	v1.xx.82
	  1. SW1.01.82 => //$ 250509 rolling shutter has only free run tmode
	  2. SW1.02.82 => //$ 250514 trig mode error debug

	v1.xx.83
	  1. SW1.01.83 => //$ 250617 ave fail 64->8
	  2. SW1.02.83 => //$ 250620 All model defualt 1.2pC
	  3. SW1.03.83 => //$ 250620 to avoid bit align error when botting.

	v1.xx.84
      1. SW1.01.84 => //$ 250627 Add xml addr to avoid error of defect
      2. SW1.02.84 => //$ 250703 Add model EXT1024RL
	  3. SW1.03.84 => //$ func_sleepmode rollback 2->3
	  4. SW1.04.84 => //$ 250806 Add model EXT4343R_4 & EXT4343RI_4
	  5. SW1.05.84 => //$ 250812 ave fail 8->64

	v1.xx.85
	  1. SW1.01.85 => //$ Offset/Gain Image count 128 -> 512


*/
