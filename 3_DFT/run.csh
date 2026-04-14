if ( ! $?ver ) setenv ver 4_14_8ns_fix_F
source ../.synopsys_dc.setup

mkdir -p ./2_output/${ver}
mkdir -p ./3_log
mkdir -p ./4_report/${ver}


dc_shell -64  -f 0_script/DFT_script.tcl       | tee 3_log/${ver}_scan_dc.log
