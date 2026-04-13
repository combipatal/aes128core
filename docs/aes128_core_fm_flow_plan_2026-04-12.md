# aes128_core FM-Centric Improvement Plan

## Update 2026-04-13

`4_13_7p3ns`를 새 clean baseline으로 채택한다.

- synthesis mapped netlist와 DFT netlist에서 `GTECH_` generic cell 제거 완료
- func / capture / shift STA를 다시 돌려 full timing picture 확보
- FM r2n / n2n PASS 유지

다만 아래 이슈는 여전히 남아 있다.

- SRAM interface hold violation `12`개 지속
- `clk_fast_aes` margin이 `0.0003ns -> 0.0000ns`로 더 얇아짐
- `scan_shift`는 generic-cell 문제는 해소됐지만 `no_input_delay` 2개가 여전히 남아 under-constrained
- DFT single-chain / debug-clock-output / FM methodology 이슈는 미해결

따라서 `4_13_7p3ns`는 "최적 baseline"이 아니라 "generic-free clean baseline"으로 해석한다.

## Requirements Summary

이 계획의 목표는 `/DATA/home/edu135/aes128_core`를 학습용 단발 실습 플로우에서, 재현 가능한 실무형 RTL -> VCS -> synthesis -> DFT -> STA -> FM 검증 플로우로 끌어올리는 것이다.

현재 기준 baseline은 `4_13_7p3ns`다.

- RTL/VCS known-answer regression 3종은 통과했다: [summary.log](../1_vcs/4_report/default_nist/summary.log), [summary.log](../1_vcs/4_report/ext_zero/summary.log), [summary.log](../1_vcs/4_report/ext_ecb_nist/summary.log).
- synthesis `4_13_7p3ns`는 `GTECH_NOT` 제거에 성공했고 setup clean을 유지하지만, `clk_div2` SRAM interface hold 12개가 남아 있다: [qor.rpt](../2_synthesis/4_report/4_13_7p3ns/qor.rpt), [area.rpt](../2_synthesis/4_report/4_13_7p3ns/area.rpt).
- post-DFT func/capture/shift STA도 다시 정리되었고, 같은 hold 12개를 유지한다. `scan_shift`는 generic-cell 문제는 없어졌지만 `no_input_delay` 2개가 남아 있다: [func_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt), [scan_shift_pre_ss0p95v125c_check_timing.rpt](../4_STA/4_report/4_13_7p3ns/shift/check_timing/scan_shift_pre_ss0p95v125c_check_timing.rpt), [scan_shift_pre_ss0p95v125c_analysis_coverage.rpt](../4_STA/4_report/4_13_7p3ns/shift/analysis_coverage/scan_shift_pre_ss0p95v125c_analysis_coverage.rpt).
- FM은 최신 baseline에서도 r2n/n2n 모두 성공했다. 다만 n2n은 `scan_out` 1포트를 `dont_verify`로 제외한 functional equivalence 기준이다: [r2n_4_13_7p3ns.log](../5_FM/3_log/r2n_4_13_7p3ns.log), [n2n_4_13_7p3ns.log](../5_FM/3_log/n2n_4_13_7p3ns.log), [FM_n2n_script.tcl](../5_FM/0_script/n2n/FM_n2n_script.tcl).

## Current Assessment

### What Is Working

- 기능 검증 자체는 최소한의 E2E 신뢰도를 확보했다. 세 케이스 모두 UART 20바이트와 `done/pass`가 통과한다: [summary.log](../1_vcs/4_report/default_nist/summary.log), [tb_top_mcu_pll_sram_multiclk_soc.sv](../1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv).
- synthesis/DFT/PT/FM까지 단계별 산출물이 끊기지 않고 존재한다. baseline 버전은 이제 `4_13_7p3ns`로 본다: [run.csh](../2_synthesis/run.csh), [run.csh](../3_DFT/run.csh), [run.csh](../4_STA/run.csh), [run_r2n.csh](../5_FM/run_r2n.csh).
- PPA sweep 자체는 의미가 있었고, `4_13_7p3ns`는 이전 `4_12_7p3ns`보다 더 clean한 netlist를 제공한다. 다만 area와 hold TNS는 약간 불리해졌다: [qor.rpt](../2_synthesis/4_report/4_12_7p3ns/qor.rpt), [qor.rpt](../2_synthesis/4_report/4_13_7p3ns/qor.rpt), [func_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_12_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt), [func_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt).

### What Must Be Fixed

