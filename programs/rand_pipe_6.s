li t0, 46
li t1, -80
li t2, 24
li a0, 95
li a1, -34
li a2, -91
li s0, -100
li s1, 256
srli s0, a2, 1
srl s0, s0, a2
bne a2, t0, skip_6_2
addi a1, a2, 1
skip_6_2: nop
sh a2, 0(s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w t2, t2, (s1)
amoadd.w s0, a0, (s1)
lh s0, 0(s1)
blt s0, t1, skip_6_7
addi a1, s0, 1
skip_6_7: nop
sb a1, 0(s1)
lh t1, 8(s1)
lhu t0, 4(s1)
xor a2, t0, t2
divu a0, a0, t1
lhu s0, 0(s1)
mul t1, s0, t0
ori a2, a1, 31
sltiu a0, t2, 61
srl a0, a0, a2
sub a0, a0, s0
csrrw a2, mscratch, s0
csrrs a0, mscratch, zero
slli s0, a0, 27
slli a2, s0, 12
divu t2, a0, a0
sltu a1, t2, t2
amoadd.w t1, a1, (s1)
srli a1, t2, 31
sra a0, a1, a0
mul a0, a0, t2
amoadd.w t2, a2, (s1)
sltu a1, t2, a2
mulh a2, a1, a0
amoadd.w s0, a1, (s1)
add a0, s0, t1
lh a1, 8(s1)
jal ra, sub_6_0
beq t2, a1, skip_6_35
addi t1, t2, 1
skip_6_35: nop
srai s0, s0, 31
sll t1, s0, t2
jal ra, sub_6_0
mulh a2, a2, t0
mulh a2, a2, a0
csrrw a2, mscratch, t0
csrrs a2, mscratch, zero
sw t0, 8(s1)
csrrw a2, mscratch, a0
csrrs a0, mscratch, zero
lb s0, 12(s1)
srai a0, s0, 17
srli a1, t0, 23
ori t0, t0, 7
j end_main
sub_6_0:
srl a0, a0, t2
mulh t0, t0, t1
sltu s0, a2, t1
ret
end_main:
mv a0, s0
ecall
