# Lab-3 单周期 CPU 新增指令

## 目录

本次 `lab-3` 已整理为独立实验目录：

```text
lab-3/
├── README.md
└── source-sc/
```

`source-sc` 是本次实验的单周期 CPU 工程目录。

## 完成情况

本次 `lab-3` 已完成并验收通过：

- 简单运算指令：`andi`
- 分支指令：`bne`

当前已经完成：

- 指令实现
- 测试程序编写
- testbench 自动验收
- Windows / Python / Linux 运行脚本整理

## 本次改了哪些文件

`lab-3/source-sc` 中和本次实验直接相关的核心文件有：

- `ctrl.v`
- `rv32_sc_sim.dat`
- `sccomp_tb.v`

其中：

- `ctrl.v`：增加 `andi` 和 `bne` 的译码与控制信号
- `rv32_sc_sim.dat`：加入覆盖 `andi`、`bne taken`、`bne not taken` 的测试程序
- `sccomp_tb.v`：加入自动检查逻辑，仿真结束时直接输出 `PASS/FAIL`

## 为什么这样实现

### 为什么改 `ctrl.v`

`ctrl.v` 是控制器，新增指令首先要在这里补译码。

- `andi` 需要增加 I-type 逻辑运算译码
- `bne` 需要增加 B-type 分支译码，并把分支条件从“相等跳转”扩展成“可支持不相等跳转”

### 为什么改 `rv32_sc_sim.dat`

只改控制器还不够，必须让仿真程序真实执行到新指令，才能验证实现正确。

所以本次把测试程序改成同时覆盖：

- `andi`
- `bne taken`
- `bne not taken`

### 为什么改 `sccomp_tb.v`

这次修改 testbench 不是为了改 CPU 功能，而是为了自动验收。

仿真结束时会自动检查关键寄存器值，直接输出：

```text
[PASS] lab-3 source-sc checks passed.
```

## 为什么这次不用改别的模块

这次选 `andi` 和 `bne`，是因为它们可以复用现有数据通路：

- `andi` 复用 I-type 立即数扩展和 `and` 运算
- `bne` 复用 B-type 立即数扩展、减法比较和分支地址计算

所以这次主要改的是控制逻辑，不需要新增 ALU、EXT、NPC 或顶层连线模块。

## 怎么运行

### 运行目录

进入：

```powershell
cd lab-3/source-sc
```

### Windows

如果本机安装了`iverilog`：


直接运行：

```powershell
.\build.bat run
```

只编译：

```powershell
.\build.bat build
```

查看波形：

```powershell
.\build.bat wave
```

清理生成物：

```powershell
.\build.bat clean
```

### Python

```powershell
python .\build.py run
python .\build.py wave
python .\build.py clean
```

### Linux / WSL

```bash
make run
make wave
make clean
```

## 如何判断运行成功

终端应看到：

```text
[PASS] lab-3 source-sc checks passed.
```

并生成：

- `sccpu_sim.out`
- `sccpu_sim.vcd`

## 本次测试程序

当前 `rv32_sc_sim.dat` 内容为：

```text
03c00093
00f0f113
00500193
00700213
00419463
00100293
00200313
00319463
00300393
00900413
0000006f
```

对应逻辑：

```assembly
addi x1, x0, 60
andi x2, x1, 15
addi x3, x0, 5
addi x4, x0, 7
bne  x3, x4, +8
addi x5, x0, 1
addi x6, x0, 2
bne  x3, x3, +8
addi x7, x0, 3
addi x8, x0, 9
jal  x0, 0
```

