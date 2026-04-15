# 3_DFT

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`에 대해 single scan chain 기반 DFT insertion을 수행하는 워크스페이스입니다. 입력은 `2_synthesis`의 mapped DDC이고, 출력은 scan inserted netlist/DDC/SPF/SCANDEF 및 관련 DRC/QoR 리포트입니다.

## 목적

- `2_synthesis` mapped DDC를 입력으로 사용
- DFT signal 정의, test protocol 생성, pre/post DFT DRC 수행
- single scan chain 삽입
- scan inserted Verilog/DDC/SPF/SCANDEF 생성

## 디렉터리 구성

- `0_script/DFT_script.tcl`
  메인 DFT 스크립트입니다.
- `2_output/$ver/`
  DFT 결과물 저장 경로입니다.
- `3_log/${ver}_scan_dc.log`
  DC DFT 실행 로그입니다.
- `4_report/$ver/`
  pre/post DFT 리포트 저장 경로입니다.
- `run.csh`
  기본 `ver`를 설정하고 DFT insertion을 실행하는 wrapper입니다.

## 기본 입력 / 출력

입력:

- `../2_synthesis/2_output/${ver}/mapped/soc_gate.ddc`

출력:

- `./2_output/${ver}/scan_internal.spf`
- `./2_output/${ver}/scan.def`
- `./2_output/${ver}/aes_128_internal.v`
- `./2_output/${ver}/aes_128_internal.ddc`

## 실행 방법

[run.csh](run.csh)의 현재 기본값은 아래와 같습니다.

```csh
if ( ! $?ver ) setenv ver 4_15_8ns_ff
source ../.synopsys_dc.setup

mkdir -p ./2_output/${ver}
mkdir -p ./3_log
mkdir -p ./4_report/${ver}

dc_shell -64 -f 0_script/DFT_script.tcl | tee 3_log/${ver}_scan_dc.log
```

실행 예시:

```bash
cd ./3_DFT
csh run.csh
env ver=4_13_7p3ns csh run.csh
```

## DFT 설정 요약

[DFT_script.tcl](0_script/DFT_script.tcl) 기준 현재 설정은 아래와 같습니다.

- scan clock: `ref_clk`
  - `set_dft_signal -view exist -type ScanClock -port ref_clk -timing {45 55}`
- scan enable: `scan_en`
- reset: `rst_n`
- test mode: `test_mode`
- scan input: `scan_in`
- scan output: `scan_out`
- chain count: `1`
- scan style: `multiplexed_flip_flop`
- internal clocks: `none`
- scan path: `chain0`
- compression: 사용 안 함

현재 flow는 scan compression 없이 single scan chain 기준으로 동작합니다.

## Clock-gating 처리

현재 스크립트는 controller-level AES ICG를 명시적으로 DFT clock-gating cell로 연결합니다.

```tcl
set_dft_configuration -connect_clock_gating enable
set_dft_clock_gating_pin [get_cells u_ctrl/u_icg_aes] \
    -pin_name test_en \
    -control_signal ScanEnable
