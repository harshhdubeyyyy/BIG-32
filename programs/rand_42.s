li t0, 63
li t1, -72
li t2, -94
li a0, 89
li a1, -30
li s0, -38
li s1, 256
remu t0, s0, s0
addi a1, a0, -41
slt a1, a1, t0
srl s0, s0, a1
divu a1, t2, t0
sw t2, 0(s1)
sub t1, t2, t0
xor t2, t2, a1
sw a1, 0(s1)
xor a0, t0, a1
sw a1, 0(s1)
or t0, t0, s0
srli t0, t1, 17
ori t2, t1, -11
addi s0, s0, -21
xori t1, t1, 5
bne s0, a1, skip_42_23
addi s0, s0, 1
skip_42_23: nop
rem t2, t0, t1
sub t2, a0, t2
or a1, s0, t2
andi a0, s0, 3
xor s0, a1, a1
srli a0, a1, 14
bne a1, a0, skip_42_32
addi t1, a1, 1
skip_42_32: nop
mul t0, t0, t1
sub s0, a0, a1
xor a1, a0, a1
mv a0, s0
ecall
