# functional 모드에서는 scan/test를 끈다
set_case_analysis 0 [get_ports scan_en]
set_case_analysis 0 [get_ports test_mode]

# netlist에 남아 있는 ICG 경로에 맞춰 clk_fast_aes를 다시 만든다
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
