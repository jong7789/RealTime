#define TESTAPP_GEN
/******************************************************************************
* Copyright (C) 2020 - 2022 Xilinx, Inc. All rights reserved.
* Copyright (c) 2022 - 2023 Advanced Micro Devices, Inc. All Rights Reserved.
* SPDX-License-Identifier: MIT
******************************************************************************/

/*****************************************************************************/
/**
*
* @file xclk_wiz_intr_example.c
*
* This file contains a design example using the XClk_Wiz driver with interrupts
* it will generate interrupt for clok glitch, clock overflow and underflow
* The user should have setup with 2 clocking wizard instances, one instance act
* as clocking monitor (Enable clock monitor in GUI), In another instance enable
* dynamic clock reconfiguration. In the present example XCLK_WIZ_DYN_DEVICE_ID
* assigned to clock wizard 1. Modify this value as per your dynamic clock
* reconfiguration Clocking wizard
*
* @note		This example requires an interrupt controller connected to the
*		processor and the MIPI CLK_WIZ  in the system.
* <pre>
* MODIFICATION HISTORY:
*
* Ver Who Date   Changes
* ----- ---- -------- -------------------------------------------------------
* 1.0 ram 2/12/16 Initial version for Clock Wizard
* 1.1 ms  01/23/17 Modified xil_printf statement in main function to
*                  ensure that "Successfully ran" and "Failed" strings are
*                  available in all examples. This is a fix for CR-965028.
* 1.6 sd 7/7/23    Add SDT support.
* </pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xclk_wiz.h"
#include "xil_printf.h"
#include "xil_types.h"
#include "xparameters.h"
#include "xstatus.h"
#ifdef XPAR_INTC_0_DEVICE_ID
 #include "xintc.h"
 #include <stdio.h>
#else
 #include "xscugic.h"
 #include "xil_printf.h"
#endif

#include "func_printf.h"
#include "fpga_info.h" // mbh
 #include "func_printf.h"

#ifdef SDT
#include "xinterrupt_wrap.h"
#endif
/************************** Constant Definitions *****************************/

/*
* The following constants map to the names of the hardware instances.
* They are only defined here such that a user can easily change all the
* needed device IDs in one place.
*/
#ifndef SDT
#define XCLK_WIZ_DEVICE_ID		XPAR_CLK_WIZ_0_DEVICE_ID

#ifdef XPAR_INTC_0_DEVICE_ID
 #define XINTC_CLK_WIZ_INTERRUPT_ID	XPAR_INTC_0_CLK_WIZ_0_VEC_ID
 #define XINTC_DEVICE_ID	XPAR_INTC_0_DEVICE_ID
#else
 #define XINTC_CLK_WIZ_INTERRUPT_ID	XPAR_FABRIC_AXI_CLK_WIZ_0_INTERRUPT_INTR
 #define XINTC_DEVICE_ID	XPAR_SCUGIC_SINGLE_DEVICE_ID
#endif /* XPAR_INTC_0_DEVICE_ID */

/*
* change the XCLK_WIZ_DYN_DEVICE_ID value as per the Clock wizard
* whihc is setting as dynamic reconfiguration. In the present
* example clokc wizard 1 configured as clock wizard 1 as dynamic
* reconfigurable parameter
*/
#define XCLK_WIZ_DYN_DEVICE_ID		XPAR_CLK_WIZ_0_DEVICE_ID
#endif

/*
* The following constants are part of clock dynamic reconfiguration
* They are only defined here such that a user can easily change
* needed parameters
*/

#define CLK_LOCK			1

/*FIXED Value */
#define VCO_FREQ			600
#define CLK_WIZ_VCO_FACTOR		(VCO_FREQ * 10000)

 /*Input frequency in MHz */
#define DYNAMIC_INPUT_FREQ		100
#define DYNAMIC_INPUT_FREQ_FACTOR	(DYNAMIC_INPUT_FREQ * 10000)

/*
 * Output frequency in MHz. User need to change this value to
 * generate grater/lesser interrupt as per input frequency
 */
#define DYNAMIC_OUTPUT_FREQ		175
#define DYNAMIC_OUTPUT_FREQFACTOR	(DYNAMIC_OUTPUT_FREQ * 10000)

#define CLK_WIZ_RECONFIG_OUTPUT		DYNAMIC_OUTPUT_FREQ
#define CLK_FRAC_EN			1

#define inclk  1000  // 100Mhz * 10
#define fbclkunder  6000 // 600Mhz * 10
u32 fbmul = 48;
u32 fracmultiply = 0;
u32 fbdiv = 5;
u32 clk0div = 48;
u32 clk0frac = 0;
u32 clk1div = 4;


#ifndef SDT
#ifdef XPAR_INTC_0_DEVICE_ID
 #define XINTC_DEVICE_ID	XPAR_INTC_0_DEVICE_ID
 #define INTC		XIntc
 #define INTC_HANDLER	XIntc_InterruptHandler
