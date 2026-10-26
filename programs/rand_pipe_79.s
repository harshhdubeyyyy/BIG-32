li t0, -63
li t1, 12
li t2, -11
li a0, 52
li a1, -59
li a2, -39
li s0, -38
li s1, 256
mulh t0, t1, t0
sh a0, 8(s1)
lh t0, 12(s1)
mulh a2, t0, t2
div a0, a2, t0
slli a2, t0, 25
sra t1, a2, t2
mul t0, t1, a1
rem t2, t0, t1
mulhu a2, t2, t2
jal ra, sub_79_0
jal ra, sub_79_0
lw s0, 12(s1)
mulh t0, s0, t0
remu t1, a0, a2
sw s0, 4(s1)
div a2, t1, a0
sb s0, 4(s1)
sb s0, 12(s1)
lh t0, 12(s1)
or a2, t0, t1
bne t2, t1, skip_79_21
addi t2, t2, 1
skip_79_21: nop
add a1, t2, a0
remu a2, t0, a2
lh a2, 8(s1)
ori a1, a2, 10
ori t1, t2, -26
sub s0, t1, a1
blt s0, a1, skip_79_28
addi a0, s0, 1
skip_79_28: nop
sb a0, 12(s1)
lbu s0, 12(s1)
sra a0, s0, a2
jal ra, sub_79_0
sll t0, a0, t1
j end_main
sub_79_0:
or s0, t2, s0
sra a2, a1, a2
ret
sub_79_1:
sra t2, t1, t0
srl t2, t2, t2
ret
end_main:
mv a0, s0
ecall
