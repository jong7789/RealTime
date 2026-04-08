# AFE3256 Timing Register Reference

> **Source**: AFE3256 Datasheet (SBASAD5B – October 2023, Revised November 2024)
> **Purpose**: VS Code Claude Code 참조용 — PDF 직접 열람 불가하므로 텍스트로 정리
> **Target**: `roic_3256_init()` 함수 타이밍 레지스터 설정 부분

---

## 1. Timing Generator (TG) 개요

### 1.1 기본 동작 원리 (Section 6.3.1.4, Page 29-30)

- AFE3256은 내부 TG가 모든 타이밍 신호(IRST, SHR, SHS, LPF1, LPF2, TDEF, DF_SM[6:0])를 생성
- TG는 SYNC, MCLK, TP_SEL 세 외부 CMOS 신호로 동작
- SYNC 검출 후 MCLK 카운팅하여 모든 신호를 자동 생성
- 신호 주기 = `tSCAN` (= 2^(8+STR) × tMCLK)
- A_BZ는 `2 × tSCAN` 주기

### 1.2 STR 설정과 tSCAN 관계 (Equation 17)

```
tMCLK = tSCAN / 2^(8+STR)
```

- **STR = 0**: tSCAN을 256개의 등간격 시간 슬롯으로 분할
- **STR = 1**: 512 슬롯, **STR = 2**: 1024 슬롯, **STR = 3**: 2048 슬롯
- 모든 STR 설정에서 **timing 레지스터 값은 0~255 범위 내 슬롯 인덱스**로 표현

### 1.3 tstep 계산 (Equation 19)

```
tstep = 2^STR × tMCLK
```

| STR | tMCLK 범위 | 비고 |
|:---:|:---|:---|
| 0 | 31.25ns ≤ tMCLK ≤ 100ns | 10MHz ≤ fMCLK ≤ 32MHz |
| 1, 2, 3 | 50ns ≤ tMCLK ≤ 100ns | 10MHz ≤ fMCLK ≤ 20MHz |

**중요**: STR=0이면 N(레지스터 값) = MCLK cycle 수가 그대로. STR>0이면 N × 2^STR이 실제 cycle.

---

## 2. Charge Acquisition 신호 흐름 (Section 6.3.1.1, Page 21-23)

### 2.1 한 scan의 위상 순서

```
[Reset Phase]                        [Integration Phase]
IRST↑ → IRST↓ → SHR↑ → LPF1↑ → SHR↓ → SHS↑ → LPF2↑ → TFT_ON → TFT_OFF → SHS↓
        |        |       |       |               |             
        Reset    SHR     LPF1    Reset           Signal        
        end     start    on      sample          sample        
                                  end             end          
```

### 2.2 핵심 신호 의미

| 신호 | 역할 |
|:---:|:---|
| **IRST** | Integrator reset (capacitor 초기화). High일 때 reset 상태 |
| **SHR** | Reset level sample. CDS reset capacitor와 integrator 출력 연결 |
| **LPF1** | SHR phase의 dynamic LPF. Off→On 시 high BW→low BW 전환 |
| **SHS** | Signal level sample. CDS signal capacitor와 integrator 출력 연결 |
| **LPF2** | SHS phase의 dynamic LPF. Off→On 시 high BW→low BW 전환 |
| **TDEF** | Pixel short detection. 비정상 픽셀 감지 시 integrator 즉시 리셋 |
| **DF_SM[6:0]** | Charge injection compensation 캐패시터 스위칭 |

### 2.3 LPF의 dynamic 동작 핵심

- **LPF1 = Low일 때**: SHR이 integrator 출력을 high bandwidth로 추적 (빠른 settling)
- **LPF1 = High일 때**: low bandwidth로 노이즈 제거하며 sample
- **SHR fall edge에 reset level이 CDS에 hold됨**
- LPF2도 동일 원리, signal level 샘플링용

---

## 3. 핵심 타이밍 레지스터

### 3.1 Register 0x3A — IRST_REG (Page 68-69)

