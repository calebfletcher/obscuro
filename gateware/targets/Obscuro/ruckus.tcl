# Load RUCKUS environment and library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load common and sub-module ruckus.tcl files
loadRuckusTcl $::env(TOP_DIR)/submodules/surf
loadRuckusTcl $::env(TOP_DIR)/common

# Load local source Code and constraints
loadSource      -dir "$::DIR_PATH/rtl" -fileType {VHDL 2008}
loadConstraints -dir "$::DIR_PATH/rtl"

# Load local SIM source Code
loadSource -sim_only -dir "$::DIR_PATH/tb" -fileType {VHDL 2008}