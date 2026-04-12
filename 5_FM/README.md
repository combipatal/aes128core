# 5_FM

이 폴더는 `aes128_core`의 Formality(FM) 학습/실행용 환경입니다.

## 목적

- **r2n(pre-DFT FM)**: RTL ↔ synthesis mapped gate equivalence 확인
- **n2n(post-DFT FM)**: synthesis mapped gate ↔ DFT inserted gate equivalence 확인

## 기준 top

- `top_mcu_pll_sram_multiclk_soc`

## 입력 매핑

### r2n
- Reference: `../2_synthesis/1_input/rtl/*.v`
- Implementation: `../2_synthesis/2_output/${ver}/mapped/soc_gate.v`
- Guidance: `../2_synthesis/default.svf`

### n2n
- Reference: `../2_synthesis/2_output/${ver}/mapped/soc_gate.v`
- Implementation: `../3_DFT/2_output/${ver}/aes_128_internal.v`

## 기본 실행

### pre-DFT FM

```bash
cd /DATA/home/edu135/aes128_core/5_FM
csh run_r2n.csh
```

### post-DFT FM

```bash
cd /DATA/home/edu135/aes128_core/5_FM
csh run_n2n.csh
```

## 공부 포인트

1. `match` 전후 unmatched point 개수 확인
2. `verify` 이후 failing / aborted / unverified point 구분
3. `black_box.rpt`에서 PLL / SRAM 처리 확인
4. `constants.rpt`에서 `scan_en`, `test_mode`, `scan_in`이 제대로 묶였는지 확인