1. 실사용 RTL과 검증 전용 RTL intent가 섞여 있다.
   `aes_key_ext`, `aes_pt_ext`, `aes_vec_valid`는 top/soc에서 항상 포트로 존재하지만 실제 사용은 `SIM_EXTVEC` define 아래로만 제한된다: [top_mcu_pll_sram_multiclk_soc.v](../0_rtl/top_mcu_pll_sram_multiclk_soc.v), [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v). 이 구조 때문에 synthesis `check_design`에 대량 `LINT-28` 경고가 쌓인다: [aes_chk_design.rpt](../2_synthesis/4_report/4_12_7p3ns/aes_chk_design.rpt).

2. `u_mem` wrapper `dont_touch`로 인한 `GTECH_NOT` 잔존 문제는 해결됐다.
   `4_13_7p3ns`에서는 synthesis mapped netlist와 DFT netlist에서 `GTECH_`가 제거되었고, STA의 generic-cell 경고도 사라졌다. 다만 이 변경 이후 area / net area / hold TNS는 약간 불리해졌다: [area.rpt](../2_synthesis/4_report/4_13_7p3ns/area.rpt), [func_pre_ss0p95v125c_check_timing.rpt](../4_STA/4_report/4_13_7p3ns/func/check_timing/func_pre_ss0p95v125c_check_timing.rpt), [scan_shift_pre_ss0p95v125c_check_timing.rpt](../4_STA/4_report/4_13_7p3ns/shift/check_timing/scan_shift_pre_ss0p95v125c_check_timing.rpt).

3. scan_shift STA는 여전히 under-constrained다.
   shift override는 본질적으로 달라지지 않았고, `4_13_7p3ns`에서도 `no clock-relative input delay` 2개가 남아 있으며 coverage도 `37% met / 63% untested`에 머문다: [scan_shift_sta.tcl](../4_STA/1_input/constraint/scan_shift_sta.tcl), [scan_shift_pre_ss0p95v125c_check_timing.rpt](../4_STA/4_report/4_13_7p3ns/shift/check_timing/scan_shift_pre_ss0p95v125c_check_timing.rpt), [scan_shift_pre_ss0p95v125c_analysis_coverage.rpt](../4_STA/4_report/4_13_7p3ns/shift/analysis_coverage/scan_shift_pre_ss0p95v125c_analysis_coverage.rpt).

4. FM은 성공했지만 methodology가 아직 brittle하다.
   r2n은 `guide_hier_map` 부재 경고와 `FMR_ELAB-059` RTL interpretation warning을 안고 통과했다: [r2n_4_12_7p3ns.log](../5_FM/3_log/r2n_4_12_7p3ns.log), [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v). 또한 FM source list에만 `aes_sbox.v`가 들어가 있는데 synthesis/VCS filelist에는 없다: [FM_r2n_script.tcl](../5_FM/0_script/r2n/FM_r2n_script.tcl), [synthesis_script.tcl](../2_synthesis/0_script/synthesis_script.tcl), [filelist.f](../1_vcs/0_script/filelist.f), [black_box.rpt](../5_FM/4_report/r2n_4_12_7p3ns/black_box.rpt).

5. DFT 구조는 학습용으로는 충분하지만 실무 test cost 관점에서는 약하다.
   현재 single scan chain 길이가 1532이고 dedicated scan-out도 만들지 않는다: [scan_config_internal.rpt](../3_DFT/4_report/4_12_7p3ns/scan_config_internal.rpt), [scan_chains_internal.rpt](../3_DFT/4_report/4_12_7p3ns/scan_chains_internal.rpt). 이는 bring-up에는 단순하지만 production test time과 ATPG 효율 측면에서는 불리하다.

6. top interface에 debug/observe용 internal clock output을 노출해 DFT DRC를 더럽힌다.
   top이 `clk_fast/div2/div4/div8`를 출력 포트로 유지하고 있고: [top_mcu_pll_sram_multiclk_soc.v](../0_rtl/top_mcu_pll_sram_multiclk_soc.v), post-DFT DRC에는 `Clock connected to primary output`가 남아 있다: [insert_drc_internal.dft](../3_DFT/4_report/4_12_7p3ns/insert_drc_internal.dft).

### What Is Acceptable For Now

