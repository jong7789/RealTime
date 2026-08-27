/*
 * fpga_reg.h
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#ifndef SRC_FPGA_INFO_H_
#define SRC_FPGA_INFO_H_

#include <xparameters.h>
// Compatibility: old BSP uses XPAR_M1_AXI_GEV_BASEADDR, new BSP uses XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR
//#ifndef XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR
//#define XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR XPAR_M1_AXI_GEV_BASEADDR
//#endif
// BSP compat: new BSP(_CPU_I_) vs old(_CPU4DDR_I_ or short name)
#ifdef XPAR__CPU_I_M1_AXI_GEV_BASEADDR
//$ 2606011642 BSP rename compat: new _CPU_I_ BSP detected, map all legacy names
#define XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR XPAR__CPU_I_M1_AXI_GEV_BASEADDR
//# 2605291217 BSP rename compat: legacy short name -> current _CPU_I_ name (func_cmd.c gige_init sites)
#define XPAR_M1_AXI_GEV_BASEADDR            XPAR__CPU_I_M1_AXI_GEV_BASEADDR
//# 2605291217 BSP rename compat: SYSTEM CPU IRQ masks (int.h INT_MASK_GIGE/FB)
#define XPAR_SYSTEM_CPU_IRQ_0_MASK          XPAR_SYSTEM__CPU_I_CPU_IRQ_0_MASK
#define XPAR_SYSTEM_CPU_IRQ_1_MASK          XPAR_SYSTEM__CPU_I_CPU_IRQ_1_MASK
#else
//$ 2606011642 BSP rename compat: old BSP - map _CPU4DDR_I_ long name if missing
#ifndef XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR
#define XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR    XPAR_M1_AXI_GEV_BASEADDR
#endif
//$ 2606171653 BSP rename compat: CPU4DDR BSP - map legacy short names (gige_init, IRQ masks)
#ifdef XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR
#ifndef XPAR_M1_AXI_GEV_BASEADDR
#define XPAR_M1_AXI_GEV_BASEADDR            XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR
#endif
#endif
#ifdef XPAR_SYSTEM__CPU4DDR_I_CPU_IRQ_0_MASK
#ifndef XPAR_SYSTEM_CPU_IRQ_0_MASK
#define XPAR_SYSTEM_CPU_IRQ_0_MASK          XPAR_SYSTEM__CPU4DDR_I_CPU_IRQ_0_MASK
#define XPAR_SYSTEM_CPU_IRQ_1_MASK          XPAR_SYSTEM__CPU4DDR_I_CPU_IRQ_1_MASK
#endif
#endif
#endif
#include "xil_types.h"
#include "func_printf.h"
//#include "model_sel.h" //# 221018
//#include "model/model_sel.h" //# 221018
//#include <model_sel.h> //# 221018
//#include <model/model_sel.h> //# 221018

#define MODEL_LOW 0 //# 1616R 4343RC
//#define MODEL_LOW 1 //# 1616RL 4343RCL

extern char  FPGA_MODEL  [16];
extern char GIGE_MODEL[32];
extern char HW_VER[16];
/************************************************************
 * MODEL SELECTION #221018
 ************************************************************/
// #define EXT1616R             // 40 fps
//     #define EXT1616RL        // 30 fps
// #define EXT2430R             // 12 fps
//     #define EXT2430RI //# 10G         // 25 fps
// #define EXT2832R             // 30 fps //# 2832R_2 common
//     #define EXT2832R_2       // 30 fps tft=innocare
// #define EXT4343R             // 15 fps himax    = 4343R
//     #define EXT4343R_1       // 15 fps raydium  = 4343RR
//     #define EXT4343R_2       // 15 fps raydium  = 4343RR256 tft=innocare
//     #define EXT4343R_3       //  7 fps novatech = 4343RN tft=a-si
//     #define EXT4343R_4		// 15 fps raydium  = 4343RR    tft=innocare bit align
//     #define EXT4343RC_1      // 15 fps raydium  = 4343RCR
//     #define EXT4343RCL_1     //  8 fps raydium  = 4343RCRL
//     #define EXT4343RC_2      // 15 fps raydium  = 4343RCR
//     #define EXT4343RCL_2     //  8 fps raydium  = 4343RCCRL
//     #define EXT4343RC_3      //  7 fps novatech = 4343RCN tft=a-si
//     #define EXT4343RCL_3     //  4 fps ? novatech = 4343RCN tft=a-si
//     #define EXT4343RI_2  //# 10G      // 20 fps raydium  = 4343RR256 tft=innocare 10G
//	   #define EXT4343RI_4  //$ 10G	     // 20 fps raydium  = 4343RR    tft=innocare 10G bit align
//     #define EXT4343RCI_1 //# 10G      // 20 fps raydium  = 4343RCR 10G
//     #define EXT4343RCI_2 //# 10G      // 20 fps raydium  = 4343RCR 10G innocare
// #define EXT810R              // 10 fps direct
// #define EXT2430RD            // 10 fps direct
/*********************************************************** */

/* ***********************************************************
 * 10G Model selection
 *********************************************************** */
//#if ( defined(EXT4343RCI_1) ||\
//      defined(EXT4343RCI_2) ||\
//      defined(EXT4343RCI_3) ||\
//      defined(EXT4343RI_1)  ||\
//      defined(EXT4343RI_2)  ||\
//      defined(EXT4343RI_3)  ||\
//      defined(EXT4343RI_4)  ||\
//      defined(EXT2430RI  )  ||\
//		defined(EXT1024R   )  ) // 241014 jyp
//    #define GEV10G 1
//#else
//    #define GEV2p5G 1
//#endif

//#ifdef GEV10G
//	#define ETHERSPEED_B 10000000000/8 //# BYTE
//#else
//	#define ETHERSPEED_B 2500000000/8
//#endif

/************************************************************
 * EXT1616R(New) Specifications
 ************************************************************/
////#define EXT1616R
//#ifdef EXT1616R
//#define AFE2256
//#define RM76U89
//#endif

/************************************************************
 * EXT4343R(New) Specifications
 ************************************************************/
////#define EXT4343R
//#ifdef EXT4343R
//#define AFE2256
//#define RM76U89
//#endif

/************************************************************
 * EXT2430R(New) Specifications
 ************************************************************/
////#define EXT2430R  // MODEL
//#ifdef EXT2430R
//#define AFE2256   // TI_ROIC
//#define RM76U89   // GATE IC
//#endif

/************************************************************
 * EXT2832R(New) Specifications
 ************************************************************/
////#define EXT2832R  // MODEL
//#ifdef EXT2832R
//#define AFE2256   // TI_ROIC
//#define RM76U89   // GATE IC
//#endif

/************************************************************
 * EXT810R(New) Specifications
 ************************************************************/
////#define EXT810R  // MODEL
//#ifdef EXT810R
//#define AFE2256   // TI_ROIC
//#define NT39530   // GATE IC
//#endif

/************************************************************
 * EXT2430RD(New) Specifications
 ************************************************************/
////#define EXT2430RD  // MODEL
//#ifdef EXT2430RD
//#define AFE2256   // TI_ROIC
//#define RM76U89   // GATE IC
//#endif

// 241014 jyp
/************************************************************
 * EXT1024R(New) Specifications
 ************************************************************/
////#define EXT1024R  // MODEL
//#ifdef EXT1024R
//#define AFE2256   // TI_ROIC
//#define RM76U89   // GATE IC
//#endif

/************************************************************
 * Flash Size Specifications
 ************************************************************/
/*
#if defined(EXT4343R)
    #if (defined(EXT4343R_1)  ||\
         defined(EXT4343R_2)  ||\
         defined(EXT4343R_3)  ||\
         defined(EXT4343R_4)  ||\
         defined(EXT4343RC)   ||\
         defined(EXT4343RC_1) ||\
         defined(EXT4343RC_2) ||\
         defined(EXT4343RC_3) ||\
         defined(EXT4343RCL)  ||\
         defined(EXT4343RCL_1)||\
         defined(EXT4343RCL_2)||\
         defined(EXT4343RCL_3)||\
         defined(EXT4343RI_2) ||\
         defined(EXT4343RI_4) ||\
         defined(EXT4343RCI_1)||\
         defined(EXT4343RCI_2) )
        #define FLASH_2GBIT
    #else
        #define FLASH_1GBIT
    #endif
#else
    #define FLASH_2GBIT
#endif
 */
