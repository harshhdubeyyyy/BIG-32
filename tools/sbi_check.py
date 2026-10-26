#!/usr/bin/env python3
"""SBI + DTB checker (Phase 5).

Builds the SBI image (tools/build_sbi.py), builds the DTB with
dtc (os_programs/big32.dts -> soc2_hex/big32.dtb), converts the
DTB to one hex byte per line (soc2_hex/big32.dtb.txt), runs it
on the soc2 Verilog top with the DTB loaded at RAM offset
0x20000, and checks: halted, s0 (x8) == 0, UART contains 'S'
(legacy putchar) and does NOT contain '!' (firmware trap flag).

Usage (from the big32 directory): python3 tools/sbi_check.py
"""
import subprocess
import sys


def main():
    r = subprocess.run(["python3", "tools/build_sbi.py"],
                       capture_output=True, text=True)
    print(r.stdout, end="")
    if r.returncode != 0:
        print(f"sbi FAIL: build failed\n{r.stderr}")
        return 1
    r = subprocess.run(["dtc", "-I", "dts", "-O", "dtb",
                        "os_programs/big32.dts",
                        "-o", "soc2_hex/big32.dtb"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(f"sbi FAIL: dtc failed\n{r.stdout}{r.stderr}")
        return 1
    with open("soc2_hex/big32.dtb", "rb") as fh:
        blob = fh.read()
    with open("soc2_hex/big32.dtb.txt", "w") as fh:
        for b in blob:
            fh.write(f"{b:02x}\n")
    print(f"dtb: {len(blob)} bytes -> soc2_hex/big32.dtb")
    out = subprocess.run(
        ["vvp", "sim/tb_soc2.vvp", "+HEX=soc2_hex/sbi.hex",
         "+DTBFILE=soc2_hex/big32.dtb.txt", "+DTBOFF=131072"],
        capture_output=True, text=True, timeout=300)
    regs = cycles = halted = None
    uart_lines = []
    for line in out.stdout.splitlines():
        if "CYCLES:" in line:
            # A UART byte printed with no newline merges with
            # this line ("SCYCLES: ..."): keep the byte as UART
            # instead of swallowing it with the cycles parse.
            prefix, _, suffix = line.partition("CYCLES:")
            if prefix and not prefix.startswith("WARNING:"):
                uart_lines.append(prefix)
            cycles = int(suffix)
        elif line.startswith("HALTED:"):
            halted = int(line[7:])
        elif line.startswith("REGS:"):
            regs = [int(x) for x in line[5:].split()]
        elif line.startswith("RAM:"):
            continue
        elif "$finish called" in line:
            continue
        else:
            uart_lines.append(line)
    uart = "".join(l + "\n" for l in uart_lines)
    problems = []
    if halted != 1:
        problems.append(f"halted={halted}")
    if regs is None or regs[8] != 0:
        problems.append(f"s0={regs[8] if regs else None} (expected 0)")
    if "S" not in uart:
        problems.append(f"UART missing 'S' (got {uart!r})")
    if "!" in uart:
        problems.append(f"UART contains '!' (firmware trap flag)")
    if problems:
        print("sbi FAIL: " + "; ".join(problems))
        print(f"UART:\n{uart}\nRAW:\n{out.stdout}\n{out.stderr}")
        return 1
    print(f"sbi PASS (cycles={cycles}, s0=0, UART={uart!r})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
