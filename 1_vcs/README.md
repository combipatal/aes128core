# AES128 Core VCS Verification

이 디렉토리는 `top_mcu_pll_sram_multiclk_soc`를 VCS로 검증하기 위한 환경입니다.

## 목적

- `0_rtl/`의 top-level RTL을 실제로 시뮬레이션 가능한 형태로 검증
- AES 결과값, SRAM write/readback, CRC32, UART TX, `done/pass`를 end-to-end로 확인
- `2_synthesis`와 비슷한 구조로 정리해서 이후 유지보수가 쉽도록 구성

## 디렉토리 구조

```text
1_vcs/
├── 0_script/
│   ├── filelist.f
│   ├── vcs_opts.f
│   └── run.csh
├── 1_input/
│   ├── model/
│   │   └── saed32sram.v
│   ├── rtl/
│   └── tb/
│       └── tb_top_mcu_pll_sram_multiclk_soc.sv
├── 2_output/
│   ├── default_nist/
│   ├── ext_zero/
│   └── ext_ecb_nist/
├── 3_log/
└── 4_report/
```

생성물은 기본적으로 각 testcase 이름 기준으로 분리됩니다.

- `2_output/<case>/simv`
- `2_output/<case>/csrc`
- `2_output/<case>/wave/<case>.vcd`
- `3_log/<case>_compile.log`
- `3_log/<case>_run.log`
- `4_report/<case>/summary.log`

`ucli.key` 같은 VCS 임시 파일은 실행 후 정리되도록 했습니다.

## 무엇을 어떻게 했는지

### 1. Top-level 기준으로 검증

- DUT는 `top_mcu_pll_sram_multiclk_soc`입니다.
- `soc_ctrl_multiclk_soc` 단독이 아니라 실제 top을 올려서 검증합니다.
- RTL compile source는 `1_vcs/1_input/rtl/` 복제본이 아니라 상위 경로의 `../0_rtl/`입니다.

### 2. PLL 처리 방식

- `PLL_bb_for_syn.v`는 black-box stub 형태입니다.
- 시뮬레이션에서는 `+define+SIM`을 쓰지 않고, TB에서 `test_mode=1`을 drive합니다.
- 그러면 top 내부에서 PLL 출력 대신 `ref_clk`가 내부 클록으로 bypass됩니다.

이 방식으로 별도 PLL behavioral model 없이도 top 시뮬레이션이 가능합니다.

### 3. SRAM 처리 방식

- `sram_wrap_1rw1024x8.v`는 내부에서 `SRAM1RW1024x8` 라이브러리 셀을 인스턴스합니다.
- 따라서 시뮬레이션에서는 wrapper만 넣으면 안 되고, 실제 모델도 함께 compile해야 합니다.
- 이 환경에서는 `SAED32_EDK/lib/sram/verilog/saed32sram.v`를 `1_input/model/saed32sram.v`로 복제해 filelist에 포함했습니다.

즉, SRAM은 behavioral stub로 대체하지 않고 SAED 모델을 그대로 사용합니다.

### 4. VCS 실행 방식

- 이 머신에서는 `vcs1` 직접 호출 경로에서 compile backend가 `SIGSEGV`를 내는 경우가 있었습니다.
- 그래서 `run.csh`는 `vcs -full64` wrapper를 사용합니다.
- 실행 전에는 반드시 `/DATA/home/edu135/.bashrc`를 source해야 합니다.

## 테스트벤치에서 확인하는 항목

`1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv`는 self-checking TB입니다.
RTL source file은 `0_script/filelist.f`를 통해 `../0_rtl/*.v`를 직접 읽습니다.

확인 항목:
- `done == 1`
- `pass == 1`
- UART로 정확히 20바이트가 전송되는지
- 앞 16바이트가 expected ciphertext와 일치하는지
- 뒤 4바이트가 expected CRC32와 일치하는지
- timeout 없이 완료되는지

## 테스트 시나리오

### 1. `default_nist`

- 내부 기본 벡터 사용 (`aes_vec_valid=0`)
- Expected ciphertext:
  - `69c4e0d86a7b0430d8cdb78070b4c55a`
- Expected CRC32:
  - `3f6ea62f`

### 2. `ext_zero`

- 외부 벡터 사용 (`aes_vec_valid=1`)
- Key:
  - `00000000000000000000000000000000`
- Plaintext:
  - `00000000000000000000000000000000`
- Expected ciphertext:
  - `66e94bd4ef8a2c3b884cfa59ca342b2e`
- Expected CRC32:
  - `e7270ef5`

### 3. `ext_ecb_nist`

- 외부 벡터 사용 (`aes_vec_valid=1`)
- Key:
  - `2b7e151628aed2a6abf7158809cf4f3c`
- Plaintext:
  - `6bc1bee22e409f96e93d7e117393172a`
- Expected ciphertext:
  - `3ad77bb40d7a3660a89ecaf32466ef97`
- Expected CRC32:
  - `04647086`

## 실행 방법

루트 경로:

```bash
cd /DATA/home/edu135/aes128_core/1_vcs
source /DATA/home/edu135/.bashrc
```

기본 실행:

```bash
./0_script/run.csh
```

위 명령은 아래 3개 케이스를 순서대로 모두 실행합니다.

- `default_nist`
- `ext_zero`
- `ext_ecb_nist`

개별 케이스 실행:

```bash
env case_name=default_nist ./0_script/run.csh
env case_name=ext_zero ./0_script/run.csh
env case_name=ext_ecb_nist ./0_script/run.csh
```

전체 케이스를 명시적으로 다시 실행:

```bash
env case_name=all ./0_script/run.csh
```

## 결과 확인 위치

- compile log:
  - `3_log/<case>_compile.log`
- run log:
  - `3_log/<case>_run.log`
- testcase summary:
  - `4_report/<case>/summary.log`
- waveform:
  - `2_output/<case>/wave/<case>.vcd`

summary에는 UART byte log와 pass/fail 판정이 함께 남고, waveform은 VCD로 저장됩니다.

## 현재 검증 완료 상태

현재 기본 regression 대상 케이스:
- `default_nist`
- `ext_zero`
- `ext_ecb_nist`

이 환경은 현재 위 3개 known-answer case를 기본 회귀 대상으로 사용합니다.
추가 케이스를 넣으려면 `tb_top_mcu_pll_sram_multiclk_soc.sv`의 `load_case()`에 벡터와 기대값을 추가하면 됩니다.

각 케이스는 다음 조건을 만족하도록 확인했습니다.
- UART 20바이트 일치
- `done=1`
- `pass=1`
- summary log 생성
- waveform 생성
