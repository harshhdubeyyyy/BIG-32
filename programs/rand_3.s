li t0, -40
li t1, 51
li t2, 39
li a0, -67
li a1, -6
li s0, 54
li s1, 256
xori t0, a1, 2
slti t1, s0, 57
and t1, t1, s0
lw a1, 0(s1)
add t0, t1, a1
sltu t0, t2, a0
srli a0, s0, 28
bne t2, t0, skip_3_14
addi t1, t2, 1
skip_3_14: nop
mul a0, t1, t2
slt s0, t2, a0
sw a1, 0(s1)
sltiu a1, t1, -57
sw s0, 0(s1)
sltu t2, a1, a1
rem s0, t1, s0
bne t2, t0, skip_3_24
addi t2, t2, 1
skip_3_24: nop
sll s0, a0, t0
sw t0, 0(s1)
sltu a0, t0, t0
slti t0, a0, 20
addi t2, a1, 15
add t0, a1, a1
bne t2, a1, skip_3_33
addi a0, t2, 1
skip_3_33: nop
sll s0, t0, t2
sra t1, a0, a0
lw a0, 0(s1)
ori t0, a1, 46
xori s0, t1, 2
xori a1, t2, 16
and a1, a1, s0
sll s0, t2, a0
ori t2, a1, 61
sll t0, s0, t0
sltu a0, t2, a1
divu t2, t1, t2
mv a0, s0
ecall
