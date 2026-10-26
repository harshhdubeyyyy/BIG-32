# sum 1..10 -> a0. Expected result: 55.
        li t0, 10        # count
        li t1, 0         # sum
loop:   add t1, t1, t0
        addi t0, t0, -1
        bne t0, zero, loop
        mv a0, t1
        ecall
