################################################################################
# 10_read_design.tcl
# - Read ATPG simulation libraries.
# - Read the final post-DFT gate netlist.
# - Declare blocks that ATPG should treat as black boxes.
################################################################################

# Read standard cell ATPG models so scan flops and combinational cells are known.
read_netlist -library $LIB_RVT
read_netlist -library $LIB_HVT
read_netlist -library $LIB_LVT

# Read IO and PLL models because top-level ATPG netlist includes them.
read_netlist -library $LIB_IO
read_netlist -library $LIB_PLL -define TETRAMAX

# Read SRAM model so module names are resolved before black-boxing memory.
read_netlist -library $LIB_SRAM

# Read common helper primitives from the reference ATPG project if available.
if {[file exists $LIB_COMMON]} {
  read_netlist -library $LIB_COMMON
} else {
  puts "INFO: common.v was not found, continue without it -> $LIB_COMMON"
}

# SRAM macro is not scan-inserted logic, so ATPG should treat it as a black box.
set_build -black_box [list SRAM1RW1024x8]

# Read the final post-DFT ECO netlist that will be used for pattern generation.
read_netlist $NETLIST
