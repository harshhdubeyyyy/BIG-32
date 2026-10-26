// big32_pipe — simulation top for the pipelined big32 core.
// ---------------------------------------------------------------------------
// Same pattern as src/big32.v (v7 top), but instantiating
// big32_core_pipe. Same parameters, same port list, same memory
// behaviour: IMEM combinational read at PC (index PC[bits+1:2]),
// DMEM bytes combinational read of d_addr_o..d_addr_o+3 (each byte
// wrapped modulo DMEM_DEPTH), clocked byte writes from the core's
// relative mask. Memories are NOT cleared on reset; the testbench
// clears DMEM to zero before each program (v5 rule, kept).
// ---------------------------------------------------------------------------
`default_nettype none

module big32_pipe #(
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

    // Phase 2: the pipe top has no interrupt sources, so the new
    // core inputs are tied off and Phase 1 behaviour is unchanged
    // (interrupts can never pend: irq_timer = irq_ext = 0, and
    // uart_rx_ready = 0 keeps the v7 RX-empty values -1 / 0).
    big32_core_pipe core (
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
        .d_we_o(d_we_w),
        .irq_timer(1'b0),
        .irq_ext(1'b0),
        .uart_rx_ready(1'b0),
        .uart_rx_data(8'b0),
        .uart_rx_pop()
    );

    assign instr_w = imem[if_addr_w[IMEM_ADDR_BITS+1:2]];

    wire [7:0] db0 = dmem[d_addr_w & (DMEM_DEPTH-1)];
    wire [7:0] db1 = dmem[(d_addr_w + 32'd1) & (DMEM_DEPTH-1)];
    wire [7:0] db2 = dmem[(d_addr_w + 32'd2) & (DMEM_DEPTH-1)];
    wire [7:0] db3 = dmem[(d_addr_w + 32'd3) & (DMEM_DEPTH-1)];
    assign d_rdata_w = {db3, db2, db1, db0};

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
