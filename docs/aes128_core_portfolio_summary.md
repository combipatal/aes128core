# aes128_core Portfolio Summary

이 문서는 `/DATA/home/edu135/aes128_core` 프로젝트를 포트폴리오 관점에서 한 번에 설명하기 위한 요약 문서다.

목적:

- 최종 baseline과 결과를 한 문서에서 정리
- 진행 중 실제로 부딪힌 문제와 수정 내역을 기술
- 포트폴리오 / 면접 / 발표 자료에 바로 옮길 수 있는 형태로 수행 내용을 정리

중요:

- 아래 내용은 **현재 저장소에 체크인된 산출물과 로그 기준**으로 작성했다.
- 최신 baseline은 `4_16_8ns_topo_ss`로 본다.

## 1. 프로젝트 개요

이 프로젝트는 AES128 기반 SoC 형태의 RTL을 시작으로, 기능 검증, 합성, Formality, DFT, STA, ATPG까지 이어지는 디지털 구현 흐름을 실제로 연결한 작업이다.

기준 top:

- `top_mcu_pll_sram_multiclk_soc`

포함 블록:

- AES128 core
- UART RX / TX
- SRAM wrapper + SRAM macro
- PLL block
- clock divider
- CDC logic
- clock gating logic

핵심 포인트:

- RTL만 작성한 것이 아니라
- RTL -> VCS -> synthesis -> r2n FM -> DFT -> n2n FM -> STA -> ATPG
- 흐름을 실제 산출물과 리포트까지 이어서 검증했다

## 2. 최종 baseline

현재 문서 기준으로 가장 중요한 버전은 아래다.

- `4_16_8ns_topo_ss`

이 baseline에서 확인되는 연결:

- synthesis
  - [soc_gate.v](../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.v)
  - [soc_gate.ddc](../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.ddc)
  - [soc_func.sdc](../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_func.sdc)
- r2n FM
  - [r2n_4_16_8ns_topo_ss.log](../3_FM/3_log/r2n_4_16_8ns_topo_ss.log)
- DFT
  - [aes_128_internal.v](../4_DFT/2_output/4_16_8ns_topo_ss/aes_128_internal.v)
  - [scan_internal.spf](../4_DFT/2_output/4_16_8ns_topo_ss/scan_internal.spf)
- n2n FM
  - [n2n_4_16_8ns_topo_ss.log](../5_FM/3_log/n2n_4_16_8ns_topo_ss.log)
- post-DFT STA
  - [4_16_8ns_topo_ss](../6_STA/4_report/4_16_8ns_topo_ss)
- ATPG
  - [4_16_8ns_topo_ss](../7_ATPG/4_report/4_16_8ns_topo_ss)

## 3. 최종 결과

### 3.1 VCS 기능 검증

현재 체크인된 summary 기준으로 3개 testcase가 모두 PASS다.

- `default_nist`
- `ext_zero`
- `ext_ecb_nist`

근거:

- [default_nist/summary.log](../1_vcs/4_report/default_nist/summary.log)
- [ext_zero/summary.log](../1_vcs/4_report/ext_zero/summary.log)
- [ext_ecb_nist/summary.log](../1_vcs/4_report/ext_ecb_nist/summary.log)

의미:

- UART 20바이트 출력
- `done=1`
- `pass=1`
- known-answer vector 기준 기능 검증 완료

### 3.2 synthesis 결과

[qor.rpt](../2_synthesis/4_report/4_16_8ns_topo_ss/qor.rpt) 기준 핵심 결과:

- Design WNS/TNS = `0 / 0`
- Hold WNS/TNS = `0 / 0`
- `clk_fast` critical slack = `0.63ns`
- `clk_fast_aes` critical slack = `0.00ns`
- max cap violations = `28`

해석:

- 합성 timing은 met
- 하지만 `clk_fast_aes`는 매우 빡빡한 경계 slack 상태
- synthesis는 usable baseline이지만, 여유가 넉넉한 구조는 아님

### 3.3 r2n FM 결과

[r2n_4_16_8ns_topo_ss.log](../3_FM/3_log/r2n_4_16_8ns_topo_ss.log) 기준으로 `Verification SUCCEEDED`

