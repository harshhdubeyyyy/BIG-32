# big32: toward a real Linux boot (Phase 5)

Status and honesty first: **Linux does not boot on big32 yet.**
This document records the Phase 5 platform (SBI, device tree,
PLIC, 16550 UART, 64-bit timer, virtio block, bootloader, TLB,
A/D bits, misaligned traps), what was actually tested, how to
build a kernel for this machine, and exactly what remains.
Everything here runs in simulation only (Icarus Verilog 12.0).
Not silicon, not production-ready, not RISCOF/formal-verified.

## Phase 5 platform (soc2): memory map

New top `src/big32_soc2.v`. The old top `src/big32_soc.v`
(Phases 2-4) is untouched; `./run_os.sh` still runs on it.

| Region | Address | Notes |
|---|---|---|
| ROM (2 instructions) | 0x00000000-0x00000FFF | `lui t0, 0x80000; jalr x0, 0(t0)`. The core resets pc to 0 and RAM lives at 0x80000000, which jal cannot reach, so the ROM is the only bridge. ROM reads return the ROM word; data writes ignored. |
| RAM | 0x80000000 + MEM_BYTES | Parameter, default 1 MiB (was 16 MiB in the first soc2 draft; lowered because Icarus elaboration/simulation at 16 MiB was impractical — see below). Override with `iverilog -Pbig32_soc2.MEM_BYTES=...`. A kernel needs megabytes: the boot attempt uses 32 MiB. |
| PLIC | 0x0C000000 | Standard layout (see below). |
| Legacy UART (core-driven) | 0x10000000 TX, 0x10000004 RX, 0x10000008 status | Kept for the SBI console and old programs. The core's load overrides hard-code these addresses, which is why the 16550 lives elsewhere. |
| SBI IPI register | 0x10002000 | Any nonzero write (mask bit 0) sets the core's `irq_soft` line; a zero write clears it. Backs SBI send_ipi on this single-hart machine. |
| virtio-mmio block | 0x10001000 | Device ID 2, version 2, queue 0 only (see below). |
| 16550 UART | 0x10010000 | ns16550a-compatible (see below). |
| CLINT | 0x02004000 mtimecmp, 0x0200BFF8 mtime | 64-bit each (low +0, high +4). mtime +1/cycle; timer pends while mtime >= mtimecmp (64-bit compare). |

Testbench: `sim/tb_soc2.v`. Plusargs: `+HEX` (word image),
`+DISKHEX` (disk words), `+DTBFILE`/`+DTBOFF` (default 131072 =
0x20000), `+RX2FILE`/`+RX2START`/`+RX2PERIOD` (16550 RX
injection), `+EXTAT`/`+EXTLEN` (external line), `+MAXCYCLES`
(default 2000000), `+KIMG`/`+KIMGOFF` (kernel image, Linux
attempt only, default offset 65536 = 0x10000).

## Why the RAM is a word array (Icarus lesson)

The first soc2 used a byte array with ~44 combinational read
ports (fetch, data, virtio descriptor/ring/header/used reads).
Icarus elaboration scaled with ports x depth with a huge
constant: 64 KiB took 3m43s, 1 MiB hung past 164 s. The fix:

- RAM is a word array `memw` (MEM_WORDS = MEM_BYTES/4).
  Fetch and data each do 2 word reads + an unaligned merge
  by addr[1:0]. CPU stores use a shift trick
  (`st_data64`, `st_mask8`) with word read-modify-write, so
  unaligned stores spanning two words, A/D writebacks, AMO
  writes, and UART byte stores all work.
- Virtio FSM reads use ONE synchronous port (`v_rd_addr` /
  `v_rd_data` / `v_rd_armed`, one cycle latency, states
  V_RD_AVAIL/V_RD_RING/V_RD_D0/V_RD_D2/V_RD_D3/V_RD_H0/
  V_RD_H2/V_RD_H3). Each such state waits one cycle, then
  consumes the latched word.
- Result: `iverilog` on core + soc2 + tb_soc2 exits 0 in
  0.062 s at the 1 MiB default (was >164 s).
- The testbench clear loop and main image load scale with
  `dut.MEM_WORDS`, so a `-P MEM_BYTES` override for a
  kernel-size RAM clears/loads the whole array (startup
  ~35 s at 32 MiB, measured by construction: 8M-word loop).

## SBI (`os_programs/sbi_firmware.s`, M-mode)

Entry at RAM base (via ROM jump). Sets mscratch =
0x8000E000 (handler stack), mtvec = handler, medeleg =
0xB9FF, mideleg = 0x888, then drops to S-mode (mstatus
MPP=S, mepc = test/kernel, a0 = hartid 0, a1 = DTB
address 0x80020000). S-ecalls land in M because medeleg
bit 9 (S-ecall) is 0 — the SBI design relies on this.

Implemented extensions (unknown extension/FID returns
SBI_ERR_INVALID_PARAM, -2):

