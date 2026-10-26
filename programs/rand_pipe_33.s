li t0, 46
li t1, -58
li t2, 61
li a0, -41
li a1, -30
li a2, 22
li s0, 66
li s1, 256
csrrw a1, mscratch, t2
csrrs a2, mscratch, zero
sb a2, 0(s1)
addi t2, a1, 45
amoadd.w t2, a1, (s1)
div t1, t0, s0
sltiu t2, t1, 29
slt t2, t2, t1
mul t0, t2, a1
sltiu a0, a0, -36
csrrw t2, mscratch, s0
csrrs a2, mscratch, zero
div a1, s0, t0
add t0, a1, t2
or t2, t0, t1
lbu a0, 8(s1)
lh a0, 12(s1)
srl a0, a0, a0
divu t2, t0, a2
mulh a1, t2, a0
andi s0, a2, 62
div a0, t0, a2
csrrw a2, mscratch, t2
csrrs a0, mscratch, zero
sra a1, a0, t2
csrrw s0, mscratch, a0
csrrs a0, mscratch, zero
sll a0, a0, s0
sltu t1, a0, t2
blt t1, s0, skip_33_25
addi a1, t1, 1
skip_33_25: nop
lr.w a0, (s1)
addi a0, a0, 1
sc.w t2, a0, (s1)
beq t2, s0, skip_33_27
addi s0, t2, 1
skip_33_27: nop
lr.w a2, (s1)
addi a2, a2, 1
sc.w t0, a2, (s1)
sltu t0, t0, t2
or t0, t0, s0
mul a1, t0, t0
rem a1, a0, a1
sub t1, a1, t0
amoadd.w t1, t0, (s1)
amoadd.w a1, t1, (s1)
amoadd.w t1, t0, (s1)
xori t0, s0, 15
jal ra, sub_33_0
amoadd.w a0, t2, (s1)
lh t2, 0(s1)
xori a0, t2, 5
and t0, a0, t1
and t1, t0, a1
sra a0, t1, a0
addi a2, t1, -58
mulh t2, a2, t2
add t2, t2, s0
sh a1, 8(s1)
srl t0, t2, t1
j end_main
sub_33_0:
sub t2, t0, s0
mul t1, a0, t2
ret
end_main:
mv a0, s0
ecall
