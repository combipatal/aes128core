#!/bin/csh -f

# STA run configuration
if ( ! $?ver ) setenv ver 4_15_8ns_ff_holdfix_tcl6
if ( ! $?net_ver ) setenv net_ver ${ver}
if ( ! $?sdc_ver ) setenv sdc_ver 4_15_8ns_ff
if ( ! $?corner ) setenv corner ss
if ( ! $?mode ) setenv mode pre
if ( ! $?sta_scenario ) setenv sta_scenario scan_shift
if ( ! $?run_mode ) setenv run_mode pre
if ( ! $?hier_mode ) setenv hier_mode top
if ( ! $?design_name ) setenv design_name top_mcu_pll_sram_multiclk_soc

# DFT output netlist used for STA
if ( ! $?net ) setenv net ../3_DFT/2_output/${net_ver}/aes_128_internal.v
if ( ! $?sdc ) setenv sdc ../2_synthesis/2_output/${sdc_ver}/mapped/soc_func.sdc

if ( ! -f "$net" ) then
    echo "Missing netlist: $net"
    exit 1
endif

if ( ! -f "$sdc" ) then
    echo "Missing SDC: $sdc"
    exit 1
endif

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
