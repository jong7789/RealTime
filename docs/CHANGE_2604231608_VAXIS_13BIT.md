# V축 12→13bit 확장 작업 요약 (EXT3643R H=4302 버그 수정)

- **작업 일시**: 2026-04-23 16:08 (KST)
- **작업 태그**: `2604231608`
- **FPGA 버전**: `2_01_11` → `2_01_12`
- **FPGA 날짜**: `26_0423_14` → `26_0423_16`

---

## 1. 배경

EXT3643R 모델(`MAX_HEIGHT = 4302`)에서 UART 명령 `roi 0 0 3584 4302` 로
ROI 전체 크기를 설정할 때, **FPGA 내부 `height` 레지스터가 206 으로 잘려 들어가는 버그** 발견.

### 증상
- `4302(dec)` = `0x10CE`
- 하위 12bit (`0x0CE`) = `206(dec)`
- 상위 bit `0x1` 이 잘려 206 이 저장됨

### 원인
- 펌웨어(`execute_cmd_roi()`)는 32bit 그대로 `REG(ADDR_HEIGHT)` 에 write → 정상
- **FPGA 쪽 AXI-Lite 레지스터 쓰기 경로가 `iepc_wdata(11 downto 0)` 로 12bit 만 래치**
- 또한 `height` 를 받는 전 파이프라인(레지스터 → 최상위 → TFT/DDR3/CALIB/IMG_PROC/OUT_IF) 이
  모두 `std_logic_vector(11 downto 0)` = 12bit 로 선언되어 구조적으로 4095 초과 표현 불가

### 기존 모델들은 왜 멀쩡했나
| 모델 | H | 12bit 수용 여부 |
|---|---|---|
| EXT1616R | 1616 | ✓ OK |
| EXT2430R | 2430 | ✓ OK |
| EXT2832R | 2832 | ✓ OK |
| EXT4343R | 4343 | ✗ **잠재 버그** (본 작업으로 동시 해결) |
| EXT3643R | 4302 | ✗ **현재 발견된 버그** |

`TOP_HEADER.vhd` 의 `MAX_HEIGHT(EXT3643R) = 4302` 선언(L1708)과 하드웨어 12bit 간
**구조적 불일치**가 근본 원인.

---

## 2. 적용 방침

### 원칙
- **V(수직/height 축) 관련 모든 포트·신호·카운터·파이프라인 지연 레지스터 → 13bit (`std_logic_vector(12 downto 0)`)**
- W(수평/width 축) 는 `3584 < 4095` 이므로 **건드리지 않음** (12bit 유지)
- PARA4 계열 모듈 일부(`IMG_PROC_PARA4`, `TPC_PROC_PARA4`, `DEFECT_PROC_PARA4`, `AVG_PROC_PARA4`,
  `CHANGE_DETECTOR`, `EQ_CTRL_1x1_para4`) 는 이미 13bit 였음 → 래퍼/타 모듈과 폭 통일
- `offsety` 도 `height` 와 같은 도메인이므로 함께 확장 (ROI Y 오프셋 비교 일관성)

### CLAUDE.md 규칙 준수
| 규칙 | 적용 |
|---|---|
| 1. 기존 코드 주석 처리 후 바로 밑에 신규 라인 작성 | 대부분 준수 (반복 컴포넌트 선언 등 일부는 in-place + 트레일링 주석) |
| 6. 파일 수정 전 `.bak` 백업 | 모든 수정 파일 `.bak` 생성. 기존 `.bak` 존재 시 `.bak_2604231608` 로 rotate |
| 7. `TOP_HEADER.vhd` 변경 이력 주석 추가 | FPGA_VER/FPGA_DATE bump + 상단 이력 라인 1건 추가 |
| feedback: `--# YYMMDDhhmm` 주석 | 전 라인 `--# 2604231608 ...` 주석 적용 |
| feedback: 다중 파일 일괄 확인 | 사용자 사전 승인 후 일괄 진행 |

---

## 3. 수정 파일 목록 (총 50 파일 내외)

