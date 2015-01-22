@
@ balloon fight
@ core game logic
@

        .include "constants.inc"

@ ---
@ Equates
@ ---

@ maximum actors alive at a time
.equ max_actors, 10
@ total length of the actor structure
.equ actor_len, 32
@ number of bits to shift lift by
.equ lift_shifter, 1
@ physical scaling constant (2^n)
.equ phys_scale, 4
@ gravity
.equ gravity, 16
@ terminal velocities
.equ terminal_yv, 16
.equ terminal_neg_yv, -16
.equ terminal_xv, 16
.equ terminal_neg_xv, -16
.equ min_y_accel, -32
.equ max_x_accel, 16
.equ min_x_accel, -16
@ collision radii
.equ dude_collide_radius, 220

        .equ BALLOON_TILE, 0
        .equ BALLOON_POP_TILE, 1
        .equ ACTOR_TILE_OFFSET, 16
        .equ FRAME_FLY, 0
        .equ FRAME_BUMP, 4
        .equ FRAME_DIE, 8
        .equ FRAME_WIN, 16

        .section .iwram
        .align 2

@ Drift variables
.lcomm drift, 2
@ Number of actors
.lcomm n_actors, 1
@ Actor data
@ 0	byte	palette
@ 1	byte	type
@ 2	byte	mode bits:
@		rrrr rrrf
@		r = reserved, f = facing (0 = right)
@ 3	byte	n_balloons
@ 4	hword	x
@ 6	hword	y
@ 8	hword	x velocity
@ 10	hword	y velocity
@ 12	hword	x acceleration
@ 14	hword	y acceleration
@ 16	byte	current animation
@		laaa aaaa
@		l = has looped?
@		a = animation idx
@ 17	byte	current frame in animation
@ 18	byte	frame delay counter
@ 19-32	bytes	arbitrary state information
@ NOTE: Actor 0 is always the player.
        .align 2
.lcomm actors, actor_len*max_actors

        .align 2
.lcomm arena, 4


	.section .text
	.arm
	.align

	.include "gba.inc"

@@@ play_game(r0 = us, r1 = our color, r2 = them, r3 = their color, r4 = arena)
        .global play_game
