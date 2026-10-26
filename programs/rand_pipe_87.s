li t0, -63
li t1, 88
li t2, -52
li a0, 38
li a1, -74
li a2, -29
li s0, 93
li s1, 256
sh t0, 0(s1)
sra s0, t0, s0
sb s0, 4(s1)
sub t1, s0, a1
slti a2, t2, 46
xori a2, a2, -12
lhu s0, 12(s1)
amoadd.w a1, t2, (s1)
sll t2, a1, t2
remu a2, a1, t2
lhu s0, 0(s1)
amoadd.w s0, t0, (s1)
xori a0, t1, 7
and a1, a0, s0
andi t2, a0, -5
lr.w t1, (s1)
addi t1, t1, 1
sc.w t2, t1, (s1)
xor t0, t2, t2
lhu t2, 12(s1)
amoadd.w t1, a0, (s1)
sw t2, 4(s1)
beq t0, a1, skip_87_20
addi t1, t0, 1
skip_87_20: nop
or t0, t1, a0
ori t2, t1, -53
slti t2, t0, 19
lbu a0, 8(s1)
csrrw a2, mscratch, a0
csrrs s0, mscratch, zero
blt a2, t1, skip_87_26
addi t1, a2, 1
skip_87_26: nop
slti t2, a2, 62
xor a2, t2, t0
sltu a0, a2, s0
ori s0, t0, -43
csrrw a0, mscratch, a2
csrrs a0, mscratch, zero
andi t0, s0, -2
mulh s0, t0, t0
lh a2, 4(s1)
lw a1, 12(s1)
lb t0, 12(s1)
lhu a0, 8(s1)
sb a0, 8(s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
divu a0, t0, s0
mulhu t0, a0, t2
mulhu a0, t0, t1
or t1, a0, t0
lbu a0, 4(s1)
remu t1, a0, t0
sh s0, 12(s1)
blt t0, t2, skip_87_47
addi s0, t0, 1
skip_87_47: nop
srl a2, s0, t2
lw a2, 12(s1)
j end_main
sub_87_0:
slt a2, t0, a0
mul t2, t2, t0
slt a2, t0, t1
sll t0, a1, t1
ret
sub_87_1:
srl t0, t0, a1
and t2, s0, a2
or t1, t1, a2
or t0, a0, a1
ret
end_main:
mv a0, s0
ecall
