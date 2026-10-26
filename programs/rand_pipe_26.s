li t0, 91
li t1, -49
li t2, 68
li a0, -48
li a1, 10
li a2, 53
li s0, 39
li s1, 256
divu s0, a0, t0
lb t1, 0(s1)
lb s0, 4(s1)
mulhu a0, s0, s0
beq t1, s0, skip_26_4
addi t2, t1, 1
skip_26_4: nop
slt a2, t2, s0
sw a2, 12(s1)
lh a1, 12(s1)
slli a2, a1, 16
srl a1, a2, s0
lw t1, 4(s1)
sw t1, 0(s1)
addi t2, a1, 19
mulh s0, t2, a0
slli t0, t0, 15
amoadd.w t1, t2, (s1)
sltiu s0, s0, 47
sltiu a0, a1, -56
jal ra, sub_26_0
jal ra, sub_26_0
add t1, s0, a1
lh s0, 12(s1)
sub t2, s0, t1
mul s0, t2, t0
blt t0, s0, skip_26_24
addi a1, t0, 1
skip_26_24: nop
sb a2, 12(s1)
or t0, a1, a0
slti t1, s0, 34
addi s0, t2, -48
divu a2, t0, t0
ori t2, t0, 18
slli t1, a2, 0
sw t0, 4(s1)
mulh t0, t1, a1
j end_main
sub_26_0:
sltu t0, a2, a2
and a1, s0, t1
ret
end_main:
mv a0, s0
ecall
