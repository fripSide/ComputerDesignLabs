# ModelSim 安全使用教程（Lab-2 配套）

## 教程目的
本课程 Lab-2 的主验收流程以 iVerilog 为主，ModelSim 教程用于图形化理解与补充演示。
本文档用于说明如何使用合法安装的 ModelSim / QuestaSim 打开并运行 Lab-2 流水线 CPU 仿真工程。文档只介绍正常的软件使用流程，不涉及破解、许可证绕过或任何灰色安装方式。

Lab-2 的主流程仍以 iVerilog 为准；ModelSim 可作为课堂演示、图形化调试和波形观察的补充工具。

## 适用工程说明

当前教程对应工程目录：

```text
lab-2/source
```

该目录来自 `plcpu_sim/source`，其中：

- `plcomp_tb.v` 是仿真入口，模块名为 `plcomp_tb`
- `plcomp.v` 是仿真系统封装
- `PLCPU.v` 是流水线 CPU 顶层
- `rv32_pl_sim.dat` 是指令初始化文件

`source` 是运行目录。ModelSim 运行仿真时也必须处理好 `rv32_pl_sim.dat` 的相对路径，否则 `$readmemh("rv32_pl_sim.dat", ...)` 可能找不到文件。

## 启动 ModelSim 的规范方式

请使用学校机房、课程授权环境或个人合法授权安装的 ModelSim / QuestaSim。

建议方式：

1. 从开始菜单、桌面快捷方式或已配置好的命令行启动 ModelSim。
2. 不要移动 `source` 内部文件。
3. 创建工程时将工程位置设在 `lab-2/source`，或确保仿真工作目录指向 `lab-2/source`。

## 创建工程

1. 打开 ModelSim。
2. 选择 `File` -> `New` -> `Project`。
3. Project Location 建议选择 `lab-2/source`。
4. Project Name 可填写 `plcpu_sim`。
5. Default Library Name 保持 `work`。
6. 点击确认后进入添加文件流程。

如果你希望把 ModelSim 工程文件放在其他目录，也可以这样做，但运行仿真前必须确认当前仿真目录能找到 `rv32_pl_sim.dat`。

## 添加 Verilog 文件
在当前工程中，建议将全部源文件加入工程后统一执行 Compile All；若使用命令行编译，则需保证 include 路径正确。
将以下文件添加到工程中：

```text
alu.v
ctrl.v
dm.v
EXT.v
im.v
NPC.v
PC.v
plcomp.v
plcomp_tb.v
PLCPU.v
pl_reg.v
RF.v
```

同时保留 `ctrl_encode_def.v` 在 `source` 目录中。该文件由其他 Verilog 文件通过 `` `include`` 引入，通常不需要作为独立仿真顶层运行。

不要添加以下文件：

- `plcomp_tb_backup.v`
- `plcomp_tb_iverilog.v`
- `plcpu_sim.out`
- `plcpu_sim.vcd`
- `*.wlf`
- `*.log`

## 设置 `plcomp_tb` 为仿真入口

本实验的 testbench 是：

```text
plcomp_tb.v
```

顶层模块名是：

```text
plcomp_tb
```

在 ModelSim 中启动仿真时，应选择 `work.plcomp_tb` 作为仿真入口。不要选择 `plcomp` 或 `PLCPU` 作为顶层入口，因为它们不是完整 testbench，不负责产生时钟、复位、加载程序和结束仿真。

## 编译工程

图形界面方式：

1. 在 Project 面板中选中所有 Verilog 源文件。
2. 右键选择 `Compile` -> `Compile Selected`，或使用菜单 `Compile` -> `Compile All`。
3. 确认 Transcript 中没有 error。

命令行方式可参考：

```tcl
vlib work
vlog +incdir+. alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v plcomp.v plcomp_tb.v PLCPU.v pl_reg.v RF.v
```

`+incdir+.` 的作用类似 iVerilog 中的 `-I .`，用于让 `ctrl_encode_def.v` 等 include 文件可被找到。

## 运行仿真

启动仿真：

```tcl
vsim work.plcomp_tb
```

如果工程文件不在 `source` 目录，建议先在 Transcript 中确认或切换工作目录，例如：

```tcl
cd <你的 lab-2/source 路径>
vsim work.plcomp_tb
```

运行仿真：

```tcl
run -all
```

`plcomp_tb.v` 中已经设置了结束时间和 `$finish`，因此仿真会自动结束。

## 打开波形窗口并添加信号

打开 Wave 窗口：

```tcl
view wave
```

添加常用信号：

```tcl
add wave sim:/plcomp_tb/clk
add wave sim:/plcomp_tb/rstn
add wave sim:/plcomp_tb/plcomp/PC
add wave sim:/plcomp_tb/plcomp/instr
add wave sim:/plcomp_tb/plcomp/U_PLCPU/U_RF/RFWr
add wave sim:/plcomp_tb/plcomp/U_PLCPU/U_RF/A3
add wave sim:/plcomp_tb/plcomp/U_PLCPU/U_RF/WD
run -all
```

也可以在 Objects 或 Structure 面板中逐级展开 `plcomp_tb`、`plcomp`、`PLCPU`，手动把信号拖入 Wave 窗口。

## 建议观察的关键信号

- `clk`：时钟信号
- `rstn`：复位信号
- `PC`：取指阶段 PC
- `instr`：当前取出的指令
- `RFWr`：寄存器堆写使能
- `A3`：寄存器堆写地址
- `WD`：寄存器堆写数据

观察时重点说明 PC 如何推进、有效指令阶段寄存器是否写回，以及复位前后信号变化是否符合预期。

## 常见问题

### 编译时报 include 文件找不到

请确认 `ctrl_encode_def.v` 位于 `source` 目录，并在编译命令中使用 `+incdir+.`。如果使用图形界面工程，请确认工程目录或 include 目录指向 `source`。

### 运行时报 `rv32_pl_sim.dat` 找不到

请确认 ModelSim 当前运行目录是 `source`，或者在启动仿真前使用 `cd` 切换到 `lab-2/source`。该文件通过相对路径读取，路径不正确会导致指令存储器初始化失败。

### 不知道选哪个顶层

选择 `work.plcomp_tb`。`plcomp_tb` 是 testbench，负责产生时钟、复位、加载 `rv32_pl_sim.dat`、生成波形并结束仿真。

### 波形后段出现 `xxxxxxxx`

程序结束后继续访问未初始化指令存储器区域时，`instr` 可能显示为 `xxxxxxxx`。当前 Lab-2 允许该现象，验收时重点观察有效程序段内的信号变化。

### ModelSim 生成了 `work/`、`*.wlf` 或 `*.log`

这些是仿真工具缓存和日志，不属于最终提交内容。提交前请不要把它们放入 `lab-2` 正式提交包。

## 与 iVerilog 主流程的关系

Lab-2 的推荐验收主流程是：

```powershell
.\build.bat
python .\build.py run
```

或在 Linux / WSL 中：

```bash
make run
```

ModelSim 用于辅助理解工程、手动编译和观察波形。若 ModelSim 与 iVerilog 的观察结果不一致，应优先检查运行目录、`rv32_pl_sim.dat` 是否被正确加载、仿真入口是否为 `plcomp_tb`。