```
Bit[15:14]: 0 (must write 0)
Bit[13:0]:  IRST_REG (R/W)
```

**의미**: IRST rise → IRST fall 폭 (= NIRST)

```c
execute_cmd_wroic(0x3A, N_irst);
```

⚠ **주의**: `IRST_REG = 0`이면 IRST가 scan 전체 동안 계속 high (integrator 영구 reset)

### 3.2 Register 0x3B — SHR_LPF1_REG (Page 69)

```
Bit[15:14]: 0 (must write 0)
Bit[13:0]:  SHR_LPF1_REG (R/W)
```

**의미**: SHR rise → LPF1 rise 폭 (= NSHR-LPF1)

```c
execute_cmd_wroic(0x3B, N_shr_lpf1);
```

### 3.3 Register 0x3E — LPF1_REG (Page 70)

```
Bit[15:14]: SDOUT_MUX_SEL[1:0]
Bit[13:0]:  LPF1_REG (R/W)
```

**의미**: LPF1 rise → SHR fall 폭 (= NLPF1)

```c
execute_cmd_wroic(0x3E, N_lpf1);
```

### 3.4 Register 0x3D — SHS_LPF2_REG (Page 70)

```
Bit[15:14]: SDOUT_MUX_SEL[3:2]
Bit[13:0]:  SHS_LPF2_REG (R/W)
```

**의미**: SHS rise → LPF2 rise 폭

```c
execute_cmd_wroic(0x3D, fmax(N_shs_lpf2_min, N_TFT));
```

⚠ **중요**: 단순히 N_shs_lpf2가 아니라 **`max(N_shs_lpf2_min, N_TFT)`** 를 써야 함!
- N_TFT가 클 때(긴 게이트 ON 시간)는 N_TFT를 사용
- N_TFT가 작을 때는 N_shs_lpf2_min(데이터시트 최소값) 사용

### 3.5 Register 0x3C — DIS_TDEF_REG (Page 69)

```
Bit[15:14]: SDOUT_MUX_SEL[5:4]
Bit[13:0]:  DIS_TDEF_REG (R/W)
```

**의미**: TDEF fall → SHS fall 폭 (= NTDEF + NLPF2)

```c
execute_cmd_wroic(0x3C, N_tdef + N_lpf2);
```

⚠ **중요**: `N_tdef`는 **고정 최소값** (STR에 따라 다름):
- **STR 0/1**: N_tdef = ceil(1.0µs / tstep), 최소 30 cycles @ 30MHz
- **STR 2/3**: N_tdef = ceil(2.0µs / tstep)
- **N_tdef = N_shs로 설정하면 안 됨** (LPF2가 두 번 더해지는 효과)

### 3.6 Register 0x1E — TG_SIG0/1_REG, 0x1F — TG_SIG2_REG (Page 67-68)

```
0x1E:
  Bit[15:8]: TG_SIG1_REG
  Bit[7:0]:  TG_SIG0_REG

0x1F:
  Bit[15:8]: 0
  Bit[7:0]:  TG_SIG2_REG
```

**의미**: Essential TG 신호 (SIG0, SIG1, SIG2)의 폭 — 디바이스 정상 동작에 필수

```c
execute_cmd_wroic(0x1E, (N_sig1 << 8) | N_sig0);
execute_cmd_wroic(0x1F, N_sig2);
```

⚠ **주의**: 이 신호들은 메인 scan에는 영향 없지만 **데이터시트 사양 만족**을 위해 필수

---

## 4. 최소 신호 폭 (Section 8.1.1.4.1)

### 4.1 STR 0/1 (Table 8-1)

| Symbol | 설명 | Min Duration |
|:---:|:---|:---:|
| tIRST | IRST 폭 | **1.0 µs** |
| tSHR-LPF1 | SHR rise → LPF1 rise | **1.2 µs** |
| tLPF1-min | SHR LPF 최소 settling | **1.6 µs** |
| tSHS-LPF2-min | SHS rise → LPF2 rise 최소 | **1.2 µs** |
| tLPF2-min | SHS LPF 최소 settling | **1.6 µs** |
| tTDEF | TDEF off → LPF2 rise | **1.0 µs** |
| tSIG0 | Essential TG 0 | **0.75 µs** |
| tSIG1 | Essential TG 1 | **0.2 µs** |
| tSIG2 | Essential TG 2 | **0.5 µs** |

