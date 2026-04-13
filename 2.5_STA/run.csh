#!/bin/csh -f

# STA run configuration
if ( ! $?ver ) setenv ver 4_13_7p3ns
if ( ! $?corner ) setenv corner ss0p95v125c
if ( ! $?mode ) setenv mode synthcmp
if ( ! $?sta_scenario ) setenv sta_scenario func
if ( ! $?run_mode ) setenv run_mode pre
if ( ! $?hier_mode ) setenv hier_mode top
if ( ! $?design_name ) setenv design_name top_mcu_pll_sram_multiclk_soc
if ( ! $?net_source ) setenv net_source synth

switch ("$net_source")
case synth:
    if ( ! $?net ) setenv net ../2_synthesis/2_output/${ver}/mapped/soc_gate.v
    if ( ! $?sdc ) setenv sdc ../2_synthesis/2_output/${ver}/mapped/soc_func.sdc
    breaksw
case dft:
    if ( ! $?net ) setenv net ../3_DFT/2_output/${ver}/aes_128_internal.v
    if ( ! $?sdc ) setenv sdc ../2_synthesis/2_output/${ver}/mapped/soc_func.sdc
    breaksw
default:
    echo "Unsupported net_source: $net_source"
    exit 1
endsw

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

mkdir -p 2_output
mkdir -p 3_log
mkdir -p 4_report/${ver}

pt_shell -f 0_script/STA_script.tcl | tee 3_log/${ver}_${net_source}_${sta_scenario}_${mode}_${corner}_sta.log
