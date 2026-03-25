library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

package TOP_HEADER is

    constant SIMULATION : string := "OFF";
-- constant SIMULATION : string := "ON";
-- constant GNR_MODEL  : string := "EXT1616R";

--constant FPGA_VER  : std_logic_vector(19 downto 0) := x"1_99_00"; --# 1st image
    constant FPGA_VER  : std_logic_vector(19 downto 0) := x"2_01_11"; --(ti1,adi0_MainVer_subVer)
constant FPGA_DATE : std_logic_vector(31 downto 0):= x"26_0323_17";

-- # 2_01_11 26_0323_17 :  $ 2DDR & 4DDR
-- # 2_01_11 26_0320_11 :  rxaui bufh, sfp bypass
-- # 2_01_11 26_0320_10 :  --# bufh-> bufg 250320
-- # 2_01_11 26_0318_18 :  --# SFP+ 10GBASE-R PHY and XGMII MUX
-- # 2_01_11 26_0317_14 :  $ EXT3643R MODEL ADD
-- # 2_01_11 26_0312_17 :  --$ 260312 4343rd roic dclk
-- # 2_01_11 26_0312_15 :  --$ 260312 AFE3256 ADC 128Ch
-- # 2_01_11 26_0304_11 :  --$ 260304 10G Edge cut
-- # 2_01_11 26_0226_13 :  --$ 260226 AFE3256 SPI sck 7.5Mhz
-- # 2_01_11 26_0226_11 :  $ ext4343rd sdi num 1->2
-- # 2_01_11 26_0223_10 :  --$ 260223 dual roic 2x2 binning error
-- # 2_01_11 26_0220_10 :  --$ 260220 dual roic offset
-- # 2_01_11 26_0219_15 :  $ ila gate ctrl
-- # 2_01_11 26_0128_09 :  --$260128 integrate sm
-- # 2_01_11 26_0126_17 :  $ mask para4 ila
-- # 2_01_11 26_0126_14 :  $ cpu axi monitor
-- # 2_01_11 26_0126_13 :  --$260126
-- # 2_01_11 26_0126_10 :  $ Defect '1'
-- # 2_01_11 26_0123_18 :  # crossbar prioity
-- # 2_01_11 26_0123_17 :  # uiclk to reg // fw cmd "rclk"
-- # 2_01_11 26_0123_13 :  # added ddr axipmon
-- # 2_01_11 26_0123_09 :  $ sch0_warea
-- # 2_01_11 26_0122_18 :  --$ 260122 GEN_DEFECT
-- # 2_01_11 26_0121_14 :  $ AXI Master ila
-- # 2_01_11 26_0121_14 :  $ ROI PROC debug
-- # 2_01_11 26_0121_14 :  $ SUB_IF debug
-- # 2_01_11 26_0116_15 :  $ SUB_IF debug
-- # 2_01_11 26_0114_17 :  $ ila TOP
-- # 2_01_11 26_0113_18 :  $ ila axi_sub & axi
-- # 2_01_11 26_0113_15 :  $ EXTREAM_TOP ILA & WCONV_DATA
-- # 2_01_11 26_0113_12 :  $ EXTREAM_TOP ILA
-- # 2_01_11 26_0113_11 :  $ TFT TOP vio & ila
-- # 2_01_11 26_0113_10 :  $ EXTREAM_R DDR sdata_test
-- # 2_01_11 26_0112_15 :  $ ROI_PROC TEST
-- # 2_01_11 26_0107_20 :  $ ila ROI_PROC & DDR SYNC
-- # 2_01_11 26_0107_20 :  $ ila ROI_PROC
-- # 2_01_11 26_0107_19 :  $ LVDS xdc dclk 2.778ns & LVDS_RX shft eye isys_clk
-- # 2_01_11 26_0107_18 :  $ LVDS xdc dclk 2.7ns
-- # 2_01_11 26_0107_17 :  $ LVDS receive roic dclk
-- # 2_01_11 26_0106_17 :  $ AXI_IF vio test
-- # 2_01_11 26_0106_17 :  $ EXTREAM_R vio test
-- # 2_01_11 26_0106_16 :  $ cpu clk wiz 20 -> 30 => bcal error
-- # 2_01_11 26_0106_16 :  $ cpu clk wiz 30 -> 20
-- # 2_01_11 25_1231_16 :  $ vio_img_out
-- # 2_01_11 25_1223_19 :  $ EXTREAM_R 4343RD add
-- # 2_01_11 25_1223_18 :  $ pin map rollback
-- # 2_01_11 25_1223_17 :  # bd mclk 20M->30M
-- # 2_01_11 25_1223_16 :  $ EXT4343RD lvds pin map test
-- # 2_01_11 25_1223_15 :  $ EXT4343RD lvds ila
-- # 2_01_11 25_1223_10 :  $ EXT4343RD Model

-- # 2_01_11 25_1013_14 :  ddr refclk error -> no bufg
-- # 2_01_11 25_1001_10 :  impl:congestion_sp..high ==> align OK
-- # 2_01_11 25_0930_18 :  pwr_ctrl except 4343r4
-- # 2_01_11 25_0930_13 :  xdc map
-- # 2_01_11 25_0930_12 :  vio, off, 12 on
-- # 2_01_11 25_0929_14 :  bufg seq at lvds_rx
-- # 2_01_11 25_0929_11 :  4343r_4 bufg mux update
-- # 2_01_11 25_0909_14 :  R1 update from 250904
-- # 2_01_10 24_0809_12 :  OSD trig enhence
-- # 2_01_09 24_0805_19 :  vio_gate_test
-- # 2_01_08 24_0130_14 :  --# ignored ver_stt_trig at 2832 30fps, 240130
-- # 2_01_07 24_0129_14 :  rollback "240122 cpv position test"
-- # 2_01_07 24_0122_13 :  --# 240122 cpv position test
-- # 2_01_07 24_0122_12 : use roic oe out " --# it need a roic setting "rreg 0x5A 0x40" 240122
-- # 2_01_07 24_0122_11 : gate oe reverse mapping to reg_gate_en
-- # 2_01_06 23_1222_15 : remove avg
-- # 2_01_06 23_1212_19 : '1', --#force sync counter
-- # 2_01_06 23_1212_19 : 4para bnc modeul add, all model compile
-- # 2_01_05 23_1212_18 : added model 2832R
-- # 2_01_05 23_1212_17 : "if SyncStart = '1' then --# preventing non Vsync 231212
-- # 2_01_05 23_1212_12 : finding v sync at 44binn
-- # 2_01_04 23_1212_12 : 3x3, 4x4 abnormal
-- # 2_02_03 23_1212_11 : img_out_top vertical sync, version test=OK
-- #                        "if (ver_stt_trig='1') then --# 231212
-- # 2_01_03 23_1212_11 : GEN_ILA_img_out_top trouble
-- # 2_01_03 23_1208_18 : 2430 screen rotation ila
-- # 2_01_02 23_1207_15 : version check
-- # 2_01_02 23_1206_11 : project clean
-- # 2_01_02 23_1205_08 : clock check via tp
-- # 2_01_02 23_1201_17 : vivado project name "EXTxR2"
-- # 2_01_02 23_1201_14 : axi2 dwidth converter
-- # 2_01_01 23_1130_18 : ila all check
-- # 2_01_01 23_1130_16 : cpu bram 128->16, GEN_VIO_SYNC_COUNTER0 on
-- # 2_01_01 23_1129_14 : axi_clk name conn
-- # 2_01_01 23_1128_13 : bd mb bram size 16k->128k
--################################## V2 #################################
-- # 1_70_10 23_1120_10 : generic model GNR_MODEL reg 4, 8 bug fix
-- # 1_70_09 23_1117_18 : generic model GNR_MODEL Image is diago
-- # 1_70_08 23_1116_12 : generic model GNR_MODEL
-- # 1_70_07 23_1102_16 : first pixel fixing more.
--                          "--# first pixel offset data bug, added uderneath line #231102
-- # 1_70_06 23_1101_15 : first pixel of offset is 0 cause data delay by state-machine
--                          "--# first pixel offset data bug, added uderneath line #231101
-- # 1_70_05 23_1101_12 : offset data is 0, axi_if ila ,13 avg ila
-- # 1_70_04 23_1101_10 : offset correction (0,0) data error debug with ILA
-- # 1_70_03 23_1026_16 : roic_sync timing
-- #                      " if 32 <= sTpSelChangedCnt and
-- # 1_70_02 23_1026_13 : oroic_sync <=  sroic_sync; --# 231026
-- #                      " tp_sel with roic_sync ### 210812 ## comments 231025
-- #                      " oroic_sync <=  sroic_sync when  ireg_req_align = '0' else
-- # 1_70_01 23_1026_10 : 2832 roic_tp_sel abnormal. clean up the related code
--------- V1.70.xx --------------------------
-- # 1_69_05 23_1011_16 : 1616 offset err, ila
-- # 1_69_04 23_1006_11 : 2430RD not spwr_roic_en_l
-- #         23_1006_12 : 2430RD gate map
-- #         23_1006_15 : 2430RD INIT_PWDAC_LEVEL volt 0.5->0.1 = 100V
-- #         23_1006_16 : 2430RD roic size 1742->3584
-- # 1_69_03 23_1004_14 : sync cnt rollback
-- # 1_69_02 23_0926_10 : v1.69.69 release test
-- #         23_0925_17 : oe by oe state
-- #                      sgate_oe        <= '0'; --# 230925
-- #         23_0925_16 : rollback
-- #         23_0925_10 : gate oe defense
-- #         23_0921_17 : activation TP
-- # 1_69_01 23_0921_16 : "- sgate_dummy_add" roll back -> do FW
-- # 1_69_00 23_0921_11 : release ver for binn test
---------------------------------------------------------------------
--  ### SELECTION ###
-- * MODEL : EXT1024R, EXT1616R, EXT4343R
-- * ROIC : ADAS1255, ADAS1258, AFE2256
-- * GATE : NT39565, NT39565D, NT39530, NT61303, RM76U89, HX8698
-- * ROIC_DUAL : 1 : Normal 2 : Dual ROIC

-- 1616R   raydium 450 274use
-- 4343R   => R
-- 4343RR  => R1 raydium512
-- 4343RR2 => R2 raydium256 inocare
-- 4343RN  => R3 nova a-si
-- 4343RC  => RC NT39565D
-- 4343RCR => RC1 raydium512
-- 4343RCR => RC2 raydium256 No exist #####
-- 4343RCN => RC3 NT39530 a-si

-- fix constant
    constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
    constant DDR3_ADDR_14  : string  := "AA13";

-- ▄█ ▄▀▀▄ ▀█ █░█
-- ░█ █  █ █▀ █▄█
-- ░█ ▀▄▄▀ █▄   █
-- jyp 241010
-- ### EXT 1024R ### synth-25
-- constant MODEL         : string  := "EXT1024R" ; -- 76um
-- constant ROIC_IC       : string  := "AFE2256";   -- 256x5 = 1280
-- constant GATE_IC       : string  := "RM76U89";   -- 384x8 = 3072
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT1024R -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT1024R/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ▄█ █▄▄ ▄█ █▄▄
-- ░█ █▄█ ░█ █▄█
-- ### EXT1616R ### synth-0
-- constant MODEL         : string  := "EXT1616R"; -- 100u
-- constant ROIC_IC       : string  := "AFE2256";  -- 236x7=1652-4=1648
-- constant GATE_IC       : string  := "RM76U89";  -- 274x6=1644 dmy(450-(88*2))=274
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT1616R -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT1616R/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ▀█ █░█ ▀▀█ ▄▀▀▄
-- █▀ █▄█ ▀▀█ █  █
-- █▄   █ ▄▄█ ▀▄▄▀
-- ### EXT2430R ### synth-1
-- constant MODEL         : string  := "EXT2430R"; -- 76u
-- constant ROIC_IC       : string  := "AFE2256";  -- 256x15=3840
-- constant GATE_IC       : string  := "RM76U89";  -- 384x 8=3072 dmy(450-(33*2))=384
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT2430R -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT2430R/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ▀█ █▀█ ▀▀█ ▀█
-- █▀ █▀█ ▀▀█ █▀
-- █▄ █▄█ ▄▄█ █▄
-- ### EXT2832R ### synth-2
-- constant MODEL         : string  := "EXT2832R"; -- 140u
-- constant ROIC_IC       : string  := "AFE2256";  -- 256x9=2304
-- constant GATE_IC       : string  := "RM76U89";  -- 512x4=2048
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT2832R -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT2832R/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT2832R_2 ### innocare synth-3
-- constant MODEL         : string  := "EXT2832R_2"; -- 140u
-- constant ROIC_IC       : string  := "AFE2256";  -- 256x9=2304
-- constant GATE_IC       : string  := "RM76U89";  -- 512x4=2048
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT2832R_2 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT2832R_2/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

----------------------------------------------------------------------

-- █░█ ▀▀█ █░█ ▀▀█ █▀█
-- █▄█ ▀▀█ █▄█ ▀▀█ █▀▄
--   █ ▄▄█   █ ▄▄█
-- ### EXT4343R ###
-- constant MODEL         : string  := "EXT4343R"; -- 140u
-- constant ROIC_IC       : string  := "AFE2256";  -- 256*12=3072
-- constant GATE_IC       : string  := "HX8698";   -- 512*6 =3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 13; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13"; -- no effective
-- constant GEV_SPEED     : string  := "2p5G";
-- ### EXT4343R_1 ### synth-4
-- constant MODEL         : string  := "EXT4343R_1"; -- 140u
-- constant ROIC_IC       : string  := "AFE2256";    -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";    -- 512*6 =3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343R_1 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343R_1/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343R_2 ### synth-5
-- constant MODEL         : string  := "EXT4343R_2"; -- innocare raydium 512
-- constant ROIC_IC       : string  := "AFE2256";    -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";    -- 512*6 =3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343R_2 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343R_2/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343R_3 ### synth-6
-- constant MODEL         : string  := "EXT4343R_3"; -- a-si nova
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "NT39530";   -- 256*12=3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343R_3 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343R_3/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343R_4 ### synth-26 --$ dclk ver.
-- constant MODEL         : string  := "EXT4343R_4"; -- innocare raydium 512
-- constant ROIC_IC       : string  := "AFE2256";    -- 256*12=3072
-- constant GATE_IC       : string  := "NT39530";    -- 512*6 =3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343R_3 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343R_3/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf
-- █░█ ▀▀█ █░█ ▀▀█ █▀█ █▀▀
-- █▄█ ▀▀█ █▄█ ▀▀█ █▀▄ █▄▄
--   █ ▄▄█   █ ▄▄█
-- ### EXT4343RC ###  old
-- constant MODEL         : string  := "EXT4343RC";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "NT39565D";  -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AF10";
-- constant GEV_SPEED     : string  := "2p5G";
-- ### EXT4343RC_1 ### default synth-8
-- constant MODEL         : string  := "EXT4343RC_1";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343RC_1 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RC_1/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### 4343RC_2 ### IGZO i-sa TFT synth-9
-- constant MODEL         : string  := "EXT4343RC_2";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 12500;
-- constant ROIC_DCLK_KHz : integer := 150000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343RC_2 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RC_2/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343RC_3 ### -- 1set in DIC 221017
-- constant MODEL         : string  := "EXT4343RC_3";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "NT39530";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 6250;
-- constant ROIC_DCLK_KHz : integer := 75000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT4343RC_3 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RC_3/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ▄█ ▄▀▀▄ █▀▀
--  █ █  █ █▄█
-- ░█ ▀▄▄▀
-- ### EXT2430RI ### --synth-12 impl-opt area
-- constant MODEL         : string  := "EXT2430RI"; -- 76u
-- constant ROIC_IC       : string  := "AFE2256";  -- 256x15=3840
-- constant GATE_IC       : string  := "RM76U89";  -- 384x 8=3072 dmy(450-(33*2))=384
-- constant ROIC_MCLK_KHz : integer := 20000; -- #230518 speed miss fix
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT2430RI -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT2430RI/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343RI_2 ### synth-15
-- constant MODEL         : string  := "EXT4343RI_2"; -- innocare raydium256
-- constant ROIC_IC       : string  := "AFE2256";    -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";    -- 256*12=3072
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT4343RI_2 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RI_2/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343RI_4 ### 10G
-- constant MODEL         : string  := "EXT4343RI_4";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT4343RCI_2 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RCI_2/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343RCI_1 ### synth-18
-- constant MODEL         : string  := "EXT4343RCI_1";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT4343RCI_1 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RCI_1/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343RCI_2 ### 10G
-- constant MODEL         : string  := "EXT4343RCI_2";
-- constant ROIC_IC       : string  := "AFE2256";   -- 256*12=3072
-- constant GATE_IC       : string  := "RM76U89";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 20000;
-- constant ROIC_DCLK_KHz : integer := 240000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT4343RCI_2 -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RCI_2/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT4343RD ### 10G
-- constant MODEL         : string  := "EXT4343RD";
-- constant ROIC_IC       : string  := "AFE3256";   -- 256*24=3072 (Dual)
-- constant GATE_IC       : string  := "RM76U89";   -- 512*6=3072
-- constant ROIC_MCLK_KHz : integer := 30000;
-- constant ROIC_DCLK_KHz : integer := 360000;
-- constant ROIC_DUAL     : integer := 2;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT4343RD -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT4343RD/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- ### EXT3643R ### 10G
-- constant MODEL         : string  := "EXT3643R";
-- constant ROIC_IC       : string  := "AFE3256";   -- 256*14=3584-50(dummy)=3534
-- constant GATE_IC       : string  := "RM76U89";   -- 512*9=4608-306(dummy)=4302
-- constant ROIC_MCLK_KHz : integer := 30000;
-- constant ROIC_DCLK_KHz : integer := 360000;
-- constant ROIC_DUAL     : integer := 1;
-- constant DDR3_ADDR_NUM : integer := 14; -- 14:4Gx2 13:2Gx2
-- constant DDR3_ADDR_14  : string  := "AA13";
-- constant GEV_SPEED     : string  := "10G";
-- launch_runs impl_EXT3643R -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT3643R/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

