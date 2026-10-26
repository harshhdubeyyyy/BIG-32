# big32 pipelined core — Phase 1

A 5-stage pipelined RV32IMAC core (`src/big32_core_pipe.v`) with the
**exact v7 instruction semantics**, verified against the Python model
(`tools/model.py`). This is Phase 1 only: no S/U modes, no MMU, no
interrupts, no CLINT/PLIC. Those are later phases and are not
half-built here. Simulation only (Icarus Verilog). Not
production-ready, not RISCOF/formal verified, not Linux-capable.

## Files

- `src/big32_core_pipe.v` — the pipelined core (no memories)
- `src/big32_pipe.v` — simulation top: core + IMEM/DMEM, same
  pattern, parameters, and port list as the v7 top
- `sim/tb_pipe.v` — testbench: loads one program (`+HEX=...`,
  default `programs/pipe_current.hex`), prints `CYCLES:`,
  `HALTED:`, all 32 registers (`REGS:`), scratch words
  (`DMEM:`), and the raw UART transcript
- `programs/pipe_hazards.s` / `.hex` — hazard-heavy directed test
- `tools/pipe_check.py` — directed differential check (model vs
  pipelined Verilog: full registers, UART, scratch memory)
- `tools/rand_pipe_test.py` — hazard-heavy random differential test
- `run_pipe.sh` — one-command re-run of Phase 1
- `pipe_hex/` — assembled copies used by the pipe checks, so the
  existing `programs/*.hex` files are never overwritten

The v7 files (`src/big32_core.v`, `src/big32.v`, `tools/model.py`,
`tools/asm.py`, `run.sh`, `sim/tb_big32.v`, `sim/tb_rand.v`) are
untouched, and v7 still passes its full suite (see below).

## Pipeline stages

