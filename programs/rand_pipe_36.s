li t0, -16
li t1, -86
li t2, -95
li a0, -28
li a1, -80
li a2, -100
li s0, 28
li s1, 256
slt a2, a0, t2
sra t0, a2, a0
jal ra, sub_36_0
csrrw a0, mscratch, t1
csrrs t0, mscratch, zero
sb t1, 8(s1)
mulh a2, t0, t2
csrrw t1, mscratch, t0
csrrs a1, mscratch, zero
jal ra, sub_36_0
xori t2, s0, 1
lbu t1, 8(s1)
slli a2, t1, 19
mulh t1, a2, t0
slt t2, t1, a2
and a0, t2, a0
sw t0, 12(s1)
and a2, a0, t2
div s0, t1, a1
srli s0, t2, 0
sh t0, 0(s1)
sw a2, 8(s1)
andi t1, t2, -29
andi a0, t0, -36
slt a2, a0, t2
slli a1, t1, 3
addi a0, t1, 44
addi t2, t2, 55
lbu a0, 0(s1)
mul a1, a0, a1
lw a2, 0(s1)
rem a2, a2, a1
bne a2, a2, skip_36_30
addi a2, a2, 1
skip_36_30: nop
lw a2, 12(s1)
sw a2, 12(s1)
mul a0, a2, a2
or t0, a0, a0
div s0, a2, a0
divu t0, a2, t1
j end_main
sub_36_0:
sra a2, a0, t2
and a1, a2, t0
mulh a2, a1, a0
ret
end_main:
mv a0, s0
ecall
