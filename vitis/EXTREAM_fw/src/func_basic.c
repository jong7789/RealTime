/*
 * function.c
 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */

#include <xparameters.h>
#include <xuartlite_l.h>
#include <xenv_standalone.h>

#include <stdio.h>
#include <stdlib.h>
#include "math.h"
#include "gige.h"

#include "func_basic.h"
#include "command.h"
#include "fpga_info.h"
#include "func_cmd.h"
#include "display.h"
#include "flash.h"
#include "user.h"
#include "clk_wiz_header.h" //mbh
#include "func_printf.h"
#include "phy.h" //# 2605121219 for m88x33xx_retry_init_if_pending()
Profile_HandleDef profile;
u32 func_userset_cmd    = 0;
u32 func_calib_cmd        = 0;
u32 func_flash_cmd        = 0;
u32 func_calib_map        = 0;
u32 func_addr_table        = 0;
u8 func_reg_addr[12]    = {0, };
u8 func_reg_data[12]    = {0, };
u32 func_pointx            = 0;
u32 func_pointy            = 0;
float func_ds1731_temp[DS1731_NUM]     = {0, };
// TI_ROIC
float func_roic_temp     = 0;
float func_fpga_temp     = 0;
u32 func_phy_temp         = 0;
//u32 func_rns_valid        = 0;    // 0.xx.07
u32 func_rns_valid        = 1;    // 0.xx.07 //# 241217 delay5sec do at init
u32 keep0x5c =0;
u32 bcal_once = 0; //# 241230 1024R dclk need bcal once at booting
//# 2605131158 REG access watch state — paired with REG macro wrapper in fpga_info.h.
//  Configured at runtime via the 'watch' UART command (see UART_CMD_watch in command.c).
//  - dbg_watch_addr[i] == 0 : empty slot, skipped.
//  - dbg_watch_prev[i]      : last-seen value at dbg_watch_addr[i]; mismatch -> W log.
//  - dbg_watch_flags bit0   : ALL mode (sample every REG access, 1/DBG_WATCH_ALL_DIV).
//  Each occupied slot always runs both R+W triggers (no mode selector).
//  Boot default: slot 0 = 0x0074 so the 0x74-stuck-at-0 diag runs without UART input.
//  Clear at runtime with 'watch 0 0x74' (per-addr remove).
u8  dbg_watch_flags                = 0;
u32 dbg_watch_addr[DBG_WATCH_MAX]  = {0,};
u32 dbg_watch_prev[DBG_WATCH_MAX]  = {0,};

//# 2605131126 Pre-hook called by the REG() macro on every register access.
//  Purpose : iterate the watch table and emit log lines per the slot mode.
//  Why     : centralizes the watcher so the REG() macro stays tiny (just a thunk).
//  Inputs  : access_addr - the address being touched by the current REG() call,
//            fname/line  - __func__/__LINE__ captured at the macro expansion site.
//  Output format: "addr: 0xNNNN  data: 0xNNNNNNNN NNN" (hex 4d addr, hex 8d + decimal data).
//  Caveats : R mode triggers on both reads and writes (macro cannot distinguish).
//            W detection is one access late (value is read before the operation).
//            Each iteration updates prev so the change log stays self-seeding.
//
//# 2605131126 WATCH-ALL R/W classification:
//  Cache last-seen value per addr (up to DBG_WATCH_ALL_CACHE_N entries, linear scan).
//  At each sampled access: compare FREG(addr) to cached value.
//    - addr unseen           -> "[WATCH-ALL-?]" (cache miss, first sighting)
//    - value unchanged       -> "[WATCH-ALL-R]" (no write between samples)
//    - value changed         -> "[WATCH-ALL-W]" (some write happened in the window)
//  Caveat: sampling = 1/N; a write that's immediately overwritten with the same
//          value can still register as R. The tag is "what likely happened between
//          this sample and the previous sample of this addr", not exact.
#define DBG_WATCH_ALL_CACHE_N  32
static u32 _all_cache_addr[DBG_WATCH_ALL_CACHE_N] = {0,};
static u32 _all_cache_val [DBG_WATCH_ALL_CACHE_N] = {0,};
static u32 _all_cache_n   = 0;

//# 2605131142 Aligned output format. Field widths:
//   tag        %-13s   ("[WATCH-R]"=9, "[WATCH-W]"=9, "[WATCH-ALL-=]"=13, "[WATCH-ALL-#]"=13, "[WATCH-ALL-?]"=13)
//   fname:line %-30s   (composed via snprintf into a local buf)
//   addr       0x%04x  (fixed 6 chars after 0x)
//   data       0x%08x %10u   (hex 10 chars + decimal right-aligned 10 chars)
//# ALL mode auto-classification tags renamed to be honest about what we measure:
//   `=` (same as last sample) -- previously printed as "R" (misleading: HW-updated
//       regs like XADC temp, status counters changed naturally, looked like writes)
//   `#` (differs from last sample) -- previously "W"
//   `?` (first sighting in cache) -- unchanged
//   Slot R/W tags stay as user-chosen mode names.
//# 2605131213 Lazy fnln build: snprintf only when a log line is about to be emitted.
//             Previously snprintf ran unconditionally on every REG() invocation, which
//             made long flash-scan loops (flash_calc_sum -> ~1.68M iters x 3 REG calls
//             = ~5M format ops) take 1-2 minutes during boot ("ROM FPGA check..." stuck).
//             With this fix, REG() overhead is just FREG read + compare when no print
//             fires (the common path) -- back to near-baseline performance.
void dbg_watch_check(u32 access_addr, const char *fname, int line) {
    char fnln[40];
    u8   fnln_ready = 0;
    #define WATCH_FNLN() do { if (!fnln_ready) { \
        snprintf(fnln, sizeof(fnln), "%s:%d", fname, line); fnln_ready = 1; } } while (0)

    //# Slot triggers (always dual: R + W independent of each other).
    for (int i = 0; i < DBG_WATCH_MAX; i++) {
        if (!dbg_watch_addr[i]) continue;
        u32 cur = FREG(dbg_watch_addr[i]);
        //# R trigger: this access touches the watched addr.
        if (access_addr == dbg_watch_addr[i]) {
            WATCH_FNLN();
            func_printf("%-13s  %-30s  addr: 0x%04x  data: 0x%08x %10u\r\n",
                        "[WATCH-R]", fnln,
                        (unsigned)dbg_watch_addr[i],
                        (unsigned)cur, (unsigned)cur);
        }
        //# W trigger: stored value differs from last seen.
        if (cur != dbg_watch_prev[i]) {
            WATCH_FNLN();
            func_printf("%-13s  %-30s  addr: 0x%04x  data: 0x%08x %10u  (prev: 0x%08x %u)\r\n",
                        "[WATCH-W]", fnln,
                        (unsigned)dbg_watch_addr[i],
                        (unsigned)cur, (unsigned)cur,
                        (unsigned)dbg_watch_prev[i], (unsigned)dbg_watch_prev[i]);
        }
        dbg_watch_prev[i] = cur;
    }
    //# ALL mode: sample every Nth access globally; same dual-trigger pattern
    //  applied per-sample via per-addr cache.
    if (dbg_watch_flags & DBG_WATCH_FLAG_ALL) {
        static u32 _all_n = 0;
        if ((++_all_n % DBG_WATCH_ALL_DIV) == 0) {
            u32 v = FREG(access_addr);
            //# Locate cache entry for this addr (linear scan, capacity = DBG_WATCH_ALL_CACHE_N).
            int found = -1;
            for (u32 k = 0; k < _all_cache_n; k++) {
                if (_all_cache_addr[k] == access_addr) { found = (int)k; break; }
            }
            //# Always emit the ALL-R line (sampled access happened on this line).
            WATCH_FNLN();
            func_printf("%-13s  %-30s  addr: 0x%04x  data: 0x%08x %10u\r\n",
                        "[WATCH-A-R]", fnln,
                        (unsigned)access_addr,
                        (unsigned)v, (unsigned)v);
            //# Additionally emit ALL-W line if value differs from last cached sample.
            if (found < 0) {
                if (_all_cache_n < DBG_WATCH_ALL_CACHE_N) {
                    _all_cache_addr[_all_cache_n] = access_addr;
                    _all_cache_val [_all_cache_n] = v;
                    _all_cache_n++;
                }
                //# First sighting: no prev to compare, skip W line.
            } else if (v != _all_cache_val[found]) {
                func_printf("%-13s  %-30s  addr: 0x%04x  data: 0x%08x %10u  (prev: 0x%08x %u)\r\n",
                            "[WATCH-A-W]", fnln,
                            (unsigned)access_addr,
                            (unsigned)v, (unsigned)v,
                            (unsigned)_all_cache_val[found], (unsigned)_all_cache_val[found]);
                _all_cache_val[found] = v;
            }
        }
    }

    #undef WATCH_FNLN
}

//Profile_HandleDef profile;        // dskim - 21.07.22
//Profile_Def profile_init;            // dskim - 21.07.22
//Profile_Def profile_d2;


void gige_send_message4(u16 event, u16 channel, u16 data_len, u8 *data){
	gige_send_message(event, channel, data_len, data, NULL);
}

int pos = 0;
char str[255] = {0,};
int uart_receive(void) {
    return !XUartLite_IsReceiveEmpty(XPAR_UARTLITE_0_BASEADDR);
}
void uart_command(void) {
    char RecvByte = 0;
    static char str[128] = {0,};
    static char pre_str[128] = {0,};
    static char pre2_str[128] = {0,};

    if(!XUartLite_IsReceiveEmpty(XPAR_UARTLITE_0_BASEADDR)) {
        RecvByte = XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
        if(RecvByte >= 'A' && RecvByte <= 'Z')    RecvByte += 0x20;

        if(RecvByte == 0x08){ // BackSpace
            if(pos > 0) str[--pos] = 0; //$ 260402 underflow
        }
        else if(RecvByte == 0x3D )     { // equal = copy command // mbh 210526
            memcpy(str, pre_str, sizeof(str));    // Input Data
            command_execute((char*)str);        // Command Execute
            func_printf("prev_command\r\n");
        }
        else if(RecvByte == 0x2D )     { // - copy command // mbh 221013
            memcpy(str, pre2_str, sizeof(str));    // Input Data
            command_execute((char*)str);        // Command Execute
            func_printf("prev2_command\r\n");
        }
        else if(RecvByte != '\n' && RecvByte != '\r'){
            if(pos < sizeof(str) - 1) str[pos++] = RecvByte;    // Input Data   //$ 260402 overflow
        }     
        else if(RecvByte == '\n' || RecvByte == '\t') {
            str[pos] = '\0';                    // Finish
            command_execute((char*)str);        // Command Execute
            if(pos){ //# check data exist and save 221013
                memcpy(pre2_str, pre_str, sizeof(str));    // Copy Data //# 221013
                memcpy(pre_str, str, sizeof(str));    // Copy Data
            }
            pos = 0;                            // Reset Position
            memset(str, 0, sizeof(str));        // Reset Data
        }
    }
}

int rsscanf(const char* str, const char* format, ...) {
    va_list ap;
    int value, tmp_value;
    int count;
    int pos, div = 1;
    char neg, fmt_code, check_float = 0;
    float fvalue;

    va_start(ap, format);

    for (count = 0; *format != 0 && *str != 0; format++, str++)    {
        while (*format == ' ' && *format != 0)    format++;
        if (*format == 0)                        break;
        while (*str == ' ' && *str != 0)        str++;
        if (*str == 0)                            break;

        if (*format == '%')    {
            format++;
            if (*format == 'n') {
                if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X'))     { fmt_code = 'x'; str += 2; }
                else if (str[0] == 'b')                                    { fmt_code = 'b'; str ++; }
                else {
                    int i=0, k=0;
                    do {
                        if(str[i] == ' ' || str[i] == 0) {
                            do {
                                if(str[k]== '.') { check_float = 1; break; }
                            } while(k++ <= i);

                            if(check_float == 1)    fmt_code = 'f';
                            else                    fmt_code = 'd';
                            break;
                        }
                    } while(*(str+(i++)) != 0);
                }
            }
            else
                fmt_code = *format;

            switch (fmt_code) {
              case 'f' :
                sys_state.float_state = 1;
                for (value = 0, pos = 0; *str != '.'; str++, pos++) {
                    if ('0' <= *str && *str <= '9')        value = value*10 + (int)(*str - '0');
                    else                                break;
                }
                str ++;
                for (fvalue = 0, pos = 0, div = 1; *str != 0; str++, pos++) {
                    div *= 10;
                    if ('0' <= *str && *str <= '9')        fvalue += ((float)(*str - '0')) / div;
                    else                                break;
                }

                fvalue = value + fvalue;
                value = (int)(fvalue * 1000);

                if (pos == 0)                   return count;
                *(va_arg(ap, int*)) = value;
                count++;
                check_float = 0;
                break;

                case 'x':
                case 'X':
                    for (value = 0, pos = 0; *str != 0; str++, pos++) {
                        if ('0' <= *str && *str <= '9')            tmp_value = *str - '0';
                        else if ('a' <= *str && *str <= 'f')    tmp_value = *str - 'a' + 10;
                        else if ('A' <= *str && *str <= 'F')    tmp_value = *str - 'A' + 10;
                        else                                    break;
                        value *= 16;
                        value += tmp_value;
                    }

                    if (pos == 0)        return count;
                    *(va_arg(ap, int*)) = value;
                    count++;
                    break;

                case 's':
                    tmp_value = (int)va_arg(ap, char*);
                    for (value = 0, pos = 0; *str != 0; str++, pos++) {
                        if (*str == ' ' || *str == '\t' || *str == '\r' || *str == '\n')  break;
                        ((char*)tmp_value)[pos] = *str;
                    }
                    ((char*)tmp_value)[pos] = 0;
                    if (pos == 0)        return count;
                    count++;
                    break;

                case 'S':
                    tmp_value = (int)va_arg(ap, char*);
                    for (value = 0, pos = 0; *str != 0; str++, pos++) {
                        if (*str == ' ' || *str == '\t' || *str == '\r' || *str == '\n')  break;
                        ((char*)tmp_value)[pos] = (*str >= 0x61 && *str <= 0x7A) ? *str - 0x20 : *str;
                    }
                    ((char*)tmp_value)[pos] = 0;
                    if (pos == 0)        return count;
                    count++;
                    break;

                case 'a':
                    tmp_value = (int)va_arg(ap, char*);
                    for (value = 0, pos = 0; *str != 0; str++, pos++) {
                        if (*str == '\t' || *str == '\r' || *str == '\n')  break;
                        ((char*)tmp_value)[pos] = *str;
                    }
                    ((char*)tmp_value)[pos] = 0;
                    if (pos == 0)        return count;
                    count++;
                    break;

                case 'b':
                    for (value = 0, pos = 0; *str != 0; str++, pos++) {
                        if (*str != '0' && *str != '1')            break;
                        value *= 2;
                        value += *str - '0';
                    }

                    if (pos == 0)        return count;
                    *(va_arg(ap, int*)) = value;
                    count++;
                    break;

                case 'd':
                    if (*str == '-') {     neg = 1; str++; }
                    else                neg = 0;
                    for (value = 0, pos = 0; *str != 0; str++, pos++) {
                        if ('0' <= *str && *str <= '9')        value = value*10 + (int)(*str - '0');
                        else                                break;
                    }

                    if (pos == 0)        return count;
                    *(va_arg(ap, int*)) = neg ? -value : value;
                    count++;
                    break;

                case 'c':
                    *(va_arg(ap, char*)) = *str;
                    count++;
                    break;

                default:
                    return count;
            }
        }
        else {
            if (*format != *str)    break;
        }
    }

    va_end(ap);

    return count;
}

int rstrcmp(char *a, char *b) {
    int d;

    for ( ; !(d = (int)*b - (int)*a) && *a; a++, b++);
    return d;
}

#define DBG_floatprintf 0
void float_printf(float val, u8 digits) {
    char format[5 + 1] = "%.";
    char temp[2 + 1];
    char result[500 + 1];

    if(DBG_floatprintf)func_printf("# float_printf float_printf\r\n");

    if (digits > 99) digits = 99;
    if(DBG_floatprintf)func_printf("# float_printf digits99\r\n");
    itoa(digits, temp, 10);
    if(DBG_floatprintf)func_printf("# float_printf itoa\r\n");
    strcat(format, temp); strcat(format, "f");
    if(DBG_floatprintf)func_printf("# float_printf strcat\r\n");
    sprintf(result, format, val); //# v2 231127 stuck here
//# FPGA Temperature = assertion "Balloc succeeded" failed: file "/usr/src/debug/libmblebspm-newlib/4.1.0-r0/newlib-4.1.0/newlib/libc/stdlib/mprec.c", line 778
    if(DBG_floatprintf)func_printf("# float_printf sprintf\r\n");

    func_printf("%s", &result);
}

void usdelay(u32 usecond) {
    usleep(usecond);
}

void msdelay(u32 msecond) {
    register u32 count = msecond;
    for( ; count > 0; count--) usdelay(1000);
}

#define DBG_finit 0
void func_init(void) {
    func_printf("Function Init...    ");
//    set_able_func(); //# 230926 //# 250317 load_func_able

    execute_cmd_psel(func_test_pattern);
    execute_cmd_pmode(func_sync_source);
    execute_cmd_pdead(func_intsync_ldead);
    execute_cmd_bmode(func_binning_mode);
//    execute_cmd_bmode_gain_force(func_binning_mode);    // dskim - 22.06.02    // dskim - 22.07.18 -API SW Correction 기능으로 추가되었으나, NUC 저장 후 Gain이 되돌아가는 현상으로 기능 제거, API 업데이트 필요

    if(DBG_finit)func_printf("#DBG func_init func_offsetx=%d func_offsety=%d\r\n",func_offsetx, func_offsety);
    if(DBG_finit)func_printf("#DBG func_init func_width=%d func_height=%d\r\n",func_width, func_height);
    execute_cmd_roi(func_offsetx, func_offsety, func_width, func_height);
//    execute_cmd_fmax();
//    execute_cmd_emax();
//    execute_cmd_tmode(func_trig_mode);
//    execute_cmd_smode(func_shutter_mode);
//    sys_state.float_state = 1;    execute_cmd_frate(func_frate*1000);    sys_state.float_state = 0;
//    execute_cmd_gewt(func_gewt);
    execute_cmd_gewt(func_gewt); // 220121mbh
    execute_cmd_fmax();
    execute_cmd_frate(0);
    execute_cmd_emax();

    execute_cmd_gain(func_gain_cal);
    execute_cmd_offset(func_offset_cal);
    execute_cmd_defect(func_defect_cal);
    execute_cmd_dgain(func_dgain);

    execute_cmd_iproc(func_img_proc);
    execute_cmd_bright(func_bright);
    execute_cmd_contra(func_contrast);

    execute_cmd_hwdbg(func_hw_debug);

    // dskim - 0.xx.08
    func_read_defect        = 0;    // Default. Point
    func_trig_valid         = 0;
    func_trig_out_active    = 0;
    func_trig_in_active        = 1;
    func_trig_delay_min        = 0;
    func_trig_delay_max     = 65535;

    func_printf("\tDone\r\n");
}

#define DBG_MSG_fwver 0
void load_fw_ver(void) {
    for(int i=0; i<16; i++)
        FW_VER[i] = GIGE_DVER[i];

    u32 ver_minor1 = 0;
//    u32 ver_minor2 = 0;
    u32 asc_base = 0x30;

    ver_minor1     = (REG(ADDR_FPGA_VER) & 0x0FF00) >> 8;
//    ver_minor2     = (REG(ADDR_FPGA_VER) & 0x000FF) >> 0;

//    GIGE_DVER[0] = 'f';
//    GIGE_DVER[1] = 'w';
//    GIGE_DVER[2] = asc_base + ver_major;
//    GIGE_DVER[3] = '.';
    GIGE_DVER[4] = asc_base + (ver_minor1 / 16);
    GIGE_DVER[5] = asc_base + (ver_minor1 % 16);
//    GIGE_DVER[6] = '.';
//    GIGE_DVER[7] = asc_base + (ver_minor2 / 16);
//    GIGE_DVER[8] = asc_base + (ver_minor2 % 16);

    //220621mbh for non license mark in version.
//    case 0x1000000C:    return (u32)gige_get_auth_status();
//    case 0x10000010:    return (u32)gige_get_license_checksum();
//    func_printf("##### 0x%8x\r\n",gige_get_auth_status()); // OkLicense=2, NoLicense=0
    if(DBG_MSG_fwver) func_printf("gige_get_license_checksum = 0x%08x\r\n",gige_get_license_checksum()); // OkLicense=0x0acc, NoLicense=0xffff
    if(DBG_MSG_fwver) func_printf("GigE Auth Status = 0x%08x\r\n",gige_get_auth_status()); //# v2
    if(gige_get_license_checksum()==0xFFFF ||\
       gige_get_license_checksum()==0x0000 )
    {
    	func_printf("License fail! gige_get_license_checksum = 0x%8x\r\n",(0xFFFF==gige_get_license_checksum()));
//        GIGE_DVER[9] = '.';
        GIGE_DVER[10] = 'X';
        GIGE_DVER[11] = 'L';
        GIGE_DVER[12] = 'i';
        GIGE_DVER[13] = 'c';
    }
    GIGE_DVER[15] = 0;
//    GIGE_DVER[8] = 0;
}


void load_fpga_ver(void) {
    u32 ver_major = 0;
    u32 ver_minor1 = 0;
    u32 ver_minor2 = 0;
    u32 asc_base = 0x30;

    ver_major     = (REG(ADDR_FPGA_VER) & 0xF0000) >> 16;
    ver_minor1     = (REG(ADDR_FPGA_VER) & 0x0FF00) >> 8;
    ver_minor2     = (REG(ADDR_FPGA_VER) & 0x000FF) >> 0;

    FPGA_VER[0] = 'F';
    FPGA_VER[1] = 'P';
    FPGA_VER[2] = asc_base + ver_major;
    FPGA_VER[3] = '.';
    FPGA_VER[4] = asc_base + (ver_minor1 / 16);
    FPGA_VER[5] = asc_base + (ver_minor1 % 16);
    FPGA_VER[6] = '.';
    FPGA_VER[7] = asc_base + (ver_minor2 / 16);
    FPGA_VER[8] = asc_base + (ver_minor2 % 16);
    FPGA_VER[9] = 0;
}

void load_fpga_date(void) {
    u32 fdate_year  = 0;
    u32 fdate_month = 0;
    u32 fdate_day   = 0;
    u32 fdate_hour  = 0;
    u32 asc_base    = 0x30;

    fdate_year  = (REG(ADDR_FPGA_DATE) & 0xFF000000) >> 24;
    fdate_month = (REG(ADDR_FPGA_DATE) & 0x00FF0000) >> 16;
    fdate_day   = (REG(ADDR_FPGA_DATE) & 0x0000FF00) >> 8;
    fdate_hour  = (REG(ADDR_FPGA_DATE) & 0x000000FF) >> 0;

    FPGA_DATE[0]  = '2';
    FPGA_DATE[1]  = '0';
    FPGA_DATE[2]  = asc_base + (fdate_year / 16);
    FPGA_DATE[3]  = asc_base + (fdate_year % 16);
    FPGA_DATE[4]  = '.';
    FPGA_DATE[5]  = asc_base + (fdate_month / 16);
    FPGA_DATE[6]  = asc_base + (fdate_month % 16);
    FPGA_DATE[7]  = '.';
    FPGA_DATE[8]  = asc_base + (fdate_day / 16);
    FPGA_DATE[9]  = asc_base + (fdate_day % 16);
    FPGA_DATE[10] = ' ';
    FPGA_DATE[11] = asc_base + (fdate_hour / 16);
    FPGA_DATE[12] = asc_base + (fdate_hour % 16);
    FPGA_DATE[13] = 'h';
    FPGA_DATE[14] = 0;
}

