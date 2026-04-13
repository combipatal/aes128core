# STA Comparison for 4_13_7p3ns vs 4_13_7p3ns_ff

Source workspace: `/DATA/home/edu135/aes128_core/2.5_STA`

Net source used for all four runs: `synth`

## Run matrix

| Netlist version | Corner | Result summary |
|---|---|---|
| `4_13_7p3ns` | `ss0p95v125c` | setup clean, only small `clk_div2` hold violations remain |
| `4_13_7p3ns` | `ff1p16v125c` | setup catastrophically broken across `INS`, `clk_div2`, `clk_fast`, `clk_fast_aes` |
| `4_13_7p3ns_ff` | `ss0p95v125c` | mild setup violations remain in `INS`, `clk_fast`, `clk_fast_aes` |
| `4_13_7p3ns_ff` | `ff1p16v125c` | reproduces the expected bad FF behavior, worst in `clk_fast_aes` and `clk_div2` |

## Key observations

### `4_13_7p3ns @ SS`

- QOR report:
  - [func_synthcmp_ss0p95v125c_qor.rpt](/DATA/home/edu135/aes128_core/2.5_STA/4_report/4_13_7p3ns/synth/func/qor/func_synthcmp_ss0p95v125c_qor.rpt)
- Summary:
  - `clk_fast_aes` setup slack `0.0003`
  - `clk_div2` setup slack `1.2460`
  - `clk_fast` setup slack `0.7951`

### `4_13_7p3ns @ FF125`

- QOR report:
  - [func_synthcmp_ff1p16v125c_qor.rpt](/DATA/home/edu135/aes128_core/2.5_STA/4_report/4_13_7p3ns/synth/func/qor/func_synthcmp_ff1p16v125c_qor.rpt)
- Summary:
  - `INS` slack `-100.0914`
  - `clk_div2` slack `-2913.7942`
  - `clk_fast` slack `-9006.9590`
  - `clk_fast_aes` slack `-1992.2627`
- Worst path report:
  - [func_synthcmp_ff1p16v125c_setup.rpt](/DATA/home/edu135/aes128_core/2.5_STA/4_report/4_13_7p3ns/synth/func/setup/func_synthcmp_ff1p16v125c_setup.rpt)

### `4_13_7p3ns_ff @ SS`

- QOR report:
  - [func_synthcmp_ss0p95v125c_qor.rpt](/DATA/home/edu135/aes128_core/2.5_STA/4_report/4_13_7p3ns_ff/synth/func/qor/func_synthcmp_ss0p95v125c_qor.rpt)
- Summary:
  - `INS` slack `-0.1873`
  - `clk_fast` slack `-0.2015`
  - `clk_fast_aes` slack `-0.5306`
  - `clk_div2` setup is clean

### `4_13_7p3ns_ff @ FF125`

- QOR report:
  - [func_synthcmp_ff1p16v125c_qor.rpt](/DATA/home/edu135/aes128_core/2.5_STA/4_report/4_13_7p3ns_ff/synth/func/qor/func_synthcmp_ff1p16v125c_qor.rpt)
- Summary:
  - `INS` slack `-1.2291`
  - `clk_div2` slack `-5.1277`
  - `clk_fast` slack `-3.9723`
  - `clk_fast_aes` slack `-7.6001`
- Worst path report:
  - [func_synthcmp_ff1p16v125c_setup.rpt](/DATA/home/edu135/aes128_core/2.5_STA/4_report/4_13_7p3ns_ff/synth/func/setup/func_synthcmp_ff1p16v125c_setup.rpt)

## Interpretation

- The bad FF behavior is not explained by FF re-synthesis alone.
- The `SS` netlist (`4_13_7p3ns`) also collapses when analyzed at `FF125`, and in fact collapses far more severely than the FF-resynthesized netlist.
- The FF-resynthesized netlist is still bad at `FF125`, but it is only mildly bad at `SS`.
- This points to a strong corner sensitivity / same-netlist cross-corner issue in addition to any FF re-synthesis mapping effects.

## Next focus

1. Investigate why `4_13_7p3ns @ FF125` produces extreme delay explosions in PT.
2. Compare worst-path topology between:
   - `4_13_7p3ns @ FF125`
   - `4_13_7p3ns_ff @ FF125`
3. Re-check whether the generated-clock / path interaction in FF is being modeled as intended, especially around:
   - `clk_fast`
   - `clk_fast_aes`
   - `ct_hold_fast_reg[*]`
   - AES state path logic
