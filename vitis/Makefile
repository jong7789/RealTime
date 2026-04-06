#-------------------------------------------------------------------------------
#  10G GigE Vision Reference Design Firmware
#-------------------------------------------------------------------------------
#  Software environment : Xilinx Vitis 2022.2
#  Hardware platform    : Xilinx KC705
#  Target SoC           : XC7K325T
#  Embedded CPU         : MicroBlaze 11.0, little-endian
#-------------------------------------------------------------------------------
#  Complementary Makefile to perform tasks not covered by the Xilinx Vitis GUI.
#
#  Particular targets...
#    scripts : update auxiliary TCL scripts
#    boot    : build the bootloader executable
#    lib     : build the GigE static library
#    eeprom  : generate EEPROM binary image
#    bit     : merge the bootloader into the bitstream
#    bin     : generate application and bitstream binary files
#  Top-level targets...
#    all     : build everything
#    s2i     : prepare scripts, bootloader, eeprom and library for customer
#
#  The scripts, lib, boot, and s2i targets are nonfunctional for end customers
#  due to missing source code of the scripts, library, and bootloader. Customer
#  gets prebuilt object files in the ./lib directory and up to date scripts
#  in the ./etc directory instead.
#-------------------------------------------------------------------------------
#  0.1  |  2013-03-05  |  JP  |  Initial release
#  0.2  |  2013-10-04  |  JP  |  Update for the Vivado
#  0.3  |  2014-01-28  |  JP  |  Perl scripts replaced by TCL
#  0.4  |  2014-01-29  |  JP  |  Fixed Windows incompatibility
#  0.5  |  2014-07-25  |  JP  |  Update for Vivado 2014.2
#  0.6  |  2014-08-01  |  JP  |  Fixed incompatibility with Vivado 2014.2 under
#       |              |      |  Windows operating systems
#  0.7  |  2016-08-19  |  JP  |  New Vivado tools (xmd replaced by xsdb,
#       |              |      |  data2mem replaced by updatemem)
#  0.8  |  2021-04-15  |  SS  |  Update to Vivado/Vitis 2020.2
#  0.9  |  2021-07-15  |  JP  |  Fixed command line tools settings
#  0.10 |  2022-02-17  |  SS  |  Fixed Flash. Removed 4B addressing
#  0.11 |  2023-01-13  |  AZ  |  Minor cosmetic updates
#  0.12 |  2023-10-25  |  AZ  |  Fixed BSP_PATH
#-------------------------------------------------------------------------------

   1616R_DIR =   EXT_1616R_GEN_HW2.10.01_02_SW2.01.01
  1616RL_DIR =  EXT_1616RL_GEN_HW2.10.01_02_SW2.01.01
   2430R_DIR =   EXT_2430R_GEN_HW2.10.00_02_SW2.01.01
  2430RD_DIR =  EXT_2430RD_GEN_HW2.32.01_10_SW2.01.01
  2430RI_DIR =  EXT_2430RI_GEN_HW2.10.00_02_SW2.01.01
   2832R_DIR =   EXT_2832R_GEN_HW2.00.02_01_SW2.01.01
  2832R2_DIR =   EXT_2832R_GEN_HW2.10.02_01_SW2.01.01
  4343R1_DIR =   EXT_4343R_GEN_HW2.00.02_01_SW2.01.01
  4343R2_DIR =   EXT_4343R_GEN_HW2.10.02_01_SW2.01.01
  4343R3_DIR =   EXT_4343R_GEN_HW2.11.02_10_SW2.01.01
 4343RC1_DIR =  EXT_4343RC_GEN_HW2.00.02_01_SW2.01.01
4343RCL1_DIR = EXT_4343RCL_GEN_HW2.00.02_01_SW2.01.01
 4343RC2_DIR =  EXT_4343RC_GEN_HW2.10.02_01_SW2.01.01
4343RCL2_DIR = EXT_4343RCL_GEN_HW2.10.02_01_SW2.01.01
 4343RC3_DIR =  EXT_4343RC_GEN_HW2.11.02_01_SW2.01.01
