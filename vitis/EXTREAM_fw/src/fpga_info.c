/*
 * fpga_info.c
 *
 *  Created on: Oct 23, 2023
 *      Author: fpga0
 */
#include <string.h>
#include "fpga_info.h"

const char mEXT1024     [16] = "EXT1024R"     ; // #221018
const char mEXT1024RL   [16] = "EXT1024RL"    ; //$ 250703
const char mEXT1616R    [16] = "EXT1616R"     ; // #model redefine
const char mEXT1616RL   [16] = "EXT1616RL"    ; // #model redefine
const char mEXT2430R    [16] = "EXT2430R"     ;
const char mEXT2430RI   [16] = "EXT2430RI"    ;
const char mEXT2832R    [16] = "EXT2832R"     ;
const char mEXT2832R_2  [16] = "EXT2832R_2"   ;
const char mEXT4343R    [16] = "EXT4343R"     ;
const char mEXT4343R_1  [16] = "EXT4343R_1"   ;
const char mEXT4343R_2  [16] = "EXT4343R_2"   ;
const char mEXT4343R_3  [16] = "EXT4343R_3"   ;
const char mEXT4343R_4  [16] = "EXT4343R_4"   ;
const char mEXT4343RC   [16] = "EXT4343RC"    ;
const char mEXT4343RC_1 [16] = "EXT4343RC_1"  ;
const char mEXT4343RC_2 [16] = "EXT4343RC_2"  ;
const char mEXT4343RC_3 [16] = "EXT4343RC_3"  ;
const char mEXT4343RCL_1[16] = "EXT4343RCL_1" ;
const char mEXT4343RCL_2[16] = "EXT4343RCL_2" ;
const char mEXT4343RCL_3[16] = "EXT4343RCL_3" ;
const char mEXT810R     [16] = "EXT810R"      ;
const char mEXT2430RD   [16] = "EXT2430RD"    ;
const char mEXT4343RI_2 [16] = "EXT4343RI_2"  ;
const char mEXT4343RI_4 [16] = "EXT4343RI_4"  ;
const char mEXT4343RCI_1[16] = "EXT4343RCI_1" ;
const char mEXT4343RCI_2[16] = "EXT4343RCI_2" ;
const char mEXT4343RD	[16] = "EXT4343RD"	  ;
const char mEXT3643R	[16] = "EXT3643R"	  ;
const char mEXT0        [16] = "undefined"    ;

char GIGE_MODEL[32];
char HW_VER    [16];
char FPGA_MODEL[16];

u32 FPGA_TFT_MAIN_CLK;
u32 FPGA_TFT_DATA_CLK;

u32 MAX_WIDTH      ;
u32 MAX_WIDTH_x32  ;
u32 MAX_HEIGHT     ;
u32 PIXEL_WIDTH    ;
u32 ROIC_DUAL      ;
u32 ROIC_MAX_CH    ;
u32 ROIC_CH        ;
u32 GATE_CH        ;
u32 GATE_MAX_CH    ;
u32 GATE_DUMMY_LINE;

u32 ROIC_DUMMY_LINE;
u32 ROIC_DUMMY_CH  ;
u32 ROIC_NUM       ;
u32 GATE_NUM       ;
u32 GATE_CHECK     ;
//u32 DS1731_NUM     ;
u32 FLASH_1GBIT=0;
u32 TFT_TIMING_MODE=0;
u32 mEXT1024_series; // 241014 jyp
u32 mEXT4343R_series;
u32 mEXT1616R_series;
u32 mEXT2832R_series;
u32 mEXT2430R_series;
u32 mEXT3643R_series;

u32 AFE3256_series;

int msame ( const char* mEXT ) {
	if (strcmp(FPGA_MODEL, mEXT  ))
		return 0;
	else
		return 1;
}

