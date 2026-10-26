# Atomic demo (A extension, word only).
# Memory word at 0x100 starts at 0 (DMEM is zero at reset).
# amoadd.w adds 40, then lr.w/sc.w adds 2 more -> total 42.
# Expected result: 42, and sc.w returns 0 (success).
        li t0, 256        # address 0x100
        li t1, 40
        amoadd.w t2, t1, (t0)
        lr.w t3, (t0)
        addi t3, t3, 2
        sc.w t4, t3, (t0)
        lw a0, 0(t0)
        # a0 should be 42; t4 (sc result) is checked in the testbench
        # via a second run? No: fold it in: a0 = a0 + t4*1000 would
        # change the answer, so instead the model/verilog check is
        # simply a0 = 42 here, and a separate sc_fail program checks
        # the failure path.
        ecall