### 4.2 STR 2/3 (Table 8-2)

| Symbol | 설명 | Min Duration |
|:---:|:---|:---:|
| tIRST | IRST 폭 | **1.5 µs** |
| tSHR-LPF1 | SHR rise → LPF1 rise | **2.5 µs** |
| tLPF1-min | SHR LPF 최소 settling | **1.6 µs** |
| tSHS-LPF2-min | SHS rise → LPF2 rise 최소 | **2.5 µs** |
| tLPF2-min | SHS LPF 최소 settling | **1.6 µs** |
| tTDEF | TDEF off → LPF2 rise | **2.0 µs** |
| tSIG0/1/2 | Essential TG | (STR0/1과 동일) |

### 4.3 N 값 계산

```
N_irst       = ceil(tIRST       / tstep)
N_shr_lpf1   = ceil(tSHR_LPF1   / tstep)
N_lpf1_min   = ceil(tLPF1_min   / tstep)
N_shs_lpf2_min = ceil(tSHS_LPF2_min / tstep)
N_lpf2_min   = ceil(tLPF2_min   / tstep)
N_tdef       = ceil(tTDEF       / tstep)
```

---

## 5. SHR / SHS 폭 계산 절차 (Section 8.1.1.4.2)

### 5.1 NTFT-max 계산 (Equation 22)

```
NTFT-max = 256 - (NIRST + NSHR-LPF1 + NLPF1-min + NLPF2-min) - 4
```

- **-4**: IRST↓→SHR↑, SHR↓→SHS↑, SHS↓→IRST↑ 사이의 non-overlap 시간
- NTFT는 NTFT-max를 초과할 수 없음

### 5.2 Nextra 계산 (Equation 21)

```
Nextra = 256 - (NIRST + NSHR-LPF1 + max(NSHS-LPF2-min, NTFT)) - 4
```

⚠ **중요**: `max(NSHS-LPF2-min, NTFT)` 사용. NTFT가 크면 그것이, 작으면 최소값 사용.

### 5.3 NLPF1, NLPF2 분배 (Equation 24, 25)

```
NLPF1 = max(floor(Nextra/2), NLPF1-min)
NLPF2 = max(Nextra - NLPF1, NLPF2-min)
```

→ **남는 시간을 LPF1과 LPF2에 균등 분배**, 단 각각 최소값 보장

### 5.4 NSHR, NSHS 계산 (Equation 26, 27)

```
NSHR = NSHR-LPF1 + NLPF1
NSHS = NSHS-LPF2 + NLPF2
```

### 5.5 SHS_RISE 최적화 (Equation 12, Page 38)

```
SHS_RISE = IRST_REG + SHR_LPF1_REG + LPF1_REG + 3
```

⚠ **권장사항**: SHS_RISE는 **홀수**(2n+1) 형태가 되도록 NLPF1을 ±1 조정
- 예: SHS_RISE = 126이면 NLPF1을 1 줄여서 SHS_RISE = 125로 만듦, NLPF2는 1 늘림

---

## 6. STR 설정별 레지스터 (Section 8.1.1.4.2.1)

### 6.1 STR = 0, 10MHz ≤ fMCLK ≤ 20MHz (Table 8-4)

```c
execute_cmd_wroic(0xAD, 0x1400);
execute_cmd_wroic(0xB0, 0x0000);
execute_cmd_wroic(0xB2, 0x7D80);
execute_cmd_wroic(0xB5, 0x0010);
execute_cmd_wroic(0xB6, 0x0000);
execute_cmd_wroic(0xC0, 0x0000);
execute_cmd_wroic(0xC3, 0x0020);
execute_cmd_wroic(0xAF, 0x0000);
execute_cmd_wroic(0xBC, 0x0000);
execute_cmd_wroic(0x81, 0x0000);
execute_cmd_wroic(0x0B, 0x0006);
```

