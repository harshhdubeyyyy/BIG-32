#!/usr/bin/env python3
"""Run a Forge-generated big32 program in both the Python model and
Icarus Verilog, and print both UART transcripts for comparison.

Usage (from the big32 directory):
    python3 tools/run_forge.py programs/forge_os.hex
The .hex is produced by Forge: `forge.py build --target big32 prog.fg`.
The Verilog testbench is generated into /tmp (not committed).
Requires iverilog.
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TB = """`timescale 1ns/1ps
module tb_forge;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;
    big32 dut (.clk(clk), .rst_n(rst_n), .halted(halted),
               .uart_tx(uart_tx), .uart_tx_valid(uart_tx_valid));
    always @(negedge clk) begin
        if (uart_tx_valid) $write("%c", uart_tx);
    end
    always #5 clk = ~clk;
    integer cycles;
    integer i;
    initial begin
        rst_n = 0;
        for (i = 0; i < 65536; i = i + 1) dut.dmem[i] = 8'b0;
        $readmemh("__HEX__", dut.imem);
        #23;
        rst_n = 1;
        cycles = 0;
        while (!halted && cycles < 1000000) begin
            @(posedge clk);
            cycles = cycles + 1;
        end
        $display("\\n[verilog] halted=%0d cycles=%0d a0=%0d", halted, cycles, dut.core.regs[10]);
        $finish;
    end
endmodule
"""


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 1
    hex_path = os.path.abspath(sys.argv[1])
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "model.py"), hex_path],
                       capture_output=True, text=True)
    print("== model ==")
    print(r.stdout, end="")
    with tempfile.TemporaryDirectory(prefix="big32_forge_") as td:
        tb_path = os.path.join(td, "tb_forge.v")
        with open(tb_path, "w") as f:
            f.write(TB.replace("__HEX__", hex_path))
        vvp = os.path.join(td, "tb_forge.vvp")
        rc = subprocess.run(["iverilog", "-o", vvp,
                             os.path.join(ROOT, "src", "big32_core.v"),
                             os.path.join(ROOT, "src", "big32.v"), tb_path],
                            capture_output=True, text=True)
        if rc.returncode != 0:
            print("iverilog failed:", rc.stdout, rc.stderr)
            return 1
        rv = subprocess.run(["vvp", vvp], capture_output=True, text=True)
        print("== verilog ==")
        print(rv.stdout, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