#else
 #define XINTC_DEVICE_ID	XPAR_SCUGIC_SINGLE_DEVICE_ID
 #define INTC		XScuGic
 #define INTC_HANDLER	XScuGic_InterruptHandler
#endif /* XPAR_INTC_0_DEVICE_ID */
#endif


/***************** Macros (Inline Functions) Definitions *********************/


/**************************** Type Definitions *******************************/


/************************** Function Prototypes ******************************/

#ifndef SDT
//u32 ClkWiz_IntrExample(INTC *IntcInstancePtr, u32 DeviceId, u32 clk0khz, u32 clk1khz);
u32 ClkWiz_IntrExample( u32 DeviceId, u32 clk0khz, u32 clk1khz);

int SetupInterruptSystem(INTC *IntcInstancePtr, XClk_Wiz *ClkWizPtr);
#else
u32 ClkWiz_IntrExample(UINTPTR BaseAddress);
#endif
void XClk_Wiz_IntrHandler(void *InstancePtr);
void XClk_Wiz_InterruptEnable(XClk_Wiz *InstancePtr, u32 Mask);
int Clk_Wiz_Reconfig(XClk_Wiz_Config *CfgPtr_Dynamic);
int Wait_For_Lock(XClk_Wiz_Config *CfgPtr_Dynamic);

/* Interrupt helper functions */
void ClkWiz_ClkOutOfRangeEventHandler(void *CallBackRef, u32 Mask);
void ClkWiz_ClkGlitchEventHandler(void *CallBackRef, u32 Mask);
void ClkWiz_ClkStopEventHandler(void *CallBackRef, u32 Mask);

/************************** Variable Definitions *****************************/
XClk_Wiz ClkWiz_Mon;   /* The instance of the ClkWiz_Mon */
XClk_Wiz ClkWiz_Dynamic; /* The instance of the ClkWiz_Dynamic */
//XIntc InterruptController;  /* The instance of the Interrupt Controller */

volatile u8 Clk_Outof_Range_Flag = 1;
volatile u8 Clk_Glitch_Flag = 1;
volatile u8 Clk_Stop_Flag = 1;

#ifndef SDT
INTC Intc;
#endif

#define DBG_clk 0
/************************** Function Definitions *****************************/

/*****************************************************************************/
/**
*
* This is the Wait_For_Lock function, it will wait for lock to settle change
* frequency value
*
* @param	CfgPtr_Dynamic provides pointer to clock wizard dynamic config
*
* @return
*		- Error 0 for pass scenario
*		- Error > 0 for failure scenario
*
* @note		None
*
******************************************************************************/
int Wait_For_Lock(XClk_Wiz_Config *CfgPtr_Dynamic)
{
	u32 Count = 0;
	u32 Error = 0;

     /*DEB*/ if (DBG_clk) func_printf("[DBG_clk] Wait_For_Lock\r\n");
	while(!(*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK)) {
		if(Count == 10000) {
			Error++;
                /*DEB*/ if (DBG_clk) func_printf("[DBG_clk] Wait_For_Lock Err Break \r\n");
			break;
		}
		Count++;
        }
    /*DEB*/ if (DBG_clk) func_printf("[DBG_clk] Wait_For_Lock return error, %d \r\n", Error);
    return Error;
}

/******************************************************************************/
/**
*
* For Microblaze we use an assembly loop that is roughly the same regardless of
* optimization level, although caches and memory access time can make the delay
* vary.  Just keep in mind that after resetting or updating the PHY modes,
* the PHY typically needs time to recover.
*
* @param	Number of seconds to sleep
*
* @return	None
*
* @note		None
*
******************************************************************************/
void Delay(u32 Seconds)
{
#if defined (__MICROBLAZE__) || defined(__PPC__)
	static s32 WarningFlag = 0;

	/* If MB caches are disabled or do not exist, this delay loop could
	 * take minutes instead of seconds (e.g., 30x longer).  Print a warning
	 * message for the user (once).  If only MB had a built-in timer!
	 */
	if (((mfmsr() & 0x20) == 0) && (!WarningFlag)) {
		WarningFlag = 1;
	}

#define ITERS_PER_SEC   (XPAR_CPU_CORE_CLOCK_FREQ_HZ / 6)
    asm volatile ("\n"
			"1:               \n\t"
			"addik r7, r0, %0 \n\t"
			"2:               \n\t"
			"addik r7, r7, -1 \n\t"
			"bneid  r7, 2b    \n\t"
			"or  r0, r0, r0   \n\t"
			"bneid %1, 1b     \n\t"
			"addik %1, %1, -1 \n\t"
			:: "i"(ITERS_PER_SEC), "d" (Seconds));
#else
    sleep(Seconds);
#endif
}

