# Division by zero: RISC-V says DIV returns -1 (all bits set).
# Expected a0 (unsigned): 4294967295.
        li t0, 42
        li t1, 0
        div a0, t0, t1
        ecall
