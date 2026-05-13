# CPU 小测试点自动评分

这个目录用于完成老师要求的第二部分：把单周期 CPU 和流水线 CPU 的大测试拆成多个小 `.dat` 文件，用 `iverilog` 自动运行，并检查寄存器和数据内存结果。

## 目录结构

```text
cpu-tests/
  grade_cpu_tests.py       # 自动编译、运行、评分
  manifest.json            # 测试点列表和期望结果
  tb/                      # 通用评分 testbench
  tests/sc/                # lab-3 单周期 CPU 小测试
  tests/pl/                # lab-4-0507 流水线 CPU 小测试
```

默认测试对象：

- 单周期：`lab-3/source-sc`
- 流水线：`lab-4-0507/source-pl`

## 运行全部测试

先确认本机已经安装 OSS CAD Suite，或者命令行可以找到 `iverilog` 和 `vvp`：

```powershell
where iverilog
where vvp
```

如果上面两个命令能找到路径，再从仓库根目录执行：

```powershell
cd lab-5\cpu-tests
.\grade.bat
```

全部通过时会看到类似输出：

```text
[PASS] sc_addi: 2/2
[PASS] sc_rtype_add_sub: 2/2
...
Score: 31/31
```

每一行 `[PASS] 测试名: 通过检查数/总检查数` 表示一个小测试点。最后的 `Score` 是所有寄存器和内存检查项的总分。

## 只运行某一类 CPU

```powershell
.\grade.bat --target sc
.\grade.bat --target pl
```

## 查看测试点列表

```powershell
.\grade.bat --list
```

当前测试点覆盖：

- 单周期 CPU：`addi`、R 型 `add/sub`、逻辑运算、`sw/lw`、`beq`。
- 流水线 CPU：`addi`、`add`、`andi`、`jal` 跳转冲刷、`sw/lw`、`lui`。

## 如果测试失败怎么看

失败时会出现类似：

```text
[FAIL] pl_add: 2/3
       x3: expected 0x0000000c, got 0x00000000
```

含义是 `pl_add` 测试里一共有 3 个检查项，通过了 2 个，寄存器 `x3` 的结果不对。排查顺序建议如下：

1. 先打开对应 `.dat` 文件，例如 `tests/pl/pl_add.dat`，确认测试程序是什么。
2. 再打开 `manifest.json`，找到同名测试，确认期望的寄存器或内存值。
3. 如果是寄存器不对，重点检查 CPU 的译码、ALU、写回或流水线寄存器。
4. 如果是内存不对，重点检查 `dm.v`、`MemWrite/MemRead`、地址选择和写入数据。
5. 如果流水线测试失败，额外检查数据冒险、跳转冲刷和 nop 插入是否符合当前 CPU 实现。

## 新增测试点的方法

1. 在 `tests/sc` 或 `tests/pl` 下新增一个 `.dat` 文件，每行写一条 32 位机器码。
2. 在 `manifest.json` 的 `tests` 数组里新增一项。
3. 在 `checks.regs` 写期望寄存器值，例如 `"x3": "0x0000000c"`。
4. 在 `checks.mem` 写期望数据内存 word 下标和值，例如 `"4": "0x00000111"`。
5. 重新运行 `.\grade.bat`。

注意：流水线测试点如果检查相关冒险以外的单条指令功能，建议在产生数据和使用数据之间插入若干条 `00000013`，也就是 `nop`，这样测试目标更单一。

下面是一个最小示例。假设新增 `tests/sc/sc_addi_example.dat`：

```text
00500093
0000006f
```

含义是：

- `00500093`：`addi x1, x0, 5`
- `0000006f`：`jal x0, 0`，让程序停在原地，避免继续执行未初始化指令。

然后在 `manifest.json` 的 `tests` 数组里加入：

```json
{
  "name": "sc_addi_example",
  "target": "sc",
  "program": "tests/sc/sc_addi_example.dat",
  "checks": {
    "regs": {
      "x1": "0x00000005"
    }
  }
}
```

再次运行：

```powershell
.\grade.bat
```