/*****************************************************************************/
/**
*
* This is the Clk_Wiz_Reconfig function, it will reconfigure frequencies as
* per input array
*
* @param	CfgPtr_Dynamic provides pointer to clock wizard dynamic config
* @param	Findex provides the index for Frequency divide register
* @param	Sindex provides the index for Frequency phase register
*
* @return
*		-  Error 0 for pass scenario
*		-  Error > 0 for failure scenario
*
* @note	 None
*
******************************************************************************/
#define DBG_clk_rec 0
int Clk_Wiz_Reconfig(XClk_Wiz_Config *CfgPtr_Dynamic)
{
    u32 Count = 0;
    u32 Error = 0;
    u32 Fail  = 0;
    u32 Frac_en = 0;
    u32 Frac_divide = 0;
    u32 Divide = 0;
    u32 divclk_divide = 0;
    u32 clkfbout_mult = 0;
    u32 clkfbout_fracmultiply = 0;
//    u32 dummy = 0;

    Fail = Wait_For_Lock(CfgPtr_Dynamic);

     /*DEB*/ if (DEBUG) func_printf("Clk_Wiz_Reconfig 0 \r\n");
    if(Fail) {
    Error++;
        func_printf("\n ERROR4: Clock is not locked for default frequency" \
    " : 0x%x\r\n", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
     }

    /*DEB*/ if (DEBUG) func_printf("SW reset applied 0 \r\n");
    /* SW reset applied */ // it makes halt 210729
//    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x00) = 0xA;
//while ( 0xFFFF < *(u32 *)(0x44A00000) ) {
//  if (dummy%10==0) func_printf("%d reset = %8x \r\n",dummy ,*(u32 *)(0x44A00000) );
//  if (dummy%10==0) func_printf("%d reset = %8x \r\n",dummy ,*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x00) );
//  msdelay(10);
//  dummy++;
//  if (100 < dummy) break;
//
//}
//    func_printf(" reset = %8x \r\n", *(u32 *)(0x44A00000) );
//    if ( 0xFFFF > *(u32 *)(0x44A00000) ) *(u32 *)(0x44A00000) = 0xA;
//    func_printf(" reset = %8x \r\n", *(u32 *)(0x44A00000) );
//    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x00) = 0x0;
//    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x00) = 0xA;

    if(*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK) {
    Error++;
//        func_printf("\n ERROR: Clock is locked : 0x%x \t expected "\
      "0x00\r\n", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
    }

    /*DEB*/ if (DEBUG) func_printf("SW reset applied 1x \r\n");

    Fail = Wait_For_Lock(CfgPtr_Dynamic); // mbh 210115

     /*DEB*/ if (DEBUG) func_printf("Clk_Wiz_Reconfig 1 \r\n");
    if(*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK) {
    Error++;
//        func_printf("\n ERROR5: Clock is locked : 0x%x \t expected "\
      "0x00\r\n", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
    }

//    /* Wait cycles after SW reset */
    for(Count = 0; Count < 2000; Count++);

    Fail = Wait_For_Lock(CfgPtr_Dynamic);
     /*DEB*/ if (DEBUG) func_printf("Clk_Wiz_Reconfig 2 \r\n");
    if(Fail) {
      Error++;
//          func_printf("\n ERROR6: Clock is not locked after SW reset :"
//        "0x%x \t Expected  : 0x1\r\n",
//        *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
//        dummy = *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK;
    }

     /*DEB*/ if (DEBUG) func_printf("Clk_Wiz_Reconfig 2-1 \r\n");
    // ################################## IN FBCLK
    clkfbout_fracmultiply = fracmultiply; clkfbout_mult=fbmul; divclk_divide=fbdiv; // 100*48/5=960 // dskim - 21.03.16
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x200) = \
    (clkfbout_fracmultiply << 16) | (clkfbout_mult << 8) | divclk_divide;
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x204) = 0x00;
    /*DEB*/ if (DEBUG) func_printf("Clk_Wiz_Reconfig 2-2 \r\n");
    // ################################## clock out 0 ####################
        Frac_en = 0; Frac_divide = clk0frac; Divide = clk0div; // 960/48=20 // dskim - 21.03.16
    /* Configuring Multiply and Divide values */
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x208) =
        Frac_en | (Frac_divide << 8) | (Divide);
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x20C) = 0x00;

    if(DBG_clk) func_printf("[DBG_clk] clkfbout_mult=%d \r\n",clkfbout_mult);
    if(DBG_clk) func_printf("[DBG_clk] clkfbout_fracmultiply=%d \r\n",clkfbout_fracmultiply);
    if(DBG_clk) func_printf("[DBG_clk] divclk_divide=%d \r\n",divclk_divide);
    if(DBG_clk) func_printf("[DBG_clk] Frac_divide=%d \r\n",Frac_divide);
    if(DBG_clk) func_printf("[DBG_clk] Divide=%d \r\n",Divide);
    // ################################## clock out 1 #####################
//        Frac_en = 0; Frac_divide = 0; Divide = 4; // 960/4=240
        Frac_en = 0; Frac_divide = 0; Divide = clk1div; // 960/8=120
