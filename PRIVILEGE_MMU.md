# big32 Phases 2 and 3 — interrupts, privilege modes, Sv32 MMU

Phase 2 adds M-mode interrupts (CLINT timer, external line,
UART RX) to the pipelined core. Phase 3 adds privilege modes
(M/S/U), trap delegation, and an Sv32 MMU with a multi-cycle
page-table walker, plus a unified-memory SOC top for OS/firmware
programs. Simulation only (Icarus Verilog). No Linux boot, no
xv6 boot, no RISCOF, no formal verification, no silicon — none
of those is claimed.

## Files

- `src/big32_core_pipe.v` — the pipelined core, extended (Phases
  2 and 3 live here; the v7 files are untouched)
- `src/big32_pipe.v` — pipe top, extended only to tie the new
  interrupt/RX inputs off (Phase 1 behaviour unchanged)
- `src/big32_soc.v` — NEW: OS top: unified RAM + CLINT + UART RX
  FIFO + external interrupt input
- `sim/tb_soc.v` — NEW: SOC testbench (program image, RX file
  injection, external pulse, RAM-word reporting)
- `tools/soc_asm.py` — NEW: assembler wrapper over `tools/asm.py`
  (which is untouched) adding `sret`, `sfence.vma`, `.word`, and
  the CSR names `mip`, `sie`, `sscratch`, `medeleg`, `mideleg`
- `soc_programs/*.s` — NEW: SOC test programs (see Test results)
- `tools/soc_check.py` — NEW: SOC expected-value checks
- `run_soc.sh` — NEW: compile SOC testbench, run SOC checks,
  then run `./run_pipe.sh` as regression

## Phase 2 — interrupts

### CSRs and implemented bits

| CSR | Address | Implemented bits | Other bits |
|---|---|---|---|
| `mstatus` | 0x300 | MIE (3), MPIE (7), MPP (12:11) | read 0; writes masked |
| `mie` | 0x304 | MEIE (11), MTIE (7), MSIE (3) | read 0; writes masked |
| `mip` | 0x344 | MEIP (11, from `irq_ext`), MTIP (7, from `irq_timer`) | read 0 (incl. MSIP) |
| `mtvec` | 0x305 | full, incl. MODE (1:0) | — |

MSIE is stored but never pending: there is no software
interrupt source. `mip` is computed from the inputs, not stored.

### mtvec modes

- MODE 00 (direct): all traps and interrupts go to `BASE`
  (`mtvec[31:2] << 2`).
- MODE 01 (vectored): exceptions still go to `BASE`;
  interrupts go to `BASE + 4 * code` (code 11 → +44, code 7 →
  +28, and for S delivery code 9 → +36, code 5 → +20).
- MODE 10/11 are reserved and treated as direct.

### Interrupt sources (SOC top, `src/big32_soc.v`)

1. **CLINT timer.** `mtime` is a free-running 32-bit counter,
   **tick = 1 clock cycle** (no prescaler). Timer interrupt
   pends while `mtime >= mtimecmp` (unsigned). `mtimecmp`
   resets to `0xFFFFFFFF` (far future), and `mie`/`mstatus`
   reset to 0, so interrupts are disabled by default and old
   programs are unaffected. Only the low 32 bits of the
   64-bit CLINT registers are implemented (see Limitations).
2. **External line.** Top-level `ext_irq` input, ORed with
   UART RX ready into the core's `irq_ext` line. There is
   **no PLIC**: this is a single level-sensitive external line,
   pending in `mip.MEIP`. A pulse longer than the handler
   legitimately re-interrupts (the line is still asserted when
   the handler returns); the test uses a 5-cycle pulse.
