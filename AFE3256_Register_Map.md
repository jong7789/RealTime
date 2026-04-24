# AFE3256 Register Map Reference

기준 문서: AFE3256 Datasheet SBASAD5B, Nov 2024, Section 7

주소 0x20~0x85 범위는 PAGE_SELECT 상태에 따라 다른 레지스터가 매핑됨.
- PAGE_SELECT0=0, PAGE_SELECT1=0 (0x03=0x0000): Configuration page
- PAGE_SELECT0=1 (0x03=0x0002): TG Profile 0
- PAGE_SELECT1=1 (0x03=0x0004): TG Profile 1
- PAGE_SELECT0=1, PAGE_SELECT1=1 (0x03=0x0006): TG Profile 0 and 1 동시


## Section 7.1 COMMON and Configuration Register Map

PAGE_SELECT = 0 상태에서 접근

### 0x00 - Device Control
- bit[1]: REG_READ (1=read mode, 이후 write 불가)
- bit[0]: RESET (1=device reset, self-clearing, 400ns 대기)

### 0x01 - SPI Mode
- bit[15]: LEGACY_SPI_MODE (1=legacy SPI, 0=daisy chain)
- bit[3]: SPI_BURST_MODE

### 0x03 - Page Select
- bit[1]: PAGE_SELECT0 (1=TG Profile 0 선택)
- bit[0]: PAGE_SELECT1 (1=TG Profile 1 선택)

### 0x05 - Misc Control
- bit[3:2]: REG5_A
- bit[1:0]: REG5_B

### 0x08 - Misc Control
- bit[2]: REG8_A
- bit[0]: MSB_LSB_SWAP

### 0x09 - Misc Control
- bit[9:8]: REG9_A
- bit[1:0]: REG9_B

### 0x0B - Multi-function Control
- bit[5]: TRIM_CLK_EN
- bit[4]: EN_SPARE_TG
- bit[2]: REGB_D
- bit[1]: REGB_E
- bit[0]: REGB_F
- 주의: Default Register Table 기본값 0x0006 (REGB_E=1, REGB_F=1)
- STR-specific 값도 이 레지스터에 있음

### 0x0D - COMP Enable / ISOPANEL / ADDCAP
- bit[14]: ISOPANEL3
- bit[11]: ADDCAP_EN
- bit[10]: CDUMP_EN4
- bit[7]: CDUMP_EN3
- bit[6]: CDUMP_EN2
- bit[5]: CDUMP_EN1
- bit[3]: INT_DAC_EN
- COMP enable 시 0x04E0 (DAC 미사용) 또는 0x04E8 (DAC 사용)
- CDUMP_EN1~4 + CDUMP_EN5(0x86) 모두 1이어야 COMP 동작

### 0x13 - Misc
- bit[9]: REG13_A

### 0x14 - LVDS_CUSTOM_PATTERN[47:32]
### 0x15 - LVDS_CUSTOM_PATTERN[31:16]
### 0x16 - LVDS_CUSTOM_PATTERN[15:0]
### 0x17 - LVDS_CUSTOM_PATTERN_TOGGLE[47:32]
### 0x18 - LVDS_CUSTOM_PATTERN_TOGGLE[31:16]
### 0x19 - LVDS_CUSTOM_PATTERN_TOGGLE[15:0]

### 0x1A - Test Pattern Control
- bit[15]: ALIGN_BITS_IN_TESTMODE
- bit[3:1]: LVDS_PATTERN_SELECT (000~111)
- bit[0]: TEST_PATTERN_EN

### 0x1E - TG_SIG0 / TG_SIG1
- bit[15:8]: TG_SIG1_REG
- bit[7:0]: TG_SIG0_REG

### 0x1F - TG_SIG2
- bit[7:0]: TG_SIG2_REG

### 0x39 - DIG_TP_MUX_SEL
- bit[15:10]: DIG_TP_MUX_SEL (6-bit, TG signal probe 선택)

