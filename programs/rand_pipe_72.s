li t0, -82
li t1, 100
li t2, 52
li a0, 89
li a1, -53
li a2, -12
li s0, 78
li s1, 256
rem a2, a1, t1
mulh t1, a2, t0
amoadd.w a0, t0, (s1)
srai s0, t2, 20
rem s0, a0, t2
xori t1, t2, -1
ori a0, a2, 40
csrrw a1, mscratch, t2
csrrs t1, mscratch, zero
slli s0, t1, 21
andi a0, t0, 12
mul a0, a0, t0
sw a0, 0(s1)
amoadd.w a0, a2, (s1)
add a0, a0, a0
sll a2, a0, a2
slt s0, a2, s0
sub s0, s0, s0
sltiu a2, t0, 63
or a1, a2, t2
lb a2, 0(s1)
ori a0, a2, -14
divu a1, a1, a0
sltiu t0, a1, 21
divu t2, a0, a1
lr.w t0, (s1)
addi t0, t0, 1
sc.w s0, t0, (s1)
lbu t1, 12(s1)
amoadd.w s0, t0, (s1)
slti t0, t1, 44
andi t0, a1, 19
div a2, t2, a2
add a0, a2, t0
sltiu a2, a1, 17
lr.w a2, (s1)
addi a2, a2, 1
sc.w a1, a2, (s1)
amoadd.w a1, a2, (s1)
sub t2, a1, a0
lh t0, 4(s1)
amoadd.w t0, a1, (s1)
mulh t2, t0, t0
lw t2, 4(s1)
j end_main
sub_72_0:
sub a2, a2, t1
mulh a2, a0, t0
sub a0, a1, a0
ret
sub_72_1:
sltu a2, s0, a1
mul s0, t2, a1
xor a0, t2, s0
and a2, a2, t1
ret
end_main:
mv a0, s0
ecall
