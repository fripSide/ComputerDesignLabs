#!/usr/bin/env python3
"""Run small Icarus Verilog CPU tests and grade register/memory checks."""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
BUILD_DIR = ROOT / "build"
MANIFEST = ROOT / "manifest.json"
OSS_CAD_ROOT = Path(r"D:\oss-cad-suite\oss-cad-suite")
OSS_CAD_BIN = OSS_CAD_ROOT / "bin"
OSS_CAD_LIB = OSS_CAD_ROOT / "lib"

REG_RE = re.compile(r"^\[REG\] x(\d+)=(\w{8})$")
MEM_RE = re.compile(r"^\[MEM\] m(\d+)=(\w{8})$")


def load_manifest() -> dict:
    with MANIFEST.open("r", encoding="utf-8") as f:
        return json.load(f)


def tool_path(name: str) -> str:
    path = shutil.which(name)
    if path:
        return path

    candidate = OSS_CAD_BIN / f"{name}.exe"
    if candidate.exists():
        return str(candidate)

    raise RuntimeError(f"Cannot find {name}. Please install OSS CAD Suite or add {name} to PATH.")


def run(cmd: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    env = dict(os.environ)
    if OSS_CAD_BIN.exists():
        env["PATH"] = f"{OSS_CAD_BIN};{OSS_CAD_LIB};" + env.get("PATH", "")

    return subprocess.run(
        cmd,
        cwd=cwd,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        env=env,
        check=False,
    )


def build_target(target_key: str, target: dict) -> Path:
    iverilog = tool_path("iverilog")
    src_dir = (ROOT / target["source_dir"]).resolve()
    tb_file = (ROOT / target["testbench"]).resolve()
    out_file = BUILD_DIR / f"{target_key}_grade.out"
    BUILD_DIR.mkdir(exist_ok=True)

    sources = [str(src_dir / item) for item in target["sources"]]
    cmd = [
        iverilog,
        "-I",
        str(src_dir),
        "-s",
        target["top"],
        "-o",
        str(out_file),
        *sources,
        str(tb_file),
    ]
    proc = run(cmd, ROOT)
    if proc.returncode != 0:
        print(proc.stdout)
        raise RuntimeError(f"Build failed for {target_key}")
    return out_file


def parse_snapshot(output: str) -> tuple[dict[str, int], dict[int, int]]:
    regs: dict[str, int] = {}
    mem: dict[int, int] = {}
    for raw_line in output.splitlines():
        line = raw_line.strip()
        reg_match = REG_RE.match(line)
        if reg_match:
            regs[f"x{reg_match.group(1)}"] = int(reg_match.group(2), 16)
            continue

        mem_match = MEM_RE.match(line)
        if mem_match:
            mem[int(mem_match.group(1))] = int(mem_match.group(2), 16)
    return regs, mem


def normalize_word(value: str) -> int:
    return int(value, 16) & 0xFFFF_FFFF


def grade_test(test: dict, target: dict, executable: Path) -> tuple[int, int]:
    vvp = tool_path("vvp")
    program = (ROOT / test["program"]).resolve()
    cycles = int(test.get("cycles", target.get("cycles", 100)))
    proc = run([vvp, str(executable), f"+IMEM={program.as_posix()}", f"+CYCLES={cycles}"], ROOT)
    if proc.returncode != 0:
        print(proc.stdout)
        print(f"[FAIL] {test['name']}: simulation returned {proc.returncode}")
        return 0, count_checks(test)

    regs, mem = parse_snapshot(proc.stdout)
    passed = 0
    total = 0
    failures: list[str] = []

    for reg_name, expected_text in test.get("checks", {}).get("regs", {}).items():
        total += 1
        expected = normalize_word(expected_text)
        actual = regs.get(reg_name)
        if actual == expected:
            passed += 1
        else:
            failures.append(f"{reg_name}: expected 0x{expected:08x}, got {format_actual(actual)}")

    for mem_index_text, expected_text in test.get("checks", {}).get("mem", {}).items():
        total += 1
        mem_index = int(mem_index_text, 0)
        expected = normalize_word(expected_text)
        actual = mem.get(mem_index)
        if actual == expected:
            passed += 1
        else:
            failures.append(f"mem[{mem_index}]: expected 0x{expected:08x}, got {format_actual(actual)}")

    status = "PASS" if passed == total else "FAIL"
    print(f"[{status}] {test['name']}: {passed}/{total}")
    for failure in failures:
        print(f"       {failure}")
    return passed, total


def format_actual(value: int | None) -> str:
    if value is None:
        return "<missing>"
    return f"0x{value:08x}"


def count_checks(test: dict) -> int:
    checks = test.get("checks", {})
    return len(checks.get("regs", {})) + len(checks.get("mem", {}))


def clean() -> None:
    if BUILD_DIR.exists():
        shutil.rmtree(BUILD_DIR)
    for vcd in ROOT.glob("*.vcd"):
        vcd.unlink()
    print("[OK] clean finished")


def main() -> int:
    parser = argparse.ArgumentParser(description="Grade lab CPU unit-style tests with iverilog/vvp.")
    parser.add_argument("--target", choices=("sc", "pl", "all"), default="all")
    parser.add_argument("--list", action="store_true", help="list available tests and exit")
    parser.add_argument("--clean", action="store_true", help="remove generated grader outputs and exit")
    args = parser.parse_args()

    if args.clean:
        clean()
        return 0

    manifest = load_manifest()
    tests = manifest["tests"]
    if args.target != "all":
        tests = [test for test in tests if test["target"] == args.target]

    if args.list:
        for test in tests:
            print(f"{test['target']}: {test['name']} -> {test['program']}")
        return 0

    try:
        built: dict[str, Path] = {}
        total_passed = 0
        total_checks = 0

        for target_key, target in manifest["targets"].items():
            if any(test["target"] == target_key for test in tests):
                built[target_key] = build_target(target_key, target)

        for test in tests:
            target = manifest["targets"][test["target"]]
            passed, checks = grade_test(test, target, built[test["target"]])
            total_passed += passed
            total_checks += checks

        print(f"\nScore: {total_passed}/{total_checks}")
        return 0 if total_passed == total_checks else 1
    except RuntimeError as exc:
        print(f"[ERROR] {exc}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
