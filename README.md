# aes128_core

이 저장소는 AES128 기반 SoC 형태의 RTL부터 기능 검증, 합성, DFT, STA, FM까지 이어지는 전체 디지털 구현 흐름을 정리한 프로젝트입니다. 현재 기준 top module은 `top_mcu_pll_sram_multiclk_soc`입니다.

이 프로젝트의 핵심은 단순히 AES 코어 하나를 동작시키는 것이 아니라, 아래 흐름을 실제로 연결해서 검증한 점입니다.

- RTL 작성
- VCS 기능 검증
- Design Compiler 합성
- single scan chain 기반 DFT insertion
- PrimeTime STA
- Formality r2n / n2n
- post-DFT hold ECO

즉 “RTL이 맞는다” 수준이 아니라, “합성/DFT/STA/FM까지 이어지는 흐름이 실제로 굴러간다”는 점이 이 저장소의 가장 중요한 결과입니다.

## SoC 구성

현재 top 내부에는 아래 블록이 포함됩니다.

- AES128 core
- UART RX/TX
- SRAM wrapper + SRAM macro
- PLL black-box
- clock divider
- CDC logic
- clock gating logic

## 전체 디렉터리 구조

```text
aes128_core/
├── 0_rtl/
├── 1_vcs/
├── 2_synthesis/
├── 2.5_STA/
├── 3_DFT/
├── 4_STA/
├── 5_FM/
├── SAED32_EDK/
├── docs/
└── .synopsys_dc.setup
```

각 디렉터리의 역할은 다음과 같습니다.

- `0_rtl`
  - 기준 RTL 소스
- `1_vcs`
  - 기능 검증 환경
- `2_synthesis`
  - Design Compiler 합성
- `2.5_STA`
  - 실험/비교용 PrimeTime STA
- `3_DFT`
  - scan insertion
- `4_STA`
  - post-DFT 기준 최종 pre-layout STA
- `5_FM`
  - RTL vs synth / synth vs DFT formal check
- `docs`
  - 분석 메모와 계획 문서

## 전체 흐름

이 저장소의 작업 순서는 아래처럼 보면 됩니다.

1. `0_rtl`
   - RTL 작성 및 구조 수정
2. `1_vcs`
   - 기능 검증
3. `2_synthesis`
   - mapped netlist와 synthesis SDC 생성
4. `3_DFT`
   - post-DFT netlist 생성
5. `4_STA`
   - post-DFT timing 검증
6. `5_FM`
   - formal equivalence 검증

중간에 `2.5_STA`는 final signoff용이라기보다, 아래를 비교/실험하는 워크스페이스입니다.

- synth vs DFT netlist
- SS/FF/TT corner
- generated clock / wire-load / custom ICG 해석 방식

## 각 단계의 의미

### 1. 기능 검증: `1_vcs`

기능 검증은 VCS 환경에서 수행합니다. 이 단계의 목적은 합성 이전에 기능이 맞는지 확인하는 것입니다.

관련 README:
- [1_vcs/README.md](1_vcs/README.md)

### 2. 합성: `2_synthesis`

합성은 mapped netlist와 `soc_func.sdc`를 만들어 이후 DFT/STA/FM의 기준을 세우는 단계입니다.

이 단계에서 중요했던 점:
- `clk_fast_aes`처럼 민감한 generated clock domain을 clean하게 유지
- hierarchy와 ICG anchor를 후속 단계에서 다시 쓸 수 있게 유지
- warning을 무조건 bug로 보기보다 허용 경고와 실제 이슈를 구분

관련 README:
- [2_synthesis/README.md](2_synthesis/README.md)

### 3. 실험/비교용 STA: `2.5_STA`

이 단계는 최종 결과를 내기 위한 공간이 아니라, synthesis netlist와 DFT netlist를 비교하고, corner sweep과 constraint 해석 방식을 정리하는 공간입니다.

이 단계에서 중요했던 점:
- synthesis SDC를 sanitize해서 cross-corner STA를 안정화
- flat wire-load와 legacy hierarchy wire-load를 비교
- custom ICG 내부 arc를 generated clock 관점으로 정리

관련 README:
- [2.5_STA/README.md](2.5_STA/README.md)

### 4. DFT: `3_DFT`

DFT는 `2_synthesis`의 mapped DDC를 입력으로 받아 single scan chain을 삽입하는 단계입니다.

이 단계에서 중요했던 점:
- `ref_clk`, `scan_en`, `scan_in`, `scan_out`, `test_mode` 기반 single chain 구성
- custom AES clock gating cell을 test 시 열 수 있도록 hookup
- pre/post DFT DRC와 scan chain 구조 확인

관련 README:
- [3_DFT/README.md](3_DFT/README.md)

### 5. 최종 STA: `4_STA`

최종 STA는 post-DFT netlist 기준으로 `func`, `scan_capture`, `scan_shift`를 나눠 timing을 검증하는 단계입니다.

