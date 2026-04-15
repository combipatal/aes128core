#!/bin/csh -f

if ( ! $?ver ) setenv ver 4_15_8ns_ff
if ( ! $?eco_ver ) setenv eco_ver ${ver}_holdfix1

set in_net = ./2_output/${ver}/aes_128_internal.v
set out_dir = ./2_output/${eco_ver}

if ( ! -f "$in_net" ) then
    echo "Missing input netlist: $in_net"
    exit 1
endif

mkdir -p "$out_dir"
tclsh 0_script/post_dft_hold_eco.tcl "$in_net" "$out_dir"
