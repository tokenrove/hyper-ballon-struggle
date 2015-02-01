@
@ balloon fight
@ tokenrove / 2002
@

	.section .text
	.arm
	.align

	.include "gba.inc"
        .include "game.inc"
        .include "archetype.inc"
        .include "arenas.inc"

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
        ldr r5, =levels
metagame:
        @@ r0 = archetype
        @@ r1 = palette
        @@ r2 = next opponent
        @@ r3 = opponent palette
        @@ r4 = arena
        @@ r5 = level ptr
        @@ select next opponent
        ldrh r3, [r5], #2
        ldrb r2, [r5], #1
        @@ select an arena
        ldrb r4, [r5], #1
        stmfd sp!, {r0,r1,r5}
        @@ call challenge
        bl challenge
        @@ call play_game(us, color, them, color, arena)
        bl play_game
        @@ we get back an outcome r0 -- lose or win
        mov r6, r0
        cmp r6, #OUTCOME_LOSE
        beq game_over

        bl victory

        ldmfd sp!, {r0,r1,r5}
        @@ are there more opponents?
        ldr r6, =levels_end     @ &levels_len is also the end of levels
        cmp r5, r6
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

        bl random_init

        @@ as a default; every screen sets its own mode
        bl gfx_set_mode_1

        @@ Setup fonts
        bl font_load

        @@ Setup interrupts and start playing music
        bl music_init
        bl intr_init

        ldr r4, =instrument_bank_0
        ldmia r4!, {r0-r3}
        bl music_set_instruments

        @@ black to begin
        mov r0, #palram_base
        mov r1, #0
        str r1, [r0]

        @@ unblank the display
        ldr r0, =REG_DISPCNT
        ldrh r1, [r0]
        bic r1, r1, #1<<7
        strh r1, [r0]

        ldmfd sp!, {pc}

        .section .rodata

        @@ levels format:
        @@ one byte each: palette, alt. palette, character, arena
        @@ Palette first so we can load both together as a 16-bit load
        .align
levels:
        .byte PALETTE_PINK
        .byte PALETTE_CYAN
        .byte CHAR_MYR
        .byte ARENA_GOBACKTOSPACE

        .byte PALETTE_SALMON
        .byte PALETTE_SLATE_BLUE
        .byte CHAR_ICECLOWN
        .byte ARENA_LOZENGE

        .byte PALETTE_GREEN
        .byte PALETTE_YELLOW
        .byte CHAR_RUDOLPH
        .byte ARENA_DEFAULT

        .byte PALETTE_PURPLE
        .byte PALETTE_RED
        .byte CHAR_MONOCLE
        .byte ARENA_VTUBE
levels_end:

@ EOF main.s
