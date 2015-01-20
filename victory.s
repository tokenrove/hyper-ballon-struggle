
        .include "gba.inc"
        .section .text
        .align 2
        .global victory
victory:
        stmfd sp!, {lr}

        bl gfx_wait_vblank

        mov r0, #REG_DISPCNT
        mov r1, #0x0040		@ mode 0, 1D
        orr r1, r1, #0b00011<<8 @ backgrounds, no sprites
        strh r1, [r0]

        @@ copy victory screen to VRAM BG1
        mov r0, #1
        ldr r1, =victory_tilemap
        bl copy_tilemap_to_vram_bg

        ldr r0, =victory_pal
        bl gfx_load_bg_palette

        @@ XXX we want to have balloons rising here, behind the text
        @@ but in front of the background.

        bl wait_for_start_toggled
        ldmfd sp!, {pc}

        .section .rodata
        .align 2
victory_tilemap:
        .byte 30, 20
        .incbin "data/victory.map"
        .hword (.Ltiles_end - .Ltiles)/64
.Ltiles:    .incbin "data/victory.tiles"
.Ltiles_end:
victory_pal:      .incbin "data/victory.pal"
