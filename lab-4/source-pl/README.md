# Lab-4-0507 source-pl 使用说明

本目录是 `lab-4-0507` 的独立运行目录，用来验证流水线 CPU 新增的两条指令：

- `andi`
- `jal`

## 运行前先知道这几件事

1. 仿真入口是 `plcomp_tb.v`，顶层模块名是 `plcomp_tb`。
2. 测试程序文件是 `rv32_pl_sim.dat`。
3. 本目录下的脚本默认都要在当前目录运行，否则可能找不到 `rv32_pl_sim.dat`。

## 本次实验重点文件

- `ctrl.v`
  控制器，负责识别 `andi`、`jal` 并给出控制信号。
- `EXT.v`
  立即数扩展模块，`jal` 需要 J-type 立即数扩展。
- `NPC.v`
  下一个 PC 选择逻辑，`jal` 需要从这里生成跳转目标地址。
- `PLCPU.v`
  流水线顶层，负责把跳转冲刷逻辑接起来。
- `plcomp_tb.v`
  testbench，负责加载程序、导出波形、打印调试信息和自动验收。

## 运行方法

### Windows

编译并运行：

```powershell
.\build.bat run
```

只编译：

```powershell
.\build.bat build
```

打开波形：

```powershell
.\build.bat wave
```

清理生成文件：

```powershell
.\build.bat clean
```

如果你更想用 Python 脚本：

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

## 验收标准

运行成功后，终端应看到：

```text
[PASS] lab-4 source-pl checks passed.
```

同时会生成：

- `plcpu_sim.out`
- `plcpu_sim.vcd`

## 你应该观察到的正确结果

### `andi`

测试程序里先让：

- `x1 = 5`

然后执行：

- `andi x2, x1, 3`

因为：

- `5 = 0101`
- `3 = 0011`
- `0101 & 0011 = 0001`

所以应看到：

- `x2 = 1`

### `jal`

测试程序里执行：

- `jal x3, 12`

应同时看到两件事：

1. `x3` 写回 `PC + 4`
2. PC 跳转到目标地址继续执行

在当前测试程序里，验收值是：

- `x3 = 0x18`

### 跳转冲刷

`jal` 之后顺序位置上的两条指令本来会写：

- `x4`
- `x5`

但因为它们应该被跳过，所以正确结果是：

- `x4 = 0`
- `x5 = 0`

如果你看到它们被写成了非零值，通常说明你只改了跳转地址，没有清空两级流水。

## 波形里建议看什么

建议在 GTKWave 里重点观察：

- `clk`
- `rstn`
- `plcomp.PC`
- `plcomp.instr`
- `plcomp.U_PLCPU.EX_pc`
- `plcomp.U_PLCPU.EX_NPCOp`
- `plcomp.U_PLCPU.NPC`
- `plcomp.U_PLCPU.U_RF.RFWr`
- `plcomp.U_PLCPU.U_RF.A3`
- `plcomp.U_PLCPU.U_RF.WD`

观察重点：

1. `jal` 执行周期里，`NPC` 是否切到跳转目标。
2. `x3` 是否写回 `PC+4`。
3. `x4`、`x5` 是否没有被错误写回。
4. 跳转目标后的 `x6` 是否成功写成 `9`。

## 常见错误排查

### 终端没有输出 `PASS`

先检查：

- `ctrl.v` 是否真的识别了 `andi` 和 `jal`
- `EXT.v` 是否支持 J-type 扩展
- `NPC.v` 是否支持跳转
- `PLCPU.v` 是否做了 IF/ID 和 ID/EX 清空

### `x3` 不是 `PC+4`

这通常说明：

- `WDSel` 没有给 `jal` 选到 `PC+4`
- 或者写回阶段没有正确保留该条指令对应的 `PC`

### `x4`、`x5` 被写坏了

这通常说明：

- 跳转后没有冲刷流水线
- 或者只清空了一级，不够

### 找不到 `rv32_pl_sim.dat`

说明运行目录不对。请先进入本目录，再执行：

```powershell
cd lab-4-0507/source-pl
```

## 一句话总结

本实验要真正做对，不是只让 `jal` 能跳，而是要同时满足：

- 会跳
- 会写回 `PC+4`
- 会把错误进入流水线的顺序指令清掉
