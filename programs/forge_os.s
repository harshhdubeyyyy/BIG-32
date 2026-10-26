_start:
    li sp, 65532
    li t0, 4096
    li t1, 102
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 111
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 114
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 103
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 101
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 32
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 79
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 83
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 32
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 111
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 110
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 32
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 98
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 105
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 103
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 51
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 50
    sb t1, 0(t0)
    addi t0, t0, 1
    sb zero, 0(t0)
    li t0, 4116
    li t1, 98
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 111
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 111
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 116
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 32
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 111
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 107
    sb t1, 0(t0)
    addi t0, t0, 1
    sb zero, 0(t0)
    li t0, 4124
    li t1, 97
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 112
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 112
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 95
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 115
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 117
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 109
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 32
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 61
    sb t1, 0(t0)
    addi t0, t0, 1
    sb zero, 0(t0)
    li t0, 4136
    li t1, 97
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 112
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 112
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 95
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 109
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 117
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 108
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 32
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 61
    sb t1, 0(t0)
    addi t0, t0, 1
    sb zero, 0(t0)
    li t0, 4148
    li t1, 100
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 111
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 110
    sb t1, 0(t0)
    addi t0, t0, 1
    li t1, 101
    sb t1, 0(t0)
    addi t0, t0, 1
    sb zero, 0(t0)
    jal ra, main
    ecall
app_sum:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)
    mv s0, sp
    addi sp, sp, -2048
    li t0, 0
    sw t0, -4(s0)
    li t1, 1
    sw t1, -8(s0)
while_1:
    lw t2, -8(s0)
    li t3, 10
    slt t2, t3, t2
    xori t2, t2, 1
    beq t2, zero, wend_2
    lw t4, -4(s0)
    lw t5, -8(s0)
    add t4, t4, t5
    sw t4, -4(s0)
    lw t6, -8(s0)
    li a1, 1
    add t6, t6, a1
    sw t6, -8(s0)
    j while_1
wend_2:
    lw a2, -4(s0)
    mv a0, a2
    j app_sum_epilogue
app_sum_epilogue:
    mv sp, s0
    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret
app_mul:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)
    mv s0, sp
    addi sp, sp, -2048
    li t0, 6
    li t1, 7
    mul t0, t0, t1
    mv a0, t0
    j app_mul_epilogue
app_mul_epilogue:
    mv sp, s0
    lw s0, 0(sp)
    lw ra, 4(sp)
    addi sp, sp, 8
    ret
main:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw s0, 0(sp)
    mv s0, sp
    addi sp, sp, -2048
    li t0, 4096
    mv a0, t0
    jal ra, forge_print_str
    li t0, 268435456
    li t1, 10
    sb t1, 0(t0)
    li t1, 4116
    mv a0, t1
    jal ra, forge_print_str
    li t0, 268435456
    li t1, 10
    sb t1, 0(t0)
    li t2, 4124
    mv a0, t2
    jal ra, forge_print_str
    li t0, 268435456
    li t1, 32
    sb t1, 0(t0)
    jal ra, app_sum
    mv t3, a0
    mv a0, t3
    jal ra, forge_print_int
    li t0, 268435456
    li t1, 10
    sb t1, 0(t0)
    li t4, 4136
    mv a0, t4
    jal ra, forge_print_str
    li t0, 268435456
    li t1, 32
    sb t1, 0(t0)
    jal ra, app_mul
    mv t5, a0
    mv a0, t5
    jal ra, forge_print_int
    li t0, 268435456
    li t1, 10
    sb t1, 0(t0)
    li t6, 4148
    mv a0, t6
    jal ra, forge_print_str
    li t0, 268435456
    li t1, 10
    sb t1, 0(t0)
    li a1, 0
    mv a0, a1
    ecall
    ecall
forge_print_str:
    addi sp, sp, -4
    sw ra, 0(sp)
forge_print_str_loop:
    lb t0, 0(a0)
    beq t0, zero, forge_print_str_done
    li t1, 268435456
    sb t0, 0(t1)
    addi a0, a0, 1
    j forge_print_str_loop
forge_print_str_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
forge_print_int:
    addi sp, sp, -4
    sw ra, 0(sp)
    li t0, -2147483648
    bne a0, t0, forge_print_int_sign
    li t0, 268435456
    li t1, 45
    sb t1, 0(t0)
    li a0, -2147483648
    j forge_print_int_push_u
forge_print_int_sign:
    blt a0, zero, forge_print_int_neg
    j forge_print_int_digits
forge_print_int_neg:
    li t0, 268435456
    li t1, 45
    sb t1, 0(t0)
    sub a0, zero, a0
forge_print_int_digits:
    beq a0, zero, forge_print_int_zero
    mv t3, sp
    li t2, 10
forge_print_int_push:
    beq a0, zero, forge_print_int_pop
    rem t0, a0, t2
    addi t0, t0, 48
    addi sp, sp, -4
    sw t0, 0(sp)
    div a0, a0, t2
    j forge_print_int_push
forge_print_int_push_u:
    mv t3, sp
    li t2, 10
forge_print_int_push_u_loop:
    beq a0, zero, forge_print_int_pop
    remu t0, a0, t2
    addi t0, t0, 48
    addi sp, sp, -4
    sw t0, 0(sp)
    divu a0, a0, t2
    j forge_print_int_push_u_loop
forge_print_int_pop:
    beq sp, t3, forge_print_int_done
    lw t0, 0(sp)
    addi sp, sp, 4
    li t1, 268435456
    sb t0, 0(t1)
    j forge_print_int_pop
forge_print_int_zero:
    li t0, 268435456
    li t1, 48
    sb t1, 0(t0)
forge_print_int_done:
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
forge_strlen:
    li t0, 0
forge_strlen_loop:
    lb t1, 0(a0)
    beq t1, zero, forge_strlen_done
    addi a0, a0, 1
    addi t0, t0, 1
    j forge_strlen_loop
forge_strlen_done:
    mv a0, t0
    ret
