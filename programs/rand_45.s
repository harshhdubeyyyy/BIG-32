li t0, -31
li t1, 6
li t2, 24
li a0, -35
li a1, -80
li s0, -23
li s1, 256
xor a0, t0, t0
sw s0, 0(s1)
xor a1, t0, t1
sw t1, 0(s1)
bne a0, t0, skip_45_11
addi s0, a0, 1
skip_45_11: nop
addi t1, s0, -20
sub t2, s0, t2
divu t0, t2, t2
slt s0, a1, s0
lw s0, 0(s1)
xori a1, s0, 31
lw t2, 0(s1)
sw s0, 0(s1)
xori t2, t1, 33
slt a0, a1, t0
sltu a1, a1, t0
sw a1, 0(s1)
slli t2, t2, 0
addi t0, a0, 28
ori a0, a0, 5
bne s0, a1, skip_45_29
addi s0, s0, 1
skip_45_29: nop
bne a0, t0, skip_45_32
addi t1, a0, 1
skip_45_32: nop
rem t0, a1, t2
addi t1, a1, -41
and t1, a0, a1
sra s0, s0, s0
sw t2, 0(s1)
div a0, a0, t1
slti t0, t0, 42
or t2, a0, a1
mv a0, s0
ecall