#define FLASH_2GBIT //# all fix 2G 231023

#define DEBUG 0
#define DEBUGFLAW 0
#define DEBUGDDR 0
#define DEBUGXML_R 1
#define DEBUGXML_W 1
//# 2608191920 BD (NCT175/DS1731) outlier rejection. A single dropped readback bit turned
//# 41.9C into 9.4C (hi byte 41 -> 9, exactly bit5), and the old guard let it through while
//# blocking stable readings. Temperature cannot move this fast between polls, so a jump
//# larger than STEP_MAX is held until CONFIRM_N consecutive samples agree on it.
#define BD_TEMP_STEP_MAX_C  8.0f   // max plausible change between two polls [C]
#define BD_TEMP_CONFIRM_N   2      // agreeing samples needed to accept a large jump
#define BD_TEMP_ABSENT_LO   0x0000 // sensor missing / bus never ran
#define BD_TEMP_ABSENT_HI   0xFFFF // no ACK, SDA pulled up only

//# 2608201518 Board temperature IC select. read_ds1731_temp() used to ALTERNATE the
//# pointer between 0xAA and 0x00 every call to "support both" ICs. 0x00 is not a DS1731
//# command (its set is 0xAC/0xAA/0x51/0x22/0xA1/0xA2), so on a DS1731 board every other
//# read returned undefined data - that is where the bogus 9.3C came from. Pin the pointer
//# to the installed part instead.
//#   1 = DS1731 : 0xAA "Read Temperature" (init already sends 0xAC 0x0C / 0x51 / 0xAA)
//#   0 = NCT175 / LM75-compatible : pointer register 0x00 = Temperature
#define BD_TEMP_IC_DS1731   1
#if BD_TEMP_IC_DS1731
#define BD_TEMP_PTR         0xAA
#else
#define BD_TEMP_PTR         0x00
#endif

//# 2608201518 Rejections in a row before the filter assumes its own reference is wrong
//# and re-arms. Guards against a boot glitch getting latched as bd_last permanently.
#define BD_TEMP_RESYNC_N    8

//# 2608211132 Absolute plausibility window. The step filter is relative, so on the very
//# first sample it has no reference and cannot reject anything - at power-on BD0/BD1 both
//# reported -60.0 C (raw 0xC400, bit-identical on two separate ICs, so a deterministic
//# register state rather than a bus glitch) and it went straight out to rtemp and XML.
//# A board sensor can never read these values, so gate on the range as well.
//# DS1731 spec range is -55..+125 C; keep the window inside what a chassis can reach.
#define BD_TEMP_MIN_C       (-30.0f)
#define BD_TEMP_MAX_C       125.0f

//# 2608201518 Print the raw 16-bit word per BD sensor in rtemp. Set to 0 for normal use.
//# 2608201531 back to 0: BD diagnosis done - BD0/BD1 answer (0x2cb0/0x27f0), BD2/BD3
//# return 0xffff (no ACK) and are confirmed not populated on this board.
#define DBG_BDRAW           0

//# 2608201531 Raw ADC code print inside read_roic_temp(). It used to be an unconditional
//# func_printf, so "ROIC Temp = nn" appeared unformatted ahead of the rtemp listing.
//# The value is the 9-bit register 0x78 code, not a temperature - debug only.
#define DBG_ROICTEMP        0

//# 2608191856 Trace every temperature value XML actually reads (FPGA/PHY/SFP/BD).
//# Set to 0 to remove the prints - the host polls these nodes continuously, so leaving
//# it on floods the UART and slows the main loop.
#define DBG_XMLTEMP 0
#define DBGDFEC 0
//#define DEBUGXML_PRINT
//#define ROMDOWNLOADER //# Rom Download program  21.11.17mbh
#define GEN_NUC_EDGE 0
#define GEN_HWMASK_EDGE 1

// dskim - 21.02.18 - Offset 18bit 처리 여부
#define GAIN_CALIB_BIT_OFFSET_18 // Offset 18bit, Gain 14bit 사용 // Default 16bit, 16bit
#define GAIN_CALIB_BIT_DEPTH_256 // Gain Calibration 256bit  // 사용하지 않음
#define GAIN_CALIB_SAVE_NUC_PARAM // NUC 파라미터 저장

/************************************************************
 * FPGA Info (Import FPGA TOP_HEADER.vhd and Others)
 *
 * MODEL : EXT1024R, EXT1616R, EXT4343R
 * ROIC : ADAS1255, ADAS1258
 * GATE : NT39565, NT39530, NT61303, RM76U89, HX8698
 ************************************************************/
// TI_ROIC
//# 10G Raydium
/*
#if defined(EXT4343RI_1) ||\
    defined(EXT4343RI_2) ||\
    defined(EXT4343RI_4) ||\
    defined(EXT4343RCI_1) ||\
    defined(EXT4343RCI_2) ||\
    defined(EXT4343RCI_3) ||\
    defined(EXT4343RCLI_1) ||\
    defined(EXT4343RCLI_2) ||\
    defined(EXT4343RCLI_3)
    #define FPGA_TFT_MAIN_CLK  20000000
    #define FPGA_TFT_DATA_CLK  240000000
    //### roic over clk ###
    // #define FPGA_TFT_MAIN_CLK  22000000
    // #define FPGA_TFT_DATA_CLK  264000000
//# a-si
#elif (defined(EXT4343R) && defined(EXT4343R_3)) ||\
      (defined(EXT4343R) && defined(EXT4343RC_3)) ||\
      (defined(EXT4343R) && defined(EXT4343RCL_3))
    #define FPGA_TFT_MAIN_CLK   6250000 //# roic str 512
//    #define FPGA_TFT_MAIN_CLK  12500000 //# 230718
    #define FPGA_TFT_DATA_CLK  153000000
#elif defined EXT4343R
    #define FPGA_TFT_MAIN_CLK  12500000
    #define FPGA_TFT_DATA_CLK  153000000
#elif defined EXT2430RI
    #define FPGA_TFT_MAIN_CLK  20000000
    #define FPGA_TFT_DATA_CLK  240000000
#elif defined EXT2430R
    #define FPGA_TFT_MAIN_CLK  12500000
    #define FPGA_TFT_DATA_CLK  153000000
#elif defined EXT810R
    #define FPGA_TFT_MAIN_CLK  5000000
    #define FPGA_TFT_DATA_CLK  60000000
#elif defined EXT2430RD
    #define FPGA_TFT_MAIN_CLK  5000000
    #define FPGA_TFT_DATA_CLK  60000000
#else
    #define FPGA_TFT_MAIN_CLK  20000000
    #define FPGA_TFT_DATA_CLK  240000000
#endif
*/

#define FPGA_SYS_CLK   100000000
#define FPGA_DATA_CLK  187500000 // 750 MHz
//#define FPGA_DATA_CLK   166666666 // 666 MHz
//#define FPGA_DATA_CLK   200000000 // 800 MHz

#define GEV_SPEED    2500   // MBps
#define FPGA_DDR_BASEADDR  0x89000000

//#define VIDEO_REGS    XPAR_EPC_0_PRH1_BASEADDR
//#define XGIGE_REGS    XPAR_EPC_0_PRH0_BASEADDR
//#define VIDEO_REGS    XPAR_M_AXIL_REG_BASEADDR
#define FPGA_REGS    XPAR_AXI_EPC_0_PRH0_BASEADDR
//#define XGIGE_REGS    XPAR_M1_AXI_GEV_BASEADDR
#define XGIGE_REGS XPAR__CPU4DDR_I_M1_AXI_GEV_BASEADDR //$ 260401
#define DDR3_REGS    XPAR_SDRAM_0_BASEADDR
#define DDR3_CALIB_REGS   FPGA_DDR_BASEADDR

