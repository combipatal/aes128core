# 4_DFT

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`의 scan insertion 워크스페이스입니다.

현재 역할:

- 입력: `2_synthesis`의 mapped DDC
- 처리: internal scan insertion
- 출력: scan inserted netlist / DDC / SPF / SDF / DEF / DRC / QoR report

## 현재 기준 버전

현재 기본 실행 버전과 최신 결과 기준은 아래입니다.

- `4_16_8ns_topo_ss`

현재 [run.csh](run.csh) 기본값도 이 버전을 사용합니다.

## 입력 / 출력

입력:

- [../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.ddc](../2_synthesis/2_output/4_16_8ns_topo_ss/mapped/soc_gate.ddc)

주요 출력:

- [2_output/4_16_8ns_topo_ss/aes_128_internal.v](2_output/4_16_8ns_topo_ss/aes_128_internal.v)
- [2_output/4_16_8ns_topo_ss/aes_128_internal.ddc](2_output/4_16_8ns_topo_ss/aes_128_internal.ddc)
- [2_output/4_16_8ns_topo_ss/aes_128_internal.sdf](2_output/4_16_8ns_topo_ss/aes_128_internal.sdf)
- [2_output/4_16_8ns_topo_ss/scan_internal.spf](2_output/4_16_8ns_topo_ss/scan_internal.spf)
- [2_output/4_16_8ns_topo_ss/scan.def](2_output/4_16_8ns_topo_ss/scan.def)

## 주요 스크립트

- [run.csh](run.csh)
  - DFT insertion wrapper
- [0_script/DFT_script.tcl](0_script/DFT_script.tcl)
  - 메인 DFT 스크립트
- [0_script/post_dft_setup_eco.tcl](0_script/post_dft_setup_eco.tcl)
  - setup 관련 후속 실험용 ECO 스크립트

## 현재 DFT 설정 요약

[scan_config_internal.rpt](4_report/4_16_8ns_topo_ss/scan_config_internal.rpt) 기준 설정은 아래와 같습니다.

- chain count: `4`
- scan style: `Multiplexed flip-flop`
- internal clocks: `none`
- add lockup: `True`
- lockup type: `latch`
- physical partitioning: `Horizontal`

현재 실제 chain 구성:

- `scan_in -> scan_out`
- `test_si2 -> test_so2`
- `test_si3 -> test_so3`
- `test_si4 -> test_so4`

각 chain length는 모두 `383`이고 총 scan FF는 `1532`입니다.

즉 예전 single-chain 기준 설명은 더 이상 현재 상태와 맞지 않습니다.

## 현재 결과 요약

현재 [4_report/4_16_8ns_topo_ss](4_report/4_16_8ns_topo_ss) 기준으로 DFT insertion은 정상적으로 완료됐습니다.

핵심 결과:

- [scan_config_internal.rpt](4_report/4_16_8ns_topo_ss/scan_config_internal.rpt)
  - chain count `4`
  - scan style `Multiplexed flip-flop`
- [scan_chains_internal.rpt](4_report/4_16_8ns_topo_ss/scan_chains_internal.rpt)
  - 4개 chain
  - 각 chain length `383`
- [dft_qor_internal.rpt](4_report/4_16_8ns_topo_ss/dft_qor_internal.rpt)
  - Design WNS/TNS `0 / 0`
  - Hold WNS/TNS `0 / 0`

즉 현재 `4_DFT`는 “scan insertion 실패”가 아니라 “4-chain DFT가 정상 삽입된 상태”로 보는 것이 맞습니다.

## 현재 DRC 해석

[insert_drc_internal.dft](4_report/4_16_8ns_topo_ss/insert_drc_internal.dft) 기준 post-DFT DRC의 핵심은 아래입니다.

- Total violations: `4`
- modeling violation 2건
  - `u_mem/u_sram`, `u_pll` unknown model
- clock violation 1건
  - `Clock ref_clk is connected to primary output clk_fast`
- other violation 1건
  - `u_ctrl/u_icg_aes/en_lat_reg` constant 1

현재 해석:

- macro / black-box 성격 warning
- clock observe output 구조 관련 warning
- custom ICG latch 관련 warning

즉 warning은 남지만, 현재 flow에서 이미 알고 있는 구조적 warning으로 보는 편이 정확합니다.

## 확인 포인트

DFT 결과를 다시 볼 때는 아래 순서가 가장 빠릅니다.

1. [preview_dft.rpt](4_report/4_16_8ns_topo_ss/preview_dft.rpt)
   - 예상 scan 구조 확인
2. [scan_config_internal.rpt](4_report/4_16_8ns_topo_ss/scan_config_internal.rpt)
   - 실제 chain count / lockup 설정 확인
3. [scan_chains_internal.rpt](4_report/4_16_8ns_topo_ss/scan_chains_internal.rpt)
   - 입력 / 출력 scan 포트와 chain 길이 확인
4. [insert_drc_internal.dft](4_report/4_16_8ns_topo_ss/insert_drc_internal.dft)
   - 남은 DRC warning 확인
5. [dft_qor_internal.rpt](4_report/4_16_8ns_topo_ss/dft_qor_internal.rpt)
   - DFT 이후 timing / hold 상태 확인

## 현재 판단

현재 `4_DFT`는 아래처럼 정리할 수 있습니다.

- 기본 baseline은 `4_16_8ns_topo_ss`
- 4-chain scan insertion이 정상 완료됨
- inserted netlist / DDC / SPF / SDF / DEF가 생성됨
- timing은 met
- warning 4건은 구조적으로 설명 가능한 수준으로 남아 있음

즉 지금 단계에서는:

- DFT insertion 자체는 정상
- 다음 의미 있는 확인 단계는 [5_FM](../5_FM/README.md), [6_STA](../6_STA/README.md), [7_ATPG](../7_ATPG/README.md)입니다

## 같이 보면 좋은 README

- synthesis: [../2_synthesis/README.md](../2_synthesis/README.md)
- n2n FM: [../5_FM/README.md](../5_FM/README.md)
- post-DFT STA: [../6_STA/README.md](../6_STA/README.md)
- ATPG: [../7_ATPG/README.md](../7_ATPG/README.md)
