// big32 — simulation top for the big32 CPU (v7).
// ---------------------------------------------------------------------------
// This module is NOT the core. It instantiates big32_core
// (src/big32_core.v) and wires its memory ports to the instruction
// and data memories, exactly as v6's internal arrays behaved:
//   - IMEM: 32-bit words, combinational read at PC. The index is
//     PC[IMEM_ADDR_BITS+1:2], so the PC wraps within the IMEM
//     depth in words, exactly as v6 did.
//   - DMEM: bytes, combinational read of the 4 bytes at
//     d_addr_o..d_addr_o+3, each byte wrapped modulo DMEM_DEPTH
//     (both depths must be powers of two, as in v6). Clocked
//     write: byte i of d_wdata_o lands at d_addr_o+i, for each
//     bit set in the core's relative byte mask d_wmask_o.
//   - Memories are NOT cleared on reset (v5 decision, kept):
//     real RAM power-up is undefined, and the testbenches clear
//     DMEM to zero before each program, matching the Python
//     model's zeroed bytearray per run. IMEM is loaded by the
//     testbench while reset is active.
// The port list is unchanged from v6, so testbenches and run.sh
// keep working; only the hierarchical paths to the register file
// and PC change (dut.core.regs, dut.core.pc — see the testbenches).
// For synthesis, use big32_core alone (see sim/synth_test.v and
// the v7 README section), NOT this top: this top still contains
// the full-size memory arrays, which is precisely what Yosys
// cannot map to logic.
// ---------------------------------------------------------------------------
`default_nettype none

module big32 #(
    parameter IMEM_DEPTH = 4096,
    parameter DMEM_DEPTH = 65536
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire        halted,
    output wire [7:0]  uart_tx,
    output wire        uart_tx_valid
);
    localparam IMEM_ADDR_BITS = $clog2(IMEM_DEPTH);
    reg [31:0] imem [0:IMEM_DEPTH-1];
    reg [7:0]  dmem [0:DMEM_DEPTH-1];

    wire [31:0] instr_w;
    wire [31:0] if_addr_w;
    wire [31:0] d_addr_w;
    wire [31:0] d_rdata_w;
    wire [31:0] d_wdata_w;
    wire [3:0]  d_wmask_w;
    wire        d_we_w;

    big32_core core (
        .clk(clk),
        .rst_n(rst_n),
        .halted(halted),
        .uart_tx(uart_tx),
        .uart_tx_valid(uart_tx_valid),
        .instr_i(instr_w),
        .if_addr_o(if_addr_w),
        .d_addr_o(d_addr_w),
        .d_rdata_i(d_rdata_w),
        .d_wdata_o(d_wdata_w),
        .d_wmask_o(d_wmask_w),
        .d_we_o(d_we_w)
    );

    // Instruction fetch: combinational, same indexing as v6.
    assign instr_w = imem[if_addr_w[IMEM_ADDR_BITS+1:2]];

    // Data read: 4 bytes at d_addr_w..d_addr_w+3, each wrapped
    // modulo DMEM_DEPTH, little-endian, exactly as v6 read them.
    wire [7:0] db0 = dmem[d_addr_w & (DMEM_DEPTH-1)];
    wire [7:0] db1 = dmem[(d_addr_w + 32'd1) & (DMEM_DEPTH-1)];
    wire [7:0] db2 = dmem[(d_addr_w + 32'd2) & (DMEM_DEPTH-1)];
    wire [7:0] db3 = dmem[(d_addr_w + 32'd3) & (DMEM_DEPTH-1)];
    assign d_rdata_w = {db3, db2, db1, db0};

    // Data write: clocked, one byte per set mask bit, at the
    // relative address d_addr_w+i. Unrolled (not a loop with a
    // variable part-select) so Icarus and Yosys both read it plainly.
    always @(posedge clk) begin
        if (d_we_w) begin
            if (d_wmask_w[0])
                dmem[d_addr_w & (DMEM_DEPTH-1)] <= d_wdata_w[7:0];
            if (d_wmask_w[1])
                dmem[(d_addr_w + 32'd1) & (DMEM_DEPTH-1)] <= d_wdata_w[15:8];
            if (d_wmask_w[2])
                dmem[(d_addr_w + 32'd2) & (DMEM_DEPTH-1)] <= d_wdata_w[23:16];
            if (d_wmask_w[3])
                dmem[(d_addr_w + 32'd3) & (DMEM_DEPTH-1)] <= d_wdata_w[31:24];
        end
    end
endmodule
