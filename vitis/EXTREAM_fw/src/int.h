/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  int.h                                                           */
/*    Date :  2016-07-11                                                      */
/*     Rev :  0.2                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design interrupt include file                       */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2011-12-19  |  JP  |  Initial release                             */
/*  0.2  |  2016-07-11  |  JP  |  Updated for recent MicroBlaze               */
/******************************************************************************/

#ifndef _INT_H_
#define _INT_H_


// ---- Global variables -------------------------------------------------------

// System library first level interrupt handlers
extern int _start1;
extern int _exception_handler;
extern int _hw_exception_handler;
extern int __interrupt_handler;


// ---- Register bits ----------------------------------------------------------

// Interrupt masks
#define INT_MASK_GIGE   XPAR_SYSTEM_CPU_IRQ_0_MASK
#define INT_MASK_FB     XPAR_SYSTEM_CPU_IRQ_1_MASK


// ---- Function prototypes ----------------------------------------------------

void int_refresh_vectors(void);
void int_init(void);
void int_handler(void);


#endif
