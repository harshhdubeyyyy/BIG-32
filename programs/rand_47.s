li t0, -10
li t1, -84
li t2, 10
li a0, 41
li a1, 16
li s0, 46
li s1, 256
add a0, a0, a1
sw t0, 0(s1)
add a0, s0, a1
lw t2, 0(s1)
sra a1, a1, t2
bne a1, t2, skip_47_12
addi t0, a1, 1
skip_47_12: nop
srai t2, a1, 12
sll s0, t0, t1
slt a1, a0, a1
sw t1, 0(s1)
lw t2, 0(s1)
srai a0, a1, 18
lw t1, 0(s1)
xor a1, t0, a0
slti a0, t2, -8
xori s0, t1, 0
bne t1, a0, skip_47_25
addi a1, t1, 1
skip_47_25: nop
divu t1, a1, s0
srai t0, t2, 30
sw t0, 0(s1)
sltiu s0, a1, 56
lw s0, 0(s1)
sltiu t1, t2, -17
and t1, t1, t0
srli a1, t2, 6
srl t0, s0, t0
and t0, t2, t0
divu a1, a0, t1
srai a0, a1, 0
ori t1, t1, -53
mv a0, s0
ecall
