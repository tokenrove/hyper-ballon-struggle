@@@ Simple xorshift32 PRNG, based on Marsaglia's Xorshift RNGs paper
@@@ <http://core.ac.uk/download/pdf/6250138.pdf>.  We could easily go to
@@@ xorshift* if this generator's results don't feel good.

        .section .ewram
        .align 2
        .lcomm y, 4

        .section .text
        .global random_init
random_init:
        @@ static uint32_t y = 2463534242UL;
        ldr r0, =#2463534242
        ldr r1, =y
        str r0, [r1]
        bx lr

        .global random_word
random_word:
        @@ y^=(y<<13); y^=(y>>17); return (y^=(y<<15));
        ldr r1, =y
        ldr r0, [r1]
        eor r0, r0, r0, lsl #13
        eor r0, r0, r0, lsr #17
        eor r0, r0, r0, lsl #15
        str r0, [r1]
        bx lr
