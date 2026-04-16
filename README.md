# aes128_core

이 저장소는 `top_mcu_pll_sram_multiclk_soc`를 기준으로 RTL부터 기능 검증, 합성, Formality, DFT, STA, ATPG까지 이어지는 전체 디지털 구현 흐름을 정리한 프로젝트입니다.

이 프로젝트의 핵심은 단순히 AES 코어 RTL을 작성한 것이 아니라, 아래 흐름을 실제 산출물과 리포트까지 연결해 검증한 점입니다.

- RTL 작성
- VCS 기능 검증
- Design Compiler 합성
- Formality r2n
- DFT insertion
- Formality n2n
- post-DFT STA
- ATPG

즉 “RTL이 동작한다”를 넘어서, “후속 구현 / test flow까지 실제로 이어진다”는 점이 이 저장소의 핵심 결과입니다.

## SoC 구성

현재 top 내부에는 아래 블록이 포함됩니다.

- AES128 core
- UART RX / TX
- SRAM wrapper + SRAM macro
- PLL block
- clock divider
- CDC logic
- clock gating logic

## 현재 디렉터리 구조

```text
aes128_core/
├── 0_rtl/
├── 1_vcs/
├── 2_synthesis/
├── 2.5_STA/
├── 3_FM/
├── 4_DFT/
├── 5_FM/
├── 6_STA/
├── 7_ATPG/
├── SAED32_EDK/
├── docs/
└── .synopsys_dc.setup
```

각 디렉터리의 역할:

- `0_rtl`
  - 기준 RTL
- `1_vcs`
  - 기능 검증
- `2_synthesis`
  - mapped gate / DDC / synthesis SDC 생성
- `2.5_STA`
  - 실험 / 비교용 STA
- `3_FM`
  - RTL ↔ synthesis gate equivalence
- `4_DFT`
  - scan insertion
- `5_FM`
  - synthesis gate ↔ DFT gate equivalence
- `6_STA`
  - post-DFT pre-layout STA
- `7_ATPG`
  - ATPG
- `docs`
  - 분석 메모와 계획 문서

## 전체 흐름

현재 저장소의 실제 작업 순서는 아래처럼 보는 것이 맞습니다.

1. `0_rtl`
   - RTL 작성 / 수정
2. `1_vcs`
   - 기능 회귀 확인
3. `2_synthesis`
   - mapped netlist / DDC / SDC / SVF 생성
4. `3_FM`
   - RTL ↔ synthesis gate 등가 확인
5. `4_DFT`
   - scan insertion 수행
6. `5_FM`
   - synthesis gate ↔ DFT gate 등가 확인
7. `6_STA`
   - post-DFT timing 검증
8. `7_ATPG`
   - ATPG 수행

중간의 `2.5_STA`는 최종 baseline보다는 아래를 정리하는 실험용 워크스페이스입니다.

- synth vs DFT netlist 비교
- SS / FF / TT corner sweep
- sanitized SDC 해석 방식 검토
- custom ICG / generated clock 해석 정리

## 각 단계의 현재 의미

### 1. 기능 검증: `1_vcs`

현재 `default_nist`, `ext_zero`, `ext_ecb_nist` 3개 testcase가 모두 PASS입니다.

즉 RTL 기준 기능 regression은 현재 맞는 상태입니다.

관련 README:

- [1_vcs/README.md](1_vcs/README.md)

### 2. 합성: `2_synthesis`

현재 synthesis 기준 baseline은 `4_16_8ns_topo_ss`입니다.

현재 상태:

- mapped netlist / DDC / SDC / SVF 정상 생성
- Design WNS/TNS = `0 / 0`
- Hold WNS/TNS = `0 / 0`
- 다만 `clk_fast_aes` 여유는 매우 작음
- max cap violation 28건이 남음

즉 synthesis 결과는 usable baseline이지만, 여유가 아주 큰 상태는 아닙니다.

관련 README:

- [2_synthesis/README.md](2_synthesis/README.md)

### 3. r2n FM: `3_FM`

현재 `r2n_4_16_8ns_topo_ss` 기준으로 `Verification SUCCEEDED`입니다.

현재 상태:

- unmatched 없음
- failing 없음
- aborted 없음
- unverified 없음
- `scan_out` 1개만 dont_verify

즉 RTL ↔ synthesis gate 기능 등가는 현재 정상입니다.

관련 README:

- [3_FM/README.md](3_FM/README.md)

### 4. DFT: `4_DFT`

현재 DFT 기준 baseline도 `4_16_8ns_topo_ss`입니다.

현재 상태:

- scan insertion 정상 완료
- 현재 구조는 single-chain이 아니라 `4-chain`
- 각 chain length는 `383`
- inserted netlist / DDC / SPF / SDF / DEF 생성
- DFT 후 timing은 met
- post-DFT DRC warning 4건은 구조적으로 설명 가능한 수준