#define DBG_MODEL 0
void load_fpga_model(void) {
    u32 name = 0;

    name     = (REG(ADDR_FPGA_VER)>>20)& 0xFFF;

    if(DBG_MODEL) func_printf("[DBG_MODEL] name = %d\r\n",name);
    // ###################################################################
    if     (name == 100             )  strcpy(FPGA_MODEL , mEXT1024     );
    else if(name == 101             )  strcpy(FPGA_MODEL , mEXT1024RL   );
    else if(name == 160 && MODEL_LOW)  strcpy(FPGA_MODEL , mEXT1616RL   );
    else if(name == 160             )  strcpy(FPGA_MODEL , mEXT1616R    );
    else if(name == 240             )  strcpy(FPGA_MODEL , mEXT2430R    );
    else if(name == 241             )  strcpy(FPGA_MODEL , mEXT2430RI   );
    else if(name == 280             )  strcpy(FPGA_MODEL , mEXT2832R    );
    else if(name == 282             )  strcpy(FPGA_MODEL , mEXT2832R_2  );
    else if(name == 430             )  strcpy(FPGA_MODEL , mEXT4343R    );
    else if(name == 431             )  strcpy(FPGA_MODEL , mEXT4343R_1  );
    else if(name == 432             )  strcpy(FPGA_MODEL , mEXT4343R_2  );
    else if(name == 433             )  strcpy(FPGA_MODEL , mEXT4343R_3  );
    else if(name == 434				)  strcpy(FPGA_MODEL , mEXT4343R_4  );
    else if(name == 435             )  strcpy(FPGA_MODEL , mEXT4343RC   );
    else if(name == 436 && MODEL_LOW)  strcpy(FPGA_MODEL , mEXT4343RCL_1);
    else if(name == 437 && MODEL_LOW)  strcpy(FPGA_MODEL , mEXT4343RCL_2);
    else if(name == 438 && MODEL_LOW)  strcpy(FPGA_MODEL , mEXT4343RCL_3);
    else if(name == 436             )  strcpy(FPGA_MODEL , mEXT4343RC_1 );
    else if(name == 437             )  strcpy(FPGA_MODEL , mEXT4343RC_2 );
    else if(name == 438             )  strcpy(FPGA_MODEL , mEXT4343RC_3 );
    else if(name == 810             )  strcpy(FPGA_MODEL , mEXT810R     );
    else if(name == 811             )  strcpy(FPGA_MODEL , mEXT2430RD   );
    else if(name == 442             )  strcpy(FPGA_MODEL , mEXT4343RI_2 );
    else if(name == 444				)  strcpy(FPGA_MODEL , mEXT4343RI_4 );
    else if(name == 446             )  strcpy(FPGA_MODEL , mEXT4343RCI_1);
    else if(name == 447             )  strcpy(FPGA_MODEL , mEXT4343RCI_2);
    else if(name == 450             )  strcpy(FPGA_MODEL , mEXT4343RD   );
    else if(name == 360				)  strcpy(FPGA_MODEL , mEXT3643R    );
    else                               strcpy(FPGA_MODEL , mEXT0        );

    if(DBG_MODEL) func_printf("[DBG_MODEL] FPGA_MODEL = ");
    for(int i=0; FPGA_MODEL[i] != '\0'; i++)
    	if(DBG_MODEL) func_printf("%c",FPGA_MODEL[i]);

    if(DBG_MODEL) func_printf("\r\n");

//    █▀█ █▀█ █ █▀▀
//    █▀▄ █▄█ █ █▄▄
    if( msame(mEXT4343RD)||
    	msame(mEXT3643R))	AFE3256_series=1;
    else					AFE3256_series=0;

//    █▀ █▀▀ █▀█ █ █▀▀ █▀
//    ▄█ ██▄ █▀▄ █ ██▄ ▄█
    if( (msame(mEXT4343R_1   )) ||  
        (msame(mEXT4343R_2   )) || 
        (msame(mEXT4343R_3   )) ||
		(msame(mEXT4343R_4   )) ||
        (msame(mEXT4343RC_1  )) || 
        (msame(mEXT4343RC_2  )) || 
        (msame(mEXT4343RC_3  )) || 
        (msame(mEXT4343RCL_1 )) || 
        (msame(mEXT4343RCL_2 )) || 
        (msame(mEXT4343RCL_3 )) || 
        (msame(mEXT4343RI_2  )) ||
		(msame(mEXT4343RI_4  )) ||
        (msame(mEXT4343RCI_1 )) || 
        (msame(mEXT4343RCI_2 )) ||
		(msame(mEXT4343RD    )))
        mEXT4343R_series = 1;
    else
        mEXT4343R_series = 0;

    if( (msame(mEXT1616R     )) ||
        (msame(mEXT1616RL    )) )
        mEXT1616R_series = 1;
    else
        mEXT1616R_series = 0;

    if( (msame(mEXT2832R     )) ||
        (msame(mEXT2832R_2   )) )
        mEXT2832R_series = 1;
    else
        mEXT2832R_series = 0;

    if( (msame(mEXT2430R     )) ||
        (msame(mEXT2430RI    )) )
        mEXT2430R_series = 1;
    else
        mEXT2430R_series = 0;
    // 241014 jyp
    if( (msame(mEXT1024     )) ||
    	(msame(mEXT1024RL   )) ) //$ 250703
        mEXT1024_series = 1;
    else
        mEXT1024_series = 0;
    if (msame(mEXT3643R)) 	mEXT3643R_series = 1;
    else					mEXT3643R_series = 0;

    if(DBG_MODEL) func_printf("mEXT4343R_series = %d\r\n"  ,mEXT4343R_series);
    if(DBG_MODEL) func_printf("mEXT1616R_series = %d\r\n"  ,mEXT1616R_series);
    if(DBG_MODEL) func_printf("mEXT2832R_series = %d\r\n"  ,mEXT2832R_series);
    if(DBG_MODEL) func_printf("mEXT1024_series  = %d\r\n"  ,mEXT1024_series);
    if(DBG_MODEL) func_printf("mEXT3643R_series  = %d\r\n" ,mEXT3643R_series);

    // ###################################################################

//    █▀▀ █░░ █▀█ █▀▀ █▄▀
//    █▄▄ █▄▄ █▄█ █▄▄ █░█
    if(  (msame(mEXT4343R_3  )) || //# A-si
         (msame(mEXT4343RC_3 )) ||
		 (msame(mEXT4343RCL_3)) )
    {
        FPGA_TFT_MAIN_CLK =   6250000; //#   6.25M roic str 512
        FPGA_TFT_DATA_CLK = 153000000; //# 153M
    }
    else if((msame(mEXT4343R    )) || //# 4343
    		(msame(mEXT4343R_1  )) ||
			(msame(mEXT4343R_2  )) ||
			(msame(mEXT4343R_4  )) ||
			(msame(mEXT4343RC_1 )) ||
			(msame(mEXT4343RC_2 )) ||
			(msame(mEXT4343RCL_1)) ||
			(msame(mEXT4343RCL_2)) ||
			(msame(mEXT2430R    )))
    {
        FPGA_TFT_MAIN_CLK =  12500000;
        FPGA_TFT_DATA_CLK = 153000000;
    }
    else if( (msame(mEXT810R  )) || //# direct
    		(msame(mEXT2430RD)) )
    {
        FPGA_TFT_MAIN_CLK =  5000000;
        FPGA_TFT_DATA_CLK = 60000000;
    }
    else if( (msame(mEXT4343RI_2  )) ||
    		 (msame(mEXT4343RI_4  )) ||
    		 (msame(mEXT2430RI    ))) //$ 241213 11 jyp $250424
    {
        FPGA_TFT_MAIN_CLK =  16000000;
        FPGA_TFT_DATA_CLK = 192000000;
    }
    else if( (msame(mEXT4343RD  ))||
    		 (msame(mEXT3643R   ))){ //$ 251121
    	FPGA_TFT_MAIN_CLK =  30000000;
    	FPGA_TFT_DATA_CLK = 360000000;
    }
    else
    {
        FPGA_TFT_MAIN_CLK =  20000000;
        FPGA_TFT_DATA_CLK = 240000000;
    }

    // ###################################################################
    if( msame(mEXT4343R))
    	FLASH_1GBIT = 1;
    else
    	FLASH_1GBIT = 0;

    if( msame(mEXT4343R))
    	TFT_TIMING_MODE = 3;
    else
    	TFT_TIMING_MODE = 0;


    // ###################################################################

//    █▀ █ ▀█ █▀▀ ▄▄ █▀█ █▀█ █ █▀▀ ▄▄ █▀▀ ▄▀█ ▀█▀ █▀▀
//    ▄█ █ █▄ ██▄ ░░ █▀▄ █▄█ █ █▄▄ ░░ █▄█ █▀█ ░█░ ██▄
    if( (msame(mEXT1616R  )) ||
    		(msame(mEXT1616RL )) )
    {
        MAX_WIDTH       = 1648;
        MAX_WIDTH_x32   = 1664;
        MAX_HEIGHT      = 1644;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  236;
        GATE_CH         =  274;
        GATE_MAX_CH     =  450;
        GATE_DUMMY_LINE =   88;
    }
    else if((msame(mEXT4343R    )) || //# 4343
    		(msame(mEXT4343R_1  )) ||
			(msame(mEXT4343R_2  )) ||
			(msame(mEXT4343R_3  )) ||
			(msame(mEXT4343R_4  )) ||
			(msame(mEXT4343RC_1 )) ||
			(msame(mEXT4343RC_2 )) ||
			(msame(mEXT4343RC_3 )) ||
			(msame(mEXT4343RCL_1)) ||
			(msame(mEXT4343RCL_2)) ||
			(msame(mEXT4343RCL_3)) ||
			(msame(mEXT4343RI_2 )) ||
			(msame(mEXT4343RI_4 )) ||
			(msame(mEXT4343RCI_1)) ||
			(msame(mEXT4343RCI_2)) )
    {
        MAX_WIDTH       = 3072;
        MAX_WIDTH_x32   = 3072;
        MAX_HEIGHT      = 3072;
        PIXEL_WIDTH     =   16;
//        if(NT39565) //#???
//            ROIC_DUAL= 2;
//        else
            ROIC_DUAL= 1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  512;
        GATE_MAX_CH     =  512;
        GATE_DUMMY_LINE =    0;
    }
    else if( (msame(mEXT2430R  )) ||
		     (msame(mEXT2430RI )) )
    {
        MAX_WIDTH       = 3840;
        MAX_WIDTH_x32   = 3840;
        MAX_HEIGHT      = 3072;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  512;
        GATE_MAX_CH     =  512;
        GATE_DUMMY_LINE =   33;
    }
    else if( (msame(mEXT2832R    )) ||
		     (msame(mEXT2832R_2  )) )
    {
        MAX_WIDTH       = 2304;
        MAX_WIDTH_x32   = 2304;
        MAX_HEIGHT      = 2048;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  512;
        GATE_MAX_CH     =  512;
        GATE_DUMMY_LINE =    0;
    }
    else if( (msame(mEXT810R     )) )
    {
        MAX_WIDTH       = 2048;
        MAX_WIDTH_x32   = 2048;
        MAX_HEIGHT      = 1536;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  256;
        GATE_MAX_CH     =  256;
        GATE_DUMMY_LINE =    0;
    }
    else if( (msame(mEXT2430RD   )) )
    {
        MAX_WIDTH       = 3584;
        MAX_WIDTH_x32   = 3584;
        MAX_HEIGHT      = 2304;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  384;
        GATE_MAX_CH     =  450;
        GATE_DUMMY_LINE =   33;
    }
    // 241014 jyp
    else if( (msame(mEXT1024   )) ||
    		 (msame(mEXT1024RL )) ) //$ 250703
    {
        MAX_WIDTH       = 1280;
        MAX_WIDTH_x32   = 1280;
        MAX_HEIGHT      = 3072;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  384;
        GATE_MAX_CH     =  450;
        GATE_DUMMY_LINE =   33;
    }
    else if( (msame(mEXT4343RD   )) )
    {
        MAX_WIDTH       = 3072;
        MAX_WIDTH_x32   = 3072;
        MAX_HEIGHT      = 3072;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    2;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  512;
        GATE_MAX_CH     =  512;
        GATE_DUMMY_LINE =    0;
    }
    else if( (msame(mEXT3643R )))
    {
        MAX_WIDTH       = 3584;
        MAX_WIDTH_x32   = 3584;
        MAX_HEIGHT      = 4302;
        PIXEL_WIDTH     =   16;
        ROIC_DUAL       =    1;
        ROIC_MAX_CH     =  256;
        ROIC_CH         =  256;
        GATE_CH         =  478;
        GATE_MAX_CH     =  512;
        GATE_DUMMY_LINE =   34;
    }
//    █▄░█ ▄▀█ █▀▄▀█ █▀▀ ▄▄ █░█ █░█░█
//    █░▀█ █▀█ █░▀░█ ██▄ ░░ █▀█ ▀▄▀▄▀
         if( (msame(mEXT1616R     )) ) {strcpy(GIGE_MODEL , "EXT1616R\0"  );  strcpy(HW_VER , "HW2.10.01_02\0");}
    else if( (msame(mEXT1616RL    )) ) {strcpy(GIGE_MODEL , "EXT1616RL\0" );  strcpy(HW_VER , "HW2.10.01_02\0");}
    else if( (msame(mEXT4343R     )) ) {strcpy(GIGE_MODEL , "EXT4343R\0"  );  strcpy(HW_VER , "HW2.00.02_01\0");}
    else if( (msame(mEXT4343R_1   )) ) {strcpy(GIGE_MODEL , "EXT4343R\0"  );  strcpy(HW_VER , "HW2.00.02_01\0");}
    else if( (msame(mEXT4343R_2   )) ) {strcpy(GIGE_MODEL , "EXT4343R\0"  );  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT4343R_3   )) ) {strcpy(GIGE_MODEL , "EXT4343R\0"  );  strcpy(HW_VER , "HW2.11.02_10\0");}
    else if( (msame(mEXT4343R_4   )) ) {strcpy(GIGE_MODEL , "EXT4343R\0"  );  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT4343RC_1  )) ) {strcpy(GIGE_MODEL , "EXT4343RC\0" );  strcpy(HW_VER , "HW2.00.02_01\0");}
    else if( (msame(mEXT4343RC_2  )) ) {strcpy(GIGE_MODEL , "EXT4343RC\0" );  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT4343RC_3  )) ) {strcpy(GIGE_MODEL , "EXT4343RC\0" );  strcpy(HW_VER , "HW2.11.02_10\0");}
    else if( (msame(mEXT4343RCL_1 )) ) {strcpy(GIGE_MODEL , "EXT4343RCL\0");  strcpy(HW_VER , "HW2.00.02_01\0");}
    else if( (msame(mEXT4343RCL_2 )) ) {strcpy(GIGE_MODEL , "EXT4343RCL\0");  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT4343RCL_3 )) ) {strcpy(GIGE_MODEL , "EXT4343RCL\0");  strcpy(HW_VER , "HW2.11.02_10\0");}
    else if( (msame(mEXT4343RI_2  )) ) {strcpy(GIGE_MODEL , "EXT4343RI\0" );  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT4343RI_4  )) ) {strcpy(GIGE_MODEL , "EXT4343RI\0" );  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT4343RCI_1 )) ) {strcpy(GIGE_MODEL , "EXT4343RCI\0");  strcpy(HW_VER , "HW2.00.02_01\0");}
    else if( (msame(mEXT4343RCI_2 )) ) {strcpy(GIGE_MODEL , "EXT4343RCI\0");  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT2430R     )) ) {strcpy(GIGE_MODEL , "EXT2430R\0"  );  strcpy(HW_VER , "HW2.10.00_02\0");}
    else if( (msame(mEXT2430RI    )) ) {strcpy(GIGE_MODEL , "EXT2430RI\0" );  strcpy(HW_VER , "HW2.10.00_02\0");}
    else if( (msame(mEXT2832R     )) ) {strcpy(GIGE_MODEL , "EXT2832R\0"  );  strcpy(HW_VER , "HW2.00.02_01\0");}
    else if( (msame(mEXT2832R_2   )) ) {strcpy(GIGE_MODEL , "EXT2832R\0"  );  strcpy(HW_VER , "HW2.10.02_01\0");}
    else if( (msame(mEXT810R      )) ) {strcpy(GIGE_MODEL , "EXT810R\0"   );  strcpy(HW_VER , "HW2.32.01_10\0");}
    else if( (msame(mEXT2430RD    )) ) {strcpy(GIGE_MODEL , "EXT2430RD\0" );  strcpy(HW_VER , "HW2.32.01_10\0");}
    else if( (msame(mEXT1024      )) ) {strcpy(GIGE_MODEL , "EXT1024R\0"  );  strcpy(HW_VER , "HW2.11.00_02\0");}// 241202 jyp
    else if( (msame(mEXT1024RL    )) ) {strcpy(GIGE_MODEL , "EXT1024RL\0" );  strcpy(HW_VER , "HW2.11.00_02\0");}//$ 250703
    else if( (msame(mEXT4343RD    )) ) {strcpy(GIGE_MODEL , "EXT4343RD\0" );  strcpy(HW_VER , "HW2.10.22_01\0");}
    else if( (msame(mEXT3643R     )) ) {strcpy(GIGE_MODEL , "EXT3643R\0"  );  strcpy(HW_VER , "HW2.10.22_01\0");}
    else                               {strcpy(GIGE_MODEL , "UNDEFINED"   );  strcpy(HW_VER , "HW2.00.00_00\0");}


    // ###################################################################
    ROIC_DUMMY_LINE = (2 * ROIC_DUAL);
    ROIC_DUMMY_CH   = ((ROIC_MAX_CH - ROIC_CH) / 2);
    ROIC_NUM        = (int)(((float)MAX_WIDTH / ROIC_CH + 0.499) * ROIC_DUAL);//220411 mbh
    GATE_NUM        = (MAX_HEIGHT / GATE_CH);
    GATE_CHECK      = (1000000.0 / FPGA_TFT_MAIN_CLK); // us (MCLK)
