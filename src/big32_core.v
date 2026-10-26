// big32_core — the big32 CPU core alone, no internal memories (v7).
// ---------------------------------------------------------------------------
// Ibex-style split: this module is pure core logic (register file,
// ALU, CSRs, traps, UART pulse outputs). It contains NO instruction
// or data memory arrays, so Yosys can synthesise it without turning
// 80KB of memory into registers. Memories live in the simulation
// top (src/big32.v), which instantiates this core and wires its
// memory ports to byte arrays.
// Memory interface (single-cycle, combinational read, clocked write):
//   instr_i   : instruction word fetched at if_addr_o (input)
//   if_addr_o : current PC, byte address (output)
//   d_addr_o  : data address: load -> rs1+imm_i, store -> rs1+imm_s,
//               AMO -> rs1, otherwise rs1 (don't care) (output)
//   d_rdata_i : 32-bit word read at d_addr_o, little-endian bytes
//               at d_addr_o..d_addr_o+3 (input). The top must supply
//               this combinationally from its byte memory, with
//               per-byte modulo wrapping (see big32.v).
//   d_wdata_o : data to write (store: rs2; AMO: computed amo_new)
//   d_wmask_o : 4-bit RELATIVE byte mask: bit i means "write byte i
//               of d_wdata_o to d_addr_o+i". SB=0001, SH=0011,
//               SW/AMO=1111. This is relative, not an absolute word
//               lane mask, so unaligned accesses behave exactly as
//               in v6 (bytes land at addr..addr+3, wrapping per byte).
//   d_we_o    : write enable (store to real memory, or AMO write).
//               Stores to UART MMIO addresses never assert d_we_o;
//               AMO writes assert it even at MMIO addresses, exactly
//               as v6's store_word did (AMO bypassed the MMIO check).
// Semantic changes vs v6: NONE for the tested behaviour. Unaligned
// loads/stores, AMO, UART MMIO, reservation clearing and trap
// handling are identical; only the location of the memory arrays
// moved. The one interface caveat: a real SRAM/AXI wrapper must
// translate the relative mask into absolute lanes for unaligned
// addresses, or restrict itself to aligned accesses (then the
// relative mask equals the absolute lane mask).
// What it has:
//   - 32 registers x0..x31 (x0 hardwired to 0), 32-bit PC, single-cycle:
//     fetch, decode, execute, memory, writeback all in one clock.
//   - RV32I base integer instructions: R, I, S, B, U, J formats.
//   - RV32M: mul, mulh, mulhsu, mulhu, div, divu, rem, remu.
//   - RV32A (word only): lr.w, sc.w, amoadd/add, swap, xor, or, and,
//     min, max, minu, maxu. Single core, so atomics are a
//     read-modify-write in one cycle, with an LR/SC reservation.
//   - M-mode CSRs: mstatus, mtvec, mscratch, mepc, mcause, mtval,
//     mhartid (read-only 0). CSR instructions csrrw/csrrs/csrrc and
//     their immediate forms, plus mret.
//   - Traps: ECALL/EBREAK trap to mtvec (mcause 11/3) when mtvec is
//     non-zero, and halt when mtvec is zero — so plain test programs
//     that end with ECALL still halt, while a kernel that sets mtvec
//     gets control on every ECALL.
//   - UART MMIO: store a byte to 0x10000000 to transmit it; loads from
//     0x10000004 (RX) return -1 (no input in this core), loads from
//     0x10000008 (status) return 0.
//   - Harvard memory for now: 16KB instruction memory (4096 words) and
//     64KB byte-addressable data memory. PC is a byte address; the
//     instruction index is PC[13:2], so programs live at 0..16383.
//     Data addresses are taken modulo DMEM_DEPTH (default 64KB).
//   - Privilege in v3 is M-mode only: there is no S/U mode yet, and
//     no MMU. Linux needs S-mode + Sv32, which is the next big step.
// ---------------------------------------------------------------------------
`default_nettype none

module big32_core (
    input  wire        clk,
    input  wire        rst_n,
    output reg         halted,
    output reg  [7:0]  uart_tx,
    output reg         uart_tx_valid,
    // Memory ports (see header comment for the interface contract).
    input  wire [31:0] instr_i,
    output wire [31:0] if_addr_o,
    output wire [31:0] d_addr_o,
    input  wire [31:0] d_rdata_i,
    output wire [31:0] d_wdata_o,
    output wire [3:0]  d_wmask_o,
    output wire        d_we_o
);
    reg [31:0] pc;
    reg [31:0] regs [0:31];
    // Sparse CSR file (v4): only implemented CSRs exist as registers.
    // mstatus, mtvec, mscratch, mepc, mcause, mtval. mhartid reads 0
    // and is not stored. Everything else reads 0, writes are ignored.
    reg [31:0] csr_mstatus, csr_mtvec, csr_mscratch;
    reg [31:0] csr_mepc, csr_mcause, csr_mtval;
    reg        reservation_valid;
    reg [31:0] reservation_addr;

    // ---- Fetch ---------------------------------------------------------
    // Instruction comes from the top's memory, at the current PC.
    wire [31:0] instr = instr_i;
    assign if_addr_o = pc;

    // ---- Decode --------------------------------------------------------
    wire [6:0]  opcode = instr[6:0];
    wire [4:0]  rd     = instr[11:7];
    wire [2:0]  funct3 = instr[14:12];
    wire [4:0]  rs1    = instr[19:15];
    wire [4:0]  rs2    = instr[24:20];
    wire [6:0]  funct7 = instr[31:25];

    wire [31:0] rs1_val = regs[rs1];
    wire [31:0] rs2_val = regs[rs2];
    // Signed views, used for arithmetic shifts (v4 fix: Icarus
    // Verilog turned $signed(rs1_val) >>> shift inside a ternary
    // into a logical shift, so SRAI gave 32767 instead of -1 for
    // srai -56, 17. A signed wire shifts arithmetically, reliably.)
    wire signed [31:0] s_rs1 = rs1_val;
    wire signed [31:0] s_rs2 = rs2_val;

    // ---- System / CSR decode -------------------------------------------
    wire [11:0] csr_addr = instr[31:20];
    reg  [31:0] csr_old;
    always @* begin
        case (csr_addr)
            12'h300: csr_old = csr_mstatus;
            12'h305: csr_old = csr_mtvec;
            12'h340: csr_old = csr_mscratch;
            12'h341: csr_old = csr_mepc;
            12'h342: csr_old = csr_mcause;
            12'h343: csr_old = csr_mtval;
            default: csr_old = 32'b0; // mhartid and unimplemented CSRs
        endcase
    end
    wire [31:0] mtvec_val = csr_mtvec;
    wire [31:0] mepc_val  = csr_mepc;
    wire is_system = (opcode == 7'b1110011);
    wire is_csr    = is_system && (funct3 != 3'b000);
    wire is_mret   = is_system && (funct3 == 3'b000) && (csr_addr == 12'h302);
    wire is_ecall  = is_system && (funct3 == 3'b000) && (csr_addr == 12'h000);
    wire is_ebreak = is_system && (funct3 == 3'b000) && (csr_addr == 12'h001);
    wire trap_ecall  = is_ecall  && (mtvec_val != 32'b0);
    wire trap_ebreak = is_ebreak && (mtvec_val != 32'b0);
    wire [4:0]  csr_uimm = rs1; // for csrrwi/csrrsi/csrrci
    reg  [31:0] csr_new;
    reg         csr_write;
    always @* begin
        csr_new = 32'b0;
        csr_write = 1'b0;
        if (is_csr && (csr_addr != 12'hF14)) begin // mhartid is read-only
            case (funct3)
                3'b001: begin csr_new = rs1_val; csr_write = 1'b1; end // csrrw
                3'b010: begin csr_new = csr_old | rs1_val; csr_write = (rs1 != 5'd0); end // csrrs
                3'b011: begin csr_new = csr_old & ~rs1_val; csr_write = (rs1 != 5'd0); end // csrrc
                3'b101: begin csr_new = {27'b0, csr_uimm}; csr_write = 1'b1; end // csrrwi
                3'b110: begin csr_new = csr_old | {27'b0, csr_uimm}; csr_write = (csr_uimm != 5'd0); end // csrrsi
                3'b111: begin csr_new = csr_old & ~{27'b0, csr_uimm}; csr_write = (csr_uimm != 5'd0); end // csrrci
                default: begin csr_new = 32'b0; csr_write = 1'b0; end
            endcase
        end
    end

    // Sign-extended immediates
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7],
                         instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12],
                         instr[20], instr[30:21], 1'b0};

    // ---- ALU -----------------------------------------------------------
    // 64-bit products for the M extension. The 64-bit left-hand side
    // makes Verilog extend the operands to 64 bits before multiplying,
    // so the full product (not just the low 32 bits) is kept.
    wire signed [63:0] mul_ss = $signed(rs1_val) * $signed(rs2_val);
    wire signed [63:0] mul_su = $signed(rs1_val) * $signed({1'b0, rs2_val});
    wire [63:0]        mul_uu = rs1_val * rs2_val;

    reg [31:0] alu_out;
    always @* begin
        alu_out = 32'b0;
        case (opcode)
            7'b0110011: begin // R-type
                case ({funct7, funct3})
                    10'b0000000000: alu_out = rs1_val + rs2_val;          // ADD
                    10'b0100000000: alu_out = rs1_val - rs2_val;          // SUB
                    10'b0000000111: alu_out = rs1_val & rs2_val;          // AND
                    10'b0000000110: alu_out = rs1_val | rs2_val;          // OR
                    10'b0000000100: alu_out = rs1_val ^ rs2_val;          // XOR
                    10'b0000000001: alu_out = rs1_val << rs2_val[4:0];    // SLL
                    10'b0000000101: alu_out = rs1_val >> rs2_val[4:0];    // SRL
                    10'b0100000101: alu_out = s_rs1 >>> rs2_val[4:0]; // SRA
                    10'b0000000010: alu_out = ($signed(rs1_val) < $signed(rs2_val)) ? 32'd1 : 32'd0; // SLT
                    10'b0000000011: alu_out = (rs1_val < rs2_val) ? 32'd1 : 32'd0; // SLTU
                    // M extension (funct7 = 0x01)
                    10'b0000001000: alu_out = mul_ss[31:0];  // MUL
                    10'b0000001001: alu_out = mul_ss[63:32]; // MULH
                    10'b0000001010: alu_out = mul_su[63:32]; // MULHSU
                    10'b0000001011: alu_out = mul_uu[63:32]; // MULHU
                    // NOTE: DIV/REM must NOT use a ternary here. Icarus
                    // Verilog makes a ternary unsigned when any branch
                    // is unsigned, which turned signed division into
                    // unsigned division (e.g. -1 / -41 gave 1 instead
                    // of 0, and -1644167168 / -29 gave 0 instead of
                    // 56695419). if/else keeps the signed operation
                    // signed. DIVU/REMU are unsigned anyway.
                    10'b0000001100: begin // DIV
                        if (rs2_val == 32'b0)
                            alu_out = 32'hFFFFFFFF;
                        else if (rs1_val == 32'h80000000 && rs2_val == 32'hFFFFFFFF)
                            alu_out = 32'h80000000;
                        else
                            alu_out = s_rs1 / s_rs2;
                    end
                    10'b0000001101: alu_out = (rs2_val == 32'b0) ? 32'hFFFFFFFF :
                        (rs1_val / rs2_val); // DIVU
                    10'b0000001110: begin // REM
                        if (rs2_val == 32'b0)
                            alu_out = rs1_val;
                        else if (rs1_val == 32'h80000000 && rs2_val == 32'hFFFFFFFF)
                            alu_out = 32'b0;
                        else
                            alu_out = s_rs1 % s_rs2;
                    end
                    10'b0000001111: alu_out = (rs2_val == 32'b0) ? rs1_val :
                        (rs1_val % rs2_val); // REMU
                    default: alu_out = 32'b0;
                endcase
            end
            7'b0010011: begin // I-type ALU
                case (funct3)
                    3'b000: alu_out = rs1_val + imm_i;                    // ADDI
                    3'b111: alu_out = rs1_val & imm_i;                    // ANDI
                    3'b110: alu_out = rs1_val | imm_i;                    // ORI
                    3'b100: alu_out = rs1_val ^ imm_i;                    // XORI
                    3'b010: alu_out = ($signed(rs1_val) < $signed(imm_i)) ? 32'd1 : 32'd0; // SLTI
                    3'b011: alu_out = (rs1_val < imm_i) ? 32'd1 : 32'd0;   // SLTIU
                    3'b001: alu_out = rs1_val << imm_i[4:0];              // SLLI
                    // NOTE: do NOT write this as a ternary. Icarus
                    // Verilog makes the whole ternary unsigned when
                    // the SRLI branch is unsigned, which turns the
                    // SRAI shift into a logical shift (32767 instead
                    // of -1 for srai -56, 17). if/else keeps the
                    // arithmetic shift arithmetic.
                    3'b101: begin
                        if (funct7 == 7'h20)
                            alu_out = s_rs1 >>> imm_i[4:0]; // SRAI
                        else
                            alu_out = rs1_val >> imm_i[4:0]; // SRLI
                    end
                    default: alu_out = 32'b0;
                endcase
            end
            default: alu_out = 32'b0;
        endcase
    end

    // ---- Memory read (loads) -------------------------------------------
    wire [31:0] mem_addr = rs1_val + imm_i;
    // Load bytes come from the top's combinational read port.
    // d_addr_o (below) points at mem_addr for loads, so these are
    // exactly the bytes v6 read from its internal dmem.
    wire [7:0]  b0 = d_rdata_i[7:0];
    wire [7:0]  b1 = d_rdata_i[15:8];
    wire [7:0]  b2 = d_rdata_i[23:16];
    wire [7:0]  b3 = d_rdata_i[31:24];
    reg [31:0] load_data;
    always @* begin
        if (mem_addr == 32'h10000000) begin
            load_data = 32'b0;                    // UART TX: write-only
        end else if (mem_addr == 32'h10000004) begin
            load_data = 32'hFFFFFFFF;             // UART RX: no input
        end else if (mem_addr == 32'h10000008) begin
            load_data = 32'b0;                    // UART status: RX not ready
        end else begin
            case (funct3)
                3'b000: load_data = {{24{b0[7]}}, b0};              // LB
                3'b001: load_data = {{16{b1[7]}}, b1, b0};          // LH
                3'b010: load_data = {b3, b2, b1, b0};               // LW
                3'b100: load_data = {24'b0, b0};                    // LBU
                3'b101: load_data = {16'b0, b1, b0};                // LHU
                default: load_data = 32'b0;
            endcase
        end
    end

    // ---- A extension: atomic word operations ---------------------------
    // Address is rs1 alone (no immediate). funct5 = instr[31:27].
    wire [4:0] amo_funct5 = instr[31:27];
    // AMO old word is the top's read at rs1 (d_addr_o, below).
    wire [31:0] amo_old = d_rdata_i;
    wire sc_success = reservation_valid && (reservation_addr == rs1_val);
    reg [31:0] amo_new;
    always @* begin
        case (amo_funct5)
            5'b00000: amo_new = amo_old + rs2_val; // amoadd.w
            5'b00001: amo_new = rs2_val;           // amoswap.w
            5'b00100: amo_new = amo_old ^ rs2_val; // amoxor.w
            5'b01000: amo_new = amo_old | rs2_val; // amoor.w
            5'b01100: amo_new = amo_old & rs2_val; // amoand.w
            5'b10000: amo_new = ($signed(amo_old) < $signed(rs2_val)) ? amo_old : rs2_val; // amomin.w
            5'b10100: amo_new = ($signed(amo_old) > $signed(rs2_val)) ? amo_old : rs2_val; // amomax.w
            5'b11000: amo_new = (amo_old < rs2_val) ? amo_old : rs2_val; // amominu.w
            5'b11100: amo_new = (amo_old > rs2_val) ? amo_old : rs2_val; // amomaxu.w
            default: amo_new = amo_old;
        endcase
    end

    // ---- Branch condition ----------------------------------------------
    reg branch_taken;
    always @* begin
        case (funct3)
            3'b000: branch_taken = (rs1_val == rs2_val);                  // BEQ
            3'b001: branch_taken = (rs1_val != rs2_val);                  // BNE
            3'b100: branch_taken = ($signed(rs1_val) < $signed(rs2_val)); // BLT
            3'b101: branch_taken = ($signed(rs1_val) >= $signed(rs2_val)); // BGE
            3'b110: branch_taken = (rs1_val < rs2_val);                   // BLTU
            3'b111: branch_taken = (rs1_val >= rs2_val);                  // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    // ---- Writeback value -------------------------------------------------
    reg [31:0] wb_data;
    reg        reg_write;
    always @* begin
        wb_data = 32'b0;
        reg_write = 1'b0;
        case (opcode)
            7'b0110011, 7'b0010011: begin wb_data = alu_out; reg_write = 1'b1; end
            7'b0000011: begin wb_data = load_data; reg_write = 1'b1; end // LOAD
            7'b1101111: begin wb_data = pc + 32'd4; reg_write = 1'b1; end // JAL
            7'b1100111: begin wb_data = pc + 32'd4; reg_write = 1'b1; end // JALR
            7'b0110111: begin wb_data = imm_u; reg_write = 1'b1; end     // LUI
            7'b0010111: begin wb_data = pc + imm_u; reg_write = 1'b1; end // AUIPC
            7'b0101111: begin // A extension (word only, funct3 = 010)
                if (amo_funct5 == 5'b00011)
                    wb_data = sc_success ? 32'd0 : 32'd1; // sc.w: 0 = success
                else
                    wb_data = amo_old; // lr.w and amo*.w return the old value
                reg_write = 1'b1;
            end
            7'b1110011: begin // CSR instructions return the old CSR value
                if (is_csr) begin wb_data = csr_old; reg_write = 1'b1; end
                else begin wb_data = 32'b0; reg_write = 1'b0; end
            end
            default: begin wb_data = 32'b0; reg_write = 1'b0; end
        endcase
    end

    // ---- Next PC ---------------------------------------------------------
    reg [31:0] pc_next;
    always @* begin
        if (trap_ecall || trap_ebreak)
            pc_next = {mtvec_val[31:2], 2'b00}; // mtvec BASE mode
        else if (is_mret)
            pc_next = mepc_val;
        else begin
            case (opcode)
                7'b1100011: pc_next = branch_taken ? (pc + imm_b) : (pc + 32'd4); // BRANCH
                7'b1101111: pc_next = pc + imm_j;                                 // JAL
                7'b1100111: pc_next = (rs1_val + imm_i) & ~32'd1;                 // JALR
                default: pc_next = pc + 32'd4;
            endcase
        end
    end

    wire [31:0] store_addr = rs1_val + imm_s;

    // ---- Memory ports (combinational) --------------------------------
    // Single data read port, multiplexed by opcode. The top reads
    // combinationally at this address and returns the word on
    // d_rdata_i in the same cycle.
    assign d_addr_o = (opcode == 7'b0000011) ? mem_addr :
                      (opcode == 7'b0100011) ? store_addr : rs1_val;
    reg        d_we_comb;
    reg [31:0] d_wdata_comb;
    reg [3:0]  d_wmask_comb;
    always @* begin
        d_we_comb = 1'b0;
        d_wdata_comb = 32'b0;
        d_wmask_comb = 4'b0;
        if (opcode == 7'b0100011) begin // STORE
            if ((store_addr != 32'h10000000) &&
                (store_addr != 32'h10000004) &&
                (store_addr != 32'h10000008)) begin
                case (funct3)
                    3'b000: begin d_we_comb = 1'b1; d_wdata_comb = rs2_val; d_wmask_comb = 4'b0001; end // SB
                    3'b001: begin d_we_comb = 1'b1; d_wdata_comb = rs2_val; d_wmask_comb = 4'b0011; end // SH
                    3'b010: begin d_we_comb = 1'b1; d_wdata_comb = rs2_val; d_wmask_comb = 4'b1111; end // SW
                    default: begin end // invalid funct3: no write
                endcase
            end
        end else if (opcode == 7'b0101111) begin // A extension
            if (amo_funct5 == 5'b00010) begin
                d_we_comb = 1'b0; // lr.w: read only
            end else if (amo_funct5 == 5'b00011) begin // sc.w
                if (sc_success) begin
                    d_we_comb = 1'b1; d_wdata_comb = rs2_val; d_wmask_comb = 4'b1111;
                end
            end else begin // amo*.w (and invalid funct5, which v6
                            // also wrote back, with amo_new == amo_old)
                d_we_comb = 1'b1; d_wdata_comb = amo_new; d_wmask_comb = 4'b1111;
            end
        end
    end
    assign d_we_o = d_we_comb;
    assign d_wdata_o = d_wdata_comb;
    assign d_wmask_o = d_wmask_comb;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc <= 32'b0;
            halted <= 1'b0;
            uart_tx <= 8'b0;
            uart_tx_valid <= 1'b0;
            reservation_valid <= 1'b0;
            reservation_addr <= 32'b0;
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
            csr_mstatus <= 32'b0;
            csr_mtvec <= 32'b0;
            csr_mscratch <= 32'b0;
            csr_mepc <= 32'b0;
            csr_mcause <= 32'b0;
            csr_mtval <= 32'b0;
            // v7: there is no DMEM/IMEM in this module at all —
            // memories live in the top (big32.v). Real RAM contents
            // on power-up are undefined, and software must not rely
            // on them; the testbenches initialise the top's DMEM to
            // zero (see tb_big32.v / tb_rand.v), and the Python
            // model uses a zeroed bytearray per run, so simulation
            // still starts from a known state.
        end else if (!halted) begin
            uart_tx_valid <= 1'b0; // pulse: cleared unless a UART store lands
            if (is_ecall && !trap_ecall) begin
                halted <= 1'b1;
            end else if (is_ebreak && !trap_ebreak) begin
                halted <= 1'b1;
            end else begin
                pc <= pc_next;
                if (reg_write && (rd != 5'd0))
                    regs[rd] <= wb_data;
                if (csr_write) begin
                    case (csr_addr)
                        12'h300: csr_mstatus <= csr_new;
                        12'h305: csr_mtvec <= csr_new;
                        12'h340: csr_mscratch <= csr_new;
                        12'h341: csr_mepc <= csr_new;
                        12'h342: csr_mcause <= csr_new;
                        12'h343: csr_mtval <= csr_new;
                        default: begin end // unimplemented: ignore
                    endcase
                end
                // Traps record where they came from and why.
                if (trap_ecall) begin
                    csr_mepc <= pc;             // mepc
                    csr_mcause <= 32'd11;       // mcause: ECALL from M-mode
                    csr_mtval <= 32'b0;         // mtval
                end else if (trap_ebreak) begin
                    csr_mepc <= pc;
                    csr_mcause <= 32'd3;        // mcause: breakpoint
                    csr_mtval <= 32'b0;
                end
                // Stores: the actual memory write happens in the
                // top, on d_we_o (see the memory-port block above).
                // This block only pulses the UART and clears the
                // LR/SC reservation, exactly as v6 did. Note the
                // reservation clears for any store to a real-memory
                // address, even with an invalid funct3, but never
                // for a store to a UART MMIO address.
                if (opcode == 7'b0100011) begin // STORE
                    if (store_addr == 32'h10000000) begin
                        uart_tx <= rs2_val[7:0];
                        uart_tx_valid <= 1'b1;
                    end else if ((store_addr != 32'h10000004) &&
                                 (store_addr != 32'h10000008)) begin
                        if (store_addr == reservation_addr)
                            reservation_valid <= 1'b0;
                    end
                end
                // A extension reservation effects only — the
                // memory write itself happens in the top, on d_we_o.
                if (opcode == 7'b0101111) begin
                    if (amo_funct5 == 5'b00010) begin // lr.w
                        reservation_valid <= 1'b1;
                        reservation_addr <= rs1_val;
                    end else if (amo_funct5 == 5'b00011) begin // sc.w
                        reservation_valid <= 1'b0;
                    end else begin // amo*.w
                        if (rs1_val == reservation_addr)
                            reservation_valid <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
