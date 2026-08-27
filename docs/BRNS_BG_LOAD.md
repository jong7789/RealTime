# BRNS_BG_LOAD — NUC 백그라운드 청크 로드

- 상태: **구현 완료 (2026.06.12)**
- 변경 태그: `//# 2606121417` (최초 구현, 전 파일 공통), `//# 2606121502` (검토 후 보완 2건)
- 대상 FW: `vitis/EXTREAM_fw/src/` (MicroBlaze)
- 백업: `backup/*_2606121417.{c,h}.bak` 6개, `backup/*_2606121502.c.bak` 2개

## 변경 이력

| 태그 | 내용 |
|------|------|
| 2606121417 | 최초 구현 (상태머신, BRNS_BG_LOAD define, rns 2/3, 진행 메시지) |
| 2606121502 | 검토 보완: (1) 진행률 % 계산 u32 오버플로 수정 — `done*100`이 total > 약 43M dword에서 오버플로하므로 divide-first(`done / (total/100+1)`)로 변경, `brns_bg_poll`/`brns_bg_progress` 2곳. (2) RUN 청크 진입 시마다 `REG(ADDR_FW_BUSY)=1` 재어서트 — 청크 사이 실행되는 다른 명령들이 FW_BUSY를 0으로 청산(스톰핑)하는 것 보상 |
| 2606121543 | 버벅거림 대책 + 실측: (1) 적응형 청크 — `BRNS_BG_CHUNK_CONN=512`(연결 시, ~0.5ms) / `BRNS_BG_CHUNK_IDLE=4096`(미연결 시, ~4ms), `func_ether_conn` 기준 자동 전환. (2) 청크 시간 실측 — FPGA free-running 카운터 `AREG(0x43E0C024)`(100MHz, 10ns/tick)로 청크당 last/avg/min/max(µs) 및 누적 전송시간 측정, Finish 메시지와 `rns 3`(`brns_bg_disp_status()`)에서 출력 |
| 260612 (user) | `brns_bg_init()`의 `REG(ADDR_FW_BUSY)=1` → `=0` 수정 (`no busy use`) — XML_BUSY(`func_busy \| REG(ADDR_FW_BUSY)`)가 host 이미지 출력을 막기 때문 |
| 2606121604 | FW_BUSY 잔존 제거 — RUN 청크 재어서트(2606121502) 및 finish 클리어 주석 처리. bg 로드는 더 이상 FW_BUSY를 소유하지 않음 |
| 2606121620 | 로딩 중 NUC gain 보정 OFF: (1) `brns_bg_init()`에서 `ADDR_GAIN_CAL=0` (offset 0x0050은 독립 — 건드리지 않음). (2) `execute_cmd_gain()`에 `brns_bg_active()` 가드 — 로딩 중 gc/GenICam/부팅 경로로 켜도 레지스터 0 유지, 요청값은 `func_gain_cal`에 저장. (3) finish에서 `brns_bg_state=IDLE` **이후** `execute_cmd_gain(func_gain_cal)` 호출로 GAIN+OFFSET 동시 복원 (gain ON은 offset ON 필요; IDLE 이전 호출 시 가드에 걸려 0이 써지므로 순서 중요) |
| 2606121641 | **`rns 2/3` 디스패치 버그 수정** — UART 파서의 `num`은 인자 개수, 값은 `data[0]`. 기존 `num==2/3` 분기는 도달 불가였고 `rns 2/3`이 전부 `num==1`(동기 전체 로드)로 빠짐. `num==1` 내부에서 `switch(data[0])` 1/2/3 분기로 재구성 |
| 2606121720 | (1) **GEV SPI busy 양보 추가** — host XML 다운로드(GVCP READMEM)가 GEV 코어 SPI 엔진으로 flash(`FLASH_XML_BASEADDR`)를 읽는 동안 청크 로드 일시정지. `gige_spi_gcsr` done 비트(0x80000000)로 감지, busy면 청크 skip + idle 카운터 리셋, `BRNS_BG_SPI_IDLE_POLLS`(1000) 연속 idle 관측 후 재개 (클록 불필요). (2) **청크 시간 측정/표시 제거** — `AREG(0x43E0C024)` 단독 읽기가 latch된 stale 값 반환(전 청크 delta=0)으로 무의미. 통계 변수/측정/출력 전부 주석 처리, 청크 수(`chunks`)와 양보 횟수(`spi_hold`)만 Finish/`rns 3`에 표시 |
| 2606121740 | **이벤트 기반 suspend/resume (주 메커니즘)** — 실보드에서 `spi_hold=0`(SPI busy가 poll에 안 잡힘, READMEM이 gige_callback 내부 동기 완결로 추정)이라 libgige `gige_event()`(user.c) 이벤트로 전환: `LIB_EVENT_GVCP_CONFIG_WRITE`(앱 접속) → `brns_bg_suspend()` 청크 정지, `STREAM_OPEN`/`APP_DISCONNECT`/`LINK_DOWN` → `brns_bg_resume()` 즉시 재개, 안전 타임아웃 `BRNS_BG_SUSPEND_POLLS`(300000 poll, 튜닝 필요). suspend/resume/timeout 시 메시지 출력, SPI busy 첫 감지 시 진단 메시지(`spi busy detected`) 추가, `rns 3`에 suspend 잔여 카운터 표시 |
| 2606151027 | **flash 접근 감지 방식 교체 (busy-bit → addr-change)** — 실측에서 busy-bit/이벤트 둘 다 XML 다운로드 중 청크 정지 실패 확인(메시지 안 찍힘, 진행률 계속 증가). 근본 원인: `flash_read_dword`/라이브러리 XML 읽기가 `flash_done()` busy-wait로 gige_callback 안에서 **동기 완결** → poll 시점엔 done 비트 항상 1, 또 XML READMEM은 GVCP config write보다 먼저 옴. 해결: `gige_spi_addr`(읽기마다 갱신되는 주소 레지스터)를 poll 간 비교 — 값이 바뀌었으면 직전 루프에 flash 접근이 있었다는 뜻이므로 청크 skip + idle 리셋, `BRNS_BG_SPI_IDLE_POLLS` 연속 무변화 후 재개. snapshot은 init의 모든 flash 읽기 직후 seed. 메시지 `flash activity detected (hold=N)` |
| 2606151121 | **offset 취득을 이더넷 연결 이후로 지연 (`OFFSET_AFTER_ETH`)** — 부팅 시 `get_calib_init()`이 안정화 대기 없이 즉시 `execute_cmd_wddr(1,..)`로 offset(DOSE0)을 잡아 불안정 이미지가 들어가는 문제. 어차피 이미지는 이더넷 연결 후에만 보므로, 연결까지의 링크/디스커버리 시간 동안 센서가 안정화됨을 활용. `get_calib_init`은 인라인 grab 대신 `func_offset_after_eth=1` 예약만, main 루프의 `check_offset_after_eth()`가 `func_ether_conn==1`(레벨 트리거: 부팅은 연결 대기, hwcal 재교정은 이미 연결돼 즉시 실행)일 때 offset 취득. `OFFSET_AFTER_ETH 0`이면 기존(즉시) 동작 |
| 2606151146 | **지연 offset 취득 `Image Average=0` 수정** — 2606151121이 `func_calib_cmd=1` 경로로만 트리거해 부팅 인라인이 갖던 영상 파이프라인 컨텍스트(`OUT_EN=1`+acq)를 잃음 → 평균기 입력 0 → avg=0(영상에 offset 미적용). `check_offset_after_eth()`을 직접 grab으로 변경: `OUT_EN=1`+`gige_set_acquisition_status(0,1)`+`grab(1)` 설정 후 `execute_cmd_wddr(1,user_avg_level)`(global-shutter 제외, 부팅 parity), 완료 후 `OUT_EN` 원복(`outen_save`). 연결 시점엔 호스트 스트리밍 전이라 토글 안전 |
| 2606151409 | **전송 hang 디버깅 (진단용 프린트)** — 증상: brns 완료→연결→offset→전송 시 영상 안 올라오고 FW hang. 의심 지점: `check_offset_after_eth()`이 **연결 후** `gige_set_acquisition_status()`/`OUT_EN`을 토글(BEFORE에는 연결 전 부팅에서만 실행) → GEV 라이브러리 스트림 상태머신과 충돌 추정. `DBG_offeth`(func_basic.c, 기본 1) 단계별 `[OFFETH]` 프린트 + user.c acq-start `[ACQ]` 프린트 추가. hang 직전 마지막 출력으로 위치 특정 (offset 내부 vs 반환 후 스트림 시작 경로). 진단 후 제거/수정 예정 |

