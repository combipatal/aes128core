# aes128_core

이 저장소는 AES128 기반 SoC 형태의 RTL, 기능 검증, 합성, DFT, STA, FM 플로우를 정리한 프로젝트입니다.

현재 기준 top module은 `top_mcu_pll_sram_multiclk_soc`이며, 내부에 다음과 같은 블록이 포함되어 있습니다.

- AES128 core
- UART RX/TX
- SRAM wrapper + SRAM macro
- PLL black-box
- clock divider
- CDC logic
- clock gating logic

## 전체 디렉터리 구조

```text
aes128_core/
├── 0_rtl/
├── 1_vcs/
│   ├── 0_script/
│   ├── 1_input/
│   ├── 2_output/
│   ├── 3_log/
│   └── 4_report/
├── 2_synthesis/
│   ├── 0_script/
│   ├── 1_input/
│   ├── 2_output/
│   ├── 3_log/
│   └── 4_report/
├── 3_DFT/
│   ├── 0_script/
│   ├── 2_output/
│   ├── 3_log/
│   └── 4_report/
├── 4_STA/
│   ├── 0_script/
│   ├── 1_input/
│   ├── 3_log/
│   └── 4_report/
├── 5_FM/
│   ├── 0_script/
│   ├── 2_output/
│   ├── 3_log/
│   └── 4_report/
├── SAED32_EDK/
├── docs/
└── .synopsys_dc.setup
```

## 디렉터리 설명

### `0_rtl/`

- 프로젝트의 기준 RTL 소스 폴더
- top 및 하위 모듈 원본을 보관

### `1_vcs/`

- VCS 기반 기능 검증 환경
- testbench, filelist, 실행 스크립트, 파형/로그/요약 리포트를 관리
- 자세한 내용은 [README.md](1_vcs/README.md) 참고

### `2_synthesis/`

- Design Compiler 기반 합성 환경
- RTL 복사본, constraint, 합성 스크립트, 결과 netlist/DDC/리포트를 관리
- 버전 태그(`ver`) 기준으로 결과를 나눠 저장
- 자세한 내용은 [README.md](2_synthesis/README.md) 참고

### `3_DFT/`

- DFT/scan insertion 환경
- 합성 결과 DDC를 입력으로 받아 single scan chain 기반 DFT 삽입을 수행
- DFT 로그, preview, pre/post DRC, scan chain 리포트를 관리
- 현재는 `ref_clk`, `scan_en`, `scan_in`, `scan_out`, `test_mode`를 기준으로 single scan chain을 구성
- 자세한 내용은 [README.md](3_DFT/README.md) 참고

### `SAED32_EDK/`

- SAED32 라이브러리/매크로/문서
- 표준셀, IO, PLL, SRAM 관련 `.db`, Verilog model, LEF/GDS 등의 기술 파일 포함
- 용량이 크므로 Git에는 포함하지 않도록 관리

### `docs/`

- 프로젝트 메모, 문서, 참고 자료 정리용 폴더
- 현재 FM 중심 개선 계획 문서:
  - [aes128_core_fm_flow_plan_2026-04-12.md](docs/aes128_core_fm_flow_plan_2026-04-12.md)

### `.synopsys_dc.setup`

- 프로젝트 공통 Synopsys 환경 설정 파일
- library search path, target/link library, work library를 정의

## 기본 진행 흐름

보통 작업 순서는 아래와 같습니다.

1. `0_rtl/` 기준으로 RTL 작성/수정
2. `1_vcs/`에서 기능 검증
3. `2_synthesis/`에서 합성 및 timing/area 확인
4. `3_DFT/`에서 scan insertion 및 DFT 리포트 확인
5. `4_STA/`에서 functional / scan scenario STA 확인
6. `5_FM/`에서 r2n / n2n equivalence 확인

각 단계는 앞 단계 결과를 다음 단계 입력으로 사용합니다.

- `0_rtl -> 1_vcs`
- `0_rtl -> 2_synthesis`
- `2_synthesis/mapped DDC -> 3_DFT`
- `3_DFT/netlist + 2_synthesis SDC -> 4_STA`
- `RTL <-> synthesis gate -> 5_FM/r2n`
- `synthesis gate <-> DFT gate -> 5_FM/n2n`

