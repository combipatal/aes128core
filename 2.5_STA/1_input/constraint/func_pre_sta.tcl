set_case_analysis 0 [get_ports scan_en]
set_case_analysis 0 [get_ports test_mode]

# Recreate the AES generated clock using whichever ICG path exists in the
# current mapped netlist. The design has used both the controller-level
# u_ctrl/u_icg_aes and the temporary internal u_ctrl/u_aes/u_icg_state paths.
if {[sizeof_collection [get_clocks -quiet clk_fast_aes]] == 0} {
    if {[sizeof_collection [get_pins -quiet u_ctrl/u_icg_aes/gclk]] > 0} {
        create_generated_clock [get_pins u_ctrl/u_icg_aes/gclk] \
            -name clk_fast_aes \
            -source [get_pins u_ctrl/u_icg_aes/clk] \
            -combinational
    } elseif {[sizeof_collection [get_pins -quiet u_ctrl/u_aes/u_icg_state/gclk]] > 0} {
        create_generated_clock [get_pins u_ctrl/u_aes/u_icg_state/gclk] \
            -name clk_fast_aes \
            -source [get_pins u_ctrl/u_aes/u_icg_state/clk] \
            -combinational
    }
}
