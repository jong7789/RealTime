# Framebuf 2nd-grab stuck 수정 + sfp_phy_sel 디바운스

- **작업 일시**: 2026-05-08 11:00 (KST), 13:00 진단 갱신
- **작업 태그**: `2605081100`
- **FPGA 버전**: `2_01_13` (유지)
- **FPGA 날짜**: `26_0507_18` → `26_0508_11`
- **FW 날짜**: `2026.05.06 16:50` → `2026.05.08 11:00`

> **2026-05-08 13:00 갱신**: `fov` / `fstat` 명령으로 stuck 상태 캡처 결과 **OVFLW 비트는 set되지 않음**으로 확인. 초기 가설(sticky OVFLW)이 틀린 것이며, 실제 원인은 **reader 측 stall + buffer 만석**으로 판명. 따라서 `CLRSTAT` 단독 → `INIT | CLRSTAT` 로 강화, buffer 96MB → 192MB 로 확대.
>
> **2026-05-08 13:30 재갱신 (회귀 원인 정정)**: 13:00 변경 후 "연결 자체가 안 되는 회귀" 발생.
> 초기에는 `INIT` 패치(A) 가 원인이라 추정했으나 실측 결과 **buffer 192MB 확대(D) 가 진짜 원인**으로 확인.
> 192MB malloc 이 heap 영역을 넘어 다른 메모리 번지(코드/스택 등)를 침범한 것으로 판단됨.
> → **D 만 96MB 로 롤백**, **A(`INIT|CLRSTAT`) 는 그대로 유지**.
>
> **2026-05-08 14:00 재시도 (heap 우회)**: DDR 메모리 맵 분석 후 `_FRAMEBUF_DEDICATED_RAM_` 매크로
> 활성화로 heap 한계를 우회. framebuf 영역을 **DDR 마지막 256 MB (0xB0000000~0xC0000000)** 로
> 확보 — heap (0x80~0x87) / FPGA calibration (0x89~0x9C) 영역과 모두 분리. EXT3643R 기준 7 frames
> 마진 (다른 모델 5 frames 보다 양호).

---

## 1. 증상

자유실행(Free-run) 그랩 모드에서:

1. GigE Vision 클라이언트 연결 후 첫 그랩 → 정상 영상 수신
2. AcquisitionStop → 데이터 흐름 정지
3. AcquisitionStart 재실행 → **컨트롤 채널은 살아있는데 영상이 안 옴**
4. 회복 방법:
   - UART에 `finit` 입력 → 즉시 회복 (연결 유지된 채로)
   - 또는 클라이언트 disconnect → reconnect → 회복

---

## 2. 원인 분석

### 2-1. framebuf 내부 OVFLW 비트가 sticky

[`framebuf.h`](../vitis/EXTREAM_fw/src/framebuf.h) 의 status 비트:

| 비트 | 의미 |
|---|---|
| `FRAMEBUF_S_DF_OVFLW` (0x00010000) | Descriptor FIFO overflow |
| `FRAMEBUF_S_RF_OVFLW` (0x00020000) | Resend FIFO overflow |
| `FRAMEBUF_S_IF_OVFLW` (0x00040000) | Image FIFO overflow |
| `FRAMEBUF_S_TF_OVFLW` (0x00100000) | TX FIFO overflow |

이 비트들은 **sticky** — 한 번 set 되면 `FRAMEBUF_C_CLRSTAT` 비트를 명시적으로 써야만 클리어. set된 동안 framebuf IP가 송신 중단.

### 2-2. AcquisitionStart에서 CLRSTAT 누락

