# Lab-5: Vivado board number display demo

## Goal

This lab builds a minimal Vivado project for the Nexys4 DDR style board used by the course. The demo reads the 16 slide switches and displays the value in two ways:

- `led_o[15:0]` mirrors `sw_i[15:0]`.
- The 8-digit seven-segment display shows `{16'h0000, sw_i}` as hexadecimal.

This is intentionally a small board bring-up demo. It is independent from the CPU labs.

## Directory

```text
lab-5/
├─ README.md
├─ Makefile
├─ build.bat
├─ constraints/
│  └─ Nexys4DDR_NumberDemo.xdc
├─ scripts/
│  └─ create_vivado_project.tcl
├─ sim/
│  └─ tb_board_number_demo.v
└─ src/
   ├─ board_number_demo.v
   ├─ hex_to_7seg.v
   └─ scan_7seg.v
```

## How to run simulation

Linux / WSL:

```bash
make sim
```

Windows:

```powershell
.\build.bat sim
```

Expected result:

```text
[PASS] lab-5 board number demo checks passed.
```

## How to create the Vivado project

Run this on a machine with Vivado installed:

```bash
vivado -mode batch -source scripts/create_vivado_project.tcl
```

The generated project is placed under:

```text
lab-5/vivado/number_demo/
```

Generated Vivado files are not committed. Recreate them with the TCL script when needed.

## Board operation

1. Open the generated Vivado project.
2. Synthesize, implement, and generate bitstream.
3. Program the board.
4. Change `sw_i[15:0]`.
5. Check that LEDs mirror the switches.
6. Check that the seven-segment display shows the same 16-bit value as hex on the lower 4 digits.

Example:

- `sw_i = 16'h1234`
- LEDs show `0001_0010_0011_0100`
- Seven-segment display shows `00001234`

## Notes

- `rstn` is active-low.
- Seven-segment outputs are active-low, matching the existing course constraint style.
- `sw_i[15]` is only a normal data switch in this lab. It is not used as a CPU clock selector.