-- █▀▄ █ █▀█ █▀▀ █▀▀ ▀█▀
-- █▄▀ █ █▀▄ ██▄ █▄▄ ░█░
-- ### EXT810R ### -- direct type
--   constant MODEL         : string  := "EXT810R";
--   constant ROIC_IC       : string  := "AFE2256"; -- 256*8=2048
--   constant GATE_IC       : string  := "NT39530"; -- 256*6=1536
--   constant ROIC_MCLK_KHz : integer := 20000;
--   constant ROIC_DCLK_KHz : integer := 240000;
--   constant ROIC_DUAL     : integer := 1;
--   constant DDR3_ADDR_NUM : integer := 14;
--   constant DDR3_ADDR_14  : string  := "AA13";
--   constant GEV_SPEED     : string  := "2p5G";
-- ### EXT2430RD ### -- direct type #230619 --synth-24
--   constant MODEL         : string  := "EXT2430RD";
--   constant ROIC_IC       : string  := "AFE2256"; -- 256*14=3584
--   constant GATE_IC       : string  := "RM76U89"; -- 384*6=2304
--   constant ROIC_MCLK_KHz : integer := 20000;
--   constant ROIC_DCLK_KHz : integer := 240000;
--   constant ROIC_DUAL     : integer := 1;
--   constant DDR3_ADDR_NUM : integer := 14;
--   constant DDR3_ADDR_14  : string  := "AA13";
--   constant GEV_SPEED     : string  := "2p5G";
-- launch_runs impl_EXT2430RD -to_step write_bitstream -jobs 8
-- file copy -force /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.runs/impl_EXT2430RD/EXTREAM_TOP.sysdef /home/fpga0/work/EXTxR1FM/EXTREAM_TOP.sdk/EXTREAM_TOP.hdf

------------------------------------------------------------
    constant LOWV  : std_logic_vector(255 downto 0) := (others => '0');
    constant HIGHV : std_logic_vector(255 downto 0) := (others => '1');

    constant TPC_1418                 : string := "1418"; -- "1616" or "1418"
    function ilaswitch                (s : string) return string;
    -- ### debug ila on off
     constant ILA_ON                  : string := ilaswitch(SIMULATION);
    -- TOP
    constant GEN_ILA_top              : string := "OFF";
    constant GEN_ILA_top_roic         : string := "OFF";
    constant GEN_ILA_TOP_SPI          : string := "OFF";
    -- TI_TFT
    constant GEN_ILA_tft_data         : string := "OFF";
    constant GEN_ILA_tft_ctrl         : string := "OFF";
    constant GEN_ILA_roic_setting     : string := "OFF";
    constant GEN_ILA_lvds_serdes      : string := "OFF";
    constant GEN_ILA_lvds_rx          : string := "OFF";
    constant GEN_ILA_lvds_rx_2        : string := "OFF";
    constant GEN_ILA_data_align       : string := "OFF";
    constant GEN_ILA_roi              : string := "OFF";
    constant GEN_ILA_data_align_video : string := "OFF";
    constant GEN_ILA_gate_ctrl        : string := "OFF";
    -- DDR3
    constant GEN_ILA_ddr3_top         : string := "OFF";
    constant GEN_ILA_ddr_sync_gen     : string := "OFF";
    constant GEN_ILA_axi_if           : string := "OFF";
    constant GEN_ILA_axi_sub_if       : string := "OFF";
    constant GEN_ILA_axi_master_if    : string := "OFF";
    -- CALIB
    constant GEN_ILA_avg              : string := "OFF";
    constant GEN_ILA_claib_top        : string := "OFF";
    constant GEN_ILA_tpc_proc         : string := "OFF";
    constant GEN_ILA_defect_proc      : string := "OFF";
    constant GEN_ILA_defectline_proc  : string := "OFF";

    -- IMG_PROC
    constant GEN_2DDNR    : std_logic := '0';
    constant GEN_ACC      : std_logic := '0'; -- #210928
    constant GEN_DGAIN    : std_logic := '0'; -- $250321
    constant GEN_OSD      : std_logic := '0'; -- #220209
    constant GEN_EDGE     : std_logic := '1'; -- #230210
    constant GEN_BNC      : std_logic := '0'; -- #230904
    constant GEN_EQ       : std_logic := '0'; -- #230904
    constant GEN_DEFECT   : std_logic := '1'; -- $260122
    -- IMG_OUT
    constant GEN_ILA_img_out_top      : string := "OFF";
    -- Flash_ctrl
    constant GEN_ILA_SPI              : string := "OFF";

    constant GEN_SYNC_COUNTER         : string := ILA_ON;
    constant GEN_SM_PROBE             : string := ILA_ON;
    constant GEN_VIO_CLK_COUNTER      : std_logic := '0';
    constant GEN_VIO_SYNC_COUNTER0    : std_logic := '0'; -- video sync ila on
    constant GEN_VIO_SYNC_COUNTER1    : std_logic := '0'; -- video sync ila on //# 230919
    constant GEN_VIO_SYNC_COUNTER2    : std_logic := '0';

    constant CSYSCLKHZ              : integer := 100_000_000;
    constant MHz                    : integer := 1000000;
    constant KHz                    : integer := 1000;

    constant ADDR_OUT_EN            : std_logic_vector(15 downto 0) := x"0000";
    constant ADDR_WIDTH             : std_logic_vector(15 downto 0) := x"0004";
    constant ADDR_HEIGHT            : std_logic_vector(15 downto 0) := x"0008";
    constant ADDR_OFFSETX           : std_logic_vector(15 downto 0) := x"000C";
    constant ADDR_OFFSETY           : std_logic_vector(15 downto 0) := x"0010";
    constant ADDR_REV_X             : std_logic_vector(15 downto 0) := x"0014";
    constant ADDR_REV_Y             : std_logic_vector(15 downto 0) := x"0018";
    constant ADDR_TP_SEL            : std_logic_vector(15 downto 0) := x"001C";
    constant ADDR_TP_MODE           : std_logic_vector(15 downto 0) := x"0020";
    constant ADDR_TP_DTIME          : std_logic_vector(15 downto 0) := x"0024";
    constant ADDR_PWR_MODE          : std_logic_vector(15 downto 0) := x"0028";
    constant ADDR_GRAB_EN           : std_logic_vector(15 downto 0) := x"002C";
    constant ADDR_GATE_EN           : std_logic_vector(15 downto 0) := x"0030";
    constant ADDR_IMG_MODE          : std_logic_vector(15 downto 0) := x"0034";
    constant ADDR_RST_MODE          : std_logic_vector(15 downto 0) := x"0038";
    constant ADDR_TRIG_MODE         : std_logic_vector(15 downto 0) := x"003C";
    constant ADDR_TRIG_DELAY        : std_logic_vector(15 downto 0) := x"0040";
    constant ADDR_TRIG_VALID        : std_logic_vector(15 downto 0) := x"0044";
    constant ADDR_TRIG_FILT         : std_logic_vector(15 downto 0) := x"0048";
    constant ADDR_ROIC_CDS1         : std_logic_vector(15 downto 0) := x"004C";
    constant ADDR_OFFSET_CAL        : std_logic_vector(15 downto 0) := x"0050";
    constant ADDR_ROIC_INTRST       : std_logic_vector(15 downto 0) := x"0054";
    constant ADDR_GATE_OE           : std_logic_vector(15 downto 0) := x"0058";
    constant ADDR_GATE_XON          : std_logic_vector(15 downto 0) := x"005C";
    constant ADDR_GATE_XON_FLK      : std_logic_vector(15 downto 0) := x"0060";
    constant ADDR_GATE_FLK          : std_logic_vector(15 downto 0) := x"0064";
    constant ADDR_ROIC_DEAD         : std_logic_vector(15 downto 0) := x"0068";
    constant ADDR_ROIC_MUTE         : std_logic_vector(15 downto 0) := x"006C";
    constant ADDR_EXP_TIME          : std_logic_vector(15 downto 0) := x"0070";
    constant ADDR_FRAME_TIME        : std_logic_vector(15 downto 0) := x"0074";
    constant ADDR_FRAME_NUM         : std_logic_vector(15 downto 0) := x"0078";
    constant ADDR_ROIC_CDS2         : std_logic_vector(15 downto 0) := x"007C";
    constant ADDR_ROIC_RDATA        : std_logic_vector(15 downto 0) := x"0080";
    constant ADDR_DDR_CH3_WADDR     : std_logic_vector(15 downto 0) := x"0084";
    constant ADDR_DDR_CH3_RADDR     : std_logic_vector(15 downto 0) := x"0088";
    constant ADDR_EXT_EXP_TIME      : std_logic_vector(15 downto 0) := x"008C";
    constant ADDR_EXT_FRAME_TIME    : std_logic_vector(15 downto 0) := x"0090";
    constant ADDR_ROIC_EN           : std_logic_vector(15 downto 0) := x"0094";
    constant ADDR_ROIC_ADDR         : std_logic_vector(15 downto 0) := x"0098";
    constant ADDR_ROIC_WDATA        : std_logic_vector(15 downto 0) := x"009C";
    constant ADDR_REQ_ALIGN         : std_logic_vector(15 downto 0) := x"00A0";
    constant ADDR_OUT_MODE          : std_logic_vector(15 downto 0) := x"00A4";
    constant ADDR_DEBUG             : std_logic_vector(15 downto 0) := x"00A8";
    constant ADDR_DDR_CH_EN         : std_logic_vector(15 downto 0) := x"00AC";
    constant ADDR_DDR_BASE_ADDR     : std_logic_vector(15 downto 0) := x"00B0";
    constant ADDR_DDR_CH0_WADDR     : std_logic_vector(15 downto 0) := x"00B4";
    constant ADDR_DDR_CH0_RADDR     : std_logic_vector(15 downto 0) := x"00B8";
    constant ADDR_DDR_CH1_RADDR     : std_logic_vector(15 downto 0) := x"00BC";
    constant ADDR_DDR_CH2_RADDR     : std_logic_vector(15 downto 0) := x"00C0";
    constant ADDR_DDR_OUT           : std_logic_vector(15 downto 0) := x"00C4";
    constant ADDR_DEBUG_MODE        : std_logic_vector(15 downto 0) := x"00C8";
    constant ADDR_GAIN_CAL          : std_logic_vector(15 downto 0) := x"00CC";
    constant ADDR_DEFECT_CAL        : std_logic_vector(15 downto 0) := x"00D0";
    constant ADDR_DEFECT_WEN        : std_logic_vector(15 downto 0) := x"00D4";
    constant ADDR_DEFECT_ADDR       : std_logic_vector(15 downto 0) := x"00D8";
    constant ADDR_DEFECT_WDATA      : std_logic_vector(15 downto 0) := x"00DC";
    constant ADDR_DEFECT_RDATA      : std_logic_vector(15 downto 0) := x"00E0";
    constant ADDR_DGAIN             : std_logic_vector(15 downto 0) := x"00E4";
    constant ADDR_IPROC_MODE        : std_logic_vector(15 downto 0) := x"00E8";
    constant ADDR_DEFECT2_WEN       : std_logic_vector(15 downto 0) := x"00EC";
    constant ADDR_DEFECT2_ADDR      : std_logic_vector(15 downto 0) := x"00F0";
    constant ADDR_DEFECT2_WDATA     : std_logic_vector(15 downto 0) := x"00F4";
    constant ADDR_DEFECT2_RDATA     : std_logic_vector(15 downto 0) := x"00F8";
    constant ADDR_AVG_EN            : std_logic_vector(15 downto 0) := x"00FC";
    constant ADDR_AVG_LEVEL         : std_logic_vector(15 downto 0) := x"0100";
    constant ADDR_AVG_END           : std_logic_vector(15 downto 0) := x"0104";
    constant ADDR_DDR_CH1_WADDR     : std_logic_vector(15 downto 0) := x"0108";
    constant ADDR_FPGA_VER          : std_logic_vector(15 downto 0) := x"010C";
    constant ADDR_ROIC_DONE         : std_logic_vector(15 downto 0) := x"0110";
    constant ADDR_ALIGN_DONE        : std_logic_vector(15 downto 0) := x"0114";
    constant ADDR_CALIB_DONE        : std_logic_vector(15 downto 0) := x"0118";
    constant ADDR_PWR_DONE          : std_logic_vector(15 downto 0) := x"011C";
    constant ADDR_SHUTTER_MODE      : std_logic_vector(15 downto 0) := x"0120";
    constant ADDR_I2C_WEN           : std_logic_vector(15 downto 0) := x"0124";
    constant ADDR_I2C_WSIZE         : std_logic_vector(15 downto 0) := x"0128";
    constant ADDR_I2C_WDATA         : std_logic_vector(15 downto 0) := x"012C";
    constant ADDR_I2C_REN           : std_logic_vector(15 downto 0) := x"0130";
    constant ADDR_I2C_RSIZE         : std_logic_vector(15 downto 0) := x"0134";
    constant ADDR_I2C_RDATA0        : std_logic_vector(15 downto 0) := x"0138";
    constant ADDR_I2C_RDATA1        : std_logic_vector(15 downto 0) := x"013C";
    constant ADDR_I2C_MODE          : std_logic_vector(15 downto 0) := x"0140";
    constant ADDR_I2C_DONE          : std_logic_vector(15 downto 0) := x"0144";
    constant ADDR_ROIC_SYNC_ACLK    : std_logic_vector(15 downto 0) := x"0148";
    constant ADDR_FRAME_VAL         : std_logic_vector(15 downto 0) := x"014C";
    constant ADDR_ROIC_FA           : std_logic_vector(15 downto 0) := x"0150";
    constant ADDR_API_EXT_TRIG      : std_logic_vector(15 downto 0) := x"0154";
    constant ADDR_ROIC_SYNC_DCLK    : std_logic_vector(15 downto 0) := x"0158";
    constant ADDR_ROIC_AFE_DCLK     : std_logic_vector(15 downto 0) := x"015C";
    constant ADDR_GATE_RST_CYCLE    : std_logic_vector(15 downto 0) := x"0160";
    constant ADDR_TEMP_EN           : std_logic_vector(15 downto 0) := x"0164";
    constant ADDR_DEVICE_TEMP       : std_logic_vector(15 downto 0) := x"0168";
    constant ADDR_ROIC_SHAAZEN      : std_logic_vector(15 downto 0) := x"016C";
    constant ADDR_TIMING_MODE       : std_logic_vector(15 downto 0) := x"0170";
    constant ADDR_GRAB_DONE         : std_logic_vector(15 downto 0) := x"0174";
    constant ADDR_LDEFECT_CAL       : std_logic_vector(15 downto 0) := x"0178";
    constant ADDR_RDEFECT_WEN       : std_logic_vector(15 downto 0) := x"017C";
    constant ADDR_RDEFECT_ADDR      : std_logic_vector(15 downto 0) := x"0180";
    constant ADDR_RDEFECT_WDATA     : std_logic_vector(15 downto 0) := x"0184";
    constant ADDR_RDEFECT_RDATA     : std_logic_vector(15 downto 0) := x"0188";
    constant ADDR_CDEFECT_WEN       : std_logic_vector(15 downto 0) := x"0190";
    constant ADDR_CDEFECT_ADDR      : std_logic_vector(15 downto 0) := x"0194";
    constant ADDR_CDEFECT_WDATA     : std_logic_vector(15 downto 0) := x"0198";
    constant ADDR_CDEFECT_RDATA     : std_logic_vector(15 downto 0) := x"019C";
    constant ADDR_LINE_TIME         : std_logic_vector(15 downto 0) := x"01A0";
    constant ADDR_DDR_CH2_WADDR     : std_logic_vector(15 downto 0) := x"01A4";
    constant ADDR_SD_WEN            : std_logic_vector(15 downto 0) := x"01A8";
    constant ADDR_SD_REN            : std_logic_vector(15 downto 0) := x"01AC";
    constant ADDR_SD_ADDR           : std_logic_vector(15 downto 0) := x"01B0";
    constant ADDR_SD_RW_END         : std_logic_vector(15 downto 0) := x"01B4";
    constant ADDR_DEFECT_MAP        : std_logic_vector(15 downto 0) := x"01B8";
    constant ADDR_ROIC_TEMP0        : std_logic_vector(15 downto 0) := x"01BC";
    constant ADDR_ROIC_TEMP1        : std_logic_vector(15 downto 0) := x"01C0";
    constant ADDR_ROIC_TEMP2        : std_logic_vector(15 downto 0) := x"01C4";
    constant ADDR_ROIC_TEMP3        : std_logic_vector(15 downto 0) := x"01C8";
    constant ADDR_ROIC_TEMP4        : std_logic_vector(15 downto 0) := x"01CC";
    constant ADDR_ROIC_TEMP5        : std_logic_vector(15 downto 0) := x"01D0";
    constant ADDR_ROIC_TEMP6        : std_logic_vector(15 downto 0) := x"01D4";
    constant ADDR_ROIC_TEMP7        : std_logic_vector(15 downto 0) := x"01D8";
    constant ADDR_ROIC_TEMP8        : std_logic_vector(15 downto 0) := x"01DC";
    constant ADDR_ROIC_TEMP9        : std_logic_vector(15 downto 0) := x"01E0";
    constant ADDR_ROIC_TEMP10       : std_logic_vector(15 downto 0) := x"01E4";
    constant ADDR_ROIC_TEMP11       : std_logic_vector(15 downto 0) := x"01E8";
    constant ADDR_MPC_NUM           : std_logic_vector(15 downto 0) := x"01EC";
    constant ADDR_MPC_POINT0        : std_logic_vector(15 downto 0) := x"01F0";
    constant ADDR_MPC_POINT1        : std_logic_vector(15 downto 0) := x"01F4";
    constant ADDR_MPC_POINT2        : std_logic_vector(15 downto 0) := x"01F8";
    constant ADDR_MPC_POINT3        : std_logic_vector(15 downto 0) := x"01FC";
    constant ADDR_RST_NUM           : std_logic_vector(15 downto 0) := x"0200";
    constant ADDR_BRIGHT            : std_logic_vector(15 downto 0) := x"0204";
    constant ADDR_CONTRAST          : std_logic_vector(15 downto 0) := x"0208";
    constant ADDR_EXT_TRIG_HIGH     : std_logic_vector(15 downto 0) := x"020C";
    constant ADDR_EXT_TRIG_PERIOD   : std_logic_vector(15 downto 0) := x"0210";
    constant ADDR_EXT_TRIG_ACTIVE   : std_logic_vector(15 downto 0) := x"0214";
    constant ADDR_FW_BUSY           : std_logic_vector(15 downto 0) := x"0218";
    constant ADDR_SEXP_TIME         : std_logic_vector(15 downto 0) := x"021C";
    constant ADDR_ERASE_EN          : std_logic_vector(15 downto 0) := x"0220";
    constant ADDR_ERASE_TIME        : std_logic_vector(15 downto 0) := x"0224";
    constant ADDR_ERASE_DONE        : std_logic_vector(15 downto 0) := x"0228";
    constant ADDR_ROIC_TP_SEL       : std_logic_vector(15 downto 0) := x"022C";
    constant ADDR_CLK_MCLK          : std_logic_vector(15 downto 0) := x"0230";
    constant ADDR_CLK_DCLK          : std_logic_vector(15 downto 0) := x"0234";
    constant ADDR_CLK_ROICDCLK      : std_logic_vector(15 downto 0) := x"0238";
    constant ADDR_MPC_CTRL          : std_logic_vector(15 downto 0) := x"023C"; -- substract ref0 img -- mbh 210222
    constant ADDR_FLA_CTRL          : std_logic_vector(15 downto 0) := x"0240";
    constant ADDR_FLA_ADDR          : std_logic_vector(15 downto 0) := x"0244";
    constant ADDR_FLA_DATA          : std_logic_vector(15 downto 0) := x"0248";
    constant ADDR_SYNC_CTRL         : std_logic_vector(15 downto 0) := x"024C";
    constant ADDR_I2C_RDATA2        : std_logic_vector(15 downto 0) := x"0250";
    constant ADDR_I2C_RDATA3        : std_logic_vector(15 downto 0) := x"0254";
    constant ADDR_SYNC_RCNT0        : std_logic_vector(15 downto 0) := x"0258";
    constant ADDR_SYNC_RCNT1        : std_logic_vector(15 downto 0) := x"025C";
    constant ADDR_SYNC_RCNT2        : std_logic_vector(15 downto 0) := x"0260";
    constant ADDR_SYNC_RCNT3        : std_logic_vector(15 downto 0) := x"0264";
    constant ADDR_SYNC_RCNT4        : std_logic_vector(15 downto 0) := x"0268";
    constant ADDR_SYNC_RCNT5        : std_logic_vector(15 downto 0) := x"026C";
    constant ADDR_SYNC_RCNT6        : std_logic_vector(15 downto 0) := x"0270";
    constant ADDR_SYNC_RCNT7        : std_logic_vector(15 downto 0) := x"0274";
    constant ADDR_SYNC_RCNT8        : std_logic_vector(15 downto 0) := x"0278";
    constant ADDR_SYNC_RCNT9        : std_logic_vector(15 downto 0) := x"027C";
    constant ADDR_SYNC_RDATA_AVCN0  : std_logic_vector(15 downto 0) := x"0280";
    constant ADDR_SYNC_RDATA_AVCN1  : std_logic_vector(15 downto 0) := x"0284";
    constant ADDR_SYNC_RDATA_AVCN2  : std_logic_vector(15 downto 0) := x"0288";
    constant ADDR_SYNC_RDATA_AVCN3  : std_logic_vector(15 downto 0) := x"028C";
    constant ADDR_SYNC_RDATA_AVCN4  : std_logic_vector(15 downto 0) := x"0290";
    constant ADDR_SYNC_RDATA_AVCN5  : std_logic_vector(15 downto 0) := x"0294";
    constant ADDR_SYNC_RDATA_AVCN6  : std_logic_vector(15 downto 0) := x"0298";
    constant ADDR_SYNC_RDATA_AVCN7  : std_logic_vector(15 downto 0) := x"029C";
    constant ADDR_SYNC_RDATA_AVCN8  : std_logic_vector(15 downto 0) := x"0300";
    constant ADDR_SYNC_RDATA_AVCN9  : std_logic_vector(15 downto 0) := x"0304";
    constant ADDR_SYNC_RDATA_BGLW0  : std_logic_vector(15 downto 0) := x"0308";
    constant ADDR_SYNC_RDATA_BGLW1  : std_logic_vector(15 downto 0) := x"030C";
    constant ADDR_SYNC_RDATA_BGLW2  : std_logic_vector(15 downto 0) := x"0310";
    constant ADDR_SYNC_RDATA_BGLW3  : std_logic_vector(15 downto 0) := x"0314";
    constant ADDR_SYNC_RDATA_BGLW4  : std_logic_vector(15 downto 0) := x"0318";
    constant ADDR_SYNC_RDATA_BGLW5  : std_logic_vector(15 downto 0) := x"031C";
    constant ADDR_SYNC_RDATA_BGLW6  : std_logic_vector(15 downto 0) := x"0320";
    constant ADDR_SYNC_RDATA_BGLW7  : std_logic_vector(15 downto 0) := x"0324";
    constant ADDR_SYNC_RDATA_BGLW8  : std_logic_vector(15 downto 0) := x"0328";
    constant ADDR_SYNC_RDATA_BGLW9  : std_logic_vector(15 downto 0) := x"032C";

    constant ADDR_SM_CTRL   : std_logic_vector(15 downto 0) := x"0330";
    constant ADDR_SM_DATA0  : std_logic_vector(15 downto 0) := x"0334";
    constant ADDR_SM_DATA1  : std_logic_vector(15 downto 0) := x"0338";
    constant ADDR_SM_DATA2  : std_logic_vector(15 downto 0) := x"033C";
    constant ADDR_SM_DATA3  : std_logic_vector(15 downto 0) := x"0340";
    constant ADDR_SM_DATA4  : std_logic_vector(15 downto 0) := x"0344";
    constant ADDR_SM_DATA5  : std_logic_vector(15 downto 0) := x"0348";
    constant ADDR_SM_DATA6  : std_logic_vector(15 downto 0) := x"034C";
    constant ADDR_SM_DATA7  : std_logic_vector(15 downto 0) := x"0350";
    constant ADDR_CLK_UICLK : std_logic_vector(15 downto 0) := x"0354";
    -- reseved space
    constant ADDR_BCAL_CTRL  : std_logic_vector(15 downto 0) := x"03A0";
    constant ADDR_BCAL_DATA  : std_logic_vector(15 downto 0) := x"03A4";

    constant ADDR_MPC_POSOFFSET  : std_logic_vector(15 downto 0) := x"03B0";

    constant ADDR_FLAW_CTRL   : std_logic_vector(15 downto 0) := x"03B4";
    constant ADDR_FLAW_CMD    : std_logic_vector(15 downto 0) := x"03B8";
    constant ADDR_FLAW_ADDR   : std_logic_vector(15 downto 0) := x"03BC";
    constant ADDR_FLAW_WDATA  : std_logic_vector(15 downto 0) := x"03C0";
    constant ADDR_FLAW_RDATA  : std_logic_vector(15 downto 0) := x"03C4";

    constant ADDR_D2M_EN         : std_logic_vector(15 downto 0) := x"03C8";
    constant ADDR_D2M_EXP_IN     : std_logic_vector(15 downto 0) := x"03CC";
    constant ADDR_D2M_SEXP_TIME  : std_logic_vector(15 downto 0) := x"03D0";
    constant ADDR_D2M_FRAME_TIME : std_logic_vector(15 downto 0) := x"03D4";
    constant ADDR_D2M_XRST_NUM   : std_logic_vector(15 downto 0) := x"03D8";
    constant ADDR_D2M_DRST_NUM   : std_logic_vector(15 downto 0) := x"03DC";

    constant ADDR_TOPRST_CTRL   : std_logic_vector(15 downto 0) := x"03E0";

    constant ADDR_DNR_CTRL          : std_logic_vector(15 downto 0) := x"03E4";
    constant ADDR_DNR_SOBELCOEFF0   : std_logic_vector(15 downto 0) := x"03E8";
    constant ADDR_DNR_SOBELCOEFF1   : std_logic_vector(15 downto 0) := x"03EC";
    constant ADDR_DNR_SOBELCOEFF2   : std_logic_vector(15 downto 0) := x"03F0";
    constant ADDR_DNR_BLUROFFSET    : std_logic_vector(15 downto 0) := x"03F4";
