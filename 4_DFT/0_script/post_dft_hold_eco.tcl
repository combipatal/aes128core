proc fail {msg} {
    puts stderr $msg
    exit 1
}

if {$argc != 2} {
    fail "Usage: tclsh 0_script/post_dft_hold_eco.tcl <input_netlist> <output_dir>"
}

set input_netlist [file normalize [lindex $argv 0]]
set output_dir [file normalize [lindex $argv 1]]

if {![file exists $input_netlist]} {
    fail "Missing input netlist: $input_netlist"
}

file mkdir $output_dir

set fp [open $input_netlist r]
set text [read $fp]
close $fp

if {[string first "HOLD_ECO_A_INV0_0" $text] >= 0} {
    fail "Input netlist already appears to contain this hold ECO."
}

set wire_block_old [join {
    {  wire   [3:0] mem_addr;}
    {  wire   [7:0] mem_wdata;}
    {  wire   [7:0] mem_rdata;}
} "\n"]

set wire_block_new [join {
    {  wire   [3:0] mem_addr;}
    {  wire   [3:0] mem_addr_holdfix_n;}
    {  wire   [3:0] mem_addr_holdfix;}
    {  wire   [7:0] mem_wdata;}
    {  wire   [7:0] mem_wdata_holdfix_n;}
    {  wire   [7:0] mem_wdata_holdfix;}
    {  wire   [7:0] mem_rdata;}
} "\n"]

set eco_lines {}
for {set idx 0} {$idx < 4} {incr idx} {
    lappend eco_lines [format {  INVX0_RVT HOLD_ECO_A_INV0_%d ( .A(mem_addr[%d]), .Y(mem_addr_holdfix_n[%d]) );} $idx $idx $idx]
    lappend eco_lines [format {  INVX0_RVT HOLD_ECO_A_INV1_%d ( .A(mem_addr_holdfix_n[%d]), .Y(mem_addr_holdfix[%d]) );} $idx $idx $idx]
}
for {set idx 0} {$idx < 8} {incr idx} {
    lappend eco_lines [format {  INVX0_RVT HOLD_ECO_I_INV0_%d ( .A(mem_wdata[%d]), .Y(mem_wdata_holdfix_n[%d]) );} $idx $idx $idx]
    lappend eco_lines [format {  INVX0_RVT HOLD_ECO_I_INV1_%d ( .A(mem_wdata_holdfix_n[%d]), .Y(mem_wdata_holdfix[%d]) );} $idx $idx $idx]
}
set eco_block [join $eco_lines "\n"]

if {[string first $wire_block_old $text] < 0} {
    fail "Could not find the expected SRAM bus wire block."
}
set text [string map [list $wire_block_old $wire_block_new] $text]

set sram_block_old "  SRAM1RW1024x8 u_mem_u_sram ( .I(mem_wdata), .O(mem_rdata), .A({1'b0, 1'b0, \n        1'b0, 1'b0, 1'b0, 1'b0, mem_addr}), .CE(clk_div2), .CSB(mem_cs), .WEB(\n        mem_we), .OEB(mem_oe) );"
set sram_block_new "  SRAM1RW1024x8 u_mem_u_sram ( .I(mem_wdata_holdfix), .O(mem_rdata), .A({1'b0, 1'b0, \n        1'b0, 1'b0, 1'b0, 1'b0, mem_addr_holdfix}), .CE(clk_div2), .CSB(mem_cs), .WEB(\n        mem_we), .OEB(mem_oe) );\n${eco_block}"

if {[string first $sram_block_old $text] < 0} {
    fail "Could not find the expected SRAM instance block."
}
set text [string map [list $sram_block_old $sram_block_new] $text]

if {[string first "mem_addr_holdfix" $text] < 0 || [string first "mem_wdata_holdfix" $text] < 0} {
    fail "ECO rewrite failed sanity check."
}

set output_netlist [file join $output_dir [file tail $input_netlist]]
set out_fp [open $output_netlist w]
puts -nonewline $out_fp $text
close $out_fp

foreach extra_name {scan_internal.spf scan.def} {
    set extra_path [file join [file dirname $input_netlist] $extra_name]
    if {[file exists $extra_path]} {
        file copy -force $extra_path [file join $output_dir $extra_name]
    }
}

puts "Wrote ECO netlist: $output_netlist"
