################################################################################
# 20_build_model.tcl
# - Build the ATPG internal model from the read gate netlist.
################################################################################

# Ignore floating primary-input warning B12 because some test-only ports can look floating.
set_rules B12 ignore

# Let ATPG learn equivalent structures before fault processing starts.
set_learning -atpg_equivalence

# Build the ATPG model for the selected top design.
run_build_model $DESIGN_NAME