//#define REG(x)  (*(volatile u32 *)(VIDEO_REGS + x))
//#define REG(x)  (*(volatile u32 *)(FPGA_REGS + x))
//# 2605131158 REG access watcher (simplified: no mode concept).
//  FREG()  : raw accessor; bypasses the watcher.
//  REG()   : wraps FREG; calls dbg_watch_check() before yielding the original lvalue.
//  Per-slot behavior is unconditional dual-trigger:
//    - R trigger: log every REG() invocation at the watched addr ("access happened").
//    - W trigger: log when the stored value differs from last seen ("value changed").
//    Both triggers fire independently on each macro call. A pure read shows only
//    [WATCH-R]. A write shows [WATCH-R] on the write line, then [WATCH-W] on the
//    NEXT macro call (attribution is one access late by design).
//  ALL mode (dbg_watch_flags bit0) applies the same dual-trigger pattern to every
//  sampled access (1/DBG_WATCH_ALL_DIV), with per-addr cache for the W trigger.
//  Configured at runtime via the 'watch' UART command (see UART_CMD_watch).
//  Build-time disable: define DBG_WATCH_COMPILE 0 -> REG == FREG (zero overhead).
#define FREG(x)  (*(volatile u32 *)(FPGA_REGS + (x)))   //# raw accessor

#define DBG_WATCH_COMPILE   1                //# 1 = compile in watcher; 0 = REG == FREG
#define DBG_WATCH_MAX       8                //# number of address slots
//#define DBG_WATCH_FLAG_ALL  0x01u            //# bit0 of dbg_watch_flags: print every REG() access (sampled)
#define DBG_WATCH_FLAG_ALL  0x00u            //# disable dbg_watch
#define DBG_WATCH_ALL_DIV   100u             //# in ALL mode, print 1 of every N accesses

#if DBG_WATCH_COMPILE
extern u8  dbg_watch_flags;
extern u32 dbg_watch_addr[DBG_WATCH_MAX];
extern u32 dbg_watch_prev[DBG_WATCH_MAX];
extern void dbg_watch_check(u32 access_addr, const char *fname, int line);
#define REG(x) (*({                                                              \
    u32 _a = (u32)(x);                                                           \
    dbg_watch_check(_a, __func__, __LINE__);                                     \
    (volatile u32 *)(FPGA_REGS + _a);                                            \
}))
#else
#define REG(x)  FREG(x)
#endif
#define DREG(x) (*(volatile u32 *)(DDR3_CALIB_REGS + x))
#define AREG(x) (*(volatile u32 *)(x))
#define XREG(x) (*(volatile u32 *)(XGIGE_REGS + x))

//$ 2606161124 boot section profiler (LAP)
//  ADDR_FREERUN_CNT(0x0454) = 32-bit 100MHz free-run (10ns/count, wraps ~42.9s).
//  u32 subtract is wrap-safe while an interval is < 42.9s. LAP(tag) prints the
//  time spent SINCE the previous LAP. DBG_LAP=0 -> all LAP/LAP_INIT compile to no-op.
//  FREG() (raw, no REG-watcher overhead) is used for accurate timing.
#define DBG_LAP        1
//$ 2607101034 DBG_IMGOUT: print RCNT0/3/9 video stats inside every LAP (boot only)
#define DBG_IMGOUT     0
#define FREERUN_NOW()  FREG(ADDR_FREERUN_CNT)
#define LAP_INIT()     do { if(DBG_LAP){ _lap_prev = FREERUN_NOW(); } } while(0)
#define LAP(tag)       do { if(DBG_LAP){                                       \
    u32 _n = FREERUN_NOW();                                                     \
    u32 _d = (u32)(_n - _lap_prev);            /* wrap-safe elapsed counts */   \
    func_printf("[LAP] %-22s %lu.%03lu ms\r\n", (tag),                         \
        (unsigned long)(_d / 100000),          /* ms integer part */           \
        (unsigned long)((_d / 100) % 1000));   /* us -> 3-digit fraction */     \
    if(DBG_IMGOUT){                                                             \
        func_printf("[IMGOUT] ALIGN  ");                                        \
        execute_cmd_read_video(ADDR_SYNC_RCNT0,ADDR_SYNC_RDATA_AVCN0,ADDR_SYNC_RDATA_BGLW0); \
        func_printf("[IMGOUT] DDR3   ");                                        \
        execute_cmd_read_video(ADDR_SYNC_RCNT3,ADDR_SYNC_RDATA_AVCN3,ADDR_SYNC_RDATA_BGLW3); \
        func_printf("[IMGOUT] OUT    ");                                        \
        execute_cmd_read_video(ADDR_SYNC_RCNT9,ADDR_SYNC_RDATA_AVCN9,ADDR_SYNC_RDATA_BGLW9); \
    }                                                                           \
    _lap_prev = FREERUN_NOW();   /* re-sample: exclude this printf's own time */ \
} } while(0)

//$ 2606161124 while-loop profiler (LAPW) - same as LAP but prints ONLY when a
//  section took >= LAP_WHILE_MS (default 10ms). Avoids flooding the per-iteration
//  loop. Uses its own _lapw_prev so it never disturbs the boot LAP chain.
#define LAP_WHILE_MS   10u                          /* print threshold [ms] */
#define LAP_WHILE_CNT  (LAP_WHILE_MS * 100000u)     /* -> counts (100MHz: 100000/ms) */
#define LAPW_INIT()    do { if(DBG_LAP){ _lapw_prev = FREERUN_NOW(); } } while(0)
#define LAPW(tag)      do { if(DBG_LAP){                                        \
    u32 _n = FREERUN_NOW();                                                     \
    u32 _d = (u32)(_n - _lapw_prev);           /* wrap-safe elapsed counts */   \
    if (_d >= LAP_WHILE_CNT)                                                    \
        func_printf("[LAPW] %-22s %lu.%03lu ms\r\n", (tag),                    \
            (unsigned long)(_d / 100000),                                      \
            (unsigned long)((_d / 100) % 1000));                               \
    _lapw_prev = FREERUN_NOW();   /* re-sample: exclude this printf's own time */ \
} } while(0)

//$ 2606161124 aggregated while-loop profiler (LAPW_AGG) for repetitive sections
//  (e.g. brns_bg_poll runs hundreds of times). Accumulates over 'every' calls,
//  then prints ONE summary line: count + avg + max [ms] + running TOTAL [s].
//  Block-scope statics -> each call site keeps its own counters. avg/max/cnt
//  reset every window; _atot_us (cumulative total) persists and is zeroed only
//  when 'reset' is nonzero (pass rising-edge of the activity gate at load start).
//  _atot_us is us in u32 -> safe up to ~71 min total. Set 'every' larger = fewer prints.
//$ 2606161224 add 'reset' param + cumulative total (tot=.. s)
#define LAPW_AGG(tag, every, reset) do { if(DBG_LAP){                           \
    static u32 _acnt = 0, _asum_us = 0, _amax = 0, _atot_us = 0;                \
    u32 _n = FREERUN_NOW();                                                     \
    u32 _d = (u32)(_n - _lapw_prev);           /* wrap-safe elapsed counts */   \
    if (reset) { _acnt = 0; _asum_us = 0; _amax = 0; _atot_us = 0; }            \
    _acnt++; _asum_us += _d / 100; _atot_us += _d / 100;   /* us */             \
    if (_d > _amax) _amax = _d;                                                 \
    if (_acnt >= (u32)(every)) {                                                \
        u32 _avg_us = _asum_us / _acnt;                                         \
        func_printf("[LAPW] %-18s x%lu avg=%lu.%03lu max=%lu.%03lu tot=%lu.%03lu s\r\n", \
            (tag), (unsigned long)_acnt,                                        \
            (unsigned long)(_avg_us / 1000), (unsigned long)(_avg_us % 1000),   \
            (unsigned long)(_amax / 100000), (unsigned long)((_amax / 100) % 1000), \
            (unsigned long)(_atot_us / 1000000), (unsigned long)((_atot_us / 1000) % 1000)); \
        _acnt = 0; _asum_us = 0; _amax = 0;                                     \
    }                                                                           \
    _lapw_prev = FREERUN_NOW();   /* re-sample: exclude this printf's own time */ \
} } while(0)

