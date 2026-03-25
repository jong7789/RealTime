# AFE3256 Datasheet Reference

## 1. Overview
- Part: AFE3256 (Texas Instruments)
- 256-channel Analog Front-End for Digital X-Ray Flat-Panel Detectors
- On-chip 16-bit SAR ADC × 2 (128ch each, total 256ch)
- Single 1.85V power supply (AVDD)
- Correlated Double Sampling (CDS) with dual banking
- 256:2 analog MUX → 2× ADC
- Serial LVDS data output (DOUT, DCLK, FCLK)
- Package: COF (TFU 320-pad, TFV 315-pad)

---

## 2. Recommended Operating Conditions

| Parameter | Symbol | Min | Nom | Max | Unit |
|-----------|--------|-----|-----|-----|------|
| Analog supply | AVDD | 1.8 | 1.85 | 1.9 | V |
| Reference voltage | VREF | 1.24 | 1.25 | 1.26 | V |
| MCLK frequency | FMCLK | 10 | - | 32 | MHz |
| **SPI clock frequency** | **FSCLK** | - | - | **10** | **MHz** |
| Scan time | tSCAN | 8 | - | 204.8 | µs |
| TP_SEL, MCLK, SYNC voltage | - | 0 | 1.8 | 2.5 | V |
| SPI pin voltage (SDATA, SCLK, SEN) | - | 0 | 1.8 | 3.3 | V |
| SDOUT voltage | - | - | 1.8 | - | V (LVCMOS only) |
| Operating temperature | TA | 0 | - | 85 | °C |

---

## 3. Electrical Characteristics
Conditions: TA=25°C, AVDD=1.85V, MCLK=20MHz, STR=2, tSCAN=51.2µs, input charge range=5pC

### Noise Performance
| Condition | Noise (electrons RMS) |
|-----------|-----------------------|
| Low-noise, 0.31pC, 102.4µs | 190 |
| Low-noise, 0.625pC, 8µs | 480 |
| Normal-power, 1.25pC, 12.8µs | 705 |
| Normal-power, 1.25pC, 51.2µs | 440 |
| Low-power, 5pC, 51.2µs | 1125 |
| Low-power, 12.5pC, 102.4µs | 2270 |

### Other Specifications
| Parameter | Value | Unit |
|-----------|-------|------|
| Correlated noise | 10 | % of total |
| Full-channel INL | ±2 | LSB (16-bit) |
| Input charge range | 0.3 ~ 12.5 (step 0.3125) | pC |
| Feedback capacitor (CFB) | 0.25 ~ 10 | pF |
| Gain error | ±10 | % of ideal |
| Ch-to-ch gain matching | ±2 | % |
| Input leakage current | ±10 | pA |

---

## 4. Pin Configuration (Key Pins)

### Sensor Interface
| Pin | Name | I/O | Description |
|-----|------|-----|-------------|
| PG[8:263] | IN[255:0] | I | 256 analog input channels |
| PG[7,264] | EXTC_I | O | Shield voltage |

### Digital Control
| Pin | Name | I/O | Description |
|-----|------|-----|-------------|
| - | MCLK | I | Master clock (10~32MHz) |
| - | SYNC | I | Scan start trigger |
| - | TP_SEL | I | Timing profile select (0=TP0, 1=TP1) |

### SPI Interface
| Pin | Name | I/O | Description |
|-----|------|-----|-------------|
| - | SCLK | I | SPI clock (max 10MHz) |
| - | SDATA | I | SPI data input (MOSI) |
| - | SEN | I | SPI enable (active low, 100kΩ pullup to AVDD) |
| - | SDOUT | O | SPI data output (MISO), LVCMOS 1.8V only |

### LVDS Data Output
| Pin | Name | I/O | Description |
|-----|------|-----|-------------|
| - | DOUTP/M | O | LVDS serial data output (2 pairs, one per ADC) |
| - | DCLKP/M | O | LVDS bit clock |
| - | FCLKP/M | O | LVDS frame clock |

### Power
| Pin | Name | Description |
|-----|------|-------------|
| - | AVDD | 1.85V analog supply |
| - | AVSS | Analog ground |
| - | VREF | 1.25V reference |
| - | COMP1~4 | Charge injection compensation inputs (0~1.85V) |

---

## 5. SPI Protocol

### 5.1 SPI Modes
| Mode | Max SCLK | FPGA Pins | Description |
|------|----------|-----------|-------------|
| Standard (Legacy) | 10MHz | N+3 | 24-bit packet, independent per device |
| Daisy Chain | 10MHz | 4 | 24×N bit packet, sequential programming |

**NOTE: Device powers up in daisy chain mode. Must write LEGACY_SPI_MODE=1 after every reset.**

