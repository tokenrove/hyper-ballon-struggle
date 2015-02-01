
        .include "gba.inc"
        .section .text
        .align 2

        .equ MIDPOINT, 60
        .equ WIDTH, 200

        @@ challenge(player, palette, enemy, palette)
        @@ display VERSUS screen
        .global challenge
challenge:
        stmfd sp!, {r0-r4,lr}
        mov r9, r0
        mov r10, r1
        mov r11, r2
        mov r12, r3
        bl music_stop_song
        bl gfx_wait_vblank
        mov r0, #0
        bl gfx_disable_sprites
        @@ mode 1
        mov r0, #REG_DISPCNT
        mov r1, #0x41
        orr r1, r1, #0b00111<<8
        strh r1, [r0]
        @@ BG2 is the rotscale VERSUS
        ldr r1, =REG_BG2
        ldr r2, =0x0488
        strh r2, [r1]
        ldr r1, =REG_BG2RS
        mov r0, #0x100
        strh r0, [r1]
        strh r0, [r1, #6]
        mov r0, #0
        strh r0, [r1, #2]
        strh r0, [r1, #4]
        ldr r0, =-60<<8
        str r0, [r1, #8]
        ldr r0, =-60<<8
        str r0, [r1, #12]
        @@ BG0 is the player's diagonal slab from the left

        @@ we could use windowing here to avoid wrapping, but instead
        @@ i take advantage of the sparsity of this screen and use
        @@ double-size tilemaps with lots of empty space
        ldr r1, =REG_BG0
        ldr r2, =0x4007
        strh r2, [r1]
        ldr r1, =REG_BG0SCX
        mov r2, #MIDPOINT+WIDTH
        strh r2, [r1], #2
        mov r2, #0
        strh r2, [r1]
        @@ BG1 is the enemy's diagonal slab from the right
        ldr r1, =REG_BG1
        ldr r2, =0x4207
        strh r2, [r1]
        ldr r1, =REG_BG1SCX
        mov r2, #MIDPOINT-WIDTH
        strh r2, [r1], #2
        mov r2, #0
        strh r2, [r1]

        @@ set the backdrop

        @@ the slabs are 160px of diagonal plus 6 tiles visible; we
        @@ fill the whole line of 32 tiles to keep things simple

        @@ BG0
        mov r0, #vram_base
        mov r1, #0x1000
        bl dma_zero32
        @@ fill with width-y-1 fill tiles, 1 diagonal tile, and y empty tiles
        mov r0, #vram_base
        mov r1, #0
0:      rsb r3, r1, #31
        mov r2, #0
1:      cmp r2, r3
        movlt r4, #1
        movgt r4, #0
        moveq r4, #2
        orr r4, r4, #0x4000
        strh r4, [r0], #2
        add r2, r2, #1
        cmp r2, #32
        bne 1b
        add r1, r1, #1
        cmp r1, #20
        blt 0b

        @@ BG1
        mov r0, #vram_base
        add r0, r0, #0x1000
        mov r1, #0x1000
        bl dma_zero32
        mov r0, #vram_base
        add r0, r0, #0x1000
        mov r1, #0
0:      rsb r3, r1, #31
        mov r2, #0
1:      cmp r2, r3
        movlt r4, #0
        movgt r4, #1
        moveq r4, #2
        orr r4, r4, #0x5c00
        strh r4, [r0], #2
        add r2, r2, #1
        cmp r2, #32
        bne 1b
        add r1, r1, #1
        cmp r1, #20
        blt 0b

        mov r0, #vram_base
        add r0, r0, #0x1800
        mov r1, #0
0:      mov r3, #12
        mov r2, #0
1:      cmp r2, r3
        movlt r4, #1
        movge r4, #0
        orr r4, r4, #0x5c00
        strh r4, [r0], #2
        add r2, r2, #1
        cmp r2, #32
        bne 1b
        add r1, r1, #1
        cmp r1, #20
        blt 0b

        @@ BG2
        mov r0, #vram_base
        add r0, r0, #0x800*4
        mov r1, #0x100
        bl dma_zero32

        mov r0, #vram_base
        add r0, r0, #0x800*4
        mov r2, #VERSUS_HEIGHT
        mov r3, #VERSUS_WIDTH
        mov r4, #1
0:      add r1, r4, #1
        orr r1, r4, r1, lsl #8
        strh r1, [r0], #2
        add r4, r4, #2
        subs r3, r3, #2
        bne 0b
        mov r3, #VERSUS_WIDTH
        add r0, r0, #16-VERSUS_WIDTH
        subs r2, r2, #1
        bne 0b

        @@ XXX we could actually pack all this stuff into one bank
        @@ copy in VERSUS
        ldr r0, =vram_base + 0x8040
        ldr r1, =versus_data
        ldr r2, =versus_len
        bl dma_copy32

        @@ construct the fill tiles
        mov r0, #vram_base
        add r0, r0, #0x4000
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

        @@ one filled square
        mov r1, #0x11
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

        @@ and the diagonal square
        ldr r8, =diagonal_tile
        ldmia r8, {r1-r8}
        stmia r0!, {r1-r8}

        @@ copy in the actor sprites
        @@ construct the diagonals

        @@ construct a background palette that includes our diagonal
        @@ colors, the versus word palette, and the two balloonist
        @@ palettes

        @@ while start isn't hit
        @@ while the diagonals haven't met,
        @@ slide in the diagonals
        @@ spin+scale the versus text

        @@ once the diagonals have met,
        @@ flash the palette for a few frames
        @@ and play sching sound
        @@ hold on a few frames then fade out

        ldr r0, =versus_palette
        bl gfx_fade_to

        mov r9, #WIDTH
0:      bl gfx_wait_vblank

        mov r0, #MIDPOINT
        add r1, r0, r9
        ldr r2, =REG_BG0SCX
        strh r1, [r2]
        sub r1, r0, r9
        ldr r2, =REG_BG1SCX
        strh r1, [r2]

        ldr r2, =debounce
        ldrh r2, [r2]
        tst r2, #0b1000		@ start button
        beq 9f

        subs r9, r9, #4
        bge 0b

        mov r9, #10
0:      bl gfx_wait_vblank

        ldr r0, =palram_base
        ldr r1, =0xffff
        strh r1, [r0, #65*2]
        strh r1, [r0, #81*2]

        ldr r2, =debounce
        ldrh r2, [r2]
        tst r2, #0b1000		@ start button
        beq 9f

        subs r9, r9, #1
        bge 0b

9:      bl gfx_fade_to_black
        ldmfd sp!, {r0-r4,pc}


        @@ to make a diagonal tile:
        @@ start with a filled tile
        @@ on line i, make the first n-i-1 pixels transparent


        .equ VERSUS_WIDTH, 14
        .equ VERSUS_HEIGHT, 4
        .section .rodata
        .align 2
versus_palette: .incbin "data/versus.pal"
        .align 2
versus_data:    .incbin "data/versus.raw256"
        .equ versus_len, .-versus_data

        .align 2
diagonal_tile:
        .word 0x21111111
        .word 0x02111111
        .word 0x00211111
        .word 0x00021111
        .word 0x00002111
        .word 0x00000211
        .word 0x00000021
        .word 0x00000002
