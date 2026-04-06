# AFE3256 MicroBlaze/Vitis 펌웨어 구현 체크리스트

기준 문서: AFE3256 Datasheet (SBASAD5B, Nov 2024)
기준 흐름: Figure 6-26. Device Register Configuration Flow
작성 목적: Figure 6-26 기본 흐름은 코드화 완료. 각 단계별 세부 기능 중 아직 구현하지 않았거나 추가해야 할 항목 정리.
최종 검증일: 2026-04-06 (소스코드 교차 검증 완료)


## 0. 전체 Configuration Flow (Figure 6-26 요약)

Power ON - Device Reset - TRIM LOAD - Default Register Programming
- Power Mode and Input Charge Range Selection - Timing Register Programming
- Digital Offset Correction - Functionality and Noise Tests


## 1. Device Reset and TRIM LOAD (Table 6-29) -- ✅ 구현 완료

구현 위치: func_basic.c:576-588 (roic_3256_init)
동작: 0x00=0x0001 리셋 -> 1ms 대기 -> Legacy SPI(0x01=0x8000) -> TRIM LOAD 9단계
비고: TRIM LOAD 5ms 대기를 10ms로 여유있게 설정

### 1.1 Reset
- RESET 발행: Reg 0x00 bit0 = 1 -- ✅ func_basic.c:576
- SPI 모드 설정: Reg 0x01 = 0x8000 (Legacy) -- ✅ func_basic.c:577

### 1.2 TRIM LOAD 시퀀스 -- 전체 ✅
1. 0xAC / 0x8000 / REGAC_A = 1
2. 0x0B / 0x0020 / TRIM_CLK_EN = 1
3. 0x7B / 0x0800 / TRIM_SUP = 1
4. 0x7B / 0x8800 / TRIM_SUP=1, TRIM_LOAD_EN=1
5. 0x7B / 0x8840 / TRIM_LOAD=1, 10ms 대기
6. 0x7B / 0x8800 / TRIM_LOAD=0
7. 0x7B / 0x0800 / TRIM_LOAD_EN=0
8. 0x7B / 0x0000 / TRIM_SUP=0
9. 0x0B / 0x0000 / TRIM_CLK_EN=0


## 2. Default Register Programming (Table 6-30) -- ✅ 구현 완료

구현 위치: func_basic.c:590-615 (roic_3256_init)
동작: 20+개 레지스터 순차 설정, TG Essential은 PAGE_SELECT 전환 후 기록
모든 레지스터 설정 확인됨 -- ✅


## 3. Power Mode Selection (Table 6-20) -- △ 부분 구현

구현: func_basic.c:628-631 -- Low-Noise 고정
미구현: 런타임 Normal/LowPower/LowNoise 전환 함수

모드 / 0x86 / 0x88 / 0x8E / 상태
- Normal-Power / 0x0000 / 0x0000 / 0x0002 / ⚡ 전환함수 필요
- Low-Power / 0x0200 / 0x0002 / 0x0006 / ⚡ 전환함수 필요
- Low-Noise / 0x0400 / 0x0000 / 0x0002 / ✅ 초기화 시 고정

구현 상태:
- execute_cmd_sleep() -- ✅ func_cmd.c:5994
- execute_cmd_sleep_mode() -- ✅ func_cmd.c:6011
- execute_cmd_power_mode(int mode) -- ⚡ 필요
- execute_cmd_standby_enter() -- ⚡ 필요
- execute_cmd_standby_exit() -- ⚡ 필요


## 4. Input Charge Range (SEL_CFB) -- ✅ 구현 완료

구현 위치: func_basic.c:617-620, func_basic.c:2216-2223 (AFE3256_Cfb 12-step LUT)
동작: index 0~11 -> LUT -> Reg 0x82, binning 연동 포함
12 step 전체 ✅


## 5. Timing Generator (TG) Programming -- △ 부분 구현

구현: func_basic.c:646-718 -- Profile 파라미터 기반 TG 자동 계산
미구현: STR 런타임 전환 시 추가 레지스터(Table 8-4~8-6) 자동 업데이트

5.1 STR 설정 -- ✅ (func_basic.c:657-663)
5.2 TG Phase 계산 -- ✅ (func_basic.c:688-704)
5.3 TG Profile 레지스터 -- ✅ (func_basic.c:707-717)
5.4 STR별 추가 Config -- △ STR=0만 구현 (func_basic.c:634-644)
5.5 TP0/TP1 프로필 전환 -- ⚡ 미구현

구현 상태:
- TG 자동 계산 -- ✅ roic_3256_init 내부
- execute_cmd_str_change(int new_str) -- ⚡ 필요
- set_str_dependent_regs(int str, int fmclk) -- ⚡ 필요
- program_tg_profile(int profile) -- ⚡ 필요


## 6. LPF (Low-Pass Filter) 설정 -- △ 부분 구현

구현: func_basic.c:669-684 -- 4모드(221/106/52/26kHz) 초기화 시 설정
미구현: 런타임 독립 전환 함수

lpf_sel / NLPF / fLPF(kHz) / 상태
- 0 / 0 / 221 / ✅
- 1 / 4 / 106 / ✅
- 2 / 12 / 52 / ✅
- 3 / 28 / 26 / ✅

