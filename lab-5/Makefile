# Lab-5 board number demo simulation

IVERILOG ?= iverilog
VVP      ?= vvp

OUT := board_number_demo_tb.out

SRCS := \
	src/hex_to_7seg.v \
	src/scan_7seg.v \
	src/board_number_demo.v \
	sim/tb_board_number_demo.v

.PHONY: sim build run clean vivado

sim: build run

build:
	$(IVERILOG) -I src -s tb_board_number_demo -o $(OUT) $(SRCS)

run:
	$(VVP) $(OUT)

vivado:
	vivado -mode batch -source scripts/create_vivado_project.tcl

clean:
	rm -f $(OUT) *.vcd *.log
