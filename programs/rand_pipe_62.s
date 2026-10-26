li t0, 47
li t1, -56
li t2, -84
li a0, -40
li a1, 18
li a2, -21
li s0, 71
li s1, 256
sb t2, 4(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w a0, t0, (s1)
sb t2, 4(s1)
lhu a2, 12(s1)
sh a2, 8(s1)
ori t0, t2, 45
and a1, t0, t1
lhu t0, 4(s1)
sub t1, t0, t1
lb a0, 8(s1)
blt a0, t1, skip_62_10
addi s0, a0, 1
skip_62_10: nop
sll a1, s0, a0
slti t0, t2, -46
sra t0, t0, a2
slt a2, t0, a2
xori a2, a2, -38
lh t2, 12(s1)
beq t2, t2, skip_62_17
addi a1, t2, 1
skip_62_17: nop
ori t0, a0, 39
andi t1, a1, -21
sh a2, 8(s1)
amoadd.w a0, t1, (s1)
sub t1, a0, t2
rem s0, a1, t1
rem t1, s0, a2
xor a0, t1, a1
rem a0, t2, t2
slt s0, a0, a0
sra t1, s0, a0
csrrw t0, mscratch, t1
csrrs a2, mscratch, zero
bne t0, a0, skip_62_30
addi t2, t0, 1
skip_62_30: nop
slli a2, t2, 26
lhu s0, 12(s1)
sb s0, 0(s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w s0, a1, (s1)
j end_main
sub_62_0:
or a2, a2, t2
add s0, t2, t1
mul a1, t0, a0
ret
sub_62_1:
mul t1, a2, t1
mulhu t0, a0, t2
add a0, t2, s0
ret
end_main:
mv a0, s0
ecall
