# Phase 4 U-mode test program. Entry: kernel srets here at VA 0x3000
# (U R+X page); stack VA 0x4000 page (U R+W), top 0x5000.
# Assembled ONLY via tools/build_os.py (STRING lines + fixed layout).
# Syscalls (U ECALL, delegated to S, cause 8):
#   a7 = 1, a0 = string VA  -> print NUL-terminated string
#   a7 = 2, a0 = integer    -> print decimal integer (no newline)
#   a7 = 3, a0 = exit code  -> terminate (never returns)
# Flow: hello, sum 1..10 (= 55), then a load from the unmapped
# VA 0x60000000. That faults (load page fault 13); the kernel
# demand-maps the page and retries the load, which then reads 0
# from the fresh zeroed page. Then exit(0).
u_entry:
        li sp, 0x5000
        li a7, 1
        la a0, u_str_hello
        ecall
        li t0, 0
        li t1, 1
        li t2, 11
u_sum_loop:
        add t0, t0, t1
        addi t1, t1, 1
        blt t1, t2, u_sum_loop
        li a7, 1
        la a0, u_str_sum
        ecall
        mv a0, t0
        li a7, 2
        ecall
        li a7, 1
        la a0, u_str_nl
        ecall
        li t0, 0x60000000
        lw t2, 0(t0)
        li a7, 1
        la a0, u_str_fv
        ecall
        mv a0, t2
        li a7, 2
        ecall
        li a7, 1
        la a0, u_str_nl
        ecall
        li a0, 0
        li a7, 3
        ecall
u_str_hello: STRING "U: hello from user\n"
u_str_sum: STRING "U: sum="
u_str_fv: STRING "U: faultval="
u_str_nl: STRING "\n"
