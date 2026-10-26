li t0, 66
li t1, 22
li t2, 79
li a0, -30
li a1, -27
li s0, -50
li s1, 256
sll a1, t2, t2
sw t1, 0(s1)
lw a0, 0(s1)
lw a1, 0(s1)
addi a0, a0, 48
bne s0, a0, skip_27_12
addi t0, s0, 1
skip_27_12: nop
mul a1, t2, a1
srl a1, t1, t0
srai s0, t0, 5
slt s0, t1, t2
bne s0, t0, skip_27_19
addi t1, s0, 1
skip_27_19: nop
slti t1, t2, 42
add a0, a0, t2
sll t2, t1, a0
lw t0, 0(s1)
sub s0, a0, a1
mul t0, a0, t2
div t2, a1, s0
slt a0, a0, t2
remu t0, t2, t1
slli a1, a1, 0
sltiu t2, t1, -40
mv a0, s0
ecall
