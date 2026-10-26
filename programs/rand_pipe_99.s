li t0, 3
li t1, -3
li t2, -49
li a0, 53
li a1, -55
li a2, -42
li s0, -37
li s1, 256
mulh a0, a1, a2
sh t1, 4(s1)
amoadd.w s0, s0, (s1)
xori a2, t1, -19
lr.w t2, (s1)
addi t2, t2, 1
sc.w a2, t2, (s1)
sh a0, 12(s1)
or a1, a2, a0
slti a1, t0, -14
lb t0, 4(s1)
divu a0, t0, a1
beq t1, t0, skip_99_10
addi a2, t1, 1
skip_99_10: nop
srl a0, a2, s0
and a0, a0, t0
andi t0, a0, 39
or s0, t0, a2
slli a1, a0, 22
bne t0, t1, skip_99_16
addi a0, t0, 1
skip_99_16: nop
lw a0, 4(s1)
andi t1, a0, -11
csrrw t2, mscratch, s0
csrrs a0, mscratch, zero
amoadd.w s0, t0, (s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w a2, t2, (s1)
add t2, a2, a1
xori a0, a0, 34
andi t2, a1, -55
bge s0, a0, skip_99_25
addi a2, s0, 1
skip_99_25: nop
mul s0, a2, t1
rem t0, s0, a2
mulh s0, t0, a2
sub t2, s0, s0
csrrw a0, mscratch, t2
csrrs t0, mscratch, zero
sh t2, 4(s1)
j end_main
sub_99_0:
xor a0, a0, a2
sltu s0, t1, t2
mul a0, a2, a1
ret
end_main:
mv a0, s0
ecall
