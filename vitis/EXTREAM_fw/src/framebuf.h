/******************************************************************************/
/*  GigE Vision Device Firmware                                               */
/*----------------------------------------------------------------------------*/
/*    File :  framebuf.h                                                      */
/*    Date :  2021-02-18                                                      */
/*     Rev :  1.3                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  Template of the AXI framebuffer control functions include file to be used */
/*  in a device user firmware                                                 */
/*----------------------------------------------------------------------------*/
/*  1.0  |  2020-04-29  |  JP  |  Initial version based on a reference design */
/*  1.1  |  2020-05-20  |  JP  |  Calculation of current SCPS increment       */
/*  1.2  |  2021-02-16  |  JP  |  Extended registers for wider AXI addresses  */
/*       |              |      |  introduced in fb-axi v2.1.0                 */
/*  1.3  |  2021-02-18  |  MAS |  Extended Chunk mode support added           */
/******************************************************************************/

#ifndef _FRAMEBUF_H_
#define _FRAMEBUF_H_


// ---- Framebuffer registers --------------------------------------------------

// Framebuffer base address
                            // TODO: Define proper base address of the
                            //       framebuffer control registers here!
#define FRAMEBUF_REGS       XPAR_M0_AXI_FB_BASEADDR

// ID registers
#define framebuf_id         (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0000))
#define framebuf_version    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0004))
#define framebuf_date       (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0008))
// Control registers
#define framebuf_control    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0010))
#define framebuf_bot_l      (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0014))
#define framebuf_top_l      (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0018))
#define framebuf_blk_max_l  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x001C))
#define framebuf_lead_offs  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0020))
#define framebuf_lead_len   (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0024))
#define framebuf_trail_offs (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0028))
#define framebuf_trail_len  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x002C))
#define framebuf_pld_type   (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0030))
#define framebuf_bot_h      (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0034))
#define framebuf_top_h      (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0038))
#define framebuf_blk_max_h  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x003C))
// Status registers
#define framebuf_status     (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0040))
#define framebuf_desc_wr    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0044))
#define framebuf_desc_rd    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0048))
#define framebuf_desc_drop  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x004C))
#define framebuf_wr_drop    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0050))
#define framebuf_wr_nosp    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0054))
#define framebuf_wr_fifo_f  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0058))
#define framebuf_rd_skip    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x005C))
#define framebuf_rd_cancel  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0060))
#define framebuf_rd_sent    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0064))
#define framebuf_rsnd_wr    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0068))
#define framebuf_rsnd_rd    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x006C))
#define framebuf_rsnd_drop  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0070))
#define framebuf_rsnd_ok    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0074))
#define framebuf_rsnd_na    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0078))
// Current pointers
#define framebuf_p_wr_bot_l (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0080))
#define framebuf_p_wr_top_l (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0084))
#define framebuf_p_rd_bot_l (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0088))
#define framebuf_p_rs_bot_l (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x008C))
#define framebuf_p_wr_bot_h (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0090))
#define framebuf_p_wr_top_h (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0094))
#define framebuf_p_rd_bot_h (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x0098))
#define framebuf_p_rs_bot_h (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x009C))
// Descriptor FIFO access registers
#define framebuf_d_start_l  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00B0))
#define framebuf_d_len_l    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00B4))
#define framebuf_d_ts_h     (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00B8))
#define framebuf_d_ts_l     (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00BC))
#define framebuf_d_bid_h    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00C0))
#define framebuf_d_bid_l    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00C4))
#define framebuf_d_start_h  (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00C8))
#define framebuf_d_len_h    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00CC))
// Interrupt registers
#define framebuf_int_mask   (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00E0))
#define framebuf_int_req    (*(volatile uint32_t *)(FRAMEBUF_REGS + 0x00E4))
// Leader/trailer DPRAM
#define framebuf_pkt_dpram  ( (volatile uint32_t *)(FRAMEBUF_REGS + 0x1000))

// Backwards compatible (pre-v2.1.0) register names
#define framebuf_bot        framebuf_bot_l
#define framebuf_top        framebuf_top_l
#define framebuf_blk_max    framebuf_blk_max_l
#define framebuf_p_wr_bot   framebuf_p_wr_bot_l
#define framebuf_p_wr_top   framebuf_p_wr_top_l
#define framebuf_p_rd_bot   framebuf_p_rd_bot_l
#define framebuf_p_rs_bot   framebuf_p_rs_bot_l
#define framebuf_d_start    framebuf_d_start_l
#define framebuf_d_len      framebuf_d_len_l


// ---- Register bits ----------------------------------------------------------

// Control register
#define FRAMEBUF_C_INIT     0x00000001
#define FRAMEBUF_C_CLRSTAT  0x00000002
#define FRAMEBUF_C_DEINT    0x00000100
#define FRAMEBUF_C_RDMODE   0x00030000
#define FRAMEBUF_C_LEADTS   0x01000000
#define FRAMEBUF_C_DYNTRAIL 0x04000000
#define FRAMEBUF_C_EXTTRAIL 0x08000000
#define FRAMEBUF_C_BID16B   0x10000000
#define FRAMEBUF_C_EXTSTAT  0x20000000

// Control register read modes
#define RDMODE_FULL_BLK     0x00000000
#define RDMODE_LOW_LAT      0x00010000
#define RDMODE_HIGH_THR     0x00020000

// Status register
#define FRAMEBUF_S_BITS_AXI 0x0000000F
#define FRAMEBUF_S_DYNTRAIL 0x00000010
#define FRAMEBUF_S_BURST    0x0000FF00
#define FRAMEBUF_S_DF_OVFLW 0x00010000
#define FRAMEBUF_S_RF_OVFLW 0x00020000
#define FRAMEBUF_S_IF_OVFLW 0x00040000
#define FRAMEBUF_S_DF_FULL  0x00080000
#define FRAMEBUF_S_TF_OVFLW 0x00100000
#define FRAMEBUF_S_IF_EMPTY 0x00200000
#define FRAMEBUF_S_WR_ACT   0x00400000
#define FRAMEBUF_S_RD_ACT   0x00800000
#define FRAMEBUF_S_BITS_OUT 0x0F000000

// Payload types
#define PLD_IMAGE           0x00000001

// Additional payload type flags
#define PLD_EXTCHUNK_MODE   0x00004000

// Interrupt masks/request
#define FRAMEBUF_INT_TX     0x00000001
#define FRAMEBUF_INT_RX     0x00000002
#define FRAMEBUF_INT_GLOBAL 0x80000000


// ---- Global variables -------------------------------------------------------
//
extern volatile uint16_t framebuf_pad_x;
extern volatile uint16_t framebuf_pad_y;
extern volatile uint64_t framebuf_bpb;


// ---- Function prototypes ----------------------------------------------------

void    *framebuf_init(int low_latency, int deinterlace, int gev1mode, uint64_t size);
void     framebuf_padding(uint32_t pixel_format, uint32_t size_x, uint32_t size_y, uint32_t size_chunk);
uint32_t framebuf_scps_inc(void);
void     framebuf_img_leader(uint32_t pixel_format, uint32_t size_x, uint32_t size_y, uint32_t offset_x, uint32_t offset_y);
void     framebuf_img_trailer(uint32_t size_y, uint32_t chunk_layout_id);
void     framebuf_printregs(void);
void     framebuf_set_pld_type(uint32_t pld_type);


#endif
