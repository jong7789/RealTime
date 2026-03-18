/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  tn80xx.c                                                        */
/*    Date :  2016-03-18                                                      */
/*     Rev :  0.3                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  Aquantia TN80xx 10GBASE-T PHY specific functions                          */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2013-01-22  |  JP  |  Initial release                             */
/*  0.2  |  2013-02-08  |  JP  |  Different format of the firmware image      */
/*  0.3  |  2016-03-18  |  JP  |  Removed fan control GPO setting             */
/******************************************************************************/

#include <xparameters.h>
#include <stdio.h>
#include "gige.h"
#include "phy.h"
#include "tn80xx_ram.h"


// ---- Initialize the 10GBASE-T PHY -------------------------------------------
//
int tn80xx_init()
{
    u32 i, addr;

    // Reset PHY and enter low-power mode
    gige_gcsr |= GCSR_RST_PHY;                                  // Hard reset the PHY
    while (gige_gcsr & GCSR_RST_PHY) {};
    usleep(100000);
    mdio_write(0x1E, 0x0000, mdio_read(0x1E, 0x0000) | 0x8000); // PHY software reset
    usleep(100000);
//  mdio_write(0x1E, 0x0000, mdio_read(0x1E, 0x0000) | 0x0800); // Set PHY to low-power mode
    if ((mdio_read(0x1F, 0x0008) & 0xC000) != 0x8000)
        return 1;                                               // PHY unavailable

    // Prepare initialization of the PHY's internal CPU
    mdio_write(0x1F, 0x0000, mdio_read(0x1F, 0x0000) | 0x0002); // Set CPU to reset mode
    if ((mdio_read(0x1F, 0x0008) & 0xC000) != 0x8000)
        return 2;                                               // PHY unavailable
    mdio_write(0x1F, 0x0000, mdio_read(0x1F, 0x0000) | 0x0001); // Enable address auto-increment

    // Load firmware
    addr = 0xFFFFFFFE;                                                                  // Unexpected start index - 1
    for (i = 0; i < (sizeof(tn80xx_a3_ram_xaui) / (2 * sizeof(u32))); i++)
    {
        if (tn80xx_a3_ram_xaui[i][0] != (addr + 1))                                     // Set address if needed
        {
            mdio_write(0x1F, 0x0020, (u16)((tn80xx_a3_ram_xaui[i][0] <<  2) & 0xFFFF)); // Lsbs of index * 4
            mdio_write(0x1F, 0x0021, (u16)((tn80xx_a3_ram_xaui[i][0] >> 14) & 0xFFFF)); // Msbs of index * 4
            set_phy_addr(0x1F, 0x0030);
        }
        addr = tn80xx_a3_ram_xaui[i][0];                                                // Update current index
        set_phy_reg(0x1F, (u16)(tn80xx_a3_ram_xaui[i][1] & 0xFFFF));                    // Lsbs of data
        set_phy_reg(0x1F, (u16)(tn80xx_a3_ram_xaui[i][1] >> 16));                       // Msbs of data
    }

    // Finish PHY initialization
    mdio_write(0x1F, 0x0000, mdio_read(0x1F, 0x0000) & 0xFFFE); // Disable address auto-increment
    if ((mdio_read(0x1F, 0x0008) & 0xC000) != 0x8000)
        return 3;                                               // PHY unavailable
    mdio_write(0x1F, 0x0000, mdio_read(0x1F, 0x0000) & 0xFFFD); // Release CPU reset
    usleep(100000);
//  mdio_write(0x1E, 0x0000, mdio_read(0x1E, 0x0000) & 0xF7FF); // Release PHY from low-power mode

    // Workaround to release CPU from the reset state
    //  - needed at least for silicon revision A3
    //  - manual invocation of the PHY’s watchdog timer expiration to trigger CPU reset
    mdio_write(0x1F, 0x22, 0x0220);
    mdio_write(0x1F, 0x32, 0x0001);
    mdio_write(0x1F, 0x22, 0x0222);
    mdio_write(0x1F, 0x32, 0x0000);
    usleep(100000);

    return 0;
}


