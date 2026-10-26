#!/usr/bin/env python3
"""Build the kernel-boot firmware image (Phase 5, Linux attempt).

Takes os_programs/sbi_firmware.s and changes ONLY the drop
target: mepc 0x80001000 (the S-mode test) -> 0x80400000 (where
the Linux kernel Image is loaded by the testbench via
+KIMGBIN at +KIMGOFF=4194304: the riscv kernel's setup_vm()
has BUG_ON((kernel_map.phys_addr % PMD_SIZE) != 0), and on
Sv32 (folded PMD) PMD_SIZE = PGDIR_SIZE = 4 MB. A 2MB-aligned
load (0x80200000) trips it: the kernel traps with ebreak
(scause 3) in setup_vm+0x80 and parks in its temporary wfi
trap vector forever (found 26 Oct 2026 by the dbg9
trap-entry trace: sepc 0x81204438, stvec 0x802000cc,
satp 0). So the load address is 4MB-aligned: 0x80400000
= RAM base + 0x400000).
Everything else (SBI handler, delegation, stacks) is identical
to the tested SBI firmware, so the kernel runs under the same
M-mode environment the SBI tests verified.

Writes soc2_hex/kboot_fw.hex and prints the word count.

Usage (from the big32 directory):
  python3 tools/build_kboot.py
"""
import re
import subprocess
import sys

SRC = "os_programs/sbi_firmware.s"
OUT = "soc2_hex/kboot_fw.hex"

src = open(SRC).read()
# The firmware entry sets mepc to the S test at 0x80001000.
# Replace ONLY the mepc load (the literal also appears in a
# comment, which must stay accurate to the original file).
old = "li t1, 0x80001000\n    csrw mepc, t1"
assert src.count(old) == 1, src.count(old)
src = src.replace(old, "li t1, 0x80400000\n    csrw mepc, t1")
open("/tmp/kboot_fw.s", "w").write(src)
r = subprocess.run(["python3", "tools/soc_asm.py", "/tmp/kboot_fw.s", OUT],
                   capture_output=True, text=True)
print(r.stdout.strip(), r.stderr.strip())
sys.exit(r.returncode)
