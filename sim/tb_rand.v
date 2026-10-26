// Random-test testbench for big32: loads programs/rand_current.hex
// (copied there by tools/rand_test.py for each seed), runs it until
// halt, then prints all 32 registers on one line for comparison
// with the Python model. Run from the big32 directory:
//   iverilog -o sim/tb_rand.vvp src/big32_core.v src/big32.v sim/tb_rand.v
//   vvp sim/tb_rand.vvp
`timescale 1ns/1ps

module tb_rand;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;

    big32 dut (
        .clk(clk), .rst_n(rst_n), .halted(halted),
        .uart_tx(uart_tx), .uart_tx_valid(uart_tx_valid)
    );

    always #5 clk = ~clk;

    integer cycles;
    integer i;

    initial begin
        rst_n = 0;
        // v5: core no longer clears DMEM on reset; the testbench
        // initialises it, matching the Python model's zeroed memory.
        for (i = 0; i < 65536; i = i + 1)
            dut.dmem[i] = 8'b0;
        $readmemh("programs/rand_current.hex", dut.imem);
        #23;
        rst_n = 1;
        cycles = 0;
        while (!halted && cycles < 100000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        $write("REGS:");
        for (i = 0; i < 32; i = i + 1)
            $write(" %0d", dut.core.regs[i]);
        $display("");
        $finish;
    end
endmodule
