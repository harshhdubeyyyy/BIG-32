#!/usr/bin/env python3
"""Build the SBI test image: firmware at RAM offset 0, S-mode
test at offset 0x1000 (word 1024). Firmware must fit in 1024 words
or the build fails loudly rather than overlapping the test.

Usage (from the big32 directory):
  python3 tools/build_sbi.py
Writes soc2_hex/sbi.hex (and prints word counts).
"""
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
    fw = assemble("os_programs/sbi_firmware.s", "soc2_hex/sbi_fw.hex")
    test = assemble("os_programs/sbi_test.s", "soc2_hex/sbi_test.hex")
    if len(fw) > 1024:
        print(f"build_sbi FAIL: firmware is {len(fw)} words, "
              "over the 1024-word slot before the S test at 0x1000")
        return 1
    image = fw + [0] * (1024 - len(fw)) + test
    with open("soc2_hex/sbi.hex", "w") as fh:
        for w in image:
            fh.write(f"{w:08x}\n")
    print(f"build_sbi: firmware {len(fw)} words, "
          f"test {len(test)} words, image {len(image)} words "
          "-> soc2_hex/sbi.hex")
    return 0


if __name__ == "__main__":
    sys.exit(main())
