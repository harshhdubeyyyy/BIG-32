li t0, -63
li t1, 96
li t2, 25
li a0, 29
li a1, -26
li a2, -55
li s0, -58
li s1, 256
div t0, a0, a0
sub a1, t0, t1
sh s0, 12(s1)
or t1, a1, t0
ori t2, t0, 48
sltiu t2, a2, 0
or t2, t2, a2
ori t1, s0, -33
lw a1, 12(s1)
beq a1, a0, skip_82_9
addi a1, a1, 1
skip_82_9: nop
andi s0, a1, -41
div a0, a0, t0
sh a1, 0(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w a0, t0, (s1)
amoadd.w a0, t2, (s1)
lhu a2, 12(s1)
sltiu s0, a2, -43
or a0, s0, t2
and a2, a0, a1
lb t2, 4(s1)
or a2, t2, s0
lr.w a0, (s1)
addi a0, a0, 1
sc.w t0, a0, (s1)
sltu t0, t0, s0
andi a0, t2, 20
srl s0, a0, a0
lw t2, 4(s1)
lhu t2, 0(s1)
lb a2, 8(s1)
srl a2, a2, t2
bge a0, s0, skip_82_29
addi a2, a0, 1
skip_82_29: nop
or t0, a2, t0
srli t1, t0, 5
csrrw a1, mscratch, t0
csrrs s0, mscratch, zero
lw a2, 0(s1)
mulhu t0, a2, a0
j end_main
sub_82_0:
mulh a2, t0, a0
add t2, a1, s0
sub t1, a1, a1
mulh a1, a0, t2
ret
sub_82_1:
sub s0, t1, t0
xor s0, s0, s0
ret
end_main:
mv a0, s0
ecall
