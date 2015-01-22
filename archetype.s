
        .include "archetype.inc"
	.section .rodata
	.align

@@ Format of the archetypes table:
@@
@@   0  name, NUL-terminated    8 bytes
@@@ strength
@@@ stamina
@@@ mass
@@@ collision information
@@@ palettes in two byte pairs
@@@ ptr to frames (fly, bump, die, win)

        .global archetype_table, archetype_table_len
        .align 2
archetype_table:
        .asciz "Retsyn"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_BLUE, PALETTE_GREEN
        .byte PALETTE_GOTH, PALETTE_BEARD
        .word retsyn_fly, retsyn_bump, retsyn_die, retsyn_win

        .asciz "Rudolph"
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_RED, PALETTE_YELLOW
        .byte PALETTE_GREEN, PALETTE_BLUE
        .word monk_fly, monk_bump, monk_die, monk_win

        .asciz "Ralph"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_BLUE, PALETTE_GREEN
        .byte PALETTE_RED, PALETTE_PURPLE
        .word alien_fly, alien_bump, alien_die, alien_win

        .asciz "Lopez"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_GREEN, PALETTE_CYAN
        .byte PALETTE_BLUE, PALETTE_GREEN
        .word octo_fly, octo_bump, octo_die, octo_win

        .asciz "Pierce"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_GOTH, PALETTE_BLUE
        .byte PALETTE_BLUE, PALETTE_YELLOW
        .word dude_fly, dude_bump, dude_die, dude_win

        .asciz "Lana"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_PINK, PALETTE_BLUE
        .byte PALETTE_GREEN, PALETTE_BLUE
        .word dudette_fly, dudette_bump, dudette_die, dudette_win

        .asciz "Myr"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_YELLOW, PALETTE_BLUE
        .byte PALETTE_PINK, PALETTE_RED
        .word myr_fly, myr_bump, myr_die, myr_win

        .asciz "Randy"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_BEARD, PALETTE_GREEN
        .byte PALETTE_YELLOW, PALETTE_PINK
        .word randy_fly, randy_bump, randy_die, randy_win

        .asciz "Mono"
        .balign 8
        .byte 1                 @ strength
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_PURPLE, PALETTE_PINK
        .byte PALETTE_PINK, PALETTE_RED
        .word monocle_fly, monocle_win, monocle_fly, monocle_win

        .ascii "Melville"
        .byte 0                 @ strength; zero so it also terminates his long name
        .byte 1                 @ stamina
        .byte 10                @ mass
        .byte 0
        .byte PALETTE_RED, PALETTE_GOTH
        .byte PALETTE_BEARD, PALETTE_PINK
        .word corpse_fly, corpse_bump, corpse_bump, corpse_bump
archetype_table_len:    .hword .-archetype_table

@@@ Tile data

        .align 2
        .global balloon_sprites, balloon_sprites_end
balloon_sprites: .incbin "data/ball2.raw"
        .incbin "data/ball2e.raw"
balloon_sprites_end:

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

        .global invariant_palette
invariant_palette:
        @@ Invariant part
        .hword 0x39ff, 0x0421, 0x2d6b, 0x56b5, 0x7fff, 0x1def, 0x36b6, 0x4f9c
        .global palette_table
palette_table:
        @@ Variable part (two groups of four, ascending luminance)
palette_blue:   .hword 0x1c00, 0x3c00, 0x5c00, 0x7c00
palette_green:  .hword 0x00e0, 0x01e0, 0x02e0, 0x03e0
palette_cyan:   .byte 0x60, 0x2d, 0x20, 0x46, 0xe0, 0x5e, 0xc0, 0x7b
palette_pink:   .byte 0x10, 0x1c, 0xb5, 0x38, 0x7a, 0x55, 0x3f, 0x72
palette_yellow: .byte 0x09, 0x01, 0xd0, 0x01, 0x98, 0x02, 0x5f, 0x03
palette_beard: .byte 0x08, 0x09, 0xac, 0x25, 0x31, 0x3e, 0xd6, 0x5a
palette_purple: .byte 0x07, 0x1c, 0x0e, 0x34, 0x14, 0x50, 0x1b, 0x68
palette_red:    .byte 0x06, 0x00, 0x0d, 0x00, 0x13, 0x00, 0x1a, 0x00
palette_goth:   .byte 0x00, 0x00, 0x00, 0x00, 0xad, 0x35, 0xf7, 0x5e
