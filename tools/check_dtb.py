#!/usr/bin/env python3
"""Minimal FDT walker for the Phase 5 DTB.

Parses soc2_hex/big32.dtb (big-endian FDT format) and checks:
magic 0xd00dfeed, version, totalsize matches the file length,
and the presence of /memory, /cpus/cpu, /soc/uart, /soc/plic,
/soc/clint, /soc/virtio nodes with their reg properties.
This proves the blob is a structurally valid device tree that
a kernel's libfdt can walk; it is NOT a substitute for booting
a kernel against it (see LINUX_BOOT.md).

Usage (from the big32 directory):
  dtc -I dts -O dtb os_programs/big32.dts -o soc2_hex/big32.dtb
  python3 tools/check_dtb.py
"""
import struct
import sys

FDT_BEGIN_NODE = 1
FDT_END_NODE = 2
FDT_PROP = 3
FDT_NOP = 4
FDT_END = 9


def main():
    with open("soc2_hex/big32.dtb", "rb") as fh:
        blob = fh.read()
    (magic, totalsize, off_struct, off_strings, off_rsvmap,
     version, _compat, cpu_boot, size_strings,
     size_struct) = struct.unpack(">10I", blob[:40])
    problems = []
    if magic != 0xD00DFEED:
        problems.append(f"magic {magic:#x} != 0xd00dfeed")
    if totalsize != len(blob):
        problems.append(f"totalsize {totalsize} != file {len(blob)}")
    if version < 17:
        problems.append(f"version {version} < 17")
    # Walk the structure block.
    nodes = []
    props = {}
    path = []
    pos = off_struct
    cur = ""
    while True:
        (tag,) = struct.unpack(">I", blob[pos:pos + 4])
        pos += 4
        if tag == FDT_END:
            break
        if tag == FDT_BEGIN_NODE:
            end = blob.index(b"\0", pos)
            name = blob[pos:end].decode()
            pos += (end - pos + 1 + 3) & ~3
            path.append(name)
            cur = "/" + "/".join(p for p in path if p)
            nodes.append(cur)
            props[cur] = {}
        elif tag == FDT_END_NODE:
            path.pop()
            cur = "/" + "/".join(p for p in path if p)
        elif tag == FDT_PROP:
            ln, nameoff = struct.unpack(">II", blob[pos:pos + 8])
            pos += 8
            data = blob[pos:pos + ln]
            pos += (ln + 3) & ~3
            end = blob.index(b"\0", off_strings + nameoff)
            pname = blob[off_strings + nameoff:end].decode()
            props[cur][pname] = data
        elif tag == FDT_NOP:
            continue
        else:
            problems.append(f"unknown tag {tag} at {pos}")
            break
    for want in ("/memory@80000000", "/cpus/cpu@0",
                 "/soc/uart@10010000", "/soc/plic@0c000000",
                 "/soc/clint@2000000", "/soc/virtio@10001000"):
        if want not in nodes:
            problems.append(f"missing node {want}")
    checks = [
        ("/memory@80000000", "reg", bytes.fromhex("80000000" "00100000")),
        ("/soc/uart@10010000", "compatible", b"ns16550a\0"),
        ("/soc/virtio@10001000", "compatible", b"virtio,mmio\0"),
    ]
    for node, prop, want in checks:
        got = props.get(node, {}).get(prop)
        if got != want:
            problems.append(f"{node} {prop}: got {got!r}, want {want!r}")
    if problems:
        print("dtb FAIL: " + "; ".join(problems))
        return 1
    print(f"dtb PASS: {len(blob)} bytes, version {version}, "
          f"{len(nodes)} nodes, all required nodes present")
    return 0


if __name__ == "__main__":
    sys.exit(main())
