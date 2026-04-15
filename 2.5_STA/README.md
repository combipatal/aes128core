# 2.5_STA

`2.5_STA`는 versioned netlist에 대해 PrimeTime pre-layout STA를 돌리는 별도 워크스페이스입니다. 기존 `4_STA`와 분리해서 SS/FF/TT 비교, synth-vs-DFT netlist 비교, scenario별 실험을 독립적으로 관리하는 용도입니다.

## 목적

- version별 mapped netlist STA 결과를 분리 저장
- `synth`와 `dft` net source를 같은 구조로 비교
- `func`, `scan_shift`, `scan_capture` 시나리오를 같은 스크립트에서 전환
- SS/FF/TT corner 비교를 쉽게 반복

## 기본값

[run.csh](/DATA/home/edu135/aes128_core/2.5_STA/run.csh)의 기본 환경변수는 아래와 같습니다.

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

기본 netlist/SDC는 아래 경로를 사용합니다.

- `net_source=synth`
  - netlist: `../2_synthesis/2_output/${ver}/mapped/soc_gate.v`
  - SDC: `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`
- `net_source=dft`
  - netlist: `../3_DFT/2_output/${ver}/aes_128_internal.v`
  - SDC: `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`

## 실행 방법

기본 functional synth STA:

```bash
cd /DATA/home/edu135/aes128_core/2.5_STA
csh run.csh
```

corner 지정 예시:

```bash
env ver=4_13_7p3ns corner=ss sta_scenario=func net_source=synth csh run.csh
env ver=4_13_7p3ns corner=ff sta_scenario=func net_source=synth csh run.csh
env ver=4_13_7p3ns corner=tt sta_scenario=func net_source=synth csh run.csh
```

DFT netlist STA 예시:

```bash
env ver=4_13_7p3ns corner=ss sta_scenario=func net_source=dft csh run.csh
```

scan scenario 예시:

```bash
env ver=4_13_7p3ns corner=ss sta_scenario=scan_shift net_source=dft csh run.csh
env ver=4_13_7p3ns corner=ss sta_scenario=scan_capture net_source=dft csh run.csh
```

긴 실행은 별도 `tmux` 세션에서 돌리는 편이 안전합니다.

```bash
tmux new-session -d -s sta_7p3_ss 'cd /DATA/home/edu135/aes128_core/2.5_STA && env ver=4_13_7p3ns corner=ss sta_scenario=func net_source=synth csh run.csh'
```

## Corner 이름

[STA_script.tcl](/DATA/home/edu135/aes128_core/2.5_STA/0_script/STA_script.tcl)에서 지원하는 `corner` 값은 아래와 같습니다.

- `ss` → `ss0p95v125c`
- `ff` → `ff1p16v125c`
- `ff1p16vn40c`
- `tt` → `tt1p05v125c`

README나 예전 로그에 `ss0p95v125c`, `ff1p16v125c`가 직접 보이더라도, 실행 변수는 현재 `ss`, `ff`, `tt` short name을 쓰는 것이 맞습니다.

## Scenario override

`sta_scenario`에 따라 아래 override 파일을 추가로 읽습니다.

- `func` → [func_pre_sta.tcl](/DATA/home/edu135/aes128_core/2.5_STA/1_input/constraint/func_pre_sta.tcl)
- `scan_shift` → [scan_shift_sta.tcl](/DATA/home/edu135/aes128_core/2.5_STA/1_input/constraint/scan_shift_sta.tcl)
- `scan_capture` → [scan_capture_sta.tcl](/DATA/home/edu135/aes128_core/2.5_STA/1_input/constraint/scan_capture_sta.tcl)

각 파일의 역할은 다음과 같습니다.

- `func_pre_sta.tcl`
  - `scan_en=0`, `test_mode=0`
  - AES generated clock `clk_fast_aes`가 누락된 경우 current mapped hierarchy에 맞춰 재생성
- `scan_shift_sta.tcl`
  - `scan_en=1`, `test_mode=1`
