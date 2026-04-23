# Lab-2：使用 iVerilog 跑通单核与流水线 CPU 仿真工程

## 实验名称

Lab-2 单周期单核 CPU 与流水线 CPU 仿真工程运行与波形观察。

## 实验目标

1. 跑通已有单周期单核 CPU 和流水线 CPU 仿真工程，理解仿真工程的目录结构和 testbench 组织方式。
2. 掌握使用 iVerilog / vvp 编译和运行 Verilog testbench 的方法。
3. 能够生成 `sccpu_sim.vcd` 与 `plcpu_sim.vcd`，并使用 GTKWave 或 ModelSim 观察关键波形。
4. 能够说明 `rv32_sc_sim.dat` 与 `rv32_pl_sim.dat` 的相对路径要求，以及仿真顶层 `sccomp_tb.v` / `plcomp_tb.v` 的作用。

本实验不是新增 CPU 指令实验，不要求修改 CPU 功能逻辑。

## 前置知识

- Verilog 模块例化、时钟、复位和 testbench 基本写法
- 单周期 CPU 和流水线 CPU 的 PC、取指、译码、执行、访存、写回基本流程
- RISC-V 指令存储器初始化文件的基本用途
- 命令行进入目录、执行脚本和查看输出文件的基本操作

## 实验内容

学生需要在给定工程中完成以下工作：

### 单核（单周期）CPU 仿真实验

1. 在 `lab-2/source-sc` 运行目录中编译单周期 CPU 仿真工程。
2. 运行仿真入口 `sccomp_tb`，生成 `sccpu_sim.out` 和 `sccpu_sim.vcd`。
3. 打开波形文件，观察 `clk`、`rstn`、`PC`、`instr`、`RFWr`、`A3`、`WD` 等关键信号。
4. 说明 `rv32_sc_sim.dat` 如何被 `sccomp_tb.v` 通过相对路径加载。
5. 记录运行过程、关键波形和遇到的问题。

### 流水线 CPU 仿真实验

1. 在 `lab-2/source-pl` 运行目录中编译流水线 CPU 仿真工程。
2. 运行仿真入口 `plcomp_tb`，生成 `plcpu_sim.out` 和 `plcpu_sim.vcd`。
3. 打开波形文件，观察 `clk`、`rstn`、`PC`、`instr`、`RFWr`、`A3`、`WD` 等关键信号。
4. 说明 `rv32_pl_sim.dat` 如何被 `plcomp_tb.v` 通过相对路径加载。
5. 记录运行过程、关键波形和遇到的问题。

## 工程位置与目录说明

项目目录为：

```text
lab-2/
├── README.md
├── modelsim_guide.md
├── source-pl/
└── source-sc/
```

`source-pl` 是流水线 CPU 运行目录，`source-sc` 是单周期单核 CPU 运行目录。编译、运行、生成波形时都应进入对应目录后执行命令。

`source-pl` 中的主要文件如下：

| 文件 | 说明 |
|---|---|
| `plcomp_tb.v` | 流水线 CPU 仿真顶层 testbench，模块名为 `plcomp_tb` |
| `plcomp.v` | 流水线仿真系统封装，连接 CPU、指令存储器和数据存储器 |
| `PLCPU.v` | 流水线 CPU 顶层 |
| `rv32_pl_sim.dat` | 流水线指令初始化文件，运行时依赖当前目录相对路径 |
| `build.bat` | Windows 下的构建脚本 |
| `build.py` | Python 辅助构建脚本 |
| `Makefile` | Linux / WSL 下的构建脚本 |

`plcomp_tb.v` 中通过如下语句加载程序：

```verilog
$readmemh("rv32_pl_sim.dat", plcomp.U_imem.RAM);
```

`source-sc` 中的主要文件如下：

| 文件 | 说明 |
|---|---|
| `sccomp_tb.v` | 单周期 CPU 仿真顶层 testbench，模块名为 `sccomp_tb` |
| `sccomp.v` | 单周期仿真系统封装 |
| `SCCPU.v` | 单周期 CPU 顶层 |
| `rv32_sc_sim.dat` | 单周期指令初始化文件，运行时依赖当前目录相对路径 |
| `build.bat` | Windows 下的构建脚本 |
| `build.py` | Python 辅助构建脚本 |
| `Makefile` | Linux / WSL 下的构建脚本 |

`sccomp_tb.v` 中通过如下语句加载程序：

```verilog
$readmemh("rv32_sc_sim.dat", sccomp.U_imem.RAM);
```

因此必须处理好 `.dat` 文件的相对路径。推荐始终在对应 `source-pl` 或 `source-sc` 目录内运行。

