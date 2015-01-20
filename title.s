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

        mov r0, #REG_DISPCNT
        mov r1, #0x0040		@ mode 0, 1D
        orr r1, r1, #0b00011<<8 @ backgrounds, no sprites
        strh r1, [r0]

        @@ copy title screen to VRAM BG1
        mov r0, #1
        ldr r1, =title_tilemap
        bl copy_tilemap_to_vram_bg

        ldr r0, =title_pal
        bl gfx_load_bg_palette

        bl wait_for_start_toggled
        ldmfd sp!, {pc}

        .section .rodata
        .align 2
title_tilemap:
        .byte 30, 20
        .incbin "data/title.map"
        .hword (.Ltiles_end - .Ltiles)/64
.Ltiles:    .incbin "data/title.tiles"
.Ltiles_end:
title_pal:      .incbin "data/title.pal"
