# aes128_core Interface Separation Plan

## Requirements Summary

이 계획의 목적은 `aes128_core`에서 **sim-only external AES vector interface**와 **synth/production interface**를 분리하는 것이다.

대상 신호:

- `aes_key_ext`
- `aes_pt_ext`
- `aes_vec_valid`

현재 구조에서는 위 세 신호가 top과 control block의 정식 포트로 존재하지만, 실제 사용은 simulation define 아래에만 묶여 있다.

근거:

- top에 항상 포트가 존재함: [top_mcu_pll_sram_multiclk_soc.v](../0_rtl/top_mcu_pll_sram_multiclk_soc.v)
- `soc_ctrl_multiclk_soc`에도 항상 포트가 존재함: [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v)
- 실제 load/use는 `SIM_EXTVEC` 아래에서만 발생함: [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v)
- testbench는 이 포트들을 직접 drive함: [tb_top_mcu_pll_sram_multiclk_soc.sv](../1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv)

그 결과 synthesis `check_design`에는 대량 `LINT-28`이 남아 있다:

- `Unconnected ports (LINT-28) 260`: [aes_chk_design.rpt](../2_synthesis/4_report/4_13_7p3ns/aes_chk_design.rpt)
- `aes_key_ext[*]`, `aes_pt_ext[*]`가 대량으로 report됨: [aes_chk_design.rpt](../2_synthesis/4_report/4_13_7p3ns/aes_chk_design.rpt)

즉 현재 문제는 “기능이 안 돌아간다”가 아니라,

> 실제 제품 인터페이스와 testbench 편의용 인터페이스가 한 RTL 계층에 섞여 있어서 synthesis lint와 intent clarity를 해친다

로 정리할 수 있다.

## Root Cause

### 1. Interface intent mismatch

지금 RTL은 product top에 다음 두 종류의 인터페이스가 섞여 있다.

- 실제 SoC/DFT/clock/reset I/O
- testbench가 known-answer vector를 넣기 위한 simulation 편의용 I/O

그런데 두 번째 종류가 실제 synth top의 정식 포트로 남아 있다.

### 2. Compile-time conditional use

`aes_key_ext`, `aes_pt_ext`, `aes_vec_valid`는 always-on 포트이지만 실제 functional selection은 아래 블록에서만 이뤄진다.

```verilog
`ifdef SIM_EXTVEC
  if (aes_vec_valid) begin
    aes_key <= aes_key_ext;
    aes_pt  <= aes_pt_ext;
    ...
  end
`endif
```

근거: [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v)

즉 synthesis build에서 `SIM_EXTVEC`가 없으면 이 포트들은 구조적으로 dead input이 된다.

### 3. TB convenience leaked into production top

TB는 벡터 입력을 위해 DUT top에 직접 external AES 포트를 연결하고 있다:

- [tb_top_mcu_pll_sram_multiclk_soc.sv](../1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv)

이 방식은 TB 입장에서는 간단하지만, product RTL 입장에서는 simulation-specific ingress가 permanent interface로 남게 된다.

## Why This Matters

### 1. Lint noise reduction

현재 `LINT-28` 260개 중 큰 비중이 이 sim-only vector 포트에서 나온다.

이 상태를 방치하면:

- 진짜 중요한 lint를 묻어버림
- `check_design`를 신뢰하기 어려워짐
- 이후 새 경고가 생겨도 원인 분리가 어려워짐

### 2. Intent clarity

실무에서는 top interface가 아래 중 무엇인지 분명해야 한다.

- chip/package/SoC integration용 포트
- DFT/test mode용 포트
- simulation injection용 포트

지금 구조는 이 세 가지를 명확히 분리하지 못한다.

### 3. Downstream flow hygiene

이 문제는 단순 synthesis lint만의 문제가 아니다.

- FM 해석 시 simulation define 의존성이 남음
- integration 시 외부에서 이 포트를 실제 제품 포트로 오해할 수 있음
- 문서/테스트벤치/RTL intent가 어긋남

## Design Options

### Option A. TB wrapper 분리

접근:

- production top에서는 `aes_key_ext`, `aes_pt_ext`, `aes_vec_valid` 제거
- testbench 전용 wrapper module을 따로 만들고, wrapper 안에서 DUT에 default vector 또는 injected vector를 연결

장점:

- product RTL intent가 가장 깨끗함
- synthesis lint 감소 효과가 가장 큼
- simulation-only 기능이 product hierarchy 밖으로 이동함

단점:

- TB 인스턴스 대상 변경 필요
- wrapper 추가와 filelist 수정 필요

평가:

- **권장안**

### Option B. Same top, parameterized simulation ingress

접근:

- top 포트는 유지하되, parameter나 generate를 통해 sim mode에서만 enable

장점:

- top/TB 구조 변화가 상대적으로 작음

단점:

- product top에 simulation-specific 포트가 계속 남음
- lint와 intent clarity 문제를 완전히 해결하지 못함

평가:

- 임시 절충안

### Option C. Current structure 유지

접근:

- 현재 구조 유지
- lint만 문서로 무시 처리

장점:

- 구현 비용 거의 없음

단점:

- root cause 해결 안 됨
- 이후 유지보수/설명 비용 지속

평가:

- 비권장

## Recommended Decision

**Option A: TB wrapper 분리**를 권장한다.

이유:

