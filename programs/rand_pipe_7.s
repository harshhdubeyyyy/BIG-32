li t0, -18
li t1, -62
li t2, 1
li a0, 66
li a1, -88
li a2, -82
li s0, 37
li s1, 256
lw a1, 12(s1)
slti t1, a1, 44
mul a1, t1, t1
lbu t0, 0(s1)
jal ra, sub_7_0
slti t1, a1, 14
sb t0, 4(s1)
slti a1, a2, -49
lbu a0, 8(s1)
srli a0, a0, 15
amoadd.w a2, t1, (s1)
sll t2, a2, a0
div t2, a1, t0
sw t2, 12(s1)
srai a2, t0, 20
slti t2, a1, 52
mulh t0, t2, a0
lh t0, 12(s1)
ori a0, t0, -59
beq t1, a1, skip_7_19
addi t2, t1, 1
skip_7_19: nop
sw t2, 4(s1)
andi s0, a0, 50
xori t2, t1, 7
divu t2, a2, a0
mul t1, t2, t1
and a0, t1, a1
slt t0, a0, a0
sltiu a1, t2, -51
srai s0, s0, 25
sltiu a0, t0, 38
and t0, a0, a0
add a1, t0, t0
sb t2, 0(s1)
and t1, a1, a0
lbu t2, 0(s1)
sra a0, t2, a0
sb t0, 8(s1)
divu a0, s0, a2
sw t2, 0(s1)
div t2, a2, s0
lb t2, 8(s1)
j end_main
sub_7_0:
slt a1, s0, a1
mul t2, t1, a1
ret
end_main:
mv a0, s0
ecall
