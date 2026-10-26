li t0, -82
li t1, -21
li t2, 11
li a0, -37
li a1, 14
li a2, -25
li s0, -35
li s1, 256
mulh a1, t1, s0
srl t2, a1, t1
div a0, a2, a1
sh t1, 0(s1)
csrrw a2, mscratch, t1
csrrs a2, mscratch, zero
srli a1, t1, 30
bne t2, t0, skip_66_6
addi t1, t2, 1
skip_66_6: nop
remu t2, a2, t2
add t0, t2, t2
lbu t2, 0(s1)
lw a1, 12(s1)
ori s0, a1, -9
add t2, s0, t2
xori t2, a1, 22
mulh a1, t2, t1
addi s0, t0, 29
amoadd.w t0, t0, (s1)
mul t1, t0, a2
lw t1, 12(s1)
mulh t0, t1, t2
andi a1, s0, -47
beq t0, a0, skip_66_21
addi s0, t0, 1
skip_66_21: nop
or a1, s0, t2
lb s0, 8(s1)
andi t2, s0, 38
sltu t1, t2, t1
sub t0, t1, t0
lw s0, 4(s1)
lhu s0, 12(s1)
addi t1, s0, 16
addi a2, t2, -43
ori a0, a1, -40
srl t1, a0, s0
jal ra, sub_66_0
amoadd.w a0, a2, (s1)
rem a0, t0, t2
divu s0, t1, t1
csrrw a1, mscratch, t2
csrrs a2, mscratch, zero
rem s0, t2, t1
sltiu s0, a0, 48
jal ra, sub_66_0
bge a1, a0, skip_66_41
addi a2, a1, 1
skip_66_41: nop
remu a1, t0, t1
sb a2, 4(s1)
xor t2, a1, s0
j end_main
sub_66_0:
srl t1, a0, t0
sra s0, t0, s0
sll s0, a0, t2
sub t2, t0, t0
ret
end_main:
mv a0, s0
ecall
