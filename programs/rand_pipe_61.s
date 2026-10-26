li t0, 26
li t1, -54
li t2, 42
li a0, -45
li a1, -18
li a2, -25
li s0, -18
li s1, 256
ori t0, a0, -22
addi t0, a1, -20
andi a0, s0, 39
ori t2, a2, 48
jal ra, sub_61_0
amoadd.w a1, a0, (s1)
slti t1, t1, 30
sh t0, 0(s1)
srai t0, a0, 4
slti t0, a1, 19
srl a0, t0, a0
sub t0, a0, a0
bge a2, a0, skip_61_12
addi t2, a2, 1
skip_61_12: nop
or s0, t2, a2
remu s0, t1, s0
bne s0, t0, skip_61_15
addi t0, s0, 1
skip_61_15: nop
amoadd.w t1, a1, (s1)
or a0, t1, a2
srl s0, a0, a0
andi t0, t2, -18
sll a0, t0, t1
csrrw t1, mscratch, a1
csrrs t2, mscratch, zero
and a1, t2, t1
addi t1, t1, 44
mul t1, t1, a0
beq a0, s0, skip_61_25
addi a1, a0, 1
skip_61_25: nop
rem s0, t1, s0
divu a0, t1, a1
lw a1, 12(s1)
ori a0, a1, 7
bne a2, t2, skip_61_30
addi a0, a2, 1
skip_61_30: nop
sb a1, 4(s1)
lhu t2, 4(s1)
mulhu a1, t2, a0
sra a1, a1, t1
lw a2, 8(s1)
sra a0, a2, a1
sltiu t1, t2, 52
mulhu a2, t1, s0
lr.w a0, (s1)
addi a0, a0, 1
sc.w t1, a0, (s1)
lw a1, 0(s1)
sh a1, 8(s1)
mulhu t2, a1, a1
lbu t2, 8(s1)
rem t0, t2, s0
j end_main
sub_61_0:
xor t2, a1, t2
sltu a0, a1, a1
ret
end_main:
mv a0, s0
ecall