- Base 0x10: FID 0 spec version 2.0 (a1 = 0x02000000),
  FID 1 implementation ID "BIG3" (a1 = 0x42494733),
  FID 2 implementation version 1, FID 3 probe (1 for
  0x10, 0x54494D45, 0x735049, 0x52464E43, 0x53525354,
  else 0), FIDs 4/5/6 return 0.
- Legacy 0x01: console putchar (byte in a0 to legacy UART).
- TIME 0x54494D45: FID 0 set_timer (a0 = mtimecmp low,
  a1 = high).
- sPI 0x735049: FID 0 send_ipi — a REAL single-hart IPI
  (not a no-op): if hart_mask_base (a1) is -1 (all harts)
  or base is 0 with mask bit 0 set (a0 & 1), it writes 1
  to the IPI register at 0x10002000, which asserts the
  core's `irq_soft` line. The S handler clears it by
  writing 0 to the same register (via its VA mapping).
- RFNC 0x52464E43: FID 0 fence_i (no-op success),
  FIDs 1/2 sfence_vma (executes `sfence.vma` in M, which
  flushes the TLB), FIDs 3-6 hfence variants (no-op
  success).
- SRST 0x53525354: FID 0 system_reset — restores the
  stack, clears mtvec, ecalls in M with mtvec == 0, so
  the core halts. A defensive `j halt_loop` follows.

Handler: swaps sp with mscratch, saves ra/a0-a7/t0-t6 on a
128-byte frame, dispatches, restores a2-a7/t0-t6 (NOT
a0/a1, which carry returns), mepc += 4, restores sp, mret.
Machine timer interrupt (0x80000007) sets mtimecmp far
future and mret without advancing mepc. Other traps print
'!' to the legacy UART and halt (the '!' is the firmware
trap flag the checkers assert is absent on success).

Firmware size: 252 words (limit 1024 words in the
build_smode layout — see "builders" below).

## Device tree (`os_programs/big32.dts`)

Built with `dtc -I dts -O dtb`. Root: compatible
"big32,phase5", model "big32 Phase 5", #address-cells 1,
#size-cells 1. Chosen: bootargs "earlycon", stdout-path
"/soc/uart@10010000". Memory: reg <0x80000000 0x00100000>
(1 MiB, matching the soc2 default — a kernel attempt
overrides RAM but the DTB memory size must then be
updated to match, or the kernel will size memory wrong).
CPU: cpu@0, compatible riscv, riscv,isa "rv32ima"
(no C: big32 has no compressed extension; no F: no FPU),
mmu-type "riscv,sv32", timebase-frequency 10000000
(10 MHz, QEMU's usual value; the kernel divides rdtime
ticks by it — see "counters" below).
SOC (simple-bus): uart@10010000 (ns16550a, interrupts <1>,
interrupt-parent PLIC, clock-frequency 1843200), plic
(riscv,plic0, #interrupt-cells 1, reg <0x0c000000
0x04000000>, riscv,ndev 3), clint@2000000 (riscv,clint0,
reg <0x02000000 0x00010000>, interrupts-extended <&cpu0 7
&cpu0 3>), virtio@10001000 (virtio,mmio, interrupts <2>,
interrupt-parent PLIC).

`tools/check_dtb.py` walks the DTB (magic, totalsize ==
file length, version >= 17, required nodes + memory reg +
uart/virtio compatibles). It proves a structurally valid
tree a kernel's libfdt can walk; it is NOT a substitute
for booting a kernel against it.

## PLIC (soc2)

Sources: 1 = UART16550, 2 = virtio block, 3 = external
line. Standard register layout, verified against the
PLIC spec section the kernel's sifive-plic driver uses:
priorities at 0x0C000000 + 4*source (3-bit priority
fields), pending at 0x0C001000, enables M at 0x0C002000
and S at 0x0C002080 (0x80 stride), M threshold
0x0C200000 / claim 0x0C200004, S threshold 0x0C201000 /
claim 0x0C201004. Claim resolution is combinational per
context: highest priority above threshold wins; ties go
to the LOWEST-numbered source (fixed in Phase 5 from an
earlier highest-id-wins loop). Pending is LEVEL: a source
stays pending while its device asserts it, so a handler
must drain/ack the device before completing, or the
interrupt retakes — correct PLIC behaviour for level
sources, not a bug. The core sees one `irq_ext` line,
asserted when EITHER context has a claimable interrupt;
the core's own M/S delegation (mideleg/sie/mie) then
decides which mode takes it. Claim marking is guarded by
`mem_load_w` (real MEM loads only), so speculative
fetch reads cannot claim. Complete writes clear
`plic_claimed[id]`.

Kernel note: if the kernel never programs priorities
(it leaves them 0), no PLIC interrupt is ever claimed
(priority 0 = never interrupt). Console OUTPUT still
works (the 8250 driver polls THRE for output); only
interrupt-driven INPUT would be missing. Not a boot
blocker for a boot-log attempt.

## 16550 UART (soc2, 0x10010000)

