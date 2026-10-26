#!/usr/bin/env python3
"""Bootloader check (Phase 5).

Assembles the bootloader (os_programs/bootloader.s) and the
boot kernel (soc2_programs/boot_kernel.s), builds the DTB,
then runs the soc2 testbench with the kernel as the virtio
disk image (+DISKHEX: sector 0 = kernel words). The
bootloader must load sectors 0-1 to 0x80010000, drop to the
kernel in S-mode with a1=DTB, and the kernel must print 'B'
+ 'K' via SBI putchar and shut down via SRST.

Pass: halted==1, s0 (regs[8]) == 0, UART contains 'B' and
'K' and does NOT contain '!' (the bootloader's fail flag).

Usage (from the big32 directory):
  python3 tools/boot_check.py
"""
import os
import subprocess
import sys


def run(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def main():
    os.makedirs("soc2_hex", exist_ok=True)
    r = run(["python3", "tools/soc_asm.py", "os_programs/bootloader.s",
             "soc2_hex/boot.hex"])
    if r.returncode != 0:
        print("boot FAIL: bootloader assemble failed")
        print(r.stdout, r.stderr)
        return 1
    print(r.stdout.strip())
    r = run(["python3", "tools/soc_asm.py", "soc2_programs/boot_kernel.s",
             "soc2_hex/boot_kernel.hex"])
    if r.returncode != 0:
        print("boot FAIL: kernel assemble failed")
        print(r.stdout, r.stderr)
        return 1
    print(r.stdout.strip())
    r = run(["dtc", "-I", "dts", "-O", "dtb", "os_programs/big32.dts",
             "-o", "soc2_hex/big32.dtb"])
    if r.returncode != 0:
        print("boot FAIL: dtc failed")
        print(r.stdout, r.stderr)
        return 1
    with open("soc2_hex/big32.dtb", "rb") as fh:
        blob = fh.read()
    with open("soc2_hex/big32.dtb.txt", "w") as fh:
        for b in blob:
            fh.write(f"{b:02x}\n")
    print(f"dtb: {len(blob)} bytes -> soc2_hex/big32.dtb")
    out = run(["vvp", "sim/tb_soc2.vvp", "+HEX=soc2_hex/boot.hex",
               "+DISKHEX=soc2_hex/boot_kernel.hex",
               "+DTBFILE=soc2_hex/big32.dtb.txt", "+DTBOFF=131072"],
              timeout=300)
    regs = cycles = halted = None
    uart_lines = []
    for line in out.stdout.splitlines():
        if "CYCLES:" in line:
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
    for want in ("B", "K"):
        if want not in uart:
            problems.append(f"UART missing {want!r} (got {uart!r})")
    if "!" in uart:
        problems.append("UART contains '!' (bootloader fail flag)")
    if problems:
        print("boot FAIL: " + "; ".join(problems))
        print(f"UART:\n{uart}\nRAW:\n{out.stdout}\n{out.stderr}")
        return 1
    print(f"boot PASS (cycles={cycles}, s0=0, UART has 'BK')")
    return 0


if __name__ == "__main__":
    sys.exit(main())