1. product RTL과 simulation-only behavior를 가장 명확히 분리한다.
2. synth/FM/STA 관점에서 intent가 가장 방어 가능하다.
3. 지금 프로젝트는 학습용이지만 이미 FM/STA까지 보고 있으므로, 이 정도 hygiene는 가져가는 것이 맞다.

## Acceptance Criteria

1. production top에서 `aes_key_ext`, `aes_pt_ext`, `aes_vec_valid`가 제거되거나, 최소한 synthesis 대상 계층에서 제거된다.
2. testbench는 wrapper 또는 별도 simulation adapter를 통해 기존 3개 test case를 그대로 구동한다.
3. synthesis `check_design`에서 sim-only vector 관련 `LINT-28`이 제거된다.
4. VCS regression `default_nist`, `ext_zero`, `ext_ecb_nist`가 모두 PASS한다.
5. synthesis / STA / FM가 기존 baseline 기능을 유지한다.

## Implementation Steps

### Step 1. Production boundary 정의

대상:

- [top_mcu_pll_sram_multiclk_soc.v](../0_rtl/top_mcu_pll_sram_multiclk_soc.v)
- [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v)

작업:

- production top에서 유지할 실제 인터페이스를 확정한다.
- `aes_key_ext`, `aes_pt_ext`, `aes_vec_valid`를 product interface에서 제거 대상으로 표기한다.
- 동시에 `clk_fast/div2/div4/div8` output도 product interface인지 debug interface인지 재확인한다.

산출물:

- interface ownership 표

### Step 2. Simulation adapter 구조 선택

대상:

- [tb_top_mcu_pll_sram_multiclk_soc.sv](../1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv)

작업:

- TB가 직접 DUT production top을 물지 않고, simulation wrapper를 물도록 구조를 정한다.
- wrapper 역할:
  - testcase별 external vector load
  - default vector path / ext vector path 선택
  - DUT에 전달될 내부 `aes_key`, `aes_pt`, `use_ext` 형태로 normalize

산출물:

- wrapper interface definition

### Step 3. Control block 내부 조건부 로직 정리

대상:

- [soc_ctrl_multiclk_soc.v](../0_rtl/soc_ctrl_multiclk_soc.v)

작업:

- `SIM_EXTVEC` define 의존 block을 제거하거나, simulation wrapper가 선택을 끝낸 값을 받도록 리팩터링한다.
- synth path에서 dead input이 생기지 않게 한다.

권장 방향:

- product RTL 안에서는 `if (use_ext_vec)` 같은 product-defined behavior만 남기고
- compile-time `ifdef SIM_EXTVEC`에 product behavior가 묶이지 않게 한다.

### Step 4. TB/filelist 연결 수정

대상:

- [tb_top_mcu_pll_sram_multiclk_soc.sv](../1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv)
- [filelist.f](../1_vcs/0_script/filelist.f)

작업:

- wrapper file 추가
- filelist 반영
- testcase loader는 기존 plusarg contract를 유지

목표:

- 기존 regression 사용성은 그대로 유지

### Step 5. Lint and equivalence verification

대상:

- [aes_chk_design.rpt](../2_synthesis/4_report/4_13_7p3ns/aes_chk_design.rpt)

작업:

- `check_design` 재실행
- `LINT-28`가 얼마나 줄었는지 비교
- VCS regression, synthesis, STA func, FM r2n/n2n 최소 재검증

## Risks And Mitigations

- 리스크: TB wrapper 도입 후 regression이 깨질 수 있음
  대응: testcase plusarg / summary log / waveform interface는 그대로 유지한다.

- 리스크: product top interface 변경이 기존 문서와 어긋날 수 있음
  대응: README와 plan 문서를 함께 갱신한다.

- 리스크: sim-only logic를 product RTL 밖으로 빼면서 default vector path가 바뀔 수 있음
  대응: `default_nist`, `ext_zero`, `ext_ecb_nist`를 모두 golden regression으로 유지한다.

## Verification Steps

1. VCS:
   - `default_nist` PASS
   - `ext_zero` PASS
   - `ext_ecb_nist` PASS
2. synthesis:
   - `check_design`에서 sim-only vector 관련 `LINT-28` 감소 확인
3. STA:
   - func scenario baseline 유지
4. FM:
   - r2n PASS 유지
   - n2n PASS 유지

## Difficulty Assessment

- 필요성: **높음**
- 긴급성: **중간**
- 난이도: **중간**

이유:

- 기능 자체를 새로 만드는 작업은 아니어서 알고리즘 난도는 낮다.
- 하지만 top interface, control RTL, TB, filelist, 문서를 함께 건드려야 해서 변경면은 넓다.
- 특히 “simulation 편의 기능을 어디 계층으로 보낼지”를 명확히 정해야 하므로 설계 intent 판단이 필요하다.

## Short Recommendation

이 작업은 지금 당장 hold closure보다 먼저가 아니라, **clean baseline 확보 이후 바로 들어가야 하는 hygiene 작업**이다.

권장 순서는:

1. production top에서 external AES vector interface 제거
2. simulation wrapper 도입
3. TB를 wrapper 기준으로 재연결
4. `check_design` lint 감소 확인

가장 좋은 방향은 product RTL을 더 단순하고 방어 가능하게 만들고, simulation 편의 기능은 TB/wrapper 쪽으로 보내는 것이다.