4343RCL3_DIR = EXT_4343RCL_GEN_HW2.11.02_01_SW2.01.01
4343RCI1_DIR = EXT_4343RCI_GEN_HW2.00.02_01_SW2.01.01
4343RCI2_DIR = EXT_4343RCI_GEN_HW2.10.02_01_SW2.01.01
 4343RI2_DIR =  EXT_4343RI_GEN_HW2.10.02_01_SW2.01.01
  4343RD_DIR =  EXT_4343RD_GEN_HW2.10.22_01_SW2.01.01

#---- Project specific settings ------------------------------------------------

# Vitis workspace projects
VITIS_PRJ_APP   = EXTREAM_fw
VITIS_CFG_APP   = Release
#VITIS_EXPORT    = xgvrd_platform/export/xgvrd_platform
VITIS_EXPORT    = EXTREAM_R_platform/export/EXTREAM_R_platform
#VITIS_EXPORT_SW = $(VITIS_EXPORT)/sw/xgvrd_platform
VITIS_EXPORT_SW = $(VITIS_EXPORT)/sw/EXTREAM_R_platform
VITIS_EXPORT_HW = $(VITIS_EXPORT)/hw

# EEPROM image generator options
# EE_OPTIONS = -m 3C:39:E7:71:04:16 -c 6 -i 169.254.100.100 -n 255.255.0.0 -g 169.254.100.1 -p 3956 -e XGVRD_KC705_N -a FEC20000
## v2
EE_OPTIONS = -m 3C:39:E7:71:04:16 -c 5 -i 192.168.250.145 -n 255.255.255.0 -g 0.0.0.0 -p 3956 -e 710668 -a FEC20000

# Serial communication device
SERIAL = /dev/ttyUSB0


#---- Project files and directories --------------------------------------------

# Base names of the input/output files
BOOT_NAME = bootloader
LIB_NAME  = gige
APP_NAME  = application
BIT_NAME  = bitstream
EE_NAME   = eeprom
#XML_NAME  = xgvrd-tpg
XML_NAME  = EXTREAM_TOP
#HW_NAME   = xgvrd
HW_NAME   = EXTREAM_R

# Project directories
#HW_PATH  = $(wildcard ../*.runs/impl_1)
#HW_PATH  = $(wildcard ../*.runs/impl_EXT1616R)
#HW_PATH  =  $(FW_PATH)/EXTREAM_R_xsa
HW_PATH  =  $(VITIS_EXPORT_HW)
FW_PATH  = .
OUT_PATH = $(FW_PATH)/bin
LIB_PATH = $(FW_PATH)/lib
ETC_PATH = $(FW_PATH)/etc

# Full input/output file names
BOOT_FILE    = $(LIB_PATH)/$(BOOT_NAME).elf
LIB_FILE     = $(LIB_PATH)/lib$(LIB_NAME).a
APP_BIN_FILE = $(OUT_PATH)/$(APP_NAME).bin
BIT_FILE     = $(OUT_PATH)/$(BIT_NAME).bit
BIT_BIN_FILE = $(OUT_PATH)/$(BIT_NAME).bin
EE_BIN_FILE  = $(OUT_PATH)/$(EE_NAME).bin
EE_C_FILE    = $(FW_PATH)/$(VITIS_PRJ_APP)/src/$(EE_NAME).c
XML_FILE     = $(ETC_PATH)/$(XML_NAME).xml
LNK_SCR_BOOT = $(ETC_PATH)/bootloader.ld
HW_MMI       = $(HW_PATH)/$(HW_NAME).mmi
HW_BIT       = $(HW_PATH)/$(HW_NAME).bit

