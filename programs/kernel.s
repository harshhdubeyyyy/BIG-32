# big32 OS kernel, v3 — a tiny supervisor, not Linux.
# Boots, prints a banner on the UART, runs two apps in turn, and
# handles each app's ECALL in the trap handler: the handler prints
# the app's result (a0) and returns to the instruction after the
# ECALL, so the app can ret back to the kernel. At the end the
# kernel clears mtvec and ECALLs, which halts (mtvec == 0 -> halt).
#
# Trap entry (standard RISC-V style, M-mode only in v3):
#   csrrw sp, mscratch, sp   swaps to the kernel stack
#   push a0,a1,t0-t6,ra       (40 bytes)
#   print "E=" + a0 (decimal) + newline
#   mepc += 4                  (skip the ECALL)
#   pop, swap sp back, mret
#
# Kernel stack top: 0x8000 (in DMEM, well above the app stack).
# App stack top: 65532 (as in call_demo).

        # --- boot ---
        li sp, 65532
        li t0, 32768          # 0x8000 kernel stack top
        csrw mscratch, t0
        la t0, trap_handler
        csrw mtvec, t0
        # banner: "big32 OS\n"
        li a0, 'b'
        jal ra, print_char
        li a0, 'i'
        jal ra, print_char
        li a0, 'g'
        jal ra, print_char
        li a0, '3'
        jal ra, print_char
        li a0, '2'
        jal ra, print_char
        li a0, ' '
        jal ra, print_char
        li a0, 'O'
        jal ra, print_char
        li a0, 'S'
        jal ra, print_char
        li a0, '\n'
        jal ra, print_char
        # --- run apps ---
        jal ra, app_sum
        jal ra, app_mul
        # --- done: print "done\n", clear mtvec, halt via ECALL ---
        li a0, 'd'
        jal ra, print_char
        li a0, 'o'
        jal ra, print_char
        li a0, 'n'
        jal ra, print_char
        li a0, 'e'
        jal ra, print_char
        li a0, '\n'
        jal ra, print_char
        csrw mtvec, zero
        ecall
        # never reached

# --- apps (return via ret; ECALL in the middle is handled, then
# execution resumes at the ret) ---
app_sum:
        li t0, 10
        li t1, 0
app_sum_loop:
        add t1, t1, t0
        addi t0, t0, -1
        bne t0, zero, app_sum_loop
        mv a0, t1
        ecall
        ret

app_mul:
        li t0, 6
        li t1, 7
        mul a0, t0, t1
        ecall
        ret

# --- print_char: a0 = byte to send to the UART (0x10000000) ---
print_char:
        li t0, 268435456     # 0x10000000
        sb a0, 0(t0)
        ret

# --- print_num: a0 = unsigned number, prints it in decimal ---
# Uses t0 (working copy), t1 (digit count), t2 (digit), t3 (10).
# Digits are pushed on the stack, then popped in reverse order.
# Saves ra at entry, because it calls print_char (which clobbers ra).
print_num:
        addi sp, sp, -4
        sw ra, 0(sp)
        mv t0, a0
        li t1, 0
        li t3, 10
        bne t0, zero, print_num_loop
        li a0, '0'
        jal ra, print_char
        j print_num_done
print_num_loop:
        rem t2, t0, t3
        div t0, t0, t3
        addi t2, t2, 48      # '0'
        addi sp, sp, -4
        sw t2, 0(sp)
        addi t1, t1, 1
        bne t0, zero, print_num_loop
print_num_out:
        lw a0, 0(sp)
        addi sp, sp, 4
        jal ra, print_char
        addi t1, t1, -1
        bne t1, zero, print_num_out
print_num_done:
        lw ra, 0(sp)
        addi sp, sp, 4
        ret

# --- trap handler: entered on ECALL with mtvec set ---
trap_handler:
        csrrw sp, mscratch, sp
        addi sp, sp, -40
        sw a0, 0(sp)
        sw a1, 4(sp)
        sw t0, 8(sp)
        sw t1, 12(sp)
        sw t2, 16(sp)
        sw t3, 20(sp)
        sw t4, 24(sp)
        sw t5, 28(sp)
        sw t6, 32(sp)
        sw ra, 36(sp)
        # print "E=" + a0 + newline
        li a0, 'E'
        jal ra, print_char
        li a0, '='
        jal ra, print_char
        lw a0, 0(sp)          # restore app's a0 for print_num
        jal ra, print_num
        li a0, '\n'
        jal ra, print_char
        # mepc += 4 (skip the ECALL)
        csrr t0, mepc
        addi t0, t0, 4
        csrw mepc, t0
        # restore registers, swap stack back, return
        lw ra, 36(sp)
        lw t6, 32(sp)
        lw t5, 28(sp)
        lw t4, 24(sp)
        lw t3, 20(sp)
        lw t2, 16(sp)
        lw t1, 12(sp)
        lw t0, 8(sp)
        lw a1, 4(sp)
        lw a0, 0(sp)
        addi sp, sp, 40
        csrrw sp, mscratch, sp
        mret
