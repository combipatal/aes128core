################################################################################
# aes128_core ATPG main flow
# - Keep the flow easy to read.
# - Each sourced script does one stage only.
################################################################################

source -e -v ./0_script/00_setup.tcl
source -e -v ./0_script/10_read_design.tcl
source -e -v ./0_script/20_build_model.tcl
source -e -v ./0_script/30_run_drc.tcl
source -e -v ./0_script/40_run_atpg.tcl
source -e -v ./0_script/50_write_patterns.tcl
source -e -v ./0_script/60_write_reports.tcl

# Exit cleanly when every stage finishes.
exit
