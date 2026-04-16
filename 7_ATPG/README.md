# 7_ATPG

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`의 post-DFT netlist를 기준으로 stuck-at ATPG를 수행하는 워크스페이스입니다.

현재 목적은 아래 세 가지입니다.

- `4_DFT`에서 생성한 scan inserted netlist와 SPF를 ATPG에 입력
- scan chain / DRC / fault coverage가 정상인지 확인
- STIL / WGL 패턴과 fault report를 다음 단계에서 바로 쓸 수 있게 정리

즉 `7_ATPG`는 “scan insertion이 끝난 설계가 실제 ATPG까지 무리 없이 진행되는지” 확인하는 단계입니다.

## 전체 흐름에서의 위치

현재 프로젝트의 관련 순서는 아래처럼 보면 됩니다.

1. `2_synthesis`
   - 합성 결과 생성
2. `4_DFT`
   - scan insertion 수행
   - `aes_128_internal.v`, `scan_internal.spf` 생성
3. `6_STA`
   - post-DFT timing 확인
4. `7_ATPG`
   - DRC, fault list, pattern generation 수행

즉 `7_ATPG`의 직접 입력은 `4_DFT` 결과이고, timing 쪽 baseline은 `6_STA`와 같이 봐야 합니다.

## 현재 기준 버전

현재 확인 기준으로 가장 중요한 버전은 아래입니다.

- `4_16_8ns_topo_ss`

현재 `run.csh`도 기본값으로 이 버전을 사용합니다.

## 입력 / 출력

입력:

- [../4_DFT/2_output/4_16_8ns_topo_ss/aes_128_internal.v](../4_DFT/2_output/4_16_8ns_topo_ss/aes_128_internal.v)
- [../4_DFT/2_output/4_16_8ns_topo_ss/scan_internal.spf](../4_DFT/2_output/4_16_8ns_topo_ss/scan_internal.spf)

주요 출력:

- 로그:
  - [3_log/4_16_8ns_topo_ss/console.log](3_log/4_16_8ns_topo_ss/console.log)
  - [3_log/4_16_8ns_topo_ss/tmax.log](3_log/4_16_8ns_topo_ss/tmax.log)
- 패턴:
  - [2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_full_serial.stil](2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_full_serial.stil)
  - [2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_preview_serial.stil](2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_preview_serial.stil)
  - [2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_full_parallel.stil](2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_full_parallel.stil)
  - [2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_shift_only.stil](2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_shift_only.stil)
  - [2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_full.wgl](2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_full.wgl)
- 리포트:
  - [4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults.rpt)
  - [4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.coverage_level_16.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.coverage_level_16.rpt)
  - [4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.scan_chains.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.scan_chains.rpt)
  - [4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_AU.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_AU.rpt)
  - [4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_UD.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_UD.rpt)

## 실행 방법

기본 실행 예시는 아래와 같습니다.

```bash
cd ./7_ATPG
csh run.csh
```

버전을 명시해서 실행하려면 아래처럼 사용합니다.

```bash
cd ./7_ATPG
env ver=4_16_8ns_topo_ss csh run.csh
```

현재 [run.csh](run.csh)는 아래를 수행합니다.

- `2_output/$ver`, `3_log/$ver`, `4_report/$ver` 생성
- `4_DFT`의 netlist / SPF 존재 여부 확인
- `tmax -64 -tcl -shell ./0_script/atpg_script.tcl` 실행
- 전체 콘솔 로그를 `console.log`에 저장

## 주요 스크립트

- [run.csh](run.csh)
  - ATPG 실행 wrapper
  - 입력 파일이 없으면 바로 종료
- [0_script/atpg_script.tcl](0_script/atpg_script.tcl)
  - library read
  - ATPG model build
  - scan DRC
  - stuck-at fault 생성
  - `run_atpg -auto`
  - pattern / fault / coverage report 저장

## 현재 ATPG 설정 요약

현재 스크립트 기준 핵심 설정은 아래와 같습니다.

- top design: `top_mcu_pll_sram_multiclk_soc`
- fault model: `stuck`
- fault report 기준: `collapsed`
- ATPG coverage target: `98`
- simulation processes: `4`
- ATPG processes: `4`
- fill: `adjacent`
- merge: `high`
- decision: `random`
- power budget: `min`
- power effort: `high`
- external bus `Z` 처리: `X`
- SRAM macro `SRAM1RW1024x8`: black box

즉 현재 flow는:

- internal scan SPF 기반 DRC 수행
- stuck-at 전체 fault set 생성
- 기본 auto ATPG 수행
- STIL / WGL / fault summary를 한 번에 남김

## 현재 결과 요약

현재 [3_log/4_16_8ns_topo_ss](3_log/4_16_8ns_topo_ss)와 [4_report/4_16_8ns_topo_ss](4_report/4_16_8ns_topo_ss) 기준으로 보면 ATPG는 전반적으로 정상입니다.

확인된 핵심 결과:

- 실행 시각: `2026-04-16 10:47:03 KST`
- DRC: 성공
- scan chain: `4`개
- chain length: 각 `383`
- total faults: `58765`
- detected: `58055`
- possibly detected: `3`
- undetectable: `521`
- ATPG untestable: `186`
- not detected: `0`
- test coverage: `99.68%`
- fault coverage: `98.79%`
- internal patterns: `215`

참고:

- [console.log](3_log/4_16_8ns_topo_ss/console.log)
- [tmax.log](3_log/4_16_8ns_topo_ss/tmax.log)
- [top_mcu_pll_sram_multiclk_soc.faults.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults.rpt)

즉 현재 상태는:

- ATPG 실행 자체는 정상 종료
- coverage 수치도 충분히 높음
- `ND=0`이므로 미검출 fault가 남아 있지는 않음

## 현재 리포트 해석

### 1. scan chain / DRC

- [top_mcu_pll_sram_multiclk_soc.scan_chains.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.scan_chains.rpt)

현재 확인된 체인:

- `chain0`
  - `scan_in -> scan_out`
  - length `383`
- `2`
  - `test_si2 -> test_so2`
  - length `383`
- `3`
  - `test_si3 -> test_so3`
  - length `383`
- `4`
  - `test_si4 -> test_so4`
  - length `383`

즉 총 scan FF `1532`개가 4개 chain으로 균등하게 나뉘어 있습니다.

DRC 쪽에서는 최종적으로 `successful`로 끝났습니다. 다만 warning은 일부 남아 있습니다.

대표 warning:

- `C17 (clock connected to PO)` 4건
- build 단계의 `B6/B7/B8/B9/B10/B13`

현재 해석:

- `C17`은 clock observe output 구조 영향으로 보입니다.
- `B8/B9` 계열은 macro / black-box / ATPG 비기능 포트 영향이 섞여 있을 가능성이 큽니다.
- 현재 run에서는 fatal error로 이어지지 않았고 ATPG도 정상 완료됐습니다.

### 2. fault coverage

- [top_mcu_pll_sram_multiclk_soc.faults.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults.rpt)

핵심 수치는 아래처럼 보면 됩니다.

- `test coverage 99.68%`
- `fault coverage 98.79%`
- `ND 0`

해석:

- 패턴 생성은 충분히 잘 된 편입니다.
- 종료 이유도 crash가 아니라 coverage target 도달입니다.
- 현재 baseline에서는 “ATPG 실패”로 볼 근거는 없습니다.

### 3. 남은 AU / UD fault

- [top_mcu_pll_sram_multiclk_soc.faults_AU.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_AU.rpt)
- [top_mcu_pll_sram_multiclk_soc.faults_UD.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_UD.rpt)

현재 남은 fault는 주로 아래 성격입니다.

- `u_mem/u_sram` 관련 입출력 / 주소 / 제어 신호
- `u_pll/CLK_*`
- `test_mode`
- `u_ctrl/u_icg_aes` 주변 ICG / latch 경로

현재 해석:

- SRAM macro black-box 성격
- PLL black-box / observe 제약
- test constraint에 의해 막히는 fault

즉 현재 `AU`, `UD`는 “ATPG가 덜 돌았다”기보다 “구조적으로 ATPG가 접근하기 어려운 fault가 남아 있다”에 더 가깝습니다.

## 리포트 목록

현재 버전별 리포트는 `4_report/$ver/` 아래에 저장됩니다.

- `*.faults.rpt`
  - fault / pattern 요약
- `*.coverage_level_16.rpt`
  - hierarchy별 coverage 상세
- `*.scan_chains.rpt`
  - scan chain 정보
- `*.scan_cells.rpt`
  - scan cell 목록
- `*.nonscan_cells.rpt`
  - non-scan sequential 정보
- `*.constraints.rpt`
  - PI constraint
- `*.capture_masks.rpt`
  - capture mask
- `*.po_masks.rpt`
  - PO mask
- `*.feedback_paths.rpt`
  - feedback path 요약
- `*.faults_AU.rpt`
  - ATPG untestable fault 분석
- `*.faults_UD.rpt`
  - undetectable fault 분석
- `*.faults_ND.rpt`
  - not detected fault 분석

## 확인 포인트

ATPG 결과를 볼 때는 아래 순서가 좋습니다.

1. [3_log/4_16_8ns_topo_ss/console.log](3_log/4_16_8ns_topo_ss/console.log)
   - 실행 시각, 입력 파일, 전체 종료 여부 확인
2. [3_log/4_16_8ns_topo_ss/tmax.log](3_log/4_16_8ns_topo_ss/tmax.log)
   - DRC / ATPG 중간 진행 / 종료 이유 확인
3. [top_mcu_pll_sram_multiclk_soc.scan_chains.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.scan_chains.rpt)
   - chain 수와 길이 확인
4. [top_mcu_pll_sram_multiclk_soc.faults.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults.rpt)
   - coverage / pattern 수 / ND 확인
5. [top_mcu_pll_sram_multiclk_soc.faults_AU.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_AU.rpt)
   - 제약 때문에 막히는 fault 확인
6. [top_mcu_pll_sram_multiclk_soc.faults_UD.rpt](4_report/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc.faults_UD.rpt)
   - 구조적으로 탐지 어려운 fault 확인

## 현재 판단

현재 `4_16_8ns_topo_ss` 기준 ATPG는 아래처럼 정리할 수 있습니다.

- 실행은 정상적으로 끝남
- scan chain 구조는 정상적으로 인식됨
- DRC는 warning이 있지만 성공으로 종료됨
- 패턴 생성까지 완료됨
- coverage는 높고 `ND=0`
- 남은 `AU/UD`는 주로 SRAM / PLL / constraint / ICG 성격

즉 지금 단계에서는:

- ATPG flow 자체는 정상
- 다음에 더 볼 것은 “잔여 AU/UD를 줄일 가치가 있는가”입니다

## 같이 보면 좋은 다른 README

- 상위 개요: [../README.md](../README.md)
- DFT 입력 단계: [../4_DFT/README.md](../4_DFT/README.md)
- ATPG 전 timing 확인: [../6_STA/README.md](../6_STA/README.md)
