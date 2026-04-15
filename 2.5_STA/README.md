# 2.5_STA

이 디렉터리는 versioned netlist에 대해 PrimeTime pre-layout STA를 돌리는 별도 워크스페이스입니다. 목적은 최종 signoff를 바로 내는 것이 아니라, `합성 버전별 비교`, `corner 비교`, `synth vs DFT netlist 비교`, `scenario 실험`을 분리해서 보기 쉽게 만드는 것입니다.

포트폴리오 관점에서 보면 `2.5_STA`는 다음 의미를 갖습니다.

- 같은 디자인을 여러 version/corner/netlist 소스로 비교하는 분석 환경
- `4_STA`로 들어가기 전에 실험적으로 constraint와 해석 방식을 다듬는 공간
- SDC/wire-load/generated-clock 문제를 정리해 PrimeTime 해석을 안정화한 과정

## 전체 흐름에서의 위치

이 프로젝트에서 `2.5_STA`는 아래 역할을 합니다.

1. `2_synthesis`
   - mapped netlist와 `soc_func.sdc` 생성
2. `3_DFT`
   - post-DFT netlist 생성
3. `2.5_STA`
   - synth/DFT netlist를 다양한 corner와 scenario로 비교
   - 해석 방식과 스크립트를 다듬음
4. `4_STA`
   - post-DFT 기준 최종 pre-layout STA 정리

즉 `2.5_STA`는 “실험용 비교/정리용 PrimeTime 공간”이고, `4_STA`는 “최종 결론을 내는 PrimeTime 공간”에 가깝습니다.

## 입력과 출력

기본 입력은 `net_source`에 따라 달라집니다.

- `net_source=synth`
  - netlist: `../2_synthesis/2_output/${ver}/mapped/soc_gate.v`
  - SDC: `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`
- `net_source=dft`
  - netlist: `../3_DFT/2_output/${ver}/aes_128_internal.v`
  - SDC: `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`

출력은 아래 구조로 저장됩니다.

- 로그: `3_log/${ver}_${net_source}_${sta_scenario}_${mode}_${corner}_sta.log`
- 리포트: `4_report/${ver}/${net_source}/${scenario}/...`

## 실행 방법

현재 [run.csh](run.csh)의 기본값은 아래와 같습니다.

```csh
if ( ! $?ver ) setenv ver 4_15_8ns_ff
if ( ! $?corner ) setenv corner ff
if ( ! $?mode ) setenv mode synthcmp
if ( ! $?sta_scenario ) setenv sta_scenario func
if ( ! $?run_mode ) setenv run_mode pre
if ( ! $?hier_mode ) setenv hier_mode top
if ( ! $?design_name ) setenv design_name top_mcu_pll_sram_multiclk_soc
if ( ! $?net_source ) setenv net_source synth
```

대표 실행 예시는 아래와 같습니다.

```bash
cd ./2.5_STA

env ver=4_15_8ns_ff corner=ss sta_scenario=func net_source=synth csh run.csh
env ver=4_15_8ns_ff corner=ff sta_scenario=func net_source=synth csh run.csh
env ver=4_15_8ns_ff corner=tt sta_scenario=func net_source=synth csh run.csh
```

DFT netlist 비교 예시:

```bash
env ver=4_15_8ns_ff corner=ss sta_scenario=func net_source=dft csh run.csh
```

scan scenario 예시:

```bash
env ver=4_15_8ns_ff corner=ss sta_scenario=scan_capture net_source=dft csh run.csh
env ver=4_15_8ns_ff corner=ss sta_scenario=scan_shift net_source=dft csh run.csh
```

## 현재 스크립트 구조

- [run.csh](run.csh)
  - `net_source=synth|dft`를 구분해서 입력 netlist를 선택
  - `func`, `scan_shift`, `scan_capture`에 따라 override 파일 선택
