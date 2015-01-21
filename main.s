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
        @@ as a default; every screen sets its own mode
        bl gfx_set_mode_1

        @ Wipe VRAM
        mov r0, #vram_base
        mov r1, #0x18000
        mov r2, #0
1:	str r2, [r0], #4
        subs r1, r1, #4
        bne 1b

        @ Setup fonts
        bl font_load

        @ Set a blue background
        mov r0, #palram_base
        mov r1, #0x005e
        strh r1, [r0]
        mov r1, #0x7e00
        strh r1, [r0], #2

        @@ Load sprites into VRAM
        @@ We just dump everything in, because we are lazy and don't
        @@ have a lot of data.  If this grows, we'll need to instead
        @@ dynamically copy sprite tiles into VRAM as we need them.
        mov r0, #vram_base
        add r0, r0, #0x10000
        ldr r1, =sprite_data_begin
        ldr r2, =sprite_data_end
        sub r2, r2, r1
        bl memcpy_h

        @ Load sprite palette
        ldr r0, =sprite_palette
        bl gfx_set_spr_palette

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
