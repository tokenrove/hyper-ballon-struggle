
        .include "gba.inc"

        .section .text
        .align 2
        .global select_character

        .equ ARCHETYPES_ON_A_PAGE, 10

@@@ Character select screen.  Returns the type and palette chosen in r0
@@@ and r1.

@@@ OBJ VRAM layout:
@@@   tiles 0-3 -- selector
@@@   tiles 4*(n+1)-4*(n+1)+3 -- flying balloonist n
select_character:
        stmfd sp!, {lr}

        @ Wipe the screen
        mov r0, #REG_DISPCNT
        mov r1, #0x41
        orr r1, r1, #0b10101<<8
        strh r1, [r0]

        @@ setup the background
        mov r0, #vram_base
        mov r1, #0x4000
        bl dma_zero32

        @@ Set a blue background
        mov r0, #palram_base
        mov r1, #0x005e
        strh r1, [r0]
        mov r1, #0x7e00
        strh r1, [r0], #2

        bl copy_in_sprites

        mov r6, #3              @ Cursor position

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
        ldr r1, =REG_BLDCNT
        mov r2, #0x0f40
        strh r2, [r1], #2
        mov r2, #0x1f00
        orr r2, r2, #0x0a
        strh r2, [r1]

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

        @ Check input
        mov r2, #reg_base
        add r2, r2, #0x130
        ldrh r3, [r2]   @ REG_KEY

        tst r3, #0x10           @ R
        bne 1f
        add r6, r6, #1
        cmp r6, #ARCHETYPES_ON_A_PAGE
        movge r6, #1

1:      tst r3, #0x20           @ L
        bne 1f
        subs r6, r6, #1
        moveq r6, #ARCHETYPES_ON_A_PAGE

1:      tst r3, #0x40           @ U
        bne 1f
        subs r6, r6, #2
        addle r6, r6, #ARCHETYPES_ON_A_PAGE

1:      tst r3, #0x80           @ D
        bne 1f
        add r6, r6, #2
        cmp r6, #ARCHETYPES_ON_A_PAGE
        subge r6, r6, #ARCHETYPES_ON_A_PAGE

1:      tst r3, #0x100		@ R trigger
        beq 1f
        add r1, r1, #1		@ next palette
        and r1, r1, #0xf

1:	tst r3, #0x200		@ L trigger
        beq 1f
        sub r1, r1, #1		@ previous palette
        and r1, r1, #0xf

1:	tst r3, #0b1000		@ start button
        bne 0b

        @@ make noise
        stmfd sp!, {r0-r2,lr}
        mov r0, #3
        mov r1, #0
        ldr r2, =0b010000011000
        bl music_play_sfx
        ldmfd sp!, {r0-r2,lr}

        ldmfd sp!, {pc}

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
        ldr r0, =sprite_palette
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

char_select_topmsg: .string "Select Warrior"
char_names: .string "Dude"

        .align 2
selector:       .incbin "data/selector.raw"