- `scan_out`를 n2n functional FM에서 `dont_verify` 처리한 것은 현재 목적상 합리적이다. DFT는 동일 포트를 `ScanDataOut`으로 재사용하고 있고 chain도 `scan_in -> scan_out`로 구성된다: [FM_n2n_script.tcl](../5_FM/0_script/n2n/FM_n2n_script.tcl), [dft_signals_internal.rpt](../3_DFT/4_report/4_12_7p3ns/dft_signals_internal.rpt), [scan_config_internal.rpt](../3_DFT/4_report/4_12_7p3ns/scan_config_internal.rpt), [scan_chains_internal.rpt](../3_DFT/4_report/4_12_7p3ns/scan_chains_internal.rpt).
- `4_13_7p3ns` baseline 선택은 합리적이다. functional PT `clk_fast_aes` slack이 `0.0000ns`로 매우 얇지만 clean이고, func/capture/shift full picture에서도 generic-free 상태를 유지한다: [func_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt), [scan_capture_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/capture/qor/scan_capture_pre_ss0p95v125c_qor.rpt), [scan_shift_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/shift/qor/scan_shift_pre_ss0p95v125c_qor.rpt).

## Acceptance Criteria

이 계획이 완료되었다고 판단하려면 아래 항목이 충족되어야 한다.

1. synthesis mapped/netlist와 DFT netlist에서 `GTECH_` generic cell이 제거된다. `4_13_7p3ns`에서 달성.
2. synthesis `check_design`의 대규모 sim-only 포트 경고가 구조적으로 정리된다.
3. scan_shift scenario가 dedicated test intent를 반영한 제약으로 정리되고 `no_input_delay` 경고가 제거되거나 합리적으로 설명된다.
4. r2n/n2n FM이 최신 버전에서 재실행되어 `Verification SUCCEEDED`를 재현하고, n2n의 `dont_verify` 의도는 문서/스크립트에 명시된다.
5. 최소 1개의 버전 manifest가 생성되어 VCS/synthesis/FM의 source list와 artifact handoff가 일치한다.
6. baseline PPA 표가 작성되어 `clk_period`, setup WNS, hold WNS, area, DFT delta, FM status를 한 눈에 비교할 수 있다.

## Implementation Steps

### Step 1. RTL intent 분리: sim-only interface와 synth interface를 나눈다

대상:

- [top_mcu_pll_sram_multiclk_soc.v](../0_rtl/top_mcu_pll_sram_multiclk_soc.v)
- [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v)
- [tb_top_mcu_pll_sram_multiclk_soc.sv](../1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv)

작업:

- `aes_key_ext`, `aes_pt_ext`, `aes_vec_valid`를 production top에 계속 둘지 결정한다.
- 권장안은 `tb wrapper`를 따로 두고, synth top에서는 sim-only vector ingress를 제거하는 것이다.
- 최소한 production top에서는 `ifdef`가 아니라 명시적 parameter 또는 별도 wrapper로 intent를 분리한다.
- `!==` 기반 compare는 FM-friendly하게 바꾼다. 권장안은 synth path에서는 `!=`를 사용하고, X-detect가 필요하면 testbench나 assertion으로 분리하는 것이다: [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v).

이유:

- 현재 구조는 synthesis lint noise와 FM interpretation warning을 동시에 만든다.

### Step 2. synthesis handoff를 library-clean하게 만든다

대상:

- [synthesis_script.tcl](../2_synthesis/0_script/synthesis_script.tcl)
- [sram_wrap_1rw1024x8.v](../0_rtl/sram_wrap_1rw1024x8.v)
- [soc_gate.v](../2_synthesis/2_output/4_12_7p3ns/mapped/soc_gate.v)

작업:

- `set_dont_touch [get_cells u_mem]`를 제거하고, 필요하면 실제 macro instance `u_mem/u_sram`만 보호한다.
- wrapper의 active-low 변환 logic가 standard cell inverter로 맵되도록 한다.
- compile 후 `check_design`, `report_qor`, `report_area`, `report_constraint`, `check_timing`을 함께 남기고 `GTECH_`/generic 잔존 여부를 grep으로 자동 확인한다.
- `default.svf`도 버전별 산출물로 저장되도록 경로를 정리한다.

상태:

- `4_13_7p3ns`에서 완료.
- 이후 baseline은 `4_13_7p3ns` 기준으로 유지한다.

### Step 3. filelist/manifest를 단일 source of truth로 통합한다

대상:

- [filelist.f](../1_vcs/0_script/filelist.f)
- [synthesis_script.tcl](../2_synthesis/0_script/synthesis_script.tcl)
- [FM_r2n_script.tcl](../5_FM/0_script/r2n/FM_r2n_script.tcl)

