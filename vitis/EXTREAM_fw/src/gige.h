/******************************************************************************/
/*  GigE Vision Core Firmware                                                 */
/*----------------------------------------------------------------------------*/
/*    File :  gige.h                                                          */
/*    Date :  2023-11-01                                                      */
/*     Rev :  0.44                                                            */
/*  Author :  JP                                                              */
/*----------------------------------------------------------------------------*/
/*  The GigE Vision library (libgige.a) public include file                   */
/*----------------------------------------------------------------------------*/
/*  0.1  |  2008-03-12  |  JP  |  Initial release                             */
/*  0.2  |  2012-10-29  |  JP  |  Macros for endianness of the CPU            */
/*  0.3  |  2013-08-23  |  JP  |  Support for multiple stream channels core   */
/*  0.4  |  2016-03-18  |  JP  |  Updated to current state of libgige         */
/*  0.5  |  2016-09-21  |  JP  |  Event IDs for libgige events added          */
/*  0.6  |  2017-07-03  |  JP  |  Main public header as part of multilib srcs */
/*  0.7  |  2018-01-09  |  JP  |  Fixed includes on ARM platforms             */
/*  0.8  |  2018-04-18  |  JP  |  New event IDs for libgige events            */
/*  0.9  |  2018-05-09  |  JP  |  New public functions to set and get current */
/*       |              |      |  acquisition status                          */
/*  0.10 |  2018-10-10  |  JP  |  New authentication and licensing related    */
/*       |              |      |  public functions                            */
/*  0.11 |  2019-04-08  |  JP  |  Do not include unistd.h for Intel SoCs      */
/*  0.12 |  2019-09-19  |  JP  |  Initial support of GEV 2.2 and GenDC        */
/*  0.13 |  2020-03-19  |  AZ  |  New PHY type Intel 1G/10G PHY IP core       */
/*  0.14 |  2020-03-25  |  JP  |  New constants & functions for physical link */
/*       |              |      |  configuration and capability registers,     */
/*       |              |      |  new library event                           */
/*  0.15 |  2020-06-02  |  JP  |  New functions gige_now() and gige_timeout() */
/*  0.16 |  2020-06-05  |  JP  |  Included unistd.h on 64b ARM and inttypes.h */
/*       |              |      |  on all platforms                            */
/*  0.17 |  2020-06-06  |  JP  |  New IEEE 1588 PTP public functions          */
/*  0.18 |  2020-06-11  |  JP  |  Structure and public function to get SFNC   */
/*       |              |      |  PtpControl features                         */
/*  0.19 |  2020-06-11  |  JP  |  Function to set PTP time                    */
/*  0.20 |  2020-09-25  |  JP  |  gige_send_message() returns timestamp       */
/*  0.21 |  2020-10-04  |  JP  |  New function gige_force_gev_version()       */
/*  0.22 |  2020-12-09  |  JP  |  Updated authentication functions            */
/*  0.23 |  2021-02-25  |  JP  |  PTP operation mode constants and functions  */
/*  0.24 |  2021-03-05  |  JP  |  New function ptp_utc_offset_en()            */
/*  0.25 |  2021-05-06  |  JP  |  New library event for scheduled action      */
/*  0.26 |  2021-05-26  |  JP  |  Added gige_set_phy_base() prototype         */
/*  0.27 |  2021-05-28  |  JP  |  Functions to set/get packet resend support  */
/*  0.28 |  2021-07-16  |  JP  |  New function mdio_wait()                    */
/*  0.29 |  2021-10-15  |  JP  |  Public functions to set/get stream channel  */
/*       |              |      |  maximum block size gige_set/get_scmbs()     */
/*  0.30 |  2021-12-13  |  JP  |  Additional NBASE-T constants for MAC        */
/*  0.31 |  2022-01-17  |  SS  |  Add support for Analog Devices PHY ADIN1300 */
/*  0.32 |  2022-05-17  |  JP  |  Support for Broadcom NBASE-T PHYs           */
/*  0.38 |  2023-02-22  |  JP  |  User configurable number of action signals  */
/*       |              |      |  and depth of scheduled action queue         */
/*  0.39 |  2023-03-03  |  JP  |  Trigger types for action_trigger()          */
/*  0.40 |  2023-04-26  |  JP  |  Support of the stream channel source regs   */
/*  0.41 |  2023-06-13  |  JH  |  New PHY type Intel 25G PCS/PMA IP core      */
/*  0.42 |  2023-06-16  |  JP  |  Support of Realtek 1G PHYs                  */
/*  0.43 |  2023-08-01  |  JP  |  User configurable params of the PTP clock   */
/*       |              |      |  control loop                                */
/*  0.44 |  2023-11-01  |  JP  |  Support for MaxLinear GPY215 PHY            */
/******************************************************************************/

