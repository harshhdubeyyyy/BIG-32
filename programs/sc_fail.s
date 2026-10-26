# sc.w without a preceding lr.w must fail (return 1) and must
# NOT store. a0 = 100 + sc_result, so a0 = 101 proves failure
# (a successful sc would give a0 = 100). amo_demo already proves
# the success path stores correctly.
        li t0, 256
        li t1, 99
        sc.w t2, t1, (t0)
        li a0, 100
        add a0, a0, t2
        ecall
