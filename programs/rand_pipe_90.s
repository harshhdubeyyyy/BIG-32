li t0, -48
li t1, 82
li t2, -77
li a0, 23
li a1, 68
li a2, 47
li s0, 50
li s1, 256
csrrw s0, mscratch, a0
csrrs a1, mscratch, zero
csrrw s0, mscratch, t2
csrrs t2, mscratch, zero
sb a1, 4(s1)
srl a2, t2, s0
slti s0, t0, -18
slt t0, s0, t0
addi s0, t1, 44
mul t0, s0, t1
slt s0, t0, s0
slli s0, a2, 30
andi t2, a1, 31
slti t2, a2, 44
sh a0, 12(s1)
srai a1, a2, 16
sra t0, a1, a0
slt a1, t0, s0
sw s0, 8(s1)
lh t1, 8(s1)
add t0, t1, t2
sltiu s0, a2, -63
sltiu a1, a0, 37
mulh t0, a1, s0
sltiu a1, s0, -43
addi a1, a0, 13
sb t0, 4(s1)
sll a1, a1, t0
jal ra, sub_90_0
amoadd.w a0, t0, (s1)
addi a0, a0, 52
lw a0, 8(s1)
sltiu t0, a0, 27
sw a1, 0(s1)
sb t1, 8(s1)
sll s0, t0, a0
xor s0, s0, a1
divu a1, t0, s0
mulh a1, a1, t1
sra a2, a1, t1
or t2, a2, a0
slli s0, t2, 0
mul t2, s0, t2
slti t1, a1, 45
add a0, t1, a0
ori a0, a0, -32
lr.w t0, (s1)
addi t0, t0, 1
sc.w a0, t0, (s1)
xori a0, a0, -43
lw s0, 0(s1)
slti s0, s0, -26
rem a2, t1, t1
or a0, a2, t2
j end_main
sub_90_0:
or a1, s0, a2
and t2, s0, t1
or a2, a2, a1
xor t0, t0, t0
ret
sub_90_1:
srl t0, a1, t0
sltu a2, t2, s0
add t0, t2, t2
ret
end_main:
mv a0, s0
ecall
