li t0, -79
li t1, 51
li t2, -56
li a0, 75
li a1, 73
li a2, -59
li s0, 2
li s1, 256
slli s0, t2, 23
amoadd.w t1, t1, (s1)
addi t0, s0, 50
lhu a2, 8(s1)
sltiu s0, a2, 46
sll t1, s0, a2
divu a1, s0, s0
csrrw s0, mscratch, t0
csrrs a1, mscratch, zero
bne a0, a0, skip_91_8
addi t0, a0, 1
skip_91_8: nop
sh a0, 8(s1)
sw s0, 12(s1)
lb t2, 8(s1)
srai t2, t2, 26
slt a2, t2, a2
csrrw t1, mscratch, a1
csrrs a1, mscratch, zero
bge a1, t0, skip_91_15
addi t1, a1, 1
skip_91_15: nop
and s0, t1, a1
add a2, s0, a0
csrrw a1, mscratch, t2
csrrs t1, mscratch, zero
sltiu t0, a0, -5
or a1, t0, a1
ori t2, s0, 4
amoadd.w t1, t1, (s1)
and a1, t1, a0
amoadd.w a0, t2, (s1)
lr.w a2, (s1)
addi a2, a2, 1
sc.w a0, a2, (s1)
jal ra, sub_91_1
lw t1, 12(s1)
slt t1, t1, t1
srli t2, s0, 7
mulhu t2, t2, t1
mulhu a1, t2, t1
mulhu t2, a1, t1
amoadd.w s0, a1, (s1)
jal ra, sub_91_1
sltu t2, t2, t2
lh s0, 0(s1)
addi a2, s0, -13
divu a2, t0, t1
srl t0, a2, t0
beq a2, t2, skip_91_40
addi t1, a2, 1
skip_91_40: nop
sb t2, 8(s1)
srai t0, a1, 12
or t1, t0, t1
j end_main
sub_91_0:
mulhu a2, t2, a1
sub t1, a1, s0
mulh t1, a1, s0
sra a2, s0, a0
ret
sub_91_1:
sra a1, a2, s0
add t0, a1, t2
sll t1, t0, t1
ret
end_main:
mv a0, s0
ecall