### 0x3A - IRST_REG
- bit[7:0]: IRST_REG (integrator reset duration, 0~255 steps)
- Configuration page (PAGE_SELECT 불필요)

### 0x3B - SHR_LPF1_REG
- bit[7:0]: SHR_LPF1_REG
- Configuration page (PAGE_SELECT 불필요)

### 0x3C - DIS_TDEF_REG / SDOUT_MUX_SEL
- bit[15:14]: SDOUT_MUX_SEL[3:2]
- bit[7:0]: DIS_TDEF_REG (= N_tdef + N_lpf2)

### 0x3D - SHS_LPF2_REG / SDOUT_MUX_SEL
- bit[15:14]: SDOUT_MUX_SEL[1:0]
- bit[7:0]: SHS_LPF2_REG (= max(N_shs_lpf2, N_TFT))

### 0x3E - LPF1_REG / SDOUT_MUX_SEL
- bit[15:14]: SDOUT_MUX_SEL[5:4]
- bit[7:0]: LPF1_REG

### 0x3F - EN_TP_ON_SDOUT
- bit[15]: EN_TP_ON_SDOUT (1=SDOUT에 TG signal probe 출력)

### 0x4B - Calibration Control
- bit[15]: CALIB_START (1=calibration 시작)
- bit[14]: CALIB_DONE (read only, 1=완료)
- bit[1:0]: CALIB_MODE

### 0x4C - Calibration Config
- bit[15]: REG4C_D
- bit[4:0]: CALIB_NUM_AVG (averaging 라인 수 설정)

### 0x51 - Digital Offset / Misc (Configuration page)
- bit[9]: DIG_OFF_CORR_EN1
- bit[8]: DIG_OFF_CORR_EN2
- bit[2]: REG51_A
- bit[1]: REG51_B
- 주의: TG page의 0x51(TG_ESSENTIAL1)과 다른 레지스터임

### 0x69 - Version ID
- bit[15:0]: VER_ID (read only)

### 0x6A - DIE_ID[57:48]
### 0x6B - DIE_ID[47:32]
### 0x6C - DIE_ID[15:0]

### 0x6D - DAC Code
- bit[7:0]: DAC_CODE (0~255)
- DAC output = DAC_CODE / 256 x 1.25V

### 0x70 - Misc (Configuration page)
- bit[9:8]: REG70_A
- 주의: TG page의 0x70(TMPSNS_RISE)과 다른 레지스터임

### 0x75 - Misc (Configuration page)
- bit[9:8]: REG75_A
- 주의: TG page의 0x75(DF_SM1_FALL)과 다른 레지스터임

### 0x78 - DIE_TEMP (Configuration page)
- bit[8:0]: DIE_TEMP (read only, 온도 센서 값)
- T(degC) = (0.97 x D0 - 512 x floor(D0/256)) / 2.45 + 108
- 주의: TG page의 0x78(DF_SM3_RISE)과 다른 레지스터임

### 0x7B - TRIM Control
- bit[15]: TRIM_LOAD_EN
- bit[11]: TRIM_SUP
- bit[6]: TRIM_LOAD

### 0x80 - Main Control
- bit[15:14]: SEL_PANEL_BIAS (0x2=EXTC_I, 0x3=COMP3)
- bit[11]: EN_TDEF (pixel short detection)
- bit[3]: REG80_C
- bit[2]: REG80_B
- bit[1]: INTG_DOWN (0=integrate up, 1=integrate down)
- bit[0]: REG80_A
- Default: 0x080D (EN_TDEF=1, integrate up)

### 0x81 - Scan Direction / STR-specific
- bit[7:6]: REG81_A (STR-specific: STR0/1=0x00, STR2/3=0x40)
- bit[1]: AUTO_REV (1=auto reverse mode)
- bit[0]: REV_SCAN (1=reverse scan)