#define DBG_lflash 0
void load_flash(void) {
//    if(execute_cmd_rns()) {
//    if(execute_cmd_brns()) {         // bhmoon 210309 burst rns
    // dskim - 22.09.21
    if(execute_cmd_read_oper_mode()) {
        func_printf("\r\nNo operation mode data in flash memory\r\n");
    } else {
        func_printf("\r\nSet the operation mode\r\n");
    }

    // dskim - 22.09.27 - HW Calibration에서만 읽도록
    if(func_sw_calibration_mode == 0) {
        if(execute_cmd_rns_info()) {
            func_printf("\r\nNo Flash Memory Data - NUC Data\r\n");    // dskim - 2021.02.15 - User Preset 먼저 읽도록
        } else {
            func_table = 1;                    // dskim - 2021.02.15 - NUC Parameter가 저장되어 있다면, User Preset 1번을 불러오도록
            func_check_gain_calib     = 1;    // dskim - 21.02.15 - Gain Calibration을 수행할 것이기 때문에.
            func_check_booting        = 1;    // dskim - 21.02.15 - 부팅 중 Gain Calibration 중에는 Grab하지 못하도록
            //Booting up.
        }
    }

    // 210526 rus, rds, rbs sequence changed for flash initial configration load
    if(execute_cmd_rus(func_table))
        func_printf("\r\nNo Flash Memory Data - User Preset Data\r\n");
    else
        func_rns_valid = 1;        // 0.xx.07

    if(execute_cmd_rds())
        func_printf("\r\nNo Flash Memory Data - Defect Data\r\n");

    if(execute_cmd_rbs())
        func_printf("\r\nNo Flash Memory Data - Default Info\r\n");

    if(execute_cmd_read_detector_sn())
        func_printf("\r\nNo Detector Serial Number\r\n");

    if(execute_cmd_read_tft_sn())
            func_printf("\r\nNo TFT(Panel) Serial Number\r\n");

    if(execute_cmd_read_oper_time())        // dskim - 22.05.19 - Storage mode
            func_printf("\r\nNo Operating Time\r\n");

    if(DBG_lflash)func_printf("#[DBG_lflash] func_width=%d\r\n",func_width);
    if(DBG_lflash)func_printf("#[DBG_lflash] func_height=%d\r\n",func_height);

    //# ewt init 230227
    execute_cmd_fmax();
    execute_cmd_frate2ewt(func_frate*1000);
    execute_cmd_frate(0);
    execute_cmd_emax();

    // dskim - 21.09.27
    func_edge_left     = func_edge_cut_left;
    func_edge_right  = func_edge_cut_right;
    func_edge_top      = func_edge_cut_top;
    func_edge_bottom = func_edge_cut_bottom;
    switch (func_binning_mode) {
        case 0 :
            break;
        case 1 :
        case 2 :
        case 3 :
            func_edge_left      /= 2;
            func_edge_right  /= 2;
            func_edge_top      /= 2;
            func_edge_bottom /= 2;
            break;
        case 4 :
        case 5 :
            func_edge_left      /= 3;
            func_edge_right  /= 3;
            func_edge_top      /= 3;
            func_edge_bottom /= 3;
            break;
        case 6 :
        case 7 :
            func_edge_left      /= 4;
            func_edge_right  /= 4;
            func_edge_top      /= 4;
            func_edge_bottom /= 4;
            break;
    }
}

void fpga_init(void) {
//    func_printf("#################### FPGA INIT \r\n");
    system_config(); //# roic CDS profile set   // dskim - 21.07.22
    load_fpga_ver();
    load_fpga_date(); //# 221104
//    load_fpga_model();
    ddr_init();
    pwr_init();
//    roic_init();        // dskim - 21.03.19 - "wtp" 명령어와 중복되어 삭제
//#ifdef EXT4343R        // dskim - 21.07.22
//    roic_settimingprofile(125, 256, 1000, 2000, 15000, 2000);
//#else
//    roic_settimingprofile(200, 256, 1000, 2000, 8000, 2000);
//#endif    // pmode 인하여 wtp를 func_init()다음에 해줘야함
    if (AFE3256_series) {roic_3256_init(); roic_3256_settingprofile(&profile.init);}
    else roic_settimingprofile(&profile.init);
    temp_init();
    calib_init();
    reg_init(); //# 230824
//    tft_set();            // dskim - 21.03.19 - "wtp" 명령어와 중복되어 삭제
    ext_trig_set();
    execute_cmd_edgemask_calc(); //# 231221 edge cut call
    //$ 2604291730 Apply BASE_OFFSETX/Y to FPGA at boot (no other path calls execute_cmd_roi at startup)
    roi_init();
}

//$ 2604291730 Boot-time ROI init: writes ADDR_OFFSETX/Y/WIDTH/HEIGHT via execute_cmd_roi so BASE_OFFSET is injected at startup
#define DBG_roi_init 0
void roi_init(void) {
    if(DBG_roi_init)func_printf("#[DBG_roi_init] func_offsetx=%d func_offsety=%d func_width=%d func_height=%d\r\n",
                                func_offsetx, func_offsety, func_width, func_height);
    execute_cmd_roi(func_offsetx, func_offsety, func_width, func_height);
}

void ddr_init(void) {
    u32 cnt = 0;

    func_printf("DDR3 Calibration...");
    while(!(REG(ADDR_CALIB_DONE))) {
        msdelay(100);
        gige_callback(0);
        if(cnt++ == 10)     { func_printf("\tError\r\n");     return; }
    }
    func_printf("\tDone\r\n");
}

//# 2605081700 ADDR_DDR_CH_EN composer driven from main loop: write every call, log only when value changes
//# 2605131126 Throttle to 1/CHEN_POLL_DIV main-loop iters. State changes from
//             cal/d2m flags are infrequent enough that periodic re-apply is fine.
//# 2605131450 Throttle replaced by change-detection: REG write fires only when
//             composed regv differs from last write. Zero REG traffic in steady
//             state, instant response on flag change.
//# 2605131508 Disconnect gating: composer is sole owner of ADDR_DDR_CH_EN.
//             func_gige_disconnected = 1 forces regv = DDR_CH_ALL_OFF so DDR
//             channels stop while no GEV viewer is connected. Reconnect
//             (user_callback case 3) clears the flag and composer restores the
//             normal cal/d2m derived value on the same main-loop iteration.
//# 2605131659 Renamed disconnect flag to func_ddrchen_gigedisconn_stat and
//             added func_ddrchen_gcal_stat. Composer OR-combines both stats:
//             any stat != 0 -> regv = DDR_CH_ALL_OFF. Separate flags so a
//             disconnect during gcal (or vice versa) survives the other source
//             clearing its own stat.
//#define CHEN_POLL_DIV 100
void set_ddr_ch_en(void) {
//    static u32 _th = CHEN_POLL_DIV - 1;             //# init so FIRST call passes
//    if (++_th < CHEN_POLL_DIV) return;
//    _th = 0;

    static u32 last_written = 0xFFFFFFFF;                               //# 2605131450 sentinel forces first write
//    u32 regv = DDR_CH_EN_DEFAULT;                                       // 0x11 base (W_ROIC | R_ROIC)
//    if (func_offset_cal) regv |= DDR_CH_EN_R_OFFSET;                    // +0x40
//    if (func_gain_cal)   regv |= DDR_CH_EN_R_NUC;                       // +0x20
//    if (func_d2m)        regv |= (DDR_CH_EN_W_OFFSET | DDR_CH_EN_R_D2M);// +0x84
    //# 2605131508 disconnect branch: force all channels OFF on GEV link down
    //# 2605131659 OR with gcal_stat so calib path also forces channels OFF
    u32 regv;
    if (func_ddrchen_gigedisconn_stat || func_ddrchen_gcal_stat) {
        regv = DDR_CH_ALL_OFF;
    } else {
        regv = DDR_CH_EN_DEFAULT;                                       // 0x11 base (W_ROIC | R_ROIC)
        if (func_offset_cal) regv |= DDR_CH_EN_R_OFFSET;                // +0x40
        if (func_gain_cal)   regv |= DDR_CH_EN_R_NUC;                   // +0x20
        if (func_d2m)        regv |= (DDR_CH_EN_W_OFFSET | DDR_CH_EN_R_D2M);// +0x84
    }
//    REG(ADDR_DDR_CH_EN) = regv;
//    if (regv != last_printed) {
//        func_printf("[DBG] set_ddr_ch_en: 0x%02x (offset_cal=%d gain_cal=%d d2m=%d)\r\n",
//                    regv, func_offset_cal, func_gain_cal, func_d2m);
//        last_printed = regv;
//    }
    //# 2605131450 Write REG + log only when regv changed since last applied value.
    //# 2605131508 disc column added (gige disconnect state)
    //# 2605131659 Renamed disc->disc_stat, added gcal_stat column
    if (regv != last_written) {
        REG(ADDR_DDR_CH_EN) = regv;
        func_printf("[DBG] set_ddr_ch_en: 0x%02x (offset_cal=%d gain_cal=%d d2m=%d disc_stat=%d gcal_stat=%d)\r\n",
                    regv, func_offset_cal, func_gain_cal, func_d2m,
                    func_ddrchen_gigedisconn_stat, func_ddrchen_gcal_stat);
        last_written = regv;
    }
}

void pwr_init(void) {
    u32 cnt = 0;

    func_printf("Power IC Init...   ");
    while(!(REG(ADDR_PWR_DONE))) {
        msdelay(100);
        gige_callback(0);
        if(cnt++ == 10)     { func_printf("\tError\r\n");     return; }
    }
    func_printf("\tDone\r\n");
}


void roic_3256_init(void){
	u32 grab = func_grab_en;

	func_printf("AFE3256 Init...   ");

	update_roic_info();

    //$ ROIC AFE3256 Register Initialization
    execute_cmd_wroic(0x00,  0x0001);	msdelay(1);     // Device Reset
    execute_cmd_wroic(0x01,  0x8000);	                // 8000 : Legacy SPI mode

    //$ TRIM LOAD Sequence (55 Page)
    execute_cmd_wroic(0xAC,  0x8000);
    execute_cmd_wroic(0x0B,  0x0020);
    execute_cmd_wroic(0x7B,  0x0800);
    execute_cmd_wroic(0x7B,  0x8800);
    execute_cmd_wroic(0x7B,  0x8840);  msdelay(10);
    execute_cmd_wroic(0x7B,  0x8800);
    execute_cmd_wroic(0x7B,  0x0800);
    execute_cmd_wroic(0x7B,  0x0000);
    execute_cmd_wroic(0x0B,  0x0000);

    //$ Default Register Settings (55 Page)
    execute_cmd_wroic(0x80,  0x080D);                  // 8 : TDEF detection / D : Integrate Up
    execute_cmd_wroic(0x94,  0x0001);                  // ISOPANEL mode (default : 0)
    execute_cmd_wroic(0x91,  0x0019);
    execute_cmd_wroic(0x09,  0x0202);
    execute_cmd_wroic(0x70,  0x0200);
    execute_cmd_wroic(0x96,  0x8000);
    execute_cmd_wroic(0x08,  0x0004);
    execute_cmd_wroic(0x13,  0x0200);
    execute_cmd_wroic(0xA3,  0x4C00);                  // Power Control Register //$ 260422 4C20 -> 4C00 to Enable DAC
    execute_cmd_wroic(0x8D,  0x0240);
    execute_cmd_wroic(0x8E,  0x0002);
    execute_cmd_wroic(0xA5,  0x4000);                  // Power Control Register
    execute_cmd_wroic(0xA9,  0x1E00);
    execute_cmd_wroic(0x89,  0x3000);                  // ISOPANEL mode (default : 0) / add Cap. Selection
    execute_cmd_wroic(0x03,  0x0006);                  // TG Profile Selection
    execute_cmd_wroic(0x50,  0x0001);                  // TG Register
    execute_cmd_wroic(0x51,  0x0001);                  // TG Register
    execute_cmd_wroic(0x03,  0x0000);                  // TG Settings done
    execute_cmd_wroic(0x82,  0x0101);                  // Input Charge Range 0.25 pF
    execute_cmd_wroic(0x0B,  0x0006);
    execute_cmd_wroic(0x90,  0x8000);
    execute_cmd_wroic(0x05,  0x000C);
    execute_cmd_wroic(0x51,  0x0006);
    execute_cmd_wroic(0xCA,  0x0204);
    execute_cmd_wroic(0x95,  0x0006);

    //$ Input Charge Range Selection
    execute_cmd_wroic(0x82,  0x0808);                  // Input Charge Range 1.25pC
    func_ifs_index = 2; 							   //$ 260403 1.25pC => index : 2 (16 step)

    //$ Integration Mode Selection (Integrate up)
    execute_cmd_wroic(0x80,  0x080D);
    execute_cmd_wroic(0xCF,  0x0000);
    execute_cmd_wroic(0xE9,  0x0000);
    execute_cmd_wroic(0xD2,  0x0000);

    // //$ Power Mode Selection (Low Noise)
    // execute_cmd_wroic(0x86,  0x0400);
    // execute_cmd_wroic(0x88,  0x0000);
    // execute_cmd_wroic(0x8E,  0x0002);

    //$ Power Mode Selection (Normal Power)
    execute_cmd_wroic(0x86,  0x0000);
    execute_cmd_wroic(0x88,  0x0000);
    execute_cmd_wroic(0x8E,  0x0002);
//
//    //$ Power Mode Selection (Low Power)
//    execute_cmd_wroic(0x86,  0x0200);
//    execute_cmd_wroic(0x88,  0x0002);
//    execute_cmd_wroic(0x8E,  0x0006);

    //$ 260422 TFT Charge Injection
    if(mEXT3643R_series)//# 260522
        execute_cmd_wroic(0x0D,  0x0);
    else
    	execute_cmd_wroic(0x0D,  0x04E8);
    // execute_cmd_wroic(0x86,  0x8401); low noise
    execute_cmd_wroic(0x86,  0x8001); // normal power
//    execute_cmd_wroic(0x86,  0x8201); // low power
    execute_cmd_wroic(0x87,  0x0300);
    execute_cmd_wroic(0x6D,  0x0010);               //$ Internal DAC Ctrl

    //$ User settings - STR 0 (107 page)
    execute_cmd_wroic(0xAD,  0x1800);
    execute_cmd_wroic(0xB0,  0xA000);
    execute_cmd_wroic(0xB2,  0x7180);
    execute_cmd_wroic(0xB5,  0x0200);
    execute_cmd_wroic(0xB6,  0x0800);
    execute_cmd_wroic(0xC0,  0x0210);
    execute_cmd_wroic(0xC3,  0x48A0);
    execute_cmd_wroic(0xAF,  0x0301);
    execute_cmd_wroic(0xBC,  0x0200);
    execute_cmd_wroic(0x81,  0x0000);
    execute_cmd_wroic(0x0B,  0x0006);

    //$ Digital Offset Correction (Page 56)
    // Calibration Time = 2 * AVG_NUM * tScan
     execute_cmd_doc();

    func_printf("\t Done\r\n");
}