### 5.2 Standard SPI Frame (24-bit)
```
[A7 A6 A5 A4 A3 A2 A1 A0] [D15 D14 D13 ... D1 D0]
|-------- 8-bit addr ----| |------ 16-bit data ------|
```
- MSB first
- SEN low = enable
- Data loaded into register on SEN rising edge
- SCLK: max 10MHz, min few Hz, non-50% duty cycle OK

### 5.3 Register Write
```
SEN goes low
→ Clock 24 bits on SDATA (addr[7:0] + data[15:0])
→ SEN goes high (data loaded)
```

### 5.4 Register Read
```
Step 1: Write reg 0x00, bit[1] = 1 (REG_READ enable)
        → Disables all register writes except reg 0x00
        → SDOUT becomes active

Step 2: Send addr on SDATA, data field ignored (set to 0)
        → From 8th SCLK falling edge, SDOUT outputs data[15:0] MSB first

Step 3: Write reg 0x00, bit[1] = 0 (exit read mode)
        → Re-enables register writes
```
**CRITICAL: SDI data is shifted out on SCLK falling edge, external controller latches on SCLK rising edge**

**CRITICAL: During register read, reg 0x00 contents cannot be read**

**CRITICAL: During register read, TG SIGNAL PROBE must be disabled (EN_TP_ON_SDOUT = 0)**

### 5.5 SPI Timing Requirements

| Parameter | Symbol | Min | Max | Unit |
|-----------|--------|-----|-----|------|
| SCLK period | tSCLK | 100 | - | ns |
| SCLK high time | tSCLK_H | 20 | - | ns |
| SCLK low time | tSCLK_L | 20 | - | ns |
| SDATA setup time | tDSU | 10 | - | ns |
| SDATA hold time | tDHO | 10 | - | ns |
| SEN fall to SCLK rise | tSEN_SU | 10 | - | ns |
| Last SCLK rise to SEN rise | tSEN_HO | 10 | - | ns |
| SCLK fall to valid SDOUT | tOUT_DV | - | 20 | ns |

**tSCLK min 100ns → SCLK max = 10MHz**
**FPGA의 SCK가 10MHz를 초과하면 SDI 데이터가 1bit shift되는 현상 발생 (검증됨)**

---

## 6. Scan Time Configuration

### tSCAN = tMCLK × 2^(8+STR)

| STR | MCLK Cycles | fMCLK Range | tSCAN Range |
|-----|-------------|-------------|-------------|
| 0 | 256 | 32~10 MHz | 8~25.6 µs |
| 1 | 512 | 20~10 MHz | 25.6~51.2 µs |
| 2 | 1024 | 20~10 MHz | 51.2~102.4 µs |
| 3 | 2048 | 20~10 MHz | 102.4~204.8 µs |

### ADC Sampling
| STR | ADC Averaging Factor | ADC Sampling Freq |
|-----|---------------------|-------------------|
| 0 | 1 | fMCLK / 2 |
| 1 | 2 | fMCLK / 2 |
| 2 | 4 | fMCLK / 2 |
| 3 | 8 | fMCLK / 2 |

---

## 7. LVDS Data Output

### Data Format
- 24-bit per channel: 16-bit ADC data + 8-bit alignment vector
- Serialized over LVDS pairs
- 2 LVDS DOUT pairs (one per ADC, 128 channels each)
- Output order: ADC0 Ch(n), ADC1 Ch(n+128), ADC0 Ch(n+1), ADC1 Ch(n+129), ...

### Clock Relationship
- FCLK = fMCLK / 2^STR
- DCLK = center-aligned with DOUT and FCLK
- Max data rate: 768 Mbps

### Control Timing
```
SYNC rising edge → starts new scan
MCLK → continuous (must be free-running for PLL lock)
TP_SEL → selects timing profile (0 or 1), toggle before SYNC
```

### Control Timing Requirements
| Parameter | Symbol | Min | Unit |
|-----------|--------|-----|------|
| TP_SEL setup to SYNC rise | tSU1 | 0 | ns |
| SYNC rise to TP_SEL hold | tH1 | 2×tMCLK | - |
| SYNC pulse width | tW1 | tMCLK | - |
| SYNC to MCLK setup | tSU2 | 0 | ns |
| MCLK rise to SYNC hold | tH2 | 1/3×tMCLK+10 | ns |
| MCLK high pulse | tWH | 0.4×tMCLK | - |
| MCLK low pulse | tWL | 0.4×tMCLK | - |

---

## 8. Device Operation

### 8.1 Signal Chain (per channel)
```
Pixel → Integrator (CSA) → CDS (SHR/SHS) → 256:2 MUX → ADC → LVDS
```
- Integrator reset: IRST signal
- SHR: samples reset level
- SHS: samples signal level
- CDS = SHS - SHR (removes offset and low-freq noise)
- Dual CDS banking for pipelined integrate-and-read

