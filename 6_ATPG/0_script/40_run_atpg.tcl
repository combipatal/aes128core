################################################################################
# 40_run_atpg.tcl
# - Configure fault model and ATPG options.
# - Generate stuck-at patterns for the scan-inserted design.
################################################################################

# Report and optimize toward overall fault coverage.
set_faults -fault_coverage

# Use the basic stuck-at model first because it is the standard entry point for ATPG study.
set_faults -model stuck

# Report faults in collapsed form to keep summary numbers easier to read.
set_faults -report collapsed

# Add all faults in the current ATPG model.
add_faults -all

# Treat undriven external buses as X during ATPG simulation.
set_buses -external_z X

# Propagate unknown clocks carefully and use multiple processes for faster simulation.
set_simulation -xclock_gives_xout -num_processes 4

# Use four processes so ATPG runs reasonably fast on the lab machine.
set_atpg -num_processes 4

# Adjacent fill is a simple pattern-fill choice that keeps the script easy to understand.
set_atpg -fill adjacent -coverage 98

# Allow the tool to merge similar patterns and store internal ATPG data.
set_atpg -merge high -decision random -store

# Start with a conservative power target for safer capture behavior.
set_atpg -power_budget min
set_atpg -power_effort high

# Run automatic ATPG for the currently selected stuck-at fault model.
run_atpg -auto

# Print the final ATPG settings and a summary into the log.
report_settings
report_summaries patterns faults memory_usage cpu_usage
