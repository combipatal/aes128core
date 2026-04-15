set_case_analysis 0 [get_ports scan_en]
set_case_analysis 0 [get_ports test_mode]

# Functional STA should not try to time scan input or async reset paths.
set_false_path -from [get_ports scan_in]
set_false_path -from [get_ports rst_n]

# Recreate the AES generated clock if the inserted netlist kept the ICG pin
# but the SDC did not resolve it cleanly.
if {[sizeof_collection [get_clocks -quiet clk_fast_aes]] == 0} {
    if {[sizeof_collection [get_pins -quiet u_ctrl/u_icg_aes/gclk]] > 0} {
        create_generated_clock [get_pins u_ctrl/u_icg_aes/gclk] \
            -name clk_fast_aes \
            -source [get_pins u_ctrl/u_icg_aes/clk] \
            -combinational
    }
}
