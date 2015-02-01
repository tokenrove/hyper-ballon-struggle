@@@
@@@ Title screen
@@@
@@@ Uses a tilemap on BG1, and potentially fonts on BG0; no sprites,
@@@ no rotscale.

        .include "gba.inc"
        .section .text
        .align 2
        .global title_screen
title_screen:
        stmfd sp!, {lr}

        bl gfx_wait_vblank
        ldr r0, =title_song_data
        bl music_play_song

        mov r0, #REG_DISPCNT
        mov r1, #0x0040		@ mode 0, 1D
        orr r1, r1, #0b00010<<8 @ backgrounds, no sprites
        strh r1, [r0]
        mov r1, #0b00000100
        strh r1, [r0, #8]	@ REG_BG0
        mov r1, #0
        strh r1, [r0, #0x10]	@ REG_BG0SCX
        strh r1, [r0, #0x12]	@ REG_BG0SCY

        mov r1, #0b00001001
        orr r1, r1, #0x0100
        strh r1, [r0, #0xA]	@ REG_BG1
        mov r1, #0
        strh r1, [r0, #0x14]	@ REG_BG1SCX
        strh r1, [r0, #0x16]	@ REG_BG1SCY

        @@ copy title screen to VRAM BG1
        mov r0, #1
        ldr r1, =title_tilemap
        bl copy_tilemap_to_vram_bg

        ldr r0, =title_pal
        bl gfx_fade_to

        bl wait_for_start_toggled
        bl gfx_fade_to_black
        bl music_stop_song

        ldmfd sp!, {pc}

        .section .rodata
        .align 2
title_tilemap:
        .byte 30, 20
        .incbin "data/title.map"
        .hword (.Ltiles_end - .Ltiles)/32
.Ltiles:    .incbin "data/title.tiles"
.Ltiles_end:
title_pal:      .incbin "data/title.pal"
