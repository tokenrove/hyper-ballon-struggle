        .section .rodata
        .align 2
        .global in_game_song_data
in_game_song_data:
        .hword 4
        .hword 0 @ pad
        .byte 0, 0, 255, 0
        .align
        .word 1f
1:      .byte 0b10111, 160, 0b000000, 0
        .word 1f, 2f, 3f, 4f
1:
        .hword 0xD0A0, 0x0, 0x0, 0x0, 0x0, 0x4802, 0x698, 0x690, 0x18, 0x858, 0x850, 0x18, 0x808, 0x7C8, 0x698, 0x690, 0x18, 0x858, 0x850, 0x18, 0x808, 0x7C8, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xffff
        .align
2:
        .hword 0xD0A0, 0x0, 0x0, 0x0, 0x0, 0x4802, 0x858, 0x850, 0x18, 0xA18, 0xA10, 0x18, 0x9C8, 0x988, 0x858, 0x850, 0x18, 0xA18, 0xA10, 0x18, 0x9C8, 0x988, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xffff
        .align
3:
        .hword 0xD0A0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0xffff
        .align
4:
        .hword 0x4002, 0xC98, 0x998, 0xBD8, 0x998, 0xB98, 0x998, 0xB58, 0x998, 0xC98, 0x998, 0xBD8, 0x998, 0xB98, 0x998, 0xB58, 0x998, 0xC98, 0x998, 0xBD8, 0x998, 0xB98, 0x998, 0xB58, 0x998, 0xC98, 0x998, 0xBD8, 0x998, 0xB98, 0x998, 0xB58, 0x998, 0x4002, 0x998, 0x698, 0x8D8, 0x698, 0x898, 0x698, 0x858, 0x698, 0x998, 0x698, 0x8D8, 0x698, 0x898, 0x698, 0x858, 0x698, 0x998, 0x698, 0x8D8, 0x698, 0x898, 0x698, 0x858, 0x698, 0x998, 0x698, 0x8D8, 0x698, 0x898, 0x698, 0x858, 0x698, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0x7D0, 0xAD8, 0xAD8, 0x7D0, 0xAD0, 0xffff
        .align
5:
        .hword 0xffff
        .align
6:
        .hword 0xffff
        .align
