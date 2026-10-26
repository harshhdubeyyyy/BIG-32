li t0, 27
li t1, -32
li t2, -7
li a0, 63
li a1, -38
li a2, 77
li s0, 21
li s1, 256
sw a1, 4(s1)
andi t0, t2, -16
sltu s0, t0, a1
srai t0, t0, 21
amoadd.w a2, a0, (s1)
srl t2, a2, s0
rem t0, t1, a0
csrrw a1, mscratch, a0
csrrs t1, mscratch, zero
sub t1, t1, a1
addi a1, a2, 63
srai a1, s0, 8
sw t2, 8(s1)
div t1, t0, t2
csrrw a2, mscratch, a0
csrrs a0, mscratch, zero
jal ra, sub_50_0
and a1, t0, s0
add s0, a1, t2
lb t0, 8(s1)
sh t0, 12(s1)
slli a0, t0, 1
add a2, a0, a1
sltiu s0, t2, 63
sub t1, s0, t1
lw t0, 4(s1)
sll a2, t0, a2
sltu a1, a2, t1
csrrw t2, mscratch, a2
csrrs a1, mscratch, zero
sll a0, a1, a0
sb t0, 8(s1)
amoadd.w t2, t2, (s1)
sra a1, t2, s0
xori s0, t0, 1
j end_main
sub_50_0:
sub a1, t0, a1
add t0, t0, t2
sra a2, s0, a0
xor t2, s0, a2
ret
sub_50_1:
mulhu t1, t2, s0
sltu t1, a2, t1
xor t1, t1, t0
sra a1, t1, t1
ret
end_main:
mv a0, s0
ecall
