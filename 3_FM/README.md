# 3_FM

이 디렉터리는 `r2n` 전용 Formality 워크스페이스입니다.

여기서 하는 일:
- reference: `0_rtl`
- implementation: `2_synthesis`의 mapped gate netlist
- 목적: 합성 후에도 RTL 기능이 유지되는지 확인

즉 `3_FM`은 아래 한 가지만 봅니다.

- `r2n`
  - RTL ↔ synthesis gate equivalence

`n2n`은 여기서 하지 않습니다.
`n2n`은 `5_FM`에서 synthesis gate ↔ DFT gate 비교용으로 분리합니다.

## 현재 기본 설정

- 기본 synthesis version: `4_15_8ns_topo_ss`
- 기본 library corner: `ss`
- top module: `top_mcu_pll_sram_multiclk_soc`

## 주요 파일

- [run_r2n.csh](run_r2n.csh)
  - r2n 실행 wrapper
- [FM_r2n_script.tcl](0_script/FM_r2n_script.tcl)
  - Formality 메인 스크립트

## 실행 방법

기본 실행:

```bash
cd /DATA/home/edu135/aes128_core/3_FM
csh run_r2n.csh
```

버전과 코너를 직접 지정해서 실행:

```bash
cd /DATA/home/edu135/aes128_core/3_FM
env ver=4_15_8ns_topo_ss lib_corner=ss fm_ver=r2n_4_15_8ns_topo_ss csh run_r2n.csh
```

## 입력 기준

reference RTL:
- [0_rtl](../0_rtl)

implementation netlist:
- [2_synthesis/2_output](../2_synthesis/2_output)

SVF:
- [2_synthesis/default.svf](../2_synthesis/default.svf)

## 라이브러리 기준

FM에서는 gate netlist를 해석할 수 있는 logical `.db` 라이브러리가 필요합니다.

현재 `3_FM`은 topo 합성과 같은 방향으로 `RVT only` 기준을 사용합니다.

- `RVT`
- `io`
- `pll`
- `sram`

즉 HVT/LVT logical db는 읽지 않습니다.

이유:
- 현재 `2_synthesis` topo baseline이 `RVT only`로 정리되어 있음
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

## 해석 기준

좋은 결과:
- unmatched 없음
- failing 없음
- aborted 없음
- unverified 없음

의미:
- 합성 최적화, constant propagation, register merge가 있어도
- RTL과 synthesis gate의 기능은 같다고 본다

## `dont_verify_points.rpt` 해석

현재 `r2n` 결과에서는 `scan_out` 하나가 `dont_verify`로 남을 수 있습니다.

이유:
- 현재 비교는 pre-DFT 기준임
- RTL에는 `scan_out` 포트가 미리 존재하지만
- 아직 scan chain이 실제로 연결된 상태는 아님

즉 `scan_out`는 기능 포트라기보다 test용 placeholder 포트에 가깝습니다.

그래서 FM은 이 포트를 비교 대상에서 제외할 수 있습니다.

현재 기준으로 아래 상태면 정상으로 봅니다.

- `dont_verify_points.rpt`에 `scan_out` 1개만 존재
- `unmatched`, `failing`, `aborted`, `unverified`는 모두 없음

이 경우 의미:
- functional logic equivalence는 정상
- `scan_out`만 pre-DFT 특성 때문에 비교에서 빠진 상태

## 함께 보는 디렉터리

- RTL: [0_rtl](../0_rtl)
- synthesis: [2_synthesis](../2_synthesis)
- n2n FM: [5_FM](../5_FM)
