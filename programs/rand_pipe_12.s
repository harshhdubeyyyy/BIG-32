li t0, 21
li t1, -32
li t2, 68
li a0, 35
li a1, 70
li a2, -11
li s0, -64
li s1, 256
jal ra, sub_12_1
lw a1, 4(s1)
jal ra, sub_12_1
csrrw t0, mscratch, a1
csrrs s0, mscratch, zero
sll a1, s0, s0
lw s0, 0(s1)
amoadd.w a2, a1, (s1)
mul a0, a2, t0
srai t1, a1, 10
jal ra, sub_12_0
xori a0, a2, 58
lw a1, 4(s1)
jal ra, sub_12_1
blt a2, a0, skip_12_13
addi s0, a2, 1
skip_12_13: nop
sll t1, s0, t2
sw a1, 0(s1)
slti s0, a0, -58
or a0, s0, a0
divu t0, s0, a1
srl a2, t0, t0
mulh t2, a2, a2
sll a0, t2, t1
xori a0, a2, -3
blt a0, a1, skip_12_23
addi t1, a0, 1
skip_12_23: nop
sltu s0, t1, t1
sll t2, s0, s0
add s0, t2, a1
slt t0, s0, a1
xor t2, t0, a2
lhu t1, 12(s1)
j end_main
sub_12_0:
sll a2, t2, a2
mulh a0, t1, a0
sltu t2, s0, t0
ret
sub_12_1:
slt t2, a2, a2
mulh a0, s0, t1
xor a2, a1, t2
ret
end_main:
mv a0, s0
ecall