### 6.2 STR = 0, 20MHz < fMCLK ≤ 32MHz (Table 8-5) ⭐ 30MHz 사용 시

```c
execute_cmd_wroic(0xAD, 0x1800);   // REGAD_A=0, REGAD_B=1, REGAD_C=1
execute_cmd_wroic(0xB0, 0xA000);   // REGB0_A=1, REGB0_B=2
execute_cmd_wroic(0xB2, 0x7180);   // REGB2_A=0, REGB2_B=3, REGB2_C=4, REGB2_D=3
execute_cmd_wroic(0xB5, 0x0200);   // REGB5_G=1
execute_cmd_wroic(0xB6, 0x0800);   // REGB6_A=2
execute_cmd_wroic(0xC0, 0x0210);   // REGC0_A=2, REGC0_B=1
execute_cmd_wroic(0xC3, 0x48A0);   // REGC3_A=5, REGC3_B=2, REGC3_C=1
execute_cmd_wroic(0xAF, 0x0301);   // REGAF_A=1, REGAF_B=6
execute_cmd_wroic(0xBC, 0x0200);   // REGBC_A=1
execute_cmd_wroic(0x81, 0x0000);   // REG81_A=0
execute_cmd_wroic(0x0B, 0x0006);   // REGB_E=1, REGB_F=1
```

### 6.3 STR = 2/3, 10MHz ≤ fMCLK ≤ 20MHz (Table 8-6)

```c
execute_cmd_wroic(0xAD, 0x1C00);
execute_cmd_wroic(0xB0, 0x2000);
execute_cmd_wroic(0xB2, 0x7DC8);
execute_cmd_wroic(0xB5, 0x00FA);
execute_cmd_wroic(0xB6, 0x0000);
execute_cmd_wroic(0xC0, 0x0000);
execute_cmd_wroic(0xC3, 0x00A0);
execute_cmd_wroic(0xAF, 0x0000);
execute_cmd_wroic(0xBC, 0x0000);
execute_cmd_wroic(0x81, 0x0040);
execute_cmd_wroic(0x0B, 0x2706);
```

⚠ **중요**: STR을 변경할 때는 반드시 위 레지스터들도 새 STR에 맞게 재프로그래밍해야 함

---

## 7. LPF Cutoff Frequency (Section 6.3.3, Page 34)

### 7.1 LPF 공식 (Equation 6, 7)

```
fLPF (Hz) = 10^6 / (4.52 + NLPF × 1.22)
TLPF (s) = 1 / (2π × fLPF)
```

### 7.2 NLPF 설정값 (Table 6-10)

| NLPF | REG (hex) | fLPF (kHz) | TLPF (µs) | 3×TLPF (µs) |
|:---:|:---:|:---:|:---:|:---:|
| 0 | 0x00 | 221 | 0.7 | 2.1 |
| 1 | 0x01 | 174 | 0.9 | 2.7 |
| 2 | 0x02 | 144 | 1.1 | 3.3 |
| 4 | 0x04 | 106 | 1.5 | 4.5 |
| 8 | 0x08 | 70 | 2.3 | 6.9 |
| 12 | 0x0C | 52 | 3.1 | 9.3 |
| 16 | 0x10 | 42 | 3.8 | 11.4 |
| 28 | 0x1C | 26 | 6.1 | 18.3 |
| 32 | 0x20 | 23 | 6.9 | 20.7 |
| 64 | 0x40 | 12 | 13.3 | 39.9 |

### 7.3 LPF 선택 권장사항

- LPF 사용 가능 시간(`tLPF-available`)에서 **`3 × TLPF` 시간**이 확보되도록 선택
- **NLPF_SHR = NLPF_SHS** 사용 권장 (최적 노이즈 성능)
- 가장 낮은 cutoff frequency 선택이 노이즈 측면 최적

### 7.4 Register 0x96 — NLPF 설정

