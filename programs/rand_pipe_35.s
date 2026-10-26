li t0, 40
li t1, -15
li t2, 92
li a0, -67
li a1, 91
li a2, -13
li s0, -61
li s1, 256
jal ra, sub_35_1
lw s0, 8(s1)
sub a1, s0, t0
rem t2, a2, t0
lh t0, 0(s1)
sub t1, t0, a1
slli t2, t0, 4
lbu t1, 12(s1)
addi a1, t1, 3
div s0, a0, a1
csrrw s0, mscratch, t0
csrrs a2, mscratch, zero
xori a0, t0, 39
lr.w a0, (s1)
addi a0, a0, 1
sc.w a2, a0, (s1)
or a1, a2, t1
amoadd.w s0, t0, (s1)
bne t0, t0, skip_35_15
addi t0, t0, 1
skip_35_15: nop
sltu a2, t0, a1
mulhu a0, a2, s0
slt s0, a0, t2
srai a0, s0, 24
amoadd.w a2, t2, (s1)
sh a1, 8(s1)
sb t2, 0(s1)
lbu s0, 12(s1)
sra a1, s0, a2
sll a2, a1, s0
lw a1, 4(s1)
csrrw a2, mscratch, a1
csrrs t2, mscratch, zero
sll a0, t2, a0
srai a2, t0, 6
sw a1, 4(s1)
amoadd.w a2, a0, (s1)
remu t1, t1, t1
slt a2, t1, a2
divu a0, a0, s0
sltu a0, a0, a0
sw a2, 8(s1)
divu s0, a1, t2
div t1, t2, t2
sh t2, 0(s1)
sra a1, t1, a2
bge s0, t0, skip_35_41
addi t0, s0, 1
skip_35_41: nop
slli t2, t2, 8
j end_main
sub_35_0:
sra a0, t0, t2
sll a2, a0, a0
add t0, a1, a1
and t0, t2, a1
ret
sub_35_1:
mulhu a1, a1, t0
sll t1, a0, a2
mul s0, t2, a0
ret
end_main:
mv a0, s0
ecall
