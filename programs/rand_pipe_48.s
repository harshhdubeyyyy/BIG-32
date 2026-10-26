li t0, 40
li t1, -20
li t2, -67
li a0, 42
li a1, 82
li a2, 36
li s0, -23
li s1, 256
sub s0, s0, a2
sb s0, 4(s1)
slli t0, t0, 8
sb t0, 8(s1)
bne t2, t0, skip_48_4
addi a2, t2, 1
skip_48_4: nop
xor a2, a2, a1
lb t2, 4(s1)
slti s0, t2, 6
xor t0, s0, a1
lw a2, 4(s1)
slt t2, a2, a0
lw s0, 8(s1)
srai t2, s0, 25
srli a1, t2, 12
srai a2, t1, 10
mul t1, a2, s0
lhu a2, 12(s1)
sb a2, 0(s1)
csrrw a1, mscratch, t2
csrrs t0, mscratch, zero
lw t0, 8(s1)
slti t0, t0, 50
sh t0, 0(s1)
sb t0, 4(s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w a0, t2, (s1)
jal ra, sub_48_0
div a0, a2, a0
lw a0, 0(s1)
or s0, a0, t1
blt t1, t1, skip_48_28
addi t0, t1, 1
skip_48_28: nop
sltiu s0, t1, 44
div t0, a1, a1
ori a1, t0, -26
lr.w t0, (s1)
addi t0, t0, 1
sc.w s0, t0, (s1)
mulhu s0, s0, a1
sh t2, 12(s1)
lb s0, 4(s1)
or a0, s0, a0
lb t0, 12(s1)
jal ra, sub_48_0
and a1, a2, a1
and a2, a1, a1
sw a2, 0(s1)
srli t1, a1, 6
j end_main
sub_48_0:
add t1, t0, t0
and s0, t1, a0
ret
end_main:
mv a0, s0
ecall
