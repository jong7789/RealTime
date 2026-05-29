/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  int.c                                                           */
/*    Date :  2016-08-19                                                      */
/*     Rev :  0.3                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design interrupt functions                          */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2011-12-19  |  JP  |  Initial release                             */
/*  0.2  |  2016-07-11  |  JP  |  Updated for recent MicroBlaze               */
/*  0.3  |  2016-08-19  |  JP  |  Fixed problem with Release configuration    */
/******************************************************************************/

#include <xparameters.h>
#include <mb_interface.h>
#include <xintc_l.h>
#include <stdio.h>
#include "gige.h"
#include "framebuf.h"
#include "int.h"
#include "func_printf.h"
#include "xil_types.h"      //# 2605181144 u8 type for runtime toggles

// Enable some IRQ specific debugging
//#define _IRQ_DBG_

/*
 * //# 2605151745 Per-frame TX-complete '.' UART progress indicator
 *  Purpose:    Emit one '.' to UART on every framebuffer TX-complete IRQ so the
 *              user can visually confirm GEV streaming throughput from the
 *              serial console without needing a host viewer.
 *  Why:        FRAMEBUF_INT_TX (framebuf.h bit 0) is latched by the framebuf IP
 *              once per data block (= one GVSP frame) — see FB-AXI IP spec
 *              Table 22 (req_tx: "New data block has been transmitted").
 *  Reference:  cores/s2i_framebuf_2.2.6/doc/FB-AXI_IP_spec.pdf p.30
 *  Toggle:     Set FB_TX_DOT_EN to 0 to silence; 1 to enable.
 *  Note:       Runs in ISR context, so we use xil_printf (single char, no
 *              vsprintf overhead like func_printf) and skip the GEV mirror
 *              path (gige_send_message4) to keep ISR latency low.
 */
//#define FB_TX_DOT_EN    0
//#define FB_ERR_MSG_EN   1
/*
 * //# 2605181144 fdot UART cmd: compile-time toggles -> runtime globals
 *  fb_tx_dot_en : per-frame '.' progress on TX-complete IRQ
 *  fb_err_msg_en: rising-edge FB overflow UART message
 *  Both togglable at runtime via 'fdot 0|1' / 'ferr 0|1' UART command.
 */
volatile u8 fb_tx_dot_en  = 0;
volatile u8 fb_err_msg_en = 1;
#define FRAMEBUF_S_ERR_MASK (FRAMEBUF_S_DF_OVFLW | FRAMEBUF_S_RF_OVFLW | \
                             FRAMEBUF_S_IF_OVFLW | FRAMEBUF_S_TF_OVFLW)


// ---- Insert unconditional jump instruction ----------------------------------
//
//  The function inserts a machine code jump instruction to the destination
//  address "dest". The instruction is placed to the address "addr".
//
void __attribute__((optimize("O0"))) insert_jump(int addr, int dest)
{
    *(int*)(addr    ) = 0xB0000000 | ((dest & 0xFFFF0000) >> 16);
    *(int*)(addr + 4) = 0xB8080000 | ((dest & 0x0000FFFF));

    return;
}


// ---- Debug reset vectors ----------------------------------------------------
//
//  Print out contents of the reset/exception/interrupt vector memory
//
#ifdef _IRQ_DBG_
void dbg_print_vectors(int num, int fmt)
{
    int i;

    for (i = 0; i < num; i++)
    {
        if (!(i % fmt))
        {
            if (i)
                func_printf("\r\n");
            func_printf("[DBG] ADDR(0x%04X) =", i * 4);
        }
        func_printf(" 0x%08X", *(int*)(i * 4));
    }
    func_printf("\r\n");

    return;
}
#endif


// ---- Regenerate vectors -----------------------------------------------------
//
//  The function regenerates the reset, exception, and interrupt vectors.
//  It needs to be executed after booting a striped firmware image from flash.
//
void int_refresh_vectors(void)
{
#ifdef _IRQ_DBG_
    dbg_print_vectors(0x28 / 4, 4);
#endif

    insert_jump(0x00, (int)&_start1);               // Reset vector
    insert_jump(0x08, (int)&_exception_handler);    // Software exception vector
    insert_jump(0x10, (int)&__interrupt_handler);   // Interrupt vector
    insert_jump(0x20, (int)&_hw_exception_handler); // Hardware exception vector

#ifdef _IRQ_DBG_
    dbg_print_vectors(0x28 / 4, 4);
#endif

    return;
}


