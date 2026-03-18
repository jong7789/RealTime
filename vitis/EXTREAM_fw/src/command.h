/*
 * uart_cmd.h
 *
 *  Created on: 2019. 10. 1.
 */

#include "xil_types.h"
#include "fpga_info.h"

#ifndef SRC_UART_CMD_H_
#define SRC_UART_CMD_H_

// TI_ROIC
//#ifdef ADAS1258
//  #define ROIC_REG_NUM        47
//#elif defined ADAS1255
//  #define ROIC_REG_NUM        47
//#endif
#define ROIC_REG_NUM        2       // dskim //$ 260224 1->2

#define TFT_TIMING_NUM      12
// TI_ROIC
#define MAX_CMD_NUM         150
//#define MAX_CMD_NUM           85

#define MAX_ARG_NUM         6 // 4 to 6 // mbh 210118
#define MAX_CMD_LEN         10
#define MAX_COMMENT_NUM     80

#define CMD_OK    0
#define CMD_ERR1  1  // Access Authority Error
#define CMD_ERR2  2  // Command Name Error
#define CMD_ERR3  3  // Number of Parameter Error
#define CMD_ERR4  4  // Parameter Value is Out of Range
#define CMD_ERR5  5  // Can't Change in Image Acquisition
#define CMD_ERR6  6  // Can't Change in current Operation Mode
#define CMD_ERR7  7  // NUC Parameter ACQ Process must be preceded
#define CMD_ERR8  8  // Parameter Value is Only Unsigned Integer
#define CMD_ERR9  9  // There is no Flash Data
#define CMD_ERR10 10 // There is no External Trigger
#define CMD_ERR11 11 // Resolution is out of Range
#define CMD_ERR12 12 // TFT is not operating.
#define CMD_ERR13 13 // Calibration Data is already loaded.
#define CMD_ERR14 14 // There is no Calibration Data
#define CMD_ERR15 15 // Can't Change in Rolling Shutter Mode
#define CMD_ERR16 16 // There is no Reference Image
#define CMD_ERR17 17 // The Unit of Value is not Correct
#define CMD_ERR18 18 // ROIC Setting Value Error. (Refer to TFT Sequence)
#define CMD_ERR19 19 // Invalid Defect Point (Can't be Added)
#define CMD_ERR20 20 // Invalid Defect Point (Can't be Removed)

typedef struct {
    u8      cmd[MAX_CMD_LEN];
    u8      (*p)(u8 num, u32* data);
    u8      comment[MAX_COMMENT_NUM];

    u8      access;
} CMD_STRUCT;

typedef struct {
    u8      name[16];
    u8      comment[MAX_COMMENT_NUM];
    u8      addr;
    u8      lsb;
    u8      size;
    u8      data;
    u8      idx;
} ROIC_STRUCT;

typedef struct {
  u8        float_state;
  u8        only_comment;
} SYSTEM_STATE;

extern const CMD_STRUCT CMD_MAT[MAX_CMD_NUM];
// TI_ROIC
extern ROIC_STRUCT ROIC_MAT[ROIC_REG_NUM];
extern SYSTEM_STATE sys_state;

void command_execute(char *str);

u8 UART_CMD_h(u8 num, u32* data);
u8 UART_CMD_auth(u8 num, u32* data);
u8 UART_CMD_stat(u8 num, u32* data);
u8 UART_CMD_psel (u8 num, u32* data);
u8 UART_CMD_gmode (u8 num, u32* data);
u8 UART_CMD_bmode (u8 num, u32* data);
u8 UART_CMD_tmode (u8 num, u32* data);
u8 UART_CMD_tdly (u8 num, u32* data);
u8 UART_CMD_smode (u8 num, u32* data);
u8 UART_CMD_roi (u8 num, u32* data);
u8 UART_CMD_emode (u8 num, u32* data);
//u8 UART_CMD_edge (u8 num, u32* data);
u8 UART_CMD_frate (u8 num, u32* data);
u8 UART_CMD_ewt (u8 num, u32* data);
u8 UART_CMD_max (u8 num, u32* data);
u8 UART_CMD_gain (u8 num, u32* data);
u8 UART_CMD_offset (u8 num, u32* data);
u8 UART_CMD_defect (u8 num, u32* data);
u8 UART_CMD_dmap (u8 num, u32* data);
u8 UART_CMD_ghost (u8 num, u32* data);
// TI_ROIC
u8 UART_CMD_ifs (u8 num, u32* data);
u8 UART_CMD_dgain (u8 num, u32* data);
u8 UART_CMD_iproc (u8 num, u32* data);
u8 UART_CMD_wus (u8 num, u32* data);
u8 UART_CMD_rus (u8 num, u32* data);
u8 UART_CMD_debug (u8 num, u32* data);  // dskim
u8 UART_CMD_rtemp (u8 num, u32* data);
u8 UART_CMD_rtime (u8 num, u32* data);
u8 UART_CMD_reboot (u8 num, u32* data);

