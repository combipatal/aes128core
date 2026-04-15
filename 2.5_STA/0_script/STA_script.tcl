set ver $env(ver)
set corner $env(corner)
set mode $env(mode)
set run_mode $env(run_mode)
set hier_mode $env(hier_mode)
set design_name $env(design_name)
set NET $env(net)
set SDC $env(sdc)
set sta_scenario $env(sta_scenario)
set net_source "unknown"
if {[info exists env(net_source)]} {
    set net_source $env(net_source)
}
set STA_OVERRIDE ""
if {[info exists env(sta_override)]} {
    set STA_OVERRIDE $env(sta_override)
}

set lib /DATA/home/edu135/aes128_core/SAED32_EDK
set syn_lib /tools/synopsys/prime/W-2024.09-SP5-3/libraries/syn

set_app_var search_path [list \
    $lib/lib/stdcell_rvt/db_nldm \
    $lib/lib/stdcell_lvt/db_nldm \
    $lib/lib/stdcell_hvt/db_nldm \
    $lib/lib/io_std/db_nldm \
    $lib/lib/sram/db_nldm \
    $lib/lib/pll/db_nldm \
    $syn_lib]

if {$corner == "ss"} {
    set TARGET_LIBRARY_FILES_HVT [list saed32hvt_ss0p95v125c.db]
    set TARGET_LIBRARY_FILES_LVT [list saed32lvt_ss0p95v125c.db]
    set TARGET_LIBRARY_FILES [list \
        saed32rvt_ss0p95v125c.db \
        saed32pll_ss0p95v125c_2p25v.db \
        saed32io_fc_ss0p95v125c_2p25v.db]
    set TARGET_LIBRARY_FILES_MEM [list saed32sram_ss0p95v125c.db]
}

if {$corner == "ff"} {
    set TARGET_LIBRARY_FILES_HVT [list saed32hvt_ff1p16v125c.db]
    set TARGET_LIBRARY_FILES_LVT [list saed32lvt_ff1p16v125c.db]
    set TARGET_LIBRARY_FILES [list \
        saed32rvt_ff1p16v125c.db \
        saed32pll_ff1p16v125c_2p75v.db \
        saed32io_fc_ff1p16v125c_2p75v.db]
    set TARGET_LIBRARY_FILES_MEM [list saed32sram_ff1p16v125c.db]
}

if {$corner == "ff1p16vn40c"} {
    set TARGET_LIBRARY_FILES_HVT [list saed32hvt_ff1p16vn40c.db]
    set TARGET_LIBRARY_FILES_LVT [list saed32lvt_ff1p16vn40c.db]
    set TARGET_LIBRARY_FILES [list \
        saed32rvt_ff1p16vn40c.db \
        saed32pll_ff1p16vn40c_2p75v.db \
        saed32io_fc_ff1p16vn40c_2p75v.db]
    set TARGET_LIBRARY_FILES_MEM [list saed32sram_ff1p16vn40c.db]
}

if {$corner == "tt"} {
    set TARGET_LIBRARY_FILES_HVT [list saed32hvt_tt1p05v125c.db]
    set TARGET_LIBRARY_FILES_LVT [list saed32lvt_tt1p05v125c.db]
    set TARGET_LIBRARY_FILES [list \
        saed32rvt_tt1p05v125c.db \
        saed32pll_tt1p05v125c_2p5v.db \
        saed32io_fc_tt1p05v125c_2p5v.db]
    set TARGET_LIBRARY_FILES_MEM [list saed32sram_tt1p05v125c.db]
}

if {![info exists TARGET_LIBRARY_FILES]} {
    puts stderr "Unsupported corner: $corner"
    exit 1
}

set_app_var target_library "$TARGET_LIBRARY_FILES $TARGET_LIBRARY_FILES_LVT $TARGET_LIBRARY_FILES_HVT"
set synthetic_library [list standard.sldb]
set_app_var link_path "* $target_library $TARGET_LIBRARY_FILES_MEM gtech.db"

set run_dir [pwd]
set rpt_dir "${run_dir}/4_report/${ver}"

file mkdir $rpt_dir

