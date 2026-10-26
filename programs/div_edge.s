# Overflow edge case: (-2147483648) / (-1).
# RISC-V says the result is -2147483648 itself (it cannot be +2147483648).
# As an unsigned register value, a0 = 2147483648. Expected: 2147483648.
        li t0, -2147483648
        li t1, -1
        div a0, t0, t1
        ecall
