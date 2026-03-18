/******************************************************************************/
/*  10 GigE Vision Reference Design                                           */
/*----------------------------------------------------------------------------*/
/*    File :  pcs_pma.c                                                       */
/*    Date :  2016-03-18                                                      */
/*     Rev :  0.2                                                             */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  GigE Vision reference design 10GBASE-R IP core specific functions         */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2013-02-22  |  JP  |  Initial release                             */
/*  0.2  |  2016-03-18  |  JP  |  Removed fan control GPO setting             */
/******************************************************************************/

#include <xparameters.h>
#include <stdio.h>
#include "gige.h"
#include "phy.h"


// ---- Initialize the PHY -----------------------------------------------------
//
void pcs_pma_init()
{
    // Configure the Si5324 clock multiplier/jitter attenuator on KC705
    i2c_write_byte(0xE8, 0x80);             // Enable I2C access to the Si5324
    i2c_write_byte_addr(0xD0, 0x00, 0x16);  // Set bypass mode
    usleep(100000);                         // Wait for 100 ms to get the clock
//  i2c_write_byte(0xE8, 0x08);             // Enable I2C acess to EEPROM on the KC705 board

    // Reset the PCS/PMA core
//  gige_gcsr |= GCSR_RST_PHY;              // Generate reset pulse
//  usleep(100000);                         // Wait for 100 ms to get the device out of reset
//  mdio_write(1, 0, 0xA040);               // Reset PMA/PMD block
//  mdio_write(3, 0, 0xA040);               // Reset PCS block
//  usleep(100000);                         // Wait for 100 ms to get the device out of reset

    return;
}


// ---- Print PHY debug information --------------------------------------------
//
void pcs_pma_debug()
{
    int i, j;
    u16 tmp;
    static const u8  dbg_r[] = {1, 1, 1, 1, 1, 1, 1, 1,  1,     1, 3, 3, 3, 3, 3, 3, 3,  3,  3,     3};
    static const u16 dbg_a[] = {0, 1, 4, 5, 6, 7, 8, 9, 10, 65535, 0, 1, 4, 5, 6, 7, 8, 32, 33, 65535};

    printf("--------------------------------------------\r\n");
    for (i = 0; i < (sizeof(dbg_r) / sizeof(u8)); i++)
    {
        tmp = mdio_read(dbg_r[i], dbg_a[i]);
        printf("PHY(%1d, %5d) = 0x%04X = ", dbg_r[i], dbg_a[i], tmp);
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
