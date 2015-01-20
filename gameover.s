
        .include "gba.inc"
        .section .text
        .align 2
        .global display_gameover
display_gameover:
        stmfd sp!, {lr}

        bl gfx_wait_vblank

        mov r0, #REG_DISPCNT
        mov r1, #0x0040		@ mode 0, 1D
        orr r1, r1, #0b00011<<8 @ backgrounds, no sprites
        strh r1, [r0]

        @@ copy gameover screen to VRAM BG1
        mov r0, #1
        ldr r1, =gameover_tilemap
        bl copy_tilemap_to_vram_bg

        ldr r0, =gameover_pal
        bl gfx_load_bg_palette

        bl wait_for_start_toggled
        ldmfd sp!, {pc}

        .section .rodata
        .align 2
gameover_tilemap:
        .byte 30, 20
        .incbin "data/gameover.map"
        .hword (.Ltiles_end - .Ltiles)/64
.Ltiles:    .incbin "data/gameover.tiles"
.Ltiles_end:
gameover_pal:      .incbin "data/gameover.pal"
