li t0, -31
li t1, 6
li t2, 24
li a0, -35
li a1, -80
li a2, -23
li s0, -14
li s1, 256
sw s0, 8(s1)
lr.w a2, (s1)
addi a2, a2, 1
sc.w a1, a2, (s1)
and t2, a1, a2
srl s0, t2, a2
add a0, s0, a2
blt t2, t2, skip_45_5
addi t1, t2, 1
skip_45_5: nop
div t2, t0, a0
srl t2, t2, s0
lhu a2, 8(s1)
lh t0, 4(s1)
addi a2, t0, -1
sw t2, 12(s1)
xori a0, t1, -42
sw a1, 8(s1)
slti t1, t1, 7
sltu s0, t1, t0
blt t2, a1, skip_45_16
addi a2, t2, 1
skip_45_16: nop
slli t1, t2, 14
sh a1, 12(s1)
sub a1, t1, s0
csrrw t0, mscratch, a2
csrrs t1, mscratch, zero
jal ra, sub_45_0
lbu a2, 12(s1)
lbu t2, 12(s1)
sub a1, t2, t0
xori a2, s0, -5
xori a0, a1, -64
lbu a1, 0(s1)
or a1, a1, t1
sll t0, a1, s0
sh t2, 12(s1)
lbu a2, 12(s1)
j end_main
sub_45_0:
srl t0, t1, s0
add a0, t0, t2
xor a2, t0, s0
and a1, a0, t2
ret
end_main:
mv a0, s0
ecall
