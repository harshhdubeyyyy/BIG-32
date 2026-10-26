li t0, 27
li t1, 17
li t2, -78
li a0, -68
li a1, -4
li a2, -92
li s0, -88
li s1, 256
srl t0, s0, t0
or t2, t0, s0
srli a2, a2, 10
sra t0, a2, s0
slti a1, a2, 17
srli s0, s0, 28
mul s0, s0, a0
sw t1, 8(s1)
srai t1, a2, 2
lbu a0, 4(s1)
beq a0, t2, skip_83_10
addi t2, a0, 1
skip_83_10: nop
xori t1, t0, -47
sll s0, t1, t2
lhu a0, 8(s1)
lhu t1, 8(s1)
lhu s0, 12(s1)
srai a0, s0, 6
csrrw s0, mscratch, a0
csrrs t0, mscratch, zero
lbu a0, 8(s1)
srli t0, a0, 3
srli t1, a1, 24
srl a0, t1, t2
mul s0, a0, t0
csrrw a1, mscratch, a2
csrrs a2, mscratch, zero
sw t2, 12(s1)
srai a2, t0, 15
beq s0, a0, skip_83_26
addi a0, s0, 1
skip_83_26: nop
rem a1, t2, a1
srai a1, t1, 28
amoadd.w a1, t0, (s1)
sltiu t1, t2, 49
slli a2, t2, 10
sh a2, 12(s1)
srli t2, a0, 9
sltiu t1, s0, -30
srl a0, t1, t1
j end_main
sub_83_0:
mul t0, a2, t0
sll t1, t2, t2
and s0, a1, t0
ret
end_main:
mv a0, s0
ecall
