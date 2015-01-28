
	@ Instrument banks
	.global instr_standard_sqr0
instr_standard_sqr0:
.word 0x35000008,0xff3f005f

	.global instr_standard_sqr1
instr_standard_sqr1:
.short 0xf040, 0xdfbf, 0xd500, 0xf140
.align

        .global instr_standard_noise
instr_standard_noise:
.word 0
@ 1: snare 1 (C0)
.word 0x9060A100
@ 2: hihat 1 (C#0)
.word 0x90006100
@ 3: horriblekick 1 (D0)
.word 0xC04771F4
@ 4: revsweep 1 (D#0)
.word 0xC0143910
@ 5,6,7,8,9,10,11,12,13,14,15: reserved
.word 0,0,0,0,0,0,0,0,0,0,0
@ 16: defender explosion (D#1)
.word 0x80988600
@ 17: arcade hit low (E1)
.word 0x8073A400
@ 18: arcade hit medium (F1)
.word 0x80729200
@ 19: arcade hit high (F#1)
.word 0x8071C200
@ 20: Sam attack (G1)
.word 0xC0106920
@ 21: Sam hit (G#1)
.word 0x8046B100
@ 22: Guard hit (A1)
.word 0x8047B200
@ 23: pistol (A#1)
.word 0xC05AC9F4
@ 24: submachine gun (B1)
.word 0xC04EC9F6
@ 25: Quinn's slide (C2)
.word 0xC021871D
@ 26: Landing on ground (C#2)
.word 0xC08159F7

        .global instr_standard_samples
instr_standard_samples:
@ 0: pizzicato strings quarter note
.hword inst_pop_len
.hword 11025
.word inst_pop

inst_pop: .incbin "samples/pop.sb"
        .align
        .equ inst_pop_len, .-inst_pop

@ EOF instruments.s
