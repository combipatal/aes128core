#!/bin/csh -f

# Default ATPG result version.
if ( ! $?ver ) setenv ver 4_15_8ns_ff_holdfix_tcl6_atpg

# Default input netlist/SPF version from the final post-DFT ECO baseline.
if ( ! $?input_ver ) setenv input_ver 4_15_8ns_ff_holdfix_tcl6

# Top module name used in the DFT netlist.
if ( ! $?top ) setenv top top_mcu_pll_sram_multiclk_soc

# Final post-DFT ECO netlist used for ATPG.
if ( ! $?netlist ) setenv netlist ../3_DFT/2_output/${input_ver}/aes_128_internal.v

# Internal scan SPF generated during DFT insertion.
if ( ! $?spf ) setenv spf ../3_DFT/2_output/${input_ver}/scan_internal.spf

# Create result directories before launching the tool.
mkdir -p 2_output/${ver}
mkdir -p 3_log/${ver}
mkdir -p 4_report/${ver}

# Stop early if the ATPG input netlist is missing.
if ( ! -e ${netlist} ) then
  echo "ERROR: netlist not found -> ${netlist}"
  exit 1
endif

# Stop early if the scan SPF is missing.
if ( ! -e ${spf} ) then
  echo "ERROR: SPF not found -> ${spf}"
  exit 1
endif

# Launch TestMAX / TetraMAX in Tcl mode with the main flow script.
tmax -64 -tcl -shell ./0_script/main.tcl |& tee 3_log/${ver}/console.log