리포트 상태:

- unmatched 없음
- failing 없음
- aborted 없음
- unverified 없음
- `scan_out` 1개만 dont_verify

의미:

- RTL ↔ synthesis gate 기능 등가 유지

### 3.4 DFT 결과

[scan_config_internal.rpt](../4_DFT/4_report/4_16_8ns_topo_ss/scan_config_internal.rpt) 기준:

- chain count = `4`
- scan style = `Multiplexed flip-flop`
- lockup type = `latch`

[scan_chains_internal.rpt](../4_DFT/4_report/4_16_8ns_topo_ss/scan_chains_internal.rpt) 기준:

- `scan_in -> scan_out`
- `test_si2 -> test_so2`
- `test_si3 -> test_so3`
- `test_si4 -> test_so4`
- 각 chain length = `383`

[dft_qor_internal.rpt](../4_DFT/4_report/4_16_8ns_topo_ss/dft_qor_internal.rpt) 기준:

- Design WNS/TNS = `0 / 0`
- Hold WNS/TNS = `0 / 0`

의미:

- 현재 DFT는 4-chain internal scan 구조로 정상 삽입
- inserted netlist / DDC / SPF / SDF / DEF 생성
- DFT 이후 timing도 유지

### 3.5 n2n FM 결과

[n2n_4_16_8ns_topo_ss.log](../5_FM/3_log/n2n_4_16_8ns_topo_ss.log) 기준으로 `Verification SUCCEEDED`

리포트 상태:

- failing 없음
- aborted 없음
- unverified 없음
- `scan_out` 2개는 dont_verify
- `test_si2/3/4`, `test_so2/3/4` 6개는 implementation unmatched

의미:

- DFT-only test port 추가 때문에 structural unmatched는 남음
- functional logic equivalence 자체는 PASS

### 3.6 post-DFT STA 결과

현재 [6_STA](../6_STA/README.md) 기준 결과는 아래처럼 정리할 수 있다.

- `ff / ss / tt` 결과 존재
- `func / scan_capture / scan_shift` 모두 setup clean
- `func / scan_capture / scan_shift` 모두 hold clean
- post-DFT SDF까지 반영한 pre-layout STA 결과 존재

대표 근거:

- [func_pre_ss_qor.rpt](../6_STA/4_report/4_16_8ns_topo_ss/func/qor/func_pre_ss_qor.rpt)
- [func_pre_ss_hold.rpt](../6_STA/4_report/4_16_8ns_topo_ss/func/hold/func_pre_ss_hold.rpt)
- [scan_capture_pre_ss_hold.rpt](../6_STA/4_report/4_16_8ns_topo_ss/capture/hold/scan_capture_pre_ss_hold.rpt)
- [scan_shift_pre_ss_hold.rpt](../6_STA/4_report/4_16_8ns_topo_ss/shift/hold/scan_shift_pre_ss_hold.rpt)

추가 해석:

- `clk_fast_aes` setup slack은 여전히 매우 얇다
- `func analysis_coverage`는 낮아 보이지만, 이는 scan/reset 관련 arc를 의도적으로 timing 대상에서 제외한 영향이 크다

### 3.7 ATPG 결과

[top_mcu_pll_sram_multiclk_soc.faults.rpt](../7_ATPG/4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults.rpt) 기준 핵심 결과:

- total faults = `58765`
- detected = `58055`
- possibly detected = `3`
- undetectable = `521`
- ATPG untestable = `186`
- not detected = `0`
- test coverage = `99.68%`
- fault coverage = `98.79%`
- internal patterns = `215`

의미:

- ATPG가 실제로 완료됨
- `ND=0`
- 현재 baseline 기준으로는 충분히 높은 coverage 확보

## 4. 프로젝트에서 실제로 겪은 문제

### 문제 1. `clk_fast_aes` timing margin이 매우 얇았다

증상:

- synthesis와 STA에서 `clk_fast_aes` slack이 거의 0에 가까운 수준으로 나타남
- 같은 8ns baseline이어도 fast domain 경로가 매우 민감하게 보임

