li t0, 33
li t1, 6
li t2, -23
li a0, -7
li a1, -26
li a2, -56
li s0, 96
li s1, 256
bge a0, s0, skip_17_0
addi t1, a0, 1
skip_17_0: nop
mul a1, t1, t2
lr.w a2, (s1)
addi a2, a2, 1
sc.w t1, a2, (s1)
jal ra, sub_17_0
mulhu a2, a1, a1
beq t2, a1, skip_17_5
addi t1, t2, 1
skip_17_5: nop
csrrw a2, mscratch, t0
csrrs t2, mscratch, zero
sltiu a1, s0, -28
lh a0, 0(s1)
srai a1, a0, 22
mulhu a0, a1, a1
slt a0, a0, t0
add t1, a0, t2
mulh s0, t1, t1
lb a1, 8(s1)
lb t2, 8(s1)
mulhu a1, t2, a1
sll t0, a1, s0
mul a2, t0, a0
sub t1, a2, t2
divu a2, a0, t0
xori a2, a1, -18
sub t2, a2, a2
csrrw t0, mscratch, s0
csrrs a1, mscratch, zero
addi t2, s0, -23
blt a2, s0, skip_17_25
addi t0, a2, 1
skip_17_25: nop
lr.w a2, (s1)
addi a2, a2, 1
sc.w a0, a2, (s1)
or t0, a0, a2
mulhu t2, t0, t1
xori a2, a0, 60
sra a0, a2, a2
or a0, a0, t1
sb t2, 0(s1)
j end_main
sub_17_0:
sltu a1, a1, a0
sll t0, a1, t1
or a1, a1, t2
and t2, s0, t1
ret
sub_17_1:
sll a0, a0, a1
slt t0, t0, a1
or t0, a1, a2
ret
end_main:
mv a0, s0
ecall
