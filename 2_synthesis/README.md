# 2_synthesis

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`에 대한 Design Compiler 합성 플로우를 정리한 폴더입니다.

## 디렉터리 구성

- `0_script/`
  - `synthesis_script.tcl`: 메인 합성 스크립트
- `1_input/`
  - `rtl/`: RTL 소스
  - `constraint/constraint.con`: 타이밍 제약 파일
- `2_output/`
  - 버전별 합성 결과 저장 폴더 (`mapped/`, `unmapped/`)
- `3_log/`
  - 버전별 DC 실행 로그
- `4_report/`
  - 버전별 리포트 (`qor`, `timing`, `area`, `constraint`, `clock`, `check_design`)
- `run.csh`
  - 단일 합성 실행용 스크립트

## 환경 설정

이 플로우는 프로젝트 상위의 setup 파일을 사용합니다.

- [`../.synopsys_dc.setup`](/DATA/home/edu135/aes128_core/.synopsys_dc.setup)

이 파일에서 다음 항목을 정의합니다.

- 라이브러리 search path
- target / link library
- RTL search path
- DC work library

## 실행 방법

[`run.csh`](/DATA/home/edu135/aes128_core/2_synthesis/run.csh)에서 run 버전을 먼저 설정합니다.

```csh
setenv ver 4_11_4_6p5ns
source ../.synopsys_dc.setup
dc_shell -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
```

실행:

```bash
csh run.csh
```

## 버전별 결과 관리

합성 스크립트는 `env(ver)` 값을 읽어서 결과를 아래 경로에 저장합니다.

- `2_output/$ver/unmapped/`
- `2_output/$ver/mapped/`
- `4_report/$ver/`

이 방식으로 타깃 주기나 옵션이 다른 실험 결과를 덮어쓰지 않고 비교할 수 있습니다.

## 현재 합성 플로우 메모

- Top module: `top_mcu_pll_sram_multiclk_soc`
- Compile 방식: `compile_ultra -scan` 후 incremental compile
- 제약 파일: `1_input/constraint/constraint.con`
- 현재는 non-topographical 흐름 기준으로 사용
- 생성 리포트:
  - `aes_chk_design.rpt`
  - `qor.rpt`
  - `timing.rpt`
  - `area.rpt`
  - `constraint.rpt`
  - `clock.rpt`

## 제약 파일 메모

현재 `constraint.con`에는 아래 항목이 포함됩니다.

- primary clock: `ref_clk`
- generated clocks:
  - `clk_fast`
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
- false path 제외:
  - `clk_fast`
  - `clk_div2`
  - `clk_div4`
  - `clk_div8`
  - `scan_out`

## 결과 해석 메모

- `ver`별로 target period를 바꿔가며 pre-layout 기준 feasible timing을 탐색합니다.
- setup과 hold는 별도로 봅니다.
- `check_timing`은 constraint completeness 확인용이고,
  실제 setup/hold 평가는 `qor.rpt`, `timing.rpt`, `constraint.rpt` 기준으로 봅니다.
- 현재 실험 예시는 다음과 같습니다.
  - `4_11_4_6p5ns`
  - `4_11_5_6p6ns`
  - `4_11_6_7ns`

## 디버그 포인트

- DC가 RTL 파일을 못 찾으면 `1_input/rtl` 경로의 대소문자를 먼저 확인합니다.
- mapped 결과에 unmapped logic가 남으면 아래 파일을 우선 확인합니다.
  - `3_log/${ver}_syn_dc.log`
  - `4_report/$ver/area.rpt`
  - `4_report/$ver/qor.rpt`
- `check_timing`에 경고가 있으면 먼저 제약 completeness를 정리합니다.
- setup 위반이 있으면 RTL 수정 전에 `constraint.con`을 먼저 점검합니다.
- hold 위반은 setup closure와 분리해서 보는 것이 좋습니다.
- topographical mode에서 physical library linking 문제가 있으면 QoR가 왜곡될 수 있으므로, 현재는 non-topo 기준 결과를 우선 사용합니다.