//        func_printf("[DEBUG] Divide(clk1div) = %d\r\n", Divide);  // dskim - debug
    /* Configuring Multiply and Divide values */
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x214) =
        Frac_en | (Frac_divide << 8) | (Divide);
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x218) = 0x00;

    if(DBG_clk) func_printf("[DBG_clk] Frac_divide=%d \r\n",Frac_divide);
    if(DBG_clk) func_printf("[DBG_clk] Divide=%d \r\n",Divide);

//    *(u32 *)(0x44A0025C) = 0x7; //# very annoying!! 231207
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x25C) = 0x7; //# v2
//    func_printf(" Configuration a = %8x \r\n", *(u32 *)(0x44A0025C) );

    if(*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK) {
    Error++;
    	if(DBG_clk_rec)func_printf("\n ERROR: Clock is locked : 0x%x \t expected "
      "0x00\r\n", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
     }
    msdelay(10);
     /* Clock Configuration Registers are used for dynamic reconfiguration */
     *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x25C) = 0x02;
     msdelay(10);
    Fail = Wait_For_Lock(CfgPtr_Dynamic);
    if(Fail) {
	Error++;
		if(DBG_clk_rec)func_printf("\n ERROR: Clock is not locked : 0x%x \t Expected "\
	": 0x1\n\r", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
    }
	return Error;

    if(DBG_clk_rec) func_printf("[DBG_clk] Error=%d \r\n",Error);
    return Error;
}

int Clk_Wiz_Reconfig_x(XClk_Wiz_Config *CfgPtr_Dynamic)
{
    u32 Count = 0;
    u32 Error = 0;
    u32 Fail  = 0;
    u32 Frac_en = 0;
    u32 Frac_divide = 0;
    u32 Divide = 0;
    float Freq = 0.0;

    u32 divclk_divide = 0;
    u32 clkfbout_mult = 0;
    u32 clkfbout_fracmultiply = 0;
    u32 dummy = 0;

    Fail = Wait_For_Lock(CfgPtr_Dynamic);

     /*DEB*/ if (DBG_clk) func_printf("[DBG_clk] Clk_Wiz_Reconfig 0 \r\n");
    if(Fail) {
	Error++;
	func_printf("\n ERROR: Clock is not locked for default frequency" \
	" : 0x%x\n\r", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
     }

    /* SW reset applied */
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x00) = 0xA;

    if(*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK) {
	Error++;
	func_printf("\n ERROR: Clock is locked : 0x%x \t expected "\
	  "0x00\n\r", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
    }

    /* Wait cycles after SW reset */
    for(Count = 0; Count < 2000; Count++);

    Fail = Wait_For_Lock(CfgPtr_Dynamic);
    if(Fail) {
	  Error++;
	  func_printf("\n ERROR: Clock is not locked after SW reset :"
	      "0x%x \t Expected  : 0x1\n\r",
	      *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
    }

    /* Calculation of Input Freq and Divide factors*/
    Freq = ((float) CLK_WIZ_VCO_FACTOR/ DYNAMIC_INPUT_FREQ_FACTOR);

    Divide = Freq;
    Freq = (float)(Freq - Divide);

    Frac_divide = Freq * 10000;

    if(Frac_divide % 10 > 5) {
	   Frac_divide = Frac_divide + 10;
    }
    Frac_divide = Frac_divide/10;

    if(Frac_divide > 1023 ) {
	   Frac_divide = Frac_divide / 10;
    }

    if(Frac_divide) {
	   /* if fraction part exists, Frac_en is shifted to 26
	    * for input Freq */
	   Frac_en = (CLK_FRAC_EN << 26);
    }
    else {
	   Frac_en = 0;
    }

    /* Configuring Multiply and Divide values */
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x200) = \
	Frac_en | (Frac_divide << 16) | (Divide << 8) | 0x01;
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x204) = 0x00;

    /* Calculation of Output Freq and Divide factors*/
    Freq = ((float) CLK_WIZ_VCO_FACTOR / DYNAMIC_OUTPUT_FREQFACTOR);

    Divide = Freq;
    Freq = (float)(Freq - Divide);

    Frac_divide = Freq * 10000;

    if(Frac_divide%10 > 5) {
	Frac_divide = Frac_divide + 10;
    }
    Frac_divide = Frac_divide / 10;

    if(Frac_divide > 1023 ) {
        Frac_divide = Frac_divide / 10;
    }

    if(Frac_divide) {
	/* if fraction part exists, Frac_en is shifted to 18 for output Freq */
	Frac_en = (CLK_FRAC_EN << 18);
    }
    else {
	Frac_en = 0;
    }

    /* Configuring Multiply and Divide values */
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x208) =
	    Frac_en | (Frac_divide << 8) | (Divide);
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x20C) = 0x00;

    /* Load Clock Configuration Register values */
    *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x25C) = 0x07;

    if(*(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK) {
	Error++;
	func_printf("\n ERROR: Clock is locked : 0x%x \t expected "
	    "0x00\n\r", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
     }

     /* Clock Configuration Registers are used for dynamic reconfiguration */
     *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x25C) = 0x02;

    Fail = Wait_For_Lock(CfgPtr_Dynamic);
    if(Fail) {
	Error++;
	func_printf("\n ERROR: Clock is not locked : 0x%x \t Expected "\
	": 0x1\n\r", *(u32 *)(CfgPtr_Dynamic->BaseAddr + 0x04) & CLK_LOCK);
    }
	return Error;
}


