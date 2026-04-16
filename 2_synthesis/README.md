# 2_synthesis

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`의 Synopsys Design Compiler 합성 워크스페이스입니다.

현재 이 단계의 역할:

- RTL을 mapped gate netlist와 synthesis SDC로 변환
- `3_FM`, `4_DFT`, `5_FM`, `6_STA`, `7_ATPG`의 기준 netlist를 제공
- timing이 맞는 baseline과 후속 단계에서 재사용 가능한 hierarchy / clock anchor를 유지

## 전체 흐름에서의 위치

1. `0_rtl`
   - RTL 작성
2. `1_vcs`
   - 기능 검증
3. `2_synthesis`
   - mapped gate netlist / DDC / SDC 생성
4. `3_FM`
   - RTL ↔ synthesis formal check
5. `4_DFT`
   - scan insertion
6. `5_FM`
   - synthesis ↔ DFT formal check
7. `6_STA`
   - post-DFT STA
8. `7_ATPG`
   - ATPG

## 현재 기준 버전

현재 기본 실행 버전과 가장 최신 산출물 기준은 아래입니다.

- `4_16_8ns_topo_ss`

현재 [run.csh](run.csh) 기본값도 이 버전을 사용합니다.

## 주요 파일

- [run.csh](run.csh)
  - `dc_shell -topo` wrapper
- [0_script/synthesis_script.tcl](0_script/synthesis_script.tcl)
  - 메인 합성 스크립트
- [1_input/constraint/constraint.con](1_input/constraint/constraint.con)
  - 합성 제약
- [default.svf](default.svf)
  - Formality guidance

주요 출력:

- [2_output/4_16_8ns_topo_ss/mapped/soc_gate.v](2_output/4_16_8ns_topo_ss/mapped/soc_gate.v)
- [2_output/4_16_8ns_topo_ss/mapped/soc_gate.ddc](2_output/4_16_8ns_topo_ss/mapped/soc_gate.ddc)
- [2_output/4_16_8ns_topo_ss/mapped/soc_func.sdc](2_output/4_16_8ns_topo_ss/mapped/soc_func.sdc)
- [4_report/4_16_8ns_topo_ss/qor.rpt](4_report/4_16_8ns_topo_ss/qor.rpt)
- [4_report/4_16_8ns_topo_ss/timing.rpt](4_report/4_16_8ns_topo_ss/timing.rpt)
- [4_report/4_16_8ns_topo_ss/dft_ready.rpt](4_report/4_16_8ns_topo_ss/dft_ready.rpt)

## 실행 방법

기본 실행:

```bash
cd /DATA/home/edu135/aes128_core/2_synthesis
csh run.csh
```

버전과 period를 직접 지정:

```bash
env ver=4_16_8ns_topo_ss clk_period=8 csh run.csh
```

현재 wrapper 기본값:

- `ver=4_16_8ns_topo_ss`
- `clk_period=8`
- `dc_shell -topo -64`

## 현재 스크립트 방향

현재 합성 스크립트는 아래 방향으로 정리돼 있습니다.

- topographical compile 사용
- synthesis 결과를 그대로 후속 단계에서 쓰기 쉬운 계층 이름 유지
- `u_mem/u_sram`, `u_pll` 같은 macro 성격 블록은 보존
- generated clock anchor가 깨지지 않도록 `u_ctrl/u_icg_aes` 계층 유지
- mapped netlist, DDC, SDC, SVF를 같이 남겨 후속 단계에서 바로 재사용

## 현재 결과 요약

현재 [4_report/4_16_8ns_topo_ss/qor.rpt](4_report/4_16_8ns_topo_ss/qor.rpt) 기준으로 보면 합성 timing은 맞습니다.

핵심 수치:

- Design WNS/TNS: `0 / 0`
- Hold WNS/TNS: `0 / 0`
- `clk_fast` critical slack: `0.63`
- `clk_fast_aes` critical slack: `0.00`

즉 현재 synthesis baseline은 timing은 met이지만, `clk_fast_aes`는 거의 여유가 없는 경계값입니다.

추가로 남아 있는 QoR 이슈:

- Max cap violations: `28`

즉 “합성 실패”는 아니지만, synthesis QoR만 놓고 보면 아주 넉넉한 상태는 아닙니다.

## DFT readiness 해석

[dft_ready.rpt](4_report/4_16_8ns_topo_ss/dft_ready.rpt) 기준으로 pre-DFT rule warning은 남아 있습니다.

현재 확인되는 핵심 항목:

- `D9` 256건
- `D17` 256건
- `TEST-505` 1건

해석:

- 내부 clock / capture 조건 때문에 pre-DFT rule warning이 많이 보입니다.
- `u_ctrl/u_icg_aes/en_lat_reg` constant 1 warning도 계속 남습니다.
- 하지만 이후 [4_DFT](../4_DFT/README.md)와 [7_ATPG](../7_ATPG/README.md) 결과를 보면 flow 전체가 막히지는 않았습니다.

즉 현재 synthesis README에서는 “DFT-ready가 완전 clean하다”보다 “후속 DFT flow가 돌아갈 수준의 baseline”으로 보는 편이 정확합니다.

## 현재 판단

현재 `2_synthesis`는 아래처럼 정리할 수 있습니다.

- 기본 baseline은 `4_16_8ns_topo_ss`
- mapped netlist / DDC / SDC / SVF는 정상 생성됨
- synthesis timing은 met
- `clk_fast_aes` 여유는 매우 작음
- max cap violation 28건이 남아 있음
- pre-DFT warning은 남지만 후속 DFT / STA / ATPG flow는 실제로 진행됨

즉 지금 단계에서는:

- 합성 결과는 현재 프로젝트 기준으로 usable baseline
- signoff 관점보다는 후속 flow 연결용 기준점 역할이 더 큼

## 같이 보면 좋은 README

- 기능 검증: [../1_vcs/README.md](../1_vcs/README.md)
- r2n FM: [../3_FM/README.md](../3_FM/README.md)
- DFT: [../4_DFT/README.md](../4_DFT/README.md)
- post-DFT STA: [../6_STA/README.md](../6_STA/README.md)
