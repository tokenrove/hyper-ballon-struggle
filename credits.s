
        .include "gba.inc"
        .section .text
        .align 2
        .global roll_credits
roll_credits:
        stmfd sp!, {lr}
        ldr r0, =sight_for_sore_thumbs_song_data
        bl music_play_song

        bl gfx_wait_vblank
        @@ Wipe the screen
        mov r0, #REG_DISPCNT
        mov r1, #0x40
        orr r1, r1, #0b00011<<8
        strh r1, [r0]

        ldr r0, =credits_lines
        mov r1, #8
        mov r2, #8
        mov r3, #17
1:      bl font_putstring_return_end
        add r2, r2, #8
        subs r3, r3, #1
        bne 1b

        ldr r0, =credits_pal
        bl gfx_fade_to

        bl wait_for_start_toggled
        bl gfx_fade_to_black
        ldmfd sp!, {pc}

        .section .rodata
credits_lines:
        .asciz "You beat the game!"
        .asciz "(such as it is)"
        .asciz ""
        .asciz "Originally written"
        .asciz "  July 26-28 2002"
        .asciz "Resuscitated for"
        .asciz " #1GAM January 2015"
        .asciz ""
        .asciz "Code, garbage pixels, etc"
        .asciz "              - tokenrove"
        .asciz "Quality Pixels"
        .asciz "              - Retsyn"
        .asciz ""
        .asciz ""
        .asciz ""
        .asciz "See you next!"

        .align 2
credits_pal:
        .incbin "data/title.pal"