#define DBG_3256 1
void roic_3256_settingprofile(Profile_Def *profile){
	u32 grab = func_grab_en;
	u32 str_init = 0;
    u32 T_tdef;

    //$ Timing Generator
    u32 mclk           = profile->mclk;
    u32 T_irst     	   = profile->tirst;
    u32 T_shr_lpf1 	   = profile->tshr_lpf1;
    u32 T_shs_lpf2     = profile->tshs_lpf2;
    u32 T_gate         = profile->tgate;
    u32 lpf_sel        = profile->filter;
    u32 T_lpf_min, lpf;
    func_roicstr       = profile->cmdstr;
    u32 dclk = (func_roicstr/256);
    u32 T_sig0 = 750;
    u32 T_sig1 = 200;
    u32 T_sig2 = 500;

    switch (func_roicstr) {
        case 256 : REG(ADDR_ROIC_STR) = 0; T_tdef = 1000; break;
        case 512 : REG(ADDR_ROIC_STR) = 1; T_tdef = 1000; break;
        case 1024: REG(ADDR_ROIC_STR) = 2; T_tdef = 2000; break;
        case 2048: REG(ADDR_ROIC_STR) = 3; T_tdef = 2000; break;
        default  : REG(ADDR_ROIC_STR) = 0; T_tdef = 1000;
    }

    float tmclk    = (1 * 1000000000.0f) / (mclk * 100000);    //$ 260407 only use str 0
    float MCLK_MHz = mclk * 100000 / 1000000.0;
    float MCLK_KHz = mclk * 100000 / 1000.0;

    switch (lpf_sel) {
    	case 0 :  lpf  = 0;			// 221kHz
    			  T_lpf_min = 1600; // 1.6us
    			  break;
    	case 1 :  lpf  = 4;			// 106kHz
    			  T_lpf_min = 3100; // 3.1us
    			  break;
    	case 2 :  lpf = 12;			// 52kHz
    			  T_lpf_min = 9100; // 9.1us
    			  break;
    	case 3 :  lpf = 28;			// 26kHz
    			  T_lpf_min = 18200;// 18.2us
    			  break;
    	default : lpf = 0;
    			  T_lpf_min = 1600;
    }

    //  u32 T_step         = (1<<str_init) * tmclk;    // When, str_init = 0, tmclk = 30Mhz => T_step = 33.333ns
    //  u32 N_irst		= ceil(T_irst		/ T_step);
    //  u32 N_shr_lpf1	= ceil(T_shr_lpf1	/ T_step);
    //  u32 N_lpf1_min	= ceil(T_lpf_min	/ T_step);
    //  u32 N_shs_lpf2	= ceil(T_shs_lpf2	/ T_step);
    //  u32 N_lpf2_min	= ceil(T_lpf_min	/ T_step);
    //  u32 N_tdef		= ceil(T_tdef		/ T_step);
    //  u32 N_gate		= ceil(T_gate		/ T_step);	// not in roic datasheet
    
    //$ 260507 fix timing profile
   float T_step         = (1<<str_init) * tmclk;    // When, str_init = 0, tmclk = 30Mhz => T_step = 33.333ns
   u32 N_irst		= (T_irst		* mclk + 9999) / 10000;
   u32 N_shr_lpf1	= (T_shr_lpf1	* mclk + 9999) / 10000;
   u32 N_lpf1_min	= (T_lpf_min	* mclk + 9999) / 10000;
   u32 N_shs_lpf2	= (T_shs_lpf2	* mclk + 9999) / 10000;
   u32 N_lpf2_min	= (T_lpf_min	* mclk + 9999) / 10000;
   u32 N_tdef		= (T_tdef		* mclk + 9999) / 10000;
   u32 N_gate		= (T_gate		* mclk + 9999) / 10000;	// not in roic datasheet

    u32 N_sig0		= (T_sig0		* mclk + 9999) / 10000;
    u32 N_sig1		= (T_sig1		* mclk + 9999) / 10000;
    u32 N_sig2		= (T_sig2		* mclk + 9999) / 10000;

    u32 N_TFT      	= 256 - (N_irst + N_shr_lpf1 + N_lpf1_min + N_lpf2_min ) - 4;
    u32 N_extra    	= 256 - (N_irst + N_shr_lpf1 + fmax(N_shs_lpf2,N_TFT)) - 4;
    u32 N_lpf1     	= fmax(floor(N_extra/2),N_lpf1_min);
    u32 N_lpf2     	= fmax((int)N_extra-(int)N_lpf1,N_lpf2_min);
    u32 N_shr      	= N_shr_lpf1 + N_lpf1;
    u32 N_shs      	= N_shs_lpf2 + N_lpf2;

    //$ 260422 TFT Charge Injection
    u32 SHS_RISE = N_irst + N_shr_lpf1 + N_lpf1 + 3;
    u32 SHS_FALL = SHS_RISE + N_shs;
    u32 DF_SM0_R = SHS_RISE;
    u32 DF_SM0_F = SHS_FALL;
    u32 DF_SM1_R = SHS_RISE;
    u32 DF_SM1_F = SHS_FALL;
    u32 DF_SM2_R = SHS_RISE;
    u32 DF_SM2_F = SHS_FALL;
    u32 DF_SM3_R = SHS_RISE;
    u32 DF_SM3_F = SHS_FALL;
    u32 DF_SM4_R = SHS_RISE;
    u32 DF_SM4_F = SHS_FALL;
    u32 DF_SM5_R = SHS_RISE;
    u32 DF_SM5_F = SHS_FALL;
    u32 DF_SM6_R = SHS_RISE;
    u32 DF_SM6_F = SHS_FALL;

    //$ 260406 Grab protection before TG register write
    execute_cmd_grab(0);
    execute_cmd_grab(1);
    execute_cmd_grab(0);
    msdelay(10);

    execute_cmd_wroic(0x3A, N_irst);
    execute_cmd_wroic(0x3B, N_shr_lpf1);
    execute_cmd_wroic(0x3E, N_lpf1);
    execute_cmd_wroic(0x3D, fmax(N_shs_lpf2, N_TFT));
    execute_cmd_wroic(0x3C, N_tdef+N_lpf2);
    execute_cmd_wroic(0x1E, (N_sig1 << 8 | N_sig0));
    execute_cmd_wroic(0x1F, N_sig2);
    execute_cmd_wroic(0x96, ((1<<15) | lpf << 8 | lpf));

    //$ 260422 TFT Charge Injection
   execute_cmd_wroic(0x03, 0x0006);
   execute_cmd_wroic(0x72, DF_SM0_R); execute_cmd_wroic(0x73, DF_SM0_F);
   execute_cmd_wroic(0x74, DF_SM1_R); execute_cmd_wroic(0x75, DF_SM1_F);
   execute_cmd_wroic(0x76, DF_SM2_R); execute_cmd_wroic(0x77, DF_SM2_F);
   execute_cmd_wroic(0x78, DF_SM3_R); execute_cmd_wroic(0x79, DF_SM3_F);
   execute_cmd_wroic(0x7A, DF_SM4_R); execute_cmd_wroic(0x7B, DF_SM4_F);
   execute_cmd_wroic(0x7C, DF_SM5_R); execute_cmd_wroic(0x7D, DF_SM5_F);
   execute_cmd_wroic(0x7E, DF_SM6_R); execute_cmd_wroic(0x7F, DF_SM6_F);
   execute_cmd_wroic(0x03, 0x0000);


    execute_cmd_wroic(0x1A,  0x000F);
//    execute_cmd_ifs(get_roic_data(1)); //$ to Get Analog Gain

    /*DEB*/ if (DBG_3256) func_printf("MCLK_MHz   =%dMhz          \r\n", (u32)MCLK_MHz);
    /*DEB*/ if (DBG_3256) func_printf("tmclk      =%.3f(ns)       \r\n", tmclk);
    /*DEB*/ if (DBG_3256) func_printf("T_step     =%.3f(ns)       \r\n", T_step);
    /*DEB*/ if (DBG_3256) func_printf("N_irst     =%3d, %3d.%03dus \r\n", N_irst    , (N_irst     * 10000/mclk) /1000, (N_irst     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_shr_lpf1 =%3d, %3d.%03dus \r\n", N_shr_lpf1, (N_shr_lpf1 * 10000/mclk) /1000, (N_shr_lpf1 * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_shs_lpf2 =%3d, %3d.%03dus \r\n", N_shs_lpf2, (N_shs_lpf2 * 10000/mclk) /1000, (N_shs_lpf2 * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_TFT      =%3d, %3d.%03dus \r\n", N_TFT     , (N_TFT      * 10000/mclk) /1000, (N_TFT      * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_extra    =%3d, %3d.%03dus \r\n", N_extra   , (N_extra    * 10000/mclk) /1000, (N_extra    * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_lpf1     =%3d, %3d.%03dus \r\n", N_lpf1    , (N_lpf1     * 10000/mclk) /1000, (N_lpf1     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_lpf2     =%3d, %3d.%03dus \r\n", N_lpf2    , (N_lpf2     * 10000/mclk) /1000, (N_lpf2     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_shr      =%3d, %3d.%03dus \r\n", N_shr     , (N_shr      * 10000/mclk) /1000, (N_shr      * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_shs      =%3d, %3d.%03dus \r\n", N_shs     , (N_shs      * 10000/mclk) /1000, (N_shs      * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_tdef     =%3d, %3d.%03dus \r\n", N_tdef    , (N_tdef     * 10000/mclk) /1000, (N_tdef     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_gate     =%3d, %3d.%03dus \r\n", N_gate    , (N_gate     * 10000/mclk) /1000, (N_gate     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_SIG0     =%3d, %3d.%03dus \r\n", N_sig0    , (N_sig0     * 10000/mclk) /1000, (N_sig0     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_SIG1     =%3d, %3d.%03dus \r\n", N_sig1    , (N_sig1     * 10000/mclk) /1000, (N_sig1     * 10000/mclk)    %1000);
    /*DEB*/ if (DBG_3256) func_printf("N_SIG2     =%3d, %3d.%03dus \r\n", N_sig2    , (N_sig2     * 10000/mclk) /1000, (N_sig2     * 10000/mclk)    %1000);

    //$ 251125 FPGA TFT SET
    u32 total_step	= N_irst + N_shr + N_shs + 4;

    REG(ADDR_ROIC_INTRST)        = N_irst;
    REG(ADDR_ROIC_CDS1)          = N_shr;
    REG(ADDR_ROIC_CDS2)          = N_shs;
    REG(ADDR_GATE_OE)            = N_gate;
    REG(ADDR_GATE_XON)           = (u32)(func_gate_xon       * MCLK_MHz);
    REG(ADDR_GATE_XON_FLK)       = (u32)(func_gate_xonflk    * MCLK_MHz);
    REG(ADDR_GATE_FLK)           = (u32)(func_gate_flk       * MCLK_MHz);
    REG(ADDR_GATE_RST_CYCLE)     = (u32)(func_gate_rcycle    * MCLK_KHz);
    REG(ADDR_ERASE_TIME)         = (u32)(func_erase_time     * MCLK_KHz);

    /*DEB*/ if (DBG_3256) func_printf("ADDR_ROIC_INTRST(%4x) =%d  \r\n",ADDR_ROIC_INTRST, REG(ADDR_ROIC_INTRST));
	/*DEB*/ if (DBG_3256) func_printf("ADDR_ROIC_CDS1  (%4x) =%d  \r\n",ADDR_ROIC_CDS1  , REG(ADDR_ROIC_CDS1  ));
	/*DEB*/ if (DBG_3256) func_printf("ADDR_ROIC_CDS2  (%4x) =%d  \r\n",ADDR_ROIC_CDS2  , REG(ADDR_ROIC_CDS2  ));
	/*DEB*/ if (DBG_3256) func_printf("ADDR_GATE_OE    (%4x) =%d  \r\n",ADDR_GATE_OE    , REG(ADDR_GATE_OE    ));
    /*DEB*/ if (DBG_3256) func_printf("Total Step Count = %d \r\n", total_step);
    /*DEB*/ if (DBG_3256) func_printf("Total Time =%3d.%03dus\r\n",  (total_step * 10000/mclk) /1000, (total_step * 10000/mclk) %1000);

    execute_cmd_tseq(func_tft_seq);

    //$ 251125 CLOCK
    if(ClkWiz_IntrExample(XPAR_CLK_WIZ_0_DEVICE_ID, mclk, dclk) == XST_FAILURE) {
        func_printf("ClkWiz_IntrExample == XST_FAILURE\r\n");
        return;
    }

//    REG(ADDR_TOPRST_CTRL)= 0xFFFB;
//    msdelay(10);
//    REG(ADDR_TOPRST_CTRL)= 0;
//    msdelay(100);
    execute_cmd_fmax2(mclk*100000);
    
    msdelay(200);


    execute_cmd_wroic(0x1A, 0x0000);
    // 2604250800 In FW bcal mode, skip auto bcal1 trigger - update_image() will
    //            run bcalfw once at boot via temp branch. Prevents double bcal.
    #if !BOOT_BCAL_USE_FW
        func_bcal1_token = 1;
    #endif
}

void roic_init(void) {
    // TI_ROIC
//    u32 i;
//    u32 cnt = 0;
    u32 grab  = func_grab_en;

    func_printf("ROIC Config Init...");
    execute_cmd_grab(0);

    // TI_ROIC
    update_roic_info();        // dskim
//    for(i = 0; i < 16; i++) {
//        execute_cmd_wroic(i, func_roic_data[i]);
//        while(!(REG(ADDR_ROIC_DONE))) {
//            msdelay(100);
//            gige_callback(0);
//            if(cnt++ == 30) { func_printf("\tError\r\n"); return; }
//        }
//    }

    float MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000.0;

    // 7.5.1 Register Initialization
    execute_cmd_wroic(0x00,    0x0001);    msdelay(1);        // Initialize the Internal Registers to Default
    execute_cmd_wroic(0x13,    0x0020);                    // Quick WakeUp Mode
//    execute_cmd_wroic(0x30,    0x0001);    msdelay(1);        // Load Factory Set Trim Value
    execute_cmd_wroic(0x30,    0x0002);    msdelay(1);        // Load Factory Set Trim Value => bit 1 error mbh 201228
    execute_cmd_wroic(0x30,    0x0000);                    // Then, reset TRIM_LOAD (register 30h, bit 1) = 0. 201228 mbh

    // 7.5.2 Default Register Settings (Integrate-Up Mode)
    execute_cmd_wroic(0x61, 0x4000);                    // ESSENTIAL BIT4

if     ((mEXT4343R_series)) execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if((mEXT2832R_series)) execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if(msame(mEXT810R))  execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if(msame(mEXT2430RD))execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else                     execute_cmd_wroic(0x11, 0x0400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV

    execute_cmd_wroic(0x12, 0x4000);                    // ESSENTIAL BIT2
    execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
    execute_cmd_wroic(0x2C, 0x0000);                    // ESSENTIAL BIT8
    execute_cmd_wroic(0x5E, 0x0000);                    // INTG MODE
    execute_cmd_wroic(0x16, 0x00C8);                    // ESSENTIAL BIT5~7, Low Noise Mode

    // User Setting
    execute_cmd_wroic(0x10,    0x03C0);                    // Config Mode0, Sync & Deskew Test Pattern
    execute_cmd_wroic(0x5C,    0x0800);                    // InputChargeRage(0.6pc)/LPF1/LPF2 210107 mbh
    // Finished
    execute_cmd_wroic(0x13,    0x0000);                    // Active Mode

    msdelay(10); // roic sync wait
    func_printf("wait 10ms \r\n");
//###################################################################################
// Timing Setting
//#define ROIC_INTRST            1.5        // us (MCLK)
//#define ROIC_CDS1                4.0        // us (MCLK)
//#define ROIC_CDS2                6.5        // us (MCLK)
//#define ROIC_FA1                1.0        // us (MCLK)
//#define ROIC_FA2                1.0        // us (MCLK)
//#define GATE_OE                1.7        // us (MCLK)
// ################### TG WAVE TIMING ####################
//  ____________
// | IRST(1.5)  |                     
// 1           31
//               ____________________ 
//              | CDS1(4.0-1.5)      |
//              32                  81 
//                        ____________
//             > FA1(1.0)| (1.5)      |
//                       52          82
//                                                    ________________________________
//                                                   | CDS2(6.5)                      |
//                                                   116                            246
//                                                              ________________________
//                                                    >FA2(1.0)| (5.5)                  |
//                                                             136                    247
    u32 IRST_R     = 1;
    u32 IRST_F     = IRST_R     + (u32)(func_roic_intrst * MCLK_MHz);
    u32 SHR_R     = IRST_F     + 1;
    u32 SHR_F     = IRST_R     + (u32)(func_roic_cds1 * MCLK_MHz);
    u32 LPF1_R     = SHR_R     + (u32)(func_roic_fa1 * MCLK_MHz);
    u32 LPF1_F     = SHR_F     + 1;
    u32 SHS_R     = LPF1_F     + (u32)(func_gate_oe * MCLK_MHz);
    u32 SHS_F     = SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
    u32 LPF2_R    = SHS_R        + (u32)(func_roic_fa2 * MCLK_MHz);
    u32 LPF2_F    = SHS_F        + 1;
//    u32 GATE_R  = LPF1_F + 1;
//    u32 GATE_F  = SHS_R;

//    u32 TDEF_R     = LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); // pixel short detection
//    u32 TDEF_F     = SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM0_R= LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM0_F= SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM1_R= LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM1_F= SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM2_R= LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM2_F= SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM3_R= LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM3_F= SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM4_R= LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM4_F= SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM5_R= LPF1_F     + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM5_F= SHS_R     + (u32)(func_roic_cds2 * MCLK_MHz);

    REG(ADDR_ROIC_TP_SEL) = 1; // !!!!! TG alpha use !!!!! mbh 210105
    func_printf("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADDR_ROIC_TP_SEL 1 \r\n");

    execute_cmd_wroic(0x40, (IRST_R << 8     | IRST_F));
    execute_cmd_wroic(0x42, (SHR_R << 8     | SHR_F));
    execute_cmd_wroic(0x43, (SHS_R << 8     | SHS_F));
    execute_cmd_wroic(0x46, (LPF1_R << 8     | LPF1_F));
    execute_cmd_wroic(0x47, (LPF2_R << 8     | LPF2_F));
//    execute_cmd_wroic(0x4A, (TDEF_R << 8     | TDEF_F)); // TDEF
//    execute_cmd_wroic(0x4B, (GATE_R << 8     | GATE_F)); // GATE
//    execute_cmd_wroic(0x50, (DF_SM0_R << 8     | DF_SM0_F));
//    execute_cmd_wroic(0x51, (DF_SM1_R << 8     | DF_SM1_F));
//    execute_cmd_wroic(0x52, (DF_SM2_R << 8     | DF_SM2_F));
//    execute_cmd_wroic(0x53, (DF_SM3_R << 8     | DF_SM3_F));
//    execute_cmd_wroic(0x54, (DF_SM4_R << 8     | DF_SM4_F));
//    execute_cmd_wroic(0x55, (DF_SM5_R << 8     | DF_SM5_F));

//    execute_cmd_rtimingprofile();
//    execute_cmd_gtimingprofile();

/*########################
  // It dose not works because roic_sync not run before power init over.
    ///// TG Beta setting ///// mbh 210106
    REG(ADDR_ROIC_TP_SEL) = 0;
//    func_printf("wait char \r\n");
//    inbyte(); // wait
    func_printf("read reg ADDR_ROIC_TP_SEL = %d \r\n",REG(ADDR_ROIC_TP_SEL));
    execute_cmd_grab(grab);
    msdelay(100); // roic sync wait
    func_printf("wait 100ms \r\n");

    execute_cmd_wroic(0x40, (IRST_R << 8     | IRST_F));
    execute_cmd_wroic(0x42, (SHR_R << 8     | SHR_F));
    execute_cmd_wroic(0x43, (SHS_R << 8     | SHS_F));
    execute_cmd_wroic(0x46, (LPF1_R << 8     | LPF1_F));
    execute_cmd_wroic(0x47, (LPF2_R << 8     | LPF2_F));
    execute_cmd_wroic(0x4A, (0x5678)); // for test
########################*/

    REG(ADDR_ROIC_TP_SEL) = 0; // !!!!! TG alpha use !!!!! mbh 210105
    func_printf("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ADDR_ROIC_TP_SEL 0 \r\n");
    execute_cmd_grab(grab);
    msdelay(10); // roic sync wait

    execute_cmd_grab(grab);
    func_printf("\tDone\r\n");
}

//void roic_settimingfilter(u32 num) {
void roic_settimingfilter(Profile_Def *profile) {
    u32 num = profile->filter;
    u32 new0x5c;
    u32 lpf;

    // over value exception break
    if ( 5 <= num)
    {
        execute_cmd_wroic(0x5c, keep0x5c);
        return;
    }
    switch(num){
        case 0 : lpf = 0; break;
        case 1 : lpf = 1; break;
        case 2 : lpf = 3; break;
        case 3 : lpf = 7; break;
        case 4 : lpf = 15;break;
        default : lpf = 0;
    }


    keep0x5c = execute_cmd_rroic(0x5c);
    new0x5c = keep0x5c;
    new0x5c = (new0x5c & 0xF800) | lpf<<6 | lpf << 1;
    execute_cmd_wroic(0x5c, new0x5c);

}

u32 pre_mclk=0;
#define DBG_WTP 0
//void roic_settimingprofile(u32 mclk, u32 cmdstr, u32 tirst, u32 tshr_lpf1, u32 tshs_lpf2, u32 tgate) {
void roic_settimingprofile(Profile_Def *profile) {

    u32 mclk = profile->mclk;
//    u32 cmdstr = profile->cmdstr;
    u32 tirst = profile->tirst;
    u32 tshr_lpf1 = profile->tshr_lpf1;
    u32 tshs_lpf2 = profile->tshs_lpf2;
    u32 tgate = profile->tgate;
    func_roicstr =  profile->cmdstr;

//    u32 strreg = (str/256-1);
//    u32 dclk = mclk * 12 / (1<<strreg);
    if(DBG_WTP) func_printf(")!!* tgate=%d\r\n",tgate);
    // dclk -> dclk 배수 210719mbh
    u32 strreg = 0; // (str/256-1);
    u32 dclk = (func_roicstr/256);
//    func_printf("dclk=%d\r\n", (u32)dclk);
//    REG(ADDR_ROIC_STR) = func_roicstr;
    switch (func_roicstr) { //# bug fix 230119
        case 256 : REG(ADDR_ROIC_STR) = 0; break;
        case 512 : REG(ADDR_ROIC_STR) = 1; break;
        case 1024: REG(ADDR_ROIC_STR) = 2; break;
        case 2048: REG(ADDR_ROIC_STR) = 3; break;
        default  : REG(ADDR_ROIC_STR) = 0;
    }

//    func_printf("ADDR_ROIC_STR=%d\r\n",REG(ADDR_ROIC_STR));
    // TI_ROIC
    update_roic_info();        // dskim

//    execute_cmd_wroic(0x13,    0xffbf);                    // all power down
//    execute_cmd_wroic(0x13,    0xf827);                    // nap with pll on
//#######################################################################################
    float tmclk = (1 * 1000000000) / (mclk/(1<<strreg) * 100000); // when 20Mhz  = 50(ns)
    float MCLK_MHz = mclk * 100000 / 1000000.0;
    float MCLK_KHz = mclk * 100000 / 1000.0;

    u32 tstep = (1<<strreg) * tmclk; // p70(4)
    u32 nirst     = ceil(tirst/tstep);
    u32 nshr_lpf1 = ceil( (tshr_lpf1)/tstep );
    u32 nshs_lpf2 = ceil( (tshs_lpf2)/tstep );
    u32 nextra    = 256- (nirst + nshr_lpf1 + nshs_lpf2)-5;
    u32 nlpf1     = floor(nextra/2);
    u32 nlpf2     = nextra - nlpf1;
    u32 nshr      = nshr_lpf1 + nlpf1;
    u32 nshs      = nshs_lpf2 + nlpf2;
    u32 ngate     = ceil( (tgate)/tstep ); // not in datasheet 
    u32 tshr      = nshr * tmclk;
    u32 tshs      = nshs * tmclk;

    u32 IRST_R      = 1;
    u32 IRST_F      = nirst + 1;
    u32 SHR_R      = IRST_F     + 1;
    u32 SHR_F      = SHR_R     + nshr;
    u32 SHS_R      = SHR_F + 1;
    u32 SHS_F      = 254;
    u32 LPF1_R      = SHR_F - nlpf1;
    u32 LPF1_F      = SHR_F + 1;
    u32 LPF2_R     = 254 - nlpf2;
    u32 LPF2_F     = 255;
    u32 GATE_R   = LPF1_F + 1;
    u32 GATE_F   = GATE_R + ngate;
    if(DBG_WTP) func_printf(")!!* GATE_R=%d\r\n",GATE_R);
    if(DBG_WTP) func_printf(")!!* GATE_F=%d\r\n",GATE_F);

//    u32 TDEF_R   = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); // pixel short detection
//    u32 TDEF_F   = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM0_R = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); // compensation
//    u32 DF_SM0_F = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM1_R = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM1_F = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM2_R = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM2_F = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM3_R = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM3_F = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM4_R = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM4_F = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);
//    u32 DF_SM5_R = LPF1_F   + (u32)(func_gate_oe * MCLK_MHz); //
//    u32 DF_SM5_F = SHS_R    + (u32)(func_roic_cds2 * MCLK_MHz);

    //# 240110 use charge injection
    u32 TDEF_R   = SHS_R;
    u32 TDEF_F   = SHS_F;
    u32 DF_SM0_R = SHS_R;
    u32 DF_SM0_F = SHS_F;
    if (msame(mEXT1024)|| msame(mEXT1024RL)) DF_SM0_F = 220; //$ 250703
    u32 DF_SM1_R = SHS_R;
    u32 DF_SM1_F = SHS_F;
    u32 DF_SM2_R = SHS_R;
    u32 DF_SM2_F = SHS_F;
    u32 DF_SM3_R = SHS_R;
    u32 DF_SM3_F = SHS_F;
    u32 DF_SM4_R = SHS_R;
    u32 DF_SM4_F = SHS_F;
    u32 DF_SM5_R = SHS_R;
    u32 DF_SM5_F = SHS_F;

    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] MCLK_MHz =%dMhz \r\n", (u32)MCLK_MHz);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] (float)tmclk =%d(ns) \r\n", (u32)tmclk);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] tstep =%d \r\n", tstep);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nirst     =%4d, %3d.%3dus \r\n", nirst    , (u32)tmclk*nirst    /1000,(u32)tmclk*nirst    %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nshr_lpf1 =%4d, %3d.%3dus \r\n", nshr_lpf1, (u32)tmclk*nshr_lpf1/1000,(u32)tmclk*nshr_lpf1%1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nshs_lpf2 =%4d, %3d.%3dus \r\n", nshs_lpf2, (u32)tmclk*nshs_lpf2/1000,(u32)tmclk*nshs_lpf2%1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nextra    =%4d, %3d.%3dus \r\n", nextra   , (u32)tmclk*nextra   /1000,(u32)tmclk*nextra   %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nlpf1     =%4d, %3d.%3dus \r\n", nlpf1    , (u32)tmclk*nlpf1    /1000,(u32)tmclk*nlpf1    %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nlpf2     =%4d, %3d.%3dus \r\n", nlpf2    , (u32)tmclk*nlpf2    /1000,(u32)tmclk*nlpf2    %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nshr      =%4d, %3d.%3dus \r\n", nshr     , (u32)tmclk*nshr     /1000,(u32)tmclk*nshr     %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] nshs      =%4d, %3d.%3dus \r\n", nshs     , (u32)tmclk*nshs     /1000,(u32)tmclk*nshs     %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] ngate     =%4d, %3d.%3dus \r\n", ngate    , (u32)tmclk*ngate    /1000,(u32)tmclk*ngate    %1000);
    /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] (float)MCLK_MHz=%d/1000(ns) \r\n", (u32)(tmclk*1000) );
//  /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] tshr      =%d \r\n", tshr      );
//  /*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] tshs      =%d \r\n", tshs      );

//    func_printf("\033[31m"); //red
//    /*ERR*/ if ( tmclk < 50 || 800 < tmclk ) func_printf("\r\n ERR: mclk range over tmclk(%d)\r\n ",tmclk);
//    /*ERR*/ if ( tirst     < 1.5 * 1000 )    func_printf("\r\n ERR: tirst minimum is 1.5us (%d) \r\n ", tirst);
//    /*ERR*/ if ( tshr_lpf1 < 4.0 * 1000 )    func_printf("\r\n ERR: tshr_lpf1 minimum is 4us (%d) \r\n ", tshr_lpf1);
//    /*ERR*/ if ( IRST_R < 1 || 255 < IRST_R  ) func_printf("\r\n ERR: IRST_R range over \r\n ");
//    /*ERR*/ if ( IRST_F < 1 || 255 < IRST_F  ) func_printf("\r\n ERR: IRST_F range over \r\n ");
//    /*ERR*/ if ( SHR_R  < 1 || 255 < SHR_R   ) func_printf("\r\n ERR: SHR_R  range over \r\n ");
//    /*ERR*/ if ( SHR_F  < 1 || 255 < SHR_F   ) func_printf("\r\n ERR: SHR_F  range over \r\n ");
//    /*ERR*/ if ( SHS_R  < 1 || 255 < SHS_R   ) func_printf("\r\n ERR: SHS_R  range over \r\n ");
//    /*ERR*/ if ( SHS_F  < 1 || 255 < SHS_F   ) func_printf("\r\n ERR: SHS_F  range over \r\n ");
//    /*ERR*/ if ( LPF1_R < 1 || 255 < LPF1_R  ) func_printf("\r\n ERR: LPF1_R range over \r\n ");
//    /*ERR*/ if ( LPF1_F < 1 || 255 < LPF1_F  ) func_printf("\r\n ERR: LPF1_F range over \r\n ");
//    /*ERR*/ if ( LPF2_R < 1 || 255 < LPF2_R  ) func_printf("\r\n ERR: LPF2_R range over \r\n ");
//    /*ERR*/ if ( LPF2_F < 1 || 255 < LPF2_F  ) func_printf("\r\n ERR: LPF2_F range over \r\n ");
//    /*ERR*/ if ( GATE_R < 1 || 255 < GATE_R  ) func_printf("\r\n ERR: GATE_R range over \r\n ");
//    /*ERR*/ if ( GATE_F < 1 || 255 < GATE_F  ) func_printf("\r\n ERR: GATE_F range over \r\n ");
//    func_printf("\033[0m"); // default

// #####################################################################
// ##### FPGA TFT SET ###################################################
    REG(ADDR_ROIC_INTRST) = 1;
    REG(ADDR_ROIC_CDS1)   = 1;
    REG(ADDR_ROIC_CDS2)   = 1;
    REG(ADDR_GATE_OE)   = 1;

    REG(ADDR_ROIC_INTRST)        = (u32)(tirst/1000.0        * MCLK_MHz);
    REG(ADDR_ROIC_CDS1)            = (u32)(tshr /1000.0        * MCLK_MHz);
    REG(ADDR_ROIC_CDS2)            = (u32)(tshs /1000.0         * MCLK_MHz);
    REG(ADDR_GATE_OE)            = (u32)(tgate/1000.0         * MCLK_MHz);
    REG(ADDR_GATE_XON)            = (u32)(func_gate_xon         * MCLK_MHz);
    REG(ADDR_GATE_XON_FLK)        = (u32)(func_gate_xonflk     * MCLK_MHz);
    REG(ADDR_GATE_FLK)            = (u32)(func_gate_flk         * MCLK_MHz);
    if(DBG_WTP) func_printf(")!!* REG(ADDR_GATE_OE)=%d\r\n",REG(ADDR_GATE_OE));

//    func_printf("tgate=%d\r\n",tgate); //# 220929 debug wtp oe
//    func_printf("(tgate/1000.0* MCLK_MHz)=%d\r\n",(u32)(tgate/1000.0* MCLK_MHz));
//    func_printf("REG(ADDR_GATE_OE)=%d\r\n",(u32)REG(ADDR_GATE_OE));

    REG(ADDR_GATE_RST_CYCLE)    = (u32)(func_gate_rcycle    * MCLK_KHz);
    REG(ADDR_ERASE_TIME)        = (u32)(func_erase_time     * MCLK_KHz);
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP]ADDR_ROIC_INTRST(%4x)%d  \r\n",ADDR_ROIC_INTRST, REG(ADDR_ROIC_INTRST));
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP]ADDR_ROIC_CDS1  (%4x)%d  \r\n",ADDR_ROIC_CDS1  , REG(ADDR_ROIC_CDS1  ));
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP]ADDR_ROIC_CDS2  (%4x)%d  \r\n",ADDR_ROIC_CDS2  , REG(ADDR_ROIC_CDS2  ));
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP]ADDR_GATE_OE    (%4x)%d  \r\n",ADDR_GATE_OE    , REG(ADDR_GATE_OE    ));
//
    execute_cmd_tseq(func_tft_seq);
// ----------------------------------------------------------------------
// #####################################################################
// ##### clock #########################################################

        if(ClkWiz_IntrExample(XPAR_CLK_WIZ_0_DEVICE_ID, mclk, dclk) == XST_FAILURE) {
            func_printf("ClkWiz_IntrExample == XST_FAILURE\r\n");
            return;
        }
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP]ClkWiz_IntrExample == XST_SUCCESS\r\n");
//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));
//        REG(ADDR_TOPRST_CTRL)= 0x0001;
//        msdelay(10);
//
//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));
//        REG(ADDR_TOPRST_CTRL)= 0x0003;
//        msdelay(10);