#define ERROR 0
#define OK 1
// TI_ROIC
//#define ROIC_SYNC_DCLK   0.04 // us (DCLK)
//#define ROIC_SYNC_ACLK   0.04 // us (MCLK)
//#define ROIC_A3_A4_MIN   0.1  // us (MCLK)
//#define ROIC_DEAD    0.04 // us (MCLK)
//#define ROIC_FA     0.1  // us (MCLK)
//#define ROIC_CDS    7.65 // us (MCLK)
#define ROIC_CDS1    4.0  // us (MCLK)
#define ROIC_CDS2    6.5  // us (MCLK)
#define ROIC_FA1     1.0  // us (MCLK)
#define ROIC_FA2     1.0  // us (MCLK)
#define ROIC_INTRST  1.5  // us (MCLK)

#define GATE_OE        1.7 // us (MCLK)
#define GATE_XON     340   // us (MCLK)
#define GATE_XON_FLK  50   // us (MCLK)
#define GATE_FLK     150   // us (MCLK)

#define GATE_DIO_CPV        0.02 // us (MCLK)
#define GATE_TRST_PERIOD   10    // ms (MCLK)
#define ERASE_TIME       1000    // ms (MCLK)

//#ifdef EXT1024R
//    #define MAX_WIDTH       1280
//    #define MAX_WIDTH_x32   1280
//    #define MAX_HEIGHT      3072
//    #define PIXEL_WIDTH       16
//    #define ROIC_DUAL          1
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          256
//    #define GATE_CH          384
//    #define GATE_MAX_CH      450
//    #define GATE_DUMMY_LINE    0 // 241014 jyp 33 -> 0
//
//#elif defined EXT1616R
////  #define MAX_WIDTH       1652 mbh 210125
//    #define MAX_WIDTH       1648
//    #define MAX_WIDTH_x32   1664
//    #define MAX_HEIGHT      1644
//    #define PIXEL_WIDTH       16
//    #define ROIC_DUAL          1
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          236
//    #define GATE_CH          274
//    #define GATE_MAX_CH      450
//    #define GATE_DUMMY_LINE   88
//
//#elif defined EXT4343R
//    #define MAX_WIDTH       3072
//    #define MAX_WIDTH_x32   3072
//    #define MAX_HEIGHT      3072
//    #define PIXEL_WIDTH       16
//    #ifdef NT39565
//        #define ROIC_DUAL      2
//    #elif defined HX8698
//        #define ROIC_DUAL      1
//    #endif
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          256
//    #define GATE_CH          512
//    #define GATE_MAX_CH      512
//    #define GATE_DUMMY_LINE    0
//
//#elif defined EXT2430R
//    #define MAX_WIDTH       3840
//    #define MAX_WIDTH_x32   3840
//    #define MAX_HEIGHT      3072
//    #define PIXEL_WIDTH       16
//    #define ROIC_DUAL          1
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          256
//    #define GATE_CH          512
//    #define GATE_MAX_CH      512
//    #define GATE_DUMMY_LINE   33
//
//#elif defined EXT2832R
//    #define MAX_WIDTH       2304
//    #define MAX_WIDTH_x32   2304
//    #define MAX_HEIGHT      2048
//    #define PIXEL_WIDTH       16
//    #define ROIC_DUAL          1
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          256
//    #define GATE_CH          512
//    #define GATE_MAX_CH      512
//    #define GATE_DUMMY_LINE    0
//
//#elif defined EXT810R
//    #define MAX_WIDTH       2048
//    #define MAX_WIDTH_x32   2048
//    #define MAX_HEIGHT      1536
//    #define PIXEL_WIDTH       16
//    #define ROIC_DUAL          1
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          256
//    #define GATE_CH          256
//    #define GATE_MAX_CH      256
//    #define GATE_DUMMY_LINE    0
//
//#elif defined EXT2430RD
////    #define MAX_WIDTH       1792
////    #define MAX_WIDTH_x32   1792
//    #define MAX_WIDTH       3584
//    #define MAX_WIDTH_x32   3584
//    #define MAX_HEIGHT      2304
//    #define PIXEL_WIDTH       16
//    #define ROIC_DUAL          1
//    #define ROIC_MAX_CH      256
//    #define ROIC_CH          256
//    #define GATE_CH          384
//    #define GATE_MAX_CH      450
//    #define GATE_DUMMY_LINE   33
//#endif

/***** 230516
#ifdef NT39530
    #define GATE_CPV_PERIOD  5.00 // us (MCLK)
#elif defined NT39565
    #define GATE_CPV_PERIOD  5.00 // us (MCLK)
#elif defined NT61303
    #define GATE_CPV_PERIOD  2.88 // us (MCLK)
#elif defined RM76U89
//    #define GATE_CPV_PERIOD  3.36 // us (MCLK)
    #define GATE_CPV_PERIOD  0.55 // us (MCLK)
    // #define GATE_CPV_PERIOD  2.50 // us (MCLK) // 220107mbh dummytime
#elif defined HX8698
    #define GATE_CPV_PERIOD  2.80 // us (MCLK)
#endif
******/
#define GATE_CPV_PERIOD  0.55 // us (MCLK) // 230516mbh

// Calculation Value
//#define ROIC_DUMMY_LINE (2 * ROIC_DUAL)
//#define ROIC_DUMMY_CH   ((ROIC_MAX_CH - ROIC_CH) / 2)
//#define ROIC_NUM        (int)(((float)MAX_WIDTH / ROIC_CH + 0.499) * ROIC_DUAL) //220411 mbh
//#define GATE_NUM        (MAX_HEIGHT / GATE_CH)
//#define GATE_CHECK      (1000000.0 / FPGA_TFT_MAIN_CLK) // us (MCLK)
#define DS1731_NUM      4 // 2->4 added temperature ic 3,4 mbh 210305

//# FPGA INIT VALUE
//    constant INIT_PWDAC_LEVEL    : std_logic_vector(12-1 downto 0) := x"800"; -- half level
//    constant INIT_PWDAC_TICKTIME : std_logic_vector(16-1 downto 0) := x"0064"; -- 25MHz 100clk period
//    constant INIT_PWDAC_TICKINC  : std_logic_vector(12-1 downto 0) := x"000"; -- 1
#define PWDAC_INIT_VALUE  0x800

/************************************************************
 * Others for FW Operation
 ************************************************************/
//#define MIN_WIDTH       1  // 128
//#define MIN_HEIGHT    1 // 128
#define MIN_WIDTH    128 //# 4의 배수가되어야 문제가 생기지 않음 rollback 220809mbh
#define MIN_HEIGHT   128 //# rollback 220809mbh
#define MIN_OFFSETX    0
#define MIN_OFFSETY    0
//#define INTERVALX      4
//### must be 16. FPGA ROI is designed in 16-pixel increments
//#define INTERVALX      4  //# 231012 16->4 231115 only offset interval 16.
#define INTERVALX      16   //# 260601 4->16 framebuf min size
#define OFFSINTVX      16 //# 231115
#define INTERVALY      2
#define MIN_DGAIN      1
#define MAX_DGAIN   1600
// TI_ROIC
//#define MIN_IFS         0
//#define MAX_IFS        16 //$ 260224 31->39 //$ 260403 39->16
//$ 2607221549 ifs range split per ROIC family, then folded back into MIN_IFS/MAX_IFS
//$ so existing users of the macro keep working unchanged. AFE3256 step0 (0.3125pC,
//$ AFE3256_Cfb table index 0) is excluded; AFE2256 keeps 0 because there 0 selects
//$ the 0.3pC special sequence in execute_cmd_ifs(), not a gain table index.
//$ NOTE: MIN_IFS/MAX_IFS are runtime expressions now - not usable as array size or case label.
#define MIN_IFS_2256    0       //$ 2607221549 AFE2256 lower bound (0 = 0.3pC path)
#define MAX_IFS_2256   16       //$ 2607221549 AFE2256 upper bound
#define MIN_IFS_3256    0       //$ 2607221549 AFE3256 lower bound, step0 0.3125pC excluded
#define MAX_IFS_3256   16       //$ 2607221549 AFE3256 upper bound
#define MIN_IFS        (AFE3256_series ? MIN_IFS_3256 : MIN_IFS_2256)   //$ 2607221549 runtime bound
#define MAX_IFS        (AFE3256_series ? MAX_IFS_3256 : MAX_IFS_2256)   //$ 2607221549 runtime bound