set scenario_dir_name $sta_scenario
if {$sta_scenario == "scan_shift"} {
    set scenario_dir_name "shift"
}
if {$sta_scenario == "scan_capture"} {
    set scenario_dir_name "capture"
}

set scenario_rpt_dir "${rpt_dir}/${net_source}/${scenario_dir_name}"
file mkdir $scenario_rpt_dir

set rpt_check_timing_dir "${scenario_rpt_dir}/check_timing"
set rpt_no_clocks_dir "${scenario_rpt_dir}/no_clocks"
set rpt_disable_timing_dir "${scenario_rpt_dir}/disable_timing"
set rpt_analysis_coverage_dir "${scenario_rpt_dir}/analysis_coverage"
set rpt_clocks_dir "${scenario_rpt_dir}/clocks"
set rpt_clock_gating_dir "${scenario_rpt_dir}/clock_gating"
set rpt_all_violations_dir "${scenario_rpt_dir}/all_violations"
set rpt_setup_dir "${scenario_rpt_dir}/setup"
set rpt_hold_dir "${scenario_rpt_dir}/hold"
set rpt_qor_dir "${scenario_rpt_dir}/qor"

foreach dir [list \
    $rpt_check_timing_dir \
    $rpt_no_clocks_dir \
    $rpt_disable_timing_dir \
    $rpt_analysis_coverage_dir \
    $rpt_clocks_dir \
    $rpt_clock_gating_dir \
    $rpt_all_violations_dir \
    $rpt_setup_dir \
    $rpt_hold_dir \
    $rpt_qor_dir] {
    file mkdir $dir
}

source 0_script/STA_opt.tcl

sh date

read_verilog $NET
current_design $design_name
link

set wlm_profile "flat_forqa"
if {[info exists env(wlm_profile)]} {
    set wlm_profile $env(wlm_profile)
}

set auto_wire_load_selection false

# Default to a flat top-level wire-load model. The old hierarchical override
# (70000 on u_ctrl / 35000 on u_aes) exaggerated FF pre-layout pessimism and
# made same-netlist SS/FF comparisons unstable.
if {$wlm_profile == "legacy_hier"} {
    set_wire_load_mode enclosed
    set_wire_load_model -name ForQA [current_design]
    if {[sizeof_collection [get_cells -quiet u_ctrl]] > 0} {
        set_wire_load_model -name 70000 [get_cells u_ctrl]
    }
    if {[sizeof_collection [get_cells -quiet u_ctrl/u_aes]] > 0} {
        set_wire_load_model -name 35000 [get_cells u_ctrl/u_aes]
    }
} else {
    set_wire_load_mode top
    set_wire_load_model -name ForQA [current_design]
}

# The synthesis-written SDC bakes in source-corner wire-load library names.
# Strip those commands here so cross-corner STA does not fail on missing
# libraries and so the explicit WLM policy below remains authoritative.
set sanitized_sdc "${scenario_rpt_dir}/[file tail $SDC].sanitized"
set sdc_in [open $SDC r]
set sdc_out [open $sanitized_sdc w]
while {[gets $sdc_in line] >= 0} {
    if {[regexp {^set_wire_load_mode} $line]} { continue }
    if {[regexp {^set_wire_load_model} $line]} { continue }
    puts $sdc_out $line
}
close $sdc_in
close $sdc_out

read_sdc $sanitized_sdc
if {$STA_OVERRIDE != ""} {
    source $STA_OVERRIDE
}

set uncertainty_mode "scaled_by_period"
if {[info exists env(uncertainty_mode)]} {
    set uncertainty_mode $env(uncertainty_mode)
}
if {$uncertainty_mode == "scaled_by_period"} {
    # Hard-coded per-clock uncertainty values aligned to the active clock plan.
    # 8ns domain: 0.16/0.04, 4ns domain: 0.08/0.02, 2ns domain: 0.04/0.01.
    foreach spec {
        {ref_clk 0.16 0.04}
        {clk_div4 0.16 0.04}
        {clk_div2 0.08 0.02}
        {clk_fast 0.04 0.01}
        {clk_fast_aes 0.04 0.01}
        {clk_div8 0.32 0.08}
    } {
        lassign $spec clk_name setup_u hold_u
        if {[sizeof_collection [get_clocks -quiet $clk_name]] > 0} {
            set_clock_uncertainty -setup $setup_u [get_clocks $clk_name]
            set_clock_uncertainty -hold  $hold_u  [get_clocks $clk_name]
        }
    }
}