//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));
//        REG(ADDR_TOPRST_CTRL)= 0x0007;
//        msdelay(10);

//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));
//        REG(ADDR_TOPRST_CTRL)= 0x000F;
//        msdelay(10);

//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));
        REG(ADDR_TOPRST_CTRL)= 0xFFFB;
        msdelay(10);

//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));
        REG(ADDR_TOPRST_CTRL)= 0;
//        msdelay(10);
//
//        func_printf("TOPRST START 210806 b 0x%4x \r\n", REG(ADDR_TOPRST_CTRL));


    msdelay(100);
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] clk change read %4x \r\n",execute_cmd_rroic(0x11) );
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] clk change read %4x \r\n",execute_cmd_rroic(0x61) );
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] clk change read %4x \r\n",execute_cmd_rroic(0x16) );
/*DEB*/ if (DBG_WTP) func_printf("[DBG_WTP] clock set done ! \r\n");
// ----------------------------------------------------------------------
// #####################################################################
// ##### ROIC CLK#######################################################
//    execute_cmd_grab(0);
//    /*DEB*/ if (DEBUG) func_printf("grab 0 done ! \r\n");
    // 7.5.1 Register Initialization
    execute_cmd_wroic(0x00,    0x0001);    msdelay(1);        // Initialize the Internal Registers to Default
    execute_cmd_wroic(0x13,    0x0020);                    // Quick WakeUp Mode
    execute_cmd_wroic(0x30,    0x0002);    msdelay(1);        // Load Factory Set Trim Value => bit 1 error mbh 201228
    execute_cmd_wroic(0x30,    0x0000);                    // Then, reset TRIM_LOAD (register 30h, bit 1) = 0. 201228 mbh

    // datasheet 7.5.1.1 Default Register Settings //# 220530mbh
    execute_cmd_wroic(0x61, 0x4000);                    // ESSENTIAL BIT4
    execute_cmd_wroic(0x11, 0x0400);                    // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV

if (msame(mEXT810R  )){
    execute_cmd_wroic(0x12, 0x0000);                    // ESSENTIAL BIT2
    execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
    execute_cmd_wroic(0x2C, 0x0001);                    // ESSENTIAL BIT8
    execute_cmd_wroic(0x5E, 0x1000);                    // INTG MODE
	}
else if (msame(mEXT2430RD)){
    execute_cmd_wroic(0x12, 0x0000);                    // ESSENTIAL BIT2
    execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
    execute_cmd_wroic(0x2C, 0x0001);                    // ESSENTIAL BIT8
    execute_cmd_wroic(0x5E, 0x1000);                    // INTG MODE
	}
else if (msame(mEXT4343R_3)){ //# a-si
    execute_cmd_wroic(0x12, 0x4000);                    // ESSENTIAL BIT2
    execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
//    execute_cmd_wroic(0x5D, 0x02F0);                  // enable charge injection for a-si
//    execute_cmd_wroic(0x5D, 0x0000);                    // 2f0-> 208 over saturation 240130
    execute_cmd_wroic(0x5D, 0x0208);                    // 2f0-> 208 over saturation 240131
	}
else if (msame(mEXT1024   )|| msame(mEXT1024RL)){ //$ 241128 jyp add EXT 1024R to compensate cap. //$ 250703
	execute_cmd_wroic(0x12, 0x4000);                    // ESSENTIAL BIT2
	execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
	execute_cmd_wroic(0x5D, 0x0208);					// COMP1 0.045pF
	}
else if (msame(mEXT2430RI  )){ //$ 250430 EXT2430RI Data 0
    execute_cmd_wroic(0x12, 0x4000);                    // ESSENTIAL BIT2
    execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
    execute_cmd_wroic(0x5D, 0x0210);					// COMP1 0.122pF
	}
else{
    execute_cmd_wroic(0x12, 0x4000);                    // ESSENTIAL BIT2
    execute_cmd_wroic(0x18, 0x0001);                    // ESSENTIAL BIT3
}
     if ((mEXT4343R_series))  execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if ((mEXT2832R_series))  execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if (msame(mEXT2430R))  execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if (msame(mEXT2430RI)) execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if (msame(mEXT810R))   execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else if (msame(mEXT2430RD)) execute_cmd_wroic(0x11, 0x8400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV
else                        execute_cmd_wroic(0x11, 0x0400); // ESSENTIAL BIT1, STR0, FORWARD SCAN, No REV

     if (msame(mEXT810R  )) execute_cmd_wroic(0x16, 0xCAC8); // ESSENTIAL BIT5~7, Low Noise Mode
else if (msame(mEXT2430RD)) execute_cmd_wroic(0x16, 0xCAC8); // ESSENTIAL BIT5~7, Low Noise Mode
else                        execute_cmd_wroic(0x16, 0x00C8); // ESSENTIAL BIT5~7, Low Noise Mode

    // User Setting
    execute_cmd_wroic(0x10,    0x03C0);                    // Config Mode0, Sync & Deskew Test Pattern
//    execute_cmd_wroic(0x5C,    0x0800);                    // InputChargeRage(0.6pc)/LPF1/LPF2 210107 mbh
    u8 ifs_data = get_roic_data(0);                        // dskim - 21.03.19
    //# set_roic_data(0, ifs_data); //# not using, comment #230411
    execute_cmd_ifs(ifs_data);      //# ifs set all routine. #230411

////    // Finished
    execute_cmd_wroic(0x13,    0x0000);                    // Active Mode
//    /*DEB*/ if (DEBUG) func_printf("roic init done ! \r\n");
// ----------------------------------------------------------------------
// #####################################################################
// ##### ROIC TG #######################################################

    REG(ADDR_ROIC_TP_SEL) = 1; // !!!!! TG alpha use !!!!! mbh 210105
    execute_cmd_grab(0);
    execute_cmd_grab(1);
    execute_cmd_grab(0);
    msdelay(10); // roic sync wait

    execute_cmd_wroic(0x40, (IRST_R << 8     | (IRST_F  ) ));
    execute_cmd_wroic(0x42, (SHR_R << 8     | (SHR_F   ) ));
    execute_cmd_wroic(0x43, (SHS_R << 8     | (SHS_F   ) ));
    execute_cmd_wroic(0x46, (LPF1_R << 8     | (LPF1_F  ) ));
    execute_cmd_wroic(0x47, (LPF2_R << 8     | (LPF2_F  ) ));
    execute_cmd_wroic(0x4A, (TDEF_R << 8     | (TDEF_F  ) )); // TDEF
    execute_cmd_wroic(0x4B, (GATE_R << 8     | (GATE_F  ) )); // GATE
    execute_cmd_wroic(0x50, (DF_SM0_R << 8     | (DF_SM0_F) ));
    execute_cmd_wroic(0x51, (DF_SM1_R << 8     | (DF_SM1_F) ));
    execute_cmd_wroic(0x52, (DF_SM2_R << 8     | (DF_SM2_F) ));
    execute_cmd_wroic(0x53, (DF_SM3_R << 8     | (DF_SM3_F) ));
    execute_cmd_wroic(0x54, (DF_SM4_R << 8     | (DF_SM4_F) ));
    execute_cmd_wroic(0x55, (DF_SM5_R << 8     | (DF_SM5_F) ));

//    execute_cmd_rtimingprofile();
//    execute_cmd_gtimingprofile();

    execute_cmd_fmax2(mclk*100000);

    REG(ADDR_ROIC_TP_SEL) = 0; // !!!!! TG alpha use !!!!! mbh 210105



    //############### STR SETTING ###################################
static    u32 roicstr = 0; //# static for using fps calculation.
    switch(func_roicstr){
        case 256  : roicstr =0; break;
        case 512  : roicstr =1; break;
        case 1024 : roicstr =2; break;
        case 2048 : roicstr =3; break;
        default  : roicstr =0;
    }
    u32 rroictemp = 0;
    rroictemp = execute_cmd_rroic(0x11);
    // func_printf("read 0x11=%x \r\n",rroictemp);
    rroictemp =( rroictemp & ~0x30 ) | ( roicstr<<4 & 0x30 );
    // func_printf("write 0x11=%x \r\n",rroictemp);
    execute_cmd_wroic(0x11, rroictemp); // roic str set
    //###############################################################


    msdelay(200); // mbh210721
    func_printf("\t### roic_settimingprofile Done\r\n"); //$ 250219
    execute_cmd_wroic(0x10,    0); // Sync & Deskew Test Pattern return #250926
//    func_grabbcal = 1; // call bcal with temperature setting.
    // 2604250800 skip auto bcal1 trigger in FW bcal mode (prevents double bcal at boot)
#if !BOOT_BCAL_USE_FW
    func_bcal1_token = 1; //# delete grabbcal #250926
#endif
    // bw_align(); //# 220525
}

void temp_init(void) {
    func_printf("Temperature Init...   ");

    if(ds1731_init()) {
        func_printf("\tError\r\n");
        return;
    }
    phy_temp_init();
    xadc_init();

    func_printf("\tDone\r\n");
}

u32 ds1731_init(void) {
    u32 cnt = 0;

    REG(ADDR_I2C_MODE)         = 0;                // 0x140
    REG(ADDR_I2C_WEN)         = 0;                // 0x124
    REG(ADDR_I2C_REN)         = 0;                // 0x130

    // Configuration
    REG(ADDR_I2C_WSIZE)        = 2;                // 0x128
    REG(ADDR_I2C_WDATA)     = 0xAC0C;            // 0x12C
    REG(ADDR_I2C_WEN)         = 1;                // 0x124
    msdelay(100);
    while(!(REG(ADDR_I2C_DONE))) {
        msdelay(100);
        gige_callback(0);
        if(cnt++ == 10)        return 1;
    }
    REG(ADDR_I2C_WEN)         = 0;                // 0x124
    msdelay(100);

    // Start Convert
    REG(ADDR_I2C_WSIZE)     = 1;                // 0x128
    REG(ADDR_I2C_WDATA)     = 0x51;                // 0x12C
    REG(ADDR_I2C_WEN)         = 1;                // 0x124
    msdelay(100);
    while(!(REG(ADDR_I2C_DONE))) {
        msdelay(100);
        gige_callback(0);
        if(cnt++ == 10)        return 1;
    }
    REG(ADDR_I2C_WEN)         = 0;                // 0x124
    msdelay(100);

    // Read Temperature
    REG(ADDR_I2C_WSIZE)     = 1;                // 0x128
    REG(ADDR_I2C_WDATA)     = 0xAA;                // 0x12C
    REG(ADDR_I2C_WEN)         = 1;                // 0x124
    msdelay(100);
    while(!(REG(ADDR_I2C_DONE))) {
        msdelay(100);
        gige_callback(0);
        if(cnt++ == 10)        return 1;
    }
    REG(ADDR_I2C_WEN)         = 0;                // 0x124
    msdelay(100);

    REG(ADDR_I2C_RSIZE)     = 2;                // 0x134
    REG(ADDR_I2C_MODE)         = 1;                // 0x140

    read_ds1731_temp();
    return 0;
}

void phy_temp_init(void) {
    mdio_write(31, 0xF08A, 0x4500);            // Temperature Sensor Init
}

void xadc_init(void) {
    REG(ADDR_TEMP_EN)        = 1;
}

void bw_align(void) {
    Token_wake = 1; //# wake 220322mbh
    u32 bcalmid0[ROIC_NUM];
    u32 bcalmid1[ROIC_NUM];
    u32 diff = 0;
    u8 fail_flag = 0;
    u8 fail_cnt = 0;

    u32 keepOutEn = 0; //#220510
    keepOutEn = REG(ADDR_OUT_EN);
    REG(ADDR_OUT_EN) = 0;

    do{
        bw_align_fpga(&bcalmid0[0]);
        bw_align_fpga(&bcalmid1[0]);

        fail_flag = 0;
        for(u32 j=0; j<ROIC_NUM; j++)
        {
            diff = abs(bcalmid0[j]-bcalmid1[j]);
            if (diff > 3)
            {
                fail_flag = 1;
                func_printf("fail_cnt(%d) bcalmid0[%d](%d) bcalmid0[%d](%d)\r\n",fail_cnt ,j,bcalmid0[j], j,bcalmid1[j] );
            }
        }
        // ### fail escape
        fail_cnt++;
        if (fail_cnt > 4)
        {
            func_printf("bw_align fail by diff value !!! \r\n");
            REG(ADDR_OUT_EN) = keepOutEn;
            break;
        }
    }while(fail_flag);
    func_bw_align_done = 1; //# 231226
//    func_printf("bw_align done &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& \r\n");

    REG(ADDR_OUT_EN) = keepOutEn;
}


void bw_align_fpga(u32 *bcalmid) {
    u32 cnt = 0;
    u32 grab = func_grab_en;
    u32 keepd2m = 0;
//    u32 keepOutEn = 0;

    // TI_ROIC
//    u32 pd = get_roic_data(11);
//
//    set_roic_data(11, 0);

//    out_en return do at outside. #220510mbh
//    keepOutEn = REG(ADDR_OUT_EN);
//    REG(ADDR_OUT_EN) = 0; // preventing Bcal get an image during trigger mode. 211101mbh

    keepd2m = REG(ADDR_D2M_EN); // mbh210708
    REG(ADDR_D2M_EN) = 0;
    // Sync Test Pattern
    if (AFE3256_series) execute_cmd_wroic(0x1A, 0x000F); //$ 251121
    else 				execute_cmd_wroic(0x10, 0x03C0);


    REG(ADDR_SHUTTER_MODE) = 0;
    REG(ADDR_TRIG_MODE) = 0; // 211027mbh
    REG(ADDR_FRAME_TIME) = 0; //# 0x74 checked
    REG(ADDR_EXP_TIME) = 0;
    REG(ADDR_SEXP_TIME) = 0; //# 0x21c checked

//    REG(ADDR_LINE_TIME) = 0; //# 0x1a0 checked # 220510mbh ADDR_EXT_EXP_TIME
//    REG(ADDR_EXT_EXP_TIME) = 0; //## 220510mbh
//    REG(ADDR_EXT_FRAME_TIME) = 0; //## 220510mbh
//    REG(ADDR_RST_NUM) = 0; //## 220510mbh
//    REG(ADDR_ERASE_TIME) = 0; //## 220510mbh
//    REG(ADDR_FRAME_NUM) = 0; //## 220510mbh

    execute_cmd_grab(1);

    func_printf("Bit & Word Align...");
    REG(ADDR_REQ_ALIGN) = 1;
    while(!(REG(ADDR_ALIGN_DONE))) {
//        msdelay(100);
        msdelay(50); //# 250912
        gige_callback(0);
        func_printf(" .");
        if(cnt++ == 30) { //# it was 50. #220531
            REG(ADDR_REQ_ALIGN) = 0;
            execute_cmd_grab(grab);
            func_printf("\033[31m"); //red
            func_printf("\tError\r\n");
            execute_cmd_bcal_rdata();
            func_printf("\033[0m"); // default
            //return;
            break;
        }
    }

    REG(ADDR_REQ_ALIGN) = 0;

    execute_cmd_grab(grab);
    execute_cmd_smode(func_shutter_mode);
    execute_cmd_tmode(func_trig_mode); // 211027mbh
//    execute_cmd_frate((u32)(func_frate*1000));
//    execute_cmd_gewt(func_gewt);
    execute_cmd_gewt(func_gewt); // 220121mbh
    execute_cmd_fmax();
    execute_cmd_frate(0);
    execute_cmd_emax();

    // TI_ROIC
//    set_roic_data(11, pd);
    // Normal Data
    if (AFE3256_series) execute_cmd_wroic(0x1A, 0x0000); //$ 251121
    else				execute_cmd_wroic(0x10, 0x0000); // mbh 210119
    // ROIC RAMP Pattern
//    execute_cmd_wroic(0x10,    0x0260);

    // dskim - 21.04.12 - 디버깅 코드 주석
//   msdelay(200);
//   u32 bglw0 = REG(ADDR_SYNC_RDATA_BGLW3);
//   u16 big0  = (bglw0 >>16) & 0xFFFF;
//   u32 bglw1 = REG(ADDR_SYNC_RDATA_BGLW7);
//   u16 big1  = (bglw1 >>16) & 0xFFFF;
//   func_printf("video read = %5d, %5d", big0, big1);
//   if (big0 < 5000 && big1 < 5000)
//       func_printf("\tDone\r\n");
//   else
//       func_printf("\tError!!!!!!!!!!!\r\n");
//
//   execute_cmd_bcal_rdata();

    REG(ADDR_D2M_EN) = keepd2m; // d2m recover 210708

    func_printf("\tDone\r\n");
    msdelay(100); // preventing Bcal get an image during trigger mode. 211101bmh
//    REG(ADDR_OUT_EN) = keepOutEn; //# 220510mbh

    //### read mid data ###

    //u32 rdata = 0;
    for(u32 i=0; i<ROIC_NUM; i++){
        REG(ADDR_BCAL_CTRL) = i;
        msdelay(10);
        *bcalmid = (REG(ADDR_BCAL_DATA)>>8)&0xff;
        bcalmid++;
    }
    REG(ADDR_BCAL_CTRL) = 0; //# 220609 bug
}

// 2604242200 ==== FW-driven bit-align (separated bit_stable + word_align) ====
// Goal: make alignment fully observable from FW; replace the HW FSM during
//       diagnostics. HW FSM remains intact; choose via fw_mode_en bit.
//
// Hardware contract (from TI_LVDS_RX.vhd 2604242200 changes):
//   - ADDR_BCAL_FW_CTRL: write fw_en/ch_sel + pulses (CE/RST/BS/PROBE auto-clear)
//   - ADDR_BCAL_FW_PAR : read sdata_par(ch_sel)[23:0] + diff_lat[24] + ff00_lat[25]
//                                                    + sdata_val[26] + bs_mode[27]
//   - ADDR_BCAL_FW_STATUS: ocnt[4:0] + oser[9:5] + obs[14:10] + rdy[16]
//   - sticky latch in rclk_ch domain auto-resets on any pulse
//
// Timing: 1 measurement window per tap. Runtime variable bcalfw_wait_us
//   driven by run_all (DOUBLE_PASS toggles FAST/SLOW for comparison).
//   Default at boot = SLOW (100us). FAST = 1us for short-window check.
#define BCAL_FW_NUM_TAPS         32
#define BCAL_FW_BS_MAX           (24*4)
//# 2605081600 strict word_align: par must equal target FFF000, not just ff00_lat
#define BCAL_FW_PAR_TARGET       0xFFF000u
//# 2605081600 retry whole bit_stable+word_align up to N more times if par != target
#define BCAL_FW_RETRY_MAX        3

u32 bcalfw_wait_us = BCAL_FW_STABLE_WAIT_US_FAST;   // 2604251400 default FAST (1us)

#define BCAL_FW_PAR_DIFF_LAT(x)  (((x) >> 24) & 1u)
#define BCAL_FW_PAR_FF00_LAT(x)  (((x) >> 25) & 1u)
#define BCAL_FW_PAR_VAL(x)       (((x) >> 26) & 1u)
#define BCAL_FW_PAR_BSMODE(x)    (((x) >> 27) & 1u)
#define BCAL_FW_PAR_DATA(x)      ((x) & 0xFFFFFFu)

static u32 bcal_fw_ctrl_shadow = 0; // current ch_sel + fw_en (pulses always 0 in shadow)

// 2604242300 ROIC mode keep across init/exit
// 2604242330 strengthened: full keep/restore matching bw_align_fpga (avoid main-loop hang)
static u32 bcal_fw_keep_d2m_en  = 0;
static u32 bcal_fw_keep_out_en  = 0;
static u32 bcal_fw_keep_grab_en = 0;
static u8  bcal_fw_init_done    = 0; // guard: avoid double-keep if init called twice

void bw_align_fw_init(void) {
    BCALFW_DBG("[dbg] init> enter\r\n");
    if (!bcal_fw_init_done) {
        bcal_fw_keep_out_en  = REG(ADDR_OUT_EN);
        bcal_fw_keep_d2m_en  = REG(ADDR_D2M_EN);
        bcal_fw_keep_grab_en = func_grab_en;
        bcal_fw_init_done    = 1;
    }
    REG(ADDR_OUT_EN) = 0;
    REG(ADDR_D2M_EN) = 0;
    REG(ADDR_SHUTTER_MODE) = 0;
    REG(ADDR_TRIG_MODE)    = 0;
    // REG(ADDR_FRAME_TIME)   = 0; //# 26051314
    REG(ADDR_EXP_TIME)     = 0;
    REG(ADDR_SEXP_TIME)    = 0;
    if (AFE3256_series) execute_cmd_wroic(0x1A, 0x000F);
    else                execute_cmd_wroic(0x10, 0x03C0);
    // 2604250100 do NOT call execute_cmd_grab(1) here - DDR framebuffer write
    //            stays active during entire 14ch sweep with frame_time=0
    //            -> memory corruption -> system reset.
    //            SERDES alignment does not need grab; ROIC SPI test pattern is enough.
    msdelay(10);
    bcal_fw_ctrl_shadow = BCAL_FW_CTRL_EN_BIT;
    REG(ADDR_BCAL_FW_CTRL) = bcal_fw_ctrl_shadow;
    BCALFW_DBG("[dbg] init> done\r\n");
}

void bw_align_fw_exit(void) {
    BCALFW_DBG("[dbg] exit> enter\r\n");
    bcal_fw_ctrl_shadow = 0;
    REG(ADDR_BCAL_FW_CTRL) = 0;
    if (AFE3256_series) execute_cmd_wroic(0x1A, 0x0000);
    else                execute_cmd_wroic(0x10, 0x0000);
    if (!bcal_fw_init_done) { BCALFW_DBG("[dbg] exit> no init\r\n"); return; }
    REG(ADDR_OUT_EN)  = bcal_fw_keep_out_en;
    REG(ADDR_D2M_EN)  = bcal_fw_keep_d2m_en;
    func_hwload_flag  = 0;        // safety: avoid update_hwload trigger
    Token_wake        = 1;
    bcal_fw_init_done = 0;
    BCALFW_DBG("[dbg] exit> done\r\n");
}

void bw_align_fw_set_ch(u8 ch) {
    if (ch >= ROIC_NUM) return;
    bcal_fw_ctrl_shadow = (bcal_fw_ctrl_shadow & ~(0xFFu << BCAL_FW_CTRL_CH_SHIFT))
                        | ((u32)ch << BCAL_FW_CTRL_CH_SHIFT)
                        | BCAL_FW_CTRL_EN_BIT;
    REG(ADDR_BCAL_FW_CTRL) = bcal_fw_ctrl_shadow;
    BCALFW_DBG("[dbg] set_ch ch=%d CTRL=0x%08lX\r\n",
               (int)ch, (unsigned long)bcal_fw_ctrl_shadow);
}

void bw_align_fw_pulse(bcal_fw_pulse_t type) {
    u32 bit = 0;
    switch (type) {
        case BCAL_FW_PULSE_CE:    bit = BCAL_FW_CTRL_CE_PULSE;    break;
        case BCAL_FW_PULSE_RST:   bit = BCAL_FW_CTRL_RST_PULSE;   break;
        case BCAL_FW_PULSE_BS:    bit = BCAL_FW_CTRL_BS_PULSE;    break;
        case BCAL_FW_PULSE_PROBE: bit = BCAL_FW_CTRL_PROBE_PULSE; break;
    }
    REG(ADDR_BCAL_FW_CTRL) = bcal_fw_ctrl_shadow | bit;
    BCALFW_DBG("[dbg] pulse %s\r\n",
               (type == BCAL_FW_PULSE_CE)    ? "CE" :
               (type == BCAL_FW_PULSE_RST)   ? "RST" :
               (type == BCAL_FW_PULSE_BS)    ? "BS"  : "PROBE");
}

u32 bw_align_fw_read_par(void)    { return REG(ADDR_BCAL_FW_PAR);    }
u32 bw_align_fw_read_status(void) { return REG(ADDR_BCAL_FW_STATUS); }

