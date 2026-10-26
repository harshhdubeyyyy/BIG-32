li t0, -65
li t1, 12
li t2, 42
li a0, -24
li a1, 23
li a2, 24
li s0, -3
li s1, 256
sltiu a2, a0, -13
sltu s0, a2, a0
srl t2, s0, t2
xor t1, t2, a2
bge a1, t0, skip_54_4
addi a0, a1, 1
skip_54_4: nop
lb t2, 0(s1)
srl a2, t2, t1
sra t0, a2, t1
andi t1, a0, -60
lh a1, 12(s1)
slti a0, a1, -60
lr.w a0, (s1)
addi a0, a0, 1
sc.w a0, a0, (s1)
ori t2, a0, -44
csrrw a2, mscratch, a1
csrrs a0, mscratch, zero
sra a0, a0, s0
lh a1, 0(s1)
bge a1, t2, skip_54_16
addi a1, a1, 1
skip_54_16: nop
ori a0, t1, 17
sw a1, 4(s1)
sh s0, 4(s1)
andi t2, a2, 11
lw t0, 4(s1)
lb t1, 8(s1)
mulh t1, t1, a2
xori t2, t1, 2
lw a1, 0(s1)
xor s0, a1, t1
lr.w a0, (s1)
addi a0, a0, 1
sc.w a0, a0, (s1)
slti t0, t1, 34
sh t0, 12(s1)
divu a1, t0, a0
sltiu t2, t0, -5
slti a0, t1, 45
mulhu t0, a0, a1
div a0, t2, a2
jal ra, sub_54_0
sb s0, 0(s1)
slti a2, t0, -11
srli a1, t2, 3
lhu a0, 4(s1)
jal ra, sub_54_0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a1, a1, (s1)
srli s0, t1, 6
ori s0, a0, -27
j end_main
sub_54_0:
slt t2, a0, s0
srl t0, a2, t2
ret
end_main:
mv a0, s0
ecall