### 0x82 - Input Charge Range (SEL_CFB)
- bit[14:8]: SEL_CFB1
- bit[6:0]: SEL_CFB0
- QFS = 1.25V x CFB(pF)
- 40-step, 0.3125pC resolution

### 0x84 - Misc
- bit[7:0]: REG84_A

### 0x86 - COMP / Power Mode
- bit[15]: CDUMP_EN5
- bit[10:9]: POWER_MODE (0=Normal, 1=Low-Power, 2=Low-Noise)
- bit[8]: REG86_A
- bit[6:0]: SEL_CDUMP_CAP (7-bit capacitor select)
  - bit[6]: C[6]=4.0pF (COMP1/2, DF_SM[6])
  - bit[5]: C[5]=2.0pF (COMP1/2, DF_SM[5])
  - bit[4]: C[4]=2.0pF (COMP1/2, DF_SM[4])
  - bit[3]: C[3]=1.0pF (COMP3/4, DF_SM[3])
  - bit[2]: C[2]=0.5pF (COMP3/4, DF_SM[2])
  - bit[1]: C[1]=0.25pF (COMP3/4, DF_SM[1])
  - bit[0]: C[0]=0.25pF (COMP1/2, DF_SM[0])
- 주의: COMP 설정 시 POWER_MODE 비트 유지 필수

### 0x87 - COMP MUX (SEL_COMP1~4)
- bit[11:9]: SEL_COMP1
- bit[8:6]: SEL_COMP2
- bit[5:3]: SEL_COMP3
- bit[2:0]: SEL_COMP4
- Table 6-11 MUX 선택 (Selected Input / SEL_COMP1 / SEL_COMP2 / SEL_COMP3 / SEL_COMP4):
  - COMP1 핀: 0 / 3 / 2 / 1
  - COMP2 핀: 1 / 0 / 3 / 2
  - COMP3 핀: 2 / 1 / 0 / 3
  - COMP4 핀: 3 / 2 / 1 / 0
  - INT_DAC: 4 / 4 / 4 / 4
  - INT_VREF: 5 / 5 / 5 / 5

### 0x88 - Power Mode
- bit[1]: REG88_A
- bit[0]: REG88_B

### 0x89 - ISOPANEL / ADD_CAP
- bit[13:12]: REG89_A
- bit[11]: REG89_B
- bit[10]: ADD_20PF_1
- bit[9]: ADD_20PF_0
- bit[8]: ADD_10PF
- bit[5:4]: ISOPANEL1 (0x0=normal, 0x3=isolated)
- Default: 0x3000

### 0x8D - Misc
- bit[9]: REG8D_A
- bit[8]: REG8D_B

### 0x8E - Power Mode
- bit[2:1]: REG8E_C, REG8E_A
- bit[0]: REG8E_B

### 0x8F - Misc
- bit[0]: REG8F_A

### 0x90 - Misc
- bit[15]: REG90_A
- bit[0]: REG90_B

### 0x91 - Misc
- bit[4:2]: REG91_A
- bit[0]: REG91_B

### 0x94 - ISOPANEL2
- bit[15]: ISOPANEL2
- bit[0]: REG94_A

### 0x95 - Misc
- bit[2:0]: REG95_A

### 0x96 - LPF Control
- bit[15]: REG96_C (must write 1)
- bit[14:8]: NLPF_SHS (LPF2 bandwidth, 7-bit, 0~127)
- bit[6:0]: NLPF_SHR (LPF1 bandwidth, 7-bit, 0~127)
- fLPF(Hz) = 1000000 / (4.52 + NLPF x 1.22)
- TI 권장: NLPF_SHR = NLPF_SHS

### 0xA3 - Power Control / DAC
- bit[15]: PDN_REG7
- bit[14:13]: REGA3_A
- bit[12]: PDN_REG8
- bit[11:10]: REGA3_B, REGA3_C
- bit[9]: PDN_REG9
- bit[8]: PDN_REG10
- bit[5]: PDN_DAC (1=DAC power down, default)
- bit[4]: PDN_REG1
- Default: 0x4C20