play_game:
        stmfd sp!, {r5-r12,lr}

        @@ set things up based on arguments passed in
        ldr r5, =arena_table
        ldr r5, [r5, r4, lsl #2]
        ldr r4, =arena
        str r5, [r4]

        stmfd sp!, {r0-r3}
        @@ setup the background
        mov r0, #REG_DISPCNT
        mov r1, #0x40
        orr r1, r1, #0b10111<<8	@ display sprites.
        strh r1, [r0]

        mov r0, #vram_base
        mov r1, #0x4000
        bl dma_zero32

        mov r0, #1
        ldr r1, [r5,#8]
        bl copy_tilemap_to_vram_bg

        mov r0, #2
        ldr r1, [r5,#12]
        bl copy_tilemap_to_vram_bg

        ldr r0, [r5,#4]
        bl gfx_load_bg_palette

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

        @@ Initialize actor structures
        ldr r0, =n_actors
        mov r1, #2
        strb r1, [r0]

        @@ XXX TODO load spawn points from arena
        ldr r8, =actors
        ldmfd sp!, {r6,r7}
        mov r9, #1
        bl setup_balloonist
        ldmfd sp!, {r6,r7}
        mov r9, #2
        bl setup_balloonist

        @@ Run the core game loop
coreloop:
0:	@ check input (do not call this if we are in demo mode)
	bl human_input
	@ process actors
	@ update physics
	bl update_physics
	@ check collisions
	bl check_collisions
	@ check if any terminating condition occurred

	@ -----
	@ render graphics
	@ -----

	@ Wait for vblank
	bl gfx_wait_vblank

	@ NOTE
	@ after each sprite added, check that we haven't run out of
	@ sprites

	mov r0, #oam_base
	ldr r2, =actors
	ldr r8, =n_actors
	ldrb r8, [r8]

	@ for each actor
	@   render actor to oam based on type and state

1:	ldrsh r1, [r2, #6]  @ y coordinate
        @@ FIXME: clip by y here
        and r1, r1, #0xff
	strh r1, [r0], #2

	ldrb r3, [r2, #2]   @ mode
	ldrsh r1, [r2, #4]  @ x coordinate
        @@ FIXME: clip by x here
        mov r4, #0x200
        sub r4, r4, #1
        and r1, r1, r4
	orr r1, r1, #0x4000 @ size = 16x16
	and r3, r3, #1	    @ take the facing bit
	orr r1, r1, r3, lsl #12
	strh r1, [r0], #2

	@ check type and such here
        ldrb r1, [r2, #17]      @ current frame
        lsl r1, r1, #2
        ldrb r9, [r2]	    @ palette
        @@ XXX hack: use palette number to figure which actor we're indexing.
        add r1, r1, r9, lsl #4
        orr r1, r9, lsl #12
        orr r1, r1, #0x0800 @ priority 2 (behind balloons)
	strh r1, [r0], #2

	@ rotation bits
	mov r1, #0
	strh r1, [r0], #2

	@   set local driftx and drifty from global drift
	@   for each of actor's balloons
        ldrb r4, [r2, #3]   @ number of balloons
        cmp r4, #0
        beq match_finished
	ldrsh r5, [r2, #4]  @ player's x
	@add r5, r5, #8
	ldrsh r6, [r2, #6]  @ player's y
	sub r6, r6, #8

2:	@ FIXME improve drift algorithm
	ldr r7, =drift
	ldrh r1, [r7]
	add r1, r1, #1
	strh r1, [r7]
	tst r1, #1
	addeq r5, r5, #3
	subne r5, r5, #3
	tst r1, #3
	addeq r6, r6, #1
	subne r6, r6, #1

        @@ render balloon to oam
        mov r1, r6	    @ y
        and r1, r1, #255
        strh r1, [r0], #2
        mov r1, #512
        sub r1, r1, #1
        and r1, r5, r1	    @ x
	strh r1, [r0], #2
	@ FIXME add palette switching and such here
	@ also make priority random
        mov r1, #0	    @ tile idx
        orr r1, r1, r9, lsl #12 @ player's palette
	strh r1, [r0], #2
	mov r1, #0	    @ rotation bits
	strh r1, [r0], #2
	@     update driftx, drifty
	add r5, r5, #2
	@ FIXME should cluster around player center
	@ with wider spread for larger n
	subs r4, r4, #1
	bne 2b

3:      add r2, r2, #actor_len
	subs r8, r8, #1
	bne 1b

	@ Disable other sprites.
	mov r8, #oam_base
	add r8, r8, #1024
1:	mov r1, #0x200
	strh r1, [r0], #2
	mov r1, #0
	strh r1, [r0], #2
	strh r1, [r0], #2
	strh r1, [r0], #2
	cmp r0, r8
	blt 1b

	@ loop forever
	b 0b

@@@ We get here from the loop through the actors, where r2 is the pointer to the actor, and r8 is the number of actors left in the table.
match_finished:
        mov r0, #OUTCOME_LOSE
        ldmfd sp!, {r5-r12,pc}
@ EOR coreloop


        @@ copy in frames, setup actor structure
        @@ r5 = vram offset (the value passed in isn't use; we use r9
        @@                   instead and copy to a fixed location)
        @@ r6 = archetype index
        @@ r7 = palettes
        @@ r8 = actors ptr
        @@ r9 = palette index / which player
setup_balloonist:
        stmfd sp!, {lr}
        ldr r4, =archetype_table
        add r4, r4, r6, lsl #5

        mov r5, #vram_base
        add r5, #0x10000
        add r5, r5, r9, lsl #9  @ 32 bytes per tile, 16 tiles per group

        ldr r1, [r4, #16]!      @ fly
        mov r2, #16*16/2
        mov r0, r5
        add r5, r5, r2
        bl dma_copy32

        ldr r1, [r4, #4]!       @ bump
        mov r2, #16*16/2
        mov r0, r5
        add r5, r5, r2
        bl dma_copy32

        ldr r1, [r4, #4]!       @ die
        mov r2, #16*16/2
        mov r0, r5
        add r5, r5, r2
        bl dma_copy32

        ldr r1, [r4, #4]!       @ win
        mov r2, #16*16/2
        mov r0, r5
        add r5, r5, r2
        bl dma_copy32

        mov r0, #palram_base
        add r0, #0x200
        add r0, r0, r9, lsl #5
        ldr r2, =invariant_palette
        ldmia r2, {r1-r4}
        stmia r0!, {r1-r4}

        and r1, r7, #0xff
        lsr r3, r7, #8
        ldr r2, =palette_table
        add r3, r2, r3, lsl #3
        add r2, r2, r1, lsl #3
        ldmia r2, {r1,r2}
        stmia r0!, {r1,r2}
        ldmia r3, {r1,r2}
        stmia r0!, {r1,r2}

        strb r9, [r8], #1       @ palette
        strb r6, [r8], #1       @ archetype
        mov r1, #0x00	    @ mode
        strb r1, [r8], #1
        mov r1, #0x04	    @ n_balloons
        strb r1, [r8], #1
        mov r1, #42	    @ x
        cmp r9, #2
        addeq r1, r1, #100
        strh r1, [r8], #2
        mov r1, #52	    @ y
        strh r1, [r8], #2
        mov r1, #0	    @ x velocity
        strh r1, [r8], #2
        strh r1, [r8], #2   @ ... and y velocity
        strh r1, [r8], #2   @ ... and x acceleration
        strh r1, [r8], #2   @ ... and y acceleration
        mov r1, #0	    @ current animation and frame
        strh r1, [r8], #2
        @ we don't touch the arbitrary state information
        add r8, r8, #14

        ldmfd sp!, {pc}

@ human_input
@ FIXME replace raw compares with table lookups of player speeds
@
human_input:
        stmfd sp!, {r4,lr}
        ldr r2, =key_input
        ldrh r1, [r2], #2
        ldrh r4, [r2]           @ debounce
	@ NOTE: the human controllable player is always
	@ actor zero.
	ldr r2, =actors

        @@ B button (flap)
        tst r1, #0b10	    @ B button
        tstne r4, #0b10	    @ check debounce
	beq 0f
	ldrsh r3, [r2, #14]  @ y acceleration
	sub r3, r3, #16
	cmp r3, #min_y_accel
	movlt r3, #min_y_accel
	strh r3, [r2, #14]
	b 1f

	@ sink y accel to zero
0:	ldrsh r3, [r2, #14]  @ y acceleration
	cmp r3, #0
	addlt r3, r3, #1
	subgt r3, r3, #1
	strh r3, [r2, #14]

1:	tst r1, #0b00010000 @ right
	bne 0f
	ldrb r3, [r2, #2]   @ mode
	bic r3, r3, #1	    @ face right
	strb r3, [r2, #2]
	ldrsh r3, [r2, #12]  @ x acceleration
	add r3, r3, #8
	cmp r3, #max_x_accel
	movgt r3, #max_x_accel
	strh r3, [r2, #12]
	b 9f

0:	tst r1, #0b00100000 @ left
	bne 1f
	ldrb r3, [r2, #2]   @ mode
	orr r3, r3, #1	    @ face left
	strb r3, [r2, #2]
	ldrsh r3, [r2, #12]  @ x accel
	sub r3, r3, #8
	cmp r3, #min_x_accel
	movlt r3, #min_x_accel
	strh r3, [r2, #12]
	b 9f

1:	ldrsh r3, [r2, #12]  @ x acceleration
	cmp r3, #0
	addlt r3, r3, #2
	subgt r3, r3, #2
	strh r3, [r2, #12]

9:	@tst r1, #0b01000000 @ up
	@tst r1, #0b10000000 @ down

        ldmfd sp!, {r4,pc}
@ EOR human_input


@ update_physics
@
update_physics:
	stmfd sp!, {lr}
	@ For each actor...
	ldr r0, =actors
	ldr r8, =n_actors
	ldrb r8, [r8]

0:	@ calculate lift
	ldrb r2, [r0, #3]	@ nballoons
	mov r2, r2, lsl #lift_shifter
	@ sub this from our acceleration
	ldrsh r1, [r0, #14]	@ y accel
	sub r1, r1, r2
	add r1, r1, #gravity	@ apply gravity
	ldrsh r2, [r0, #10]	@ y velocity
	add r2, r2, r1		@ euler integration
	@ clip against terminal velocity
	cmp r2, #terminal_yv
	movgt r2, #terminal_yv
	cmp r2, #terminal_neg_yv
	movlt r2, #terminal_neg_yv
	strh r2, [r0, #10]

	ldrsh r1, [r0, #12]	@ x accel
	ldrsh r2, [r0, #8]	@ x velocity
	add r2, r2, r1		@ euler integration
	@ clip against terminal velocity
	cmp r2, #terminal_xv
	movgt r2, #terminal_xv
	cmp r2, #terminal_neg_xv
	movlt r2, #terminal_neg_xv
	strh r2, [r0, #8]

	@ integrate velocity into position
	ldrsh r1, [r0, #10]	@ y velocity
	ldrsh r2, [r0, #6]	@ y position
	add r2, r2, r1, asr #phys_scale
	@ clip against sides of the world
	cmp r2, #144
	movgt r2, #144
	movgt r1, #0
	cmp r2, #0
	movlt r2, #0
	movlt r1, #0
	strh r2, [r0, #6]
	strh r1, [r0, #10]

	ldrsh r1, [r0, #8]	@ x velocity
	ldrsh r2, [r0, #4]	@ x position
	add r2, r2, r1, asr #phys_scale
	@ clip against sides of the world
	cmp r2, #224
	movgt r2, #224
	movgt r1, #0
	cmp r2, #0
	movlt r2, #0
	movlt r1, #0
	strh r2, [r0, #4]
        strh r1, [r0, #8]

        @@ collide with playfield
        ldrsh r1, [r0, #4]	@ x position
        ldrsh r2, [r0, #6]	@ y position
        mov r2, r2, lsr #3
        mov r1, r1, lsr #3
        ldr r3, =arena
        ldr r3, [r3]
        ldr r3, [r3, #8]
        ldrb r4, [r3], #2       @ width of map
        mla r4, r2, r4, r1
        lsl r4, r4, #1
        ldrh r4, [r3, r4]
        cmp r4, #0
        beq 1f

        @@ mov r1, r1, lsl #3
        mov r2, r2, lsl #3
        ldrsh r4, [r0, #10]      @ y velocity
        cmp r4, #0
        addlt r2, r2, #8
        subgt r2, r2, #16
        @@ strh r1, [r0, #4]	@ x position
        strh r2, [r0, #6]	@ y position
        mov r4, #0
        strh r4, [r0, #8]	@ x velocity
        strh r4, [r0, #10]      @ y velocity
1:

	@ apply friction to velocity
	ldrsh r1, [r0, #8]	@ x velocity
	cmp r1, #0
	addlt r1, r1, #1
	subgt r1, r1, #1
	strh r1, [r0, #8]

	@ Next actor.
	add r0, r0, #actor_len
	subs r8, r8, #1
	bne 0b

        ldmfd sp!, {pc}
@ EOR update_physics


@ check_collisions
@
check_collisions:
	stmfd sp!, {lr}
	ldr r0, =actors
	ldr r2, =n_actors
	ldrb r2, [r2]
0:	@ For a in each actor...
	ldr r1, =actors
	ldr r3, =n_actors
        ldrb r3, [r3]
	ldrsh r4, [r0, #4]	@ a's x coord
	ldrsh r5, [r0, #6]	@ a's y coord
1:	@   For b in each actor again...
	@     If a = b then Next
	cmp r2, r3
	beq 9f
	@ FIXME: If the velocity delta > 0, no collision
	@     Switch collidep(a, b)
	ldrsh r6, [r1, #4]	@ b's x coord
	ldrsh r7, [r1, #6]	@ b's y coord
	@ y' = ay - by
	sub r9, r5, r7
	@ y = y'*y'
	mul r8, r9, r9
	@ x = ax - bx
	sub r9, r4, r6
	@ p = x*x + y
	mla r10, r9, r9, r8
	@ FIXME: replace with table lookup on type property
	mov r8, #dude_collide_radius
	mov r9, #dude_collide_radius
	add r8, r8, r9
	cmp r10, r8
	bgt 9f		    @ no collision

	cmp r5, r7	    @ compare y coords
	@       case equal:
	@         elastic collision
	@       case higher:
	@         do_damage(a, b)
	@       case lower:
	@       default:
	@         do_damage(b, a)

	blt 2f
	bgt 3f

	b 8f

2:	@ do damage to b
	stmfd sp!, {r0-r10}
	mov r2, r0
	mov r0, r1
	mov r1, r2
	bl do_damage
	ldmfd sp!, {r0-r10}
	b 8f

3:	@ do damage to a
	stmfd sp!, {r0-r10}
	bl do_damage
	ldmfd sp!, {r0-r10}
	b 8f

8:	@ collision response
	ldrsh r8, [r0, #8]
	ldrsh r9, [r1, #8]
	strh r9, [r0, #8]
	strh r8, [r1, #8]
	add r4, r4, r9, asr #phys_scale
	add r6, r6, r8, asr #phys_scale
	strh r4, [r0, #4]
	strh r6, [r1, #4]

	ldrsh r8, [r0, #10]
	ldrsh r9, [r1, #10]
	strh r9, [r0, #10]
	strh r8, [r1, #10]
	add r5, r5, r9, asr #phys_scale
	add r7, r7, r8, asr #phys_scale
	strh r5, [r0, #6]
	strh r7, [r1, #6]

9:	add r1, r1, #actor_len
	subs r3, r3, #1
	bne 1b

	add r0, r0, #actor_len
	subs r2, r2, #1
	bne 0b

        ldmfd sp!, {pc}
@ EOR check_collisions


@ do_damage(defender, attacker)
@
do_damage:
        stmfd sp!, {r0-r3,lr}
	ldrb r2, [r0, #3]	@ n_balloons
	subs r2, r2, #1
	bne 1f

	@ deal with popping
        mov r2, #0

1:	strb r2, [r0, #3]

        @@ make noise
        mov r0, #3
        mov r1, #0
        mov r2, #0x510
        bl music_play_sfx

        ldmfd sp!, {r0-r3,pc}
@ EOR do_damage

@ EOF game.s
