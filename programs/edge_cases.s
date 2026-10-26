# edge_cases: hand-checked edge cases for big32. t2 = fail count.
# Every check compares a computed value against a hand-computed
# expected value; on mismatch, t2 increments. Final a0 = t2, so
# a0 = 0 means every check passed. This program would have caught
# the v4 SRAI and signed DIV/REM bugs on its own, because the
# expected values below are written out by hand, not taken from
# either the model or the Verilog.
li s1, 256
li t2, 0

# 1. srai -56, 17 = -1
li t0, -56
srai t0, t0, 17
li t1, -1
bne t0, t1, fail1
j ok1
fail1: addi t2, t2, 1
ok1:

# 2. sra (register shift) -56, 17 = -1
li t0, -56
li t1, 17
sra t0, t0, t1
li t1, -1
bne t0, t1, fail2
j ok2
fail2: addi t2, t2, 1
ok2:

# 3. div -1, -41 = 0 (truncation toward zero)
li t0, -1
li t1, -41
div t0, t0, t1
bne t0, zero, fail3
j ok3
fail3: addi t2, t2, 1
ok3:

# 4. div -100, 7 = -14 ; rem -100, 7 = -2
li t0, -100
li t1, 7
div t0, t0, t1
li t1, -14
bne t0, t1, fail4
j ok4
fail4: addi t2, t2, 1
ok4:
li t0, -100
li t1, 7
rem t0, t0, t1
li t1, -2
bne t0, t1, fail5
j ok5
fail5: addi t2, t2, 1
ok5:

# 5. divu 100, 7 = 14 ; remu 100, 7 = 2
li t0, 100
li t1, 7
divu t0, t0, t1
li t1, 14
bne t0, t1, fail6
j ok6
fail6: addi t2, t2, 1
ok6:
li t0, 100
li t1, 7
remu t0, t0, t1
li t1, 2
bne t0, t1, fail7
j ok7
fail7: addi t2, t2, 1
ok7:

# 6. mulh 100000 * 100000: high 32 bits = 2
li t0, 100000
li t1, 100000
mulh t0, t0, t1
li t1, 2
bne t0, t1, fail8
j ok8
fail8: addi t2, t2, 1
ok8:

# 7. lb sign-extends, lbu does not: byte 0xFF -> lb -1, lbu 255
li t0, 255
sb t0, 0(s1)
lb t0, 0(s1)
li t1, -1
bne t0, t1, fail9
j ok9
fail9: addi t2, t2, 1
ok9:
lbu t0, 0(s1)
li t1, 255
bne t0, t1, fail10
j ok10
fail10: addi t2, t2, 1
ok10:

# 8. lh sign-extends, lhu does not: half 0x8000 -> lh -32768, lhu 32768
li t0, -32768
sh t0, 0(s1)
lh t0, 0(s1)
li t1, -32768
bne t0, t1, fail11
j ok11
fail11: addi t2, t2, 1
ok11:
lhu t0, 0(s1)
li t1, 32768
bne t0, t1, fail12
j ok12
fail12: addi t2, t2, 1
ok12:

# 9. slt -1, 1 = 1 ; sltu -1, 1 = 0 (unsigned -1 is huge)
li t0, -1
li t1, 1
slt t0, t0, t1
li t1, 1
bne t0, t1, fail13
j ok13
fail13: addi t2, t2, 1
ok13:
li t0, -1
li t1, 1
sltu t0, t0, t1
bne t0, zero, fail14
j ok14
fail14: addi t2, t2, 1
ok14:

# 10. blt taken: -1 < 1, so the bad increment is skipped
li t0, 0
li t1, -1
li a1, 1
blt t1, a1, ok15
addi t0, t0, 1
ok15:
bne t0, zero, fail15
j ok15b
fail15: addi t2, t2, 1
ok15b:

# 11. amoadd on a fresh scratch word (address 260, never written
# before, so it is still zero from the testbench): old 0, then
# lw = 40. Note: 0(s1) was already used by checks 7-8, so it is
# not zero here; the assembler takes amo addresses as (reg) only.
li a1, 260
li t0, 40
amoadd.w t1, t0, (a1)
bne t1, zero, fail16
j ok16
fail16: addi t2, t2, 1
ok16:
lw t0, 0(a1)
li t1, 40
bne t0, t1, fail17
j ok17
fail17: addi t2, t2, 1
ok17:

# 12. CSR: mtvec = 4660, read back, then clear before ECALL
li t1, 4660
csrrw t0, mtvec, t1
csrr t0, mtvec
li t1, 4660
bne t0, t1, fail18
j ok18
fail18: addi t2, t2, 1
ok18:
csrw mtvec, zero

# 13. jal subroutine: add 5, return
li t0, 37
jal ra, sub_add5
li t1, 42
bne t0, t1, fail19
j ok19
fail19: addi t2, t2, 1
ok19:
j done
sub_add5:
addi t0, t0, 5
ret
done:
mv a0, t2
ecall