- [STA_script.tcl](0_script/STA_script.tcl)
  - `ss`, `ff`, `tt`, `ff1p16vn40c` corner 지원
  - synth/DDC가 남긴 wire-load 명령을 제거한 sanitized SDC 생성
  - `flat_forqa`와 `legacy_hier` 두 종류 wire-load policy 지원
  - custom ICG timing arc를 기본적으로 disable
- override 파일
  - [func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)
  - [scan_shift_sta.tcl](1_input/constraint/scan_shift_sta.tcl)
  - [scan_capture_sta.tcl](1_input/constraint/scan_capture_sta.tcl)

## 실제로 겪었던 문제와 수정 방법

### 1. synthesis SDC를 그대로 읽으면 cross-corner STA가 불안정했다

문제:
- synthesis가 쓴 SDC 안에는 source-corner 기준 wire-load 명령이 들어 있습니다.
- 이 상태로 PT에서 corner를 바꿔 읽으면, missing library나 불필요한 correlation noise가 생기기 쉬웠습니다.

수정:
- `STA_script.tcl`에서 `set_wire_load_mode`, `set_wire_load_model` 줄을 제거한 `soc_func.sdc.sanitized`를 생성한 뒤 읽도록 했습니다.

의미:
- synthesis SDC는 유지하면서도, STA 쪽에서 wire-load policy를 따로 통제할 수 있게 됐습니다.
- 실험용 corner sweep이 쉬워졌습니다.

### 2. hierarchy wire-load와 flat wire-load 중 어떤 해석이 맞는지 비교가 필요했다

문제:
- 예전에는 hierarchy별 wire-load가 PT 해석을 지나치게 비관적으로 만들거나, 반대로 synthesis correlation에 유리하게 보일 때가 있었습니다.

수정:
- `wlm_profile=flat_forqa`를 기본으로 두고,
- 필요할 때만 `legacy_hier`를 켜서 비교할 수 있게 했습니다.

의미:
- “현재 결과가 정말 논리적으로 나아진 것인지”
- “아니면 wire-load 가정 때문에 좋아 보이는 것인지”
를 분리해서 볼 수 있게 됐습니다.

### 3. custom ICG 내부 arc 때문에 비정상적인 clock-gating violation이 보였다

문제:
- RTL 기반 custom ICG가 gate/latch로 구현된 뒤, PT가 내부 implementation arc를 실제 timing path처럼 세게 해석하는 경우가 있었습니다.
- 특히 FF cross-corner 비교에서 비물리적인 clock-gating violation이 커 보이는 문제가 있었습니다.

수정:
- `STA_script.tcl`에서 custom ICG 관련
  - `set_clock_gating_check -setup 0 -hold 0`
  - `set_disable_timing`
  을 사용해 내부 gate arc를 기본적으로 비활성화했습니다.

의미:
- generated clock 기반의 intended model을 우선하도록 정리
- `report_qor`와 `clock_gating` 결과를 더 해석 가능하게 만듦

### 4. generated clock가 hierarchy 변화에 따라 사라질 수 있었다

문제:
- `clk_fast_aes`는 custom ICG 경로를 기준으로 만들어지는데, netlist 구조가 바뀌면 SDC에서 그대로 못 잡는 경우가 있었습니다.

수정:
- `func_pre_sta.tcl`에서
  - `u_ctrl/u_icg_aes/gclk`
  - 또는 예전 경로 `u_ctrl/u_aes/u_icg_state/gclk`
  중 실제로 존재하는 pin에 다시 generated clock를 생성하도록 했습니다.

의미:
- synth netlist version이 조금 달라도 functional STA를 다시 세우기 쉬워졌습니다.

## 이 워크스페이스에서 확인한 중요한 결과

현재 `4_15_8ns_ff`의 `synth/func` 결과를 보면, `ss/ff/tt` 모두 기능 경로 setup/hold는 clean입니다.

대표 결과:

- `ss`
  - [func_synthcmp_ss_qor.rpt](4_report/4_15_8ns_ff/synth/func/qor/func_synthcmp_ss_qor.rpt)
  - `clk_fast_aes` setup slack: `0.4528ns`
