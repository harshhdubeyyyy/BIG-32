li t0, 38
li t1, -26
li t2, 56
li a0, -93
li a1, 59
li a2, 67
li s0, -47
li s1, 256
xori a2, t1, -63
jal ra, sub_30_0
csrrw s0, mscratch, a1
csrrs a1, mscratch, zero
beq a2, t2, skip_30_3
addi s0, a2, 1
skip_30_3: nop
sltiu t1, s0, 7
rem a1, t0, a2
lh t0, 4(s1)
amoadd.w t2, t2, (s1)
sh a2, 0(s1)
rem a0, a2, a1
mul a2, a0, a0
ori a0, s0, 22
sra a2, a0, a0
xor a0, a2, a1
csrrw a2, mscratch, t1
csrrs a2, mscratch, zero
srl t1, a2, t2
lbu t1, 8(s1)
sb t1, 12(s1)
sltiu s0, a2, 56
andi a1, t1, 11
sw a2, 0(s1)
rem a1, t0, a1
lr.w a2, (s1)
addi a2, a2, 1
sc.w s0, a2, (s1)
lw t0, 4(s1)
amoadd.w a0, a1, (s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w s0, t2, (s1)
sb a0, 0(s1)
divu t2, s0, t0
xori a0, t0, -48
ori s0, t2, -61
csrrw t2, mscratch, t0
csrrs a0, mscratch, zero
j end_main
sub_30_0:
sub a2, t2, a0
sra s0, a1, a2
sub t1, t1, t2
ret
sub_30_1:
sub a0, t1, t1
mulh a0, t0, t0
sub a0, t1, t1
ret
end_main:
mv a0, s0
ecall
