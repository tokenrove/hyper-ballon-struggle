
        .section .text
        .align 2

        @@ challenge(player, palette, enemy, palette)
        .global challenge
challenge:
        @@ display VERSUS screen
        bx lr