//    DS1731_NUM      = 4; // 2->4 added temperature ic 3,4 mbh 210305

    execute_func_cmd();
    load_frame_rate();    
    load_gev_speed();
    load_tempbcal(); //# 24120216
    load_calib_def();
    load_func_able();
    flash_init();
}


// ###################################################################
#define DBG_lfrate 0
float MAX_FRATE;
void load_frame_rate(void) 
{

//	 █▀▀ █▀█ █▀
//	 █▀░ █▀▀ ▄█
         if( (msame(mEXT1616R     )) )  MAX_FRATE = 40.0; // fps
    else if( (msame(mEXT1616RL    )) )  MAX_FRATE = 30.0;
    else if( (msame(mEXT4343R     )) )  MAX_FRATE = 15.0;
    else if( (msame(mEXT4343R_1   )) )  MAX_FRATE = 15.0;
    else if( (msame(mEXT4343R_2   )) )  MAX_FRATE = 15.0;
    else if( (msame(mEXT4343R_3   )) )  MAX_FRATE =  7.0;
    else if( (msame(mEXT4343R_4   )) )  MAX_FRATE = 15.0;
    else if( (msame(mEXT4343RC_1  )) )  MAX_FRATE = 15.0;
    else if( (msame(mEXT4343RC_2  )) )  MAX_FRATE = 15.0;
    else if( (msame(mEXT4343RC_3  )) )  MAX_FRATE =  7.0;
    else if( (msame(mEXT4343RCL_1 )) )  MAX_FRATE =  8.0;
    else if( (msame(mEXT4343RCL_2 )) )  MAX_FRATE =  8.0;
    else if( (msame(mEXT4343RCL_3 )) )  MAX_FRATE =  4.0;
    else if( (msame(mEXT4343RI_2  )) )  MAX_FRATE = 20.0; //$ 241213 jyp 25->20
    else if( (msame(mEXT4343RI_4  )) )  MAX_FRATE = 20.0;
    else if( (msame(mEXT4343RCI_1 )) )  MAX_FRATE = 20.0;
    else if( (msame(mEXT4343RCI_2 )) )  MAX_FRATE = 20.0;
    else if( (msame(mEXT2430R     )) )  MAX_FRATE = 12.0; // fps
    else if( (msame(mEXT2430RI    )) )  MAX_FRATE = 20.0; // fps //# 250317 25->20
    else if( (msame(mEXT2832R     )) )  MAX_FRATE = 30.0; // fps
    else if( (msame(mEXT2832R_2   )) )  MAX_FRATE = 30.0; // fps
    else if( (msame(mEXT810R      )) )  MAX_FRATE = 10.0; // fps
    else if( (msame(mEXT2430RD    )) )  MAX_FRATE = 10.0; // fps
    else if( (msame(mEXT1024      )) )  MAX_FRATE = 25.0; //$ 241014 jyp
    else if( (msame(mEXT1024RL    )) )  MAX_FRATE =  6.0; //$ 250703
    else if( (msame(mEXT4343RD    )) )  MAX_FRATE = 60.0;
    else if( (msame(mEXT3643R     )) )  MAX_FRATE = 25.0;
    else                                MAX_FRATE = 40.0;
 
}
   /* MODEL,        BINN 4,3,2,1, Gain, DNR */
