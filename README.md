# big32 — a 32-bit RISC-V CPU, built from zero

A single-cycle RV32IMAC core in Verilog, with a Python model that runs
the same programs, a two-pass assembler, and a tiny OS kernel that
runs on it. This is v7 (core/memory split for synthesis). It is a
complete little computer — and it is still NOT a Linux machine (see
"Why this is not Linux yet" below).

## What it is

- 32 registers x0..x31 (x0 hardwired to 0), 32-bit program counter.
- Single-cycle: fetch, decode, execute, memory, writeback in one clock.
- RV32I base integer instructions, all formats:
  - R: add, sub, and, or, xor, sll, srl, sra, slt, sltu
  - I: addi, andi, ori, xori, slti, sltiu, slli, srli, srai
  - Loads: lb, lh, lw, lbu, lhu — Stores: sb, sh, sw (little-endian)
  - Branches: beq, bne, blt, bge, bltu, bgeu
  - jal, jalr, lui, auipc, ecall, ebreak
- RV32M (v2): mul, mulh, mulhsu, mulhu, div, divu, rem, remu —
  including the spec edge cases: div by zero returns -1, rem by zero
  returns the dividend, and (-2147483648) / (-1) returns -2147483648.
- RV32A, word only (v3): lr.w, sc.w, amoadd.w, amoswap.w, amoxor.w,
  amoor.w, amoand.w, amomin.w, amomax.w, amominu.w, amomaxu.w, with
  an LR/SC reservation (single core, so each atomic is a
  read-modify-write in one cycle).
- M-mode CSRs (v3): mstatus, mtvec, mscratch, mepc, mcause, mtval,
  mhartid (read-only 0). Instructions: csrrw, csrrs, csrrc,
  csrrwi, csrrsi, csrrci, plus the pseudos csrw, csrs, csrc, csrr,
  and mret. ECALL/EBREAK trap to mtvec (mcause 11/3) when mtvec is
  non-zero, and halt when mtvec is zero — so plain test programs
  ending with ECALL still halt, while a kernel that sets mtvec gets
  control on every ECALL.
- UART MMIO (v3): store a byte to 0x10000000 to transmit it; loads
  from 0x10000004 (RX) return -1 (no input in this core), loads from
  0x10000008 (status) return 0.
- Memory (Harvard, for now): 16KB instruction memory (4096 words,
  programs live at byte addresses 0..16383) and 64KB byte-addressable
  data memory (addresses modulo 64KB).
- Assembler pseudos: nop, mv, li (small immediates as addi, larger
  ones as lui + addi), j, jr, ret, la (auipc + addi, pc-relative),
  and character literals in li, e.g. li a0, 'A'.

## The tiny OS kernel

`programs/kernel.s` is a real supervisor, not a demo print:

- Boots, sets the kernel stack (mscratch = 0x8000) and mtvec to its
  trap handler, and prints `big32 OS` on the UART.
- Runs two apps in turn (sum 1..10, then 6 × 7) via jal.
- Each app ends with ECALL. The trap handler swaps to the kernel
  stack via mscratch, saves a0/a1/t0–t6/ra, prints `E=` plus the
  app's result in decimal, advances mepc past the ECALL, restores
  everything, swaps the stack back, and mrets — so the app returns
  normally to the kernel.
- Prints `done`, clears mtvec, and ECALLs, which halts (mtvec == 0).

Expected UART output:

```
big32 OS
E=55
E=42
done
```

## Files

- `src/big32_core.v` — the CPU core alone (v7, no memories)
- `src/big32.v` — simulation top: core + instruction/data memories
- `tools/asm.py` — RISC-V assembler (labels, R/I/S/B/U/J/A/CSR
  encodings, la, character literals)
- `tools/model.py` — Python behavioural model, cross-checks the Verilog
- `tools/rand_test.py` — random differential tester (see below)
- `programs/` — sum, fib, mul_loop, call_demo, mul_demo, mulh_demo,
  div_demo, div_edge, div_zero, rem_zero, amo_demo, sc_fail,
  csr_demo, edge_cases, kernel (each .s with its assembled .hex)