// ---- Verify the firmware ----------------------------------------------------
//
int tn80xx_verify()
{
    mdio_write(0x1E, 0x4010, 0x0000);   // Inititial address to write the opcode to
    mdio_write(0x1E, 0x4011, 0x0220);   // Verification opcode
    mdio_write(0x1E, 0x400F, 0x1000);   // Execute the verification command
//  while ((mdio_read(0x1E, 0x400F) & 0xE000) != 0x2000) {};
    usleep(100000);

    printf("Verify: 0x1E.0x400F = 0x%04X\r\n", mdio_read(0x1E, 0x400F));
    printf("Verify: 0x1E.0x4012 = 0x%04X\r\n", mdio_read(0x1E, 0x4012));
    printf("Verify: 0x1E.0x4013 = 0x%04X\r\n", mdio_read(0x1E, 0x4013));

    return 0;
}


// ---- Print PHY debug information --------------------------------------------
//
void tn80xx_debug()
{
    int i, j;
    u16 tmp;
    static const u8  dbg_r[] = {1, 1, 1,  1,   1,   1, 3, 3, 3,  3,  3, 4, 4, 4,  4, 7, 7,  7,  7, 30, 30, 30, 30, 30, 30, 30, 30, 30, 31, 31};
    static const u16 dbg_a[] = {0, 1, 8, 10, 129, 130, 0, 1, 8, 32, 33, 0, 1, 8, 24, 0, 1, 32, 33,  0,  1, 29, 31, 44, 84, 85, 93, 94,  0,  8};

    printf("--------------------------------------------\r\n");
    for (i = 0; i < (sizeof(dbg_r) / sizeof(u8)); i++)
    {
        tmp = mdio_read(dbg_r[i], dbg_a[i]);
        printf("PHY(%3d, %3d) = 0x%04X = ", dbg_r[i], dbg_a[i], tmp);
        for (j = 15; j >= 0; j--)
        {
            (tmp & (1 << j) ? printf("1") : printf("0"));
            if ((!(j % 4)) && j)
                printf("_");
        }
        printf("\r\n");
    }
    printf("--------------------------------------------\r\n");

    return;
}


// ---- Read silicon and firmware version --------------------------------------
//
void tn80xx_revision()
{
    unsigned char hw_id, rev_id;

    hw_id = (unsigned char)(mdio_read(0x1E, 0x20) >> 12) - 4 + 'A';
    mdio_write(0x1F, 0x22, 0x48);
    rev_id = (unsigned char)(mdio_read(0x1F, 0x32) & 0xFF);

    printf("Silicon revision %c%d\r\n", hw_id, rev_id);
    printf("Firmware revision %d.%d.%d\r\n",
           mdio_read(30, 11) >> 8,
           mdio_read(30, 11) & 0xFF,
           mdio_read(30, 32) & 0xFF);
    printf("Current temperature %d°C\r\n", mdio_read(30, 44) & 0xFF);

    return;
}


// ---- Enable/disable PHY-XS (line) loopback ----------------------------------
//
void tn80xx_loopback_line()
{
    mdio_write(4, 0, mdio_read(4,0) ^ 0x4000);  // Invert bit 14
    if (mdio_read(4,0) & 0x4000)
        printf("PHY-XS (line) loopback enabled\r\n");
    else
        printf("PHY-XS (line) loopback disabled\r\n");

    return;
}


// ---- Enable/disable PCS loopback --------------------------------------------
//
void tn80xx_loopback_pcs()
{
    mdio_write(3, 0, mdio_read(3,0) ^ 0x4000);  // Invert bit 14
    if (mdio_read(3,0) & 0x4000)
        printf("PCS loopback enabled, check bit 30.23.9\r\n");
    else
        printf("PCS loopback disabled\r\n");

    return;
}
