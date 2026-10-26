# big32 Phase 4 — OS-boot milestone: M firmware + S-mode kernel

Phase 4 is the first thing on this core that deserves the word
"boot": M-mode firmware hands control to an S-mode kernel, the
kernel turns on Sv32 translation, counts timer interrupts, drops
to U-mode, serves syscalls, demand-maps a faulting page, and
shuts down cleanly through the firmware. **No xv6 boots here,
and no Linux boots here** — the xv6/Linux assessment at the end
of this document is a roadmap with named blockers, not a boot
claim. Simulation only (Icarus Verilog). No GitHub push in this
phase (a later phase does docs + push). The v7 files are
untouched; the one core change in this phase is a bug fix to
`src/big32_core_pipe.v` (see "Phase 4 core fix" below), and all
Phase 1/2/3 suites still pass with it.

Run it: `./run_os.sh` (OS boot check, then `./run_soc.sh` as
regression: SOC 11/11, pipe 16/16, random 50/50).

## Files

- `os_programs/firmware.s` — M-mode firmware (see below)
- `os_programs/kernel_s.s` — S-mode test kernel (see below)
- `os_programs/user.s` — U-mode test program (see below)
- `os_programs/os_boot.s` — GENERATED combined image source
  (do not hand-edit; built by `tools/build_os.py`)
- `tools/build_os.py` — image builder (STRING expansion +
  fixed-layout padding + assembly + size checks)
- `tools/os_check.py` — boot transcript checker (exact match)
- `soc_hex/os_boot.hex` — GENERATED image the testbench loads
- `run_os.sh` — OS check + full regression

## Why one image, placed by padding

The SOC testbench (`sim/tb_soc.v`) loads ONE contiguous word
image at physical address 0. There is no linker and no second
load port, so the firmware/kernel/user split is done by
construction: `tools/build_os.py` assembles each fragment,
checks it against its slot, and pads with `.word 0` up to the
next slot. Every cross-fragment address is therefore a literal
constant, not a label — the firmware mrets to `0x1000`, the
kernel srets to `0x3000` — and the builder fails hard if a
fragment overflows its slot, because an overflow would silently
move the next fragment. The fragments also use `STRING "…"`
lines, which the builder expands to NUL-terminated `.word`
data (little-endian, only `\n` and `\\` escapes): the base
assembler has no string directive, so strings are data words.

## Firmware design (`os_programs/firmware.s`, at 0x0000)

Reset state is M-mode, bare (`satp = 0`). The firmware:

1. Sets `sp = 0x10000` (M stack, growing down into the free
   `0xE000..0xFFFF` region; the page tables start at `0x10000`
   and are never pushed onto).
2. Sets `mtvec` to its terminal M handler (below).
3. Sets `medeleg = 0xB9FF`, `mideleg = 0x888` (table below).
4. Writes the CLINT baseline `mtimecmp = 0xFFFFFFFF`
   (also the reset value; written explicitly so the baseline is
   visible in code, not just implied by reset).
5. Prints the banner and delegation lines (physical UART
   `0x10000000`; M-mode is always bare, so no mapping needed).
6. Sets `mepc = 0x1000`, `mstatus = 0x880` (MPP = S, MPIE = 1),
   and `mret`s to the kernel. After the `mret`: `MIE = MPIE`,
   `MPIE = 1`, `MPP = 0`, `priv = S`.

### Delegation table