즉 현재 DFT는 “정상 삽입 완료”로 보는 것이 맞습니다.

관련 README:

- [4_DFT/README.md](4_DFT/README.md)

### 5. n2n FM: `5_FM`

현재 `n2n_4_16_8ns_topo_ss` 기준으로 `Verification SUCCEEDED`입니다.

현재 상태:

- failing 없음
- aborted 없음
- unverified 없음
- `scan_out` 2개는 dont_verify
- 추가 scan test port 6개는 implementation unmatched

중요한 점:

- 현재 4-chain DFT 구조 때문에 `test_si2/3/4`, `test_so2/3/4`가 implementation 쪽에만 생깁니다.
- 그래서 structural unmatched는 남지만 functional equivalence는 PASS입니다.

관련 README:

- [5_FM/README.md](5_FM/README.md)

### 6. post-DFT STA: `6_STA`

현재 STA 기준 baseline은 `4_16_8ns_topo_ss`입니다.

현재 상태:

- `ff / ss / tt` 결과 존재
- `func / capture / shift` 모두 setup / hold clean
- post-DFT SDF까지 반영한 pre-layout STA 결과 존재
- `check_timing` warning은 일부 남음
- `clk_fast_aes` 여유는 매우 작지만 현재 met

즉 timing 기준으로 ATPG 전 단계까지는 연결된 상태입니다.

관련 README:

- [6_STA/README.md](6_STA/README.md)

### 7. ATPG: `7_ATPG`

현재 ATPG 기준 baseline은 `4_16_8ns_topo_ss`입니다.

현재 상태:

- ATPG 실행 정상 종료
- 4개 scan chain 인식
- internal pattern `215`
- total faults `58765`
- `ND = 0`
- test coverage `99.68%`
- fault coverage `98.79%`

즉 현재 ATPG도 실제로 돌아간 상태입니다.

관련 README:

- [7_ATPG/README.md](7_ATPG/README.md)

## 현재 가장 중요한 baseline

현재 상위 문서 기준으로 가장 먼저 보면 되는 버전은 아래 하나입니다.

- `4_16_8ns_topo_ss`

이 버전에서 현재 확인된 연결은 아래와 같습니다.

- synthesis:
  - [soc_gate.v](2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.v)
  - [soc_gate.ddc](2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.ddc)
  - [soc_func.sdc](2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_func.sdc)
- r2n FM:
  - [r2n_4_16_8ns_topo_ss](3_FM/4_report/r2n_4_16_8ns_topo_ss)
- DFT:
  - [aes_128_internal.v](4_DFT/2_output/4_16_8ns_topo_ss/aes_128_internal.v)
  - [scan_internal.spf](4_DFT/2_output/4_16_8ns_topo_ss/scan_internal.spf)
- n2n FM:
  - [n2n_4_16_8ns_topo_ss](5_FM/4_report/n2n_4_16_8ns_topo_ss)
- post-DFT STA:
  - [4_16_8ns_topo_ss](6_STA/4_report/4_16_8ns_topo_ss)
- ATPG:
  - [4_16_8ns_topo_ss](7_ATPG/4_report/4_16_8ns_topo_ss)

## 현재 상태를 한 줄로 요약하면

현재 `aes128_core`는 `RTL -> VCS -> synthesis -> r2n FM -> DFT -> n2n FM -> STA -> ATPG` 흐름이 `4_16_8ns_topo_ss` 기준으로 실제 산출물과 리포트까지 연결된 상태입니다.

## 먼저 보면 좋은 문서

- 기능 검증: [1_vcs/README.md](1_vcs/README.md)
- 합성: [2_synthesis/README.md](2_synthesis/README.md)
- 실험용 STA: [2.5_STA/README.md](2.5_STA/README.md)
- r2n FM: [3_FM/README.md](3_FM/README.md)
- DFT: [4_DFT/README.md](4_DFT/README.md)
- n2n FM: [5_FM/README.md](5_FM/README.md)
- post-DFT STA: [6_STA/README.md](6_STA/README.md)
- ATPG: [7_ATPG/README.md](7_ATPG/README.md)

분석 문서:

- [aes128_core_fm_flow_plan_2026-04-12.md](docs/aes128_core_fm_flow_plan_2026-04-12.md)
- [aes128_core_dft_production_aware_plan_2026-04-13.md](docs/aes128_core_dft_production_aware_plan_2026-04-13.md)

## Git 관리 기준

보통 Git에 직접 넣지 않는 항목:

- `SAED32_EDK/`
- `2_output/`
- `3_log/`
- `4_report/`
- tool-generated `work/`, `alib`

주로 Git에 남기는 항목:

- RTL
- constraint
- Tcl / csh script
- README / docs
