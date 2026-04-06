# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Role
1. 당신은 Vivado 및 Vitis를 설계 경험이 풍부한 상급 수준의 FPGA 개발자 역할
2. 모든 설명은 한국어로 대답
3. VHDL과 C 코드 분석 시 실제 신호명/변수명을 사용하여 설명
4. 코드 수정 제안 시 해당 함수/모듈의 관련 부분만 제공
5. 추측하지 말고, 코드에서 확인된 사실만 기반으로 답변
6. 수정 제안 시 기존 코드와의 호환성(AFE2256) 항상 고려
7. Vivado 에러는 에러 코드와 함께 원인/해결을 같이 제시

## Project Overview

EXTREAM-R 시리즈 적외선 열화상 카메라용 FPGA 설계 프로젝트. S2I GigE Vision 10G 레퍼런스 디자인 기반.
- **툴체인**: Xilinx Vivado 2022.2 (FPGA) + Vitis 2022.2 (펌웨어)
- **타겟**: Xilinx KC705 (Kintex-7 XC7K325T)
- **프로세서**: MicroBlaze 11.0 (little-endian 소프트코어 CPU)
- **프로토콜**: 10G GigE Vision (GEV 1.2/2.0), SFP+ 10GBASE-R / RXAUI / XAUI
- **지원 모델**: EXT1616R, EXT2430R, EXT2832R, EXT4343R 계열, EXT3643R 등 (20개+ 변형)
- **VHDL 스타일**: `IEEE.STD_LOGIC_UNSIGNED` + `STD_LOGIC_ARITH` 사용 (numeric_std 아님)

## Reference Documents
- docs/AFE3256_refernce.md : AFE3256 ROIC 요약 데이터시트

## Feature
- EXT3643R만 SFP 모듈 사용

## Build Commands

### FPGA 프로젝트 복원 (Vivado)
```tcl
# Vivado TCL 콘솔에서 실행
source project.tcl   # 프로젝트 구조 복원
source bd0.tcl       # CPU 블록다이어그램(MicroBlaze) 생성
# 이후 Vivado GUI에서 "Generate Bitstream" 실행
```

### 펌웨어 빌드 (Vitis/Makefile)
```bash
cd vitis/
make all          # 전체 빌드 (firmware + bootloader + boot image)
make bit          # 비트스트림에 부트로더 머지
make bin          # BIN 파일 생성
make boot         # BOOT.bin 생성
make lib          # GigE 정적 라이브러리 빌드
make eeprom       # EEPROM 이미지 생성
make s2i          # S2I 배포용 패키지 (스크립트, 부트로더, EEPROM, 라이브러리)
```
- 크로스 컴파일러: `mb-gcc` (MicroBlaze 전용)
- 빌드 결과물: `vitis/bin/` 디렉토리에 출력

### 시뮬레이션
`EXTxR2.srcs/sim_1/new/` 의 테스트벤치를 Vivado Simulator에서 실행:
- `TB_TOP.vhd` - 최상위 테스트벤치
- `TB_TI_DATA_ALIGN.vhd` - TI ROIC 데이터 정렬 테스트
- `TB_TI_TFT_TOP.vhd` - TFT 컨트롤러 테스트
- `TB_TI_FRAME_MANAGER.vhd` - 프레임 매니저 테스트
- `TB_ADI_TFT_TOP.vhd` / `TB_ADI_FRAME_MANAGER.vhd` - ADI ROIC 테스트
- 시뮬레이션 모드: `TOP_HEADER.vhd`에서 `SIMULATION` 상수를 `"ON"`으로 변경

## Architecture

### 소스 디렉토리 구조
FPGA 소스는 `EXTxR2.srcs/sources_1/new/` 아래에 위치 (`new/` 서브디렉토리 주의):
```
EXTREAM_R.vhd          # 최상위 엔티티 (xgvrd.vhd 기반, 모든 서브시스템 인스턴스화)
TOP_HEADER.vhd         # 전역 패키지 - 모델별 파라미터, 버전, 상수 정의
xgvrd.vhd              # S2I 원본 레퍼런스 디자인 최상위
TFT_CTRL/              # 센서 제어 (ROI, 테스트패턴, 트리거 딜레이, 모듈 리셋)
  TI/                  # TI ROIC 인터페이스 (LVDS RX, 데이터 정렬, SERDES, 전원제어 등)
CALIBRATION/           # 오프셋/결함 보정, 이득 보정, TPC, 누적처리
IMAGE_PROC/            # 영상처리 (밝기/대비/DNR/엣지/히스토그램 평활화/OSD/마스킹)
DDR3_CTRL/             # AXI DDR3 메모리 컨트롤러 (프레임 버퍼, 동기화)
GEV/                   # GigE Vision IP 래퍼 (xgige, xgmac, framebuf, rxaui, videotpg)
OUT_IF/                # 출력 인터페이스 (GEV 데이터 변환/매핑, 영상 평균)
REGISTER/              # AXI-Lite 레지스터 맵 (AXIL_REG.vhd, REG_TOP.vhd)
OTHERS/                # I2C, Flash, LED, XADC 컨트롤러, DPRAM
PROBE/                 # 디버그/모니터링 (ILA, VIO)
```

### 신호 처리 파이프라인
```
TI ROIC → LVDS RX → 데이터 정렬 → 교정(오프셋/결함/이득) → 영상처리 → DDR3 프레임버퍼 → GEV 패킷화 → 10G 스트리밍
         (TI_LVDS_RX)  (TI_DATA_ALIGN)  (CALIB_TOP)        (IMG_PROC_TOP)  (DDR3_TOP/AXI_IF)  (GEV_IF)
```
- 병렬처리(PARA4) 변형 존재: `CALIB_TOP_PARA4`, `IMG_PROC_PARA4`, `TPC_PROC_PARA4` 등