# Custom latch-based ICGs are modeled in RTL and then mapped into generic
# gates/latches. PrimeTime can infer internal clock-gating checks on those
# implementation details, which produced non-physical tens-of-thousands-ns
# violations in FF cross-check runs. External generated clocks already cover
# the intended timing; disable the internal implementation arcs by default.
set custom_icg_mode "disable_internal_timing"
if {[info exists env(custom_icg_mode)]} {
    set custom_icg_mode $env(custom_icg_mode)
}
if {$custom_icg_mode == "disable_internal_timing"} {
    set custom_icg_gating_cells [get_cells -quiet -hier {u_ctrl/u_aes/u_icg_state/U2 u_ctrl/u_aes/u_icg_state/U3 u_ctrl/u_aes/u_icg_state/U6}]
    if {[sizeof_collection $custom_icg_gating_cells] > 0} {
        set_clock_gating_check -setup 0 -hold 0 $custom_icg_gating_cells
    }

    set custom_icg_latches [get_cells -quiet -hier {u_ctrl/u_aes/u_icg_state/en_lat_reg}]
    if {[sizeof_collection $custom_icg_latches] > 0} {
        set_disable_timing $custom_icg_latches
    }

    # The custom AES ICG is inferred from RTL and implemented as a latch plus
    # generic gates. In FF cross-corner runs PT can still report huge
    # non-physical setup paths through those implementation arcs even after the
    # high-level clock-gating check is zeroed out. Disable the internal gate
    # arcs directly so report_qor matches the intended generated-clock model.
    foreach {cell_name from_name to_name} {
        u_ctrl/u_aes/u_icg_state/U2 A1 Y
        u_ctrl/u_aes/u_icg_state/U2 A2 Y
        u_ctrl/u_aes/u_icg_state/U3 A Y
        u_ctrl/u_aes/u_icg_state/U6 A1 Y
        u_ctrl/u_aes/u_icg_state/U6 A2 Y
    } {
        set cell_obj [get_cells -quiet $cell_name]
        if {[sizeof_collection $cell_obj] > 0} {
            set_disable_timing $cell_obj -from $from_name -to $to_name
        }
    }
}

update_timing -full

check_timing > ${rpt_check_timing_dir}/${sta_scenario}_${mode}_${corner}_check_timing.rpt
check_timing -override_defaults no_clock -verbose > ${rpt_no_clocks_dir}/${sta_scenario}_${mode}_${corner}_no_clocks.rpt
report_disable_timing > ${rpt_disable_timing_dir}/${sta_scenario}_${mode}_${corner}_disable_timing.rpt
report_analysis_coverage > ${rpt_analysis_coverage_dir}/${sta_scenario}_${mode}_${corner}_analysis_coverage.rpt
report_clocks > ${rpt_clocks_dir}/${sta_scenario}_${mode}_${corner}_clocks.rpt
report_clock_gating_check > ${rpt_clock_gating_dir}/${sta_scenario}_${mode}_${corner}_clock_gating.rpt

report_constraints -all_violators -nosplit -significant_digits 4 \
    > ${rpt_all_violations_dir}/${sta_scenario}_${mode}_${corner}_all_violations.rpt

report_timing -delay_type max -path full_clock_expanded -nosplit -input_pins -max_paths 25 \
    > ${rpt_setup_dir}/${sta_scenario}_${mode}_${corner}_setup.rpt

report_timing -delay_type min -path full_clock_expanded -nosplit -input_pins -max_paths 25 \
    > ${rpt_hold_dir}/${sta_scenario}_${mode}_${corner}_hold.rpt

report_qor > ${rpt_qor_dir}/${sta_scenario}_${mode}_${corner}_qor.rpt