## 实验步骤

### 单周期 CPU

1. 进入 `lab-2/source-sc`。
2. 确认目录中存在 `sccomp_tb.v`、`sccomp.v`、`SCCPU.v` 和 `rv32_sc_sim.dat`。
3. 使用 Windows 或 Linux / WSL 对应命令运行仿真。
4. 确认终端输出中能看到周期、PC、指令和寄存器写回相关信息。
5. 确认生成 `sccpu_sim.vcd`。
6. 使用 GTKWave 或 ModelSim 打开波形并观察关键信号。

### 流水线 CPU

1. 进入 `lab-2/source-pl`。
2. 确认目录中存在 `plcomp_tb.v`、`plcomp.v`、`PLCPU.v` 和 `rv32_pl_sim.dat`。
3. 使用 Windows 或 Linux / WSL 对应命令运行仿真。
4. 确认终端输出中能看到周期、PC、指令和寄存器写回相关信息。
5. 确认生成 `plcpu_sim.vcd`。
6. 使用 GTKWave 或 ModelSim 打开波形并观察关键信号。

## Windows 运行方法

建议在已配置好 Icarus Verilog 环境的终端中运行；课程推荐使用 OSS CAD Suite 终端。

### 单周期 CPU

```powershell
cd lab-2\source-sc
.\build.bat
```

打开波形：

```powershell
.\build.bat wave
```

或者：

```powershell
python .\build.py run
python .\build.py wave
```

### 流水线 CPU

```powershell
cd lab-2\source-pl
.\build.bat
```

打开波形：

```powershell
.\build.bat wave
```

也可以使用 Python 脚本：

```powershell
python .\build.py run
python .\build.py wave
```

清理生成物：

```powershell
.\build.bat clean
python .\build.py clean
```

## Linux / WSL 运行方法

### 单周期 CPU

```bash
cd lab-2/source-sc
make run
```

打开波形：

```bash
make wave
```

### 流水线 CPU

```bash
cd lab-2/source-pl
make run
```

打开波形：

```bash
make wave
```

清理生成物：

```bash
make clean
```

## 波形查看方法

单周期 CPU 仿真运行后会生成：

```text
sccpu_sim.vcd
```

流水线 CPU 仿真运行后会生成：

```text
plcpu_sim.vcd
```

使用 GTKWave 打开：

```bash
gtkwave sccpu_sim.vcd
# 或
gtkwave plcpu_sim.vcd
```

建议观察的关键信号：

- `clk`
- `rstn`
- `PC`
- `instr`
- `RFWr`
- `A3`
- `WD`

观察重点包括时钟复位是否正常、PC 是否按程序推进、指令是否被正确取出、寄存器堆是否发生写回。

## 提交要求

通过 ModelSim 或 Icarus Verilog 命令行分别运行单周期单核 CPU 和流水线 CPU，并写实验报告。

## 常见问题

### 找不到 `iverilog` 或 `vvp`

说明工具未安装，或工具目录未加入 `PATH`。请先在终端检查：

```bash
iverilog -V
vvp -V
```

### 找不到 `rv32_sc_sim.dat` 或 `rv32_pl_sim.dat`

通常是运行目录不正确。请进入对应目录后再执行 `./build.bat`、`python ./build.py run` 或 `make run`。

### 没有生成 `sccpu_sim.vcd` 或 `plcpu_sim.vcd`

请确认仿真已经正常运行结束，并确认 testbench 中包含对应的 dump 语句：

```verilog
$dumpfile("sccpu_sim.vcd");
$dumpvars(0, sccomp_tb);
```

或

```verilog
$dumpfile("plcpu_sim.vcd");
$dumpvars(0, plcomp_tb);
```

### 出现 `$readmemh` warning

`$readmemh` 关于 IEEE 1364-2005 行为的 warning、指令文件不足以填满存储器的 warning，在当前实验中可以接受。

### 波形后段 `instr=xxxxxxxx`

程序结束后 PC 继续访问未初始化的指令存储器区域，可能出现 `instr=xxxxxxxx`。当前实验重点观察有效程序段内的 PC、指令和寄存器写回行为，该现象可以接受。

## 选做内容

1. 使用 ModelSim 按 `modelsim_guide.md` 手动创建工程并运行仿真。
2. 在 GTKWave 中保存一份自己常用的信号观察配置。
3. 对照终端输出，解释若干个周期中的 PC、`instr` 和寄存器写回变化。
4. 尝试替换 `rv32_pl_sim.dat` 或 `rv32_sc_sim.dat` 中的测试程序，并说明需要保持的文件路径要求。