#ifndef _GIGE_H_
#define _GIGE_H_


// ---- General-purpose types and constants ------------------------------------

// Standard platform-independent types and definitions
#include <stdint.h>
#include <stddef.h>
#include <inttypes.h>

// Shortcuts to basic unsigned types
#ifndef XIL_TYPES_H
typedef uint64_t    u64;
#endif
#ifndef XBASIC_TYPES_H
typedef uint32_t    u32;
typedef uint16_t    u16;
typedef uint8_t     u8;
#endif

// Endianness of the CPU
#if (XPAR_MICROBLAZE_ENDIANNESS != 0) || (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
#ifndef LITTLE_ENDIAN
#define LITTLE_ENDIAN
#endif
#else
#ifndef BIG_ENDIAN
#define BIG_ENDIAN
#endif
#endif

// GenICam SFNC PtpControl features
typedef struct {
    uint8_t     clockAccuracy;
    uint8_t     status;
    uint8_t     servoStatus;
    int64_t     offsetFromMaster;
    int64_t     meanPathDelay;
    uint64_t    clockId;
    uint64_t    parentClockId;
    uint64_t    grandmasterClockId;
} sfnc_ptp_t;


// ---- GigE library global control --------------------------------------------

// Global variables
extern uintptr_t gige_base_addr;
extern u8  gige_reg_bank;
extern u8  gige_phy_access;
extern u8  gige_phy_user;

// I2C access modes for EEPROM and sensor
extern u8  eeprom_access_mode;
extern u8  sensor_access_mode;

// Stream channel packet size margins
extern const u32 SCPS_MIN;
extern const u32 SCPS_MAX;
extern const u32 SCPS_INC;

// User supplied link status
#define PHY_USER_OFF    0x00
#define PHY_USER_DOWN   0x01
#define PHY_USER_MASK   0x02
#define PHY_USER_UP     0x03

// PHY access modes
#define PHY_ACC_COMMON  0x01
#define PHY_ACC_MULTI   0x02

// Types of the Ethernet PHYs
#define PHY_BROADCOM    0x00
#define PHY_MARVELL     0x01
#define PHY_NATIONAL    0x02
#define PHY_MICREL      0x03
#define PHY_10G_AEL2005 0x04
#define PHY_10G_TN80XX  0x05
#define PHY_10G_PCS_PMA 0x06
#define PHY_1G_PCS_PMA  0x07
#define PHY_TI          0x08
#define PHY_NBASET_MRVL 0x09
#define PHY_NBASET_AQR  0x0A
#define PHY_SWITCH_MRVL 0x0B
#define PHY_25G_PCS_PMA 0x0C
#define PHY_10G_IP_CORE 0x0D
#define PHY_ANALOG      0x0E
#define PHY_NBASET_BCM  0x0F
#define PHY_25G_IP_CORE 0x10
#define PHY_REALTEK     0x11
#define PHY_MAXLINEAR   0x12
#define PHY_NONE        0xFF

// Ethernet MAC NBASE-T link speed and interface mode constants
#define NBASET_USXGMII  0x80000000
#define NBASET_SPD_MASK 0x0000000F
#define NBASET_SPD_10G  0
#define NBASET_SPD_5G   1
#define NBASET_SPD_2500 3
#define NBASET_SPD_1000 9
// ... aliases
#define NBASET_SPD_10000    NBASET_SPD_10G
#define NBASET_SPD_5000     NBASET_SPD_5G

// Device modes (transmitter, receiver, non-streaming)
#define DEV_MODE_TX     0x00
#define DEV_MODE_RX     0x01
#define DEV_MODE_NSTM   0x02
#define DEV_MODE_MULTI  0xFF

// I2C devices access modes
#define I2C_ACC_NONE    0x00
#define I2C_ACC_COMMON  0x01
#define I2C_ACC_LARGE   0x02
#define I2C_ACC_MULTI   0xFF

// Event IDs for libgige user firmware callback
#define LIB_EVENT_NONE                  0x00000000
#define LIB_EVENT_GVCP_CONFIG_WRITE     0x00000001
#define LIB_EVENT_STREAM_OPEN_CLOSE     0x00000002
#define LIB_EVENT_SCCFG_WRITE           0x00000003
#define LIB_EVENT_APP_DISCONNECT        0x00000004
#define LIB_EVENT_LINK_DOWN             0x00000005
#define LIB_EVENT_LINK_CONFIG_WRITE     0x00000006
#define LIB_EVENT_SCHEDULED_ACTION      0x00000007

