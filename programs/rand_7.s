li t0, -18
li t1, -62
li t2, 1
li a0, 66
li a1, -88
li s0, -82
li s1, 256
or a1, t0, a1
or a0, a0, t0
sub a0, t0, a1
bne s0, a1, skip_7_10
addi s0, s0, 1
skip_7_10: nop
bne a1, a0, skip_7_13
addi a1, a1, 1
skip_7_13: nop
rem t1, t0, a1
sub a0, t1, a1
addi a1, s0, -16
sltu a1, s0, t0
slt t1, a0, s0
remu t2, a0, a1
sltiu t2, t1, -2
remu t2, a1, a0
sub a0, t2, a1
and a0, t1, t2
lw a0, 0(s1)
sll a1, a1, t2
xori a1, a0, -47
sw s0, 0(s1)
ori t0, s0, 50
add a0, s0, t2
bne t1, a1, skip_7_32
addi t2, t1, 1
skip_7_32: nop
and t0, t1, t2
slli a0, a0, 10
rem a1, t2, t1
srl a1, t2, s0
bne a0, t1, skip_7_39
addi s0, a0, 1
skip_7_39: nop
mul t1, t1, t1
xor a0, a1, t1
sll t1, a0, a1
slti t2, t1, -51
xori s0, a1, 38
add a0, s0, a0
sub t1, a0, t1
sltu t0, t0, t0
add t0, t2, a1
and t1, a1, a0
mv a0, s0
ecall
