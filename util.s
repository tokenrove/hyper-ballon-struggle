@
@ Some utility functions
@

	.section .text
	.arm
	.align

@
@ memcpy_h(dst, src, len) -- Copies len bytes from src to dst, in halfword
@   chunks.  Assumes len is a multiple of two, and that src and dst are
@   word aligned.
@
	.global memcpy_h
memcpy_h:
1:	ldrh r3,[r1],#2
	strh r3,[r0],#2
	subs r2,r2,#2
	bgt 1b
	@ Return
	bx lr

        .global zero_h
zero_h:
        mov r2, #0
1:      strh r2,[r0],#2
        subs r1,r1,#2
        bgt 1b
        @ Return
        bx lr

        .include "gba.inc"
        .global wait_for_start_toggled
        @@ wait for user to press and release start
wait_for_start_toggled:
        stmfd sp!, {lr}
0:
        bl gfx_wait_vblank

        mov r2, #reg_base
        add r2, r2, #0x130
        ldrh r3, [r2]   @ REG_KEY
        tst r3, #0b1000		@ start button
        bne 0b

1:      bl gfx_wait_vblank

        mov r2, #reg_base
        add r2, r2, #0x130
        ldrh r3, [r2]   @ REG_KEY
        tst r3, #0b1000		@ start button
        beq 1b

        ldmfd sp!, {pc}


@ EOF util.s