## 실행 기준

### 기능 검증

- `1_vcs/0_script/run.csh`

### 합성

- `2_synthesis/run.csh`

### DFT

- `3_DFT/run.csh`

### STA

- `4_STA/run.csh`

### FM

- `5_FM/run_r2n.csh`
- `5_FM/run_n2n.csh`

각 단계는 보통 `ver` 환경변수를 기준으로 결과 폴더를 분리합니다.

예:

```csh
setenv ver 4_11_4_6p5ns
```

## 현재 작업 시 주의사항

- Linux 환경에서는 경로 대소문자를 정확히 맞춰야 합니다
- 합성/DFT 결과는 `2_output/`, `3_log/`, `4_report/` 아래 버전별로 누적됩니다
- PLL/SRAM macro는 black-box 또는 macro cell로 다뤄지므로 일반 RTL처럼 보지 않아야 합니다
- setup과 hold는 분리해서 해석해야 합니다
- DFT 후 timing은 보통 pre-DFT보다 나빠질 수 있습니다

## 현재 상태 메모

현재 권장 baseline은 `4_13_7p3ns`입니다.

- VCS regression 3종은 통과 상태입니다.
  - `default_nist`
  - `ext_zero`
  - `ext_ecb_nist`
- synthesis baseline:
  - target period `7.3ns`
  - `GTECH_NOT` 제거 완료
  - setup clean
  - `clk_div2` -> SRAM interface hold violation `12`개 잔존
- DFT baseline:
  - single scan chain 삽입 성공
  - `scan_in -> chain0 -> scan_out`
  - chain length `1532`
  - dedicated scan-out port 생성 없이 기존 `scan_out` 포트 재사용
- STA baseline:
  - func / capture / shift 3개 scenario 모두 다시 정리됨
  - functional `clk_fast_aes` setup slack `0.0000ns`
  - functional / capture / shift 기준 SRAM interface hold violation `12`개 잔존
  - `scan_shift`는 generic-cell 문제는 사라졌지만 `no_input_delay` 2개가 아직 남아 있음
- FM baseline:
  - r2n PASS
  - n2n PASS
  - n2n은 functional equivalence 기준으로 `scan_out`를 `dont_verify` 처리

즉 현재 상태는 "generic-free clean baseline은 확보했지만, 실무형 signoff 관점에서는 hold closure와 constraint refinement가 남아 있는 상태"로 보는 것이 맞습니다.

## 최근 반영 결과

- synthesis에서 `u_mem` wrapper 전체 `dont_touch`를 제거하고 실제 mapping이 되도록 수정했습니다.
- 그 결과:
  - synthesis mapped netlist에서 `GTECH_NOT` 제거
  - DFT netlist에서도 generic cell 제거
  - FM r2n / n2n PASS 유지

다만 이 변경 이후:

- area와 net area는 다소 증가
- `clk_fast_aes` margin은 더 얇아짐
- SRAM interface hold 12개는 여전히 남아 있음

즉 `4_13_7p3ns`는 "더 깨끗한 baseline"이지만, 아직 "더 최적화된 baseline"은 아닙니다.

## 현재 가장 먼저 손봐야 할 항목

다음 우선순위는 아래 순서가 적절합니다.

1. VCS / synthesis / FM source list를 단일 manifest로 정리
2. sim-only external AES vector interface를 production top과 분리
3. `scan_shift` STA 제약 강화
4. SRAM interface hold violation 12개 closure
5. 이후 DFT multi-chain / PPA 재정리

자세한 분석과 실행 계획은 아래 문서를 기준으로 봅니다.

- [aes128_core_fm_flow_plan_2026-04-12.md](docs/aes128_core_fm_flow_plan_2026-04-12.md)

## Git 관리 기준

현재 저장소에서는 보통 아래 항목은 Git에 포함하지 않습니다.

- `SAED32_EDK/`
- 합성 결과물 (`2_output/`)
- 로그 (`3_log/`)
- 리포트 (`4_report/`)
- work/alib 같은 툴 생성물

즉 Git에는 주로 다음을 남깁니다.

- RTL
- constraint
- Tcl / csh 스크립트
- README / 문서
