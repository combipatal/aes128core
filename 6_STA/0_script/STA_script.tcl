# 실행 변수 읽기
set ver $env(ver)
set corner $env(corner)
set mode $env(mode)
set design_name $env(design_name)
set NET $env(net)
set SDC $env(sdc)
set SDF_DELAY $env(sdf_delay)
set sta_scenario $env(sta_scenario)
set STA_OVERRIDE ""
if {[info exists env(sta_override)]} {
    set STA_OVERRIDE $env(sta_override)
}

# 라이브러리 경로 설정
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

# 사용할 논리 라이브러리 묶기
set_app_var target_library "$TARGET_LIBRARY_FILES $TARGET_LIBRARY_FILES_LVT $TARGET_LIBRARY_FILES_HVT"
set synthetic_library [list standard.sldb]
set_app_var link_path "* $target_library $TARGET_LIBRARY_FILES_MEM gtech.db"

# 리포트 디렉터리 경로 만들기
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

set scenario_rpt_dir "${rpt_dir}/${scenario_dir_name}"
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

# PrimeTime 기본 옵션 읽기
source 0_script/STA_opt.tcl

sh date

# 넷리스트 읽고 링크하기
read_verilog $NET
current_design $design_name
link

# SDC에서는 wire-load 관련 명령만 제거하고 나머지 제약은 최대한 유지한다
set sanitized_sdc "${scenario_rpt_dir}/[file tail $SDC].sanitized"
set sdc_in [open $SDC r]
set sdc_out [open $sanitized_sdc w]
while {[gets $sdc_in line] >= 0} {
    if {[regexp {^set_wire_load_mode} $line]} { continue }
    if {[regexp {^set_wire_load_model} $line]} { continue }
    if {[regexp {^create_generated_clock \[get_pins u_ctrl/u_icg_aes/gclk\]} $line]} {
        set line {create_generated_clock [get_pins u_ctrl/u_icg_aes/U4/Y] -name clk_fast_aes -source [get_pins u_ctrl/u_icg_aes/U4/A1] -combinational}
    }
    if {[regexp {^create_generated_clock \[get_pins u_div8/clk_out\]} $line]} {
        set line {create_generated_clock [get_pins u_div8/clk_out_reg/Q] -name clk_div8 -source [get_pins u_div8/clk_out_reg/CLK] -divide_by 2}
    }
    puts $sdc_out $line
}
close $sdc_in
close $sdc_out

read_sdc $sanitized_sdc
if {$STA_OVERRIDE != ""} {
    source $STA_OVERRIDE
}

# post-DFT SDF 지연을 annotate 한다
puts "Info: post-DFT SDF 지연을 사용합니다: $SDF_DELAY"
read_sdf -type sdf_max $SDF_DELAY

# 클럭 불확실도는 클럭 주기별 고정값으로 다시 준다
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

# 최종 타이밍 계산
update_timing -full

# 주요 리포트 출력
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

exit
