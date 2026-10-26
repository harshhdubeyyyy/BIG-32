li t0, 18
li t1, 56
li t2, -5
li a0, -32
li a1, -65
li a2, -53
li s0, 73
li s1, 256
sb t2, 0(s1)
remu t1, a2, a0
and t1, t1, t0
sb s0, 12(s1)
amoadd.w t0, t1, (s1)
lw a2, 8(s1)
blt a2, t2, skip_9_6
addi a0, a2, 1
skip_9_6: nop
amoadd.w t1, t0, (s1)
csrrw t0, mscratch, a0
csrrs s0, mscratch, zero
sb a0, 0(s1)
jal ra, sub_9_0
csrrw t1, mscratch, t2
csrrs t0, mscratch, zero
csrrw t1, mscratch, a1
csrrs t0, mscratch, zero
sw a1, 12(s1)
sub t1, t0, s0
div t1, t1, a1
and a1, t1, a1
div a2, a1, t0
lr.w a0, (s1)
addi a0, a0, 1
sc.w t1, a0, (s1)
lhu t0, 0(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w s0, t0, (s1)
csrrw t2, mscratch, a0
csrrs t1, mscratch, zero
xori a1, a2, 20
sra t0, a1, t1
mul s0, t0, t2
addi a1, s0, 33
amoadd.w s0, a0, (s1)
sltiu s0, t1, -48
srli t1, t0, 23
blt t2, t1, skip_9_29
addi a1, t2, 1
skip_9_29: nop
add s0, a1, t0
bne t1, t2, skip_9_31
addi s0, t1, 1
skip_9_31: nop
jal ra, sub_9_0
xor t1, s0, a0
lb s0, 12(s1)
sb s0, 8(s1)
lb t0, 12(s1)
lh s0, 12(s1)
slti t0, s0, -32
and a2, t0, t0
j end_main
sub_9_0:
add s0, t1, t1
sra a0, a1, a1
ret
end_main:
mv a0, s0
ecall
