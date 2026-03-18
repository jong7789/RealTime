/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  user.h                                                          */
/*    Date :  2013-01-07                                                      */
/*     Rev :  0.1                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design networking functions                         */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2013-01-07  |  JP  |  Initial release                             */
/******************************************************************************/

#include <stdlib.h>
#include <xparameters.h>
#include "gige.h"


// ---- Processing of data received on UDP Telnet port -------------------------
//
//           This function must be always implemented!
//           It is called by the gige_callback() from libgige
//
//           Access: nc -u <ip_address> 23
//
// length  = number of received data bytes
// data    = pointer to data buffer
//
void telnet_user_process(u32 length, u8 *data)
{
    // Echo received data back to remote host
    telnet_send(length, data);

    return;
}


// ---- Process incoming generic UDP packet ------------------------------------
//
//           This function must be always implemented!
//           It is called by the gige_callback() from libgige
//
void udp_process(void)
{
    return;
}


// ---- Process incoming TCP packet --------------------------------------------
//
//           This function must be always implemented!
//           It is called by the gige_callback() from libgige
//
void tcp_process(void)
{
    return;
}


// ---- Process incoming generic IP packet -------------------------------------
//
//           This function must be always implemented!
//           It is called by the gige_callback() from libgige
//
void ip_process(void)
{
    return;
}
