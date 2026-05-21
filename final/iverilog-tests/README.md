# Iverilog 按点给分测试模板

这个目录提供最终验收可复用的 testbench 模板。老师或学生可以把它们复制到自己的单周期/流水线工程中，再配合多个小 `.dat` 程序做按点给分。

## 文件说明

- `tb/sc_final_tb.v`：单周期 CPU 测试模板，默认实例化 `sccomp`。
- `tb/pl_final_tb.v`：流水线 CPU 测试模板，默认实例化 `plcomp`。
- `tests/sc/`：单周期 CPU 指令测试数据。
- `tests/pl/`：流水线 CPU 指令测试数据。
- `tests/expected_results.json`：每个测试数据对应的期望寄存器结果和覆盖指令。

两个 testbench 都支持：

```text
+IMEM=<机器码 dat 文件路径>
+CYCLES=<运行周期数>
```

仿真结束后会打印 32 个寄存器和前 64 个数据内存 word：

```text
[REG] x1=00000005
[MEM] m4=12345678
```

评分脚本可以解析这些行，再和每个测试点的期望值比较。

## 使用方式示例

单周期 CPU：

```powershell
iverilog -I . -s sc_final_tb -o sc_final.out alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v sccomp.v SCCPU.v RF.v tb\sc_final_tb.v
vvp sc_final.out +IMEM=tests\sc_slt_signed.dat +CYCLES=80
```

流水线 CPU：

```powershell
iverilog -I . -s pl_final_tb -o pl_final.out alu.v ctrl.v dm.v EXT.v im.v NPC.v PC.v plcomp.v PLCPU.v pl_reg.v RF.v tb\pl_final_tb.v
vvp pl_final.out +IMEM=tests\pl_jalr_flush.dat +CYCLES=160
```

## 建议测试组织方式

建议一个 `.dat` 文件只测一个指令或一个相关行为，例如：

- `sc_slt_signed.dat`
- `sc_sltu_unsigned.dat`
- `sc_branch_blt_taken.dat`
- `pl_jal_flush.dat`
- `pl_load_use_stall.dat`

每个 `.dat` 文件对应多个检查项，例如检查 3 个寄存器和 1 个内存值，则这个测试点总分为 4 分。

## 已提供的测试数据

单周期 CPU：

```text
tests/sc/sc_compare_slt.dat          slt
tests/sc/sc_compare_sltu.dat         sltu
tests/sc/sc_logic_immediate.dat      andi, ori, xori
tests/sc/sc_shift_immediate.dat      slli, srli, srai
tests/sc/sc_set_less_immediate.dat   slti, sltiu
tests/sc/sc_branches.dat             bne, bge, bgeu, blt, bltu
tests/sc/sc_jalr.dat                 jalr
```

流水线 CPU：

```text
tests/pl/pl_compare_slt.dat          slt
tests/pl/pl_compare_sltu.dat         sltu
tests/pl/pl_logic_immediate.dat      andi, ori, xori
tests/pl/pl_shift_immediate.dat      slli, srli, srai
tests/pl/pl_set_less_immediate.dat   slti, sltiu
tests/pl/pl_branches.dat             bne, bge, bgeu, blt, bltu
tests/pl/pl_beq.dat                  beq
tests/pl/pl_jal.dat                  jal
tests/pl/pl_jalr.dat                 jalr
```

这些文件覆盖了 `final/README.md` 中列出的全部要求指令。每个 `.dat` 内部包含多个检查点，期望结果见：

```text
tests/expected_results.json
```

注意：老师原文中的 `sltui` 按 RISC-V 标准写作 `sltiu`，测试数据和期望结果均使用 `sltiu`。
