/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  m88x33xx.c                                                      */
/*    Date :  2018-02-28                                                      */
/*     Rev :  0.5                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  Marvell 88X33xx NBASE-T PHY specific functions                            */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2016-03-18  |  JP  |  Initial version, mostly empty declarations  */
/*  0.2  |  2016-xx-xx  |  VB  |  Marvell PHY functions                       */
/*  0.3  |  2016-08-19  |  JP  |  Extended the init() function to set mode of */
/*       |              |      |  the PHY host interface                      */
/*  0.4  |  2018-02-27  |  AZ  |  Update to Marvell MTD API version 2.3       */
/*  0.5  |  2018-02-28  |  JP  |  Modification to support both 1.x and 2.x    */
/*       |              |      |  MTD API versions                            */
/******************************************************************************/

#include <xparameters.h>
#include <stdio.h>
#include "gige.h"
#include "phy.h"


// Marvell PHY API
#include "mtd_api/mtdApiTypes.h"
#include "mtd_api/mtdAPI.h"
#include "mtd_api/mtdInitialization.h"
#include "mtd_api/mtdFwDownload.h"
#include "mtd_api/mtdDiagnostics.h"
#include "mtd_api/mtdDiagnosticsRegDumpData.h"
#include "mtd_api/mtdHXunit.h"
#include "mtd_api/mtdApiRegs.h"
#include "mtd_api/mtdHunit.h"
#include "mtd_api/mtdHwCntl.h"

// Include Marvell 88X33xx FW image
#if MTD_API_MAJOR_VERSION == 1
#include "m88x33xx_ram_0_1_0_20.h"
#else
#include "m88x33xx_ram_0_3_3_0.h"
#endif


// ---- Global variables -------------------------------------------------------

// PHY device instance and port
MTD_DEV mtd_dev = {0};
MTD_U16 mtd_port = 0;


// ---- MDIO read access -------------------------------------------------------
//
MTD_STATUS m88x33xx_read_mdio(
                        MTD_DEV*   dev,
                        MTD_U16 port,
                        MTD_U16 mmd,
                        MTD_U16 reg,
                        MTD_U16* value)
{
    *value = mdio_read(mmd, reg);
#if MTD_API_MAJOR_VERSION == 1
    return MTD_TRUE;        // MTD API version 1.x supporting M88X33xx Z1/Z2 silicon
#else
    return MTD_OK;          // Newer MTD API version supporting M88X33xx A0/A1 silicon
#endif
}

// ---- MDIO write access ------------------------------------------------------
//
MTD_STATUS m88x33xx_write_mdio(
                        MTD_DEV*   dev,
                        MTD_U16 port,
                        MTD_U16 mmd,
                        MTD_U16 reg,
                        MTD_U16 value)
{
    mdio_write(mmd, reg, value);
#if MTD_API_MAJOR_VERSION == 1
    return MTD_TRUE;        // MTD API version 1.x supporting M88X33xx Z1/Z2 silicon
#else
    return MTD_OK;          // Newer MTD API version supporting M88X33xx A0/A1 silicon
#endif
}


// ---- Initialize the PHY -----------------------------------------------------
//
int m88x33xx_deinit()
{
	m88x33xx_initx(RXAUI);
	m88x33xx_init(RXAUI);
}
int m88x33xx_initx(phy_if_mode if_mode)
{
	func_printf("Ethernet IC reInit...");

    mtdAutonegRestart(&mtd_dev, mtd_port);
	func_printf("\tDone\r\n");

    return 0;
}
int m88x33xx_inity(phy_if_mode if_mode)
{

    MTD_U16 error;
    MTD_STATUS retStatus;
    MTD_BOOL appStarted = MTD_FALSE;

    retStatus = mtdLoadDriver(m88x33xx_read_mdio,
                              m88x33xx_write_mdio,
                              MTD_FALSE,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              mtd_port,
                              &mtd_dev);

    if (retStatus != MTD_OK)
    {
        return 1;
    }

    retStatus = mtdUpdateRamImage(&mtd_dev,
                                  mtd_port,
                                  m88x3310fw,
                                  sizeof(m88x3310fw),
                                  &error);

    if (retStatus == MTD_FAIL)
    {
        return error;
    }

    retStatus = mtdDidPhyAppCodeStart(&mtd_dev,
                                      mtd_port,
                                      &appStarted);

    if (retStatus == MTD_FAIL)
    {
        return 0x1000;
    }

    if (appStarted != MTD_TRUE)
    {
        return 0x1001;
    }

    return 0;
}

