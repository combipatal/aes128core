# STA Issue Summary

## Scope

이 문서는 `aes128_core/4_STA` bring-up 과정에서 실제로 발생한 주요 문제, 원인, 수정 방향, 적용 결과를 정리한다.

기준 버전:
- Functional baseline 비교: `4_11_6_7ns`, `4_11_7p3ns`
- Coverage 정리 기준: `4_12_7p3ns`

현재 리포트 구조:
- `4_STA/4_report/<ver>/func/...`
- `4_STA/4_report/<ver>/capture/...`
- `4_STA/4_report/<ver>/shift/...`

## 1. 초기 PrimeTime bring-up 문제

### Problem

초기 STA bring-up 단계에서 PrimeTime batch run이 정상 종료되지 않고 interactive prompt에 머무르는 문제가 있었다.

또한 초기에 DFT netlist link가 불완전해서 STA 자체가 성립하지 않는 상태가 있었다.

### Root Cause

1. PT script에 `report_area`가 들어 있었고, 해당 환경에서 명령이 맞지 않아 `CMD-005`를 유발했다.
2. DFT netlist 안에 `GTECH_NOT`가 남아 있었는데, PT link path에 `gtech.db`가 없어서 unresolved reference가 발생했다.

### Fix Direction

- `4_STA/0_script/STA_script.tcl`
  - `report_area` 제거
  - 마지막에 `exit` 추가
  - `gtech.db` link 추가 유지

### Result

현재 PT는 batch로 종료되며 prompt에 머무르지 않는다.

현재 관련 구현 위치:
- `4_STA/0_script/STA_script.tcl:47-49`
- `4_STA/0_script/STA_script.tcl:131`

## 2. DC-PT Correlation 문제 (Load / Wire Load Model 문제)

### Problem

합성/DC와 DFT/DC에서는 functional setup이 clean하게 보였는데, PT functional STA에서는 `clk_fast_aes` 경로에 setup violation이 나타났다.

예:
- `4_STA/4_report/4_11_6_7ns/pre_ss0p95v125c_setup.rpt:16-73`
- worst slack: `-0.0054ns`

### Root Cause

이 문제의 핵심은 RTL 기능 문제가 아니라 **pre-layout timing correlation 문제**였다.

DC는 hierarchy별 wire load model을 사용하고 있었는데, PT는 처음에 그 값을 그대로 재현하지 못해서 AES 경로를 더 비관적으로 계산했다.

DC timing report 기준으로 확인된 hierarchy별 wire load model:
- top: `ForQA`
- `u_ctrl` (`soc_ctrl_multiclk_soc`): `70000`
- `u_ctrl/u_aes` (`aes128_core`): `35000`

즉, 같은 netlist라도:
- DC는 hierarchy별 WLM 반영
- PT는 초기에는 기본 상태로 계산

그 결과 `clk_fast_aes` setup이 PT에서만 음수로 보였다.

### Fix Direction

PT script에 DC와 맞는 wire load correlation 설정을 추가했다.

적용 위치:
- `4_STA/0_script/STA_script.tcl:100-104`

적용 내용:

```tcl
set auto_wire_load_selection false
set_wire_load_mode enclosed
set_wire_load_model -name ForQA [current_design]
set_wire_load_model -name 70000 [get_cells u_ctrl]
set_wire_load_model -name 35000 [get_cells u_ctrl/u_aes]
```

### Result

7.0ns 기준:
- `4_STA/4_report/4_11_6_7ns/pre_ss0p95v125c_setup.rpt:73`
- slack `-0.0054ns`

7.3ns 기준:
- `4_STA/4_report/4_11_7p3ns/pre_ss0p95v125c_setup.rpt:15`
- `No paths with slack less than 0.0000.`

현재 functional PT summary:
- `4_STA/4_report/4_12_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt:62-68`
- `clk_fast_aes` setup slack `0.0003ns`

### Status

- 적용 완료
- main project 반영 완료

## 3. Functional Setup Closure 기준 정리

### Problem

`7.0ns`에서는 correlation fix 이후에도 아주 작은 residual negative slack가 남았다.

### Decision

스크립트 정합성과 flow 검증을 우선하는 현재 단계에서는, 과도한 cell-level optimization보다 `7.3ns`를 functional validation baseline으로 사용하는 것이 적절하다고 판단했다.

### Result

현재 functional setup clean 기준 버전:
- `4_11_7p3ns`
- `4_12_7p3ns`

대표 리포트:
- `4_STA/4_report/4_12_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt:62-68`

## 4. Coverage 해석 문제: Functional과 Scan을 섞어 보면 의미가 흐려짐

### Problem

초기에는 `func` 하나만 보고 coverage를 판단했기 때문에 `Untested` 비율이 너무 커 보였고, 그 원인이 scan arc인지 reset arc인지 구분이 어려웠다.

대표 예:
- functional report에서 setup/hold untested가 매우 큼
- recovery/removal이 100% untested

### Root Cause

1. `func`에서는 `scan_en=0`, `test_mode=0`이라 scan flop의 `SI/SE` 관련 timing arc가 의도적으로 비활성된다.
2. reset 관련 clock-relative timing이 없으면 recovery/removal은 전부 untested로 남는다.

