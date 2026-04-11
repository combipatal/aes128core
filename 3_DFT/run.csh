setenv ver 4_11_4_6p5ns
source ../.synopsys_dc.setup

file mkdir ./2_output/${ver}
file mkdir ./3_log
file mkdir ./4_report/${ver}


dc_shell -64  -f 0_script/DFT_script.tcl       | tee 3_log/${ver}_scan_dc.log