[user.c:1539-1551](../vitis/EXTREAM_fw/src/user.c#L1539-L1551) 의 콜백:
```c
if (REG(ADDR_OUT_EN) & 0x00000001) {
    execute_cmd_op_acq_start();        // <- 동작 시간만 기록
    gige_send_message4(...);
    execute_cmd_grab(1);               // <- ADDR_GRAB_EN=1 만 씀
}
```

`execute_cmd_op_acq_start()` ([func_cmd.c:6241](../vitis/EXTREAM_fw/src/func_cmd.c#L6241)) 도 시간 기록만, framebuf 상태를 건드리지 않음.

### 2-3. 시나리오

```
첫 그랩  → 정상 송신
   ↓
순간 백프레셔 / 패킷 드롭 / IRQ 지연으로 *_OVFLW 비트 set
   ↓
AcquisitionStop → 데이터 흐름 중단, OVFLW 비트는 sticky로 잔존
   ↓
AcquisitionStart → ADDR_OUT_EN=1, 그러나 framebuf는 OVFLW에 박혀 송신 못함
   ↓
finit (FRAMEBUF_C_INIT|CLRSTAT) → 비트 클리어 → 정상화
또는
disconnect → sys_net_up=0 → framebuf sys_en 토글 → 부수효과 회복
```

### 2-4. SFP 디바운스 (보조 안정화)

`sfp_phy_sel`이 **combinational** AND 출력 (`sfp_signal_detect AND sfp_rst_done`) 인 채로
`xgmii_clk` LUT-mux 의 select 로 사용 중. SFP 미장착 시에도 `sfp_los` 핀의 미세 흔들림이
xgmii_clk 글리치 → framebuf TX 핸드셰이크 손상 위험. 본 작업으로는 select 만 안정화
(클럭 mux 자체의 BUFGMUX_CTRL 교체는 후속 과제로 분리).

---

## 3. 수정 내역

### 3-1. 펌웨어 ([user.c](../vitis/EXTREAM_fw/src/user.c))

**Patch 1** — AcquisitionStart 시 `FRAMEBUF_C_INIT | FRAMEBUF_C_CLRSTAT` 추가 (1542줄 근처).
fstat 분석에서 OVFLW 미발생 + reader stall (`RD_ACT 1→0`) + 168 frame drop 으로 확인되어
INIT 까지 추가. INIT 은 writer/reader 포인터 baseline 리셋으로 reader FSM 재기동 효과.

**Patch 3** — `user_callback()` 끝에 OVFLW 변경 시 `[FBOV]` UART 로그.
DF/RF/IF/TF 4비트 edge-triggered 출력. 검증 후 `#ifdef DEBUG_FBOV` 가드 또는 제거.

**Patch 4** — UART 명령 `fov` 신설 ([command.c](../vitis/EXTREAM_fw/src/command.c), [command.h](../vitis/EXTREAM_fw/src/command.h)).
[FBOV] 와 동일 포맷의 한 줄 요약을 사용자 요청 시 출력. `fstat`(풀 덤프) 보조용.

### 기존 framebuf 관련 UART 명령 정리

| 명령 | 동작 |
|---|---|
| `fstat` | `framebuf_printregs()` 풀 덤프 (control/status/pointers + FIFO 카운터, ~50줄) |
| `finit` | `framebuf_control \|= FRAMEBUF_C_INIT` (writer/reader 포인터 baseline 리셋) |
| `fclr`  | `framebuf_control \|= FRAMEBUF_C_CLRSTAT` (overflow 비트 + 통계 카운터 클리어) |
| `fov`   | **신규** — `[FBOV] framebuf_status=0x... (DF/RF/IF/TF=....) [OK\|OVFLW SET]` 한 줄 |

### 3-2. FPGA ([EXTREAM_R.vhd](../EXTxR2.srcs/sources_1/new/EXTREAM_R.vhd))

**Patch 2** — `sfp_phy_sel` 체인을 raw → 2FF sync → 256-cycle 디바운스 → downstream MUXes 로 구성.

- 신호 선언 (425줄 부근): `sfp_sel_dbnc_cnt[7:0]`, `sfp_phy_sel_dbnc` 추가, `ASYNC_REG=TRUE` attribute on `sfp_phy_sel_d0/_sync`
- 로직 (3869줄 부근): `SFP_SEL_SYNC_PROC` (2FF CDC) + `SFP_SEL_DEBOUNCE_PROC` (256-sample hold filter, ~2.56us @100MHz)
- 기존에 미완성으로 선언만 되어 있던 `sfp_phy_sel_raw/_d0/_sync` 신호를 실제로 wire-up

### 3-3. 변경 이력

- [TOP_HEADER.vhd](../EXTxR2.srcs/sources_1/new/TOP_HEADER.vhd) — FPGA_DATE 갱신, 한 줄 이력 추가
- [main.c](../vitis/EXTREAM_fw/src/main.c) — FW_DATE 갱신, 17번 항목 추가

---

## 4. 수정 파일 목록

| 파일 | 변경 |
|---|---|
| [vitis/EXTREAM_fw/src/user.c](../vitis/EXTREAM_fw/src/user.c) | Patch 1 (`INIT \| CLRSTAT`) + Patch 3 (overflow 로그) |
| [vitis/EXTREAM_fw/src/command.c](../vitis/EXTREAM_fw/src/command.c) | Patch 4 (`fov` 명령 등록 + 함수 구현) |
| [vitis/EXTREAM_fw/src/command.h](../vitis/EXTREAM_fw/src/command.h) | Patch 4 (`UART_CMD_fov` 선언) |
| [vitis/EXTREAM_fw/src/framebuf.c](../vitis/EXTREAM_fw/src/framebuf.c) | Patch D (`_FRAMEBUF_DEDICATED_RAM_` 매크로 활성, 0xB0000000) |
| [vitis/EXTREAM_fw/src/main.c](../vitis/EXTREAM_fw/src/main.c) | Patch D (framebuf size 96MB → 256MB) + FW_DATE bump + 이력 |
| [EXTxR2.srcs/sources_1/new/EXTREAM_R.vhd](../EXTxR2.srcs/sources_1/new/EXTREAM_R.vhd) | Patch 2 (sfp_phy_sel debounce/sync) |
| [EXTxR2.srcs/sources_1/new/TOP_HEADER.vhd](../EXTxR2.srcs/sources_1/new/TOP_HEADER.vhd) | FPGA_DATE bump + 이력 |

## 5. 백업 (CLAUDE.md 룰 6)

`backup/` 디렉토리에 평탄 구조로:

- `backup/user_2605081100.c.bak`
- `backup/main_2605081100.c.bak`
- `backup/command_2605081100.c.bak`
- `backup/command_2605081100.h.bak`
- `backup/framebuf_2605081100.c.bak`
- `backup/EXTREAM_R_2605081100.vhd.bak`
- `backup/TOP_HEADER_2605081100.vhd.bak`

---

## 6. 검증 절차

### 6-1. 펌웨어만 우선 (FPGA 재합성 불필요)

```bash
cd vitis/
make all          # 또는 fw만 빌드
```

테스트:
1. 클라이언트 연결 → AcquisitionStart → 그랩 정상
2. AcquisitionStop → AcquisitionStart 반복 → **이제 영상 정상**
3. UART 로그 모니터:
   - `[FBOV] framebuf_status=0x........ (DF/RF/IF/TF=....)` 가 나오면 OVFLW 발생 → 어떤 비트인지 확인
   - 안 나오면 → OVFLW 미발생 (다른 원인이거나 이미 막힘)

### 6-2. FPGA 재합성

```tcl
reset_run EXT3643R
launch_runs impl_EXT3643R -to_step write_bitstream -jobs 8
```

합성 후 `report_methodology` 실행:
- `TIMING-10 Missing property on synchronizer` 카운트가 줄었는지 (sfp_phy_sel_d0/sync에 ASYNC_REG 적용 효과)

### 6-3. (실패 시) 강한 리셋

`CLRSTAT` 만으로 부족하면 [user.c](../vitis/EXTREAM_fw/src/user.c) 의 해당 라인을:
```c
framebuf_control |= (FRAMEBUF_C_INIT | FRAMEBUF_C_CLRSTAT);
```
로 변경. INIT은 writer/reader 포인터까지 baseline 리셋.

---

## 6-A. 진단 결과 (2026-05-08 13:00, fstat 3-state 캡처)

`fov` / `fstat` 으로 시작 전 / 동작 중 / 멈춤 상태를 비교해서 얻은 결정적 사실:

| 항목 | 시작 전 | 동작 중 | 멈춤 후 |
|---|---|---|---|
| Status | `0x03203F04` | `0x03C03F04` | `0x03603F04` |
| WR_ACT / RD_ACT | 0 / 0 | 1 / 1 | **1 / 0** |
| IF_EMPTY | 1 | 0 | 1 |
| Descr.FIFO writes | 0 | 80 | 228 |
| Read sent | 0 | 80 | 227 |
| Read canceled | 0 | 0 | **1** |
| **Write dropped blocks** | **0** | **0** | **168** |
| **Write no space in FB** | **0** | **0** | **170** |
| 모든 OVFLW 비트 | 0 | 0 | **0** |

### 핵심 발견
1. **OVFLW 4비트 모두 0** → 초기 가설(sticky OVFLW) **기각**. `CLRSTAT` 단독 패치로는 해결 불가.
2. **RD_ACT 1→0** → reader가 stall. `Read canceled = 1` 이후 복귀 못함.
3. **Write dropped blocks = 168, Write no space in FB = 170** → reader 정지로 96MB 버퍼가 ~3 프레임만에 만석 → writer가 168 프레임을 드롭. 버퍼 사이즈 = 0x06000000(96MB), 프레임 = `XML_PLOAD_SIZE` 30,390,272(~29MB) → 3 프레임 분량.

### 결론
framebuf reader 측이 `Read canceled` 후 복귀하지 못하는 상태가 stuck의 본질. OVFLW 통계와 무관.
`finit`(=INIT|CLRSTAT)이 회복시키는 이유는 INIT이 writer/reader 포인터를 baseline 리셋하여 reader FSM을 재기동하기 때문.

## 7. 후속 과제

- **Framebuf 버퍼 확대 재시도 (D 재적용)** — 96MB(3 frames) → 192MB+ 로 늘리려면
  먼저 MicroBlaze linker script(`vitis/EXTREAM_fw/src/lscript.ld` 또는 BSP 측)의 heap
  사이즈를 키워야 함. malloc 자체는 NULL 을 안 돌려주더라도 인접 영역을 silent
  하게 침범하는 케이스가 발생. 또는 `_FRAMEBUF_DEDICATED_RAM_` 매크로로 정적
  주소 할당 검토.
- **Reader stall 근본 원인 추적** — INIT 으로 우회는 가능하나 매 acq 시 latency 발생.
  `mem_full` / `mem_scc` / `tx_full` 신호를 ILA 로 캡처하여 어느 신호가 stuck 되는지 확인.
- **stuck watchdog (옵션)** — `WR_ACT && !RD_ACT` 가 N초 이상 지속될 때 자동 INIT 발동하는 로직 추가.
- **`xgmii_clk` LUT-mux → BUFGMUX_CTRL 교체** ([EXTREAM_R.vhd:3878](../EXTxR2.srcs/sources_1/new/EXTREAM_R.vhd#L3878))
  - 본 작업은 select 만 안정화. 클럭 mux 자체는 여전히 LUT.
- **`xgvrd_kc705_n.xdc` RXAUI CDC 제약 hierarchy 정정** (이전 작업 `2605071900`에서 EXT3643R.xdc로 포팅 완료)
- **TIMING-23 combinational loop 2건 위치 파악** (기존 timing_summary 보고서 항목)
- **ROIC LVDS hold 위반 14건 수정** (IDELAYE2 tap 조정 별도 작업)
