// big32_soc — OS top for the pipelined big32 core (Phases 2 and 3).
// ---------------------------------------------------------------------------
// Unlike the Harvard pipe top (src/big32_pipe.v), this top has ONE
// byte-addressable main memory: instruction fetch and data access
// both read it (two combinational read ports on the same array in
// simulation). It is for OS/firmware programs linked for it, NOT a
// drop-in for the 15 directed Harvard programs: their code lives
// in IMEM at 0.. and their data in DMEM at 0.., and on this top
// code and data share one address space, so a Harvard program
// whose code and data addresses overlap does NOT run unchanged
// here (see PRIVILEGE_MMU.md).
//
// Memory map (physical addresses):
//   RAM            0x00000000 .. MEM_BYTES-1 (parameter, default
//                  1 MiB, power of two; index = addr & (MEM_BYTES-1))
//   UART TX        0x10000000 (byte store transmits; core pulses
//                  uart_tx, as in v7; loads return 0)
//   UART RX data   0x10000004 (byte available: zero-extended byte
//                  and the FIFO pops; empty: -1, as in v7)
//   UART RX status 0x10000008 (bit 0 = RX ready)
//   CLINT mtimecmp 0x20004000 (low 32 bits of the compare value)
//   CLINT mtime    0x2000BFF8 (low 32 bits of the free-running
//                  counter; high words at +4 read 0)
// Peripherals are decoded on the PHYSICAL address (d_addr_o after
// any MMU translation in the core), so an OS maps them with page
// tables that translate a virtual address to these physical ones.
//
// CLINT timer: mtime increments by 1 every clock cycle (tick = 1
// cycle, documented; there is no prescaler). The timer interrupt
// pends while mtime >= mtimecmp. mtimecmp resets to 0xFFFFFFFF
// (far future), so with interrupts disabled by default (mie and
// mstatus reset to 0) old programs are unaffected. Note the edge
// case: if software writes mtimecmp = 0, the interrupt pends
// immediately (mtime >= 0 always) until mtimecmp is raised.
// External interrupt: top-level ext_irq input, ORed with RX ready
// into the core's irq_ext line, so both share machine external
// code 11 (documented; no PLIC). UART RX: a 16-byte FIFO fed by
// the rx_data/rx_valid top-level inputs (one byte per valid
// pulse, dropped when full); the core pops one byte per load
// from 0x10000004 via uart_rx_pop.
// ---------------------------------------------------------------------------
`default_nettype none

module big32_soc #(
    parameter MEM_BYTES = 1048576
) (
    input  wire        clk,
    input  wire        rst_n,
    output wire        halted,
    output wire [7:0]  uart_tx,
    output wire        uart_tx_valid,
    input  wire        ext_irq,
    input  wire [7:0]  rx_data,
    input  wire        rx_valid
);
    reg [7:0] mem [0:MEM_BYTES-1];

    // ---- CLINT ------------------------------------------------------
    reg [31:0] mtime_r;
    reg [31:0] mtimecmp_r;

    // ---- UART RX FIFO (16 bytes) ------------------------------------
    reg [7:0] rx_fifo [0:15];
    reg [3:0] rx_head, rx_tail;
    reg [4:0] rx_count;
    wire rx_ready = (rx_count != 5'd0);
    wire [7:0] rx_head_byte = rx_fifo[rx_head];

    wire [31:0] instr_w;
    wire [31:0] if_addr_w;
    wire [31:0] d_addr_w;
    wire [31:0] d_rdata_w;
    wire [31:0] d_wdata_w;
    wire [3:0]  d_wmask_w;
    wire        d_we_w;
    wire        rx_pop_w;

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
        .irq_timer(mtime_r >= mtimecmp_r),
        .irq_ext(ext_irq | rx_ready),
        .irq_soft(1'b0),
        .uart_rx_ready(rx_ready),
        .uart_rx_data(rx_head_byte),
        .uart_rx_pop(rx_pop_w)
    );

    // ---- Instruction fetch: RAM bytes at if_addr --------------------
    wire [31:0] if_masked = if_addr_w & (MEM_BYTES-1);
    assign instr_w = {mem[(if_masked + 32'd3) & (MEM_BYTES-1)],
                      mem[(if_masked + 32'd2) & (MEM_BYTES-1)],
                      mem[(if_masked + 32'd1) & (MEM_BYTES-1)],
                      mem[if_masked]};

    // ---- Data read: CLINT registers win over RAM --------------------
    wire [31:0] d_masked = d_addr_w & (MEM_BYTES-1);
    wire [7:0] dd0 = mem[d_masked];
    wire [7:0] dd1 = mem[(d_masked + 32'd1) & (MEM_BYTES-1)];
    wire [7:0] dd2 = mem[(d_masked + 32'd2) & (MEM_BYTES-1)];
    wire [7:0] dd3 = mem[(d_masked + 32'd3) & (MEM_BYTES-1)];
    assign d_rdata_w = (d_addr_w == 32'h02004000) ? mtimecmp_r :
                       (d_addr_w == 32'h02004004) ? 32'b0 :
                       (d_addr_w == 32'h0200BFF8) ? mtime_r :
                       (d_addr_w == 32'h0200BFFC) ? 32'b0 :
                       {dd3, dd2, dd1, dd0};

    // ---- Clocked state: mtime, CLINT writes, RAM writes, RX FIFO ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mtime_r <= 32'b0;
            mtimecmp_r <= 32'hFFFFFFFF;
            rx_head <= 4'b0;
            rx_tail <= 4'b0;
            rx_count <= 5'b0;
        end else begin
            mtime_r <= mtime_r + 32'd1;
            // Data writes: CLINT registers first, UART range
            // dropped (the core never asserts d_we for UART
            // stores; an AMO to UART would also land here and
            // is dropped rather than written to RAM), else RAM.
            if (d_we_w) begin
                if (d_addr_w == 32'h02004000) begin
                    if (d_wmask_w[0]) mtimecmp_r[7:0] <= d_wdata_w[7:0];
                    if (d_wmask_w[1]) mtimecmp_r[15:8] <= d_wdata_w[15:8];
                    if (d_wmask_w[2]) mtimecmp_r[23:16] <= d_wdata_w[23:16];
                    if (d_wmask_w[3]) mtimecmp_r[31:24] <= d_wdata_w[31:24];
                end else if (d_addr_w == 32'h0200BFF8) begin
                    if (d_wmask_w[0]) mtime_r[7:0] <= d_wdata_w[7:0];
                    if (d_wmask_w[1]) mtime_r[15:8] <= d_wdata_w[15:8];
                    if (d_wmask_w[2]) mtime_r[23:16] <= d_wdata_w[23:16];
                    if (d_wmask_w[3]) mtime_r[31:24] <= d_wdata_w[31:24];
                end else if ((d_addr_w == 32'h02004004) ||
                             (d_addr_w == 32'h0200BFFC)) begin
                    // High words of the 64-bit CLINT registers:
                    // read as 0, writes dropped (not RAM aliases).
                end else if ((d_addr_w < 32'h10000000) ||
                             (d_addr_w >= 32'h10000010)) begin
                    if (d_wmask_w[0]) mem[d_masked] <= d_wdata_w[7:0];
                    if (d_wmask_w[1])
                        mem[(d_masked + 32'd1) & (MEM_BYTES-1)] <= d_wdata_w[15:8];
                    if (d_wmask_w[2])
                        mem[(d_masked + 32'd2) & (MEM_BYTES-1)] <= d_wdata_w[23:16];
                    if (d_wmask_w[3])
                        mem[(d_masked + 32'd3) & (MEM_BYTES-1)] <= d_wdata_w[31:24];
                end
            end
            // RX FIFO push/pop (simultaneous push+pop keeps count).
            case ({rx_valid && (rx_count != 5'd16), rx_pop_w && rx_ready})
                2'b10: begin
                    rx_fifo[rx_tail] <= rx_data;
                    rx_tail <= rx_tail + 4'd1;
                    rx_count <= rx_count + 5'd1;
                end
                2'b01: begin
                    rx_head <= rx_head + 4'd1;
                    rx_count <= rx_count - 5'd1;
                end
                2'b11: begin
                    rx_fifo[rx_tail] <= rx_data;
                    rx_tail <= rx_tail + 4'd1;
                    rx_head <= rx_head + 4'd1;
                end
                default: begin end
            endcase
        end
    end
endmodule
