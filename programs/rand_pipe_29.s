li t0, 40
li t1, -81
li t2, -12
li a0, 53
li a1, 55
li a2, -27
li s0, -78
li s1, 256
xori t0, t0, -7
amoadd.w t0, t2, (s1)
bne a0, s0, skip_29_2
addi a1, a0, 1
skip_29_2: nop
srli t1, t1, 12
sb t2, 4(s1)
amoadd.w s0, a1, (s1)
sltu t2, s0, t2
div a0, a0, s0
rem t2, s0, t1
slt t2, t2, t0
xori a0, a2, 55
ori a1, a2, -12
lbu t0, 12(s1)
bne t0, a0, skip_29_13
addi t1, t0, 1
skip_29_13: nop
addi t0, s0, -54
div t2, t0, t0
bne s0, t0, skip_29_16
addi a1, s0, 1
skip_29_16: nop
sub a0, a1, t1
add t1, a0, a0
add t0, t1, t1
lb a0, 4(s1)
lh a1, 4(s1)
csrrw s0, mscratch, a1
csrrs t0, mscratch, zero
lh s0, 8(s1)
add a0, s0, s0
csrrw a0, mscratch, t2
csrrs a1, mscratch, zero
csrrw t2, mscratch, a0
csrrs a2, mscratch, zero
sra t0, a2, a0
amoadd.w t0, t2, (s1)
slti t1, t1, 56
andi a1, t0, 57
bne s0, t1, skip_29_31
addi a0, s0, 1
skip_29_31: nop
amoadd.w a0, s0, (s1)
lb a2, 0(s1)
bge a2, t0, skip_29_34
addi a0, a2, 1
skip_29_34: nop
lb t0, 8(s1)
sltu t1, t0, a2
xor t1, t1, s0
ori t2, t0, -16
amoadd.w t1, t1, (s1)
blt t2, a1, skip_29_40
addi t2, t2, 1
skip_29_40: nop
sltiu a0, t2, -35
j end_main
sub_29_0:
mulhu t1, a1, a1
mul t0, t2, t0
mulhu s0, t0, s0
or t1, t1, t0
ret
sub_29_1:
mulhu s0, s0, t2
mul s0, t2, a2
xor t0, a2, t0
ret
end_main:
mv a0, s0
ecall