// Find the widest contiguous stable window in stable_map[0..31].
// Returns 0 if found (eye_start/end/mid/width set), -1 if none.
static int bcal_fw_find_widest_eye(const u8 *stable_map,
                                   int *eye_start, int *eye_end,
                                   int *eye_mid,   int *eye_width) {
    int best_s = -1, best_e = -1, best_w = 0;
    int cur_s = -1;
    for (int t = 0; t < BCAL_FW_NUM_TAPS; t++) {
        if (stable_map[t]) {
            if (cur_s < 0) cur_s = t;
            int w = t - cur_s + 1;
            if (w > best_w) { best_w = w; best_s = cur_s; best_e = t; }
        } else {
            cur_s = -1;
        }
    }
    if (best_s < 0) {
        *eye_start = -1; *eye_end = -1; *eye_mid = -1; *eye_width = 0;
        return -1;
    }
    *eye_start = best_s;
    *eye_end   = best_e;
    *eye_mid   = (best_s + best_e) / 2;
    *eye_width = best_w;
    return 0;
}

// Phase 5: Bit Stable - sweep IDELAY 0..31, measure sticky diff/ff00 per tap,
//          find widest stable region, place IDELAY at mid.
int bw_align_fw_bit_stable(u8 ch, bcal_fw_stable_result_t *res, u8 verbose) {
    (void)verbose; // gated by DBG_BCALFW now
    BCALFW_DBG("[dbg] bit_stable> ch=%d\r\n", ch);
    if (res == NULL) return -1;
    for (int i = 0; i < BCAL_FW_NUM_TAPS; i++) {
        res->stable_map[i] = 0;
        res->ff00_map[i]   = 0;
        res->par_log[i]    = 0;
    }
    res->status = -1;

    bw_align_fw_set_ch(ch);
    bw_align_fw_pulse(BCAL_FW_PULSE_RST);     // tap=0 + latch reset
    usdelay(bcalfw_wait_us);

    BCALFW_DBG("[dbg] bit_stable sweep ch%d tap par      diff ff00 result\r\n", ch);

    for (int tap = 0; tap < BCAL_FW_NUM_TAPS; tap++) {
        u32 par_val = bw_align_fw_read_par();
        u32 diff    = BCAL_FW_PAR_DIFF_LAT(par_val);
        u32 ff00    = BCAL_FW_PAR_FF00_LAT(par_val);
        u32 par24   = BCAL_FW_PAR_DATA(par_val);

        res->par_log[tap]    = par24;
        res->stable_map[tap] = (diff == 0) ? 1 : 0;
        res->ff00_map[tap]   = (ff00 == 1) ? 1 : 0;

        BCALFW_DBG("[dbg] ch%d t%2d 0x%06lX d%lu f%lu %s\r\n",
                   ch, tap, (unsigned long)par24,
                   (unsigned long)diff, (unsigned long)ff00,
                   res->stable_map[tap] ? "STABLE" : "UNSTABLE");

        bw_align_fw_pulse(BCAL_FW_PULSE_CE);
        usdelay(bcalfw_wait_us);
        gige_callback(0);
    }

    if (bcal_fw_find_widest_eye(res->stable_map,
                                &res->eye_start, &res->eye_end,
                                &res->eye_mid,   &res->eye_width) < 0) {
        func_printf("ch%2d bit_stable FAIL (no eye)\r\n", ch);
        res->status = -1;
        return -1;
    }

    bw_align_fw_pulse(BCAL_FW_PULSE_RST);
    usdelay(bcalfw_wait_us);
    for (int i = 0; i < res->eye_mid; i++) {
        bw_align_fw_pulse(BCAL_FW_PULSE_CE);
        usdelay(2);
    }
    usdelay(bcalfw_wait_us);

    if (verbose) {     // 2604250500 OK only on verbose=1; quiet for run_all
        func_printf("ch%2d bit_stable OK  mid=%d width=%d (eye %d~%d)\r\n",
                    ch, res->eye_mid, res->eye_width,
                    res->eye_start, res->eye_end);
    }
    res->status = 0;
    BCALFW_DBG("[dbg] bit_stable< ok\r\n");
    return 0;
}

// Phase 6: Word Align - bitslip until ff00_lat=1 (FFF000 pattern matched).
//          Assumes IDELAY is already placed at a stable position.
int bw_align_fw_word_align(u8 ch, bcal_fw_word_result_t *res, u8 verbose) {
    (void)verbose;
    BCALFW_DBG("[dbg] word_align> ch=%d\r\n", ch);
    if (res == NULL) return -1;
    res->bitslip_count = -1;
    res->par_at_match  = 0;
    res->status        = -1;

    bw_align_fw_set_ch(ch);
    bw_align_fw_pulse(BCAL_FW_PULSE_PROBE);
    usdelay(bcalfw_wait_us);

    //# 2605081600 strict match: require par24 == 0xFFF000 (not just ff00_lat sticky)
    //#            ff00_lat could fire on shifted patterns (e.g. 0x1FFE00) leading
    //#            to false OK; track best partial match for diagnostic only.
    int  best_bs   = -1;
    u32  best_par  = 0;
    u32  best_ff00 = 0;
    for (int bs = 0; bs <= BCAL_FW_BS_MAX; bs++) {
        u32 par_val = bw_align_fw_read_par();
        u32 ff00    = BCAL_FW_PAR_FF00_LAT(par_val);
        u32 par24   = BCAL_FW_PAR_DATA(par_val);

        BCALFW_DBG("[dbg] ch%d bs=%2d par=0x%06lX f%lu\r\n",
                   ch, bs, (unsigned long)par24, (unsigned long)ff00);

        //# 2605081600 strict success: par24 must equal target word
        if (par24 == BCAL_FW_PAR_TARGET) {
            res->bitslip_count = bs;
            res->par_at_match  = par24;
            res->status        = 0;
            if (verbose) {     // 2604250500 OK only on verbose=1
                func_printf("ch%2d word_align OK  bs=%d par=0x%06lX\r\n",
                            ch, bs, (unsigned long)par24);
            }
            return 0;
        }

        //# 2605081600 remember last ff00_lat hit for diagnostic on FAIL
        if (ff00 && best_bs < 0) {
            best_bs   = bs;
            best_par  = par24;
            best_ff00 = ff00;
        }

        if (bs == BCAL_FW_BS_MAX) break;
        bw_align_fw_pulse(BCAL_FW_PULSE_BS);
        usdelay(bcalfw_wait_us);
        gige_callback(0);
    }

    //# 2605081600 expose best partial result so retry caller can decide
    res->bitslip_count = best_bs;
    res->par_at_match  = best_par;
    res->status        = -1;
    func_printf("ch%2d word_align FAIL (no 0x%06lX in %d bs; best bs=%d par=0x%06lX f%lu)\r\n",
                ch, (unsigned long)BCAL_FW_PAR_TARGET,
                BCAL_FW_BS_MAX, best_bs, (unsigned long)best_par,
                (unsigned long)best_ff00);
    return -1;
}

// Phase 7: Run both stages on one channel; continue word_align even if bit_stable
// fails so the diagnostic captures both result sets.
int bw_align_fw_run_one_ch(u8 ch, bcal_fw_full_result_t *res, u8 verbose) {
    BCALFW_DBG("[dbg] run_one_ch> ch=%d\r\n", ch);
    if (res == NULL) return -1;
    bw_align_fw_init();

    //# 2605081600 retry up to BCAL_FW_RETRY_MAX times until par == 0xFFF000 AND
    //#            eye_mid is in valid range. Earlier code accepted ff00_lat alone
    //#            and printed OK even for par=0x1FFE00.
    int s = -1, w = -1;
    int attempt = 0;
    for (attempt = 0; attempt <= BCAL_FW_RETRY_MAX; attempt++) {
        s = bw_align_fw_bit_stable(ch, &res->stable, verbose);
        w = bw_align_fw_word_align(ch, &res->word,   verbose);

        u8 mid_ok = (res->stable.status == 0 &&
                     res->stable.eye_mid >= 0 &&
                     res->stable.eye_mid < BCAL_FW_NUM_TAPS);
        u8 par_ok = (res->word.status == 0 &&
                     res->word.par_at_match == BCAL_FW_PAR_TARGET);
        if (mid_ok && par_ok) {
            if (attempt > 0) {
                func_printf("ch%2d bcalfw retry%d OK  mid=%d par=0x%06lX\r\n",
                            ch, attempt,
                            res->stable.eye_mid,
                            (unsigned long)res->word.par_at_match);
            }
            break;
        }
        if (attempt < BCAL_FW_RETRY_MAX) {
            func_printf("ch%2d bcalfw retry%d (mid=%d par=0x%06lX target=0x%06lX)\r\n",
                        ch, attempt + 1,
                        res->stable.eye_mid,
                        (unsigned long)res->word.par_at_match,
                        (unsigned long)BCAL_FW_PAR_TARGET);
        }
    }

    if (s < 0)      res->overall_status = 1;
    else if (w < 0) res->overall_status = 2;
    else            res->overall_status = 0;
    return res->overall_status;
}

// 2604251000 Single sweep+report pass at the currently set bcalfw_wait_us.
//             Used directly by run_all (single mode) and twice when
//             BCAL_FW_DOUBLE_PASS=1 (FAST then SLOW comparison).
static void bcalfw_one_pass(u8 verbose) {
    // 2604250900 added stable_map[32] for O/X per-tap visualization in report
    struct {
        int s_mid; int s_width; int s_start; int s_end; int s_status;
        int w_bs;  u32 w_par;   int w_status;
        u8  stable_map[32];
    } sum[ROIC_NUM];

    func_printf("===== bcalfw pass start (wait_us=%lu, %lu ch) =====\r\n",
                (unsigned long)bcalfw_wait_us, (unsigned long)ROIC_NUM);

    for (u32 ch = 0; ch < ROIC_NUM; ch++) {
        bcal_fw_stable_result_t s;
        bcal_fw_word_result_t   w;
        //# 2605081600 retry bit_stable+word_align until par == 0xFFF000 AND mid valid
        //#            (was: accepted ff00_lat alone, allowing false OK at par=0x1FFE00)
        for (int attempt = 0; attempt <= BCAL_FW_RETRY_MAX; attempt++) {
            bw_align_fw_bit_stable((u8)ch, &s, verbose);
            gige_callback(0); msdelay(20); gige_callback(0);
            bw_align_fw_word_align((u8)ch, &w, verbose);
            gige_callback(0); msdelay(20); gige_callback(0);

            u8 mid_ok = (s.status == 0 && s.eye_mid >= 0 && s.eye_mid < BCAL_FW_NUM_TAPS);
            u8 par_ok = (w.status == 0 && w.par_at_match == BCAL_FW_PAR_TARGET);
            if (mid_ok && par_ok) {
                if (attempt > 0) {
                    func_printf("ch%2lu bcalfw retry%d OK  mid=%d par=0x%06lX\r\n",
                                (unsigned long)ch, attempt,
                                s.eye_mid, (unsigned long)w.par_at_match);
                }
                break;
            }
            if (attempt < BCAL_FW_RETRY_MAX) {
                func_printf("ch%2lu bcalfw retry%d (mid=%d par=0x%06lX target=0x%06lX)\r\n",
                            (unsigned long)ch, attempt + 1,
                            s.eye_mid,
                            (unsigned long)w.par_at_match,
                            (unsigned long)BCAL_FW_PAR_TARGET);
            }
        }

        sum[ch].s_mid    = s.eye_mid;
        sum[ch].s_width  = s.eye_width;
        sum[ch].s_start  = s.eye_start;
        sum[ch].s_end    = s.eye_end;
        sum[ch].s_status = s.status;
        sum[ch].w_bs     = w.bitslip_count;
        sum[ch].w_par    = w.par_at_match;
        sum[ch].w_status = w.status;
        for (int t = 0; t < 32; t++) {
            sum[ch].stable_map[t] = s.stable_map[t];
        }
    }

    func_printf("===== bcalfw report (wait_us=%lu) =====\r\n",
                (unsigned long)bcalfw_wait_us);
    // 2604251100 align tap index header with stable_map content position
    //            ch 0  [OOO...]  -> '[' at col 7, first map char at col 8
    func_printf("   tap=0         1         2         3            result\r\n");
    func_printf("       01234567890123456789012345678901\r\n");
    for (u32 ch = 0; ch < ROIC_NUM; ch++) {
        char map_str[33];
        // 2604251200 'O'=stable / '-'=unstable / '@'=mid position highlight
        for (int t = 0; t < 32; t++) {
            map_str[t] = sum[ch].stable_map[t] ? 'o' : '-';
        }
        if (sum[ch].s_status == 0 &&
            sum[ch].s_mid >= 0 && sum[ch].s_mid < 32) {
            map_str[sum[ch].s_mid] = '@';
        }
        map_str[32] = '\0';
        //# 2605081600 OK only when mid valid AND par == 0xFFF000 (was: any w_status==0)
        u8 rep_mid_ok = (sum[ch].s_status == 0 &&
                         sum[ch].s_mid >= 0 && sum[ch].s_mid < 32);
        u8 rep_par_ok = (sum[ch].w_status == 0 &&
                         sum[ch].w_par == BCAL_FW_PAR_TARGET);
        if (rep_mid_ok && rep_par_ok) {
            func_printf("ch%2lu  [%s]  mid=%2d w=%2d bs=%2d par=0x%06lX  \033[32m  OK\033[0m\r\n",
                        (unsigned long)ch, map_str,
                        sum[ch].s_mid, sum[ch].s_width,
                        sum[ch].w_bs, (unsigned long)sum[ch].w_par);
        } else {
            func_printf("ch%2lu  [%s]  s_st=%2d w_st=%2d mid=%2d bs=%2d  \033[31mFAIL\033[0m\r\n",
                        (unsigned long)ch, map_str,
                        sum[ch].s_status, sum[ch].w_status,
                        sum[ch].s_mid, sum[ch].w_bs);
        }
    }
}

// 2604251000 Double-pass mode (#define BCAL_FW_DOUBLE_PASS 1) runs the sweep
//             twice with bcalfw_wait_us=FAST then SLOW so user can compare
//             stable_map between settle times.
void bw_align_fw_run_all(u8 verbose) {
    BCALFW_DBG("[dbg] run_all> ROIC_NUM=%lu DOUBLE_PASS=%d\r\n",
               (unsigned long)ROIC_NUM, BCAL_FW_DOUBLE_PASS);

    bw_align_fw_init();
#if BCAL_FW_DOUBLE_PASS
    bcalfw_wait_us = BCAL_FW_STABLE_WAIT_US_FAST;
    bcalfw_one_pass(verbose);
    bcalfw_wait_us = BCAL_FW_STABLE_WAIT_US_SLOW;
    bcalfw_one_pass(verbose);
#else
    bcalfw_wait_us = BCAL_FW_STABLE_WAIT_US_FAST;   // 2604251400 single-pass uses FAST (1us)
    bcalfw_one_pass(verbose);
#endif
    bw_align_fw_exit();
}

void tft_set(void) {
    // TI_ROIC
    float MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000.0;
    float MCLK_KHz = FPGA_TFT_MAIN_CLK / 1000.0;

    REG(ADDR_ROIC_CDS1)            = (u32)(func_roic_cds1         * MCLK_MHz);
    REG(ADDR_ROIC_CDS2)            = (u32)(func_roic_cds2         * MCLK_MHz);
    REG(ADDR_ROIC_INTRST)        = (u32)(func_roic_intrst     * MCLK_MHz);

    REG(ADDR_GATE_OE)            = (u32)(func_gate_oe         * MCLK_MHz);
    REG(ADDR_GATE_XON)            = (u32)(func_gate_xon         * MCLK_MHz);
    REG(ADDR_GATE_XON_FLK)        = (u32)(func_gate_xonflk     * MCLK_MHz);
    REG(ADDR_GATE_FLK)            = (u32)(func_gate_flk         * MCLK_MHz);

    REG(ADDR_GATE_RST_CYCLE)    = (u32)(func_gate_rcycle    * MCLK_KHz);
    REG(ADDR_ERASE_TIME)        = (u32)(func_erase_time     * MCLK_KHz);

    execute_cmd_tseq(func_tft_seq);

// #ifdef EXT1616R
// //    float MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000.0;
// //    float MCLK_KHz = FPGA_TFT_MAIN_CLK / 1000.0;
// //
// //    REG(ADDR_ROIC_CDS1)            = (u32)(func_roic_cds1         * MCLK_MHz);
// //    REG(ADDR_ROIC_CDS2)            = (u32)(func_roic_cds2         * MCLK_MHz);
// //    REG(ADDR_ROIC_INTRST)        = (u32)(func_roic_intrst     * MCLK_MHz);
// //
// //    REG(ADDR_GATE_OE)            = (u32)(func_gate_oe         * MCLK_MHz);
// //    REG(ADDR_GATE_XON)            = (u32)(func_gate_xon         * MCLK_MHz);
// //    REG(ADDR_GATE_XON_FLK)        = (u32)(func_gate_xonflk     * MCLK_MHz);
// //    REG(ADDR_GATE_FLK)            = (u32)(func_gate_flk         * MCLK_MHz);
// //
// //    REG(ADDR_GATE_RST_CYCLE)    = (u32)(func_gate_rcycle    * MCLK_KHz);
// //    REG(ADDR_ERASE_TIME)        = (u32)(func_erase_time     * MCLK_KHz);
// //
// //    execute_cmd_tseq(func_tft_seq);
// //    roic_settimingprofile(200, 256, 1000, 2000, 8000,  2000);
// #else
// //    roic_settimingprofile(125, 256, 1000, 2000, 15000, 2000);
// #endif

//    execute_cmd_gtimingprofile(); // read wave
}

void ext_trig_set(void) {
//    REG(ADDR_EXT_TRIG_ACTIVE)    = 0b01;        // Input     : High Active
                                            // Outout     : Low Active
    REG(ADDR_EXT_TRIG_ACTIVE)    = 0b00; // mbh 210511 both for active high
}


u32 set_str_data(u8 *data) {
    return (u32)((data[0] & 0xFF) << 24) | ((data[1] & 0xFF) << 16) | ((data[2] & 0xFF) << 8) | ((data[3] & 0xFF) << 0);
}

u32 set_userset_data(u32 table, u8 step) {
    return set_str_data(&USERSET_NAME[table][step*4]);
}

void get_str_data(u32 value, u8 *data) {
    data[0] = (value >> 24) & 0xFF;
    data[1] = (value >> 16) & 0xFF;
    data[2] = (value >> 8 ) & 0xFF;
    data[3] = (value >> 0 ) & 0xFF;
}

void get_userset_data(u32 table, u32 value, u8 step) {
    USERSET_NAME[table][(step*4)+0] = (value >> 24) & 0xFF;
    USERSET_NAME[table][(step*4)+1] = (value >> 16) & 0xFF;
    USERSET_NAME[table][(step*4)+2] = (value >> 8 ) & 0xFF;
    USERSET_NAME[table][(step*4)+3] = (value >> 0 ) & 0xFF;
}

void genicam_command(void) {
    execute_user_cmd();
    execute_calib_cmd();
    execute_flash_cmd();
}

void update_data(void) {
    if(func_frame_num == 0){
        update_image();
    }

    if(func_bcal1_token == 1) // bcal1 220117mbh
    {
        update_bcal1();
        func_bcal1_token = 0;
    }
}

static u32 prev_acc_change = 0;
//# 2605131126 Throttle ACC polling to 1/ACC_POLL_DIV iters. ADDR_ACC_CTRL and
//             ADDR_ACC_STAT change rarely (operator-driven mode toggle), so a
//             100x slower poll cadence still catches edge transitions in <100ms.
//# 2605131355 Runtime gate: skip update_acc() entirely while ACC is OFF.
//             func_acc_enabled is set by execute_cmd_acc (func_cmd.c) -- mirrors
//             the `on` bit written to ADDR_ACC_CTRL. Boot default 0 -> no REG()
//             traffic until the operator enables ACC via the 'acc' UART command
//             or static-avg path.
#define ACC_POLL_DIV 100
void update_acc(void) {
    if (!func_acc_enabled) return;          //# ACC feature not turned on

    static u32 _th = ACC_POLL_DIV - 1;
    if (++_th < ACC_POLL_DIV) return;
    _th = 0;

    u32 acc_autorst_enable = ((REG(ADDR_ACC_CTRL) & 7) == 7) ? 1:0;
//    if(func_acc_read == 1){
    if(acc_autorst_enable == 1){
        u32 curr_acc_change = REG(ADDR_ACC_STAT) & 1;
        if(prev_acc_change == 0 && curr_acc_change == 1)
            func_printf("ACC changing detected !!! \r\n");

        prev_acc_change = curr_acc_change;
    }
}

static u32 prev_func_ether_conn =0;
void update_sleep(void) {
    u32 breaktime_sign = 0;
        switch(func_sleepmode) {
            case 0 : Token_wake = 1;
                break;
            case 1 : //# ethernet conn checker
                    if (func_ether_conn)
                        Token_wake = 1;
                    else
                        Token_sleep = 1;
               break;
            case 2 : //# continuous sleep
                    if (func_out_en)
                        Token_wake = 1;
//                    else if (func_grabbcal) //$ 250620 to avoid bit align error when booting.
					else if (func_bcal1_token) //# del grabbcal #250926
                    	Token_wake = 1;
                    else
                        Token_sleep = 1;
               break;
            case 3 : //# timer sleep
                    if (prev_func_ether_conn==0 && func_ether_conn==1) // only Ethernet connected once
                        breaktime_sign = 0;
                    else if (func_ether_conn==1 && func_out_en==1)
                        breaktime_sign = 0;
                    else
                        breaktime_sign = 1;

                    if (Token_wake) {
                        breaktime_sign = 0;
                    }

                    if (execute_cmd_check_acq_stop_timeover(breaktime_sign)) { //# 5min time over checker
                        Token_sleep = 1;
                    }
                    else {
                        Token_wake = 1;
                    }
               break;
            default :
                Token_wake = 1;
                break;
        }
    prev_func_ether_conn = func_ether_conn;

    //### execute wake
    if(Token_wake == 1){
        execute_cmd_wake();
        Token_wake=0;
    }
    //### execute sleep
    if(Token_sleep == 1){
        execute_cmd_sleep();
        Token_sleep=0;
    }

}
u32 keep_trig_cnt=0;
void update_fwtrig(void) {
    if(func_api_ext_trig_flag == 1)
    {
        func_printf("update_fwtrig...\r\n");
        execute_fw_ext_trig_rst(func_api_ext_trig, func_insert_rst_num);
        func_api_ext_trig_flag = 0;
    }
//    execute_fw_ext_trig_rst(func_api_ext_trig, func_insert_rst_num);
    u32 read_trig_cnt=0;
    if(func_triglog_on == 1)
    {
        read_trig_cnt = REG(ADDR_TRIGCNT);
        if (read_trig_cnt != keep_trig_cnt){
//            disp_cmd_rtime();
            func_printf("hw_ext_trig_cnt = %d\r\n",read_trig_cnt);
            keep_trig_cnt = read_trig_cnt;
        }

    }
}



void update_hwload(void) {
//    if(func_hwload_flag){
    if(func_hwload_flag && func_bw_align_done){ //# bcal after
//    	func_printf("func_hwload_flag ### execute_cmd_load_hw_calibration ###\r\n");
        execute_cmd_load_hw_calibration(func_hwload_flag);
        func_hwload_flag = 0;
    }
}

u32 flashreadold, flashread = 0;
u32 read, read0 = 0;
u32 samecnt = 0;
void checker_rom(void) {

    // ### 4 ADDRESS COMMAND ###
    REG(ADDR_FLAW_CMD)  = FLAW_CMD_ENTER4BYTE; // Write Enable
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1;
    usdelay(10); //
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear
    // ##########################

    REG(ADDR_FLAW_CMD)  = FLAW_CMD_READREGISTER; // Write Enable
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_W1R1;
    usdelay(10); //
    REG(ADDR_FLAW_CTRL) = FPGA_FLAWCMD_CLEAR; // clear
//    func_printf("ADDR_FLAW_RDATA(%08x) \r\n",REG(ADDR_FLAW_RDATA));


    read = (REG(ADDR_FLAW_RDATA) >> 16) & 0xff;
    if (read == read0)
    {
        if (samecnt < 8192)
        {
            samecnt++;
            return;
        }
        else
        {
            samecnt = 0;
            flashread = read0;
        }
    }
    else
    {
        samecnt = 0;
        read0 = read;
        return;
    }


    if (flashreadold != flashread)
    {
        if( (flashread)==0xff )
        {
            func_printf("\r\n ROMs are detached \r\n");
//            execute_cmd_rom();
        }
        else
        {
            func_printf("\r\n ROMs are working \r\n");
            execute_cmd_rom();
        }
    }
    flashreadold = flashread;
}

