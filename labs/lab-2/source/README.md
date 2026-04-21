# Lab-2 流水线 CPU 工程运行说明

本目录是 Lab-2 的可运行目录，即 `plcpu_sim/source`。请在本目录下编译、运行仿真，避免 `rv32_pl_sim.dat` 的相对路径失效。

## 工程说明

- 仿真顶层：`plcomp_tb.v`，顶层模块名为 `plcomp_tb`
- CPU 顶层：`PLCPU.v`
- 系统封装：`plcomp.v`
- 指令初始化文件：`rv32_pl_sim.dat`
- 仿真输出文件：`plcpu_sim.out`
- 波形输出文件：`plcpu_sim.vcd`

当前工程用于跑通已有流水线 CPU 仿真流程，不要求新增 CPU 指令或修改 CPU 功能逻辑。

## 文件说明

| 文件 | 作用 |
|---|---|
| `plcomp_tb.v` | 仿真 testbench，负责加载程序、产生时钟和复位、生成 VCD 波形并结束仿真 |
| `plcomp.v` | 连接流水线 CPU、指令存储器和数据存储器 |
| `PLCPU.v` | 流水线 CPU 顶层 |
| `alu.v`、`ctrl.v`、`dm.v`、`EXT.v`、`im.v`、`NPC.v`、`PC.v`、`pl_reg.v`、`RF.v` | CPU 相关功能模块 |
| `ctrl_encode_def.v` | 控制信号宏定义，由 Verilog 源文件通过 `` `include`` 引入 |
| `rv32_pl_sim.dat` | 仿真程序数据文件，必须放在 source 运行目录中 |
| `Makefile` | Linux / WSL 下的构建脚本 |
| `build.bat` | Windows 下的构建脚本 |
| `build.py` | Python 辅助构建脚本 |

## 编译命令

当前已验证通过的 iVerilog 编译命令为：

```bash
iverilog -o plcpu_sim.out -s plcomp_tb -I . alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v plcomp.v plcomp_tb.v PLCPU.v pl_reg.v RF.v
```

其中 `-I .` 用于保证当前目录下的 include 文件可被找到，`-s plcomp_tb` 指定仿真顶层。

## Windows 运行方法

在 PowerShell 或 CMD 中进入本 `source` 目录：

```powershell
.\build.bat
```

默认执行编译和运行。也可以使用：

```powershell
.\build.bat wave
.\build.bat clean
```

如果使用 Python 脚本：

```powershell
python .\build.py run
python .\build.py wave
python .\build.py clean
```

## Linux / WSL 运行方法

在本 `source` 目录执行：

```bash
make run
```

查看波形：

```bash
make wave
```

清理生成物：

```bash
make clean
```

## 波形查看

仿真成功后会生成 `plcpu_sim.vcd`。可以使用 GTKWave 打开：

```bash
gtkwave plcpu_sim.vcd
```

建议观察的关键信号包括：

- `clk`
- `rstn`
- `PC`
- `instr`
- `RFWr`
- `A3`
- `WD`

这些信号可用于检查时钟复位、PC 推进、取指过程和寄存器写回行为。

## 相对路径提醒

`plcomp_tb.v` 通过如下方式加载程序：

```verilog
$readmemh("rv32_pl_sim.dat", plcomp.U_imem.RAM);
```

因此运行目录必须处理好 `rv32_pl_sim.dat` 的相对路径。建议始终在 `source` 目录中执行 `.\build.bat`、`python .\build.py run` 或 `make run`。

## 可接受 warning

以下 warning 在当前实验中可以接受：

- `$readmemh` 关于 IEEE 1364-2005 行为的 warning
- `rv32_pl_sim.dat` 不足以填满 `[0:255]` 的 warning
- 程序结束后继续取未初始化指令导致后段 `instr=xxxxxxxx`

如果出现无法生成 `plcpu_sim.out`、无法运行 `vvp`、找不到 `rv32_pl_sim.dat` 或无法生成 `plcpu_sim.vcd`，需要先检查工具安装、运行目录和文件完整性。