### 8.2 Charge Integration Modes

| Mode | INTG_DOWN | Charge Polarity | Description |
|------|-----------|-----------------|-------------|
| Integrate-up | 0 (default) | Electrons (-) | Output rises during integration |
| Integrate-down | 1 | Holes (+) | Output falls during integration |

Register settings for integrate-down mode:
| Addr | Value | Description |
|------|-------|-------------|
| 0x80 | 0x080F | INTG_DOWN = 1 |
| 0xCF | 0x0010 | REGCF_A = 1 |
| 0xE9 | 0x0109 | REGE9_A = 1, REGE9_B = 0x9 |
| 0xD2 | 0x9000 | REGD2_A = 0x9 |

### 8.3 Input Charge Range
- Range: 0.3pC ~ 12.5pC (step 0.3125pC)
- Controlled by SEL_CFB0/1 bits in register 0x82
- Capacitor selection is additive (multiple bits can be set)

| SEL_CFB bit | Capacitor |
|-------------|-----------|
| bit[6] | 4pF |
| bit[5] | 2pF |
| bit[4] | 1pF |
| bit[3] | 0.5pF |
| bit[2] | 0.25pF |
| bit[1] | 0.25pF |
| bit[0] | 0.25pF |

Example: SEL_CFB = 0x40 → 4pF → 5pC range
Example: SEL_CFB = 0x18 → 1pF+0.5pF = 1.5pF → 1.875pC range

---

## 9. Power Modes

### 9.1 Active Power Modes
| Mode | 0x86 | 0x88 | 0x8E | Use Case |
|------|------|------|------|----------|
| Normal-Power | 0x0000 | 0x0000 | 0x0002 | General purpose |
| Low-Power | 0x0200 | 0x0002 | 0x0006 | High charge range, battery apps |
| Low-Noise | 0x0400 | 0x0000 | 0x0002 | Small charge range, fast scan |

NOTE: scan time < 12.8µs → only normal-power and low-noise supported

### 9.2 Power-Down Modes
- Standby: signal chain powered down, registers preserved
- Sleep: entire device powered down, registers preserved
- No register reconfiguration needed at wakeup

---

## 10. Digital Offset Correction (DOC)

### 10.1 Purpose
Corrects channel-to-channel offset mismatch using internal calibration engine.
Removes only ch-to-ch offset mismatch, NOT pixel offset.

### 10.2 Lines Averaged Configuration
| CALIB_NUM_AVG | Lines Per Bank |
|---------------|----------------|
| 3 | 256 |
| 4 | 512 |
| 5 | 1024 |
| 6 | 2048 |
| 7 | 4096 |

### 10.3 Calibration Time
```
Calibration Time = 2 × Lines_Per_Bank × tSCAN
Example: 1024 lines, tSCAN=51.2µs → 2 × 1024 × 51.2µs ≈ 104.9ms
```

### 10.4 DOC Register Sequence
```
Step 1: Configure ISOPANEL mode with 20pF ADD_CAP
  0x0D = 0x4800  (ADDCAP_EN=1, ISOPANEL3=1)
  0x94 = 0x8001  (ISOPANEL2=1, REG94_A=1)
  0x89 = 0x3230  (ISOPANEL1=3, ADD_20PF_0=1)
  0x80 = 0x082D  (SEL_PANEL_BIAS=2, EN_TDEF=1, INTG_DOWN=0)

Step 2: Configure DOC engine
  0x4C = 0x0005  (CALIB_NUM_AVG=5, 1024 lines)
  0x51 = 0x0306  (DIG_OFF_CORR_EN1=1, DIG_OFF_CORR_EN2=1)

Step 3: Start calibration
  0x4B = 0x8003  (CALIB_MODE=3, CALIB_START=1)

Step 4: Wait for CALIB_DONE
  Poll reg 0x4B bit[14] = 1 (or wait calculated time)

Step 5: Clear and finalize
  0x4B = 0x0003  (CALIB_START=0)
  0x4C = 0x8005  (REG4C_D=0x20)

Step 6: Restore original settings
  0x0D = 0x0000  (ADDCAP_EN=0, ISOPANEL3=0)
  0x94 = 0x0001  (ISOPANEL2=0)
  0x89 = 0x3000  (ISOPANEL1=0, ADD_20PF_0=0)
  0x80 = 0x080D  (SEL_PANEL_BIAS=0)
```

After DOC: digital output code is around 256 LSBs

---

## 11. Key Register Map

### 11.1 Register Space Structure
```
Address 0x00~0x1F: COMMON registers (accessible regardless of page)
Address 0x20~:     Paged registers
  PAGE_SELECT = 00: Configuration page
  PAGE_SELECT = 01: Timing Profile 0
  PAGE_SELECT = 10: Timing Profile 1
```

