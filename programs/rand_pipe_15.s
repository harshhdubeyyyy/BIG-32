li t0, -47
li t1, -98
li t2, 33
li a0, 88
li a1, -91
li a2, -60
li s0, -39
li s1, 256
csrrw a2, mscratch, t1
csrrs s0, mscratch, zero
lh t2, 12(s1)
rem t2, t2, a0
ori s0, t1, 16
or a2, s0, a0
sw a0, 12(s1)
sh a1, 12(s1)
xori s0, s0, -60
mulhu a1, s0, a1
lhu a2, 12(s1)
sub s0, a2, t0
slti t0, a0, 11
slti a1, t1, 26
mul t2, a1, t1
xori a0, t2, -46
remu s0, s0, t2
srl a2, s0, a0
xor t2, a2, t0
and a0, t2, t2
amoadd.w a1, s0, (s1)
jal ra, sub_15_0
lr.w a1, (s1)
addi a1, a1, 1
sc.w t1, a1, (s1)
rem a1, a0, a2
lh a1, 12(s1)
srai t0, a1, 19
lw t2, 12(s1)
csrrw a0, mscratch, t2
csrrs t0, mscratch, zero
csrrw t2, mscratch, a1
csrrs a0, mscratch, zero
csrrw t0, mscratch, t1
csrrs t2, mscratch, zero
or a1, t2, t2
lw t2, 8(s1)
j end_main
sub_15_0:
sll t1, t0, s0
mul t1, s0, a1
sub a2, s0, a2
srl a1, t2, s0
ret
end_main:
mv a0, s0
ecall
