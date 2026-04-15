# 4_DFT

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`에 대해 scan insertion을 수행하는 DFT 워크스페이스입니다.

현재 기준 역할:
- 입력: `2_synthesis`의 mapped DDC
- 처리: single scan chain 기반 DFT insertion
- 출력: scan inserted netlist, DDC, SPF, scan DEF, DRC/QoR report

## 현재 기준 버전

현재 확인 기준으로 가장 중요한 버전은 아래입니다.

- `4_15_8ns_topo_ss`

즉 지금 DFT baseline은 topo synthesis 결과를 입력으로 만든 scan-inserted 버전입니다.

## 입력 / 출력

입력:
- [2_synthesis/2_output/4_15_8ns_topo_ss/mapped/soc_gate.ddc](../2_synthesis/2_output/4_15_8ns_topo_ss/mapped/soc_gate.ddc)

출력:
- [2_output/4_15_8ns_topo_ss/aes_128_internal.v](2_output/4_15_8ns_topo_ss/aes_128_internal.v)
- [2_output/4_15_8ns_topo_ss/aes_128_internal.ddc](2_output/4_15_8ns_topo_ss/aes_128_internal.ddc)
- [2_output/4_15_8ns_topo_ss/scan_internal.spf](2_output/4_15_8ns_topo_ss/scan_internal.spf)
- [2_output/4_15_8ns_topo_ss/scan.def](2_output/4_15_8ns_topo_ss/scan.def)

## 주요 스크립트

- [run.csh](run.csh)
  - DFT insertion 실행 wrapper
- [0_script/DFT_script.tcl](0_script/DFT_script.tcl)
  - 메인 DFT 스크립트

## DFT 설정 요약

현재 설정은 아래와 같습니다.

- scan clock: `ref_clk`
- scan enable: `scan_en`
- reset: `rst_n`
- test mode: `test_mode`
- scan data in: `scan_in`
- scan data out: `scan_out`
- chain count: `1`
- scan style: `multiplexed_flip_flop`
- internal clocks: `none`
- lockup: `latch`

즉 현재 flow는:
- scan compression 없음
- single scan chain
- muxed scan flop 기반

## 현재 결과 요약

현재 [4_report/4_15_8ns_topo_ss](4_report/4_15_8ns_topo_ss) 기준으로 보면 DFT insertion은 전반적으로 정상입니다.

확인된 핵심 결과:
- [scan_config_internal.rpt](4_report/4_15_8ns_topo_ss/scan_config_internal.rpt)
  - chain count `1`
  - scan style `Multiplexed flip-flop`
- [scan_chains_internal.rpt](4_report/4_15_8ns_topo_ss/scan_chains_internal.rpt)
  - `chain0`
  - length `1532`
  - `scan_in -> scan_out`
- [dft_qor_internal.rpt](4_report/4_15_8ns_topo_ss/dft_qor_internal.rpt)
  - WNS/TNS `0`
  - hold violation count `0`

즉 DFT insertion 자체는 잘 들어갔다고 봐도 됩니다.

## 현재 리포트 해석

### 1. pre-DFT DRC

- [pre_dft.rpt](4_report/4_15_8ns_topo_ss/pre_dft.rpt)

현재 주요 경고:
- `u_pll` unknown model
- `u_ctrl/u_icg_aes/en_lat_reg` constant 1

이 경고들은 현재 구조에서 치명적 실패로 보기 어렵습니다.

의미:
- `u_pll`
  - black-box / macro 성격 경고
- `u_ctrl/u_icg_aes/en_lat_reg`
  - custom latch-based ICG의 test 해석 경고

### 2. post-DFT DRC

- [insert_drc_internal.dft](4_report/4_15_8ns_topo_ss/insert_drc_internal.dft)

현재 주요 경고:
- `u_pll`, `u_mem/u_sram` unknown model
- `Clock ref_clk is connected to primary output clk_fast`
- `u_ctrl/u_icg_aes/en_lat_reg` constant 1

현재 해석:
- macro / black-box 경고는 허용 범주
- clock observe output 구조 때문에 `C17`이 남음
- custom ICG 때문에 latch 관련 warning이 남음

즉 현재 report만 보면 “scan insertion 실패”보다는 “구조상 알고 있는 warning이 남아 있는 상태”에 가깝습니다.

## 리포트 목록

현재 버전별 리포트는 `4_report/$ver/` 아래에 저장됩니다.

- `pre_dft.rpt`
  - pre-DFT DRC 요약
- `pre_drc_verbose.rpt`
  - pre-DFT DRC 상세
- `preview_dft.rpt`
  - insert 전 scan summary
- `insert_drc_internal.dft`
  - post-DFT DRC 상세
- `scan_config_internal.rpt`
  - scan configuration 요약
- `scan_chains_internal.rpt`
  - 실제 생성된 scan chain 정보
- `dft_signals_internal.rpt`
  - DFT signal 정의 결과
- `dft_qor_func.rpt`
  - insert 후 functional mode incremental compile QoR
- `dft_qor_internal.rpt`
  - inserted netlist 최종 QoR
- `dft_internal_area.rpt`
  - inserted netlist hierarchy area

## 확인 포인트

DFT 결과를 볼 때는 아래 순서가 좋습니다.

1. [preview_dft.rpt](4_report/4_15_8ns_topo_ss/preview_dft.rpt)
   - chain count, 예상 scan 구조 확인
2. [scan_config_internal.rpt](4_report/4_15_8ns_topo_ss/scan_config_internal.rpt)
   - 실제 scan 설정 확인
3. [scan_chains_internal.rpt](4_report/4_15_8ns_topo_ss/scan_chains_internal.rpt)
   - `scan_in -> chain0 -> scan_out` 확인
4. [pre_dft.rpt](4_report/4_15_8ns_topo_ss/pre_dft.rpt)
   - insert 전 DRC 확인
5. [insert_drc_internal.dft](4_report/4_15_8ns_topo_ss/insert_drc_internal.dft)
   - insert 후 DRC 확인
6. [dft_qor_internal.rpt](4_report/4_15_8ns_topo_ss/dft_qor_internal.rpt)
   - timing/QoR 확인

## 현재 판단

현재 `4_15_8ns_topo_ss` 기준 DFT는 아래처럼 정리할 수 있습니다.

- single scan chain이 정상 생성됨
- scan inserted netlist/DDC/SPF/DEF가 정상 생성됨
- DFT 후 QoR는 큰 문제 없이 유지됨
- 남은 warning은 macro/black-box/custom ICG/clock observe output 성격이 강함

즉 지금 단계에서는:
- DFT insertion 자체는 정상
- 다음 확인 포인트는 post-DFT STA

## 다음 단계

현재 `2.5_STA` 기준 synth netlist에서 FF hold가 SRAM input에 작게 남아 있습니다.

그래서 다음 권장 순서는 아래입니다.

1. `4_DFT` 결과 사용
2. post-DFT STA 실행
3. 실제 최종 hold 위반 확인
4. 필요하면 별도 ECO 흐름을 새로 정리해서 적용

즉 hold closure는 synthesis 단계보다 post-DFT 단계에서 마무리하는 쪽이 현재 흐름에 더 잘 맞습니다.
