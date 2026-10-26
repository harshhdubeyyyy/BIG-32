li t0, 35
li t1, -9
li t2, 49
li a0, -93
li a1, -42
li a2, -93
li s0, -1
li s1, 256
srai t2, t2, 9
mulhu t2, t2, t0
add a1, t2, s0
addi a2, a1, 35
blt s0, a2, skip_34_4
addi a1, s0, 1
skip_34_4: nop
xori t2, t1, -19
lhu a1, 12(s1)
sub a2, a1, s0
lbu a2, 8(s1)
andi a1, a2, -20
addi s0, t2, 57
srli a0, t2, 17
sub t1, a0, t2
blt t0, a1, skip_34_13
addi a1, t0, 1
skip_34_13: nop
ori t1, a0, 26
jal ra, sub_34_1
srl a2, t0, t2
xori s0, t1, 23
sb t0, 8(s1)
sh t1, 0(s1)
sb a2, 12(s1)
divu t2, a2, a2
srai t1, a2, 24
jal ra, sub_34_1
lbu s0, 12(s1)
sltu s0, s0, a0
sw t1, 12(s1)
slti a1, t2, 52
srli a0, a1, 28
lw s0, 4(s1)
xor a1, s0, a2
lbu t2, 12(s1)
j end_main
sub_34_0:
slt s0, t2, t1
slt a1, t2, t0
sll t2, s0, s0
ret
sub_34_1:
mulhu t2, t2, a2
add a2, t2, t2
srl t1, a1, a0
add t0, t0, a2
ret
end_main:
mv a0, s0
ecall
