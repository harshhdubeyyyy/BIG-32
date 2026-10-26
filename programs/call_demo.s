# Nested jal calls -> a0. Expected result: 112 (7 + 5 + 100).
# main sets a0 = 7, a1 = 5, and jal's to outer. outer saves ra on the
# stack, jal's to inner (which adds a0 + a1), adds 100, restores ra,
# and returns. This proves jal/ret, nested calls, and stack save/restore.
# Stack top is 65532 (near the top of the 64KB data memory).
        li sp, 65532
        li a0, 7
        li a1, 5
        jal ra, outer
        ecall
outer:  addi sp, sp, -4
        sw ra, 0(sp)
        jal ra, inner
        addi a0, a0, 100
        lw ra, 0(sp)
        addi sp, sp, 4
        ret
inner:  add a0, a0, a1
        ret