//$ 2607241132 AFE3256 pixel short detection (TDEF = reg0x80 bit11 EN_TDEF) master switch.
//$ Why: false-trigger at low a-gain makes dotted-line artifact; turn TDEF off for normal op.
//$ 0: OFF (all normal-op 0x80 writes = 0x000D), 1: ON (=0x080D). DOC-calib site (0x082D) unaffected.
#define TDEF_EN         1
#define ROIC80_NORMAL   (TDEF_EN ? 0x080D : 0x000D)   //$ 2607241132 reg0x80 normal-operation value

//$ 2607151649 ifs->ROIC 0x6D map (EXT3643R only). //$ 2607161145 switched from
//$ runtime formula to lookup table ifs_r6d_tbl[] in func_cmd.c, indexed by
//$ func_ifs_index (0..15). Set on every ifs change in execute_cmd_ifs().
//  Table seeded from 210-13*x (low byte to ROIC 0x6D); edit per-index freely:
//    ifs  0: 210 0xD2    ifs  8: 106 0x6A
//    ifs  1: 197 0xC5    ifs  9:  93 0x5D
//    ifs  2: 184 0xB8    ifs 10:  80 0x50
//    ifs  3: 171 0xAB    ifs 11:  67 0x43
//    ifs  4: 158 0x9E    ifs 12:  54 0x36
//    ifs  5: 145 0x91    ifs 13:  41 0x29
//    ifs  6: 132 0x84    ifs 14:  28 0x1C
//    ifs  7: 119 0x77    ifs 15:  15 0x0F
#define IFS_R6D_EN     0        //$ 2607151649 1=enable, 0=disable
#define IFS_R6D_REG    0x6D     //$ 2607151649 target ROIC register

//#ifdef EXT4343R
//    #define TFT_TIMING_MODE   3
//#else
//    #define TFT_TIMING_MODE   0
//#endif

#define TFT_ROUTINE_RESET  0
#define TFT_START_RESET    0
#define TOTAL_RESET        0
#define SERIAL_RESET       1

#ifdef GAIN_CALIB_BIT_OFFSET_18
    #define CALIB_PARAM_RESOLUTION 12
#else
    #define CALIB_PARAM_RESOLUTION 8
#endif

#define SLEEP_TIMEOVER   10 // 60*5 min
//#define IMAGE_DATA_HIGH            55000
/************************************************************
 * Register for communication between FPGA and FW
 ************************************************************/
#define ADDR_OUT_EN          0x0000
#define ADDR_WIDTH           0x0004
#define ADDR_HEIGHT          0x0008
#define ADDR_OFFSETX         0x000C
#define ADDR_OFFSETY         0x0010
#define ADDR_REV_X           0x0014
#define ADDR_REV_Y           0x0018
#define ADDR_TP_SEL          0x001C
#define ADDR_TP_MODE         0x0020
#define ADDR_TP_DTIME        0x0024
#define ADDR_PWR_MODE        0x0028
#define ADDR_GRAB_EN         0x002C
#define ADDR_GATE_EN         0x0030
#define ADDR_IMG_MODE        0x0034
#define ADDR_RST_MODE        0x0038
#define ADDR_TRIG_MODE       0x003C
#define ADDR_TRIG_DELAY      0x0040
#define ADDR_TRIG_VALID      0x0044
#define ADDR_TRIG_FILT       0x0048
#define ADDR_ROIC_CDS1       0x004C
#define ADDR_OFFSET_CAL      0x0050
#define ADDR_ROIC_INTRST     0x0054
#define ADDR_GATE_OE         0x0058
#define ADDR_GATE_XON        0x005C
#define ADDR_GATE_XON_FLK    0x0060
#define ADDR_GATE_FLK        0x0064
#define ADDR_ROIC_DEAD       0x0068
#define ADDR_ROIC_MUTE       0x006C
#define ADDR_EXP_TIME        0x0070
#define ADDR_FRAME_TIME      0x0074
#define ADDR_FRAME_NUM       0x0078
#define ADDR_ROIC_CDS2       0x007C
#define ADDR_ROIC_RDATA      0x0080
#define ADDR_DDR_CH3_WADDR   0x0084
#define ADDR_DDR_CH3_RADDR   0x0088
#define ADDR_EXT_EXP_TIME    0x008C
#define ADDR_EXT_FRAME_TIME  0x0090
#define ADDR_ROIC_EN         0x0094
#define ADDR_ROIC_ADDR       0x0098
#define ADDR_ROIC_WDATA      0x009C
#define ADDR_REQ_ALIGN       0x00A0
#define ADDR_OUT_MODE        0x00A4
#define ADDR_DEBUG           0x00A8
#define ADDR_DDR_CH_EN       0x00AC
	//$ 2604301700 ADDR_DDR_CH_EN bit masks (see AXI_SUB_IF.vhd)
	#define DDR_CH_EN_W_ROIC     0x01    // bit0 : CH0 write (ROIC raw)
	#define DDR_CH_EN_W_NUC      0x02    // bit1 : CH1 write (NUC, unused)
	#define DDR_CH_EN_W_OFFSET   0x04    // bit2 : CH2 write (offset / d2m ref-avg)
	#define DDR_CH_EN_W_CH3      0x08    // bit3 : CH3 write (unused)
	#define DDR_CH_EN_R_ROIC     0x10    // bit4 : CH0 read  (ROIC raw)
	#define DDR_CH_EN_R_NUC      0x20    // bit5 : CH1 read  (gain / NUC map)
	#define DDR_CH_EN_R_OFFSET   0x40    // bit6 : CH2 read  (offset)
	#define DDR_CH_EN_R_D2M      0x80    // bit7 : CH3 read  (D2M xray)
	#define DDR_CH_EN_DEFAULT    (DDR_CH_EN_W_ROIC | DDR_CH_EN_R_ROIC)  // 0x11
	//# 2605081700 explicit all-off mask for direct REG writes that must force-disable every DDR channel
	#define DDR_CH_ALL_OFF       0x00