//  {"EXT1616R\0"   ,    0b0011,    4,   1},
//  {"EXT1616RL\0"  ,    0b0011,    4,   1},
//  {"EXT4343R\0"   ,    0b1111,    4,   1},
//  {"EXT4343RC\0"  ,    0b1111,    4,   1},
//  {"EXT4343RCL\0" ,    0b1111,    4,   1},
//  {"EXT4343RI\0"  ,    0b1111,    1,   0},
//  {"EXT4343RCI\0" ,    0b1111,    1,   0},
//  {"EXT2430R\0"   ,    0b1111,    4,   1},
//  {"EXT2430RI\0"  ,    0b1111,    1,   0},
//  {"EXT2832R\0"   ,    0b0011,    4,   1},
//  {"EXT810R\0"    ,    0b0011,    4,   1},
//  {"EXT2430RD\0"  ,    0b0011,    4,   1},
//  {"EXT1024R\0"   ,    0b0011,    1,   0}, //$ 241127 add EXT1024R
//  {"EXT1024RL\0"  ,    0b0011,    1,   0}, //$ 250703
//  {"EXT4343RD\0"  ,    0b0011,    1,   0},
//	{"EXT3643R\0"	,    0b0011,    1,   0},
//		func_able_binn_num = MODEL_FUNC_ABLE[i].able_binn_num;
//		func_able_gain_num = MODEL_FUNC_ABLE[i].able_gain_num;
//		func_able_dnr      = MODEL_FUNC_ABLE[i].able_dnr;