```c
execute_cmd_wroic(0x96, (1 << 15) | (NLPF_SHS << 8) | NLPF_SHR);
// bit15 = REG96_C = 1 (default 설정)
```

---

## 8. Application Examples (참고용)

### 8.1 Application-1: Static (Section 8.2.1)

- tSCAN = 102.4µs, tTFT = 75µs, **STR = 3**, MCLK = 20MHz
- tstep = 400ns
- N_IRST = 4, N_SHR-LPF1 = 7, N_LPF1 = 27, N_LPF2 = 27, N_TDEF = 5
- N_TFT = 187 → Register 0x3D = max(NSHS-LPF2-min, NTFT) = **187 = 0x00BB**

### 8.2 Application-2: Dynamic (Section 8.2.2) ⭐ 현재 코드 하드코딩값 출처

- tSCAN = 12.8µs, tTFT = 7µs, **STR = 0, MCLK = 20MHz**
- tstep = 50ns
- N_IRST = 20, N_SHR-LPF1 = 24, N_LPF1 = 34, N_LPF2 = 34, N_TDEF = 20
- N_TFT = 140 → Register 0x3D = **140 = 0x008C**
- TG_SIG0 = 15, TG_SIG1 = 4, TG_SIG2 = 10
  - 0x1E = (4<<8 | 15) = **0x040F**
  - 0x1F = 10 = **0x000A**

⚠ **현재 코드의 하드코딩 값(0x008C, 0x040F, 0x000A)은 Application-2 (20MHz STR0)에서 그대로 가져온 것**
- **30MHz STR0 환경에서 사용 시 부적절** — tstep가 33.33ns로 다르기 때문에 N값을 재계산해야 함

### 8.3 Application-3: Ultra-Fast (Section 8.2.3)

- tSCAN = 8µs, **STR = 0, MCLK = 32MHz**
- tstep = 31.25ns
- N_TFT = 128 > N_TFT-max = 77 → Register 0x3D = **77** (NTFT-max로 clip)
- SHS_RISE 최적화: 126 → 125 (홀수 보정), NLPF1 51, NLPF2 53

---

## 9. Timing Profile (TP0/TP1) (Section 6.3.1.4.1, Page 31-32)

- AFE3256은 두 개의 timing profile (TP0, TP1) 지원
- TP_SEL 핀으로 즉시 전환 가능 (SPI 재프로그래밍 불필요)
- 두 profile은 같은 register address 공유, **PAGE_SELECT0/1**로 구분
- **사용 안 하는 inactive profile에 SPI write** 권장 (active 동작 방해 방지)

### Timing Profile 프로그래밍 시 주의

```c
// TP1 프로그래밍 시
execute_cmd_wroic(0x03, 0x0006);   // PAGE_SELECT0=1, PAGE_SELECT1=1
// ... 타이밍 레지스터 설정 ...
execute_cmd_wroic(0x03, 0x0000);   // PAGE_SELECT 복원
```

⚠ **AFE225x 차이**: AFE3256은 TP_SEL과 무관하게 프로그래밍 가능하지만, **active profile에 쓰면 진행 중인 scan을 방해**할 수 있음

---

## 10. 디바이스 초기화 순서 (Section 6.5.2)

```
1. Power ON (Power Supply Sequencing 준수)
2. Device Reset                          ← 0x00 = 0x0001
3. SPI 모드 설정                         ← LEGACY_SPI_MODE = 1
4. TRIM LOAD Operation (Table 6-29)      ← 0xAC, 0x0B, 0x7B 시퀀스
5. Default Register Settings (Table 6-30) ← 0x80, 0x94, 0x91, ... 등
6. Power Mode 선택                       ← POWER_MODE
7. Input Charge Range 선택               ← SEL_CFB0/1 (Register 0x82)
8. Timing Register Programming           ← 0x3A, 0x3B, 0x3C, 0x3D, 0x3E, 0x1E, 0x1F
9. STR-Specific Register Settings        ← 0xAD, 0xB0, 0xB2, ... (Table 8-4/5/6)
10. Filter Selection                     ← 0x96 (NLPF_SHR/SHS)
11. Digital Offset Correction (선택)     ← Table 6-32 시퀀스
```

