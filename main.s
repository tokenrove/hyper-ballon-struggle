@
@ balloon fight
@ tokenrove / 2002
@

	.section .text
	.arm
	.align

	.include "gba.inc"

@ main
@   program entry point.  never returns.
	.global main
main:
	@ currently we run the whole game in the in-game mode
	bl game_init
	bl menu_loop
0:	b 0b
@ EOR main


@ menu_loop
@
menu_loop:
	stmfd sp!, {lr}
	@ Start the game...
	bl char_select
	bl game_loop
	ldmfd sp!, {lr}
	bx lr
@ EOR menu_loop


@ char_select
@   Character select screen.  Returns the type and palette chosen in r0
@   and r1.
char_select:
	stmfd sp!, {lr}

	@ Wipe the screen


	mov r0, #0
	mov r1, #0

	@ Loop
0:	bl gfx_wait_vblank
	ldr r0, =char_select_topmsg
	mov r1, #8
	mov r2, #8
	bl font_putstring

	@ For each archetype...
	mov r3, #10
	mov r4, #0

1:	ldr r0, =char_names
	mov r1, #0
	tst r4, #1
	moveq r1, #96
	add r1, r1, #8
	mov r2, r4, lsr #1
	add r2, r2, #2
	mov r2, r2, lsl #4
	bl font_putstring

	add r4, r4, #1
	subs r3, r3, #1
	bne 1b

	@ disable remaining sprites
	stmfd sp!, {r0-r3}
	mov r0, #0
	bl gfx_disable_sprites
	ldmfd sp!, {r0-r3}

	@ Check input
	mov r2, #reg_base
	add r2, r2, #0x130	@ REG_KEY
	ldrh r3, [r2]

	tst r3, #0x100		@ R trigger
	bne 1f	
	add r1, r1, #1		@ next palette
	and r1, r1, #0xf

1:	tst r3, #0x200		@ L trigger
	bne 1f
	sub r1, r1, #1		@ previous palette
	and r1, r1, #0xf

1:	tst r3, #0b1000		@ start button
	beq 9f

	b 0b

9:	ldmfd sp!, {lr}
	bx lr
@ EOR char_select


	.section .rodata
	.align

char_select_topmsg: .string "Select Warrior"
char_names: .string "Dude"

@ EOF main.s