| Trap / interrupt | Delegated? | Reason |
|---|---|---|
| Exceptions 0–7 (misaligned fetch/load/store, access faults, illegal, EBREAK) | Yes (`medeleg` bits 0–7) | The S kernel is the OS; it must see ordinary faults. Illegal/EBREAK from U land in the kernel's unhandled path, which terminates the user cleanly. |
| U ECALL, cause 8 | Yes (`medeleg[8]`) | This IS the syscall path. |
| S ECALL, cause 9 | **No** | Deliberate: S ECALL is reserved as the kernel→firmware shutdown request. If it were delegated, the kernel's shutdown ECALL would re-enter the S handler instead of reaching the firmware halt path. |
| M ECALL, cause 11 | Bit set, unreachable from below M | Cause is by origin mode; only M code produces 11, and traps from M never delegate. Harmless, listed for completeness. |
| Instruction page fault 12, load page fault 13, store/AMO page fault 15 | Yes (`medeleg` bits 12, 13, 15) | The kernel handles (demand-maps) or terminates on these. |
| Reserved exception bits 10, 14 | No (mask `0xBBFF` minus bit 9 = `0xB9FF`) | Not delegatable causes. |
| Machine external (11 → S code 9) | Yes (`mideleg[11]`) | The OS owns external interrupts. No external source is active in the boot test, but the S handler counts them (`0x900C`) if one ever arrives. |
| Machine timer (7 → S code 5) | Yes (`mideleg[7]`) | The kernel's tick source. |
| Machine software (3) | Bit set, no source | `mideleg = 0x888` = bits 11, 7, 3. There is no software interrupt source on this SOC, so bit 3 never fires. |

`mideleg`/`medeleg` values are printed by the firmware
(`M: deleg medeleg=0xb9ff mideleg=0x888`) so the transcript
itself proves the delegation state.

### M handler (terminal, no return)

The M handler is reached only for non-delegated traps. It
borrows the M stack (`sp = 0x10000`), prints `M: halt` for an
S ECALL (cause 9) or `M: trap` for anything else, then sets
`mtvec = 0` and executes `ecall`: an M ECALL with `mtvec == 0`
halts under the Phase 1 rule. It saves no registers because it
never returns — clobbering is irrelevant on a halt path. In the
successful boot the only M-handler entry is the kernel's
shutdown ECALL.

## Memory map (physical; VA == PA for the low region)

| Physical / VA | Contents | Page-table entry |
|---|---|---|
| `0x0000..0x0FFF` | Firmware code + strings (83 words) | VA `0x0000`, S R+X, PTE `0xB` |
| `0x1000..0x2FFF` | Kernel code + strings (401 words, two pages) | VA `0x1000` S R+X `0x40B`; VA `0x2000` S R+X `0x80B` |
| `0x3000..0x3FFF` | User code + strings (50 words) | VA `0x3000`, U R+X, PTE `0xC1B` |
| `0x4000..0x4FFF` | User stack (top `0x5000`) | VA `0x4000`, U R+W, PTE `0x1017` |
| `0x8000..0x8FFF` | Kernel stack (top `0x9000`) | VA `0x8000`, S R+W, PTE `0x2007` |
| `0x9000..0x9FFF` | Kernel scratch: `0x9000` ticks, `0x9004` timer interval, `0x9008` exit code, `0x900C` ext count | VA `0x9000`, S R+W, PTE `0x2407` |
| `0xE000..0xFFFF` | M stack (top `0x10000`, grows down) | Not mapped (M-mode is bare; never accessed under translation) |
| `0x10000` | Sv32 root table | VA `0x10000`, S R+W, PTE `0x4007`; `satp = 0x80000010` (MODE Sv32, PPN `0x10`) |
| `0x11000` | L0 table, low region | VA `0x11000`, S R+W, `0x4407` |
| `0x12000` | L0 table, UART | VA `0x12000`, S R+W, `0x4807` |
| `0x13000` | L0 table, CLINT | VA `0x13000`, S R+W, `0x4C07` |
| `0x14000` | L0 table, demand region (filled by the fault handler) | VA `0x14000`, S R+W, `0x5007` |
| `0x15000` | Demand-mapped user page (zeroed RAM) | VA `0x60000000` after fault, U R+W, PTE `0x5417` |
| VA `0x40000000` | UART TX (byte stores transmit) | Root L1[256] = `0x4801` → L0 `0x12000` entry 0 = `0x04000007` (PPN `0x10000` → PA `0x10000000`, R+W) |
| VA `0x50004000` | CLINT `mtimecmp` | Root L1[320] = `0x4C01` → L0 `0x13000` entry 4 = `0x801007` (PA `0x02004000`, R+W) |
| VA `0x5000BFF8` | CLINT `mtime` (low 32 bits) | Same L0 table, entry 11 = `0x802C07` (PA `0x0200B000` page, R+W) |
| VA `0x60000000` | Unmapped at boot → fault → demand-mapped | Root L1[384] = 0 at boot; fault handler writes `0x5001` (→ L0 `0x14000`) |