// ---- Initialization of the interrupt subsystem ------------------------------
//
//  This function initializes and enables all the interrupt sources.
//
void int_init(void)
{
    // Refresh interrupt vectors and register interrupt handler
    int_refresh_vectors();
    microblaze_register_handler((XInterruptHandler)int_handler, (void *)0);

    // Acknowledge pending requests and enable interrupt controller
    XIntc_AckIntr(XPAR_INTC_0_BASEADDR, INT_MASK_GIGE | INT_MASK_FB);
    XIntc_EnableIntr(XPAR_INTC_0_BASEADDR, INT_MASK_GIGE | INT_MASK_FB);
    XIntc_MasterEnable(XPAR_INTC_0_BASEADDR);

    // Enable GigE core interrupts
    gige_clr_int_req();             // Clear pending GigE interrupt requests
    gige_set_int_mask(0x80000003);  // Enable GigE RX, TX, and global interrupts

    // Enable framebuffer interrupts
    framebuf_int_req  = 0xFFFFFFFF; // Clear pending framebuffer requests
    framebuf_int_mask = 0xFFFFFFFF; // Enable all framebuffer interrupt sources

    // Enable CPU interrupts
    microblaze_enable_interrupts();

    return;
}


// ---- Interrupt handler ------------------------------------------------------
//
//  Main interrupt service routine.
//
void int_handler(void)
{
    // GigE core interrupts
    if (XIntc_GetIntrStatus(XPAR_INTC_0_BASEADDR) & INT_MASK_GIGE)
    {
        // func_printf("[IRQ] GigE core:   0x%08X\r\n", gige_get_int_status());
        gige_clr_int_req();
        XIntc_AckIntr(XPAR_INTC_0_BASEADDR, INT_MASK_GIGE);
    }

    // Framebuffer interrupts
    if (XIntc_GetIntrStatus(XPAR_INTC_0_BASEADDR) & INT_MASK_FB)
    {
        //# 2605151745 Per-frame TX-complete '.' progress (toggle via FB_TX_DOT_EN)
//        func_printf("[IRQ] Framebuffer: 0x%08X\r\n", framebuf_int_req);
//#if FB_TX_DOT_EN
//        if (framebuf_int_req & FRAMEBUF_INT_TX)
//            xil_printf(".");
//#endif
        //# 2605181144 fdot runtime gate (fb_tx_dot_en, was #if FB_TX_DOT_EN)
        if (fb_tx_dot_en && (framebuf_int_req & FRAMEBUF_INT_TX))
            xil_printf(".");                    // 1-byte UART write per frame

//#if FB_ERR_MSG_EN  ... #endif  (gate moved to runtime)
        //# 2605181144 ferr runtime gate (fb_err_msg_en, was #if FB_ERR_MSG_EN)
        if (fb_err_msg_en && (framebuf_int_req & FRAMEBUF_INT_TX))
        {
            static uint32_t fb_err_last = 0;
            uint32_t        s    = framebuf_status & FRAMEBUF_S_ERR_MASK;
            uint32_t        rise = s & ~fb_err_last;    // rising-edge only

            if (rise)
                xil_printf("\r\n[FBERR] status=0x%08X DF/RF/IF/TF=%c%c%c%c\r\n",
                            framebuf_status,
                            (s & FRAMEBUF_S_DF_OVFLW) ? 'D' : '-',
                            (s & FRAMEBUF_S_RF_OVFLW) ? 'R' : '-',
                            (s & FRAMEBUF_S_IF_OVFLW) ? 'I' : '-',
                            (s & FRAMEBUF_S_TF_OVFLW) ? 'T' : '-');
            fb_err_last = s;
        }
        framebuf_int_req = 0xFFFFFFFF;          // W1C: clear all latched req bits
        XIntc_AckIntr(XPAR_INTC_0_BASEADDR, INT_MASK_FB);
    }

    return;
}
