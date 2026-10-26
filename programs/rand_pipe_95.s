li t0, 94
li t1, 36
li t2, 31
li a0, 88
li a1, 38
li a2, 100
li s0, -68
li s1, 256
mul t0, a1, t0
mulh t1, t0, a1
sw a2, 8(s1)
andi s0, a0, -19
sltu t2, s0, t1
andi t2, a1, -36
remu a2, t2, s0
slti t0, t2, 25
slti t2, t1, 33
sltu t1, t2, t0
or t1, t1, a0
sb a2, 4(s1)
lbu a0, 4(s1)
sh a0, 4(s1)
sw a1, 8(s1)
slt s0, a0, t1
lbu t0, 0(s1)
andi t2, t0, 39
sll a1, t2, a1
rem a1, t1, t0
slli a0, a2, 28
rem a0, t0, a2
or t2, a0, t2
slli t2, t0, 16
srl t0, t2, a2
lh a0, 12(s1)
rem s0, a0, a1
slt t2, s0, a0
amoadd.w t0, a0, (s1)
remu t0, t0, a0
j end_main
sub_95_0:
mul a0, t2, a1
mulh a2, a2, t2
sltu t2, a1, t0
sll a2, a0, t0
ret
sub_95_1:
slt a0, t0, t0
or a2, t2, s0
ret
end_main:
mv a0, s0
ecall
