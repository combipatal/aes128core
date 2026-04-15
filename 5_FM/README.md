# 5_FM

이 디렉터리는 `aes128_core` 프로젝트의 Formality(FM) 워크스페이스입니다. 목적은 기능이 맞는지 “느낌상” 확인하는 것이 아니라, 아래 두 단계에서 실제 등가성을 증명하는 것입니다.

- `r2n`
  - RTL ↔ synthesis gate equivalence
- `n2n`
  - synthesis gate ↔ post-DFT gate equivalence

포트폴리오 관점에서 이 단계의 의미는 명확합니다.

- RTL이 합성 후에도 기능적으로 유지되는지
- DFT와 post-DFT ECO 이후에도 기능 equivalence가 유지되는지

를 실제 Formality 리포트로 증명한 단계입니다.

## 전체 흐름에서의 위치

이 프로젝트에서 FM은 아래 흐름의 마지막 기능 등가 확인 단계입니다.

1. `0_rtl`
   - 기준 RTL
2. `2_synthesis`
   - synthesis baseline 생성
3. `3_DFT`
   - DFT inserted gate 생성
4. `4_STA`
   - post-DFT timing clean 확인
5. `5_FM`
   - 기능 equivalence 최종 확인

즉 `5_FM`은 “이전 단계에서 만든 netlist들이 timing만 맞는 게 아니라, 논리적으로도 같은가?”를 확인하는 자리입니다.

## 두 가지 비교의 의미

### 1. `r2n`

`r2n`은 RTL과 synthesis gate를 비교합니다.

의미:
- RTL이 합성되면서 기능이 바뀌지 않았는지 확인
- synthesis optimization, hierarchy 변화, constant propagation이 있어도 최종 기능은 유지되는지 확인

### 2. `n2n`

`n2n`은 synthesis gate와 DFT/post-DFT gate를 비교합니다.

의미:
- scan insertion 이후에도 기능 logic이 깨지지 않았는지 확인
- post-DFT hold ECO를 하고 나서도 기능이 유지되는지 확인

즉 이 프로젝트에서는 `n2n`이 특히 중요했습니다.

## 현재 입력 버전

현재 문서 기준으로 사용하는 버전은 아래와 같습니다.

### r2n

- reference: `0_rtl`
- implementation: `2_synthesis/2_output/4_15_8ns_ff/mapped/soc_gate.v`

### n2n

- reference: `2_synthesis/2_output/4_15_8ns_ff/mapped/soc_gate.v`
- implementation: `3_DFT/2_output/4_15_8ns_ff_holdfix_tcl6/aes_128_internal.v`

즉 post-DFT ECO까지 끝난 최종 netlist를 기준으로 `n2n`을 확인한 상태입니다.

## 현재 스크립트 구조

- [run_r2n.csh](run_r2n.csh)
  - 기본 `ver=4_15_8ns_ff`
  - `lib_corner` 지원
  - synthesis gate 존재 여부를 먼저 확인
- [run_n2n.csh](run_n2n.csh)
  - `ref_ver=4_15_8ns_ff`
  - `impl_ver=4_15_8ns_ff_holdfix_tcl6`
  - `lib_corner` 지원
  - reference/implementation netlist 존재 여부를 먼저 확인
- [FM_r2n_script.tcl](0_script/r2n/FM_r2n_script.tcl)
  - reference RTL은 `../0_rtl` 기준으로 읽음
  - `aes128_core_rewrite.v`까지 포함
  - library는 `lib_corner` 기준으로 선택
- [FM_n2n_script.tcl](0_script/n2n/FM_n2n_script.tcl)
  - `ref_ver`와 `impl_ver`를 분리해서 읽음
  - post-DFT ECO netlist까지 비교 가능

## 실제로 겪었던 문제와 수정 방법

### 1. 예전 스크립트는 최신 RTL 변경과 버전 체계를 충분히 반영하지 못했다

문제:
- `r2n` script가 `../2_synthesis/1_input/rtl` 기준으로 RTL을 읽고 있었습니다.
- 하지만 현재 프로젝트에서는 `0_rtl`이 기준 RTL이며, `aes128_core_rewrite.v` 같은 실제 변경이 `0_rtl`에 반영돼 있었습니다.

수정:
- `FM_r2n_script.tcl`의 reference RTL 입력을 `../0_rtl` 기준으로 변경
- `aes128_core_rewrite.v`를 reference RTL 목록에 포함

의미:
- 실제 현재 RTL과 합성 gate를 비교하게 정리

### 2. n2n은 synthesis baseline과 ECO implementation 버전을 따로 받아야 했다

문제:
- 예전 구조는 `ver` 하나로 reference와 implementation을 동시에 결정하는 방식이었습니다.
- 하지만 현재는
  - synthesis baseline `4_15_8ns_ff`
  - post-DFT ECO implementation `4_15_8ns_ff_holdfix_tcl6`
  처럼 두 버전이 다릅니다.

수정:
- `run_n2n.csh`와 `FM_n2n_script.tcl`을 `ref_ver` / `impl_ver` 분리형으로 수정

의미:
- synthesis gate와 post-DFT ECO gate를 자연스럽게 비교할 수 있게 됨

### 3. `scan_out`는 functional n2n에서 그대로 비교하면 false fail이 날 수 있었다

