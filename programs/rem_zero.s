# Remainder by zero: RISC-V says REM returns the dividend.
# Expected result: 42.
        li t0, 42
        li t1, 0
        rem a0, t0, t1
        ecall
