/*
 * func_print.h
 *
 *  Created on: 2021. 11. 26.
 *      Author: dskim
 */

#ifndef SRC_FUNC_PRINTF_H_
#define SRC_FUNC_PRINTF_H_

#include "xil_printf.h"
#include "xil_types.h"
#include "xil_assert.h"
#include "calib.h"
#include "fpga_info.h"


void func_printf( const char8 *ctrl1, ...);


extern char temparr[128][128];

#endif /* SRC_FUNC_PRINTF_H_ */

