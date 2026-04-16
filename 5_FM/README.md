# 5_FM

이 디렉터리는 `n2n` 전용 Formality 워크스페이스입니다.

현재 역할:

- reference: `2_synthesis`의 mapped gate netlist
- implementation: `4_DFT`의 scan-inserted gate netlist
- 목적: DFT insertion 이후에도 functional logic이 유지되는지 확인

즉 `5_FM`은 `synthesis gate ↔ DFT gate` equivalence만 확인합니다.

## 현재 기준 버전

- reference version: `4_16_8ns_topo_ss`
- implementation version: `4_16_8ns_topo_ss`
- library corner 기본값: `ss`
- top module: `top_mcu_pll_sram_multiclk_soc`

현재 [run_n2n.csh](run_n2n.csh) 기본값도 이 조합을 사용합니다.

## 주요 파일

- [run_n2n.csh](run_n2n.csh)
  - n2n 실행 wrapper
- [0_script/FM_n2n_script.tcl](0_script/FM_n2n_script.tcl)
  - Formality 메인 스크립트

입력:

- synthesis reference: [../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.v](../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.v)
- DFT implementation: [../4_DFT/2_output/4_16_8ns_topo_ss/aes_128_internal.v](../4_DFT/2_output/4_16_8ns_topo_ss/aes_128_internal.v)

출력:

- log: `3_log/n2n_4_16_8ns_topo_ss.log`
- reports: [4_report/n2n_4_16_8ns_topo_ss](4_report/n2n_4_16_8ns_topo_ss)

## 실행 방법

```bash
cd ./5_FM
csh run_n2n.csh
```

버전을 직접 지정:

```bash
env ref_ver=4_16_8ns_topo_ss impl_ver=4_16_8ns_topo_ss lib_corner=ss fm_ver=n2n_4_16_8ns_topo_ss csh run_n2n.csh
```

## 현재 결과 요약

현재 `3_log/n2n_4_16_8ns_topo_ss.log` 기준으로 `Verification SUCCEEDED`입니다.

리포트 기준 상태:

- [failing_points.rpt](4_report/n2n_4_16_8ns_topo_ss/failing_points.rpt)
  - failing 없음
- [aborted_points.rpt](4_report/n2n_4_16_8ns_topo_ss/aborted_points.rpt)
  - aborted 없음
- [unverified_points.rpt](4_report/n2n_4_16_8ns_topo_ss/unverified_points.rpt)
  - unverified 없음
- [dont_verify_points.rpt](4_report/n2n_4_16_8ns_topo_ss/dont_verify_points.rpt)
  - `scan_out` 2개 제외

즉 functional equivalence 자체는 PASS입니다.

## 현재 unmatched point 해석

현재 [unmatched_points_post_matching.rpt](4_report/n2n_4_16_8ns_topo_ss/unmatched_points_post_matching.rpt)에는 implementation unmatched point가 6개 있습니다.

현재 남는 포트:

- `test_si2`
- `test_si3`
- `test_si4`
- `test_so2`
- `test_so3`
- `test_so4`

해석:

- 현재 DFT가 4-chain 구조로 바뀌면서 implementation 쪽에만 추가 scan test port가 생겼습니다.
- synthesis reference에는 이 포트들이 없으므로 structural unmatched는 남습니다.
- 하지만 verify 자체는 성공했고 failing / aborted / unverified는 없습니다.

즉 현재 `5_FM`은 아래처럼 읽는 것이 맞습니다.

- functional n2n은 PASS
- DFT-only scan port 6개는 implementation unmatched로 남음

이 점이 예전 README의 “`scan_out` 두 개만 남는다” 설명과 가장 크게 달라진 부분입니다.

## `scan_out` 처리

현재 스크립트는 `scan_out`만 `dont_verify`로 처리합니다.

이유:

- pre-DFT synthesis gate의 `scan_out`
- post-DFT implementation의 `scan_out`

이 둘은 functional 포트라기보다 test output 성격이 강하기 때문입니다.

현재 `dont_verify_points.rpt`에는 아래 두 개가 보입니다.

- reference `scan_out`
- implementation `scan_out`

## 현재 판단

현재 `5_FM`은 아래처럼 정리할 수 있습니다.

- `Verification SUCCEEDED`
- functional compare point는 PASS
- `scan_out` 2개는 의도적으로 제외
- 추가 scan test port 6개는 implementation unmatched로 남음

즉 지금 단계에서는:

- 기능 등가는 유지됨
- 다만 DFT 포트 수가 바뀐 현재 구조를 README에 반영해야 함

## 같이 보면 좋은 README

- synthesis: [../2_synthesis/README.md](../2_synthesis/README.md)
- DFT: [../4_DFT/README.md](../4_DFT/README.md)
- r2n FM: [../3_FM/README.md](../3_FM/README.md)
