/******************************************************************************/
/*  GigE Vision Device Firmware                                               */
/*----------------------------------------------------------------------------*/
/*    File :  framebuf.c                                                      */
/*    Date :  2021-03-09                                                      */
/*     Rev :  1.5                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  Template of the AXI framebuffer control functions to be used in a device  */
/*  user firmware                                                             */
/*----------------------------------------------------------------------------*/
/*  1.0  |  2020-04-29  |  JP  |  Initial version based on a reference design */
/*  1.1  |  2020-05-20  |  JP  |  Calculation of current SCPS increment       */
/*  1.2  |  2020-06-05  |  JP  |  Portable for 32b/64b platforms              */
/*  1.3  |  2021-02-16  |  JP  |  Wide AXI address support                    */
/*  1.4  |  2021-03-08  |  JP  |  Updated static buffer address allocation,   */
/*       |              |      |  compatible with 64b address on 32b platform */
/*  1.5  |  2021-03-09  |  MAS |  Extended Chunk mode support added           */
/******************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <inttypes.h>
// TODO: Include correct platform-dependent header file here!
#include <xparameters.h>
#include "framebuf.h"
#include "gige.h"
#include "user.h"


// Fixed start address of the static buffer (not dynamically allocated)
// TODO: Uncomment and set appropriate address for static buffer!
//#define _FRAMEBUF_DEDICATED_RAM_ 0x0000000000000000


// ---- Global variables -------------------------------------------------------
//
volatile uint16_t framebuf_pad_x;   // Line padding
volatile uint16_t framebuf_pad_y;   // Block (frame) padding
volatile uint64_t framebuf_bpb;     // Total bytes per block


// ---- Initialization of the framebuffer --------------------------------------
//
//               Initialization of the framebuffer. The function returns pointer
//               to the memory allocated for the framebuffer.
//
//         NOTE: The return value is not correct for statically allocated buffer
//               on 32b platform starting at 64b address above 4GB!
//
// low_latency = enable the low-latency readout mode
// deinterlace = perform de-interlacing of the interlaced video
// gev1mode    = operate in GEV 1.x compatibility mode
//               0: GEV 2.x (64b block id, extended GVSP status codes)
//               1: GEV 1.x (16b block id, no extended GVSP status codes)
// size        = number of bytes to allocate
//
void *framebuf_init(int low_latency, int deinterlace, int gev1mode, uint64_t size)
{
    void *fb;
    uint64_t bl, dw, align, fb_len, fb_bot;

    // Framebuffer core check
    if (framebuf_id != 0xA5A50005)
    {
        printf("[UU] No framebuffer core found!\r\n");
        return NULL;
    }

    // Allocate space for the framebuffer (aligned to burst length address)
    bl     = ((framebuf_status & FRAMEBUF_S_BURST) >> 8) + 1;   // AXI burst length in words
    dw     = 1 << (framebuf_status & FRAMEBUF_S_BITS_AXI);      // AXI data width in bytes
    align  = (bl * dw) - 1;                                     // AXI burst length in bytes - 1
    fb_len = size & (~align);
#ifndef _FRAMEBUF_DEDICATED_RAM_
    // Frame buffers in CPU shared RAM
    fb = malloc(fb_len + align);
    if (!fb)
    {
        printf("[MBH] fb=%d, size=0x%08x\r\n",(int)fb,fb_len + align);
        printf("[UU] Error allocating memory for the framebuffer!\r\n");
        return NULL;
    }
    fb     = (void *)(((uintptr_t)fb + (uintptr_t)align) & (uintptr_t)(~align));
    fb_bot = (uint64_t)((uintptr_t)fb);
#else
    // Frame buffers in dedicated separate RAM (not shared with CPU)
    fb_bot = _FRAMEBUF_DEDICATED_RAM_;
    fb     = (void *)(uintptr_t)fb_bot;
#endif

    // Initialize framebuffer
    framebuf_bot_h      = (uint32_t)(fb_bot >> 32);
    framebuf_bot_l      = (uint32_t)(fb_bot & 0xFFFFFFFF);
    framebuf_top_h      = (uint32_t)((fb_bot + fb_len) >> 32);
    framebuf_top_l      = (uint32_t)((fb_bot + fb_len) & 0xFFFFFFFF);
    framebuf_control    = FRAMEBUF_C_LEADTS | FRAMEBUF_C_INIT | FRAMEBUF_C_CLRSTAT |
                          (low_latency ? RDMODE_LOW_LAT     : 0) |
                          (deinterlace ? FRAMEBUF_C_DEINT   : 0) |
                          (gev1mode    ? FRAMEBUF_C_BID16B  : 0) |
                          (!gev1mode   ? FRAMEBUF_C_EXTSTAT : 0);
    framebuf_pld_type   = PLD_IMAGE;    // Default is PLD_IMAGE, switching to chunk mode is done from user firmware with function framebuf_set_pld_type
    framebuf_lead_offs  = 0x0000;
    framebuf_trail_offs = 0x0400;

    // Enable dynamic trailers
    //framebuf_control = framebuf_control | FRAMEBUF_C_DYNTRAIL;

    // Print IP core information
    printf("[UU] Framebuffer version %" PRIu32 ".%" PRIu32 ".%" PRIu32 " (%04" PRIX32 "-%02" PRIX32 "-%02" PRIX32 ")\r\n",
           framebuf_version >> 24, (framebuf_version >> 16) & 0xFF, framebuf_version & 0xFFFF,
           framebuf_date >> 16, (framebuf_date >> 8) & 0xFF, framebuf_date & 0xFF);
    printf("     0x%016" PRIX64 " bytes at 0x%016" PRIX64 ", alignment %" PRIu64 " bytes\r\n",
           fb_len, fb_bot, align + 1);

    return fb;
}


// ---- Set payload type -------------------------------------------------------
//
void framebuf_set_pld_type(uint32_t pld_type)
{
    framebuf_pld_type = pld_type;
}


// ---- Calculation of frame padding and bytes per block -----------------------
//
//         This function updates current x/y padding and total bytes per block
//         global variables according to the pixel format, width, and height
//
// pixel_format = GenICam pixel format
// size_x       = video frame width
// size_y       = video frame height
// size_chunk   = size of chunk data
//
#define DBG_fbPadding 0
void framebuf_padding(uint32_t pixel_format, uint32_t size_x, uint32_t size_y, uint32_t size_chunk)
{
    uint32_t burst, bpp, temp;

    // Burst length in bytes and bytes per pixel
    burst = (((framebuf_status & FRAMEBUF_S_BURST) >> 8) + 1) * (1 << (framebuf_status & FRAMEBUF_S_BITS_AXI));
    bpp   = (((pixel_format & 0x00FF0000) >> 16) + 7) / 8;

    // Padding
    if (framebuf_control & FRAMEBUF_C_DEINT)    // Interlaced scan
    {
        temp = burst - ((size_x * bpp) % burst);
        if (temp >= burst)
            temp = 0;
        framebuf_pad_x = temp;
        framebuf_pad_y = 0;
    }
    else                                        // Progressive scan
    {
        if (size_chunk == 0)
        {
            temp = burst - ((size_x * size_y * bpp) % burst);
            if (temp >= burst)
                temp = 0;
            framebuf_pad_x = 0;
            framebuf_pad_y = temp;
        }
        else
        {
            // No image padding for progressive scan and chunk mode
            framebuf_pad_x = 0;
            framebuf_pad_y = 0;

        }
    }

    // Total bytes per block
    framebuf_bpb = ((((uint64_t)size_x * (uint64_t)bpp) + (uint64_t)framebuf_pad_x) * (uint64_t)size_y) + (uint64_t)framebuf_pad_y + (uint64_t)size_chunk;

    // Set safe maximum block length (total bytes per block + 1 burst)
    framebuf_blk_max_h = (uint32_t)((framebuf_bpb + (uint64_t)burst) >> 32);
    framebuf_blk_max_l = (uint32_t)((framebuf_bpb + (uint64_t)burst) & 0xFFFFFFFF);

    if(DBG_fbPadding)func_printf("[DBG_fbPadding] size_x=%d\r\n",size_x);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] bpp=%d\r\n",bpp);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] framebuf_pad_x=%d\r\n",framebuf_pad_x);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] size_y=%d\r\n",size_y);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] framebuf_pad_y=%d\r\n",framebuf_pad_y);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] size_chunk=%d\r\n",size_chunk);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] framebuf_bpb=%d\r\n",framebuf_bpb);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] framebuf_blk_max_h=%d\r\n",framebuf_blk_max_h);
    if(DBG_fbPadding)func_printf("[DBG_fbPadding] framebuf_blk_max_l=%d\r\n",framebuf_blk_max_l);


    return;
}


// ---- Get currently supported SCPS increment ---------------------------------
//
uint32_t framebuf_scps_inc(void)
{
    uint32_t dw = 1 << ( framebuf_status & FRAMEBUF_S_BITS_AXI);
    uint32_t ow = 1 << ((framebuf_status & FRAMEBUF_S_BITS_OUT) >> 24);

    return (dw >= ow ? dw : ow);
}


// ---- Initialize image leader packet -----------------------------------------
//
void framebuf_img_leader(uint32_t pixel_format, uint32_t size_x, uint32_t size_y, uint32_t offset_x, uint32_t offset_y)
{
    // Calculate padding and bytes per block
    // ... use precalculated globals instead!
//  framebuf_padding(pixel_format, size_x, size_y);

    // Load leader packet DPRAM
    framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 0] = pixel_format;
    framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 1] = size_x;
    framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 2] = size_y;
    framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 3] = offset_x;
    framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 4] = offset_y;
    framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 5] = ((uint32_t)framebuf_pad_x << 16) | ((uint32_t)framebuf_pad_y & 0xFFFF);
    // Total payload length is needed for U3V core only!
//  framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 6] = 0;
//  framebuf_pkt_dpram[(framebuf_lead_offs / 4) + 7] = framebuf_bpb;

    // Leader packet payload length
    framebuf_lead_len = 24;

    return;
}


// ---- Initialize image trailer packet ----------------------------------------
//
void framebuf_img_trailer(uint32_t size_y, uint32_t chunk_layout_id)
{
    // Load trailer packet DPRAM (not needed if dynamic trailers are activated)
    framebuf_pkt_dpram[(framebuf_trail_offs / 4) + 0] = size_y;

   // Trailer packet payload length (also needed if dynamic trailers are activated!)
    if (video_chunk_ctrl & 0x80000000)    //check if chunks are activated
    {
        framebuf_pkt_dpram[(framebuf_trail_offs / 4) + 1] = framebuf_bpb;
        framebuf_pkt_dpram[(framebuf_trail_offs / 4) + 2] = chunk_layout_id;
        framebuf_trail_len = 12;
    }
    else
    {
        framebuf_trail_len = 4;
    }

    return;
}


// ---- List contents of the registers -----------------------------------------
//
void framebuf_printregs(void)
{
    uint32_t i;

    printf("ID registers:\r\n");
    printf("  Core ID               = 0x%08" PRIX32 "\r\n", framebuf_id);
    printf("  Version               = %" PRIu32 ".%" PRIu32 ".%" PRIu32 "\r\n", framebuf_version >> 24, (framebuf_version >> 16) & 0xFF, framebuf_version & 0xFFFF);
    printf("  Build date            = %04" PRIX32 "-%02" PRIX32 "-%02" PRIX32 "\r\n", framebuf_date >> 16, (framebuf_date >> 8) & 0xFF, framebuf_date & 0xFF);
    printf("Control registers:\r\n");
    printf("  Control               = 0x%08" PRIX32 "\r\n", framebuf_control);
    printf("  Framebuffer bottom    = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_bot_h, framebuf_bot_l);
    printf("  Framebuffer top + 1   = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_top_h, framebuf_top_l);
    printf("  Maximum block length  = 0x%08" PRIX32 "_%08" PRIX32 " = %" PRIu64 "\r\n", framebuf_blk_max_h, framebuf_blk_max_l,
                                                                                        ((uint64_t)framebuf_blk_max_h << 32) | (uint64_t)framebuf_blk_max_l);
    printf("  Leader DPRAM offset   = 0x%04" PRIX32 "\r\n", framebuf_lead_offs);
    printf("  Leader length         = %" PRIu32 "\r\n", framebuf_lead_len);
    printf("  Trailer DPRAM offset  = 0x%04" PRIX32 "\r\n", framebuf_trail_offs);
    printf("  Trailer length        = %" PRIu32 "\r\n", framebuf_trail_len);
    printf("Status registers:\r\n");
    printf("  Status                = 0x%08" PRIX32 "\r\n", framebuf_status);
    printf("                          %u bits input + AXI data width\r\n", 8 * (1 << (framebuf_status & FRAMEBUF_S_BITS_AXI)));
    printf("                          %u bits output data width\r\n", 8 * (1 << ((framebuf_status & FRAMEBUF_S_BITS_OUT) >> 24)));
    printf("                          %" PRIu32 " words bursts\r\n", 1 + ((framebuf_status & FRAMEBUF_S_BURST) >> 8));
    if (framebuf_status & FRAMEBUF_S_DYNTRAIL)
        printf("                          dynamic and external trailers supported\r\n");
    if (framebuf_status & FRAMEBUF_S_DF_OVFLW)
        printf("                          descriptor FIFO overflowed\r\n");
    if (framebuf_status & FRAMEBUF_S_RF_OVFLW)
        printf("                          resend FIFO overflowed\r\n");
    if (framebuf_status & FRAMEBUF_S_IF_OVFLW)
        printf("                          input FIFO overflowed\r\n");
    if (framebuf_status & FRAMEBUF_S_IF_EMPTY)
        printf("                          input FIFO empty\r\n");
    if (framebuf_status & FRAMEBUF_S_TF_OVFLW)
        printf("                          trailer FIFO overflowed\r\n");
    if (framebuf_status & FRAMEBUF_S_DF_FULL)
        printf("                          descriptor FIFO is full\r\n");
    if (framebuf_status & FRAMEBUF_S_WR_ACT)
        printf("                          memory write active\r\n");
    if (framebuf_status & FRAMEBUF_S_RD_ACT)
        printf("                          memory read active\r\n");
    printf("  Descr. FIFO writes    = %" PRIu32 "\r\n", framebuf_desc_wr);
    printf("  Descr. FIFO reads     = %" PRIu32 "\r\n", framebuf_desc_rd);
    printf("  Descr. FIFO drops     = %" PRIu32 "\r\n", framebuf_desc_drop);
    printf("  Write dropped blocks  = %" PRIu32 "\r\n", framebuf_wr_drop);
    printf("  Write no space in FB  = %" PRIu32 "\r\n", framebuf_wr_nosp);
    printf("  Write desc. FIFO full = %" PRIu32 "\r\n", framebuf_wr_fifo_f);
    printf("  Read skipped          = %" PRIu32 "\r\n", framebuf_rd_skip);
    printf("  Read canceled         = %" PRIu32 "\r\n", framebuf_rd_cancel);
    printf("  Read sent             = %" PRIu32 "\r\n", framebuf_rd_sent);
    printf("  Resend FIFO writes    = %" PRIu32 "\r\n", framebuf_rsnd_wr);
    printf("  Resend FIFO reads     = %" PRIu32 "\r\n", framebuf_rsnd_rd);
    printf("  Resend FIFO drops     = %" PRIu32 "\r\n", framebuf_rsnd_drop);
    printf("  Resend OK             = %" PRIu32 "\r\n", framebuf_rsnd_ok);
    printf("  Resend N/A            = %" PRIu32 "\r\n", framebuf_rsnd_na);
    printf("Pointers:\r\n");
    printf("  Write bottom          = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_p_wr_bot_h, framebuf_p_wr_bot_l);
    printf("  Write top             = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_p_wr_top_h, framebuf_p_wr_top_l);
    printf("  Read bottom           = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_p_rd_bot_h, framebuf_p_rd_bot_l);
    printf("  Resend bottom         = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_p_rs_bot_h, framebuf_p_rs_bot_l);
    printf("Descriptor registers:\r\n");
    printf("  Block start address   = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_d_start_h, framebuf_d_start_l);
    printf("  Block length          = 0x%08" PRIX32 "_%08" PRIX32 " = %" PRIu64 "\r\n", framebuf_d_len_h, framebuf_d_len_l,
                                                                                        ((uint64_t)framebuf_d_len_h << 32) | (uint64_t)framebuf_d_len_l);
    printf("  Block timestamp       = 0x%08" PRIX32 "_%08" PRIX32 "\r\n", framebuf_d_ts_h, framebuf_d_ts_l);
    printf("Interrupt registers:\r\n");
    printf("  Interrupt mask        = 0x%08" PRIX32 "\r\n", framebuf_int_mask);
    printf("  Interrupt request     = 0x%08" PRIX32 "\r\n", framebuf_int_req);
    printf("Leader DPRAM:");
    for (i = 0; i < (framebuf_lead_len + 3) / 4; i++)
    {
        if ((i % 8) == 0)
            printf("\r\n  ");
        printf("%08" PRIX32 " ", framebuf_pkt_dpram[(framebuf_lead_offs / 4) + i]);
    }
    printf("\r\nTrailer DPRAM:");
    for (i = 0; i < (framebuf_trail_len + 3) / 4; i++)
    {
        if ((i % 8) == 0)
            printf("\r\n  ");
        printf("%08" PRIX32 " ", framebuf_pkt_dpram[(framebuf_trail_offs / 4) + i]);
    }
    printf("\r\n");

    return;
}