void update_defect(void) {
    if(func_re_defect == 1) {
        func_printf("start update defect... ");
        func_re_defect = 0;
        execute_cmd_re_defect();
        func_printf("\tDone\r\n");
    }
}

// 2604221700 Boot-force port 0 + N-iteration debounce for SFP auto-switch
int once88m=0;
//# 2605131056 SFP poll throttle: run body only 1/SFP_POLL_DIV main-loop iters.
//             Cuts REG(ADDR_SFP_STAT) traffic 100x. SFP_STAB_CNT reduced from 500 to 5
//             to keep wall-clock debounce duration unchanged (500*1 -> 5*100).
#define SFP_POLL_DIV  100
#define SFP_STAB_CNT  5             // # of consecutive stable POLLS before commit (poll cadence = SFP_POLL_DIV iters)
void check_sfp_stat(void) {
    //# Throttle: skip 99 of every 100 calls. Initialize counter so the FIRST call
    //  passes through (so first_run logic below fires immediately on boot).
    static u32 _th = SFP_POLL_DIV - 1;
    if (++_th < SFP_POLL_DIV) return;
    _th = 0;

    static u8  first_run = 1;
    static u32 prev      = 0;       // committed state (post-init: bit0=0)
    static u32 pending   = 0;       // candidate being debounced
    static u32 cnt       = 0;       // consecutive-stable counter

    //# 2605121219 Background retry for deferred m88x33xx_init when wait_app_ready timed out
    //             at boot path. Internally throttled (~10Hz). No-op when not pending.
    //(void)m88x33xx_retry_init_if_pending();




if ( (g_port_sel==0) && (once88m==0) && (XREG(XGIGE_ADDR_IP)) )
{
    func_printf("##### ONCE88m 0 #####[SFP_STAT] m88x33xx_initx(RXAUI)\r\n");
    m88x33xx_initx(RXAUI);
//  func_printf("##### ONCE88m #####[SFP_STAT] m88x33xx_init(RXAUI)\r\n");
//  execute_cmd_ip(192,168,250,145);
//  m88x33xx_init(RXAUI);
    once88m = 1;
}

if ( (g_port_sel==0) && (once88m==1) && (XREG(XGIGE_ADDR_IP)==0) )
{
//  func_printf("##### ONCE88m #####[SFP_STAT] m88x33xx_initx(RXAUI)\r\n");
//  m88x33xx_initx(RXAUI);
    func_printf("##### ONCE88m 1 #####[SFP_STAT] m88x33xx_init(RXAUI)\r\n");
//  execute_cmd_ip(192,168,250,145);
//  m88x33xx_init(RXAUI);
    once88m = 2;
}

if ( (g_port_sel==0) && (once88m==2) && !(XREG(XGIGE_ADDR_IP)) )
{
//  func_printf("##### ONCE88m #####[SFP_STAT] m88x33xx_initx(RXAUI)\r\n");
//  m88x33xx_initx(RXAUI);
    func_printf("##### ONCE88m 2 #####[SFP_STAT] m88x33xx_init(RXAUI)\r\n");
    execute_cmd_ip(192,168,250,145);
    m88x33xx_init(RXAUI);
    once88m = 3;
}
    u32 cur = REG(ADDR_SFP_STAT);

    // ---- Boot init: unconditionally force port 0 (RXAUI) ----
    if (first_run) {
        first_run = 0;
        func_printf("[SFP_STAT] boot init: force execute_cmd_port(0) (RXAUI)\r\n");
        execute_cmd_port(0);
        prev    = 0;
        pending = cur;
        cnt     = 0;
        return;
    }

    // ---- Stable at committed value: reset debounce, no action ----
    if (cur == prev) {
        cnt = 0;
        return;
    }

    // ---- Candidate tracking ----
    if (cur != pending) {
        pending = cur;              // flicker to a new value -> restart count
        cnt     = 0;
        return;
    }

    cnt++;
    if (cnt < SFP_STAB_CNT) return; // not yet stable

    // ---- Stable for SFP_STAB_CNT iterations: commit and report ----
    u32 diff = cur ^ prev;

    if (diff & 0x01) {
        u8 nb = (u8)(cur & 1);
        func_printf("[SFP_STAT] sfp_phy_sel %u->%u (stable %u)\r\n",
                    (u8)(prev & 1), nb, SFP_STAB_CNT);
        execute_cmd_port(nb);
        once88m=0;
        func_printf("[SFP_STAT] -> execute_cmd_port(%u), g_port_sel=%u\r\n",
                    nb, g_port_sel);
    }
    if (diff & 0x02) {
        func_printf("[SFP_STAT] sfp_rst_done %u->%u\r\n",
                    (u8)((prev >> 1) & 1), (u8)((cur >> 1) & 1));
    }
    if (diff & 0x04) {
        func_printf("[SFP_STAT] sfp_signal_detect %u->%u\r\n",
                    (u8)((prev >> 2) & 1), (u8)((cur >> 2) & 1));
    }

    prev = cur;
    cnt  = 0;
}

void update_trig(void) {
    static u32 prev = 0;
    float MCLK_MHz = FPGA_TFT_MAIN_CLK / 1000000.0;

    if(prev == func_trig_mode)    return;

    switch (func_trig_mode) {
        case 0 :    if(prev == 0)    return;
                    else {
                        func_frate = (float)FPGA_TFT_MAIN_CLK / REG(ADDR_FRAME_TIME);
                        execute_cmd_emax();
                    }
                    break;

        case 1 :     func_frate = (float)FPGA_TFT_MAIN_CLK / REG(ADDR_FRAME_TIME); // 220107mbh REG(ADDR_EXT_FRAME_TIME);
//                    func_printf("3.func_basic.c-update_trig func_frate(%d)=FPGA_TFT_MAIN_CLK(%d)/REG(ADDR_EXT_FRAME_TIME)(%d) \r\n",(u32)func_frate,FPGA_TFT_MAIN_CLK,REG(ADDR_EXT_FRAME_TIME));
                    execute_cmd_emax();
                    break;

        case 2 :    func_frate = (float)FPGA_TFT_MAIN_CLK / REG(ADDR_FRAME_TIME); // 220107mbh  REG(ADDR_EXT_FRAME_TIME);
                    func_gewt = (u32)(REG(ADDR_EXT_EXP_TIME) / MCLK_MHz);
                    execute_cmd_emax();
                    break;
    }

    prev = func_trig_mode;
}

//# 2605131056 Temp-driven bcal poll throttle: run body only 1/TEMP_POLL_DIV iters.
//             Cuts REG(ADDR_DEVICE_TEMP) traffic. The avg/10 smoothing window still
//             works -- it just spans (DIV*10) wall-clock time, which is fine for
//             XADC-based temperature trend monitoring (slow physical signal).
//# 2605131135 DIV 100 -> 1000 (FPGA die temp drifts slowly; 10 samples per ~1-2s
//             of wall-clock is still plenty for the temp-bcal range trigger).
#define TEMP_POLL_DIV  1000
void update_image(void) {
    static u32 _th = TEMP_POLL_DIV - 1;
    if (++_th < TEMP_POLL_DIV) return;
    _th = 0;

    static float prev = 0, curr = 0;
    static float sum = 0;
    static u32 i = 0;

    float range_min = 0, range_max = 0;

    read_fpga_temp();
    sum += func_fpga_temp;

    if(++i < 10)     return;
    curr = sum / 10.0;
    i = 0;
    sum = 0;

//    range_min = prev - 10;
//    range_max = prev + 10;
    //# temp range 10 -> 8 //# 220222mbh
    range_min = prev - 8;
    range_max = prev + 8;

    //### "NO" bcal condition ###
    if((curr >= range_min) &&
       (curr <= range_max) &&
       (func_grabbcal == 0 ))  // added func_grabbcal //# 220222mbh
    	return;

//$ 250219 dclk use x
   if ((def_tempbcal == 0) & (bcal_once == 1)){    //# 241202 add condition def_tempbcal
    	return;				   //# 24120916 bunri condition
    }

    bcal_once = 1;         //# 241230 1024R dclk need bcal once at booting.

    func_grabbcal = 0;
    prev = curr;

    func_printf("FPGA Temperature = ");             float_printf(curr, 1);
    func_printf("\r\nExceed Temperature Range [");     float_printf(range_min, 1); func_printf(" - "); float_printf(range_max, 1); func_printf("]\r\n");

//    Token_wake = 1; //# wake 220322mbh
//    func_printf("\r\n######### ""bw_align();"" dose NOT excuted for burnnig aging"); // 210402 mbh
    // 2604250600 BOOT_BCAL_USE_FW switch (func_basic.h): 0=HW FSM, 1=FW-driven
    if (func_tempbcal == 1) { // 220118mbh
#if BOOT_BCAL_USE_FW
        bw_align_fw_run_all(0);
#else
        bw_align();
#endif
    }

//    func_printf("bw end / rns valid Check %d \r\n", func_rns_valid);

    if(func_rns_valid)    {
    	get_calib_init();    // 0.xx.07 -> 0.xx.09
    }
}

void update_bcal1(void) {
    u32 keepx10 = execute_cmd_rroic(0x10);
    u32 keepx1A = execute_cmd_rroic(0x1A);
    // 2604250700 BOOT_BCAL_USE_FW switch: 0=HW FSM, 1=FW-driven (also covers boot path)
#if BOOT_BCAL_USE_FW
    bw_align_fw_run_all(0);
#else
    bw_align();
#endif
    if(AFE3256_series)	execute_cmd_wroic(0x1A,keepx1A);
    else				execute_cmd_wroic(0x10,keepx10);
    execute_cmd_bcal_rdata();
}

void execute_user_cmd(void) {
    u32 grab = func_grab_en;
    u32 addr = 0;

    if(func_userset_cmd == 0)        return;

    switch(func_userset_cmd) {
        case 1    :    execute_cmd_grab(0);
                    execute_cmd_wus(func_table);
                    execute_cmd_wbs();
                    execute_cmd_grab(grab);
                    break;
        case 2    :     execute_cmd_grab(0);
                    if(execute_cmd_rus(func_table))        func_printf("\r\nERR14: There is User Preset Data\r\n");
                    //    execute_cmd_rbs();
                    // TI_ROIC
//                    roic_init();
                    update_roic_info();        // dskim - 22.07.27 - Correction Type을 변경할 때, Analog Gain 값이 변경되도록 추가
                    tft_set();
                    func_init();
                    execute_cmd_grab(grab);
                    break;
        case 3    :    func_busy = 1;
                    func_busy_time = 10000;
                    addr = FLASH_USER_BASEADDR + (func_table * 0x10000);
                    flash_erase_block(addr);
                    func_printf("Erase Addr: 0x%06x [Interval 0x10000]\r\n", addr);
                    memcpy(&USERSET_NAME[func_table], &DEFAULT_NAME, sizeof(USERSET_NAME[func_table]));
                    break;
    }
    func_userset_cmd = 0;

    func_busy = 0;
    func_busy_time = 0;
}
void execute_calib_cmd(void) {
    if(func_calib_cmd == 0)            return;

    switch(func_calib_cmd) {
        case 1    :    func_busy = 1;
//        			if(AFE3256_series){ //$ 260305
//                        func_busy_time = 300;
//        				execute_cmd_doc();
//        			}
//        			else{
                    func_busy_time = (u32)(((1 << (user_avg_level)) / func_frate) * 1000);
                    execute_cmd_wddr(func_calib_map, user_avg_level);
//                    if((func_calib_map == 1) && (func_check_gain_calib == 1))    // dskim - ti 사용하지 않음
//                        execute_cmd_ucal();
//        			}
                    break;
        case 2    :     execute_cmd_cddr(func_calib_map);
                    break;
        case 3    :     func_busy = 1;
                    func_busy_time = 10000;
                    execute_cmd_gcal();            // 0.xx.07
                    break;
        case 4    :    func_busy = 1;
                    func_busy_time = 20000;
//                    execute_cmd_erase(6);        // dskim - 21.03.22 - defect map 지워지지 않도록 수정함
                    execute_cmd_erase(4);
                    execute_cmd_erase(5);
                    execute_cmd_erase(7);
                    break;
        case 5    :     func_busy = 1;
                    func_busy_time = 1000;
                    execute_cmd_wdot(func_pointx, func_pointy, 0);
                    break;
        case 6    :     func_busy = 1;
                    func_busy_time = 1000;
                    execute_cmd_wdot(func_pointx, func_pointy, 1);
                    break;
        case 7    :     func_busy = 1;
                    func_busy_time = 1000;
                    execute_cmd_timg(func_calib_map);
                    break;
        case 8    :     func_busy = 1;                        // WriteColumnDefect - Write Column Defect Manually
                    func_busy_time = 1000;
                    execute_cmd_wcdot(func_pointx, 0);
                    break;
        case 9    :     func_busy = 1;                        // EraseColumnDefect - Erase Column Defect that be written manually.
                    func_busy_time = 1000;
                    execute_cmd_wcdot(func_pointx, 1);    // dskim - SW0.xx.08
                    break;
        case 10    :     func_busy = 1;                        // WriteRowDefect - Write Row Defect Manually.
                    func_busy_time = 1000;
                    execute_cmd_wrdot(func_pointy, 0);    // dskim - SW0.xx.08
                    break;
        case 11    :     func_busy = 1;                        // EraseRowDefect - Erase Row Defect that be written manually
                    func_busy_time = 1000;
                    execute_cmd_wrdot(func_pointy, 1);
                    break;
        case 12 :
                    // dskim - 21.03.31 - Unicomp. Clear Reference -> Save to memory 동작 예외 처리.
                    if(func_check_gain_calib == 1) {
                        func_busy = 1;
                        func_busy_time = 20000;
//                        execute_cmd_wns(); //$ 250425 test
                        execute_cmd_bwns(); // 210526 write flash by fpga
                        if(func_stop_save_flash == 0)
                        execute_cmd_wds();

                        func_stop_save_flash = 0;
                    }
                    break;
        case 13 :    func_busy = 1;
                    func_busy_time = 20000;
                    execute_cmd_rns();
                    execute_cmd_rds();
                    break;
        case 14 :    func_busy = 1;
                    func_busy_time = 10000;
                    execute_cmd_ucal();
                    break;
        case 15 :    func_busy = 1;
                    func_busy_time = 10000;
                    execute_cmd_wds();
                    break;
                    // 0.xx.09 - dskim
        case 16 :    func_busy = 1;
                    func_busy_time = 1000;
                    execute_cmd_erase(10);
                    break;
    }
    func_calib_cmd = 0;

    func_busy = 0;
    func_busy_time = 0;
}

void execute_flash_cmd(void) {
    if(func_flash_cmd == 0)            return;

    switch(func_flash_cmd) {
        case 1    :    func_busy = 1;
                    func_busy_time = 20000;
                    execute_cmd_erase(4);
                    execute_cmd_erase(5);
//                    execute_cmd_erase(6);    // dskim - 21.05.13 - defect는 지워지지 않도록 변경
                    execute_cmd_erase(7);
                    break;
    }
    func_flash_cmd = 0;

    func_busy = 0;
    func_busy_time = 0;
}

u32 atoi2(u8* arr) {
    char data[12] = {0, };
    char* data2 = 0;
    u32 tmp_data = 0;
    u32 data3 = 0;
    u32 i = 0;

    if(arr[0] == '0' && (arr[1] == 'x' || arr[1] == 'X')) {
        for (i = 0; i < 8; i++)        data[i] = arr[i+2];
        data2 = (char*)data;

        for (data3 = 0, i = 0; *data2 != 0; data2++, i++) {
            if         (*data2 >= '0' && *data2 <= '9')    tmp_data = *data2 - '0';
            else if (*data2 >= 'a' && *data2 <= 'f')    tmp_data = *data2 - 'a' + 10;
            else if (*data2 >= 'A' && *data2 <= 'F')    tmp_data = *data2 - 'A' + 10;
            else                                        break;
            data3 *= 16;
            data3 += tmp_data;
        }
    }
    else {
        for (i = 0; i < 12 ; i++)        data[i] = arr[i];
        data2 = (char*)data;
        for (data3 = 0, i = 0; *data2 != 0; data2++, i++) {
            if         (*data2 >= '0' && *data2 <= '9')    tmp_data = *data2 - '0';
            else                                        break;
            data3 *= 10;
            data3 += tmp_data;
        }
    }
    return data3;
}

void get_register(void) {
    u32 addr = 0, data = 0;
    addr = atoi2(&func_reg_addr[0]);

    switch (func_addr_table) {
        case 0    :    data = REG(addr);                break;
        case 1    :     data = DREG(addr);              break;
        case 2    :     data = AREG(addr);              break;
        case 3    :     data = flash_read_dword(addr);  break;
        case 4    :     data = eeprom_read_dword(addr); break;
        // TI_ROIC
        case 5    :     data = execute_cmd_rroic(addr); break;
    }
    sprintf((char*)func_reg_data, "0x%08x\n", (unsigned int)data);
}

void set_register(void) {
    u32 addr = 0, data = 0;
    u32 grab = func_grab_en;

    addr = atoi2(&func_reg_addr[0]);
    data = atoi2(&func_reg_data[0]);

    switch (func_addr_table) {
        case 0    :    REG(addr)  = data; break;
        case 1    :    DREG(addr) = data; break;
        case 2    :    AREG(addr) = data; break;
        case 3    :                       break;
        case 4    :                       break;
        case 5    :     execute_cmd_grab(0);
                    execute_cmd_wroic(addr, data);
                    // TI_ROIC
                //    update_roic_info();
                    execute_cmd_grab(grab);
                    break;
    }
}

// TI_ROIC
void update_roic_info(void) {
    u32 i, j;
    u16 mask = 0;

    for (i = 0; i < ROIC_REG_NUM; i++) {
        for (j = 0; j < ROIC_MAT[i].size; j++) {
            mask = mask << 1;
            mask |= 0x01;
        }
//        ROIC_MAT[i].data = (func_roic_data[ROIC_MAT[i].addr] >> ROIC_MAT[i].lsb) & mask;
//        ROIC_MAT[i].data = (func_roic_data[ROIC_MAT[i].idx] >> ROIC_MAT[i].lsb) & mask;    // dskim
        //$ 251014
        if(AFE3256_series)
        	ROIC_MAT[1].data = (func_roic_data[ROIC_MAT[1].idx] >> ROIC_MAT[1].lsb) & mask;
        else
        	ROIC_MAT[0].data = (func_roic_data[ROIC_MAT[0].idx] >> ROIC_MAT[0].lsb) & mask;
        mask = 0;
    }

//    REG(ADDR_ROIC_SHAAZEN) = ROIC_MAT[18].data;
}
//$ 260303 AFE3256 ROIC TEMP.
void read_roic_temp(void) {
	u32 data;

	//$ Enable Temp. Sensor
	execute_cmd_wroic(0x03, 0x0006);
	execute_cmd_wroic(0x70, 0x0032);
	execute_cmd_wroic(0x71, 0x00FF);
	execute_cmd_wroic(0x03, 0x0000);
	execute_cmd_wroic(0xE4, 0x8000);
	execute_cmd_wroic(0xE4, 0x0000);
	execute_cmd_wroic(0xE4, 0x8000);

	msdelay(1);

	data = execute_cmd_rroic(0x78) & 0x01FF;
	func_printf("ROIC Temp = %d\r\n",data);
	func_roic_temp = (0.97 * (data -(512 * floor(data/256)))+108)/2.45;

	//$ Disable Temp. Sensor
	execute_cmd_wroic(0x03, 0x0006);
	execute_cmd_wroic(0x70, 0x0000);
	execute_cmd_wroic(0x71, 0x0000);
	execute_cmd_wroic(0x03, 0x0000);
	execute_cmd_wroic(0xE4, 0x0000);
}

u32 temp_arr [2][2][DS1731_NUM] = {0, }; //temperature arry 211112 mbh
void read_ds1731_temp(void) {
    u32 i = 0;
    u32 addr = 0, data = 0;
    u8 icsel =0;

//     toggle command for NCT175(new)
    if (REG(ADDR_I2C_WDATA)==0)
    {
        REG(ADDR_I2C_WDATA) = 0xAA; // ds1731 read temperature command
        icsel = 0;
    }
    else
    {
        REG(ADDR_I2C_WDATA) = 0x0; // nct175 read 0 address
        icsel = 1;
    }

    for (i = 0; i < DS1731_NUM; i++) 
    {
        switch (i) 
        {
          case 0 : addr = ADDR_I2C_RDATA0; break;
          case 1 : addr = ADDR_I2C_RDATA1; break;
          case 2 : addr = ADDR_I2C_RDATA2; break;
          case 3 : addr = ADDR_I2C_RDATA3; break;
        }
        data = REG(addr);
        temp_arr[icsel][0][i] = temp_arr[icsel][1][i]; // 0:old <= 1:new
        temp_arr[icsel][1][i] = data;                  // 1:new <= in data
        // func_printf(" read reg b = 0x%4x \r\n", data);

        if ( temp_arr[icsel][0][i] != temp_arr[icsel][1][i] && \
             temp_arr[icsel][0][i] != 0)
        {
            func_ds1731_temp[i] = (float)data/(1<<8); // calc changed simple 211112
            //func_printf(" [%d][0][%d]0x%4x, [%d][0][%d]0x%4x \r\n" ,icsel,i,temp_arr[icsel][0][i], icsel,i,temp_arr[icsel][1][i]);

//            temp_int     = (data >> 8)     & 0x7F;
//            temp_dec[0] = (data >> 7)    & 0x1;
//            temp_dec[1] = (data >> 6)    & 0x1;
//            temp_dec[2] = (data >> 5)    & 0x1;
//            temp_dec[3] = (data >> 4)    & 0x1;
//            func_ds1731_temp[i] = ((float)temp_int + (float)(temp_dec[0] * 0.5) + (float)(temp_dec[1] * 0.25) + (float)(temp_dec[2] * 0.125) + (float)(temp_dec[3] * 0.0625));
        }
    }
}

void read_phy_temp(void) {
//    func_phy_temp = ((mdio_read(31, 0xF08A) & 0xFF) - 75);
    func_phy_temp = ((mdio_read(31, 0xF08A) & 0xFF) - 95);
}

void read_fpga_temp(void) {
    u32 data = (REG(ADDR_DEVICE_TEMP) >> 4) & 0xFFF;
//    func_fpga_temp = (data * 503.975 / 4096.0) - 273.15;
    func_fpga_temp = (data * 503.975 / 4096.0) - 283.15;
}

// TI_ROIC
//u32 get_roic_data(u32 num) {
//    return ROIC_MAT[num].data;
//}

