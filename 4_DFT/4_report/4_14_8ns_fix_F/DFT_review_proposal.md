# `4_14_8ns_fix_F` DFT 검토 제안서

## 검토 범위
- 검토 스크립트:
  - `/DATA/home/edu135/aes128_core/3_DFT/0_script/DFT_script.tcl`
- 검토 리포트:
  - `pre_dft.rpt`
  - `pre_drc_verbose.rpt`
  - `preview_dft.rpt`
  - `insert_drc_internal.dft`
  - `scan_config_internal.rpt`
  - `scan_chains_internal.rpt`
  - `dft_qor_func.rpt`
  - `dft_qor_internal.rpt`

## 현재 상태 요약
- scan insertion 자체는 완료됨
- insertion 이후 기능/내부 scan QoR 상 setup/hold violation은 없음
- 다만 ICG와 macro 처리 이슈가 남아 있어, 현재 결과를 최종 DFT closure로 보기는 어려움

## 핵심 이슈

### 1. AES ICG가 DFT 관점에서 제대로 처리되지 않음
- 근거:
  - `pre_dft.rpt`: `No gating element has been automatically identified`
  - `pre_dft.rpt`: `u_ctrl/u_icg_aes/en_lat_reg is not scannable`
  - `pre_dft.rpt`: `u_ctrl/u_icg_aes/en_lat_reg has constant 1 value`
  - `insert_drc_internal.dft`에서도 동일 이슈 유지
- 해석:
  - 툴이 `u_ctrl/u_icg_aes`를 정상적인 DFT 제어 가능 clock-gating 셀로 이해하지 못하고 있음
  - 현재 run은 문제 셀 1개를 남긴 채 insertion이 진행된 상태이지, AES clock gating test path가 깨끗하게 정리된 상태는 아님

### 2. 멀티클럭 설계를 단일 scan clock / 단일 chain으로 묶어 둠
- 근거:
  - `DFT_script.tcl`: `chain_count 1`
  - `DFT_script.tcl`: `internal_clocks none`
  - `scan_chains_internal.rpt`: chain 1개, 길이 `1108`
  - `dft_signals_internal.rpt`: scan master clock로 `ref_clk`만 사용
- 해석:
  - 첫 insertion trial로는 가능하지만, 최종 구조로 보기엔 비효율적임
  - shift time, ATPG runtime, test 효율 측면에서 불리할 가능성이 큼

### 3. PLL / SRAM macro가 unknown-model 상태로 남아 있음
- 근거:
  - `pre_drc_verbose.rpt`: `u_mem/u_sram`, `u_pll` unknown-model violation
  - `insert_drc_internal.dft`에서도 동일 이슈 유지
- 해석:
  - scan insertion 실패는 아니지만, macro test 정책이 아직 없는 상태라는 뜻임
  - MBIST, macro test abstraction, waiver 중 어떤 방식으로 처리할지 결정이 필요함

### 4. ref_clk가 primary output인 `clk_fast`에 연결된 경고가 남아 있음
- 근거:
  - `insert_drc_internal.dft`: `Clock ref_clk is connected to primary output clk_fast. (C17-1)`
- 해석:
  - PLL/clock output 구조에서 나올 수 있는 경고라 치명적이진 않음
  - 다만 최종 signoff 전에는 waive 근거나 예외 처리 기준을 남겨야 함

## 권장 작업 순서

### 1단계. `u_ctrl/u_icg_aes`의 DFT 처리부터 정리
- 목표:
  - AES clock gating 구조를 툴이 명시적으로 이해하도록 만들 것
- 권장 검토 항목:
  - 아래 주석 처리된 설정을 다시 활성화하고 검증
  - `set_dft_clock_gating_pin [get_cells u_ctrl/u_icg_aes] -pin_name test_en -control_signal ScanEnable`
  - `set_scan_element false [get_cells u_ctrl/u_icg_aes]`
- 메모:
  - 현재 `test_dft_drc_ungate_clocks true`만으로는 부족함
  - 가장 우선순위가 높은 항목임

### 2단계. `u_pll`, `u_mem/u_sram`에 대한 test 정책 결정
- 아래 중 하나를 명확히 정해야 함
  - waiver 처리
  - 별도 macro DFT 처리
  - MBIST / memory test flow 연계
- 메모:
  - 현재 unknown-model warning을 그냥 무시하면 안 됨
  - non-scan test 전략이 명확할 때만 허용 가능

### 3단계. 단일 scan chain 정책 재검토
- 현재 상태:
  - chain 1개, 길이 `1108`
- 권장:
  - pin budget이 허용되면 `chain_count 2` 또는 `4` 실험
- 기대 효과:
  - shift time 감소
  - ATPG runtime 및 tester 운용 측면 개선
- 메모:
  - 이건 1단계보다 우선순위가 낮음
  - 먼저 ICG 처리가 정리돼야 함

### 4단계. clock-to-output 경고 분류 또는 waiver 정리
- 대상 경고:
  - `C17-1`: `ref_clk`가 primary output `clk_fast`에 연결됨
- 조치:
  - top-level PLL/clock export 구조상 의도된 경로인지 확인
  - 의도된 구조라면 waiver 근거 문서화

## 스크립트 수정 방향 제안

### 유지해도 되는 항목
- `set_dft_insertion_configuration -synthesis_optimization none -preserve_design_name true`
- `set_scan_configuration -test_mode all -style multiplexed_flip_flop`
- `set_dft_configuration -fix_bus enable`

### 먼저 재검토할 항목
- `set_dft_clock_gating_pin ...`
- `set_scan_element false ...`
- `set_scan_configuration -test_mode all -chain_count 1`
- `set_scan_configuration -test_mode all -internal_clocks none`

## 다음 DFT run의 통과 기준
- `u_ctrl/u_icg_aes/en_lat_reg`가 더 이상 unresolved scannability 이슈로 남지 않을 것
- AES clock gating test bypass path가 명확히 정리될 것
- macro unknown-model warning이
  - 모델링/전용 test 처리로 줄어들거나
  - 프로젝트 기준으로 정당한 waiver가 준비될 것
- scan chain 구조가 의도적으로 선택된 상태일 것

## 실무적 결론
- 현재 결과는 “DFT 1차 insertion checkpoint”로는 의미가 있음
- 하지만 “최종 DFT 완료 상태”로 보기엔 이르다
- 다음 run은 ATPG나 coverage보다 먼저, `u_ctrl/u_icg_aes` 처리 정리를 우선해야 함
