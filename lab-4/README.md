# Lab-4-0507: 流水线 CPU 新增两条指令

## 实验目标

本次 `lab-4-0507` 严格按照老师要求完成：

- 给流水线 CPU 增加一条跳转指令：`jal`
- 给流水线 CPU 增加一条普通运算指令：`andi`

本实验不扩展到 `lab-5` 的 Vivado 工程，也不扩展到 `lab-6` 的开发板运行。

## 目录结构

```text
lab-4-0507/
├─ README.md
└─ source-pl/
```

`source-pl` 是本次实验的独立运行目录。学生应在这个目录里阅读代码、运行仿真、观察结果。

## 你要完成什么

建议按下面顺序完成实验：

1. 先跑通当前 `lab-4-0507/source-pl`，确认环境没有问题。
2. 阅读测试程序，明确这次要验证的两条指令分别是什么。
3. 阅读控制器 `ctrl.v`，理解新增指令需要哪些控制信号。
4. 阅读 `EXT.v` 和 `NPC.v`，理解 `jal` 的立即数扩展和跳转地址生成。
5. 阅读 `PLCPU.v`，重点看流水线寄存器和跳转后的清空逻辑。
6. 重新运行仿真，确认测试程序能得到 `PASS`。
7. 打开波形，观察 `jal` 跳转前后的 PC 变化，以及被冲刷掉的顺序指令没有写回。

## 本次实验的核心思路

### 1. `andi` 为什么容易加

`andi` 属于 I-type 普通运算指令：

- 需要从指令中取 12 位立即数
- 需要做符号扩展
- 需要让 ALU 执行按位与
- 结果从 ALU 写回寄存器

也就是说，`andi` 主要是补控制器译码，数据通路基本复用现有 `addi` 的路径。

### 2. `jal` 为什么比 `andi` 多一步

`jal` 不只是“改 PC”这么简单，它还有两件事：

- 把返回地址 `PC+4` 写回到 `rd`
- 跳转成功后，顺序取到的后两条指令不能继续执行

在这份流水线 CPU 里，跳转是在 EX 阶段确定的，因此当 `jal` 生效时，IF/ID 和 ID/EX 里已经装进了两条顺序指令。为了避免它们误执行，需要把这两级清空。

### 3. 本实验为什么要清空两级流水

如果只改 `NPC`，不清空流水线，会出现：

- PC 虽然跳到了目标地址
- 但跳转后本应被跳过的两条顺序指令仍然会继续下流
- 最终会错误写回寄存器

所以，本实验里 `jal` 的正确实现 = 跳转地址计算 + 写回 `PC+4` + 两级流水冲刷。

## 本次实验实际改动了哪些文件

位于 [source-pl](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl)：

- [ctrl.v](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\ctrl.v)
  增加 `andi`、`jal` 的译码和控制信号。
- [EXT.v](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\EXT.v)
  增加 `jal` 所需的 J-type 立即数扩展。
- [NPC.v](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\NPC.v)
  增加 `jal` 跳转目标地址生成。
- [PLCPU.v](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\PLCPU.v)
  增加跳转后的两级流水清空逻辑。
- [rv32_pl_sim.dat](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\rv32_pl_sim.dat)
  改为本次实验专用测试程序。
- [plcomp_tb.v](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\plcomp_tb.v)
  增加 `PASS/FAIL` 自动检查和波形导出。
- [Makefile](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\Makefile)
  Linux / WSL 运行入口。
- [build.bat](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\build.bat)
  Windows 运行入口。
- [build.py](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\build.py)
  Windows Python 运行入口。

## 学生实验步骤

### 第一步：进入目录

```powershell
cd lab-4-0507/source-pl
```

### 第二步：运行仿真

Windows：

```powershell
.\build.bat run
```

如果你用 Python 脚本：

```powershell
python .\build.py run
```

Linux / WSL：

```bash
make run
```

### 第三步：看终端是否通过

运行成功后，终端应看到：

```text
[PASS] lab-4 source-pl checks passed.
```

如果没有看到这行，就说明你的实现还没通过。

### 第四步：打开波形

Windows：

```powershell
.\build.bat wave
```

Linux / WSL：

```bash
make wave
```

### 第五步：重点观察这些现象

1. `andi` 执行后，目标寄存器写回按位与结果。
2. `jal` 执行后，`rd` 写回跳转指令原地址的 `PC+4`。
3. `jal` 之后顺序位置上的两条指令没有生效。
4. 跳转目标处的指令继续正常执行。

## 本次测试程序在验证什么

[rv32_pl_sim.dat](E:\gogogo\work\ComputerDesignLabs_repo\lab-4-0507\source-pl\rv32_pl_sim.dat) 当前验证了下面几件事：

- `addi x1, x0, 5`
  先准备一个后续 `andi` 要使用的源操作数。
- `andi x2, x1, 3`
  验证普通运算指令新增成功，预期 `x2 = 1`。
- `jal x3, 12`
  验证跳转指令新增成功，预期 `x3 = PC + 4 = 0x18`。
- 跳转后两条顺序指令应被冲刷
  也就是写 `x4`、写 `x5` 的两条指令不应生效。
- 跳转目标处 `addi x6, x0, 9`
  应继续正常执行，预期 `x6 = 9`。

## 如何判断自己实现正确

本次 testbench 会自动检查：

- `x1 == 5`
- `x2 == 1`
- `x3 == 0x18`
- `x4 == 0`
- `x5 == 0`
- `x6 == 9`

只要这些条件全部满足，就会输出：

```text
[PASS] lab-4 source-pl checks passed.
```

## 常见问题

### 1. 为什么会看到 `$readmemh` warning

这是因为测试程序条数比指令存储器深度短，属于当前实验可接受现象，不影响验收。

### 2. 为什么后面会看到 `instr=xxxxxxxx`

测试程序执行完后，PC 继续访问了未初始化的指令区，所以后段可能出现 `xxxxxxxx`。只要前面的关键寄存器检查通过，就不影响本实验结论。

### 3. 为什么 `jal` 不能只改 `NPC.v`

因为这是流水线 CPU。只改跳转地址不够，跳转发生时已经有后续顺序指令进入流水线，需要额外把 IF/ID 和 ID/EX 清空。

### 4. `jal` 为什么写回的是 `PC+4`

`jal` 的语义本来就是：

- 跳到目标地址执行
- 同时把返回地址保存到 `rd`

这个返回地址就是当前 `jal` 指令所在地址的下一条地址，也就是 `PC+4`。

## 建议写进实验报告的内容

1. 本次新增的两条指令分别是什么，属于哪两类指令。
2. `andi` 主要改了哪些控制信号。
3. `jal` 为什么除了改跳转地址，还要增加写回和流水线冲刷。
4. 终端 `PASS` 截图。
5. 波形中 `jal` 前后 PC 变化截图。
6. 波形或寄存器结果中 `x4`、`x5` 没有被错误写回的证据。