### 모델별 소스셋 구조
`EXTxR2.srcs/` 아래에 모델별 디렉토리가 존재 (번호 접두사 + 모델명):
- `0_EXT1616R/`, `1_EXT2430R/`, `2_EXT2832R/`, `3_EXT4343R_1/` ... `17_EXT3643R/`
- 이 디렉토리들은 Vivado fileset으로 사용되며, 모델별로 다른 소스 구성을 가짐
- 공통 소스는 `sources_1/new/`에, 모델 전용 수정은 해당 모델 디렉토리에 위치

### 버전 관리
`TOP_HEADER.vhd` 상단의 두 상수로 버전 추적:
- `FPGA_VER`: `x"2_01_11"` 형태 (ti/adi_메이저_서브)
- `FPGA_DATE`: `x"26_0320_11"` 형태 (년_월일_빌드번호)
- 변경 이력은 같은 파일에 주석으로 기록

### 펌웨어 구조 (`vitis/EXTREAM_fw/src/`)
MicroBlaze C 펌웨어:
- `command.c` / `func_cmd.c` / `func_basic.c` - UART 명령 처리 및 기본 기능
- `calib.c` - 교정 루틴
- `framebuf.c` - 프레임 버퍼 관리
- `flash.c` - Flash 메모리 관리
- `display.c` - 디스플레이 제어
- `fpga_info.c` - FPGA 버전/상태 정보

### IP 코어 (`cores/`)
S2I 제공 IP (소스 제한 - 일부 암호화/프리빌트):
- `s2i_libgige_5.4.1m` - GigE Vision 라이브러리 (핵심 IP)
- `s2i_xgige_2.3.4` / `s2i_xgmac_2.0.2` - 10G 이더넷 MAC/PHY
- `s2i_framebuf_2.2.6` - 프레임 버퍼 IP
- `s2i_videotpg_1.0.3` - 비디오 테스트 패턴 생성기
- `rxaui_v4_4` / `xaui_v12_3` - 고속 시리얼 트랜시버 (Xilinx IP)
- `SphinxSDK_GEV_2.7.3` - GEV 프로토콜 SDK (Windows 도구)
- `bootloader_src_v1.25` - 부트로더 소스

## Key Files

| 파일 | 설명 |
|------|------|
| `EXTxR2.srcs/sources_1/new/EXTREAM_R.vhd` | FPGA 최상위 설계 |
| `EXTxR2.srcs/sources_1/new/TOP_HEADER.vhd` | 모델별 파라미터/상수/버전 (패키지) |
| `EXTxR2.srcs/sources_1/new/TFT_CTRL/TI/TI_TFT_CTRL.vhd` | TI ROIC 메인 컨트롤러 |
| `EXTxR2.srcs/sources_1/new/TFT_CTRL/TI/TI_DATA_ALIGN.vhd` | LVDS 데이터 정렬 |
| `EXTxR2.srcs/constrs_1/new/xgvrd_kc705_n.xdc` | XDC 핀 제약 파일 |
| `project.tcl` | Vivado 프로젝트 복원 스크립트 |
| `bd0.tcl` | MicroBlaze CPU 블록다이어그램 생성 |
| `vitis/Makefile` | 펌웨어 전체 빌드 시스템 |
| `mod_step1.py` | VHDL 자동 수정 스크립트 (모델 추가 시 코드 변환) |
| `vhdl_ls.toml` | VHDL Language Server 설정 |
| `EXT_R_Series Memory Map_FPGA_v1.18.19_211102.xlsx` | 레지스터 메모리 맵 문서 |
| `UART Command 정리_211102.xlsx` | UART 명령어 문서 |

## Multi-Model Support

새 카메라 모델 추가 시:
1. `TOP_HEADER.vhd` - 모델 파라미터 추가 (제너릭/상수)
2. `EXTxR2.srcs/constrs_1/` - XDC 제약 파일 추가/수정 (핀 배치)
3. `vitis/Makefile` - 빌드 타겟에 모델 디렉토리 변수 추가 (예: `3643R_DIR`)
4. `mod_step1.py` - VHDL 자동 수정 스크립트 활용 (컴포넌트/신호 삽입 자동화)
5. `EXTxR2.srcs/` 아래에 모델별 소스셋 디렉토리 추가

## Development Notes

- VHDL 소스의 `.bak` 파일은 수정 전 백업본 (무시 가능)
- `EXTREAM_R.vhd`는 S2I의 `xgvrd.vhd` 레퍼런스 디자인을 커스텀한 것
- GEV IP 래퍼 파일들(`GEV/`)은 S2I IP 코어를 VHDL로 감싼 것으로, IP 코어 버전에 의존
- EEPROM 설정(MAC, IP 등)은 `vitis/Makefile`의 `EE_OPTIONS` 변수에서 관리

## VHDL 코드 작성
1. 코드 수정 시 기존 코드 주석 처리 후 바로 밑에 수정할 코드 작성
2. 작성한 코드는 '--$ (오늘날짜) (변경 이유 1줄)' 주석을 영어로 작성 ex) --$ 260325 Add EXT3643R SFP Module
3. 신규 변수 선언 시 기존 변수 선언한 것 참고하여 통일성있게 작성
4. CDC 코드 작성 시 process 별도로 분리하여 작성
5. .vhd 코드만 수정하기 나머지 확장자는 수정하는 방법 가이드라인으로 제시