--  constant                        : std_logic_vector(15 downto 0) := x"03F8";

    constant ADDR_ACC_STAT          : std_logic_vector(15 downto 0) := x"03FC";
    constant ADDR_ACC_CTRL          : std_logic_vector(15 downto 0) := x"0400";
    constant ADDR_DDR_CH4_WADDR     : std_logic_vector(15 downto 0) := x"0404";
    constant ADDR_DDR_CH4_RADDR     : std_logic_vector(15 downto 0) := x"0408";

    constant ADDR_EXT_TRIG_EN       : std_logic_vector(15 downto 0) := x"040C";
    constant ADDR_FRAME_CNT         : std_logic_vector(15 downto 0) := x"0410";

    constant ADDR_EXT_RST_MODE      : std_logic_vector(15 downto 0) := x"0414";
    constant ADDR_EXT_RST_DetTime   : std_logic_vector(15 downto 0) := x"0418";
    constant ADDR_LED_CTRL          : std_logic_vector(15 downto 0) := x"041C";
    constant ADDR_TRIGCNT           : std_logic_vector(15 downto 0) := x"0420";
    constant ADDR_OSD_CTRL          : std_logic_vector(15 downto 0) := x"0424";

    constant ADDR_PWDAC_CMD         : std_logic_vector(15 downto 0) := x"0428";
    constant ADDR_PWDAC_TICKTIME    : std_logic_vector(15 downto 0) := x"042c";
    constant ADDR_PWDAC_TICKINC     : std_logic_vector(15 downto 0) := x"0430";
    constant ADDR_PWDAC_TRIG        : std_logic_vector(15 downto 0) := x"0434";
    constant ADDR_PWDAC_CURRLEVEL   : std_logic_vector(15 downto 0) := x"0438";
    constant ADDR_FPGA_DATE         : std_logic_vector(15 downto 0) := x"043C"; --# 221104

    constant ADDR_TESTPOINT1        : std_logic_vector(15 downto 0) := x"0440";
    constant ADDR_TESTPOINT2        : std_logic_vector(15 downto 0) := x"0444";
    constant ADDR_TESTPOINT3        : std_logic_vector(15 downto 0) := x"0448";
    constant ADDR_TESTPOINT4        : std_logic_vector(15 downto 0) := x"044C";
--# 220901 roic str
    constant ADDR_ROIC_STR          : std_logic_vector(15 downto 0) := x"0450";
--# 221122 freerun cnt
    constant ADDR_FREERUN_CNT       : std_logic_vector(15 downto 0) := x"0454";
--# 230213 edge
    constant ADDR_EDGE_CTRL       : std_logic_vector(15 downto 0) := x"0458";
    constant ADDR_EDGE_VALUE      : std_logic_vector(15 downto 0) := x"045C";
    constant ADDR_EDGE_TOP        : std_logic_vector(15 downto 0) := x"0460";
    constant ADDR_EDGE_LEFT       : std_logic_vector(15 downto 0) := x"0464";
    constant ADDR_EDGE_RIGHT      : std_logic_vector(15 downto 0) := x"0468";
    constant ADDR_EDGE_BOTTOM     : std_logic_vector(15 downto 0) := x"046C";

    constant ADDR_TP_VALUE        : std_logic_vector(15 downto 0) := x"0470";

    constant ADDR_BNC_CTRL        : std_logic_vector(15 downto 0) := x"0474"; --# 230721
    constant ADDR_BNC_HIGH        : std_logic_vector(15 downto 0) := x"0478";
--    constant ADDR_                : std_logic_vector(15 downto 0) := x"047C";
    constant ADDR_OFGA_LIM        : std_logic_vector(15 downto 0) := x"0480"; --# 230725

    constant ADDR_EQ_CTRL         : std_logic_vector(15 downto 0) := x"0484"; --# 230817
    constant ADDR_EQ_TOPVAL       : std_logic_vector(15 downto 0) := x"0488"; --# 230817
--# 221110 fpga reboot
    constant ADDR_FPGA_REBOOT       : std_logic_vector(15 downto 0) := x"1000";

    -- ##### REG END #####
    function ROIC_BY_MODEL          (s : string) return string;
    function GATE_BY_MODEL          (s : string) return string;
    function ROIC_MCLK_BY_MODEL     (s : string) return integer;
    function ROIC_DCLK_BY_MODEL     (s : string) return integer;
    function GEV_SPEED_BY_MODEL     (s : string) return string;
    function ROIC_DUAL_BY_MODEL     (s : string) return integer;

    function MAX_WIDTH              (s : string) return integer;
    function MAX_HEIGHT             (s : string) return integer;
    function PIXEL_DEPTH            (s : string) return integer;
    function ROIC_DUMMY_LINE        (s : string) return integer;
    function ROIC_MAX_CH            (s : string) return integer;
    function ROIC_CH                (s : string) return integer;
    function ROIC_DUMMY_CH          (s : string) return integer;
    function ROIC_NUM               (s : string) return integer;
    function ROIC_DCLK_NUM          (s : string) return integer;
    function ROIC_FCLK_NUM          (s : string) return integer;
    function ROIC_NUM2              (s : string) return integer;
    function ROIC_NUM2_REG          (s : string) return integer;
--  function ROIC_BURST             (s : string) return integer;
--  function ROIC_BURST_NUM         (s : string) return integer;
--  function ROIC_SHAAZEN           (s : string) return integer;
--  function ROIC_MUTE              (s : string) return integer;
--  function ROIC_AFE_DCLK          (s : string) return integer;
    function ROIC_SPI_NUM           (s : string) return integer;
    function ROIC_MCLK_NUM          (s : string) return integer;
    function ROIC_SCLK_NUM          (s : string) return integer;
    function ROIC_SDI_NUM           (s : string) return integer;

    function GATE_CH                (s : string) return integer;
    function GATE_MAX_CH            (s : string) return integer;
    function GATE_NUM               (s : string) return integer;
    function GATE_NUM2              (s : string) return integer;
    function GATE_DUMMY_LINE        (s : string) return integer;
    function GATE_CONFIG_NUM        (s : string) return integer;
    function GATE_CPV_PERIOD        (s : string) return integer;

    function PWR_NUM                (s : string) return integer;
    function FUNC_ADC_REV           (s : string) return std_logic;
    function FUNC_H_FLIP            (s : string) return std_logic;
    function FUNC_BIT_ALIGN         (s : string) return std_logic;
    function FUNC_MODEL_NAME        (s : string) return integer;  -- std_logic_vector(12-1 downto 0); -- _vector(8-1 downto 0);

    function PARA_PIX               (s : string) return integer;
    function DDR_BIT_W0             (s : string) return integer;
    function DDR_BIT_W1             (s : string) return integer;
    function DDR_BIT_W2             (s : string) return integer;
    function DDR_BIT_W3             (s : string) return integer;
    function DDR_BIT_W4             (s : string) return integer;
    function DDR_BIT_R0             (s : string) return integer;
    function DDR_BIT_R1             (s : string) return integer;
    function DDR_BIT_R2             (s : string) return integer;
    function DDR_BIT_R3             (s : string) return integer;
    function DDR_BIT_R4             (s : string) return integer;
    function DDR_BY_MODEL           (s : string) return integer;
    function DDR_DM                 (s : string) return integer;
    function DDR_DQS                (s : string) return integer;
    function DDR_DQ                 (s : string) return integer;
    function DDR_AXI2               (s : string) return integer;

    function ROIC_SYNC_DCLK           (s : string) return integer;
    function ROIC_SYNC_ACLK           (s : string) return integer;
    function ROIC_DEAD                (s : string) return integer;
    function ROIC_FA                  (s : string) return integer;
    function ROIC_CDS1                (s : string) return integer;
    function ROIC_CDS2                (s : string) return integer;
    function ROIC_INTRST              (s : string) return integer;
    function GATE_OE                  (s : string) return integer;
    function GATE_XON                 (s : string) return integer;
    function GATE_XON_FLK             (s : string) return integer;
    function GATE_FLK                 (s : string) return integer;
    function GATE_DIO_CPV             (s : string) return integer;
    function GATE_TRST_PERIOD         (s : string) return integer;
    function GATE_ERASE               (s : string) return integer;
    function T_1MS                    (s : string) return integer;
    function T_1US                    (s : string) return integer;
    function T_10S                    (s : string) return integer;
--  function ROIC_A3_A4_MIN           (s : string) return integer;
--  function ADAS1255_SHAAZEN         (s : string) return integer;
--  function ADAS1255_MUTE            (s : string) return integer;
--  function ADAS1255_AFE_DCLK        (s : string) return integer;
--  function ADAS1258_SHAAZEN         (s : string) return integer;
--  function ADAS1258_MUTE            (s : string) return integer;
--  function ADAS1258_AFE_DCLK        (s : string) return integer;
    function NT39530_CPV_PERIOD       (s : string) return integer;
    function NT39565_CPV_PERIOD       (s : string) return integer;
    function NT61303_CPV_PERIOD       (s : string) return integer;
    function RM76U89_CPV_PERIOD       (s : string) return integer;
    function HX8698_CPV_PERIOD        (s : string) return integer;
    function EXT_TRIG_DEBO_PERIOD     (s : string) return integer;
    function EXT_TRIG_DEBO_PERIOD_SIM (s : string) return integer;
    function SIM_GATE_XON             (s : string) return integer;
    function SIM_GATE_XON_FLK         (s : string) return integer;
    function SIM_GATE_FLK             (s : string) return integer;
    function SIM_GATE_TRST_PERIOD     (s : string) return integer;
    function SIM_GATE_ERASE           (s : string) return integer;
    --# 260320 FUNC_SFP replaced: return integer (1=ON, 0=OFF/null array)
    function FUNC_SFP_NUM             (s : string) return integer;

--    constant GLB_H_FLIP : std_logic := FUNC_H_FLIP(MODEL);

--    type tdata_par                  is array (0 to ROIC_NUM(MODEL)-1) of std_logic_vector(15 downto 0);

    -- Variable Value
    constant ROIC_PIPELINE          : string := "OFF";
--  constant ROIC_SYNC_DCLK         : integer := ( 100  * ROIC_DCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ROIC_SYNC_ACLK         : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ROIC_DEAD              : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ROIC_FA                : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ROIC_CDS1              : integer := (4000  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ROIC_CDS2              : integer := (6500  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ROIC_INTRST            : integer := (1500  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant GATE_OE                : integer := (1700  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant GATE_XON               : integer := ( 340  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)
--  constant GATE_XON_FLK           : integer := (  50  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)
--  constant GATE_FLK               : integer := ( 150  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)
--  constant GATE_DIO_CPV           : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant GATE_TRST_PERIOD       : integer := (  10  * ROIC_MCLK_BY_MODEL(GNR_MODEL));           -- 1E-3 / 1E+0 = 1E-3 (ms)
--  constant GATE_ERASE             : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL));           -- 1E-3 / 1E+0 = 1E-3 (ms)
--  constant T_1MS                  : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL));           -- 1E-3 / 1E+0 = 1E-3 (ms)
--  constant T_1US                  : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-6 / 1E+0 = 1E-6 (us)
--  constant T_10S                  : integer := (  10  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) * KHz;     -- 1E-3 * 1E+3 = 1E+0 ( s)
--### no use
--  constant ROIC_A3_A4_MIN         : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)

    -- Fixed Value