RBR/THR +0, IER +1, IIR/FCR +2, LCR +3, MCR +4, LSR +5,
MSR +6, SCR +7, DLL/DLM when LCR.DLAB = 1. SCR, DLL, DLM
are stored and read back (the 8250 autoconfig probes
them). IIR = 0xC4 for RDA (FIFO bits 11, ID 010),
0xC2 for THRE, 0xC1 for none. LSR = TEMT 1, THRE 1,
DR = RX FIFO non-empty (bit 0; an earlier draft had DR
at bit 1 and was fixed). FIFO is always on (documented
deviation: FCR bit 0 is stored but the FIFO does not
switch off). RX is a 16-byte FIFO fed by rx2 inputs;
16550 irq = (DR && IER[0]) || (THRE && IER[1]). THRE is
always 1 in simulation, so a driver enabling THRE
interrupts without handling them will spam — correct
16550 behaviour. MSR reads 0 (no modem lines). TX pulses
the top-level uart_tx on THR writes. Divisor values do
not affect TX timing in simulation (bytes go out
immediately).

## 64-bit timer (soc2 CLINT)

mtime/mtimecmp are 64-bit (low +0, high +4 at both
0x02004000 and 0x0200BFF8). mtime +1/cycle; the timer
pends while mtime >= mtimecmp (64-bit compare), so a
compare set across the 32-bit boundary fires when the
high word rolls over. The old SOC's 32-bit-only CLINT
(high words read 0, writes dropped) is gone on soc2.

## Counters (core): TIME/CYCLE/INSTRET

The kernel's riscv clocksource reads the TIME CSR
(rdtime). The core implements: CYCLE 0xC00 / CYCLEH
0xC80, TIME 0xC01 / TIMEH 0xC81, INSTRET 0xC02 /
INSTRETH 0xC82, all from one free-running 64-bit
`core_cycles` counter (+1/clock). INSTRET aliases the
cycle counter (simplification: no kernel boot path reads
instret, only perf tools do). Counters are readable in
all modes; mcounteren is not implemented (writes to it
are ignored, counter reads are never blocked) — a
documented permissive deviation. Before this fix, rdtime
returned a stuck 0, which would have wedged the kernel's
timekeeping.

## Virtio-mmio block (soc2, 0x10001000)

Chosen over a custom ramdisk-style MMIO device because
virtio-mmio block IS in mainline Linux (CONFIG_VIRTIO_MMIO
+ CONFIG_VIRTIO_BLK), whereas a custom device would need
a custom kernel driver. The ramdisk fallback was
considered and rejected for the Linux path.

Only queue 0, only block device, QueueNumMax 64. Driver
sequence: reset (Status = 0), ACKNOWLEDGE, DRIVER, read
features (0), FEATURES_OK, set queue addresses,
QUEUE_READY, DRIVER_OK, then QueueNotify. On notify the
FSM walks the descriptor chain from guest RAM, copies
data between RAM and the internal disk array (DISK_BYTES
default 1 MiB = 2048 sectors of 512 bytes), writes the
used ring, sets InterruptStatus bit 0, and asserts PLIC
source 2 until the driver acks. Disk initialises with a
checkable pattern (sector s, byte = s % 256) unless the
testbench overwrites it; sector 0's first 8 bytes are
magic EF BE AD DE 78 56 34 12 (words 0xDEADBEEF,
0x12345678 little-endian). Guest physical addresses in
descriptors are translated by subtracting RAM_BASE;
addresses outside RAM abort the request (used entry with
len 0, status byte 1). Descriptor word 1 (addr hi) and
header word 1 (reserved) are skipped (32-bit guest
addresses only).

## Bootloader (`os_programs/bootloader.s`)

M-mode program (356 words) that embeds the SBI handler
(copied verbatim from sbi_firmware.s — if the firmware
changes, this copy must be re-synced) and replaces the
firmware entry with: SBI setup (mscratch/mtvec/medeleg/
mideleg) + virtio identify/init + read sectors 0-1
(1024 bytes) into RAM at 0x80010000 + drop to the loaded
image in S-mode (mepc = 0x80010000, mstatus MPP = S,
a0 = 0, a1 = DTB 0x80020000). Queue buffers: desc
0x80002000, avail 0x80003000, used 0x80004000, header
0x80005000, status 0x80006000 (no overlap with the
firmware stack at 0x8000E000, the kernel at 0x80010000,
or the DTB at 0x80020000). Each read checks status byte
== 0 and used idx == sector+1; any failure (bad magic /
version / id, nonzero features, notify timeout, nonzero
status, wrong used idx, uncleared InterruptStatus)
prints '!' to the legacy UART and halts — the checker
treats '!' as a boot failure. The test kernel
(`soc2_programs/boot_kernel.s`, 55 words, loaded as the
disk image) checks the DTB magic, prints 'B' + 'K' via
SBI putchar, checks the SBI spec version, and shuts down
via SRST. `tools/boot_check.py` assembles both, builds
the DTB, and runs the testbench with the kernel as
+DISKHEX.

## Core semantic changes vs Phases 1-4

