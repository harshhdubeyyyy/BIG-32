li t0, 7
li t1, 32
li t2, 44
li a0, 40
li a1, 42
li a2, 50
li s0, -32
li s1, 256
sw s0, 8(s1)
mul s0, t0, a2
amoadd.w s0, t1, (s1)
lbu t1, 4(s1)
divu a2, t1, s0
amoadd.w t0, t2, (s1)
andi t2, t1, -8
lb t1, 12(s1)
amoadd.w a0, a2, (s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w a2, t2, (s1)
jal ra, sub_92_0
ori t1, a1, 19
remu t0, s0, a2
sh t1, 4(s1)
sw s0, 4(s1)
jal ra, sub_92_0
lw a1, 0(s1)
csrrw s0, mscratch, a1
csrrs a1, mscratch, zero
addi a1, s0, -38
sltiu s0, a1, -8
andi a0, a1, -12
amoadd.w a0, a1, (s1)
xori a1, t1, -47
rem a2, t2, t1
lbu s0, 0(s1)
amoadd.w a2, t2, (s1)
andi t1, s0, -31
andi a0, a1, 47
remu t2, a2, t1
slti s0, t0, 26
addi a1, a1, 29
sb t2, 8(s1)
amoadd.w a1, t1, (s1)
slti t2, t1, 44
csrrw a0, mscratch, a0
csrrs a0, mscratch, zero
sra s0, a0, s0
sub t0, s0, t2
csrrw t1, mscratch, s0
csrrs a0, mscratch, zero
lb a2, 12(s1)
slti t0, a2, -37
sw t2, 0(s1)
beq s0, a1, skip_92_41
addi t0, s0, 1
skip_92_41: nop
sra t0, t0, s0
lr.w t1, (s1)
addi t1, t1, 1
sc.w t2, t1, (s1)
amoadd.w t1, a0, (s1)
blt t0, t1, skip_92_45
addi s0, t0, 1
skip_92_45: nop
mulh t0, s0, t1
div t2, t2, a0
j end_main
sub_92_0:
sra t0, t0, t1
and a1, a0, t1
ret
end_main:
mv a0, s0
ecall
