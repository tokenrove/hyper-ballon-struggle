
        .section .rodata
        .align 2

        .global dude_sprite, dude_sprite_len
dude_sprite:   .incbin "data/dude10r.raw"
dude_sprite_len:        .hword .-dude_sprite

        .global balloon_sprite, balloon_sprite_len
balloon_sprite: .incbin "data/ball2.raw"
balloon_sprite_len:      .hword .-balloon_sprite