Every one of these changes behaviour that Phases 1-4 code
could observe. They are deliberate, tested, and required
for Linux; the old tests that encoded the old behaviour
were updated, not the core reverted.

1. **TLB (16 entries, fully associative, round-robin
   replacement).** Each entry: valid, VPN[19:0],
   PPN[19:0], R/W/X/U flags, D flag, superpage flag.
   ASID ignored (entries effectively global). Fetch
   lookup is pc-based; data lookup uses the raw virtual
   effective address. Permission mirrors the walker
   (load needs R, store/AMO needs W; W-without-R pages
   never reach the TLB — the walker faults them; S from
   a U page faults unless SUM; U from an S page faults).
   TLB-hit + permission fault: fetch faults into IF/ID,
   data faults cause 13 (load) / 15 (store/AMO) with tval
   = VA. Flushed by any sfence.vma in M/S and any satp
   write in WB (flush beats insert on the same edge).
   The old one-entry fetch cache (`fetch_pa`) still
   exists and is also cleared on sfence in M/S.
2. **A/D writeback (walker state 4).** When a leaf is
   accepted but A (PTE bit 6) is 0, or (store/AMO and D
   (bit 7) is 0), the walker stores the accept regs and
   goes to state 4, where the data port writes the
   updated PTE (PTE | 0x40 | (store ? 0x80 : 0)) and then
   completes the translation. TLB insert happens on
   immediate accept (only when A set and (not store or
   D set)) or on state-4 completion.
3. **D-miss re-walk (found by the ad test).** A load
   caches a TLB entry with D = 0; a later store hitting
   that entry must NOT silently store without setting D
   (the privileged spec requires D to be set or a fault).
   So TLB entries record D, and a store/AMO hitting an
   entry with W ok but D = 0 is a D-miss, not a fault:
   it re-walks (state 4 sets D) instead of faulting.
   Inserts invalidate older overlapping entries, so a
   fresh D = 1 entry can never be shadowed by the stale
   D = 0 entry it replaces (round-robin order would
   otherwise allow that).
4. **Misaligned traps.** Load half needs addr[0] == 0;
   load word / store word / AMO need addr[1:0] == 0;
   byte accesses never misaligned. Causes: load 4,
   store/AMO 6, except misaligned LR = 4 (LR detected
   via AMO funct5 00010). Misaligned outranks page
   fault (privileged-spec trap priority). The Phase 1-4
   behaviour (a misaligned access crossing a page
   boundary silently continued into the next physical
   page) is GONE. The old `mmu_cross` test encoded the
   old behaviour (expecting 0x44332211); it now expects
   the trap (cause 4, tval 0x40000FFE, a0 = 4).
   No walk starts for a misaligned access.
5. **Software interrupt.** New core input `irq_soft`;
   mip bit 3 = irq_soft. Priority: external > software >
   timer (privileged-spec order MEI > MSI > MTI, same
   for supervisor remaps). Codes: M software 3, S
   software 1. Old tops tie it to 0; soc2 drives it
   from the SBI IPI register.
6. **EX/MEM halt bubble (found by the misaligned
   work).** EX/MEM now also bubbles on `ex_halt`.
   Without this, a misaligned load (or an illegal CSR
   instruction) with mtvec == 0 would still commit its
   wrapped load / CSR write in WB after halting.
7. **SUM stall (found by the old OS boot).** A write to
   sstatus (0x100) or mstatus (0x300) pending in EX/MEM/
   WB stalls ID (bubbles ID/EX), mirroring satp_pending.
   Reason: a translated load/store/AMO checks
   sstatus.SUM combinationally on a TLB hit in EX, and
   CSR forwarding does not cover that check. Without
   this stall, a load two instructions after
   `csrs sstatus, SUM` reads the pre-csrs SUM value and
   faults on a U page (the old kernel's print path hit
   exactly this: cause 13 on the user string, cascading
   to cause 15 on the handler stack). The stall must
   include WB: the memory op reaches EX the cycle after
   the write leaves MEM, while the write is still in
   WB, and the check would still read stale. Writes to
   sstatus/mstatus are rare (kernel only), so the cost
   is negligible.
8. **WFI / fence as NOPs (no change, documented).**
   WFI executes as a NOP (it does not wait — the idle
   loop spins instead of sleeping; safe for boot, no
   power saving). fence / fence.i are NOPs (no caches,
   so fences are correctly no-ops).
9. **mem_load_o (new core output).** = ex_mem_is_load
   (MEM-stage load flag), for SOC tops whose register
   reads have side effects (16550 RBR pop, PLIC claim).
   Old tops leave it unconnected (legal for an output).

## Builders (the 0x1000 slot bug)