- `sim/tb_big32.v` — testbench, prints PASS/FAIL per program and
  captures the kernel's UART output
- `sim/tb_rand.v` — testbench for the random tester
- `sim/synth_test.v` — synthesis wrapper instantiating the core alone

## Production hardening (v4)

This is what "production ready" work actually looks like for a core
like this, following the pattern of the production open cores
(Ibex, PicoRV32, SERV — see below): verification first, then
synthesis-friendliness, then honest numbers.

- **Sparse CSR file.** v3 kept all 4096 CSRs in one array, which
  would synthesise to an enormous block of flip-flops. v4 keeps only
  the implemented CSRs (mstatus, mtvec, mscratch, mepc, mcause,
  mtval) as individual registers; unimplemented CSRs read 0 and
  ignore writes, and the Python model matches exactly.
- **ABI-correct register names.** The assembler used to map t3–t6
  to 25–28 and s2–s11 to 16–25, which is not the RISC-V ABI
  (t3–t6 = 28–31, s2–s11 = 18–27). Internal programs still ran
  because model and Verilog agreed, but ABI-wrong code would not
  interoperate with a real RISC-V toolchain. Fixed in v4.
- **Random differential testing.** `python3 tools/rand_test.py 50 0`
  generates 50 random, terminating programs (ALU, M, shifts,
  loads/stores to a scratch word, forward-only branches), runs each
  through the Python model and the Verilog simulation, and compares
  all 32 registers. This is the small version of the riscv-torture /
  riscv-dv approach used by the production cores, and it caught
  three real bugs that the 14 directed tests missed (below).
- **v5: DMEM no longer cleared on reset.** The v4 fix (clearing
  64KB of data memory on reset) was a simulation convenience that
  would synthesise to 64KB of resettable flip-flops — and it is
  what stalled the Yosys check. Real RAM power-up contents are
  undefined anyway, and software must not rely on them. The core
  now leaves DMEM alone on reset; the testbenches initialise it
  to zero (once in tb_rand, and on every reset in tb_big32), and
  the Python model still starts from a zeroed bytearray per run.
  The old Yosys run was killed and restarted on the v5 core.
- **v6: parametrised memories.** IMEM_DEPTH (default 4096 words)
  and DMEM_DEPTH (default 65536 bytes) are now module parameters,
  both required to be powers of two. Defaults are unchanged, so
  all tested programs behave identically. The point is synthesis:
  Yosys replaces async-read memories with registers, so the full
  64KB DMEM makes even `proc; opt` time out (>120s, no stat).
  Core logic is therefore measured with a small-memory
  instantiation (`sim/synth_test.v`: 256-word IMEM, 1KB DMEM),
  and the full-size memories are reported separately as SRAM
  bits (IMEM 131072 bits, DMEM 524288 bits), not as logic.
- **Edge-case test.** `programs/edge_cases.s` checks 19
  hand-computed cases (SRAI/SRA on -56, signed div/rem, mulh,
  lb/lbu, lh/lhu, slt/sltu, blt, amoadd, CSR readback, jal
  subroutine) and ends with a0 = fail count, so a0 = 0 is a pass
  in both model and Verilog, independent of either implementation.
  It is now the 15th directed program in `./run.sh`.
