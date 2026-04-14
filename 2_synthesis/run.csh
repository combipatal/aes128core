if ( ! $?ver ) setenv ver 4_14_7.5ns_ff
if ( ! $?clk_period ) setenv clk_period 7.5
mkdir -p 3_log
source ../.synopsys_dc.setup
dc_shell -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
