// Synthesis measurement wrapper for big32 (v7).
// Instantiates big32_core ALONE — no memories at all. The core's
// memory ports are tied off here (instr = NOP, data read = 0),
// because Yosys only needs the core logic to measure it; the
// memories are SRAM bits, not logic, and are reported separately
// (default: 4096x32 IMEM = 131072 bits, 65536x8 DMEM = 524288
// bits). This wrapper is NOT a testbench and is never used for
// simulation of programs. Yosys can also be run directly on
// src/big32_core.v with hierarchy -top big32_core.
`timescale 1ns/1ps

module synth_test;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;
    wire [31:0] if_addr_w;
    wire [31:0] d_addr_w;
    wire [31:0] d_wdata_w;
    wire [3:0] d_wmask_w;
    wire d_we_w;

    big32_core core (
        .clk(clk),
        .rst_n(rst_n),
        .halted(halted),
        .uart_tx(uart_tx),
        .uart_tx_valid(uart_tx_valid),
        .instr_i(32'h00000013),
        .if_addr_o(if_addr_w),
        .d_addr_o(d_addr_w),
        .d_rdata_i(32'b0),
        .d_wdata_o(d_wdata_w),
        .d_wmask_o(d_wmask_w),
        .d_we_o(d_we_w)
    );

    always #5 clk = ~clk;
endmodule