`tools/build_sbi.py` and `tools/build_smode.py` lay out
firmware + test with the test at byte offset 0x1000
(image word 1024). An earlier version padded to word 256
(0x400) while the firmware jumped to 0x80001000, so the
core fetched zeros there, took an illegal-instruction
trap with stvec still 0, and looped through ROM. Fixed
by padding to word 1024. The same class of bug bit the
PLIC/timer tests differently: they ended with `ecall`
while mtvec still pointed at the handler, so the ecall
trapped to the handler and mret returned to the same
ecall forever — fixed by clearing mtvec before the
final ecall in `soc2_programs/plic.s` and
`soc2_programs/timer64.s`. And the SBI test's timer
handler originally never masked the level timer
interrupt, so it retook forever (s1 = 5291 at 50K
cycles) — fixed by clearing STIE in sie on the first
tick.

## Test results (Phase 5, all green at push time)

- soc2 platform: plic PASS (32089 cycles, a0 = 0),
  uart16550 PASS (1220), timer64 PASS (20074),
  virtio PASS (2115).
- Core gaps: tlb PASS (242), ad PASS (193), misalign
  PASS (492), ipi PASS (258). (Cycle counts vary by a
  few cycles run to run with the SUM stall; a0/s0 = 0
  is the pass criterion.)
- SBI + DTB: sbi PASS (32623 cycles, s0 = 0, UART 'S',
  no '!'), dtb PASS (1294 bytes, version 17, 10 nodes,
  all required nodes present).
- Bootloader: boot PASS (1573 cycles, s0 = 0, UART 'BK').
- Regressions: `./run_os.sh` 78/78 PASS (os_boot PASS
  at 10174 cycles — was 28037 at Phase 4; the TLB
  caches translations so fewer walks run — plus SOC
  11/11, pipe 16/16, random 50/50). v7 (`./run.sh`)
  green, including call_demo sp restored to 65532.
- Full suite: `./run_soc2.sh` (soc2 + coregaps + sbi +
  dtb + boot + run_os.sh).
- Debug aids (kept in the repo, not part of the suite):
  `sim/tb_dbg.v` (soc2 pc/instruction + walker + ADDBG
  traces) and `sim/tb_soc_dbg.v` (old-SOC pc/priv trace
  + S-handler trap-register trace). These are how the
  SBI pad bug, the ad D-miss, and the OS-boot SUM stall
  were found; they print to stdout and are only useful
  with small +MAXCYCLES budgets.
- Icarus speed (measured): TB startup ~1.2 s per run at
  1 MiB; per-cycle ~0.11-0.17 ms. Do NOT run multiple
  vvp jobs concurrently on the 2-core VM; wall time
  inflates sharply.

## Building a Linux kernel for big32

Toolchain (free, apt): `gcc-riscv64-linux-gnu` (the
bare-metal `gcc-riscv64-unknown-elf` toolchain CANNOT
build the kernel: its ld rejects `-shared`, which the
riscv vDSO link needs — that failure is what forced the
switch). The kernel source used here: Linux 6.6.52
(LTS) from kernel.org. Config: start from
`rv32_defconfig`, then:

- Disable compressed instructions: CONFIG_RISCV_ISA_C
  must be off (big32 has no C extension). It is
  selected by CONFIG_EFI, so disable EFI first, then
  disable RISCV_ISA_C, then olddefconfig — in that
  order, or the select forces it back on.
- Disable the FPU: CONFIG_FPU off (no FPU in the core).
- Disable SMP (single CPU in the DTB), modules, and
  initramfs (the boot attempt has no root filesystem;
  the honest stopping point is the kernel's "no working
  init" panic, which still proves early boot got through
  setup, console, and driver init).
- Keep: CONFIG_SERIAL_8250 + CONFIG_SERIAL_8250_CONSOLE
  + CONFIG_SERIAL_EARLYCON (console via the 16550),
  CONFIG_VIRTIO_MMIO + CONFIG_VIRTIO_BLK (block
  device), CONFIG_SIFIVE_PLIC (PLIC), CONFIG_RISCV_SBI
  (SBI v0.2+ calls), CONFIG_RISCV_TIMER (rdtime
  clocksource — needs the TIME CSR above).

Build (from the kernel tree):

  make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- -j2 Image

Verify the result before any boot attempt:

- `file vmlinux` / `readelf -h vmlinux` must show
  ELF32, RISC-V.
- No compressed instructions: disassemble vmlinux and
  check no 16-bit encodings appear (any 4-hex-digit
  instruction word in objdump output would be a C
  instruction the core cannot execute).
- Note the Image size: it must fit in the RAM you give
  the simulation (32 MiB here) alongside the firmware,
  the DTB, and the kernel's own runtime allocations.

Boot attempt harness (test-only shortcut, documented):
the real path would use the bootloader (virtio -> RAM
-> S-mode). For the attempt, the testbench loads the
kernel Image directly (+KIMGBIN, the binary Image
itself, at +KIMGOFF=2097152 = 0x200000, the 2 MiB-aligned
load address the riscv kernel requires for its early
megapage mapping) and a firmware variant
(`tools/build_kboot.py`: the SBI firmware with ONLY
the drop target changed, mepc 0x80001000 -> 0x80200000)
drops to it in S-mode with a0 = 0, a1 = DTB. The DTB
is loaded at 0x80020000 (+DTBFILE/+DTBOFF) and is the
boot variant (`tools/build_kboot_dtb.py`: 64 MiB memory,
100 kHz timebase — see below). Compile with
`iverilog -Ptb_soc2.TB_MEM_BYTES=67108864` (64 MiB)
and run with a cycle budget; capture the UART
transcript and the final state.