---

## 1. 배경 / 문제

`execute_cmd_brns()`(flash → DDR CH1 NUC 데이터 적재, 6~12초 소요)가 부팅 직후
이더넷 커넥션 **전에** 동기 실행되어, 완료까지 GVCP discovery/connection이 사실상
먹통이 되는 문제.

확인된 호출 체인:

1. `func_rns_valid = 1` 부팅 기본값 — `func_basic.c:43` (`//# 241217`)
2. main `while(1)` → `update_data()` → `update_image()` — `func_basic.c`
   첫 온도 샘플 직후 `get_calib_init()` 호출
3. `get_calib_init()` 내부에서 `execute_cmd_brns()` 동기 호출 — `calib.c`
4. `execute_cmd_brns()`(활성 변형: `GAIN_CALIB_SAVE_NUC_PARAM`, `fpga_info.h:195`)는
   `repeat = flash_width_x32 × flash_height × nun_num` dword를 단일 루프로 전부 전송.
   루프 내 `(i & 0x3FFFF)==0`(약 250ms)마다 `gige_callback(0)` 1회로는 부족.

## 2. 변경 개요

| 항목 | 내용 |
|------|------|
| 동작 선택 | `#define BRNS_BG_LOAD` (func_cmd.h) — **0 = 기존 동기 로드, 1 = 백그라운드 청크 로드(기본)** |
| 시작 시점 | `brns_bg_request()` 직후 다음 main 루프 poll부터 즉시 시작. **이더넷 연결 대기 없음** — 청크 단위로 돌므로 main 루프(gige_callback)가 계속 돌아 연결이 병행 진행됨 |
| 전송 단위 | `BRNS_BG_CHUNK_DWORDS = 4096` dword/청크 ≈ 4ms (기존 코드 주석 기준 약 1M dword/s) |
| 구동 위치 | main `while(1)`에서 매 루프 `brns_bg_poll()` 1회 = 1청크 |
| 보호 | 로딩 중 `set_ddr_ch_en()`이 `DDR_CH_EN_R_NUC`(+0x20) 마스크 (부분 적재 데이터 보정 사용 방지), `REG(ADDR_FW_BUSY)=1` 유지 |
| flash 점유 | 청크마다 FLA 엔진 재시크(`ADDR_FLA_ADDR` 설정 후 `CTRL=1`) / 청크 종료 시 `CTRL=0` 해제 → 청크 사이에는 다른 flash 사용자와 충돌 없음 |
| 신규 UART 명령 | `rns 2` = 백그라운드 재로드 요청, `rns 3` = 진행 상태 조회 |
| 진행 메시지 | 로딩 중 10% 단위로 `[BRNS-BG] xx% (loaded/total dwords)` 자동 출력 |
| 기존 경로 | `execute_cmd_brns()` 본체와 UART `rns 1`(동기 로드)은 그대로 유지 |

