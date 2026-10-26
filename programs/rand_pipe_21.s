li t0, -58
li t1, 7
li t2, 76
li a0, 7
li a1, 62
li a2, -28
li s0, 22
li s1, 256
amoadd.w a1, a1, (s1)
sh t0, 12(s1)
or s0, a1, t1
lbu a0, 12(s1)
sra t2, a0, a1
lb a2, 0(s1)
and t0, a2, a0
sw a0, 4(s1)
lb a0, 0(s1)
amoadd.w t1, a2, (s1)
jal ra, sub_21_0
srl a0, a1, s0
xor t1, a0, a0
ori a0, a1, 60
andi t0, s0, 62
mulh t0, t0, a1
sb t2, 0(s1)
sll t1, t0, t2
addi a1, t2, -21
srl s0, a1, s0
slti a2, t0, -3
addi t1, a2, 24
sw t1, 4(s1)
sb a0, 12(s1)
xor t2, t1, s0
lb t0, 12(s1)
and t2, t0, a2
jal ra, sub_21_0
sra a2, a1, a2
mulhu t1, a2, t2
srl t2, t1, s0
sw t2, 8(s1)
mul a2, t2, a0
sltu a2, a2, t2
xori t1, s0, 1
lb s0, 4(s1)
add t0, s0, t1
lw s0, 8(s1)
srl a1, s0, t2
sw t1, 4(s1)
lr.w t1, (s1)
addi t1, t1, 1
sc.w a2, t1, (s1)
sb a2, 0(s1)
amoadd.w t0, a0, (s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w a1, a0, (s1)
mulh a2, a1, t2
j end_main
sub_21_0:
mulh t2, t0, t1
and a0, t2, a2
slt t2, s0, a1
sltu a0, t0, a1
ret
end_main:
mv a0, s0
ecall