Three harness lessons, all found by running, in the
order they bit:

1. **Icarus -P only overrides TOP-module parameters.**
   `-Pbig32_soc2.MEM_BYTES=...` and
   `-Ptb_soc2.dut.MEM_BYTES=...` are silently ignored
   (verified: a probe printed MEM_BYTES=1048576 after
   both). The size therefore lives on the testbench
   itself (`TB_MEM_BYTES`, default 1048576, passed down
   to dut), and the kernel attempt compiles with
   `-Ptb_soc2.TB_MEM_BYTES=67108864`. The 1 MiB default
   is unchanged, so all Phase 5 tests are unaffected.
2. **The firmware image load loop must be bounded by
   the img array, not by MEM_WORDS.** The old break
   (`i = 262144`) only exited the loop when MEM_WORDS
   was 262144 (the 1 MiB default). At 64 MiB it skipped
   to 262144 and then ran all 16.7M iterations, each
   hierarchical write re-evaluating the core/SOC
   combinational logic that reads memw — that was the
   15+ min "hang" in every 64 MiB run. Fixed by bounding
   the loop at 262144 (the img array size). The same
   class of bug does not affect the disk loop (already
   bounded by 262144) or the clear loop (skipped by
   +NOCLEAR on big-RAM runs).
3. **Do not load a multi-megabyte kernel with
   $readmemh.** Icarus's hex parser takes ~300 us per
   line: a 9.7M-line (87 MB) text hex needs 35-65 min
   before cycle 0. The kernel attempt instead uses
   $fread of the binary Image into a word array plus a
   byte-swap loop ($fread packs bytes big-endian into
   words; the RISC-V Image is little-endian), via
   +KIMGBIN. Measured pieces: 1M hierarchical writes
   in 0.75 s, 16M-word async reads in 0.38 s for 2000
   cycles — the file parsers, not the memory, are the
   bottleneck. +NOCLEAR skips the 16M-word RAM clear
   (same re-evaluation cost as the firmware loop bug)
   on big-RAM runs; the firmware, DTB, and kernel
   regions are written explicitly, and the kernel
   zeroes its own BSS before use.

Boot DTB choices (simulation, documented, not hardware
claims): memory 64 MiB (the trimmed Image alone is
34.4 MB; the 1 MiB default cannot hold it) and
timebase-frequency 100 kHz instead of 10 MHz (mtime
ticks 1/cycle, so a kernel second costs
timebase-frequency cycles: 100 kHz makes kernel time
run 100x faster relative to cycles, so second-scale
timeouts expire in 100K cycles instead of 10M; the
SBI timer and rdtime both use the same mtime, so
timekeeping stays self-consistent).

Kernel execution proof (debug run, 20000 cycles,
`sim/tb_kboot_dbg.v` trace, trimmed Image):
pc=80200000 instr=0d40006f (`j _start_kernel`) in
S-mode (priv=1), then sie/sip clears, then a memory
zeroing loop (sw zero, pointer +4, bound check) at
0x80200104-0x80200114, ~3990 iterations in the window,
a1=0x80020000 (DTB) preserved, no traps, no UART yet
(earlycon prints come after the assembly setup, MMU
on, and start_kernel — all after the zeroing loop).
The kernel is booting normally, just slowly: the
zeroing loop alone needs on the order of 1-2M cycles
for a multi-megabyte region, which is why the bounded
attempt below uses 5M cycles.

## Linux status (honest)

**Linux 6.6.52 boots and prints on big32 in simulation
(SBI probed, DTB parsed, earlycon enabled, memory/SLUB/
IRQ init reached), but does NOT reach a prompt or
userspace yet — no root filesystem is provided, and a
full boot needs far more cycles than Icarus delivers
in a session.** Attempts below, 26 Oct 2026, in order
(the first attempt used a 2MB-aligned load and died in
setup_vm; the 4MB-aligned attempts are the ones that
print). Debug testbenches used for the kernel runs:
`sim/tb_kboot_dbg.v` (filtered pc/instr trace) and
`sim/tb_kboot_dbg9.v` (trap-entry trigger + CSR footer:
sepc/scause/stval/stvec/satp/sstatus/sie/priv — the
tool that found the setup_vm ebreak).

- Kernel: Linux 6.6.52, rv32, no C / no FPU / no SMP,
  no VGA console (link fix), trimmed of DRM / sound /
  wireless / media / framebuffer (Image 34,402,300
  bytes, down from 38,746,188). vmlinux verified ELF32
  RISC-V; objdump of the whole vmlinux shows NO
  compressed instructions (the 14 four-hex-digit lines
  are the Image header fields and zero padding, not
  instructions; the entry is `j _start_kernel`, which
  jumps over the header).
