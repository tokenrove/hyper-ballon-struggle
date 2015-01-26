@@@
@@@ balloon spite
@@@ core game logic
@@@

        .include "game.inc"
        .include "arenas.inc"
        .include "archetype.inc"

        @@ Physics numbers are mostly 12.4 fixed point
        .equ PHYS_FIXED_POINT, 4
        @@ Accounts for both the division by 2 required for correct
        @@ integration, and the fixed point fraction of mass
        .equ IMPULSE_SCALING, 6
        @@ Terminal velocity
        .equ TERMINAL_VELOCITY, 16
        @@ Collision radii squared
        .equ COLLIDE_TYPE_0_RADIUS, 50
        .equ COLLIDE_TYPE_1_RADIUS, 220

        .equ BALLOON_TILE, 0
        .equ BALLOON_POP_TILE, 1
        .equ ACTOR_TILE_OFFSET, 16
        .equ FRAME_FLY, 0
        .equ FRAME_BUMP, 4
        .equ FRAME_DIE, 8
        .equ FRAME_WIN, 16

        .equ BODY_LEN, 16
        .equ BALLOONIST_LEN, BODY_LEN+16
        .equ N_BALLOONISTS,2
        .equ MAX_BALLOONS,8

        .equ BALLOON_MASS, 1
        .equ BALLOON_LIFT, -20

        .equ BODY_T_X, 0
        .equ BODY_T_Y, 2
        .equ BODY_T_VX, 4
        .equ BODY_T_VY, 6
        .equ BODY_T_IMPULSE_X, 8
        .equ BODY_T_IMPULSE_Y, 10
        .equ BODY_T_COLLIDE_TYPE, 12
        .equ BODY_T_MASS, 13

        .equ BALLOON_T_POPPING_CTR, 14

        .equ ACTOR_T_ARCHETYPE_PTR, 16
        .equ ACTOR_T_EXERTION, 20
        .equ ACTOR_T_TILE_OFFSET, 22
        .equ ACTOR_T_FRAME, 24
        .equ ACTOR_T_FRAME_DELAY, 25
        .equ ACTOR_T_ANIMATION, 26
        .equ ACTOR_T_BALLOONS, 27
        .equ ACTOR_T_INVULNERABILITY, 28
        .equ ACTOR_T_IDENTITY, 29

        .section .iwram

        @@ See the file HACKING.org for details of these structures
        .align 2
        .lcomm balloonists, BALLOONIST_LEN*N_BALLOONISTS
        .align 2
        .lcomm balloons, BODY_LEN*MAX_BALLOONS*N_BALLOONISTS

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

        @@ put the balloonist spawns on the stack for later
        ldrh r6, [r5, #ARENA_T_SPAWN_1_X]
        ldrh r7, [r5, #ARENA_T_SPAWN_2_X]
        stmfd sp!, {r2,r3,r7}
        stmfd sp!, {r0,r1,r6}

        bl setup_arena
        bl setup_balloons

        ldr r8, =balloonists
        ldmfd sp!, {r6,r7,r10}
        mov r9, #1
        bl setup_balloonist
        ldr r8, =balloonists+BALLOONIST_LEN
        ldmfd sp!, {r6,r7,r10}
        mov r9, #2
        bl setup_balloonist

        @@ Run the core game loop
.Lcoreloop:
0:
        ldr r5, =arena
        ldr r5, [r5]

        @@ PROCESS ACTORS
        @@ If we're in demo mode, we'd want to call an alternate
        @@ routine for the player.
        ldr r4, =balloonists
        bl apply_gravity
        bl human_input
        add r4, r4, #BALLOONIST_LEN
        bl apply_gravity
        bl enemy_action

        ldr r4, =balloonists
        add r6, r4, #BALLOONIST_LEN
        bl check_balloonist_collisions
        eor r4, r4, r6
        eor r6, r4, r6
        eor r4, r4, r6
        bl check_balloonist_collisions

        @@ UPDATE PHYSICS
        ldr r4, =balloonists
        bl update_balloonist_motion
        add r4, r4, #BALLOONIST_LEN
        bl update_balloonist_motion

        @@ check if any terminating condition occurred
        ldr r4, =balloonists
        ldrb r2, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        cmp r2, #0
        beq .Lmatch_finished
        add r4, r4, #BALLOONIST_LEN
        ldrb r2, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        cmp r2, #0
        beq .Lmatch_finished

        @@ RENDER GRAPHICS
        bl gfx_wait_vblank

        mov r0, #oam_base
        ldr r4, =balloonists
        bl render_balloonist
        add r4, r4, #BALLOONIST_LEN
        bl render_balloonist

        bl disable_remaining_sprites

        @@ loop forever
        b .Lcoreloop

.Lmatch_finished:
        ldrb r0, [r4, #ACTOR_T_IDENTITY]
        cmp r0, #1
        moveq r0, #OUTCOME_LOSE
        movne r0, #OUTCOME_WIN
        ldmfd sp!, {r5-r12,pc}


        @@ r5 = arena ptr
setup_arena:
        stmfd sp!, {lr}
        @@ setup the background
        bl gfx_wait_vblank
        mov r0, #REG_DISPCNT
        mov r1, #0x40
        orr r1, r1, #0b10111<<8	@ display sprites.
        strh r1, [r0]

        mov r0, #vram_base
        mov r1, #0x4000
        bl dma_zero32

        mov r0, #1
        ldr r1, [r5, #ARENA_T_MIDGROUND_PTR]
        bl copy_tilemap_to_vram_bg

        mov r0, #2
        ldr r1, [r5, #ARENA_T_MIDGROUND_PTR+4]
        bl copy_tilemap_to_vram_bg

        ldr r0, [r5, #ARENA_T_PALETTE_PTR]
        bl gfx_load_bg_palette
        ldmfd sp!, {pc}


        @@ Expects r0 to point to our current offset into OAM
disable_remaining_sprites:
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
        mov pc, lr


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

        @@ Make balloons transparent
        ldr r1, =REG_BLDCNT
        mov r3, #0x0f40
        strh r3, [r1], #2
        mov r3, #0x0400
        orr r3, r3, #0x1c
        strh r3, [r1]

        ldr r0, =balloons
        mov r1, #BODY_LEN*MAX_BALLOONS*N_BALLOONISTS
        bl dma_zero32

        ldmfd sp!, {pc}


        @@ copy in frames, setup actor structure
        @@ r5 = vram offset (the value passed in isn't use; we use r9
        @@                   instead and copy to a fixed location)
        @@ r6 = archetype index
        @@ r7 = palettes
        @@ r8 = actors ptr
        @@ r9 = palette index / which player
        @@ r10 = spawn point (y<<8 | x)
setup_balloonist:
        stmfd sp!, {lr}
        ldr r4, =archetype_table
        add r4, r4, r6, lsl #5
        str r4, [r8, #ACTOR_T_ARCHETYPE_PTR]

        @@ Fill in body structure
        and r1, r10, #0xff
        lsl r1, r1, #PHYS_FIXED_POINT
        strh r1, [r8, #BODY_T_X]   @ X
        lsr r1, r10, #8
        lsl r1, r1, #PHYS_FIXED_POINT
        strh r1, [r8, #BODY_T_Y]   @ Y
        mov r1, #0
        str r1, [r8, #BODY_T_VX]    @ x and y velocity
        str r1, [r8, #BODY_T_IMPULSE_X]   @ x and y impulse
        mov r1, #1
        strb r1, [r8, #BODY_T_COLLIDE_TYPE] @ 16x16 collisions
        ldrb r1, [r4, #ARCHETYPE_T_MASS]
        strb r1, [r8, #BODY_T_MASS]

        @@ Copy frames into VRAM
        mov r5, #vram_base
        add r5, #0x10000
        add r5, r5, r9, lsl #9  @ 32 bytes per tile, 16 tiles per group

        add r4, r4, #ARCHETYPE_T_FRAME_PTRS
        .rept 4             @ fly, bump, die, win
          ldr r1, [r4], #4
          mov r2, #16*16/2
          mov r0, r5
          add r5, r5, r2
          bl dma_copy32
        .endr

        @@ Setup palette
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

        @@ Fill in balloonist structure
        strb r9, [r8, #ACTOR_T_IDENTITY]
        mov r1, r9, lsl #4
        strh r1, [r8, #ACTOR_T_TILE_OFFSET]
        mov r1, #0	    @ frame and facing
        strb r1, [r8, #ACTOR_T_FRAME]
        strb r1, [r8, #ACTOR_T_FRAME_DELAY]
        strb r1, [r8, #ACTOR_T_ANIMATION]
        strb r1, [r8, #ACTOR_T_INVULNERABILITY]
        strh r1, [r8, #ACTOR_T_EXERTION]

        @@ XXX should clear enemy state info here
        mov r3, #40
        strh r3, [r8, #BODY_T_IMPULSE_X]

        @@ start with 4 balloons
        mov r5, #0b1111
        strb r5, [r8, #ACTOR_T_BALLOONS]

        ldr r0, =balloons
        sub r2, r9, #1
        add r0, r0, r2, lsl #7 @ log2(BODY_LEN*MAX_BALLOONS)

        @@ place balloons initially in fixed positions in an arc around the player
        ldrsh r2, [r8, #BODY_T_X]
        ldrsh r3, [r8, #BODY_T_Y]
        ldr r4, =initial_balloon_offs

1:      ldrsb r1, [r4], #1
        add r1, r2, r1, lsl #PHYS_FIXED_POINT
        strh r1, [r0, #BODY_T_X]
        ldrsb r1, [r4], #1
        add r1, r3, r1, lsl #PHYS_FIXED_POINT
        strh r1, [r0, #BODY_T_Y]

        mov r1, #0
        strb r1, [r0, #BODY_T_COLLIDE_TYPE]
        mov r1, #BALLOON_MASS
        strb r1, [r0, #BODY_T_MASS]

        add r0, r0, #BODY_LEN

2:      lsrs r5, r5, #1
        beq 1f
        tst r5, #1
        bne 1b
        b 2b
1:

        ldmfd sp!, {pc}


        @@ render actor and balloons to oam
        @@ r4 = us
        @@ r0 =  OAMptr
render_balloonist:
        stmfd sp!, {lr}

        ldrb r9, [r4, #ACTOR_T_IDENTITY]
        ldrb r5, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        ldr r3, =balloons
        sub r2, r9, #1
        add r3, r3, r2, lsl #7 @ log2(BODY_LEN*MAX_BALLOONS)
.Lnext_balloon:
        cmp r5, #0
        beq .Ldone
        tst r5, #1
        lsreq r5, r5, #1
        addeq r3, r3, #BODY_LEN
        beq .Lnext_balloon

        ldrsh r1, [r3, #BODY_T_Y]
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #4
        and r1, r1, #255
        orr r1, r1, #0x400
        strh r1, [r0], #2

        ldrsh r1, [r3, #BODY_T_X]
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #4
        mov r2, #512
        sub r2, r2, #1
        and r1, r1, r2
        strh r1, [r0], #2

        @@ would be nice to make priority random
        mov r1, #0              @ tile idx
        orr r1, r1, r9, lsl #12 @ player's palette
        strh r1, [r0], #2

        mov r1, #0              @ rotation bits
        strh r1, [r0], #2

        add r3, r3, #BODY_LEN
        lsrs r5, r5, #1
        bne .Lnext_balloon

.Ldone:
        ldrsh r1, [r4, #BODY_T_Y]  @ y coordinate
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #8
        @@ FIXME: clip by y here
        and r1, r1, #0xff
        strh r1, [r0], #2

        ldrb r3, [r4, #ACTOR_T_FRAME]   @ mode
        ldrsh r1, [r4, #BODY_T_X]  @ x coordinate
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #8
        @@ FIXME: clip by x here
        mov r2, #0x200
        sub r2, r2, #1
        and r1, r1, r2
        orr r1, r1, #0x4000 @ size = 16x16
        and r2, r3, #1	    @ take the facing bit
        orr r1, r1, r2, lsl #12
        strh r1, [r0], #2

        bic r2, r2, #1
        lsl r2, r2, #1
        @@ XXX hack: use palette number to figure which actor we're indexing.
        add r2, r2, r9, lsl #4
        orr r2, r9, lsl #12
        orr r2, r2, #0x0800 @ priority 2 (behind balloons)
        strh r2, [r0], #2

        @ rotation bits
        mov r1, #0
        strh r1, [r0], #2

        ldmfd sp!, {pc}


@ FIXME replace raw compares with table lookups of player speeds
        @@ r4 = us
human_input:
        stmfd sp!, {lr}
        ldr r2, =key_input
        ldrh r1, [r2], #2
        ldrh r2, [r2]           @ debounce

        @@ XXX temporary debug function: hold A to fly around
        tst r1, #1
        bne .Lregular_input

        mov r3, #0
        strh r3, [r4, #BODY_T_IMPULSE_Y]

        tst r1, #0x10
        bne 1f
        mov r3, #8
        strh r3, [r4, #BODY_T_IMPULSE_X]
1:      tst r1, #0x20
        bne 1f
        mov r3, #-8
        strh r3, [r4, #BODY_T_IMPULSE_X]
1:      tst r1, #0x40
        bne 1f
        mov r3, #-8
        strh r3, [r4, #BODY_T_IMPULSE_Y]
1:      tst r1, #0x80
        bne 1f
        mov r3, #16
        strh r3, [r4, #BODY_T_IMPULSE_Y]
1:      ldmfd sp!, {pc}

.Lregular_input:
        @@ B button (flap)
        tst r2, #0b10           @ B button
        bne .Lnot_flapping
        @@ XXX maybe give us a little extra impulse on the frame after debounce?
        ldrsh r3, [r4, #BODY_T_IMPULSE_Y]
        ldr r0, [r4, #ACTOR_T_ARCHETYPE_PTR]
        ldrb r0, [r0, #ARCHETYPE_T_STRENGTH]
        sub r3, r3, r0, lsl #2
        @@ XXX this is where the flap abstraction needs to happen
        strh r3, [r4, #BODY_T_IMPULSE_Y]

1:	tst r1, #0b00010000 @ right
        bne 0f
        ldrb r3, [r4, #ACTOR_T_FRAME]
        bic r3, r3, #1          @ face right
        strb r3, [r4, #ACTOR_T_FRAME]
        ldrsh r3, [r4, #BODY_T_IMPULSE_X]
        @@ add r3, r3, #8
        mov r3, #8
        strh r3, [r4, #BODY_T_IMPULSE_X]
        b 9f

0:	tst r1, #0b00100000 @ left
        bne 9f
        ldrb r3, [r4, #ACTOR_T_FRAME]
        orr r3, r3, #1          @ face left
        strb r3, [r4, #ACTOR_T_FRAME]
        ldrsh r3, [r4, #BODY_T_IMPULSE_X]
        @@ sub r3, r3, #8
        mov r3, #-8
        strh r3, [r4, #BODY_T_IMPULSE_X]

.Lnot_flapping:
9:
        ldmfd sp!, {pc}


        @@ r4 = us
enemy_action:
        stmfd sp!, {lr}
        @@ XXX needs to become a separate state variable
        ldrb r0, [r4, #ACTOR_T_FRAME_DELAY]
        subs r0, r0, #1
        movne r3, #0
        bne 0f
        mov r0, #20
        mov r3, #-16
        strh r3, [r4, #BODY_T_IMPULSE_Y]  @ y acceleration
0:      strb r0, [r4, #ACTOR_T_FRAME_DELAY]
        ldmfd sp!, {pc}


        @@ r4 = balloonist
        @@ r5 = arena
apply_gravity:
        ldrsh r1, [r4, #BODY_T_IMPULSE_Y]
        ldrsb r0, [r5, #ARENA_T_GRAVITY]
        add r1, r1, r0
        strh r1, [r4, #BODY_T_IMPULSE_Y]
        mov pc,lr


        @@ r4 = this balloonist
        @@ r5 = arena
update_balloonist_motion:
	stmfd sp!, {lr}

        @@ update balloons
        ldrb r6, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        ldrsh r7, [r4, #BODY_T_X]
        ldrsh r8, [r4, #BODY_T_Y]
        ldrb r9, [r4, #ACTOR_T_IDENTITY]
        ldrb r0, [r4, #ACTOR_T_IDENTITY]
        sub r0, r0, #1
        stmfd sp!, {r4}
        ldr r4, =balloons
        add r4, r4, r0, lsl #7 @ log2(BODY_LEN*MAX_BALLOONS)
0:      tst r6, #1
        beq 1f

        ldrsh r0, [r4, #BODY_T_IMPULSE_Y]
        add r0, r0, #BALLOON_LIFT
        strh r0, [r4, #BODY_T_IMPULSE_Y]
        bl update_body_motion
        @@ constrain to be within a given radius of the ballonist
        ldrsh r0, [r4, #BODY_T_X]
        ldrsh r1, [r4, #BODY_T_Y]
        asr r0, r0, #PHYS_FIXED_POINT
        sub r0, r0, r7, asr #PHYS_FIXED_POINT
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, r8, asr #PHYS_FIXED_POINT
        mul r2, r0, r0
        mla r2, r1, r1, r2
        cmp r9, #1
        bne 8f
        stmfd sp!, {r0-r5}
        mov r0, r2
        bl print_debug_word
        ldmfd sp!, {r0-r5}
8:

        cmp r2, #30<<PHYS_FIXED_POINT
        blt 1f
        @@ bring balloons closer
        strh r7, [r4, #BODY_T_X]
        strh r8, [r4, #BODY_T_Y]
        @@ apply lift to balloonist

1:      add r4, r4, #BODY_LEN
        lsrs r6, r6, #1
        bne 0b

        ldmfd sp!, {r4}

        @@ update balloonist
        bl update_body_motion

        ldmfd sp!, {pc}


        @@ r4 = body
        @@ r5 = arena
update_body_motion:
        @@ we should be able to avoid saving a few of these registers
        @@ if we're a little more careful.
        stmfd sp!, {r6-r10,lr}

        ldrb r3, [r4, #BODY_T_MASS]

        @@ delta = mass * impulse
        mov r0, #0
        ldrsh r1, [r4, #BODY_T_IMPULSE_X]
        strh r0, [r4, #BODY_T_IMPULSE_X]
        mul r0, r1, r3
        asr r0, r0, #IMPULSE_SCALING
        @@ velocity += delta / 2
        ldrsh r1, [r4, #BODY_T_VX]
        add r1, r1, r0, asr #1
        @@ position += velocity
        ldrsh r2, [r4, #BODY_T_X]
        add r2, r2, r1

        @@ delta = mass * impulse
        mov r6, #0
        ldrsh r7, [r4, #BODY_T_IMPULSE_Y]
        strh r6, [r4, #BODY_T_IMPULSE_Y]
        mul r6, r7, r3
        asr r6, r6, #IMPULSE_SCALING
        @@ velocity += delta / 2
        ldrsh r7, [r4, #BODY_T_VY]
        add r7, r7, r6, asr #1
        @@ position += velocity
        ldrsh r8, [r4, #BODY_T_Y]
        add r8, r8, r7

        @@ at this point
        @@ r0 = accel delta X
        @@ r1 = vx
        @@ r2 = x
        @@ r3 = mass (unused from here on)
        @@ r4 = actor
        @@ r5 = arena
        @@ r6 = accel delta y
        @@ r7 = vy
        @@ r8 = y

        ldrb r3, [r4, #BODY_T_COLLIDE_TYPE]
        stmfd sp!, {r0,r4,r6}
        @@ free: r0,r4,r6,r9,r10

@@         ldr r8, [r5, #ARENA_T_MIDGROUND_PTR]
@@         ldrb r6, [r8], #1
@@         ldrb r7, [r8], #1

@@         @@ we check the minkowski sum of an 8x8 tile and either an 8x8 or 16x16 sprite

@@         @@ collide with playfield
@@         @@ we check the four tiles that compose the balloonist and set
@@         @@ a flag for each, then decide how to respond based on those
@@         @@ flags and current velocity
@@         ldrsh r1, [r4, #BODY_T_X]
@@         ldrsh r2, [r4, #BODY_T_Y]
@@         @@ subs r1, r1, #4<<PHYS_FIXED_POINT
@@         @@ subs r2, r2, #4<<PHYS_FIXED_POINT
@@         asrs r2, #3+PHYS_FIXED_POINT
@@         movmi r2, #0
@@         asrs r1, #3+PHYS_FIXED_POINT
@@         movmi r1, #0
@@         sub r2, r2, #1
@@         sub r1, r1, #1
@@         mla r0, r2, r6, r1
@@         lsl r0, r0, #1
@@         add r1, r0, r6, lsl #1
@@         add r1, r1, r6, lsl #1
@@         ldrh r2, [r8, r0]
@@         add r0, r0, #4
@@         ldrh r3, [r8, r0]
@@         ldrh r0, [r8, r1]
@@         add r1, r1, #4
@@         ldrh r1, [r8, r1]

@@         @@ r6 = rlRL -- i.e., Upper Left collision is bit 0
@@         mov r6, #0
@@         cmp r2, #0
@@         movne r6, #0b1
@@         cmp r3, #0
@@         orrne r6, r6, #0b10
@@         cmp r0, #0
@@         orrne r6, r6, #0b100
@@         cmp r1, #0
@@         orrne r6, r6, #0b1000

@@         ldrsh r0, [r4, #BODY_T_VY]
@@         cmp r0, #0
@@         beq .Lcheck_h
@@         bmi .Lnegative_y
@@         tst r6, #0b1100
@@         beq .Lcheck_h
@@         @@ we're on a floor
@@         mov r0, #0
@@         strh r0, [r4, #BODY_T_VY]
@@         ldrsh r0, [r4, #BODY_T_Y]
@@         sub r0, r0, #1<<PHYS_FIXED_POINT
@@         bic r0, r0, #0xf
@@         strh r0, [r4, #BODY_T_Y]
@@         b .Lcheck_h
@@ .Lnegative_y:
@@         tst r6, #0b11
@@         beq .Lcheck_h
@@         @@ okay, we hit a roof
@@         mov r0, #0
@@         strh r0, [r4, #BODY_T_VY]
@@         ldrsh r0, [r4, #BODY_T_Y]
@@         add r0, r0, #1<<PHYS_FIXED_POINT
@@         bic r0, r0, #0xf
@@         strh r0, [r4, #BODY_T_Y]

@@ .Lcheck_h:
@@         ldrsh r0, [r4, #BODY_T_VX]
@@         cmp r0, #0
@@         beq .Ldone_checking
@@         bmi .Lnegative_x
@@         tst r6, #0b1010
@@         beq .Ldone_checking
@@         mov r0, #0
@@         strh r0, [r4, #BODY_T_VX]
@@         ldrsh r0, [r4, #BODY_T_X]
@@         sub r0, r0, #1<<PHYS_FIXED_POINT
@@         bic r0, r0, #0xf
@@         strh r0, [r4, #BODY_T_X]
@@         b .Ldone_checking

@@ .Lnegative_x:
@@         tst r6, #0b101
@@         beq .Ldone_checking
@@         mov r0, #0
@@         strh r0, [r4, #BODY_T_VX]
@@         ldrsh r0, [r4, #BODY_T_X]
@@         add r0, r0, #1<<PHYS_FIXED_POINT
@@         bic r0, r0, #0xf
@@         strh r0, [r4, #BODY_T_X]

@@ .Ldone_checking:

        @@ Clip against the sides of the world
        ldr r6, [r5, #ARENA_T_MIDGROUND_PTR]
        ldrb r9, [r6], #1
        ldrb r10, [r6], #1
        @@ r9,r10,r6 = width, height, map ptr
        ldrb r0, [r5, #ARENA_T_FLAGS]
.Lright_side:
        cmp r1, #0
        blt .Lleft_side
        cmp r2, r9, lsl #3+PHYS_FIXED_POINT
        blt .Ltop_side
        tst r0, #ARENA_FLAG_WRAP_H
        bne 1f
        mov r2, r9, lsl #3+PHYS_FIXED_POINT
        mov r1, #0
        b .Ltop_side
1:      sub r2, r2, r9, lsl #3+PHYS_FIXED_POINT
        b .Ltop_side
.Lleft_side:
        cmp r2, #0
        bgt .Ltop_side
        tst r0, #ARENA_FLAG_WRAP_H
        bne 1f
        mov r2, #0
        mov r1, #0
        b .Ltop_side
1:      add r2, r2, r9, lsl #3+PHYS_FIXED_POINT

.Ltop_side:
        cmp r7, #0
        blt .Lbottom_side
        cmp r8, r10, lsl #3+PHYS_FIXED_POINT
        blt .Ldone_clipping
        tst r0, #ARENA_FLAG_WRAP_V
        bne 1f
        mov r8, r10, lsl #3+PHYS_FIXED_POINT
        mov r7, #0
        b .Ldone_clipping
1:      sub r8, r8, r10, lsl #3+PHYS_FIXED_POINT
        b .Ldone_clipping
.Lbottom_side:
        cmp r8, #0
        bgt .Ldone_clipping
        tst r0, #ARENA_FLAG_WRAP_V
        bne 1f
        mov r8, #0
        mov r7, #0
        b .Ldone_clipping
1:      add r8, r8, r10, lsl #3+PHYS_FIXED_POINT

.Ldone_clipping:

        ldmfd sp!, {r0,r4,r6}

.Lafter_playfield_collision:
        strh r2, [r4, #BODY_T_X]
        @@ velocity += delta / 2
        add r1, r1, r0, asr #1
        @@ Stokes' drag
        @@ velocity -= velocity / 16
        movs r0, r1, asr #4
        moveqs r0, r1, asr #3
        moveqs r0, r1, asr #2
        moveqs r0, r1, asr #1
        moveqs r0, r1
        subne r1, r1, r0
        strh r1, [r4, #BODY_T_VX]

        strh r8, [r4, #BODY_T_Y]
        @@ velocity += delta / 2
        add r7, r7, r6, asr #1
        @@ Stokes' drag
        @@ velocity -= velocity / 16
        movs r0, r7, asr #4
        moveqs r0, r7, asr #3
        moveqs r0, r7, asr #2
        moveqs r0, r7, asr #1
        moveqs r0, r7
        subne r7, r7, r0
        strh r7, [r4, #BODY_T_VY]

        ldmfd sp!, {r6-r10,pc}


        @@ r4 = balloonist
        @@ r6 = other balloonist
check_balloonist_collisions:
        stmfd sp!, {lr}
        ldrsh r0, [r4, #BODY_T_X]
        ldrsh r1, [r4, #BODY_T_Y]

        @ FIXME: If the velocity delta > 0, no collision
	@     Switch collidep(a, b)
        ldrsh r2, [r6, #BODY_T_X]
        ldrsh r3, [r6, #BODY_T_Y]
        @ dy = ay - by
        sub r9, r1, r3
        @ dy^2
	mul r8, r9, r9
        @ dx = ax - bx
        sub r9, r0, r2
        @ p = dx^2 + dy^2
	mla r10, r9, r9, r8
	@ FIXME: replace with table lookup on type property
        mov r8, #COLLIDE_TYPE_1_RADIUS
        mov r9, #COLLIDE_TYPE_1_RADIUS
	add r8, r8, r9
	cmp r10, r8
        bgt .Lno_collision

        @@ collision response
        ldrsh r8, [r4, #BODY_T_VX]
        ldrsh r9, [r6, #BODY_T_VX]
        strh r9, [r4, #BODY_T_VX]
        strh r8, [r6, #BODY_T_VX]
        add r0, r0, r9, asr #PHYS_FIXED_POINT
        add r1, r1, r8, asr #PHYS_FIXED_POINT
        strh r0, [r4, #BODY_T_X]
        strh r1, [r6, #BODY_T_X]

        ldrsh r8, [r4, #BODY_T_VY]
        ldrsh r9, [r6, #BODY_T_VY]
        strh r9, [r4, #BODY_T_VY]
        strh r8, [r6, #BODY_T_VY]
        add r1, r1, r9, asr #PHYS_FIXED_POINT
        add r3, r3, r8, asr #PHYS_FIXED_POINT
        strh r1, [r4, #BODY_T_Y]
        strh r3, [r6, #BODY_T_Y]

.Lno_collision:
        ldmfd sp!, {pc}
@ EOR check_collisions


        @@ r4 = defender
        @@ r6 = attacker
do_damage:
        stmfd sp!, {r0-r3,lr}
        ldrb r2, [r4, #3]	@ n_balloons
	subs r2, r2, #1
        bgt 1f

	@ deal with popping
        mov r2, #0

1:	strb r2, [r4, #3]

        @@ make noise
        mov r0, #3
        mov r1, #0
        mov r2, #0x510
        bl music_play_sfx

        ldmfd sp!, {r0-r3,pc}
@ EOR do_damage

        .section .rodata
        .align
        @@ (let ((r 16)) (loop for i from 0 to 4 for theta = (+ (/ pi 2) (* i (/ pi 10) (expt -1 i))) collect (mapcar (lambda (x) (truncate (* r x))) (list (cos theta) (- (sin theta))))))
        @@ ((0 -16) (4 -15) (-9 -12) (12 -9) (-15 -4))
initial_balloon_offs:
        .byte 0, -10, 3, -9, -5, -8, 8, -5, -9, -3

@ EOF game.s
