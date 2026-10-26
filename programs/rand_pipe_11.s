li t0, 15
li t1, 43
li t2, 99
li a0, 19
li a1, 15
li a2, 30
li s0, 50
li s1, 256
amoadd.w a0, a1, (s1)
amoadd.w t0, t2, (s1)
mul a1, t0, a2
mulh a0, a1, a2
lhu t1, 0(s1)
sltu t1, t1, t1
sltu a0, t1, a0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
xori t0, a2, 7
sltiu a1, s0, 1
addi t1, a1, -47
sh t0, 12(s1)
add t0, t1, a2
mulh t0, t0, a0
andi t0, a1, 5
xori t2, t2, -34
add a2, t2, t0
srai a0, t1, 12
slli t1, a2, 26
lb t0, 0(s1)
xor s0, t0, a1
jal ra, sub_11_0
jal ra, sub_11_0
xor t1, t1, a0
xor a1, t1, s0
slti t0, t0, -2
sra t2, t0, a1
sltu a1, t2, s0
and a0, a1, a2
andi t1, s0, -16
mul a2, t1, t1
bge a1, t0, skip_11_31
addi a0, a1, 1
skip_11_31: nop
xor t0, a0, a1
srl a2, t0, t2
amoadd.w a1, t2, (s1)
j end_main
sub_11_0:
mulh t1, t0, t1
sra t1, a1, a2
sltu s0, a1, t0
or t2, t1, a2
ret
end_main:
mv a0, s0
ecall