영향:

- 합성 결과는 clean처럼 보이더라도, 구현 여유가 충분하다고 보기 어려움
- 이후 DFT / STA / ATPG로 넘어갈 때도 계속 주의해야 하는 경로가 됨

최종 상태:

- 현재 baseline에서는 met
- 하지만 margin이 크지는 않음

### 문제 2. DFT 구조와 포트 intent가 바뀌면서 문서/해석이 stale해지기 쉬웠다

과거에는 single-chain 설명이 남아 있었지만, 현재 구조는 4-chain이다.

현재 실제 구조:

- `scan_in -> scan_out`
- `test_si2 -> test_so2`
- `test_si3 -> test_so3`
- `test_si4 -> test_so4`

영향:

- DFT README, 상위 README, FM 해석이 같이 바뀌어야 했음
- 특히 `5_FM`에서 unmatched port 해석 방식이 달라짐

### 문제 3. n2n FM에서 DFT-only 포트 때문에 unmatched가 생겼다

증상:

- implementation 쪽에만 `test_si2/3/4`, `test_so2/3/4`가 존재
- synthesis reference에는 이 포트들이 없음

영향:

- structural unmatched는 남지만, 기능 등가까지 실패한 것은 아님

최종 해석:

- `Verification SUCCEEDED`
- functional logic equivalence는 PASS
- test port unmatched는 DFT 구조 차이로 설명 가능

### 문제 4. `func` analysis coverage가 낮아 보여 오해하기 쉬웠다

증상:

- `func/analysis_coverage`에서 setup/hold가 `34% met`, `66% untested`
- recovery/removal은 `100% untested`

원인:

- `func` 시나리오에서 `scan_en=0`, `test_mode=0`
- `scan_in` false path
- `rst_n` false path
- scan flop의 `SI/SE` 관련 arc와 async reset 관련 check가 의도적으로 제외됨

최종 해석:

- coverage 숫자가 낮다고 해서 timing failure는 아님
- 실제 timing 품질은 QOR / setup / hold report를 같이 봐야 함

### 문제 5. DFT/STA/FM를 잇는 문서와 스크립트가 단계 개편을 따라가지 못했다

예:

- `0_rtl/README.md`가 실제로 없는 `aes128_core_rewrite.v`를 설명함
- `2.5_STA/README.md`가 예전 baseline과 단계 번호를 기준으로 작성됨
- `2.5_STA/run.csh`의 DFT 경로가 예전 `3_DFT` 경로를 가리킴
- 상위 README가 실제 체크인 로그보다 더 강한 톤으로 VCS/FM를 서술하고 있었음

영향:

- 프로젝트를 보는 사람이 현재 상태를 잘못 이해할 수 있음
- 포트폴리오용 문서로 쓰기 어려워짐

### 문제 6. STA에서 `PTE-015` SDF annotation 에러가 발생했다

증상:

- `read_sdf` 직후
- `cannot be annotated because of a timing assertion on hierarchical pin ... (PTE-015)`

대표 위치:

- `u_ctrl/u_icg_aes/gclk`
- `u_div8/clk_out`

원인:

- generated clock를 hierarchical pin에 직접 정의한 상태에서
- 같은 경계에 대해 SDF net delay를 annotate하려고 하면서 충돌이 발생

중요한 점:

- 이 문제는 `set_clock_uncertainty`를 다시 줘서 생긴 것이 아님
- `read_sdf` 시점에서 이미 발생하는 annotation 충돌 문제였음

영향:

- 일부 clock path interconnect delay가 제대로 annotate되지 않을 수 있음
- 특히 ICG / divided clock 경로 해석 품질에 좋지 않음

## 5. 문제를 어떻게 수정했는가

### 수정 1. README 체계를 현재 구조에 맞게 전면 정리

정리한 문서:

