li t0, -81
li t1, -46
li t2, -63
li a0, -23
li a1, 78
li a2, -40
li s0, 27
li s1, 256
add a1, t2, s0
sw a1, 4(s1)
sw s0, 8(s1)
blt a0, t0, skip_32_3
addi t1, a0, 1
skip_32_3: nop
and a1, t1, a2
srai a0, t0, 22
sra a0, a0, a2
xor s0, a0, a2
sw s0, 8(s1)
mul t2, s0, t1
addi t2, a0, 58
mulh t1, t2, t1
jal ra, sub_32_0
add t2, t1, a0
slt t0, t2, t0
bge t2, t2, skip_32_15
addi a2, t2, 1
skip_32_15: nop
srli s0, t1, 14
sll a0, s0, a2
sltu s0, a0, t1
lb t2, 4(s1)
jal ra, sub_32_0
blt s0, t1, skip_32_21
addi a1, s0, 1
skip_32_21: nop
remu a0, t1, a0
sll t2, a0, t1
andi a2, a1, -31
amoadd.w a1, a0, (s1)
lw t2, 4(s1)
csrrw t0, mscratch, t2
csrrs a1, mscratch, zero
rem a2, a1, s0
andi t0, a0, -25
mul a0, t0, a0
j end_main
sub_32_0:
sra t0, s0, s0
add t2, a1, t0
ret
end_main:
mv a0, s0
ecall