//$ 260224
//u32 AFE3256_Cfb (u32 data){
//	u32 n = data + 1;
//	u32 value = 0;
//
//	if(n >= 16) { value |= 0x40; n -= 16; }
//	if(n >=  8) { value |= 0x20; n -=  8; }
//	if(n >=  8) { value |= 0x10; n -=  8; }
//	if(n >=  4) { value |= 0x08; n -=  4; }
//	if(n >=  2) { value |= 0x04; n -=  2; }
//	if(n >=  1) { value |= 0x02; n -=  1; }
//	if(n >=  1) { value |= 0x01;          }
//	return value;
//}
//$ 260403 Reduce AFE3256 Cfb from 40 to 12 steps //$ 260423 12 -> 16
u32 AFE3256_Cfb (u32 data){
	const u32 cfb_table[16] = {
// Step : 0      1     2     3     4     5     6     7     8     9     10    11	   12    13    14    15
// QFS  : 0.3125 0.625 1.250 1.875 2.500 3.125 3.750 4.375 5.000 5.625 6.250 6.875 7.500 8.125 8.750 9.375 (pC)
		  0x01,  0x04, 0x08, 0x0C, 0x10, 0x14, 0x18, 0x1C, 0x40, 0x44, 0x48, 0x4C, 0x60, 0x64, 0x68, 0x6C
	};
	if(data > 15) data = 15;
	return cfb_table[data];
}
// TI_ROIC
void set_roic_data(u32 num, u32 data) {
    u32 i;
    u32 roic_addr = 0, roic_data = 0, mask = 0;
    u32 idx = 0;
    u32 grab = func_grab_en;

//    if(num == 18)         REG(ADDR_ROIC_SHAAZEN) = data;

    ROIC_MAT[num].data = data;
    roic_addr = ROIC_MAT[num].addr;
    idx = ROIC_MAT[num].idx;    // dskim
    for (i = 0; i < ROIC_MAT[num].size; i++) { mask <<= 1;  mask |= 0x01; }
    roic_data = (ROIC_MAT[num].data & mask) << ROIC_MAT[num].lsb;
    func_roic_data[idx] &= ~(mask << ROIC_MAT[num].lsb);
    func_roic_data[idx] |= roic_data;

    //$ 251014 AFE3256 should set in [0:7] as well.
    if(AFE3256_series){
    	func_roic_data[idx] &= ~mask;
    	func_roic_data[idx] |= (roic_data >> ROIC_MAT[num].lsb);
    }
    execute_cmd_grab(0);
    execute_cmd_wroic(roic_addr, func_roic_data[idx]);
    execute_cmd_grab(grab);
}

u8 get_roic_data(u32 num) {
    return ROIC_MAT[num].data;
}

//void system_config(void) {
////# 4343 a-si
//#if (defined(EXT4343R)&&defined(EXT4343R_3)) ||\
//    (defined(EXT4343R)&&defined(EXT4343RC_3)) ||\
//    (defined(EXT4343R)&&defined(EXT4343RCL_3))
////    roic_settimingprofile(125, 256, 1000, 2000, 15000, 2000);
//    profile.init.mclk = MCLK_125;
//    profile.init.cmdstr = CMDSTR_512;
//    profile.init.tirst = TIRST_2000;
//    profile.init.tshr_lpf1 = LPF1_4000;
//    profile.init.tshs_lpf2 = LPF2_12000;
//    profile.init.tgate = TGATE_10000;
//    profile.init.filter = FILTER_5;
//    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
////     roic_settimingprofile(200, 1024, 350, 1750, 1750, 1100);
//    profile.d2.mclk = MCLK_200;
//    profile.d2.cmdstr = CMDSTR_1024;
//    profile.d2.tirst = TIRST_350;
//    profile.d2.tshr_lpf1 = LPF1_1750;
//    profile.d2.tshs_lpf2 = LPF2_1750;
//    profile.d2.tgate = TGATE_1100;
//    profile.d2.filter = FILTER_4;
//    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//#elif (defined(EXT4343RI_2)||defined(EXT4343RCI_1)||defined(EXT4343RCI_2)||defined(EXT2430RI)) //### 10G
////    roic_settimingprofile(200, 256, 1000, 2000, 8000, 2000);
//    profile.init.mclk = MCLK_200;
//    profile.init.cmdstr = CMDSTR_256;
//    profile.init.tirst = TIRST_1000;
//    profile.init.tshr_lpf1 = LPF1_2000;
//    profile.init.tshs_lpf2 = LPF2_8000;
////    profile.init.tgate = TGATE_2000;
//    profile.init.tgate = TGATE_1500; //# 230925 oe time reduce for 3x3 binn, but dont know why
//    profile.init.filter = FILTER_5;
//    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
//
//    profile.d2.mclk = MCLK_200;
//    profile.d2.cmdstr = CMDSTR_1024;
//    profile.d2.tirst = TIRST_350;
//    profile.d2.tshr_lpf1 = LPF1_1750;
//    profile.d2.tshs_lpf2 = LPF2_1750;
//    profile.d2.tgate = TGATE_1100;
//    profile.d2.filter = FILTER_4;
//    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//#elif (defined(EXT4343R)||defined(EXT2430R))
////    roic_settimingprofile(125, 256, 1000, 2000, 15000, 2000);
//    profile.init.mclk = MCLK_125;
//    profile.init.cmdstr = CMDSTR_256;
//    profile.init.tirst = TIRST_1000;
//    profile.init.tshr_lpf1 = LPF1_2000;
//    profile.init.tshs_lpf2 = LPF2_15000;
//    profile.init.tgate = TGATE_2000;
//    profile.init.filter = FILTER_5;
//    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
////     roic_settimingprofile(200, 1024, 350, 1750, 1750, 1100);
//    profile.d2.mclk = MCLK_200;
//    profile.d2.cmdstr = CMDSTR_1024;
//    profile.d2.tirst = TIRST_350;
//    profile.d2.tshr_lpf1 = LPF1_1750;
//    profile.d2.tshs_lpf2 = LPF2_1750;
//    profile.d2.tgate = TGATE_1100;
//    profile.d2.filter = FILTER_4;
//    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//
//#elif (defined(EXT1616R)||defined(EXT2832R))
////    roic_settimingprofile(200, 256, 1000, 2000, 8000, 2000);
//    profile.init.mclk = MCLK_200;
//    profile.init.cmdstr = CMDSTR_256;
//    profile.init.tirst = TIRST_1000;
//    profile.init.tshr_lpf1 = LPF1_2000;
//    profile.init.tshs_lpf2 = LPF2_8000;
//    profile.init.tgate = TGATE_2000;
//    profile.init.filter = FILTER_5;
//    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
//
//    profile.d2.mclk = MCLK_200;
//    profile.d2.cmdstr = CMDSTR_1024;
//    profile.d2.tirst = TIRST_350;
//    profile.d2.tshr_lpf1 = LPF1_1750;
//    profile.d2.tshs_lpf2 = LPF2_1750;
//    profile.d2.tgate = TGATE_1100;
//    profile.d2.filter = FILTER_4;
//    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//#elif (defined(EXT810R)||defined(EXT2430RD))
////    roic_settimingprofile(200, 256, 1000, 2000, 8000, 2000);
//    profile.init.mclk = MCLK_200;
//    profile.init.cmdstr = CMDSTR_1024; // 512 is fail
//    profile.init.tirst = TIRST_1000;
//    profile.init.tshr_lpf1 = LPF1_2000;
//    profile.init.tshs_lpf2 = LPF2_8000;
//    profile.init.tgate = TGATE_2000;
//    profile.init.filter = FILTER_5;
//    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
//
//    profile.d2.mclk = MCLK_200;
//    profile.d2.cmdstr = CMDSTR_1024;
//    profile.d2.tirst = TIRST_350;
//    profile.d2.tshr_lpf1 = LPF1_1750;
//    profile.d2.tshs_lpf2 = LPF2_1750;
//    profile.d2.tgate = TGATE_1100;
//    profile.d2.filter = FILTER_4;
//    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//#else
//    #error "Error."
//#endif
//}

void system_config(void) {
//# 4343 a-si
// #if (defined(EXT4343R)&&defined(EXT4343R_3)) ||
//    (defined(EXT4343R)&&defined(EXT4343RC_3)) ||
//    (defined(EXT4343R)&&defined(EXT4343RCL_3))
     if( (msame(mEXT4343R_3   )) ||
         (msame(mEXT4343RC_3  )) ||
         (msame(mEXT4343RCL_3 )) )
     {
        profile.init.mclk = MCLK_125;
        profile.init.cmdstr = CMDSTR_512;
        profile.init.tirst = TIRST_2000;
        profile.init.tshr_lpf1 = LPF1_4000;
        profile.init.tshs_lpf2 = LPF2_12000;
        profile.init.tgate = TGATE_10000;
        profile.init.filter = FILTER_5;
        profile.init.m_clock = FPGA_TFT_MAIN_CLK;
        profile.d2.mclk = MCLK_200;
        profile.d2.cmdstr = CMDSTR_1024;
        profile.d2.tirst = TIRST_350;
        profile.d2.tshr_lpf1 = LPF1_1750;
        profile.d2.tshs_lpf2 = LPF2_1750;
        profile.d2.tgate = TGATE_1100;
        profile.d2.filter = FILTER_4;
        profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
     }
//#elif (defined(EXT4343RI_2)||defined(EXT4343RCI_1)||defined(EXT4343RCI_2)||defined(EXT2430RI)) //### 10G
    else if( /*(msame(mEXT4343RI_2  )) ||\*/ //$ 241213 jyp
             (msame(mEXT4343RCI_1 )) ||\
             (msame(mEXT4343RCI_2 )))
             //(msame(mEXT2430RI    )) ) $250423 jyp 2430 crosstalk test
     {
        profile.init.mclk = MCLK_200;
        profile.init.cmdstr = CMDSTR_256;
//        profile.init.tirst = TIRST_1000;
        profile.init.tirst = TIRST_2000; //# 240123 overExposure problem
        profile.init.tshr_lpf1 = LPF1_2000;
        profile.init.tshs_lpf2 = LPF2_8000;
        profile.init.tgate = TGATE_1500; //# 230925 oe time reduce for 3x3 binn, but dont know why
        profile.init.filter = FILTER_5;
        profile.init.m_clock = FPGA_TFT_MAIN_CLK;
        profile.d2.mclk = MCLK_200;
        profile.d2.cmdstr = CMDSTR_1024;
        profile.d2.tirst = TIRST_350;
        profile.d2.tshr_lpf1 = LPF1_1750;
        profile.d2.tshs_lpf2 = LPF2_1750;
        profile.d2.tgate = TGATE_1100;
        profile.d2.filter = FILTER_4;
        profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
     }
// #elif (defined(EXT4343R)||defined(EXT2430R))
    else if( (msame(mEXT4343R_1   )) ||\
             (msame(mEXT4343R_2   )) ||\
			 (msame(mEXT4343R_4   )) ||\
             (msame(mEXT4343RC_1  )) ||\
             (msame(mEXT4343RC_2  )) ||\
             (msame(mEXT4343RCL_1 )) ||\
             (msame(mEXT4343RCL_2 )) ||\
             (msame(mEXT2430R     )) )
    {
        profile.init.mclk = MCLK_125;
        profile.init.cmdstr = CMDSTR_256;
//        profile.init.tirst = TIRST_1000;
//        profile.init.tirst = TIRST_2000; 		//# 240123 overExposure problem //$ 241024 cross talk
        profile.init.tirst = TIRST_3000; 		//$ 241024 cross talk
//        profile.init.tshr_lpf1 = LPF1_2000; 	//$ 241024 cross talk
        profile.init.tshr_lpf1 = LPF1_3000; 	//$ 241024 cross talk
        profile.init.tshs_lpf2 = LPF2_14000; 	//$ 241024 cross talk
//        profile.init.tshs_lpf2 = LPF2_15000;  //$ 241024 cross talk
        profile.init.tgate = TGATE_2000;
        profile.init.filter = FILTER_5;
        profile.init.m_clock = FPGA_TFT_MAIN_CLK;
        profile.d2.mclk = MCLK_200;
        profile.d2.cmdstr = CMDSTR_1024;
        profile.d2.tirst = TIRST_350;
        profile.d2.tshr_lpf1 = LPF1_1750;
        profile.d2.tshs_lpf2 = LPF2_1750;
        profile.d2.tgate = TGATE_1100;
        profile.d2.filter = FILTER_4;
        profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }
// #elif (defined(EXT1616R)||defined(EXT2832R))
    else if( (msame(mEXT1616R  )) ||\
             (msame(mEXT1616RL )) ||\
             (msame(mEXT2832R  )) ||\
             (msame(mEXT2832R_2)) )
    {
        profile.init.mclk = MCLK_200;
        profile.init.cmdstr = CMDSTR_256;
//        profile.init.tirst = TIRST_1000;
        profile.init.tirst = TIRST_2000;
        profile.init.tshr_lpf1 = LPF1_2000;
        profile.init.tshs_lpf2 = LPF2_8000;
        profile.init.tgate = TGATE_2000;
        profile.init.filter = FILTER_5;
        profile.init.m_clock = FPGA_TFT_MAIN_CLK;
        profile.d2.mclk = MCLK_200;
        profile.d2.cmdstr = CMDSTR_1024;
        profile.d2.tirst = TIRST_350;
        profile.d2.tshr_lpf1 = LPF1_1750;
        profile.d2.tshs_lpf2 = LPF2_1750;
        profile.d2.tgate = TGATE_1100;
        profile.d2.filter = FILTER_4;
        profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }
// #elif (defined(EXT810R)||defined(EXT2430RD))
    else if( (msame(mEXT810R      )) ||\
             (msame(mEXT2430RD    )) )
    {
    profile.init.mclk = MCLK_200;
    profile.init.cmdstr = CMDSTR_1024; // 512 is fail
//    profile.init.tirst = TIRST_1000;
    profile.init.tirst = TIRST_2000;
    profile.init.tshr_lpf1 = LPF1_2000;
    profile.init.tshs_lpf2 = LPF2_8000;
    profile.init.tgate = TGATE_2000;
    profile.init.filter = FILTER_5;
    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
    profile.d2.mclk = MCLK_200;
    profile.d2.cmdstr = CMDSTR_1024;
    profile.d2.tirst = TIRST_350;
    profile.d2.tshr_lpf1 = LPF1_1750;
    profile.d2.tshs_lpf2 = LPF2_1750;
    profile.d2.tgate = TGATE_1100;
    profile.d2.filter = FILTER_4;
    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }

    else if( (msame(mEXT4343RI_2)) ||\
    		 (msame(mEXT4343RI_4)) ||\
    		 (msame(mEXT2430RI) )){
   profile.init.mclk = MCLK_160;
   profile.init.cmdstr = CMDSTR_256;
   profile.init.tirst = TIRST_4000;
//  profile.init.tshr_lpf1 = LPF1_3000;
   profile.init.tshr_lpf1 = LPF1_2000; //$ 241213 jyp 30 -> 20
   profile.init.tshs_lpf2 = LPF2_8000;
 //  profile.init.tgate = TGATE_2000;
   profile.init.tgate = TGATE_1500; //$ 241213 jyp 20 -> 15
   profile.init.filter = FILTER_5;
   profile.init.m_clock = FPGA_TFT_MAIN_CLK;
   profile.d2.mclk = MCLK_200;
   profile.d2.cmdstr = CMDSTR_1024;
   profile.d2.tirst = TIRST_350;
   profile.d2.tshr_lpf1 = LPF1_1750;
   profile.d2.tshs_lpf2 = LPF2_1750;
   profile.d2.tgate = TGATE_1100;
   profile.d2.filter = FILTER_4;
   profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }
    else if((msame(mEXT4343RD))) //$ 251121 //$ 260408 add EXT3643R
    {
    profile.init.mclk = MCLK_300;
    profile.init.cmdstr = CMDSTR_256;
    profile.init.tirst = TIRST_1000;
    profile.init.tshr_lpf1 = LPF1_1200;
    profile.init.tshs_lpf2 = LPF2_2000;
    profile.init.tgate = TGATE_1000;
    profile.init.filter = FILTER_5;
    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
    profile.d2.mclk = MCLK_200;
    profile.d2.cmdstr = CMDSTR_1024;
    profile.d2.tirst = TIRST_350;
    profile.d2.tshr_lpf1 = LPF1_1750;
    profile.d2.tshs_lpf2 = LPF2_1750;
    profile.d2.tgate = TGATE_1100;
    profile.d2.filter = FILTER_4;
    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }
    else if((msame(mEXT3643R))) //$ 251121 //$ 260408 add EXT3643R
    {
//# 4343rd
//  profile.init.mclk = MCLK_300;
//  profile.init.cmdstr = CMDSTR_256;
//  profile.init.tirst = TIRST_1000;
//  profile.init.tshr_lpf1 = LPF1_1200;
//  profile.init.tshs_lpf2 = LPF2_2000;
//  profile.init.tgate = TGATE_1000;
//  profile.init.filter = FILTER_5;
//  profile.init.m_clock = FPGA_TFT_MAIN_CLK;
//  profile.d2.mclk = MCLK_200;
//  profile.d2.cmdstr = CMDSTR_1024;
//  profile.d2.tirst = TIRST_350;
//  profile.d2.tshr_lpf1 = LPF1_1750;
//  profile.d2.tshs_lpf2 = LPF2_1750;
//  profile.d2.tgate = TGATE_1100;
//  profile.d2.filter = FILTER_4;
//  profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//# 4343
    profile.init.mclk = MCLK_180;
    profile.init.cmdstr = CMDSTR_256;
    profile.init.tirst = TIRST_3000; 		//$ 241024 cross talk
    profile.init.tshr_lpf1 = LPF1_3000; 	//$ 241024 cross talk
    profile.init.tshs_lpf2 = LPF2_10000; 	//$ 241024 cross talk
    profile.init.tgate = TGATE_7000;
    profile.init.filter = FILTER_5;
    profile.init.m_clock = FPGA_TFT_MAIN_CLK;
    profile.d2.mclk = MCLK_200;
    profile.d2.cmdstr = CMDSTR_1024;
    profile.d2.tirst = TIRST_350;
    profile.d2.tshr_lpf1 = LPF1_1750;
    profile.d2.tshs_lpf2 = LPF2_1750;
    profile.d2.tgate = TGATE_1100;
    profile.d2.filter = FILTER_4;
    profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
//# a-si
//      profile.init.mclk = MCLK_125;
//      profile.init.cmdstr = CMDSTR_256; //# CMDSTR_512;
//      profile.init.tirst = TIRST_2000;
//      profile.init.tshr_lpf1 = LPF1_4000;
//      profile.init.tshs_lpf2 = LPF2_12000;
//      profile.init.tgate = TGATE_10000;
//      profile.init.filter = FILTER_5;
//      profile.init.m_clock = FPGA_TFT_MAIN_CLK;
//      profile.d2.mclk = MCLK_200;
//      profile.d2.cmdstr = CMDSTR_1024;
//      profile.d2.tirst = TIRST_350;
//      profile.d2.tshr_lpf1 = LPF1_1750;
//      profile.d2.tshs_lpf2 = LPF2_1750;
//      profile.d2.tgate = TGATE_1100;
//      profile.d2.filter = FILTER_4;
//      profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }
    else
    {
        profile.init.mclk = MCLK_200;
        profile.init.cmdstr = CMDSTR_256;
//        profile.init.tirst = TIRST_1000;
        profile.init.tirst = TIRST_2000;
        profile.init.tshr_lpf1 = LPF1_2000;
        profile.init.tshs_lpf2 = LPF2_8000;
        profile.init.tgate = TGATE_2000;
        profile.init.filter = FILTER_5;
        profile.init.m_clock = FPGA_TFT_MAIN_CLK;
        profile.d2.mclk = MCLK_200;
        profile.d2.cmdstr = CMDSTR_1024;
        profile.d2.tirst = TIRST_350;
        profile.d2.tshr_lpf1 = LPF1_1750;
        profile.d2.tshs_lpf2 = LPF2_1750;
        profile.d2.tgate = TGATE_1100;
        profile.d2.filter = FILTER_4;
        profile.d2.m_clock = FPGA_TFT_MAIN_CLK;
    }
}

void roic_set_wake() { //# 220318mbh
    execute_cmd_wroic(0x13,    0); // roic active
}
void roic_set_sleep() { //# 220318mbh
    execute_cmd_wroic(0x13,    0xFFBF); // roic Power down
}

void fpga_set_wake() { //# 220318mbh
    REG(ADDR_TOPRST_CTRL) = 0; // fpga sm active
}
void fpga_set_sleep() { //# 220318mbh
//    REG(ADDR_TOPRST_CTRL) = 4; // fpga only ddr sync gen stop #220510
    REG(ADDR_TOPRST_CTRL) = 8; // isyncgen_rstn => sbd_clk_lock(3), mistake #220603
}

void set_sleepmode(u32 data){
    func_sleepmode = data;
}

u32 get_run_time(){
    u32 runtime_msb, runtime_lsb;
    u32 runtime;
    u32 runtime_s = 0;
    float tick = 0.16777216;

    runtime_msb = AREG(0x43E0C020);
    runtime_lsb = AREG(0x43E0C024);
    runtime = ((runtime_msb << 8) & 0xFFFFFF00) | ((runtime_lsb >> 24) & 0x000000FF);
    runtime_s = (u32)(runtime * tick);

    return runtime_s;
}
//#@ 2000 V
#define VOLT_LIMIT 2000 //# 230203 volt limit up
#define VALUE_LIMIT 2483 //# = 2483*4096/3.3/1000
//#@ 3000 V
//#define VOLT_LIMIT 3000 //# 230203 volt limit up
//#define VALUE_LIMIT 3724 //# = 2483*4096/3.3/1000
void set_pwdac(u32 en, u32 volt, u32 time){

    u32 pwdn_mode = 0;
    float ticktime = 0;
    u32 ticklevel = 0;
    u32 prev_level=REG(ADDR_PWDAC_CURRLEVEL);
    u32 level = 0;

    if(VOLT_LIMIT < volt){
        func_printf("high voltage limit is %d volt, %d\r\n", VOLT_LIMIT, volt);
        return;
    }
    level = volt  * 4096 / 3.3 / 1000;

    if(VALUE_LIMIT < level){
        func_printf("Calculated level is over VALUE_LIMIT, %d\r\n",VALUE_LIMIT, level);
        return;
    }
    func_printf("(%d)volt is (%d)Level\r\n", volt, level);

    ticktime = (float)time * 20000 / (abs(prev_level-level)+1) ; //Time(mSec), Level is 12 bit, clk is 25MHz
    if      (32 < ticktime ) ticklevel = 1-1;
    else if (16 < ticktime ) ticklevel = 2-1;
    else if ( 8 < ticktime ) ticklevel = 4-1;
    else if ( 4 < ticktime ) ticklevel = 8-1;
    else if ( 2 < ticktime ) ticklevel =16-1;
    else                     ticklevel =32-1;

    switch(en)
    {
        case 0  : pwdn_mode = 1; break; // 1kohm to GND
        case 1  : pwdn_mode = 0; break; // normal operation
        case 2  : pwdn_mode = 2; break; // 100kohm to GND
        case 3  : pwdn_mode = 3; break; // three-state
        default : pwdn_mode = 1;
    }

    func_printf("ticktime=%d \r\n", (u32)ticktime);
    REG(ADDR_PWDAC_CMD     ) = (pwdn_mode & 0b11) << 14 | (level & 0xFFF) <<2;
    REG(ADDR_PWDAC_TICKTIME) = (u32)ticktime;
    func_printf("ADDR_PWDAC_TICKTIME=%d \r\n", REG(ADDR_PWDAC_TICKTIME));
    REG(ADDR_PWDAC_TICKINC ) = ticklevel & 0xFFF; 
    func_printf("ADDR_PWDAC_TICKINC=%d \r\n", REG(ADDR_PWDAC_TICKINC));

    //# toggle trigger
    REG(ADDR_PWDAC_TRIG    ) = 1; 
    usdelay(1); 
    REG(ADDR_PWDAC_TRIG    ) = 0; 
}

//#define FLASH_ALLOC_BASEADDR        0x0C00000
//#define FLASH_ALLOC_BIT_SIZE        0x0000000
//#define FLASH_ALLOC_BIT_CHECKSUM    0x0000004
//#define FLASH_ALLOC_BIT2ND_SIZE     0x0000008
//#define FLASH_ALLOC_BIT2ND_CHECKSUM 0x000000c
//#define FLASH_ALLOC_XML_SIZE        0x0000018
//#define FLASH_ALLOC_XML_CHECKSUM    0x000001C
//#define FLASH_ALLOC_APP_SIZE        0x0000028
//#define FLASH_ALLOC_APP_CHECKSUM    0x000002C

u32 flash_allo_check(u32 addr){
    u32 data = flash_read_dword(addr);
    if(
            //
            (data == 0) ||
            (data == 0xFFFFFFFF)
       )
    {
        func_printf("Allocation Error Flash addr %08x = %08x \r\n", addr, data);
        return 0;
    }

    return 1;
}

#define DEBUG_CHECKSUM_VALUE 0
u32 flash_allo_check_1st(void){
    if (
            flash_allo_check(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_BIT_SIZE) &&
            flash_allo_check(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_BIT_CHECKSUM ) &&
            flash_allo_check(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_BIT2ND_SIZE) &&
            flash_allo_check(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_BIT2ND_CHECKSUM ) &&
            flash_allo_check(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_APP_SIZE) &&
            flash_allo_check(FLASH_ALLOC_BASEADDR + FLASH_ALLOC_APP_CHECKSUM )
        )
        return 1;
    else
        return 0;
}
u32 flash_allo_check_2nd(void){
    if (
            flash_allo_check(FLASH_AL2ND_BASEADDR + FLASH_ALLOC_BIT_SIZE) &&
            flash_allo_check(FLASH_AL2ND_BASEADDR + FLASH_ALLOC_BIT_CHECKSUM ) &&
            flash_allo_check(FLASH_AL2ND_BASEADDR + FLASH_ALLOC_BIT2ND_SIZE) &&
            flash_allo_check(FLASH_AL2ND_BASEADDR + FLASH_ALLOC_BIT2ND_CHECKSUM ) &&
            flash_allo_check(FLASH_AL2ND_BASEADDR + FLASH_ALLOC_APP_SIZE) &&
            flash_allo_check(FLASH_AL2ND_BASEADDR + FLASH_ALLOC_APP_CHECKSUM )
        )
        return 1;
    else
        return 0;
}

u32 flash_fpga_check_2nd(void){ //# 220920
    u32 calcsum=flash_calc_sum(FLASH_BIT2ND_BASEADDR,FLASH_BIT_LEN);
    u32 readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_CHECKSUM);
    if(DEBUG_CHECKSUM_VALUE)func_printf("\r\nFPGA2nd calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
    if (calcsum == readchecksum)
        return calcsum;
    else
        return 0;
}

u32 flash_fpga_check_3rd(void){
    u32 calcsum=flash_calc_sum(FLASH_BIT3RD_BASEADDR,FLASH_BIT_LEN);
    u32 readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT3RD_CHECKSUM);
    if(DEBUG_CHECKSUM_VALUE)func_printf("FPGA3rd calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
    if (calcsum == readchecksum)
        return calcsum;
    else
        return 0;
}


u32 flash_fw_check_1st(void){ //# 220920
    u32 flash_app_len = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_SIZE);
    if(DEBUG_CHECKSUM_VALUE)func_printf("flash_fw_check_1st\r\n");
    if (flash_app_len == 0xFFFFFFFF)
    {
        func_printf("flash app length is 0xFFFFFFFF\r\n");
        return 0;
    }
    u32 calcsum=flash_calc_sum(FLASH_APP_BASEADDR,flash_app_len);
    if(DEBUG_CHECKSUM_VALUE)func_printf("flash_calc_sum\r\n");
    u32 readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_CHECKSUM);
    if(DEBUG_CHECKSUM_VALUE)func_printf("\r\nFW1st calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
    if (calcsum == readchecksum)
        return calcsum;
    else
        return 0;
}

