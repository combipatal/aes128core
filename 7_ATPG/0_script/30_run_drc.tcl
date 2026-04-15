################################################################################
# 30_run_drc.tcl
# - Run ATPG design-rule checks using the scan SPF from DFT.
################################################################################

# Allow async set/reset behavior that is common in real scan designs.
set_drc -allow_unstable_set_resets

# Use dynamic clock analysis because test_mode reroutes internal clocks from ref_clk.
set_drc -clock -dynamic -nodisturb_clock_grouping

# Run ATPG DRC using the scan protocol extracted from DFT.
run_drc $SPF_FILE