/*****************************************************************************/
/**
*
* This is the main function for XClk_Wiz interrupt example. If the
* ClkWiz_IntrExample function which sets up the system succeeds, this function
* will wait for the interrupts. Notify the events
*
* @param	None.
*
* @return
*		- XST_FAILURE if the interrupt example was unsuccessful.
*
* @note		Unless setup failed, main will never return since
*		ClkWiz_IntrExample is blocking (it is waiting on interrupts
*		for Hot-Plug-Detect (HPD) events.
*
******************************************************************************/
//#ifndef TESTAPP_GEN
//int main()
//{
//	u32 Status;
//
//	xil_printf("------------------------------------------\n\r");
//	xil_printf("CLK_WIZ Monitor interrupt example\n\r");
//	xil_printf("(c) 2016 by Xilinx\n\r");
//	xil_printf("-------------------------------------------\n\r\n\r");
//
//#ifndef SDT
//	Status = ClkWiz_IntrExample(&Intc, XCLK_WIZ_DEVICE_ID);
//#else
//	Status = ClkWiz_IntrExample(XPAR_CLK_WIZARD_1_BASEADDR);
//#endif
//	if (Status != XST_SUCCESS) {
//		xil_printf("CLK_WIZ Monitor interrupt example Failed");
//		return XST_FAILURE;
//	}
//
//	xil_printf("Successfully ran CLK_WIZ Monitor interrupt example\n\r");
//
//	return XST_SUCCESS;
//}
//#endif

/****************************************************************************/
/**
*
* This function setups the interrupt system such that interrupts can occur
* for the CLK_WIZ device. This function is application specific since the
* actual system may or may not have an interrupt controller. The CLK_WIZ
* could be directly connected to a processor without an interrupt controller.
* The user should modify this function to fit the application.
*
* @param	ClkWizPtr contains a pointer to the instance of the CLK_WIZ
*		component which is going to be connected to the interrupt
*		controller.
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None
*
****************************************************************************/
#ifndef SDT
int SetupInterruptSystem(INTC *IntcInstancePtr, XClk_Wiz *ClkWizPtr)
{

	int Status;


	/* Setup call back handlers */
	XClk_Wiz_SetCallBack(ClkWizPtr, XCLK_WIZ_HANDLER_CLK_OUTOF_RANGE,
				ClkWiz_ClkOutOfRangeEventHandler, ClkWizPtr);
	XClk_Wiz_SetCallBack(ClkWizPtr, XCLK_WIZ_HANDLER_CLK_GLITCH,
				ClkWiz_ClkGlitchEventHandler, ClkWizPtr);
	XClk_Wiz_SetCallBack(ClkWizPtr, XCLK_WIZ_HANDLER_CLK_STOP,
				ClkWiz_ClkStopEventHandler, ClkWizPtr);

#ifdef XPAR_INTC_0_DEVICE_ID
	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	Status = XIntc_Initialize(IntcInstancePtr, XINTC_DEVICE_ID);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect a device driver handler that will be called when an interrupt
	 * for the device occurs, the device driver handler performs the
	 * specific interrupt processing for the device.
	 */
	Status = XIntc_Connect(IntcInstancePtr, XINTC_CLK_WIZ_INTERRUPT_ID,\
			   (XInterruptHandler)XClk_Wiz_IntrHandler, \
			   (void *)ClkWizPtr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Start the interrupt controller such that interrupts are enabled for
	 * all devices that cause interrupts, specific real mode so that
	 * the CLK_WIZ can cause interrupts through the interrupt controller.
	 */
	Status = XIntc_Start(IntcInstancePtr, XIN_REAL_MODE);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Enable the interrupt for the CLK_WIZ.
	 */
	XIntc_Enable(IntcInstancePtr, XINTC_CLK_WIZ_INTERRUPT_ID);

#else
	XScuGic_Config *IntcConfig;

	/*
	 * Initialize the interrupt controller driver so that it is ready to
	 * use.
	 */
	IntcConfig = XScuGic_LookupConfig(XINTC_DEVICE_ID);
	if (NULL == IntcConfig) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize(IntcInstancePtr, IntcConfig,
					IntcConfig->CpuBaseAddress);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XScuGic_SetPriorityTriggerType(IntcInstancePtr, XINTC_CLK_WIZ_INTERRUPT_ID,
					0xA0, 0x3);

	/*
	 * Connect the interrupt handler that will be called when an
	 * interrupt occurs for the device.
	 */
	Status = XScuGic_Connect(IntcInstancePtr, XINTC_CLK_WIZ_INTERRUPT_ID,
			(XInterruptHandler)XClk_Wiz_IntrHandler, (void *)ClkWizPtr);
	if (Status != XST_SUCCESS) {
		return Status;
	}

	/* Enable the interrupt for the GPIO device.*/
	XScuGic_Enable(IntcInstancePtr, XINTC_CLK_WIZ_INTERRUPT_ID);
#endif
	/*
	 * Initialize the exception table.
	 */
	Xil_ExceptionInit();

	/*
	 * Register the interrupt controller handler with the exception table.
	 */
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, \
			 (Xil_ExceptionHandler)INTC_HANDLER, \
			 IntcInstancePtr);

	/*
	 * Enable exceptions.
	 */
	Xil_ExceptionEnable();

	return XST_SUCCESS;
}
#endif

