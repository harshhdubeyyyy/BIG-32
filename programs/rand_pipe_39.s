li t0, -47
li t1, -34
li t2, -2
li a0, -94
li a1, -51
li a2, -44
li s0, 1
li s1, 256
amoadd.w a2, a2, (s1)
mul s0, a2, t2
csrrw t0, mscratch, t2
csrrs t0, mscratch, zero
mulhu t2, t0, s0
xor a0, t2, a1
xor t0, a0, a0
sb a2, 0(s1)
lhu a1, 12(s1)
amoadd.w s0, t2, (s1)
slti t2, a0, 46
xor t2, t2, s0
sub a2, t2, a2
slti a2, s0, -42
sltiu t0, a2, 43
mul a1, t0, a1
slti t1, s0, -8
slt a0, t1, t1
csrrw s0, mscratch, t1
csrrs s0, mscratch, zero
csrrw a2, mscratch, t1
csrrs t1, mscratch, zero
sh a0, 8(s1)
lr.w s0, (s1)
addi s0, s0, 1
sc.w s0, s0, (s1)
sb s0, 4(s1)
xor t1, s0, t2
sub t0, t1, a1
csrrw t0, mscratch, t0
csrrs a2, mscratch, zero
csrrw t0, mscratch, s0
csrrs a0, mscratch, zero
jal ra, sub_39_0
and t1, t1, t2
xori t0, s0, -47
andi a1, t0, -11
ori a2, a0, -27
lb a0, 8(s1)
addi a0, a0, 58
srl t2, a0, a1
bne t0, t2, skip_39_34
addi a1, t0, 1
skip_39_34: nop
blt a1, a2, skip_39_35
addi t0, a1, 1
skip_39_35: nop
lr.w t2, (s1)
addi t2, t2, 1
sc.w t1, t2, (s1)
div t0, a1, a0
jal ra, sub_39_0
jal ra, sub_39_0
srai a1, t0, 7
or t2, a1, s0
ori t0, s0, 59
sll t0, t0, t0
mul a1, t0, t1
add a0, a1, a1
bge t2, a2, skip_39_46
addi a1, t2, 1
skip_39_46: nop
sltu s0, a1, a0
bne t2, t2, skip_39_48
addi t1, t2, 1
skip_39_48: nop
srai t2, a2, 31
j end_main
sub_39_0:
add t2, s0, t0
srl a2, a0, t2
srl s0, t0, a0
or a0, a0, a1
ret
end_main:
mv a0, s0
ecall