// Physical link configuration capability bits
#define LINK_CONFIG_CAP_MASK            0x0000000F
#define LINK_CONFIG_CAP_SL              0x00000001
#define LINK_CONFIG_CAP_ML              0x00000002
#define LINK_CONFIG_CAP_SLAG            0x00000004
#define LINK_CONFIG_CAP_DLAG            0x00000008

// Physical link configuration options
#define LINK_CONFIG_MASK                0x00000003
#define LINK_CONFIG_SL                  0
#define LINK_CONFIG_ML                  1
#define LINK_CONFIG_SLAG                2
#define LINK_CONFIG_DLAG                3

// PTP operation modes
#define PTP_MODE_FULL                   0
#define PTP_MODE_SLAVE                  1

// Trigger types for action_trigger()
#define TRIGGER_UNKNOWN         0x00000000
#define TRIGGER_IMMEDIATE       0x00000001
#define TRIGGER_SCHEDULED       0x00000002
#define TRIGGER_PAST            0x00000003


// ---- GigE Vision status codes -----------------------------------------------

#define GEV_STATUS_SUCCESS              0x0000
#define GEV_STATUS_NOT_IMPLEMENTED      0x8001
#define GEV_STATUS_INVALID_PARAMETER    0x8002
#define GEV_STATUS_INVALID_ADDRESS      0x8003
#define GEV_STATUS_WRITE_PROTECT        0x8004
#define GEV_STATUS_BAD_ALIGNMENT        0x8005
#define GEV_STATUS_ACCESS_DENIED        0x8006
#define GEV_STATUS_BUSY                 0x8007
#define GEV_STATUS_LOCAL_PROBLEM        0x8008
#define GEV_STATUS_MSG_MISMATCH         0x8009
#define GEV_STATUS_INVALID_PROTOCOL     0x800A
#define GEV_STATUS_NO_MSG               0x800B
#define GEV_STATUS_PACKET_UNAVAILABLE   0x800C
#define GEV_STATUS_DATA_OVERRUN         0x800D
#define GEV_STATUS_INVALID_HEADER       0x800E
#define GEV_STATUS_NO_REF_TIME          0x8013
#define GEV_STATUS_OVERFLOW             0x8015
#define GEV_STATUS_ACTION_LATE          0x8016
#define GEV_STATUS_ERROR                0x8FFF


// ---- GigE Vision events -----------------------------------------------------
#define SLEEP_MODE_AWAKE                "1"
#define SLEEP_MODE_SLEEP                "2"

#define GEV_EVENT_TRIGGER               0x0002
#define GEV_EVENT_START_OF_EXPOSURE     0x0003
#define GEV_EVENT_END_OF_EXPOSURE       0x0004
#define GEV_EVENT_START_OF_TRANSFER     0x0005
#define GEV_EVENT_END_OF_TRANSFER       0x0006
#define GEV_EVENT_ERROR                 0x8001
//      GEV_EVENT_ERROR:   Error codes identical to status codes 0x8001 - 0x8FFF
#define GEV_EVENT_DEVSPEC               0x9000
//      GEV_EVENT_DEVSPEC: Device-specific error codes 0x9000 - 0xFFFF
#define GEV_EVENT_READ_DEFECT           0xC000    // dskim - 0.xx.08
#define GEV_EVENT_DEBUG_MSG             0xC001    // dskim - 21.03.12 - Debug Msg 출력
#define GEV_EVENT_READ_EDGE             0xC002    // dskim - 21.09.27
#define GEV_EVENT_SW_DEBUG_MSG          0xC003    // dskim - 21.03.12 - Debug Msg 출력
#define GEV_EVENT_SLEEP_MODE            0xC004    // dskim - 22.04.04 - Sleep 출력

// ---- GigE Vision pixel formats ----------------------------------------------

