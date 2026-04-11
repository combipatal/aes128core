# AES128 VCS Top-Level Verification Design

**Goal:** Build a VCS verification environment under `1_vcs` for `top_mcu_pll_sram_multiclk_soc`, using copied RTL files and a self-checking testbench that proves AES, CDC, SRAM, CRC, UART TX, and `done/pass` behavior end-to-end.

**Selected Approach:** Verify the synthesis top directly, not `soc_ctrl_multiclk_soc` in isolation. Mirror the `2_synthesis` directory shape so that the verification workspace is easy to understand and maintain.

## Scope

- DUT: `rtl/top_mcu_pll_sram_multiclk_soc.v`
- Verification entry point: `1_vcs`
- Supported checks:
  - top-level reset and start sequencing
  - AES known-answer behavior
  - fast-to-div2 CDC handoff
  - SRAM write/readback path
  - CRC32 generation over SRAM-read ciphertext bytes
  - UART transmission of 20 bytes
  - final `done` and `pass`

## Key Design Choices

### 1. Copy RTL into `1_vcs/1_input/rtl`

The VCS environment will use copied RTL files rather than symlinks or direct references to `rtl/`.

Reasons:
- matches the `2_synthesis/1_input/rtl` mental model
- gives a stable snapshot for verification work
- keeps VCS filelists local to `1_vcs`

Trade-off:
- copied RTL can drift from `rtl/` if changes are made later

Mitigation:
- the setup plan includes an explicit copy/sync step before compile

### 2. Verify the top with `test_mode=1`

The RTL top contains a PLL black-box instance in `rtl/PLL_bb_for_syn.v`. Using the top directly in simulation requires bypassing the PLL outputs.

Chosen method:
- do not compile with `+define+SIM`
- drive DUT input `test_mode=1`

Reason:
- `+define+SIM` forces `test_mode_int=0` inside the top, which disables the intended clock bypass path
- `test_mode=1` causes all internal clocks used by the design to be driven from `ref_clk`

### 3. Use `ref_clk = 100 MHz`

`soc_ctrl_multiclk_soc.v` sets:
- `UART_CLK_HZ = 100_000_000`
- `UART_BAUD = 115200`

With `test_mode=1`, `clk_div4_int` becomes `ref_clk`, so the cleanest simulation setup is:
- `ref_clk` period = `10ns`

This keeps UART timing consistent with the divider constants in the RTL.

### 4. Compile with `+define+SIM_EXTVEC`

The testbench will support both the built-in NIST vector and externally supplied vectors.

Chosen method:
- always compile with `+define+SIM_EXTVEC`
- select the test case at runtime with `+CASE=<name>`

Reason:
- one VCS binary can run all planned cases
- `aes_vec_valid=0` still exercises the default vector path
- `aes_vec_valid=1` enables additional known-answer tests

Important implication:
- for external-vector cases, DUT `pass` alone is not sufficient proof of AES correctness
- the testbench must compare observed UART bytes against expected ciphertext and expected CRC32

## Directory Layout

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
│   │   ├── aes128_core.v
│   │   ├── cdc_toggle_sync.v
│   │   ├── clk_div2_toggle.v
│   │   ├── crc32_byte.v
│   │   ├── icg_latch.v
│   │   ├── PLL_bb_for_syn.v
│   │   ├── soc_ctrl_multiclk_soc.v
│   │   ├── sram_wrap_1rw1024x8.v
│   │   ├── top_mcu_pll_sram_multiclk_soc.v
│   │   ├── uart_rx.v
│   │   └── uart_tx.v
│   └── tb/
│       └── tb_top_mcu_pll_sram_multiclk_soc.sv
├── 2_output/
│   └── <ver>/
│       ├── simv
│       ├── simv.daidir/
│       └── wave/
├── 3_log/
│   ├── <ver>_compile.log
│   └── <ver>_run.log
└── 4_report/
    └── <ver>/
        └── summary.log
```

## File Responsibilities

- `0_script/filelist.f`
  - local source list for VCS compile
- `0_script/vcs_opts.f`
  - VCS compile options only
- `0_script/run.csh`
  - create output folders, compile, run, and route logs
- `1_input/model/saed32sram.v`
  - copied SRAM behavioral model used by `sram_wrap_1rw1024x8`
- `1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv`
  - full self-checking TB

## Test Strategy

### Case A: `default_nist`

Inputs:
- `aes_vec_valid = 0`
- `start` pulse used

Expected results:
- ciphertext: `69c4e0d86a7b0430d8cdb78070b4c55a`
- crc32: `3f6ea62f`
- UART bytes:
  - `69 c4 e0 d8 6a 7b 04 30 d8 cd b7 80 70 b4 c5 5a 3f 6e a6 2f`
- `done = 1`
- `pass = 1`

### Case B: `ext_zero`

Inputs:
- `aes_vec_valid = 1`
- key: `00000000000000000000000000000000`
- pt: `00000000000000000000000000000000`

Expected results:
- ciphertext: `66e94bd4ef8a2c3b884cfa59ca342b2e`
- crc32: `e7270ef5`
- `done = 1`
- `pass = 1`

### Case C: `ext_ecb_nist`

Inputs:
- `aes_vec_valid = 1`
- key: `2b7e151628aed2a6abf7158809cf4f3c`
- pt: `6bc1bee22e409f96e93d7e117393172a`

Expected results:
- ciphertext: `3ad77bb40d7a3660a89ecaf32466ef97`
- crc32: `04647086`
- `done = 1`
- `pass = 1`

## Success Criteria

The environment is considered correct when all three cases:
- compile with VCS without unresolved module errors
- finish without timeout
- collect exactly 20 UART bytes
- match expected ciphertext bytes and CRC32 bytes
- assert `done`
- assert `pass`
- write a readable pass/fail summary to `4_report/<ver>/summary.log`

## Risks And Controls

- Risk: copied RTL diverges from source RTL
  - Control: keep an explicit copy task in the setup flow
- Risk: UART decode mis-samples bits
  - Control: derive UART bit timing directly from the same 100 MHz assumption as the DUT
- Risk: external-vector runs look green while AES output is wrong
  - Control: always use testbench byte-by-byte scoreboard as the final verdict