u8 UART_CMD_rtp (u8 num, u32* data);
u8 UART_CMD_gtp (u8 num, u32* data);
u8 UART_CMD_atp (u8 num, u32* data);
u8 UART_CMD_wtp (u8 num, u32* data);
u8 UART_CMD_mclk (u8 num, u32* data);
u8 UART_CMD_rclk (u8 num, u32* data);
u8 UART_CMD_diag (u8 num, u32* data);
u8 UART_CMD_wsm (u8 num, u32* data);
u8 UART_CMD_rsm (u8 num, u32* data);
u8 UART_CMD_d2m (u8 num, u32* data);
u8 UART_CMD_edge (u8 num, u32* data);
u8 UART_CMD_dnr (u8 num, u32* data);
u8 UART_CMD_acc (u8 num, u32* data);
u8 UART_CMD_eao (u8 num, u32* data);
u8 UART_CMD_trig (u8 num, u32* data);
u8 UART_CMD_rom (u8 num, u32* data);
u8 UART_CMD_fwtrig (u8 num, u32* data);
u8 UART_CMD_extrst (u8 num, u32* data);
u8 UART_CMD_racc (u8 num, u32* data);
u8 UART_CMD_osd(u8 num, u32* data);

u8 UART_CMD_tser (u8 num, u32* data);
u8 UART_CMD_pser (u8 num, u32* data);
u8 UART_CMD_ver (u8 num, u32* data);
u8 UART_CMD_reg(u8 num, u32* data);
u8 UART_CMD_xreg(u8 num, u32* data);
u8 UART_CMD_rreg(u8 num, u32* data);
u8 UART_CMD_areg(u8 num, u32* data);
u8 UART_CMD_dreg(u8 num, u32* data);
u8 UART_CMD_preg(u8 num, u32* data);