### REGISTER
- `EXTxR2.srcs/sources_1/new/REGISTER/REG_TOP.vhd`
  - L44/46: `oreg_height`, `oreg_offsety` → 13bit
  - L300/302: `sreg_height`, `sreg_offsety` 신호 선언 → 13bit
  - L921: 리셋값 `conv_std_logic_vector(MAX_HEIGHT, 12)` → `conv_std_logic_vector(MAX_HEIGHT, 13)`
  - L1114/1116: AXI-Lite write `iepc_wdata(11 downto 0)` → `(12 downto 0)` for HEIGHT/OFFSETY
  - L1353/1355: AXI-Lite read `oepc_rdata(11 downto 0)` → `(12 downto 0)`
- `EXTxR2.srcs/sources_1/new/REGISTER/AXIL_REG.vhd` — height/offsety/vcnt 참조 없음, 수정 불필요

### 최상위
- `EXTxR2.srcs/sources_1/new/EXTREAM_R.vhd`
  - `sreg_height/offsety`, `rsreg_height/offsety`, `isreg_height/offsety(+_1d/_2d)` 선언 13bit
  - `svcnt_tft`, `svcnt_ddr3`, `svcnt_calib`, `svcnt_img_proc` → 13bit
  - `stpc_wvcnt`, `savg_wvcnt`, `sacc_wvcnt` → 13bit

### TFT_CTRL
- `TFT_CTRL/ROI_PROC.vhd` — entity ports + `svcnt`, `svcnt_out`, `svcnt_1d~6d`, `sreg_height` → 13bit
- `TFT_CTRL/TEST_PATTERN.vhd` — entity + `sreg_height`, `svcnt(+delays)` → 13bit
- `TFT_CTRL/TI/TI_TFT_CTRL.vhd` — entity + `sreg_height/offsety(+delays)`, `sroic_line_cnt`, `sgate_line_cnt`, `sgate_dummy_cnt` → 13bit
- `TFT_CTRL/TI/TI_TFT_TOP.vhd` — entity + 4 component decl + 내부 signals
- `TFT_CTRL/TI/TI_DATA_ALIGN.vhd` — entity + `svcnt`, `sreg_height`, `dumm_svcnt_out`, `hflp_svcnt_out`, `svcnt_1d/2d`, `ty_sivcnt` 타입, 2 component decl (TI_ERASE_DUMMY, TI_HORIZONTAL_FLIP)
- `TFT_CTRL/TI/TI_FRAME_MANAGER.vhd` — entity + component decl
- `TFT_CTRL/TI/TI_LVDS_RX.vhd` — entity + `sreg_height*`, `tcnt_array` 타입 분기
- `TFT_CTRL/TI/TI_HORIZONTAL_FLIP.vhd` — entity + 내부 signals
- `TFT_CTRL/TI/TI_ERASE_DUMMY.vhd` — entity + 내부 signals

### DDR3_CTRL
- `DDR3_CTRL/AXI_IF.vhd` — entity(5ch rvcnt) + AXI_RDATA_CONV component + `iconv_vcnt`
- `DDR3_CTRL/AXI_SUB_IF.vhd` — entity(5ch wvcnt/waddr) + `ireg_height` + `iconv_vcnt` + 5ch rvcnt + AXI_WDATA_CONV component + 내부 `sddr_ch*_*vcnt`, `w0-4ireg_height`, `r0-4ireg_height`, `sch*_wvcnt_*d`, `sconv_vcnt_*d`
- `DDR3_CTRL/DDR3_SYNC_GEN.vhd` — entity + `sreg_height`, `svcnt_out`
- `DDR3_CTRL/DDR3_TOP.vhd` — entity + 2 component decl + 5ch rvcnt + `conv_vcnt*`

### CALIBRATION (16 파일)
- `ACC_PROC.vhd`, `AVG_PROC.vhd`, `AVG_PROC_PARA4.vhd`
- `CALIB_TOP.vhd`, `CALIB_TOP_PARA4.vhd` — 7개 component decl + 12+ 내부 `svcnt_*`
- `CHANGE_DETECTOR.vhd` — 이미 13bit 였으나 entity 일부 정렬
- `DEFECT_DECODER.vhd`, `DEFECT_PROC.vhd`, `DEFECT_PROC_PARA4.vhd`
- `DGAIN_PROC.vhd`, `LINE_DEFECT_PROC.vhd`
- `MASK_OUT.vhd`, `MASK_PARA4.vhd`
- `TPC_PROC.vhd`, `TPC_PROC_1418.vhd`, `TPC_PROC_PARA4.vhd`

