# 0_rtl

이 디렉터리는 `aes128_core` 프로젝트의 기준 RTL 소스 폴더입니다.

현재 후속 단계인 `1_vcs`, `2_synthesis`, `3_FM`, `4_DFT`는 모두 이 폴더의 RTL을 출발점으로 사용합니다.

## 현재 포함된 RTL

- [top_mcu_pll_sram_multiclk_soc.v](top_mcu_pll_sram_multiclk_soc.v)
  - 프로젝트 top
- [soc_ctrl_multiclk_soc.v](soc_ctrl_multiclk_soc.v)
  - SoC control / datapath orchestration
- [aes128_core.v](aes128_core.v)
  - AES128 core
- [aes_sbox.v](aes_sbox.v)
  - AES S-box
- [uart_rx.v](uart_rx.v), [uart_tx.v](uart_tx.v)
  - UART block
- [sram_wrap_1rw1024x8.v](sram_wrap_1rw1024x8.v)
  - SRAM wrapper
- [cdc_toggle_sync.v](cdc_toggle_sync.v), [clk_div2_toggle.v](clk_div2_toggle.v), [icg_latch.v](icg_latch.v), [crc32_byte.v](crc32_byte.v)
  - 보조 블록
- [PLL_bb_for_syn.v](PLL_bb_for_syn.v)
  - PLL stub / synthesis용 모델

중요:

- 현재 `0_rtl`에는 `aes128_core_rewrite.v` 파일이 없습니다.
- 따라서 이 저장소의 현재 기준 AES RTL은 [aes128_core.v](aes128_core.v)입니다.

## 현재 문서 기준으로 중요한 점

`0_rtl`은 기능만 맞는 RTL 모음이 아니라, 이후 합성 / FM / DFT / STA가 실제로 이어질 수 있는 기준 RTL이라는 점이 중요합니다.

즉 이 폴더는 아래 흐름의 시작점입니다.

- 기능 검증: [../1_vcs/README.md](../1_vcs/README.md)
- 합성: [../2_synthesis/README.md](../2_synthesis/README.md)
- r2n FM: [../3_FM/README.md](../3_FM/README.md)
- DFT: [../4_DFT/README.md](../4_DFT/README.md)

## 현재 해석

현재 저장소 상태 기준으로 `0_rtl` README에서 확실하게 말할 수 있는 내용은 아래입니다.

- `0_rtl`이 authoritative RTL source임
- 후속 flow는 이 RTL을 기준으로 연결됨
- 현재 AES core 파일은 `aes128_core.v`임

반대로, 현재 파일이 없는 `aes128_core_rewrite.v`를 기준으로 설명하는 것은 현재 저장소 상태와 맞지 않습니다.
