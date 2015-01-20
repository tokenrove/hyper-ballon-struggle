@
@ some quick hack graphics routines
@

	.arm
	.align
	.include "gba.inc"

@ gfx_set_mode_1
@   puts the gba in mode 1, enables sprites, sets palette
	.global gfx_set_mode_1
gfx_set_mode_1:
	@ Setup the display controller
	mov r0, #reg_base	@ REG_DISPCNT
	mov r1, #0x0041		@ mode 1, one-d sprites
	@orr r1, r1, #0x1700	@ display sprites.
	orr r1, r1, #0x1100	@ display sprites.
	@ mother -- edit barry susan
	@ now they are lord mathock and zx-11
	strh r1, [r0]

	@ Setup the background registers
        mov r1, #0b00000100
	strh r1, [r0, #8]	@ REG_BG0
	mov r1, #0
	strh r1, [r0, #0x10]	@ REG_BG0SCX
	strh r1, [r0, #0x12]	@ REG_BG0SCY

	mov r1, #0b00001001
	orr r1, r1, #0x0100
	strh r1, [r0, #0xA]	@ REG_BG1
	mov r1, #0
	strh r1, [r0, #0x14]	@ REG_BG1SCX
	strh r1, [r0, #0x16]	@ REG_BG1SCY

	mov r1, #0b00001110
	orr r1, r1, #0x6200
	strh r1, [r0, #0xC]	@ REG_BG2
	@ FIXME should set the scalerot stuff here

	@ Setup a black palette
	mov r0, #palram_base
	mov r1, #0x0000		@ black
	mov r2, #0xff
1:	strh r1, [r0], #2
	subs r2, r2, #1
	bne 1b
	@ Return
	bx lr
@ EOR gfx_set_mode_1


@ gfx_set_mode_4
@   puts the gba in mode 4, enables sprites, sets palette
	.global gfx_set_mode_4
gfx_set_mode_4:
	@ Setup the display controller
	mov r0, #reg_base	@ REG_DISPCNT
	mov r1, #0x0044		@ mode 4, one-d sprites
	orr r1, r1, #0x1400	@ bg2, display sprites.
	strh r1, [r0]
	@ Setup a black palette
	mov r0, #palram_base
	mov r1, #0x0000		@ black
	mov r2, #0xff
1:	strh r1, [r0], #2
	subs r2, r2, #1
	bne 1b
	@ Return
	bx lr
@ EOR gfx_set_mode_4


@ gfx_enable_display
@   turns on the display.
	.global gfx_enable_display
gfx_enable_display:
	bx lr
@ EOR gfx_enable_display


@
@ void gfx_wait_vblank(void) -- wait for _start of_ vertical blank.
@ currently uses the very power-inefficient method of testing REG_VCOUNT
@
	.global gfx_wait_vblank
gfx_wait_vblank:
	mov r0, #reg_base
1:	ldrh r1, [r0, #6]	    @ REG_VCOUNT
	cmp r1, #160		    @ vblank starts at scanline 160
	bne 1b			    @ we want to hit it on the dot?
	@ Return
	bx lr
@ EOR gfx_wait_vblank


@
@ void gfx_load_bg_palette(u16 *palette) -- installs the 256 color
@   palette as the background palette.
@
	.global gfx_load_bg_palette
gfx_load_bg_palette:
	mov r1, #palram_base
	mov r2, r1
	add r2, r2, #0x100	    @ we're copying 256 entries
1:	ldrh r3, [r0], #2
	strh r3, [r1], #2
	cmp r1, r2
	blt 1b
	@ Return
	bx lr
@ EOR gfx_load_bg_palette


@
@ void gfx_set_spr_palette(u16 *palette) -- installs the 256 color
@   palette as the sprite palette.
@
	.global gfx_set_spr_palette
gfx_set_spr_palette:
	mov r1, #palram_base
	add r1, r1, #0x200	    @ sprite palette
	mov r2, r1
	add r2, r2, #0x100	    @ we're copying 256 entries
1:	ldrh r3, [r0], #2
	strh r3, [r1], #2
	cmp r1, r2
	blt 1b
	@ Return
	bx lr
@ EOR gfx_set_spr_palette


@
@ gfx_fade_to(palette) 
@
@ Fades in a palette in 1/60th steps.
@
	.global gfx_fade_to
gfx_fade_to:
	stmfd sp!,{r4-r10,lr}
	mov r4, #palram_base	    @ Beginning
	add r6, r4, #0x100	    @ and End of transfer
1:	@ Wait vblank
	bl gfx_wait_vblank
	@ For each element in the palette, step it toward the desired one
	stmfd sp!,{r0,r4,r6}
	mov r5, #0		    @ If r5 is never changed, we're done.
2:	ldrh r7, [r4], #2	    @ current
	ldrh r8, [r0], #2	    @ destination
	cmp r7, r8
	beq 3f
	mov r5, #1		    @ They're not equal, we're not done.
	@ Seperate into components
	@ Blue
	mov r9, r7, lsr #10
	cmp r9, r8, lsr #10
	addlt r9, r9, #1
	subgt r9, r9, #1
	bicne r7, r7, #0xfc00
	orrne r7, r7, r9, lsl #10

	@ Green
	mov r9, r7, lsr #5
	and r9, r9, #31
	mov r10, r8, lsr #5
	and r10, r10, #31
	cmp r9, r10
	addlt r9, r9, #1
	subgt r9, r9, #1
	bicne r7, r7, #0x03E0
	orrne r7, r7, r9, lsl #5

	@ Red
	mov r9, r7
	and r9, r9, #0x1f
	mov r10, r8
	and r10, r10, #0x1f
	cmp r9, r10
	addlt r7, r7, #1
	subgt r7, r7, #1

	strh r7, [r4, #-2]
3:	cmp r4, r6
	bne 2b
	@ If we're not done, repeat.
	ldmfd sp!,{r0,r4,r6}
	cmp r5, #0
	bne 1b
	ldmfd sp!,{r4-r10,lr}
	bx lr
@ EOR gfx_fade_to


@ gfx_disable_sprites
@   Disables all the sprites from r0 to 128
	.global gfx_disable_sprites
gfx_disable_sprites:
	mov r2, #oam_base
	add r2, r2, #1024
	mov r0, r0, lsl #3
	add r0, r0, #oam_base
1:	mov r1, #0x200
	strh r1, [r0], #2
	mov r1, #0
	strh r1, [r0], #2
	strh r1, [r0], #2
	strh r1, [r0], #2
	cmp r0, r2
	blt 1b
	bx lr
@ EOR gfx_disable_sprites

@@@ copy_tilemap_to_vram_bg
@@@ Assumes background is set to 32x32.
@@@
@@@ r0 = BG#
@@@ r1 = tilemap address
@@@      format is:
@@@       width,height : u8 -- in tiles
@@@       map data : w*h u16s
@@@       n tiles : u16
@@@       tile data: 64*n u8s
@@@
@@@ XXX should use DMA copying all over here
        .global copy_tilemap_to_vram_bg
copy_tilemap_to_vram_bg:
        stmfd sp!, {r2-r5,lr}
        @@ calculate map bank
        mov r4, #0x800
        mul r4, r0, r4
        add r4, #vram_base
        @@ if width = 32, copy everything at once; otherwise, copy
        @@ scanlines at a time
        ldrb r2, [r1], #1
        ldrb r3, [r1], #1
        cmp r2, #32
        bne .Lscanline_copy

        lsl r3, r3, #6
1:      ldrh r5, [r1], #2
        strh r5, [r4], #2
        subs r3, r3, #2
        bgt 1b
        b .Lcopy_tiles

.Lscanline_copy:
        lsl r2, r2, #1
0:      mov r6, r2
1:      ldrh r5, [r1], #2
        strh r5, [r4], #2
        subs r6, r6, #2
        bgt 1b
        rsb r6, r2, #64
        add r4, r4, r6
        subs r3, r3, #1
        bgt 0b

.Lcopy_tiles:
        @@ calculate tile bank
        mov r4, #0x4000
        mul r0, r4, r0
        add r0, #vram_base
        add r0, r0, #0x4000
        @@ copy in tiles
        ldrh r2, [r1], #2
        lsl r2, r2, #5
        bl memcpy_h

        ldmfd sp!, {r2-r5,pc}

@ EOF gfx.s
