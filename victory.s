
        .include "gba.inc"

        .equ MAX_BALLOONS, 32

        .equ BALLOON_T_X, 0
        .equ BALLOON_T_Y, 2
        .equ BALLOON_T_LIFT, 4
        .equ BALLOON_T_COLOR, 5
        .equ BALLOON_LEN, 6

        .section .ewram
        .align 2
        @@ XXX should use an overlay for this
        .lcomm balloons, BALLOON_LEN*MAX_BALLOONS

        .section .text
        .align 2
        .global victory
victory:
        stmfd sp!, {r0-r3,lr}

        bl gfx_wait_vblank

        mov r0, #0
        bl gfx_disable_sprites

        mov r0, #REG_DISPCNT
        mov r1, #0x0040		@ mode 0, 1D
        orr r1, r1, #0b10011<<8 @ backgrounds and sprites
        strh r1, [r0]

        @@ copy victory screen to VRAM BG1
        mov r0, #1
        ldr r1, =victory_tilemap
        bl copy_tilemap_to_vram_bg

        @@ setup lots of balloon palettes
        mov r0, #palram_base
        add r0, r0, #0x200
        ldr r1, =invariant_palette
        mov r8, #16
        ldmia r1, {r2-r5}
        ldr r1, =palette_table
1:      ldmia r1!, {r6-r7}
        stmia r0!, {r2-r5}
        stmia r0!, {r6-r7}
        stmia r0!, {r6-r7}
        subs r8, r8, #1
        bne 1b

        bl setup_balloons

        ldr r0, =victory_pal
        bl gfx_fade_to

        mov r6, #0              @ the count

0:      bl gfx_wait_vblank

        @@ walk the balloons
        mov r3, #oam_base
        ldr r4, =balloons
        mov r5, #MAX_BALLOONS

