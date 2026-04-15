# 2_synthesis

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`에 대한 Synopsys Design Compiler 합성 워크스페이스입니다. 이 프로젝트에서 합성은 단순히 gate netlist를 만드는 단계가 아니라, 이후 `3_DFT`, `4_STA`, `5_FM`, `ATPG`의 기준이 되는 baseline netlist와 SDC를 만드는 단계입니다.

포트폴리오 관점에서 보면 이 디렉터리의 핵심은 아래 세 가지입니다.

- 어떤 구조와 제약으로 합성을 진행했는가
- 실제로 어떤 timing / DRC / lint 문제를 겪었는가
- 그 문제를 어떤 방식으로 수정했고, 최종 baseline은 무엇인가

## 이 단계의 역할

전체 흐름에서 `2_synthesis`는 아래 위치에 있습니다.

1. `0_rtl`
   - RTL 작성 및 구조 정리
2. `2_synthesis`
   - Design Compiler로 mapped netlist와 synthesis SDC 생성
3. `3_DFT`
   - scan insertion
4. `4_STA`
   - post-DFT pre-layout STA
5. `5_FM`
   - RTL vs synth, synth vs DFT formal check
6. ATPG

즉 합성 결과가 흔들리면 이후 단계도 같이 흔들립니다. 그래서 이 디렉터리에서는 단순 QoR보다 “후속 단계에서 계속 쓸 수 있는 clean baseline 확보”가 더 중요했습니다.

## 디렉터리 구성

- `0_script/synthesis_script.tcl`
  - 메인 합성 스크립트
- `1_input/constraint/constraint.con`
  - synthesis 제약 파일
- `2_output/$ver/unmapped/`
  - elaborate/link 직후 DDC/Verilog
- `2_output/$ver/mapped/`
  - 최종 mapped DDC/Verilog/SDC
- `3_log/${ver}_syn_dc.log`
  - DC 실행 로그
- `4_report/$ver/`
  - `aes_chk_design.rpt`, `qor.rpt`, `timing.rpt`, `area.rpt`, `constraint.rpt`, `clock.rpt`
- `run.csh`
  - 기본 버전과 clock period를 설정해서 합성을 실행하는 wrapper

## 실행 방법

현재 [run.csh](run.csh)의 기본값은 아래와 같습니다.

```csh
if ( ! $?ver ) setenv ver 4_15_8ns_ff
if ( ! $?clk_period ) setenv clk_period 8
mkdir -p 3_log
source ../.synopsys_dc.setup
dc_shell -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
```

실행 예시:

```bash
cd ./2_synthesis
csh run.csh
env ver=4_13_7p3ns clk_period=7.3 csh run.csh
env ver=4_15_8ns_ff clk_period=8 csh run.csh
```

## 스크립트 동작 요약

[synthesis_script.tcl](0_script/synthesis_script.tcl)은 아래 순서로 동작합니다.

1. `env(ver)` 기준으로 output/report 디렉터리를 생성합니다.
2. RTL을 `analyze`하고 `top_mcu_pll_sram_multiclk_soc`를 `elaborate`/`link`합니다.
3. `check_design` 결과를 `aes_chk_design.rpt`로 저장합니다.
4. unmapped DDC/Verilog를 저장합니다.
5. `constraint.con`을 source합니다.
6. top-level flat wire-load model(`ForQA`)을 설정합니다.
7. latch 계열 셀을 `dont_use` 처리합니다.
8. `u_mem/u_sram`, `u_pll`은 `dont_touch`로 유지합니다.
9. input/output path grouping과 multiple-port-net 정리를 수행합니다.
10. hierarchy 제어 후 `compile_ultra -scan`과 incremental compile을 반복 수행합니다.
11. QoR, timing, area, constraint, clocks 리포트를 생성합니다.
12. mapped DDC/Verilog와 `soc_func.sdc`를 출력합니다.

## 현재 제약 파일 핵심

[constraint.con](1_input/constraint/constraint.con)에는 아래 항목이 들어 있습니다.

- primary clock: `ref_clk`
- generated clocks:
  - `clk_fast`
  - `clk_fast_aes`
  - `clk_div2`
  - `clk_div4`
  - `clk_div8`
- case analysis:
  - `scan_en = 0`
  - `test_mode = 0`
- input delay:
  - `start`
  - `aes_vec_valid`
  - `uart_rxd`
- output delay:
  - `done`
  - `pass`
  - `uart_txd`
- false path:
  - `clk_fast`
  - `clk_div2`
  - `clk_div4`
  - `clk_div8`
  - `scan_out`

이 제약 파일에서 만들어진 `soc_func.sdc`가 이후 `3_DFT`, `4_STA`, `2.5_STA`에서 기준 SDC로 사용됩니다.

## 실제로 겪었던 문제와 수정 방법

### 1. DC/PT correlation이 불안정했고 `clk_fast_aes` margin이 너무 얇았다

문제:
- 기능적으로는 맞는데, `clk_fast_aes`가 매우 빡빡하게 보였습니다.
- 이전 버전들에서는 PT에서 marginal setup issue가 다시 보이거나, 합성 구조가 버전마다 너무 달라지는 문제가 있었습니다.

원인:
- AES 쪽이 과도하게 flatten/restructure되면 same-period, same-corner 비교가 어렵습니다.
- 반대로 hierarchy를 너무 많이 고정하면 `clk_fast_aes` 2ns domain 최적화 여지가 줄어듭니다.

수정:
- top-level `u_ctrl`는 보존하되, AES 내부는 더 자유롭게 최적화되도록 방향을 바꿨습니다.
- 현재 스크립트의 핵심은:
  - `set_ungroup [get_cells u_ctrl] false`
  - `set_ungroup [get_cells u_ctrl/u_icg_aes] false`
  - AES datapath는 내부적으로 restructured 가능

의미:
- controller-level 구조와 generated clock anchor는 유지
- AES 내부는 timing 회복을 위해 최적화 허용

결과:
- 현재 baseline에서는 `clk_fast_aes` setup이 clean으로 유지됩니다.
- 이후 `4_STA`에서도 동일한 방향으로 해석하기 쉽게 맞췄습니다.

### 2. wire-load model을 hierarchy별로 강하게 주던 방식이 후속 STA와 맞지 않았다

문제:
- 초기에는 hierarchy별 wire-load model을 강하게 주는 실험이 있었습니다.
- 이 방식은 일부 corner에서는 setup 해석을 비관적으로 만들거나, 후속 PrimeTime correlation을 복잡하게 만들었습니다.

수정:
- 현재 synthesis는 top-level flat wire-load model만 사용합니다.

적용 내용:

```tcl
set auto_wire_load_selection false
set_wire_load_mode top
set_wire_load_model -name ForQA [current_design]
```

의미:
- synthesis와 `2.5_STA`, `4_STA`의 pre-layout 해석 방향을 단순하게 맞춤
- cross-version 비교가 쉬워짐

### 3. custom ICG 경로와 generated clock anchor를 유지해야 했다

문제:
- AES clock gating 구조가 계속 바뀌면 `clk_fast_aes` generated clock 정의가 흔들립니다.
- DFT, STA에서 `u_ctrl/u_icg_aes/gclk`를 기준으로 clock를 다시 잡아야 하므로, 이 anchor가 깨지면 후속 단계가 복잡해집니다.

수정:
- `u_ctrl/u_icg_aes`는 hierarchy를 유지하도록 했습니다.

적용 내용:

```tcl
set_ungroup [get_cells u_ctrl/u_icg_aes] false
```

의미:
- `3_DFT`의 clock-gating hookup
- `2.5_STA`, `4_STA`의 generated clock 재생성
이 모두 같은 계층 이름을 기준으로 계속 동작할 수 있습니다.

### 4. `check_design` warning과 lint noise를 무조건 버그로 볼 수 없었다

문제:
- `check_design`에서는 constant-connected pin, unused-like warning, clock gating 관련 경고가 나왔습니다.
- 예전에는 이런 warning이 바로 RTL bug인지, 구조적 허용 경고인지 구분이 필요했습니다.

대표 예:
- `LINT-32`
- `LINT-60`
- ICG latch 관련 constant warning

해석:
- 모든 warning이 재합성 대상 bug는 아니었습니다.
- 특히 ICG 주변 상수 전파나 functional-only/test-only 경로는 허용 경고로 문서화하고 넘어가는 편이 맞았습니다.

의미:
- 이 단계에서는 `warning 개수`보다
  - mapped netlist clean 여부
  - generated clock 유지 여부
  - 후속 DFT/STA/FM 사용 가능 여부
  가 더 중요했습니다.

### 5. synthesis 단계에서 남은 실질 timing issue는 SRAM interface hold였다

문제:
- synthesis/STA를 거치며 가장 끝까지 남은 실질 timing issue는 SRAM interface hold였습니다.
- 이 문제는 이후 `4_STA`에서 post-DFT 기준으로 더 명확하게 추적됐습니다.

해결 방향:
- synthesis 제약으로 숨기지 않고,
- post-DFT ECO로 `u_ctrl -> SRAM macro input` short path를 늦추는 방향을 택했습니다.

즉 synthesis에서는:
- clean functional baseline 확보
- DFT/STA/FM에 쓸 netlist/SDC 확보
를 우선했고,
hold closure는 post-DFT ECO에서 마무리했습니다.

## 버전 실험 흐름

`4_report/`를 보면 이 프로젝트가 실제로 여러 버전을 거치며 수렴해 온 흔적이 남아 있습니다.

대표 버전 예시:

- `4_11_6_7ns`
- `4_11_7p3ns`
- `4_12_7p3ns`
- `4_13_7p3ns`
- `4_13_7p3ns_ff_fix1`
- `4_13_7p3ns_ff_fix2`
- `4_13_7p3ns_ff_fix3`
- `4_14_8ns_fix_F`
- `4_15_8ns_ff`

의미:
- 단순히 period sweep만 한 것이 아니라
- 구조, hierarchy, generated clock anchor, generic-cell 제거, 후속 flow 적합성까지 같이 보며 baseline을 다듬었습니다.

## 현재 최종 baseline

현재 synthesis 기준으로 가장 보기 좋은 baseline은 `4_15_8ns_ff`입니다.

이 버전의 의미:
- mapped netlist와 `soc_func.sdc`가 안정적으로 생성됨
- 이후 `3_DFT`와 `4_STA`로 연결 가능
- post-DFT ECO 전 baseline으로 사용 가능

후속 단계에서 실제로 사용된 연결:

- synthesis baseline:
  - `2_synthesis/2_output/4_15_8ns_ff/mapped/soc_gate.v`
  - `2_synthesis/2_output/4_15_8ns_ff/mapped/soc_gate.ddc`
  - `2_synthesis/2_output/4_15_8ns_ff/mapped/soc_func.sdc`
- DFT output:
  - `3_DFT/2_output/4_15_8ns_ff/aes_128_internal.v`
- post-DFT ECO final:
  - `3_DFT/2_output/4_15_8ns_ff_holdfix_tcl6/aes_128_internal.v`
- final STA result:
  - `4_STA/4_report/4_15_8ns_ff_holdfix_tcl6/...`

## 이 단계의 결과를 어떻게 해석하면 되는가

이 합성 단계에서 중요한 건 아래 네 가지입니다.

1. `soc_gate.v`, `soc_gate.ddc`, `soc_func.sdc`가 안정적으로 생성되는가
2. `clk_fast_aes` 같은 민감한 generated clock domain이 clean baseline으로 유지되는가
3. DFT/STA/FM이 같은 netlist 계층을 기준으로 계속 이어질 수 있는가
4. warning이 있더라도 실제 bug와 허용 경고를 구분해 해석했는가

즉 합성만 따로 보면 끝나는 작업이 아니라, 이후 flow 전체의 기준을 만든 단계라고 보는 게 맞습니다.

## 기억이 안 날 때 먼저 볼 파일

나중에 왜 이런 구조로 합성했는지 다시 확인해야 할 때는 아래를 먼저 보면 됩니다.

1. [synthesis_script.tcl](0_script/synthesis_script.tcl)
   - 현재 compile 전략과 hierarchy 제어가 들어 있음
2. `4_report/<ver>/qor.rpt`
   - setup/hold summary와 path group 상태 확인
3. `4_report/<ver>/aes_chk_design.rpt`
   - 구조 경고와 lint noise 확인
4. [aes128_core_fm_flow_plan_2026-04-12.md](../docs/aes128_core_fm_flow_plan_2026-04-12.md)
   - synthesis, DFT, STA, FM을 연결해서 어떻게 해석했는지 정리돼 있음
5. [4_STA/README.md](../4_STA/README.md)
   - post-DFT ECO까지 포함한 최종 결과가 정리돼 있음

## 함께 보면 좋은 README

- 실험용 STA: [2.5_STA/README.md](../2.5_STA/README.md)
- DFT: [3_DFT/README.md](../3_DFT/README.md)
- 최종 STA: [4_STA/README.md](../4_STA/README.md)
