# 5_FM

이 디렉터리는 `n2n` 전용 Formality 워크스페이스입니다.

여기서 하는 일:
- reference: `2_synthesis`의 mapped gate netlist
- implementation: `4_DFT`의 scan-inserted gate netlist
- 목적: DFT insertion 이후에도 기능이 유지되는지 확인

즉 `5_FM`은 아래 한 가지만 봅니다.

- `n2n`
  - synthesis gate ↔ DFT gate equivalence

`r2n`은 여기서 하지 않습니다.
`r2n`은 [3_FM](../3_FM) 에서 RTL ↔ synthesis gate 비교용으로 분리합니다.

## 현재 기본 설정

- 기본 synthesis version: `4_15_8ns_topo_ss`
- 기본 DFT version: `4_15_8ns_topo_ss`
- 기본 library corner: `ss`
- top module: `top_mcu_pll_sram_multiclk_soc`

## 주요 파일

- [run_n2n.csh](run_n2n.csh)
  - n2n 실행 wrapper
- [FM_n2n_script.tcl](0_script/FM_n2n_script.tcl)
  - Formality 메인 스크립트
- [N2N_SCAN_OUT_DONT_VERIFY_NOTE.md](N2N_SCAN_OUT_DONT_VERIFY_NOTE.md)
  - `scan_out` 처리 이유 메모

## 실행 방법

기본 실행:

```bash
cd /DATA/home/edu135/aes128_core/5_FM
csh run_n2n.csh
```

버전과 코너를 직접 지정해서 실행:

```bash
cd /DATA/home/edu135/aes128_core/5_FM
env ref_ver=4_15_8ns_topo_ss impl_ver=4_15_8ns_topo_ss lib_corner=ss fm_ver=n2n_4_15_8ns_topo_ss csh run_n2n.csh
```

## 입력 기준

reference gate netlist:
- [2_synthesis/2_output](../2_synthesis/2_output)

implementation gate netlist:
- [4_DFT/2_output](../4_DFT/2_output)

현재 기준 구현 netlist:
- [4_DFT/2_output/4_15_8ns_topo_ss/aes_128_internal.v](../4_DFT/2_output/4_15_8ns_topo_ss/aes_128_internal.v)

## 라이브러리 기준

FM에서는 gate netlist를 해석할 수 있는 logical `.db` 라이브러리가 필요합니다.

현재 `5_FM`은 topo synthesis / DFT와 같은 방향으로 `RVT only` 기준을 사용합니다.

- `RVT`
- `io`
- `pll`
- `sram`

즉 HVT/LVT logical db는 읽지 않습니다.

이유:
- 현재 `2_synthesis` baseline이 `RVT only topo`로 정리되어 있음
- `4_DFT` 결과도 그 logical library set을 바탕으로 만들어짐
- FM도 같은 logical library set을 읽는 편이 mismatch warning이 적고 해석이 단순함

## 출력

실행 후 아래 경로에 결과가 쌓입니다.

- `2_output/${fm_ver}`
- `3_log/${fm_ver}.log`
- `4_report/${fm_ver}`

주요 report:
- `unmatched_points_post_matching.rpt`
- `failing_points.rpt`
- `aborted_points.rpt`
- `unverified_points.rpt`
- `black_box.rpt`
- `dont_verify_points.rpt`

## `scan_out` 처리

`n2n`에서는 `scan_out`를 `dont_verify`로 처리합니다.

이유:
- pre-DFT synthesis gate에서는 `scan_out`가 test용 placeholder 포트처럼 보일 수 있음
- post-DFT gate에서는 실제 scan chain의 `ScanDataOut` 역할이 됨
- 따라서 functional equivalence 관점에서 `scan_out`를 그대로 compare하면 false fail이 날 수 있음

즉 `n2n`에서 중요한 건:
- scan chain test output 자체가 아니라
- functional logic equivalence가 유지되는지입니다.

## 해석 기준

좋은 결과:
- unmatched 없음
- failing 없음
- aborted 없음
- unverified 없음

그리고 아래 상태도 정상으로 봅니다.

- `dont_verify_points.rpt`에 `scan_out`만 존재

의미:
- scan insertion 이후에도 기능은 유지됨
- `scan_out`만 test 포트 성격 때문에 비교에서 제외된 상태

## 현재 `n2n_4_15_8ns_topo_ss` 결과 해석

현재 [n2n_4_15_8ns_topo_ss](4_report/n2n_4_15_8ns_topo_ss) 기준으로 보면 결과는 정상입니다.

확인된 상태:
- `unmatched_points_post_matching.rpt`
  - unmatched 없음
- `failing_points.rpt`
  - failing compare point 없음
- `unverified_points.rpt`
  - unverified point 없음
- `dont_verify_points.rpt`
  - `scan_out` 두 개만 존재
  - reference 쪽 `scan_out`
  - implementation 쪽 `scan_out`

즉 현재 결과는:
- functional n2n은 PASS
- `scan_out`만 의도적으로 비교에서 제외된 상태

왜 두 개가 찍히는가:
- reference synthesis gate에도 `scan_out` 포트가 있음
- implementation DFT gate에도 `scan_out` 포트가 있음
- n2n 스크립트가 양쪽 포트를 모두 `set_dont_verify_point`로 지정함

이유:
- reference 쪽 `scan_out`는 아직 실질적인 scan chain 출력이라기보다 test placeholder 포트 성격이 강함
- implementation 쪽 `scan_out`는 실제 scan chain output이 됨
- 그래서 functional equivalence 관점에서는 이 포트를 그대로 compare하지 않는 편이 맞음

한 줄 해석:
- `dont_verify_points.rpt`에 `scan_out` 두 개만 있고
- 나머지 `unmatched/failing/unverified`가 모두 없으면
- 현재 n2n 결과는 정상으로 봐도 됩니다.

## 현재 단계 의미

`5_FM`은 아래를 확인하는 단계입니다.

1. synthesis gate는 기능을 유지했는가
2. DFT inserted gate도 기능을 유지했는가

즉 `3_FM`의 `r2n`과 이어서 보면:

- `3_FM`
  - RTL ↔ synthesis gate
- `5_FM`
  - synthesis gate ↔ DFT gate

이 두 결과가 모두 맞아야 전체 흐름의 기능 등가가 닫힙니다.

## 함께 보는 디렉터리

- r2n FM: [3_FM](../3_FM)
- synthesis: [2_synthesis](../2_synthesis)
- DFT: [4_DFT](../4_DFT)
