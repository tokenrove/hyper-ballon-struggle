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

        ldr r2, =debounce
        ldrh r3, [r2]
        tst r3, #0b1000		@ start button
        beq 0b

        @@ make noise
        mov r0, #4
        mov r1, #0
        @@ 0b0001 iiii  iidd dDDD
        ldr r2, =0b0001000000010000
        bl music_play_sfx

        ldmfd sp!, {pc}

@ EOF util.s
