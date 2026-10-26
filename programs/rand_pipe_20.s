li t0, 85
li t1, 75
li t2, 96
li a0, -62
li a1, -34
li a2, 72
li s0, 62
li s1, 256
sh a0, 0(s1)
sra t2, a0, a1
sltiu t1, t2, 21
xori t0, a2, 39
or a1, t0, t0
mulhu t1, a1, a2
slti a2, t2, -34
csrrw t2, mscratch, a2
csrrs t1, mscratch, zero
lr.w t1, (s1)
addi t1, t1, 1
sc.w t1, t1, (s1)
xor s0, t1, a1
sltu a2, s0, t2
remu t1, a2, t2
sub a0, t1, s0
lh s0, 4(s1)
slt a1, s0, t0
sub t1, a1, s0
mul t2, t1, s0
amoadd.w a2, a0, (s1)
beq s0, s0, skip_20_18
addi a1, s0, 1
skip_20_18: nop
lr.w t1, (s1)
addi t1, t1, 1
sc.w a0, t1, (s1)
sb a1, 0(s1)
mul t2, a0, t0
amoadd.w a2, s0, (s1)
mulh t1, a2, a1
slt t0, t1, a2
csrrw t2, mscratch, s0
csrrs t1, mscratch, zero
andi t0, a0, -3
and t1, t0, t2
sh t0, 12(s1)
xor t1, t1, a2
ori s0, t0, -12
sltiu t2, t1, -39
mulh t0, t2, t2
jal ra, sub_20_0
mulh a0, t1, t0
rem t0, s0, a1
div t1, t2, t2
or t0, t1, a2
lw a0, 8(s1)
amoadd.w a0, t0, (s1)
j end_main
sub_20_0:
sltu t1, a0, s0
srl a1, a0, t2
mulhu t0, s0, a0
sltu t0, s0, a0
ret
end_main:
mv a0, s0
ecall