### 0xA5 - Power Control
- bit[15]: PDN_REG0
- bit[14]: REGA5_A
- Default: 0x4000

### 0xA9 - Misc
- bit[12:8]: REGA9_A

### 0xAC - TRIM
- bit[15]: REGAC_A

### 0xAD - STR-specific
- bit[12:11]: REGAD_A
- bit[10:9]: REGAD_B
- bit[3:0]: REGAD_C

### 0xAF - STR-specific
- bit[9:8]: REGAF_A
- bit[7:0]: REGAF_B

### 0xB0 - STR-specific
- bit[15]: REGB0_A
- bit[14:8]: REGB0_B

### 0xB2 - STR-specific
- bit[15:14]: REGB2_A
- bit[13:8]: REGB2_B
- bit[7:4]: REGB2_C
- bit[3:0]: REGB2_D

### 0xB5 - STR-specific
- bit[15:0]: REGB5_A ~ REGB5_I (multiple sub-fields)

### 0xB6 - STR-specific
- bit[11:0]: REGB6_A

### 0xBC - STR-specific
- bit[9:8]: REGBC_A

### 0xBD - Misc
- bit[15:12]: REGBD_A
- bit[11:8]: REGBD_B ~ REGBD_D

### 0xBE - Misc
- bit[15:12]: REGBE_A
- bit[11:8]: REGBE_B ~ REGBE_D

### 0xC0 - STR-specific
- bit[9:8]: REGC0_A
- bit[4:0]: REGC0_B

### 0xC1 - Misc
- bit[15:12]: REGC1_A ~ REGC1_D

### 0xC3 - STR-specific
- bit[15:14]: REGC3_A
- bit[13:8]: REGC3_B
- bit[5:0]: REGC3_C

### 0xCA - Misc
- bit[15:0]: REGCA_A

### 0xCF - Integration Mode
- bit[4]: REGCF_A (integrate-down 시 1)

### 0xD0 - Power Down Control (Standby/Sleep)
- bit[15:4]: PDN bits
- Active: 0x0000, Standby: 0x3FF0, Sleep: 0xFFF0

### 0xD2 - Integration Mode
- bit[15:12]: REGD2_A (integrate-down 시 0x9)

### 0xDA - Power Down Control
- bit[15:14]: DIS_STANDBY
- Active: 0x0000, Standby/Sleep: 0xC000

### 0xE4 - Temperature Sensor Control
- bit[15]: REGE4_A (enable sequence: 1->0->1)
- bit[7:0]: REGE4_B

### 0xE7 - Power Down Control
- bit[9:0]: PDN bits
- Active: 0x0000, Standby/Sleep: 0x03FF

### 0xE9 - Integration Mode
- bit[8]: REGE9_A (integrate-down 시 1)
- bit[3:0]: REGE9_B (integrate-down 시 0x9)

### 0xFC - Power Down Control (LVDS)
- bit[15]: PDN_REG2
- bit[14]: PDN_FCLK
- bit[13]: PDN_DOUT
- bit[12]: PDN_DCLK
- bit[11]: PDN_REG3
- Active: 0x0000, Standby/Sleep: 0xFE00

### 0xFE - SPI Read Address
- bit[7:0]: SPI_READ_ADDR (read only, last read address)


## Section 7.2 TG Register Map

PAGE_SELECT0=1 또는 PAGE_SELECT1=1 상태에서 접근
주소 0x20~0x85 범위가 Configuration page와 겹침

### 0x20 - STR (TG page)
- bit[1:0]: STR (0~3)

### 0x50 - TG_ESSENTIAL0 (TG page)
- bit[13:0]: TG_ESSENTIAL0 (must write 1h)
- reset 후 기본값 0 -> 반드시 1로 설정 필요
- PAGE_SELECT 전환 후 재설정 권장