Note the UART PTE is `0x04000007` — seven hex digits. Writing
`0x40000007` (eight digits) is a real Phase 4 bug that was
found by running this boot: it decodes to truncated PA
`0x00000000`, so kernel prints sank silently into RAM[0] with
no fault and no UART output. The entry above is the corrected
value, and the checker transcript proves it.

## Kernel design (`os_programs/kernel_s.s`, at 0x1000)

Entry: bare S-mode at VA `0x1000` (VA == PA until `satp` is
written). The kernel:

1. Sets `sp = 0x9000`, `sscratch = 0x9000`, `stvec` to the S
   handler (direct mode).
2. Builds the tables above with explicit stores (bare
   accesses — no translation yet, so the physical addresses
   are the virtual addresses).
3. Writes `satp = 0x80000010`, then `sfence.vma` (a NOP on
   this core, executed anyway because a real OS must issue it
   after changing tables). From here on every fetch and data
   access is translated; the kernel's own code is identity
   mapped, so execution continues seamlessly, and all later
   prints go through the UART VA `0x40000000`. The three
   lines `S: kernel start` / `S: pagetables ok` /
   `S: translation on` are printed AFTER `satp`, so their
   very existence proves translated fetch + translated UART
   stores both work.
4. Sets `sie = 0x220` (STIE + SEIE) and `sstatus.SIE = 1`,
   then runs the timer wait phase (below).
5. Drops to U-mode (below) and never returns except through
   the shutdown path: the S handler jumps to `k_shutdown` on
   user exit or unhandled traps, and `k_shutdown` itself sits
   directly after the `sret` in the main flow as a fall-through
   safety net.

### S handler contract

Entry swaps `sp` with `sscratch` (`csrrw sp, sscratch, sp`)
and pushes `ra`, `t0`–`t6`, `a0`–`a7` (64 bytes). The swap is
symmetric, so it is correct for both origins: from U, it
installs the kernel stack and stashes the user `sp` in
`sscratch`; from S, it installs the stack top and stashes the
interrupted kernel `sp`. Exit (`s_ret`) restores the registers,
pops, swaps back, and `sret`s. Print helpers use only
t-registers, `a0`, `ra`, and the stack — never s-registers —
because the handler saves no s-registers. (This is the same
contract Phase 2 documented: a handler must preserve every
register the interrupted code may read.)

Dispatch on `scause`:

- Interrupt `0x80000005` (S timer): ticks++, `mtimecmp =
  mtime + interval`, where `interval` is the scratch variable
  at `0x9004` — so the handler is correct in both phases
  (2000 in the wait phase, 50000 in the user phase) without
  the kernel patching handler code. Returns via `s_ret`.
- Interrupt `0x80000009` (S external): ext count++, returns.
  Unknown interrupts: ignored, returns.
- Exception 8 (U ECALL): syscall dispatch (below), then
  `sepc += 4` and return.
- Exception 13 (load page fault): if `stval == 0x60000000`,
  demand-map (below) and return with `sepc` UNCHANGED so the
  faulting load retries; otherwise unhandled.
- Anything else: print `S: unhandled cause=<n>` and jump to
  `k_shutdown` (user terminated, no return). Note the
  shutdown jump does not restore registers or swap `sp` back:
  the shutdown code runs on the handler's stack frame and the
  machine halts immediately after, so there is nothing to
  restore to.

### Timer handling, and why the tick count is exactly 2

The CLINT ticks once per cycle, so a naive "count ticks during
the run" number would be a fragile function of total cycle
count. The kernel instead makes the count structural:

