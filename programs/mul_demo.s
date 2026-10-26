# 12345 * 6789 -> a0, with one MUL instruction (M extension).
# Expected result: 83810205.
        li t0, 12345
        li t1, 6789
        mul a0, t0, t1
        ecall
