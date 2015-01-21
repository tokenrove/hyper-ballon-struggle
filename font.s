
@
@ Some basic font routines using sprites.
@

	.section .text
	.arm
	.align
	.include "gba.inc"

.equ font_tile_idx, 32

@
@ font_load -- sets up the font routines
@
	.global font_load
font_load:
	stmfd sp!, {lr}

	@ Setup the font palette here
	mov r0, #palram_base
	mov r1, #0		@ black
	strh r1, [r0], #2
	mov r1, #0xff00		@ white
	orr r1, r1, #0x00ff
	strh r1, [r0], #2

	@ Copy font to VRAM
	mov r0, #vram_base
	add r0, r0, #0x4000
	@ FIXME tile idx should be flexible
	add r0, r0, #font_tile_idx*32
	ldr r1, =font_begin
	ldr r2, =font_nchars
	ldrb r2, [r2]
	mov r2, r2, lsl #5	@ 32 bytes per character
        bl dma_copy32

	@ Return
	ldmfd sp!, {lr}
	bx lr
@ EOR font_load


@
@ font_putstring(str,x,y) -- dump a NUL-terminated string to the screen,
@   rendering characters bg0, starting from x, y.
@   Clips at edge of screen.  Performs ASCII translation.
@
	.global font_putstring
font_putstring:
        stmfd sp!,{r0-r10,lr}

	ldr r10, =font_xlat	@ ASCII translation table

	mov r1, r1, lsr #3
	mov r2, r2, lsr #3

	mov r4, #vram_base	@ beginning
	add r4, r4, r1, lsl #1
	add r4, r4, r2, lsl #6

1:	ldrb r7, [r0], #1	@ get the next char in the string
	cmp r7, #0
	beq 9f			@ NUL terminated
	ldrb r7, [r10, r7]	@ xlate
	add r7, r7, #font_tile_idx	@ and push up the idx

	mov r6, r7
	strh r6, [r4], #2

	@ increment x, clip
	add r1, r1, #1
	cmp r1, #32		@ right-side clip
	bge 9f

	b 1b			@ rinse and repeat

9:	ldmfd sp!,{r0-r10,lr}
	bx lr
@ EOR font_putstring


@ EOF font.s