/*****************************************************************************/
/**
*
* This function is the main entry point for the interrupt example using the
* XClk_Wiz driver. This function will set up the system with interrupts
* handlers.
*
* @param	DeviceId is the unique device ID of the CLK_WIZ
*		Subsystem core.
*
* @return
*		- XST_FAILURE if the system setup failed.
*		- XST_SUCCESS should never return since this function, if setup
*		was successful, is blocking.
*
* @note		If system setup was successful, this function is blocking in
*		order to illustrate interrupt handling taking place for HPD
*		events.
*
******************************************************************************/
//fbmul = CLKFBOUT_MULT_F
//fbdiv = DIVCLK_DIVIDE
//
//clk0div = Divide clk_out1
//clk1div = Divide clk_out1                                                                                                                 -> over clk
//                       10  11  12  13  14  15  16  17  18  19  20  121 122 123 124 125 126 127 128 129 131 132 133 134 135 136 137 138 139  250  280  300
u32 rfbmul[32]      =   {48, 33, 36, 39, 42, 54, 48, 51, 54, 57, 48, 14, 10, 31, 47, 10, 15, 32, 10, 41, 11, 9,  47, 24, 40, 39, 59, 19, 53 ,  9 ,  26,  54 };  // CLKFBOUT_MULT_F
u32 rfracmultiply[32] = {0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  500,250,0,  625,500,125,0,  750,750,0,  500,875,125,500,125,125,875,375,  0 , 875,   0 };
u32 rfbdiv[32]      =   {5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  1,  1,  3,  4,  1,  1,  3,  1,  3,  1,  1,  3,  3,  5,  3,  4,  2,  4  ,  1 ,   2,   5 };
u32 rclk0div[32]    =   {96, 60, 60, 60, 60, 72, 60, 60, 60, 60, 48, 119,84, 84, 96, 84, 120,84, 84, 107,84, 72, 120,60, 60, 95, 107,72, 96 , 36 ,  48,  36 };
u32 rclk0frac[32]   =   {0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  875,0,  0,  0,  0,  125,0,  0,  875,0,  0,  0,  0,  0,  875,875,0,  0  ,  0 ,   0,   0 };
u32 rclk1div[32]    =   {8,  5,  5,  5,  5,  6,  5,  5,  5,  5,  4,  10, 7,  7,  8,  7,  10, 7,  7,  9,  7,  6,  10, 5,  5,  8,  9,  6,  8  ,  3 ,   4,   3 };
// 121 126 129 136 137 = not use


