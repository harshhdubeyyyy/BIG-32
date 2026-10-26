li t0, -10
li t1, -84
li t2, 10
li a0, 41
li a1, 16
li a2, 46
li s0, -13
li s1, 256
xori a1, t0, -58
bge t2, s0, skip_47_1
addi t0, t2, 1
skip_47_1: nop
remu t0, s0, t2
sra a1, t0, t2
blt a1, t2, skip_47_4
addi t0, a1, 1
skip_47_4: nop
lb a1, 4(s1)
amoadd.w a2, t0, (s1)
srl t0, a2, a1
sb t0, 4(s1)
bge t2, t1, skip_47_9
addi s0, t2, 1
skip_47_9: nop
rem s0, a0, a1
lb t2, 8(s1)
xori a1, t2, 15
sb a2, 4(s1)
lbu a2, 12(s1)
and a1, a2, a1
slli t1, a1, 4
sra s0, t1, a1
amoadd.w a0, s0, (s1)
slt t2, a0, a1
blt a2, a2, skip_47_20
addi a0, a2, 1
skip_47_20: nop
amoadd.w a1, t1, (s1)
andi s0, a2, 56
blt t0, t1, skip_47_23
addi t1, t0, 1
skip_47_23: nop
sw a0, 0(s1)
addi t2, t0, -29
or a1, t2, a0
amoadd.w s0, a1, (s1)
slli a1, t0, 11
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
xor t0, a2, t0
sltu a1, t0, t1
csrrw a1, mscratch, t1
csrrs a1, mscratch, zero
sb s0, 0(s1)
sw t0, 12(s1)
xori t2, a1, -29
mul a1, t2, a0
amoadd.w s0, a0, (s1)
amoadd.w a1, t0, (s1)
amoadd.w t2, a2, (s1)
sh t1, 8(s1)
mul t0, t2, t0
srai a0, t2, 1
jal ra, sub_47_1
srl t2, a1, a0
j end_main
sub_47_0:
mulhu a2, t0, a1
sltu a2, a1, a0
ret
sub_47_1:
mulhu a2, t2, a1
srl t2, s0, a2
mulh t1, a2, t0
slt t0, s0, t2
ret
end_main:
mv a0, s0
ecall
