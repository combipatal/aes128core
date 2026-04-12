#!/bin/csh -f

# STA run configuration
if ( ! $?ver ) setenv ver 4_12_7p3ns
setenv corner ss0p95v125c
setenv mode pre
if ( ! $?sta_scenario ) setenv sta_scenario func
setenv run_mode pre
setenv hier_mode top
setenv design_name top_mcu_pll_sram_multiclk_soc

# DFT output netlist used for STA
setenv net ../3_DFT/2_output/${ver}/aes_128_internal.v
setenv sdc ../2_synthesis/2_output/${ver}/mapped/soc_func.sdc

switch ("$sta_scenario")
case func:
    setenv sta_override 1_input/constraint/func_pre_sta.tcl
    breaksw
case scan_shift:
    setenv sta_override 1_input/constraint/scan_shift_sta.tcl
    breaksw
case scan_capture:
    setenv sta_override 1_input/constraint/scan_capture_sta.tcl
    breaksw
default:
    echo "Unsupported sta_scenario: $sta_scenario"
    exit 1
endsw

# Output directories
mkdir -p 2_output
mkdir -p 3_log
mkdir -p 4_report/${ver}

# Launch PrimeTime
pt_shell -f 0_script/STA_script.tcl | tee 3_log/${ver}_${sta_scenario}_${mode}_${corner}_sta.log
