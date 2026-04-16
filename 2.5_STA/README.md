# 2.5_STA

이 디렉터리는 versioned netlist에 대해 PrimeTime pre-layout STA를 돌리는 비교 / 실험용 워크스페이스입니다.

현재 목적:

- synthesis netlist를 여러 corner에서 비교
- constraint / sanitized SDC / generated clock 해석 방식을 정리
- 최종 `6_STA`에 들어가기 전에 PT 해석이 어떻게 보이는지 분리해서 확인

즉 `2.5_STA`는 최종 signoff 문서라기보다, “해석 방법을 다듬는 중간 분석 공간”에 가깝습니다.

## 전체 흐름에서의 위치

1. `2_synthesis`
   - mapped netlist / SDC 생성
2. `2.5_STA`
   - 합성 결과를 여러 corner / scenario로 비교
   - SDC 해석 방식을 정리
3. `4_DFT`
   - scan insertion
4. `6_STA`
   - post-DFT 기준 최종 pre-layout STA

즉 현재 `2.5_STA`는 `4_DFT`, `6_STA` 앞단의 비교 / 실험 공간입니다.

## 현재 실행 인터페이스

현재 [run.csh](run.csh)의 기본값은 아래입니다.

- `ver=4_16_8ns_topo_ss`
- `corner=ss`
- `mode=synthcmp`
- `sta_scenario=func`
- `design_name=top_mcu_pll_sram_multiclk_soc`
- `net_source=synth`

입력은 `net_source`에 따라 갈립니다.

- `net_source=synth`
  - netlist: `../2_synthesis/2_output/${ver}/mapped/soc_gate.v`
  - SDC: `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`
  - SDF: `../2_synthesis/2_output/${ver}/mapped/soc_gate.sdf`
- `net_source=dft`
  - netlist: `../4_DFT/2_output/${ver}/aes_128_internal.v`
  - SDC: `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`
  - SDF는 직접 넘겨줘야 함

중요:

- 현재 체크인된 최신 리포트는 주로 `4_16_8ns_topo_ss/synth/func` 쪽입니다.
- 즉 문서 기준 baseline도 여기에 맞추는 것이 현재 상태에 더 맞습니다.

## 출력 구조

리포트는 아래 구조로 쌓입니다.

- 로그:
  - `3_log/${ver}_${net_source}_${sta_scenario}_${mode}_${corner}_sta.log`
- 리포트:
  - `4_report/${ver}/${net_source}/${scenario}/...`

예:

- [4_report/4_16_8ns_topo_ss/synth/func](4_report/4_16_8ns_topo_ss/synth/func)

## 주요 파일

- [run.csh](run.csh)
  - synth / dft netlist 선택
  - scenario별 override 선택
- [0_script/STA_script.tcl](0_script/STA_script.tcl)
  - sanitized SDC 생성
  - report tree 생성
  - SDF annotate 후 PT 실행
- override 파일
  - [func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)
  - [scan_shift_sta.tcl](1_input/constraint/scan_shift_sta.tcl)
  - [scan_capture_sta.tcl](1_input/constraint/scan_capture_sta.tcl)

## 실행 예시

기본 synth/func 비교:

```bash
cd ./2.5_STA
csh run.csh
```

corner 비교:

```bash
env ver=4_16_8ns_topo_ss corner=ss sta_scenario=func net_source=synth csh run.csh
env ver=4_16_8ns_topo_ss corner=ff sta_scenario=func net_source=synth csh run.csh
env ver=4_16_8ns_topo_ss corner=tt sta_scenario=func net_source=synth csh run.csh
```

## 현재 스크립트 동작 요약

현재 [STA_script.tcl](0_script/STA_script.tcl)은 아래 순서로 동작합니다.

1. `ver`, `corner`, `sta_scenario`, `net_source`, `net`, `sdc`, `sdf_delay`를 읽음
2. corner별 db 라이브러리 로드
3. netlist read / link
4. 입력 SDC에서 wire-load 관련 줄만 제거한 `sanitized SDC` 생성
5. scenario override 적용
6. `read_sdf -type sdf_max`로 지연 annotate
7. `check_timing`, `report_timing`, `report_qor`, `report_analysis_coverage` 생성

즉 현재 `2.5_STA`도 단순한 SDC 실험이 아니라, gate + SDF 기반 비교 환경입니다.

## 현재 기준으로 의미 있는 결과

현재 체크인된 최신 실험 결과 중 문서 기준으로 가장 먼저 볼 것은 아래입니다.