int m88x33xx_init(phy_if_mode if_mode)
{
	func_printf("Ethernet IC init...");
//
    MTD_U16 error;
    MTD_STATUS retStatus;
    MTD_BOOL appStarted = MTD_FALSE;

//	func_printf("\t mtdLoadDriver \r\n");
//
//    retStatus = mtdLoadDriver(m88x33xx_read_mdio,
//                              m88x33xx_write_mdio,
//                              MTD_FALSE,
//                              NULL,
//                              NULL,
//                              NULL,
//                              NULL,
//                              mtd_port,
//                              &mtd_dev);
//
//    if (retStatus != MTD_OK)
//    {
//    	func_printf("\t MTD_OK 0\r\n");
//        return 1;
//    }
//
//	func_printf("\t before mtdUpdateRamImage \r\n");
//    retStatus = mtdUpdateRamImage(&mtd_dev,
//                                  mtd_port,
//                                  m88x3310fw,
//                                  sizeof(m88x3310fw),
//                                  &error);
//
//    if (retStatus == MTD_FAIL)
//    {
//    	func_printf("\t MTD_OK 1\r\n");
//        return error;
//    }

    retStatus = mtdDidPhyAppCodeStart(&mtd_dev,
                                      mtd_port,
                                      &appStarted);

    if (retStatus == MTD_FAIL)
    {
        return 0x1000;
    }

    if (appStarted != MTD_TRUE)
    {
        return 0x1001;
    }

    // Configure host interface
    switch (if_mode)
    {
        case XAUI:
            // TODO: Explicitly set XAUI mode here!
            break;

        case RXAUI:
#if MTD_API_MAJOR_VERSION == 1
            // MTD API version 1.x supporting M88X33xx Z1/Z2 silicon
            mtdSetMacInterfaceControl(&mtd_dev,
                                      mtd_port,
                                      MTD_MAC_TYPE_RXAUI_RATE_ADAPT,
                                      MTD_TRUE,
                                      MTD_MAC_SNOOP_LEAVE_UNCHANGED,
                                      0,
                                      MTD_MAC_SPEED_LEAVE_UNCHANGED,
                                      MTD_TRUE);
#else
            // Newer MTD API version supporting M88X33xx A0/A1 silicon
            mtdSetMacInterfaceControl(&mtd_dev,
                                      mtd_port,
                                      MTD_MAC_TYPE_RXAUI_RATE_ADAPT,
                                      MTD_TRUE,
                                      MTD_MAC_SNOOP_LEAVE_UNCHANGED,
                                      0,
                                      MTD_MAC_SPEED_LEAVE_UNCHANGED,
                                      MTD_MAX_MAC_SPEED_10G,
                                      MTD_TRUE,
                                      MTD_TRUE);
#endif
            mtdHwSetPhyRegField(&mtd_dev,
                                mtd_port,
                                MTD_H_UNIT,
                                0x8000,
                                1,
                                1,
                                1); // Interleave two 8-bit stream first then apply 8/10 encoding
            break;

        case USXGMII:
            // TODO: Explicitly set USXGMII mode here!
            break;

        default:
            // Use the default PHY settings (hardware configured startup options)
            // Do not explicitly reconfigure the host interface here
            break;
    }

    // Initialize the PHY
    mtdRemovePhyLowPowerMode(&mtd_dev, mtd_port);
    mtdRemoveTunitLowPowerMode(&mtd_dev, mtd_port);
    mtdAutonegEnable(&mtd_dev, mtd_port);
    mtdAutonegSetSlavePreference(&mtd_dev, mtd_port, MTD_FALSE);
    mtdEnableSpeeds(&mtd_dev, mtd_port, MTD_SPEED_ALL_33X0, MTD_FALSE);
    mtdAutonegRestart(&mtd_dev, mtd_port);

	func_printf("\tDone\r\n");
    return 0;
}