- Attempt: 5,000,000 cycles, 64 MiB RAM, kboot firmware
  (SBI, mepc 0x80200000), boot DTB (64 MiB, 100 kHz
  timebase), kernel loaded via +KIMGBIN at 0x80200000.
  Result: CYCLES 5000000, HALTED 0, **no UART output**.
- What the 5M-cycle end state proves: the kernel got
  through _start_kernel, the memory zeroing loop, page
  table setup, and MMU enable, and is running C code:
  a2 = 0xC0000000 (PAGE_OFFSET), sp/s0 set
  (0x82201F50/0x82201F70), a0 = DTB (0x80020000)
  preserved, a5 = RAM base (0x80000000). No '!' (no
  M-mode firmware trap), no halt, priv stayed in S
  after the drop.
- What it does NOT prove: no printk reached the UART
  in 5M cycles, so earlycon/console output is
  unconfirmed — either setup_arch had not reached
  earlycon_init yet, or the kernel is spinning silently
  somewhere in setup. A follow-up end-window trace
  (last 100K cycles of a 5M run) was launched to tell
  spinning from progressing; its result goes here when
  it lands. Until kernel output appears, "Linux boots"
  is NOT claimed.
- **Exact blocking point found (dbg8 + dbg9, 26 Oct
  2026): the kernel parks in its temporary trap vector,
  it does NOT idle normally.** The last 100K cycles of
  a 5M run execute only the 2-instruction loop at
  0x802000cc (`wfi; j 0x802000cc`) — the third pc in
  the trace (0x802000d4, _start_kernel's first
  instruction) is a flushed speculative fetch after
  the jump, not a real execution. The trap-entry trace
  (dbg9) gives the cause: first entry at cycle 481118,
  sepc = 0x81204438, scause = 3 (EBREAK), stval = 0,
  stvec = 0x802000cc (the temporary vector),
  satp = 0 (MMU off), priv = 1 (S-mode). The ebreak
  is setup_vm+0x80 (vmlinux 0xC1004438), i.e. the
  second of the two sanity BUG_ONs at the top of
  setup_vm (arch/riscv/mm/init.c):
  `BUG_ON((kernel_map.phys_addr % PMD_SIZE) != 0)`.
  On Sv32 (folded PMD) PMD_SIZE = PGDIR_SIZE = 4 MB
  (PGDIR_SHIFT 22), and our load address 0x80200000
  is only 2MB-aligned (0x80200000 % 0x400000 =
  0x200000), so the BUG fires. The compiler implements
  the modulo check as `slli a5, a5, 10; beqz; ebreak`
  (a5 = the auipc-derived runtime _start). The core's
  auipc/slli/beq were all verified correct by small
  directed tests on the SOC (auipc with the negative
  0xFEFFC immediate included) — this is a platform
  load-address bug, NOT a core bug. **Fix: load the
  kernel at a 4MB-aligned address, 0x80400000
  (+KIMGOFF=4194304, kboot mepc updated; the 34.4 MB
  Image still fits in the 64 MB DTB memory).**
  Attempt 4 (5M cycles, 4MB-aligned load) tests this
  fix; its result goes here when it lands.
