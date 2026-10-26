li t0, 26
li t1, 44
li t2, 85
li a0, -10
li a1, -71
li a2, -77
li s0, -10
li s1, 256
addi s0, t1, -34
lw s0, 0(s1)
divu a2, s0, t1
blt t1, a1, skip_93_3
addi a0, t1, 1
skip_93_3: nop
lbu t2, 0(s1)
mulhu t1, t2, a1
xor t0, t1, s0
amoadd.w t1, s0, (s1)
sra a0, t1, t2
amoadd.w a2, a0, (s1)
slti t1, a2, -28
lh a2, 8(s1)
lh a1, 0(s1)
srai t0, a1, 28
and a1, t0, s0
sb a2, 4(s1)
add t1, a1, t2
sll a2, t1, a2
sltu t0, a2, t2
sltu t1, t0, t2
sh t0, 0(s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w s0, a0, (s1)
sra s0, s0, t2
add a1, s0, t2
sltu s0, a1, a1
beq t0, a1, skip_93_25
addi t2, t0, 1
skip_93_25: nop
csrrw t0, mscratch, t1
csrrs a2, mscratch, zero
srli s0, t0, 27
mulh a1, s0, a0
remu a1, t1, t1
xor s0, a1, t1
lbu a0, 12(s1)
add s0, a0, a0
rem t1, a1, t0
bne t0, t0, skip_93_34
addi t0, t0, 1
skip_93_34: nop
j end_main
sub_93_0:
or t2, a2, a1
and t1, t2, a2
or t2, t2, a2
or a1, a1, s0
ret
end_main:
mv a0, s0
ecall
