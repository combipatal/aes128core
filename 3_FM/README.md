# 3_FM

이 디렉터리는 `r2n` 전용 Formality 워크스페이스입니다.

현재 역할:

- reference: `../0_rtl`
- implementation: `../2_synthesis`의 mapped gate netlist
- 목적: synthesis 이후에도 RTL 기능이 유지되는지 확인

즉 `3_FM`은 `RTL ↔ synthesis gate` equivalence만 확인합니다.

## 현재 기준 버전

- synthesis version: `4_16_8ns_topo_ss`
- library corner 기본값: `ss`
- top module: `top_mcu_pll_sram_multiclk_soc`

현재 [run_r2n.csh](run_r2n.csh) 기본값도 이 버전을 사용합니다.

## 주요 파일

- [run_r2n.csh](run_r2n.csh)
  - r2n 실행 wrapper
- [0_script/FM_r2n_script.tcl](0_script/FM_r2n_script.tcl)
  - Formality 메인 스크립트

입력:

- RTL: [../0_rtl](../0_rtl)
- synthesis netlist: [../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.v](../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.v)
- SVF: [../2_synthesis/default.svf](../2_synthesis/default.svf)

출력:

- log: [3_log/r2n_4_16_8ns_topo_ss.log](3_log/r2n_4_16_8ns_topo_ss.log)
- reports: [4_report/r2n_4_16_8ns_topo_ss](4_report/r2n_4_16_8ns_topo_ss)

## 실행 방법

```bash
cd /DATA/home/edu135/aes128_core/3_FM
csh run_r2n.csh
```

버전을 직접 지정:

```bash
env ver=4_16_8ns_topo_ss lib_corner=ss fm_ver=r2n_4_16_8ns_topo_ss csh run_r2n.csh
```

## 현재 결과 요약

현재 [r2n_4_16_8ns_topo_ss.log](3_log/r2n_4_16_8ns_topo_ss.log) 기준으로 `Verification SUCCEEDED`입니다.

리포트 기준 상태:

- [unmatched_points_post_matching.rpt](4_report/r2n_4_16_8ns_topo_ss/unmatched_points_post_matching.rpt)
  - unmatched 없음
- [failing_points.rpt](4_report/r2n_4_16_8ns_topo_ss/failing_points.rpt)
  - failing 없음
- [aborted_points.rpt](4_report/r2n_4_16_8ns_topo_ss/aborted_points.rpt)
  - aborted 없음
- [unverified_points.rpt](4_report/r2n_4_16_8ns_topo_ss/unverified_points.rpt)
  - unverified 없음
- [dont_verify_points.rpt](4_report/r2n_4_16_8ns_topo_ss/dont_verify_points.rpt)
  - `scan_out` 1개만 제외

즉 현재 `3_FM`은 functional r2n 기준으로 PASS입니다.

## `scan_out` 해석

현재 `dont_verify_points.rpt`에 남는 것은 아래 한 개입니다.

- `r:/WORK/top_mcu_pll_sram_multiclk_soc/scan_out`

해석:

- 현재 비교는 pre-DFT 기준입니다.
- RTL에는 `scan_out` 포트가 있지만 아직 실제 scan chain output이 아닙니다.
- 그래서 functional r2n 비교에서는 이 포트를 제외하는 편이 맞습니다.

즉 지금 상태에서는:

- `scan_out` 1개 제외는 정상
- 나머지 functional logic equivalence는 모두 확인됨

## black-box 해석

[black_box.rpt](4_report/r2n_4_16_8ns_topo_ss/black_box.rpt)에는 SRAM macro 같은 기술 라이브러리 블록이 보입니다.

현재 해석:

- macro / memory 성격 black-box는 FM 실패 원인으로 바로 보지 않음
- 중요한 건 unmatched / failing / aborted / unverified가 없다는 점입니다

## 현재 판단

현재 `3_FM`은 아래처럼 정리할 수 있습니다.

- 기본 baseline은 `4_16_8ns_topo_ss`
- `Verification SUCCEEDED`
- functional compare point는 모두 정상임
- `scan_out`만 의도적으로 비교에서 제외

즉 현재 README 기준으로도 `3_FM`은 현재 상황에 맞게 PASS 문서를 유지하는 것이 적절합니다.

## 같이 보면 좋은 README

- synthesis: [../2_synthesis/README.md](../2_synthesis/README.md)
- n2n FM: [../5_FM/README.md](../5_FM/README.md)
