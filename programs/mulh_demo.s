# 100000 * 100000 = 10000000000 = 0x2_540BE400.
# MULH returns the high 32 bits. Expected result: 2.
        li t0, 100000
        li t1, 100000
        mulh a0, t0, t1
        ecall
