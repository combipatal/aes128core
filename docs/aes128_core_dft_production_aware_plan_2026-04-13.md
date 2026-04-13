# aes128_core DFT Production-Aware Baseline Plan

## Requirements Summary

이 계획의 목적은 `aes128_core`의 현재 DFT 흐름을 **학습용 single-scan baseline**에서 **실무형 production-aware baseline**으로 끌어올리는 것이다.

이 계획은 아래 전제를 기준으로 작성한다.

- RTL baseline source of truth는 `0_rtl/`이다.
- synthesis / DFT / STA / FM는 앞으로 모두 이 baseline에서 다시 생성되어야 한다.
- 현재 최신 signoff-style artifact baseline은 `4_13_7p3ns`이며, 이 버전은 `GTECH_` 제거 후의 clean baseline으로 간주한다.

현재 DFT baseline의 핵심 상태는 다음과 같다.

- single scan chain `1`개: `/aes128_core/3_DFT/4_report/4_13_7p3ns/scan_config_internal.rpt`
- chain length `1532`: `/aes128_core/3_DFT/4_report/4_13_7p3ns/scan_chains_internal.rpt`
- dedicated scan out port 생성 안 함: `/aes128_core/3_DFT/4_report/4_13_7p3ns/scan_config_internal.rpt`
- `scan_out` 기존 포트를 그대로 `ScanDataOut`로 재사용: `/aes128_core/3_DFT/4_report/4_13_7p3ns/dft_signals_internal.rpt`
- post-DFT DRC에 `Clock connected to primary output (C17)`가 남아 있음: `/aes128_core/3_DFT/4_report/4_13_7p3ns/insert_drc_internal.dft`
- `u_ctrl/u_icg_aes/en_lat_reg` constant-1 경고가 남아 있음: `/aes128_core/3_DFT/4_report/4_13_7p3ns/pre_drc_verbose.rpt`
- unknown model 경고는 `u_pll`, `u_mem_u_sram`에 대해 남아 있음: `/aes128_core/3_DFT/4_report/4_13_7p3ns/pre_drc_verbose.rpt`
- post-DFT hold violation `12`개가 여전히 존재: `/aes128_core/3_DFT/4_report/4_13_7p3ns/dft_qor_internal.rpt`
- FM r2n / n2n PASS 유지: `/aes128_core/5_FM/3_log/r2n_4_13_7p3ns.log`, `/aes128_core/5_FM/3_log/n2n_4_13_7p3ns.log`

즉 현재 상태는:

> DFT 삽입 자체는 성공했고 학습용 흐름으로는 충분하지만, 테스트 시간, 포트 재사용, DRC hygiene, scan architecture, downstream signoff explainability 측면에서는 production-aware라고 보기 어렵다.

## Current State

### What Exists Today

현 스크립트는 아래 방식으로 동작한다.

- scan clock는 `ref_clk`
- scan enable은 `scan_en`
- test mode는 `test_mode`
- scan in/out은 `scan_in`, `scan_out`
- chain count는 `1`
- style은 `multiplexed_flip_flop`
- internal clocks는 `none`

근거:

- `/aes128_core/3_DFT/0_script/DFT_script.tcl`

현재 설정의 핵심 라인:

- `set_scan_configuration -test_mode all -chain_count 1`
- `set_scan_configuration -test_mode all -style multiplexed_flip_flop`
- `set_scan_configuration -test_mode all -internal_clocks none`
- `set_dft_signal -view spec -type ScanDataOut -port scan_out`

### Why It Is Good Enough For Learning

- 구조가 단순해서 디버깅이 쉽다.
- scan chain이 하나라 리포트 해석이 직관적이다.
- FM n2n까지 연결하기 쉽다.
- DFT bring-up 중 어디서 깨지는지 추적하기 좋다.

### Why It Is Not Production-Aware Yet

