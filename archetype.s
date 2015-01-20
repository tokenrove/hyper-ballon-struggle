
	.section .rodata
	.align

@@ Format of the archetypes table:
@@
@@   0  name, NUL-terminated    9 bytes
@@@ strength
@@@ stamina
@@@ mass
@@@ collision information
@@@ ptr to frames (fly, bump, die, win)
@@@ four palettes

        .global archetype_table, archetype_table_len
        .align 2
archetype_table:
        .asciz "Retsyn"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 1,5,9,13
        .word retsyn_fly, retsyn_bump, retsyn_die, retsyn_win

        .asciz "Monk?"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 17,21,25,29
        .word monk_fly, monk_bump, monk_die, monk_win

        .asciz "Alien?"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 33,37,41,45
        .word alien_fly, alien_bump, alien_die, alien_win

        .asciz "Octo?"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 49,53,57,61
        .word octo_fly, octo_bump, octo_die, octo_win

        .asciz "Dude?"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 65,69,73,77
        .word dude_fly, dude_bump, dude_die, dude_win

        .asciz "Dudette"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 81,85,89,93
        .word dudette_fly, dudette_bump, dudette_die, dudette_win

        .asciz "Myr"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 97,101,105,109
        .word myr_fly, myr_bump, myr_die, myr_win

        .asciz "Randy"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 113,117,121,125
        .word randy_fly, randy_bump, randy_die, randy_win

        .asciz "Mono"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 129,133,129,133
        .word monocle_fly, monocle_win, monocle_fly, monocle_win

        .asciz "Corpse"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte 137,141,141,141
        .word corpse_fly, corpse_bump, corpse_bump, corpse_bump
archetype_table_len:    .hword .-archetype_table

@@@ Tile data

        .align 2
        .global sprite_data_begin
sprite_data_begin:
balloon_sprite: .incbin "data/ball2.raw"

        .local retsyn_fly, retsyn_bump, retsyn_die, retsyn_win
        .align 2
retsyn_fly:     .incbin "data/retsyn_fly.raw"
retsyn_bump:    .incbin "data/retsyn_bump.raw"
retsyn_die:     .incbin "data/retsyn_die.raw"
retsyn_win:     .incbin "data/retsyn_win.raw"

        .local monk_fly, monk_bump, monk_die, monk_win
        .align 2
monk_fly:     .incbin "data/monk_fly.raw"
monk_bump:    .incbin "data/monk_bump.raw"
monk_die:     .incbin "data/monk_die.raw"
monk_win:     .incbin "data/monk_win.raw"

        .local alien_fly, alien_bump, alien_die, alien_win
        .align 2
alien_fly:     .incbin "data/alien_fly.raw"
alien_bump:    .incbin "data/alien_bump.raw"
alien_die:     .incbin "data/alien_die.raw"
alien_win:     .incbin "data/alien_win.raw"

        .local octo_fly, octo_bump, octo_die, octo_win
        .align 2
octo_fly:     .incbin "data/octo_fly.raw"
octo_bump:    .incbin "data/octo_bump.raw"
octo_die:     .incbin "data/octo_die.raw"
octo_win:     .incbin "data/octo_win.raw"

        .local dude_fly, dude_bump, dude_die, dude_win
        .align 2
dude_fly:     .incbin "data/dude_fly.raw"
dude_bump:    .incbin "data/dude_bump.raw"
dude_die:     .incbin "data/dude_die.raw"
dude_win:     .incbin "data/dude_win.raw"

        .local dudette_fly, dudette_bump, dudette_die, dudette_win
        .align 2
dudette_fly:     .incbin "data/dudette_fly.raw"
dudette_bump:    .incbin "data/dudette_bump.raw"
dudette_die:     .incbin "data/dudette_die.raw"
dudette_win:     .incbin "data/dudette_win.raw"

        .local myr_fly, myr_bump, myr_die, myr_win
        .align 2
myr_fly:     .incbin "data/myr_fly.raw"
myr_bump:    .incbin "data/myr_bump.raw"
myr_die:     .incbin "data/myr_die.raw"
myr_win:     .incbin "data/myr_win.raw"

        .local randy_fly, randy_bump, randy_die, randy_win
        .align 2
randy_fly:     .incbin "data/randy_fly.raw"
randy_bump:    .incbin "data/randy_bump.raw"
randy_die:     .incbin "data/randy_die.raw"
randy_win:     .incbin "data/randy_win.raw"

        .local monocle_fly, monocle_win
        .align 2
monocle_fly:     .incbin "data/monocle_fly.raw"
monocle_win:     .incbin "data/monocle_win.raw"

        .local corpse_fly, corpse_bump
        .align 2
corpse_fly:     .incbin "data/corpse_fly.raw"
corpse_bump:    .incbin "data/corpse_bump.raw"

        .global sprite_data_end
sprite_data_end:

        .global sprite_palette
sprite_palette:
        @@ Invariant part
        .hword 0x39ff, 0x0421, 0x2d6b, 0x56b5, 0x7fff, 0x1def, 0x36b6, 0x4f9c
        @@ Variable part (two groups of four, ascending luminance)
        .hword 0x1c00, 0x3c00, 0x5c00, 0x7c00, 0x00e0, 0x01e0, 0x02e0, 0x03e0
