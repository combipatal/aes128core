# 1_vcs

이 디렉터리는 `top_mcu_pll_sram_multiclk_soc`의 RTL 기능 검증용 VCS 워크스페이스입니다.

현재 목적:

- `../0_rtl`의 top-level RTL을 실제 top 기준으로 시뮬레이션
- AES 결과, CRC32, UART 출력, `done/pass`를 end-to-end로 확인
- 이후 합성 기준으로 쓸 RTL baseline이 기능적으로 맞는지 먼저 확인

## 현재 구조

- [0_script/run.csh](0_script/run.csh)
  - 기본 3개 testcase를 순서대로 compile / run
- [0_script/filelist.f](0_script/filelist.f)
  - RTL source는 `../0_rtl/*.v`를 직접 참조
- [0_script/vcs_opts.f](0_script/vcs_opts.f)
  - VCS compile option
- [1_input/model/saed32sram.v](1_input/model/saed32sram.v)
  - SRAM simulation model
- [1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv](1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv)
  - self-checking testbench
- [1_input/tb/top_mcu_pll_sram_multiclk_soc_tbwrap.sv](1_input/tb/top_mcu_pll_sram_multiclk_soc_tbwrap.sv)
  - top wrapper

참고:

- `1_input/rtl/`는 현재 비어 있는 legacy 자리이고, compile source로 사용하지 않습니다.
- 실제 RTL은 `../0_rtl`를 직접 읽습니다.

## 테스트 시나리오

현재 기본 regression 대상은 아래 3개입니다.

- `default_nist`
  - 내부 기본 벡터
  - expected ciphertext: `69c4e0d86a7b0430d8cdb78070b4c55a`
  - expected CRC32: `3f6ea62f`
- `ext_zero`
  - all-zero external vector
  - expected ciphertext: `66e94bd4ef8a2c3b884cfa59ca342b2e`
  - expected CRC32: `e7270ef5`
- `ext_ecb_nist`
  - ECB known-answer vector
  - expected ciphertext: `3ad77bb40d7a3660a89ecaf32466ef97`
  - expected CRC32: `04647086`

## 실행 방법

```bash
cd /DATA/home/edu135/aes128_core/1_vcs
./0_script/run.csh
```

개별 testcase 실행:

```bash
env case_name=default_nist ./0_script/run.csh
env case_name=ext_zero ./0_script/run.csh
env case_name=ext_ecb_nist ./0_script/run.csh
```

전체 testcase를 명시적으로 다시 실행:

```bash
env case_name=all ./0_script/run.csh
```

## 생성물

- 실행 바이너리: `2_output/<case>/simv`
- compile log: `3_log/<case>_compile.log`
- run log: `3_log/<case>_run.log`
- summary: `4_report/<case>/summary.log`
- waveform: `2_output/<case>/wave/<case>.vcd`

## 현재 상태

현재 저장된 summary 기준으로 3개 testcase가 모두 PASS입니다.

- [default_nist/summary.log](4_report/default_nist/summary.log)
  - `done=1`, `pass=1`
- [ext_zero/summary.log](4_report/ext_zero/summary.log)
  - `done=1`, `pass=1`
- [ext_ecb_nist/summary.log](4_report/ext_ecb_nist/summary.log)
  - `done=1`, `pass=1`

즉 현재 `1_vcs`는 기능 회귀 기준으로는 적절한 상태입니다.

## 확인 포인트

VCS 결과를 다시 볼 때는 아래 순서가 가장 빠릅니다.

1. `4_report/<case>/summary.log`
   - pass/fail과 UART byte를 바로 확인
2. `3_log/<case>_run.log`
   - runtime 에러나 timeout 여부 확인
3. `3_log/<case>_compile.log`
   - compile warning / error 확인
4. `2_output/<case>/wave/<case>.vcd`
   - 필요하면 waveform 확인

## 같이 보면 좋은 README

- 상위 개요: [../README.md](../README.md)
- 합성: [../2_synthesis/README.md](../2_synthesis/README.md)
