@@@ -*- mode: asm; -*-

        .equ ARENA_DEFAULT, 0
        .equ ARENA_VTUBE, 1
        .equ ARENA_LOZENGE, 2
        .equ ARENA_GOBACKTOSPACE, 3

        .equ ARENA_T_FLAGS, 0
        .equ ARENA_T_GRAVITY, 1
        .equ ARENA_T_SPAWN_1_X, 4
        .equ ARENA_T_SPAWN_2_X, 6
        .equ ARENA_T_PALETTE_PTR, 8
        .equ ARENA_T_MIDGROUND_PTR, 12

        .equ ARENA_FLAG_BACKGROUND, 0b1
        .equ ARENA_FLAG_FOREGROUND, 0b10
        .equ ARENA_FLAG_WRAP_H, 0b0100
        .equ ARENA_FLAG_WRAP_V, 0b1000