--  constant ADAS1255_SHAAZEN       : integer := 0;
--  constant ADAS1255_MUTE          : integer := (1445  * ROIC_DCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ADAS1255_AFE_DCLK      : integer := (1640  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ADAS1258_SHAAZEN       : integer := (1000  * ROIC_DCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ADAS1258_MUTE          : integer := ( 140  * ROIC_DCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant ADAS1258_AFE_DCLK      : integer := ( 450  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)

--  constant NT39530_CPV_PERIOD     : integer := (5000  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant NT39565_CPV_PERIOD     : integer := (3600  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns) -- test 210615 mbh
--  constant NT61303_CPV_PERIOD     : integer := (2880  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant RM76U89_CPV_PERIOD     : integer := (0500  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant HX8698_CPV_PERIOD      : integer := (2860  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant EXT_TRIG_DEBO_PERIOD     : integer := ( 100000   * ROIC_MCLK_BY_MODEL(s)) / MHz;   -- 1E-3 / 1E+6 = 1E-9 (ns)
--  constant EXT_TRIG_DEBO_PERIOD_SIM : integer := (   1000   * ROIC_MCLK_BY_MODEL(s)) / MHz;   -- 1E-3 / 1E+6 = 1E-9 (ns)

    -- x0.01
--  constant SIM_GATE_XON           : integer := GATE_XON(s)         / 100;
--  constant SIM_GATE_XON_FLK       : integer := GATE_XON_FLK(s)     / 100;
--  constant SIM_GATE_FLK           : integer := GATE_FLK(s)         / 100;
--  constant SIM_GATE_TRST_PERIOD   : integer := GATE_TRST_PERIOD(s) / 100;
--  constant SIM_GATE_ERASE         : integer := GATE_ERASE(s)       / 100;

--    constant INIT_PWDAC_LEVEL    : std_logic_vector(12-1 downto 0) := conv_std_logic_vector(621,12); -- 0.5v
    constant INIT_PWDAC_LEVEL    : std_logic_vector(12-1 downto 0) := conv_std_logic_vector(124,12); -- 0.1v
--    constant INIT_PWDAC_LEVEL    : std_logic_vector(12-1 downto 0) := conv_std_logic_vector(931,12); -- 0.75v
    -- 20M(Hz) * 5(sec) / 621 (step)
    constant INIT_PWDAC_TICKTIME : std_logic_vector(32-1 downto 0) := conv_std_logic_vector(161031,32); -- 5sec
    constant INIT_PWDAC_TICKINC  : std_logic_vector(12-1 downto 0) := x"000"; -- 1

    constant SAFEZONE_MIN           : integer := 10; --# bcal minimum safe time at TI_LVDS_RX 220610
    constant REF_CLK                : real := 200.0;

    constant G2p5_DDR_BIT_W0 : integer := 64; -- roic in
    constant G2p5_DDR_BIT_W1 : integer := 32; -- x
    constant G2p5_DDR_BIT_W2 : integer := 32; -- avg
    constant G2p5_DDR_BIT_W3 : integer := 32; -- ofs
    constant G2p5_DDR_BIT_W4 : integer := 16; -- acc

    constant G10p_DDR_BIT_W0 : integer := 64;
    constant G10p_DDR_BIT_W1 : integer := 64;
    constant G10p_DDR_BIT_W2 : integer := 64;
    constant G10p_DDR_BIT_W3 : integer := 64;
    constant G10p_DDR_BIT_W4 : integer := 64;

    constant G2p5_DDR_BIT_R0 : integer := 16;  -- roic
    constant G2p5_DDR_BIT_R1 : integer := 128; -- gain
    constant G2p5_DDR_BIT_R2 : integer := 32;  -- avg
    constant G2p5_DDR_BIT_R3 : integer := 32;  -- offset
    constant G2p5_DDR_BIT_R4 : integer := 16;  -- acc

    constant G10p_DDR_BIT_R0 : integer := 64;
--    constant G10p_DDR_BIT_R1 : integer := 64;
    constant G10p_DDR_BIT_R1 : integer := 128; --# 230201
    constant G10p_DDR_BIT_R2 : integer := 64;
    constant G10p_DDR_BIT_R3 : integer := 64;
    constant G10p_DDR_BIT_R4 : integer := 64;

    constant DDR_DM_2    : integer := 4;
    constant DDR_DQS_2   : integer := 4;
    constant DDR_DQ_2    : integer := 32;
    constant DDR_AXI2_2  : integer := 4;
    
    constant DDR_DM_4    : integer := 8;
    constant DDR_DQS_4   : integer := 8;
    constant DDR_DQ_4    : integer := 64;
    constant DDR_AXI2_4  : integer := 6;
    
    type tstate_grab            is (
                                        s_IDLE,         -- 0
                                        s_DATA,         -- 1
                                        s_WAIT          -- 2
                                    );

    type tstate_tft             is (
                                        s_IDLE,         -- 0
                                        s_TRST,         -- 1
                                        s_SRST,         -- 2
                                        s_EWT,          -- 3
                                        s_SCAN,         -- 4
                                        s_FINISH,       -- 5
                                        s_GRST,         -- 6
                                        s_RstFINISH,    -- 7
                                        s_ScanFrWait,   -- 8
                                        s_RstFrWait,    -- 9
                                        s_SRST_EWT,     -- A --# 240415
                                        s_B,            -- B
                                        s_C,            -- C
                                        s_D,            -- D
                                        s_Trig,         -- E
                                        s_F             -- F
                                    );

    type tstate_roic            is (
                                        s_IDLE,         -- 0 0
                                        s_OFFSET,       -- 1 1
                                        s_DUMMY,        -- 2 2
                                        s_INTRST,       -- 4 3
                                        s_CDS1,         -- 5 4
                                        s_GATE_OPEN,    -- 6 5
                                        s_CDS2,         -- 7 6
                                        s_LDEAD,        -- 8 7
                                        s_FWAIT         -- 9 8
                                    );

    type tstate_gate            is (
                                        s_IDLE,         -- 0
                                        s_DUMMY,        -- 1
                                        s_READY,        -- 2
                                        s_DIO_CPV,      -- 3
                                        s_CPV,          -- 4
                                        s_XON,          -- 5
                                        s_OE,           -- 6
                                        s_XON_FLK,      -- 7
                                        s_FLK,          -- 8
                                        s_CHECK,        -- 9
                                        s_OE_READY,     -- A
                                        s_LWAIT,        -- B
                                        s_FWAIT,        -- C
                                        s_GRST_G,
                                        s_GRST_GEnd
                                    );

    type tstate_roic_setting    is (
                                        s_IDLE,
                                        s_READY,
                                        s_CS,
                                        s_DATA,
                                        s_WAIT,
                                        s_FINISH
                                    );
    type tstate_align_ctrl is (
        s_IDLE,
        s_ALIGN,
        s_WAIT,
        s_CHECK
    );
    type tstate_dpram_data_align is (
        s_IDLE,
        s_READY,
        s_WAIT_ODD,
        s_DATA_ODD,
        s_WAIT_EVEN,
        s_DATA_EVEN
    );

    type tstate_dpram_roi       is (
                                        s_IDLE,
                                        s_WAIT,
                                        s_DATA
                                    );

    type tstate_data_tpat           is (
                                        s_IDLE,
                                        s_DATA,
                                        s_LWAIT,
                                        s_FWAIT
                                    );
    type tstate_sync_ddr        is  (
                                    s_IDLE,
                                    s_DATA,
                                    s_LWAIT,
                                    s_FWAIT
                                );
    type tstate_ddr_sub is (
        s_IDLE,
        s_READY,
        s_WRITE,
        s_WRESP,
        s_READ,
        s_WCHECK,
        s_RCHECK,
        s_FINISH
    );
    type tstate_write is (
        s_IDLE,
        s_READY,
        s_WAIT,
        s_WRITE,
        s_CHECK
    );

    type tstate_read is (
        s_IDLE,
        s_READY,
        s_WAIT,
        s_READ,
        s_CHECK
    );

    type tstate_write_ddr_mast  is  (
                                s_IDLE,
                                s_READY,
                                s_ADDR,
                                s_DATA,
                                s_CHECK,
                                s_BRESP
                            );

    type tstate_read_ddr_mast   is  (
                                s_IDLE,
                                s_START,
                                s_READ,
                                s_CHECK
                            );

    type type_state_d2m is (
        sm_idle,
        sm_d2m_xray_start,
        sm_d2m_xray,
        sm_d2m_xrayrst,
        sm_d2m_dark_start,
        sm_d2m_dark,
        sm_d2m_darkrst,
        sm_d2m_end
    );

    type tstate_avg             is  (
                                        s_IDLE,
                                        s_FWAIT,
                                        s_LWAIT,
                                        s_WAIT,
                                        s_READY,
                                        s_AVG,
                                        s_CHECK
                                    );

end TOP_HEADER;

PACKAGE BODY TOP_HEADER is
--####################
--##### BY MODEL #####
    function ROIC_BY_MODEL (s : string) return string is
        variable val : string(1 to 7);
    begin
           if(s = "EXT4343RD"  ) then val := "AFE3256";
        elsif(s = "EXT3643R"   ) then val := "AFE3256";
        else                          val := "AFE2256";
        end if;
        return (val);
    end ROIC_BY_MODEL;

    function GATE_BY_MODEL (s : string) return string is
        variable val : string(1 to 8);
    begin
        if(SIMULATION = "ON") then
            val :=  "RM76U89 ";
        else
               if(s = "EXT1024R"    ) then val := "RM76U89 "; -- jyp 241010
            elsif(s = "EXT1616R"    ) then val := "RM76U89 ";
            elsif(s = "EXT2430R"    ) then val := "RM76U89 ";
            elsif(s = "EXT2832R"    ) then val := "RM76U89 ";
            elsif(s = "EXT2832R_2"  ) then val := "RM76U89 ";
            elsif(s = "EXT4343R"    ) then val := "HX8698  ";
            elsif(s = "EXT4343R_1"  ) then val := "RM76U89 ";
            elsif(s = "EXT4343R_2"  ) then val := "RM76U89 ";
            elsif(s = "EXT4343R_3"  ) then val := "NT39530 ";
            elsif(s = "EXT4343R_4"  ) then val := "RM76U89 ";
            elsif(s = "EXT4343RC"   ) then val := "NT39565D";
            elsif(s = "EXT4343RC_1" ) then val := "RM76U89 ";
            elsif(s = "EXT4343RC_2" ) then val := "RM76U89 ";
            elsif(s = "EXT4343RC_3" ) then val := "NT39530 ";
            elsif(s = "EXT2430RI"   ) then val := "RM76U89 ";
            elsif(s = "EXT4343RI_2" ) then val := "RM76U89 ";
            elsif(s = "EXT4343RI_4" ) then val := "RM76U89 ";
            elsif(s = "EXT4343RCI_1") then val := "RM76U89 ";
            elsif(s = "EXT4343RCI_2") then val := "RM76U89 ";
            elsif(s = "EXT810R"     ) then val := "NT39530 ";
            elsif(s = "EXT2430RD"   ) then val := "RM76U89 ";
            elsif(s = "EXT4343RD"   ) then val := "RM76U89 ";
            elsif(s = "EXT3643R"    ) then val := "RM76U89 ";
            end if;
        end if;
        return (val);
    end GATE_BY_MODEL;

    function ROIC_MCLK_BY_MODEL (s : string) return integer is
        variable val : integer;
    begin
        if(SIMULATION = "ON") then
            val     := 20000;
        else
               if(s = "EXT1024R"    ) then val :=  20000; -- jyp 241010
            elsif(s = "EXT1616R"    ) then val :=  20000;
            elsif(s = "EXT2430R"    ) then val :=  12500;
            elsif(s = "EXT2832R"    ) then val :=  20000;
            elsif(s = "EXT2832R_2"  ) then val :=  20000;
            elsif(s = "EXT4343R"    ) then val :=  12500;
            elsif(s = "EXT4343R_1"  ) then val :=  12500;
            elsif(s = "EXT4343R_2"  ) then val :=  12500;
            elsif(s = "EXT4343R_3"  ) then val :=  12500;
            elsif(s = "EXT4343R_4"  ) then val :=  12500;
            elsif(s = "EXT4343RC"   ) then val :=  12500;
            elsif(s = "EXT4343RC_1" ) then val :=  12500;
            elsif(s = "EXT4343RC_2" ) then val :=  12500;
            elsif(s = "EXT4343RC_3" ) then val :=  12500;
            elsif(s = "EXT2430RI"   ) then val :=  20000;
            elsif(s = "EXT4343RI_2" ) then val :=  20000;
            elsif(s = "EXT4343RI_4" ) then val :=  20000;
            elsif(s = "EXT4343RCI_1") then val :=  20000;
            elsif(s = "EXT4343RCI_2") then val :=  20000;
            elsif(s = "EXT810R"     ) then val :=  20000;
            elsif(s = "EXT2430RD"   ) then val :=  20000;
            elsif(s = "EXT4343RD"   ) then val :=  30000;
            elsif(s = "EXT3643R"    ) then val :=  30000;
            end if;
        end if;
        return (val);
    end ROIC_MCLK_BY_MODEL;

    function ROIC_DCLK_BY_MODEL (s : string) return integer is
        variable val : integer;
    begin
        if(SIMULATION = "ON") then
            val     := 240000;
        else
               if(s = "EXT1024R"    ) then val := 240000; -- jyp 241010
            elsif(s = "EXT1616R"    ) then val := 240000;
            elsif(s = "EXT2430R"    ) then val := 150000;
            elsif(s = "EXT2832R"    ) then val := 240000;
            elsif(s = "EXT2832R_2"  ) then val := 240000;
            elsif(s = "EXT4343R"    ) then val := 150000;
            elsif(s = "EXT4343R_1"  ) then val := 150000;
            elsif(s = "EXT4343R_2"  ) then val := 150000;
            elsif(s = "EXT4343R_3"  ) then val := 150000;
            elsif(s = "EXT4343R_4"  ) then val := 150000;
            elsif(s = "EXT4343RC"   ) then val := 150000;
            elsif(s = "EXT4343RC_1" ) then val := 150000;
            elsif(s = "EXT4343RC_2" ) then val := 150000;
            elsif(s = "EXT4343RC_3" ) then val := 150000;
            elsif(s = "EXT2430RI"   ) then val := 240000;
            elsif(s = "EXT4343RI_2" ) then val := 240000;
            elsif(s = "EXT4343RI_4" ) then val := 240000;
            elsif(s = "EXT4343RCI_1") then val := 240000;
            elsif(s = "EXT4343RCI_2") then val := 240000;
            elsif(s = "EXT810R"     ) then val := 240000;
            elsif(s = "EXT2430RD"   ) then val := 240000;
            elsif(s = "EXT4343RD"   ) then val := 360000;
            elsif(s = "EXT3643R"    ) then val := 360000;
            end if;
        end if;
        return (val);
    end ROIC_DCLK_BY_MODEL;

    function GEV_SPEED_BY_MODEL (s : string) return string is
        variable val : string(1 to 4);
    begin
        if(SIMULATION = "ON") then
            val     := "2p5G";

        else
               if(s = "EXT1024R"    ) then val := "10G "; -- jyp 241010
            elsif(s = "EXT1616R"    ) then val := "2p5G";
            elsif(s = "EXT2430R"    ) then val := "2p5G";
            elsif(s = "EXT2832R"    ) then val := "2p5G";
            elsif(s = "EXT2832R_2"  ) then val := "2p5G";
            elsif(s = "EXT4343R"    ) then val := "2p5G";
            elsif(s = "EXT4343R_1"  ) then val := "2p5G";
            elsif(s = "EXT4343R_2"  ) then val := "2p5G";
            elsif(s = "EXT4343R_3"  ) then val := "2p5G";
            elsif(s = "EXT4343R_4"  ) then val := "2p5G";
            elsif(s = "EXT4343RC"   ) then val := "2p5G";
            elsif(s = "EXT4343RC_1" ) then val := "2p5G";
            elsif(s = "EXT4343RC_2" ) then val := "2p5G";
            elsif(s = "EXT4343RC_3" ) then val := "2p5G";
            elsif(s = "EXT2430RI"   ) then val := "10G ";
            elsif(s = "EXT4343RI_2" ) then val := "10G ";
            elsif(s = "EXT4343RI_4" ) then val := "10G ";
            elsif(s = "EXT4343RCI_1") then val := "10G ";
            elsif(s = "EXT4343RCI_2") then val := "10G ";
            elsif(s = "EXT810R"     ) then val := "2p5G";
            elsif(s = "EXT2430RD"   ) then val := "2p5G";
            elsif(s = "EXT4343RD"   ) then val := "10G ";
            elsif(s = "EXT3643R"    ) then val := "10G ";
            end if;
        end if;
        return (val);
    end GEV_SPEED_BY_MODEL;

    function ROIC_DUAL_BY_MODEL (s : string) return integer is
        variable val : integer;
    begin
        if(s = "EXT4343RD"  ) then val := 2;
        else                       val := 1;
        end if;
        return (val);
    end ROIC_DUAL_BY_MODEL;
    
    function DDR_BY_MODEL (s : string) return integer is
        variable val : integer;
    begin
        if(s = "EXT4343RD"  ) then val := 4;
        else                       val := 2;
        end if;
        return (val);
    end DDR_BY_MODEL;
    
--##### BY MODEL #####
--####################

--  constant ROIC_SYNC_DCLK         : integer := ( 100  * ROIC_DCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_SYNC_DCLK (s:string) return integer is
        variable val:integer;
    begin
        val := ( 100  * ROIC_DCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant ROIC_SYNC_ACLK         : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_SYNC_ACLK (s:string) return integer is
        variable val:integer;
    begin
        val := ( 100  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant ROIC_DEAD              : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_DEAD(s:string) return integer is
        variable val:integer;
    begin
        val := ( 100  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
        return (val);
    end;

--  constant ROIC_FA                : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_FA(s:string) return integer is
        variable val:integer;
    begin
        val := ( 100  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant ROIC_CDS1              : integer := (4000  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_CDS1(s:string) return integer is
        variable val:integer;
    begin
--$        val := (4000  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        val := (2000  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant ROIC_CDS2              : integer := (6500  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_CDS2(s:string) return integer is
        variable val:integer;
    begin
--$        val := (6500  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        val := (4000  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant ROIC_INTRST            : integer := (1500  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function ROIC_INTRST(s:string) return integer is
        variable val:integer;
    begin
--$        val := (1500  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        val := (500  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant GATE_OE                : integer := (1700  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function GATE_OE(s:string) return integer is
        variable val:integer;
    begin
        val := (1700  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant GATE_XON               : integer := ( 340  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)
    function GATE_XON (s : string) return integer is
        variable val:integer;
    begin
        val := ( 340  * ROIC_MCLK_BY_MODEL(s)) / KHz;
        return (val);
    end;

--  constant GATE_XON_FLK           : integer := (  50  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)
    function GATE_XON_FLK(s:string) return integer is
        variable val:integer;
    begin
        val :=  (  50  * ROIC_MCLK_BY_MODEL(s)) / KHz;
        return (val);
    end;

--  constant GATE_FLK               : integer := ( 150  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-3 / 1E+3 = 1E-6 (us)
    function GATE_FLK(s:string) return integer is
        variable val:integer;
    begin
        val :=  ( 150  * ROIC_MCLK_BY_MODEL(s)) / KHz;
        return (val);
    end;

--  constant GATE_DIO_CPV           : integer := ( 100  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function GATE_DIO_CPV(s:string) return integer is
        variable val:integer;
    begin
        val :=  ( 100  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant GATE_TRST_PERIOD       : integer := (  10  * ROIC_MCLK_BY_MODEL(GNR_MODEL));           -- 1E-3 / 1E+0 = 1E-3 (ms)
    function GATE_TRST_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val :=  (  10  * ROIC_MCLK_BY_MODEL(s));
        return (val);
    end;

--  constant GATE_ERASE             : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL));           -- 1E-3 / 1E+0 = 1E-3 (ms)
    function GATE_ERASE(s:string) return integer is
        variable val:integer;
    begin
        val :=  (   1  * ROIC_MCLK_BY_MODEL(s));
        return (val);
    end;

--  constant T_1MS                  : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL));           -- 1E-3 / 1E+0 = 1E-3 (ms)
    function T_1MS(s:string) return integer is
        variable val:integer;
    begin
        val :=  (   1  * ROIC_MCLK_BY_MODEL(s));
        return (val);
    end;

--  constant T_1US                  : integer := (   1  * ROIC_MCLK_BY_MODEL(GNR_MODEL)) / KHz;     -- 1E-6 / 1E+0 = 1E-6 (us)
    function T_1US(s:string) return integer is
        variable val:integer;
    begin
        val :=  (   1  * ROIC_MCLK_BY_MODEL(s)) / KHz;
        return (val);
    end;

--  constant t_10s                  : integer := (  10  * roic_mclk_by_model(gnr_model)) * khz;     -- 1e-3 * 1e+3 = 1e+0 ( s)
    function t_10S(s:string) return integer is
        variable val:integer;
    begin
        val :=  (  10  * roic_mclk_by_model(s)) * khz;
        return (val);
    end;

--  constant NT39530_CPV_PERIOD     : integer := (5000  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function NT39530_CPV_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val :=  (5000  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant NT39565_CPV_PERIOD     : integer := (3600  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns) -- test 210615 mbh
    function NT39565_CPV_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val :=  (3600  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant NT61303_CPV_PERIOD     : integer := (2880  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function NT61303_CPV_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val :=  (2880  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant RM76U89_CPV_PERIOD     : integer := (0500  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function RM76U89_CPV_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val :=  (0500  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant HX8698_CPV_PERIOD      : integer := (2860  * ROIC_MCLK_BY_MODEL(s)) / MHz;     -- 1E-3 / 1E+6 = 1E-9 (ns)
    function HX8698_CPV_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val :=  (2860  * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant EXT_TRIG_DEBO_PERIOD     : integer := ( 100000   * ROIC_MCLK_BY_MODEL(s)) / MHz;   -- 1E-3 / 1E+6 = 1E-9 (ns)
    function EXT_TRIG_DEBO_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val := ( 100000   * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant EXT_TRIG_DEBO_PERIOD_SIM : integer := (   1000   * ROIC_MCLK_BY_MODEL(s)) / MHz;   -- 1E-3 / 1E+6 = 1E-9 (ns)
    function EXT_TRIG_DEBO_PERIOD_SIM(s:string) return integer is
        variable val:integer;
    begin
        val := (   1000   * ROIC_MCLK_BY_MODEL(s)) / MHz;
        return (val);
    end;

--  constant SIM_GATE_XON           : integer := GATE_XON(s)         / 100;
    function SIM_GATE_XON(s:string) return integer is
        variable val:integer;
    begin
        val := GATE_XON(s)         / 100;
        return (val);
    end;

--  constant SIM_GATE_XON_FLK       : integer := GATE_XON_FLK(s)     / 100;
    function SIM_GATE_XON_FLK(s:string) return integer is
        variable val:integer;
    begin
        val := GATE_XON_FLK(s)     / 100;
        return (val);
    end;

--  constant SIM_GATE_FLK           : integer := GATE_FLK(s)         / 100;
    function SIM_GATE_FLK(s:string) return integer is
        variable val:integer;
    begin
        val := GATE_FLK(s)         / 100;
        return (val);
    end;

--  constant SIM_GATE_TRST_PERIOD   : integer := GATE_TRST_PERIOD(s) / 100;
    function SIM_GATE_TRST_PERIOD(s:string) return integer is
        variable val:integer;
    begin
        val := GATE_TRST_PERIOD(s) / 100;
        return (val);
    end;

--  constant SIM_GATE_ERASE         : integer := GATE_ERASE(s)       / 100;
    function SIM_GATE_ERASE(s:string) return integer is
        variable val:integer;
    begin
        val := GATE_ERASE(s)       / 100;
        return (val);
    end;

    function gate_ch (s : string) return integer is
        variable val : integer range 0 to 512;
    begin
        if(simulation = "on") then
            val     := 4;
        else
            if   (s = "EXT1024R"    ) then val := 384;
            elsif(s = "EXT1616R"    ) then val := 274;
            elsif(s = "EXT2430R"    ) then val := 384;
            elsif(s = "EXT2430RI"   ) then val := 384;
            elsif(s = "EXT2832R"    ) then val := 512;
            elsif(s = "EXT2832R_2"  ) then val := 512;
            elsif(s = "EXT4343R"    ) then val := 512;
            elsif(s = "EXT4343R_1"  ) then val := 512;
            elsif(s = "EXT4343R_2"  ) then val := 512;
            elsif(s = "EXT4343R_3"  ) then val := 256;
            elsif(s = "EXT4343R_4"  ) then val := 512;
            elsif(s = "EXT4343RC"   ) then val := 512;
            elsif(s = "EXT4343RC_1" ) then val := 512;
            elsif(s = "EXT4343RC_2" ) then val := 512;
            elsif(s = "EXT4343RC_3" ) then val := 256;
            elsif(s = "EXT810R"     ) then val := 256;
            elsif(s = "EXT2430RD"   ) then val := 384;
            elsif(s = "EXT4343RI_2" ) then val := 512;
            elsif(s = "EXT4343RI_4" ) then val := 512;
            elsif(s = "EXT4343RCI_1") then val := 512;
            elsif(s = "EXT4343RCI_2") then val := 512;
            elsif(s = "EXT4343RD"   ) then val := 512;
            elsif(s = "EXT3643R"    ) then val := 478;
            end if;
        end if;
        return (val);
    end gate_ch;

    function gate_max_ch (s : string) return integer is
        variable val    : integer range 0 to 512;
    begin
        if(simulation = "on") then
            val     := 4;
        else
            if   (s = "EXT1024R"    ) then val := 450;
            elsif(s = "EXT1616R"    ) then val := 450;
            elsif(s = "EXT2430R"    ) then val := 450;
            elsif(s = "EXT2430RI"   ) then val := 450;
            elsif(s = "EXT2832R"    ) then val := 512;
            elsif(s = "EXT2832R_2"  ) then val := 512;
            elsif(s = "EXT4343R"    ) then val := 512;
            elsif(s = "EXT4343R_1"  ) then val := 512;
            elsif(s = "EXT4343R_2"  ) then val := 512;
            elsif(s = "EXT4343R_3"  ) then val := 256;
            elsif(s = "EXT4343R_4"  ) then val := 512;
            elsif(s = "EXT4343RC"   ) then val := 512;
            elsif(s = "EXT4343RC_1" ) then val := 512;
            elsif(s = "EXT4343RC_2" ) then val := 512;
            elsif(s = "EXT4343RC_3" ) then val := 256;
            elsif(s = "EXT810R"     ) then val := 256;
            elsif(s = "EXT2430RD"   ) then val := 450;
            elsif(s = "EXT4343RI_2" ) then val := 512;
            elsif(s = "EXT4343RI_4" ) then val := 512;
            elsif(s = "EXT4343RCI_1") then val := 512;
            elsif(s = "EXT4343RCI_2") then val := 512;
            elsif(s = "EXT4343RD"   ) then val := 512;
            elsif(s = "EXT3643R"    ) then val := 512;
            end if;
        end if;
        return val;
    end gate_max_ch;

    function max_width (s : string) return integer is
        variable val    : integer range 0 to 3840;
    begin
        if   (s = "EXT1024R"    ) then val := 1280;
        elsif(s = "EXT1616R"    ) then val := 1652;
        elsif(s = "EXT2430R"    ) then val := 3840; -- 256 * 15
        elsif(s = "EXT2430RI"   ) then val := 3840; -- 256 * 15
        elsif(s = "EXT2832R"    ) then val := 2304; -- 256 * 9
        elsif(s = "EXT2832R_2"  ) then val := 2304; -- 256 * 9
        elsif(s = "EXT4343R"    ) then val := 3072;
        elsif(s = "EXT4343R_1"  ) then val := 3072;
        elsif(s = "EXT4343R_2"  ) then val := 3072;
        elsif(s = "EXT4343R_3"  ) then val := 3072;
        elsif(s = "EXT4343R_4"  ) then val := 3072;
        elsif(s = "EXT4343RC"   ) then val := 3072;
        elsif(s = "EXT4343RC_1" ) then val := 3072;
        elsif(s = "EXT4343RC_2" ) then val := 3072;
        elsif(s = "EXT4343RC_3" ) then val := 3072;
        elsif(s = "EXT810R"     ) then val := 2048; -- 256 * 8
--      elsif(s = "EXT2430RD"   ) then val := 1792; -- 256 * 7
        elsif(s = "EXT2430RD"   ) then val := 3584; -- 256 * 14
        elsif(s = "EXT4343RI_2" ) then val := 3072;
        elsif(s = "EXT4343RI_4" ) then val := 3072;
        elsif(s = "EXT4343RCI_1") then val := 3072;
        elsif(s = "EXT4343RCI_2") then val := 3072;
        elsif(s = "EXT4343RD"   ) then val := 3072;
        elsif(s = "EXT3643R"    ) then val := 3584; --$ 256 * 14
        end if;
        return val;
    end max_width;

    function max_height (s : string) return integer is
--        variable val    : integer range 0 to 3072;
        variable val    : integer range 0 to 4302;
    begin
        if(simulation = "on") then
            val     := 8;
        else
            if   (s = "EXT1024R"    ) then val := 3072;
            elsif(s = "EXT1616R"    ) then val := 1644;
            elsif(s = "EXT2430R"    ) then val := 3072; -- 384*8
            elsif(s = "EXT2430RI"   ) then val := 3072; -- 384*8
            elsif(s = "EXT2832R"    ) then val := 2048; -- 512*4
            elsif(s = "EXT2832R_2"  ) then val := 2048; -- 512*4
            elsif(s = "EXT4343R"    ) then val := 3072;
            elsif(s = "EXT4343R_1"  ) then val := 3072;
            elsif(s = "EXT4343R_2"  ) then val := 3072;
            elsif(s = "EXT4343R_3"  ) then val := 3072;
            elsif(s = "EXT4343R_4"  ) then val := 3072;
            elsif(s = "EXT4343RC"   ) then val := 3072;
            elsif(s = "EXT4343RC_1" ) then val := 3072;
            elsif(s = "EXT4343RC_2" ) then val := 3072;
            elsif(s = "EXT4343RC_3" ) then val := 3072;
            elsif(s = "EXT810R"     ) then val := 1536; -- 256*6
            elsif(s = "EXT2430RD"   ) then val := 2304; -- 384*6
            elsif(s = "EXT4343RI_2" ) then val := 3072;
            elsif(s = "EXT4343RI_4" ) then val := 3072;
            elsif(s = "EXT4343RCI_1") then val := 3072;
            elsif(s = "EXT4343RCI_2") then val := 3072;
            elsif(s = "EXT4343RD"   ) then val := 3072;
            elsif(s = "EXT3643R"    ) then val := 4302;
            end if;
        end if;
        return val;
    end max_height;

    function roic_dummy_line (s : string) return integer is
        variable val    : integer range 0 to 4;
    begin
        if(roic_by_model(s) = "afe2256") then
            val := 0;
        else
            if(roic_pipeline = "on") then
                val := ROIC_DUAL_BY_MODEL(s); -- roic_dual;
            else
                val := 0;
            end if;
        end if;
        return val;
    end roic_dummy_line;

    function roic_max_ch (s : string) return integer is
        variable val    : integer range 0 to 256;
    begin
        if   (s = "EXT1024R"    ) then val := 256;
        elsif(s = "EXT1616R"    ) then val := 256;
        elsif(s = "EXT2430R"    ) then val := 256;
        elsif(s = "EXT2430RI"   ) then val := 256;
        elsif(s = "EXT2832R"    ) then val := 256;
        elsif(s = "EXT2832R_2"  ) then val := 256;
        elsif(s = "EXT4343R"    ) then val := 256;
        elsif(s = "EXT4343R_1"  ) then val := 256;
        elsif(s = "EXT4343R_2"  ) then val := 256;
        elsif(s = "EXT4343R_3"  ) then val := 256;
        elsif(s = "EXT4343R_4"  ) then val := 256;
        elsif(s = "EXT4343RC"   ) then val := 256;
        elsif(s = "EXT4343RC_1" ) then val := 256;
        elsif(s = "EXT4343RC_2" ) then val := 256;
        elsif(s = "EXT4343RC_3" ) then val := 256;
        elsif(s = "EXT810R"     ) then val := 256;
        elsif(s = "EXT2430RD"   ) then val := 256;
        elsif(s = "EXT4343RI_2" ) then val := 256;
        elsif(s = "EXT4343RI_4" ) then val := 256;
        elsif(s = "EXT4343RCI_1") then val := 256;
        elsif(s = "EXT4343RCI_2") then val := 256;
        elsif(s = "EXT4343RD"   ) then val := 256;
        elsif(s = "EXT3643R"    ) then val := 256;
        end if;
        return val;    end roic_max_ch;

    function roic_ch (s : string) return integer is
        variable val    : integer range 0 to 256;
    begin
        if   (s = "EXT1024R"    ) then val := 256;
        elsif(s = "EXT1616R"    ) then val := 236; -- 236
        elsif(s = "EXT2430R"    ) then val := 256;
        elsif(s = "EXT2430RI"   ) then val := 256;
        elsif(s = "EXT2832R"    ) then val := 256;
        elsif(s = "EXT2832R_2"  ) then val := 256;
        elsif(s = "EXT4343R"    ) then val := 256;
        elsif(s = "EXT4343R_1"  ) then val := 256;
        elsif(s = "EXT4343R_2"  ) then val := 256;
        elsif(s = "EXT4343R_3"  ) then val := 256;
        elsif(s = "EXT4343R_4"  ) then val := 256;
        elsif(s = "EXT4343RC"   ) then val := 256;
        elsif(s = "EXT4343RC_1" ) then val := 256;
        elsif(s = "EXT4343RC_2" ) then val := 256;
        elsif(s = "EXT4343RC_3" ) then val := 256;
        elsif(s = "EXT810R"     ) then val := 256;
        elsif(s = "EXT2430RD"   ) then val := 256;
        elsif(s = "EXT4343RI_2" ) then val := 256;
        elsif(s = "EXT4343RI_4" ) then val := 256;
        elsif(s = "EXT4343RCI_1") then val := 256;
        elsif(s = "EXT4343RCI_2") then val := 256;
        elsif(s = "EXT4343RD"   ) then val := 256;
        elsif(s = "EXT3643R"    ) then val := 256;
        end if;
        return val;
    end roic_ch;

    function roic_dummy_ch (s : string) return integer is
        variable val    : integer range 0 to 256;
    begin
        val := (roic_max_ch(s) - roic_ch(s)) / 2;
        return val;
    end roic_dummy_ch;

    function roic_num (s : string) return integer is
        variable val    : integer range 0 to 24;
    begin
        val := (max_width(s) / roic_ch(s)) * ROIC_DUAL_BY_MODEL(s);
        return val;
    end roic_num;

    function roic_dclk_num (s : string) return integer is
        variable val    : integer range 0 to 24;
    begin
           if(s = "EXT4343R"    ) then val := (max_width(s) / roic_ch(s)) * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_1"  ) then val := 3;
        elsif(s = "EXT4343R_2"  ) then val := 3;
        elsif(s = "EXT4343R_3"  ) then val := 3;
        elsif(s = "EXT4343R_4"  ) then val := 4;
        elsif(s = "EXT4343RC"   ) then val := 3;
        elsif(s = "EXT4343RC_1" ) then val := 2;
        elsif(s = "EXT4343RC_2" ) then val := 2;
        elsif(s = "EXT4343RC_3" ) then val := 2;
        elsif(s = "EXT2430R"    ) then val := 2;
        elsif(s = "EXT2430RI"   ) then val := 2;
        elsif(s = "EXT2832R"    ) then val := 2;
        elsif(s = "EXT2832R_2"  ) then val := 2;
        elsif(s = "EXT810R"     ) then val := 2;
        elsif(s = "EXT2430RD"   ) then val := 2;
        elsif(s = "EXT4343RI_2" ) then val := 3;
        elsif(s = "EXT4343RI_4" ) then val := 4;
        elsif(s = "EXT4343RCI_1") then val := 2;
        elsif(s = "EXT4343RCI_2") then val := 2;
        elsif(s = "EXT1024R"    ) then val := 3; --$ 241127 jyp
        elsif(s = "EXT4343RD"   ) then val := 8;
        elsif(s = "EXT3643R"    ) then val := 5;
        else val := (MAX_WIDTH(S) / roic_ch(s)) * ROIC_DUAL_BY_MODEL(s);
        end if;
        return val;
    end roic_dclk_num;

    function roic_fclk_num (s : string) return integer is
        variable val    : integer range 0 to 24;
    begin
        if   (s = "EXT4343R"    ) then val := (max_width(s) / roic_ch(s)) * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_1"  ) then val := 3;
        elsif(s = "EXT4343R_2"  ) then val := 3;
        elsif(s = "EXT4343R_3"  ) then val := 3;
        elsif(s = "EXT4343R_4"  ) then val := 3;
        elsif(s = "EXT4343RC"   ) then val := 3;
        elsif(s = "EXT4343RC_1" ) then val := 2;
        elsif(s = "EXT4343RC_2" ) then val := 2;
        elsif(s = "EXT4343RC_3" ) then val := 2;
        elsif(s = "EXT2430R"    ) then val := 2;
        elsif(s = "EXT2430RI"   ) then val := 2;
        elsif(s = "EXT2832R"    ) then val := 2;
        elsif(s = "EXT2832R_2"  ) then val := 2;
        elsif(s = "EXT810R"     ) then val := 2;
        elsif(s = "EXT2430RD"   ) then val := 2;
        elsif(s = "EXT4343RI_2" ) then val := 3;
        elsif(s = "EXT4343RI_4" ) then val := 3;
        elsif(s = "EXT4343RCI_1") then val := 2;
        elsif(s = "EXT4343RCI_2") then val := 2;
        elsif(s = "EXT4343RD"   ) then val := 2;
        elsif(s = "EXT3643R"    ) then val := 2;
        else
              val := (MAX_WIDTH(s) / roic_ch(s)) * ROIC_DUAL_BY_MODEL(s);
        end if;
        return val;
    end roic_fclk_num;

    function roic_num2 (s : string) return integer is
        variable val    : integer range 0 to 15;
    begin
        val := (max_width(s) / roic_ch(s));
        return val;
    end roic_num2;

    function roic_num2_reg (s : string) return integer is -- register to 11
        variable val    : integer range 0 to 15;
    begin
        val := (max_width(s) / roic_ch(s));
        if val <= 12 then
          return val;
        else
          return 12;
        end if;
    end roic_num2_reg;

    function pixel_depth (s : string) return integer is
        variable val    : integer range 0 to 16;
    begin
            val := 16;
        return val;
    end pixel_depth;

--  function roic_burst (s : string) return integer is
--      variable val    : integer range 0 to 64;
--  begin
--      if(roic_ic = "aDAS1258") then
--          val := 64;
--      elsif(ROIC_IC = "ADAS1255") then
--          val := 64;
--      end if;
--      return val;
--  end ROIC_BURST;

--  function ROIC_BURST_NUM (s : string) return integer is
--      variable val    : integer range 0 to 32;
--  begin
--      if(ROIC_IC = "ADAS1258") then
--          val := 32;
--      elsif(ROIC_IC = "ADAS1255") then
--          val := 32;
--      end if;
--      return val;
--  end ROIC_BURST_NUM;

    function GATE_NUM (s : string) return integer is
        variable val    : integer range 0 to 15;
    begin
        if(GATE_BY_MODEL(s) = "RM76U89 ") then
            val := (MAX_HEIGHT(s) / GATE_CH(s));
        elsif(GATE_BY_MODEL(s) = "NT39530 ") then --# gate start pulse error 220523
            val := (MAX_HEIGHT(s) / GATE_CH(s));
        else --if(GATE_IC = "NT39530 ") then --# cascade only 1 start pulse --#220426
            val := 1;
        end if;
        return val;
    end GATE_NUM;

    function GATE_NUM2 (s : string) return integer is
        variable val    : integer range 0 to 15;
    begin
        if(GATE_BY_MODEL(s) = "RM76U89 ") then
            val := (MAX_HEIGHT(s) / GATE_CH(s));
        else
            val := 1;
        end if;
        return val;
    end GATE_NUM2;

    function GATE_DUMMY_LINE (s : string) return integer is
        variable val    : integer range 0 to 88;
    begin
        if(SIMULATION = "ON") then
            val := 0;
--          val := 2;
        else
            if   (s = "EXT1024R"   ) then val    := 33; -- (450-384)/2=33 --$ 241119 jyp
            elsif(s = "EXT1616R"   ) then val    := 88; -- (450-274)/2
            elsif(s = "EXT2430R"   ) then val    := 33; -- (450-384)/2
            elsif(s = "EXT2430RI"   ) then val   := 33; -- (450-384)/2 --# 230920 33->32
            elsif(s = "EXT2832R"   ) then val    := 0;
            elsif(s = "EXT2832R_2" ) then val    := 0;
            elsif(s = "EXT4343R"   ) then val    := 0;
            elsif(s = "EXT4343R_1" ) then val    := 0;
            elsif(s = "EXT4343R_2" ) then val    := 0;
            elsif(s = "EXT4343R_3" ) then val    := 0;
            elsif(s = "EXT4343R_4" ) then val    := 0;
            elsif(s = "EXT4343RC"  ) then val    := 0;
            elsif(s = "EXT4343RC_1") then val    := 0;
            elsif(s = "EXT4343RC_2") then val    := 0;
            elsif(s = "EXT4343RC_3") then val    := 0;
            elsif(s = "EXT810R"    ) then val    := 0;
            elsif(s = "EXT2430RD"  ) then val    := 33;
            elsif(s = "EXT4343RI_2" ) then val    := 0;
            elsif(s = "EXT4343RI_4" ) then val    := 0;
            elsif(s = "EXT4343RCI_1") then val    := 0;
            elsif(s = "EXT4343RCI_2") then val    := 0;
            elsif(s = "EXT4343RD"   ) then val    := 0;
            elsif(s = "EXT3643R"    ) then val    := 34;
            end if;
        end if;
        return val;
    end GATE_DUMMY_LINE;

--  function ROIC_SHAAZEN (s : string) return integer is
--      variable val    : integer range 0 to 200;
--  begin
--      if(ROIC_IC = "ADAS1258") then
--          val := ADAS1258_SHAAZEN;
--      elsif(ROIC_IC = "ADAS1255") then
--          val := ADAS1255_SHAAZEN;
--      end if;
--      return val;
--  end ROIC_SHAAZEN;
--
--  function ROIC_MUTE (s : string) return integer is
--      variable val    : integer range 0 to 2500;
--  begin
--      if(ROIC_IC = "ADAS1258") then
--          val := ADAS1258_MUTE;
--      elsif(ROIC_IC = "ADAS1255") then
--          val := ADAS1255_MUTE;
--      end if;
--      return val;
--  end ROIC_MUTE;
--
--  function ROIC_AFE_DCLK (s : string) return integer is
--      variable val    : integer range 0 to 96;
--  begin
--      if(ROIC_IC = "ADAS1258") then
--          val := ADAS1258_AFE_DCLK;
--      elsif(ROIC_IC = "ADAS1255") then
--          val := ADAS1255_AFE_DCLK;
--      end if;
--      return val;
--  end ROIC_AFE_DCLK;

    function PWR_NUM (s : string) return integer is
        variable val    : integer range 0 to 24;
    begin
        if   (s = "EXT1024R"   ) then val := 7; --$ 241127 jyp 13->7
        elsif(s = "EXT1616R"   ) then val := 9;
        elsif(s = "EXT2430R"   ) then val := 7;
        elsif(s = "EXT2430RI"   ) then val := 7;
        elsif(s = "EXT2832R"   ) then val := 7;
        elsif(s = "EXT2832R_2" ) then val := 7;
        elsif(s = "EXT4343R"   ) then val := 5;
        elsif(s = "EXT4343R_1" ) then val := 5;
        elsif(s = "EXT4343R_2" ) then val := 5;
        elsif(s = "EXT4343R_3" ) then val := 5;
        elsif(s = "EXT4343R_4" ) then val := 5;
        elsif(s = "EXT4343RC"  ) then val := 5;
        elsif(s = "EXT4343RC_1") then val := 5;
        elsif(s = "EXT4343RC_2") then val := 5;
        elsif(s = "EXT4343RC_3") then val := 5;
        elsif(s = "EXT810R"    ) then val := 11;
        elsif(s = "EXT2430RD"  ) then val := 11; --# +hv_sw 230626
        elsif(s = "EXT4343RI_2" ) then val := 5;
        elsif(s = "EXT4343RI_4" ) then val := 5;
        elsif(s = "EXT4343RCI_1") then val := 5;
        elsif(s = "EXT4343RCI_2") then val := 5;
        elsif(s = "EXT4343RD"  ) then val := 6;
        elsif(s = "EXT3643R"   ) then val := 7;
        end if;
        return val;
    end PWR_NUM;

    function ROIC_SPI_NUM (s : string) return integer is
        variable val    : integer range 0 to 30;
    begin
        if   (s = "EXT1024R"    ) then val := ROIC_NUM(s) * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT1616R"    ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430R"    ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430RI"   ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2832R"    ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2832R_2"  ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R"    ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_1"  ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_2"  ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_3"  ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_4"  ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC"   ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_1" ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_2" ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_3" ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT810R"     ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430RD"   ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RI_2" ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RI_4" ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RCI_1") then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RCI_2") then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RD"   ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT3643R"    ) then val :=           1 * ROIC_DUAL_BY_MODEL(s);
        end if;
        return val;
    end ROIC_SPI_NUM;

    function ROIC_MCLK_NUM (s : string) return integer is -- mbh 210317
        variable val    : integer range 0 to 31;
    begin
        if   (s = "EXT1024R"    ) then val :=     ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT1616R"    ) then val :=     ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430R"    ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430RI"   ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2832R"    ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2832R_2"  ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R"    ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_1"  ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_2"  ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_3"  ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_4"  ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC"   ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_1" ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_2" ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_3" ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT810R"     ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430RD"   ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RI_2" ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RI_4" ) then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RCI_1") then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RCI_2") then val := 2 * ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RD"   ) then val :=     ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT3643R"    ) then val :=     ROIC_DUAL_BY_MODEL(s);
        end if;
        return val;
    end ROIC_MCLK_NUM;

    function ROIC_SCLK_NUM (s : string) return integer is
        variable val    : integer range 0 to 31;
    begin
        if   (s = "EXT1024R"   ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT1616R"   ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430R"   ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430RI"  ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2832R"   ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2832R_2" ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R"   ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_1" ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_2" ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_3" ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343R_4" ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC"  ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_1") then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_2") then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RC_3") then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT810R"    ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT2430RD"  ) then val  := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RI_2" ) then val := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RI_4" ) then val := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RCI_1") then val := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RCI_2") then val := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT4343RD"   ) then val := ROIC_DUAL_BY_MODEL(s);
        elsif(s = "EXT3643R"    ) then val := ROIC_DUAL_BY_MODEL(s);
        end if;
        return val;
    end ROIC_SCLK_NUM;

    function ROIC_SDI_NUM (s : string) return integer is -- mbh 210317
        variable val    : integer range 0 to 31;
    begin
        if   (s = "EXT1024R"    ) then val := ROIC_NUM(s);
        elsif(s = "EXT1616R"    ) then val := ROIC_NUM(s);
        elsif(s = "EXT2430R"    ) then val := 2;
        elsif(s = "EXT2430RI"   ) then val := 2;
        elsif(s = "EXT2832R"    ) then val := 2;
        elsif(s = "EXT2832R_2"  ) then val := 2;
        elsif(s = "EXT4343R"    ) then val := 2;
        elsif(s = "EXT4343R_1"  ) then val := 2;
        elsif(s = "EXT4343R_2"  ) then val := 2;
        elsif(s = "EXT4343R_3"  ) then val := 2;
        elsif(s = "EXT4343R_4"  ) then val := 2;
        elsif(s = "EXT4343RC"   ) then val := 2;
        elsif(s = "EXT4343RC_1" ) then val := 2;
        elsif(s = "EXT4343RC_2" ) then val := 2;
        elsif(s = "EXT4343RC_3" ) then val := 2;
        elsif(s = "EXT810R"     ) then val := 2;
        elsif(s = "EXT2430RD"   ) then val := 2;
        elsif(s = "EXT4343RI_2" ) then val := 2;
        elsif(s = "EXT4343RI_4" ) then val := 2;
        elsif(s = "EXT4343RCI_1") then val := 2;
        elsif(s = "EXT4343RCI_2") then val := 2;
        elsif(s = "EXT4343RD"   ) then val := 2;
        elsif(s = "EXT3643R"    ) then val := 2;
        end if;
        return val;
    end ROIC_SDI_NUM;

    function GATE_CONFIG_NUM (s : string) return integer is
        variable val    : integer range 0 to 10;
    begin
        if   (GATE_BY_MODEL(s) = "NT39530 " ) then val := 0; -- 810 0
        elsif(GATE_BY_MODEL(s) = "NT39565 " ) then val := 10;
        elsif(GATE_BY_MODEL(s) = "NT39565D" ) then val := 1;
        elsif(GATE_BY_MODEL(s) = "NT61303 " ) then val := 9;
        elsif(GATE_BY_MODEL(s) = "RM76U89 " ) then val := 3;  -- DUAL/SINGLE_ROIC (TI)
        elsif(GATE_BY_MODEL(s) = "HX8698  " ) then val := 6;  -- TI_ROIC_SINGLE
        end if;
        return val;
    end GATE_CONFIG_NUM;

    function GATE_CPV_PERIOD (s : string) return integer is
        variable val    : integer range 0 to 250;
    begin
        if   (GATE_BY_MODEL(s) = "NT39530 " ) then val := NT39530_CPV_PERIOD(s);
        elsif(GATE_BY_MODEL(s) = "NT39565 " ) then val := NT39565_CPV_PERIOD(s);
        elsif(GATE_BY_MODEL(s) = "NT39565D" ) then val := NT39565_CPV_PERIOD(s);
        elsif(GATE_BY_MODEL(s) = "NT61303 " ) then val := NT61303_CPV_PERIOD(s);
        elsif(GATE_BY_MODEL(s) = "RM76U89 " ) then val := RM76U89_CPV_PERIOD(s);
        elsif(GATE_BY_MODEL(s) = "HX8698  " ) then val :=  HX8698_CPV_PERIOD(s);
        end if;
        return val;
    end GATE_CPV_PERIOD;

    function ilaswitch(s : string) return string is begin
        if (SIMULATION = "ON") then
            return "OFF";
        else
            return "ON";
        end if;
    end function ilaswitch;

    function FUNC_ADC_REV(s: string) return std_logic is
    begin -- 64 pixel channel change in 256
            if   (s = "EXT1024R"    ) then return  '0'; -- jyp 241010
            elsif(s = "EXT1616R"    ) then return  '0';
            elsif(s = "EXT2430R"    ) then return  '1';
            elsif(s = "EXT2430RI"   ) then return  '1';
            elsif(s = "EXT2832R"    ) then return  '1';
            elsif(s = "EXT2832R_2"  ) then return  '1';
            elsif(s = "EXT4343R"    ) then return  '1';
            elsif(s = "EXT4343R_1"  ) then return  '1';
            elsif(s = "EXT4343R_2"  ) then return  '1';
            elsif(s = "EXT4343R_3"  ) then return  '1';
            elsif(s = "EXT4343R_4"  ) then return  '1';
            elsif(s = "EXT4343RC"   ) then return  '1';
            elsif(s = "EXT4343RC_1" ) then return  '1';
            elsif(s = "EXT4343RC_2" ) then return  '1';
            elsif(s = "EXT4343RC_3" ) then return  '1';
            elsif(s = "EXT810R"     ) then return  '1';
            elsif(s = "EXT2430RD"   ) then return  '1';
            elsif(s = "EXT4343RI_2" ) then return  '1';
            elsif(s = "EXT4343RI_4" ) then return  '1';
            elsif(s = "EXT4343RCI_1") then return  '1';
            elsif(s = "EXT4343RCI_2") then return  '1';
            elsif(s = "EXT4343RD"   ) then return  '0';
            elsif(s = "EXT3643R"    ) then return  '0';
            else                           return  '0';
            end if;
    end function FUNC_ADC_REV;

    function FUNC_H_FLIP(s: string) return std_logic is
    begin
            if   (s = "EXT1024R"    ) then return '0'; -- jyp 241010
            elsif(s = "EXT1616R"    ) then return '0';
            elsif(s = "EXT2430R"    ) then return '1';
            elsif(s = "EXT2430RI"   ) then return '1';
            elsif(s = "EXT2832R"    ) then return '1';
            elsif(s = "EXT2832R_2"  ) then return '1';
            elsif(s = "EXT4343R"    ) then return '0'; --
            elsif(s = "EXT4343R_1"  ) then return '1';
            elsif(s = "EXT4343R_2"  ) then return '1';
            elsif(s = "EXT4343R_3"  ) then return '1';
            elsif(s = "EXT4343R_4"  ) then return '1';
            elsif(s = "EXT4343RC"   ) then return '1';
            elsif(s = "EXT4343RC_1" ) then return '1';
            elsif(s = "EXT4343RC_2" ) then return '1';
            elsif(s = "EXT4343RC_3" ) then return '1';
            elsif(s = "EXT810R"     ) then return '1';
            elsif(s = "EXT2430RD"   ) then return '1';
            elsif(s = "EXT4343RI_2" ) then return '1';
            elsif(s = "EXT4343RI_4" ) then return '1';
            elsif(s = "EXT4343RCI_1") then return '1';
            elsif(s = "EXT4343RCI_2") then return '1';
            elsif(s = "EXT4343RD"   ) then return '0';
            elsif(s = "EXT3643R"    ) then return '0';
            else                           return '0';
            end if;
    end function FUNC_H_FLIP;

    function FUNC_MODEL_NAME(s : string) return integer is
    begin
        if   (s = "EXT1024R"    ) then return 100;
        elsif(s = "EXT1616R"    ) then return 160;
        elsif(s = "EXT2430R"    ) then return 240;
        elsif(s = "EXT2430RI"   ) then return 241;
        elsif(s = "EXT2832R"    ) then return 280;
        elsif(s = "EXT2832R_2"  ) then return 282;
        elsif(s = "EXT4343R"    ) then return 430;
        elsif(s = "EXT4343R_1"  ) then return 431;
        elsif(s = "EXT4343R_2"  ) then return 432;
        elsif(s = "EXT4343R_3"  ) then return 433;
        elsif(s = "EXT4343R_4"  ) then return 434;
        elsif(s = "EXT4343RC"   ) then return 435;
        elsif(s = "EXT4343RC_1" ) then return 436;
        elsif(s = "EXT4343RC_2" ) then return 437;
        elsif(s = "EXT4343RC_3" ) then return 438;
        elsif(s = "EXT810R"     ) then return 810; -- direct
        elsif(s = "EXT2430RD"   ) then return 811; -- direct
        elsif(s = "EXT4343RI_2" ) then return 442;
        elsif(s = "EXT4343RI_4" ) then return 444;
        elsif(s = "EXT4343RCI_1") then return 446;
        elsif(s = "EXT4343RCI_2") then return 447;
        elsif(s = "EXT4343RD"   ) then return 450;
        elsif(s = "EXT3643R"    ) then return 360;
        else                           return 0;
        end if;
    end function FUNC_MODEL_NAME;

    function FUNC_BIT_ALIGN(s : string) return std_logic is
    begin
        if   (s = "EXT1024R"    ) then return '1';
        elsif(s = "EXT4343R_4"  ) then return '1';
        elsif(s = "EXT4343RI_4" ) then return '1';
        elsif(s = "EXT4343RD"   ) then return '1';
        elsif(s = "EXT3643R"    ) then return '1';
        else                           return '0';
        end if;
    end function FUNC_BIT_ALIGN;

    --### 10G 4 parallel pixel selection ###
    function PARA_PIX (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return 4;
        else                       return 1;
        end if;
    end PARA_PIX;

    function DDR_BIT_W0 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_W0;
        else                       return G2p5_DDR_BIT_W0;
        end if;
    end function DDR_BIT_W0;
    function DDR_BIT_W1 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_W1;
        else                       return G2p5_DDR_BIT_W1;
        end if;
    end function DDR_BIT_W1;
    function DDR_BIT_W2 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_W2;
        else                       return G2p5_DDR_BIT_W2;
        end if;
    end function DDR_BIT_W2;
    function DDR_BIT_W3 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_W3;
        else                       return G2p5_DDR_BIT_W3;
        end if;
    end function DDR_BIT_W3;
    function DDR_BIT_W4 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_W4;
        else                       return G2p5_DDR_BIT_W4;
        end if;
    end function DDR_BIT_W4;
    function DDR_BIT_R0 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_R0;
        else                       return G2p5_DDR_BIT_R0;
        end if;
    end function DDR_BIT_R0;
    function DDR_BIT_R1 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_R1;
        else                       return G2p5_DDR_BIT_R1;
        end if;
    end function DDR_BIT_R1;
    function DDR_BIT_R2 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_R2;
        else                       return G2p5_DDR_BIT_R2;
        end if;
    end function DDR_BIT_R2;
    function DDR_BIT_R3 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_R3;
        else                       return G2p5_DDR_BIT_R3;
        end if;
    end function DDR_BIT_R3;
    function DDR_BIT_R4 (s : string) return integer is
    begin
        if(GEV_SPEED_BY_MODEL(s) = "10G ") then return G10p_DDR_BIT_R4;
        else                       return G2p5_DDR_BIT_R4;
        end if;
    end function DDR_BIT_R4;
    
--$ DDR3
function DDR_DM (s : string) return integer is
begin
    if(DDR_BY_MODEL(s) = 4 ) then return DDR_DM_4;
    else                          return DDR_DM_2;
    end if;
end function DDR_DM;
function DDR_DQS (s : string) return integer is
begin
    if(DDR_BY_MODEL(s) = 4 ) then return DDR_DQS_4;
    else                          return DDR_DQS_2;
    end if;
end function DDR_DQS;
function DDR_DQ (s : string) return integer is
begin
    if(DDR_BY_MODEL(s) = 4 ) then return DDR_DQ_4;
    else                          return DDR_DQ_2;
    end if;
end function DDR_DQ;
function DDR_AXI2 (s : string) return integer is
begin
    if(DDR_BY_MODEL(s) = 4 ) then return DDR_AXI2_4;
    else                          return DDR_AXI2_2;
    end if;
end function DDR_AXI2;

    --# 260320 SFP port count: 1=SFP used, 0=null array (ports disappear)
    function FUNC_SFP_NUM (s : string) return integer is
    begin
        if    (s = "EXT3643R") then
            return 1;
        else
            return 0;
        end if;
    end FUNC_SFP_NUM;

end TOP_HEADER;

-- ##########################
-- ##### REGACY HISTORY #####

--  constant MODEL                  : string := "EXT1024R";
--  constant GATE_IC                : string := "RM76U89";
--  constant ROIC_IC                : string := "AFE2256";
--  constant ROIC_MCLK_KHz          : integer := 20000;
--  constant ROIC_DCLK_KHz          : integer := 240000;
--  constant ROIC_DUAL              : integer := 2;

--  constant MODEL                  : string := "EXT4343R";
--  constant GATE_IC                : string := "HX8698";
--  constant ROIC_IC                : string := "ADAS1258";
--  constant ROIC_MCLK_KHz          : integer := 50000;
--  constant ROIC_DCLK_KHz          : integer := 166666;
--  constant ROIC_DUAL              : integer := 2;

--  constant MODEL                  : string := "EXT1616R";
--  constant GATE_IC                : string := "RM76U89";
--  constant ROIC_IC                : string := "AFE2256";
--  constant ROIC_MCLK_KHz          : integer := 20000;
--  constant ROIC_DCLK_KHz          : integer := 240000;
--  constant ROIC_DUAL              : integer := 2; -- "dual"
--  constant DDR3_ADDR_NUM          : integer := 13; -- 14:4Gx2 13:2Gx2

 -- constant FPGA_VER               : std_logic_vector(19 downto 0) := x"50004";
--  constant FPGA_VER               : std_logic_vector(19 downto 0) := x"50005";
       -- upper right image copy to lower left fix. TI_DATA_ALIGN.vhd sroic_cnt 201230 mbh
       -- lower image mirror. TI_ERASE_DUMMY 201231 mbh
--    constant FPGA_VER             : std_logic_vector(19 downto 0) := x"10001";
        -- SPI debug port, BD Bram 512k->256k
        -- SPI TI_ROIC_SETTING.vhd --if(itft_busy = '0') then -- 210106 mbh
        -- lower image mirror declare at header
        -- for roic single, address reverse declare on header -- 210112 mbh
--    constant FPGA_VER             : std_logic_vector(19 downto 0) := x"10003"; -- 210121
        -- offset unsigned 16b -> "signed" 16bit ,added substract ip at TPC_PROC
        -- axi clk ctrl + interrupt
        -- cmd -sdk "mclk" "rclk" "rtp 1" "gtp"
        -- sgate_oe_cnt reset for binning bug -- not yet
--    constant FPGA_VER             : std_logic_vector(19 downto 0) := x"50007"; -- 21.2.5 10:20
        -- ext_in, ext_out
        -- Horizontal rotation bug at axi_if, not sure
        -- binning tested, fixed screen rotation
        --- ti_lvds rx, axi_sub_if
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"10001"; -- 21.2.9
        -- ila switch on top_header
        -- added ila_data_align_video
        -- fixed defect delete, clear error on fpga & fw mbh 210215
        -- bd_locked => ui_rst at top
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"10002"; -- 21.2.18
        -- TPC 14b18b added
        -- fw update
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"10008"; -- 21.2.26
        -- - offset 0 img
        -- tpc ; video + 100
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"10009"; -- 21.3.5
        -- added temperature ic 3,4
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"11001"; -- 21.3.9
        -- fw will read mid version.
        -- added Flash_ctrl componenet, load data in 3sec as auto address increment.
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"1_10_06"; -- 21.3.16
        -- xadc_ctrl disable, bd_ddr <= xadc
        -- twinkle noise write enable disable at ddr3-axi_if-axi_rdata_conv--- comment
        -- ddr3-axi_sub_if-sconv_vcnt_4d vcnt latch at rising h sync.
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"1_11_02"; -- 21.3.19
        -- 1616 base, 4343 merge
        -- 4343 3x3 binn
        -- ddr 28b -> 29b
        -- 4343 3x3 roi_proc
-- constant FPGA_VER                : std_logic_vector(19 downto 0) := x"1_11_08"; -- 21.3.30
        -- ddr adc -> fpga temp return
        -- diag + sync_counter
        -- aging and bit align bug fix
        -- diag average, center, biggest, lowest

-- constant FPGA_VER                : std_logic_vector(19 downto 0) := x"1_12_06"; -- 21.4.06
        -- 4343 update for simulation
        -- diag, bcal fw update
        -- defect update
        -- sm probe
-- constant FPGA_VER                : std_logic_vector(19 downto 0) := x"1_13_08"; -- 21.4.08
        -- V rotation bug when changing binning : top isreg_height/width/x/y
        -- DDR Video freezing when changing binning : axi_sub ddr write sm - added timeout
        -- diag video counter update : added frame rate
        -- bit align enhenced :  1 and 31 ban & compare
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"1_13_09"; -- 21.4.09
        -- offset 100 -> 400 : tpc
        -- bcal eye value read
        -- state machine read ing..
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"1_14_12"; -- 21.4.12
        -- DDR addr 14bit -> 15bit  8Gb
--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"1_15_01"; -- 21.4.12
        -- added model 2430
        -- 2430 port connection
        -- ddr3 bram size 3072->3840
        -- ddr3 address reg bit
-- constant FPGA_VER                : std_logic_vector(19 downto 0) := x"1_16_06"; -- 21.4.14
    -- dio high during unusing
    -- 3 gate unuse pin "low"
    -- ila
    -- sm tftCtrl dio

--constant FPGA_VER             : std_logic_vector(19 downto 0) := x"1_14_29"; -- 21.4.20
    -- 164324 <- 1643 fw defect, top size reg latch
    -- Ddr axi_sub_if V cnt sync synchronization
    -- ver.21 is axi_sub_if vio test
    -- ver.23 avg troblem
    -- ver.24 avg ok, code clean
    -- ver.25 tft_ctrl bug
    -- ver.26 axi_sub_if height, width not latch. and cnt not free run all wr/rd 012ch
    -- ver.27 rollback wr 01 ch free run
    -- ver 28. 4343 booting troublem, bit calib condition dismiss,lvds_rx rollback
    -- ver 29. lvds_rx bit align 3~28 check only 1616

    -- # ver 02 210427
        -- 4343  eye_start, eye_end in lvds_rx are excepted limitation by mclk speed
        -- line_time calcultation is modified at sdk
        -- bug list : gate start line problem, roi h 4pixel
    -- # ver 02 210428 : gate start line debug vio
    -- # ver 03 210429 : even if no roic data, make video sync
    -- # ver 04 210503 : no_roic_go is modified -- Fail
                      -- oe size troblem fix test
    -- # ver 07 210507 : roi x posion move, roi_proc,line204 -- Fail Cancel
    -- # ver 10 210510 : external trigger test code revive
    -- # ver 10 210511 : external trigger added pin exposure_in, ext_in pin is changed
    -- # ver 11 210512 : Dic ext1616r"L"
    -- # ver 12 210512 : Global - Freerun use ewt,
    -- # ver 13 210512 : trig2 mode has a limitation / Red LED means Error or ext exp out en
    -- # ver 14 210513 : flash debug
    -- # ver 15 210518 : flash write by fpga
    -- # ver 15 210520 : flash write by fpga , reg trouble
    -- # ver 16 210524 : power on but cant get image -> lvds_rx svcnt,shcnt <= 0 l.588
    -- # ver 17 210524 : --delete,grab tide with gev out en--
    -- # ver 18 210604 : ddr3 address 512M->1G
    -- # ver 19 210610 : 4343rc gate pin sequence change
    -- # ver 20 210611 : 4343rc h flip component added, top-tft_top-data_align-h_flip
    -- # ver 21 210615 : 4343rc 3x3binning black screen, cause dio pulse width, tft_ctrl fixed. little danger
    -- # ver 22 210617 : tpc code clean
    -- # ver 23 210618 : tpc reg vsync latch dismiss
    -- # ver 24 210623 : ROI bram width 3072->3840 for 2430
    -- # ver 25 210623 : Defect bram width 3072->4096 for 2430
    -- # ver 26 210624 : ila debug
    -- # ver 27 210625 : GATE_VGH_RST, pwr_num spwr_r1_avdd2_en activation.
    -- # ver 28 210628 : GATE ud rollback, adc rev=1, gate start pinmap
    -- # ver 29 210628 : gate start pinmap 8 pin, h flip en
    -- # ver 16.1 210625 : d2 mode
    -- # ver 16.2 210628 : reg connec fix, ila d2m
    -- # ver 16.3 210629 : prevent to add previous value / avg_proc
    -- # ver 16.4 210629 : connect ext_trig for d2 mode / tft_ctrl
    -- # ver 16.5 210630 : when it xray comes, bypass data at tpc./ name change d2m_avg->xray d2m_calc->dark
    -- # ver 16.6 210701 : flk, xon register vector 16 -> 32k
    -- # ver 16.7 210701 : "oe" ctrl by vio for test.
    -- # ver 16.8 210705 : dark, xray sel for debug
    -- # ver 16.9 210706 : state_tft_d2m_sel can select trst or srst by vio
    -- # ver 16.10 210706 : prevent d2mode srst get image.
    -- # ver 16.11 210708 : rolling d2mode vio.
    -- # ver 16.12 210708 : d2m tpc calc ila.
    -- # ver 16.13 210708 : roic sync drive test
    -- # ver 16.14 210709 : left 14 pixel is black debug
    -- # ver 16.15 210709 : h flip end01/23 2,3->0,1
    -- # ver 16.16 210709 : h flip fix 0 point
    -- # ver 16.17 210712 : tpc overflow x+400
    -- # ver 16.18 210712 : avg ila cause cant save to memory
    -- # ver 16.20 210713 : sch0_warea sync with sch0_rarea not
    -- # ver 16.21 210714 : sxon_cnt for roic_sync gen frequently
    -- # ver 16.22 210714 : added grst mode + v 511 +2 margin, hold roic_sync
    -- # ver 16.23 210714 : grst roic_sync ctrl
    -- # ver 16.24 210715 : bias_ctrl <= flk
    -- # ver 16.25 210719 : str:512, bcal error inspection
    -- # ver 16.26 210720 : dclk / 12 -> mclk
    -- # ver 16.27 210720 : smain_rstn, sroic_rstn are not use // cause ext_in not work
    -- # ver 16.28 210720 : smain_rstn, sroic_rstn are roll back, state_delay <= s_IDLE;
    -- # ver 16.30 210721 : debug_branch, ext debug
    -- # ver 16.31 210721 : debug_branch, ext debug sfifo_rd_en <= '1';
    -- # ver 16.32 210723 : updated from main, fw updated as profile structure
    -- # ver 16.33 210723 : d2m idle sm_idle
    -- # ver 16.34 210723 : axi_sub_if test ila
    -- # ver 16.35 210726 : finding bug d2m double input and first left noise
    -- # ver 16.36 210726 : d2m disable do state reset  , state_d2m <= sm_idle;
    -- # ver 16.37 210726 : added ddr3 read ch3 -> savg offset
    -- # ver 16.38 210728 : added func d2m hw calc at avg
    -- # ver 16.39 210728 : added exception, d2m xray img save to wddr1 place at axi_sub
    -- # ver 16.40 210729 : axi_sub_if debug for d2m avg
    -- # ver 16.41 210729 : axi_sub_if register latch method changed
    -- # ver 16.42 210730 : tpc ila
    -- # ver 16.43 210804 : ddr5 d2 xray save, d2xray(iofs)-curr
    -- # ver 16.44 210804 : d2m avg only save during xray to wddr6.
    -- # ver 16.45 210805 : avg statemachine reset is modified
    -- # ver 16.46 210805 : avg statemachine rollback, frame_cnt not gose 0 at idel state
    -- # ver 16.47 210805 : avg dark exception
    -- # ver 16.48 210805 : avg dark exception + clk lock fall check
    -- # ver 16.49 210805 : clk lock ctrl at top
    -- # ver 16.50 210805 : avg dark state change
    -- # ver 16.51 210805 : sbd_clk_lock dose not be drived, always '1'
    -- # ver 16.52 210805 : pwr_ctrl <= sysclk, sysclklocked
    -- # ver 16.53 210805 : bd_lock not connect
    -- # ver 16.55 210805 : toprst_ctrl for locked rst ctrl
    -- # ver 16.56 210805 : rst block seperatly
    -- # ver 16.57 210809 : test_pattern added for d2m
    -- # ver 16.58 210812 : 1616 bcal debug
    -- # ver 16.59 210812 : ROIC tpsel, sync force drive at tft_ctrl
    --------- ddr union model ------------------
    -- # ver 16.16 210810 : ddr2g merge in proj
    -- # ver 16.17 210811 : continue defect debug
    -- # ver 16.18 210811 : continue defect fix some
    -- # ver 16.19 210818 : 4343rcr pin map, need a check
    --------- 1616 dic double line -------------
    -- # ver 16.19 210817 : added for continued double line defect to be possible
    -- # ver 16.20 210817 : line defect ila
    --------- union + d2 -----------------------
    -- # ver 16.60 210820 : Bcal fail debug -> ex)bcal 1
    -- # ver 16.61 210823 : lvds rx littlebit change
    -- # ver 16.62 210823 : lvds rx ila

    --------- V17 ------------------------------
    -- # ver 17.00 210823 : version 16->17 for D2
    -- # ver 17.01 210823 : Model declare clear & added model EXT2832R
    -- # ver 17.02 210830 : 4343rcr gate setting change0
    -- # ver 17.03 210830 : 4343rcr gate setting change1 non use to Z
    -- # ver 17.04 210830 : 4343rcr
    -- # ver 17.05 210916 : 2832 image order
    -- # ver 17.06 210916 : 2832 image order : adc_rev bcak -> fw reverse
    -- # ver 17.07 210916 : 2832 d2m digital1_in -> ready_in_c -> a8 -> d2m trig
    -- # ver 17.08 210917 : 1616 gate LR bug fix
    -- # ver 17.09
    -- # ver 17.10 210923 : 2832 dnr
    -- # ver 17.11 210924 : DNR prevent v image rotation bug
    -- # ver 17.12 210924 : compile option, remove ila clk map
    -- # ver 17.13 210924 : timing constraint. roic_dout_p
    -- # ver 17.14 210927 : edge offset out
    -- # ver 17.15 210927 : dnr offset calc using dsp
    -- # ver 17.16 210928 : added accumulation
    -- # ver 17.17 210928 : GEN_ILA_axi_if
    -- # ver 17.18 210929 : ddr wch3 bug fix
    -- # ver 17.19 210929 : Gen ila axi_sub_if
    -- # ver 17.20 210929 : ddr wch3 wen & AccEnable
    -- # ver 17.21 210929 : timing noise test, no dnr
    -- # ver 17.22 210930 : ddr ch4
    -- # ver 17.23 211001 : ddr ch4 bug fix
    -- # ver 17.24 211001 : ddr ch4 bug fix 0
    -- # ver 17.25 211001 : ddr nuc r_en sequence rollback
    -- # ver 17.26 211005 : ila test
    -- # ver 17.27 211005 : ddr 750Mhz
    -- # ver 17.28 211006 : acc 256*limit -> 2**limit
    -- # ver 17.29 211005 : all ddr 750Mhz
    -- # ver 17.32 211005 : dnr update bug fix
    -- # ver 17.33 211012 : block design -> compile per blockdesign 750M
    -- # ver 17.34 211012 : mawari - calc change to + FF
    -- # ver 17.35 211013 : 4343rr
    -- # ver 17.36 211013 : 4343rr gate fix
    -- # ver 17.37 211013 : 4343rcr acc dnr measure
    -- # ver 17.38 211013 : ext trig improvement
    -- # ver 17.39 211020 : global shutter - serial reset mode Auto offset
    -- # ver 17.40 211020 : vio
    -- # ver 17.41 211020 : tft_ctrl rolling bug
    -- # ver 17.42 211022 : tft_ctrl external fix
    -- # ver 17.43 211025 : when trigger mode changed, 1 pulse bug fix
    -- # ver 17.44 211025 : roic_sync mask with auto_offset
    -- # ver 17.45 211026 : state_tftd (delayed) -> calib stream_en
    -- # ver 17.46 211026 : avg ila
    -- # ver 17.47 211026 : trig grab bug, ext trig avg bug
    -- # ver 17.48 211026 : ext trig avg state machine bug
    -- # ver 17.49 211027 : acc little bit changed
    -- # ver 17.50 211027 : rsm state machine name change
    -- # ver 17.51 211027 : shutter counter reset bug fix. state_tft <= s_EWT; -- 211022mbh
    -- # ver 17.52 211027 : tft_ctrl ila_grab
    -- # ver 17.53 211028 : tft_ctrl ila_grab 0
    -- # ver 17.54 211028 : not use trig_delay

    --------- V18 ------------------------------
    -- # ver 18.00 211029 : version 17->18
    -- # ver 18.01 211104 : roi stuck, ila probe
    -- # ver 18.02 211105 : api_trigger
    -- # ver 18.03 211112 : temp i2c complete
    -- # ver 18.04 211122 : roi 4 pixel debug -- no bug..
    -- # ver 18.05 211123 : roi stuck .. prevent + ila + rsm
    -- # ver 18.06 211124 : global shutter ext1 - can get a ext_in during ewt,scan.
    -- # ver 18.07 211125 : global shutter also wait frame_time. tft_ctrl
    -- # ver 18.08 211202 : reg trigger active
    -- # ver 18.09 211206 : ewt stop by sgrab_en , top debug module go to under hierarchy
    -- # ver 18.10 211206 : ewt stop by sgrab_en + state_grab
    -- # ver 18.11 211208 : average frame counter -> reg
    -- # ver 18.12 211208 : avg "CANCEL" in state // rsm 6 :avg
    -- # ver 18.13 211208h: avg rollback
    -- # ver 18.14 211208h: avg rollback fall
    -- # ver 18.15 211209 : microblaze cach 8000~bfff => 8000~7fff --cancel
    -- # ver 18.16 211209 : fw debug
    -- # ver 18.17 211210 : nuc tpc 1418 out 18bit-> 16bit cut
    -- # ver 18.18 211213 : preventing for wddr 0 ch over to nuc address. Line1011
    -- # ver 18.19 211214 : rsm 16b -> 32 reg/routine change
    -- # ver 18.20 211215 : roic counter reset, danger <= rollback
    -- # ver 18.21 211215 : sm_tft finish wait roic_cnt 256.
    -- # ver 18.22 211216 : sm_tft Rstfinish
    -- # ver 18.23 211216 : frame_cnt to register, ila
    -- # ver 18.24 211216 : reg_frame_num/val update
    -- # ver 18.25 211217 : state_grab no s_wait
    -- # ver 18.26 211220 : no roic 256 rule
    -- # ver 18.27 211221 : added reg_rstFrCnt for inserting serial-rst at staic mode
    -- # ver 18.28 211221 : no rstwait if gonna scan
    -- # ver 18.29 211227 : 18.28 roll back cause it makes first dose has a high value barely.
    -- # ver 18.30 211227 : serial reset use roic sync at tft_ctrl
    -- # ver 18.31 211223,30 : improve bcal, 24~32 -> 16~512
    -- # ver 18.32 220105 : sExt_TimeRst, Ext1 rst mode for SEC
    -- # ver 18.33 220118 : Led ctrl by FW.
    -- # ver 18.34 220120 : ACC ddr ch bug when roi changed prevente code added.
    -- # ver 18.35 220124 : rolling 8fps, staic 40fps: first img has a 8fps time. no grab sframe_time<= sreg_frame_time;
    -- # ver 18.36 220209 : added OSD function
    -- # ver 18.37 220325 : ACC auto reset , added change detaction module
    -- # ver 18.38 220331 : ACC auto reset OSD
--------- V40 ------------------------------
-- # ver 40.01 220407 : project version system changing
-- # ver 40.02 220408 : dpram_16x64 registered ram. in & addra
-- # ver 40.03 220426 : ext810r model
-- # ver 40.04 220502 : acc round --# 220502 round process
-- # ver 40.05 220508 : pwdac bug fix, develope
-- # ver 40.06 220509 : sleep mode reset -> ddr sync gen block.
-- # ver 40.07 220511 : tft ctrl reg assign, make wait out in tft_ctrl for bcal speed.
-- # ver 40.07 220516 : clean debugger, reduce bram state machine read fifo.
-- # ver 40.08 220520 : 810 pwdac 0.75v, it is not woiking at "STR 512".
-- # ver 40.09 220523 : 810 gate start pulse not working, gate_num in header = 1 -> 6
-- # ver 40.10 220523 : 4pixel 2line uder async problem. ti_data_align clk doamin fixed.
-- # ver 40.11 220603 : synth bufg20->24, imple  area->default -- flash write OK
-- # ver 40.12 220603 : flash clk 50M -> 25 MHz, halfclk <= clkcnt(1);
-- # ver 40.13 220603 :  if(state_tft = s_IDLE) then -- state latch roll back for boot stuck.
--------- V41 ------------------------------
-- # ver 41.01 220609 :  ver up; 1616 twinkle, imple strata->area, const->in delay data
-- # ver 41.02 220609 :  TI_LVDS_RX bit align more time // if(swait_cnt = 512) then -> 2**16
-- # ver 41.03 220609 :  TI_LVDS_RX if(swait_cnt > 2**16) then // ila
-- # ver 41.04 220609 :  IDELAYE2 LD, -- 1-bit input: Load IDELAY_VALUE input => REGRST
-- # ver 41.05 220610 :  rollbcak IDEALY REGRST
-- # ver 41.06 220610 :  SAFEZONE_MIN < seye_dif
-- # ver 41.07 220610 :  sEyestart_done
-- # ver 41.08 220610 :  roic sync mask while align process
-- # ver 41.09 220613 :  version release, lvds rx roll back cause 4343rcr has an error.
--------- V42 ------------------------------
-- # ver 42.01 220725 :  ti_data_align state_dpram ILA
-- # ver 42.02 220725 :  stoggle_portb check
-- # ver 42.03 220725 :  stoggle_portb with sm
-- # ver 42.04 220725 :  sm code rollbcak
-- # ver 42.05 220725 :  force abnormal stoggle_protb
-- # ver 42.06 220725 :  clear ambiguous
-- # ver 42.07-11 220726 :  ila
-- # ver 42.12 220727 :  ila
-- # ver 42.13 220727 :  back to align ila
-- # ver 42.14 220727 :  strength sync, mclk
-- # ver 42.15 220728 :  back to 41, only drive strength.
-- # ver 42.16 220728 :  sync falling edge
-- # ver 42.17 220728 :  sync falling edge sel by vio
-- # ver 42.18 220728 :  sync falling/rising edge sel by vio
-- # ver 42.20 220728 :  actually mclk divide fixed.
--------- V43 ------------------------------
-- # ver 43.01 220811 :  Blur 8pixel bug fix. /8 => /9
-- # ver 43.02 220811 :  0.11110687255859375
--------- V44 ------------------------------
-- # ver 44.01 220831 :  4343rc Nova
-- # ver 44.02 220901 :  roic str for clk modefied
--------- V45 ------------------------------
-- # ver 45.01 220914 :  flash 2nd boot test   --#################################### multi boot #####################################
--------- V46 ------------------------------
-- # ver 46.02 221012 :  image 2pixel downroll - lvds_rx debug
-- # ver 46.03 221012 :  image 2pixel downroll - data align debug
-- # ver 46.04 221012 :  image 2pixel downroll - data_align state_dpram idle condition.
-- # ver 46.05 221012 :  image 2pixel downroll - siganl cdc toggle
--------- V47 ------------------------------
-- # ver 47.01 221018 :  4343 project model name redefine.
-- # ver 47.02 221102 :  4343R_2 boot ready  top-GateL0R1 1->0
-- # ver 47.03 221103 :  OSD free frame count added

-- # version jump up for model list change
--------- V60 ------------------------------
-- # ver 60.01 221104 : FPGA DATE info ADDR_FPGA_DATE, FPGA_DATE
-- # ver 60.02 221107 10: 4343R_3 a-si GATE_ALL_OUT C26 -> G22
-- # ver 60.03 221107 11: 4343R_3 a-si gate stv sequence reversed
-- # ver 60.04 221108 08: beta prepare
-- # ver 60.05 221110 09: icap reboot
-- # ver 60.06 221110 11: ADDR_FPGA_REBOOT x"1000";
-- # ver 60.07 221121 17: SEC static speed up. if (sreg_RstFrCnt = 0) then --# 1 is meaning ready
-- # ver 60.08 221122 11: free run cnt 100MHz for debug
-- # ver 60.09 221122 15: frame cnt roollback, oreg_frame_cnt
-- # ver 60.10 221202 16: Dic report ACC error at 2832R, acc ila

--------- V61 ------------------------------
-- # ver 61.01 221207 : 2832 acc problem, it happen with gain on. => acc write priority up. sddr_ch_en(8)
-- # ver 61.02 221207 : sddr_ch_en(9) priority up
-- # ver 61.03 221207 18: sddr_ch_en(8) sddr_ch_en(9) priority to second, next offset
-- # ver 61.04 221208 10: ddr order strict
-- # ver 61.05 221208 10: axi 03 highest
-- # ver 61.06 221208 11: ddr row bank cl
-- # ver 61.08 221208 14: sddr_ch_en(8) 9 , priority up again
-- # ver 61.08 221208 17: cut error ; sXraySubRef_5d(18*(i+1)-2)
--------- V1.62.01 --------------------------
-- # ver 00.01 221220 : axi 4pixel 64bit read, 64bit ram added.
-- # ver 00.02 221220 15: 4343T_2:target, 4343TC_1:test model
-- # ver 00.03 221222 13: ddr bit width all changed
-- # ver 00.04 221227 10: 4para offset
-- # ver 00.05 221227 18: ddr rength + ila + wen + avg_wen bug
-- # ver 00.05 221228 08: ila data 16-> 64
-- # ver 00.05 221228 09: axi_if addr length
-- # ver 00.05 221228 10: connect offset 400 reg
-- # ver 00.05 221228 12: data width cur error fix
-- # ver 00.05 221228 16: ddr addr line width +'0'
-- # ver 00.06 230106 08: defect point add.
-- # ver 00.06 230106 12: defect write, read reg conn
-- # ver 00.06 230106 14: defect map error
-- # ver 00.07 230109 14: line defect test
-- # ver 00.07 230110 08: line defect init error finding
-- # ver 00.07 230110 15: row debugging wen->rise edge
-- # ver 00.07 230110 16: double line, news (16-1 downto 0)
-- #                  17: row_inc error -> addr inc compare 12bit
-- #                  18: column 0 line error
-- #           230111 09: news select position changed
-- #           230111 12: dot exception in line
-- #           230111 14: dot defect priority
-- #           230119 09: a-si str 1024 not work debug
--------- V1.62.xx --------------------------
-- # ver 1.62.02 230126 08 : 2832R_2 compile
-- # ver 1.62.03 230130 10 : 4 parallel i-point gain
-- # ver 1.62.03 23_0131_11 : add tp for check
-- # ver 1_62_03 23_0201_11 : 4 parallel i-point gain offset in 16b
-- # 1_62_04 23_0202_09 : 10G xgmac
-- # 1_62_05 23_0203_08 : 2430T model add
-- # 1_62_06 23_0206_13 : gain_4para offset 9b(11), gain14b, gainoffset9b(11)
-- # 1_62_06 23_0206_16 : gain_4para offset 10b, gain12b(14), gainoffset10b
-- # 1_62_06 23_0209_16 : add acc para4
-- # 1_62_07 23_0210_15 : add osd para4
-- # 1_62_08 23_0213_15 : add edge
-- # 1_62_08 23_0216_14 : add edge para4 10g
-- # 1_62_08 23_0216_17 : left right // top down error
-- # 1_63_01 23_0220_15 : version merge & check
-- # 1_63_02 23_0224_12 : 10g osd size bug fix
--------- V1.64.xx --------------------------
-- # 1_64_01 23_0417_17 : xdc timing met.
-- # 1_64_02 23_0512_14 : roi time analyze for cpv
-- # 1_64_03 23_0512_20 : sdata_sum_2x2_tmp_4d; --# 2d->4d fix error #230512
-- # 1_64_03 23_0515_10 : roi error, rollback tetst
-- # 1_64_03 23_0515_11 : roi data timing 0;
--                        roi_proc.vhd @ sdoutb  <= sdoutbx; --# datat dalay for compile 230515
-- # 1_64_04 23_0515_12 : frame counter range up
--                        sync_counter @ --# if over 127, 3 bit shift
-- # 1_64_04 23_0515_16 : ila_tft_ctrl
-- # 1_64_04 23_0515_17 : rear dummy
--------- V1.66.xx --------------------------
-- # 1_66_00 23_0516_10 : version jump for FW 64->66
-- # 1_66_00 23_0516_12 : cpv period rollback.
-- # 1_66_00 23_0516_15 : error finded. cpv 0.05
-- # 1_66_00 23_0517_11 : release compile
-- # 1_66_01 23_0531_18 : 2430 EXT_IN pinmap error C9->A8
-- # 1_66_01 23_0608_20 : OSD frame rate over 127 clac fix.
-- # 1_66_02 23_0619_15 : added 2430UR model
-- # 1_66_02 23_0630_10 : top code clean
-- # 1_66_03 23_0707_17 : sm_tft <+ Trig detection for SEC

--------- V1.67.xx --------------------------
-- # 1_67_00 23_0707_17 : release to SEC
-- # 1_67_01 23_0717_13 : ddr write position set
--                        sddr_ch4_wvcnt <= sch4_wvcnt_3d; --# 230717 at AXI_SUB_IF.vhd
-- # 1_67_02 23_0717_16 : ddr write position set add ch1,2,3 + 10G
-- # 1_67_02 23_0717_17 : add tp value to ADDR_TP_VALUE
-- # 1_67_03 23_0717_19 : sync blocking tpc -> ddr3 sync gen signal:sframe_end_trig
-- # 1_67_04 23_0718_15 : Trig Hz 1sec null reset
-- # 1_67_05 23_0718_19 : TPC gain calc offset unsigned -> signed for minus offset
-- #                      u_ADD_U16_S16_S18
-- # 1_67_06 23_0719_14 : Gain malfunction debug
-- # 1_67_07 23_0720_16 : gain resolve
-- # 1_67_08 23_0721_10 : dark flat Rollback
-- # 1_67_09 23_0721_17 : add HW B&C
-- # 1_67_09 23_0724_11 : fix contrast bug
-- #                 14 : contrast ila
-- #                 16 : bright not
-- #                 17 : britcont active area
-- #                 18 : h pixel avg
-- #                 19 : h pixel avg + 3x3
-- #                 20 : 3x3
-- # 1_67_09 23_0725_14 : offset gain limitation, 65000
-- #                 15 : offset X
-- # 1_67_09 23_0726_13 : BritCont + margin
-- #                 14 : min_margin bug fix
-- #                 15 : 16bit divider
-- #                 16 : diff min 768
-- #                 17 : no use 33, blinking
-- # 1_67_09 23_0728_15 : bnc margin bug fix
-- #                 16 : fix
-- #                 17 : fix
-- #                 18 : diff min 256
-- # 1_67_09 23_0801_16 : EQ test
-- #         23_0804_10 : ila check
-- #         23_0807_19 : hisAcc filter
-- #         23_0808_10 : filter overflow ila
-- #         23_0808_11 : last value error
-- #         23_0808_12 : defense interpol overflow
-- #         23_0809_11 : eq pass, SEC compile
-- #         23_0811_16 : eq ctrl for multi eq 4x4

-- # 1_67_10 23_0816_12 : eq 3x3
-- #                 13 : bug fix
-- #                 15 : EQ active end
-- #                 16 : EQ active position
-- #                 17 : 1/2 margin
-- #                 18 : full bit div
-- # 1_67_10 23_0817_12 : eq high radix
-- #                 13 : eq high radix + ready
-- #                 15 : 1eq and 9eq
-- #                 16 : eq reg conn
-- #         23_0818_11 : decide 1 eq
-- #                 12 : eq option
-- #                 16 : eq option by pixel rate
-- #         23_0821_10 : eq active and para4
-- # 1_67_12 23_0821_13 : eq step2
-- #         23_0825_14 : eq step jojunng
-- # 1_68_01 23_0829_13 : eq,bnc release
-- #         23_0904_15 : eq,bnc generate code
-- # 1_68_02 23_0911_11 : 10G gain check ila
-- #         23_0919_10 : 10G image rotate check ila - GEN_VIO_SYNC_COUNTER 1
-- #         23_0919_16 : roi block sync with vtrig %(vtrig = '1')
-- #         23_0919_18 : maked defects
-- #         23_0919_19 : maked defects 2
-- #         23_0920_10 : maked defects edge
-- #         23_0920_14 : sgate_dummy_add 1->0 // (15) rollback
-- #         23_0920_15 : gate dummy 33->32
-- #         23_0920_18 : - sgate_dummy_add
-- #         23_0920_19 : dummy odd check