1. Wait phase: interval 2000, `mtimecmp = mtime + 2000`. The
   kernel spins on the tick counter until it reaches 2, then
   IMMEDIATELY writes `mtimecmp = 0xFFFFFFFF` — before any
   printing — so no third tick can land while the tick line
   prints. Two ticks, deterministically, regardless of how
   fast the spin loop runs, because the handler advances the
   compare by the interval on every tick.
2. The kernel prints `S: ticks=2`.
3. User phase: interval 50000, `mtimecmp = mtime + 50000`,
   set immediately before the `sret` to U. The whole rest of
   the run (user program + syscalls + fault handling +
   shutdown) is 28,037 cycles total from reset, so the
   drop-to-shutdown span is necessarily under 28,037 cycles —
   well inside the 50,000-cycle window. No tick can fire in
   the user phase, and the final `S: ticks=2` line proves it.
   (If a future, longer user program ever outlasted the
   window, the checker would fail loudly on the tick line
   rather than silently accepting a different count.)

### Dropping to U-mode

Before `sret`: `sepc = 0x3000` (user entry), `sscratch =
0x9000` (kernel stack top for the handler swap), `sp =
0x5000` (user stack top), `sstatus = 0x22` (SPIE = 1, SIE = 1,
SPP = 0). The `sret` then sets `SIE = SPIE = 1`, `SPIE = 1`,
`SPP = 0`, `priv = U`, `pc = sepc`. Timer interrupts during
U-mode are delegated to S (mode U + `sie` STIE), so a tick in
the user phase would land in the S handler and return to the
user correctly — the window argument above is why none does
in this test.

### Syscall ABI (U ECALL, cause 8, delegated to S)

| a7 | Name | Arguments | Effect |
|---|---|---|---|
| 1 | print-string | `a0` = VA of a NUL-terminated string in user memory | Prints the string via the UART VA. The handler calls the kernel's `k_print_str`, which sets `sstatus.SUM` while reading so S-mode may load from the U page, and clears SUM before returning. |
| 2 | print-int | `a0` = integer | Prints the decimal integer (handles 0 and negatives; `INT_MIN` negation is not special-cased and is not tested). No trailing newline — the caller prints one with syscall 1 if wanted. Implemented with the iterative divider (32 cycles per division), no digit stack: count digits, build the divisor, then print most-significant first. |
| 3 | exit | `a0` = exit code | Saves the code, prints `U: exit=<code>`, jumps to `k_shutdown` (never returns to the user). |

`k_print_int`/`k_print_hex` save `ra` (and any value they
need) on the stack because they `jal` to `k_putc`, which
clobbers `t0` (UART base) — every loop reloads its working
value after a `jal`, it never assumes `t0` survives a call.
`k_print_hex` prints `0x` plus exactly 8 lowercase hex digits.

### Page-fault handling (demand-map, chosen over terminate)

The user program loads from VA `0x60000000`, whose root entry
L1[384] is deliberately zero at boot. The fault is a load page
fault (cause 13, `stval = 0x60000000`), delegated to S. The
handler prints `FAULT: cause=13 addr=0x60000000`, then
demand-maps: root L1[384] = `0x5001` (pointer to the L0 page
at `0x14000`), L0[0] = `0x5417` (PA `0x15000`, U+R+W), then
`sfence.vma`, then prints `FAULT: mapped page` and `sret`s
with `sepc` unchanged. The faulting load retries and reads 0
from the fresh zeroed page (the testbench clears RAM at
reset, and nothing ever wrote `0x15000`). The user then
prints `U: faultval=0` and exits normally. Demand-mapping was
chosen over terminate-on-fault because it exercises the full
OS primitive — allocate a table page, install entries, flush,
retry — while terminate-on-fault remains the path for any
OTHER fault address (via `s_unhandled` → shutdown).

## User program (`os_programs/user.s`, at 0x3000)

Straight-line U-mode code, stack top `0x5000`:

1. Syscall 1: `U: hello from user`
2. Compute 1+…+10 = 55 in a loop; syscall 1 `U: sum=`, syscall
   2 `55`, syscall 1 newline.
3. `lw` from `0x60000000` → fault → demand-mapped → retry
   reads 0; syscall 1 `U: faultval=`, syscall 2 `0`, syscall 1
   newline.
