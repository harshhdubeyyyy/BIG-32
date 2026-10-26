li t0, -16
li t1, -86
li t2, -95
li a0, -28
li a1, -80
li s0, -100
li s1, 256
sltiu t1, t2, 46
sltu t2, a1, t0
divu a0, a0, t2
sw t1, 0(s1)
slt a0, s0, t1
sll a0, s0, a1
srai a1, t1, 24
lw a0, 0(s1)
remu t2, t1, a0
lw t2, 0(s1)
slt a1, a0, s0
xor s0, t0, t1
div t1, t1, t0
slt t2, a0, s0
and a0, t2, a0
addi s0, t2, 52
and s0, s0, t2
slli t1, a1, 30
lw t2, 0(s1)
remu t2, s0, a1
sub t0, a0, s0
srl t0, t2, a0
xor t2, t1, t1
addi t0, s0, -32
xori t2, t2, -56
addi a0, t0, 19
srl t1, t2, t0
sub t2, t2, t2
xori a0, a0, 38
lw t1, 0(s1)
bne a1, s0, skip_36_37
addi s0, a1, 1
skip_36_37: nop
sub t1, s0, t0
slli s0, a1, 9
addi s0, t0, 61
slti a1, t0, 44
mul a0, a1, s0
mv a0, s0
ecall