설계 이력: 초기안에는 이더넷 연결(`func_ether_conn`) 대기 상태(WAIT_ETH)와
타임아웃(`BRNS_BG_ETH_WAIT_POLLS`)이 있었으나, **청크 로드 자체가 main 루프를
막지 않으므로 연결을 기다릴 이유가 없어 삭제** (2026.06.12 결정).

## 3. 상태머신

```
BRNS_BG_IDLE ──brns_bg_request()──▶ BRNS_BG_PEND ──헤더 파싱 OK──▶ BRNS_BG_RUN ──완료──▶ BRNS_BG_IDLE
                                         │ (NUC 없음/헤더 불량)                │ (로딩 중 재요청 시)
                                         └────────▶ BRNS_BG_IDLE        PEND 로 재시작
```

| API (func_cmd.c / func_cmd.h) | 역할 |
|------|------|
| `void brns_bg_request(void)` | 로드 요청. 로딩 중 재요청이면 현재 청크 종료 후 처음부터 재시작 |
| `void brns_bg_poll(void)` | main 루프 매회 호출. PEND: 헤더 파싱 / RUN: 1청크 전송·완료 처리 |
| `u8 brns_bg_active(void)` | IDLE이 아니면 1 (UART `rns 1` busy 가드용) |
| `u8 brns_bg_progress(void)` | 진행률 0~100(%) — `rns 3` 조회용 |

원본 `execute_cmd_brns()` 루프와 동일하게 복제한 부분:
- NUC info 13 dword 파싱, `func_img_avg_dose1~4`, `mpc_cal()`, 존재 체크
- `nun_num` dword마다 0 패딩 1 dword 삽입
- `def_gev_speed != 10`일 때 `ddr_addr += (16 - 4*nun_num)` 주소 스킵
- FLA 수동 주소 증가 시퀀스 (`CTRL=0b11` → `CTRL=0b01`)

