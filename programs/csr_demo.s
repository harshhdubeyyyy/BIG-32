# CSR demo: write mtvec, read it back via csrrs.
# csrrw t0, mtvec, t1 (t1 = 4660, old mtvec = 0),
# then csrrs a0, mtvec, zero (reads mtvec, rs1 = 0 so no write).
# mtvec is cleared before the final ECALL, otherwise that ECALL
# would trap to 4660 instead of halting. Expected result: 4660.
        li t1, 4660
        csrrw t0, mtvec, t1
        csrrs a0, mtvec, zero
        csrw mtvec, zero
        ecall
