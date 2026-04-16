#!/bin/csh -f

# STA 실행 변수 기본값
if ( ! $?ver ) setenv ver 4_16_8ns_topo_ss
if ( ! $?corner ) setenv corner ss
if ( ! $?mode ) setenv mode synthcmp
if ( ! $?sta_scenario ) setenv sta_scenario func
if ( ! $?design_name ) setenv design_name top_mcu_pll_sram_multiclk_soc
if ( ! $?net_source ) setenv net_source synth

switch ("$net_source")
case synth:
    # 합성 netlist 기준 STA
    if ( ! $?net ) setenv net ../2_synthesis/2_output/${ver}/mapped/soc_gate.v
    if ( ! $?sdc ) setenv sdc ../2_synthesis/2_output/${ver}/mapped/soc_func.sdc
    if ( ! $?sdf_delay ) setenv sdf_delay ../2_synthesis/2_output/${ver}/mapped/soc_gate.sdf
    breaksw
case dft:
    # DFT netlist 기준 STA
    if ( ! $?net ) setenv net ../4_DFT/2_output/${ver}/aes_128_internal.v
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

if ( ! $?sdf_delay ) then
    echo "Missing SDF path"
    exit 1
endif
if ( ! -f "$sdf_delay" ) then
    echo "Missing SDF: $sdf_delay"
    exit 1
endif

switch ("$sta_scenario")
case func:
    # 기능 모드 제약
    setenv sta_override 1_input/constraint/func_pre_sta.tcl
    breaksw
case scan_shift:
    # scan shift 제약
    setenv sta_override 1_input/constraint/scan_shift_sta.tcl
    breaksw
case scan_capture:
    # scan capture 제약
    setenv sta_override 1_input/constraint/scan_capture_sta.tcl
    breaksw
default:
    echo "Unsupported sta_scenario: $sta_scenario"
    exit 1
endsw

mkdir -p 2_output
mkdir -p 3_log
mkdir -p 4_report/${ver}

# PrimeTime 실행
pt_shell -f 0_script/STA_script.tcl | tee 3_log/${ver}_${net_source}_${sta_scenario}_${mode}_${corner}_sta.log
