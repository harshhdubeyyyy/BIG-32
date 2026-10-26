li t0, -32
li t1, -87
li t2, 85
li a0, 31
li a1, 23
li a2, -6
li s0, 4
li s1, 256
and s0, a0, s0
jal ra, sub_52_0
sw t1, 4(s1)
sra t1, a2, t2
div a0, t0, s0
csrrw a0, mscratch, t0
csrrs a1, mscratch, zero
andi t2, a1, 37
sh t1, 0(s1)
slti s0, a2, 45
lhu t1, 12(s1)
slli t1, t1, 11
xor a2, t1, t1
slt a1, a2, t0
and a2, a1, t1
sb t1, 12(s1)
lhu t1, 12(s1)
sw t1, 4(s1)
xor a1, t1, t2
and t0, a1, a1
slt a2, t0, a0
lr.w t0, (s1)
addi t0, t0, 1
sc.w t2, t0, (s1)
slli t0, t1, 9
sll a2, t0, t1
lb t2, 0(s1)
div t2, t2, t0
csrrw s0, mscratch, s0
csrrs t1, mscratch, zero
sll t2, t1, t2
ori t1, a2, -42
sh t0, 4(s1)
remu t2, t2, t2
lw a1, 12(s1)
slt a2, a1, t0
sra a2, a2, a0
xor t0, a2, a2
j end_main
sub_52_0:
xor t0, s0, s0
slt t2, t1, s0
sll t0, a1, t1
sub t1, a2, t2
ret
end_main:
mv a0, s0
ecall