#define GVSP_PIX_MONO8                  0x01080001
#define GVSP_PIX_MONO8_SIGNED           0x01080002
#define GVSP_PIX_MONO10                 0x01100003
#define GVSP_PIX_MONO10_PACKED          0x010C0004
#define GVSP_PIX_MONO12                 0x01100005
#define GVSP_PIX_MONO12_PACKED          0x010C0006
#define GVSP_PIX_MONO14                 0x01100025
#define GVSP_PIX_MONO16                 0x01100007
#define GVSP_PIX_BAYGR8                 0x01080008
#define GVSP_PIX_BAYRG8                 0x01080009
#define GVSP_PIX_BAYGB8                 0x0108000A
#define GVSP_PIX_BAYBG8                 0x0108000B
#define GVSP_PIX_BAYGR10                0x0110000C
#define GVSP_PIX_BAYRG10                0x0110000D
#define GVSP_PIX_BAYGB10                0x0110000E
#define GVSP_PIX_BAYBG10                0x0110000F
#define GVSP_PIX_BAYGR12                0x01100010
#define GVSP_PIX_BAYRG12                0x01100011
#define GVSP_PIX_BAYGB12                0x01100012
#define GVSP_PIX_BAYBG12                0x01100013
#define GVSP_PIX_RGB8_PACKED            0x02180014
#define GVSP_PIX_BGR8_PACKED            0x02180015
#define GVSP_PIX_RGBA8_PACKED           0x02200016
#define GVSP_PIX_BGRA8_PACKED           0x02200017
#define GVSP_PIX_RGB10_PACKED           0x02300018
#define GVSP_PIX_BGR10_PACKED           0x02300019
#define GVSP_PIX_RGB12_PACKED           0x0230001A
#define GVSP_PIX_BGR12_PACKED           0x0230001B
#define GVSP_PIX_RGB10V1_PACKED         0x0220001C
#define GVSP_PIX_RGB10V2_PACKED         0x0220001D
#define GVSP_PIX_YUV411_PACKED          0x020C001E
#define GVSP_PIX_YUV422_PACKED          0x0210001F
#define GVSP_PIX_YUV444_PACKED          0x02180020
#define GVSP_PIX_RGB8_PLANAR            0x02180021
#define GVSP_PIX_RGB10_PLANAR           0x02300022
#define GVSP_PIX_RGB12_PLANAR           0x02300023
#define GVSP_PIX_RGB16_PLANAR           0x02300024
#define GVSP_PIX_RGB565p                0x02100035
#define GVSP_PIX_BGR565p                0x02100036

//#
#define XGIGE_ADDR_MAC_H                0xC030
#define XGIGE_ADDR_MAC_L                0xC034
#define XGIGE_ADDR_IP                   0xC044

#define EEPROM_ADDR_MAC                 0x0000
#define EEPROM_ADDR_IPMODE              0x0007
#define EEPROM_ADDR_IP                  0x0014
#define EEPROM_ADDR_SUBNET              0x0024
#define EEPROM_ADDR_GATEWAY             0x0034

// ---- Acquisition modes as defined in XML file -------------------------------

#define ACQ_MODE_CONTINUOUS             0x00000001


// ---- Debug info verbosity levels --------------------------------------------

#define DBG_QUIET       0
#define DBG_NORMAL      1
#define DBG_ICMP        2
#define DBG_VERBOSE     3


// ---- Prototypes of public functions -----------------------------------------

// Main control
void gige_init(u8 idx, uintptr_t base_addr, u8 dev_mode, u32 bus_clk_freq, u8 phy_type, u8 phy_addr, u32 phy_mdc_freq, u8 data_rate, u16 eth_mtu, u8 verbosity);
int  gige_callback(u8 idx);
void gige_switch(u8 idx);
void gige_send_message(u16 event, u16 channel, u16 data_len, u8 *data, u64 *msg_timestamp);

// Advanced parameters access
void gige_set_params(u8 uart_bypass, u8 heartbeat_en, u8 payload_type);
void gige_get_params(u8 *uart_bypass, u8 *heartbeat_en, u8 *payload_type);
int  gige_set_stmdir(u32 channel, int dir_rx);
int  gige_get_stmdir(u32 channel);
void gige_set_gev_version(u8 ver);
u8   gige_get_gev_version();
void gige_force_gev_version(u32 ver);
void gige_set_sernum(char *sn);
void gige_set_multipart_support(u8 en);
u8   gige_get_multipart_support();
void gige_set_gendc_support(u8 en);
u8   gige_get_gendc_support();
void gige_set_resend_support(u8 en);
u8   gige_get_resend_support();
void gige_set_data_rates(u32 stm_tx_freq, u32 eth_rate);
void gige_set_acquisition_status(u32 channel, u32 status);
u32  gige_get_acquisition_status(u32 channel);
void gige_set_sceba(u32 channel, u32 address);
u32  gige_get_sceba(u32 channel);
void gige_set_scmbs(u32 channel, u64 mbs);
u64  gige_get_scmbs(u32 channel);
int  gige_set_action_numsig(u32 num);
u32  gige_get_action_numsig();
int  gige_set_action_qsize(u32 size);
u32  gige_get_action_qsize();
void gige_set_link_config_cap(u32 capability);
u32  gige_get_link_config_cap();
void gige_set_link_config(u32 configuration);
u32  gige_get_link_config();
void gige_set_phy_base(u32 phy_base);
u64  gige_get_stm_src_mac(u32 channel);
void gige_set_stm_src_mac(u32 channel, u64 mac);
u32  gige_get_stm_src_ip(u32 channel);
void gige_set_stm_src_ip(u32 channel, u32 ip);
u16  gige_get_stm_src_port(u32 channel);
void gige_set_stm_src_port(u32 channel, u16 port);
u32  gige_get_stm_src_cfg();
void gige_set_stm_src_cfg(u32 val);

