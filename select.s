
        .include "gba.inc"

        .section .ewram
        @@ this could be in an overlay
        .align
        .lcomm rotscale_theta, 2
        .lcomm rotscale_distance, 2
        .align

        .section .text
        .align 2
        .global select_character

        .equ ARCHETYPES_ON_A_PAGE, 10
        .equ ALTERNATE_PALETTES_MASK, 1

@@@ Character select screen.  Returns the type and palette chosen in r0
@@@ and r1.

@@@ OBJ VRAM layout:
@@@   tiles 0-3 -- selector
@@@   tiles 4*(n+1)-4*(n+1)+3 -- flying balloonist n
select_character:
        stmfd sp!, {lr}

        ldr r0, =select_tune_data
        bl music_play_song

        @@ Wipe the screen
        mov r0, #REG_DISPCNT
        mov r1, #0x41
        orr r1, r1, #0b10101<<8
        strh r1, [r0]

        ldr r1, =REG_BLDCNT
        mov r2, #0x0f40
        strh r2, [r1], #2
        ldr r2, =0x1f0a
        strh r2, [r1]

        ldr r1, =REG_BG2
        ldr r2, =0x228b
        strh r2, [r1]
        ldr r1, =REG_BG2RS
        mov r0, #0x100
        strh r0, [r1]
        strh r0, [r1, #6]
        mov r0, #0
        strh r0, [r1, #2]
        strh r0, [r1, #4]

        ldr r1, =rotscale_theta
        mov r2, #0x42
        strh r2, [r1]
        ldr r1, =rotscale_distance
        mov r2, #20
        strh r2, [r1]

        mov r0, #0
        bl gfx_disable_sprites

        @@ setup the background
        mov r0, #vram_base
        mov r1, #0x4000
        bl dma_zero32

        mov r0, #vram_base
        add r0, #0x1000         @ BG2

        mov r1, #256
        @@ row xor column gives us a checkerboard
1:      tst r1, #0b10
        moveq r2, #0
        movne r2, #1
        tst r1, #0b100000
        eorne r2, r2, #1
        strb r2, [r0], #1
        subs r1, r1, #1
        bne 1b

        @@ copy in tiles
        mov r0, #vram_base
        add r0, r0, #0x8000
        @@ one blank square
        mov r1, #0
        mov r2, r1
        mov r3, r1
        mov r4, r1
        mov r5, r1
        mov r6, r1
        mov r7, r1
        mov r8, r1
        stmia r0!, {r1-r8}
        stmia r0!, {r1-r8}

        @@ one filled square
        mov r1, #2
        orr r1, r1, r1, lsl #8
        orr r1, r1, r1, lsl #16
        mov r2, r1
        mov r3, r1
        mov r4, r1
        mov r5, r1
        mov r6, r1
        mov r7, r1
        mov r8, r1
        stmia r0!, {r1-r8}
        stmia r0!, {r1-r8}

        @@ Set a blue background
        mov r0, #palram_base
        mov r1, #0x7e00
        strh r1, [r0], #2
        @@ font color
        @@ ldr r1, =0xffff
        mov r1, #0x1800
        strh r1, [r0], #2
        @@ and a darker blue foreground for our rotscale stuff
        mov r1, #0xf000
        strh r1, [r0], #2

        bl copy_in_sprites

        mov r6, #1              @ Cursor position (indexed from 1)
        mov r7, #0              @ Selected palette

        @ Loop
0:      bl gfx_wait_vblank
        ldr r0, =char_select_topmsg
        mov r1, #8
        mov r2, #8
        bl font_putstring

        @ For each archetype...
        mov r3, #ARCHETYPES_ON_A_PAGE
        mov r4, #0

        ldr r0, =archetype_table
        mov r5, #oam_base

1:      ldrb r1, [r0]
        cmp r1, #0
        beq 2f

        mov r1, #32
        tst r4, #1
        movne r1, #128
        mov r2, r4, lsr #1
        mov r2, r2, lsl #5
        add r2, r2, #16
        bl font_putstring

        strh r2, [r5], #2
        sub r3, r1, #20
        orr r3, r3, #0x4000     @ 16x16 sprite
        strh r3, [r5], #2
        add r4, r4, #1          @ increment i early so our tile calculation is correct
        lsl r3, r4, #2
        orr r3, r3, r4, lsl #12
        orr r3, r3, #0x0800     @ priority
        strh r3, [r5], #2

        mov r3, #0
        strh r3, [r5], #2

        @@ is this where the cursor is?  if so, put the selector here (and bounce)
        cmp r4, r6
        bne 3f

        sub r2, r2, #10
        orr r2, r2, #0x400
        strh r2, [r5], #2
        sub r1, r1, #30
        orr r1, r1, #0x4000     @ 16x16 sprite
        strh r1, [r5], #2
        mov r1, #0x0000
        strh r1, [r5], #2
        mov r1, #0
        strh r1, [r5], #2

3:      add r0, r0, #32
        subs r3, r3, #1
        bne 1b

2:      @ disable remaining sprites
        @ Disable other sprites.
        mov r8, #oam_base
        add r8, r8, #1024
1:	mov r1, #0x200
        strh r1, [r5], #2
        mov r1, #0
        strh r1, [r5], #2
        strh r1, [r5], #2
        strh r1, [r5], #2
        cmp r5, r8
        blt 1b

        @@ update rotscale stuff
        ldr r1, =rotscale_theta
        ldrsh r2, [r1]
        add r2, r2, #1
        strh r2, [r1]
        mov r0, r2
        bl sine
        ldr r1, =rotscale_distance
        ldrsh r1, [r1]
        asr r0, #15-8
        mul r0, r1, r0
        asr r0, #4
        ldr r3, =REG_BG2RS
        strh r0, [r3, #4]
        rsb r0, r0, #0
        strh r0, [r3, #2]
        mov r0, r2
        bl cosine
        asr r0, #15-8
        strh r0, [r3, #0]
        strh r0, [r3, #6]

        @@ Check input
        ldr r2, =debounce
        ldrh r4, [r2]

        tst r4, #0x10           @ right
        bne 1f

        mov r7, #0
        bl load_new_palette_for_r6
        add r6, r6, #1
        cmp r6, #ARCHETYPES_ON_A_PAGE
        movgt r6, #1
        b 2f

1:      tst r4, #0x20           @ left
        bne 1f

        mov r7, #0
        bl load_new_palette_for_r6
        subs r6, r6, #1
        moveq r6, #ARCHETYPES_ON_A_PAGE
        b 2f

1:      tst r4, #0x40           @ up
        bne 1f

        mov r7, #0
        bl load_new_palette_for_r6
        subs r6, r6, #2
        addle r6, r6, #ARCHETYPES_ON_A_PAGE
        b 2f

1:      tst r4, #0x80           @ down
        bne 2f

        mov r7, #0
        bl load_new_palette_for_r6
        add r6, r6, #2
        cmp r6, #ARCHETYPES_ON_A_PAGE
        subgt r6, r6, #ARCHETYPES_ON_A_PAGE

2:      tst r4, #0x100		@ R trigger
        bne 1f

        add r7, r7, #1
        and r7, r7, #ALTERNATE_PALETTES_MASK
        bl load_new_palette_for_r6
        b 2f

1:	tst r4, #0x200		@ L trigger
        bne 2f

        sub r7, r7, #1
        and r7, r7, #ALTERNATE_PALETTES_MASK
        bl load_new_palette_for_r6

2:	tst r4, #0b1000		@ start button
        bne 0b

        @@ make noise
        stmfd sp!, {r0-r2,lr}
        mov r0, #3
        mov r1, #0
        ldr r2, =0b010000011000
        bl music_play_sfx
        ldmfd sp!, {r0-r2,lr}

        sub r0, r6, #1
        ldr r1, =archetype_table
        add r1, r1, r0, lsl #5
        add r1, r1, r7, lsl #1
        ldrb r2, [r1, #13]
        ldrb r1, [r1, #12]
        orr r1, r1, r2, lsl #8
        ldmfd sp!, {pc}

        @@ helper routine to find palette r7 for character r6 and pop
        @@ it into palette RAM; steps on r0-r3 at least
load_new_palette_for_r6:
        ldr r2, =archetype_table
        add r2, r2, r6, lsl #5
        sub r2, r2, #32
        add r2, r2, #12
        add r2, r2, r7, lsl #1
        ldrh r0, [r2]
        and r1, r0, #0xff
        lsr r0, r0, #8
        ldr r2, =palette_table
        add r3, r2, r0, lsl #3
        add r2, r2, r1, lsl #3
        mov r0, #palram_base
        add r0, #0x200
        add r0, r0, r6, lsl #5
        ldr r1, [r2], #4
        str r1, [r0, #16]!
        ldr r1, [r2], #4
        str r1, [r0, #4]!
        ldr r1, [r3], #4
        str r1, [r0, #4]!
        ldr r1, [r3], #4
        str r1, [r0, #4]!
        bx lr

        @@ copy in sprites
        @@ we need a frame of each character, and the selector arrow
copy_in_sprites:
        stmfd sp!, {lr}
        mov r6, #vram_base
        add r6, r6, #0x10000
        mov r0, r6
        ldr r1, =selector
        mov r2, #128
        bl dma_copy32
        @@ palette for selector
        mov r7, #palram_base
        add r7, r7, #0x200
        ldr r0, =invariant_palette
        ldmia r0, {r0-r5,r8-r9}
        stmia r7!, {r0-r5,r8-r9}

        mov r5, #ARCHETYPES_ON_A_PAGE
        ldr r4, =archetype_table
        @@ if we hit a zero, stop
0:      ldrb r1, [r4], #12
        cmp r1, #0
        beq 1f

        @@ construct palette
        ldr r0, =invariant_palette
        ldmia r0, {r0-r3}
        stmia r7!, {r0-r3}
        ldr r0, =palette_table
        ldrh r1, [r4], #4
        and r2, r1, #0xff
        add r2, r0, r2, lsl #3
        @@ Think carefully about this if you ever have more than 32 palettes
        add r1, r0, r1, lsr #5
        ldmia r2, {r0,r3}
        stmia r7!, {r0,r3}
        ldmia r1, {r0,r3}
        stmia r7!, {r0,r3}

        @@ copy in first frame tiles
        add r6, r6, #128
        mov r0, r6
        ldr r1, [r4], #16
        mov r2, #128
        bl dma_copy32

        subs r5, r5, #1
        bne 0b

1:      ldmfd sp!, {pc}

        .section .rodata
        .align

char_select_topmsg: .string "Select Your Champion"

        .align 2
selector:       .incbin "data/selector.raw"
