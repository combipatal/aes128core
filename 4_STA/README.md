# 4_STA

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`에 대해 pre-layout STA를 수행하는 폴더입니다.

## 목적

- `3_DFT`의 netlist와 `2_synthesis`의 SDC를 입력으로 사용
- PrimeTime으로 functional / scan scenario별 timing 분석 수행
- setup / hold / coverage / disable timing / clock 관련 리포트 생성
- DC와 PT 간 pre-layout correlation을 맞추기 위한 wire load model 반영

## 디렉터리 구성

- `0_script/`
  - `STA_script.tcl`: 메인 PrimeTime 스크립트
  - `STA_opt.tcl`: PT 옵션 설정
- `1_input/constraint/`
  - `func_pre_sta.tcl`: functional scenario override
  - `scan_shift_sta.tcl`: scan shift scenario override
  - `scan_capture_sta.tcl`: scan capture scenario override
- `3_log/`
  - 버전/시나리오별 PT 실행 로그
- `4_report/`
  - 버전별 STA 리포트
- `STA_ISSUES_SUMMARY.md`
  - bring-up 중 발생한 STA 문제, 원인, 수정 방향, 결과 정리 문서
- `run.csh`
  - STA 실행 스크립트

## 입력 / 출력 관계

### 입력

- DFT netlist:
  - `../3_DFT/2_output/$ver/aes_128_internal.v`
- synthesis SDC:
  - `../2_synthesis/2_output/$ver/mapped/soc_func.sdc`

### 출력

- 로그:
  - `3_log/${ver}_${sta_scenario}_${mode}_${corner}_sta.log`
- 리포트:
  - `4_report/$ver/<scenario>/...`

## 실행 방법

기본 실행 스크립트:

```csh
#!/bin/csh -f

if ( ! $?ver ) setenv ver 4_12_7p3ns
setenv corner ss0p95v125c
setenv mode pre
if ( ! $?sta_scenario ) setenv sta_scenario func
setenv run_mode pre
setenv hier_mode top
setenv design_name top_mcu_pll_sram_multiclk_soc
setenv net ../3_DFT/2_output/${ver}/aes_128_internal.v
setenv sdc ../2_synthesis/2_output/${ver}/mapped/soc_func.sdc
```

### Functional

```bash
env ver=4_12_7p3ns sta_scenario=func csh run.csh
```

### Scan Shift

```bash
env ver=4_12_7p3ns sta_scenario=scan_shift csh run.csh
```

### Scan Capture

```bash
env ver=4_12_7p3ns sta_scenario=scan_capture csh run.csh
```

## Scenario 의미

### `func`

- `scan_en=0`
- `test_mode=0`
- functional path 기준 setup / hold / coverage 확인용

### `scan_shift`

- `scan_en=1`
- `test_mode=1`
- scan shift path 기준 timing / coverage 확인용

### `scan_capture`

- `scan_en=0`
- `test_mode=1`
- scan capture / reset recovery-removal 확인용

## 리포트 구조

리포트는 버전 아래에서 scenario별로 먼저 나뉩니다.

```text
4_report/<ver>/
  func/
  capture/
  shift/
```

각 scenario 안에는 report 종류별 폴더가 있습니다.

```text
analysis_coverage/
all_violations/
check_timing/
clock_gating/
clocks/
disable_timing/
hold/
no_clocks/
qor/
setup/
```

예:

```text
4_report/4_12_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt
4_report/4_12_7p3ns/capture/analysis_coverage/scan_capture_pre_ss0p95v125c_analysis_coverage.rpt
4_report/4_12_7p3ns/shift/check_timing/scan_shift_pre_ss0p95v125c_check_timing.rpt
```

## 현재 기준 상태

현재 main project 기준 권장 baseline은 `4_12_7p3ns`입니다.

### Functional setup

- `4_STA/4_report/4_12_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt`
- `clk_fast_aes` setup slack: `0.0003ns`
- violating path 수: `0`

### Capture coverage

- `4_STA/4_report/4_12_7p3ns/capture/analysis_coverage/scan_capture_pre_ss0p95v125c_analysis_coverage.rpt`
- `recovery 1532/1532 met`
- `removal 1532/1532 met`
- 전체 `55% met / 45% untested`

### 남은 이슈

- SRAM interface hold violation 12개는 아직 남아 있음
- `scan_shift`는 scenario 분리는 되었지만, 추가 제약 refinement 여지가 있음

## Correlation 메모

현재 PT script는 DC와 pre-layout correlation을 맞추기 위해 hierarchy별 wire load model을 강제로 반영합니다.

적용 위치:

- `4_STA/0_script/STA_script.tcl`

핵심 설정:

```tcl
set auto_wire_load_selection false
set_wire_load_mode enclosed
set_wire_load_model -name ForQA [current_design]
set_wire_load_model -name 70000 [get_cells u_ctrl]
set_wire_load_model -name 35000 [get_cells u_ctrl/u_aes]
```

이 설정이 없으면 DC에서는 clean하게 보이는 `clk_fast_aes` 경로가 PT에서 더 비관적으로 계산될 수 있습니다.

## 추가 참고 문서

- 문제 발생 배경 / 원인 / 수정 결과:
  - `4_STA/STA_ISSUES_SUMMARY.md`

이 문서에는 다음 내용이 정리되어 있습니다.

- 초기 PT bring-up 문제
- `GTECH_NOT` / `gtech.db` link 문제
- DC-PT correlation load 문제
- `7.0ns` vs `7.3ns` functional setup 결과
- func / capture / shift coverage 해석
