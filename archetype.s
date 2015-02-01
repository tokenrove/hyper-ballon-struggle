
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
        .byte 40                @ strength
        .byte 50                @ stamina
        .byte 85                @ mass
        .byte 0
        .byte PALETTE_BLUE, PALETTE_GREEN
        .byte PALETTE_GOTH, PALETTE_BEARD
        .word retsyn_fly, retsyn_bump, retsyn_die, retsyn_win

        .asciz "Rudolph"
        .byte 50                @ strength
        .byte 80                @ stamina
        .byte 100               @ mass
        .byte 0
        .byte PALETTE_RED, PALETTE_YELLOW
        .byte PALETTE_GREEN, PALETTE_BLUE
        .word rudolph_fly, rudolph_bump, rudolph_die, rudolph_win

        .asciz "Ralph"
        .balign 8
        .byte 40                @ strength
        .byte 50                @ stamina
        .byte 100               @ mass
        .byte 0
        .byte PALETTE_BLUE, PALETTE_GREEN
        .byte PALETTE_RED, PALETTE_PURPLE
        .word alien_fly, alien_bump, alien_die, alien_win

        .asciz "Lopez"
        .balign 8
        .byte 80                @ strength
        .byte 40                @ stamina
        .byte 140               @ mass
        .byte 0
        .byte PALETTE_GREEN, PALETTE_CYAN
        .byte PALETTE_BLUE, PALETTE_GREEN
        .word octo_fly, octo_bump, octo_die, octo_win

        .asciz "Pierce"
        .balign 8
        .byte 35                @ strength
        .byte 60                @ stamina
        .byte 100               @ mass
        .byte 0
        .byte PALETTE_GOTH, PALETTE_BLUE
        .byte PALETTE_BLUE, PALETTE_YELLOW
        .word pierce_fly, pierce_bump, pierce_die, pierce_win

        .asciz "Greedy"
        .balign 8
        .byte 40                @ strength
        .byte 50                @ stamina
        .byte 60                @ mass
        .byte 0
        .byte PALETTE_PINK, PALETTE_BLUE
        .byte PALETTE_GREEN, PALETTE_BLUE
        .word greedy_fly, greedy_bump, greedy_die, greedy_win

        .asciz "Myr"
        .balign 8
        .byte 40                @ strength
        .byte 50                @ stamina
        .byte 70                @ mass
        .byte 0
        .byte PALETTE_YELLOW, PALETTE_BLUE
        .byte PALETTE_PINK, PALETTE_RED
        .word myr_fly, myr_bump, myr_die, myr_win

        .asciz "Randy"
        .balign 8
        .byte 50                @ strength
        .byte 50                @ stamina
        .byte 110               @ mass
        .byte 0
        .byte PALETTE_BEARD, PALETTE_GREEN
        .byte PALETTE_YELLOW, PALETTE_PINK
        .word randy_fly, randy_bump, randy_die, randy_win

        .asciz "Mono"
        .balign 8
        .byte 90                @ strength
        .byte 40                @ stamina
        .byte 190               @ mass
        .byte 0
        .byte PALETTE_PURPLE, PALETTE_PINK
        .byte PALETTE_PINK, PALETTE_RED
        .word monocle_fly, monocle_win, monocle_fly, monocle_win

        @@ Moby died in the Spinning Room
        .ascii "Melville"
        .byte 0                 @ strength; zero so it also terminates his long name
        .byte 1                 @ stamina
        .byte 100               @ mass
        .byte 0
        .byte PALETTE_RED, PALETTE_GOTH
        .byte PALETTE_BEARD, PALETTE_PINK
        .word melville_fly, melville_bump, melville_die, melville_win

        .asciz "Iceclwn"
        .balign 8
        .byte 80                @ strength
        .byte 40                @ stamina
        .byte 140               @ mass
        .byte 0
        .byte PALETTE_SALMON, PALETTE_SLATE_BLUE
        .byte PALETTE_BLUE, PALETTE_GREEN
        .word iceclown_fly, iceclown_bump, iceclown_die, iceclown_win

archetype_table_len:    .hword .-archetype_table

@@@ Tile data

        .align 2
        .global balloon_sprites, balloon_sprites_end
balloon_sprites: .incbin "data/ball2.raw"
        .incbin "data/ball2e.raw"
        .incbin "data/sweatdrop.raw"
balloon_sprites_end:

        .local retsyn_fly, retsyn_bump, retsyn_die, retsyn_win
        .align 2
retsyn_fly:     .incbin "data/retsyn_fly.raw"
retsyn_bump:    .incbin "data/retsyn_bump.raw"
retsyn_die:     .incbin "data/retsyn_die.raw"
retsyn_win:     .incbin "data/retsyn_win.raw"

        .local rudolph_fly, rudolph_bump, rudolph_die, rudolph_win
        .align 2
rudolph_fly:     .incbin "data/rudolph_fly.raw"
rudolph_bump:    .incbin "data/rudolph_bump.raw"
rudolph_die:     .incbin "data/rudolph_die.raw"
rudolph_win:     .incbin "data/rudolph_win.raw"

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

        .local pierce_fly, pierce_bump, pierce_die, pierce_win
        .align 2
pierce_fly:     .incbin "data/pierce_fly.raw"
pierce_bump:    .incbin "data/pierce_bump.raw"
pierce_die:     .incbin "data/pierce_die.raw"
pierce_win:     .incbin "data/pierce_win.raw"

        .local greedy_fly, greedy_bump, greedy_die, greedy_win
        .align 2
greedy_fly:     .incbin "data/greedy_fly.raw"
greedy_bump:    .incbin "data/greedy_bump.raw"
greedy_die:     .incbin "data/greedy_die.raw"
greedy_win:     .incbin "data/greedy_win.raw"

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

        .local melville_fly, melville_bump, melville_die, melville_win
        .align 2
melville_fly:     .incbin "data/melville_fly.raw"
melville_bump:    .incbin "data/melville_bump.raw"
melville_die:     .incbin "data/melville_die.raw"
melville_win:     .incbin "data/melville_win.raw"

        .local iceclown_fly, iceclown_bump, iceclown_die, iceclown_win
        .align 2
iceclown_fly:     .incbin "data/iceclown_fly.raw"
iceclown_bump:    .incbin "data/iceclown_bump.raw"
iceclown_die:     .incbin "data/iceclown_die.raw"
iceclown_win:     .incbin "data/iceclown_win.raw"

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

palette_salmon: .hword 0x0008, 0x1070, 0x20f7, 0x317f
palette_slate_blue: .hword 0x30c4, 0x49a9, 0x626f, 0x7b35
        @@ extras until we have a full set
        .byte 0x06, 0x00, 0x0d, 0x00, 0x13, 0x00, 0x1a, 0x00
        .hword 0x00e0, 0x01e0, 0x02e0, 0x03e0
        .byte 0x10, 0x1c, 0xb5, 0x38, 0x7a, 0x55, 0x3f, 0x72
        .byte 0x09, 0x01, 0xd0, 0x01, 0x98, 0x02, 0x5f, 0x03
        .byte 0x06, 0x00, 0x0d, 0x00, 0x13, 0x00, 0x1a, 0x00
        .byte 0x06, 0x00, 0x0d, 0x00, 0x13, 0x00, 0x1a, 0x00
        .hword 0x00e0, 0x01e0, 0x02e0, 0x03e0
