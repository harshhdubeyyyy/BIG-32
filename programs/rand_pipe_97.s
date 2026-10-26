li t0, -51
li t1, 9
li t2, -5
li a0, -87
li a1, 47
li a2, -95
li s0, 42
li s1, 256
csrrw s0, mscratch, t2
csrrs t2, mscratch, zero
mul a2, t2, a0
and t2, a2, t2
and a0, t2, t1
lr.w t1, (s1)
addi t1, t1, 1
sc.w a1, t1, (s1)
sub s0, a1, t1
beq a1, t2, skip_97_6
addi a1, a1, 1
skip_97_6: nop
divu a0, t0, s0
or a1, a0, a1
addi a2, a1, -28
lbu t0, 0(s1)
lw a1, 0(s1)
sh a1, 0(s1)
add a1, a1, s0
sb a1, 4(s1)
sw s0, 12(s1)
sltu a2, a1, t2
jal ra, sub_97_0
amoadd.w t2, t0, (s1)
sb a2, 0(s1)
sw a0, 0(s1)
sb t2, 0(s1)
add t2, t2, s0
or a1, t2, a0
slti a2, t0, -23
xori t0, s0, -12
sw t1, 4(s1)
srli s0, t0, 19
div t1, t1, t0
csrrw t1, mscratch, a2
csrrs t2, mscratch, zero
j end_main
sub_97_0:
mulhu t0, a1, a0
and t2, t0, t0
sltu t2, t2, a2
sub t1, t1, s0
ret
end_main:
mv a0, s0
ecall