#ifndef SDT
//u32 ClkWiz_IntrExample(INTC *IntcInstancePtr, u32 DeviceId, u32 clk0khz, u32 clk1khz)
u32 ClkWiz_IntrExample(u32 DeviceId, u32 clk0khz, u32 clk1khz)
#else
u32 ClkWiz_IntrExample(UINTPTR BaseAddress)
#endif
{
u8 idx = 0;
//if(clk0khz < 100 || clk0khz > 240) {
if(clk0khz < 100 || clk0khz > 320) {
///*DEB*/ func_printf("The input parameter value is invalid. Input is available from 10~20 (MHz).");
/*DEB*/ func_printf("The input parameter value is invalid. Input is available from 10~32 (MHz).");
/*DEB*/ func_printf("clk0khz(mclk) = %d, clk1khz(dclk) = %d ",clk0khz, clk1khz);
        return XST_FAILURE;
    }

    if(clk0khz == 100)      idx = 0;
    else if(clk0khz == 110) idx = 1;
    else if(clk0khz == 120) idx = 2;
    else if(clk0khz == 130) idx = 3;
    else if(clk0khz == 140) idx = 4;
    else if(clk0khz == 150) idx = 5;
    else if(clk0khz == 160) idx = 6;
    else if(clk0khz == 170) idx = 7;
    else if(clk0khz == 180) idx = 8;
    else if(clk0khz == 190) idx = 9;
    else if(clk0khz == 200) idx = 10;
//  else if(clk0khz == 121) idx = 11;
    else if(clk0khz == 122) idx = 12;
    else if(clk0khz == 123) idx = 13;
    else if(clk0khz == 124) idx = 14;
    else if(clk0khz == 125) idx = 15;
//  else if(clk0khz == 126) idx = 16;
    else if(clk0khz == 127) idx = 17;
    else if(clk0khz == 128) idx = 18;
//  else if(clk0khz == 129) idx = 19;
    else if(clk0khz == 131) idx = 20;
    else if(clk0khz == 132) idx = 21;
    else if(clk0khz == 133) idx = 22;
    else if(clk0khz == 134) idx = 23;
    else if(clk0khz == 135) idx = 24;
//  else if(clk0khz == 136) idx = 25;
//  else if(clk0khz == 137) idx = 26;
    else if(clk0khz == 138) idx = 27;
    else if(clk0khz == 139) idx = 28;
    else if(clk0khz == 250) idx = 29;
//    else if(clk0khz == 220) idx = 30;
//    else if(clk0khz == 230) idx = 31;
    else if(clk0khz == 280) idx = 30;
    else if(clk0khz == 300) idx = 31;
    else {
/*DEB*/ if (DBG_clk) func_printf("\033[31m");
/*DEB*/            func_printf("The input parameter value is invalid.");
/*DEB*/ if (DBG_clk) func_printf("\033[0m");
        return XST_FAILURE;
    }

    /*DEB*/ if (DBG_clk) func_printf("DBG_clk clk0khz=%d idx=%d \r\n",clk0khz,idx);

    fbmul = rfbmul[idx];
    fracmultiply = rfracmultiply[idx];
    fbdiv = rfbdiv[idx];
    clk0div = rclk0div[idx];
    clk0frac = rclk0frac[idx];
    clk1div = rclk1div[idx] * clk1khz; // mbh210719
	XClk_Wiz_Config *CfgPtr_Mon;
	XClk_Wiz_Config *CfgPtr_Dynamic;
	ULONG Exit_Count = 0;
	u32 Status = XST_SUCCESS;


    if(DBG_clk) func_printf("DBG_clk idx=%d \r\n",idx);
    if(DBG_clk) func_printf("DBG_clk fbmul=%d \r\n",fbmul);
    if(DBG_clk) func_printf("DBG_clk fracmultiply=%d \r\n",fracmultiply);
    if(DBG_clk) func_printf("DBG_clk fbdiv=%d \r\n",fbdiv);
    if(DBG_clk) func_printf("DBG_clk clk0div=%d \r\n",clk0div);
    if(DBG_clk) func_printf("DBG_clk clk0frac=%d \r\n",clk0frac);
    if(DBG_clk) func_printf("DBG_clk clk1div=%d \r\n",clk1div);

#ifndef SDT
	CfgPtr_Mon = XClk_Wiz_LookupConfig(DeviceId);
#else
	CfgPtr_Mon = XClk_Wiz_LookupConfig(BaseAddress);
#endif
	if (!CfgPtr_Mon) {
		return XST_FAILURE;
	}

	/*
	 * Initialize the CLK_WIZ driver so that it is ready to use.
	 */
	Status = XClk_Wiz_CfgInitialize(&ClkWiz_Mon, CfgPtr_Mon,
					CfgPtr_Mon->BaseAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Check the given clock wizard is enabled with clock monitor
	 * This test applicable only for clock monitor
	 */
	if(CfgPtr_Mon->EnableClkMon == 0) {
		func_printf("Interrupt test only applicable for "
			"clock monitor\r\n");
		return XST_SUCCESS;
	}

	/*
	 * Get the CLK_WIZ Dynamic reconfiguration driver instance
	 */
#ifndef SDT
	CfgPtr_Dynamic = XClk_Wiz_LookupConfig(XCLK_WIZ_DYN_DEVICE_ID);
#else
	CfgPtr_Dynamic = XClk_Wiz_LookupConfig(XPAR_CLK_WIZARD_2_BASEADDR);
#endif
	if (!CfgPtr_Dynamic) {
		return XST_FAILURE;
	}

	/*
	 * Initialize the CLK_WIZ Dynamic reconfiguration driver
	 */
	Status = XClk_Wiz_CfgInitialize(&ClkWiz_Dynamic, CfgPtr_Dynamic,
		 CfgPtr_Dynamic->BaseAddr);
	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	/*
	 * Connect the CLK_WIZ to the interrupt subsystem such that interrupts can
	 * occur. This function is application specific.
	 */

//#ifndef SDT
//	Status = SetupInterruptSystem(IntcInstancePtr, &ClkWiz_Mon);
//#else
//	/* Setup call back handlers */
//	XClk_Wiz_SetCallBack(&ClkWiz_Mon, XCLK_WIZ_HANDLER_CLK_OUTOF_RANGE,
//				ClkWiz_ClkOutOfRangeEventHandler, &ClkWiz_Mon);
//	XClk_Wiz_SetCallBack(&ClkWiz_Mon, XCLK_WIZ_HANDLER_CLK_GLITCH,
//				ClkWiz_ClkGlitchEventHandler, &ClkWiz_Mon);
//	XClk_Wiz_SetCallBack(&ClkWiz_Mon, XCLK_WIZ_HANDLER_CLK_STOP,
//				ClkWiz_ClkStopEventHandler, &ClkWiz_Mon);
//	Status = XSetupInterruptSystem(&ClkWiz_Mon, &XClk_Wiz_IntrHandler,
//			               ClkWiz_Mon.Config.IntId,
//				       ClkWiz_Mon.Config.IntrParent,
//				       XINTERRUPT_DEFAULT_PRIORITY);
//#endif
//	if (Status != XST_SUCCESS) {
//		return XST_FAILURE;
//	}

	/* Calling Clock wizard dynamic reconfig */
	Clk_Wiz_Reconfig(CfgPtr_Dynamic);

	/* Enable interrupts after setup interrupt */
	XClk_Wiz_InterruptEnable(&ClkWiz_Mon, XCLK_WIZ_IER_ALLINTR_MASK);

//	do {
//		Delay(1);
//		Exit_Count++;
//		if(Exit_Count > 3) {
//			func_printf("ClKMon Interrupt test failed, " \
//				"Please check design\r\n");
////			return XST_FAILURE;
//		}
//	}
//	while((Clk_Outof_Range_Flag == 1) && (Clk_Glitch_Flag == 1) \
//		&& (Clk_Stop_Flag == 1));
	return XST_SUCCESS;
}

/*****************************************************************************/
/**
*
* This function is called when a clock out of range is received by
* the CLK_WIZ  Subsystem core.
*
* @param	CallBackRef contains a callback reference from the driver.
*		In this case it is the instance pointer for the ClkWiz_Mon driver.
*
* @param	Mask of interrupt which caused this event
*
* @return	None
*
* @note		None
*
******************************************************************************/
void ClkWiz_ClkOutOfRangeEventHandler(void *CallBackRef, u32 Mask)
{
	if (Mask & XCLK_WIZ_ISR_CLK0_MAXFREQ_MASK) {
		func_printf(" User Clock 0  frequency is greater "
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK1_MAXFREQ_MASK) {
		func_printf(" User Clock 1  frequency is greater "
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK2_MAXFREQ_MASK) {
		func_printf(" User Clock 2  frequency is greater "
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK3_MAXFREQ_MASK) {
		func_printf(" User Clock 3  frequency is greater"
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK0_MINFREQ_MASK) {
		func_printf(" User Clock 0  frequency is lesser "
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK1_MINFREQ_MASK) {
		func_printf(" User Clock 1  frequency is lesser "
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK2_MINFREQ_MASK) {
		func_printf(" User Clock 2  frequency is lesser "
			"than the specifications \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK3_MINFREQ_MASK) {
		func_printf(" User Clock 3  frequency is lesser "
			"than the specifications \r\n");
	}
	Clk_Outof_Range_Flag = 0;
}

/*****************************************************************************/
/**
*
* This function is called when a clock glitch event is received by
* the CLK_WIZ Subsystem core.
*
* @param	CallBackRef contains a callback reference from the driver.
*		In this case it is the instance pointer for the ClkWiz_Mon driver.
*
* @param	Mask of interrupt which caused this event
*
* @return	None
*
* @note		None
*
******************************************************************************/
void ClkWiz_ClkGlitchEventHandler(void *CallBackRef, u32 Mask)
{
	if (Mask & XCLK_WIZ_ISR_CLK0_GLITCH_MASK) {
		func_printf("Glitch occurred in the user clock 0 \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK1_GLITCH_MASK) {
		func_printf("Glitch occurred in the user clock 1 \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK2_GLITCH_MASK) {
		func_printf("Glitch occurred in the user clock 2 \r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK3_GLITCH_MASK) {
		func_printf("Glitch occurred in the user clock 3 \r\n");
	}
	Clk_Glitch_Flag = 0;
}

/*****************************************************************************/
/**
*
* This function is called when a clock stop event is received by
* the CLK_WIZ Subsystem core.
*
* @param	CallBackRef is a pointer to the XClk_Wiz instance.
*
* @param	Mask of interrupt which caused this event
*
* @return	None
*
* @note		None
*
******************************************************************************/
void ClkWiz_ClkStopEventHandler(void *CallBackRef, u32 Mask)
{
	if (Mask & XCLK_WIZ_ISR_CLK0_STOP_MASK) {
		func_printf("Clock stop on User clock 0\r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK1_STOP_MASK) {
		func_printf("Clock stop on User clock 1\r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK2_STOP_MASK) {
		func_printf("Clock stop on User clock 2\r\n");
	}
	if (Mask & XCLK_WIZ_ISR_CLK3_STOP_MASK) {
		func_printf("Clock stop on User clock 3\r\n");
	}
	Clk_Stop_Flag = 0;
}
