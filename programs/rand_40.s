li t0, 17
li t1, 48
li t2, 34
li a0, -92
li a1, -38
li s0, -28
li s1, 256
sltiu t1, t2, 48
sw t1, 0(s1)
sra t1, a1, s0
sw a1, 0(s1)
divu t2, t2, t1
addi a1, t0, 16
slli t2, t1, 19
sra t2, s0, t2
sw t1, 0(s1)
slti a1, t0, -12
xori a1, t0, 13
sub t1, a0, a0
xori s0, t2, 8
sw t0, 0(s1)
bne a1, a0, skip_40_21
addi t1, a1, 1
skip_40_21: nop
rem s0, a0, t0
srli t1, a1, 30
sltiu t1, t1, -15
sub t2, t2, s0
add t2, t1, t1
or t0, a1, t1
xor a0, a0, t2
addi t0, s0, -24
ori t1, t2, 28
slt s0, a0, t2
srli a1, a1, 30
slt s0, a1, t0
lw a1, 0(s1)
sltu s0, t0, t0
addi a1, t0, 2
bne t1, a1, skip_40_39
addi t1, t1, 1
skip_40_39: nop
andi t0, s0, 22
lw a0, 0(s1)
xori t1, t2, -40
remu a0, a0, t2
srli t1, a0, 21
addi a0, s0, -13
and t2, s0, s0
lw a0, 0(s1)
srai a1, t0, 10
mv a0, s0
ecall
