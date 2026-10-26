# pipe_hazards: hazard-heavy directed test for the 5-stage pipeline.
# Hand-computed expected result: a0 = 1406 (see the tally at the end).
# Every section exercises a different pipeline hazard; the Python
# model must agree with the hand computation, and the pipelined
# Verilog must agree with both.
        li sp, 65532
        li s1, 256
        # 1. back-to-back dependent ALU ops (forwarding, no stalls)
        li t0, 5
        addi t1, t0, 3       # t1 = 8
        add t2, t1, t1       # t2 = 16
        addi t3, t2, -6      # t3 = 10
        # 2. load-use chain: store, load, immediate use, chained use
        sw t3, 0(s1)         # mem[0x100] = 10
        lw t4, 0(s1)         # t4 = 10
        addi t5, t4, 5       # t5 = 15 (load-use stall + MEM->EX forward)
        add t6, t5, t4       # t6 = 25 (forwarding chain)
        # 3. load feeding a branch (taken) + a not-taken branch
        sw t6, 0(s1)         # mem[0x100] = 25
        lw a1, 0(s1)         # a1 = 25
        beq a1, t6, L1       # taken (load feeds branch)
        li a2, 999           # skipped
        j L2
L1:
        li a2, 7
L2:
        bne a1, t6, L3       # not taken
        addi a2, a2, 3       # a2 = 10
L3:
        # 4. jal/jalr chain: jal to SUB, ret via jalr; then la + jalr
        jal ra, SUB          # SUB sets a3 = 40, returns here
        la t0, L4            # t0 = address of L4
        jalr ra, 0(t0)       # jump to L4 (ra overwritten, not used again)
        li a4, 111           # skipped by the jalr
L4:
        li a4, 33
        # 5. AMO + LR/SC sequence on mem[0x100] (= 25)
        li t0, 5
        amoadd.w a5, t0, (s1)  # a5 = 25 (old), mem = 30
        lr.w t1, (s1)          # t1 = 30
        addi t1, t1, 2         # t1 = 32
        sc.w t2, t1, (s1)      # t2 = 0 (success), mem = 32
        lw a6, 0(s1)           # a6 = 32 (load after AMO sees new value)
        # 6. back-to-back CSR write then read (CSR hazard stall path)
        li t0, 1234
        csrrw t3, mscratch, t0  # t3 = old mscratch = 0, mscratch = 1234
        csrrs a7, mscratch, zero # a7 = 1234 (must see the write)
        # 7. store whose data depends on a preceding load
        lw t4, 0(s1)         # t4 = 32
        sw t4, 4(s1)         # mem[0x104] = 32 (load-use via store data)
        lw s2, 4(s1)         # s2 = 32
        # 8. final tally: a0 = a2 + a3 + a4 + a5 + a6 + a7 + s2 + t2
        #    = 10 + 40 + 33 + 25 + 32 + 1234 + 32 + 0 = 1406
        mv a0, a2            # 10
        add a0, a0, a3       # 50
        add a0, a0, a4       # 83
        add a0, a0, a5       # 108
        add a0, a0, a6       # 140
        add a0, a0, a7       # 1374
        add a0, a0, s2       # 1406
        add a0, a0, t2       # 1406 (t2 = sc result 0; 1407 would mean sc failed)
        ecall
SUB:
        li a3, 40
        ret
