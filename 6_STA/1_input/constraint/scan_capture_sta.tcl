set_case_analysis 0 [get_ports scan_en]
set_case_analysis 1 [get_ports test_mode]

# In scan capture mode, treat ref_clk as the only test clock.
# Functional generated clocks from synthesis SDC are not useful here.
foreach clk_name {clk_fast clk_fast_aes clk_div2 clk_div4 clk_div8} {
    if {[sizeof_collection [get_clocks -quiet $clk_name]] > 0} {
        remove_clock [get_clocks $clk_name]
    }
}

set_input_delay -clock ref_clk -max 1.0 [get_ports scan_in]
set_input_delay -clock ref_clk -min 0.2 [get_ports scan_in]
set_output_delay -clock ref_clk -max 1.0 [get_ports scan_out]
set_output_delay -clock ref_clk -min 0.2 [get_ports scan_out]

# rst_n is async reset, not capture data.
set_false_path -from [get_ports rst_n]