- `scan_capture_sta.tcl`
  - `scan_en=0`, `test_mode=1`
  - `rst_n`, `scan_in`, `scan_out`에 scan capture용 delay 부여

## STA 스크립트 동작

[STA_script.tcl](/DATA/home/edu135/aes128_core/2.5_STA/0_script/STA_script.tcl)은 아래 순서로 동작합니다.

1. 환경변수에서 `ver`, `corner`, `mode`, `design_name`, `net`, `sdc`, `sta_scenario`를 읽습니다.
2. corner에 맞는 SAED32 stdcell/PLL/IO/SRAM library를 설정합니다.
3. `4_report/${ver}/${net_source}/${scenario}` 이하 리포트 디렉터리를 생성합니다.
4. netlist를 `read_verilog`하고 `link`합니다.
5. wire-load 정책을 적용합니다.
   기본은 `wlm_profile=flat_forqa`이고, 선택적으로 `legacy_hier`를 사용할 수 있습니다.
6. synthesis-written SDC에서 `set_wire_load_mode`, `set_wire_load_model` 줄을 제거한 sanitized SDC를 생성합니다.
7. sanitized SDC를 `read_sdc`한 뒤 scenario override를 source합니다.
8. 기본 uncertainty mode가 `scaled_by_period`이면 clock별 uncertainty를 다시 설정합니다.
9. custom ICG 내부 timing arc를 disable해서 non-physical clock-gating violation을 줄입니다.
10. `update_timing -full` 후 `check_timing`, `report_analysis_coverage`, `report_clocks`, `report_timing`, `report_qor` 등을 출력합니다.

## 산출물 구조

로그:

```text
3_log/${ver}_${net_source}_${sta_scenario}_${mode}_${corner}_sta.log
```

리포트 루트:

```text
4_report/${ver}/${net_source}/${scenario}/
```

scenario 이름은 아래처럼 directory에 매핑됩니다.

- `func` → `func`
- `scan_shift` → `shift`
- `scan_capture` → `capture`

주요 리포트:

- `check_timing/`
- `no_clocks/`
- `disable_timing/`
- `analysis_coverage/`
- `clocks/`
- `clock_gating/`
- `all_violations/`
- `setup/`
- `hold/`
- `qor/`

또한 각 scenario 디렉터리에는 읽은 SDC에서 wire-load 명령을 제거한
`soc_func.sdc.sanitized`가 저장됩니다.

## Warning 해석 메모

- `SDC-2`
  - SDC 파일 헤더 버전과 `read_sdc` 요청 버전이 다를 때 나는 warning입니다.
  - 보통 SDC가 안 읽힌 것이 아니라 version mismatch warning입니다.
- `UITE-136`
  - hierarchical pin에 generated clock을 생성할 때 나는 warning입니다.
  - `u_ctrl/u_icg_aes/gclk`, `u_div8/clk_out` 같은 pin 기반 generated clock 모델에서는 흔합니다.
- `check_timing`의 `no_input_delay`
  - functional scenario에서 입력 포트 일부가 unconstrained라는 뜻입니다.
  - 현재는 synthesis-side constraint 정리와 scenario override로 줄여가며 관리합니다.

## 디버그 포인트

- `Missing netlist` 또는 `Missing SDC`가 나오면 `ver`, `net_source` 조합부터 확인합니다.
- generated clock warning이 보이면 먼저 `clocks/*.rpt`에서 `clk_fast_aes`, `clk_div8`이 실제 생성됐는지 확인합니다.
- `check_timing` warning은 `check_timing/*.rpt`, `analysis_coverage/*.rpt`, `clocks/*.rpt`를 같이 봐야 원인을 좁힐 수 있습니다.
- cross-corner 비교에서 wire-load 영향이 과하게 보이면 `wlm_profile=legacy_hier`와 기본 `flat_forqa` 결과를 비교합니다.
- custom ICG 관련 비정상 violation은 `clock_gating/*.rpt`와 `disable_timing/*.rpt`를 먼저 확인합니다.