이 단계에서 중요했던 점:
- scenario별로 coverage를 다르게 해석
- `scan_capture`에서 recovery/removal을 실제로 met시키는 것
- post-DFT hold violation을 ECO로 닫는 것

관련 README:
- [4_STA/README.md](4_STA/README.md)

### 6. Formality: `5_FM`

FM은 아래 두 가지를 확인합니다.

- `r2n`
  - RTL vs synthesis gate
- `n2n`
  - synthesis gate vs DFT gate

즉 기능적으로 RTL이 유지됐는지, DFT insertion 이후에도 논리 등가가 유지됐는지를 확인하는 단계입니다.

## 실제로 겪었던 대표 문제

이 프로젝트에서는 아래 문제가 실제로 중요했습니다.

### 1. `clk_fast_aes` margin이 얇았다

- 합성과 PT 해석이 완전히 같은 방향으로 나오지 않았고,
- AES clock-gated domain이 특히 빡빡했습니다.

해결 방향:
- hierarchy/ungroup 전략 조정
- generated clock anchor 유지
- wire-load policy 단순화

### 2. synthesis SDC를 STA에서 그대로 읽기 어려웠다

- source-corner wire-load 명령 때문에 cross-corner STA가 흔들렸습니다.

해결 방향:
- `2.5_STA`, `4_STA`에서 sanitized SDC 생성 후 사용

### 3. custom ICG 때문에 clock-gating 관련 해석이 복잡했다

- RTL 기반 custom ICG가 gate/latch로 바뀌면서 PT에서 implementation arc를 과도하게 해석하는 경우가 있었습니다.

해결 방향:
- generated clock 기준 해석
- custom ICG 내부 arc disable

### 4. post-DFT SRAM input hold violation 12개가 남았다

- `u_ctrl -> SRAM macro input` short path 문제였습니다.

해결 방향:
- synthesis에서 억지로 숨기지 않고,
- `3_DFT`에서 Tcl 기반 post-DFT ECO를 만들어
- SRAM `A[*]`, `I[*]` 앞에 inverter pair를 삽입했습니다.

관련 파일:
- [post_dft_hold_eco.tcl](3_DFT/0_script/post_dft_hold_eco.tcl)
- [run_hold_eco.csh](3_DFT/run_hold_eco.csh)

## 현재 최종 baseline

현재 흐름상 가장 중요한 버전은 아래 두 개입니다.

### synthesis baseline

- `4_15_8ns_ff`
- 생성물:
  - [soc_gate.v](2_synthesis/2_output/4_15_8ns_ff/mapped/soc_gate.v)
  - [soc_gate.ddc](2_synthesis/2_output/4_15_8ns_ff/mapped/soc_gate.ddc)
  - [soc_func.sdc](2_synthesis/2_output/4_15_8ns_ff/mapped/soc_func.sdc)

### post-DFT ECO baseline

- `4_15_8ns_ff_holdfix_tcl6`
- 생성물:
  - [aes_128_internal.v](3_DFT/2_output/4_15_8ns_ff_holdfix_tcl6/aes_128_internal.v)

### 최종 STA 결과

- [4_STA/4_report/4_15_8ns_ff_holdfix_tcl6](4_STA/4_report/4_15_8ns_ff_holdfix_tcl6)

현재 이 결과에서 확인된 상태:

- `func`
  - setup clean
  - hold clean
- `scan_capture`
  - setup clean
  - hold clean
  - recovery/removal met
- `scan_shift`
  - setup clean
  - hold clean

즉 현재 기준으로는:
- synthesis baseline 확보
- DFT insertion 완료
- post-DFT hold ECO 완료
- pre-layout STA clean
까지 연결된 상태입니다.

## 현재 결과를 한 줄로 요약하면

이 프로젝트는 `AES128 SoC RTL -> 합성 -> DFT -> STA -> FM` 흐름을 실제로 연결했고, 최종적으로 post-DFT hold까지 ECO로 정리한 상태입니다.

## 먼저 보면 좋은 문서

세부 내용은 아래 README를 보면 됩니다.

- 합성: [2_synthesis/README.md](2_synthesis/README.md)
- 실험용 STA: [2.5_STA/README.md](2.5_STA/README.md)
- DFT: [3_DFT/README.md](3_DFT/README.md)
- 최종 STA: [4_STA/README.md](4_STA/README.md)

분석 문서:
- [aes128_core_fm_flow_plan_2026-04-12.md](docs/aes128_core_fm_flow_plan_2026-04-12.md)
- [aes128_core_dft_production_aware_plan_2026-04-13.md](docs/aes128_core_dft_production_aware_plan_2026-04-13.md)

## Git 관리 기준

보통 Git에는 아래를 직접 넣지 않습니다.

- `SAED32_EDK/`
- `2_output/`
- `3_log/`
- `4_report/`
- tool-generated work/alib

주로 Git에 남기는 것은 아래입니다.

- RTL
- constraint
- Tcl / csh scripts
- README / docs
