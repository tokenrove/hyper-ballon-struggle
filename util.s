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

        @@ r0 = word to print
        .global print_debug_word
print_debug_word:
        mov r3, #vram_base	@ beginning
        ldr r2, =hex_xlat
        .macro m_print n=32
          lsr r1, r0, #\n-4
          and r1, r1, #0xf
          ldrb r1, [r2, r1]
          strh r1, [r3], #2
          .if \n-4
          m_print "(\n-4)"
          .endif
        .endm
        m_print
        mov pc,lr

        .section .rodata
hex_xlat:
        .byte 32+26, 32+27, 32+28, 32+29, 32+30, 32+31, 32+32, 32+33, 32+34
        .byte 32+35, 32, 32+1, 32+2, 32+3, 32+4, 32+5

@ EOF util.s