- [README.md](../README.md)
- [0_rtl/README.md](../0_rtl/README.md)
- [1_vcs/README.md](../1_vcs/README.md)
- [2_synthesis/README.md](../2_synthesis/README.md)
- [2.5_STA/README.md](../2.5_STA/README.md)
- [3_FM/README.md](../3_FM/README.md)
- [4_DFT/README.md](../4_DFT/README.md)
- [5_FM/README.md](../5_FM/README.md)
- [6_STA/README.md](../6_STA/README.md)
- [7_ATPG/README.md](../7_ATPG/README.md)

정리 내용:

- 현재 baseline을 `4_16_8ns_topo_ss` 기준으로 통일
- 예전 `3_DFT/4_STA` 번호 체계를 현재 `3_FM/4_DFT/5_FM/6_STA/7_ATPG` 구조로 수정
- 결과 표현을 “현재 체크인된 로그/리포트 기준”으로 톤 조정

### 수정 2. `2.5_STA/run.csh` 경로 오류 수정

수정 파일:

- [2.5_STA/run.csh](../2.5_STA/run.csh)

수정 전 문제:

- `net_source=dft`일 때 예전 `../3_DFT/...` 경로를 참조

수정 후:

- 현재 구조인 `../4_DFT/2_output/${ver}/aes_128_internal.v`를 참조하도록 수정

의미:

- 문서뿐 아니라 실제 비교용 스크립트도 현재 디렉터리 구조와 일치하게 만듦

### 수정 3. `func analysis coverage` 해석을 문서에 명시

수정 파일:

- [6_STA/README.md](../6_STA/README.md)

추가한 핵심 설명:

- 왜 `func` coverage가 낮아 보이는지
- scan/reset 관련 arc를 기능 모드에서 의도적으로 제외하고 있다는 점
- 그래서 coverage 숫자만으로 timing 품질을 판단하면 안 된다는 점

의미:

- STA 결과를 더 실무적으로 해석할 수 있게 됨

### 수정 4. `.omx` Git 추적 제거

수정 파일:

- [../.gitignore](../.gitignore)

조치:

- `.omx/`를 ignore 대상으로 명확화
- Git 인덱스에서 `.omx/tmux-hook.json` 제거

의미:

- 작업용 보조 상태 파일이 GitHub에 올라가는 문제를 정리

### 수정 5. `PTE-015`를 줄이기 위해 generated clock anchor를 leaf pin으로 변경

수정 파일:

- [6_STA/0_script/STA_script.tcl](../6_STA/0_script/STA_script.tcl)
- [2.5_STA/0_script/STA_script.tcl](../2.5_STA/0_script/STA_script.tcl)
- [6_STA/1_input/constraint/func_pre_sta.tcl](../6_STA/1_input/constraint/func_pre_sta.tcl)
- [2.5_STA/1_input/constraint/func_pre_sta.tcl](../2.5_STA/1_input/constraint/func_pre_sta.tcl)

수정 내용:

- hierarchical pin 기반 generated clock를 그대로 쓰지 않고
- 실제 구동 leaf pin 기준으로 치환하도록 변경

변경 기준:

- `u_ctrl/u_icg_aes/gclk`
  - → `u_ctrl/u_icg_aes/U4/Y`
- source `u_ctrl/u_icg_aes/clk`
  - → `u_ctrl/u_icg_aes/U4/A1`
- `u_div8/clk_out`
  - → `u_div8/clk_out_reg/Q`
- source `u_div8/clk_in`
  - → `u_div8/clk_out_reg/CLK`

의미:

- `read_sdf` 시 hierarchical pin timing assertion과 충돌하던 문제를 줄임
- STA에서 실제 leaf driver 기준으로 clock 해석을 더 안정화
- 문제를 단순 무시한 것이 아니라, clock anchor 정의 자체를 더 정확한 방향으로 정리

## 6. 이 프로젝트에서 내가 한 일

아래는 포트폴리오에 직접 적을 수 있도록 정리한 “수행 내용”이다.

### 수행 내용 요약

