@
@ balloon fight
@ tokenrove / 2002
@

	.section .text
	.arm
	.align

	.include "gba.inc"
        .include "constants.inc"

@ main
@   program entry point.  never returns.
	.global main
main:
        @@ initialize things
        bl init
@@@ FOREVER
forever:
        @@ call the title sequence
        bl title_screen

        @@ title can return either START or DEMO, but we haven't
        @@ implemented demo mode.

        @@ call the select screen
        bl select_character
        @@ we get back r0 (selected character archetype) and r1 (palette)

        @@ while there are more opponents to challenge, challenge them
metagame:
        @@ select next opponent
        @@ select an arena
        @@ call challenge
        bl challenge
        @@ call play_game(us, color, them, color, arena)
        stmfd sp!, {r0,r1}
        mov r4, #0
        bl play_game
        @@ we get back an outcome r0 -- lose or win
        mov r5, r0
        ldmfd sp!, {r0,r1}
        cmp r5, #OUTCOME_LOSE
        beq game_over

        bl victory

        @@ are there more opponents?
        ldr r1, =levels_end     @ &levels_len is also the end of levels
        cmp r0, r1
        blt metagame

        @@ if you got here, you won!  congratulations!
        bl roll_credits
        b forever

game_over:
        bl display_gameover
        b forever
@ EOR main

        .local init
init:
        stmfd sp!, {lr}
        @@ disable video so we can write freely to VRAM
        ldr r0, =REG_DISPCNT
        ldrh r1, [r0]
        orr r1, r1, #1<<7
        strh r1, [r0]

        @@ as a default; every screen sets its own mode
        bl gfx_set_mode_1

        @@ Setup fonts
        bl font_load

        @@ Set a blue background of doom; if we see this, we died
        @@ somewhere before hitting the title screen.
        mov r0, #palram_base
        mov r1, #0x005e
        strh r1, [r0]
        mov r1, #0x7e00
        strh r1, [r0], #2

        @@ Setup interrupts and start playing music
        bl music_init
        bl intr_init

        mov r0, #0		    @ music idx
        ldr r4, =music_table
        add r4, r4, r0, lsl #2
        ldr r4, [r4]
        ldmia r4!, {r0-r3}
        bl music_set_instruments

        @@ unblank the display
        ldr r0, =REG_DISPCNT
        ldrh r1, [r0]
        bic r1, r1, #1<<7
        strh r1, [r0]

        ldmfd sp!, {pc}

        .section .rodata

.equ CHAR_RETSYN, 0
.equ ARENA_DEFAULT, 0

        @@ levels format:
        @@ one byte each: character, palette, alt. palette, arena
        .align
levels:
        .byte CHAR_RETSYN
        .byte 0
        .byte 1
        .byte ARENA_DEFAULT
levels_end:

@ EOF main.s