u8 UART_CMD_pmode (u8 num, u32* data);
u8 UART_CMD_pdead (u8 num, u32* data);
u8 UART_CMD_grab (u8 num, u32* data);
u8 UART_CMD_fstat(u8 num, u32* data);
u8 UART_CMD_finit(u8 num, u32* data);
u8 UART_CMD_fclr(u8 num, u32* data);
u8 UART_CMD_pdbg(u8 num, u32* data);
u8 UART_CMD_prev(u8 num, u32* data);
u8 UART_CMD_flash(u8 num, u32* data);
u8 UART_CMD_rflash(u8 num, u32* data);
u8 UART_CMD_eeprom(u8 num, u32* data);
u8 UART_CMD_erase(u8 num, u32* data);
u8 UART_CMD_cddr(u8 num, u32* data);
u8 UART_CMD_wddr(u8 num, u32* data);
u8 UART_CMD_rddr(u8 num, u32* data);
u8 UART_CMD_tempbcal(u8 num, u32* data);
u8 UART_CMD_bcal1(u8 num, u32* data);
u8 UART_CMD_bcal(u8 num, u32* data);
u8 UART_CMD_gcal(u8 num, u32* data);
u8 UART_CMD_ucal(u8 num, u32* data);
u8 UART_CMD_dcal(u8 num, u32* data);
u8 UART_CMD_sens(u8 num, u32* data);
u8 UART_CMD_gdot(u8 num, u32* data);
u8 UART_CMD_wdot(u8 num, u32* data);
u8 UART_CMD_wrdot(u8 num, u32* data);
u8 UART_CMD_wcdot(u8 num, u32* data);
u8 UART_CMD_wdot_factory(u8 num, u32* data);    // dskim - 21.09.24
u8 UART_CMD_wrdot_factory(u8 num, u32* data);   // dskim - 21.09.24
u8 UART_CMD_wcdot_factory(u8 num, u32* data);   // dskim - 21.09.24
u8 UART_CMD_rdot(u8 num, u32* data);
u8 UART_CMD_cdot(u8 num, u32* data);
u8 UART_CMD_wns(u8 num, u32* data);
u8 UART_CMD_rns(u8 num, u32* data);
u8 UART_CMD_wds(u8 num, u32* data);
u8 UART_CMD_rds(u8 num, u32* data);
u8 UART_CMD_hwdbg(u8 num, u32* data);
u8 UART_CMD_bright(u8 num, u32* data);
u8 UART_CMD_contra(u8 num, u32* data);
// TI_ROIC
//  u8 UART_CMD_hroic(u8 num, u32* data);
u8 UART_CMD_tstat(u8 num, u32* data);
u8 UART_CMD_mac(u8 num, u32* data);
u8 UART_CMD_ip(u8 num, u32* data);
u8 UART_CMD_smask(u8 num, u32* data);
u8 UART_CMD_gate(u8 num, u32* data);
u8 UART_CMD_ipmode(u8 num, u32* data);
u8 UART_CMD_intrst(u8 num, u32* data);
u8 UART_CMD_cds1(u8 num, u32* data);
u8 UART_CMD_cds2(u8 num, u32* data);
u8 UART_CMD_fa(u8 num, u32* data);
u8 UART_CMD_dead(u8 num, u32* data);
u8 UART_CMD_mute(u8 num, u32* data);
u8 UART_CMD_oe(u8 num, u32* data);
u8 UART_CMD_xon(u8 num, u32* data);
u8 UART_CMD_flk(u8 num, u32* data);
u8 UART_CMD_xonflk(u8 num, u32* data);
u8 UART_CMD_crmode(u8 num, u32* data);
u8 UART_CMD_srmode(u8 num, u32* data);
u8 UART_CMD_rcycle(u8 num, u32* data);
// TI_ROIC
//  u8 UART_CMD_roicval(u8 num, u32* data);
u8 UART_CMD_timg(u8 num, u32* data);
u8 UART_CMD_tfrate(u8 num, u32* data);
u8 UART_CMD_tseq(u8 num, u32* data);
u8 UART_CMD_edge_cut (u8 num, u32* data);   // dskim - 21.09.24
u8 UART_CMD_edge_save (u8 num, u32* data);  // dskim - 21.09.24
u8 UART_CMD_wake (u8 num, u32* data); //# 220318mbh
u8 UART_CMD_sleep (u8 num, u32* data); //# 220318mbh
u8 UART_CMD_sleepmode (u8 num, u32* data); //# 220321mbh
u8 UART_CMD_pwdac(u8 num, u32* data); // mbh 220429
u8 UART_CMD_pixpos(u8 num, u32* data); // mbh 220524
u8 UART_CMD_rstdev(u8 num, u32* data); // mbh 220525
u8 UART_CMD_fch(u8 num, u32* data); // mbh 220919
u8 UART_CMD_fpdiff(u8 num, u32* data); // mbh 220921
u8 UART_CMD_fwdiff(u8 num, u32* data); // mbh 220921
u8 UART_CMD_dmesg(u8 num, u32* data); //# 210928
u8 UART_CMD_sw_gain_mode (u8 num, u32* data);           // 220928dskim
u8 UART_CMD_load_hw_calibration (u8 num, u32* data);    // 220928dskim
u8 UART_CMD_flash4b (u8 num, u32* data);    //# 220930
u8 UART_CMD_stop (u8 num, u32* data);   //# 221021
u8 UART_CMD_fpgareboot (u8 num, u32* data); //# 221110
u8 UART_CMD_triglog (u8 num, u32* data); //# 230809
u8 UART_CMD_topv (u8 num, u32* data); //# 230904
u8 UART_CMD_bnc (u8 num, u32* data); //# 230824
u8 UART_CMD_eq  (u8 num, u32* data); //# 230824
u8 UART_CMD_able  (u8 num, u32* data); //# 230926
u8 UART_CMD_romdiag  (u8 num, u32* data); //# 231017
u8 UART_CMD_romread  (u8 num, u32* data); //# 231017
u8 UART_CMD_ropertime  (u8 num, u32* data); //# 231121

#endif /* SRC_UART_CMD_H_ */