- **ATTEMPT 4 RESULT (26 Oct 2026): THE KERNEL BOOTS
  AND PRINTS.** 5,000,000 cycles, 64 MiB RAM, kboot
  firmware (mepc 0x80400000), boot DTB, Image via
  +KIMGBIN at 0x80400000. Full UART output:
  ```
  [    0.000000] Linux version 6.6.52 (root@htch-runtime)
    (riscv64-linux-gnu-gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1)
    13.3.0, GNU ld (GNU Binutils for Ubuntu) 2.42) #3
    Mon Oct 26 17:33:35 UTC 2026
  [    0.000000] OF: fdt: Ignoring memory range
    0x80000000 - 0x80400000
  [    0.000000] Machine model: big32 Phase 5
  [    0.000000] SBI specification v2.0 detected
  [    0.000000] SBI implementation ID=0x42494733 Version=0x1
  [    0.000000] SBI TIME extension detected
  [    0.000000] SBI IPI extension detected
  [    0.000000] SBI RFENCE extension detected
  [    0.000000] SBI SRST extension detected
  [    0.000000] earlycon: ns16550a0 at MMIO 0x10010000
    (options '')
  [    0.000000] printk: bootconsole [ns16550a0] enabled
  ```
  What each line proves: the kernel parsed OUR device
  tree ("Machine model: big32 Phase 5" is our DTS
  model string); it probed OUR SBI (spec v2.0, impl
  ID 0x42494733 = "BIG3", our firmware's ID) and
  detected exactly the extensions we implemented
  (TIME, sPI, RFNC, SRST — and correctly NOT HSM,
  whose probe returns 0); earlycon registered on OUR
  16550 at 0x10010000 and the bootconsole is enabled.
  The run ended at the 5M-cycle budget (HALTED 0),
  still in early start_kernel — MMU on (a2 =
  0xC0000000 PAGE_OFFSET, sp/s0 in kernel VA space),
  no fault, no '!' flag. This is a real Linux kernel
  booting on big32 in simulation, not a stub: the
  4MB-alignment fix was the last blocker to first
  printk. A longer attempt (20M cycles) was run to
  push the log further; userspace is NOT reached
  yet (no root filesystem is provided — the expected
  end state without one is the kernel's "No working
  init found" panic, after driver init, which needs
  far more cycles than one session's budget).
- **ATTEMPT 5 RESULT (26 Oct 2026, PARTIAL — the run
  was killed mid-flight by a runtime/session reaping,
  not by the kernel: log ends mid-line at the PLIC
  warning trace, no CYCLES/HALTED footer; the 65
  lines it did flush are the evidence).** Same inputs
  as attempt 4 but 20M cycles. New output beyond
  attempt 4: Zone ranges (Normal 0x80400000–
  0x83FFFFFF, 60 MB — the DTB's 64 MB minus the 4 MB
  below the kernel load, as expected); "Found CPU
  without hart ID" (x2) + "Unable to find cpu node"
  + "Falling back to deprecated riscv,isa" (the DTS
  cpu node had no reg property — non-fatal fallback);
  "riscv: base ISA extensions" (empty — same cause);
  dentry/inode caches, 15225 total pages, virtual
  memory layout (fixmap/vmemmap/vmalloc/lowmem 60 MB),
  "Memory: 26168K/61440K available (13824K kernel
  code, 8963K rwdata, 4096K rodata, 4152K init, 375K
  bss, 35272K reserved)", SLUB, "NR_IRQS: 64", then
  a NON-FATAL WARNING at drivers/irqchip/
  irq-sifive-plic.c:449 in __plic_init (stack trace
  through plic_init -> of_irq_init -> irqchip_init
  -> init_IRQ -> start_kernel). Line 449 is
  `WARN_ON(!nr_contexts)` where nr_contexts =
  of_irq_count(node): our DTS PLIC node had NO
  interrupts-extended property, so the count is 0
  and PLIC init FAILS (driver unregistered; boot
  continues, but no UART/virtio external IRQs —
  timer IRQs via SBI are unaffected). **Fixes made
  to os_programs/big32.dts after attempt 5 (source
  only; a boot with the fixed DTB is a follow-up,
  NOT claimed here): cpu@0 gains `reg = <0>`
  (hartid), and the PLIC node gains
  `interrupts-extended = <&cpu0 11 &cpu0 9>`
  (M external 11, S external 9, hart 0).** The boot
  DTB builder (tools/build_kboot_dtb.py) copies the
  DTS, so the fixes propagate on rebuild.
- The binding constraint is simulation speed, not a
  missing platform piece found so far: at ~0.15
  ms/cycle, 5M cycles is ~12 min wall plus ~10 min
  image load, and a full boot needs hundreds of
  millions of cycles. No platform fault (trap, halt,
  '!' flag) has been observed in any kernel run.

## What remains before Linux boots

In rough order (to check, not assumed):

1. A kernel Image that actually builds for this machine
   (see above) and passes the no-C / ELF32 checks.
2. A boot attempt that produces kernel output, or an
   exact failure point (last UART output, trap cause,
   pc) — Icarus speed itself is a likely blocker: a
   full boot needs hundreds of millions of cycles, and
   at ~0.15 ms/cycle that is tens of hours in one
   session. A bounded attempt (fixed cycle budget) is
   the honest deliverable for this phase.
3. Platform gaps the kernel may expose, in the order
   they would bite: FPU (absent — CONFIG_FPU must stay
   off; any FP-using driver or userspace breaks),
   PMP (absent), a real TLB model with ASIDs (current
   TLB is global; the kernel uses ASIDs for
   performance but correctness does not require them),
   misaligned emulation (the kernel emulates misaligned
   accesses in S-mode only if CONFIG_RISCV_MISALIGNED
   is set — otherwise they fault to userspace),
   PLIC priority programming (if the kernel leaves
   priorities at 0, no PLIC interrupt is ever claimed),
   the HSM extension (absent — fine for 1 CPU, blocks
   any SMP attempt), SBI STA / debug console extensions
   (absent — the kernel probes and degrades gracefully).
4. A root filesystem (initramfs or virtio-blk root)
   with an init — without it the kernel stops at the
   "no working init" panic, which is a boot to
   userspace handoff, not a usable system.
5. Faster simulation (or an FPGA target) before any
   full-boot claim is practical: Icarus at this speed
   cannot boot Linux end-to-end in a session.
6. The bootloader loading a multi-megabyte kernel
   Image from virtio (currently it loads 2 sectors =
   1024 bytes; a real kernel needs thousands of
   sectors and a sector-count loop) — the test-harness
   +KIMG shortcut above is NOT the production path.
7. RAM/DTB sizing discipline: the DTB memory size must
   match the RAM actually given to the simulation, or
   the kernel will size memory wrong.
8. RISCOF/formal verification, a technology-mapped
   gate count, and any silicon claim — all still open,
   none claimed here.