# Vitis workspace paths and files
BSP_PATH  = $(FW_PATH)/$(VITIS_EXPORT_SW)/domain_0
APP_PATH  = $(FW_PATH)/$(VITIS_PRJ_APP)
APP_OUT   = $(APP_PATH)/$(VITIS_CFG_APP)
APP_FILE  = $(APP_OUT)/$(VITIS_PRJ_APP).elf
APP_SRC  := $(wildcard $(APP_PATH)/src/*.c)
APP_HDR  := $(wildcard $(APP_PATH)/src/*.h)
XSA_FILE  = $(FW_PATH)/$(VITIS_EXPORT_HW)/$(HW_NAME).xsa


#---- Private GigE files and directories ---------------------------------------

#FW_PREFIX = ../../../../s2i_cores/fw
#FW_PREFIX = ../../../../../../../s2i_cores/fw
## from v1.23
FW_PREFIX = ./fw

# TCL scripts
SCRIPTS_PATH = $(FW_PREFIX)/scripts/tcl

# Bootloader source files
BOOT_SRC := $(wildcard $(FW_PREFIX)/bootloader/src/*.c)
BOOT_HDR := $(wildcard $(FW_PREFIX)/bootloader/src/*.h)
# BOOT_SRC := $(wildcard $(FW_PREFIX)/boot/*.c)
# BOOT_HDR := $(wildcard $(FW_PREFIX)/boot/*.h)
## from v1.23

# GigE library source files
LIB_SRC := $(wildcard $(FW_PREFIX)/libgige/src/*.c)
LIB_HDR := $(wildcard $(FW_PREFIX)/libgige/src/*.h)
LIB_OBJ := $(addsuffix .o,$(basename $(notdir $(wildcard $(FW_PREFIX)/libgige/src/*.c))))
LIB_PUB := $(FW_PREFIX)/libgige/src/gige.h


#---- Toolchain setup ----------------------------------------------------------

# CPU tools
AR     = mb-ar
CC     = mb-gcc
SIZE   = mb-size
OC     = mb-objcopy

# Compiler options
CC_OPT_BOOT = -O2
CC_OPT_LIB  = -O2
CC_FLAGS    = -mcpu=v11.0 -mlittle-endian -mno-xl-soft-div -mno-xl-soft-mul -mxl-barrel-shift -mxl-pattern-compare -Wall -Wextra
CC_BFLAGS   = -D _OFFSET_BIT_=0x0000 -D _MAX_BIT_=0xC00000 \
              -D _OFFSET_SEC_=0x0100 -D _MAX_SEC_=0xC00000 \
              -D _OFFSET_TAB_=0x00C0 -D _MAX_TAB_=0x020000 \
              -D _OFFSET_XML_=0x00C2 -D _MAX_XML_=0x0E0000 \
              -D _OFFSET_APP_=0x00D0 -D _MAX_APP_=0x200000 \
              -D _OFFSET_AP2_=0x0FE0 -D _MAX_AP2_=0x0F0000 \
#             -D GIGE_REGS=XPAR_M1_AXI_GEV_BASEADDR \
              -D GIGE_REGS=0x44A10000 \
              -D SDRAM=XPAR_SDRAM_0_BASEADDR
CC_INCLUDES = -I$(BSP_PATH)/bspinclude/include

# Linker options
LNK_LIBPATH    = -L$(BSP_PATH)/bsplib/lib -L$(LIB_PATH)
LNK_FLAGS      = -l$(LIB_NAME)
LNK_FLAGS_BOOT = -Wl,-T -Wl,$(LNK_SCR_BOOT)

# Object copy options
OC_FLAGS  = -v -I elf32-microblaze -O binary
OC_REMOVE = -R .vectors.reset -R .vectors.sw_exception -R .vectors.interrupt -R .vectors.hw_exception

# Data to memory options
#PROC_TAG = CPU_INST/microblaze_0
#drt
#PROC_TAG = GEV_CPU/cpu_i/microblaze_0 
PROC_TAG = $(shell grep -oP 'InstPath="\K[^"]+' $(HW_MMI))

# Correct command line tools for GNUWin environment
XILINX_VITIS_DIR := $(subst \,/,$(XILINX_VITIS))
ifneq (,$(wildcard $(XILINX_VITIS_DIR)/gnuwin/.))
    MKDIR := $(XILINX_VITIS_DIR)/gnuwin/bin/mkdir
    ECHO  := $(XILINX_VITIS_DIR)/gnuwin/bin/echo
    RM    := $(XILINX_VITIS_DIR)/gnuwin/bin/rm
    DATE  := $(shell $(XILINX_VITIS_DIR)/gnuwin/bin/date +%Y%m%d)
else
    MKDIR := mkdir
    ECHO  := echo
    RM    := rm
    DATE  := $(shell date +%Y%m%d)
endif

# Correct NULL file
ifeq ($(SHELL),$(filter $(SHELL),sh.exe command.com))
    NULL := nul
else
    NULL := /dev/null
endif

# Tcl interpreter and scripts
TCLSH  := $(shell which tclsh 2>$(NULL))
XTCLSH := $(shell which xtclsh 2>$(NULL))
VIVADO := $(shell which vivado 2>$(NULL))
ifdef TCLSH
    TCL     := tclsh
    TCLARGS :=
else
    ifdef XTCLSH
        TCL     := xtclsh
        TCLARGS :=
    else
        ifdef VIVADO
            TCL     := vivado -mode batch -nojournal -nolog -notrace -source
            TCLARGS := -tclargs
        else
            TCL     :=
            TCLARGS :=
        endif
    endif
endif
CKSUM  = cksum.tcl
EEPROM = eeprom.tcl
BITBIN = bit2bin.tcl


#---- Compilation targets ------------------------------------------------------

# Aliases

all: scripts boot lib eeprom bit bin

s2i: scripts boot lib eeprom

scripts: $(ETC_PATH)/$(CKSUM) $(ETC_PATH)/$(EEPROM) $(ETC_PATH)/$(BITBIN)

boot: $(BOOT_FILE)

lib: $(LIB_FILE)

# delete "$(EE_C_FILE)" if EEPROM emulation is not needed
#eeprom: $(EE_BIN_FILE) $(EE_C_FILE)
eeprom: $(EE_BIN_FILE)

bit: $(BIT_FILE)

app: $(APP_FILE)

bin: $(APP_BIN_FILE) $(BIT_BIN_FILE)

xml: # $(XML_FILE) $(OUT_PATH) $(XML_NAME)
	@$(ECHO) XML_FILE Copy!
	@cp -fvp $(XML_FILE) $(OUT_PATH)/$(XML_NAME).xml
	@7z x EXTREAM_R.xsa -y -oEXTREAM_R_xsa
	@7z x $(XSA_FILE) -y -o$(FW_PATH)/$(VITIS_EXPORT_HW)                   

bin1st_dir = FPGA1stBin
bitbinuni = bitstream1st_union
bitbi43r = bitstream1st_4343r
bitbi43rc = bitstream1st_4343rc

1616r:
	@mkdir -pv                                          $(OUT_PATH)/$(1616R_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(1616R_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(1616R_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(1616R_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(1616R_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(1616R_DIR)/bitstream1st.bin

1616rl:
	@mkdir -pv                                          $(OUT_PATH)/$(1616RL_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(1616RL_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(1616RL_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(1616RL_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(1616RL_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(1616RL_DIR)/bitstream1st.bin

2430r:
	@mkdir -pv                                          $(OUT_PATH)/$(2430R_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(2430R_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(2430R_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(2430R_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(2430R_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(2430R_DIR)/bitstream1st.bin

2430rd:
	@mkdir -pv                                          $(OUT_PATH)/$(2430RD_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(2430RD_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(2430RD_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(2430RD_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(2430RD_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(2430RD_DIR)/bitstream1st.bin

2430ri:
	@mkdir -pv                                          $(OUT_PATH)/$(2430RI_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(2430RI_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(2430RI_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(2430RI_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(2430RI_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(2430RI_DIR)/bitstream1st.bin

2832r:
	@mkdir -pv                                          $(OUT_PATH)/$(2832R_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(2832R_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(2832R_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(2832R_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(2832R_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(2832R_DIR)/bitstream1st.bin

2832r2:
	@mkdir -pv                                          $(OUT_PATH)/$(2832R2_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(2832R2_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(2832R2_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(2832R2_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(2832R2_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbinuni).bin $(OUT_PATH)/$(2832R2_DIR)/bitstream1st.bin

4343r1:
	@mkdir -pv                                          $(OUT_PATH)/$(4343R1_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343R1_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343R1_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343R1_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343R1_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43r).bin  $(OUT_PATH)/$(4343R1_DIR)/bitstream1st.bin

4343r2:
	@mkdir -pv                                          $(OUT_PATH)/$(4343R2_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343R2_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343R2_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343R2_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343R2_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43r).bin  $(OUT_PATH)/$(4343R2_DIR)/bitstream1st.bin

4343r3:
	@mkdir -pv                                          $(OUT_PATH)/$(4343R3_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343R3_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343R3_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343R3_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343R3_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43r).bin  $(OUT_PATH)/$(4343R3_DIR)/bitstream1st.bin

4343rc1:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RC1_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RC1_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RC1_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RC1_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RC1_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RC1_DIR)/bitstream1st.bin

4343rc2:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RC2_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RC2_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RC2_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RC2_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RC2_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RC2_DIR)/bitstream1st.bin

4343rc3:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RC3_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RC3_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RC3_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RC3_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RC3_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RC3_DIR)/bitstream1st.bin

4343rcl1:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RCL1_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RCL1_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RCL1_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RCL1_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RCL1_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RCL1_DIR)/bitstream1st.bin

4343rcl2:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RCL2_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RCL2_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RCL2_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RCL2_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RCL2_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RCL2_DIR)/bitstream1st.bin

4343rcl3:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RCL3_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RCL3_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RCL3_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RCL3_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RCL3_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RCL3_DIR)/bitstream1st.bin

4343rci1:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RCI1_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RCI1_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RCI1_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RCI1_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RCI1_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RCI1_DIR)/bitstream1st.bin

4343rci2:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RCI2_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RCI2_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RCI2_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RCI2_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RCI2_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RCI2_DIR)/bitstream1st.bin

4343ri2:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RI2_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RI2_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RI2_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RI2_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RI2_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RI2_DIR)/bitstream1st.bin

4343rd:
	@mkdir -pv                                          $(OUT_PATH)/$(4343RD_DIR)
	@cp -fvp $(APP_BIN_FILE)                            $(OUT_PATH)/$(4343RD_DIR)/$(APP_NAME).bin
	@cp -fvp $(BIT_BIN_FILE)                            $(OUT_PATH)/$(4343RD_DIR)/$(BIT_NAME).bin
	@cp -fvp $(XML_FILE)                                $(OUT_PATH)/$(4343RD_DIR)/$(XML_NAME).xml
	@cp -fvp $(EE_BIN_FILE)                             $(OUT_PATH)/$(4343RD_DIR)/$(EE_NAME).bin
	@cp -fvp $(OUT_PATH)/$(bin1st_dir)/$(bitbi43rc).bin $(OUT_PATH)/$(4343RD_DIR)/bitstream1st.bin

# Update TCL scripts

$(ETC_PATH)/$(CKSUM): $(wildcard $(SCRIPTS_PATH)/$(CKSUM))
ifeq ($(wildcard $(SCRIPTS_PATH)/$(CKSUM)),)
	@$(ECHO)
	@$(ECHO) The TCL script is not available!
	@$(ECHO) Please use the $(ETC_PATH)/$(CKSUM) script delivered by S2I!
	@$(ECHO)
else
	@cp -fv $(SCRIPTS_PATH)/$(CKSUM) $(ETC_PATH)/$(CKSUM)
endif

$(ETC_PATH)/$(EEPROM): $(wildcard $(SCRIPTS_PATH)/$(EEPROM))
ifeq ($(wildcard $(SCRIPTS_PATH)/$(EEPROM)),)
	@$(ECHO)
	@$(ECHO) The TCL script is not available!
	@$(ECHO) Please use the $(ETC_PATH)/$(EEPROM) script delivered by S2I!
	@$(ECHO)
else
	@cp -fv $(SCRIPTS_PATH)/$(EEPROM) $(ETC_PATH)/$(EEPROM)
endif

$(ETC_PATH)/$(BITBIN): $(wildcard $(SCRIPTS_PATH)/$(BITBIN))
ifeq ($(wildcard $(SCRIPTS_PATH)/$(BITBIN)),)
	@$(ECHO)
	@$(ECHO) The TCL script is not available!
	@$(ECHO) Please use the $(ETC_PATH)/$(BITBIN) script delivered by S2I!
	@$(ECHO)
else
	@cp -fv $(SCRIPTS_PATH)/$(BITBIN) $(ETC_PATH)/$(BITBIN)
endif


# Actual targets

$(BOOT_FILE): $(BOOT_SRC) $(BOOT_HDR) $(LNK_SCR_BOOT)
ifeq ($(BOOT_SRC),)
	@$(ECHO)
	@$(ECHO) Building the bootloader is not available to end customers!
	@$(ECHO) Please use the prebuilt $(BOOT_FILE) delivered by S2I!
	@$(ECHO)
else
	@$(MKDIR) -p $(LIB_PATH)
	$(CC) $(CC_OPT_BOOT) $(CC_FLAGS) $(CC_BFLAGS) $(BOOT_SRC) -o $(BOOT_FILE) $(LNK_FLAGS_BOOT) $(CC_INCLUDES) $(LNK_LIBPATH)
	@chmod -x $(BOOT_FILE)
	@$(ECHO)
	$(SIZE) -t $(BOOT_FILE)
	@$(ECHO)
endif

$(LIB_FILE): $(LIB_SRC) $(LIB_HDR)
ifeq ($(LIB_SRC),)
	@$(ECHO)
	@$(ECHO) Building the GigE library is not available to end customers!
	@$(ECHO) Please use the prebuilt $(LIB_FILE) delivered by S2I!
	@$(ECHO)
else
	@$(MKDIR) -p $(LIB_PATH)
	@$(RM) -f $(LIB_OBJ)
	$(CC) $(CC_OPT_LIB) $(CC_FLAGS) $(CC_INCLUDES) -c $(LIB_SRC)
	$(AR) rcs $(LIB_FILE) $(LIB_OBJ)
	@$(RM) -f $(LIB_OBJ)
	@$(ECHO)
	$(SIZE) -t $(LIB_FILE)
	@$(ECHO)
	@cp $(LIB_PUB) $(FW_PATH)/$(VITIS_PRJ_APP)/src/
endif

$(EE_BIN_FILE): $(XML_FILE) $(ETC_PATH)/$(CKSUM) $(ETC_PATH)/$(EEPROM)
ifndef TCL
	$(error Tcl interpreter not found)
endif
	@$(TCL) $(ETC_PATH)/$(EEPROM) $(TCLARGS) $(EE_OPTIONS) -x $(XML_FILE) -o $(EE_BIN_FILE)
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(EE_BIN_FILE)

$(EE_C_FILE): $(XML_FILE) $(ETC_PATH)/$(EEPROM)
ifndef TCL
	$(error Tcl interpreter not found)
endif
	@$(TCL) $(ETC_PATH)/$(EEPROM) $(TCLARGS) $(EE_OPTIONS) -t -x $(XML_FILE) -o $(EE_C_FILE)

$(BIT_FILE): $(BOOT_FILE) $(HW_BIT) $(HW_MMI)
	@$(RM) -f $(BIT_FILE)
	updatemem -meminfo $(HW_MMI) -data $(BOOT_FILE) -bit $(HW_BIT) -proc $(PROC_TAG) -out $(BIT_FILE)
	@$(RM) -f updatemem.jou
	@$(RM) -f updatemem.log

$(BIT_BIN_FILE): $(BIT_FILE) $(ETC_PATH)/$(CKSUM)
ifndef TCL
	$(error Tcl interpreter not found)
endif
	@$(RM) -f $(BIT_BIN_FILE)
	$(TCL) $(ETC_PATH)/$(BITBIN) $(TCLARGS) 108 $(BIT_FILE) $(BIT_BIN_FILE)
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(BIT_BIN_FILE)

$(APP_FILE): $(LIB_FILE) $(APP_SRC) $(APP_HDR)
	make -C $(APP_OUT) all

$(APP_BIN_FILE): $(APP_FILE) $(ETC_PATH)/$(CKSUM)
	@$(OC) $(OC_FLAGS) $(OC_REMOVE) $(APP_FILE) $(APP_BIN_FILE)
	@chmod -x $(APP_BIN_FILE)
ifdef TCL
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(APP_BIN_FILE)
endif


#---- Device programming targets -----------------------------------------------

up_app: $(APP_BIN_FILE) $(ETC_PATH)/$(CKSUM)
ifdef TCL
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(APP_BIN_FILE)
endif
	stty -F $(SERIAL) 115200 -crtscts -ixon clocal cs8 -parenb -cstopb -echo
	$(ECHO) -n U > $(SERIAL)
	sleep 1
	sx -b -X $(APP_BIN_FILE) > $(SERIAL) < $(SERIAL)

up_bit: $(BIT_BIN_FILE) $(ETC_PATH)/$(CKSUM)
ifdef TCL
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(BIT_BIN_FILE)
endif
	stty -F $(SERIAL) 115200 -crtscts -ixon clocal cs8 -parenb -cstopb -echo
	$(ECHO) -n U > $(SERIAL)
	sleep 1
	sx -b -X $(BIT_BIN_FILE) > $(SERIAL) < $(SERIAL)

up_ee: $(EE_BIN_FILE) $(ETC_PATH)/$(CKSUM)
ifdef TCL
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(EE_BIN_FILE)
endif
	stty -F $(SERIAL) 115200 -crtscts -ixon clocal cs8 -parenb -cstopb -echo
	$(ECHO) -n U > $(SERIAL)
	sleep 1
	sx -b -X $(EE_BIN_FILE) > $(SERIAL) < $(SERIAL)

up_xml: $(XML_FILE) $(ETC_PATH)/$(CKSUM)
ifdef TCL
	@$(TCL) $(ETC_PATH)/$(CKSUM) $(TCLARGS) -x $(XML_FILE)
endif
	stty -F $(SERIAL) 115200 -crtscts -ixon clocal cs8 -parenb -cstopb -echo
	$(ECHO) -n U > $(SERIAL)
	sleep 1
	sx -b -X $(XML_FILE) > $(SERIAL) < $(SERIAL)
	
MY_JTAG = 00001abd04f901

prog: $(BIT_FILE)
	@$(ECHO) "connect"          					>  xsdb_prog.tcl
	@$(ECHO) "targets -set -filter {jtag_cable_serial =~ \"*$(MY_JTAG)*\" && name =~ \"xc7k*\"}"        >> xsdb_prog.tcl
	@$(ECHO) "fpga $(BIT_FILE)" 					>> xsdb_prog.tcl
	@$(ECHO) "exit"             					>> xsdb_prog.tcl
	xsct xsdb_prog.tcl
	@$(RM) -f xsdb_prog.tcl

run: $(APP_FILE)
	@$(ECHO) "connect"                      		>  xsdb_run.tcl
	@$(ECHO) "targets -set -filter {jtag_cable_serial =~ \"*$(MY_JTAG)*\" && name =~ \"MicroBlaze #0*\"}"		>>xsdb_run.tcl
	@$(ECHO) "loadhw $(XSA_FILE)"           		>> xsdb_run.tcl
	@$(ECHO) "rst -processor"               		>> xsdb_run.tcl
	@$(ECHO) "dow $(APP_FILE)"              		>> xsdb_run.tcl
	@$(ECHO) "con"                          		>> xsdb_run.tcl
	@$(ECHO) "exit"                         		>> xsdb_run.tcl
	xsct xsdb_run.tcl
	@$(RM) -f xsdb_run.tcl

runb: $(BOOT_FILE)
	@$(ECHO) "connect"                      >  xsdb_run.tcl
	@$(ECHO) "targets 3"                    >> xsdb_run.tcl
	@$(ECHO) "loadhw -hw $(XSA_FILE) -regs" >> xsdb_run.tcl
	@$(ECHO) "rst -processor"               >> xsdb_run.tcl
	@$(ECHO) "dow $(BOOT_FILE)"             >> xsdb_run.tcl
	@$(ECHO) "con"                          >> xsdb_run.tcl
	@$(ECHO) "exit"                         >> xsdb_run.tcl
	xsct xsdb_run.tcl
	@$(RM) -f xsdb_run.tcl


#---- Cleanup ------------------------------------------------------------------

clean:
ifneq ($(BOOT_SRC),)
	@$(RM) -fv $(BOOT_FILE)
endif
ifneq ($(LIB_SRC),)
	@$(RM) -fv $(LIB_FILE)
endif
	@$(RM) -fv $(APP_BIN_FILE)
	@$(RM) -fv $(BIT_FILE)
	@$(RM) -fv $(BIT_BIN_FILE)
	@$(RM) -fv $(EE_BIN_FILE)
#	@$(RM) -fv $(EE_C_FILE)
ifneq ($(wildcard $(SCRIPTS_PATH)/$(CKSUM)),)
	@$(RM) -fv $(ETC_PATH)/$(CKSUM)
endif
ifneq ($(wildcard $(SCRIPTS_PATH)/$(EEPROM)),)
	@$(RM) -fv $(ETC_PATH)/$(EEPROM)
endif
ifneq ($(wildcard $(SCRIPTS_PATH)/$(BITBIN)),)
	@$(RM) -fv $(ETC_PATH)/$(BITBIN)
endif
