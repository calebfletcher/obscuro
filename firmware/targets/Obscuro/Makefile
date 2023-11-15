# Define target output
target: prom

# Define Firmware Version: v2.6.0.0
export PRJ_VERSION = 0x00000001

# Define target part
export PRJ_PART = XC7A35TICSG324-1L

# Define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../..)

export VIVADO_PROJECT_SIM = ObscuroTb

# Use top level makefile
include $(TOP_DIR)/submodules/ruckus/system_vivado.mk

sim_replay:
	@cd $(OUT_DIR); xsim --gui $(VIVADO_PROJECT).sim/sim_1/behav/xsim/$(VIVADO_PROJECT_SIM)_behav.wdb