- `ff`
  - [func_synthcmp_ff_qor.rpt](4_report/4_15_8ns_ff/synth/func/qor/func_synthcmp_ff_qor.rpt)
  - `clk_fast_aes` setup slack: `0.0100ns`
- `tt`
  - [func_synthcmp_tt_qor.rpt](4_report/4_15_8ns_ff/synth/func/qor/func_synthcmp_tt_qor.rpt)
  - `clk_fast_aes` setup slack: `0.7367ns`

즉 이 워크스페이스는
- `ff`가 가장 빡빡하고
- `ss`, `tt`는 더 여유가 있다는 점을 비교하는 데 유용했습니다.

## coverage를 어떻게 해석했는가

`func` coverage는 세 corner에서 거의 같은 형태로 보입니다.

예:
- [func_synthcmp_ss_analysis_coverage.rpt](4_report/4_15_8ns_ff/synth/func/analysis_coverage/func_synthcmp_ss_analysis_coverage.rpt)
- [func_synthcmp_ff_analysis_coverage.rpt](4_report/4_15_8ns_ff/synth/func/analysis_coverage/func_synthcmp_ff_analysis_coverage.rpt)
- [func_synthcmp_tt_analysis_coverage.rpt](4_report/4_15_8ns_ff/synth/func/analysis_coverage/func_synthcmp_tt_analysis_coverage.rpt)

해석:
- `setup/hold` met 비율이 `34%` 수준으로 낮아 보여도,
- functional mode에서는 scan/reset 관련 arc가 비활성이라 `Untested`가 크게 나오는 것이 자연스럽습니다.
- 따라서 coverage 숫자만 보고 나쁘다고 보기보다,
  - 어떤 scenario인지
  - 어떤 check가 intended인지
를 같이 봐야 합니다.

즉 `2.5_STA`는 coverage 숫자 자체보다, “왜 이런 숫자가 나오는지 해석하는 공간”으로도 의미가 있었습니다.

## 현재 문서 기준으로 정리된 결론

`2.5_STA`를 통해 얻은 중요한 결론은 아래와 같습니다.

1. synthesis SDC는 sanitize해서 읽는 편이 corner 비교에 안정적이다
2. custom ICG 내부 arc는 의도한 generated-clock 모델 기준으로 정리해야 한다
3. `ff` corner가 기능 경로에서 가장 빡빡한 corner로 보인다
4. coverage는 scenario 목적과 함께 해석해야 한다
5. 최종 signoff는 `4_STA`에서 post-DFT/ECO 기준으로 내리고,
   `2.5_STA`는 비교/실험/정리용으로 쓰는 것이 맞다

## 현재 이 워크스페이스의 한계

- `func`에서 `no_input_delay` warning 1개가 남아 있습니다.
- scan scenario는 비교/실험에는 유용하지만, 최종 결론은 `4_STA` 쪽 문서를 같이 봐야 합니다.
- post-DFT hold closure는 이 워크스페이스가 아니라 `3_DFT ECO + 4_STA`에서 마무리했습니다.

즉 `2.5_STA`는 “문제를 다 닫는 곳”이 아니라, “문제를 비교하고 해석 방법을 다듬는 곳”이라고 보는 게 맞습니다.

## 기억이 안 날 때 먼저 볼 파일

나중에 이 워크스페이스의 의미가 기억 안 나면 아래 순서로 보면 됩니다.

1. [STA_script.tcl](0_script/STA_script.tcl)
   - sanitize/WLM/custom ICG 처리 로직이 다 들어 있음
2. `4_report/<ver>/synth/func/qor/*.rpt`
   - corner별 WNS 비교
3. `4_report/<ver>/synth/func/analysis_coverage/*.rpt`
   - func coverage 해석
4. [4_STA/README.md](../4_STA/README.md)
   - 최종 post-DFT/ECO 결과

## 함께 보면 좋은 README

- 합성: [2_synthesis/README.md](../2_synthesis/README.md)
- DFT: [3_DFT/README.md](../3_DFT/README.md)
- 최종 STA: [4_STA/README.md](../4_STA/README.md)