u8 func_able_binn_num  = 0; //# 230926 //# 250317 load_func_able
u8 func_able_gain_num  = 0;
u8 func_able_dnr   = 0;

void load_func_able(void) //# 250317 load_func_able
{
         if( (msame(mEXT1616R     )) ) {func_able_binn_num=0b0011; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT1616RL    )) ) {func_able_binn_num=0b0011; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343R     )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343R_1   )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343R_2   )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343R_3   )) ) {func_able_binn_num=0b0001; func_able_gain_num=4; func_able_dnr=1;}//# nt gate no binning
    else if( (msame(mEXT4343R_4   )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343RC_1  )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343RC_2  )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343RC_3  )) ) {func_able_binn_num=0b0001; func_able_gain_num=4; func_able_dnr=1;} //# nt gate no binning
    else if( (msame(mEXT4343RCL_1 )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343RCL_2 )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT4343RCL_3 )) ) {func_able_binn_num=0b0001; func_able_gain_num=4; func_able_dnr=1;} //# nt gate no binning
    else if( (msame(mEXT4343RI_2  )) ) {func_able_binn_num=0b1111; func_able_gain_num=1; func_able_dnr=0;}
    else if( (msame(mEXT4343RI_4  )) ) {func_able_binn_num=0b1111; func_able_gain_num=1; func_able_dnr=0;}
    else if( (msame(mEXT4343RCI_1 )) ) {func_able_binn_num=0b1111; func_able_gain_num=1; func_able_dnr=0;}
    else if( (msame(mEXT4343RCI_2 )) ) {func_able_binn_num=0b1111; func_able_gain_num=1; func_able_dnr=0;}
    else if( (msame(mEXT2430R     )) ) {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT2430RI    )) ) {func_able_binn_num=0b1111; func_able_gain_num=1; func_able_dnr=0;}
    else if( (msame(mEXT2832R     )) ) {func_able_binn_num=0b0011; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT2832R_2   )) ) {func_able_binn_num=0b0011; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT810R      )) ) {func_able_binn_num=0b0011; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT2430RD    )) ) {func_able_binn_num=0b0011; func_able_gain_num=4; func_able_dnr=1;}
    else if( (msame(mEXT1024      )) ) {func_able_binn_num=0b0011; func_able_gain_num=1; func_able_dnr=1;}
    else if( (msame(mEXT1024RL    )) ) {func_able_binn_num=0b0011; func_able_gain_num=1; func_able_dnr=1;} //$ 250703
    else if( (msame(mEXT4343RD    )) ) {func_able_binn_num=0b0011; func_able_gain_num=1; func_able_dnr=1;}
    else if( (msame(mEXT3643R     )) ) {func_able_binn_num=0b0011; func_able_gain_num=1; func_able_dnr=1;}
    else                               {func_able_binn_num=0b1111; func_able_gain_num=4; func_able_dnr=0;}
}