// ---- Print PHY debug information --------------------------------------------
//
void m88x33xx_debug(int opt)
{
    MTD_STATUS result;
    char outputBuf[64*MTD_SIZEOF_OUTPUT];
    MTD_U16 startLocation = 0;
    int i = 0;

    printf("Option %d: ", opt);

    switch (opt)
    {
        case 1:
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      cUnitRegData,
                                      MTD_CUNIT_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);
            printf("C unit (control) registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_CUNIT_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        case 2:
            startLocation = 0;
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      tUnitMmd1RegData,
                                      MTD_TUNIT_MMD1_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);
            printf("T unit (copper) PMA registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_TUNIT_MMD1_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        case 3:
            startLocation = 0;
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      tUnitMmd3RegData,
                                      MTD_TUNIT_MMD3_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);
            printf("T unit (copper) PCS registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_TUNIT_MMD3_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        case 4:
            startLocation = 0;
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      tUnitMmd3RegData2,
                                      MTD_TUNIT_MMD3_2_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);
            printf("T unit (copper) advanced PCS registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_TUNIT_MMD3_2_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        case 5:
            startLocation = 0;
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      tUnitMmd3RegData3,
                                      MTD_TUNIT_MMD3_3_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);

            printf("T unit (copper) PCS2 registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_TUNIT_MMD3_3_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        case 6:
            startLocation = 0;
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      tUnitMmd7RegData,
                                      MTD_TUNIT_MMD7_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);
            printf("T unit (copper) auto-negotiation registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_TUNIT_MMD7_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        case 7:
            startLocation = 0;
            result = mtdCopyRegsToBuf(&mtd_dev,
                                      mtd_port,
                                      hUnitRxauiRegData,
                                      MTD_HUNIT_RXAUI_NUM_REGS,
                                      outputBuf,
                                      sizeof(outputBuf),
                                      &startLocation);
            printf("H unit RXAUI registers\r\n");
            printf("--------------------------------------------\r\n");
            if (result == MTD_OK)
            {
                char *pStr = outputBuf;
                for (i = 0; i < MTD_HUNIT_RXAUI_NUM_REGS; i++)
                    pStr += printf("%s",pStr) + 1;
            }
            else
            {
                printf("Error occurred\r\n");
            }
            break;

        default:
            printf("Undefined option!\r\n");
    }

    return;
}


// ---- Read silicon and firmware version --------------------------------------
//
void m88x33xx_revision()
{
    MTD_DEVICE_ID phyRev;
    MTD_U8 numPorts;
    MTD_U8 thisPort;
    MTD_U8 major;
    MTD_U8 minor;
    MTD_U8 inc;
    MTD_U8 test;
    MTD_STATUS retStatus;

    mtdGetAPIVersion(&major, &minor);
    printf("API Version %d.%d\r\n", major, minor);

    retStatus = mtdGetPhyRevision(&mtd_dev,
                                  mtd_port,
                                  &phyRev,
                                  &numPorts,
                                  &thisPort);
    if (retStatus == MTD_OK)
    {
        printf("Revision %d (0x%04X)\r\n", phyRev, phyRev);
        printf("Port %d of %d\r\n", thisPort + 1, numPorts);
    }

    retStatus = mtdGetFirmwareVersion(&mtd_dev,
                                      mtd_port,
                                      &major,
                                      &minor,
                                      &inc,
                                      &test);

    if (retStatus == MTD_OK)
    {
        printf("Firmware revision %d.%d.%d.%d\r\n",
               major,
               minor,
               inc,
               test);
    }

    return;
}


// ---- Enable/disable line loopback -------------------------------------------
//
void m88x33xx_loopback_line()
{
    // Invert bit 5 in Copper Specific Control Register 3
    mdio_write(3, 0x8002, mdio_read(3, 0x8002) ^ (1 << 5));
    if (mdio_read(3, 0x8002) & (1 << 5))
        printf("Line loopback enabled\r\n");
    else
        printf("Line loopback disabled\r\n");

    // Invert bit 11 in XG Extended Control Register (for 10GBASE-T mode)
    mdio_write(1, 0xC000, mdio_read(1, 0xC000) ^ (1 << 11));

    return;
}


// ---- Enable/disable PCS loopback --------------------------------------------
//
void m88x33xx_loopback_pcs()
{
    MTD_BOOL loopback;
    MTD_BOOL rx_powerdown;
    MTD_BOOL block_tx_on_loopback;
    MTD_STATUS retStatus;

    retStatus = mtdGetSerdesControl1(&mtd_dev,
                                     mtd_port,
                                     MTD_H_UNIT,
                                     &loopback,
                                     &rx_powerdown,
                                     &block_tx_on_loopback);
    if (retStatus != MTD_OK)
    {
        MTD_DBG_ERROR("Read Failed\n");
        return ;
    }

    loopback = !loopback;

    retStatus = mtdSetSerdesControl1(&mtd_dev,
                                     mtd_port,
                                     MTD_H_UNIT,
                                     loopback,
                                     rx_powerdown,
                                     block_tx_on_loopback);
    if (retStatus != MTD_OK)
    {
        MTD_DBG_ERROR("Write Failed\n");
        return ;
    }

    if (loopback)
        printf("PCS loopback enabled\r\n");
    else
        printf("PCS loopback disabled\r\n");

    return;
}
