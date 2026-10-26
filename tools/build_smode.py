#!/usr/bin/env python3
"""Build an S-mode test image: SBI firmware at RAM offset 0,
given S-mode test at offset 0x1000 (word 1024). Same layout as
build_sbi.py, but the test program is a command-line argument
so the core-gaps tests can reuse the firmware.

Usage (from the big32 directory):
  python3 tools/build_smode.py <test.s> <out.hex>
Writes the image hex and prints word counts. Fails loudly if
the firmware exceeds its 1024-word slot.
"""
import os
import subprocess
import sys


def assemble(src, out):
    r = subprocess.run(["python3", "tools/soc_asm.py", src, out],
                       capture_output=True, text=True)
    if r.returncode != 0:
        print(r.stdout, r.stderr)
        sys.exit(1)
    words = []
    with open(out) as fh:
        for line in fh:
            line = line.strip()
            if line:
                words.append(int(line, 16))
    return words


def main():
    if len(sys.argv) != 3:
        print("usage: build_smode.py <test.s> <out.hex>")
        return 2
    test_src, out_hex = sys.argv[1], sys.argv[2]
    base = os.path.splitext(os.path.basename(test_src))[0]
    fw = assemble("os_programs/sbi_firmware.s",
                  f"soc2_hex/{base}_fw.hex")
    test = assemble(test_src, f"soc2_hex/{base}_test.hex")
    if len(fw) > 1024:
        print(f"build_smode FAIL: firmware is {len(fw)} words, "
              "over the 1024-word slot before the S test at 0x1000")
        return 1
    image = fw + [0] * (1024 - len(fw)) + test
    with open(out_hex, "w") as fh:
        for w in image:
            fh.write(f"{w:08x}\n")
    print(f"build_smode: firmware {len(fw)} words, "
          f"test {len(test)} words, image {len(image)} words "
          f"-> {out_hex}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
