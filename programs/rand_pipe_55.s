li t0, -77
li t1, -50
li t2, -62
li a0, 89
li a1, -23
li a2, -80
li s0, 91
li s1, 256
sra a2, s0, a2
sh a0, 12(s1)
jal ra, sub_55_0
add t1, a1, a2
sh t0, 4(s1)
or a2, t1, a0
xor t1, a2, t1
xori t0, t0, 15
xori a1, t1, -20
lr.w t1, (s1)
addi t1, t1, 1
sc.w a1, t1, (s1)
and t1, a1, a2
amoadd.w a2, s0, (s1)
srli a1, a2, 5
xor s0, a1, a2
slti t2, t1, 42
amoadd.w a0, t0, (s1)
sh t0, 4(s1)
andi a0, a0, 6
mulh t1, a0, a2
jal ra, sub_55_0
sh t0, 4(s1)
sb t2, 12(s1)
or a0, t1, a2
sll t1, a0, a2
srai a2, a0, 3
sw t2, 12(s1)
srl a2, a2, t0
mulhu s0, a2, t1
sh t1, 12(s1)
lbu s0, 0(s1)
xori t2, s0, 26
srli a0, s0, 4
and s0, a0, a0
add s0, s0, a2
lh s0, 0(s1)
lr.w a2, (s1)
addi a2, a2, 1
sc.w a1, a2, (s1)
mulh a1, a1, t1
sll a0, a1, t0
srli s0, t0, 14
j end_main
sub_55_0:
and t1, s0, a1
sltu s0, a2, t2
slt a1, a2, a1
ret
end_main:
mv a0, s0
ecall
