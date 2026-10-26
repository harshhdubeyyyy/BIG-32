li t0, 17
li t1, 48
li t2, 34
li a0, -92
li a1, -38
li a2, -28
li s0, 70
li s1, 256
div t2, a2, a0
sb t0, 4(s1)
lb a0, 8(s1)
mulhu t2, a0, t1
sh t0, 0(s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w s0, t2, (s1)
andi a2, t1, 15
lb t2, 4(s1)
sw t2, 4(s1)
lbu a1, 8(s1)
sra s0, a1, t1
srli a0, a2, 29
andi a1, a1, -47
bge t1, a1, skip_40_13
addi s0, t1, 1
skip_40_13: nop
mulh a2, s0, t0
xori a1, t0, -3
csrrw a0, mscratch, s0
csrrs s0, mscratch, zero
rem t1, t1, t2
lb t1, 4(s1)
mulhu t1, t1, t0
sh a2, 12(s1)
sltiu a1, t1, 38
bne s0, t1, skip_40_22
addi t0, s0, 1
skip_40_22: nop
ori s0, t0, 36
lhu s0, 0(s1)
sh s0, 12(s1)
slt a2, s0, t0
blt t0, a1, skip_40_27
addi a1, t0, 1
skip_40_27: nop
slti s0, t0, -58
andi t2, t0, -58
or a2, t2, s0
addi a1, a0, -20
xori a0, t0, 58
sra a2, a0, t1
j end_main
sub_40_0:
srl s0, t2, a1
sra s0, a2, s0
sra s0, t0, t1
sll a0, a2, a2
ret
end_main:
mv a0, s0
ecall