#define ADDR_DDR_BASE_ADDR   0x00B0
#define ADDR_DDR_CH0_WADDR   0x00B4
#define ADDR_DDR_CH0_RADDR   0x00B8
#define ADDR_DDR_CH1_RADDR   0x00BC
#define ADDR_DDR_CH2_RADDR   0x00C0
#define ADDR_DDR_OUT         0x00C4
#define ADDR_DEBUG_MODE      0x00C8
#define ADDR_GAIN_CAL        0x00CC
#define ADDR_DEFECT_CAL      0x00D0
#define ADDR_DEFECT_WEN      0x00D4
#define ADDR_DEFECT_ADDR     0x00D8
#define ADDR_DEFECT_WDATA    0x00DC
#define ADDR_DEFECT_RDATA    0x00E0
#define ADDR_DGAIN           0x00E4
#define ADDR_IPROC_MODE      0x00E8
#define ADDR_DEFECT2_WEN     0x00EC
#define ADDR_DEFECT2_ADDR    0x00F0
#define ADDR_DEFECT2_WDATA   0x00F4
#define ADDR_DEFECT2_RDATA   0x00F8
#define ADDR_AVG_EN          0x00FC
#define ADDR_AVG_LEVEL       0x0100
#define ADDR_AVG_END         0x0104
#define ADDR_DDR_CH1_WADDR   0x0108
#define ADDR_FPGA_VER        0x010C
#define ADDR_ROIC_DONE       0x0110
#define ADDR_ALIGN_DONE      0x0114
#define ADDR_CALIB_DONE      0x0118
#define ADDR_PWR_DONE        0x011C
#define ADDR_SHUTTER_MODE    0x0120
#define ADDR_I2C_WEN         0x0124
#define ADDR_I2C_WSIZE       0x0128
#define ADDR_I2C_WDATA       0x012C
#define ADDR_I2C_REN         0x0130
#define ADDR_I2C_RSIZE       0x0134
#define ADDR_I2C_RDATA0      0x0138
#define ADDR_I2C_RDATA1      0x013C
#define ADDR_I2C_MODE        0x0140
#define ADDR_I2C_DONE        0x0144
#define ADDR_ROIC_SYNC_ACLK  0x0148
#define ADDR_FRAME_VAL       0x014C
#define ADDR_ROIC_FA         0x0150
#define ADDR_API_EXT_TRIG    0x0154
#define ADDR_ROIC_SYNC_DCLK  0x0158
#define ADDR_ROIC_AFE_DCLK   0x015C
#define ADDR_GATE_RST_CYCLE  0x0160
#define ADDR_TEMP_EN         0x0164
#define ADDR_DEVICE_TEMP     0x0168
#define ADDR_ROIC_SHAAZEN    0x016C
#define ADDR_TIMING_MODE     0x0170
#define ADDR_GRAB_DONE       0x0174
#define ADDR_LDEFECT_CAL     0x0178
#define ADDR_RDEFECT_WEN     0x017C
#define ADDR_RDEFECT_ADDR    0x0180
#define ADDR_RDEFECT_WDATA   0x0184
#define ADDR_RDEFECT_RDATA   0x0188
#define ADDR_CDEFECT_WEN     0x0190
#define ADDR_CDEFECT_ADDR    0x0194
#define ADDR_CDEFECT_WDATA   0x0198
#define ADDR_CDEFECT_RDATA   0x019C
#define ADDR_LINE_TIME       0x01A0
#define ADDR_DDR_CH2_WADDR   0x01A4
#define ADDR_SD_WEN          0x01A8
#define ADDR_SD_REN          0x01AC
#define ADDR_SD_ADDR         0x01B0
#define ADDR_SD_RW_END       0x01B4
#define ADDR_DEFECT_MAP      0x01B8
#define ADDR_ROIC_TEMP0      0x01BC
#define ADDR_ROIC_TEMP1      0x01C0
#define ADDR_ROIC_TEMP2      0x01C4
#define ADDR_ROIC_TEMP3      0x01C8
#define ADDR_ROIC_TEMP4      0x01CC
#define ADDR_ROIC_TEMP5      0x01D0
#define ADDR_ROIC_TEMP6      0x01D4
#define ADDR_ROIC_TEMP7      0x01D8
#define ADDR_ROIC_TEMP8      0x01DC
#define ADDR_ROIC_TEMP9      0x01E0
#define ADDR_ROIC_TEMP10     0x01E4
#define ADDR_ROIC_TEMP11     0x01E8
#define ADDR_MPC_NUM         0x01EC
#define ADDR_MPC_POINT0      0x01F0
#define ADDR_MPC_POINT1      0x01F4
#define ADDR_MPC_POINT2      0x01F8
#define ADDR_MPC_POINT3      0x01FC
#define ADDR_RST_NUM         0x0200
#define ADDR_BRIGHT          0x0204
#define ADDR_CONTRAST        0x0208
#define ADDR_EXT_TRIG_HIGH   0x020C
#define ADDR_EXT_TRIG_PERIOD 0x0210
#define ADDR_EXT_TRIG_ACTIVE 0x0214
#define ADDR_FW_BUSY         0x0218
#define ADDR_SEXP_TIME       0x021C
#define ADDR_ERASE_EN        0x0220
#define ADDR_ERASE_TIME      0x0224
#define ADDR_ERASE_DONE      0x0228
#define ADDR_ROIC_TP_SEL     0x022C
#define ADDR_CLK_MCLK        0x0230
#define ADDR_CLK_DCLK        0x0234
#define ADDR_CLK_ROICDCLK    0x0238
#define ADDR_MPC_CTRL        0x023C 
// mbh 210309 offset2_cal -> mpc_ctrl dskim - 21.03.08 - offset 먼저 subtraction 하도록 변경
#define ADDR_FLA_CTRL        0x0240
#define ADDR_FLA_ADDR        0x0244
#define ADDR_FLA_DATA        0x0248
#define ADDR_SYNC_CTRL       0x024C //# 240904
#define ADDR_I2C_RDATA2      0x0250
#define ADDR_I2C_RDATA3      0x0254
#define ADDR_SYNC_RCNT0      0x0258
#define ADDR_SYNC_RCNT1      0x025C
#define ADDR_SYNC_RCNT2      0x0260
#define ADDR_SYNC_RCNT3      0x0264
#define ADDR_SYNC_RCNT4      0x0268
#define ADDR_SYNC_RCNT5      0x026C
#define ADDR_SYNC_RCNT6      0x0270
#define ADDR_SYNC_RCNT7      0x0274
#define ADDR_SYNC_RCNT8      0x0278
#define ADDR_SYNC_RCNT9      0x027C
#define ADDR_SYNC_RDATA_AVCN0 0x0280
#define ADDR_SYNC_RDATA_AVCN1 0x0284
#define ADDR_SYNC_RDATA_AVCN2 0x0288
#define ADDR_SYNC_RDATA_AVCN3 0x028C
#define ADDR_SYNC_RDATA_AVCN4 0x0290
#define ADDR_SYNC_RDATA_AVCN5 0x0294
#define ADDR_SYNC_RDATA_AVCN6 0x0298
#define ADDR_SYNC_RDATA_AVCN7 0x029C
#define ADDR_SYNC_RDATA_AVCN8 0x0300
#define ADDR_SYNC_RDATA_AVCN9 0x0304
#define ADDR_SYNC_RDATA_BGLW0 0x0308
#define ADDR_SYNC_RDATA_BGLW1 0x030C
#define ADDR_SYNC_RDATA_BGLW2 0x0310
#define ADDR_SYNC_RDATA_BGLW3 0x0314
#define ADDR_SYNC_RDATA_BGLW4 0x0318
#define ADDR_SYNC_RDATA_BGLW5 0x031C
#define ADDR_SYNC_RDATA_BGLW6 0x0320
#define ADDR_SYNC_RDATA_BGLW7 0x0324
#define ADDR_SYNC_RDATA_BGLW8 0x0328
#define ADDR_SYNC_RDATA_BGLW9 0x032C
#define ADDR_SM_CTRL        0x0330
#define ADDR_SM_DATA0       0x0334
#define ADDR_SM_DATA1       0x0338
#define ADDR_SM_DATA2       0x033C
#define ADDR_SM_DATA3       0x0340
#define ADDR_SM_DATA4       0x0344
#define ADDR_SM_DATA5       0x0348
#define ADDR_SM_DATA6       0x034C
#define ADDR_SM_DATA7       0x0350
#define ADDR_CLK_UICLK      0x0354
#define ADDR_BCAL_CTRL      0x03A0
#define ADDR_BCAL_DATA      0x03A4
//
//
#define ADDR_MPC_POSOFFSET    0x03B0
#define ADDR_FLAW_CTRL        0x03B4
#define ADDR_FLAW_CMD         0x03B8
#define ADDR_FLAW_ADDR        0x03BC
#define ADDR_FLAW_WDATA       0x03C0
#define ADDR_FLAW_RDATA       0x03C4
#define ADDR_D2M_EN           0x03C8
#define ADDR_D2M_EXP_IN       0x03CC
#define ADDR_D2M_SEXP_TIME    0x03D0
#define ADDR_D2M_FRAME_TIME   0x03D4
#define ADDR_D2M_XRST_NUM     0x03D8
#define ADDR_D2M_DRST_NUM     0x03DC
#define ADDR_TOPRST_CTRL      0x03E0
#define ADDR_DNR_CTRL         0x03E4
#define ADDR_DNR_SOBELCOEFF0  0x03E8
#define ADDR_DNR_SOBELCOEFF1  0x03EC
#define ADDR_DNR_SOBELCOEFF2  0x03F0
#define ADDR_DNR_BLUROFFSET   0x03F4
#define ADDR_ACC_STAT         0x03FC
#define ADDR_ACC_CTRL         0x0400
#define ADDR_DDR_CH4_WADDR    0x0404 // 210928 mbh
#define ADDR_DDR_CH4_RADDR    0x0408 // 210727 mbh
#define ADDR_EXT_TRIG_EN      0x040C // AUTO Offset at global shutter - serial reset offset 211025 mbh
#define ADDR_FRAME_CNT        0x0410
#define ADDR_EXT_RST_MODE     0x0414
#define ADDR_EXT_RST_DetTime  0x0418
#define ADDR_LED_CTRL         0x041C
#define ADDR_TRIGCNT          0x0420
#define ADDR_OSD_CTRL         0x0424
#define ADDR_PWDAC_CMD        0x0428
#define ADDR_PWDAC_TICKTIME   0x042c
#define ADDR_PWDAC_TICKINC    0x0430
#define ADDR_PWDAC_TRIG       0x0434
#define ADDR_PWDAC_CURRLEVEL  0x0438
#define ADDR_FPGA_DATE        0x043C
#define ADDR_TESTPOINT1       0x0440
#define ADDR_TESTPOINT2       0x0444
#define ADDR_TESTPOINT3       0x0448
#define ADDR_TESTPOINT4       0x044C
//#define ADDR_SYNCCHECKPOS   0x0450
#define ADDR_ROIC_STR         0x0450
#define ADDR_FREERUN_CNT      0x0454
#define ADDR_EDGE_CTRL        0x0458
#define ADDR_EDGE_VALUE       0x045C
#define ADDR_EDGE_TOP         0x0460
#define ADDR_EDGE_LEFT        0x0464
#define ADDR_EDGE_RIGHT       0x0468
#define ADDR_EDGE_BOTTOM      0x046C

