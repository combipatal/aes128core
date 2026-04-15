################################################################################
# 60_write_reports.tcl
# - Dump the main ATPG reports that are useful for study and sign-off.
################################################################################

# Save short and full fault summaries in native tmax text form.
report_faults -summary > ./4_report/${ver}/${DESIGN_NAME}_sa_faults.tmax
report_faults -all > ./4_report/${ver}/${DESIGN_NAME}_sa_all_faults.tmax

# Save raw fault lists in all / collapsed / uncollapsed form.
write_faults ./4_report/${ver}/${DESIGN_NAME}.faults_all.rpt -all -replace
write_faults ./4_report/${ver}/${DESIGN_NAME}.faults_all_collapsed.rpt -all -collapsed -replace
write_faults ./4_report/${ver}/${DESIGN_NAME}.faults_all_uncollapsed.rpt -all -uncollapsed -replace

# Separate undetectable / ATPG-untestable / not-detected classes for debugging.
analyze_faults -class UD -verbose > ./4_report/${ver}/${DESIGN_NAME}.faults_UD.rpt
analyze_faults -class AU -verbose > ./4_report/${ver}/${DESIGN_NAME}.faults_AU.rpt
analyze_faults -class ND -verbose > ./4_report/${ver}/${DESIGN_NAME}.faults_ND.rpt

# Main summary report used first when judging ATPG quality.
report_summaries primitives faults patterns memory > ./4_report/${ver}/${DESIGN_NAME}.faults.rpt

# Structural reports help explain scan quality and leftover non-scan logic.
report_scan_chains > ./4_report/${ver}/${DESIGN_NAME}.scan_chains.rpt
report_scan_cells -all > ./4_report/${ver}/${DESIGN_NAME}.scan_cells.rpt
report_scan_cells -all -verbose > ./4_report/${ver}/${DESIGN_NAME}_scan_cells.verbose.rpt
report_nonscan_cells -all > ./4_report/${ver}/${DESIGN_NAME}.nonscan_cells.rpt
report_feedback_paths -all > ./4_report/${ver}/${DESIGN_NAME}.feedback_paths.rpt

# Constraint and masking reports are useful when diagnosing coverage loss.
report_pi_constraints > ./4_report/${ver}/${DESIGN_NAME}.constraints.rpt
report_po_masks > ./4_report/${ver}/${DESIGN_NAME}.po_masks.rpt
report_capture_masks > ./4_report/${ver}/${DESIGN_NAME}.capture_masks.rpt

# Coverage-by-hierarchy helps explain where residual faults remain.
report_fault -level 16 64 -all -verbose > ./4_report/${ver}/${DESIGN_NAME}.coverage_level_16.rpt

# Lockup-latch report is still useful even if this design is expected to be simple.
report_lockup_latches -gated_clocking -latch_based_balanced -pipeline > ./4_report/${ver}/${DESIGN_NAME}_lockup_latches.rpt

# Print one last summary at the end of the flow.
report_settings
report_summaries patterns faults memory_usage cpu_usage