3. **UART RX.** Top-level `rx_data` + `rx_valid` inputs feed a
   **16-byte FIFO** (bytes dropped when full). RX ready is
   ORed into the external line, so UART RX interrupts use
   **machine external code 11** — no new code is invented.
   `0x10000004` returns the head byte zero-extended and pops
   it (one pop per MEM-stage load from that address, signalled
   by the core's `uart_rx_pop` output); when empty it returns
   `-1` (the v7 value, kept so the pipe top is unchanged).
   `0x10000008` bit 0 is RX ready.

### Interrupt take rules

- Only at an instruction boundary, only when no trap or halt
  commits in the same EX cycle, only when the pipeline is not
  mid-division (`div_stall`) and not mid-page-walk (Phase 3):
  a pending interrupt **waits out a whole 32-cycle division**
  and a whole page walk, and is taken when it commits. The EX
  instruction still commits to MEM in the take cycle.
- Saved pc (`mepc`/`sepc`) is the next not-yet-executed
  instruction: the EX redirect target if EX redirects that
  cycle (branch/JALR/mret/sret), else the ID instruction's pc
  if ID holds one (tracked by an `if_id_valid` bit, since a
  flushed slot's pc is 0 and must never be used as mepc),
  else the current fetch address (`pc`).
- Entry (M): `MPIE = MIE`, `MIE = 0`, `MPP = old priv`,
  `mcause = interrupt bit + code`, `mtval = 0`, `pc = mtvec`
  (direct/vectored as above), `priv = M`. Entry (S, Phase 3):
  same pattern with `SPIE/SIE/SPP/sepc/scause/stval/stvec`.
- Priority when several pend: **external over timer**
  (software never pends).
- Enable rule (M delivery): in M-mode, `MIE = 1` and the `mie`
  bit; in S/U-mode, the `mie` bit alone (MIE does not gate
  interrupts taken from a lower mode). See Phase 3 for the
  delegated-to-S rule, which is checked first per source.
- `mret`: `MIE = MPIE`, `MPIE = 1`, `MPP = 0` (U, the
  least-privileged supported mode), `priv = old MPP`,
  `pc = mepc`. `sret` (Phase 3): `SIE = SPIE`, `SPIE = 1`,
  `SPP = 0`, `priv = SPP` (1 → S, 0 → U), `pc = sepc`.
- **Handler contract (found by a real test failure):** a
  handler must save and restore every register it touches.
  Interrupt entry returns to the next not-yet-executed
  instruction, whose operands must still be intact — e.g. a
  polling loop `lw t0, 0(s0); blt t0, s1, loop` interrupted
  between the load and the branch will execute the branch with
  whatever the handler left in `t0` unless the handler
  preserved it. The Phase 2 test handlers push/pop `t0`–`t2`
  for exactly this reason; the first UART RX test failed this
  way (returned to the branch with `t0 = 0x8000` and exited
  early) before the handlers were fixed. The core is correct
  here; the contract is on software.

## Phase 3 — privilege modes

### Modes and transitions

`priv` resets to M (3). S = 1, U = 0. Transitions:

| Event | Result |
|---|---|
| Trap to M | `MPP = priv`, `MPIE = MIE`, `MIE = 0`, `priv = M` |
| Trap to S (delegated) | `SPP = priv` (1 for S, 0 for U), `SPIE = SIE`, `SIE = 0`, `priv = S` |
| `mret` (M only) | `MIE = MPIE`, `MPIE = 1`, `MPP = 0`, `priv = old MPP` |
| `sret` (M or S) | `SIE = SPIE`, `SPIE = 1`, `SPP = 0`, `priv = SPP` |

- `mret` in S/U is an illegal-instruction trap (cause 2).
- `sret` in U is an illegal-instruction trap. `sret` in M is
  allowed and uses `sstatus` (SPP/SPIE), like `sret` in S.
- ECALL cause depends on the **origin** mode: U → 8, S → 9,
  M → 11. EBREAK → 3. Illegal instruction → 2, with
  `mtval`/`stval` = 0 (the faulting instruction word is NOT
  reported; documented choice).
- A trap to M with `mtvec == 0` halts (the Phase 1 rule,
  extended to illegal/page-fault traps with no handler). A
  delegated trap goes to S even if `mtvec == 0`; a delegated
  trap with `stvec == 0` jumps to address 0.

### S CSRs and implemented bits

| CSR | Address | Implemented bits |
|---|---|---|
| `sstatus` | 0x100 | MXR (19, stored but see below), SUM (18), SPP (8), SPIE (5), SIE (1) |
| `sie` | 0x104 | SEIE (9), STIE (5), SSIE (1) |
| `stvec` | 0x105 | full, incl. MODE (direct/vectored, as for `mtvec`) |
| `sscratch` | 0x140 | full |
| `sepc` | 0x141 | full |
| `scause` | 0x142 | full |
| `stval` | 0x143 | full |
| `satp` | 0x180 | full (MODE/ASID/PPN stored; see below) |
| `medeleg` | 0x302 | exception bits 0–9, 11, 12, 13, 15 (mask `0xBBFF`) |
| `mideleg` | 0x303 | machine interrupt bits 11, 7, 3 (mask `0x888`) |

Deviations from the privileged specification, stated plainly
(the OS-boot phase must know these):

- `sstatus` is a **separate register, not a masked view of
  `mstatus`**: the SIE/SPIE/SPP bits in `mstatus` read 0, and
  writing `mstatus` S-bits has no effect on `sstatus` (and
  vice versa). Likewise `sie` is separate from `mie`: the S
  interrupt-enable bits in `mie` are not the same storage as
  `sie`. Tests use `sie` for S interrupts and `mie` for M.
- `sip` (0x144) is unimplemented: reads 0, writes ignored.
  S handlers in the tests branch on `scause`, never on `sip`.
- `MXR` (sstatus bit 19) is stored but **ignored** in
  permission checks: loads still require the R bit even with
  MXR set. An OS that sets MXR and loads from an X-only page
  will fault here.
- `satp` follows the specification, not the shorthand in the
  Phase 3 task text (which overlapped the fields): MODE is
  **bit 31 only** (1 = Sv32, 0 = bare), ASID is bits 30:22,
  PPN is bits 21:0. ASID is stored but ignored (see No TLB).
- M-mode is always bare: **MPRV is not implemented**.

### Delegation

- Exception: if `medeleg[cause]` is set **and** current
  privilege is below M, the trap goes to S (`sepc`/`scause`/
  `stval`, `pc = stvec` BASE, S entry rules). Traps from M
  always stay in M, even if the medeleg bit is set.
- Interrupt, per source: if `mideleg` for that source is set
  **and** the S enable holds (`sie` bit, and current mode is
  U or current mode is S with `SIE = 1`), the interrupt goes
  to S with the remapped code (external 11 → 9, timer 7 → 5).
  Otherwise it goes to M under the Phase 2 enable rule. If a
  delegated S interrupt is not S-enabled (e.g. S-mode with
  `SIE = 0`), it falls through to M if the `mie` bit is set.
- CSR privilege: CSR address bits [9:8] are the minimum
  privilege (00 = U, 01 = S, 10 = hypervisor, 11 = M); a
  hypervisor CSR needs priv ≥ 2, which only M satisfies here.
  Access below the minimum privilege traps as illegal (cause
  2, delegated via `medeleg[2]` if set and priv < M). A write
  attempt to a read-only CSR ([11:10] = 11, e.g. `mhartid`)
  traps as illegal; `csrrs`/`csrrc` with `rs1 = x0` (and
  immediate forms with uimm = 0) are reads and do not trap.
  Reads of unimplemented CSRs return 0; writes to
  unimplemented writable CSRs are ignored. This is a semantic
  change from Phase 1, where `mhartid` writes were silently
  ignored and `mret` worked in any mode; no Phase 1 program
  writes a read-only CSR or executes `mret` outside M, so the
  regression suite is unaffected (and a trapping instruction
  is now bubbled out of EX/MEM, so it can never write rd or
  a CSR in WB).

### sfence.vma

`sfence.vma` (SYSTEM, funct3 = 0, funct7 = 0001001) is a NOP in
M/S and an illegal trap in U. With no TLB there is nothing to
flush, so the NOP is exact, not a shortcut. `satp` writes do
flush: see below.

## Phase 3 — Sv32 MMU

### When translation applies

Translation is enabled when `satp.MODE` (bit 31) = 1 **and**
current privilege is S or U. M-mode is always bare. Every
instruction fetch and every data access (load, store, AMO,
including LR/SC) goes through the walker when enabled.
Peripheral decoding in the SOC uses the **physical** address
after translation, so an OS maps UART/CLINT with page tables
that translate a virtual address to those physical addresses.

### Walk algorithm (two levels, 4 KB pages, 10+10+12 split)

- Root table base = `{satp[19:0], 12'b0}` (PPN << 12 truncated
  to 32 bits; the top 2 PPN bits, beyond a 32-bit physical
  address, are dropped).
- Level-1 PTE address = root base + `va[31:22] * 4`.
  - Invalid (`V = 0`) → page fault.
  - Leaf (`V` and any of R/W/X) → **4 MB superpage**:
    physical address = `{pte[29:20], va[21:0]}`. A superpage
    whose PPN[0] field (`pte[19:10]`) is non-zero faults
    (misaligned superpage).
  - Otherwise a pointer: level-0 table base =
    `{pte[29:10], 12'b0}`.
- Level-0 PTE address = table base + `va[21:12] * 4`.
  - Invalid, or a non-leaf at level 0 → page fault.
  - Leaf → 4 KB page: physical address =
    `{pte[29:20], pte[19:10], va[11:0]}`.
- Permission checks per access type (PTE flags V = 0, R = 1,
  W = 2, X = 3, U = 4):
  - `W` without `R` is reserved and faults.
  - Fetch needs X; load needs R; store/AMO needs W.
  - U page (`U = 1`): fetch or data access from S faults
    (for data, S access succeeds if `sstatus.SUM` is set;
    SUM never applies to fetches); access from U succeeds.
  - S page (`U = 0`): access from U always faults (SUM is
    S-mode only); access from S succeeds (subject to R/W/X).
- Fault causes: instruction page fault 12, load page fault
  13, store/AMO page fault 15. `tval` is always the faulting
  virtual address; for a fetch fault, `epc` is also the
  faulting virtual address (the instruction never executed, so
  a handler resumes by writing a new `epc`, not by adding 4 —
  the test does exactly this). For a data fault, `epc` is the
  faulting instruction's pc, and a handler resumes by adding 4
  (skip) or fixing the mapping and retrying.
- **A/D bits are ignored**: they are never required for a
  translation to succeed and are never updated in the PTE.
- **Misaligned accesses crossing a page boundary are NOT
  split**: the whole access uses the first page's translation,
  and bytes continue into the next physical page; no fault is
  raised for the second page. This is tested (`mmu_cross`):
  an unaligned word load straddling a mapped/unmapped page
  boundary returns the contiguous physical bytes.

### Walk timing and pipeline stall (multi-cycle, not single-cycle)

The walker uses the core's existing data-memory read port in
dedicated PTW cycles, and the pipeline is frozen during a walk:

- **Start cycle** (pipeline already frozen by `ptw_start`):
  the walk latches the virtual address and the satp root.
- **DRAIN cycle**: MEM drains to WB (the data port is
  untouched this cycle, so the instruction in MEM completes
  its access normally); EX/MEM takes bubbles.
- **LEVEL1 cycle**: the data port carries the level-1 PTE
  address; `d_rdata_i` is the PTE that cycle.
- **LEVEL0 cycle** (4 KB pages only): same for level 0.
- Then the access proceeds: a fetch uses the cached
  `fetch_pa` for the current pc; a data access uses
  `ptw_data_pa` as its MEM address.

So a translated access costs **4 cycles of walk (3 for a
superpage leaf) plus the access cycle itself**, versus 1 cycle
bare. A data walk starts only from a clean state: interrupts
are gated off during a walk and its start cycle, divisions
block walks, and a walk blocks interrupts. Fetch walks are
also gated off while a `satp` write is pending (see below).

### No TLB

There is **no TLB**: every translated access walks. The only
caching is a one-entry "current fetch" cache (`fetch_pa` for
the current pc), which is not a TLB: it is refilled by a walk
whenever `pc` changes, and it is invalidated by any `satp`
write committing in WB. There is therefore no
`sfence.vma`/`satp`-write TLB flush to get wrong, and no ASID
tagging (ASID is stored and ignored).

### satp writes: flush + stall

A `satp` write is the one CSR write that stalls **every**
following instruction, not just SYSTEM instructions: while a
`satp` write is pending in EX, MEM, or WB, the ID stage is
frozen. The `satp` write in EX additionally flushes IF/ID and
sets `pc` to the next sequential address. Together these
guarantee no post-`satp` instruction is fetched or translated
with the old tables, and no post-`satp` instruction reaches EX
before the write commits in WB. (Other CSR writes keep the
Phase 1 rule: only SYSTEM instructions stall, since only they
read CSRs — and trap targets are evaluated in EX, after any
pending delegation write has committed, by the same
stall-then-WB ordering.)

## SOC top and memory map (`src/big32_soc.v`)

Unified memory (contrast: the pipe top is Harvard, and the SOC
top is **not** a drop-in for the 15 directed Harvard programs
— their code and data share one address space here, so a
Harvard program whose code and data addresses overlap does not
run unchanged on the SOC top; the SOC top is for OS/firmware
programs linked for it):

| Region | Physical addresses |
|---|---|
| RAM | `0x00000000` .. `MEM_BYTES-1` (parameter, default 1 MiB; must be a power of two — the index is `addr & (MEM_BYTES-1)`; instantiate with `MEM_BYTES = 8388608` for 8 MB) |
| UART TX | `0x10000000` (byte store transmits) |
| UART RX data | `0x10000004` (byte / pop, or -1 when empty) |
| UART RX status | `0x10000008` (bit 0 = ready) |
| CLINT `mtimecmp` (low) | `0x02004000` (classic CLINT address, also written `0x2004000`) |
| CLINT `mtime` (low) | `0x0200BFF8` (classic CLINT address, also written `0x200BFF8`) |

Notes: RAM byte addresses wrap modulo `MEM_BYTES` for
non-MMIO addresses (same convention as the pipe top). The
high words of the 64-bit CLINT registers (`+4`) read 0 and
their writes are dropped (not RAM aliases). The testbench
(`sim/tb_soc.v`) is a 1 MB testbench (it clears 1 MB and loads
a ≤ 1 MB image); a larger `MEM_BYTES` needs a matching
testbench change — the SOC module itself does not.

## Semantic changes vs v7 / Phase 1

- `mstatus` writes are now masked to MPP/MPIE/MIE (Phase 1
  stored the full value; no Phase 1 program writes other
  mstatus bits, so results are unchanged — pipe cycle counts
  are identical to Phase 1).
- `mtvec` MODE 01 is now vectored for interrupts (Phase 1
  always used BASE).
- ECALL cause now depends on origin mode (8/9/11; Phase 1
  always 11, since it was M-only).
- Traps can now go to S (delegation); interrupts can now go
  to S (delegation + `sie`).
- `mret` outside M and `sret` in U now trap instead of
  executing; writes to read-only CSRs now trap instead of
  being ignored; CSR accesses below the minimum privilege now
  trap instead of reading 0 / being ignored.
- Translated accesses cost walk cycles (above); bare accesses
  and all Phase 1 programs keep their Phase 1 cycle counts.
- Interrupt entry is an additional EX-boundary redirect with
  the same flush/drain behaviour as traps; it never flushes
  EX mid-division or mid-walk.

## Test results (all actually run with Icarus Verilog)

SOC checks (`./run_soc.sh` runs these, then `./run_pipe.sh`):

| Test | Expected | Actual | Cycles |
|---|---|---|---|
| `int_timer` (timer ×5, handler advances cmp) | a0 = 5, RAM[0x8000] = 5 | same | 4627 |
| `int_uart_rx` (RX 'A','B','C' via testbench injection) | a0 = 198, count = 3 | same | 1850 |
| `int_div` (timer fires during 100 divisions) | a0 = 14285700, count = 1 | same | 3760 |
| `int_ext` (5-cycle `ext_irq` pulse) | a0 = 1, count = 1 | same | 838 |
| `int_vectored` (vectored mtvec, timer → BASE+28) | a0 = 2, count = 2 | same | 1563 |
| `priv_ecall_deleg` (U ECALL, delegated to S, cause 8) | RAM[0x8000] = 42, S entries = 2 | same | 76 |
| `priv_ecall_m` (U ECALL, not delegated, cause 8 to M) | RAM[0x8000] = 42, M entries = 2 | same | 70 |
| `mmu_basic` (S tables, fetch+load/store + UART via VA) | a0 = 12346, UART `OK\n` | same | 299 |
| `mmu_fault` (unmapped load fault 13 + fetch fault 12) | count = 2, stvals 0x60000000 / 0x70000000 | same | 609 |
| `mmu_perm` (S→U w/o SUM faults, with SUM succeeds 77; U→S faults) | RAM[0x8100] = 77, faults = 2, U result = 1 | same | 721 |
| `mmu_cross` (unaligned load across mapped/unmapped pages) | a0 = 0x44332211, no fault | same | 241 |

Regression, same runs: **directed pipe 16/16 PASS** (cycle
counts identical to Phase 1: sum 55, fib 69, kernel 668, …),
**random pipe 50/50 PASS on seeds 0–49** (via `run_pipe.sh`)
**and 50/50 PASS on fresh seeds 50–99** (extra run). SOC
checks: **11/11 PASS**.

Bugs found and fixed during these phases (all in tests or
test programs, none left open in the core):

1. **CLINT address typo (SOC):** the SOC first decoded
   `0x20004000`/`0x2000BFF8` (extra zero) while programs used
   the classic `0x02004000`/`0x0200BFF8`; timer tests never
   fired until the SOC was fixed to the classic addresses.
2. **Handler register clobber (test programs):** see the
   Handler contract above — the first UART RX test exited
   early because its handler clobbered `t0` that the
   interrupted branch read. Fixed by save/restore in all
   handlers, not by changing the core.
3. **Level-sensitive external line (test design):** a 20-cycle
   `ext_irq` pulse outlasted the ~15-cycle handler and
   legitimately counted twice; the test now uses a 5-cycle
   pulse for one clean entry.
4. **PTE flag mix-up (test programs):** `0xB` is V+R+X, not
   V+R+W, so stores to data/UART pages faulted on W until the
   test tables used `0x7` (R/W) and `0x17` (U+R/W).

## Known limitations (what the OS-boot phase may NOT assume)

- No PLIC (single external line), no virtio/block device, no
  FPU, no caches, no branch prediction, no PMP, no debug
  module, no hypervisor extension, no 64-bit CLINT (only low
  32 bits of `mtime`/`mtimecmp`; a 32-bit `mtime` wraps after
  2³² cycles, and an interval set across the wrap boundary
  will not pend until `mtime` reaches the compare value
  again — a 64-bit counter is needed for correct long
  intervals).
- No TLB (every translated access walks; an OS that walks
  page tables on every access will be slow but correct).
- `sstatus` is not a view of `mstatus`, `sie` is not a view
  of `mie`, MXR is ignored, ASID is ignored, MPRV is not
  implemented, `sip` is unimplemented, illegal-instruction
  `tval` is 0 (not the instruction word).
- Misaligned accesses are not split across pages (see above).
- Simulation only: the unified RAM is two combinational read
  ports on one array, which is a simulation convenience, not
  a synthesis-ready memory system. No new Yosys number is
  claimed for the pipelined core (the v7 number in README.md
  is for the single-cycle core alone).
- Interrupts do not nest unless a handler re-enables them
  (entry clears MIE/SIE, as specified); nested-handler
  behaviour is untested beyond the single-level handlers here.
- The SOC testbench is 1 MB (see SOC top notes).

## What the OS-boot phase can rely on

- M/S/U privilege separation with delegation, `mret`/`sret`
  return rules, and origin-dependent ECALL causes, as
  specified above (with the listed deviations).
- Sv32 translation for fetch and data, with the documented
  fault causes/tvals, permission rules (including SUM), and
  walk timing (4 cycles, 3 for a superpage).
- A CLINT timer ticking every cycle, a level-sensitive
  external line, and a 16-byte UART RX FIFO, at the
  documented addresses, on the unified SOC top.
- The Phase 1 pipeline guarantees (forwarding, load-use and
  CSR stalls, divider behaviour, halt drain) are unchanged:
  the regression suite passes with identical cycle counts.