#define ADDR_TP_VALUE         0x0470

#define ADDR_BNC_CTRL         0x0474
#define ADDR_BNC_HIGH         0x0478
//#define ADDR_               0x047C
#define ADDR_OFGA_LIM         0x0480

#define ADDR_EQ_CTRL		  0x0484
#define ADDR_EQ_TOPVAL		  0x0488

#define ADDR_SFP_STAT         0x048C  // 2604221600 SFP/RXAUI status RO: b0=sfp_phy_sel, b1=sfp_rst_done, b2=sfp_signal_detect

// 2604242200 FW-driven bit-align registers
#define ADDR_BCAL_FW_CTRL     0x0490  // [0]fw_en [4]ce [5]rst [6]bs [7]probe_rst (auto-clear) [15:8]ch_sel
#define ADDR_BCAL_FW_PAR      0x0494  // [23:0]sdata_par [24]diff_lat [25]ff00_lat [26]val [27]bs_mode
#define ADDR_BCAL_FW_STATUS   0x0498  // [4:0]ocnt [9:5]oser [14:10]obs [16]rdy
#define ADDR_BCAL_FW_RSV      0x049C  // reserved

// 2605071529 DDR AXI burst limit selector (2-bit mode: 00=32 / 01=64 / 10=128 / 11=256 beats)
#define ADDR_DDR_BURST        0x04A0
//$ 2607141553 opwr_en manual override: bit[31]=override_en, bit[10:0]=opwr_en value (max PWR_NUM=11)
#define ADDR_PWR_CTRL         0x04A4
//$ 2607241407 Short Pixel Cover: [0]en [7:4]dark(1/128/256/512/1024) [11:8]restore(65535/34/30/60000) [15:12]satref(65535/34/30/60000)
#define ADDR_SPC_CTRL         0x04A8

//# 2608191217 5th I2C slave readback (SFP DDM), same block/register family as ADDR_I2C_RDATA0..3.
//# With RSIZE=2 and I2C_MODE[15:8]=0x60: [15:0] = A2h[96..97] = int16 temperature, 1/256 degC.
#define ADDR_I2C_RDATA4       0x047C

//# 2608191217 ADDR_I2C_MODE (0x0140) field layout - no new register, bits added to the existing one
#define I2C_MODE_AUTO_BIT     (1u << 0)  // free-running slave sweep (existing behavior)
#define I2C_MODE_SFP_EN_BIT   (1u << 1)  // include slave 4 (SFP A2h 0x51) in the sweep
#define I2C_MODE_SFP_PTR_SFT  8          // [15:8] byte pointer sent to the SFP slave

//# 2608191217 SFP DDM access constants (SFF-8472 Table 9-16)
#define SFP_DDM_PTR_TEMP      0x60    // A2h byte 96: Temperature MSB

//# 2608191706 Marvell PHY temperature sensor, MMD 31 (MTD_C_UNIT_GENERAL).
//# Register split per mtd_api/mtdApiRegs.h:113-114 - the FW used to read the CTRL
//# register by mistake, which is why it needed a 20C fudge. Now reads DATA like
//# mtdReadTemperature() (mtdDiagnostics.c:1934) does.
#define PHY_TEMP_REG_CTRL     0xF08A  // MTD_CUNIT_TEMP_SENSOR_CTRL (enable only)
#define PHY_TEMP_REG_DATA     0xF08C  // MTD_CUNIT_TEMP_SENSOR      (reading)
#define PHY_TEMP_OFS_STD      75      // mtdReadTemperature(): (s16)(raw & 0xFF) - 75

//# 2608191733 IC die temperature -> set (enclosure) temperature, for FPGA / PHY / SFP.
//# A fixed subtraction is wrong physics: die temp = ambient + self-heating, and a module
//# just plugged in from a 26C room has no self-heating yet, so "raw - 10" reported 16C.
//# Scale the rise above ambient instead, so the correction fades out as the part cools:
//#     T_set = ANCHOR + (T_ic - ANCHOR) * (SPAN - REF_OFS) / SPAN,  SPAN = REF_IC - ANCHOR
//#     T_ic <= ANCHOR -> reported as-is (nothing to remove)
//# Tuning: REF_OFS is the reduction wanted at REF_IC, i.e. the old fixed offset.
#define TEMP_ANCHOR_C         20.0f  // cold start: sensor == set temperature
#define TEMP_REF_IC_C         50.0f  // typical steady-state die reading
#define TEMP_REF_OFS_C        10.0f  // wanted reduction at TEMP_REF_IC_C

// 2604242200 BCAL_FW_CTRL bit positions
#define BCAL_FW_CTRL_EN_BIT        (1u << 0)
#define BCAL_FW_CTRL_CE_PULSE      (1u << 4)
#define BCAL_FW_CTRL_RST_PULSE     (1u << 5)
#define BCAL_FW_CTRL_BS_PULSE      (1u << 6)
#define BCAL_FW_CTRL_PROBE_PULSE   (1u << 7)
#define BCAL_FW_CTRL_CH_SHIFT      (8)

#define ADDR_FPGA_REBOOT      0x1000

#if defined EXT4343R // neg led ctrl 220118mbh
    #define LED_CTRL_OFF 1
    #define LED_CTRL_ON  0
#else
    #define LED_CTRL_OFF 0
    #define LED_CTRL_ON  1
#endif

#define LED_CTRL_BLINK_0P25S 2
#define LED_CTRL_BLINK_0P5S  3
#define LED_CTRL_BLINK_1S    4

#define MCLK_062   62
#define MCLK_125   125
#define MCLK_120   120
#define MCLK_200   200
#define MCLK_160   160 //$ 241213 jyp
#define MCLK_180   180 //# 260514
#define MCLK_250   250 //$ 251121
#define MCLK_300   300 //$ 251230
#define MCLK_320   320 //$ 251121

#define CMDSTR_256   256
#define CMDSTR_512   512
#define CMDSTR_1024 1024

#define TIRST_350   350
#define TIRST_500   500
#define TIRST_1000 1000
#define TIRST_1500 1500 //$ 2607021050 3643R shs>oe feasibility
#define TIRST_2000 2000
#define TIRST_3000 3000
#define TIRST_4000 4000 //$ 241213 jyp

#define LPF1_500     500
#define LPF1_1000   1000
#define LPF1_1200   1200
#define LPF1_1500   1500 //$ 2607021050 3643R shs>oe feasibility
#define LPF1_1750   1750
#define LPF1_2000   2000
#define LPF1_3000   3000
#define LPF1_4000   4000

