// Testbench for big32 v7: runs each program, checks a0 (x10) on halt.
// The core is now dut.core (see src/big32_core.v); memories are
// still dut.imem / dut.dmem in the top (src/big32.v).
// Run from sim/:
//   iverilog -o tb_big32.vvp ../src/big32_core.v ../src/big32.v tb_big32.v && vvp tb_big32.vvp
`timescale 1ns/1ps

module tb_big32;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;

    big32 dut (
        .clk(clk), .rst_n(rst_n), .halted(halted),
        .uart_tx(uart_tx), .uart_tx_valid(uart_tx_valid)
    );

    // UART capture: valid is a pulse set on a clock edge, so sample
    // on the falling edge, when it is stable.
    always @(negedge clk) begin
        if (uart_tx_valid)
            $write("%c", uart_tx);
    end

    always #5 clk = ~clk;

    integer cycles;
    integer fails;
    integer dmem_i;

    // v5: the core no longer clears DMEM on reset (that would be
    // 64KB of resettable flip-flops in hardware). The testbench
    // does it instead: once at the start, and on every reset
    // between programs, so each program starts from zeroed memory
    // exactly as the Python model does.
    always @(negedge rst_n) begin
        for (dmem_i = 0; dmem_i < 65536; dmem_i = dmem_i + 1)
            dut.dmem[dmem_i] = 8'b0;
    end

    task run_prog;
        input [31:0] expected;
        begin
            rst_n = 1;
            cycles = 0;
            while (!halted && cycles < 100000) begin
                @(posedge clk);
                cycles = cycles + 1;
            end
            if (!halted) begin
                $display("FAIL: did not halt");
                fails = fails + 1;
            end else if (dut.core.regs[10] !== expected) begin
                $display("FAIL: a0 = %0d, expected %0d", dut.core.regs[10], expected);
                fails = fails + 1;
            end else begin
                $display("PASS: a0 = %0d after %0d cycles, pc=%0d",
                         dut.core.regs[10], cycles, dut.core.pc);
            end
        end
    endtask

    initial begin
        fails = 0;
        rst_n = 0;
        // First program: rst_n starts at 0, so there is no negedge
        // to trigger the clear above — clear DMEM explicitly here.
        for (dmem_i = 0; dmem_i < 65536; dmem_i = dmem_i + 1)
            dut.dmem[dmem_i] = 8'b0;
        $readmemh("../programs/sum.hex", dut.imem);
        #23;
        $display("sum:");
        run_prog(32'd55);
        rst_n = 0;
        $readmemh("../programs/fib.hex", dut.imem);
        #23;
        $display("fib:");
        run_prog(32'd55);
        rst_n = 0;
        $readmemh("../programs/mul_loop.hex", dut.imem);
        #23;
        $display("mul_loop:");
        run_prog(32'd42);
        rst_n = 0;
        $readmemh("../programs/call_demo.hex", dut.imem);
        #23;
        $display("call_demo:");
        run_prog(32'd112);
        if (dut.core.regs[2] !== 32'd65532) begin
            $display("FAIL: call_demo sp = %0d, expected 65532", dut.core.regs[2]);
            fails = fails + 1;
        end else begin
            $display("PASS: call_demo sp restored to 65532");
        end
        rst_n = 0;
        $readmemh("../programs/mul_demo.hex", dut.imem);
        #23;
        $display("mul_demo:");
        run_prog(32'd83810205);
        rst_n = 0;
        $readmemh("../programs/mulh_demo.hex", dut.imem);
        #23;
        $display("mulh_demo:");
        run_prog(32'd2);
        rst_n = 0;
        $readmemh("../programs/div_demo.hex", dut.imem);
        #23;
        $display("div_demo:");
        run_prog(32'd1402);
        rst_n = 0;
        $readmemh("../programs/div_edge.hex", dut.imem);
        #23;
        $display("div_edge:");
        run_prog(32'd2147483648);
        rst_n = 0;
        $readmemh("../programs/div_zero.hex", dut.imem);
        #23;
        $display("div_zero:");
        run_prog(32'd4294967295);
        rst_n = 0;
        $readmemh("../programs/rem_zero.hex", dut.imem);
        #23;
        $display("rem_zero:");
        run_prog(32'd42);
        rst_n = 0;
        $readmemh("../programs/amo_demo.hex", dut.imem);
        #23;
        $display("amo_demo:");
        run_prog(32'd42);
        rst_n = 0;
        $readmemh("../programs/sc_fail.hex", dut.imem);
        #23;
        $display("sc_fail:");
        run_prog(32'd101);
        rst_n = 0;
        $readmemh("../programs/csr_demo.hex", dut.imem);
        #23;
        $display("csr_demo:");
        run_prog(32'd4660);
        rst_n = 0;
        $readmemh("../programs/edge_cases.hex", dut.imem);
        #23;
        $display("edge_cases:");
        run_prog(32'd0);
        rst_n = 0;
        $readmemh("../programs/kernel.hex", dut.imem);
        #23;
        $display("kernel:");
        // a0 at halt is '\n' (10), the last character printed by the
        // kernel's "done" message. The real proof is the UART output
        // ("big32 OS", "E=55", "E=42", "done"), printed by this
        // testbench as the kernel runs.
        run_prog(32'd10);
        if (fails == 0)
            $display("PASS: all big32 cases correct");
        else
            $display("FAIL: %0d case(s) failed", fails);
        $finish;
    end
endmodule
