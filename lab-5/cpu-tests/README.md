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

在仓库根目录执行：

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

## 只运行某一类 CPU

```powershell
.\grade.bat --target sc
.\grade.bat --target pl
```

## 查看测试点列表

```powershell
.\grade.bat --list
```

## 新增测试点的方法

1. 在 `tests/sc` 或 `tests/pl` 下新增一个 `.dat` 文件，每行写一条 32 位机器码。
2. 在 `manifest.json` 的 `tests` 数组里新增一项。
3. 在 `checks.regs` 写期望寄存器值，例如 `"x3": "0x0000000c"`。
4. 在 `checks.mem` 写期望数据内存 word 下标和值，例如 `"4": "0x00000111"`。
5. 重新运行 `.\grade.bat`。

注意：流水线测试点如果检查相关冒险以外的单条指令功能，建议在产生数据和使用数据之间插入若干条 `00000013`，也就是 `nop`，这样测试目标更单一。
