li t0, -91
li t1, -27
li t2, 78
li a0, 95
li a1, -64
li s0, 18
li s1, 256
xori t0, a0, -60
slti a1, t2, 47
srl t0, t0, t0
and t1, a1, a0
srai a1, a1, 11
and t0, a1, t0
bne t2, t2, skip_43_13
addi t1, t2, 1
skip_43_13: nop
lw a1, 0(s1)
bne s0, s0, skip_43_17
addi a1, s0, 1
skip_43_17: nop
sltiu t0, a1, 20
and s0, s0, a0
remu t0, t2, t0
sltiu t2, s0, -46
bne s0, t0, skip_43_24
addi a1, s0, 1
skip_43_24: nop
srl s0, t2, s0
sll a0, a1, t0
and t0, s0, s0
slti t2, t0, 44
sub t0, t1, t0
lw t0, 0(s1)
slt t2, t0, s0
xori s0, a0, -42
srai t0, s0, 25
sltu a1, a0, t2
addi t2, a0, -17
addi t1, s0, -5
bne t2, t1, skip_43_39
addi t1, t2, 1
skip_43_39: nop
slli a0, a0, 29
slti t0, t0, -36
xori t2, t1, 36
or t0, t0, s0
mv a0, s0
ecall