### IMAGE_PROC (15 파일)
- `IMG_PROC_TOP.vhd` — entity + 9 component decl + 7 signal block
- `IMG_PROC_PARA4.vhd` — entity + 5 component decl + 타입 분기
- `BRIGHT_CTRL.vhd`, `BritCont_master.vhd` (str/end_height 산술 13bit 확장 포함)
- `CONTRAST_CTRL.vhd`
- `DNR.vhd` — `mw_dina/doutb` padding 재배치(6b→5b), vcnt +1bit
- `EDGE.vhd`, `EQ_4096.vhd`, `EQ_CTRL_1x1.vhd`, `EQ_CTRL_1x1_para4.vhd`
- `MASKING_PROC.vhd`, `Matrix5x5.vhd`, `Mawari5x5.vhd`, `OSD.vhd`

### OUT_IF
- `OUT_IF/IMG_OUT_TOP.vhd` — entity + GEV_IF component + `svcnt_gev`
- `OUT_IF/GEV_IF.vhd` — entity + 2 component decl + `svcnt_gev_dconv`
- `OUT_IF/GEV_DATA_CONV.vhd` — entity + `sreg_height`, `svcnt_conv`
- `OUT_IF/GEV_DATA_MAPPING.vhd` — entity

### 시뮬레이션 TB
- `sim_1/new/TB_TI_DATA_ALIGN.vhd`
- `sim_1/new/TB_TI_FRAME_MANAGER.vhd`
- `sim_1/new/TB_TI_TFT_TOP.vhd`
- `sim_1/new/TB_ADI_FRAME_MANAGER.vhd`
- `sim_1/new/TB_ADI_TFT_TOP.vhd`

### TOP_HEADER
- `EXTxR2.srcs/sources_1/new/TOP_HEADER.vhd`
  - `FPGA_VER: x"2_01_11" → x"2_01_12"`
  - `FPGA_DATE: x"26_0423_14" → x"26_0423_16"`
  - 변경 이력 주석 1줄 추가

---

## 4. 수정 하지 않은 항목 (의도적)

| 항목 | 이유 |
|---|---|
| `width`, `hcnt`, `ihcnt`, `ohcnt`, `shcnt`, `offsetx`, `sreg_width`, `ireg_width` | 수평 축 — 3584 < 4095 이라 12bit 충분 |
| `brick_height`(`CHANGE_DETECTOR`) 8bit 슬라이스 | `reg_height(11 downto 4)` 파생. 폭 확장 후에도 의미 유지 (사용자 검토 가능) |
| `probe*` (ILA/VIO 컴포넌트 선언) | ILA IP 가 12bit probe 로 생성되어 있을 수 있음 → 연결부에서 슬라이스 처리 필요 (후속) |
| `SIM_ADAS1258`, `SIM_AFE2256` 내부 `svcnt` | ROIC 시뮬레이션 모델 — 해당 모델 line 수(≤4095) 에 맞춤 |
| `cores/s2i_xgige_*`, `cores/s2i_framebuf_*` 등 IP 코어 | S2I 암호화 IP. 확인 결과 height 포트 없음(스트림 기반). 우리 래퍼(`GEV_DATA_CONV/MAPPING`) 에서 height 처리 — 따라서 IP 수정 불필요 |
| `vitis/EXTREAM_fw/src/*.c` | 펌웨어는 32bit 그대로 써서 정상 동작. `fpga_info.h MAX_HEIGHT` 값은 빌드 옵션 확인 권장 (VHDL 작업 범위 외) |
| `EXTxR2.srcs/17_EXT3643R/` | XDC(핀 제약) 파일만 있음. VHDL 오버라이드 없음 |

---

## 5. 백업 정책

| 시점 | 처리 |
|---|---|
| 이번 작업 전 `.bak` 존재 파일 | `<file>.bak` → `<file>.bak_2604231608` 로 rotate |
| 이번 작업 직전 파일 상태 | `<file>.bak` 로 새로 복사 |