### 11.2 Important Registers

| Address | Name/Bits | Reset | Description |
|---------|-----------|-------|-------------|
| 0x00 | bit[0]: SOFT_RESET | 0 | Software reset |
| 0x00 | bit[1]: REG_READ | 0 | SPI read mode enable |
| 0x00 | bit[6]: LEGACY_SPI_MODE | 0 | Must set =1 after every reset |
| 0x03 | PAGE_SELECT[1:0] | 0 | Register page selection |
| 0x0D | ADDCAP_EN, ISOPANEL3 | 0 | Sensor emulation control |
| 0x4B | CALIB_MODE, CALIB_START, CALIB_DONE(bit14) | 0 | DOC control |
| 0x4C | CALIB_NUM_AVG | 0 | DOC averaging config |
| 0x51 | DIG_OFF_CORR_EN1/2 | 0 | DOC enable/disable |
| 0x80 | INTG_DOWN, EN_TDEF, SEL_PANEL_BIAS | - | Integration mode, TDEF |
| 0x82 | SEL_CFB0[6:0], SEL_CFB1[6:0] | 0x0808 | Input charge range (feedback cap) |
| 0x86 | POWER_MODE | 0 | Power mode selection |
| 0x88 | REG88_B | 0 | Low-power mode config |
| 0x89 | ISOPANEL1, ADD_20PF_0 | 0 | Sensor emulation |
| 0x8E | REG8E_C | 0 | Low-power mode config |
| 0x94 | ISOPANEL2 | 0 | Sensor emulation |

---

## 12. Initialization Sequence

```
1. Apply AVDD, VREF, COMP voltages
2. Apply MCLK → wait PLL lock (>20µs)
3. SOFT_RESET = 1 (reg 0x00 bit[0])
4. TRIM LOAD (>400ns)
5. LEGACY_SPI_MODE = 1 (reg 0x00 bit[6])
6. Program device registers:
   - STR (scan time range)
   - Input charge range (SEL_CFB)
   - Power mode
   - LPF settings
   - TG profiles
7. Apply TP_SEL and SYNC
8. Perform Digital Offset Correction (DOC)
9. Bit alignment in FPGA (optional, using test patterns)
10. Start data capture (allow >30ms total from power-up)
```

---

## 13. Daisy Chain SPI

### Configuration
- Device enters daisy chain mode on power-up/reset
- Program DAISY_CHAIN_LEN = (N-1) for each device as first command
- Common SCLK and SEN for all devices
- SDOUT of each device → SDATA of next device
- Packet size = 24 × N bits

### Daisy Chain Register Read
1. Program PAGE_SEL if needed
2. Write SPI_READ_ADDR (addr 0xFE) with target register address
3. Send additional SCLKs with addr=0, data=0 (dummy writes)
4. Devices shift out register data on SDOUT
5. SPI_BURST_MODE = 1 for auto-increment address
6. SEN high exits read mode

---

## 14. Differences: TFU vs TFV COF Package

| Feature | TFU (320-pad) | TFV (315-pad) |
|---------|---------------|---------------|
| Size | 38mm × 28mm | 48mm × 17.33mm |
| COMP pads | COMP1,2,3,4 all available | Only COMP3,4 on PCB side |
| DIG_TP pin | Not available | Available |
| COMP routing | Direct | COMP3→COMP2 pad, COMP4→COMP1 pad |

NOTE: TFV uses cross-point switch/MUX for COMP selection, so all features still work

---

## 15. FPGA Implementation Notes (from project experience)

### SPI Clock Issue
- imain_clk = 20MHz → SCK = 10MHz (2-division) → AFE2256 OK
- imain_clk = 30MHz → SCK = 15MHz (2-division) → **AFE3256 FAILS (exceeds 10MHz spec)**
- Fix: 4-division SCK using sclk_div process → SCK = 7.5MHz at 30MHz imain_clk

### SPI Read Issue
- rroic step 2에서 REG(ADDR_ROIC_WDATA) 클리어 안 하면 이전 값(0x0002)이 SDO로 전송됨
- ROIC가 read하면서 동시에 write할 수 있음 → 레지스터 오염
- Fix: step 2에서 REG(ADDR_ROIC_WDATA) = 0 추가

### 1-bit Shift Pattern (SCK > 10MHz)
```
Written: 0x0404 → Read: 0x8202 (1-bit right shift, MSB=1)
Written: 0x0008 → Read: 0x8004 (1-bit right shift, MSB=1)
Written: 0x0808 → Read: 0x8404 (1-bit right shift, MSB=1)
```
This pattern = definitive diagnostic for SCK frequency violation
