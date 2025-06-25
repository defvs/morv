RTL_SRC := src/morv_top.sv src/rv32i_pkg.sv
TB_SRC := tb/morv_standalone_tb.sv tb/simple_mem.sv

BUILD_DIR := build

synth:

sim:
	xrun -gui ${RTL_SRC} ${TB_SRC}

dirs:
	-mkdir ${BUILD_DIR}

clean:
	rm -rf build
