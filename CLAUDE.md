# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EXTREAM-R 시리즈 적외선 열화상 카메라용 FPGA 설계 프로젝트.
- **툴체인**: Xilinx Vivado 2022.2 (FPGA) + Vitis 2022.2 (펌웨어)
- **타겟 보드**: Xilinx KC705 (Kintex-7)
- **프로세서**: MicroBlaze (소프트코어 CPU)
- **프로토콜**: 10G GigE Vision (GEV 1.2/2.0)
- **지원 모델**: EXT1616R, EXT2430R, EXT2832R, EXT4343R 계열, EXT3643R 등 18개 이상 변형

## Build Commands

### FPGA 비트스트림 빌드 (Vivado)
```tcl
# Vivado TCL 콘솔에서 프로젝트 복원
source project.tcl
# 이후 Vivado GUI에서 Generate Bitstream 실행
```

### 펌웨어 빌드 (Vitis/Makefile)
```bash
cd vitis/
make all          # 전체 빌드 (firmware + bootloader + boot image)
make bit          # 비트스트림만
make bin          # BIN 파일 생성
make boot         # BOOT.bin 생성
make lib          # 라이브러리만 빌드
make eeprom       # EEPROM 이미지 생성
make s2i          # S2I 이미지
```

### 특정 카메라 모델 빌드
`vitis/Makefile`의 `PROJ_NAME` 변수로 모델 지정:
- EXT1616R, EXT1616RL
- EXT2430R, EXT2430RD, EXT2430RI
- EXT2832R (다수 버전)
- EXT4343R/RC/RCI/RI (1,2,3 버전)
- EXT3643R

### 시뮬레이션
`EXTxR2.srcs/sim_1/new/` 의 테스트벤치를 Vivado Simulator에서 실행:
- `TB_TOP.vhd` - 최상위 테스트벤치
- `TB_TI_DATA_ALIGN.vhd` - TI ROIC 데이터 정렬 테스트
- `TB_TI_TFT_TOP.vhd` - TFT 컨트롤러 테스트

## Architecture

### FPGA 소스 구조 (`EXTxR2.srcs/sources_1/`)
```
EXTREAM_R.vhd          # 최상위 엔티티 (모든 서브시스템 인스턴스화)
TOP_HEADER.vhd         # 전역 상수, 모델별 파라미터 정의
TFT_CTRL/TI/           # TI ROIC 인터페이스 (TI_TFT_CTRL.vhd, TI_DATA_ALIGN.vhd, TI_LVDS_RX.vhd)
CALIBRATION/           # 오프셋/결함 보정, 이득 보정 (CALIB_TOP.vhd)
IMAGE_PROC/            # 영상처리 (밝기/대비/윤곽/잡음제거/히스토그램)
DDR3_CTRL/             # AXI DDR3 메모리 컨트롤러 (프레임 버퍼)
GEV/                   # GigE Vision 프로토콜 래퍼
OUT_IF/                # 출력 인터페이스 (GEV_IF.vhd)
REGISTER/              # AXI-Lite 레지스터 맵 (AXIL_REG.vhd, REG_TOP.vhd)
OTHERS/                # I2C, Flash, LED, XADC 컨트롤러
PROBE/                 # 디버그/모니터링 (ILA 등)
```

### 신호 처리 흐름
1. **센서 데이터 수신**: TI ROIC → LVDS RX (`TI_LVDS_RX.vhd`) → 데이터 정렬 (`TI_DATA_ALIGN.vhd`)
2. **교정 처리**: `CALIB_TOP.vhd` (오프셋/결함 보정, 이득 보정)
3. **영상 처리**: `IMAGE_PROC/` (대비, 히스토그램 평활화, 엣지 등)
4. **프레임 버퍼**: DDR3 (`DDR3_TOP.vhd`) ↔ AXI 인터페이스
5. **출력**: GEV 패킷화 → 10G GigE Vision 스트리밍

### 펌웨어 구조 (`vitis/EXTREAM_fw/src/`)
MicroBlaze 기반 C 펌웨어 (94개 소스 파일):
- `command.c` / `func_cmd.c` - UART 명령 처리
- `calib.c` - 교정 루틴
- `framebuf.c` - 프레임 버퍼 관리
- `flash.c` - Flash 메모리 관리
- `fpga_info.c` - FPGA 버전/상태 정보

### IP 코어 (`cores/`)
- `s2i_libgige_5.4.1m` - GigE Vision 라이브러리 (핵심 IP)
- `s2i_xgige_2.3.4` / `s2i_xgmac_2.0.2` - 10G 이더넷
- `s2i_framebuf_2.2.6` - 프레임 버퍼 IP
- `SphinxSDK_GEV_2.7.3` - GEV 프로토콜 SDK
- `rxaui_v4_4` / `xaui_v12_3` - 고속 시리얼 트랜시버

## Key Files

| 파일 | 설명 |
|------|------|
| `EXTxR2.srcs/sources_1/EXTREAM_R.vhd` | FPGA 최상위 설계 (187KB) |
| `EXTxR2.srcs/sources_1/TOP_HEADER.vhd` | 모델별 파라미터/상수 (143KB) |
| `EXTxR2.srcs/sources_1/TFT_CTRL/TI/TI_TFT_CTRL.vhd` | TI ROIC 메인 컨트롤러 (125KB) |
| `EXTxR2.srcs/sources_1/TFT_CTRL/TI/TI_DATA_ALIGN.vhd` | LVDS 데이터 정렬 (56KB) |
| `project.tcl` | Vivado 프로젝트 복원 스크립트 |
| `bd0.tcl` | CPU 블록다이어그램 생성 스크립트 |
| `vitis/Makefile` | 펌웨어 전체 빌드 시스템 |
| `EXT_R_Series Memory Map_FPGA_v1.18.19.xlsx` | 레지스터 메모리 맵 문서 |
| `UART Command 정리_211102.xlsx` | UART 명령어 문서 |

## Multi-Model Support

새 카메라 모델 추가 시:
1. `TOP_HEADER.vhd` - 모델 파라미터 추가 (제너릭/상수)
2. `EXTxR2.srcs/constrs_1/` - XDC 제약 파일 추가 (핀 배치)
3. `vitis/Makefile` - 빌드 타겟에 모델 추가
4. `mod_step1.py` - 필요 시 VHDL 자동 수정 스크립트 활용

## Project Recreation

프로젝트 초기 설정:
```tcl
# Vivado에서 실행
source project.tcl   # 프로젝트 구조 복원
source bd0.tcl       # CPU 블록다이어그램 생성
```
