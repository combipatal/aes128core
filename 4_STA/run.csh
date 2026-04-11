#!/bin/csh -f

# STA run configuration
setenv ver 4_11_6_7ns
setenv corner ss0p95v125c
setenv mode pre
setenv run_mode pre
setenv hier_mode top
setenv design_name top_mcu_pll_sram_multiclk_soc

# DFT output netlist used for STA
setenv net ../3_DFT/2_output/${ver}/aes_128_internal.v
setenv sdc ../2_synthesis/2_output/${ver}/mapped/soc_func.sdc

# Output directories
mkdir -p 2_output
mkdir -p 3_log
mkdir -p 4_report/${ver}

# Launch PrimeTime
pt_shell -f 0_script/STA_script.tcl | tee 3_log/${ver}_${mode}_${corner}_sta.log