원본과 의도적으로 다른 부분:
- 진행바 `*` / 루프 내 `gige_callback(0)` 제거 → 매 청크마다 main 루프 복귀
- `brns_bg_flash_addr`를 dword마다 추적, 청크 시작 시 FLA 엔진 재시크
- 진행 메시지 10% 단위 출력, `[BRNS-BG]` 프리픽스
- `brns_bg_total == 0`(ref 1장 이하) 시 로드 스킵 가드 추가

## 4. 수정 파일 및 위치 (태그 `2606121417` grep)

| # | 파일 | 수정 내용 |
|---|------|-----------|
| 1 | `func_cmd.h` | `BRNS_BG_LOAD` define(기본 1), `brns_bg_*` 프로토타입 4종, `func_ddrchen_brns_stat` extern — `execute_cmd_brns()` 선언 직후 |
| 2 | `func_cmd.c` | `brns_bg_*` 상태머신 신규 — brns 변형 select `#endif` 직후 (`rns_display()` 앞) |
| 3 | `calib.c` | `get_calib_init()`: `execute_cmd_brns()` 주석 처리 → `#if BRNS_BG_LOAD` 분기 (request vs 기존 동기 호출) |
| 4 | `main.c` | `while(1)` `genicam_command()` 뒤에 `brns_bg_poll()` (`#if BRNS_BG_LOAD`), 이력 73번 append, `FW_DATE` = "2026.06.12 14:17" |
| 5 | `func_basic.c` | `set_ddr_ch_en()`: 로딩 중 `R_NUC` 마스크 + `[DBG]` 로그에 `brns_stat` 컬럼 추가 |
| 6 | `command.c` | `UART_CMD_rns()`: `rns 1` busy 가드(ERR5), `rns 2`/`rns 3` 신규 |

`BRNS_BG_LOAD 0`으로 빌드하면: calib.c/main.c 호출부가 기존 경로로 복귀,
상태머신은 요청이 없어 휴면(`brns_bg_active()`=0, `func_ddrchen_brns_stat`=0),
`rns 2`/`rns 3`은 ERR3 → 동작/로그 모두 기존과 동일.

## 5. UART 명령 (수정 후)

| 명령 | 동작 |
|------|------|
| `rns` | (기존) read-only 진단 덤프 `rns_display()` — 변경 없음 |
| `rns 1` | (기존) 동기 brns — **bg 로딩 중이면 ERR5(busy)** |
| `rns 2` | **신규**: 백그라운드 NUC 재로드 요청 (로딩 중이면 처음부터 재시작) |
| `rns 3` | **신규**: 진행 상태 조회 (`[BRNS-BG] loading... xx%` / `idle`) |

로딩 중 자동 출력 예:
```
[BRNS-BG] Start: 9437184 dwords, chunk=4096
[BRNS-BG] 10% (943718/9437184 dwords)
...
[BRNS-BG] 100% (9437184/9437184 dwords)
[BRNS-BG] Finished! brns
```

문서 갱신 필요: `UART Command 정리_211102.xlsx`에 `rns 2`, `rns 3` 행 추가 (수동).

## 6. 검증 계획 (실보드)

1. `BRNS_BG_LOAD=1` 빌드: 부팅 로그에서 `[BRNS-BG] Start` 이후에도
   "Device Discovery Success"가 지연 없이 출력되는지 (이더넷 병행 진행 확인)
2. 10%~100% 진행 메시지 / `[BRNS-BG] Finished!` 후 이득 보정 영상 정상 확인
   (`[DBG] set_ddr_ch_en` 로그에서 R_NUC(+0x20) 비트 복원 확인)
3. 로딩 중 `rns 1` → ERR5, `rns 2` → restart 메시지, `rns 3` → 진행률 출력
4. 로딩 중 GVCP 응답성 (host 연결/feature read) — 청크 4096이 크면 2048로 축소
5. 영상 데이터 무결성: bg 로드 후 영상 vs legacy(`BRNS_BG_LOAD=0`) 로드 후 영상 비교
   (FLA 재시크 방식이 연속 읽기와 동일한 데이터를 주는지 확인 포인트)
6. `BRNS_BG_LOAD=0` 빌드: 기존과 완전 동일 동작 (회귀 확인)
7. hwcal(재교정) 후 `get_calib_init()` 재호출 경로에서 bg 재로드 정상 동작

## 7. 튜닝 / 후속 항목

- `BRNS_BG_CHUNK_DWORDS`: 4096(≈4ms) 시작, GVCP 응답성에 따라 2048로 조정 가능
- `calib.c`의 `wait5sec_once` 20초 루프(`//# 241217`): brns 블로킹 보상용이었으므로
  본 변경 검증 후 단축/제거 검토 (이번 변경에서는 유지)
