li t0, 4
li t1, 33
li t2, 38
li a0, 79
li a1, -71
li a2, -55
li s0, -3
li s1, 256
sub t0, a1, t0
mulh a1, t0, t2
lh a1, 8(s1)
sltu s0, a1, t2
sub a1, s0, a1
xor t2, a1, a2
sra a0, t2, a0
bne t1, t2, skip_44_7
addi t1, t1, 1
skip_44_7: nop
remu t0, a2, s0
rem a2, a2, a2
slti a0, a2, -26
mul a0, a0, a2
jal ra, sub_44_0
sltu t0, t1, t0
rem a2, a1, a1
jal ra, sub_44_0
or t2, t0, s0
lw t0, 12(s1)
mulh t1, t0, a2
lr.w a1, (s1)
addi a1, a1, 1
sc.w t2, a1, (s1)
beq t2, t0, skip_44_20
addi t0, t2, 1
skip_44_20: nop
srai t1, a2, 12
lr.w s0, (s1)
addi s0, s0, 1
sc.w t2, s0, (s1)
sb a1, 8(s1)
sh t2, 8(s1)
addi t2, a1, 17
sub t1, t2, t1
bge a2, t2, skip_44_27
addi a0, a2, 1
skip_44_27: nop
xor a1, a0, t1
divu a1, s0, t2
sub t1, a1, a0
sw a2, 12(s1)
slt t1, t1, t2
add t2, t1, t1
mulh a0, t2, a2
amoadd.w a0, a2, (s1)
divu a2, a1, a0
add a2, a2, a2
andi t0, a1, -31
j end_main
sub_44_0:
slt t1, t0, t0
sub t0, a0, a1
ret
end_main:
mv a0, s0
ecall
