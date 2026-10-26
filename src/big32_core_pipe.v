// big32_core_pipe — 5-stage pipelined RV32IMAC core (Phase 1).
// ---------------------------------------------------------------------------
// Same instruction semantics as the v7 single-cycle core
// (src/big32_core.v), restructured as IF/ID/EX/MEM/WB. The memory
// interface is IDENTICAL to v7, so the same simulation top pattern
// works (see src/big32_pipe.v): instr_i / if_addr_o (= IF pc),
// d_addr_o (MEM-stage address), d_rdata_i (combinational word at
// d_addr_o), d_wdata_o / d_wmask_o (RELATIVE byte mask, SB=0001,
// SH=0011, SW/AMO=1111) / d_we_o. Stores to UART MMIO addresses
// never assert d_we_o; AMO writes assert it even at MMIO, exactly
// as in v7. The core contains NO memory arrays.
//
// Pipeline map:
//   IF  : pc register drives if_addr_o; instr_i is combinational.
//   ID  : decode only (opcode/rd/rs1/rs2/immediates). JAL target is
//         computed here and the redirect is taken at the end of the
//         ID cycle (the speculatively fetched next instruction in
//         IF is flushed). Register operands are NOT read here.
//   EX  : register read + full forwarding (MEM->EX, WB->EX),
//         ALU (incl. combinational MUL), branch/jump resolution,
//         CSR old-value read, multi-cycle divider (see below).
//         Branches, JALR, traps, mret resolve here; a taken
//         redirect flushes IF+ID (2-cycle penalty for taken
//         branches/JALR, 1 flushed fetch for JAL in ID).
//   MEM : data memory access. Loads form load_data from d_rdata_i
//         (with v7's UART-MMIO overrides); stores/AMO drive
//         d_we_o/d_wdata_o/d_wmask_o; AMO read-modify-write is
//         atomic here (single core, one MEM cycle). The LR/SC
//         reservation is checked and updated here, in program
//         order, because MEM stages execute in order.
//   WB  : register writeback and CSR write (both at the end of the
//         WB cycle). x0 writes are discarded.
//
// Forwarding: EX operands (rs1/rs2, used for ALU, address,
// branch, JALR target, CSR new value, store/AMO data) are
// forwarded from MEM (MEM result: ALU/link/CSR value, load_data,
// AMO old value, SC result) with priority over WB (WB data),
// else the register file. Store/AMO data is forwarded in EX and
// carried to MEM in the EX/MEM register, so MEM needs no extra
// forwarding path: when a store reaches MEM, its data is already
// final (any producer was in MEM/WB during the store's EX cycle,
// or an older register value).
//
// Stalls (IF/ID frozen, bubble into EX, MEM/WB keep draining):
//   - Load-use: EX holds a load whose rd (non-x0) equals the ID
//     instruction's rs1 or rs2 field -> 1 stall cycle. The
//     consumer then reads the load via MEM->EX forwarding.
//     The rs-field match is deliberately broad (it also fires for
//     LUI/JAL immediates that happen to match): a spurious stall
//     is always safe, a missed stall is not.
//   - CSR hazard: the ID instruction is a SYSTEM instruction and
//     a CSR write is pending in EX or MEM -> stall. A CSR write
//     in WB needs NO stall: it lands at the end of the WB cycle,
//     and the stalled instruction only reads CSRs when it reaches
//     EX in a later cycle. This keeps non-CSR instructions
//     flowing behind CSR instructions, and keeps CSR reads exact.
//   - Divider: see below.
//
// Flushes: a taken branch/JALR/trap/mret/halt in EX flushes
// IF+ID. JAL in ID flushes IF only. A trap (ECALL/EBREAK with
// mtvec != 0) sets mepc/mcause/mtval at the end of its EX cycle
// and redirects to mtvec BASE; the trapping instruction never
// reaches MEM/WB (it writes nothing anyway). ECALL/EBREAK with
// mtvec == 0 set halted at the end of the EX cycle. mret
// redirects to mepc. CSR instructions are NOT flushed: they flow
// to WB, where they write rd (= old CSR value, captured in EX)
// and the CSR file.
//
// Multi-cycle divider: DIV/DIVU/REM/REMU use a restoring
// divider, one bit per cycle, in EX. Edge cases are single-cycle
// (div-by-zero -> -1 for DIV/DIVU, dividend for REM/REMU;
// MIN/-1 -> MIN for DIV, 0 for REM; identical to v7). A normal
// division occupies EX for 32 cycles total (start cycle +
// 31 iterative cycles), i.e. 31 stall cycles beyond a normal
// instruction, during which IF/ID/ID-EX are frozen and EX/MEM
// receives bubbles while MEM/WB drain. MUL/MULH/MULHSU/MULHU
// stay combinational in EX (documented choice: the divider was
// the dominant area cost in v7, and a combinational multiplier
// keeps MUL single-cycle; see PIPELINE.md).
//
// Signedness discipline (v4 lesson): no ternary with mixed
// signed/unsigned branches for shifts or division. The divider
// and the SRA/SRAI paths use if/else with signed wires, and
// absolute values are formed as (~x + 1) on unsigned wires.
// ---------------------------------------------------------------------------
`default_nettype none

module big32_core_pipe (
    input  wire        clk,
    input  wire        rst_n,
    output reg         halted,
    output reg  [7:0]  uart_tx,
    output reg         uart_tx_valid,
    input  wire [31:0] instr_i,
    output wire [31:0] if_addr_o,
    output wire [31:0] d_addr_o,
    input  wire [31:0] d_rdata_i,
    output wire [31:0] d_wdata_o,
    output wire [3:0]  d_wmask_o,
    output wire        d_we_o,
    // Phase 2 interrupt inputs (see PRIVILEGE_MMU.md). The SOC top
    // drives irq_timer from the CLINT and irq_ext from
    // ext_irq | uart_rx_ready; the pipe top ties them to 0.
    input  wire        irq_timer,
    input  wire        irq_ext,
    // UART RX: ready + head byte from the SOC FIFO (pipe top: 0).
    input  wire        uart_rx_ready,
    input  wire [7:0]  uart_rx_data,
    // Pulsed (combinational) in the MEM cycle of a load from
    // 0x10000004 with a byte available; the SOC pops its FIFO on it.
    output wire        uart_rx_pop
);
    reg [31:0] pc;
    reg [31:0] regs [0:31];
    reg [31:0] csr_mstatus, csr_mtvec, csr_mscratch;
    reg [31:0] csr_mepc, csr_mcause, csr_mtval;
    // Phase 2/3 CSRs (see PRIVILEGE_MMU.md for implemented bits).
    reg [31:0] csr_mie;
    reg [1:0]  priv; // 3=M, 1=S, 0=U; reset to M.
    // Phase 3 S-mode CSRs.
    reg [31:0] csr_sstatus, csr_sie, csr_stvec, csr_sscratch;
    reg [31:0] csr_sepc, csr_scause, csr_stval, csr_satp;
    reg [31:0] csr_medeleg, csr_mideleg;
    // Phase 3 Sv32 page-table walker state. States: 0 IDLE,
    // 1 DRAIN (MEM drains, data port untouched), 2 LEVEL1, 3 LEVEL0.
    reg [2:0]  ptw_state;
    reg        ptw_is_fetch, ptw_is_store;
    reg [31:0] ptw_va, ptw_root_base, ptw_pte1, ptw_data_pa;
    reg        ptw_data_done, ptw_data_fault;
    reg [31:0] ptw_data_fault_cause; // 13 load, 15 store/AMO
    // Cached fetch translation for the current pc (no TLB: this
    // is a one-entry "current fetch" cache, refilled by a walk
    // whenever pc changes or satp is written, not a TLB).
    reg [31:0] fetch_pa, fetch_pa_pc;
    reg        fetch_pa_valid;
    // A fetch walk that faulted: the fault is delivered as a
    // marker instruction into ID/EX (see the IF/ID block), so
    // older instructions still commit first, in order.
    reg        fetch_fault_pending;
    reg [31:0] fetch_fault_pc;
    reg        reservation_valid;
    reg [31:0] reservation_addr;

    // ---- IF/ID -------------------------------------------------------
    reg [31:0] if_id_instr;
    reg [31:0] if_id_pc;
    reg        if_id_fetch_fault;
    // Phase 2: validity of the IF/ID register. A flushed/bubble slot
    // has valid=0 (its pc is 0 and must never be used as an
    // interrupt mepc); a real instruction, including a NOP word,
    // has valid=1. Needed so interrupt entry can tell "the next
    // not-yet-executed instruction" (ID pc) from "nothing in ID"
    // (then the next fetch address, pc).
    reg        if_id_valid;

    // ---- ID/EX -------------------------------------------------------
    reg        id_ex_fetch_fault;
    reg [31:0] id_ex_pc;
    reg [6:0]  id_ex_opcode;
    reg [4:0]  id_ex_rd, id_ex_rs1, id_ex_rs2;
    reg [2:0]  id_ex_funct3;
    reg [6:0]  id_ex_funct7;
    reg [31:0] id_ex_imm_i, id_ex_imm_s, id_ex_imm_b;
    reg [31:0] id_ex_imm_u, id_ex_imm_j;
    reg [11:0] id_ex_csr_addr;

    // ---- EX/MEM ------------------------------------------------------
    reg [31:0] ex_mem_pc;
    reg [4:0]  ex_mem_rd;
    reg [2:0]  ex_mem_funct3;
    reg [31:0] ex_mem_result;
    reg [31:0] ex_mem_rs2;
    reg [31:0] ex_mem_addr;
    reg        ex_mem_reg_write;
    reg        ex_mem_is_load, ex_mem_is_store;
    reg        ex_mem_is_amo, ex_mem_is_sc, ex_mem_is_lr;
    reg [4:0]  ex_mem_amo_funct5;
    reg        ex_mem_csr_write;
    reg [11:0] ex_mem_csr_addr;
    reg [31:0] ex_mem_csr_new;

    // ---- MEM/WB ------------------------------------------------------
    reg [4:0]  mem_wb_rd;
    reg [31:0] mem_wb_data;
    reg        mem_wb_reg_write;
    reg        mem_wb_csr_write;
    reg [11:0] mem_wb_csr_addr;
    reg [31:0] mem_wb_csr_new;

    // ---- Divider state ----------------------------------------------
    reg        div_busy;
    reg [5:0]  div_cnt;
    reg [31:0] div_rem, div_quot, div_divisor, div_dividend;
    reg        div_signed_r, div_is_rem_r, div_neg_q_r, div_neg_r_r;

    // Phase 3: translation is enabled when satp.MODE=1 and the
    // current privilege is S or U. M-mode is always bare (MPRV
    // is not implemented). A translated fetch uses the cached
    // fetch_pa for the current pc; while a walk is in progress
    // (or before it starts) if_addr_o is the virtual pc, whose
    // instruction word is never captured (IF/ID is frozen by
    // the PTW stall), so the value there is harmless.
    wire fetch_trans_enabled = (csr_satp[31] == 1'b1) &&
                               (priv != 2'd3);
    assign if_addr_o = (fetch_trans_enabled && fetch_pa_valid &&
                        (fetch_pa_pc == pc)) ? fetch_pa : pc;

    // Phase 3: page-table walk addresses. Level-1 PTE address =
    // root base + VPN1*4; level-0 PTE address = level-1 PTE's
    // page-table base + VPN0*4. Root base and table bases are
    // PPN<<12 truncated to 32 bits: {PPN[19:0], 12'b0}.
    reg [31:0] ptw_addr;
    always @* begin
        if (ptw_state == 3'd2)
            ptw_addr = ptw_root_base + {ptw_va[31:22], 2'b00};
        else if (ptw_state == 3'd3)
            ptw_addr = {ptw_pte1[29:10], 12'b0} +
                       {ptw_va[21:12], 2'b00};
        else
            ptw_addr = 32'b0;
    end

    // ================= ID stage: decode ==============================
    wire [6:0]  id_opcode = if_id_instr[6:0];
    wire [4:0]  id_rd     = if_id_instr[11:7];
    wire [4:0]  id_rs1    = if_id_instr[19:15];
    wire [4:0]  id_rs2    = if_id_instr[24:20];
    wire [31:0] id_imm_j  = {{11{if_id_instr[31]}}, if_id_instr[31],
                             if_id_instr[19:12], if_id_instr[20],
                             if_id_instr[30:21], 1'b0};
    wire id_is_jal    = (id_opcode == 7'b1101111);
    wire id_is_system = (id_opcode == 7'b1110011);
    wire [31:0] id_jal_target = if_id_pc + id_imm_j;

    // ================= MEM stage: combinational ======================
    wire [31:0] mem_addr = ex_mem_addr;
    // Phase 3: during a page-table walk's LEVEL1/LEVEL0 cycles
    // the data port carries the PTE address (the MEM stage holds
    // a bubble then, so nothing else needs the port). During
    // DRAIN the data port is untouched (normal MEM access).
    assign d_addr_o = ((ptw_state == 3'd2) || (ptw_state == 3'd3)) ?
                      ptw_addr : mem_addr;
    wire [7:0]  mb0 = d_rdata_i[7:0];
    wire [7:0]  mb1 = d_rdata_i[15:8];
    wire [7:0]  mb2 = d_rdata_i[23:16];
    wire [7:0]  mb3 = d_rdata_i[31:24];
    reg [31:0] load_data;
    always @* begin
        if (mem_addr == 32'h10000000) begin
            load_data = 32'b0;
        end else if (mem_addr == 32'h10000004) begin
            // Phase 2 UART RX: a byte available returns it
            // zero-extended; empty still returns -1 (v7 behaviour,
            // kept so the pipe top, which has no RX source, is
            // unchanged). The SOC pops its FIFO on uart_rx_pop.
            if (uart_rx_ready)
                load_data = {24'b0, uart_rx_data};
            else
                load_data = 32'hFFFFFFFF;
        end else if (mem_addr == 32'h10000008) begin
            load_data = {31'b0, uart_rx_ready};
        end else begin
            case (ex_mem_funct3)
                3'b000: load_data = {{24{mb0[7]}}, mb0};
                3'b001: load_data = {{16{mb1[7]}}, mb1, mb0};
                3'b010: load_data = {mb3, mb2, mb1, mb0};
                3'b100: load_data = {24'b0, mb0};
                3'b101: load_data = {16'b0, mb1, mb0};
                default: load_data = 32'b0;
            endcase
        end
    end

    wire [31:0] amo_old = d_rdata_i;
    wire sc_success = ex_mem_is_sc && reservation_valid &&
                      (reservation_addr == mem_addr);
    reg [31:0] amo_new;
    always @* begin
        case (ex_mem_amo_funct5)
            5'b00000: amo_new = amo_old + ex_mem_rs2;
            5'b00001: amo_new = ex_mem_rs2;
            5'b00100: amo_new = amo_old ^ ex_mem_rs2;
            5'b01000: amo_new = amo_old | ex_mem_rs2;
            5'b01100: amo_new = amo_old & ex_mem_rs2;
            5'b10000: amo_new = ($signed(amo_old) < $signed(ex_mem_rs2)) ? amo_old : ex_mem_rs2;
            5'b10100: amo_new = ($signed(amo_old) > $signed(ex_mem_rs2)) ? amo_old : ex_mem_rs2;
            5'b11000: amo_new = (amo_old < ex_mem_rs2) ? amo_old : ex_mem_rs2;
            5'b11100: amo_new = (amo_old > ex_mem_rs2) ? amo_old : ex_mem_rs2;
            default: amo_new = amo_old;
        endcase
    end

    // MEM result = the value forwarded to EX and written back in WB.
    reg [31:0] mem_result;
    always @* begin
        if (ex_mem_is_load)
            mem_result = load_data;
        else if (ex_mem_is_sc)
            mem_result = sc_success ? 32'd0 : 32'd1;
        else if (ex_mem_is_amo)
            mem_result = amo_old;
        else
            mem_result = ex_mem_result;
    end

    reg        d_we_comb;
    reg [31:0] d_wdata_comb;
    reg [3:0]  d_wmask_comb;
    always @* begin
        d_we_comb = 1'b0;
        d_wdata_comb = 32'b0;
        d_wmask_comb = 4'b0;
        if (ex_mem_is_store) begin
            if ((mem_addr != 32'h10000000) &&
                (mem_addr != 32'h10000004) &&
                (mem_addr != 32'h10000008)) begin
                case (ex_mem_funct3)
                    3'b000: begin d_we_comb = 1'b1; d_wdata_comb = ex_mem_rs2; d_wmask_comb = 4'b0001; end
                    3'b001: begin d_we_comb = 1'b1; d_wdata_comb = ex_mem_rs2; d_wmask_comb = 4'b0011; end
                    3'b010: begin d_we_comb = 1'b1; d_wdata_comb = ex_mem_rs2; d_wmask_comb = 4'b1111; end
                    default: begin end
                endcase
            end
        end else if (ex_mem_is_amo) begin
            if (ex_mem_is_lr) begin
                d_we_comb = 1'b0;
            end else if (ex_mem_is_sc) begin
                if (sc_success) begin
                    d_we_comb = 1'b1; d_wdata_comb = ex_mem_rs2; d_wmask_comb = 4'b1111;
                end
            end else begin
                d_we_comb = 1'b1; d_wdata_comb = amo_new; d_wmask_comb = 4'b1111;
            end
        end
    end
    // Phase 3: never write during a walk's PTE-read cycles (the
    // MEM stage is a bubble then, so d_we_comb is already 0;
    // this is belt-and-braces).
    assign d_we_o = d_we_comb && !((ptw_state == 3'd2) ||
                                   (ptw_state == 3'd3));
    assign d_wdata_o = d_wdata_comb;
    assign d_wmask_o = d_wmask_comb;
    // Phase 2: pop the SOC RX FIFO on a MEM-stage load from the RX
    // data register while a byte is available. Stores/AMOs to the
    // RX address do not pop (ex_mem_is_load distinguishes them).
    assign uart_rx_pop = ex_mem_is_load &&
                         (mem_addr == 32'h10000004) && uart_rx_ready;

    // ================= EX stage: forwarding ==========================
    wire [31:0] ex_rs1_raw = regs[id_ex_rs1];
    wire [31:0] ex_rs2_raw = regs[id_ex_rs2];
    reg [31:0] ex_rs1_fwd, ex_rs2_fwd;
    always @* begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs1))
            ex_rs1_fwd = mem_result;
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs1))
            ex_rs1_fwd = mem_wb_data;
        else
            ex_rs1_fwd = ex_rs1_raw;
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) &&
            (ex_mem_rd == id_ex_rs2))
            ex_rs2_fwd = mem_result;
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs2))
            ex_rs2_fwd = mem_wb_data;
        else
            ex_rs2_fwd = ex_rs2_raw;
    end
    wire signed [31:0] s_rs1_fwd = ex_rs1_fwd;
    wire signed [31:0] s_rs2_fwd = ex_rs2_fwd;

    // ================= EX stage: CSR read ============================
    // Phase 2 mip: bit 11 = external (SOC: ext_irq | uart_rx_ready),
    // bit 7 = timer (SOC: mtime >= mtimecmp). All other mip bits,
    // including MSIP (3), read 0. mie implements bits 11, 7, 3
    // (MSIE is stored but never pending: there is no software
    // interrupt source). mstatus is stored already masked to
    // MPP (12:11), MPIE (7), MIE (3); all other bits read 0.
    wire [31:0] mip_val = {20'b0, irq_ext, 3'b0, irq_timer, 7'b0};
    reg [31:0] ex_csr_old;
    always @* begin
        case (id_ex_csr_addr)
            12'h100: ex_csr_old = csr_sstatus;
            12'h104: ex_csr_old = csr_sie;
            12'h105: ex_csr_old = csr_stvec;
            12'h140: ex_csr_old = csr_sscratch;
            12'h141: ex_csr_old = csr_sepc;
            12'h142: ex_csr_old = csr_scause;
            12'h143: ex_csr_old = csr_stval;
            12'h180: ex_csr_old = csr_satp;
            12'h300: ex_csr_old = csr_mstatus;
            12'h302: ex_csr_old = csr_medeleg;
            12'h303: ex_csr_old = csr_mideleg;
            12'h304: ex_csr_old = csr_mie;
            12'h305: ex_csr_old = csr_mtvec;
            12'h340: ex_csr_old = csr_mscratch;
            12'h341: ex_csr_old = csr_mepc;
            12'h342: ex_csr_old = csr_mcause;
            12'h343: ex_csr_old = csr_mtval;
            12'h344: ex_csr_old = mip_val;
            default: ex_csr_old = 32'b0;
        endcase
    end
    wire ex_is_system = (id_ex_opcode == 7'b1110011);
    wire ex_is_csr    = ex_is_system && (id_ex_funct3 != 3'b000);
    wire ex_is_mret   = ex_is_system && (id_ex_funct3 == 3'b000) &&
                        (id_ex_csr_addr == 12'h302);
    wire ex_is_sret   = ex_is_system && (id_ex_funct3 == 3'b000) &&
                        (id_ex_csr_addr == 12'h102);
    // SFENCE.VMA: SYSTEM, funct3=0, funct7=0001001 (instr[31:25]).
    // With no TLB it is a NOP in M/S; in U it is illegal.
    wire ex_is_sfence = ex_is_system && (id_ex_funct3 == 3'b000) &&
                        (id_ex_funct7 == 7'b0001001);
    wire ex_is_ecall  = ex_is_system && (id_ex_funct3 == 3'b000) &&
                        (id_ex_csr_addr == 12'h000);
    wire ex_is_ebreak = ex_is_system && (id_ex_funct3 == 3'b000) &&
                        (id_ex_csr_addr == 12'h001);
    // Phase 3 privilege checks. CSR address bits [9:8] are the
    // minimum privilege (00=U, 01=S, 10=hypervisor, 11=M); a
    // hypervisor CSR needs priv >= 2, which only M (3) satisfies
    // here. A write attempt to a read-only CSR ([11:10]=11)
    // is illegal; csrrs/csrrc with rs1=x0 (and csrrsi/csrrci
    // with uimm=0) are reads, not writes, and are already
    // excluded by ex_csr_write below.
    wire [1:0] csr_priv_req = (id_ex_csr_addr[9:8] == 2'b11) ? 2'd3 :
                              (id_ex_csr_addr[9:8] == 2'b10) ? 2'd2 :
                              (id_ex_csr_addr[9:8] == 2'b01) ? 2'd1 : 2'd0;
    // ex_csr_write is computed just below; the illegal-CSR wire
    // is declared here and assigned after it (Verilog allows the
    // forward reference; the assignment is in the same module).
    wire csr_illegal;
    wire ex_illegal = (ex_is_mret && (priv != 2'd3)) ||
                      (ex_is_sret && (priv == 2'd0)) ||
                      (ex_is_sfence && (priv == 2'd0)) ||
                      csr_illegal;
    wire ex_is_mret_valid = ex_is_mret && (priv == 2'd3);
    wire ex_is_sret_valid = ex_is_sret && (priv != 2'd0);
    // Phase 3 trap cause / tval / delegation. Priority among
    // simultaneous trap sources: a fetch fault (marker) or data
    // fault (PTW flag) cannot coincide with an ECALL/EBREAK or
    // illegal instruction in the same EX slot, so the if/else
    // order is just a total order, not a real arbitration.
    // Delegation: a trap whose medeleg bit is set AND whose
    // current privilege is below M goes to S; traps from M
    // always stay in M.
    reg [31:0] ex_trap_cause;
    reg [31:0] ex_trap_tval;
    reg        ex_trap_to_s;
    always @* begin
        if (id_ex_fetch_fault) begin
            ex_trap_cause = 32'd12;
            ex_trap_tval = id_ex_pc;
        end else if (ptw_data_fault) begin
            ex_trap_cause = ptw_data_fault_cause;
            ex_trap_tval = ptw_va;
        end else if (ex_illegal) begin
            ex_trap_cause = 32'd2;
            ex_trap_tval = 32'b0;
        end else if (ex_is_ebreak) begin
            ex_trap_cause = 32'd3;
            ex_trap_tval = 32'b0;
        end else begin
            if (priv == 2'd0)
                ex_trap_cause = 32'd8;
            else if (priv == 2'd1)
                ex_trap_cause = 32'd9;
            else
                ex_trap_cause = 32'd11;
            ex_trap_tval = 32'b0;
        end
        ex_trap_to_s = (priv != 2'd3) &&
                       csr_medeleg[ex_trap_cause[4:0]];
    end
    wire ex_is_exception = ex_is_ecall || ex_is_ebreak || ex_illegal ||
                           id_ex_fetch_fault || ptw_data_fault;
    // A trap goes to S whenever delegated, even if mtvec is 0.
    // A trap to M with mtvec == 0 halts (the Phase 1 rule,
    // extended to illegal/page-fault traps with no handler).
    wire ex_trap = ex_is_exception &&
                  (ex_trap_to_s || (csr_mtvec != 32'b0));
    wire ex_halt = ex_is_exception && !ex_trap;
    reg [31:0] ex_csr_new;
    reg        ex_csr_write;
    always @* begin
        ex_csr_new = 32'b0;
        ex_csr_write = 1'b0;
        // Phase 3: the old mhartid write exclusion is gone. A
        // write to a read-only CSR (mhartid, 0xF14) now traps as
        // an illegal instruction via csr_illegal below, instead
        // of being silently ignored; a read (csrrs with rs1=x0)
        // still just returns 0. No Phase 1 program writes a
        // read-only CSR, so the regression suite is unaffected.
        if (ex_is_csr) begin
            case (id_ex_funct3)
                3'b001: begin ex_csr_new = ex_rs1_fwd; ex_csr_write = 1'b1; end
                3'b010: begin ex_csr_new = ex_csr_old | ex_rs1_fwd; ex_csr_write = (id_ex_rs1 != 5'd0); end
                3'b011: begin ex_csr_new = ex_csr_old & ~ex_rs1_fwd; ex_csr_write = (id_ex_rs1 != 5'd0); end
                3'b101: begin ex_csr_new = {27'b0, id_ex_rs1}; ex_csr_write = 1'b1; end
                3'b110: begin ex_csr_new = ex_csr_old | {27'b0, id_ex_rs1}; ex_csr_write = (id_ex_rs1 != 5'd0); end
                3'b111: begin ex_csr_new = ex_csr_old & ~{27'b0, id_ex_rs1}; ex_csr_write = (id_ex_rs1 != 5'd0); end
                default: begin end
            endcase
        end
    end
    assign csr_illegal = ex_is_csr &&
                         ((priv < csr_priv_req) ||
                          (ex_csr_write &&
                           (id_ex_csr_addr[11:10] == 2'b11)));

    // ================= EX stage: divider =============================
    wire ex_is_div = (id_ex_opcode == 7'b0110011) &&
                     (id_ex_funct7 == 7'b0000001) &&
                     (id_ex_funct3[2] == 1'b1);
    wire div_signed = ~id_ex_funct3[0];
    wire div_is_rem = id_ex_funct3[1];
    reg [31:0] div_abs_a, div_abs_b;
    reg div_neg_q, div_neg_r;
    always @* begin
        // Unsigned division uses the raw operands: taking the
        // absolute value here was the first random-test bug found
        // (divu 4294967210/1 gave 86 instead of 4294967210).
        if (div_signed) begin
            if (s_rs1_fwd[31])
                div_abs_a = ~ex_rs1_fwd + 32'd1;
            else
                div_abs_a = ex_rs1_fwd;
            if (s_rs2_fwd[31])
                div_abs_b = ~ex_rs2_fwd + 32'd1;
            else
                div_abs_b = ex_rs2_fwd;
        end else begin
            div_abs_a = ex_rs1_fwd;
            div_abs_b = ex_rs2_fwd;
        end
        div_neg_q = div_signed && (s_rs1_fwd[31] != s_rs2_fwd[31]);
        div_neg_r = div_signed && s_rs1_fwd[31];
    end
    // One restoring-division iteration, combinational.
    reg [31:0] div_iter_rem, div_iter_quot;
    reg [31:0] div_start_rem, div_start_quot;
    reg div_start_sub;
    reg [4:0] div_bit_idx;
    reg [31:0] div_shifted_start, div_shifted_busy;
    reg div_sub;
    always @* begin
        // Start cycle (not busy yet): iterate on bit 31 directly.
        if (div_abs_a[31])
            div_shifted_start = 32'd1;
        else
            div_shifted_start = 32'd0;
        div_start_sub = (div_shifted_start >= div_abs_b);
        if (div_start_sub) begin
            div_start_rem = div_shifted_start - div_abs_b;
            div_start_quot = 32'h80000000;
        end else begin
            div_start_rem = div_shifted_start;
            div_start_quot = 32'd0;
        end
        // Busy cycles: iterate on bit (31 - div_cnt).
        div_bit_idx = 5'd31 - div_cnt[4:0];
        div_shifted_busy = {div_rem[30:0], div_dividend[div_bit_idx]};
        div_sub = (div_shifted_busy >= div_divisor);
        if (div_sub) begin
            div_iter_rem = div_shifted_busy - div_divisor;
            div_iter_quot = div_quot | (32'd1 << div_bit_idx);
        end else begin
            div_iter_rem = div_shifted_busy;
            div_iter_quot = div_quot;
        end
    end
    reg div_ready;
    reg [31:0] div_result;
    always @* begin
        div_ready = 1'b0;
        div_result = 32'b0;
        if (ex_is_div) begin
            if (ex_rs2_fwd == 32'b0) begin
                div_ready = 1'b1;
                if (div_is_rem)
                    div_result = ex_rs1_fwd;
                else
                    div_result = 32'hFFFFFFFF;
            end else if (div_signed &&
                         (ex_rs1_fwd == 32'h80000000) &&
                         (ex_rs2_fwd == 32'hFFFFFFFF)) begin
                div_ready = 1'b1;
                if (div_is_rem)
                    div_result = 32'b0;
                else
                    div_result = 32'h80000000;
            end else if (!div_busy) begin
                div_ready = 1'b0;
                div_result = 32'b0;
            end else if (div_cnt == 6'd31) begin
                div_ready = 1'b1;
                if (div_is_rem_r) begin
                    if (div_neg_r_r)
                        div_result = ~div_iter_rem + 32'd1;
                    else
                        div_result = div_iter_rem;
                end else begin
                    if (div_neg_q_r)
                        div_result = ~div_iter_quot + 32'd1;
                    else
                        div_result = div_iter_quot;
                end
            end else begin
                div_ready = 1'b0;
                div_result = 32'b0;
            end
        end
    end
    wire div_stall = ex_is_div && !div_ready;

    // ================= EX stage: ALU =================================
    wire signed [63:0] mul_ss = $signed(ex_rs1_fwd) * $signed(ex_rs2_fwd);
    wire signed [63:0] mul_su = $signed(ex_rs1_fwd) * $signed({1'b0, ex_rs2_fwd});
    wire [63:0]        mul_uu = ex_rs1_fwd * ex_rs2_fwd;
    reg [31:0] ex_alu_out;
    always @* begin
        ex_alu_out = 32'b0;
        case (id_ex_opcode)
            7'b0110011: begin
                case ({id_ex_funct7, id_ex_funct3})
                    10'b0000000000: ex_alu_out = ex_rs1_fwd + ex_rs2_fwd;
                    10'b0100000000: ex_alu_out = ex_rs1_fwd - ex_rs2_fwd;
                    10'b0000000111: ex_alu_out = ex_rs1_fwd & ex_rs2_fwd;
                    10'b0000000110: ex_alu_out = ex_rs1_fwd | ex_rs2_fwd;
                    10'b0000000100: ex_alu_out = ex_rs1_fwd ^ ex_rs2_fwd;
                    10'b0000000001: ex_alu_out = ex_rs1_fwd << ex_rs2_fwd[4:0];
                    10'b0000000101: ex_alu_out = ex_rs1_fwd >> ex_rs2_fwd[4:0];
                    10'b0100000101: ex_alu_out = s_rs1_fwd >>> ex_rs2_fwd[4:0];
                    10'b0000000010: begin
                        if (s_rs1_fwd < s_rs2_fwd)
                            ex_alu_out = 32'd1;
                        else
                            ex_alu_out = 32'd0;
                    end
                    10'b0000000011: begin
                        if (ex_rs1_fwd < ex_rs2_fwd)
                            ex_alu_out = 32'd1;
                        else
                            ex_alu_out = 32'd0;
                    end
                    10'b0000001000: ex_alu_out = mul_ss[31:0];
                    10'b0000001001: ex_alu_out = mul_ss[63:32];
                    10'b0000001010: ex_alu_out = mul_su[63:32];
                    10'b0000001011: ex_alu_out = mul_uu[63:32];
                    10'b0000001100: ex_alu_out = div_result;
                    10'b0000001101: ex_alu_out = div_result;
                    10'b0000001110: ex_alu_out = div_result;
                    10'b0000001111: ex_alu_out = div_result;
                    default: ex_alu_out = 32'b0;
                endcase
            end
            7'b0010011: begin
                case (id_ex_funct3)
                    3'b000: ex_alu_out = ex_rs1_fwd + id_ex_imm_i;
                    3'b111: ex_alu_out = ex_rs1_fwd & id_ex_imm_i;
                    3'b110: ex_alu_out = ex_rs1_fwd | id_ex_imm_i;
                    3'b100: ex_alu_out = ex_rs1_fwd ^ id_ex_imm_i;
                    3'b010: begin
                        if (s_rs1_fwd < $signed(id_ex_imm_i))
                            ex_alu_out = 32'd1;
                        else
                            ex_alu_out = 32'd0;
                    end
                    3'b011: begin
                        if (ex_rs1_fwd < id_ex_imm_i)
                            ex_alu_out = 32'd1;
                        else
                            ex_alu_out = 32'd0;
                    end
                    3'b001: ex_alu_out = ex_rs1_fwd << id_ex_imm_i[4:0];
                    3'b101: begin
                        if (id_ex_funct7 == 7'h20)
                            ex_alu_out = s_rs1_fwd >>> id_ex_imm_i[4:0];
                        else
                            ex_alu_out = ex_rs1_fwd >> id_ex_imm_i[4:0];
                    end
                    default: ex_alu_out = 32'b0;
                endcase
            end
            default: ex_alu_out = 32'b0;
        endcase
    end

    // ================= EX stage: branch / control ====================
    reg ex_branch_taken;
    always @* begin
        case (id_ex_funct3)
            3'b000: ex_branch_taken = (ex_rs1_fwd == ex_rs2_fwd);
            3'b001: ex_branch_taken = (ex_rs1_fwd != ex_rs2_fwd);
            3'b100: ex_branch_taken = (s_rs1_fwd < s_rs2_fwd);
            3'b101: ex_branch_taken = (s_rs1_fwd >= s_rs2_fwd);
            3'b110: ex_branch_taken = (ex_rs1_fwd < ex_rs2_fwd);
            3'b111: ex_branch_taken = (ex_rs1_fwd >= ex_rs2_fwd);
            default: ex_branch_taken = 1'b0;
        endcase
    end
    wire ex_is_branch = (id_ex_opcode == 7'b1100011);
    wire ex_is_jalr   = (id_ex_opcode == 7'b1100111);
    wire ex_is_load   = (id_ex_opcode == 7'b0000011);
    wire ex_is_store  = (id_ex_opcode == 7'b0100011);
    wire ex_is_amo    = (id_ex_opcode == 7'b0101111);
    // A-instruction funct5 is instr[31:27]. It is carried in the
    // dedicated ID/EX field id_ex_amo_f5 (see the ID/EX block),
    // since funct7 alone (instr[31:25]) mixes funct5 with aq/rl.
    // Phase 3: after a data walk completes, the MEM address is
    // the translated physical address (which already includes
    // the page offset); otherwise it is the virtual address.
    wire [31:0] ex_mem_addr_comb = (ptw_data_done &&
                                    (ex_is_load || ex_is_store ||
                                     ex_is_amo)) ? ptw_data_pa :
                                   ex_is_load  ? (ex_rs1_fwd + id_ex_imm_i) :
                                   ex_is_store ? (ex_rs1_fwd + id_ex_imm_s) :
                                   ex_rs1_fwd;
    reg [31:0] ex_result;
    reg        ex_reg_write;
    always @* begin
        case (id_ex_opcode)
            7'b0110011, 7'b0010011: begin ex_result = ex_alu_out; ex_reg_write = 1'b1; end
            7'b0000011: begin ex_result = 32'b0; ex_reg_write = 1'b1; end
            7'b1101111: begin ex_result = id_ex_pc + 32'd4; ex_reg_write = 1'b1; end
            7'b1100111: begin ex_result = id_ex_pc + 32'd4; ex_reg_write = 1'b1; end
            7'b0110111: begin ex_result = id_ex_imm_u; ex_reg_write = 1'b1; end
            7'b0010111: begin ex_result = id_ex_pc + id_ex_imm_u; ex_reg_write = 1'b1; end
            7'b0101111: begin ex_result = 32'b0; ex_reg_write = 1'b1; end
            7'b1110011: begin
                if (ex_is_csr) begin ex_result = ex_csr_old; ex_reg_write = 1'b1; end
                else begin ex_result = 32'b0; ex_reg_write = 1'b0; end
            end
            default: begin ex_result = 32'b0; ex_reg_write = 1'b0; end
        endcase
    end
    wire ex_redirect = (ex_is_branch && ex_branch_taken) || ex_is_jalr ||
                       ex_trap || ex_is_mret_valid || ex_is_sret_valid ||
                       ex_halt;
    reg [31:0] ex_target;
    always @* begin
        // Exceptions always go to the trap vector BASE, even in
        // vectored mode (vectored offsets apply to interrupts).
        if (ex_trap)
            ex_target = ex_trap_to_s ? {csr_stvec[31:2], 2'b00}
                                     : {csr_mtvec[31:2], 2'b00};
        else if (ex_is_mret_valid)
            ex_target = csr_mepc;
        else if (ex_is_sret_valid)
            ex_target = csr_sepc;
        else if (ex_is_branch)
            ex_target = id_ex_pc + id_ex_imm_b;
        else if (ex_is_jalr)
            ex_target = (ex_rs1_fwd + id_ex_imm_i) & ~32'd1;
        else
            ex_target = id_ex_pc + 32'd4;
    end

    // ================= Phase 3: satp stall/flush =====================
    // A satp write pending anywhere in EX/MEM/WB stalls the ID
    // stage for every opcode (not just SYSTEM, unlike the CSR
    // stall): no post-satp instruction may reach EX, and no new
    // fetch may start, until the write has committed in WB, or
    // it would be translated (or fetched) with the old tables.
    // The satp write in EX additionally flushes IF/ID and sets
    // pc to the next sequential address (see the PC block).
    wire satp_pending = (ex_csr_write &&
                         (id_ex_csr_addr == 12'h180)) ||
                        (ex_mem_csr_write &&
                         (ex_mem_csr_addr == 12'h180)) ||
                        (mem_wb_csr_write &&
                         (mem_wb_csr_addr == 12'h180));
    wire ex_satp_write = ex_csr_write &&
                         (id_ex_csr_addr == 12'h180);
    wire satp_stall = satp_pending;

    // ================= Phase 3: page-table walker (combinational) ===
    // A walk starts only from IDLE. The start cycle itself
    // already freezes the pipeline (ptw_start joins pipe_stall),
    // so the instruction in MEM during the start cycle still
    // completes its access, then DRAIN lets MEM go to WB while
    // EX/MEM takes bubbles, and only then do LEVEL1/LEVEL0
    // drive the data port. A data walk is for the EX load/store/
    // AMO (its address is the untranslated ex_mem_addr_comb while
    // ptw_data_done is 0); a fetch walk is for the current pc.
    // A/D bits are ignored (never required, never updated).
    // Misaligned accesses that cross a page boundary are NOT
    // split: the whole access uses the first page's translation
    // (bytes continue into the next physical page), and no fault
    // is raised for the second page.
    wire data_trans_needed = fetch_trans_enabled &&
                             (ex_is_load || ex_is_store || ex_is_amo) &&
                             !ptw_data_done && !ptw_data_fault;
    wire fetch_trans_needed = fetch_trans_enabled &&
                              !(fetch_pa_valid &&
                                (fetch_pa_pc == pc)) &&
                              !fetch_fault_pending;
    wire ptw_start_data = (ptw_state == 3'd0) && data_trans_needed &&
                          !div_stall && !ex_trap && !ex_halt && !halted;
    wire ptw_start_fetch = (ptw_state == 3'd0) && fetch_trans_needed &&
                           !div_stall && !ex_trap && !ex_halt &&
                           !ex_redirect && !satp_pending && !halted;
    wire ptw_start = ptw_start_data || ptw_start_fetch;
    wire ptw_active = (ptw_state != 3'd0);
    // Permission check for the PTE currently on the data port
    // (d_rdata_i during a LEVEL1/LEVEL0 cycle). PTE flag bits:
    // V=0, R=1, W=2, X=3, U=4. A leaf is V && (R||W||X).
    wire [31:0] ptw_pte_now = d_rdata_i;
    wire ptw_leaf_now = ptw_pte_now[0] &&
                        (ptw_pte_now[1] || ptw_pte_now[2] ||
                         ptw_pte_now[3]);
    reg ptw_perm_fault_now;
    always @* begin
        ptw_perm_fault_now = 1'b0;
        if (ptw_leaf_now) begin
            if (ptw_pte_now[2] && !ptw_pte_now[1])
                ptw_perm_fault_now = 1'b1; // W without R: reserved
            else if (ptw_is_fetch) begin
                if (!ptw_pte_now[3])
                    ptw_perm_fault_now = 1'b1;
                // SUM does not apply to fetches: S-mode fetch
                // from a U page always faults, U fetch from an
                // S page always faults.
                else if ((priv == 2'd1) && ptw_pte_now[4])
                    ptw_perm_fault_now = 1'b1;
                else if ((priv == 2'd0) && !ptw_pte_now[4])
                    ptw_perm_fault_now = 1'b1;
            end else begin
                if (ptw_is_store) begin
                    if (!ptw_pte_now[2])
                        ptw_perm_fault_now = 1'b1;
                end else begin
                    if (!ptw_pte_now[1])
                        ptw_perm_fault_now = 1'b1;
                end
                if (!ptw_perm_fault_now) begin
                    if ((priv == 2'd1) && ptw_pte_now[4] &&
                        !csr_sstatus[18])
                        ptw_perm_fault_now = 1'b1; // S data from
                    // U page without SUM
                    else if ((priv == 2'd0) && !ptw_pte_now[4])
                        ptw_perm_fault_now = 1'b1; // U data from
                    // S page (SUM is S-mode only)
                end
            end
        end
    end

    // ================= Phase 2/3: interrupt take =====================
    // Priority: external over timer; there is no software source,
    // so MSIP never pends. Per source, the interrupt goes to S
    // if it is delegated (mideleg bit) AND enabled for S (sie
    // bit) AND (current mode is U, or current mode is S with
    // SIE=1); otherwise it goes to M if enabled in mie (and, in
    // M-mode, if MIE=1). Delegated codes are remapped for S:
    // external 11 -> 9, timer 7 -> 5. An interrupt is taken only
    // at an instruction boundary: the EX instruction still
    // commits to MEM this cycle, and the saved pc is the next
    // not-yet-executed instruction: the EX redirect target if
    // EX redirects this cycle (branch/JALR/mret/sret), else the
    // ID instruction's pc if ID holds one, else the current
    // fetch address (pc). It is NOT taken while a trap or halt
    // commits in EX, nor mid-division (div_stall), nor during a
    // page-table walk or its start cycle: a pending interrupt
    // waits out the whole 32-cycle division and the whole walk
    // and is taken when the division/walk completes.
    // Phase 4 fix: the S take terms must ALSO require the source
    // to be pending (irq_ext / irq_timer), exactly as the M take
    // terms already do. Without this, merely enabling an S
    // interrupt (sie bit + SIE) took a phantom interrupt that
    // retakes on every sret, starving the interrupted code --
    // found by the Phase 4 OS boot (no Phase 2/3 test enables an
    // S interrupt, so the bug was latent until now).
    wire int_ext_s_take = irq_ext && (priv != 2'd3) &&
                          csr_mideleg[11] && csr_sie[9] &&
                          ((priv == 2'd0) || csr_sstatus[1]);
    wire int_tim_s_take = irq_timer && (priv != 2'd3) &&
                          csr_mideleg[7] && csr_sie[5] &&
                          ((priv == 2'd0) || csr_sstatus[1]);
    wire int_ext_m_take = irq_ext && csr_mie[11] &&
                          ((priv == 2'd3) ? csr_mstatus[3] : 1'b1) &&
                          !int_ext_s_take;
    wire int_tim_m_take = irq_timer && csr_mie[7] &&
                          ((priv == 2'd3) ? csr_mstatus[3] : 1'b1) &&
                          !int_tim_s_take;
    wire int_take_ext = int_ext_s_take || int_ext_m_take;
    wire int_take_tim = int_tim_s_take || int_tim_m_take;
    wire int_to_s = int_take_ext ? int_ext_s_take : int_tim_s_take;
    wire [31:0] int_code = int_to_s ?
                           (int_take_ext ? 32'd9 : 32'd5) :
                           (int_take_ext ? 32'd11 : 32'd7);
    wire [31:0] mtvec_base = {csr_mtvec[31:2], 2'b00};
    wire [31:0] int_vec_base = int_to_s ? {csr_stvec[31:2], 2'b00}
                                        : mtvec_base;
    wire [1:0] int_vec_mode = int_to_s ? csr_stvec[1:0]
                                       : csr_mtvec[1:0];
    wire [31:0] int_vector = (int_vec_mode == 2'b01) ?
                             (int_vec_base + (int_code << 2)) :
                             int_vec_base;
    wire [31:0] int_mepc = ex_redirect ? ex_target :
                          (if_id_valid ? if_id_pc : pc);
    wire int_take = !halted && (int_take_ext || int_take_tim) &&
                    !ex_trap && !ex_halt && !div_stall &&
                    !ptw_active && !ptw_start;

    // ================= Hazard detection ==============================
    wire load_stall = ex_is_load && (id_ex_rd != 5'd0) &&
                      ((id_rs1 == id_ex_rd) || (id_rs2 == id_ex_rd));
    wire csr_stall = id_is_system && (ex_csr_write || ex_mem_csr_write);
    // Phase 3: a satp stall freezes IF/ID like a CSR stall, and
    // a page-table walk (or its start cycle) freezes the whole
    // front of the pipeline like the divider does.
    wire pipe_stall = div_stall || load_stall || csr_stall ||
                      satp_stall || ptw_active || ptw_start;

    // ================= Sequential: PC ================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc <= 32'b0;
        else if (!halted) begin
            if (int_take)
                pc <= int_vector;
            else if (ex_redirect)
                pc <= ex_target;
            // Phase 3 satp flush: the instruction after a satp
            // write is refetched only after the write commits
            // (satp_stall holds pc at this target meanwhile).
            else if (ex_satp_write)
                pc <= id_ex_pc + 32'd4;
            else if (pipe_stall)
                pc <= pc;
            else if (id_is_jal)
                pc <= id_jal_target;
            else
                pc <= pc + 32'd4;
        end
    end

    // ================= Sequential: IF/ID =============================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_instr <= 32'b0;
            if_id_pc <= 32'b0;
            if_id_valid <= 1'b0;
            if_id_fetch_fault <= 1'b0;
        end else if (!halted) begin
            if (int_take || ex_redirect || ex_satp_write) begin
                if_id_instr <= 32'b0;
                if_id_pc <= 32'b0;
                if_id_valid <= 1'b0;
                if_id_fetch_fault <= 1'b0;
            end else if (pipe_stall) begin
                // hold (validity and fault flag unchanged)
            end else if (id_is_jal) begin
                if_id_instr <= 32'b0;
                if_id_pc <= 32'b0;
                if_id_valid <= 1'b0;
                if_id_fetch_fault <= 1'b0;
            end else if (fetch_fault_pending &&
                         (fetch_fault_pc == pc)) begin
                // Phase 3: the fetched word is garbage (the
                // walk faulted); capture a fault marker instead.
                // Its pc is the faulting virtual address, which
                // the EX trap reports as mepc/sepc and tval.
                // The PTW block clears fetch_fault_pending on
                // this same edge (same capture condition).
                if_id_instr <= 32'b0;
                if_id_pc <= pc;
                if_id_valid <= 1'b1;
                if_id_fetch_fault <= 1'b1;
            end else begin
                if_id_instr <= instr_i;
                if_id_pc <= pc;
                if_id_valid <= 1'b1;
                if_id_fetch_fault <= 1'b0;
            end
        end
    end

    // ================= Sequential: ID/EX =============================
    reg [4:0] id_ex_amo_f5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_fetch_fault <= 1'b0;
            id_ex_pc <= 32'b0;
            id_ex_opcode <= 7'b0;
            id_ex_rd <= 5'b0;
            id_ex_rs1 <= 5'b0;
            id_ex_rs2 <= 5'b0;
            id_ex_funct3 <= 3'b0;
            id_ex_funct7 <= 7'b0;
            id_ex_imm_i <= 32'b0;
            id_ex_imm_s <= 32'b0;
            id_ex_imm_b <= 32'b0;
            id_ex_imm_u <= 32'b0;
            id_ex_imm_j <= 32'b0;
            id_ex_csr_addr <= 12'b0;
            id_ex_amo_f5 <= 5'b0;
        end else if (!halted) begin
            if (int_take || ex_redirect) begin
                id_ex_fetch_fault <= 1'b0;
                id_ex_pc <= 32'b0;
                id_ex_opcode <= 7'b0;
                id_ex_rd <= 5'b0;
                id_ex_rs1 <= 5'b0;
                id_ex_rs2 <= 5'b0;
                id_ex_funct3 <= 3'b0;
                id_ex_funct7 <= 7'b0;
                id_ex_imm_i <= 32'b0;
                id_ex_imm_s <= 32'b0;
                id_ex_imm_b <= 32'b0;
                id_ex_imm_u <= 32'b0;
                id_ex_imm_j <= 32'b0;
                id_ex_csr_addr <= 12'b0;
                id_ex_amo_f5 <= 5'b0;
            end else if (div_stall || ptw_active || ptw_start) begin
                // hold: divider / page-walk instruction stays in EX
            end else if (load_stall || csr_stall || satp_stall) begin
                id_ex_fetch_fault <= 1'b0;
                id_ex_pc <= 32'b0;
                id_ex_opcode <= 7'b0;
                id_ex_rd <= 5'b0;
                id_ex_rs1 <= 5'b0;
                id_ex_rs2 <= 5'b0;
                id_ex_funct3 <= 3'b0;
                id_ex_funct7 <= 7'b0;
                id_ex_imm_i <= 32'b0;
                id_ex_imm_s <= 32'b0;
                id_ex_imm_b <= 32'b0;
                id_ex_imm_u <= 32'b0;
                id_ex_imm_j <= 32'b0;
                id_ex_csr_addr <= 12'b0;
                id_ex_amo_f5 <= 5'b0;
            end else begin
                id_ex_fetch_fault <= if_id_fetch_fault;
                id_ex_pc <= if_id_pc;
                id_ex_opcode <= if_id_instr[6:0];
                id_ex_rd <= if_id_instr[11:7];
                id_ex_rs1 <= if_id_instr[19:15];
                id_ex_rs2 <= if_id_instr[24:20];
                id_ex_funct3 <= if_id_instr[14:12];
                id_ex_funct7 <= if_id_instr[31:25];
                id_ex_imm_i <= {{20{if_id_instr[31]}}, if_id_instr[31:20]};
                id_ex_imm_s <= {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
                id_ex_imm_b <= {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7],
                                if_id_instr[30:25], if_id_instr[11:8], 1'b0};
                id_ex_imm_u <= {if_id_instr[31:12], 12'b0};
                id_ex_imm_j <= {{11{if_id_instr[31]}}, if_id_instr[31], if_id_instr[19:12],
                                if_id_instr[20], if_id_instr[30:21], 1'b0};
                id_ex_csr_addr <= if_id_instr[31:20];
                id_ex_amo_f5 <= if_id_instr[31:27];
            end
        end
    end
    wire [4:0] ex_amo_f5 = id_ex_amo_f5;

    // ================= Sequential: EX/MEM ============================
    // NOTE (halt drain): this block is NOT frozen by halted. After
    // the halting ECALL/EBREAK flushes IF/ID/EX to bubbles, the
    // older instructions still in MEM/WB must drain: EX/MEM keeps
    // advancing (bubbles, since ID/EX is frozen on bubbles) and
    // MEM/WB below keeps advancing, so the state block can commit
    // them. Freezing here was the first pipe bug found: the
    // instruction immediately before ECALL lost its writeback.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_pc <= 32'b0;
            ex_mem_rd <= 5'b0;
            ex_mem_funct3 <= 3'b0;
            ex_mem_result <= 32'b0;
            ex_mem_rs2 <= 32'b0;
            ex_mem_addr <= 32'b0;
            ex_mem_reg_write <= 1'b0;
            ex_mem_is_load <= 1'b0;
            ex_mem_is_store <= 1'b0;
            ex_mem_is_amo <= 1'b0;
            ex_mem_is_sc <= 1'b0;
            ex_mem_is_lr <= 1'b0;
            ex_mem_amo_funct5 <= 5'b0;
            ex_mem_csr_write <= 1'b0;
            ex_mem_csr_addr <= 12'b0;
            ex_mem_csr_new <= 32'b0;
        end else begin
            // Phase 3: a trapping instruction never reaches MEM
            // (this is what stops an illegal CSR instruction from
            // writing rd or the CSR in WB), and a page-walk cycle
            // (or its start cycle) bubbles EX/MEM so MEM drains.
            if (div_stall || ex_trap || ptw_active || ptw_start) begin
                ex_mem_pc <= 32'b0;
                ex_mem_rd <= 5'b0;
                ex_mem_funct3 <= 3'b0;
                ex_mem_result <= 32'b0;
                ex_mem_rs2 <= 32'b0;
                ex_mem_addr <= 32'b0;
                ex_mem_reg_write <= 1'b0;
                ex_mem_is_load <= 1'b0;
                ex_mem_is_store <= 1'b0;
                ex_mem_is_amo <= 1'b0;
                ex_mem_is_sc <= 1'b0;
                ex_mem_is_lr <= 1'b0;
                ex_mem_amo_funct5 <= 5'b0;
                ex_mem_csr_write <= 1'b0;
                ex_mem_csr_addr <= 12'b0;
                ex_mem_csr_new <= 32'b0;
            end else begin
                ex_mem_pc <= id_ex_pc;
                ex_mem_rd <= id_ex_rd;
                ex_mem_funct3 <= id_ex_funct3;
                ex_mem_result <= ex_result;
                ex_mem_rs2 <= ex_rs2_fwd;
                ex_mem_addr <= ex_mem_addr_comb;
                ex_mem_reg_write <= ex_reg_write;
                ex_mem_is_load <= ex_is_load;
                ex_mem_is_store <= ex_is_store;
                ex_mem_is_amo <= ex_is_amo;
                ex_mem_is_sc <= ex_is_amo && (ex_amo_f5 == 5'b00011);
                ex_mem_is_lr <= ex_is_amo && (ex_amo_f5 == 5'b00010);
                ex_mem_amo_funct5 <= ex_amo_f5;
                ex_mem_csr_write <= ex_csr_write;
                ex_mem_csr_addr <= id_ex_csr_addr;
                ex_mem_csr_new <= ex_csr_new;
            end
        end
    end

    // ================= Sequential: MEM/WB ============================
    // Not frozen by halted either (see the EX/MEM note): this is
    // what lets the pre-ECALL instructions commit during drain.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_rd <= 5'b0;
            mem_wb_data <= 32'b0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_csr_write <= 1'b0;
            mem_wb_csr_addr <= 12'b0;
            mem_wb_csr_new <= 32'b0;
        end else begin
            mem_wb_rd <= ex_mem_rd;
            mem_wb_data <= mem_result;
            mem_wb_reg_write <= ex_mem_reg_write;
            mem_wb_csr_write <= ex_mem_csr_write;
            mem_wb_csr_addr <= ex_mem_csr_addr;
            mem_wb_csr_new <= ex_mem_csr_new;
        end
    end

    // ================= Sequential: page-table walker ==================
    // Walk latency (translation on, 4 KB pages): 1 start cycle
    // (pipeline already frozen) + 1 DRAIN cycle + 1 LEVEL1 cycle
    // + 1 LEVEL0 cycle = 4 cycles before the access proceeds, or
    // 3 cycles for a level-1 leaf (superpage, no LEVEL0 cycle).
    // A fetch walk's result is the cached fetch_pa; a data
    // walk's result is ptw_data_pa/ptw_data_done for the EX
    // instruction, cleared when that instruction advances to MEM.
    // Faults: fetch -> fetch_fault_pending (marker, above);
    // data -> ptw_data_fault + cause (EX trap, above).
    // Non-coincidence note: a redirect cannot be true during a
    // walk (fetch walks are gated on !ex_redirect at start and
    // the EX instruction is then held with stable operands, and
    // data walks are for loads/stores, which never redirect),
    // so a flush-clear and a walk-fault-set cannot land in the
    // same cycle; the case statement below would win if they did.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptw_state <= 3'd0;
            ptw_is_fetch <= 1'b0;
            ptw_is_store <= 1'b0;
            ptw_va <= 32'b0;
            ptw_root_base <= 32'b0;
            ptw_pte1 <= 32'b0;
            ptw_data_pa <= 32'b0;
            ptw_data_done <= 1'b0;
            ptw_data_fault <= 1'b0;
            ptw_data_fault_cause <= 32'b0;
            fetch_pa <= 32'b0;
            fetch_pa_pc <= 32'b0;
            fetch_pa_valid <= 1'b0;
            fetch_fault_pending <= 1'b0;
            fetch_fault_pc <= 32'b0;
        end else begin
            // A satp write committing in WB invalidates the
            // cached fetch translation (same pc, new tables).
            if (mem_wb_csr_write && (mem_wb_csr_addr == 12'h180))
                fetch_pa_valid <= 1'b0;
            // The data translation is consumed when the EX
            // instruction advances to MEM (which happens exactly
            // when nothing stalls/bubbles EX/MEM).
            if (ptw_data_done && !div_stall && !ex_trap &&
                !ptw_active && !ptw_start)
                ptw_data_done <= 1'b0;
            // A data fault is consumed by the EX trap it causes.
            if (ex_trap && ptw_data_fault)
                ptw_data_fault <= 1'b0;
            // A pending fetch fault is dropped if the fetch is
            // flushed before it is captured (redirect, interrupt,
            // or satp flush), or consumed when the marker is
            // captured into IF/ID (same condition as the IF/ID
            // marker branch: not flushed, not stalled, not JAL).
            if (ex_redirect || int_take || ex_satp_write)
                fetch_fault_pending <= 1'b0;
            else if (fetch_fault_pending && (fetch_fault_pc == pc) &&
                     !halted && !pipe_stall && !id_is_jal)
                fetch_fault_pending <= 1'b0;
            case (ptw_state)
                3'd0: begin
                    if (ptw_start_data) begin
                        ptw_state <= 3'd1;
                        ptw_is_fetch <= 1'b0;
                        ptw_is_store <= ex_is_store || ex_is_amo;
                        ptw_va <= ex_mem_addr_comb;
                        ptw_root_base <= {csr_satp[19:0], 12'b0};
                    end else if (ptw_start_fetch) begin
                        ptw_state <= 3'd1;
                        ptw_is_fetch <= 1'b1;
                        ptw_is_store <= 1'b0;
                        ptw_va <= pc;
                        ptw_root_base <= {csr_satp[19:0], 12'b0};
                        fetch_pa_valid <= 1'b0;
                    end
                end
                3'd1: begin
                    ptw_state <= 3'd2;
                end
                3'd2: begin
                    if (!ptw_pte_now[0]) begin
                        if (ptw_is_fetch) begin
                            fetch_fault_pending <= 1'b1;
                            fetch_fault_pc <= ptw_va;
                        end else begin
                            ptw_data_fault <= 1'b1;
                            ptw_data_fault_cause <= ptw_is_store ?
                                                    32'd15 : 32'd13;
                        end
                        ptw_state <= 3'd0;
                    end else if (ptw_leaf_now) begin
                        if (ptw_perm_fault_now ||
                            (ptw_pte_now[19:10] != 10'b0)) begin
                            if (ptw_is_fetch) begin
                                fetch_fault_pending <= 1'b1;
                                fetch_fault_pc <= ptw_va;
                            end else begin
                                ptw_data_fault <= 1'b1;
                                ptw_data_fault_cause <= ptw_is_store ?
                                                        32'd15 : 32'd13;
                            end
                            ptw_state <= 3'd0;
                        end else begin
                            if (ptw_is_fetch) begin
                                fetch_pa <= {ptw_pte_now[29:20],
                                             ptw_va[21:0]};
                                fetch_pa_pc <= ptw_va;
                                fetch_pa_valid <= 1'b1;
                            end else begin
                                ptw_data_pa <= {ptw_pte_now[29:20],
                                                ptw_va[21:0]};
                                ptw_data_done <= 1'b1;
                            end
                            ptw_state <= 3'd0;
                        end
                    end else begin
                        ptw_pte1 <= ptw_pte_now;
                        ptw_state <= 3'd3;
                    end
                end
                3'd3: begin
                    if (!ptw_pte_now[0] || !ptw_leaf_now) begin
                        if (ptw_is_fetch) begin
                            fetch_fault_pending <= 1'b1;
                            fetch_fault_pc <= ptw_va;
                        end else begin
                            ptw_data_fault <= 1'b1;
                            ptw_data_fault_cause <= ptw_is_store ?
                                                    32'd15 : 32'd13;
                        end
                        ptw_state <= 3'd0;
                    end else if (ptw_perm_fault_now) begin
                        if (ptw_is_fetch) begin
                            fetch_fault_pending <= 1'b1;
                            fetch_fault_pc <= ptw_va;
                        end else begin
                            ptw_data_fault <= 1'b1;
                            ptw_data_fault_cause <= ptw_is_store ?
                                                    32'd15 : 32'd13;
                        end
                        ptw_state <= 3'd0;
                    end else begin
                        if (ptw_is_fetch) begin
                            fetch_pa <= {ptw_pte_now[29:20],
                                         ptw_pte_now[19:10],
                                         ptw_va[11:0]};
                            fetch_pa_pc <= ptw_va;
                            fetch_pa_valid <= 1'b1;
                        end else begin
                            ptw_data_pa <= {ptw_pte_now[29:20],
                                            ptw_pte_now[19:10],
                                            ptw_va[11:0]};
                            ptw_data_done <= 1'b1;
                        end
                        ptw_state <= 3'd0;
                    end
                end
                default: begin
                    ptw_state <= 3'd0;
                end
            endcase
        end
    end

    // ================= Sequential: architectural state ===============
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            halted <= 1'b0;
            uart_tx <= 8'b0;
            uart_tx_valid <= 1'b0;
            reservation_valid <= 1'b0;
            reservation_addr <= 32'b0;
            csr_mstatus <= 32'b0;
            csr_mtvec <= 32'b0;
            csr_mscratch <= 32'b0;
            csr_mepc <= 32'b0;
            csr_mcause <= 32'b0;
            csr_mtval <= 32'b0;
            csr_mie <= 32'b0;
            csr_sstatus <= 32'b0;
            csr_sie <= 32'b0;
            csr_stvec <= 32'b0;
            csr_sscratch <= 32'b0;
            csr_sepc <= 32'b0;
            csr_scause <= 32'b0;
            csr_stval <= 32'b0;
            csr_satp <= 32'b0;
            csr_medeleg <= 32'b0;
            csr_mideleg <= 32'b0;
            priv <= 2'd3;
            div_busy <= 1'b0;
            div_cnt <= 6'b0;
            div_rem <= 32'b0;
            div_quot <= 32'b0;
            div_divisor <= 32'b0;
            div_dividend <= 32'b0;
            div_signed_r <= 1'b0;
            div_is_rem_r <= 1'b0;
            div_neg_q_r <= 1'b0;
            div_neg_r_r <= 1'b0;
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else begin
            // No halted freeze here either: after halt, IF/ID/EX
            // are frozen on bubbles (see the PC/IF/ID/ID-EX
            // blocks), so running this block only commits the
            // draining MEM/WB instructions and then idles on
            // bubbles. The UART default clear below also kills
            // any pulse left over from the halt cycle, so the
            // testbench's negedge sampler cannot re-print it.
            uart_tx_valid <= 1'b0;
            // WB register write.
            if (mem_wb_reg_write && (mem_wb_rd != 5'd0))
                regs[mem_wb_rd] <= mem_wb_data;
            // WB CSR write (unimplemented CSRs ignored, as in v7).
            if (mem_wb_csr_write) begin
                case (mem_wb_csr_addr)
                    // Phase 2 masks: mstatus keeps only MPP/MPIE/
                    // MIE; mie keeps only MEIE/MTIE/MSIE.
                    12'h300: csr_mstatus <= {19'b0, mem_wb_csr_new[12:11],
                                             3'b0, mem_wb_csr_new[7],
                                             3'b0, mem_wb_csr_new[3], 3'b0};
                    12'h304: csr_mie <= {20'b0, mem_wb_csr_new[11],
                                         3'b0, mem_wb_csr_new[7],
                                         3'b0, mem_wb_csr_new[3], 3'b0};
                    12'h305: csr_mtvec <= mem_wb_csr_new;
                    12'h340: csr_mscratch <= mem_wb_csr_new;
                    12'h341: csr_mepc <= mem_wb_csr_new;
                    12'h342: csr_mcause <= mem_wb_csr_new;
                    12'h343: csr_mtval <= mem_wb_csr_new;
                    // Phase 3 masks: sstatus keeps only MXR(19),
                    // SUM(18), SPP(8), SPIE(5), SIE(1); sie keeps
                    // only SEIE(9)/STIE(5)/SSIE(1); medeleg keeps
                    // only delegatable exception bits (0-9, 11,
                    // 12, 13, 15 = 0xBBFF); mideleg keeps only
                    // the machine interrupt bits 11/7/3 (0x888).
                    // sstatus is a SEPARATE register, not a masked
                    // view of mstatus (documented deviation: the
                    // SIE/SPIE/SPP bits in mstatus read 0).
                    12'h100: csr_sstatus <= {12'b0, mem_wb_csr_new[19],
                                             mem_wb_csr_new[18], 9'b0,
                                             mem_wb_csr_new[8], 2'b0,
                                             mem_wb_csr_new[5], 3'b0,
                                             mem_wb_csr_new[1], 1'b0};
                    12'h104: csr_sie <= {22'b0, mem_wb_csr_new[9],
                                         3'b0, mem_wb_csr_new[5],
                                         3'b0, mem_wb_csr_new[1], 1'b0};
                    12'h105: csr_stvec <= mem_wb_csr_new;
                    12'h140: csr_sscratch <= mem_wb_csr_new;
                    12'h141: csr_sepc <= mem_wb_csr_new;
                    12'h142: csr_scause <= mem_wb_csr_new;
                    12'h143: csr_stval <= mem_wb_csr_new;
                    12'h180: csr_satp <= mem_wb_csr_new;
                    12'h302: csr_medeleg <= mem_wb_csr_new &
                                            32'h0000BBFF;
                    12'h303: csr_mideleg <= mem_wb_csr_new &
                                            32'h00000888;
                    default: begin end
                endcase
            end
            // mret (EX, valid only in M): MIE=MPIE, MPIE=1,
            // MPP=0 (least-privileged supported mode, U),
            // privilege follows old MPP. An mret in a lower mode
            // is an illegal trap instead (ex_is_mret_valid is
            // false there), so this block does not fire for it.
            // Placed before trap/interrupt writes; an interrupt
            // taken in the same cycle as an mret/sret (see below)
            // overwrites these with entry values computed from
            // the post-return state.
            if (ex_is_mret_valid) begin
                csr_mstatus <= {19'b0, 2'b00, 3'b0, 1'b1, 3'b0,
                                csr_mstatus[7], 3'b0};
                priv <= csr_mstatus[12:11];
            end
            // sret (EX, valid in M/S, illegal in U): SIE=SPIE,
            // SPIE=1, SPP=0 (U), privilege follows SPP (SPP=1
            // means S, 0 means U). sstatus bits other than
            // SIE/SPIE/SPP (SUM/MXR) are preserved via the mask.
            if (ex_is_sret_valid) begin
                csr_sstatus <= (csr_sstatus & ~32'h00000122) |
                               32'h00000020 |
                               (csr_sstatus[5] ? 32'h00000002 : 32'b0);
                priv <= csr_sstatus[8] ? 2'd1 : 2'd0;
            end
            // EX trap writes. Placed after the WB CSR write, so a
            // trap wins if both ever target the same CSR in one
            // cycle; the CSR stall rule makes that unreachable
            // for SYSTEM traps (a trap in EX implies no CSR write
            // pending in MEM), and the EX/MEM bubble on ex_trap
            // stops a trapping CSR instruction from writing in WB.
            // Delegated traps go to S: sepc/scause/stval, S entry
            // rules (SPIE=SIE, SIE=0, SPP=priv, priv=S). Other
            // traps go to M: MPIE=old MIE, MIE=0, MPP=old priv.
            if (ex_trap) begin
                if (ex_trap_to_s) begin
                    csr_sepc <= id_ex_pc;
                    csr_scause <= ex_trap_cause;
                    csr_stval <= ex_trap_tval;
                    csr_sstatus <= (csr_sstatus & ~32'h00000122) |
                                   (csr_sstatus[1] ? 32'h00000020 : 32'b0) |
                                   ((priv == 2'd1) ? 32'h00000100 : 32'b0);
                    priv <= 2'd1;
                end else begin
                    csr_mepc <= id_ex_pc;
                    csr_mcause <= ex_trap_cause;
                    csr_mtval <= ex_trap_tval;
                    csr_mstatus <= {19'b0, priv, 3'b0, csr_mstatus[3],
                                    3'b0, 1'b0, 3'b0};
                    priv <= 2'd3;
                end
            end
            // Interrupt entry (EX-boundary, see int_take).
            // To S: sepc = next not-yet-executed instruction,
            // scause = interrupt bit + remapped code (9/5),
            // stval = 0, SPIE=SIE, SIE=0, SPP=priv, priv=S.
            // To M: mepc/mcause (11/7)/mtval=0, MPIE=old MIE,
            // MIE=0, MPP=priv, priv=M. Placed last so it wins
            // over a same-cycle mret/sret update; when the
            // interrupt coincides with a return, the entry
            // values are computed from the post-return state:
            // after an mret, the interrupted privilege is old
            // MPP and MPIE is old MPIE; after an sret, the
            // interrupted privilege is old SPP, SIE-after-sret
            // is old SPIE, and MIE is unchanged by sret.
            if (int_take) begin
                if (int_to_s) begin
                    csr_sepc <= int_mepc;
                    csr_scause <= 32'h80000000 | int_code;
                    csr_stval <= 32'b0;
                    if (ex_is_mret_valid)
                        csr_sstatus <= (csr_sstatus & ~32'h00000122) |
                                       (csr_sstatus[1] ? 32'h00000020 : 32'b0) |
                                       ((csr_mstatus[12:11] == 2'd1) ? 32'h00000100 : 32'b0);
                    else if (ex_is_sret_valid)
                        csr_sstatus <= (csr_sstatus & ~32'h00000122) |
                                       (csr_sstatus[5] ? 32'h00000020 : 32'b0) |
                                       (csr_sstatus[8] ? 32'h00000100 : 32'b0);
                    else
                        csr_sstatus <= (csr_sstatus & ~32'h00000122) |
                                       (csr_sstatus[1] ? 32'h00000020 : 32'b0) |
                                       ((priv == 2'd1) ? 32'h00000100 : 32'b0);
                    priv <= 2'd1;
                end else begin
                    csr_mepc <= int_mepc;
                    csr_mcause <= 32'h80000000 | int_code;
                    csr_mtval <= 32'b0;
                    if (ex_is_mret_valid)
                        csr_mstatus <= {19'b0, csr_mstatus[12:11], 3'b0,
                                        csr_mstatus[7], 3'b0, 1'b0, 3'b0};
                    else if (ex_is_sret_valid)
                        csr_mstatus <= {19'b0, csr_sstatus[8] ? 2'd1 : 2'd0,
                                        3'b0, csr_mstatus[3],
                                        3'b0, 1'b0, 3'b0};
                    else
                        csr_mstatus <= {19'b0, priv, 3'b0, csr_mstatus[3],
                                        3'b0, 1'b0, 3'b0};
                    priv <= 2'd3;
                end
            end
            if (ex_halt)
                halted <= 1'b1;
            // MEM store effects: UART pulse, reservation clear.
            if (ex_mem_is_store) begin
                if (mem_addr == 32'h10000000) begin
                    uart_tx <= ex_mem_rs2[7:0];
                    uart_tx_valid <= 1'b1;
                end else if ((mem_addr != 32'h10000004) &&
                             (mem_addr != 32'h10000008)) begin
                    if (mem_addr == reservation_addr)
                        reservation_valid <= 1'b0;
                end
            end
            // MEM AMO effects: reservation only (the memory write
            // itself happens in the top, on d_we_o).
            if (ex_mem_is_amo) begin
                if (ex_mem_is_lr) begin
                    reservation_valid <= 1'b1;
                    reservation_addr <= mem_addr;
                end else if (ex_mem_is_sc) begin
                    reservation_valid <= 1'b0;
                end else begin
                    if (mem_addr == reservation_addr)
                        reservation_valid <= 1'b0;
                end
            end
            // Divider state machine.
            if (ex_is_div && !div_ready) begin
                if (!div_busy) begin
                    div_busy <= 1'b1;
                    div_cnt <= 6'd1;
                    div_rem <= div_start_rem;
                    div_quot <= div_start_quot;
                    div_divisor <= div_abs_b;
                    div_dividend <= div_abs_a;
                    div_signed_r <= div_signed;
                    div_is_rem_r <= div_is_rem;
                    div_neg_q_r <= div_neg_q;
                    div_neg_r_r <= div_neg_r;
                end else begin
                    div_rem <= div_iter_rem;
                    div_quot <= div_iter_quot;
                    div_cnt <= div_cnt + 6'd1;
                end
            end else if (ex_is_div && div_ready) begin
                div_busy <= 1'b0;
            end
        end
    end
endmodule
