li t0, 91
li t1, -49
li t2, 68
li a0, -48
li a1, 10
li s0, 53
li s1, 256
mul a0, t0, s0
andi t1, s0, 40
srai t1, s0, 14
rem t1, a1, a0
srai a0, t2, 1
slt s0, t2, a1
sra t0, s0, t0
sltiu a1, t2, 44
remu s0, t1, t0
bne a1, a0, skip_26_16
addi t1, a1, 1
skip_26_16: nop
lw a1, 0(s1)
slt t0, t1, a1
slli t0, t0, 23
addi t0, a1, 40
sw a0, 0(s1)
sltiu t0, t2, -3
sw t2, 0(s1)
srl a1, s0, s0
div a0, a1, a0
add t0, t1, a1
addi a1, s0, -18
sw t0, 0(s1)
sw a0, 0(s1)
sub t2, t1, t0
xori t0, t0, -59
sw t2, 0(s1)
addi a1, s0, -39
xor t1, a0, t1
srl a1, a1, a0
slti t2, s0, -48
slli s0, t0, 25
sll t0, t1, t2
or t1, s0, a0
add s0, t0, t0
div t0, t1, a1
slt a1, s0, s0
add t1, a1, t0
mv a0, s0
ecall
