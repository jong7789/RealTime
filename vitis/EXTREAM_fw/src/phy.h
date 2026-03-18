/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  phy.h                                                           */
/*    Date :  2016-08-19                                                      */
/*     Rev :  0.5                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design 10G PHYs specific include file               */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2011-11-02  |  JP  |  Initial release                             */
/*  0.2  |  2013-01-22  |  JP  |  File renamed and extended for multiple PHYs */
/*  0.3  |  2013-02-22  |  JP  |  Added support for 10Gbps PCS/PMA IP core    */
/*  0.4  |  2016-03-18  |  JP  |  Removed fan control PWM from PHY init       */
/*       |              |      |  functions, added Marvell 88X33xx functions  */
/*  0.5  |  2016-08-19  |  JP  |  Type to define PHY host interface mode      */
/******************************************************************************/

#ifndef _PHY_H_
#define _PHY_H_


// ---- GigE core registers ----------------------------------------------------

// Address regions
#define GIGE_HOST       (gige_base_addr + 0x00000000)
#define GIGE_REGS       (gige_base_addr + 0x0000C000)

// Basic configuration and status registers
#define gige_gcsr       (*(volatile u32 *)(GIGE_REGS + 0x0000))

// Register "gige_gcsr" bit definitions
#define GCSR_CONNECTED      0x00000001
#define GCSR_IP_OK          0x00000002
#define GCSR_RST_PHY        0x00000004
#define GCSR_RST_TS         0x00000008
#define GCSR_LATCH_TS       0x00000010
#define GCSR_LATCH_TMR      0x00000020
#define GCSR_BYPASS_UART    0x00000080
#define GCSR_P_TYPE         0x00000F00
#define GCSR_AUTH_OK        0x04000000
#define GCSR_AUTH_BUSY      0x08000000
#define GCSR_GPO_0          0x40000000
#define GCSR_GPO_1          0x80000000


// ---- Types ------------------------------------------------------------------

// PHY access structure
struct mdio_struct
{
   u8  reg;
   u16 addr;
   u16 val;
};

// Host interface mode
typedef enum phy_if_mode {DEFAULT, XAUI, RXAUI, USXGMII} phy_if_mode;


// ---- Functions and macros ---------------------------------------------------

// Ethernet MAC access macros
#define get_mac_reg(reg)        (*(volatile u32 *)(GIGE_HOST + ((reg) << 2)))
#define set_mac_reg(reg, val)   (*(volatile u32 *)(GIGE_HOST + ((reg) << 2)) = (val))

// Functions for NetLogic AEL2005 10GBASE-R PHY
void ael2005_init();

// Functions for Aquantia TN80xx 10GBASE-T PHYs
int  tn80xx_init();
int  tn80xx_verify();
void tn80xx_debug();
void tn80xx_revision();
void tn80xx_loopback_line();
void tn80xx_loopback_pcs();

// Functions for Xilinx 10-Gigabit Ethernet PCS/PMA IP core
void pcs_pma_init();
void pcs_pma_debug();

// Functions for Marvell 88X33xx NBASE-T PHYs
int  m88x33xx_deinit();
int  m88x33xx_initx(phy_if_mode if_mode);
int  m88x33xx_inity(phy_if_mode if_mode);
int  m88x33xx_init(phy_if_mode if_mode);
void m88x33xx_debug();
void m88x33xx_revision();
void m88x33xx_loopback_line();
void m88x33xx_loopback_pcs();

// Functions for Aquantia AQRxxx NBASE-T PHYs
int aqr_init();
void aqr_debug();
void aqr_revision();


#endif