1. **single chain 1532**는 테스트 시간이 길다.
2. **기존 `scan_out` 포트 재사용**은 기능/테스트 intent를 흐린다.
3. **clock connected to primary output** 경고는 top IO intent가 깨끗하지 않다는 신호다.
4. **ICG latch constant-1 / non-scannable**는 현재는 설명 가능한 경고지만, production baseline에서는 더 적극적으로 관리해야 한다.
5. **unknown model macro 경고**는 black-box methodology로 묶어 관리돼야 한다.
6. **post-DFT hold 12개**가 남아 있어 DFT 결과를 signoff baseline으로 부르기 어렵다.

## Why This Upgrade Is Needed

### 1. Test Cost

single chain은 학습에는 단순하지만 ATE shift time, test application time, 패턴 효율 면에서 불리하다.

### 2. Intent Separation

현재 `scan_out`는 DFT 이후 test output 역할을 맡지만 dedicated port를 새로 만들지 않는다.
이 방식은 학습용으로는 이해하기 쉽지만, 실제 제품 인터페이스에서는 기능 포트와 테스트 포트를 더 명확히 분리하는 편이 안전하다.

### 3. DRC Hygiene

현재 남은 경고들 중 일부는 “자연스러운 경고”로 설명 가능하지만, production-aware baseline에서는

- 어떤 경고는 허용
- 어떤 경고는 제거
- 어떤 경고는 구조 변경 필요

로 분류되어야 한다.

### 4. Downstream Correlation

DFT 구조가 달라지면 STA / FM / ATPG / top-level IO plan이 다 같이 영향을 받는다.
그래서 DFT를 production-aware로 올리는 작업은 단순 chain count 조정이 아니라 **baseline methodology 정리**에 가깝다.

## Decision Drivers

1. 테스트 시간과 구조 단순성의 균형
2. top-level test interface의 명확성
3. STA/FM로 이어지는 설명 가능성

## Viable Options

### Option A. 현 single-chain 구조 유지

접근:

- chain count `1` 유지
- 기존 `scan_out` 재사용 유지
- 경고는 문서화하고 hold만 닫음

장점:

- 변경 범위 최소
- 기존 학습 artifact와 continuity 좋음

단점:

- production-aware 개선 효과 낮음
- test cost와 IO intent 문제가 그대로 남음

### Option B. multi-chain으로 전환하되 compression은 하지 않음

접근:

- chain count를 `2` 이상으로 늘림
- 가능하면 dedicated scan-out port 생성 검토
- scan IO / STA / FM / top port contract를 같이 재정의

장점:

- 구조는 아직 단순함
- test time 개선
- production baseline으로 설명하기 쉬움

단점:

- 포트/리포트/FM/STA 모두 다시 봐야 함

### Option C. compression까지 포함한 더 공격적인 production DFT

접근:

- scan compression, 추가 control signal, 더 복잡한 DFT topology 도입

장점:

- 실제 제품형에 가장 가까움

단점:

- 현재 프로젝트 단계에 비해 너무 크고 리스크 큼
- STA/FM/ATPG 설명 비용 급증

## Recommended Decision

**Option B**를 권장한다.

즉:

- **multi-chain 전환**
- **dedicated scan-out port 검토**
- **compression은 아직 하지 않음**

이유:

1. 학습용 단순성을 어느 정도 유지하면서 production-aware 개선을 시작하기 좋다.
2. 현재 프로젝트 규모에서는 compression까지 가는 것보다 multi-chain만으로도 충분히 큰 개선이다.
3. STA/FM/IO 영향 범위를 아직 사람이 설명할 수 있는 수준에 둔다.

## Acceptance Criteria

1. DFT chain count가 `1`보다 커진다.
2. scan chain length 분포가 리포트에 명확히 나타난다.
3. `scan_out` 재사용 여부를 명시적으로 결정하고, 필요 시 dedicated port를 도입한다.
4. post-DFT DRC 경고를 허용/미허용으로 분류한 표가 존재한다.
5. post-DFT STA func/capture/shift가 다시 생성되고 결과가 문서화된다.
6. n2n FM가 새 DFT topology에서도 PASS한다.
7. README/DFT 문서가 최신 baseline 버전과 구조를 반영한다.

## Implementation Steps

### Step 1. DFT IO policy 확정

작업:

- `scan_in`, `scan_out` 기존 재사용을 유지할지 결정
- dedicated `scan_out` 추가 여부 결정
- top-level functional/debug/test output을 분리할지 결정

