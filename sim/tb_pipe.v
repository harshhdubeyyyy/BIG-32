// Testbench for the pipelined big32 core (Phase 1).
// Loads one program, runs it until halt, prints the final register
// file, cycle count, and scratch-memory words, and passes the UART
// output through raw (sampled on the falling edge, as in tb_big32).
// The hex file comes from a +HEX=... plusarg, defaulting to
// programs/pipe_current.hex (set by the runner scripts).
// Run from the big32 directory:
//   iverilog -o sim/tb_pipe.vvp src/big32_core_pipe.v src/big32_pipe.v sim/tb_pipe.v
//   vvp sim/tb_pipe.vvp +HEX=programs/sum.hex
`timescale 1ns/1ps

module tb_pipe;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;

    big32_pipe dut (
        .clk(clk), .rst_n(rst_n), .halted(halted),
        .uart_tx(uart_tx), .uart_tx_valid(uart_tx_valid)
    );

    always @(negedge clk) begin
        if (uart_tx_valid)
            $write("%c", uart_tx);
    end

    always #5 clk = ~clk;

    integer cycles;
    integer i;
    reg [8*256-1:0] hexfile;
    reg [31:0] dw0, dw1, dw2, dw3;

    initial begin
        rst_n = 0;
        for (i = 0; i < 65536; i = i + 1)
            dut.dmem[i] = 8'b0;
        if (!$value$plusargs("HEX=%s", hexfile))
            hexfile = "programs/pipe_current.hex";
        $readmemh(hexfile, dut.imem);
        #23;
        rst_n = 1;
        cycles = 0;
        while (!halted && cycles < 2000000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        // Halt drain: the halting ECALL/EBREAK is in EX when
        // halted rises, so older instructions may still be in
        // MEM/WB. Give the pipeline 4 cycles to commit them
        // before sampling registers (cycles above still counts
        // only up to the halt, matching tb_big32's convention).
        repeat (4) @(posedge clk);
        $display("CYCLES: %0d", cycles);
        $display("HALTED: %0d", halted);
        $write("REGS:");
        for (i = 0; i < 32; i = i + 1)
            $write(" %0d", dut.core.regs[i]);
        $display("");
        dw0 = {dut.dmem[259], dut.dmem[258], dut.dmem[257], dut.dmem[256]};
        dw1 = {dut.dmem[263], dut.dmem[262], dut.dmem[261], dut.dmem[260]};
        dw2 = {dut.dmem[267], dut.dmem[266], dut.dmem[265], dut.dmem[264]};
        dw3 = {dut.dmem[271], dut.dmem[270], dut.dmem[269], dut.dmem[268]};
        $display("DMEM: %0d %0d %0d %0d", dw0, dw1, dw2, dw3);
        $finish;
    end
endmodule