1. AES128 SoC RTL을 기준으로 VCS 기능 검증 환경을 구성하고 known-answer regression 3종을 통과시켰다.
2. Design Compiler 합성 스크립트와 baseline을 정리해 mapped gate / DDC / SDC / SVF가 재사용 가능한 형태로 나오도록 만들었다.
3. Formality r2n / n2n flow를 정리해 RTL ↔ synthesis, synthesis ↔ DFT 기능 등가를 확인했다.
4. DFT insertion 결과를 4-chain 구조 기준으로 정리하고, scan chain / DRC / QoR 해석을 문서화했다.
5. post-DFT STA에서 `func / scan_capture / scan_shift` 시나리오를 분리해 setup / hold를 검증했다.
6. ATPG flow를 정리해 STIL / WGL / fault report와 coverage 결과를 생성하고 해석했다.
7. 프로젝트 전반의 README와 스크립트를 최신 baseline 기준으로 정리해 포트폴리오용 설명 가능성을 높였다.

### 기술적으로 강조할 수 있는 포인트

- 멀티클록 SoC 형태의 RTL을 대상으로 합성 / DFT / STA / FM / ATPG까지 연결한 경험
- generated clock, custom ICG, macro black-box, test port unmatched 같은 실제 구현 이슈 해석 경험
- 단순 툴 실행이 아니라, 결과를 읽고 문서와 flow를 같이 유지하는 방식으로 정리한 경험

### 포트폴리오용 3줄 요약 예시

- AES128 기반 SoC RTL에 대해 VCS, synthesis, Formality, DFT, STA, ATPG를 연결한 end-to-end 디지털 구현 흐름을 구축했다.
- `4_16_8ns_topo_ss` baseline에서 합성 timing clean, r2n/n2n FM PASS, post-DFT STA clean, ATPG coverage `99.68%`를 확보했다.
- generated clock margin, DFT-only scan port unmatched, 낮아 보이는 func analysis coverage 같은 해석 이슈를 문서와 스크립트 수준에서 정리했다.

## 7. 최종적으로 남아 있는 리스크 / 한계

현재 baseline이 충분히 의미 있는 결과를 내고 있지만, 아래 항목은 여전히 남아 있다.

- `clk_fast_aes` slack 여유가 매우 작다
- synthesis / STA에서 max cap 성격의 QoR warning이 남아 있다
- DFT DRC에는 macro / clock observe / ICG 관련 warning이 남아 있다
- n2n FM에서는 DFT-only scan port unmatched 6개가 존재한다
- `func analysis coverage`는 test arc를 제외한 영향으로 낮게 보인다

즉 현재 프로젝트는 “흐름이 실제로 연결된 상태”로는 강하지만, 모든 항목이 signoff-grade로 완전히 닫힌 상태라고 보기는 어렵다.

## 8. 포트폴리오에서 어떻게 설명하면 좋은가

이 프로젝트를 포트폴리오에서 설명할 때는 아래 흐름이 가장 자연스럽다.

1. AES128 SoC RTL을 작성 / 유지했다
2. VCS regression으로 기능 검증을 했다
3. 합성 결과를 baseline으로 만들고 FM으로 기능 등가를 확인했다
4. DFT insertion과 scan chain 구성을 실제로 만들었다
5. post-DFT STA와 ATPG까지 연결해 구현 흐름을 완성했다
6. 중간에 발생한 generated clock, test port, coverage 해석 문제까지 문서와 스크립트로 정리했다

즉 이 프로젝트의 강점은:

- 개별 툴 사용 경험이 아니라
- 여러 툴과 산출물을 하나의 구현 흐름으로 연결한 경험

에 있다.

## 9. 같이 보면 좋은 문서

- 상위 개요: [README.md](../README.md)
- RTL: [0_rtl/README.md](../0_rtl/README.md)
- VCS: [1_vcs/README.md](../1_vcs/README.md)
- synthesis: [2_synthesis/README.md](../2_synthesis/README.md)
- 실험용 STA: [2.5_STA/README.md](../2.5_STA/README.md)
- r2n FM: [3_FM/README.md](../3_FM/README.md)
- DFT: [4_DFT/README.md](../4_DFT/README.md)
- n2n FM: [5_FM/README.md](../5_FM/README.md)
- post-DFT STA: [6_STA/README.md](../6_STA/README.md)
- ATPG: [7_ATPG/README.md](../7_ATPG/README.md)
