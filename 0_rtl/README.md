# 0_rtl

이 디렉터리는 `aes128_core` 프로젝트의 기준 RTL 소스 폴더입니다. 이후 `1_vcs`, `2_synthesis`, `3_DFT`, `4_STA`, `5_FM`는 모두 이 폴더의 RTL을 출발점으로 사용합니다.

포트폴리오 관점에서 이 디렉터리에서 가장 중요한 변화는, 단순히 RTL이 동작하는 수준을 넘어서 **후속 합성/STA/DFT까지 고려한 구조 수정**이 실제로 들어갔다는 점입니다.

즉 이 디렉터리의 RTL 수정은 기능 버그를 고치는 수준이 아니라,

- 빠른 clock domain에서 timing이 버틸 수 있는 구조로 바꾸고
- multi-clock control path를 더 안전하게 만들고
- 후속 DFT/STA/FM이 해석하기 쉬운 형태로 정리하는

방향으로 진행됐습니다.

## 포함된 주요 RTL

- `top_mcu_pll_sram_multiclk_soc.v`
  - 프로젝트 top
- `soc_ctrl_multiclk_soc.v`
  - SoC control/datapath orchestration
- `aes128_core.v`
  - 기존 AES128 core
- `aes128_core_rewrite.v`
  - timing-aware로 새로 작성한 AES128 core
- `uart_rx.v`, `uart_tx.v`
  - UART block
- `sram_wrap_1rw1024x8.v`
  - SRAM wrapper
- `cdc_toggle_sync.v`, `clk_div2_toggle.v`, `icg_latch.v`, `crc32_byte.v`
  - 보조 블록

## 이 디렉터리에서 중요했던 RTL 수정

가장 큰 RTL 수정은 커밋
`3dc45d4c9d30b4a8d282e4b9580995d782ea0e13`
(`FF수정 및 8ns 기준 후속 DFT, FM, 진행`)입니다.

이 커밋에서 RTL 변경 파일은 두 개입니다.

- [aes128_core_rewrite.v](/DATA/home/edu135/aes128_core/0_rtl/aes128_core_rewrite.v)
- [soc_ctrl_multiclk_soc.v](/DATA/home/edu135/aes128_core/0_rtl/soc_ctrl_multiclk_soc.v)

이 커밋의 핵심 방향은 한 문장으로 요약하면 다음과 같습니다.

`기능은 유지하되, AES와 주변 제어/메모리/TX 경로를 더 잘게 나누고 도메인 경계를 더 명확히 해서 FF 기준 8ns 흐름이 버틸 수 있는 RTL로 재구성한다.`

즉 “동작하는 RTL”을 “구현 가능한 RTL”로 밀어가는 수정이었습니다.

## 1. `aes128_core_rewrite.v` 추가

### 문제

기존 AES 코어는 기능적으로는 맞지만, FF 기준 timing에서 조합 경로가 너무 크게 보일 수 있었습니다. 특히 `clk_fast_aes`처럼 빠른 domain에서는 구조를 더 잘게 쪼개는 방향이 필요했습니다.

좀 더 구체적으로 보면 기존 구조의 위험은 아래와 같았습니다.

- key expansion, subbytes, shiftrows, mixcolumns, addroundkey가 한 덩어리로 합성되면 조합 cone이 커질 수 있음
- same RTL이라도 corner나 compile 방향에 따라 합성 결과가 크게 흔들릴 수 있음
- PT에서 `clk_fast_aes` margin이 매우 얇거나 음수로 보일 가능성이 있음

즉 기능 알고리즘의 문제라기보다, **고속 도메인에서 구현 구조가 너무 무겁게 보일 수 있는 위험**이 있었습니다.

### 수정

새 파일 [aes128_core_rewrite.v](/DATA/home/edu135/aes128_core/0_rtl/aes128_core_rewrite.v)를 추가했습니다.

핵심 구조:

- phase 기반 state machine
  - `PH_KEY`
  - `PH_SUB`
  - `PH_SHIFT`
  - `PH_MIX`
  - `PH_ADD`
- round key를 `rk0_q ~ rk3_q`로 분리
- byte/word 단위 처리
- key expansion, subbytes, shiftrows, mixcolumns를 한 번에 크게 몰지 않고 여러 사이클로 나눔

구조적 관점에서 보면 이 RTL은 아래 방향으로 재설계된 것입니다.

1. 큰 조합 연산을 단계별로 나눔
2. key 관련 state와 data 관련 state를 register 중심으로 나눔
3. 한 사이클에 처리하는 비트 범위를 줄임
4. timing이 민감한 path를 phase/state machine으로 분산함

### 의도