작업:

- 공통 RTL manifest를 한 군데에서 관리한다.
- VCS, synthesis, FM이 모두 그 manifest를 소비하게 바꾼다.
- 사용되지 않는 `aes_sbox.v` 같은 stale module은 제거하거나, 정말 필요한 경우에만 명시적으로 포함한다.
- 버전별 run metadata에 `ver`, `clk_period`, input netlist, output netlist, SDC, SVF 경로를 기록한다.

이유:

- 지금은 단계별 source list가 subtly 다르다. 이 상태는 나중에 “왜 툴마다 다른가”를 만들기 쉽다.

### Step 4. STA scenario를 실무형으로 정리한다

대상:

- [constraint.con](../2_synthesis/1_input/constraint/constraint.con)
- [scan_shift_sta.tcl](../4_STA/1_input/constraint/scan_shift_sta.tcl)
- [scan_capture_sta.tcl](../4_STA/1_input/constraint/scan_capture_sta.tcl)
- [STA_script.tcl](../4_STA/0_script/STA_script.tcl)

작업:

- `func`, `scan_shift`, `scan_capture`를 truly distinct scenario로 만든다.
- `scan_shift`에는 test clock, scan IO delay, non-scan false path, required driving cell/load를 명시한다.
- current `constraint.con`의 false path와 debug clock output treatment를 재검토한다: [constraint.con](../2_synthesis/1_input/constraint/constraint.con).
- constraint report에서 timing 이슈와 power-default 이슈를 분리한다. 현재 `max_leakage_power` violation은 timing 판단에 노이즈만 준다: [constraint.rpt](../2_synthesis/4_report/4_12_7p3ns/constraint.rpt).

이유:

- 현재 scan_shift는 “시나리오 이름만 따로 있고 timing intent는 거의 func 재사용” 상태다.

### Step 5. hold 12개를 실제 closure 대상으로 다룬다

대상:

- [func_pre_ss0p95v125c_hold.rpt](../4_STA/4_report/4_13_7p3ns/func/hold/func_pre_ss0p95v125c_hold.rpt)
- [func_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt)

작업:

- 원인이 `u_ctrl` flop -> SRAM macro input의 너무 짧은 local path라는 점을 기준으로 fix strategy를 정한다.
- 우선순위는 `set_fix_hold [get_clocks clk_div2]` 기반 DC experiment와, wrapper 또는 control-path에 small delay/buffer 삽입 가능성 비교다.
- hold fix 전후로 `clk_fast_aes` setup 여유 `0.0000ns`가 깨지지 않는지 항상 같이 본다.

이유:

- 지금 프로젝트에서 남은 실질 timing issue는 이것 하나다. 이것을 닫지 않으면 “FM까지 갔다”가 signoff readiness를 의미하지 않는다.

### Step 6. DFT를 학습용 baseline에서 production-aware baseline으로 올린다

대상:

- [DFT_script.tcl](../3_DFT/0_script/DFT_script.tcl)
- [scan_config_internal.rpt](../3_DFT/4_report/4_13_7p3ns/scan_config_internal.rpt)
- [insert_drc_internal.dft](../3_DFT/4_report/4_13_7p3ns/insert_drc_internal.dft)

작업:

- `chain_count 1`을 유지할지, 2개 이상으로 나눌지 비교 실험을 한다.
- production 후보라면 compression은 아니더라도 multi-chain split까지는 검토한다.
- internal clock gating/test enable 연결을 명시적으로 모델링할지 결정한다. 현재 관련 설정이 주석으로 남아 있다: [DFT_script.tcl](../3_DFT/0_script/DFT_script.tcl).
- debug clock outputs가 실제 제품 IO가 아니라면 top interface에서 제거한다.

이유:

- single chain 1532는 학습용으로 단순하지만 production test time에는 길다.

### Step 7. FM methodology를 “pass one-shot”에서 “reproducible signoff checklist”로 바꾼다

대상:

- [FM_r2n_script.tcl](../5_FM/0_script/r2n/FM_r2n_script.tcl)
- [FM_n2n_script.tcl](../5_FM/0_script/n2n/FM_n2n_script.tcl)
- [r2n_4_13_7p3ns.log](../5_FM/3_log/r2n_4_13_7p3ns.log)

작업:

