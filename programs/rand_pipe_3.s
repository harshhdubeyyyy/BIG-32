li t0, -40
li t1, 51
li t2, 39
li a0, -67
li a1, -6
li a2, 54
li s0, 21
li s1, 256
slt s0, a0, t2
slt a2, s0, a1
slli a2, s0, 9
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
mulhu s0, a2, t1
beq t2, s0, skip_3_5
addi t0, t2, 1
skip_3_5: nop
amoadd.w t2, a1, (s1)
remu a0, a2, s0
andi s0, a1, 29
xor t1, s0, t1
jal ra, sub_3_0
srli s0, a0, 26
lh t2, 4(s1)
lhu t2, 0(s1)
rem t1, t2, a2
sltiu t0, a0, 59
and s0, t0, a0
sub a0, s0, a0
srl a1, a0, t0
divu t2, a1, t2
jal ra, sub_3_0
lh t0, 8(s1)
sll t0, t0, s0
xori t1, s0, 53
lr.w a0, (s1)
addi a0, a0, 1
sc.w s0, a0, (s1)
lhu a1, 8(s1)
slli a2, a1, 19
srai t2, a1, 21
add a0, t2, t2
addi a1, a2, 21
srai a2, t2, 17
div t0, a1, t0
jal ra, sub_3_0
lb t2, 8(s1)
rem s0, t2, a1
addi a0, t0, -31
ori t1, a2, -3
sltiu a2, a0, -40
or t2, a2, a2
srli s0, t1, 13
csrrw a0, mscratch, t2
csrrs t1, mscratch, zero
amoadd.w t0, t1, (s1)
andi s0, s0, 7
slti s0, a2, 24
lh a0, 12(s1)
xori a0, a0, 40
add a0, a0, t1
srli s0, a1, 14
mul a0, s0, s0
j end_main
sub_3_0:
xor a1, a1, t2
sub t1, s0, a1
sub t2, s0, t1
add t0, s0, a2
ret
end_main:
mv a0, s0
ecall
