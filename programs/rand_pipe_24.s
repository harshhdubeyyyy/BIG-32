li t0, 82
li t1, -2
li t2, 49
li a0, -54
li a1, -45
li a2, -58
li s0, -51
li s1, 256
rem t1, s0, a2
remu s0, t0, a0
lr.w a2, (s1)
addi a2, a2, 1
sc.w t0, a2, (s1)
sh s0, 8(s1)
sh s0, 4(s1)
lh t2, 0(s1)
beq t2, t2, skip_24_6
addi t2, t2, 1
skip_24_6: nop
andi t1, a2, 61
lr.w t2, (s1)
addi t2, t2, 1
sc.w a2, t2, (s1)
sra t1, a2, a1
amoadd.w a2, t2, (s1)
slli a2, a1, 30
sb t1, 4(s1)
mul t1, a2, t2
sh t1, 12(s1)
xor t2, t1, t2
remu a2, a1, s0
addi t1, t2, 51
div a0, a0, s0
mulhu t2, a0, a0
xori a0, a1, 37
lr.w t2, (s1)
addi t2, t2, 1
sc.w t2, t2, (s1)
slti t2, a2, -60
bge t0, a2, skip_24_23
addi a1, t0, 1
skip_24_23: nop
xori a0, t2, 33
lw t2, 12(s1)
csrrw a0, mscratch, t2
csrrs a0, mscratch, zero
amoadd.w t1, t1, (s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w a1, a1, (s1)
add a0, a1, t1
add t0, a0, t1
sw t0, 8(s1)
j end_main
sub_24_0:
and t0, t0, t1
slt s0, s0, t0
mulhu a1, a1, a0
ret
end_main:
mv a0, s0
ecall
