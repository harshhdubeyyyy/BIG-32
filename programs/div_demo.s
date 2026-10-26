# 100 / 7 = 14 remainder 2, combined as div*100 + rem -> a0.
# Expected result: 1402 (proves both DIV and REM in one answer).
        li t0, 100
        li t1, 7
        div t2, t0, t1
        rem t3, t0, t1
        li t4, 100
        mul t2, t2, t4
        add a0, t2, t3
        ecall
