set ver $env(ver)
set eco_ver "${ver}_setupfix1"

set in_dir "./2_output/${ver}"
set out_dir "./2_output/${eco_ver}"

set in_netlist  "${in_dir}/aes_128_internal.v"
set out_netlist "${out_dir}/aes_128_internal.v"

if {![file exists $in_netlist]} {
    puts stderr "Missing input netlist: $in_netlist"
    exit 1
}

file mkdir $out_dir
file mkdir "./4_report/${eco_ver}"

set fp [open $in_netlist r]
set text [read $fp]
close $fp

set old_root_buffer "  NBUFFX8_RVT U494 ( .A(ct_xfer_pulse_div2), .Y(n763) );"
set new_root_buffer "  NBUFFX4_RVT SETUP_ECO_BUF_14 ( .A(ct_xfer_pulse_div2), .Y(setup_eco_ct_pulse_14) );\n  NBUFFX8_RVT U494 ( .A(ct_xfer_pulse_div2), .Y(n763) );"

if {![string match "*$old_root_buffer*" $text]} {
    puts stderr "Could not find root buffer U494 in $in_netlist"
    exit 1
}

set old_branch_buffer "  NBUFFX4_RVT DFTC_14 ( .A(n763), .Y(n887) );"
set new_branch_buffer "  NBUFFX4_RVT DFTC_14 ( .A(setup_eco_ct_pulse_14), .Y(n887) );"

if {![string match "*$old_branch_buffer*" $text]} {
    puts stderr "Could not find branch buffer DFTC_14 in $in_netlist"
    exit 1
}

set text [string map [list \
    $old_root_buffer   $new_root_buffer \
    $old_branch_buffer $new_branch_buffer] $text]

set fp [open $out_netlist w]
puts -nonewline $fp $text
close $fp

foreach file_name [list scan.def scan_internal.spf aes_128_internal.ddc] {
    set src "${in_dir}/${file_name}"
    if {[file exists $src]} {
        file copy -force $src $out_dir
    }
}

set note_file "./4_report/${eco_ver}/setup_eco_note.txt"
set fp [open $note_file w]
puts $fp "Input version : $ver"
puts $fp "Output version: $eco_ver"
puts $fp ""
puts $fp "ECO summary:"
puts $fp "- Added SETUP_ECO_BUF_14 driven directly by ct_xfer_pulse_div2"
puts $fp "- Rewired DFTC_14 input from n763 to setup_eco_ct_pulse_14"
puts $fp "- Goal: reduce the overloaded n763 -> DFTC_14 branch seen in post-DFT STA"
close $fp

puts "Created ECO netlist: $out_netlist"
puts "Created ECO note   : $note_file"
