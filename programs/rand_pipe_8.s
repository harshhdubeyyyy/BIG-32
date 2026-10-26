li t0, -42
li t1, -6
li t2, -4
li a0, -68
li a1, -51
li a2, 80
li s0, -89
li s1, 256
mul a1, t1, a0
sra a0, a1, a0
sh t0, 4(s1)
remu a2, t2, a1
srai a0, a2, 16
sltu s0, a0, a0
amoadd.w t0, t0, (s1)
sltiu a2, t0, -11
lhu t1, 0(s1)
sb t1, 12(s1)
rem a0, t2, a1
lr.w a0, (s1)
addi a0, a0, 1
sc.w t1, a0, (s1)
rem t0, a1, a2
divu a2, s0, a0
slti t2, a1, -46
amoadd.w s0, a2, (s1)
sh t0, 8(s1)
srl t0, s0, t2
sltiu a2, a0, 37
or a2, a2, t0
jal ra, sub_8_0
amoadd.w a0, s0, (s1)
srl a0, a0, t1
sb t0, 0(s1)
sltiu t0, t0, -37
remu a1, t2, t1
div a1, t0, t1
beq a0, a2, skip_8_27
addi t2, a0, 1
skip_8_27: nop
div t2, t2, t2
lhu a0, 0(s1)
csrrw s0, mscratch, a0
csrrs s0, mscratch, zero
amoadd.w s0, t1, (s1)
sub a0, s0, t0
sra t1, a0, s0
j end_main
sub_8_0:
sub a0, t0, a1
sra a2, a2, t1
ret
end_main:
mv a0, s0
ecall