이 구조의 목적은 기능 변경이 아니라 **큰 조합 경로를 줄여 합성/STA에서 더 안정적인 구조를 만드는 것**입니다.

즉,
- AES 연산량은 유지
- 구현은 더 staged하게 분해
- FF/corner에서 timing margin을 확보하기 쉽게 만든 것

더 크게 보면 이 파일의 방향성은 아래와 같습니다.

- “알고리즘 중심 RTL”에서
- “구현/타이밍 중심 RTL”로 이동

즉 읽기만 쉬운 RTL보다, 실제 합성/STA/DFT에서 살아남는 RTL을 목표로 한 수정입니다.

## 2. `soc_ctrl_multiclk_soc.v` 리팩터링

### 문제

AES core를 새 구조로 바꾸면, 주변 control path도 같이 정리해야 했습니다. 특히 아래가 중요했습니다.

- 다른 clock domain에서 `done`을 바로 쓰는 구조
- SRAM write/read/verify 경로가 byte slicing에 과하게 의존하는 구조
- TX 경로가 큰 bus slice를 반복해서 읽는 구조

이 문제들은 각각 성격이 다르지만 공통점이 있습니다.

- 기능적으로는 동작할 수 있어도
- 합성 후 cone이 커지거나
- CDC 관점에서 해석이 애매해지거나
- STA에서 원인 추적이 어려워질 수 있다는 점

즉 `soc_ctrl_multiclk_soc.v`는 단순한 glue logic가 아니라,
프로젝트 전체에서 가장 많은 “구현 리스크”가 모이는 파일이었습니다.

### 수정

[soc_ctrl_multiclk_soc.v](/DATA/home/edu135/aes128_core/0_rtl/soc_ctrl_multiclk_soc.v)에서 아래를 바꿨습니다.

#### 1. AES 인스턴스 교체

- 기존:
  - `aes128_core u_aes`
- 변경:
  - `aes128_core_rewrite u_aes`

즉 controller가 새 AES 코어를 쓰도록 바꿨습니다.

이 변경의 의미는 단순한 module name 교체가 아닙니다.

- controller의 start/done/busy 제어 방식
- fast/div2/div4 domain 간 데이터 흐름
- 후속 SRAM write/read/CRC/TX 파이프라인

이 모두 새 AES 코어의 temporal behavior를 기준으로 다시 맞춰야 했다는 뜻입니다.

#### 2. `done` 신호를 `clk_div4` 도메인에서 동기화

추가:

- `done_div4_ff1`
- `done_div4_ff2`
- `wire done_div4`

그리고 `start_uart_cmd` 해제 조건을
- 기존 `done`
- 에서 `done_div4`
로 바꿨습니다.

의미:
- 다른 clock domain 신호를 바로 제어에 쓰지 않고, 수신 도메인에서 한 번 정리해서 씀
- 단순한 2FF 동기화이지만, “기능은 맞는데 구현이 불안정한 RTL”을 피하는 데 중요함

방향성:
- multi-clock design에서는 “신호를 바로 쓰지 말고, 도착 도메인에서 의미를 다시 정의한다”
- 여기서는 `done`을 `clk_div4` 기준 이벤트로 다시 만든 것

#### 3. SRAM state machine 구조 변경

기존에는 `byte_idx` 중심 구조였습니다.  
변경 후에는 아래처럼 역할을 나눴습니다.

- `S_LOAD`
- `S_W`
- `S_R`
- `S_RWAIT`
- `S_CHK`
- `S_FIN`
- `S_DONE`

그리고 인덱스도 분리했습니다.

- `load_idx`
- `wr_idx`
- `rd_idx`

또 `select_ct_byte()` 함수를 추가해서 ciphertext byte 선택을 명시적으로 처리하도록 바꿨습니다.

의미:
- CDC landing register를 한 번만 ownership register로 잡고
- active cone에서는 큰 bus slice를 반복 재구성하지 않도록 정리

이 부분의 방향성은 매우 중요합니다.

기존 구조는 “간단하게 보이지만 큰 bus를 계속 동적으로 잘라 쓰는 방식”에 가까웠고,
수정 후 구조는 “한 번 잡은 데이터를 단계별로 소비하는 방식”에 가깝습니다.

즉,
- 표현은 길어졌지만
- 데이터 흐름은 더 명확해졌고
- 합성기가 불필요하게 큰 mux/slice cone을 만들 가능성은 줄었습니다.

#### 4. TX 경로 정리

추가:

- `tx_ct_byte_cur`

의미:
- 매번 `ct_hold_div2[127 - idx*8 -: 8]` 같은 큰 동적 slicing을 반복하지 않고,
- 현재 보낼 byte를 작은 register로 잡아서 TX 쪽 cone을 정리