u32 def_gev_speed;
u32 ETHERSPEED_B;
u8  GIGE_MINFO[48];
u32 func_gainref_numlim;
void load_gev_speed(void) 
{

    if ( (msame(mEXT4343RI_2 )) ||
    	 (msame(mEXT4343RI_4 )) ||
    	 (msame(mEXT4343RCI_1)) ||
		 (msame(mEXT4343RCI_2)) ||
		 (msame(mEXT2430RI   )) ||
		 (msame(mEXT1024     )) ||
		 (msame(mEXT4343RD   )) ||
		 (msame(mEXT3643R    ))) //$ 241127 add EXT 1024R
        def_gev_speed = 10;
    else
        def_gev_speed = 2;

    if(def_gev_speed==10)
        ETHERSPEED_B = 10000000000/8; //# BYTE
    else
        ETHERSPEED_B =  2500000000/8;

//    if(def_gev_speed==10)
//        GIGE_MINFO[48] = "10G GigE Vision\0";
//    else
//        GIGE_MINFO[48] = "2.5G GigE Vision\0";

    if(def_gev_speed==10)
        strcpy(GIGE_MINFO , "10G GigE Vision\0");
    else
        strcpy(GIGE_MINFO , "2.5G GigE Vision\0");

if (def_gev_speed==2)
    func_gainref_numlim = 4;
else if (def_gev_speed==10)
    func_gainref_numlim = 1; //# 230321
else
    func_gainref_numlim = 4;
}

u8 def_tempbcal;
void load_tempbcal(void) //# 24120216 load_tempbcal
{
	if ((msame(mEXT1024    )) ||
		(msame(mEXT1024RL  )) ||//$ 250703
		(msame(mEXT4343R_4 )) ||
		(msame(mEXT4343RI_4)) ||
		(msame(mEXT4343RD  )) ||
		(msame(mEXT3643R   )))
		def_tempbcal = 0; //# 1024r does not need temp cal.
						 //# 3 roic dclk are connected to FPGA roic_rx block.
	else
		def_tempbcal = 1;
}
