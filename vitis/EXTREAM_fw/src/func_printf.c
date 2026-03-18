/*
 * func_cmd.c

 *
 *  Created on: 2019. 10. 1.
 *      Author: ykkim90
 */
#include "func_printf.h"

#include <stdio.h>
#include "gige.h"
#include "framebuf.h"
#include "flash.h"

#include "func_cmd.h"
#include "func_basic.h"
#include "command.h"
#include "calib.h"
#include "display.h"
#include "user.h"
#include "math.h"
#include "fpga_info.h"

u32 line = 0; //# 220927
int wordp = 0;
char temparr[128][128]={0,};
void func_printf(const char8 *fmt, ...)
{
    char temp[128]={0,};

    va_list args;
    va_start(args,fmt);
    vsprintf(temp, fmt, args);
    //# save dmesg
//    strcpy(temparr[line], temp);
    if(line<128)
    {
        for(int tempi=0; tempi<128; tempi++){

            if(temp[tempi]== 0x0D){ //# return
                line++;
                wordp=0;
            }
            else if (temp[tempi]== 0x08) //# backspace
                wordp--;
            else if (temp[tempi] < 0x20); //# ignore
            else
            {
                temparr[line][wordp] = temp[tempi];
                wordp++;
            }
        }
    }


    xil_printf(temp);
    if(func_sw_debug == 1)
    {
    	gige_send_message4(GEV_EVENT_SW_DEBUG_MSG, 0, strlen(temp), (u8*)&temp);
    }
    va_end(args);

    // �Ʒ� ���� �߻�
//    va_list args;
//    va_start(args, fmt);
//    if(func_debug_msg == 1) {
//      char DEBUG_MSG[128];
//      sprintf(DEBUG_MSG, fmt, args);
//      gige_send_message(GEV_EVENT_DEBUG_MSG, 0, sizeof(DEBUG_MSG), (u8*)&DEBUG_MSG);
//    }
//    xil_printf(fmt, args);    // Error
//    va_end(args);
}