왜:

- 현재 `scan_out` 재사용은 학습용으론 충분하지만 production-aware intent는 약하다.

### Step 2. chain architecture 재설계

작업:

- `chain_count 1`을 `2` 이상으로 올리는 실험 계획 수립
- chain balancing 기준 정의
- lockup latch 정책 유지 여부 검토

왜:

- 1532-depth single chain은 테스트 시간 관점에서 불리하다.

### Step 3. clock-gating / non-scannable 정책 정리

작업:

- `u_ctrl/u_icg_aes/en_lat_reg` 경고를 허용 경고로 둘지, explicit clock-gating test hookup으로 정리할지 결정
- 주석 처리된 `set_dft_configuration -connect_clock_gating enable` 경로를 재검토

왜:

- 지금 경고는 설명은 가능하지만 production baseline에선 방치보다 정책화가 중요하다.

### Step 4. macro black-box policy 정리

작업:

- `u_pll`, `u_mem_u_sram` unknown model 경고를 공식 허용 항목으로 문서화
- DFT pre/post DRC에서 허용 경고 리스트를 정의

왜:

- 이 경고 자체를 없애는 게 아니라, 의도된 black-box로 명시하는 것이 중요하다.

### Step 5. DFT rerun matrix 정의

작업:

- baseline RTL에서
  - synthesis
  - DFT
  - STA func/capture/shift
  - FM n2n
를 다시 생성하는 matrix 작성

왜:

- DFT 구조를 바꾸면 뒤 단계 검증도 세트로 다시 돌아야 한다.

### Step 6. post-DFT STA/hold 정책 수립

작업:

- multi-chain 전환 후 hold 12개가 유지/악화/개선되는지 비교
- func/capture/shift 모두에서 동일 path인지 확인

왜:

- production-aware baseline은 단순 chain 구조보다 timing closure 관점이 중요하다.

### Step 7. 문서/기준선 업데이트

작업:

- `3_DFT/README.md` 최신 상태 반영
- 현재 README의 baseline 설명과 일치시키기
- DFT 경고 분류표 추가

왜:

- 현재 `3_DFT/README.md`는 최신 기준을 `4_11_6_7ns`로 적고 있어 이미 stale하다.

## Risks And Mitigations

- 리스크: chain 수 증가로 STA hold가 악화될 수 있다.
  대응: func/capture/shift STA를 항상 세트로 비교한다.

- 리스크: dedicated scan-out port 추가 시 FM/n2n compare 기준이 바뀔 수 있다.
  대응: n2n `dont_verify` 정책을 새 구조에 맞게 다시 문서화한다.

- 리스크: clock-gating 관련 DFT hookup 변경이 기능 path를 교란할 수 있다.
  대응: DFT 변경 후 VCS smoke + FM n2n + func STA를 함께 확인한다.

## Verification Steps

1. DFT rerun 후 `scan_config_internal.rpt`에서 chain count 확인
2. `scan_chains_internal.rpt`에서 chain 길이 분포 확인
3. `insert_drc_internal.dft`에서 경고 분류 확인
4. post-DFT `dft_qor_internal.rpt`에서 setup/hold 확인
5. STA `func`, `capture`, `shift` 재실행
6. FM `n2n` PASS 확인
7. 필요 시 `r2n`도 baseline consistency 확인

## Difficulty Assessment

- 필요성: **높음**
- 긴급성: **중간**
- 난이도: **중상**

이유:

- DFT만 건드는 것처럼 보여도 top IO, STA, FM, 문서 기준선이 같이 흔들린다.
- 다만 compression까지 가지 않으면 관리 가능한 범위다.

## Short Recommendation

다음 풀랜은 아래 순서가 가장 안전하다.

1. baseline RTL / synthesis input source of truth를 고정
2. chain count를 `1 -> 2+`로 올리는 small-step 실험
3. `scan_out` 재사용 vs dedicated port 결론
4. DRC 경고 분류표 작성
5. STA / FM 재검증

핵심은 “더 복잡한 DFT”가 아니라,

> 지금 구조를 설명 가능한 production-aware baseline으로 바꾸는 것

이다.
