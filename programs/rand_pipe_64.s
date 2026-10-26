li t0, 21
li t1, -69
li t2, 61
li a0, 56
li a1, 3
li a2, 37
li s0, 75
li s1, 256
jal ra, sub_64_0
lw s0, 12(s1)
slli a2, s0, 25
lw t0, 0(s1)
bne t0, t1, skip_64_4
addi t2, t0, 1
skip_64_4: nop
srl t0, t2, a0
csrrw t2, mscratch, a2
csrrs t1, mscratch, zero
sb t2, 8(s1)
lw a1, 4(s1)
slli t1, a1, 17
add t1, t1, s0
div t2, s0, s0
csrrw t2, mscratch, t1
csrrs a2, mscratch, zero
csrrw a2, mscratch, t1
csrrs s0, mscratch, zero
lbu t1, 12(s1)
ori t2, t1, -25
amoadd.w t2, t1, (s1)
and t0, t2, t0
csrrw a1, mscratch, t2
csrrs s0, mscratch, zero
srai s0, a0, 31
addi a1, a2, 16
lw s0, 8(s1)
xori a1, s0, 35
sltiu t2, a0, -62
bne a2, a1, skip_64_24
addi a2, a2, 1
skip_64_24: nop
sltiu t1, s0, -6
srli a1, a0, 19
mul a0, a1, a2
sll t0, a0, a2
jal ra, sub_64_0
slt a2, a1, a2
lbu a0, 4(s1)
sh a0, 8(s1)
csrrw t0, mscratch, t1
csrrs a2, mscratch, zero
srl t1, a2, s0
and t1, t1, a0
j end_main
sub_64_0:
xor t2, a0, s0
sra t1, t0, t2
ret
end_main:
mv a0, s0
ecall