| Stage | Work |
|---|---|
| IF | `pc` register drives `if_addr_o`; `instr_i` is combinational from the top's IMEM. |
| ID | Decode only: opcode, rd, rs1, rs2, funct3, funct7, immediates, CSR address, AMO funct5. Register operands are **not** read here. JAL is resolved here (see below). |
| EX | Register read + forwarding, ALU (incl. combinational MUL), branch/JALR resolution, CSR old-value read, multi-cycle divider. Traps, mret, and halts resolve here. |
| MEM | Data access. Loads form `load_data` from `d_rdata_i` (with v7's UART-MMIO overrides). Stores/AMO drive `d_we_o`/`d_wdata_o`/`d_wmask_o`. AMO read-modify-write is atomic here (single core, one MEM cycle). The LR/SC reservation is checked and updated here, in program order. |
| WB | Register writeback and CSR write, at the end of the WB cycle. x0 writes are discarded. |

The memory interface is identical to v7: `d_addr_o` is the
MEM-stage address (load: rs1+imm_i, store: rs1+imm_s, AMO: rs1);
`d_rdata_i` is the combinational word at that address;
`d_wmask_o` is a RELATIVE byte mask (SB=0001, SH=0011, SW/AMO=1111);
stores to UART MMIO addresses never assert `d_we_o`; AMO writes
assert it even at MMIO addresses.

## Forwarding

EX operands (rs1/rs2 — used for the ALU, load/store address,
branch comparison, JALR target, CSR new value, and store/AMO
data) use two forwarding muxes with priority **MEM over WB**
over the register file:

- MEM forward value: for a load, `load_data` (combinational in
  the MEM cycle); for an AMO, the old word (`d_rdata_i`); for
  SC, 0/1 from the reservation check; otherwise the EX result
  carried in EX/MEM (ALU, link, LUI/AUIPC, CSR old value).
- WB forward value: the MEM/WB data register.

Store/AMO data is forwarded in EX and carried to MEM in EX/MEM,
so MEM needs no second forwarding path: by the time a store
reaches MEM, its data is already final (any producer was in
MEM/WB during the store's EX cycle, or an older register value
— the load-use stall below covers the remaining case).

## Stalls (IF/ID frozen, bubble into EX, MEM/WB keep draining)

- **Load-use, 1 cycle.** EX holds a load whose rd (non-x0)
  equals the ID instruction's rs1 or rs2 field. The consumer
  then reads the load via MEM→EX forwarding. The rs-field
  match is deliberately broad (it can fire spuriously for
  LUI/JAL immediates that happen to match): a spurious stall
  is always safe, a missed stall is not.
- **CSR hazard.** The ID instruction is a SYSTEM instruction
  and a CSR write is pending in EX or MEM. A CSR write in WB
  needs **no** stall: it lands at the end of the WB cycle, and
  the held instruction only reads CSRs once it reaches EX in a
  later cycle. Non-CSR instructions are never stalled by CSR
  instructions — they do not read CSRs.
- **Divider** (below). IF/ID/ID-EX freeze and EX/MEM receives
  bubbles while MEM/WB drain.

## Flushes and control resolution

- **JAL: resolved in ID.** The target (`ID pc + imm_j`) is
  taken at the end of the ID cycle; the speculatively fetched
  next instruction in IF is flushed. Cost: 1 flushed fetch.
- **Branches and JALR: resolved in EX** (branch operands use
  the EX forwarding muxes, so a load feeding a branch costs
  only the 1-cycle load-use stall, then forwards). A taken
  branch/JALR flushes IF+ID: 2 flushed instructions.
- **Priority in every control block:** EX redirect (branch /
  JALR / trap / mret / halt) beats stall beats JAL-in-ID beats
  sequential fetch. An EX redirect and a stall cannot demand
  different PCs in the same cycle for the same reason twice:
  a redirecting EX instruction is never a load, and a
  divider stall never coincides with a redirect.

## CSR, trap, mret, and halt commit rules

- CSR instructions flow to WB. The old CSR value is captured
  in EX (after the CSR stall rule guarantees no older CSR
  write is pending) and carried through MEM to WB, where rd
  is written with it and the CSR file is written with the new
  value. A CSR write therefore takes effect for later
  instructions, never for instructions already in flight.
- **Traps (ECALL/EBREAK with mtvec != 0) commit in EX:**
  mepc = trapping pc, mcause = 11 (ECALL) / 3 (EBREAK),
  mtval = 0, pc = mtvec BASE. IF+ID are flushed; the trapping
  instruction never reaches MEM/WB (it writes nothing anyway).
  The trap handler's instructions are fetched only after the
  redirect, so no post-trap instruction can commit early.
- **mret commits in EX:** pc = mepc, IF+ID flushed.
- **Halt (ECALL/EBREAK with mtvec == 0) commits in EX:**
  `halted` rises at the end of the EX cycle. IF/ID/EX then
  freeze on bubbles, but MEM/WB keep advancing so the older
  instructions still in MEM/WB commit (this drain was the
  first pipe bug found: the instruction immediately before
  ECALL lost its writeback when the pipeline froze outright).
  `sim/tb_pipe.v` therefore waits 4 extra cycles after
  `halted` before sampling registers; the reported cycle
  count still stops at the halt, matching `tb_big32`'s
  convention. The next phase's testbench must keep this
  drain wait.
- The CSR stall rule also makes one collision unreachable: a
  trap in EX implies no CSR write pending in MEM, so a trap's
  mepc/mcause/mtval writes can never land in the same cycle
  as a WB CSR write to the same CSR. (The code still orders
  trap writes after WB CSR writes, so a trap would win if it
  ever happened.)

## Multi-cycle divider

DIV/DIVU/REM/REMU use a restoring divider, one bit per cycle,
in EX:

- **Latency: 32 cycles in EX** for a normal division (start
  cycle iterating on bit 31, then 31 iterative cycles on bits
  30..0) — i.e. 31 stall cycles beyond a normal instruction.
  While it runs, IF/ID/ID-EX are frozen and EX/MEM receives
  bubbles; MEM/WB drain normally.
- **Edge cases are single-cycle** (no stall): div-by-zero →
  -1 for DIV/DIVU, dividend for REM/REMU; MIN/-1 → MIN for DIV,
  0 for REM. Identical to v7.
- **Signedness:** signed division iterates on absolute values
  (formed as `~x + 1` on unsigned wires) and re-applies the
  sign at the end (quotient sign = dividend sign XOR divisor
  sign; remainder sign = dividend sign). **Unsigned division
  uses the raw operands** — taking absolute values for DIVU
  was the random-test bug found in this phase (divu
  4294967210/1 gave 86 instead of 4294967210).
- All divider and shift paths use if/else with signed wires,
  never ternaries with mixed signed/unsigned branches (the v4
  Icarus lesson).

## Why MUL stays combinational

MUL/MULH/MULHSU/MULHU stay single-cycle combinational in EX.
The v7 Yosys count (42731 generic cells) was dominated by the
single-cycle divider/modulo unit plus 64-bit multipliers; the
iterative divider removes the divider part of that cost, which
is the big win, while keeping MUL single-cycle avoids adding a
second multi-cycle unit and its stall logic in Phase 1. No new
Yosys synthesis was run for the pipelined core (the task
explicitly forbids claiming one without a fast, logged run),
so no new cell count is claimed here — only the structural
fact that the combinational divider is gone.

## Cycle-count table (directed set)

Cycle counts count clock edges until `halted` is observed, the
same convention as `tb_big32`. Pipe counts are higher by
design: 4 cycles of pipeline fill, taken-branch/JALR flushes,
load-use stalls, CSR stalls, and 32-cycle divisions.

| program | v7 cycles | pipe cycles | a0 (both) |
|---|---|---|---|
| sum | 35 | 55 | 55 |
| fib | 51 | 69 | 55 |
| mul_loop | 27 | 41 | 42 |
| call_demo | 16 | 24 | 112, sp 65532 |
| mul_demo | 7 | 9 | 83810205 |
| mulh_demo | 7 | 9 | 2 |
| div_demo | 9 | 73 | 1402 |
| div_edge | 5 | 7 | 2147483648 |
| div_zero | 5 | 7 | 4294967295 |
| rem_zero | 5 | 7 | 42 |
| amo_demo | 9 | 11 | 42 |
| sc_fail | 7 | 9 | 101 |
| csr_demo | 7 | 13 | 4660 |
| edge_cases | 116 | 300 | 0 |
| kernel | 290 | 668 | 10, UART `big32 OS / E=55 / E=42 / done` |
| pipe_hazards | — | 60 | 1406 (hand-computed) |

Reading the jumps: `div_demo` is 2 normal divisions
(2 × 32 = 64) plus fill/flushes; `div_edge`/`div_zero`/
`rem_zero` use only edge-case (single-cycle) divisions, so
they grow only by fill/flushes; `edge_cases` and `kernel`
contain many divisions/remainders (`print_num` divides per
digit). No increase is hidden: every program's pipe count is
above.

## Test results (all actually run with Icarus)

- **Directed, 16/16 PASS** (`python3 tools/pipe_check.py`):
  all 15 v7 programs plus `pipe_hazards`, each compared
  against the Python model on the **full 32-register file**,
  the UART transcript, and the scratch words at
  0x100..0x10c. `pipe_hazards` covers back-to-back dependent
  ALU ops, a load-use chain, a load feeding a taken branch,
  a not-taken branch, jal/jalr chains (incl. `la` + `jalr`),
  an AMO/LR/SC sequence, back-to-back CSR write-then-read,
  and a store whose data depends on a preceding load; its
  expected a0 = 1406 was hand-computed
  (10+40+33+25+32+1234+32+0) and matches the model.
- **Random, 100/100 PASS** (`python3 tools/rand_pipe_test.py`):
  50 seeds 0–49 and a second batch of 50 seeds 50–99, each
  compared on the full register file and scratch words.
  Generator stresses forwarding chains, load-use (incl.
  load→branch and load→store-data), forward branches,
  jal/ret calls, div/rem (incl. by zero), AMO/LR/SC, and
  CSR write/read pairs.
- **v7 still green:** `sim/tb_big32.v` re-run after this
  work: all 15 programs pass with their original cycle
  counts. No v7 file was modified.

## Bugs found and fixed in this phase

1. **Halt drain (directed):** freezing the whole pipeline on
   `halted` dropped the writeback of the instruction
   immediately before ECALL (e.g. `sum` gave a0 = 0, `sc_fail`
   gave 100 instead of 101). Fix: after halt, freeze only
   IF/ID/EX (bubbles) and let MEM/WB drain; the testbench
   waits 4 cycles before sampling.
2. **Unsigned divider (random, 8/50 initially):** the divider
   took absolute values for DIVU/REMU too, corrupting any
   unsigned division whose dividend had the high bit set.
   Fix: raw operands for unsigned, absolute values only for
   signed. After the fix: 50/50, then 50/50 on fresh seeds.

## Semantic differences vs v7

None, except cycle counts. Final registers, memory, UART
output, and halt behaviour match the Python model (and hence
v7 semantics) on every test above. In particular: x0 stays 0
(including through forwarding paths), unknown opcodes are
NOPs, unimplemented CSRs read 0 and ignore writes, mhartid
is read-only 0, UART MMIO behaviour is unchanged, and
AMO/LR/SC reservation semantics are unchanged (only the
stage that applies them moved, from single-cycle to MEM).

## Known limitations (Phase 1 scope)

- M-mode only; no S/U modes, no MMU, no interrupts, no
  CLINT/PLIC, no UART RX (loads from 0x10000004 still
  return -1), no caches, no branch prediction (every taken
  branch/JALR pays the full flush).
- MUL is still combinational; the divider is iterative but
  the core has no multi-cycle MUL option yet.
- No Yosys synthesis number for the pipelined core (not run;
  see above). No RISCOF, no formal verification.
- IMEM/DMEM sizes and the Harvard layout are unchanged
  (16KB IMEM, 64KB DMEM, byte addresses modulo depth).
- Simulation only, via Icarus Verilog.

## What the next phase (interrupts) can assume

- The core is a clean 5-stage pipeline with all control
  resolved in EX (branches/JALR/traps/mret/halt) except JAL
  in ID; an interrupt entry point will slot into the same
  EX-redirect + IF/ID-flush mechanism, with the same
  drain-until-WB behaviour for older instructions.
- CSR writes commit in WB and are serialised by the CSR
  stall rule; any new CSR a later phase adds (e.g. mie/
  mip/mstatus fields for interrupts) must join that rule —
  i.e. its write must be visible to a later instruction's EX
  read, which the stall rule already guarantees if the new
  CSR's write flag rides the same EX/MEM/WB path.
- Traps already record mepc/mcause/mtval in EX and redirect
  to mtvec BASE; interrupt entry will reuse that path with
  a different mcause encoding and must preserve the
  mepc/mcause/mtval commit ordering.
- The divider stall freezes IF/ID/ID-EX: an interrupt taken
  while a division is in EX must either wait for the divider
  or be held pending until EX drains — it cannot flush the
  EX stage mid-division without losing divider state.
- The halt-drain contract: after `halted`, MEM/WB drain for
  2 cycles; any testbench that samples registers must wait
  (tb_pipe waits 4 cycles).

## Phases 2 and 3 — interrupts, privilege, MMU (done)

Phase 2 (interrupts) and Phase 3 (privilege modes M/S/U +
Sv32 MMU) are built on this pipeline and documented in full in
[`PRIVILEGE_MMU.md`](PRIVILEGE_MMU.md) — CSR lists and
implemented bits, interrupt sources/priority/entry rules,
privilege transition rules, the Sv32 walk algorithm and stall
behaviour, the no-TLB decision, the SOC memory map, and every
semantic change vs v7/Phase 1. Headlines:

- Interrupts: CLINT timer (tick = 1 cycle, `mtime` ≥
  `mtimecmp`), external line (`ext_irq`, no PLIC), UART RX
  FIFO (16 bytes, routed through external code 11). `mtvec`
  direct and vectored. Entry at instruction boundaries only,
  waiting out divisions and page walks; `mret`/`sret` return
  rules as specified.
- Privilege: M/S/U, `sstatus`/`sie`/`stvec`/`sscratch`/`sepc`/
  `scause`/`stval`/`satp`/`medeleg`/`mideleg`, `sret`,
  delegation to S, ECALL causes 8/9/11 by origin mode.
- MMU: Sv32 two-level walk using the data port in dedicated
  PTW cycles (start + drain + level-1 + level-0 = 4 cycles,
  3 for a superpage), no TLB, page faults 12/13/15 with
  `tval` = faulting VA, U/S permission rules including SUM,
  misaligned cross-page accesses not split (tested).
- SOC top (`src/big32_soc.v`): unified RAM (default 1 MiB,
  parameterisable), UART, CLINT — for OS/firmware programs,
  not a drop-in for the Harvard directed programs.
- Tests: 11/11 SOC checks pass (`./run_soc.sh`, which also
  re-runs this file's Phase 1 suite as regression: 16/16
  directed, 50/50 random seeds 0–49, plus 50/50 on fresh seeds
  50–99). Phase 1 cycle counts are unchanged.
- Not claimed: Linux/xv6 boot, RISCOF, formal verification,
  silicon, or a Yosys number for the pipelined core.
