
        .section .rodata
        .align 2
        .global arena_table
arena_table:
        .word default, vtube, lozenge, gobacktospace
        .word 0

@@@ Arena structure:
@@@ .byte flags (0000vhfb)
@@@   background
@@@   foreground
@@@   wrap h
@@@   wrap v
@@@ .byte gravity
@@@ .hword reserved
@@@ .byte spawn 1 x
@@@ .byte spawn 1 y
@@@ .byte spawn 2 x
@@@ .byte spawn 2 y
@@@ .word palette_ptr
@@@ .word midground_ptr
@@@ .word background_ptr if b bit set
@@@ .word foreground_ptr if f bit set
        .local default, default_midground, default_palette, default_background
        .align 2
default:
        .byte 0b0101
        .byte 50
        .hword 0
        .byte 42,100
        .byte 90,4
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


        .local vtube, vtube_midground, vtube_palette, vtube_background
        .align 2
vtube:
        .byte 0b1001
        .byte 50
        .hword 0
        .byte 42,100
        .byte 90,4
        .word vtube_palette
        .word vtube_midground
        .word vtube_background
vtube_midground:
        .byte 30, 20
        .incbin "data/arena_vtube_mg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_vtube_mg.tiles"
1:
vtube_background:
        .byte 30, 20
        .incbin "data/arena_vtube_bg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_vtube_bg.tiles"
1:
vtube_palette:        .incbin "data/arena_vtube_mg.pal"


        .local lozenge, lozenge_midground, lozenge_palette, lozenge_background
        .align 2
lozenge:
        .byte 0b0001
        .byte 50
        .hword 0
        .byte 42,100
        .byte 90,4
        .word lozenge_palette
        .word lozenge_midground
        .word lozenge_background
lozenge_midground:
        .byte 30, 20
        .incbin "data/arena_lozenge_mg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_lozenge_mg.tiles"
1:
lozenge_background:
        .byte 30, 20
        .incbin "data/arena_lozenge_bg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_lozenge_bg.tiles"
1:
lozenge_palette:        .incbin "data/arena_lozenge_mg.pal"

        .local gobacktospace, gobacktospace_midground, gobacktospace_palette, gobacktospace_background
        .align 2
gobacktospace:
        .byte 0b0101
        .byte 21
        .hword 0
        .byte 42,100
        .byte 120,100
        .word gobacktospace_palette
        .word gobacktospace_midground
        .word gobacktospace_background
gobacktospace_midground:
        .byte 30, 20
        .incbin "data/arena_gobacktospace_mg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_gobacktospace_mg.tiles"
1:
gobacktospace_background:
        .byte 30, 20
        .incbin "data/arena_gobacktospace_bg.map"
        .hword (1f - 0f)/32
0: .incbin "data/arena_gobacktospace_bg.tiles"
1:
gobacktospace_palette:        .incbin "data/arena_gobacktospace_mg.pal"