- [4_report/4_16_8ns_topo_ss/synth/func/qor/func_synthcmp_ff_qor.rpt](4_report/4_16_8ns_topo_ss/synth/func/qor/func_synthcmp_ff_qor.rpt)
- [4_report/4_16_8ns_topo_ss/synth/func/qor/func_synthcmp_ss_qor.rpt](4_report/4_16_8ns_topo_ss/synth/func/qor/func_synthcmp_ss_qor.rpt)

현재 `4_16_8ns_topo_ss`의 `synth/func` 결과를 보면:

- `ff`
  - `clk_fast_aes` setup slack: `0.0100ns`
- `ss`
  - `clk_fast_aes` setup slack: `0.0100ns`

즉 현재 이 워크스페이스는 “corner별 기능 경로가 전반적으로 clean한지”와 “`clk_fast_aes`가 얼마나 빡빡한지”를 비교하는 데 의미가 있습니다.

## coverage 해석

`func` coverage는 낮아 보일 수 있습니다.

예:

- [func_synthcmp_ff_analysis_coverage.rpt](4_report/4_16_8ns_topo_ss/synth/func/analysis_coverage/func_synthcmp_ff_analysis_coverage.rpt)
- [func_synthcmp_ss_analysis_coverage.rpt](4_report/4_16_8ns_topo_ss/synth/func/analysis_coverage/func_synthcmp_ss_analysis_coverage.rpt)

현재 해석:

- `func`에서는 scan/test 관련 arc를 의도적으로 비활성화함
- 그래서 `Untested` 비율이 커지는 것이 자연스럽다
- coverage 숫자만 보고 timing이 나쁘다고 해석하면 안 된다

즉 `2.5_STA`는 coverage 숫자 자체보다 “왜 이런 숫자가 나왔는가”를 비교하는 공간으로 보는 편이 맞습니다.

## 실제로 겪은 문제: `PTE-015`와 generated clock anchor

이 워크스페이스에서도 SDF 기반 비교 중 `PTE-015`를 실제로 겪었습니다.

대표 형태:

- `u_ctrl/u_icg_aes/gclk`
- `u_div8/clk_out`

증상:

- `read_sdf` 직후
- `cannot be annotated because of a timing assertion on hierarchical pin ... (PTE-015)`

원인:

- generated clock를 hierarchical pin에 직접 정의해 둔 상태에서
- 해당 hierarchical pin을 경계로 SDF net delay annotation이 들어오면서 충돌한 것입니다.

중요한 점:

- 이 문제는 `set_clock_uncertainty`를 다시 줘서 생긴 것이 아닙니다.
- `read_sdf` 단계에서 이미 발생합니다.

수정 방법:

- generated clock anchor를 hierarchical pin에서 leaf pin으로 옮겼습니다.

변경 기준:

- `u_ctrl/u_icg_aes/gclk`
  - → `u_ctrl/u_icg_aes/U4/Y`
- source `u_ctrl/u_icg_aes/clk`
  - → `u_ctrl/u_icg_aes/U4/A1`
- `u_div8/clk_out`
  - → `u_div8/clk_out_reg/Q`
- source `u_div8/clk_in`
  - → `u_div8/clk_out_reg/CLK`

적용 위치:

- [0_script/STA_script.tcl](0_script/STA_script.tcl)
  - sanitized SDC 생성 단계에서 해당 clock 정의를 치환
- [1_input/constraint/func_pre_sta.tcl](1_input/constraint/func_pre_sta.tcl)
  - `clk_fast_aes` fallback도 leaf pin 우선으로 변경

의미:

- hierarchical pin timing assertion 때문에 SDF annotation이 막히던 문제를 완화
- 비교용 STA에서도 실제 구동 pin 기준으로 clock 해석을 더 안정화

즉 현재 `2.5_STA`는 예전 hierarchical pin 기반 generated clock 정의보다, leaf pin 기준 정의를 우선 사용하도록 정리된 상태입니다.

## 현재 문서 기준으로 정리한 결론

현재 `2.5_STA`에서 안정적으로 말할 수 있는 내용은 아래입니다.

1. baseline 설명은 `4_16_8ns_topo_ss` 기준이 더 적절하다
2. 현재 체크인된 최신 리포트는 주로 `synth/func` 쪽이다
3. sanitized SDC 방식은 여전히 핵심이고, 이 워크스페이스의 주요 가치다
4. 최종 timing 결론은 [6_STA/README.md](../6_STA/README.md)에서 봐야 한다

즉 `2.5_STA`는 현재도 유효하지만, “최종 signoff 공간”보다는 “비교 / 실험 / 해석 정리 공간”으로 읽는 것이 맞습니다.

## 같이 보면 좋은 README

- 합성: [../2_synthesis/README.md](../2_synthesis/README.md)
- DFT: [../4_DFT/README.md](../4_DFT/README.md)
- 최종 STA: [../6_STA/README.md](../6_STA/README.md)
