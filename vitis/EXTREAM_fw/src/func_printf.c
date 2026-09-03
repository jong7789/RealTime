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

/* //$ 260903
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
}
*/
//$ 260903
void func_printf(const char8 *fmt, ...)
{
    char temp[256];                             

    va_list args;
    va_start(args,fmt);
    vsnprintf(temp, sizeof(temp), fmt, args);  
    va_end(args);                              


    for(int tempi=0; temp[tempi] != '\0'; tempi++){

        char c = temp[tempi];

        if(c == 0x0D){
            if(line < 128) line++;        
            wordp = 0;
        }
        else if (c == 0x08){
//          wordp--;
            if(wordp > 0) wordp--;
        }
        else if (c < 0x20);
        else if (line < 128 && wordp < 127)
        {
            temparr[line][wordp] = c;
            wordp++;
        }
        else if (wordp < 127)
        {
            wordp++;                   
        }
    }

    xil_printf("%s", temp);               
    if(func_sw_debug == 1)    	gige_send_message4(GEV_EVENT_SW_DEBUG_MSG, 0, strlen(temp), (u8*)temp);
}
