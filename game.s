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
        .equ IMPULSE_SCALING, 10
        @@ Terminal velocity
        .equ TERMINAL_VELOCITY, 16
        @@ Collision radii squared
        .equ COLLIDE_TYPE_0_RADIUS, 15
        .equ COLLIDE_TYPE_1_RADIUS, 150

        .equ BALLOON_TILE, 0
        .equ BALLOON_POP_TILE, 1
        .equ ACTOR_TILE_OFFSET, 16

        .equ FRAME_FLY, 0
        .equ FRAME_BUMP, 1
        .equ FRAME_DIE, 2
        .equ FRAME_WIN, 3

        .equ BODY_LEN, 16
        .equ BALLOONIST_LEN, BODY_LEN+16
        .equ N_BALLOONISTS,2
        .equ MAX_BALLOONS,8

        .equ BALLOON_MASS, 0xff
        .equ BALLOON_LIFT, -5
        .equ BALLOON_DISTANCE, 12
        .equ BALLOON_POP_TIMING, 20

        .equ BLINK_TIME, 60
        .equ EXERTION_BASE_SHIFT, 1
        .equ EXERTION_MAX_SHIFT, 2
        .equ COST_PER_FLAP, 16

        .equ HORIZONTAL_TRAVEL, 2

        .equ BODY_T_X, 0
        .equ BODY_T_Y, 2
        .equ BODY_T_VX, 4
        .equ BODY_T_VY, 6
        .equ BODY_T_IMPULSE_X, 8
        .equ BODY_T_IMPULSE_Y, 10
        .equ BODY_T_COLLIDE_TYPE, 12
        .equ BODY_T_MASS, 13

        .equ BALLOON_T_POPPING_CTR, 14
        .equ ACTOR_T_FLAP_CTR, 14
        .equ ACTOR_T_TARGET_CTR, 15

        .equ ACTOR_T_ARCHETYPE_PTR, 16
        .equ ACTOR_T_EXERTION, 20
        .equ ACTOR_T_TILE_OFFSET, 22
        .equ ACTOR_T_FRAME, 24
        .equ ACTOR_T_FRAME_DELAY, 25
        .equ ACTOR_T_ANIMATION, 26
        .equ ACTOR_T_BALLOONS, 27
        .equ ACTOR_T_INVULNERABILITY, 28
        .equ ACTOR_T_IDENTITY, 29
        .equ ACTOR_T_STATE, 30
        .equ ACTOR_T_TARGET, 31

        .section .iwram

        @@ See the file HACKING.org for details of these structures
        .align 2
        .lcomm balloonists, BALLOONIST_LEN*N_BALLOONISTS
        .align 2
        .lcomm balloons, BODY_LEN*MAX_BALLOONS*N_BALLOONISTS

        .align 2
        .lcomm arena, 4

        .lcomm popped_balloon, 8

        .section .text
        .arm
        .align

        .include "gba.inc"

@@@ play_game(r0 = us, r1 = our color, r2 = them, r3 = their color, r4 = arena)
        .global play_game
play_game:
        stmfd sp!, {r5-r12,lr}

        stmfd sp!, {r0-r3}
        ldr r0, =in_game_song_data
        bl music_play_song
        ldmfd sp!, {r0-r3}

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
        add r6, r4, #BALLOONIST_LEN
        bl update_exertion
        bl apply_gravity
        bl human_input
        bl process_invulnerability

        mov r0, r4
        mov r4, r6
        mov r6, r0
        bl update_exertion
        bl apply_gravity
        bl enemy_action
        bl process_invulnerability

        @@ CHECK COLLISIONS
        ldr r4, =balloonists
        add r6, r4, #BALLOONIST_LEN
        bl check_balloonist_balloonist_collision
        bl check_balloon_collisions
        mov r0, r4
        mov r4, r6
        mov r6, r0
        bl check_balloon_collisions

        @@ UPDATE MOTION
        ldr r4, =balloonists
        bl update_balloonist_motion
        add r4, r4, #BALLOONIST_LEN
        bl update_balloonist_motion

        ldr r4, =balloonists
        bl apply_arena_wrapping
        add r4, r4, #BALLOONIST_LEN
        bl apply_arena_wrapping

        @@ check if any terminating condition occurred
        ldr r4, =balloonists
        add r6, r4, #BALLOONIST_LEN
        ldrb r2, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        cmp r2, #0
        beq .Lmatch_finished
        mov r0, r4
        mov r4, r6
        mov r6, r0
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

        bl render_popped_balloon
        bl disable_remaining_sprites

        @@ loop forever
        b .Lcoreloop

