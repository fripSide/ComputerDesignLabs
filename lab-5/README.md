# Lab-5: Vivado 开发板读数字亮数字 Demo

## 实验目标

本次实验做一个最小 Vivado 开发板工程，用来验证开发板输入和显示输出是否能正常工作。

功能要求：

- 读取 16 个拨码开关 `sw_i[15:0]`。
- 16 个 LED `led_o[15:0]` 直接显示拨码开关状态。
- 8 位七段数码管显示 `{16'h0000, sw_i}` 的十六进制值。

例子：

- 拨码开关输入 `16'h1234`
- LED 显示同样的 16 位二进制状态
- 数码管显示 `00001234`

本实验不是 CPU 实验，不需要运行单周期 CPU 或流水线 CPU。

## 目录说明

```text
lab-5/
|-- README.md
|-- Makefile
|-- build.bat
|-- constraints/
|   `-- Nexys4DDR_NumberDemo.xdc
|-- scripts/
|   `-- create_vivado_project.tcl
|-- sim/
|   `-- tb_board_number_demo.v
`-- src/
    |-- board_number_demo.v
    |-- hex_to_7seg.v
    `-- scan_7seg.v
```

主要文件：

- `src/board_number_demo.v`
  顶层模块，连接拨码开关、LED 和七段数码管。
- `src/scan_7seg.v`
  七段数码管动态扫描模块。
- `src/hex_to_7seg.v`
  4 位十六进制数到七段管段码的译码模块。
- `constraints/Nexys4DDR_NumberDemo.xdc`
  Nexys4 DDR 开发板引脚约束。
- `scripts/create_vivado_project.tcl`
  自动创建 Vivado 工程的脚本。
- `sim/tb_board_number_demo.v`
  用 `iverilog` 自动验证功能正确性的 testbench。

## 第一部分：先用仿真验证代码正确

这一步不需要 Vivado，只需要 `iverilog` 和 `vvp`。

### Windows 运行方法

进入目录：

```powershell
cd lab-5
```

运行自动验证：

```powershell
.\build.bat sim
```

如果环境正确，应看到：

```text
[PASS] lab-5 board number demo checks passed.
```

这说明：

- LED 会跟随拨码开关变化。
- 七段数码管能正确显示十六进制数字。
- `16'h1234`、`16'hABCD` 这类输入已经被自动测试过。

### Linux / WSL 运行方法

进入目录：

```bash
cd lab-5
```

运行：

```bash
make sim
```

通过标准同样是：

```text
[PASS] lab-5 board number demo checks passed.
```

## 第二部分：创建 Vivado 工程

这一步需要电脑已经安装 Vivado。

在 `lab-5` 目录下执行：

```powershell
.\build.bat vivado
```

或者直接执行：

```powershell
vivado -mode batch -source scripts\create_vivado_project.tcl
```

脚本会生成 Vivado 工程：

```text
lab-5/vivado/number_demo/
```

打开工程文件：

```text
lab-5/vivado/number_demo/number_demo.xpr
```

## 第三部分：在 Vivado 中生成 bitstream

打开 `number_demo.xpr` 后按下面步骤操作：

1. 确认顶层模块是 `board_number_demo`。
2. 点击 `Run Synthesis`。
3. 综合完成后点击 `Run Implementation`。
4. 实现完成后点击 `Generate Bitstream`。
5. 连接开发板。
6. 打开 Hardware Manager。
7. Program Device，选择生成的 `.bit` 文件。

如果综合或实现报错，优先检查：

- 约束文件是否被加入工程。
- 顶层端口名是否是 `clk`、`rstn`、`sw_i`、`led_o`、`disp_seg_o`、`disp_an_o`。
- 开发板型号是否匹配 Nexys4 DDR / Artix-7 `xc7a100tcsg324-1`。

## 第四部分：上板后怎么验证

烧录完成后，直接拨动开发板上的 16 个开关。

检查点：

1. LED 是否和拨码开关一一对应。
2. 数码管低 4 位是否显示拨码开关组成的十六进制数。
3. 数码管高 4 位是否显示 `0000`。

例子：

- `sw_i = 16'h0001`，数码管显示 `00000001`。
- `sw_i = 16'h00AF`，数码管显示 `000000AF`。
- `sw_i = 16'h1234`，数码管显示 `00001234`。

## 常见问题

### 1. 运行 `.\build.bat sim` 提示找不到 `iverilog`

说明当前电脑没有把 `iverilog` 加入 PATH。

如果你安装的是 OSS CAD Suite，可以检查路径是否类似：

```text
D:\oss-cad-suite\oss-cad-suite
```

当前脚本会自动尝试这个路径。如果你的安装路径不同，需要手动把 `iverilog.exe` 和 `vvp.exe` 所在目录加入 PATH。

### 2. 运行 `.\build.bat vivado` 提示找不到 `vivado`

说明当前终端没有 Vivado 命令。

处理方法：

- 从 Vivado 自带的命令行启动。
- 或者把 Vivado 的 `bin` 目录加入 PATH。
- 也可以直接打开 Vivado GUI，再用 Tcl Console 执行 `scripts/create_vivado_project.tcl`。

可以先检查本机是否能找到 Vivado：

```powershell
Get-Command vivado
```

如果没有输出，继续检查常见安装位置：

```powershell
Get-ChildItem C:\Xilinx,D:\Xilinx -Filter vivado.bat -Recurse -ErrorAction SilentlyContinue
```

如果找到了类似下面的文件：

```text
C:\Xilinx\Vivado\2023.2\bin\vivado.bat
```

可以临时加入 PATH 后再运行：

```powershell
$env:PATH = "C:\Xilinx\Vivado\2023.2\bin;$env:PATH"
.\build.bat vivado
```

如果本机根本没有 `vivado.bat`，就说明没有安装 Vivado，需要先安装 Vivado，或者换到实验室/机房已经安装 Vivado 的电脑上运行本实验。

### 3. 数码管显示方向看起来反了

本实验按常见 Nexys4 DDR 七段管连接方式扫描：

- `disp_an_o[0]` 显示最低 4 位。
- `disp_an_o[7]` 显示最高 4 位。

如果板子型号或约束不同，显示方向可能需要按实际硬件调整。

### 4. 为什么 Vivado 工程目录没有提交到仓库

`lab-5/vivado/` 是生成目录，文件多且容易包含本机路径。仓库只提交源码、约束和创建脚本。

需要 Vivado 工程时，重新运行：

```powershell
.\build.bat vivado
```

## 提交验收建议

实验报告建议包含：

1. `.\build.bat sim` 通过截图。
2. Vivado 综合、实现、生成 bitstream 成功截图。
3. 上板后拨码开关和 LED 对应截图。
4. 上板后数码管显示输入数字的截图。
