@@@ interrupt -- hardware interrupt manager.
@@@
@@@ Originally from Convergence (rev 1.8, circa 2002/11/27), but cut
@@@ down radically for Hyper Ballon Struggle's more meager needs.

        .section .text
        .arm
        .align
        .include "gba.inc"

        .global intr_init
intr_init:
        ldr r0, =0x3007ffc
        ldr r1, =intr_handler
        str r1, [r0]

        @@ Set IE: enable VBL, nothing else for now
        mov r0, #reg_base
        ldrh r1, [r0, #REG_STAT-reg_base]!
        orr r1, r1, #0b1001
        strh r1, [r0]
        add r0, r0, #REG_IE-REG_STAT
        ldrh r1, [r0]
        orr r1, r1, #1
        strh r1, [r0]

        @@ Enable master interrupt flag
        mov r1, #1
        strh r1, [r0, #REG_IME-REG_IE]

        bx lr


        .section .iwram_code, "ax", %progbits
        .arm
        .align

@@@ intr_handler(void)
@@@   Called when an interrupt occurs.  Just acknowledges the interrupt
@@@   (if it was VBL) and moves on.
@@@
@@@ Remember, the BIOS saves r0-r3 for us.
        .local intr_handler
intr_handler:
        mov r2, #reg_base
        orr r2, r2, #REG_IE-reg_base
        ldrh r3, [r2, #2]
        strh r3, [r2, #2]       @ REG_IF
        mov r1, #0x3000000
        orr r1, r1, #0x8000
        strh r3, [r1, #-0x8]    @ BIOS mirror of REG_IF
        bx lr
