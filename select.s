
        .include "gba.inc"

        .section .text
        .align 2
        .global select_character

@@@ Character select screen.  Returns the type and palette chosen in r0
@@@ and r1.
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
        bl zero_h

        @@ Set a blue background
        mov r0, #palram_base
        mov r1, #0x005e
        strh r1, [r0]
        mov r1, #0x7e00
        strh r1, [r0], #2

        @ Loop
0:      bl gfx_wait_vblank
        ldr r0, =char_select_topmsg
        mov r1, #8
        mov r2, #8
        bl font_putstring

        @ For each archetype...
        mov r3, #10
        mov r4, #0

        ldr r0, =archetype_table
        mov r5, #oam_base
1:      mov r1, #32
        tst r4, #1
        movne r1, #128
        mov r2, r4, lsr #1
        mov r2, r2, lsl #5
        add r2, r2, #16
        bl font_putstring

        strh r2, [r5], #2
        sub r1, r1, #20
        orr r1, r1, #0x4000     @ 16x16 sprite
        strh r1, [r5], #2
        @@ XXX palette here
        ldrb r1, [r0, #12]
        orr r1, r1, #0x0800     @ priority
        strh r1, [r5], #2

        mov r1, #0
        strh r1, [r5], #2

        add r0, r0, #32
        add r4, r4, #1
        subs r3, r3, #1
        bne 1b

        @ disable remaining sprites
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

        tst r3, #0x100		@ R trigger
        bne 1f
        add r1, r1, #1		@ next palette
        and r1, r1, #0xf

1:	tst r3, #0x200		@ L trigger
        bne 1f
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


        .section .rodata
        .align

char_select_topmsg: .string "Select Warrior"
char_names: .string "Dude"
