# 3_DFT

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`에 대해 single scan chain 기반 DFT insertion을 수행하는 폴더입니다.

## 목적

- `2_synthesis`의 mapped DDC를 입력으로 사용
- scan signal 정의, test protocol 생성, pre/post DFT DRC 수행
- single scan chain 삽입
- DFT netlist/DDC/SPF/SCANDEF 및 관련 리포트 생성

## 디렉터리 구성

- `0_script/`
  - `DFT_script.tcl`: 메인 DFT 스크립트
- `2_output/`
  - 버전별 DFT 결과 저장 폴더
- `3_log/`
  - 버전별 DFT 실행 로그
- `4_report/`
  - 버전별 DFT 리포트
- `run.csh`
  - DFT 실행 스크립트

## 입력 / 출력 관계

### 입력

- 합성 결과 DDC:
  - `../2_synthesis/2_output/$ver/mapped/soc_gate.ddc`

### 출력

- `./2_output/$ver/scan_internal.spf`
- `./2_output/$ver/scan.def`
- `./2_output/$ver/aes_128_internal.v`
- `./2_output/$ver/aes_128_internal.ddc`

## 실행 방법

[`run.csh`](/DATA/home/edu135/aes128_core/3_DFT/run.csh)에서 버전을 지정합니다.

```csh
setenv ver 4_11_6_7ns
source ../.synopsys_dc.setup

file mkdir ./2_output/${ver}
file mkdir ./3_log
file mkdir ./4_report/${ver}

dc_shell -64 -f 0_script/DFT_script.tcl | tee 3_log/${ver}_scan_dc.log
```

실행:

```bash
csh run.csh
```

## 현재 DFT 설정 요약

- scan clock: `ref_clk`
- scan enable: `scan_en`
- reset: `rst_n`
- test mode: `test_mode`
- scan input: `scan_in`
- scan output: `scan_out`
- chain count: `1`
- style: `multiplexed_flip_flop`
- internal clocks: `none`

현재 flow는 scan compression 없이 single scan chain 기준으로 동작합니다.

## 생성 리포트

버전별 리포트는 `4_report/$ver/` 아래에 저장됩니다.

- `pre_dft.rpt`
  - pre-DFT DRC 요약
- `pre_drc_verbose.rpt`
  - pre-DFT DRC 상세 리포트
- `preview_dft.rpt`
  - insert 전 scan chain 미리보기
- `insert_drc_internal.dft`
  - insert 이후 post-DFT DRC 결과
- `scan_config_internal.rpt`
  - 현재 scan configuration 요약
- `scan_chains_internal.rpt`
  - 실제 생성된 scan chain 정보
- `dft_signals_internal.rpt`
  - DFT signal 선언 결과
- `dft_qor_internal.rpt`
  - post-DFT QoR 리포트
- `dft_internal_area.rpt`
  - post-DFT area 리포트

## 최신 결과 기준 상태

현재 최신 기준은 `4_11_6_7ns` 결과입니다.

- single scan chain 삽입 성공
- `scan_in -> chain0 -> scan_out`
- chain length: `1532`
- post-DFT setup: clean
- post-DFT hold: 소규모 위반 일부 잔존

## 현재 알려진 경고 해석

### 1. PLL / SRAM macro black-box 경고

- `u_pll`, `u_mem/u_sram`는 macro / black-box 성격이 강해 DFT에서 unknown model 경고가 발생할 수 있습니다
- 현재 단계에서는 자연스러운 경고로 해석합니다

### 2. `u_icg_aes_en_lat_reg` 관련 경고

- `non-scannable`
- `constant 1`

이 경고는 clock-gating latch 특성 때문에 발생하는 것으로 보이며, 전체 scan insertion 성공 여부와는 별개로 해석합니다.

### 3. DFT 후 timing 악화

- DFT 삽입 후에는 scan mux, global signal, 추가 로직 때문에 pre-DFT보다 timing이 나빠질 수 있습니다
- 따라서 post-DFT 기준 target clock는 pre-DFT보다 느슨하게 잡는 것이 일반적입니다

## 디버그 포인트

- `preview_dft.rpt`에서 chain 길이와 scan port 연결 확인
- `scan_chains_internal.rpt`에서 `scan_in -> chain0 -> scan_out` 확인
- `insert_drc_internal.dft`에서 post-DFT 경고 확인
- `dft_qor_internal.rpt`에서 post-DFT setup / hold 상태 확인
- `3_log/${ver}_scan_dc.log`에서 `insert_dft` 이후
  - `Architecting Scan Chains`
  - `Routing Scan Chains`
  - `Mapping New Logic`
  가 정상적으로 나오는지 확인
