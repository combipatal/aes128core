set ver $env(ver)
set corner $env(corner)
set mode $env(mode)
set run_mode $env(run_mode)
set hier_mode $env(hier_mode)
set design_name $env(design_name)
set NET $env(net)
set SDC $env(sdc)

set lib ./1_input/SAED32_EDK
set syn_lib /tools/synopsys/prime/W-2024.09-SP5-3/libraries/syn

set_app_var search_path [list \
    $lib/sc/ss0p95v125c \
    $lib/sc/ff1p16vn40c \
    $lib/io \
    $lib/sram \
    $lib/pll \
    $syn_lib]

if {$corner == "ss0p95v125c"} {
    set TARGET_LIBRARY_FILES_HVT [list saed32hvt_ss0p95v125c.db]
    set TARGET_LIBRARY_FILES_LVT [list saed32lvt_ss0p95v125c.db]
    set TARGET_LIBRARY_FILES [list \
        saed32rvt_ss0p95v125c.db \
        saed32pll_ss0p95v125c_2p25v.db \
        saed32io_fc_ss0p95v125c_2p25v.db]
    set TARGET_LIBRARY_FILES_MEM [list saed32sram_ss0p95v125c.db]
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

set_app_var target_library "$TARGET_LIBRARY_FILES $TARGET_LIBRARY_FILES_LVT $TARGET_LIBRARY_FILES_HVT"
set_app_var synthetic_library [list standard.sldb]
set_app_var link_path "* $target_library $TARGET_LIBRARY_FILES_MEM gtech.db"

set run_dir [pwd]
set rpt_dir "${run_dir}/4_report/${ver}"

file mkdir $rpt_dir

source 0_script/STA_opt.tcl

sh date

read_verilog $NET
current_design $design_name
link
read_sdc $SDC

update_timing -full

check_timing > ${rpt_dir}/${mode}_${corner}_check_timing.rpt
check_timing -override_defaults no_clock -verbose > ${rpt_dir}/${mode}_${corner}_no_clocks.rpt

report_constraints -all_violators -nosplit -significant_digits 4 \
    > ${rpt_dir}/${mode}_${corner}_all_violations.rpt

report_timing -delay_type max -path full_clock_expanded -nosplit -input_pins -max_paths 25 \
    > ${rpt_dir}/${mode}_${corner}_setup.rpt

report_timing -delay_type min -path full_clock_expanded -nosplit -input_pins -max_paths 25 \
    > ${rpt_dir}/${mode}_${corner}_hold.rpt

report_qor > ${rpt_dir}/${mode}_${corner}_qor.rpt
