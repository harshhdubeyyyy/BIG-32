li t0, 39
li t1, -54
li t2, -69
li a0, -29
li a1, -23
li a2, 10
li s0, -96
li s1, 256
blt a1, s0, skip_94_0
addi a0, a1, 1
skip_94_0: nop
jal ra, sub_94_1
andi a0, t2, -53
andi s0, a2, 3
mulh a2, s0, a0
jal ra, sub_94_1
srai a2, t2, 1
sra s0, a2, t0
andi t2, t1, 56
sb t0, 4(s1)
sb t0, 8(s1)
mul a2, t2, a2
srl s0, a2, t0
lb a1, 4(s1)
lb a0, 12(s1)
mul t2, a0, t2
andi a1, a2, 17
bne t1, a0, skip_94_17
addi a0, t1, 1
skip_94_17: nop
sb t2, 0(s1)
lw t2, 4(s1)
lr.w t1, (s1)
addi t1, t1, 1
sc.w a2, t1, (s1)
remu t1, t1, t2
srli a2, t0, 24
sltu t1, a2, s0
add t1, t1, t0
csrrw a2, mscratch, t0
csrrs s0, mscratch, zero
sltu a2, s0, t0
srli t0, t2, 23
srai t0, t1, 30
div a0, t2, t0
bne t0, a1, skip_94_30
addi s0, t0, 1
skip_94_30: nop
sh s0, 12(s1)
div t2, s0, a0
slli t2, t1, 16
sw a2, 12(s1)
sltu a2, t2, a1
csrrw t1, mscratch, t2
csrrs t2, mscratch, zero
sb t2, 12(s1)
lbu a0, 8(s1)
lw t1, 4(s1)
mul s0, t1, t2
j end_main
sub_94_0:
sll t1, s0, t0
sltu s0, t0, t1
ret
sub_94_1:
slt a1, t1, s0
mulh a2, t2, t0
mul s0, a0, a2
ret
end_main:
mv a0, s0
ecall