- synthesis에서 explicit SVF generation/hier-map guidance를 넣고 FM에서 그것을 소비한다.
- r2n/n2n 각각에 “expected dont_verify points”, “expected black boxes”, “expected constants”를 문서화한다.
- FM pass 기준을 리포트 파일 존재 여부가 아니라 `Verification SUCCEEDED` + failing/unverified/unmatched empty + expected dont_verify only로 정의한다.

이유:

- 현재는 성공했지만, guidance 부족과 RTL interpretation warning이 남아 있다.

### Step 8. PPA 관리 방식을 버전 폴더 나열에서 비교표 기반으로 바꾼다

대상:

- [qor.rpt](../2_synthesis/4_report/4_11_3_6ns/qor.rpt)
- [dft_qor_internal.rpt](../3_DFT/4_report/4_13_7p3ns/dft_qor_internal.rpt)
- [func_pre_ss0p95v125c_qor.rpt](../4_STA/4_report/4_13_7p3ns/func/qor/func_pre_ss0p95v125c_qor.rpt)

작업:

- `ver`별로 period / synthesis area / DFT area / PT WNS / PT hold WNS / scan chain length / FM status를 표로 만든다.
- decision 기준을 “가장 최근 버전”이 아니라 “best feasible baseline”으로 정의한다.
- `7.3ns` 이후에는 단순히 주기를 더 느슨하게 하는 대신, hold 정리와 DFT/STA quality 향상 쪽으로 투자한다.

이유:

- 지금은 버전 디렉터리가 많지만 의사결정 기록은 약하다.

## Risks And Mitigations

- 리스크: sim-only port 분리 과정에서 testbench가 깨질 수 있다.
  대응: 먼저 wrapper 분리 후 기존 TB stimulus를 wrapper 기준으로 유지한다.

- 리스크: `u_mem` dont_touch 해제 후 macro wrapper mapping이 바뀌어 FM/STA 결과가 달라질 수 있다.
  대응: GTECH 제거를 최우선 검증 포인트로 두고 r2n/n2n/STA를 즉시 재실행한다.

- 리스크: hold fix가 `clk_fast_aes`의 얇은 setup margin을 망가뜨릴 수 있다.
  대응: hold fix마다 func PT setup/hold를 동시에 비교하고, `clk_fast_aes` WNS `0.0000ns`를 gate criterion으로 둔다.

- 리스크: scan_shift 제약을 강화하면 coverage가 오르지 않고 violation만 늘어날 수 있다.
  대응: coverage 숫자만 목표로 두지 말고, no_clock/no_input_delay/unconstrained endpoint 제거를 먼저 성공 기준으로 둔다.

## Verification Steps

1. VCS regression 3종을 재실행해서 summary log가 모두 PASS인지 확인한다.
2. synthesis 후 mapped netlist에서 `rg "GTECH_"`가 0건인지 확인한다.
3. synthesis `check_design`, `qor`, `constraint`, `check_timing`을 묶어서 archive한다.
4. DFT 후 `insert_drc_internal.dft`, `scan_config_internal.rpt`, `scan_chains_internal.rpt`를 다시 확인한다.
5. STA `func`, `scan_shift`, `scan_capture` 3개를 모두 재실행하고:
   - func setup clean
   - func/capture hold 개선 여부
   - shift no_input_delay/no_clock 상태
   - coverage 변화
   를 표로 남긴다.
6. FM `run_r2n.csh`, `run_n2n.csh` 재실행 후:
   - `Verification SUCCEEDED`
   - `failing_points.rpt` empty
   - `unverified_points.rpt` empty
   - `unmatched_points_post_matching.rpt` empty
   - `dont_verify_points.rpt`가 의도한 포인트만 포함
   를 확인한다.

## Recommended Execution Order

1. Step 3 source manifest 통합
2. Step 1 sim-only interface 분리
3. Step 4 scan_shift/constraint 정리
4. Step 5 hold 12개 closure
5. Step 6 DFT multi-chain / debug port 정리
6. Step 7 FM methodology 강화
7. Step 8 PPA summary 체계화

## Short Recommendation

가장 먼저 할 일은 PPA 추가 최적화가 아니다. `4_13_7p3ns`를 clean baseline으로 고정한 뒤, sim-only port 때문에 생기는 lint noise, scan_shift under-constraint, FM source-list drift를 정리하는 것이 맞다. 그 다음에 hold 12개를 닫고, 마지막으로 multi-chain/production-aware DFT와 PPA 정리를 들어가는 순서가 실무적으로 가장 안전하다.