방향성:
- “필요한 순간에 필요한 byte만 작은 register로 들고 간다”
- 즉 큰 128-bit bus 자체를 여러 블록이 계속 직접 참조하지 않게 만드는 것

## 왜 이 수정이 중요했는가

이 RTL 수정은 단순한 스타일 변경이 아니라, 이후 흐름에 직접 영향을 줬습니다.

### 합성 관점

- AES 내부를 더 staged하게 바꿔서 빠른 clock domain에서 timing 회복 여지를 만들었습니다.
- `u_ctrl/u_icg_aes` generated clock anchor를 유지한 채 내부 logic를 재구성할 수 있게 방향을 열었습니다.
- controller를 완전히 흩뜨리지 않고, 내부 datapath만 조정할 수 있는 구조로 가는 기반이 됐습니다.

관련 문서:
- [2_synthesis/README.md](/DATA/home/edu135/aes128_core/2_synthesis/README.md)

### STA 관점

- `clk_fast_aes` 경로를 더 해석 가능하게 만들었습니다.
- 큰 bus slice 기반 구조를 줄여 `func`/`capture`/`shift` 분석에서 원인 파악이 쉬워졌습니다.
- 나중에 남은 hold 문제를 “RTL bug”가 아니라 “SRAM macro short path ECO 문제”로 분리해서 볼 수 있게 했습니다.

관련 문서:
- [2.5_STA/README.md](/DATA/home/edu135/aes128_core/2.5_STA/README.md)
- [4_STA/README.md](/DATA/home/edu135/aes128_core/4_STA/README.md)

### DFT 관점

- controller-level ICG anchor를 유지해서 `3_DFT`에서 clock-gating hookup을 계속 같은 계층 기준으로 적용할 수 있게 했습니다.
- scan insertion 이후에도 netlist 구조를 비교적 설명 가능한 형태로 유지하는 데 도움이 됐습니다.

관련 문서:
- [3_DFT/README.md](/DATA/home/edu135/aes128_core/3_DFT/README.md)

## 이 RTL 수정의 결과를 어떻게 봐야 하는가

이 커밋 하나만으로 모든 문제가 끝난 것은 아닙니다.  
하지만 이 수정은 이후 단계의 기반이 되었습니다.

실제로 이후 흐름에서 확인된 결과:

- synthesis baseline 정리
- DFT single scan chain insertion 성공
- STA scenario 정리
- post-DFT SRAM hold violation은 남았지만, 이는 RTL bug보다 short path ECO 문제로 분리됨
- 최종적으로는 post-DFT ECO까지 포함해 `func/capture/shift` timing clean 상태에 도달

즉 이 RTL 수정의 의미는:
- 기능 유지
- 구조 단순화
- 고속 domain 해석 가능성 향상
- 후속 구현/검증 흐름 안정화

더 직접적으로 표현하면, 이 수정의 목적과 방향성은 아래와 같습니다.

### 목적

- FF 기준 8ns 흐름에서 버틸 수 있는 RTL 구조 만들기
- multi-clock control path를 더 안전하게 만들기
- 큰 bus slicing과 복잡한 cone을 줄이기
- 후속 DFT/STA/FM이 해석 가능한 구조를 만들기

### 방향성

- “한 번에 크게 계산”하는 구조를 줄이고 단계적으로 나누기
- “도메인 사이에서 바로 신호를 소비”하지 않고, 도착 도메인 기준으로 재정의하기
- “큰 버스를 여러 곳에서 직접 slicing”하지 않고, 작은 local register로 쪼개서 전달하기
- “기능만 맞는 RTL”보다 “합성/STA/DFT가 따라갈 수 있는 RTL”을 우선하기

## 기억이 안 날 때 먼저 볼 파일

이 RTL 수정의 의미를 나중에 다시 확인하려면 아래를 먼저 보면 됩니다.

1. [aes128_core_rewrite.v](/DATA/home/edu135/aes128_core/0_rtl/aes128_core_rewrite.v)
   - AES core staged 구조 자체
2. [soc_ctrl_multiclk_soc.v](/DATA/home/edu135/aes128_core/0_rtl/soc_ctrl_multiclk_soc.v)
   - controller, SRAM path, TX path 정리
3. [2_synthesis/README.md](/DATA/home/edu135/aes128_core/2_synthesis/README.md)
   - 이 RTL이 합성에서 어떤 의미를 가졌는지
4. [4_STA/README.md](/DATA/home/edu135/aes128_core/4_STA/README.md)
   - 최종적으로 어떤 timing 결과로 이어졌는지
