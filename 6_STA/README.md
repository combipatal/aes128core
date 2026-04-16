# 6_STA

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`의 post-DFT pre-layout STA 워크스페이스입니다.

현재 목적:

- `4_DFT` 결과를 기준으로 기능 / scan capture / scan shift timing 확인
- synthesis SDC를 최대한 재사용하되 scenario별 override를 적용
- ATPG 전에 post-DFT netlist가 timing 관점에서 문제 없는지 점검

## 전체 흐름에서의 위치

1. `2_synthesis`
   - mapped gate / SDC 생성
2. `4_DFT`
   - scan insertion
3. `5_FM`
   - synthesis ↔ DFT formal check
4. `6_STA`
   - post-DFT timing 검증
5. `7_ATPG`
   - ATPG

즉 `6_STA`는 현재 프로젝트에서 ATPG 직전 timing 확인 단계입니다.

## 현재 실행 인터페이스

현재 [run.csh](run.csh)는 예전 `net_ver/sdc_ver` 방식이 아니라 아래 환경변수를 직접 받습니다.

- `ver`
- `corner`
- `mode`
- `sta_scenario`
- `design_name`
- `net`
- `sdc`
- `sdf_delay`

기본값:

- `ver=4_16_8ns_topo_ss`
- `corner=ff`
- `mode=pre`
- `sta_scenario=scan_capture`
- `design_name=top_mcu_pll_sram_multiclk_soc`
- `net=../4_DFT/2_output/${ver}/aes_128_internal.v`
- `sdc=../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`
- `sdf_delay=../4_DFT/2_output/${ver}/aes_128_internal.sdf`

즉 현재 README는 이 인터페이스 기준으로 읽어야 맞습니다.

## 주요 파일

- [run.csh](run.csh)
  - PrimeTime wrapper
- [0_script/STA_script.tcl](0_script/STA_script.tcl)
  - 메인 STA 스크립트
- [0_script/STA_opt.tcl](0_script/STA_opt.tcl)
  - PrimeTime 옵션
- scenario override
  - [1_input/constraint/func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)
  - [1_input/constraint/scan_capture_sta.tcl](1_input/constraint/scan_capture_sta.tcl)
  - [1_input/constraint/scan_shift_sta.tcl](1_input/constraint/scan_shift_sta.tcl)

## 실행 방법

기본 실행:

```bash
cd /DATA/home/edu135/aes128_core/6_STA
csh run.csh
```

대표 실행 예시:

```bash
env ver=4_16_8ns_topo_ss corner=ss sta_scenario=func csh run.csh
env ver=4_16_8ns_topo_ss corner=ss sta_scenario=scan_capture csh run.csh
env ver=4_16_8ns_topo_ss corner=ss sta_scenario=scan_shift csh run.csh
```

## 현재 스크립트 동작 요약

현재 [STA_script.tcl](0_script/STA_script.tcl)은 아래 순서로 동작합니다.

1. 환경변수에서 netlist / SDC / SDF / scenario를 읽음
2. corner별 RVT / LVT / HVT / IO / PLL / SRAM db를 로드
3. netlist를 읽고 link
4. 입력 SDC에서 wire-load 관련 줄만 제거한 sanitized SDC 생성
5. scenario override Tcl 적용
6. post-DFT SDF를 `read_sdf -type sdf_max`로 annotate
7. clock uncertainty를 다시 지정
8. `check_timing`, `report_timing`, `report_qor` 등 리포트 생성

즉 현재 STA는 post-DFT gate + post-DFT SDF 기준입니다.

## 현재 기준 버전

현재 가장 최신이고 README 기준으로 가장 먼저 봐야 하는 버전은 아래입니다.

- `4_16_8ns_topo_ss`

현재 이 버전은 `ff / ss / tt`와 `func / capture / shift` 결과가 모두 존재합니다.

## 현재 결과 요약

현재 `4_16_8ns_topo_ss` 기준으로 보면 timing은 전반적으로 clean합니다.

대표 확인 포인트:

- [func_pre_ss_setup.rpt](4_report/4_16_8ns_topo_ss/func/setup/func_pre_ss_setup.rpt)
  - violated path 없음
- [func_pre_ss_hold.rpt](4_report/4_16_8ns_topo_ss/func/hold/func_pre_ss_hold.rpt)
  - violated path 없음
- [scan_capture_pre_ss_setup.rpt](4_report/4_16_8ns_topo_ss/capture/setup/scan_capture_pre_ss_setup.rpt)
  - violated path 없음
- [scan_capture_pre_ss_hold.rpt](4_report/4_16_8ns_topo_ss/capture/hold/scan_capture_pre_ss_hold.rpt)
  - violated path 없음
- [scan_shift_pre_ss_setup.rpt](4_report/4_16_8ns_topo_ss/shift/setup/scan_shift_pre_ss_setup.rpt)
  - violated path 없음
- [scan_shift_pre_ss_hold.rpt](4_report/4_16_8ns_topo_ss/shift/hold/scan_shift_pre_ss_hold.rpt)
  - violated path 없음

추가로 `ff / ss / tt` 전체 report tree를 보면 각 scenario의 setup / hold report가 모두 `No paths with slack less than 0.0000.`로 끝납니다.

즉 현재 `6_STA`의 핵심 판단은:

- func clean
- scan_capture clean
- scan_shift clean

## 현재 QoR 관찰 포인트

[func_pre_ss_qor.rpt](4_report/4_16_8ns_topo_ss/func/qor/func_pre_ss_qor.rpt) 기준 대표 수치는 아래입니다.

- `clk_fast_aes` setup slack: `0.0100`
- 모든 path group에서 `No. of Violating Paths: 0`

즉 post-DFT STA에서도 `clk_fast_aes`는 여유가 매우 작지만 현재는 met 상태입니다.

## 현재 남아 있는 warning

현재 timing violation은 없지만, `check_timing` warning은 남아 있습니다.

대표 예:

- [func_pre_ss_check_timing.rpt](4_report/4_16_8ns_topo_ss/func/check_timing/func_pre_ss_check_timing.rpt)
  - `no_input_delay` 1개
  - unconstrained endpoint 3개
- [scan_capture_pre_ss_check_timing.rpt](4_report/4_16_8ns_topo_ss/capture/check_timing/scan_capture_pre_ss_check_timing.rpt)
  - `no_input_delay` 1개
  - unconstrained endpoint 3개
- [scan_shift_pre_ss_check_timing.rpt](4_report/4_16_8ns_topo_ss/shift/check_timing/scan_shift_pre_ss_check_timing.rpt)
  - `no_input_delay` 4개
  - unconstrained endpoint 3개

해석:

- 지금 남은 것은 constraint completeness warning입니다.
- 현재 setup / hold violation처럼 즉시 막히는 문제는 아닙니다.
- 다음 문서 정리나 constraint refinement 때 우선순위를 줄 수 있는 항목입니다.

## 실제로 겪은 문제: `PTE-015` SDF annotation 에러

STA를 진행하면서 아래 형태의 `PTE-015` 에러가 발생한 적이 있습니다.

- `u_ctrl/u_icg_aes/gclk`
- `u_div8/clk_out`

대표 증상:

- `read_sdf` 직후
- `cannot be annotated because of a timing assertion on hierarchical pin ... (PTE-015)`

현재 해석:

- 이 에러는 `set_clock_uncertainty`를 다시 줘서 생긴 것이 아닙니다.
- 실제 원인은 generated clock를 hierarchical pin에 걸어 둔 상태에서 SDF net delay를 annotate하려고 했기 때문입니다.
- 즉 SDF 문제라기보다, clock anchor 위치가 hierarchical pin이라서 annotation과 충돌한 경우입니다.

수정 방법:

- generated clock anchor를 hierarchical pin에서 leaf pin으로 옮겼습니다.

변경한 기준:

- `u_ctrl/u_icg_aes/gclk`
  - → `u_ctrl/u_icg_aes/U4/Y`
- source `u_ctrl/u_icg_aes/clk`
  - → `u_ctrl/u_icg_aes/U4/A1`
- `u_div8/clk_out`
  - → `u_div8/clk_out_reg/Q`
- source `u_div8/clk_in`
  - → `u_div8/clk_out_reg/CLK`

적용 위치:

- [0_script/STA_script.tcl](0_script/STA_script.tcl)
  - sanitized SDC 생성 단계에서 generated clock 정의를 leaf pin 기준으로 치환
- [1_input/constraint/func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)
  - `clk_fast_aes` fallback 생성도 leaf pin 우선으로 변경

의미:

- `read_sdf` 시 hierarchical pin timing assertion과 충돌하던 문제를 줄임
- clock tree 해석을 실제 구동 leaf pin 기준으로 더 명확하게 만듦

즉 현재 STA 스크립트는:

- hierarchical pin 기반 generated clock를 그대로 쓰지 않고
- leaf pin anchor를 우선 사용하도록 수정된 상태입니다.

## 왜 `func` analysis coverage가 낮게 보이는가

현재 [func_pre_ss_analysis_coverage.rpt](4_report/4_16_8ns_topo_ss/func/analysis_coverage/func_pre_ss_analysis_coverage.rpt)를 보면 아래처럼 보입니다.

- setup: `34% met`, `66% untested`
- hold: `34% met`, `66% untested`
- recovery / removal: `100% untested`

이 숫자만 보면 기능 STA가 많이 비어 보이지만, 현재 해석은 “timing이 나빠서”가 아니라 “func 모드에서 test-only check를 의도적으로 끈 상태”에 가깝습니다.

주된 이유는 [func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)에 들어 있는 아래 설정입니다.

- `scan_en=0`
- `test_mode=0`
- `scan_in`에서 오는 경로 `false_path`
- `rst_n`에서 오는 경로 `false_path`

이 설정 때문에 현재 `func`에서는 아래 항목들이 timing 대상에서 빠집니다.

- scan flop의 `SI`, `SE` 관련 setup / hold arc
- async reset 관련 recovery / removal check
- 일부 test-only 경로

실제 [func_pre_ss_disable_timing.rpt](4_report/4_16_8ns_topo_ss/func/disable_timing/func_pre_ss_disable_timing.rpt)를 보면 많은 scan flop에서 `CLK -> SI`, `CLK -> SE` arc가 `SE = 0` 조건 때문에 비활성화되어 있습니다.

즉 현재 `func` analysis coverage가 낮은 이유는 대부분 아래 두 가지입니다.

1. scan 경로를 기능 모드에서 의도적으로 비활성화했기 때문
2. reset 경로를 false path 처리해서 recovery / removal을 보지 않기 때문

보조 원인으로는 [func_pre_ss_check_timing.rpt](4_report/4_16_8ns_topo_ss/func/check_timing/func_pre_ss_check_timing.rpt)에 남아 있는 아래 경고도 있습니다.

- `no_input_delay` 1개
- unconstrained endpoint 3개

다만 이 둘은 coverage를 조금 깎는 부수 요인이고, 현재 `66% untested`의 주된 원인은 아닙니다.

중요한 판단:

- `func` coverage가 낮다고 해서 timing failure로 해석하면 안 됩니다.
- 실제 QOR는 [func_pre_ss_qor.rpt](4_report/4_16_8ns_topo_ss/func/qor/func_pre_ss_qor.rpt) 기준으로 모든 path group이 `No. of Violating Paths: 0`입니다.
- scan 관련 timing의 핵심 판단은 `func`보다 `scan_capture`, `scan_shift` 결과를 같이 보는 것이 맞습니다.

## 현재 판단

현재 `6_STA`는 아래처럼 정리할 수 있습니다.

- 기본 baseline은 `4_16_8ns_topo_ss`
- 현재 스크립트 인터페이스는 `net/sdc/sdf_delay` 직접 지정 방식
- post-DFT SDF까지 반영한 pre-layout STA 결과가 존재
- `ff / ss / tt`와 `func / capture / shift` 모두 timing clean
- 다만 `check_timing` warning은 일부 남아 있음

즉 지금 단계에서는:

- STA 기준으로 ATPG 진행은 가능
- 남은 일은 timing fix가 아니라 constraint 문서화 / 정리 쪽에 더 가깝습니다

## 같이 보면 좋은 README

- synthesis: [../2_synthesis/README.md](../2_synthesis/README.md)
- DFT: [../4_DFT/README.md](../4_DFT/README.md)
- n2n FM: [../5_FM/README.md](../5_FM/README.md)
- ATPG: [../7_ATPG/README.md](../7_ATPG/README.md)
