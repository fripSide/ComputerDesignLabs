# Verilog Diff Report

This tool compares student Verilog source code with the provided demo source code
and generates:

- `diff.patch`: git-style unified diff text
- `report.html`: GitHub-like HTML report for review

## Recommended Directory Layout

Put student code in these two directories at the repository root:

```text
student-sc/   # single-cycle CPU Verilog files
student-pl/   # pipeline / multi-cycle CPU Verilog files
```

The default base demo directories are:

```text
CODExp/demo/sccpu_sim/source
CODExp/demo/plcpu_sim/source
```

Then run:

```powershell
powershell -ExecutionPolicy Bypass -File tools/Generate-VerilogDiffReport.ps1
```

Or, if Python is available:

```bash
python tools/generate_verilog_diff_report.py
```

Open:

```text
diff-report/report.html
```

## Custom Directories

```powershell
powershell -ExecutionPolicy Bypass -File tools/Generate-VerilogDiffReport.ps1 `
  -BaseSc CODExp/demo/sccpu_sim/source `
  -StudentSc path/to/student/sc/source `
  -BasePl CODExp/demo/plcpu_sim/source `
  -StudentPl path/to/student/pl/source `
  -Out diff-report
```

Only `.v` files are compared by default. Add more extensions if needed:

```powershell
powershell -ExecutionPolicy Bypass -File tools/Generate-VerilogDiffReport.ps1 -Ext .v,.sv
```

For one or more fully custom comparisons:

```bash
python tools/generate_verilog_diff_report.py \
  --pair single-cycle demo/sc student/sc \
  --pair pipeline demo/pl student/pl
```
