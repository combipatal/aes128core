# 4_STA

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`의 pre-layout STA를 수행하는 워크스페이스입니다. 현재 목적은 `3_DFT`까지 끝난 post-DFT netlist를 기준으로, ATPG 전에 기능/캡처/시프트 timing이 괜찮은지 확인하는 것입니다.

## 전체 흐름에서의 위치

이 프로젝트의 관련 순서는 아래처럼 보면 됩니다.

1. `2_synthesis`
   - 합성 수행
   - `soc_gate.ddc`, `soc_gate.v`, `soc_func.sdc` 생성
2. `2.5_STA`
   - versioned synth/DFT netlist 비교용 PrimeTime 워크스페이스
   - SS/FF/TT 비교와 실험용 STA를 분리해서 보기 좋게 만든 공간
3. `3_DFT`
   - single scan chain insertion
   - `aes_128_internal.v`, `aes_128_internal.ddc`, `scan_internal.spf`, `scan.def` 생성
4. `4_STA`
   - post-DFT netlist 기준 최종 pre-layout STA 확인
   - `func`, `scan_capture`, `scan_shift`를 나눠서 해석

즉 `4_STA`는 `합성 결과 + DFT 결과`가 실제로 timing 관점에서 괜찮은지 점검하는 자리입니다.

## 입력과 출력

기본 입력은 아래 두 개입니다.

- netlist: `../3_DFT/2_output/<net_ver>/aes_128_internal.v`
- SDC: `../2_synthesis/2_output/<sdc_ver>/mapped/soc_func.sdc`

중요한 점:
- `net_ver`와 `sdc_ver`는 다를 수 있습니다.
- ECO로 post-DFT netlist만 새 버전이 생기면,
  - `net_ver = ECO 버전`
  - `sdc_ver = 원래 synthesis 버전`
  으로 두면 됩니다.

출력은 아래에 저장됩니다.

- 로그: `3_log/${ver}_${sta_scenario}_${mode}_${corner}_sta.log`
- 리포트: `4_report/${ver}/func/...`, `capture/...`, `shift/...`

## 실행 방법

현재 [run.csh](run.csh)는 `ver`, `net_ver`, `sdc_ver`를 따로 받을 수 있습니다.

기본 실행 예시:

```bash
cd ./4_STA
env ver=4_15_8ns_ff_holdfix_tcl6 \
    net_ver=4_15_8ns_ff_holdfix_tcl6 \
    sdc_ver=4_15_8ns_ff \
    corner=ss \
    sta_scenario=func \
    csh run.csh