#define LPF2_1750   1750
#define LPF2_3500   3500 //$ 251121
#define LPF2_2000   2000
#define LPF2_2500   2500
#define LPF2_7500   7500 //$ 2607021050 3643R shs>oe feasibility
#define LPF2_4000   4000
#define LPF2_6000   6000
#define LPF2_8000   8000
#define LPF2_10000 10000
#define LPF2_12000 12000
#define LPF2_14000 14000
#define LPF2_15000 15000
#define LPF2_16000 16000

#define TGATE_1000	 1000
#define TGATE_1100   1100
#define TGATE_1500   1500
#define TGATE_2000   2000
#define TGATE_2500	 2500
#define TGATE_3000   3000
#define TGATE_4000   4000
#define TGATE_5000   5000
#define TGATE_6000   6000
#define TGATE_7000   7000
#define TGATE_8000   8000
#define TGATE_10000 10000

#define FILTER_4 4
#define FILTER_5 5

#define OPER_TIME_OVERTIME 300 // 5m

/*
#if (defined(EXT4343R)     ||\
     defined(EXT4343R_1)   ||\
     defined(EXT4343R_2)   ||\
     defined(EXT4343R_3)   ||\
     defined(EXT4343RC)    ||\
     defined(EXT4343RC_1)  ||\
     defined(EXT4343RC_2)  ||\
     defined(EXT4343RC_3)  ||\
     defined(EXT4343RCL)   ||\
     defined(EXT4343RCL_1) ||\
     defined(EXT4343RCL_2) ||\
     defined(EXT4343RCL_3) ||\
     defined(EXT4343RI_2)   ||\
     defined(EXT4343RCI_1)  ||\
     defined(EXT4343RCI_2))
    #define EXT4343R_SERIES
#endif

#if (defined(EXT2430R) ||\
     defined(EXT2430RI))
    #define EXT2430R_SERIES
#endif

#if (defined(EXT810R) ||\
     defined(EXT2430RD))
    #define DIRECT_SERIES
#endif
*/

//#if defined(EXT1616R)
//    #if defined(EXT2430R_SERIES) || defined(EXT2832R) || defined(EXT4343R_SERIES) || defined(DIRECT_SERIES) || defined(EXT1024R)
//        #error "You must choose only one model."
//    #endif
//#elif defined(EXT4343R)
//    #if defined(EXT1616R) || defined(EXT1616RL) || defined(EXT2430R_SERIES) || defined(EXT2832R) || defined(DIRECT_SERIES) || defined(EXT1024R)
//        #error "You must choose only one model."
//    #endif
//#elif defined(EXT2430R_SERIES)
//    #if defined(EXT1616R) || defined(EXT1616RL) || defined(EXT4343R_SERIES) || defined(EXT2832R)  || defined(DIRECT_SERIES) || defined(EXT1024R)
//        #error "You must choose only one model."
//    #endif
//#elif defined(EXT2832R)
//    #if defined(EXT1616R) || defined(EXT1616RL) || defined(EXT2430R_SERIES) || defined(EXT4343R_SERIES) || defined(DIRECT_SERIES) || defined(EXT1024R)
//        #error "You must choose only one model."
//    #endif
//#elif defined(DIRECT_SERIES)
//    #if defined(EXT1616R) || defined(EXT1616RL) ||  defined(EXT2430R_SERIES) || defined(EXT2832R) || defined(EXT4343R_SERIES) || defined(EXT1024R)
//        #error "You must choose only one model."
//    #endif

// 241014 jyp
//#elif defined(EXT1024R)
//    #if defined(EXT1616R) || defined(EXT1616RL) ||  defined(EXT2430R_SERIES) || defined(EXT2832R) || defined(EXT4343R_SERIES) || defined(DIRECT_SERIES)
//        #error "You must choose only one model."
//    #endif
//#else
//    #error "You choose one model."
//#endif

typedef struct
{
    u32 mclk;
    u32 cmdstr;
    u32 tirst;
    u32 tshr_lpf1;
    u32 tshs_lpf2;
    u32 tgate;
    u32 filter;
    u32 m_clock;
} Profile_Def; // dskim - 21.07.22

typedef struct
{
    Profile_Def init;
    Profile_Def d2;
} Profile_HandleDef; // dskim - 21.07.22

extern const char mEXT1024     [16];
extern const char mEXT1024RL   [16]; //$ 250703
extern const char mEXT1616R    [16];
extern const char mEXT1616RL   [16];
extern const char mEXT2430R    [16];
extern const char mEXT2430RI   [16];
extern const char mEXT2832R    [16];
extern const char mEXT2832R_2  [16];
extern const char mEXT4343R    [16];
extern const char mEXT4343R_1  [16];
extern const char mEXT4343R_2  [16];
extern const char mEXT4343R_3  [16];
extern const char mEXT4343R_4  [16];
extern const char mEXT4343RC   [16];
extern const char mEXT4343RC_1 [16];
extern const char mEXT4343RC_2 [16];
extern const char mEXT4343RC_3 [16];
extern const char mEXT4343RCL_1[16];
extern const char mEXT4343RCL_2[16];
extern const char mEXT4343RCL_3[16];
extern const char mEXT810R     [16];
extern const char mEXT2430RD   [16];
extern const char mEXT4343RI_2 [16];
extern const char mEXT4343RI_4 [16];
extern const char mEXT4343RCI_1[16];
extern const char mEXT4343RCI_2[16];
extern const char mEXT4343RD   [16];
extern const char mEXT3643R	   [16];
extern const char mEXT0        [16];


extern u32 FPGA_TFT_MAIN_CLK;
extern u32 FPGA_TFT_DATA_CLK;
extern u32 MAX_WIDTH      ;
extern u32 MAX_WIDTH_x32  ;
extern u32 MAX_HEIGHT     ;
extern u32 PIXEL_WIDTH    ;
extern u32 ROIC_DUAL      ;
extern u32 ROIC_MAX_CH    ;
extern u32 ROIC_CH        ;
extern u32 GATE_CH        ;
extern u32 GATE_MAX_CH    ;
extern u32 GATE_DUMMY_LINE;
//$ 2604291608 Add EXT3643R sensor base offset (cropped border)
extern u32 BASE_OFFSETX;
extern u32 BASE_OFFSETY;
extern u32 ROIC_DUMMY_LINE;
extern u32 ROIC_DUMMY_CH  ;
extern u32 ROIC_NUM       ;
extern u32 GATE_NUM       ;
extern u32 GATE_CHECK     ;
//extern u32 DS1731_NUM     ;

extern float MAX_FRATE;
extern u32 def_gev_speed;
extern u32 ETHERSPEED_B;
extern u8  GIGE_MINFO[48];
extern u32 func_gainref_numlim;

extern u32 FLASH_1GBIT;
extern u32 TFT_TIMING_MODE;
extern u32 mEXT4343R_series;
extern u32 mEXT1616R_series;
extern u32 mEXT2832R_series;
extern u32 mEXT2430R_series;
extern u32 mEXT1024_series; // 241014 jyp
extern u32 mEXT3643R_series;
extern u32 def_sfp_port; //$ 2606171455 SFP port enable flag (EXT3643R only)

extern u32 AFE3256_series;

extern u8 func_able_binn_num; //# 230926 //# 250317
extern u8 func_able_gain_num;
extern u8 func_able_dnr;
extern u8 func_able_acc;
//extern u8 func_gige_disconnected;   //# 2605131508 1=gige link down (composer forces ADDR_DDR_CH_EN=0)
//# 2605131659 ADDR_DDR_CH_EN force-off tokens (separate per source, OR-combined in composer)
extern u8 func_ddrchen_gigedisconn_stat;   //# 2605131659 1=gige link down (forces ADDR_DDR_CH_EN=0)
extern u8 func_ddrchen_gcal_stat;          //# 2605131659 1=gcal in progress (forces ADDR_DDR_CH_EN=0)

void load_fpga_model(void);
void load_gev_speed(void);
void load_frame_rate(void);
void load_func_able(void);
int msame ( const char* mEXT );
void load_tempbcal(void);
extern u8 def_tempbcal;

#endif /* SRC_FPGA_INFO_H_ */