rotate 된 기존 `.bak` (3 건): `DDR3_TOP.vhd`, `EXTREAM_R.vhd`, `TOP_HEADER.vhd`

---

## 6. 검증 계획

### 6.1 Vivado Elaborate
- 전체 프로젝트 Elaborate → 타입/폭 mismatch 확인
- 예상되는 잔여 경고:
  - ILA `probe*` 폭 불일치 → 연결부에서 `svcnt(11 downto 0)` 슬라이스 또는 ILA IP 재생성
  - DPRAM 주소 `addra/addrb` 와 vcnt 폭 불일치 → 연결부 슬라이스
- width mismatch 에러가 있으면 파일/라인 별도 보고 후 수정

### 6.2 합성/P&R
- EXT3643R implementation run: WNS/TNS 전후 비교
- 13bit 곱셈/비교가 DSP48/LUT 사용량에 주는 영향 모니터

### 6.3 시뮬레이션
- `TOP_HEADER.vhd: SIMULATION = "ON"`
- `TB_TI_TFT_TOP`, `TB_TI_FRAME_MANAGER`, `TB_TI_DATA_ALIGN` 에서 height=4302 구동
- 확인 포인트:
  - `svcnt` 0 → 4301 까지 정상 카운트, 4302 번째에 프레임 동기
  - `sreg_height` = `"0_1000_1100_1110"` (0x10CE, 13bit) 유지
  - 비교식 `svcnt >= sreg_height - 1` 이 4301 에서 참

### 6.4 실기
1. 부트 직후 `REG(ADDR_HEIGHT)` readback = **4302** 확인 (펌웨어 `DBG_roi=1` 재빌드)
2. `roi 0 0 3584 4302` 명령 후:
   - GEV 수신 PC 에서 수신 이미지 크기 = **3584 × 4302** 확인
   - 프레임 내 모든 행 정상 데이터
3. 영상처리(밝기/대비/DNR/엣지/OSD) 정상 동작
4. DDR3 프레임 저장/NUC/offset/gain 체인 정상 동작

### 6.5 회귀
- **EXT2832R** (H=2832, 12bit 이내): 회귀 없어야 함
- **EXT4343R** (H=4343, 12bit 초과): 이번 수정으로 함께 해결되어야 함
- AFE2256 호환 유지 (CLAUDE.md 규칙 6)

---

## 7. 후속 작업 (이번 커밋 외)

1. **ILA IP 처리**: 합성 시 width mismatch 경고 발생 예상. 연결부에서 `svcnt(11 downto 0)` 슬라이스하거나 ILA IP 재생성.
2. **DEFECT 맵 포맷**: defect RAM 이 12bit row 주소 기반 → row≥4096 영역 결함 표현 불가. flash 포맷/펌웨어 확장 필요 (본 작업 범위 외).
3. **SIM_AFE3256**: EXT3643R 시뮬레이션용 AFE3256 ROIC 시뮬 모델 신규 작성 필요.
4. **펌웨어 `fpga_info.h MAX_HEIGHT`**: EXT3643R 빌드에서 4302 로 정의되어 있는지 `vitis/Makefile` 의 `EE_OPTIONS` 또는 모델별 매크로에서 확인.
5. **Vitis `calib.c`**: `defect[j][1] >= MAX_HEIGHT-2` 등 비교에서 `MAX_HEIGHT=4302` 가 `int` 로 처리되므로 펌웨어는 문제 없지만, flash 에 기록되는 row 좌표는 12bit 포맷이라 확인 필요.
6. **Vivado 합성 결과 공유**: 후속 세션에 에러/경고 로그 올려주시면 핀포인트 수정 가능.

---

## 8. 참고 위치

- 원 계획 파일: `C:\Users\bhmoom\.claude\plans\3584-4302-cozy-hare.md`
- 프로젝트 루트: `\\192.168.2.53\fpga0\work\EXTxR2_3643R_260421\`
- 메모리 맵 문서: `EXT_R_Series Memory Map_FPGA_v1.18.19_211102.xlsx`
- UART 명령: `UART Command 정리_211102.xlsx`
