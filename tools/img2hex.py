#!/usr/bin/env python3
"""Convert a binary image to one 32-bit little-endian word per
line (the $readmemh format the soc2 testbench loads).

Usage:
  python3 tools/img2hex.py <binary> <hex-out>
"""
import struct
import sys

data = open(sys.argv[1], "rb").read()
words = []
for off in range(0, len(data), 4):
    chunk = data[off:off + 4]
    chunk = chunk + b"\x00" * (4 - len(chunk))
    words.append(struct.unpack("<I", chunk)[0])
with open(sys.argv[2], "w") as fh:
    for w in words:
        fh.write(f"{w:08x}\n")
print(f"{sys.argv[1]}: {len(data)} bytes -> {len(words)} words -> {sys.argv[2]}")
