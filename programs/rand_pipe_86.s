li t0, 99
li t1, -93
li t2, 42
li a0, -19
li a1, 90
li a2, -97
li s0, 96
li s1, 256
remu t2, s0, a2
srl s0, t2, t0
slli a1, s0, 13
xori s0, s0, 8
csrrw a0, mscratch, a0
csrrs t0, mscratch, zero
xori a0, t1, 31
slli s0, a0, 13
rem t0, s0, a0
ori a2, a2, 35
lh a0, 4(s1)
lbu s0, 12(s1)
slli t0, s0, 11
or a0, t0, s0
sw a2, 0(s1)
divu t0, t2, a0
slli t0, a1, 21
divu a0, a2, a2
sh a2, 4(s1)
rem t0, a2, a2
lw t0, 8(s1)
sra s0, t0, t1
xori t2, a1, 21
csrrw t0, mscratch, t0
csrrs t1, mscratch, zero
xor a0, t1, s0
remu a0, s0, a2
sltiu s0, t2, -7
amoadd.w t2, s0, (s1)
xor t0, t2, a1
ori t1, t1, -23
div t2, t0, a0
mulhu t0, t2, s0
divu a1, a2, t2
sub t1, a1, t1
amoadd.w a2, t0, (s1)
and a2, a2, a1
slt a1, a2, t2
remu a1, t2, t1
amoadd.w a1, t0, (s1)
amoadd.w t1, a1, (s1)
lbu t1, 4(s1)
lb a0, 8(s1)
and t1, a0, s0
xori a1, t2, -45
jal ra, sub_86_0
xor t1, t0, t1
sb t1, 4(s1)
j end_main
sub_86_0:
mulhu a0, s0, a0
xor a1, a0, s0
add t2, t1, a0
add a2, t1, a1
ret
end_main:
mv a0, s0
ecall
