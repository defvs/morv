RTL_SRC := src/rv32i_pkg.sv src/morv_top.sv
TB_SRC := tb/simple_mem.sv tb/morv_standalone_tb.sv

BUILD_DIR := build

XRUN_EXTRA_OPTS := -64bit -access +rw

.PHONY: default help synth sim dirs clean

default help:
	@echo "No target selected."

synth:

sim-gui: XRUN_EXTRA_OPTS += -gui
sim-gui: sim

sim: dirs
	cd ${BUILD_DIR}; xrun ${XRUN_EXTRA_OPTS} -top morv_standalone_tb $(realpath ${RTL_SRC} ${TB_SRC})

dirs:
	-mkdir ${BUILD_DIR}

clean:
	rm -rf build
