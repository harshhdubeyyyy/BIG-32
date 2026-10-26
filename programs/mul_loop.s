# 6 * 7 -> a0, by repeated addition (no M extension yet).
# Expected result: 42.
        li t0, 6         # multiplicand
        li t1, 7         # counter
        li t2, 0         # result
loop:   add t2, t2, t0
        addi t1, t1, -1
        bne t1, zero, loop
        mv a0, t2
        ecall