set_scan_element false [get_cells u_ctrl/u_icg_aes]
```

즉 `u_ctrl/u_icg_aes`는 scan element로 넣지 않고, test 시에는 `scan_en`으로 gating을 열도록 모델링합니다.

## 스크립트 동작 순서

현재 스크립트는 대략 아래 순서로 동작합니다.

1. `ver` 기준으로 output/report/log 디렉터리를 생성합니다.
2. `../2_synthesis/2_output/${ver}/mapped/soc_gate.ddc`를 읽고 top design을 `link`합니다.
3. test default period/strobe/delay를 설정합니다.
4. auto-disable DRC nets, constant buffering, no-tri 출력을 설정합니다.
5. DFT signal과 scan path를 정의합니다.
6. `create_test_protocol` 후 pre-DFT DRC 및 preview 리포트를 생성합니다.
7. `insert_dft`를 수행합니다.
8. functional mode(`scan_en=0`, `test_mode=0`)로 case analysis를 준 뒤 incremental compile을 한 번 더 수행합니다.
9. `Internal_scan` 모드에서 post-DFT verbose DRC를 생성합니다.
10. 이름 정리 후 SPF, scan DEF, inserted Verilog/DDC를 기록합니다.
11. scan configuration, DFT signals, scan chains, QoR, area 리포트를 생성합니다.

## 생성 리포트

버전별 리포트는 `4_report/$ver/` 아래에 저장됩니다.

- `pre_dft.rpt`
  - pre-DFT DRC 요약
- `pre_drc_verbose.rpt`
  - pre-DFT DRC 상세
- `preview_dft.rpt`
  - insert 전 scan summary preview
- `dft_qor_func.rpt`
  - insert 후 functional case analysis 상태에서 incremental compile한 QoR
- `insert_drc_internal.dft`
  - `Internal_scan` 모드 기준 post-DFT verbose DRC
- `scan_config_internal.rpt`
  - scan configuration 요약
- `dft_signals_internal.rpt`
  - existing/spec DFT signal 정의 결과
- `scan_chains_internal.rpt`
  - 실제 생성된 scan chain 정보
- `dft_qor_internal.rpt`
  - inserted netlist 기준 최종 QoR
- `dft_internal_area.rpt`
  - inserted netlist 기준 hierarchical area

## 최근 버전 예시

현재 `3_DFT/4_report`와 `3_DFT/2_output` 아래에 보이는 최근 버전 예시는 아래와 같습니다.

- `4_13_7p3ns`
- `4_14_8ns_fix_F`
- `4_15_8ns_ff`

즉 예전 문서의 `4_11_6_7ns`만 최신 기준이라고 보기는 어렵고, 현재 기본 실행값은 `4_15_8ns_ff`입니다.

## Warning 해석 메모

- `u_pll`, `u_mem/u_sram` unknown-model warning
  - macro/black-box 성격 때문에 pre/post DFT DRC에서 남을 수 있습니다.
- `u_ctrl/u_icg_aes/en_lat_reg` 관련 warning
  - `not scannable`
  - `constant 1`
  - custom latch-based clock gating 구조 때문에 남을 수 있으며, scan chain 삽입 성공 여부와는 분리해서 봐야 합니다.
- `Clock connected to primary output`
  - top이 내부 clock observe output을 유지하고 있으면 post-DFT DRC에 남을 수 있습니다.
- DFT 후 timing 악화
  - scan mux, test control logic, routing 영향으로 pre-DFT보다 timing이 나빠질 수 있습니다.

## 확인 포인트

- `preview_dft.rpt`
  - chain count와 예상 chain 길이 확인
- `scan_chains_internal.rpt`
  - `scan_in -> chain0 -> scan_out` 연결 확인
- `dft_signals_internal.rpt`
  - `ref_clk`, `scan_en`, `test_mode`, `scan_in`, `scan_out` 정의 확인
- `insert_drc_internal.dft`
  - post-DFT 경고와 unresolved DRC 확인
- `dft_qor_func.rpt`, `dft_qor_internal.rpt`
  - functional/internal scan 시점 QoR 비교
- `3_log/${ver}_scan_dc.log`
  - `create_test_protocol`, `preview_dft`, `insert_dft`, incremental compile 흐름이 정상적으로 끝났는지 확인

## 디버그 포인트

- 입력 DDC가 없으면 먼저 `../2_synthesis/2_output/${ver}/mapped/soc_gate.ddc` 존재 여부를 확인합니다.
- scan chain이 예상과 다르면 `set_scan_path chain0`, `set_scan_configuration -chain_count 1`이 유지되는지 확인합니다.
- clock-gating 관련 DRC가 많으면 `set_dft_clock_gating_pin [get_cells u_ctrl/u_icg_aes]` 대상 cell 이름이 현재 netlist와 일치하는지 먼저 봅니다.
- post-DFT timing이 급격히 악화되면 `dft_qor_func.rpt`와 `dft_qor_internal.rpt`를 나눠서 봐야 원인을 좁힐 수 있습니다.