4. Syscall 3, exit code 0 (never returns).

User strings live in the user code page (U+R+X: readable by
the kernel under SUM, executable by the user). All syscall
registers are preserved by the handler's save/restore, so the
sum in `t0` and the fault value in `t2` survive their syscalls
and the fault.

## Boot transcript (verified by `tools/os_check.py`)

Exact UART output of a successful boot (28,037 cycles, stable
across repeated runs — Icarus simulation is deterministic, and
the checker re-verified the identical transcript three times):

```
BIG32 OS BOOT
M: firmware ok
M: deleg medeleg=0xb9ff mideleg=0x888
S: kernel start
S: pagetables ok
S: translation on
S: ticks=2
U: hello from user
U: sum=55
FAULT: cause=13 addr=0x60000000
FAULT: mapped page
U: faultval=0
U: exit=0
S: ticks=2
S: shutdown
M: halt
```

The checker compares this byte-for-byte, plus `halted == 1`
and cycles < 1,000,000, and fails loudly (printing expected
vs actual) on any mismatch. Expected values are hand-computed
from the kernel/user logic (sum 55, fault value 0, tick count
2 by construction as argued above), NOT taken from the Python
model — the model does not implement S/U modes or the MMU, so
it cannot be the oracle for this test.

## Phase 4 core fix (in `src/big32_core_pipe.v`, NOT a v7 file)

The Phase 2/3 interrupt-take logic had a latent bug that no
earlier test could trip, because no earlier test enabled an S
interrupt: the S take terms checked delegation and enable but
never checked whether the source was actually pending,

```
int_ext_s_take = (priv != M) && mideleg[11] && sie[9] && ...
int_tim_s_take = (priv != M) && mideleg[7]  && sie[5] && ...
```

while the M take terms correctly required `irq_ext` /
`irq_timer`. The first Phase 4 run that set `sie` therefore
took a phantom external interrupt at cycle 5069 and looped in
the S handler forever: entry clears SIE, but `sret` restores
SIE = SPIE = 1, so the phantom retakes immediately. The fix
adds the pending inputs to both S terms. It changes nothing
for any Phase 1/2/3 test (all of them deliver interrupts to M,
or use no interrupts at all), and the full regression below
confirms that. `PRIVILEGE_MMU.md`'s delegation paragraph
should be read with this correction: S delivery requires
pending + delegated + S-enabled, exactly as M delivery
requires pending + M-enabled.

## Bugs found in this phase (all fixed, none left open)

1. **UART PTE digit (test program):** `0x40000007` instead of
   `0x04000007` — kernel prints sank into RAM[0], no fault,
   no UART. Fixed; see the memory-map note above.
2. **Phantom S interrupt (core):** missing pending check in
   the S take terms — see "Phase 4 core fix" above.
3. **Checker filter (test tool):** the first passing run
   "failed" only because `os_check.py` counted the
   testbench's `WARNING:` / `$finish called` lines as UART
   output. It now uses the same filter as `soc_check.py`.

## Test results (all actually run with Icarus Verilog 12.0)

- `os_boot` PASS, 28,037 cycles, identical transcript on
  three consecutive runs (`python3 tools/os_check.py`).
- Full regression via `./run_os.sh` (exit 0): SOC 11/11 with
  identical cycle counts to Phase 2/3 (int_timer 4627,
  int_uart_rx 1850, int_div 3760, int_ext 838,
  priv_ecall_deleg 76, priv_ecall_m 70, mmu_basic 299,
  mmu_fault 609, mmu_perm 721, int_vectored 1563,
  mmu_cross 241), directed pipe 16/16 (cycle counts identical
  to Phase 1: sum 55, fib 69, kernel 668, …), random pipe
  50/50 seeds 0–49.
- No v7 file was modified (`src/big32_core.v`, `src/big32.v`,
  `tools/model.py`, `tools/asm.py`, `run.sh`,
  `sim/tb_big32.v` untouched; no existing SOC program touched).

## Deviations an OS developer will trip on (restated)