---

## 11. 현재 코드 (`roic_3256_init`) 검증 결과

### ✅ 잘 된 부분

1. **Reset / TRIM LOAD / Default Register**: 데이터시트 시퀀스 정확히 따름
2. **0x3A, 0x3B, 0x3E**: `N_irst`, `N_shr_lpf1`, `N_lpf1` 직접 사용 — 정확
3. **N_extra 계산**: `256 - (N_irst + N_shr_lpf1 + fmax(N_shs_lpf2, N_TFT)) - 4` — Equation 21 정확
4. **NLPF1/NLPF2 분배**: `floor(N_extra/2)`, `N_extra - N_lpf1` — Equation 24/25 정확
5. **N_TFT 계산**: `256 - (N_irst + N_shr_lpf1 + N_lpf1_min + N_lpf2_min) - 4` — Equation 22 정확
6. **STR-Specific 레지스터 (0xAD, 0xB0, ...)**: 30MHz 기준 Table 8-5 값 정확
7. **FPGA 레지스터**: STR0 기준 N값 직접 사용 (`REG(ADDR_ROIC_INTRST) = N_irst` 등)

### ⚠ 문제점 및 수정 권장사항

#### 문제 1: Register 0x3D 하드코딩 — **수정 필요**

```c
// 현재 코드 (잘못됨)
//    execute_cmd_wroic(0x3D, fmax(N_shs_lpf2, T_tft));
execute_cmd_wroic(0x3D, 0x008C);

// 수정안
execute_cmd_wroic(0x3D, fmax(N_shs_lpf2, N_TFT));
```

**이유**:
- 0x008C(140)는 **Application-2 (20MHz STR0)** 예제 값
- 30MHz STR0에서는 tstep가 다르므로(33.33ns vs 50ns) 재계산 필요
- N_extra 계산은 동적인데 0x3D만 고정이라 **로직 불일치**

#### 문제 2: `N_tdef = N_shs` — **수정 필요**

```c
// 현재 코드 (잘못됨)
u32 N_tdef = N_shs;

// 수정안
u32 N_tdef;
if(REG(ADDR_ROIC_STR) <= 1)
    N_tdef = ceil(1000 / T_step);   // STR 0/1: tTDEF = 1.0µs
else
    N_tdef = ceil(2000 / T_step);   // STR 2/3: tTDEF = 2.0µs
```

**이유**:
- `N_tdef`는 데이터시트상 **고정 최소값** (STR 0/1: 1.0µs, STR 2/3: 2.0µs)
- `N_tdef = N_shs`로 설정하면 0x3C 레지스터에 `N_shs + N_lpf2`가 들어가
  → 의도한 `N_tdef + N_lpf2`보다 훨씬 큰 값
- LPF2가 사실상 두 번 더해지는 효과 발생

#### 문제 3: 0x1E, 0x1F 하드코딩 — **선택적 수정**

```c
// 현재 코드
execute_cmd_wroic(0x1E, 0x040F);   // Application-2 값
execute_cmd_wroic(0x1F, 0x000A);   // Application-2 값

// 수정안
u32 N_sig0 = ceil(750 / T_step);   // tSIG0 = 0.75µs
u32 N_sig1 = ceil(200 / T_step);   // tSIG1 = 0.2µs
u32 N_sig2 = ceil(500 / T_step);   // tSIG2 = 0.5µs
execute_cmd_wroic(0x1E, (N_sig1 << 8) | N_sig0);
execute_cmd_wroic(0x1F, N_sig2);
```

**이유**: Application-2 (20MHz STR0) 값이 30MHz STR0에서는 잘못됨. 다만 SIG 신호들은 메인 scan에 영향이 적어 우선순위는 낮음.

#### 문제 4 (선택): SHS_RISE 홀수 보정

데이터시트 권장사항으로, 최적 성능을 위해 SHS_RISE = (2n+1) 형태가 되도록 NLPF1, NLPF2를 ±1 조정:

```c
u32 SHS_RISE = N_irst + N_shr_lpf1 + N_lpf1 + 3;
if((SHS_RISE & 1) == 0) {  // 짝수면
    N_lpf1--;
    N_lpf2++;
}
```

---

## 12. 30MHz STR0 기준 권장 설정 요약

| 항목 | 값 | 비고 |
|:---:|:---:|:---|
| MCLK | 30 MHz | tMCLK = 33.33ns |
| STR | 0 | tSCAN = 256 × 33.33ns = 8.533µs |
| tstep | 33.33ns | 2^0 × tMCLK |
| N_IRST (min) | 30 | ceil(1.0µs / 33.33ns) |
| N_SHR-LPF1 (min) | 36 | ceil(1.2µs / 33.33ns) |
| N_LPF1-min | 48 | ceil(1.6µs / 33.33ns) |
| N_LPF2-min | 48 | ceil(1.6µs / 33.33ns) |
| N_TDEF | 30 | ceil(1.0µs / 33.33ns), STR 0/1 |
| N_SIG0 | 23 | ceil(0.75µs / 33.33ns) |
| N_SIG1 | 6 | ceil(0.2µs / 33.33ns) |
| N_SIG2 | 15 | ceil(0.5µs / 33.33ns) |
| NLPF (221kHz) | 0 | 30MHz STR0의 유일 가능 LPF setting |

**N_TFT-max 계산** (30MHz STR0, 최소값 가정):
```
N_TFT-max = 256 - (30 + 36 + 48 + 48) - 4 = 90
→ 최대 TFT = 90 × 33.33ns ≈ 3.0µs
```

⚠ **30MHz STR0의 제약**: 짧은 tSCAN(8.533µs) 때문에 LPF는 **221kHz (NLPF=0, TLPF=0.7µs)** 만 사용 가능

---

## 13. 자주 하는 실수 (Common Pitfalls)

1. **0x3D를 N_shs_lpf2만 사용** → 반드시 `max(N_shs_lpf2, N_TFT)` 사용
2. **N_tdef를 N_shs와 동일 설정** → 데이터시트 최소값(STR별 1µs/2µs) 사용
3. **STR-Specific 레지스터 누락** → STR 변경 시 0xAD, 0xB0, 0xB2 등 모두 재설정
4. **page select 미복원** → TG profile 쓰고 나서 0x03 = 0x0000 복원 필수
5. **SHS_RISE 홀수 미보정** → 가능하면 (2n+1) 형태로 맞춤
6. **NLPF_SHR ≠ NLPF_SHS** → 노이즈 최적화를 위해 같은 값 사용 권장
7. **활성 profile에 SPI write** → inactive profile에 쓰는 게 안전
8. **MCLK 멈춘 상태에서 TRIM LOAD** → MCLK 동작 중이어야 함

---

## 14. 참조 위치 (데이터시트 페이지)

| 항목 | 페이지 | Section |
|:---|:---:|:---|
| Charge Acquisition 동작 | 21-23 | 6.3.1.1 |
| Timing Generator 개요 | 29-30 | 6.3.1.4 |
| Timing Profiles | 31-32 | 6.3.1.4.1 |
| LPF (Low-Pass Filter) | 34 | 6.3.3 |
| SHS_RISE 공식 (Eq. 12) | 38 | 6.3.4.5 |
| Timing Register 0x3A-0x3E | 68-70 | 7.1.20-7.1.24 |
| Default Register Settings | 55-56 | 6.5.2.2, Table 6-30 |
| Programming the TG (절차) | 105-107 | 8.1.1.4 |
| Minimum Signal Durations | 106 | Table 8-1, 8-2 |
| Timing Register Configuration | 107 | Table 8-3 |
| STR-Specific Registers | 108-109 | Table 8-4, 8-5, 8-6 |
| Application-1 (102.4µs/STR3) | 116-118 | 8.2.1 |
| Application-2 (12.8µs/STR0) | 120-121 | 8.2.2 |
| Application-3 (8µs/STR0) | 122-123 | 8.2.3 |
