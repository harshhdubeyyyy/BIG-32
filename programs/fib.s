# Fibonacci(10) -> a0. Expected result: 55.
# Start (a, b) = (0, 1) = F0, F1; 9 steps reach (34, 55) = F9, F10.
        li t0, 0         # a
        li t1, 1         # b
        li t2, 9         # count
loop:   add t3, t0, t1
        mv t0, t1
        mv t1, t3
        addi t2, t2, -1
        bne t2, zero, loop
        mv a0, t1
        ecall
