
LD=/usr/arm-linux-gnueabi/bin/ld
AS=/usr/arm-linux-gnueabi/bin/as
CC=/usr/bin/arm-linux-gnueabi-gcc-4.9
CFLAGS=-mthumb-interwork -mcpu=arm7tdmi
ASFLAGS=-mthumb-interwork -mcpu=arm7tdmi
OBJCOPY=/usr/arm-linux-gnueabi/bin/objcopy

.PHONY: default clean

default: mortimer roz main.bin

SRCOBJS=start.o main.o dma.o gfx.o util.o game.o font.o
DATAOBJS=palette.o dude.o fontdat.o

%.raw: %.pcx
	./roz $^

dude.s: data/dude10r.raw data/ball2.raw

main: $(SRCOBJS) $(DATAOBJS)
	$(LD) -T linkscript $^ -o $@

main.bin: main
	$(OBJCOPY) -Obinary $^ $@

%.cmx: %.ml
	ocamlopt -c -I tools $<

%.cmi: %.mli
	ocamlopt -c -I tools $<

tools/pcx.cmx: tools/pcx.cmi
tools/tile.cmx: tools/tile.cmi

mortimer: tools/pcx.cmx tools/tile.cmx tools/mortimer.ml
	ocamlopt -I tools $^ -o mortimer

roz: tools/pcx.cmx tools/tile.cmx tools/roz.ml
	ocamlopt -I tools $^ -o roz

clean:
	$(RM) *.o main main.bin