These are all documented in `PRIVILEGE_MMU.md`; they are
repeated here because Phase 4 code depends on each of them,
and stock RISC-V assumptions about them are wrong on big32:

- **`sie` is NOT a view of `mie`, and `sstatus` is NOT a view
  of `mstatus`.** Separate registers. The kernel enables
  timer interrupts with `sie`, never `mie`; firmware leaves
  `mie = 0`, so nothing can be delivered to M by mistake.
- **No PLIC.** One level-sensitive external line, shared
  with UART RX ready, delivered as machine external code 11
  (S code 9 when delegated). There is no claim/complete
  handshake and no per-source identification beyond the code.
- **32-bit CLINT only.** Only the low 32 bits of `mtime` /
  `mtimecmp` exist; `mtime` wraps after 2³² cycles, and an
  interval set across the wrap will not pend until the
  counter comes around again. The boot's intervals (2000,
  50000) are far from any wrap, but a real OS needs 64-bit
  timer handling (see the Linux roadmap).
- **No TLB.** Every translated access walks (4 cycles, 3 for
  a superpage). The kernel's `sfence.vma` is therefore a NOP
  here, but it is still issued after table changes — on a
  TLB machine the same code would be required, not optional.
- **Misaligned cross-page accesses are NOT split.** The whole
  access uses the first page's translation. The boot never
  makes one, but an OS that copies buffers across page
  boundaries must not assume a fault on the second page.
- **MXR stored but ignored** (loads still need R even with
  MXR set), **ASID stored but ignored**, **`sip` does not
  exist** (reads 0), **illegal-instruction `tval` = 0** (not
  the instruction word), **M-mode always bare** (no MPRV),
  **S data access to U pages needs SUM** (and SUM never
  applies to fetches — the kernel's strings are read with
  SUM set, its code is never fetched from a U page).
- **Fetch cache, not a TLB:** the one-entry current-fetch
  cache is invalidated on `satp` writes, so enabling
  translation mid-stream (as this kernel does) is safe; an OS
  must still not assume any other caching.
- **Interrupts wait out divisions and page walks** and are
  taken only at instruction boundaries; handlers must
  save/restore every register they touch (the handler
  contract above).
- **No FPU, no caches, no PMP, no hypervisor, no debug
  module, no virtio/block device.** Simulation only: the
  unified RAM is two combinational read ports on one array,
  not a synthesis-ready memory system.

## xv6 assessment — why xv6-riscv cannot boot here (verified)

Checked against the xv6-riscv sources and book before writing
this section (not from memory): xv6-riscv is an **RV64**
operating system. Its book states it runs on a 64-bit CPU and
is written in LP64 C (longs and pointers 64-bit, int 32-bit);
its virtual memory is **Sv39** — three-level page tables of
512 64-bit PTEs each — and its kernel is loaded at physical
**KERNBASE `0x80000000`**, with user memory low and the
kernel direct-mapped high. Its `start.c` (the M-mode firmware
in its QEMU setup, loaded with `-bios none`) sets up a stack,
delegates traps, programs the timer, and `mret`s to `main` —
the same shape as this phase's firmware, but in 64-bit code
with 64-bit CSRs and `ld`/`sd` instructions this core cannot
decode. An RV64 xv6 binary cannot run on an RV32 core, period:
register width, instruction encodings for word-vs-doubleword
operations, PTE width, and the Sv39 walk are all different.
**No xv6 boot is claimed in this phase, and none was
attempted by relabelling the test kernel.**

Device-by-device, what xv6-riscv expects (QEMU `virt`
machine, `qemu-system-riscv64`, 128 MB RAM) versus big32:

| xv6 requirement | big32 status |
|---|---|
| RV64 CPU, `ld`/`sd`, 64-bit CSRs | **Absent, architectural.** RV32IMAC only. This alone blocks xv6-riscv. |
| Sv39, 3-level, 64-bit PTEs, `satp` MODE Sv39 | **Absent, architectural.** Sv32, 2-level, 32-bit PTEs only. |
| RAM at `0x80000000` (KERNBASE), 128 MB | **Differs.** RAM at `0x00000000`, 1 MiB by default (parameterisable, but the testbench is 1 MiB and the map base differs). |
| 16550 UART at `0x10000000` (`UART0`), byte registers + RX interrupt | **Closest match, still differs.** Address matches, but big32's UART is TX-byte-store + 16-byte RX FIFO with no 16550 register set (no LSR/IER/THR/RHR layout, no baud configuration); xv6's `uart.c` programs those registers and would not drive this UART. |
| PLIC at `0x0C000000` | **Absent.** Single external line, no claim/complete, no per-hart enable/priority registers. xv6's `plic.c` would fault on its first PLIC access. |
| CLINT at `0x02000000` | **Differs.** big32's CLINT is at the classic addresses (`mtime` `0x0200BFF8`, `mtimecmp` `0x02004000`) but only 32-bit; xv6 expects the full 64-bit CLINT register block at the `virt` base. |
| VirtIO disk at `0x10001000` (`VIRTIO0`) | **Absent.** No virtio, no block device, no filesystem image path. xv6 cannot mount its root filesystem without it. |
| OpenSBI-style M firmware (or its own `start.c`) | **Present in shape, not in ABI.** This phase's firmware plays the same role (delegate, timer, `mret` to S), but xv6's `start.c` also programs PMP entries (xv6 runs with PMP protection on QEMU) and expects the QEMU boot protocol; big32 has no PMP. |
| Multi-hart (QEMU `-smp 3` by default) | **Absent.** Single hart, `mhartid` reads 0, no hart coordination. |

No maintained upstream 32-bit xv6-RISC-V port turned up in
search: the original xv6 was 32-bit x86, not RISC-V, and
xv6-riscv is RV64-only. So "a 32-bit xv6 port" is not
something to download — it is a porting project (below).

### What a 32-bit xv6 port would need on top of Phase 4

In dependency order: (1) a 32-bit xv6 tree — either a
community RV32 fork adopted and audited, or a from-scratch
port of xv6-riscv with every `uint64`/`ld`/`sd`/Sv39 construct
converted to 32-bit/Sv32 (page-table code, trapframe,
trampoline, context switch, `riscv.h` CSR accessors); (2) a
memory-map port — KERNBASE and device addresses moved to
big32's map (RAM `0x0`, UART `0x10000000` byte-store, CLINT
classic addresses) or the SOC map moved to match xv6 (RAM at
`0x80000000`, which the SOC parameterisation almost allows
but the testbench and address decoding do not); (3) a 16550
UART register layer or a rewritten console driver for
big32's UART; (4) a PLIC implementation or a rewritten
interrupt path that uses the single external line; (5) a
virtio block device + disk image, or a ramdisk-based root
filesystem replacing xv6's disk filesystem; (6) PMP or
removal of xv6's PMP setup; (7) single-hart operation (drop
the multi-hart boot). Items (1)–(3) are a large port; (5) is a
new hardware device. None of it is Phase 4 work, and none of
it is claimed here.

### What a from-scratch 32-bit OS would need instead

If the goal is "an OS on big32" rather than "xv6 on big32",
the cheaper path is to grow this phase's kernel: a physical
page allocator, per-process page tables and address spaces,
a scheduler with context switch (the trapframe + `sret`
machinery here is the seed), a real console driver with RX
interrupts (the FIFO exists), a timer-driven preemptive tick
(the handler exists), and a filesystem — first a ramdisk,
then virtio. That path reuses everything Phase 4 proved and
adds one subsystem at a time, instead of fighting xv6's
64-bit assumptions throughout.

## Linux roadmap — what a real RV32 Linux boot would need

Also a roadmap, not done work. Note the asymmetry with xv6:
an RV32 Linux is not architecturally impossible the way
RV64-xv6-on-RV32 is — upstream Linux's `arch/riscv` covers
RV32 with Sv32, and RV32IMA Linux (e.g. the biRISC-V core
booting a Linux 5.0 RV32IMA kernel) has been demonstrated on
other 32-bit cores — but big32 is still a long way from it,
in this order:

1. **SBI firmware.** Linux expects to enter in S-mode with a
   Supervisor Binary Interface: an OpenSBI-compatible M
   firmware providing at least the base, timer (STCE/time),
   and RFENCE extensions via S ECALLs, plus a device tree
   pointer in `a1`. This phase's firmware is a fixed
   delegation + `mret`, not an SBI: it answers no SBI calls
   and passes no device tree.
2. **Device tree (DTB).** Linux RISC-V boots from a device
   tree describing CPUs (`rv32ima`, `mmu-type = riscv,sv32`,
   timebase), memory, UART, CLINT, PLIC, and virtio. big32
   has no DTB generation or passing convention.
3. **PLIC.** Linux's RISC-V interrupt handling is built
   around the PLIC for external interrupts (plus the CLINT
   for timer/IPI). The single external line cannot express
   Linux's IRQ domain.
4. **64-bit timer handling.** Linux reads `mtime` as a
   64-bit value (via SBI or the `time` CSR path) and programs
   64-bit compare values. big32's CLINT is 32-bit-only and
   wraps after 2³² cycles; at Linux's tick rates that wrap
   matters within seconds of simulated time at any real
   clock, and the SBI timer path must paper over it.
5. **VirtIO block + network, or a ramdisk path.** A usable
   Linux needs a root filesystem: virtio-blk with a disk
   image (the standard QEMU path) or an initramfs/ramdisk
   baked into the kernel image. big32 has neither device nor
   image format.
6. **A real 16550-compatible UART.** Linux's 8250 driver
   expects the full 16550 register set at a DTB-described
   address; big32's byte-store UART is not that device.
   (A custom DTB UART driver is possible but is not the
   upstream path.)
7. **Megabytes of RAM at a Linux-compatible address.** Linux
   needs tens of megabytes minimum in practice, mapped where
   its DTB says memory is (conventionally `0x80000000` on
   RISC-V platforms). big32's SOC defaults to 1 MiB at
   `0x00000000`; the parameter exists for 8 MB, but the
   testbench, the address map, and the memory system would
   all need to move with it.
8. **A bootloader stage.** On real RISC-V platforms the chain
   is OpenSBI → U-Boot (or direct kernel load) → Linux, with
   the kernel image format, load address, and entry contract
   all specified. big32 loads one raw hex image at 0.
9. **Core completeness for Linux's expectations.** Linux
   assumes: a working `sfence.vma` semantics with a real TLB
   model (big32's no-TLB walk is correct but ~4 cycles per
   access — Linux would be extremely slow, not wrong); A/D
   bits are currently ignored (Linux's page-table code
   manages accessed/dirty bits and can cope, but any
   assumption it makes about hardware updates is unmet);
   misaligned-access behaviour must match what the kernel
   was built to expect (Linux RISC-V generally requires
   hardware misaligned support or traps it emulates — big32
   neither splits nor faults cross-page, it continues into
   the next physical page, which is a third behaviour Linux
   does not expect); FPU state handling is absent (a
   no-FPU kernel config avoids it, but then no userspace
   float); PMP is absent (Linux can boot without PMP on
   some platforms, but the SBI firmware normally uses it).
10. **Performance and memory system.** Even with all of the
    above, a no-cache, no-TLB, single-issue, in-order core
    with combinational dual-port simulation RAM would boot
    Linux at simulation speed only — minutes of wall clock
    per second of guest time in Icarus. An FPGA or a faster
    simulator is a practical prerequisite, not a luxury.

The honest summary: Phase 4 proves the privilege + MMU +
interrupt machinery a kernel needs, with a real (if tiny)
kernel running on it. xv6-riscv is blocked architecturally
(RV64/Sv39); RV32 Linux is blocked by missing platform
(SBI, DTB, PLIC, virtio, 16550 UART, RAM size/address) and
by core gaps (64-bit timer, A/D bits, misaligned semantics,
TLB). The next phase should be a from-scratch OS growing
from this kernel (allocator, scheduler, console RX, ramdisk),
not a Linux or xv6 attempt.
