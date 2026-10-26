#!/usr/bin/env python3
"""Build the DTB used for the Linux boot attempt.

Differs from the standard os_programs/big32.dts in two ways,
both documented simulation choices (not hardware claims):

- memory reg 0x00100000 (1 MiB) -> 0x04000000 (64 MiB):
  the kernel Image alone is ~38 MB, so the 1 MiB default
  RAM cannot hold it. The boot attempt runs soc2 with
  -Pbig32_soc2.MEM_BYTES=67108864, and the DTB must agree
  or the kernel will size memory wrong.
- timebase-frequency 10000000 (10 MHz) -> 100000 (100 kHz):
  mtime ticks 1/cycle in soc2, so a kernel second costs
  timebase-frequency cycles. At 10 MHz a single kernel
  second is 10M cycles (~25 wall minutes at Icarus speed);
  at 100 kHz it is 100K cycles. The SBI timer and rdtime
  both use the same mtime, so timekeeping stays
  self-consistent; kernel time simply runs 100x faster
  relative to cycles. Without this, a bounded boot attempt
  cannot get past the first second-scale timeout.

Writes soc2_hex/big32_kboot.dtb (+ .txt hex-byte file for
the testbench) and prints the size.

Usage (from the big32 directory):
  python3 tools/build_kboot_dtb.py
"""
import subprocess
import sys

src = open("os_programs/big32.dts").read()
assert "0x00100000" in src and "10000000" in src
src = src.replace("0x00100000", "0x04000000")
src = src.replace("timebase-frequency = <10000000>;",
                  "timebase-frequency = <100000>;")
open("/tmp/big32_kboot.dts", "w").write(src)
r = subprocess.run(["dtc", "-I", "dts", "-O", "dtb",
                    "/tmp/big32_kboot.dts",
                    "-o", "soc2_hex/big32_kboot.dtb"],
                   capture_output=True, text=True)
print(r.stdout.strip(), r.stderr.strip())
if r.returncode:
    sys.exit(r.returncode)
data = open("soc2_hex/big32_kboot.dtb", "rb").read()
with open("soc2_hex/big32_kboot.dtb.txt", "w") as fh:
    for b in data:
        fh.write(f"{b:02x}\n")
print(f"big32_kboot.dtb: {len(data)} bytes")