1:      ldrsh r0, [r4, #BALLOON_T_Y]
        cmp r0, #-8<<4
        bgt 3f

        ldrb r1, [r4, #BALLOON_T_LIFT]
        cmp r1, #0              @ disabled?
        beq 2f
        @@ this is a balloon that just reached the top
        mov r1, #0
        strb r1, [r4, #BALLOON_T_LIFT]
        sub r6, r6, #1
2:      cmp r6, #MAX_BALLOONS
        bge 4f
        bl random_word
        @@ p = 1 - count/MAX = 255 - (count<<8)>>log2(MAX)
        mov r1, r6, lsl #3    @ log2(256)-log2(MAX_BALLOONS)
        rsb r1, r1, #0x100
        and r2, r0, #0xff
        lsr r1, #1

        cmp r2, r1
        bgt 4f                  @ no balloon for you today

        lsr r0, r0, #8          @ 24 bits left
        and r2, r0, #0xff
        cmp r2, #1
        bgt 4f

        lsr r0, r0, #8          @ 16 bits left
        and r2, r0, #0x7
        add r2, r2, #4
        strb r2, [r4, #BALLOON_T_LIFT]
        lsr r0, r0, #4          @ 12 bits left
        and r2, r0, #0xf
        strb r2, [r4, #BALLOON_T_COLOR]
        lsr r0, r0, #4          @ 8 bits left
        and r2, r0, #0xff
        sub r2, r2, #4
        lsl r2, r2, #4
        strh r2, [r4, #BALLOON_T_X]
        mov r2, #168
        lsl r2, r2, #4
        strh r2, [r4, #BALLOON_T_Y]
        add r6, r6, #1

3:      mov r2, #0
        bl render_balloon

        @@ update motion
        ldrsh r2, [r4, #BALLOON_T_Y]
        ldrb r1, [r4, #BALLOON_T_LIFT]
        sub r2, r2, r1
        strh r2, [r4, #BALLOON_T_Y]
        ldrsh r1, [r4, #BALLOON_T_X]
        asr r1, #4
        mov r0, r2, asr #1
        add r0, r0, r1
        bl sine
        ldrb r1, [r4, #BALLOON_T_LIFT]
        mul r0, r1, r0          @ 0.15 * 0.4 = 0.19
        asr r0, #15
        asr r0, #2
        ldrsh r1, [r4, #BALLOON_T_X]
        add r1, r1, r0
        strh r1, [r4, #BALLOON_T_X]

4:      add r4, r4, #BALLOON_LEN
        subs r5, r5, #1
        bgt 1b

        @@ wipe the rest of OAM
        mov r4, #oam_base
        add r4, r4, #1024
1:	mov r1, #0x200
        strh r1, [r3], #2
        mov r1, #0
        strh r1, [r3], #2
        str r1, [r3], #4
        cmp r3, r4
        blt 1b

        ldr r2, =debounce
        ldrh r3, [r2]
        tst r3, #0b1000		@ start button
        bne 0b

        @@ XXX show balloons as popped
        @@ walk the balloons
        mov r3, #oam_base
        ldr r4, =balloons
        mov r5, #MAX_BALLOONS

1:      ldrsh r0, [r4, #BALLOON_T_Y]
        cmp r0, #-8<<4
        ble 2f
        mov r2, #1
        bl render_balloon
2:      add r4, r4, #BALLOON_LEN
        subs r5, r5, #1
        bgt 1b

        @@ make noise
        mov r0, #4
        mov r1, #0
        @@ 0b0001 iiii  iidd dDDD
        ldr r2, =0b0001000000010000
        bl music_play_sfx

        bl gfx_fade_to_black
        ldmfd sp!, {r0-r3,pc}


setup_balloons:
        stmfd sp!, {lr}
        @@ copy in sprite tiles
        @@ we start with the two balloon frames
        mov r5, #vram_base
        add r5, r5, #0x10000
        ldr r1, =balloon_sprites
        ldr r2, =balloon_sprites_end
        sub r2, r2, r1
        mov r0, r5
        bl dma_copy32

        @@ Drop in the invariant palette at 0 for any overlays or
        @@ anything we might use.
        mov r0, #palram_base
        add r0, r0, #0x200
        ldr r1, =invariant_palette
        mov r2, #32
        bl dma_copy32

        @@ Make balloons translucent
        ldr r1, =REG_BLDCNT
        mov r3, #0x0f40
        strh r3, [r1], #2
        mov r3, #0x0800
        orr r3, r3, #0x10
        strh r3, [r1]

        @@ Initially, all balloons are off-screen and disabled
        ldr r0, =balloons
        mov r1, #MAX_BALLOONS
0:      mov r2, #-9<<4
        strh r2, [r0, #BALLOON_T_X]
        strh r2, [r0, #BALLOON_T_Y]
        mov r2, #0
        strb r2, [r0, #BALLOON_T_LIFT]
        strb r2, [r0, #BALLOON_T_COLOR]
        add r0, r0, #BALLOON_LEN
        subs r1, r1, #1
        bgt 0b

        ldmfd sp!, {pc}


        @@ r2 = 0 normally, 1 if balloons popped
        @@ r3 = oam ptr
        @@ r4 = balloon
render_balloon:
        stmfd sp!, {lr}
        ldrsh r0, [r4, #BALLOON_T_Y]
        mov r1, r0, asr #4
        and r1, r1, #255
        orr r1, r1, #0x400
        strh r1, [r3], #2

        ldrsh r0, [r4, #BALLOON_T_X]
        mov r1, r0, asr #4
        mov r0, #512
        sub r0, r0, #1
        and r1, r1, r0
        strh r1, [r3], #2

        @@ popping would happen here
        mov r1, r2              @ tile idx
        orr r1, r1, #0xc00      @ behind everything
        ldrb r0, [r4, #BALLOON_T_COLOR]
        orr r1, r1, r0, lsl #12
        strh r1, [r3], #2
        mov r1, #0              @ rotation bits
        strh r1, [r3], #2
        ldmfd sp!, {pc}


        .section .rodata
        .align 2
victory_tilemap:
        .byte 30, 20
        .incbin "data/victory.map"
        .hword (.Ltiles_end - .Ltiles)/32
.Ltiles:    .incbin "data/victory.tiles"
.Ltiles_end:
victory_pal:      .incbin "data/victory.pal"
