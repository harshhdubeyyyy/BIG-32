li t0, 6
li t1, -27
li t2, -27
li a0, 31
li a1, -44
li a2, 13
li s0, 17
li s1, 256
bne a2, a0, skip_65_0
addi s0, a2, 1
skip_65_0: nop
or a1, s0, t2
lh a1, 0(s1)
and a2, a1, s0
amoadd.w s0, t1, (s1)
lh t2, 4(s1)
jal ra, sub_65_0
andi a0, t0, -59
rem t2, t2, t2
xor a2, t2, t0
jal ra, sub_65_0
sw a0, 12(s1)
divu a2, t2, t1
slti t2, t1, -63
xori t0, t2, -23
lr.w t1, (s1)
addi t1, t1, 1
sc.w t0, t1, (s1)
mulh a2, t0, a1
addi t2, a1, 40
sra s0, t2, a0
lhu a0, 8(s1)
bge a0, a1, skip_65_20
addi s0, a0, 1
skip_65_20: nop
bne t0, t0, skip_65_21
addi a1, t0, 1
skip_65_21: nop
sw a2, 4(s1)
and a2, a1, t1
xor s0, a2, t1
amoadd.w t1, t1, (s1)
lh a2, 0(s1)
sb a2, 12(s1)
jal ra, sub_65_1
rem t2, t1, t1
srl t2, t2, t1
div a2, a2, a2
lhu t0, 4(s1)
slti a1, t0, 31
lh s0, 0(s1)
mulhu a2, s0, s0
sh s0, 8(s1)
csrrw a1, mscratch, a0
csrrs a2, mscratch, zero
lhu a2, 4(s1)
and t0, a2, a2
sb t1, 12(s1)
sw s0, 8(s1)
mulhu a1, t0, a2
sw a2, 0(s1)
rem t2, a1, s0
mulhu s0, t2, a2
lw a1, 0(s1)
j end_main
sub_65_0:
mulhu t0, t2, a0
and t2, a1, a2
and t0, a0, t1
slt s0, t1, a1
ret
sub_65_1:
or a1, t0, a1
srl a2, a2, s0
sltu a0, a0, t2
sub t0, t0, t2
ret
end_main:
mv a0, s0
ecall
