        .section .rodata
        .align 2
        .global select_tune_data
select_tune_data:
        .hword 4
        .hword 0 @ pad
        .byte 0, 0, 255, 0
        .align
        .word 1f
1:      .byte 0b10111, 160, 0b000000, 0
        .word 1f, 2f, 3f, 4f
1:
        .hword 0xD064, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x4807, 0x4002, 0xB58, 0xB58, 0xE50, 0xDC8, 0xB58, 0xB58, 0xF90, 0xF08, 0xB58, 0xB58, 0xE50, 0xDC8, 0xB58, 0xB58, 0xF90, 0xF08, 0xffff
        .align
2:
        .hword 0xD064, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x4802, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x4802, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x418, 0x718, 0x418, 0x718, 0x458, 0x758, 0x418, 0x718, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x418, 0x718, 0x418, 0x718, 0x458, 0x758, 0x418, 0x718, 0x4807, 0x4002, 0xA18, 0xA18, 0xA10, 0x988, 0xA18, 0xA18, 0xB50, 0xAC8, 0xA18, 0xA18, 0xA10, 0x988, 0xA18, 0xA18, 0xB50, 0xAC8, 0xffff
        .align
3:
        .hword 0xD064, 0x4802, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x4802, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x4802, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x4802, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x258, 0x558, 0x1D8, 0x4D8, 0x1D8, 0x4D8, 0x98, 0x398, 0x118, 0x418, 0xffff
        .align
4:
        .hword 0xD064, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x4001, 0x4801, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x418, 0x718, 0x418, 0x718, 0x458, 0x758, 0x418, 0x718, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x18, 0x618, 0x418, 0x718, 0x418, 0x718, 0x458, 0x758, 0x418, 0x718, 0x0, 0x0, 0x0, 0x0, 0xffff
        .align
5:
        .hword 0xD064, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0, 0x0, 0x0, 0x0, 0xffff
        .align
6:
        .hword 0xD064, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x10, 0x0, 0x0, 0x0, 0x0, 0xffff
        .align