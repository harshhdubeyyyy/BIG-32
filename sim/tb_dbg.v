// Testbench for the big32 Phase 5 platform top (src/big32_soc2.v).
// Loads a word image into RAM at 0x80000000 (the ROM at 0 jumps
// there), optionally loads a disk image into dut.disk and a DTB
// blob into RAM at +DTBOFF, runs until halt, prints registers,
// cycle count, selected RAM words, and the raw UART transcript
// (legacy + 16550 pulses, sampled on the falling edge).
// Plusargs (run from the big32 directory):
//   +HEX=...      program hex (default soc2_hex/soc2_current.hex)
//   +DISKHEX=...  disk image words (default: none, pattern only)
//   +DTBFILE=...  DTB bytes, one hex byte per line
//   +DTBOFF=...   DTB RAM offset in bytes (default 0x20000)
//   +RX2FILE=...  16550 RX bytes, one hex byte per line
//   +RX2START=... default 600
//   +RX2PERIOD=... default 600
//   +EXTAT=...    cycle at which ext_irq asserts (default: never)
//   +EXTLEN=...   ext_irq pulse length in cycles (default 20)
//   +MAXCYCLES=.. default 2000000
// Compile:
//   iverilog -o sim/tb_soc2.vvp src/big32_core_pipe.v src/big32_soc2.v sim/tb_soc2.v
//   vvp sim/tb_soc2.vvp +HEX=soc2_hex/plic.hex
`timescale 1ns/1ps

module tb_dbg;
    reg clk = 0;
    reg rst_n = 0;
    wire halted;
    wire [7:0] uart_tx;
    wire uart_tx_valid;
    reg ext_irq = 0;
    reg [7:0] rx_data = 0;
    reg rx_valid = 0;
    reg [7:0] rx2_data = 0;
    reg rx2_valid = 0;

    big32_soc2 dut (
        .clk(clk), .rst_n(rst_n), .halted(halted),
        .uart_tx(uart_tx), .uart_tx_valid(uart_tx_valid),
        .ext_irq(ext_irq), .rx_data(rx_data), .rx_valid(rx_valid),
        .rx2_data(rx2_data), .rx2_valid(rx2_valid)
    );

    always @(negedge clk) begin
        if (uart_tx_valid)
            $write("%c", uart_tx);
    end

    always #5 clk = ~clk;

    integer cycles;
    integer i;
    integer maxcycles;
    integer rx2start, rx2period, extat, extlen, dtboff;
    integer nrx2, rx2idx, rx2next;
    reg [8*256-1:0] hexfile;
    reg [8*256-1:0] diskfile;
    reg [8*256-1:0] dtbfile;
    reg [8*256-1:0] rx2file;
    reg [7:0] rx2bytes [0:255];
    reg [7:0] dtbbytes [0:65535];
    reg [31:0] img [0:262143];
    reg [31:0] dimg [0:262143];
    integer fd, code, ndtb;
    reg [7:0] bval;

    // Word RAM (soc2 memw): offsets used here are all
    // word-aligned, so the word at off>>2 is the answer.
    function [31:0] ramword;
        input [31:0] off;
        begin
            ramword = dut.memw[off[31:2]];
        end
    endfunction

    initial begin
        rst_n = 0;
        for (i = 0; i < 262144; i = i + 1)
            dut.memw[i] = 32'b0;
        if (!$value$plusargs("HEX=%s", hexfile))
            hexfile = "soc2_hex/soc2_current.hex";
        $readmemh(hexfile, img);
        for (i = 0; i < 262144; i = i + 1) begin
            if (img[i] === 32'hxxxxxxxx)
                i = 262144;
            else begin
                dut.memw[i] = img[i];
            end
        end
        if ($value$plusargs("DISKHEX=%s", diskfile)) begin
            $readmemh(diskfile, dimg);
            for (i = 0; i < 262144; i = i + 1) begin
                if (dimg[i] === 32'hxxxxxxxx)
                    i = 262144;
                else begin
                    dut.disk[i*4] = dimg[i][7:0];
                    dut.disk[i*4+1] = dimg[i][15:8];
                    dut.disk[i*4+2] = dimg[i][23:16];
                    dut.disk[i*4+3] = dimg[i][31:24];
                end
            end
        end
        dtboff = 131072;
        if (!$value$plusargs("DTBOFF=%d", dtboff)) begin end
        if ($value$plusargs("DTBFILE=%s", dtbfile)) begin
            fd = $fopen(dtbfile, "r");
            ndtb = 0;
            if (fd) begin
                while (!$feof(fd) && ndtb < 65536) begin
                    code = $fscanf(fd, "%h", bval);
                    if (code == 1) begin
                        dtbbytes[ndtb] = bval;
                        ndtb = ndtb + 1;
                    end
                end
                $fclose(fd);
            end
            for (i = 0; i < ndtb; i = i + 1)
                // Byte RMW into the word array (blocking
                // assignments here, so sequential updates
                // to the same word compose correctly).
                dut.memw[(dtboff + i) >> 2] =
                    (dut.memw[(dtboff + i) >> 2] &
                     ~(32'hFF << (((dtboff + i) & 3) * 8))) |
                    (dtbbytes[i] << (((dtboff + i) & 3) * 8));
        end
        maxcycles = 2000000;
        rx2start = 600;
        rx2period = 600;
        extat = -1;
        extlen = 20;
        nrx2 = 0;
        rx2idx = 0;
        if (!$value$plusargs("MAXCYCLES=%d", maxcycles)) begin end
        if (!$value$plusargs("RX2START=%d", rx2start)) begin end
        if (!$value$plusargs("RX2PERIOD=%d", rx2period)) begin end
        if (!$value$plusargs("EXTAT=%d", extat)) begin end
        if (!$value$plusargs("EXTLEN=%d", extlen)) begin end
        if ($value$plusargs("RX2FILE=%s", rx2file)) begin
            fd = $fopen(rx2file, "r");
            if (fd) begin
                while (!$feof(fd) && nrx2 < 256) begin
                    code = $fscanf(fd, "%h", bval);
                    if (code == 1) begin
                        rx2bytes[nrx2] = bval;
                        nrx2 = nrx2 + 1;
                    end
                end
                $fclose(fd);
            end
        end
        #23;
        rst_n = 1;
        cycles = 0;
        rx2next = rx2start;
        while (!halted && cycles < maxcycles) begin
            @(posedge clk);
            cycles = cycles + 1;
            rx2_valid = 0;
            if ((rx2idx < nrx2) && (cycles >= rx2next)) begin
                rx2_data = rx2bytes[rx2idx];
                rx2_valid = 1;
                rx2idx = rx2idx + 1;
                rx2next = rx2next + rx2period;
            end
            if (extat >= 0)
                ext_irq = (cycles >= extat) && (cycles < extat + extlen);
            else
                ext_irq = 0;
        end
        rx2_valid = 0;
        ext_irq = 0;
        repeat (4) @(posedge clk);
        $display("CYCLES: %0d", cycles);
        $display("HALTED: %0d", halted);
        $write("REGS:");
        for (i = 0; i < 32; i = i + 1)
            $write(" %0d", dut.core.regs[i]);
        $display("");
        $display("ADDBG L0_0_PTE=%h DATA=%h", dut.memw[32'h11000 >> 2], dut.memw[32'h30000 >> 2]);
        $display("RAM: %0d %0d %0d %0d %0d %0d",
                 ramword(32'h0000F000), ramword(32'h0000F004),
                 ramword(32'h0000F008), ramword(32'h0000F00C),
                 ramword(32'h00010000), ramword(32'h00010004));
        $finish;
    end

    // DEBUG trace: pc + fetched word for the first 120 cycles
    // after reset release.
    integer tc;
    initial begin
        tc = 0;
        @(posedge rst_n);
        while (tc < 120) begin
            @(posedge clk);
            tc = tc + 1;
            $display("DBG cyc=%0d pc=%h instr=%h halted=%b",
                     tc, dut.core.pc, dut.instr_w, halted);
        end
    end

    // WALK trace: every cycle the walker is active, plus every
    // data write.
    integer wc;
    initial begin
        wc = 0;
        @(posedge rst_n);
        while (1) begin
            @(posedge clk);
            wc = wc + 1;
            if (dut.core.ptw_state != 0 || dut.d_we_w)
                $display("WALK cyc=%0d pc=%h state=%0d daddr=%h we=%b wdata=%h",
                         wc, dut.core.pc, dut.core.ptw_state,
                         dut.d_addr_w, dut.d_we_w, dut.d_wdata_w);
            if (wc > 300) begin end
        end
    end
endmodule