구현 상태:
- 초기화 시 LPF 4모드 -- ✅
- set_lpf_registers(nlpf_shr, nlpf_shs) -- ⚡ 필요


## 7. Digital Offset Correction (DOC) -- ✅ 구현 완료

구현 위치: func_cmd.c:6466-6495 (execute_cmd_doc)
Phase 1: ISOPANEL + ADD_CAP -- ✅
Phase 2: CALIB_START + DONE polling -- ✅
Phase 3: ISOPANEL 복귀 -- ✅

구현 상태:
- execute_cmd_doc() -- ✅ func_cmd.c:6466
- set_doc_enable(int enable) -- ⚡ 필요 (DOC ON/OFF 토글)


## 8. Charge Integration Mode -- △ 부분 구현

구현: func_basic.c:622-626 -- Integrate-Up 고정
미구현: 런타임 Up/Down 전환

Addr / Up(electron) / Down(hole) / 상태
- 0x80 / 0x080D / 0x080F / ✅ Up 고정
- 0xCF / 0x0000 / 0x0010 / ✅ Up 고정
- 0xE9 / 0x0000 / 0x0109 / ✅ Up 고정
- 0xD2 / 0x0000 / 0x9000 / ✅ Up 고정

구현 상태:
- set_integration_mode(int mode) -- ⚡ 필요


## 9. COMP Circuit -- ⚡ 미구현

4개 6:1 MUX, Internal DAC, CDUMP CAP


## 10. Temperature Sensor -- ✅ 구현 완료

구현 위치: func_basic.c:2113-2135 (read_roic_temp)
동작: Enable -> Read(0x78) -> 온도변환 -> Disable
UART: rtemp 명령
Enable 시퀀스 -- ✅
DIE_TEMP 읽기 + 변환 -- ✅
Disable -- ✅


## 11. Test Patterns -- ⚡ 미구현

## 12. Scan Direction -- ⚡ 미구현

## 13. Isolate Panel / Csensor Emulation -- △ 부분 구현

구현: DOC 시퀀스 내부에서만 사용
- DOC 내 ISOPANEL -- ✅
- set_isopanel(int enable) -- ⚡ 필요
- set_add_cap(int cap_pf) -- ⚡ 필요

## 14. Pixel Short Detection (TDEF) -- ✅ 구현 완료 (ON 고정)

구현: func_basic.c:591 -- EN_TDEF=1

## 15. Gate Driver Signal -- ⚡ 미구현

## 16. SPI Register Read -- ✅ 구현 완료

구현 위치: func_cmd.c:3930 (execute_cmd_rroic)
사용처: DOC polling, TG 읽기, bcal, 온도센서 등 20+곳 활용
UART: rreg addr 명령


## 17. 기능 구현 우선순위 정리

### ✅ 구현 완료
1. Device Reset / func_basic.c:576
2. TRIM LOAD / func_basic.c:579-588
3. Default Register Programming / func_basic.c:590-615
4. SEL_CFB 12-step LUT / func_basic.c:2216
5. DOC Sequence / func_cmd.c:6466
6. SPI Write (Legacy) / execute_cmd_wroic
7. SPI Register Read / func_cmd.c:3930 (execute_cmd_rroic)
8. Temperature Sensor / func_basic.c:2113
9. Pixel Short Detection / func_basic.c:591
10. Sleep Mode / func_cmd.c:5994

### △ 부분 구현 (런타임 전환 함수 필요)
1. Power Mode / Low-Noise 고정 / Normal/LowPower 전환 함수 필요
2. Integration Mode / Integrate-Up 고정 / Down 전환 함수 필요
3. TG Programming / STR=0 추가 레지스터만 / STR 런타임 전환 필요
4. LPF 설정 / 4모드 초기화 시 / 런타임 독립 전환 필요
5. ISOPANEL/ADD_CAP / DOC 내부에서만 / 독립 제어 함수 필요

### ⚡ 미구현 (우선순위 순)
1. TG STR 런타임 전환 / 높음 / scan time 변경 시 필수
2. Power Mode 전환 / 낮음 / 레지스터 3개 세트
3. Test Patterns / 낮음 / LVDS 검증
4. Integration Mode 전환 / 낮음 / 4개 레지스터
5. Scan Direction / 낮음 / Auto-reverse
6. Standby 모드 / 중간 / 6개 레지스터 + LVDS realign
7. COMP/DAC 설정 / 중간 / charge injection
8. LPF 런타임 전환 / 낮음 / Reg 0x96
9. ISOPANEL/ADD_CAP 독립 / 낮음 / 디버그용
10. DOC ON/OFF 토글 / 낮음 / Reg 0x51
11. Gate Driver Signal / 낮음 / DIG_TP 핀


## 18. AFE2256에서 AFE3256 차이점 요약

항목 / AFE2256 / AFE3256
- SPI SCK Max / -- / 10MHz (7.5MHz 사용)
- SEL_CFB 해상도 / 16 step / 12 step LUT, 0.3125pC
- Timing Profile / TP_SEL 제한 / PAGE_SELECT 무관
- 전원 / Dual supply / Single 1.85V
- DOC / -- / 내장 calibration engine
- SPI mode / -- / LEGACY_SPI_MODE=1 필수
