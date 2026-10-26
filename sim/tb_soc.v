// Testbench for the big32 SOC top (Phases 2 and 3).
// Loads one program image (one 32-bit word per hex line, as
// produced by tools/soc_asm.py) into unified RAM at address 0,
// runs it until halt, prints registers, cycle count, selected
// RAM words, and the raw UART transcript (sampled on the falling
// edge, as in tb_pipe). The halt-drain rule from tb_pipe applies:
// 4 extra cycles after halted before sampling registers.
// Plusargs (run from the big32 directory):
//   +HEX=...      program hex (default soc_hex/soc_current.hex)
//   +RXFILE=...   file with one hex byte per line, injected in
//                 order starting at cycle +RXSTART, one byte
//                 every +RXPERIOD cycles (default: no injection)
//   +RXSTART=...  default 600
//   +RXPERIOD=... default 600
//   +EXTAT=...    cycle at which ext_irq asserts (default: never)
//   +EXTLEN=...   ext_irq pulse length in cycles (default 20)
//   +MAXCYCLES=.. default 2000000
// Compile:
//   iverilog -o sim/tb_soc.vvp src/big32_core_pipe.v src/big32_soc.v sim/tb_soc.v
//   vvp sim/tb_soc.vvp +HEX=soc_hex/int_timer.hex
`timescale 1ns/1ps

module tb_soc;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;
    reg ext_irq = 0;
    reg [7:0] rx_data = 0;
    reg rx_valid = 0;

    big32_soc dut (
        .clk(clk), .rst_n(rst_n), .halted(halted),
        .uart_tx(uart_tx), .uart_tx_valid(uart_tx_valid),
        .ext_irq(ext_irq), .rx_data(rx_data), .rx_valid(rx_valid)
    );

    always @(negedge clk) begin
        if (uart_tx_valid)
            $write("%c", uart_tx);
    end

    always #5 clk = ~clk;

    integer cycles;
    integer i;
    integer maxcycles;
    integer rxstart, rxperiod, extat, extlen;
    integer nrx, rxidx, rxnext;
    reg [8*256-1:0] hexfile;
    reg [8*256-1:0] rxfile;
    reg [7:0] rxbytes [0:255];
    reg [31:0] img [0:262143];
    reg [31:0] w8000, w8100, w8104, w8108, w810c, w22000;
    integer fd, code;
    reg [7:0] bval;

    function [31:0] ramword;
        input [31:0] a;
        begin
            ramword = {dut.mem[a+3], dut.mem[a+2], dut.mem[a+1], dut.mem[a]};
        end
    endfunction

    initial begin
        rst_n = 0;
        for (i = 0; i < 1048576; i = i + 1)
            dut.mem[i] = 8'b0;
        if (!$value$plusargs("HEX=%s", hexfile))
            hexfile = "soc_hex/soc_current.hex";
        // Word image: $readmemh fills from line 0; entries past
        // EOF stay x, which terminates the unpack loop below.
        $readmemh(hexfile, img);
        for (i = 0; i < 262144; i = i + 1) begin
            if (img[i] === 32'hxxxxxxxx)
                i = 262144;
            else begin
                dut.mem[i*4] = img[i][7:0];
                dut.mem[i*4+1] = img[i][15:8];
                dut.mem[i*4+2] = img[i][23:16];
                dut.mem[i*4+3] = img[i][31:24];
            end
        end
        maxcycles = 2000000;
        rxstart = 600;
        rxperiod = 600;
        extat = -1;
        extlen = 20;
        nrx = 0;
        rxidx = 0;
        if (!$value$plusargs("MAXCYCLES=%d", maxcycles)) begin end
        if (!$value$plusargs("RXSTART=%d", rxstart)) begin end
        if (!$value$plusargs("RXPERIOD=%d", rxperiod)) begin end
        if (!$value$plusargs("EXTAT=%d", extat)) begin end
        if (!$value$plusargs("EXTLEN=%d", extlen)) begin end
        if ($value$plusargs("RXFILE=%s", rxfile)) begin
            fd = $fopen(rxfile, "r");
            if (fd) begin
                while (!$feof(fd) && nrx < 256) begin
                    code = $fscanf(fd, "%h", bval);
                    if (code == 1) begin
                        rxbytes[nrx] = bval;
                        nrx = nrx + 1;
                    end
                end
                $fclose(fd);
            end
        end
        #23;
        rst_n = 1;
        cycles = 0;
        rxnext = rxstart;
        while (!halted && cycles < maxcycles) begin
            @(posedge clk);
            cycles = cycles + 1;
            // RX injection: one-cycle valid pulse, set after the
            // edge so the SOC samples it on the next edge.
            rx_valid = 0;
            if ((rxidx < nrx) && (cycles >= rxnext)) begin
                rx_data = rxbytes[rxidx];
                rx_valid = 1;
                rxidx = rxidx + 1;
                rxnext = rxnext + rxperiod;
            end
            // External pulse.
            if (extat >= 0)
                ext_irq = (cycles >= extat) && (cycles < extat + extlen);
            else
                ext_irq = 0;
        end
        rx_valid = 0;
        ext_irq = 0;
        repeat (4) @(posedge clk);
        $display("CYCLES: %0d", cycles);
        $display("HALTED: %0d", halted);
        $write("REGS:");
        for (i = 0; i < 32; i = i + 1)
            $write(" %0d", dut.core.regs[i]);
        $display("");
        w8000 = ramword(32'h8000);
        w8100 = ramword(32'h8100);
        w8104 = ramword(32'h8104);
        w8108 = ramword(32'h8108);
        w810c = ramword(32'h810c);
        w22000 = ramword(32'h22000);
        $display("RAM: %0d %0d %0d %0d %0d %0d", w8000, w8100, w8104,
                 w8108, w810c, w22000);
        $finish;
    end
endmodule
