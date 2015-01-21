@
@ Some utility functions
@

	.section .text
	.arm
	.align

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

        @@ make noise
        mov r0, #4
        mov r1, #0
        @@ 0b0001 iiii  iidd dDDD
        ldr r2, =0b0001000000010000
        bl music_play_sfx

1:      bl gfx_wait_vblank

        mov r2, #reg_base
        add r2, r2, #0x130
        ldrh r3, [r2]   @ REG_KEY
        tst r3, #0b1000		@ start button
        beq 1b

        ldmfd sp!, {pc}

@ EOF util.s
