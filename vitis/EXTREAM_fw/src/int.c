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

// Enable some IRQ specific debugging
//#define _IRQ_DBG_


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
        func_printf("[IRQ] GigE core:   0x%08X\r\n", gige_get_int_status());
        gige_clr_int_req();
        XIntc_AckIntr(XPAR_INTC_0_BASEADDR, INT_MASK_GIGE);
    }

    // Framebuffer interrupts
    if (XIntc_GetIntrStatus(XPAR_INTC_0_BASEADDR) & INT_MASK_FB)
    {
        func_printf("[IRQ] Framebuffer: 0x%08X\r\n", framebuf_int_req);
        framebuf_int_req = 0xFFFFFFFF;
        XIntc_AckIntr(XPAR_INTC_0_BASEADDR, INT_MASK_FB);
    }

    return;
}
