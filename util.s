@
@ Some utility functions
@

	.section .text
	.arm
	.align

@
@ memcpy_h(dst, src, len) -- Copies len bytes from src to dst, in halfword
@   chunks.  Assumes len is a multiple of two, and that src and dst are
@   word aligned.
@
	.global memcpy_h
memcpy_h:
1:	ldrh r3,[r1],#2
	strh r3,[r0],#2
	subs r2,r2,#2
	bgt 1b
	@ Return
	bx lr
@ EOR memcpy_h

@ EOF util.s