.Lmatch_finished:
        ldrb r5, [r4, #ACTOR_T_IDENTITY]
        mov r1, #FRAME_DIE<<1
        strb r1, [r4, #ACTOR_T_FRAME]
        mov r1, #FRAME_WIN<<1
        strb r1, [r6, #ACTOR_T_FRAME]

        @@ ensure we're not flashing
        mov r0, #0
        strb r1, [r4, #ACTOR_T_INVULNERABILITY]
        strb r1, [r6, #ACTOR_T_INVULNERABILITY]

        @@ play falling sound
        stmfd sp!, {r0-r3}
        mov r0, #0
        mov r1, #0x10
        mov r2, #0xd000
        bl music_play_sfx
        mov r0, #0
        mov r1, #0x130
        mov r2, #0x0800
        bl music_play_sfx
        ldmfd sp!, {r0-r3}

        @@ crude hack to show the loser plumetting
0:      stmfd sp!, {r5}
        bl gfx_wait_vblank
        mov r0, #oam_base
        ldr r4, =balloonists
        bl render_balloonist
        add r4, r4, #BALLOONIST_LEN
        bl render_balloonist

        bl render_popped_balloon
        bl disable_remaining_sprites

        ldmfd sp!, {r5}
        ldr r4, =balloonists
        cmp r5, #2
        addeq r4, r4, #BALLOONIST_LEN
        ldrsh r0, [r4, #BODY_T_Y]
        add r0, r0, #1<<4
        strh r0, [r4, #BODY_T_Y]
        cmp r0, #160<<4
        blt 0b

        mov r0, #0
        mov r1, #0
        mov r2, #0x0000
        bl music_play_sfx
        mov r0, #3
        mov r1, #0
        ldr r2, =0b010000011000
        bl music_play_sfx

        cmp r5, #1
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
        mov r1, #0b00001110
        orr r1, r1, #0x6200
        strh r1, [r0, #0xC]	@ REG_BG2

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
        mov r3, #0x0800
        orr r3, r3, #0x10
        strh r3, [r1]

        ldr r0, =balloons
        mov r1, #BODY_LEN*MAX_BALLOONS*N_BALLOONISTS
        bl dma_zero32

        ldr r0, =popped_balloon
        mov r1, #0
        str r1, [r0], #4
        str r1, [r0], #4

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
        strb r1, [r8, #ACTOR_T_STATE]
        strb r1, [r8, #ACTOR_T_TARGET]
        mov r1, #1
        strb r1, [r8, #ACTOR_T_FLAP_CTR]
        strb r1, [r8, #ACTOR_T_TARGET_CTR]

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


        @@ r0 = OAM pointer
render_popped_balloon:
        stmfd sp!, {lr}

        ldr r2, =popped_balloon
        ldrb r1, [r2, #5]       @ count
        subs r1, r1, #1
        bmi 9f
        strb r1, [r2, #5]

        ldrsh r1, [r2, #2]
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #4
        and r1, r1, #255
        orr r1, r1, #0x400
        strh r1, [r0], #2

        ldrsh r1, [r2, #0]
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #4
        mov r3, #512
        sub r3, r3, #1
        and r1, r1, r3
        strh r1, [r0], #2

        mov r1, #BALLOON_POP_TILE @ tile idx
        ldrb r3, [r2, #4]       @ color
        orr r1, r1, r3, lsl #12
        strh r1, [r0], #2

        mov r1, #0              @ rotation bits
        strh r1, [r0], #2
9:      ldmfd sp!, {pc}


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
        ldrb r1, [r4, #ACTOR_T_INVULNERABILITY]
        tst r1, #0b1
        bne 8f

        ldrsh r1, [r4, #BODY_T_Y]  @ y coordinate
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #8
        and r1, r1, #0xff
        strh r1, [r0], #2

        ldrb r3, [r4, #ACTOR_T_FRAME]   @ mode
        ldrsh r1, [r4, #BODY_T_X]  @ x coordinate
        asr r1, r1, #PHYS_FIXED_POINT
        sub r1, r1, #8
        mov r2, #0x200
        sub r2, r2, #1
        and r1, r1, r2
        orr r1, r1, #0x4000 @ size = 16x16
        and r2, r3, #1	    @ take the facing bit
        orr r1, r1, r2, lsl #12
        strh r1, [r0], #2

        bic r3, r3, #1
        lsl r3, r3, #1
        ldrh r2, [r4, #ACTOR_T_TILE_OFFSET]
        add r2, r2, r3
        orr r2, r9, lsl #12
        orr r2, r2, #0x0800 @ priority 2 (behind balloons)
        strh r2, [r0], #2

        @ rotation bits
        mov r1, #0
        strh r1, [r0], #2

8:      @@ drop sweatdrop if overexerted
        ldrh r1, [r4, #ACTOR_T_EXERTION]
        ldr r2, [r4, #ACTOR_T_ARCHETYPE_PTR]
        ldrb r2, [r2, #ARCHETYPE_T_STAMINA]
        lsl r2, #EXERTION_BASE_SHIFT
        cmp r1, r2
        blt 9f

        ldrsh r1, [r4, #BODY_T_Y]
        asr r1, #PHYS_FIXED_POINT
        sub r1, r1, #8
        and r1, r1, #0xff
        orr r1, r1, #0x400
        strh r1, [r0], #2

        ldrsh r1, [r4, #BODY_T_X]
        asr r1, #PHYS_FIXED_POINT
        and r1, r1, #0xff
        strh r1, [r0], #2

        mov r2, #2
        strh r2, [r0], #2
        mov r1, #0
        strh r1, [r0], #2

9:      ldmfd sp!, {pc}

        .pool

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
        mov r3, #1<<(IMPULSE_SCALING-2)
        strh r3, [r4, #BODY_T_IMPULSE_X]
1:      tst r1, #0x20
        bne 1f
        mov r3, #-1
        lsl r3, #IMPULSE_SCALING-2
        strh r3, [r4, #BODY_T_IMPULSE_X]
1:      tst r1, #0x40
        bne 1f
        mov r3, #-1
        lsl r3, #IMPULSE_SCALING-2
        strh r3, [r4, #BODY_T_IMPULSE_Y]
1:      tst r1, #0x80
        bne 1f
        mov r3, #2<<(IMPULSE_SCALING-2)
        strh r3, [r4, #BODY_T_IMPULSE_Y]
1:      ldmfd sp!, {pc}

.Lregular_input:
        @@ B button (flap)
        tst r2, #0b10           @ B button
        bne .Lnot_flapping
        @@ bottom two bits are right and left, which is our direction
        mvn r0, r1, lsr #4
        bl flap

.Lnot_flapping:
9:
        ldmfd sp!, {pc}


        @@ r0 = direction (lowest bits: LR)
        @@ r4 = actor
        @@ XXX maybe give us a little extra impulse on the frame after debounce?
flap:
        tst r0, #0b11
        beq 1f

        tst r0, #0b01
        ldrb r3, [r4, #ACTOR_T_FRAME]
        bicne r3, r3, #1        @ face right
        orreq r3, r3, #1        @ face left
        strb r3, [r4, #ACTOR_T_FRAME]

1:      ldr r3, [r4, #ACTOR_T_ARCHETYPE_PTR]
        ldrh r1, [r4, #ACTOR_T_EXERTION]
        ldrb r2, [r3, #ARCHETYPE_T_STAMINA]
        lsl r2, #EXERTION_BASE_SHIFT
        cmp r1, r2
        bgt 0f
        add r1, r1, #COST_PER_FLAP
        cmp r1, r2
        addge r1, r1, r2
        strh r1, [r4, #ACTOR_T_EXERTION]

        ldrb r2, [r3, #ARCHETYPE_T_STRENGTH]
        ldrsh r1, [r4, #BODY_T_IMPULSE_Y]
        sub r1, r1, r2, lsl #4
        strh r1, [r4, #BODY_T_IMPULSE_Y]

        tst r0, #0b11
        beq 0f

        tst r0, #0b01
        ldrsh r3, [r4, #BODY_T_IMPULSE_X]
        addne r3, r3, #HORIZONTAL_TRAVEL<<(IMPULSE_SCALING-2)
        subeq r3, r3, #HORIZONTAL_TRAVEL<<(IMPULSE_SCALING-2)
        strh r3, [r4, #BODY_T_IMPULSE_X]

0:
        bx lr


        @@ r4 = us
        @@ r5 = arena
        @@ r6 = them
enemy_action:
        ldrb r0, [r4, #ACTOR_T_STATE]
        ldr r1, =dispatch_table
        ldr pc, [r1, r0, lsl #2]

initial_state:
        mov r0, #ST_APPROACH_PLAYER
        strb r0, [r4, #ACTOR_T_STATE]
        bx lr

approach_player:
        stmfd sp!, {lr}
        @@ XXX needs to become a separate state variable
        ldrb r0, [r4, #ACTOR_T_FLAP_CTR]
        subs r0, r0, #1
        movne r3, #0
        bne 0f
        ldrsh r2, [r4, #BODY_T_X]
        ldrsh r3, [r6, #BODY_T_X]
        asr r2, #2
        subs r7, r2, r3, asr #2
        movlt r0, #0b01
        movgt r0, #0b10
        moveq r0, #0
        bl flap
        bl calculate_flap_equilibrium
        mov r9, r0
        ldrsh r2, [r4, #BODY_T_Y]
        ldrsh r3, [r6, #BODY_T_Y]
        subs r8, r2, r3
        @@ XXX everything here is basically bullshit, since we
        @@ actually need to find solutions to the differential equations
        @@ that describe the motion of this object to do this properly.

        @@ r7 = delta x (12.4), r8 = delta y (12.4), r9 = flap equilibrium
        @@ n = dx / htravel
        rsb r0, r7, #0
        mov r1, #HORIZONTAL_TRAVEL+3 @ XXX needs fudging
        swi #6<<16              @ slow division
        movs r7, r0, asr #4
        rsbmi r7, r7, #0       @ abs
        @@ r7 = n, number of flaps to travel dx
        bl calculate_gravity_plus_lift
        movs r1, r0
        moveq r1, #1
        mov r0, r8
        swi #6<<16
        @@ r0 = dy / (gravity+lift)
        @@ this is the number of frames in total we'd need to add/drop to travel dy
        movs r1, r7
        moveq r1, #1
        swi #6<<16
        @@ r0 = r0 / n
        @@ this is the number of extra frames on this flap, if we
        @@ expect to make n flaps in total

        @@ we add this value to the flap equilibrium to figure out our
        @@ timing.  really, we should be incorporating our character's
        @@ stamina, though.

        @@ well, we would, except that's bullshit; we take some of
        @@ that information and drastically modify our flap rate based on
        @@ it.
        @@ adds r0, r0, r9
        @@ movmi r0, r9
        asr r0, #2
        cmp r0, #0
        lsrpl r0, r9, #1
        lslmi r0, r9, #1
        and r0, r0, #0xff
0:      strb r0, [r4, #ACTOR_T_FLAP_CTR]
        ldmfd sp!, {pc}


        @@ wish we had vcnt
        @@ this is per Hacker's Delight
        @@ uses r0-r2
popcnt:
        ldr r1, =0x55555555
        and r1, r1, r0, lsr #1
        sub r0, r0, r1
        @@ There must be a way to avoid this intermediary register
        ldr r2, =0x33333333
        and r1, r2, r0, lsr #2
        and r0, r0, r2
        add r0, r0, r1
        add r0, r0, r0, lsr #4
        ldr r1, =0x0f0f0f0f
        and r0, r0, r1
        add r0, r0, r0, lsr #8
        add r0, r0, r0, lsr #16
        and r0, r0, #0x3f
        mov pc, lr


maintain_equilibrium:
        stmfd sp!, {lr}
        @@ XXX needs to become a separate state variable
        ldrb r0, [r4, #ACTOR_T_FLAP_CTR]
        subs r0, r0, #1
        movne r3, #0
        bne 0f
        mov r0, #0
        bl flap
        bl calculate_flap_equilibrium
0:      strb r0, [r4, #ACTOR_T_FLAP_CTR]
        ldmfd sp!, {pc}


        @@ r4 = balloonist
        @@ r5 = arena
        @@ XXX It occurs to me, suddenly, that if the game loop were
        @@ structured in a specific order, we would have already
        @@ calculated this value and applied it as the only impulses on
        @@ the actor.  So instead of recomputing it all the time, we
        @@ could just use ACTOR_T_IMPULSE_Y.  Maybe later.
calculate_gravity_plus_lift:
        stmfd sp!, {lr}
        ldrb r0, [r4, #ACTOR_T_BALLOONS]
        bl popcnt
        mov r1, #BALLOON_LIFT
        ldrb r2, [r5, #ARENA_T_GRAVITY]
        mla r0, r1, r0, r2
        @@ r0 = number of balloons * lift + gravity
        ldmfd sp!, {pc}


        @@ flap count to maintain current altitude:
        @@ (strength<<4) / (gravity + lift) * cost
calculate_flap_equilibrium:
        stmfd sp!, {lr}
        bl calculate_gravity_plus_lift
        mov r1, #COST_PER_FLAP
        mul r1, r0, r1
        ldr r0, [r4, #ACTOR_T_ARCHETYPE_PTR]
        ldrb r0, [r0, #ARCHETYPE_T_STRENGTH]
        lsl r0, #12
        swi #6<<16              @ slow division
        asr r0, #4
        ldmfd sp!, {pc}

        .align 2
dispatch_table:
        .equ ST_INITIAL, 0
        .equ ST_MAINTAIN_EQUILIBRIUM, 1
        .equ ST_APPROACH_PLAYER, 2
        .word initial_state, maintain_equilibrium, approach_player


update_exertion:
        ldrh r1, [r4, #ACTOR_T_EXERTION]
        ldr r2, [r4, #ACTOR_T_ARCHETYPE_PTR]
        ldrb r2, [r2, #ARCHETYPE_T_STAMINA]
        lsl r2, #EXERTION_BASE_SHIFT
        cmp r1, r2
        moveq r1, #1
        subs r1, r1, #1
        strgeh r1, [r4, #ACTOR_T_EXERTION]
        mov pc, lr


        @@ r4 = balloonist
        @@ r5 = arena
apply_gravity:
        ldrsh r1, [r4, #BODY_T_IMPULSE_Y]
        ldrsb r0, [r5, #ARENA_T_GRAVITY]
        add r1, r1, r0
        strh r1, [r4, #BODY_T_IMPULSE_Y]
        mov pc,lr

        @@ r4 = balloonist
process_invulnerability:
        ldrb r0, [r4, #ACTOR_T_INVULNERABILITY]
        subs r0, r0, #1
        movle r0, #0
        strb r0, [r4, #ACTOR_T_INVULNERABILITY]
        mov pc, lr


        @@ r4 = this balloonist
        @@ r5 = arena
update_balloonist_motion:
        stmfd sp!, {lr}

        @@ update balloons
        ldrb r9, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        ldrsh r7, [r4, #BODY_T_X]
        ldrsh r8, [r4, #BODY_T_Y]
        mov r6, r4
        ldrb r0, [r4, #ACTOR_T_IDENTITY]
        sub r0, r0, #1
        stmfd sp!, {r4}
        ldr r4, =balloons
        add r4, r4, r0, lsl #7 @ log2(BODY_LEN*MAX_BALLOONS)
0:      tst r9, #1
        beq 1f

        ldrsh r0, [r4, #BODY_T_IMPULSE_Y]
        add r0, r0, #BALLOON_LIFT
        strh r0, [r4, #BODY_T_IMPULSE_Y]
        bl update_body_motion
        @@ constrain to be within a given radius of the ballonist
        ldrsh r0, [r4, #BODY_T_X]
        ldrsh r1, [r4, #BODY_T_Y]
        sub r0, r0, r7
        sub r1, r1, r8
        mul r2, r0, r0
        mla r2, r1, r1, r2
        asr r2, #PHYS_FIXED_POINT*2

        subs r3, r2, #BALLOON_DISTANCE*BALLOON_DISTANCE
        ble 1f
        @@ bring balloons closer and apply lift to balloonist

        @@ r4 = body A
        @@ r6 = body B
        @@ r7 = distance squared (in pixels)
        @@ r8 = penetration squared (in pixels)
        stmfd sp!, {r0-r12}
        mov r7, r2
        mov r8, r3
        bl compute_contact_normal_opp
        bl resolve_contact
        ldmfd sp!, {r0-r12}

1:      add r4, r4, #BODY_LEN
        lsrs r9, r9, #1
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

        @@ we check the minkowski sum of an 8x8 tile and either an 8x8 or 16x16 sprite

        @@ collide with playfield
        @@ we check the n tiles that compose the balloonist and set
        @@ a flag for each, then decide how to respond based on those
        @@ flags and current velocity
        @@ XXX subtract 8+r3<<2 from positions here for leftmost corner
        stmfd sp!, {r1,r2,r8}
        ldr r6, [r5, #ARENA_T_MIDGROUND_PTR]
        ldrb r9, [r6], #1
        ldrb r10, [r6], #1
        @@ scale to pixels
        asr r2, #PHYS_FIXED_POINT
        asr r8, #PHYS_FIXED_POINT
        sub r2, r2, #4
        sub r8, r8, #4
        subs r2, r2, r3, lsl #2
        movmi r2, #0
        subs r8, r8, r3, lsl #2
        movmi r8, #0
        @@ scale to tiles
        lsr r2, #3
        lsr r8, #3

        mla r0, r8, r9, r2
        lsl r0, r0, #1

        @@ replace r10 with maximum offset of the map
        mul r2, r9, r10
        mov r10, r2, lsl #1
        @@ note that we should also be testing against the horizonal
        @@ boundaries, possibly wrapping them.

        @@ walk the tiles in a boustrophedonic fashion
        @@ or'ing together the cases til you've reduced it to UDLR
        .equ PFCD_TOP, 1
        .equ PFCD_BOTTOM, 0b10
        .equ PFCD_LEFT, 0b100
        .equ PFCD_RIGHT, 0b1000

        mov r4, #0
        @@ r0 = upper-left-most tile offset
        @@ top tiles: r0, r0+1, r0+2 (if r3 = 1)
        ldrh r1, [r6, r0]
        tst r1, #0xff
        orrne r4, #PFCD_LEFT
        add r0, r0, #2
        ldrh r2, [r6, r0]
        orr r1, r1, r2
        cmp r3, #1
        bne 1f
        add r0, r0, #2
        ldrh r2, [r6, r0]
        orr r1, r1, r2
1:      tst r1, #0xff
        orrne r4, #PFCD_TOP
        tst r2, #0xff
        orrne r4, #PFCD_RIGHT

        @@ middle tiles, walking backwards
        add r0, r0, r9, lsl #1
        cmp r0, r10
        bge 2f                  @ consider subtracting (to wrap) instead of skipping
        ldrh r1, [r6, r0]
        tst r1, #0xff
        orrne r4, #PFCD_RIGHT
        sub r0, r0, #2
        ldrh r2, [r6, r0]
        orr r1, r1, r2
        cmp r3, #1
        bne 1f
        sub r0, r0, #2
        ldrh r2, [r6, r0]
        orr r1, r1, r2
1:      tst r2, #0xff
        orrne r4, #PFCD_LEFT

        @@ bottom tiles
        add r0, r0, r9, lsl #1
        cmp r0, r10
        bge 2f
        ldrh r1, [r6, r0]
        cmp r1, #0
        orrne r4, #PFCD_LEFT
        add r0, r0, #2
        ldrh r2, [r6, r0]
        orr r1, r1, r2
        cmp r3, #1
        bne 1f
        add r0, r0, #2
        ldrh r2, [r6, r0]
        orr r1, r1, r2
1:      tst r1, #0xff
        orrne r4, #PFCD_BOTTOM
        tst r2, #0xff
        orrne r4, #PFCD_RIGHT

2:      ldmfd sp!, {r1,r2,r8}

        cmp r7, #0
        beq .Lcheck_h
        bmi .Lnegative_y
        tst r4, #PFCD_BOTTOM
        beq .Lcheck_h
        @@ we're on a floor
        sub r8, r8, r7
        mov r7, #0
        b .Lcheck_h
.Lnegative_y:
        tst r4, #PFCD_TOP
        beq .Lcheck_h
        @@ okay, we hit a roof
        sub r8, r8, r7
        mov r7, #0

.Lcheck_h:
        cmp r1, #0
        beq .Ldone_checking
        bmi .Lnegative_x
        tst r4, #PFCD_RIGHT
        beq .Ldone_checking
        sub r2, r2, r1
        mov r1, #0
        b .Ldone_checking

.Lnegative_x:
        tst r4, #PFCD_LEFT
        beq .Ldone_checking
        sub r2, r2, r1
        mov r1, #0

.Ldone_checking:

        @@ Clip against the sides of the world
        ldr r6, [r5, #ARENA_T_MIDGROUND_PTR]
        ldrb r9, [r6], #1
        ldrb r10, [r6], #1
        @@ r9,r10,r6 = width, height, map ptr
        ldrb r3, [r5, #ARENA_T_FLAGS]
.Lright_side:
        cmp r1, #0
        blt .Lleft_side
        mov r3, r9, lsl #3+PHYS_FIXED_POINT
        add r3, r3, #8
        cmp r2, r3
        blt .Ltop_side
        mov r2, r3
        mov r1, #0
        b .Ltop_side
.Lleft_side:
        cmp r2, #-8
        bgt .Ltop_side
        mov r2, #-8
        mov r1, #0
        b .Ltop_side

.Ltop_side:
        cmp r7, #0
        blt .Lbottom_side
        mov r3, r10, lsl #3+PHYS_FIXED_POINT
        add r3, r3, #8
        cmp r8, r3
        blt .Ldone_clipping
        mov r8, r3
        mov r7, #0
        b .Ldone_clipping
.Lbottom_side:
        cmp r8, #-8
        bgt .Ldone_clipping
        mov r8, #-8
        mov r7, #0

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


        @@ r4 = body
        @@ r6 = other body
        @@ Returns:
        @@   LT if collision occurred, GE otherwise
        @@   r0 has distance squared
        @@   r2 has distance expected squared
check_body_collision:
        stmfd sp!, {lr}

        ldrsh r0, [r4, #BODY_T_X]
        asr r0, #PHYS_FIXED_POINT
        ldrsh r1, [r4, #BODY_T_Y]
        asr r1, #PHYS_FIXED_POINT
        ldrsh r2, [r6, #BODY_T_X]
        ldrsh r3, [r6, #BODY_T_Y]
        sub r3, r1, r3, asr #PHYS_FIXED_POINT @ dy = ay - by
        mul r1, r3, r3                        @ dy^2
        sub r2, r0, r2, asr #PHYS_FIXED_POINT @ dx = ax - bx
        mla r0, r2, r2, r1                    @ p = dx^2 + dy^2

        ldrb r2, [r4, #BODY_T_COLLIDE_TYPE]
        ldrb r3, [r6, #BODY_T_COLLIDE_TYPE]
        @@ Minowski sum
        cmp r2, #0
        moveq r2, #COLLIDE_TYPE_0_RADIUS
        movne r2, #COLLIDE_TYPE_1_RADIUS
        cmp r3, #0
        moveq r3, #COLLIDE_TYPE_0_RADIUS
        movne r3, #COLLIDE_TYPE_1_RADIUS
        add r2, r2, r3
        cmp r0, r2
        @@ the important thing here is the cpsr_flag value
9:      ldmfd sp!, {pc}


        @@ r4 = balloonist
        @@ r5 = arena
apply_arena_wrapping:
        stmfd sp!, {r6,r9,r10,lr}
        ldrb r3, [r5, #ARENA_T_FLAGS]
        tst r3, #ARENA_FLAG_WRAP_H | ARENA_FLAG_WRAP_V
        beq 9f                  @ nothing to do

        @@ get world dimensions
        ldr r0, [r5, #ARENA_T_MIDGROUND_PTR]
        ldrb r9, [r0], #1
        ldrb r10, [r0], #1
        lsl r9, #3+PHYS_FIXED_POINT
        lsl r10, #3+PHYS_FIXED_POINT
        @@ r9,r10 = width, height
        mov r2, #0
        mov r6, #0
        tst r3, #ARENA_FLAG_WRAP_H
        beq 3f
        ldrsh r0, [r4, #BODY_T_X]
        cmp r0, #0
        movlt r2, r9
        cmp r0, r9
        movgt r2, r9
        rsbgt r2, r2, #0
        add r0, r0, r2
        strh r0, [r4, #BODY_T_X]
3:      tst r3, #ARENA_FLAG_WRAP_V
        beq 3f
        ldrsh r0, [r4, #BODY_T_Y]
        cmp r0, #0
        movlt r6, r10
        cmp r0, r10
        movgt r6, r10
        rsbgt r6, r6, #0
        add r0, r0, r6
        strh r0, [r4, #BODY_T_Y]

3:      cmp r2, #0
        bne 3f
        cmp r6, #0
        beq 9f
3:      @@ make same adjustment to balloons
        ldr r3, =balloons
        ldrb r1, [r4, #ACTOR_T_IDENTITY]
        sub r1, r1, #1
        add r3, r3, r1, lsl #7  @ log2(BODY_LEN*MAX_BALLOONS)
        sub r3, r3, #BODY_LEN
        ldrb r1, [r4, #ACTOR_T_BALLOONS]
1:      lsrs r1, #1
        add r3, r3, #BODY_LEN
        ldrsh r0, [r3, #BODY_T_X]
        addcs r0, r0, r2        @ that bit was set
        strh r0, [r3, #BODY_T_X]
        ldrsh r0, [r3, #BODY_T_Y]
        addcs r0, r0, r6        @ that bit was set
        strh r0, [r3, #BODY_T_Y]
        bne 1b                  @ more bits

9:      ldmfd sp!, {r6,r9,r10,pc}


        @@ r4 = body A
        @@ r6 = body B
        @@ r7 = distance squared (in pixels)
        @@ r8 = penetration squared (in pixels)
compute_contact_normal_opp:
        stmfd sp!, {lr}
        bl compute_contact_normal
        rsb r9, r9, #0
        rsb r10, r10, #0
        ldmfd sp!, {pc}


        @@ r4 = body A
        @@ r6 = body B
        @@ r7 = distance squared (in pixels)
        @@ r8 = penetration squared (in pixels)
compute_contact_normal:
        stmfd sp!, {lr}
        @@ XXX Ideally, we'd use the reciprocal square root here.
        @@ There are great, simple algorithms for it.  But let's get the
        @@ slow way working first.
        mov r0, r7, lsl #PHYS_FIXED_POINT*2
        swi #8<<16              @ sqrt
        mov r7, r0
        mov r0, r8, lsl #PHYS_FIXED_POINT*2
        swi #8<<16              @ sqrt
        mov r8, r0
        @@ r7 = distance (12.4), r8 = penetration (12.4)

        @@ compute normal as (p_B - p_A) * rsqrt(d^2)
        @@ IOW n_x = (B_x - A_x) / d
        ldrsh r0, [r6, #BODY_T_X] @ 12.4
        ldrsh r1, [r4, #BODY_T_X]
        sub r0, r0, r1
        lsl r0, #4              @ 12.8
        movs r1, r7             @ 12.4
        moveq r1, #1
        swi #6<<16              @ slow division
        mov r9, r0              @ 12.4
        ldrsh r0, [r6, #BODY_T_Y]
        ldrsh r1, [r4, #BODY_T_Y]
        sub r0, r0, r1
        lsl r0, #4              @ 12.8
        movs r1, r7             @ 12.8
        moveq r1, #1
        swi #6<<16 @ slow division
        mov r10, r0             @ 12.4
        @@ r9,r10 = contact normal x and y
        ldmfd sp!, {pc}

        @@ r4 = body A
        @@ r6 = body B
        @@ r7 = distance
        @@ r8 = penetration
        @@ r9 = normal x
        @@ r10 = normal y
resolve_contact:
        stmfd sp!, {r7-r12,lr}
        @@ compute total inverse mass
        ldrb r0, [r4, #BODY_T_MASS]
        ldrb r1, [r6, #BODY_T_MASS]
        add r11, r0, r1         @ 0.8

        @@ r11 = total inverse mass

        @@ compute unit movement for resolving penetration
        @@  u = (penetration / total_mass) * normal
        mov r0, r8, lsl #8      @ 12.12
        movs r1, r11            @ 0.8
        moveq r1, #1
        swi #6<<16
        mov r2, r0              @ 12.4
        @@ mul r2, r8, r11
        mul r0, r2, r9          @ 12.4 * 12.4 = 12.8
        asr r0, #4              @ 12.4
        mul r1, r2, r10         @ 12.8
        asr r1, #4              @ 12.4

        @@ move bodies to resolve penetration
        @@  p_A += u * m_A
        ldrb r3, [r4, #BODY_T_MASS]
        rsb r3, r3, #0          @ 0.8
        mul r2, r0, r3          @ 12.4 * 0.8 = 12.12
        ldrsh r12, [r4, #BODY_T_X]
        add r2, r12, r2, asr #IMPULSE_SCALING @ 12.4
        strh r2, [r4, #BODY_T_X]

        mul r2, r1, r3          @ 12.12
        ldrsh r12, [r4, #BODY_T_Y]
        add r2, r12, r2, asr #IMPULSE_SCALING @ 12.4
        strh r2, [r4, #BODY_T_Y]

        @@  p_B += u * -m_B
        ldrb r3, [r6, #BODY_T_MASS]
        mul r2, r0, r3
        ldrsh r12, [r6, #BODY_T_X]
        add r2, r12, r2, asr #IMPULSE_SCALING
        strh r2, [r6, #BODY_T_X]

        mul r2, r1, r3
        ldrsh r12, [r6, #BODY_T_Y]
        add r2, r12, r2, asr #IMPULSE_SCALING
        strh r2, [r6, #BODY_T_Y]

        @@ compute unit movement for resolving collision
        @@ separating_velocity = sum ((v_A - v_B) * normal)
        ldrsh r0, [r4, #BODY_T_VX]
        ldrsh r1, [r6, #BODY_T_VX]
        sub r0, r0, r1
        mul r0, r9, r0          @ 12.4 * 12.4 = 12.8
        ldrsh r1, [r4, #BODY_T_VY]
        ldrsh r2, [r6, #BODY_T_VY]
        sub r1, r1, r2
        mul r1, r10, r1         @ 12.8
        adds r2, r0, r1         @ 12.8
        bge 9f

        @@  u = (separating_velocity / total_mass) * normal
        mov r0, r2, lsl #4      @ 12.12
        movs r1, r11            @ 0.8
        moveq r1, #1
        swi #6<<16              @ slow division
        mul r1, r0, r9          @ 12.4 * 12.4 = 12.8
        mul r2, r0, r10         @ 12.8

        @@ apply impulse to resolve collision
        ldrsh r3, [r4, #BODY_T_IMPULSE_X]
        sub r3, r3, r1, asr #PHYS_FIXED_POINT
        strh r3, [r4, #BODY_T_IMPULSE_X]
        ldrsh r3, [r4, #BODY_T_IMPULSE_Y]
        sub r3, r3, r2, asr #PHYS_FIXED_POINT
        strh r3, [r4, #BODY_T_IMPULSE_Y]

        ldrsh r3, [r6, #BODY_T_IMPULSE_X]
        add r3, r3, r1, asr #PHYS_FIXED_POINT
        strh r3, [r6, #BODY_T_IMPULSE_X]
        ldrsh r3, [r6, #BODY_T_IMPULSE_Y]
        add r3, r3, r2, asr #PHYS_FIXED_POINT
        strh r3, [r6, #BODY_T_IMPULSE_Y]

9:      ldmfd sp!, {r7-r12,pc}


        @@ r4 = balloonist
        @@ r6 = other balloonist
check_balloonist_balloonist_collision:
        stmfd sp!, {lr}

        bl check_body_collision
        mov r1, #FRAME_FLY
        bge .Lno_collision

        @@ collision response
        stmfd sp!, {r0-r12}
        mov r7, r0
        mov r8, r2

        bl compute_contact_normal
        bl resolve_contact
        ldmfd sp!, {r0-r12}

        @@ make bump noise
        mov r0, #3
        mov r1, #0
        mov r2, #0x540
        bl music_play_sfx

        mov r1, #FRAME_BUMP
.Lno_collision:
        ldrb r0, [r4, #ACTOR_T_FRAME]
        and r0, r0, #1
        orr r0, r0, r1, lsl #1
        strb r0, [r4, #ACTOR_T_FRAME]
        ldrb r0, [r6, #ACTOR_T_FRAME]
        and r0, r0, #1
        orr r0, r0, r1, lsl #1
        strb r0, [r6, #ACTOR_T_FRAME]
        ldmfd sp!, {pc}


        @@ r4 = balloonist
        @@ r6 = other balloonist
check_balloon_collisions:
        stmfd sp!, {r4,r5,r7,r9-r12,lr}
        ldrb r2, [r4, #ACTOR_T_IDENTITY]
        ldrb r9, [r4, #ACTOR_T_INVULNERABILITY]
        ldrb r5, [r4, #ACTOR_T_BALLOONS]   @ number of balloons
        mov r7, r4
        ldr r4, =balloons
        sub r2, r2, #1
        add r4, r4, r2, lsl #7 @ log2(BODY_LEN*MAX_BALLOONS)

        @@ next set bit
0:      cmp r5, #0
        beq .Lno_more_balloons
        tst r5, #1
        lsreq r5, r5, #1
        addeq r4, r4, #BODY_LEN
        beq 0b

        @@ skip balloon/actor check if our owner is invulnerable
        cmp r9, #0
        bne 1f
        @@ check balloons against opponent
        bl check_body_collision
        blt .Ldo_damage

1:      @@ check balloons against each-other
        stmfd sp!, {r5,r6}
        mov r6, r4
2:      lsrs r5, r5, #1
        beq 3f
        add r6, r6, #BODY_LEN
        tst r5, #1
        beq 2b

        bl check_body_collision
        bge 2b
        stmfd sp!, {r0-r12}
        mov r7, r0
        mov r8, r2
        bl compute_contact_normal
        bl resolve_contact
        ldmfd sp!, {r0-r12}
        b 2b

3:      ldmfd sp!, {r5,r6}

        add r4, r4, #BODY_LEN
        lsrs r5, r5, #1
        bne 0b

.Lno_more_balloons:
        b 9f

        @@ a balloon got popped; we don't care about the other
        @@ balloons right now.
.Ldo_damage:
        @@ XXX should set popping counter for balloon, but we have
        @@ entered the land of grotesque hacks now.
        ldr r0, =popped_balloon
        ldrsh r1, [r4, #BODY_T_X]
        strh r1, [r0]
        ldrsh r1, [r4, #BODY_T_Y]
        strh r1, [r0, #2]
        ldrb r1, [r7, #ACTOR_T_IDENTITY]
        strb r1, [r0, #4]
        mov r1, #BALLOON_POP_TIMING
        strb r1, [r0, #5]

        ldr r0, =balloons
        sub r0, r4, r0
        lsr r0, r0, #4                   @ log2(BODY_LEN)
        ldrb r1, [r7, #ACTOR_T_IDENTITY]
        sub r1, r1, #1
        sub r0, r0, r1, lsl #3           @ log2(MAX_BALLOONS)
        ldrb r5, [r7, #ACTOR_T_BALLOONS]   @ number of balloons
        mov r1, #1
        lsl r0, r1, r0
        bic r5, r0
        strb r5, [r7, #ACTOR_T_BALLOONS]   @ number of balloons
        mov r0, #BLINK_TIME
        strb r0, [r7, #ACTOR_T_INVULNERABILITY]

        @@ make pop! noise
        mov r0, #5
        mov r1, #0
        mov r2, #0x1000
        orr r2, r2, #0x20
        bl music_play_sfx
        mov r0, #4
        mov r1, #0
        mov r2, #0x1000
        orr r2, r2, #0x20
        bl music_play_sfx

9:      ldmfd sp!, {r4,r5,r7,r9-r12,pc}


        .section .rodata
        .align
        @@ (let ((r 16)) (loop for i from 0 to 4 for theta = (+ (/ pi 2) (* i (/ pi 10) (expt -1 i))) collect (mapcar (lambda (x) (truncate (* r x))) (list (cos theta) (- (sin theta))))))
        @@ ((0 -16) (4 -15) (-9 -12) (12 -9) (-15 -4))
initial_balloon_offs:
        .byte 0, -10, 3, -9, -5, -8, 8, -5, -9, -3

@ EOF game.s
