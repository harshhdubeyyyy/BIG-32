li t0, 87
li t1, -28
li t2, 98
li a0, -91
li a1, 25
li a2, -99
li s0, 33
li s1, 256
srai s0, a1, 23
lh a1, 12(s1)
slti a2, a1, -8
mulhu a0, a2, a1
mul t0, a0, a1
andi t0, t0, 44
sub a2, t0, t2
csrrw t0, mscratch, a1
csrrs t0, mscratch, zero
srai t0, t1, 30
and a1, t0, a2
csrrw a1, mscratch, a1
csrrs t1, mscratch, zero
slt t1, t1, t2
andi s0, a0, -60
csrrw t0, mscratch, t0
csrrs a0, mscratch, zero
lr.w a1, (s1)
addi a1, a1, 1
sc.w t0, a1, (s1)
lbu t1, 12(s1)
lh t2, 8(s1)
sltu s0, t2, t2
slti a2, a1, -46
sh s0, 8(s1)
rem t2, a2, t2
csrrw t0, mscratch, a0
csrrs t0, mscratch, zero
lr.w s0, (s1)
addi s0, s0, 1
sc.w t1, s0, (s1)
sra a2, t1, t1
lr.w a0, (s1)
addi a0, a0, 1
sc.w s0, a0, (s1)
and t0, s0, a1
and t1, t0, a0
slti t0, a2, 62
or t2, t0, a2
addi t0, a0, 7
div t0, t2, t0
lhu a2, 8(s1)
div a1, a2, t0
srli t2, a0, 19
xor t2, t2, t2
sub t1, t2, a0
j end_main
sub_84_0:
sll a2, a1, t2
srl a2, t2, a2
sltu a0, a0, a2
ret
sub_84_1:
sltu a2, t2, t0
mulhu t0, t0, t0
mulh t0, t0, a2
slt a0, t2, t0
ret
end_main:
mv a0, s0
ecall
