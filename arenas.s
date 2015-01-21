
        .section .rodata
        .align 2
        .global arena_table
arena_table:
        .word default
        .word 0

@@@ Arena structure:
@@@ .byte flags (0000vhfb)
@@@   background
@@@   foreground
@@@   wrap h
@@@   wrap v
@@@ .byte gravity
@@@ .hword reserved
@@@ .word palette_ptr
@@@ .word midground_ptr
@@@ .word background_ptr if b bit set
@@@ .word foreground_ptr if f bit set
        .local default, default_midground, default_palette, default_background
        .align 2
default:
        .byte 0b0101
        .byte 10
        .hword 0
        .word default_palette
        .word default_midground
        .word default_background
default_midground:
        .byte 30, 20
        .incbin "data/arena_default_mg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_default_mg.tiles"
1:
default_background:
        .byte 30, 20
        .incbin "data/arena_default_bg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_default_bg.tiles"
1:
default_palette:        .incbin "data/arena_default_mg.pal"
