# 2_synthesis

This directory contains the Design Compiler synthesis flow for `top_mcu_pll_sram_multiclk_soc`.

## Directory Layout

- `0_script/`
  - `synthesis_script.tcl`: main synthesis script
- `1_input/`
  - `rtl/`: RTL sources
  - `constraint/constraint.con`: timing constraints
- `2_output/`
  - versioned synthesis outputs (`mapped/`, `unmapped/`)
- `3_log/`
  - versioned DC logs
- `4_report/`
  - versioned reports (`qor`, `timing`, `area`, `constraint`, `clock`, `check_design`)
- `run.csh`
  - launch script for a single synthesis run

## Environment

This flow sources the project-level setup file:

- [`../.synopsys_dc.setup`](/DATA/home/edu135/aes128_core/.synopsys_dc.setup)

That file defines:

- library search paths
- target/link libraries
- RTL search path
- DC work library

## How To Run

Edit [`run.csh`](/DATA/home/edu135/aes128_core/2_synthesis/run.csh) and set the run version:

```csh
setenv ver 4_11_4_6p5ns
source ../.synopsys_dc.setup
dc_shell -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
```

Then run:

```bash
csh run.csh
```

## Versioned Outputs

The synthesis script reads the run tag from `env(ver)` and writes outputs under:

- `2_output/$ver/unmapped/`
- `2_output/$ver/mapped/`
- `4_report/$ver/`

This makes it easy to compare different target periods or synthesis options without overwriting previous results.

## Current Flow Notes

- Top module: `top_mcu_pll_sram_multiclk_soc`
- Compile style: `compile_ultra -scan` followed by incremental compile
- Reports generated:
  - `aes_chk_design.rpt`
  - `qor.rpt`
  - `timing.rpt`
  - `area.rpt`
  - `constraint.rpt`
  - `clock.rpt`

## Typical Debug Points

- If DC cannot find RTL files, check path case sensitivity under `1_input/rtl`.
- If mapped netlists still show unmapped logic, inspect:
  - `3_log/${ver}_syn_dc.log`
  - `4_report/$ver/area.rpt`
  - `4_report/$ver/qor.rpt`
- If setup fails, adjust `constraint.con` first before changing RTL.
- If hold remains slightly negative, treat it separately from setup closure.