문제:
- pre-DFT에서는 `scan_out`가 사실상 비활성/상수 포트처럼 보일 수 있고,
- post-DFT에서는 실제 scan chain의 `ScanDataOut`으로 재사용됩니다.
- 따라서 functional equivalence 관점에서 `scan_out`를 그대로 compare하면 불필요한 fail이 날 수 있습니다.

수정:
- `FM_n2n_script.tcl`에서
  - `r:/WORK/.../scan_out`
  - `i:/WORK/.../scan_out`
  을 `dont_verify_point`로 처리

관련 설명:
- [N2N_SCAN_OUT_DONT_VERIFY_NOTE.md](N2N_SCAN_OUT_DONT_VERIFY_NOTE.md)

의미:
- scan chain test output은 compare 대상에서 제외하고
- functional logic equivalence만 확인

### 4. 라이브러리 corner와 gate netlist interpretation을 맞춰야 했다

문제:
- gate-level Formality에서는 사용한 stdcell/PLL/SRAM db를 읽지 않으면 black-box나 unresolved 문제가 생길 수 있습니다.

수정:
- `lib_corner`를 받아서 해당 corner 라이브러리를 읽도록 정리
- 현재 기본은 `ff`

## 현재 최종 결과

### 1. `r2n_4_15_8ns_ff`

결과:
- PASS
- unmatched 없음
- failing 없음
- aborted 없음
- unverified 없음

근거:
- [unmatched_points_post_matching.rpt](4_report/r2n_4_15_8ns_ff/unmatched_points_post_matching.rpt)
- [failing_points.rpt](4_report/r2n_4_15_8ns_ff/failing_points.rpt)
- [aborted_points.rpt](4_report/r2n_4_15_8ns_ff/aborted_points.rpt)
- [unverified_points.rpt](4_report/r2n_4_15_8ns_ff/unverified_points.rpt)
- 로그는 실행 환경에서 생성되지만 repo에는 항상 포함되지 않을 수 있습니다.

추가 해석:
- `scan_out`는 reference 쪽에서 `dont_verify` 처리됨
- black-box report에는 SRAM macro가 보이는데, 이는 현재 flow에서 정상입니다
- RTL interpretation warning `FMR_ELAB-059` (`!==`)는 있었지만, 최종 verification은 성공했습니다

### 2. `n2n_4_15_8ns_ff_holdfix_tcl6`

결과:
- PASS
- unmatched 없음
- failing 없음
- aborted 없음
- unverified 없음

근거:
- [unmatched_points_post_matching.rpt](4_report/n2n_4_15_8ns_ff_holdfix_tcl6/unmatched_points_post_matching.rpt)
- [failing_points.rpt](4_report/n2n_4_15_8ns_ff_holdfix_tcl6/failing_points.rpt)
- [aborted_points.rpt](4_report/n2n_4_15_8ns_ff_holdfix_tcl6/aborted_points.rpt)
- [unverified_points.rpt](4_report/n2n_4_15_8ns_ff_holdfix_tcl6/unverified_points.rpt)
- 로그는 실행 환경에서 생성되지만 repo에는 항상 포함되지 않을 수 있습니다.

추가 해석:
- `scan_out`는 reference/implementation 양쪽 모두 `dont_verify`
- 즉 DFT inserted gate와 post-DFT ECO gate의 functional equivalence는 유지됐다고 볼 수 있습니다

## 이 단계 결과의 의미

현재 기준으로는 아래가 모두 성립합니다.

1. RTL ↔ synthesis gate equivalence 성립
2. synthesis gate ↔ post-DFT ECO gate equivalence 성립

즉:
- 합성은 기능을 깨지 않았고
- DFT insertion도 기능을 깨지 않았고
- post-DFT hold ECO도 기능을 깨지 않았습니다

이건 포트폴리오 관점에서 매우 중요한 결과입니다.  
단순히 STA가 clean한 것만이 아니라, **그 clean한 netlist가 원래 기능과 등가임을 Formality로 확인했다**는 뜻이기 때문입니다.

## 이 단계의 결론

현재 `5_FM` 기준 결론은 아래 한 줄로 요약할 수 있습니다.

`RTL -> synthesis -> DFT -> post-DFT ECO`까지 이어진 전체 흐름이 기능 등가성을 유지한 채 마무리되었다.

## 기억이 안 날 때 먼저 볼 파일

나중에 FM 쪽이 기억 안 나면 아래부터 보면 됩니다.

1. [run_r2n.csh](run_r2n.csh)
2. [run_n2n.csh](run_n2n.csh)
3. [FM_r2n_script.tcl](0_script/r2n/FM_r2n_script.tcl)
4. [FM_n2n_script.tcl](0_script/n2n/FM_n2n_script.tcl)
5. [N2N_SCAN_OUT_DONT_VERIFY_NOTE.md](N2N_SCAN_OUT_DONT_VERIFY_NOTE.md)

## 함께 보면 좋은 README

- RTL: [0_rtl/README.md](../0_rtl/README.md)
- 합성: [2_synthesis/README.md](../2_synthesis/README.md)
- DFT: [3_DFT/README.md](../3_DFT/README.md)
- 최종 STA: [4_STA/README.md](../4_STA/README.md)
