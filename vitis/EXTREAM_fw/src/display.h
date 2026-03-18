/*
 * display.h
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#ifndef SRC_DISPLAY_H_
#define SRC_DISPLAY_H_

#include "xil_types.h"
#include "func_cmd.h"

extern u8 TFT_SERIAL [16];
extern u8 PANEL_SERIAL [16];
extern u8 GIGE_DVER [16];
//extern const u8 HW_VER [16];
//extern u8 HW_VER [16];
extern u8 FW_DATE [20];
extern u8 FPGA_VER [16];
//extern char FPGA_MODEL [16];
extern u8 FPGA_DATE [16];
extern u8 DEFAULT_NAME[32];
extern u8 USERSET_NAME[MAX_USERSET][32];
extern u8 RUNNING_TIME[16];
extern u8 FW_VER [16]; //# 230621

void disp_err(u16 err_code);
void disp_cmd_h(void);
void disp_cmd_auth(void);
void disp_cmd_stat(void);
void disp_cmd_tser(void);
void disp_cmd_pser(void);
void disp_cmd_fver(void);
void disp_cmd_fmodel(void);
void disp_cmd_dver(void);
void disp_cmd_hwver(void);
void disp_cmd_fmax(void);
void disp_cmd_emax(void);
void disp_cmd_psel(void);
void disp_cmd_roi(void);
void disp_cmd_gmode(void);
void disp_cmd_bmode(void);
void disp_cmd_tmode(void);
void disp_cmd_tdly(void);
void disp_cmd_smode(void);
void disp_cmd_emode(void);
void disp_cmd_pmode(void);
void disp_cmd_pdead(void);
void disp_cmd_grab(void);
void disp_cmd_frate(void);
void disp_cmd_ewt(void);
void disp_cmd_gain(void);
void disp_cmd_offset(void);
void disp_cmd_defect(void);
void disp_cmd_dmap(void);
void disp_cmd_ghost(void);
void disp_cmd_dgain(void);
void disp_cmd_iproc(void);
void disp_cmd_us(void);
void disp_cmd_usname(void);
void disp_cmd_ipmode(void);
void disp_cmd_rtime(void);
void disp_cmd_rtemp(void);
void disp_cmd_flash(void);
void disp_cmd_eeprom(void);
void disp_cmd_erase(void);
void disp_cmd_cddr(void);
void disp_cmd_wddr(void);
void disp_cmd_wdot(u32 pointx, u32 pointy, u32 erase);
void disp_cmd_wrdot(u32 row, u32 erase);
void disp_cmd_wcdot(u32 row, u32 erase);
void disp_cmd_rdot(void);
void disp_cmd_tstat(void);
// TI_ROIC
//void disp_cmd_hroic(void);
void disp_cmd_mac(void);
void disp_cmd_ip(void);
void disp_cmd_smask(void);
void disp_cmd_gate(void);
void disp_cmd_bwidth(void);
void disp_cmd_rsnd(void);
// TI_ROIC
//void disp_roic_pwr(void);
//void disp_roic_lpf(void);
void disp_roic_ifs(void);		// dskim
//void disp_roic_refdac(void);
void disp_cmd_intrst(void);
void disp_cmd_cds1(void);
void disp_cmd_cds2(void);
void disp_cmd_fa(void);
void disp_cmd_fa1(void);
void disp_cmd_fa2(void);
// TI_ROIC
void disp_cmd_dead(void);
void disp_cmd_mute(void);
void disp_cmd_oe(void);
void disp_cmd_xon(void);
void disp_cmd_flk(void);
void disp_cmd_xonflk(void);
void disp_cmd_rcycle(void);
void disp_cmd_afe(void);
void disp_cmd_burst(void);
void disp_cmd_crmode(void);
void disp_cmd_srmode(void);
// TI_ROIC
//void disp_cmd_roicval(void);
void disp_cmd_tseq(void);
void disp_cmd_timg(void);
void disp_cmd_tfrate(void);
void disp_cmd_hwdbg(void);
void disp_cmd_bright(void);
void disp_cmd_contra(void);
void disp_cmd_sens(void);
void disp_cmd_edge_cut(void);
void disp_cmd_sleepmode(void);
void disp_cmd_osd(void);
void disp_cmd_pwdac(void);
//void disp_cmd_pixpos(void);
void disp_cmd_dnr(void);
void disp_cmd_acc(void);
void disp_cmd_topv(void);
void disp_cmd_bnc(void);
void disp_cmd_eq(void);
void disp_cmd_romdiag(void);
void disp_cmd_romread(void);
void disp_cmd_ropertime(void);
void disp_cmd_wtp(void);
#endif /* SRC_DISPLAY_H_ */