- **v7: core split from memories (Ibex-style).** `src/big32_core.v`
  is the same single-cycle logic as v6, but with no imem/dmem
  arrays. Instead it exposes: `instr_i` / `if_addr_o` (fetch),
  `d_addr_o` (load: rs1+imm_i, store: rs1+imm_s, AMO: rs1),
  `d_rdata_i` (32-bit word read at `d_addr_o`, little-endian
  bytes at addr..addr+3), `d_wdata_o` + `d_wmask_o` + `d_we_o`
  (write). The mask is RELATIVE: bit i writes byte i of
  `d_wdata_o` to `d_addr_o+i` (SB=0001, SH=0011, SW/AMO=1111),
  so unaligned loads/stores behave exactly as in v6 — bytes
  land at addr..addr+3, each wrapped modulo the memory depth.
  A real SRAM/AXI wrapper must translate that relative mask
  into absolute lanes for unaligned addresses, or restrict
  itself to aligned accesses (where relative = absolute).
  Stores to UART MMIO addresses never assert `d_we_o`; AMO
  writes assert it even at MMIO addresses, exactly as v6's
  `store_word` did (AMO bypassed the MMIO check). No other
  semantic change: the directed suite passes with identical
  cycle counts, and the random suite still passes 50/50.
  `src/big32.v` is now just the simulation top (core + the
  same byte arrays, same port list), so testbenches keep
  working — only the register-file/PC paths changed
  (`dut.core.regs`, `dut.core.pc`). Memories at defaults are
  reported separately as SRAM bits, not logic: IMEM 4096x32 =
  131072 bits, DMEM 65536x8 = 524288 bits. Yosys result for
  the core alone: see the synthesis note below.
- **Bugs the random tester caught and fixed (v4):**
  1. **SRAI was a logical shift in Icarus.** Writing SRAI as a
     ternary made the whole expression unsigned in Icarus, so
     `srai -56, 17` gave 32767 instead of -1. Fixed with if/else,
     and documented in the source.
  2. **Signed DIV/REM were unsigned in Icarus, for the same
     ternary reason.** `-1 / -41` gave 1 instead of 0, and
     `-1644167168 / -29` gave 0 instead of 56695419. Fixed with
     if/else.
  3. The directed suite passed all along; only the random tester
     found these, because no directed test used SRAI with a
     negative value or signed division with both operands
     negative. That is exactly why production cores do random
     testing, not just directed tests.

## What the production cores do that big32 does not (yet)

Checked 26 Oct 2026 against what people are actually building now:
Ibex is a production-quality 32-bit core (RV32IMC/EMC, 2-stage,
formally verified, used in Google's OpenTitan root of trust, with
nightly regression runs and published area/performance numbers
around 15–30k gates and up to 3.13 CoreMark/MHz); PicoRV32 is the
tiny FPGA core (~750–2000 LUTs, RV32I/IM/C/E); VexRiscv is the
configurable SpinalHDL core; SERV proves itself with RISCOF
compliance tests against the SAIL reference model plus riscv-formal;
TinyTapeout's community is building RISC-V peripherals and
microcontrollers, and FPGA builders are pairing custom cores with
FreeRTOS on boards like the Arty S7-25. The pattern is consistent:
directed tests + constrained-random tests + compliance against a
reference model + formal checks + synthesis numbers, all in CI.
big32 now has the first two; it does not yet have RISCOF
compliance, formal (RVFI) checks, CI, or synthesis numbers — those
are the next production steps, not claims made here.

## Synthesis (v7) — core logic only, memories excluded

Run Yosys on the core alone (log file, so the real exit code is
captured — never pipe Yosys to `tail`, which hides failures):

```sh
yosys -Q -T -l /tmp/yosys_v7.log -p 'read_verilog src/big32_core.v; hierarchy -top big32_core; proc; opt; fsm; opt; memory; opt; techmap; opt; stat'
```

RESULT (Yosys 0.33, 26 Oct 2026, run took 225 seconds, exit code
0, full log in `yosys_v7.log` in this directory):

```
=== big32_core ===

   Number of wires:               9551
   Number of wire bits:          75081
   Number of public wires:         106
   Number of public wire bits:    2520
   Number of memories:               0
   Number of memory bits:            0
   Number of processes:              0
   Number of cells:              42731
     $_AND_                      17334
     $_DFFE_PN0N_                    1
     $_DFFE_PN0P_                 1289
     $_DFF_PN0_                      1
     $_MUX_                       4373
     $_NOT_                       1328
     $_OR_                       10560
     $_XOR_                       7845
```

Read this honestly, not as a gate count:
- **Memories: 0, memory bits: 0** — the split worked. Yosys no
  longer turns memory into registers, which was the whole point
  of v7. The only Yosys warning is "Replacing memory \regs with
  list of registers", which is expected: the register file is
  meant to be flip-flops.
