# Lab-2 流水线 CPU 仿真 Makefile
# source 是运行目录，请在本目录执行 make 命令。

IVERILOG ?= iverilog
VVP      ?= vvp
GTKWAVE  ?= gtkwave

TOP      := plcomp_tb
OUT      := plcpu_sim.out
VCD      := plcpu_sim.vcd

# ctrl_encode_def.v is included by the source files through `include`.
# Backup testbenches are not compiled to avoid duplicate module definitions.
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
	@echo "Lab-2 流水线 CPU simulation"
	@echo ""
	@echo "Targets:"
	@echo "  make build  Compile Verilog sources to $(OUT)"
	@echo "  make run    Build and run simulation, generating $(VCD)"
	@echo "  make wave   Build, run, and open $(VCD) with GTKWave"
	@echo "  make clean  Remove generated simulation files"
	@echo "  make help   Show this help"
	@echo ""
	@echo "Required tools: iverilog, vvp, gtkwave"