### 0x51 - TG_ESSENTIAL1 (TG page)
- bit[13:0]: TG_ESSENTIAL1 (must write 1h)
- reset 후 기본값 0 -> 반드시 1로 설정 필요
- PAGE_SELECT 전환 후 재설정 권장
- 주의: Configuration page의 0x51(DIG_OFF_CORR_EN)과 다른 레지스터

### 0x5C - SPARE_TG_RISE (TG page)
- bit[7:0]: SPARE_TG_RISE (0~255 step)

### 0x5D - SPARE_TG_FALL (TG page)
- bit[7:0]: SPARE_TG_FALL (0~255 step)

### 0x70 - TMPSNS_RISE (TG page)
- bit[7:0]: TMPSNS_RISE (temperature sensor timing)
- 주의: Configuration page의 0x70과 다른 레지스터

### 0x71 - TMPSNS_FALL (TG page)
- bit[7:0]: TMPSNS_FALL (temperature sensor timing)

### 0x72 - DF_SM0_RISE (TG page)
- bit[7:0]: DF_SM[0] rising edge (0~255 step)

### 0x73 - DF_SM0_FALL (TG page)
- bit[7:0]: DF_SM[0] falling edge (0~255 step)

### 0x74 - DF_SM1_RISE (TG page)
- bit[7:0]: DF_SM[1] rising edge

### 0x75 - DF_SM1_FALL (TG page)
- bit[7:0]: DF_SM[1] falling edge
- 주의: Configuration page의 0x75와 다른 레지스터

### 0x76 - DF_SM2_RISE (TG page)
- bit[7:0]: DF_SM[2] rising edge

### 0x77 - DF_SM2_FALL (TG page)
- bit[7:0]: DF_SM[2] falling edge

### 0x78 - DF_SM3_RISE (TG page)
- bit[7:0]: DF_SM[3] rising edge
- 주의: Configuration page의 0x78(DIE_TEMP)과 다른 레지스터

### 0x79 - DF_SM3_FALL (TG page)
- bit[7:0]: DF_SM[3] falling edge

### 0x7A - DF_SM4_RISE (TG page)
- bit[7:0]: DF_SM[4] rising edge

### 0x7B - DF_SM4_FALL (TG page)
- bit[7:0]: DF_SM[4] falling edge
- 주의: Configuration page의 0x7B(TRIM)과 다른 레지스터

### 0x7C - DF_SM5_RISE (TG page)
- bit[7:0]: DF_SM[5] rising edge

### 0x7D - DF_SM5_FALL (TG page)
- bit[7:0]: DF_SM[5] falling edge

### 0x7E - DF_SM6_RISE (TG page)
- bit[7:0]: DF_SM[6] rising edge

### 0x7F - DF_SM6_FALL (TG page)
- bit[7:0]: DF_SM[6] falling edge


## 주소 충돌 주의 목록

아래 주소는 PAGE_SELECT 상태에 따라 완전히 다른 레지스터임:

Config page (PAGE_SEL=0) / TG page (PAGE_SEL=1)
- 0x20: Config 레지스터 / STR
- 0x50: Config 레지스터 / TG_ESSENTIAL0
- 0x51: DIG_OFF_CORR_EN 등 / TG_ESSENTIAL1
- 0x5C: Config 레지스터 / SPARE_TG_RISE
- 0x5D: Config 레지스터 / SPARE_TG_FALL
- 0x70: REG70_A / TMPSNS_RISE
- 0x71: Config 레지스터 / TMPSNS_FALL
- 0x72~0x7F: Config 레지스터 (DIE_TEMP, TRIM 등) / DF_SM[0~6]_RISE/FALL

DF_SM 레지스터에 접근 시 반드시:
1. execute_cmd_wroic(0x03, 0x0002) -- PAGE_SELECT0=1
2. TG_ESSENTIAL0(0x50)=1, TG_ESSENTIAL1(0x51)=1 재확인
3. DF_SM 레지스터 write
4. execute_cmd_wroic(0x03, 0x0000) -- PAGE_SELECT 복귀