- **Flip-flops: 1289 + 1 + 1 = 1291**, which is exactly the
  architectural state: PC 32 + registers 32x32 = 1024 + six
  CSRs 6x32 = 192 + reservation_valid 1 + reservation_addr 32
  + halted 1 + uart_tx 8 + uart_tx_valid 1 = 1291. That match
  is a good cross-check that Yosys saw the intended core.
- **Combinational cells: 41440** (AND + MUX + NOT + OR + XOR).
  That is large, and the reason is the single-cycle design: a
  32-bit divider/modulo unit and 64-bit multipliers, all
  combinational, in one cycle. It is NOT a kGE figure (no
  technology library was mapped, and no ABC gate optimisation
  to standard cells was run), so do not quote it as one — and
  do not compare it directly with Ibex's 15–30kGE, which is a
  pipelined core with multi-cycle multiplier options. The
  production lesson is the opposite: if area matters, the next
  step is a multi-cycle divider/multiplier (or a pipeline),
  not a bigger single-cycle ALU.
- **Why it took 225 seconds:** techmapping the combinational
  divider/multiplier, not memory explosion — the v6 failure
  mode is gone. A faster synthesis number would come from
  `synth` with a real library, or from splitting the M unit
  out, but that is future work, not a claim made here.
- Memories, as before, are separate SRAM bits, not logic:
  IMEM 4096x32 = 131072 bits, DMEM 65536x8 = 524288 bits.

## Run it

```sh
./run.sh        # assembles, runs the Python model, compiles + simulates the Verilog
python3 tools/rand_test.py 50 0   # random differential tests, model vs Verilog
```

Verified 26 Oct 2026 in both the Python model and Icarus Verilog
simulation on all 14 programs — sum = 55, fib = 55, mul_loop = 42,
call_demo = 112 with sp restored, all six M cases, amo_demo = 42,
sc_fail = 101, csr_demo = 4660, and the kernel's UART output above,
halting with sp restored to 65532. One real bug was caught by the
Verilog run and fixed: uninitialised DMEM read as x in simulation
and poisoned AMO results (amo_demo failed with a0 = x); DMEM is now
cleared to zero on reset, matching the model, and the suite is green.
v4 adds 50/50 random differential tests passing (see above). v5
keeps all 15 directed programs passing (edge_cases a0 = 0) and
re-runs the random suite on the new core.

## Why this is not Linux yet — honest roadmap

Linux on RISC-V needs, at minimum, all of the following, and big32 v3
has the first items but not the rest:

1. **M extension** — DONE in v2.
2. **A extension** — DONE in v3 (word atomics, single core).
3. **Privileged architecture** — PARTLY done in v3: M-mode CSRs,
   traps, and mret exist, but there is no S-mode or U-mode yet, no
   interrupt handling, and no privilege separation between kernel
   and user programs.
4. **MMU (Sv32)** — NOT done. This needs virtual memory with page
   tables, and it forces a move from Harvard memories to a unified
   memory system, plus a multi-cycle page-table walker (a single
   cycle cannot do a page walk).
5. **Peripherals** — PARTLY done: a UART TX exists, but there is no
   UART RX input, no timer (CLINT), no interrupt controller (PLIC),
   and no block device (virtio-blk or similar) for a root filesystem.
6. **Much more memory** — Linux wants megabytes, not 64KB, and a
   bootloader (like OpenSBI) to start it.

After that come the long tail: a device tree, a RISC-V toolchain and
a kernel build for this exact machine, a root filesystem, and a lot
of debugging. That is a real project, not a weekend upgrade — but
every one of those steps builds on this core, and this core now has
a working kernel of its own, which is where you have to start.

## Next steps (in order)

1. ~~M extension~~ — done in v2. ~~A extension~~ — done in v3.
   ~~M-mode CSRs/traps + UART + tiny kernel~~ — done in v3.
2. S-mode + U-mode, interrupt handling, UART RX.
3. Sv32 MMU + unified memory (multi-cycle core or a page-walk unit).
4. Timer + interrupt controller + block device, then a bootloader.
5. Only then: try to boot Linux, and expect it to take a while.