```

세 scenario는 아래처럼 봅니다.

- `func`
  - `scan_en=0`, `test_mode=0`
  - 기능 경로 setup/hold 확인용
- `scan_capture`
  - `scan_en=0`, `test_mode=1`
  - capture timing과 recovery/removal 확인용
- `scan_shift`
  - `scan_en=1`, `test_mode=1`
  - shift 경로 timing 확인용

## 현재 스크립트 구조

- [run.csh](run.csh)
  - `net_ver`와 `sdc_ver`를 분리해서 입력 받을 수 있도록 수정됨
  - netlist/SDC가 없으면 바로 종료
- [STA_script.tcl](0_script/STA_script.tcl)
  - `ss`, `ff`, `tt` short corner 지원
  - synthesis SDC에서 wire-load 명령을 제거한 `sanitized SDC`를 만든 뒤 읽음
  - top-level `ForQA` wire-load만 적용
- scenario override
  - [func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)
  - [scan_capture_sta.tcl](1_input/constraint/scan_capture_sta.tcl)
  - [scan_shift_sta.tcl](1_input/constraint/scan_shift_sta.tcl)

## 실제로 겪은 문제와 수정 방법

### 1. SDC / STA bring-up 문제

처음에는 `read_sdc` 이후 warning이 많고, corner를 바꾸면 wire-load 관련 혼선이 있었습니다.

수정:
- `STA_script.tcl`에서 synthesis가 쓴 SDC를 그대로 읽지 않고,
  `set_wire_load_mode`, `set_wire_load_model` 줄을 제거한 `soc_func.sdc.sanitized`를 만들어 읽도록 변경했습니다.

의미:
- synthesis corner와 STA corner를 분리해서 보기 쉬워졌습니다.
- `2.5_STA`에서 정리한 방식과 맞췄습니다.

### 2. scenario별 coverage 해석 문제

처음에는 `func`만 보고 coverage가 낮다고 판단하기 쉬웠습니다.

수정:
- `func`, `scan_capture`, `scan_shift`를 분리해서 보도록 유지
- `scan_capture`에서는 `rst_n`, `scan_in`, `scan_out` timing을 별도 정의
- `scan_shift`에서는 `scan_in/scan_out`만 timing 대상으로 보고 나머지 기능 입력은 false path 처리

의미:
- `func` coverage가 낮아도 그건 기능 모드 특성상 자연스러운 현상으로 해석할 수 있습니다.
- ATPG 전에는 `scan_capture` 결과가 더 중요합니다.

### 3. post-DFT SRAM hold violation 12개

문제:
- `u_mem_u_sram/A[*]`, `u_mem_u_sram/I[*]` 쪽에 아주 작은 hold violation 12개가 있었습니다.
- 주로 `u_ctrl -> SRAM macro input` short path 문제였습니다.

수정:
- `3_DFT`에서 post-DFT netlist용 Tcl ECO 스크립트를 만들었습니다.
- 관련 파일:
  - [post_dft_hold_eco.tcl](../3_DFT/0_script/post_dft_hold_eco.tcl)
  - [run_hold_eco.csh](../3_DFT/run_hold_eco.csh)
- 이 스크립트는 원본 netlist를 손으로 수정하지 않고, 새 버전 디렉터리에 ECO netlist를 생성합니다.
- 현재 사용한 ECO 결과 버전:
  - [aes_128_internal.v](../3_DFT/2_output/4_15_8ns_ff_holdfix_tcl6/aes_128_internal.v)

ECO 내용:
- `mem_addr[3:0]` 앞에 inverter pair 추가
- `mem_wdata[7:0]` 앞에 inverter pair 추가

의미:
- SRAM macro 입력 직전 데이터 경로를 조금 늦춰서 hold를 해결
- 기능은 바꾸지 않음

## 현재 최종 결과

현재 `4_STA`에서 가장 의미 있게 봐야 하는 결과는
`4_15_8ns_ff_holdfix_tcl6`입니다.

### Functional

- setup clean
- hold clean
- `clk_fast_aes` setup slack: `0.4740ns`
- 참고:
  - [func_pre_ss_setup.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/func/setup/func_pre_ss_setup.rpt)
  - [func_pre_ss_hold.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/func/hold/func_pre_ss_hold.rpt)
  - [func_pre_ss_qor.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/func/qor/func_pre_ss_qor.rpt)

### Scan Capture

- setup clean
- hold clean
- recovery/removal `1108/1108 met`
- 참고:
  - [scan_capture_pre_ss_check_timing.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/capture/check_timing/scan_capture_pre_ss_check_timing.rpt)
  - [scan_capture_pre_ss_hold.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/capture/hold/scan_capture_pre_ss_hold.rpt)
  - [scan_capture_pre_ss_analysis_coverage.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/capture/analysis_coverage/scan_capture_pre_ss_analysis_coverage.rpt)

### Scan Shift

- setup clean
- hold clean
- coverage 숫자는 낮지만, scenario 목적상 바로 문제로 보지는 않음
- 참고:
  - [scan_shift_pre_ss_check_timing.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/shift/check_timing/scan_shift_pre_ss_check_timing.rpt)
  - [scan_shift_pre_ss_hold.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/shift/hold/scan_shift_pre_ss_hold.rpt)
  - [scan_shift_pre_ss_qor.rpt](4_report/4_15_8ns_ff_holdfix_tcl6/shift/qor/scan_shift_pre_ss_qor.rpt)

## 아직 남아 있는 것

- `func`에서 `no_input_delay` warning 1개
- `scan_shift`에서 `no_input_delay` warning 1개

이 두 개는 현재 hold violation처럼 치명적인 문제는 아니고, 다음 단계에서 정리할 수 있는 warning입니다.

즉 현재 판단은:
- post-DFT hold ECO는 성공
- 기능/캡처/시프트 timing은 모두 clean
- ATPG 전 STA 기준으로는 많이 정리된 상태

## 디버깅할 때 먼저 볼 파일

기억이 안 나거나, 왜 이런 결과가 나왔는지 다시 확인해야 할 때는 아래 순서대로 보면 됩니다.

1. `4_STA/STA_ISSUES_SUMMARY.md`
   - bring-up 때 실제로 어떤 문제를 겪었는지 정리돼 있음
2. `4_report/<ver>/<scenario>/check_timing/*.rpt`
   - unconstrained, no_input_delay, generated clock warning 확인
3. `4_report/<ver>/<scenario>/qor/*.rpt`
   - scenario별 setup/hold worst summary 확인
4. `4_report/<ver>/<scenario>/analysis_coverage/*.rpt`
   - coverage를 scenario 목적에 맞게 해석
5. `3_DFT/0_script/post_dft_hold_eco.tcl`
   - SRAM hold ECO가 실제로 어떻게 들어갔는지 확인

## 같이 보면 좋은 다른 README

- 합성: [2_synthesis/README.md](../2_synthesis/README.md)
- 실험용 STA: [2.5_STA/README.md](../2.5_STA/README.md)
- DFT: [3_DFT/README.md](../3_DFT/README.md)