### Fix Direction

STA를 scenario별로 분리했다.

현재 scenario:
- `func`
- `capture` (`scan_capture`)
- `shift` (`scan_shift`)

관련 구현 위치:
- `4_STA/run.csh`
- `4_STA/0_script/STA_script.tcl:56-65`
- `4_STA/1_input/constraint/*.tcl`

### Result

이제 coverage는 scenario별로 분리해서 해석할 수 있다.

현재 폴더 구조:

```text
4_STA/4_report/4_12_7p3ns/
  func/
  capture/
  shift/
```

## 5. scan_capture coverage 문제

### Problem

초기 `scan_capture`에서는 recovery/removal이 여전히 100% untested였고, `no_input_delay` warning도 남아 있었다.

기존 상태 예:
- `4_STA/4_report/4_12_7p3ns/capture/analysis_coverage/scan_capture_pre_ss0p95v125c_analysis_coverage.rpt`
  - 현재는 개선 후 덮어써졌지만, 초기에는 recovery/removal이 `1532 untested`

### Root Cause

`rst_n`, `scan_in`, `scan_out`가 capture scenario에서 clock-relative I/O timing으로 정의되지 않았다.

### Fix Direction

`scan_capture_sta.tcl`에 아래 timing 제약을 추가했다.

적용 위치:
- `4_STA/1_input/constraint/scan_capture_sta.tcl:4-9`

```tcl
set_input_delay -clock ref_clk -max 1.0 [get_ports rst_n]
set_input_delay -clock ref_clk -min 0.2 [get_ports rst_n]
set_input_delay -clock ref_clk -max 1.0 [get_ports scan_in]
set_input_delay -clock ref_clk -min 0.2 [get_ports scan_in]
set_output_delay -clock ref_clk -max 1.0 [get_ports scan_out]
set_output_delay -clock ref_clk -min 0.2 [get_ports scan_out]
```

### Result

현재 개선 결과:
- `4_STA/4_report/4_12_7p3ns/capture/analysis_coverage/scan_capture_pre_ss0p95v125c_analysis_coverage.rpt:10-20`
  - recovery `1532 met / 0 untested`
  - removal `1532 met / 0 untested`
  - 전체 `55% met / 45% untested`

- `4_STA/4_report/4_12_7p3ns/capture/check_timing/scan_capture_pre_ss0p95v125c_check_timing.rpt:1-16`
  - `no_input_delay` warning 없음

### Status

- 적용 완료
- main project 반영 완료

## 6. scan_shift coverage 문제

### Problem

`scan_shift`도 functional과 분리해야 했지만, 단순히 `scan_en/test_mode`만 바꾸는 수준으로는 coverage 숫자가 거의 바뀌지 않았다.

### Root Cause

functional arc와 scan arc가 단지 서로 교대로 비활성될 뿐, scan-specific clocking과 I/O timing intent가 충분히 분리되지 않았다.

### Worktree Trial

worktree에서 아래 방향을 시험했다.

- 기존 functional/generated clock 제거
- 단일 `scan_shift_clk` 생성
- `scan_in/scan_out` I/O delay 부여
- non-scan input false path 추가

### Trial Result

효과:
- `scan_shift`가 단일 scan clock scenario로 해석됨
- no_clock 문제 없음

한계:
- 전체 coverage met 비율은 크게 늘지 않음
- 아직 input delay warning 1개, unconstrained endpoint 3개가 남음

즉, `scan_shift`는 방향은 맞지만 추가 정리가 더 필요하다.

### Status

- main project에는 아직 full 반영하지 않음
- worktree에서만 검증

## 7. 현재 남은 이슈

### Hold Violation

functional / capture 기준으로 SRAM 인터페이스 hold violation 12개가 남아 있다.

예:
- `4_STA/4_report/4_12_7p3ns/capture/analysis_coverage/scan_capture_pre_ss0p95v125c_analysis_coverage.rpt:10-20`
  - hold violated `12`

이 이슈는 현재 단계에서는 의도적으로 후순위로 두었다.

### scan_shift Refinement

worktree 검증 기준으로 아래가 남아 있다.
- input delay warning 1개
- unconstrained endpoint 3개

이 항목까지 정리되면 `shift`도 main project에 강화본을 반영하는 것이 적절하다.

## 8. Current Recommended Baseline

현재 STA/coverage 검증 기준으로 가장 안정적인 조합은 아래와 같다.

- timing baseline: `4_12_7p3ns`
- functional setup 확인: `func`
- reset/test coverage 확인: `capture`
- scan shift는 추가 refinement 후 반영

대표 확인 리포트:
- functional setup
  - `4_STA/4_report/4_12_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt`
- capture coverage
  - `4_STA/4_report/4_12_7p3ns/capture/analysis_coverage/scan_capture_pre_ss0p95v125c_analysis_coverage.rpt`
- capture check_timing
  - `4_STA/4_report/4_12_7p3ns/capture/check_timing/scan_capture_pre_ss0p95v125c_check_timing.rpt`
