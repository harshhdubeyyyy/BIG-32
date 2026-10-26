li t0, -6
li t1, 18
li t2, -1
li a0, -49
li a1, -24
li a2, -87
li s0, 7
li s1, 256
andi s0, a0, -43
slti t2, t1, -49
mulhu a0, t2, a1
jal ra, sub_76_0
and a2, a2, a0
sub a2, a2, a2
div t2, a2, a1
lr.w a1, (s1)
addi a1, a1, 1
sc.w t0, a1, (s1)
sra s0, t0, a0
sra a1, s0, a0
sb a1, 12(s1)
slti t1, s0, 28
slli t1, a1, 1
add t0, t1, a1
lbu t0, 12(s1)
andi t0, t0, -53
jal ra, sub_76_0
rem t0, a2, s0
srai a1, t0, 5
amoadd.w t2, t2, (s1)
sub s0, t2, a2
sra a0, s0, a0
slli a1, t2, 18
andi s0, a1, 16
srl t1, s0, t1
slti s0, t2, 13
jal ra, sub_76_0
sltu a2, a2, s0
lr.w a0, (s1)
addi a0, a0, 1
sc.w a2, a0, (s1)
sw t1, 12(s1)
xori a2, a0, -40
mulh t1, a2, t1
bge s0, a2, skip_76_32
addi a1, s0, 1
skip_76_32: nop
slt s0, a1, a2
lbu t1, 8(s1)
mulh s0, t1, a0
andi s0, a2, -61
srl s0, s0, t0
jal ra, sub_76_0
j end_main
sub_76_0:
xor t0, t1, a1
and t2, t1, t1
sub s0, t0, t1
ret
end_main:
mv a0, s0
ecall
