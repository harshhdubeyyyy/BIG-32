li t0, 33
li t1, 6
li t2, -23
li a0, -7
li a1, -26
li s0, -56
li s1, 256
xori t0, t0, 43
rem a1, t2, s0
slti s0, a0, -49
slt t1, t1, s0
slti s0, t1, -33
lw s0, 0(s1)
sltu a1, a0, s0
add a0, a1, t2
sll a1, t0, s0
divu a0, t2, a1
slt a0, t1, t0
add t1, a1, t2
sltu t2, t1, s0
sw t1, 0(s1)
and t2, t2, t2
sll a1, a1, t2
div t2, t0, a0
or s0, t0, s0
remu t0, s0, s0
sltiu a1, a1, -29
and s0, a1, a0
sub t2, t1, s0
lw t0, 0(s1)
sw t0, 0(s1)
divu a0, t0, s0
sra t2, s0, a0
or t0, a1, s0
divu t2, a1, t1
srl s0, a0, a1
sw a0, 0(s1)
andi a0, t0, -6
addi t1, t2, 44
remu t2, a1, t1
bne a1, t2, skip_17_40
addi t1, a1, 1
skip_17_40: nop
sll t1, t2, a0
slt t0, a1, t0
divu a1, s0, a1
mv a0, s0
ecall
