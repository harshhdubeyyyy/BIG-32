li t0, -72
li t1, 90
li t2, -67
li a0, 39
li a1, 52
li a2, 82
li s0, -55
li s1, 256
lb s0, 4(s1)
slti s0, s0, -16
sub a0, s0, t0
slli t2, a2, 11
csrrw a1, mscratch, a1
csrrs a2, mscratch, zero
divu s0, t2, a1
beq t1, t1, skip_28_6
addi a0, t1, 1
skip_28_6: nop
blt a2, a2, skip_28_7
addi t2, a2, 1
skip_28_7: nop
sub a1, t2, a2
sw t2, 0(s1)
srli s0, s0, 10
slti t2, s0, -20
or t2, t2, a1
divu a1, a0, t0
mulh t2, a1, a2
divu a0, t0, a0
remu a1, t1, a1
sw a0, 12(s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w t1, t2, (s1)
srl t0, t1, a0
lhu t2, 0(s1)
lh a0, 0(s1)
sub t1, a0, a1
lh t0, 12(s1)
or s0, t0, s0
slt a1, s0, a0
sltiu a1, a0, 36
addi a0, s0, 20
sltu a1, a0, a1
blt a1, t0, skip_28_29
addi t2, a1, 1
skip_28_29: nop
csrrw s0, mscratch, t0
csrrs a2, mscratch, zero
remu t2, a0, s0
beq a2, a2, skip_28_32
addi t1, a2, 1
skip_28_32: nop
xori t0, t1, -13
j end_main
sub_28_0:
mulhu a2, t1, a1
sra a1, t0, a0
ret
end_main:
mv a0, s0
ecall
