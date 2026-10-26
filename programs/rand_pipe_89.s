li t0, -80
li t1, 96
li t2, 55
li a0, 80
li a1, -34
li a2, -65
li s0, -12
li s1, 256
lr.w t2, (s1)
addi t2, t2, 1
sc.w t2, t2, (s1)
lb t2, 12(s1)
lhu t1, 12(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w a1, t0, (s1)
xori a2, t0, 57
sll s0, a2, a2
jal ra, sub_89_0
rem t1, t2, t0
lh t1, 4(s1)
sb t1, 12(s1)
sltiu a1, a1, -12
blt s0, a1, skip_89_11
addi a1, s0, 1
skip_89_11: nop
csrrw a2, mscratch, a1
csrrs s0, mscratch, zero
sltu s0, s0, s0
slti t2, t1, 13
lw t2, 12(s1)
sltu t2, t2, t2
lbu t2, 4(s1)
srli s0, t2, 3
lh a2, 12(s1)
amoadd.w a1, t0, (s1)
srli t2, a0, 3
lw t2, 12(s1)
slt a1, t2, t0
divu a0, t0, t0
sltu s0, a0, t0
amoadd.w t2, t1, (s1)
add s0, t2, s0
srl t0, s0, t2
andi a0, a0, 15
srai a2, t2, 6
csrrw a0, mscratch, a0
csrrs a1, mscratch, zero
mulhu t1, a1, t1
slt t2, t1, t1
j end_main
sub_89_0:
add t1, a0, s0
xor a1, a2, t2
and s0, s0, t2
ret
end_main:
mv a0, s0
ecall