u32 flash_fw_check_2nd(void){
    u32 flash_app_len = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_SIZE);
    if(DEBUG_CHECKSUM_VALUE)func_printf("flash_fw_check_2nd\r\n");
    if (flash_app_len == 0xFFFFFFFF)
    {
        func_printf("flash app length is 0xFFFFFFFF\r\n");
        return 0;
    }
    u32 calcsum=flash_calc_sum(FLASH_APP2ND_BASEADDR,flash_app_len);
    u32 readchecksum = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_CHECKSUM);
    if(DEBUG_CHECKSUM_VALUE)func_printf("FW2nd calcsum=0x%08x , readchecksum=0x%08x \r\n", calcsum, readchecksum);
    if (calcsum == readchecksum)
        return calcsum;
    else
        return 0;
}

#define DEBUG_CHECKSUM 0
//##### fw flash read access
//u32 flash_calc_sum(u32 baseaddr, u32 lenth) {
//    u32 flash_addr      = baseaddr;
//    u32 flash_length = lenth / 4;
//    u32 data, data0, data1, data2, data3 = 0;
//    u32 datasum = 0;
//        for(int i = 0; i < flash_length; i++)
//        {
//            data = flash_read_dword(flash_addr);
//            data0 = (data >> 0) & 0xFF;
//            data1 = (data >> 8) & 0xFF;
//            data2 = (data >> 16) & 0xFF;
//            data3 = (data >> 24) & 0xFF;
//            datasum = datasum + data0 + data1 + data2 + data3;
//                //#####
//                if (DEBUG_CHECKSUM)
//                    if (i < 2 || flash_length-3 < i )
//                        func_printf("checksum flash_addr 0x%08x = 0x%08x 0x%08x \r\n", flash_addr, data, datasum);
//
//            flash_addr += 4;
//        }
//    return datasum;
//}
//##### FPGA flash read access
u32 flash_calc_sum(u32 baseaddr, u32 lenth) {

    u32 ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_addr     = baseaddr;
    u32 repeat        = ceil((float)lenth / 4);
    u32 remainB      = repeat*4-lenth;

    if(DEBUG_CHECKSUM)func_printf("[DEBUG_CHECKSUM] length = %d, 0x%08x \r\n",lenth, lenth);
    if(DEBUG_CHECKSUM)func_printf("[DEBUG_CHECKSUM] repeat = %d, 0x%08x \r\n",repeat ,repeat);

    REG(ADDR_FLA_ADDR) = flash_addr;     // addr setup flash_addr
    REG(ADDR_FLA_CTRL) = 1;             // read start(0)
    msdelay(10);
    //# 2605131422 Progress format: "10.20.30.40.50.60.70.80.90.100" per call.
    //  Dot-joined numbers (no '%', no spaces). Caller (execute_cmd_flash_check)
    //  prefixes each call with a "[2nd] " / "[3rd] " label on its own line.
    int last_pct = 0;
    for(int i = 0; i < repeat; i++) {
        DREG(ddr_addr) = REG(ADDR_FLA_DATA);
        ddr_addr += 4;
        //# manual address increment change 220512mbh
        REG(ADDR_FLA_CTRL) = 0b11; // manual address increment(2)
        REG(ADDR_FLA_CTRL) = 0b01;
        udelay(10);
        int pct = (int)(((i + 1) * 100) / repeat);
        if (pct >= last_pct + 10) {
            if (last_pct > 0) func_printf(".");        //# separator before non-first tick
            func_printf("%d", pct);                    //# 2605131422 progress tick (no %, dots between)
            last_pct = pct;
        }
    }
//    func_printf("flash => ddr done \r\n");
    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss
//    func_printf("flash 2 ddr done! \r\n");

    ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_length = repeat;
    u32 data, data0, data1, data2, data3 = 0;
    u32 datasum = 0;
//    func_printf("flash_length = %d\r\n",flash_length);
    if(!flash_length) {
        func_printf("flash_length is 0 !!! \r\n");
        return 0;
    }

    	for(int i = 0; i < flash_length; i++)
//        for(int i = 0; i < flash_length-1; i++) //# 231026
//    for(int i = 0; i < flash_length-2; i++) //# 231207
        {
            data = DREG(ddr_addr);
            data0 = (data >> 0) & 0xFF;
            data1 = (data >> 8) & 0xFF;
            data2 = (data >> 16) & 0xFF;
            data3 = (data >> 24) & 0xFF;
            if(i == flash_length-1)
            {
            	     if (remainB == 0) datasum = datasum + data0 + data1 + data2 + data3;
            	else if (remainB == 1) datasum = datasum + data1 + data2 + data3;
            	else if (remainB == 2) datasum = datasum + data2 + data3 ;
            	else                    datasum = datasum + data3 ;
            	if (DEBUG_CHECKSUM)func_printf("[DEBUG_CHECKSUM]reminder=%d \r\n", remainB);
                if (DEBUG_CHECKSUM)func_printf("[DEBUG_CHECKSUM]0x%02x 0x%02x 0x%02x 0x%02x\r\n", data3, data2, data1, data0);
            }
            else
            {
            	datasum = datasum + data0 + data1 + data2 + data3;
            }
                //#####
                if (DEBUG_CHECKSUM)
                    if (i < 4 || flash_length-16 < i || (294/4<=i && i<314/4))
                        func_printf("[DEBUG_CHECKSUM]addr %d 0x%08x checksum flash_addr 0x%08x = 0x%08x 0x%08x \r\n", i, i*4, ddr_addr, data, datasum);
//            flash_addr += 4;
            ddr_addr += 4;
        }

    return datasum;
}

u32 flash_bulk_read(u32 baseaddr, u32 lenth) {

    u32 ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_addr     = baseaddr;
    u32 repeat        = ceil((float)lenth / 4);
//    u32 data00, data01, data02, data03, data04, data05, data06, data07 = 0;
    u32 data000[8] = {0,};

    REG(ADDR_FLA_ADDR) = flash_addr;     // addr setup flash_addr
    REG(ADDR_FLA_CTRL) = 1;             // read start(0)
    msdelay(10);
    for(int i = 0; i < repeat; i++) {

        DREG(ddr_addr) = REG(ADDR_FLA_DATA);
        ddr_addr += 4;
        //# manual address increment change 220512mbh
        REG(ADDR_FLA_CTRL) = 0b11; // manual address increment(2)
        REG(ADDR_FLA_CTRL) = 0b01;
        udelay(10);

    }
    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss

    ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_length = repeat;
    u32 data, data0, data1, data2, data3 = 0;
    u32 datasum = 0;
    if(!flash_length) {
        func_printf("flash_length is 0 !!! \r\n");
        return 0;
    }

    func_printf("flash_length = %d \r\n",flash_length);
        for(int i = 0; i < flash_length; i++)
        {
            data = DREG(ddr_addr);
            data0 = (data >> 0) & 0xFF;
            data1 = (data >> 8) & 0xFF;
            data2 = (data >> 16) & 0xFF;
            data3 = (data >> 24) & 0xFF;
            datasum = datasum + data0 + data1 + data2 + data3;
            ddr_addr += 4;

	    	data000[i%8]=data;
	    	if(i%8==7)func_printf("[DEBUG_CHECKSUM] 0x%08x = 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x\r\n",flash_addr+(i-7)*4,  data000[0], data000[1], data000[2], data000[3], data000[4], data000[5], data000[6], data000[7]);
	    	if(uart_receive())
	    		return 0;
        }
        func_printf("sum = 0x%08x",datasum);
    return 0;
}

u32 flash_bulk_checksum(u32 baseaddr, u32 lenth) {

    u32 ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_addr     = baseaddr;
    u32 repeat        = ceil((float)lenth / 4);
    u32 data00, data01, data02, data03, data04, data05, data06, data07 = 0;
    u32 data000[8] = {0,};

    func_printf("ADDR = 0x%08x LENGTH = 0x%08x\r\n",baseaddr ,lenth);

    REG(ADDR_FLA_ADDR) = flash_addr;     // addr setup flash_addr
    REG(ADDR_FLA_CTRL) = 1;             // read start(0)
    usdelay(10000); //# 250909 msdelay(10);
    for(int i = 0; i < repeat; i++) {

        DREG(ddr_addr) = REG(ADDR_FLA_DATA);
        ddr_addr += 4;
        //# manual address increment change 220512mbh
        REG(ADDR_FLA_CTRL) = 0b11; // manual address increment(2)
        REG(ADDR_FLA_CTRL) = 0b01;
        udelay(10);

    }
    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss

    ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_length = repeat;
    u32 data, data0, data1, data2, data3 = 0;
    u32 datasum = 0;
    u32 datassumector = 0;
    if(!flash_length) {
        func_printf("flash_length is 0 !!! \r\n");
        return 0;
    }

        for(int i = 0; i < flash_length-1; i++)
        {
            data = DREG(ddr_addr);
            data0 = (data >> 0) & 0xFF;
            data1 = (data >> 8) & 0xFF;
            data2 = (data >> 16) & 0xFF;
            data3 = (data >> 24) & 0xFF;
            datasum = datasum + data0 + data1 + data2 + data3;
            datassumector = datassumector + data0 + data1 + data2 + data3;
            ddr_addr += 4;
            if(i%512==512-1){
            	func_printf("0x%08x = 0x%08x\t", flash_addr+i*4+3, datassumector);
            	datassumector=0;
            }

            if(i%2048==2048-1)
            	func_printf("\r\n");

//	    	data000[i%8]=data;
//	    	if(i%8==7)func_printf("0x%08x = 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x 0x%08x\r\n", i-7, data000[0], data000[1], data000[2], data000[3], data000[4], data000[5], data000[6], data000[7]);

            if(uart_receive()) //# stop
	    		return 0;
        }
        func_printf("sum = 0x%08x",datasum);
    return 0;
}

//execute_cmd_brns

volatile u32 flash_buff[FLASH_BUFFER_SIZE];
    // FLASH_BUFFER_SIZE = 16384

void wflash(u32 addr, u32 data) {
    u32 i;
    u32 base_addr = addr & 0xFFFF0000;
    for(i = 0; i < 16384; i++)    flash_buff[i] = flash_read_dword(base_addr + (i*4));
    flash_buff[(addr & 0xFFFF)/4] = data;
    flash_write_block(base_addr, (u32*)flash_buff, 65536);
}

//void write_allo1st_checksum(void){
//    u32 calcsum=flash_calc_sum(FLASH_ALLOC_BASEADDR,FLASH_ALLOC_LEN);
//    wflash(FLASH_AL1ST_CHECKSUM, calcsum);
//}

void cp_allo1st_to_allo2nd(void){
    //# data copy
    flash_cp(FLASH_ALLOC_BASEADDR, FLASH_AL2ND_BASEADDR, FLASH_ALLOC_LEN);
    //# checksum write
    u32 calcsum=flash_calc_sum(FLASH_AL2ND_BASEADDR,FLASH_ALLOC_LEN);
    wflash(FLASH_AL2ND_CHECKSUM, calcsum);
}

void cp_allo2nd_to_allo1st(void){
    //# data copy
    flash_cp(FLASH_AL2ND_BASEADDR, FLASH_ALLOC_BASEADDR, FLASH_ALLOC_LEN);
    //# checksum write
    u32 calcsum=flash_calc_sum(FLASH_ALLOC_BASEADDR,FLASH_ALLOC_LEN);
    wflash(FLASH_AL1ST_CHECKSUM, calcsum);
}

void cp_fpga2nd_to_fpga3rd(void){
    //# length copy
    u32 length = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_SIZE);
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT3RD_SIZE, length);
    //# data copy
    flash_cp(FLASH_BIT2ND_BASEADDR, FLASH_BIT3RD_BASEADDR, length );
    func_printf("calcsum = ");
    u32 calcsum=flash_calc_sum(FLASH_BIT3RD_BASEADDR,length);
    func_printf("0x%08x\r\n", calcsum);
    func_printf("2nd checksum = 0x%08x\r\n", flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_CHECKSUM));
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT3RD_CHECKSUM, calcsum);
}

void cp_fpga3rd_to_fpga2nd(void){
    //# length copy
    u32 length = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT3RD_SIZE);
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_SIZE, length);
    //# data copy
    flash_cp(FLASH_BIT3RD_BASEADDR, FLASH_BIT2ND_BASEADDR, length );
    func_printf("calcsum = ");
    u32 calcsum=flash_calc_sum(FLASH_BIT2ND_BASEADDR,length);
    func_printf("0x%08x\r\n", calcsum);
    func_printf("3nd checksum = 0x%08x\r\n", flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT3RD_CHECKSUM));
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_BIT2ND_CHECKSUM, calcsum);
}

void cp_fw1st_to_fw2nd(void){
    //# length copy
    u32 length = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_SIZE);
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_SIZE, length);
    //# data copy
    flash_cp(FLASH_APP_BASEADDR, FLASH_APP2ND_BASEADDR, length );
    //# checksum write
    func_printf("calcsum = ");
    u32 calcsum=flash_calc_sum(FLASH_APP2ND_BASEADDR,length);
    func_printf("0x%08x\r\n", calcsum);
    func_printf("1st checksum = 0x%08x\r\n", flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_CHECKSUM));
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_CHECKSUM, calcsum);
}

void cp_fw2nd_to_fw1st(void){
    //# length copy
    u32 length = flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_SIZE);
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_SIZE, length);
    //# data copy
    flash_cp(FLASH_APP2ND_BASEADDR, FLASH_APP_BASEADDR, length );
    //# checksum write
    func_printf("calcsum = ");
    u32 calcsum=flash_calc_sum(FLASH_APP_BASEADDR,length);
    func_printf("0x%08x\r\n", calcsum);
    func_printf("2nd checksum = 0x%08x\r\n", flash_read_dword(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP2ND_CHECKSUM));
    wflash(FLASH_ALLOC_BASEADDR+FLASH_ALLOC_APP_CHECKSUM, calcsum);
}

u32 flash_compare(u32 aaddr, u32 baddr, u32 lenth) {
    u32 flash_aaddr  = aaddr;
    u32 flash_baddr  = baddr;
    u32 adata, bdata;
    u32 flash_length = lenth / 4;
    u8 diffcnt = 0;
        for(int i = 0; i < flash_length; i++)
        {
            adata = flash_read_dword(flash_aaddr);
            bdata = flash_read_dword(flash_baddr);

            if (adata != bdata)
            {
                func_printf("compare difference : \r\n a(0x%08x,0x%08x) \r\n b(0x%08x,0x%08x) \r\n", flash_aaddr, adata, flash_baddr, bdata);
                diffcnt++;
            }
            if (diffcnt > 8)
                return 0;

            flash_aaddr += 4;
            flash_baddr += 4;
        }
    func_printf("compare done!!!");
    return 1;
}

#define DEBUG_CPADDR 0
//u32 flash_cp(u32 sourceaddr, u32 targetaddr, u32 cplength) {
//    u32 saddr = sourceaddr;
//    u32 taddr = targetaddr;
//    u32 blocklength = (u32)ceil((float)cplength/ 4 / FLASH_BUFFER_SIZE);
//    u32 data  = 0;
//
//    func_printf("blocklength = %d \r\n", blocklength);
//    for(int i = 0; i < blocklength; i++)
//    {
//        if(DEBUG_CPADDR) func_printf("saddr = 0x%08x \t", saddr);
//        for(int j=0; j< FLASH_BUFFER_SIZE; j++){
////            data = flash_read_dword(saddr);
//            flash_buff[j] = flash_read_dword(saddr);
//            saddr=saddr+4;
//        }
//        if(DEBUG_CPADDR)  func_printf("taddr = 0x%08x \r\n", taddr);
//        flash_write_block(taddr, (u32*)flash_buff, FLASH_BUFFER_SIZE*4);
//        taddr = taddr + (FLASH_BUFFER_SIZE*4);
//        func_printf(".");
//    }
//
//    //##### DEBUG compare data
//    if(DEBUG_CPADDR) flash_compare(sourceaddr,targetaddr,cplength);
//}
void flash_cp(u32 sourceaddr, u32 targetaddr, u32 cplength) {

    u32 ddr_addr     = ADDR_FLASH_READ_TEMP;
    u32 flash_addr     = sourceaddr;
    u32 repeat        = ceil((float)cplength / 4);

    REG(ADDR_FLA_ADDR) = flash_addr;     // addr setup flash_addr
    REG(ADDR_FLA_CTRL) = 1;             // read start(0)
    msdelay(10);
    for(int i = 0; i < repeat; i++) {
        DREG(ddr_addr) = REG(ADDR_FLA_DATA);
        ddr_addr += 4;
        //# manual address increment change 220512mbh
        REG(ADDR_FLA_CTRL) = 0b11; // manual address increment(2)
        REG(ADDR_FLA_CTRL) = 0b01;
        udelay(10);
    }

    REG(ADDR_FLA_CTRL) = 0; // spi direct ctrl dismiss



    u32 saddr = ADDR_FLASH_READ_TEMP;
    u32 taddr = targetaddr;
    u32 blocklength = (u32)ceil((float)cplength/ 4 / FLASH_BUFFER_SIZE);
//    u32 data  = 0;

    func_printf("blocklength = %d \r\n", blocklength);
    for(int i = 0; i < blocklength; i++)
    {
        if(DEBUG_CPADDR) func_printf("saddr = 0x%08x \t", saddr);
        for(int j=0; j< FLASH_BUFFER_SIZE; j++){
//            data = flash_read_dword(saddr);
            flash_buff[j] = DREG(saddr);
            saddr=saddr+4;
        }
        if(DEBUG_CPADDR)  func_printf("taddr = 0x%08x \r\n", taddr);
        flash_write_block(taddr, (u32*)flash_buff, FLASH_BUFFER_SIZE*4);
        taddr = taddr + (FLASH_BUFFER_SIZE*4);
        func_printf(".");
    }

    //##### DEBUG compare data
    if(DEBUG_CPADDR) flash_compare(sourceaddr,targetaddr,cplength);
}

void flash_fpdiff(void){
    flash_compare(FLASH_BIT2ND_BASEADDR,FLASH_BIT3RD_BASEADDR,FLASH_BIT_LEN);
}

void flash_fwdiff(void){
    flash_compare(FLASH_APP_BASEADDR,FLASH_APP2ND_BASEADDR,FLASH_APP_LEN);
}

void fw_stop(void){
    func_printf("fw stop!\r\n");
    while(1)
        if (uart_receive()){
            func_printf("fw run!\r\n");
            break;
        }

}

const str_model_func_able MODEL_FUNC_ABLE[MAX_MODEL_NUM] = {
   /* MODEL,        BINN 4,3,2,1, Gain, DNR */
    {"EXT1616R\0"   ,    0b0011,    4,   1},
    {"EXT1616RL\0"  ,    0b0011,    4,   1},
    {"EXT4343R\0"   ,    0b1111,    4,   1},
    {"EXT4343RC\0"  ,    0b1111,    4,   1},
    {"EXT4343RCL\0" ,    0b1111,    4,   1},
    {"EXT4343RI\0"  ,    0b1111,    1,   0},
    {"EXT4343RCI\0" ,    0b1111,    1,   0},
    {"EXT2430R\0"   ,    0b1111,    4,   1},
    {"EXT2430RI\0"  ,    0b1111,    1,   0},
    {"EXT2832R\0"   ,    0b0011,    4,   1},
    {"EXT810R\0"    ,    0b0011,    4,   1},
    {"EXT2430RD\0"  ,    0b0011,    4,   1},
	{"EXT1024R\0"   ,    0b0011,    1,   0}, //$ 241127 add EXT1024R
	{"EXT1024RL\0"  ,    0b0011,    1,   0},
	{"EXT4343RD\0"  ,    0b0011,    1,   0},
};

//void set_able_func(void){ //# 230926 //# 250317 load_func_able
////    func_printf("\r\n### set_able_func ###\r\n"); //# temporary debugging message
//	for (int i = 0; i < MAX_MODEL_NUM; i++) {
//		if(rstrcmp(GIGE_MODEL, (char*)MODEL_FUNC_ABLE[i].model) == 0) {
//			func_able_binn_num = MODEL_FUNC_ABLE[i].able_binn_num;
//			func_able_gain_num = MODEL_FUNC_ABLE[i].able_gain_num;
//			func_able_dnr      = MODEL_FUNC_ABLE[i].able_dnr;
//
////            func_printf("# func_able_binn_num=%b\r\n",func_able_binn_num);
////            func_printf("# func_able_gain_num=%d\r\n",func_able_gain_num);
////            func_printf("# func_able_dnr_num=%d\r\n" ,func_able_dnr_num);
//			return;
//		}
//	}
//}

void get_able_func(void){ //# 230926
            func_printf("# GIGE_MODEL=%s\r\n",GIGE_MODEL);

            func_printf("# func_able_binn_num=4x4(%d)",func_able_binn_num>>3&1);
            func_printf("3x3(%d)",func_able_binn_num>>2&1);
            func_printf("2x2(%d)",func_able_binn_num>>1&1);
            func_printf("1x1(%d)\r\n",func_able_binn_num>>0&1);

            func_printf("# func_able_gain_num=%d\r\n",func_able_gain_num);
            func_printf("# func_able_dnr_num=%d\r\n" ,func_able_dnr);
			return;
}