// Authentication and licensing
uint8_t  gige_get_auth_status();
uint32_t gige_get_license_checksum();
int      gige_get_license_hash(uint8_t *hash);

// Interrupts
u32  gige_get_int_status(void);
void gige_clr_int_req(void);
u32  gige_get_int_mask(void);
void gige_set_int_mask(u32 mask);

// Console output functions
void print_mac(const char *txt, u64 mac);
void print_ip(const char *txt, u32 ip);
void print_speed(const char *txt);
void print_setup(void);
void gige_print_header(void);

// Ethernet PHY access
u16  get_phy_reg(u8 reg);
void set_phy_reg(u8 reg, u16 val);
u16  read_phy_reg(u8 reg);
void set_phy_addr(u8 reg, u16 addr);
u16  mdio_read(u8 reg, u16 addr);
void mdio_write(u8 reg, u16 addr, u16 val);
int  mdio_wait(uint32_t timeout);

// I2C access
u32  i2c_err(void);
// ... EEPROM
void eeprom_write_byte(u16 address, u8 value);
u8   eeprom_read_byte(u16 address);
void eeprom_write_word(u16 address, u16 value);
u16  eeprom_read_word(u16 address);
void eeprom_write_dword(u16 address, u32 value);
u32  eeprom_read_dword(u16 address);
// ... sensor with 8b address
void sensor_write_byte(u8 address, u8 value);
u8   sensor_read_byte(u8 address);
void sensor_write_word(u8 address, u16 value);
u16  sensor_read_word(u8 address);
// ... sensor with 16b address
void sensor16_write_byte(u16 address, u8 value);
u8   sensor16_read_byte(u16 address);
void sensor16_write_word(u16 address, u16 value);
u16  sensor16_read_word(u16 address);
// ... generic device one byte access
void i2c_write_byte(u8 dev, u8 val);
u8   i2c_read_byte(u8 dev);
void i2c_write_byte_addr(u8 dev, u8 addr, u8 val);

// General networking
void ethernet_header(u16 eth_type, u64 destination);
void ip_header(u16 data_len, u8 protocol, u32 src_addr, u32 dest_addr);
void udp_header(u16 data_len, u16 src_port, u16 dest_port);
void telnet_send(u32 len, u8 *data);
 
// IEEE 1588 PTP
uint64_t ptp_gev_time();
void     ptp_set_time(uint64_t seconds, uint32_t nanoseconds);
uint8_t  ptp_get_state_num();
int64_t  ptp_get_mean_path_delay();
int64_t  ptp_get_offset_from_master();
void     ptp_get_sfnc_ptpcontrol(sfnc_ptp_t *data);
void     ptp_set_mode(uint8_t mode);
uint8_t  ptp_get_mode();
void     ptp_set_utc_offset_en(int enable);
int      ptp_get_utc_offset_en();
int16_t  ptp_get_utc_offset();
void     ptp_get_control_params(uint64_t *step_corr_div, uint32_t *offset_margin_h, uint32_t *offset_margin_l, int64_t *delay_iir_coeff, int16_t *leap_seconds);
void     ptp_set_control_params(uint64_t  step_corr_div, uint32_t  offset_margin_h, uint32_t  offset_margin_l, int64_t  delay_iir_coeff, int16_t  leap_seconds);

// Delay functions
u64 gige_now();
int gige_timeout(u64 start, u64 timeout);
u32 gige_random(u32 min, u32 max);
#if defined __MICROBLAZE__
    unsigned int usleep(unsigned int useconds);
    unsigned int sleep(unsigned int seconds);
#elif defined __PPC__
#   include <sleep.h>
#elif defined __NIOS2__
#   include <unistd.h>
#elif defined __arm__  && !defined(__ALTSOC__)
#   include <unistd.h>
#elif defined __aarch64__  && !defined(__ALTSOC__)
#   include <unistd.h>
#endif


#endif
