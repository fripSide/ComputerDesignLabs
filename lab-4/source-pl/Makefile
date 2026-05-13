# Lab-4 pipeline CPU simulation Makefile

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

TOP      := plcomp_tb
OUT      := plcpu_sim.out
VCD      := plcpu_sim.vcd

SRCS := \
	alu.v \
	ctrl.v \
	dm.v \
	EXT.v \
	im.v \
	NPC.v \
	PC.v \
	plcomp.v \
	plcomp_tb.v \
	PLCPU.v \
	pl_reg.v \
	RF.v

IVERILOG_FLAGS := -I . -s $(TOP)

.PHONY: build run wave clean help

build:
	$(IVERILOG) $(IVERILOG_FLAGS) -o $(OUT) $(SRCS)

run: build
	$(VVP) $(OUT)

wave: run
	@if [ -f "$(VCD)" ]; then \
		$(GTKWAVE) "$(VCD)" & \
	else \
		echo "Cannot find $(VCD). Please run make run first."; \
		exit 1; \
	fi

clean:
	rm -f $(OUT) $(VCD) *.log

help:
	@echo "Lab-4 pipeline CPU simulation"
	@echo "  make build  Compile Verilog sources to $(OUT)"
	@echo "  make run    Build and run simulation"
	@echo "  make wave   Build, run, and open waveform"
	@echo "  make clean  Remove generated files"
