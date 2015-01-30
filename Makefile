
LD=/usr/arm-linux-gnueabi/bin/ld
AS=/usr/arm-linux-gnueabi/bin/as
CC=/usr/bin/arm-linux-gnueabi-gcc-4.9
CFLAGS=-mthumb-interwork -mcpu=arm7tdmi
ASFLAGS=-mthumb-interwork -mcpu=arm7tdmi
OBJCOPY=/usr/arm-linux-gnueabi/bin/objcopy

.PHONY: default clean

default: mortimer roz main.bin

SRCOBJS=start.o main.o dma.o gfx.o util.o interrupt.o font.o music.o random.o trig.o \
	game.o title.o select.o challenge.o victory.o gameover.o credits.o
DATAOBJS=archetype.o fontdat.o arenas.o instruments.o title-song.o in-game-song.o game-over-sting.o


%.s: %.nws
	notangle -L'.line %L%N' outline.nws $^ > $@

%.raw: %.pcx roz
	./roz $<

%.map: %.pcx mortimer
	./mortimer $<

archetype.o: data/retsyn_fly.raw data/retsyn_bump.raw data/retsyn_die.raw data/retsyn_win.raw data/monk_fly.raw data/monk_bump.raw data/monk_die.raw data/monk_win.raw data/alien_fly.raw data/alien_bump.raw data/alien_die.raw data/alien_win.raw data/octo_fly.raw data/octo_bump.raw data/octo_die.raw data/octo_win.raw data/pierce_fly.raw data/pierce_bump.raw data/pierce_die.raw data/pierce_win.raw data/greedy_fly.raw data/greedy_bump.raw data/greedy_die.raw data/greedy_win.raw data/myr_fly.raw data/myr_bump.raw data/myr_die.raw data/myr_win.raw data/randy_fly.raw data/randy_bump.raw data/randy_die.raw data/randy_win.raw data/monocle_fly.raw data/monocle_win.raw data/melville_fly.raw data/melville_bump.raw data/melville_die.raw data/melville_win.raw data/ball2.raw data/ball2e.raw

title.o: data/title.map
victory.o: data/victory.map
gameover.o: data/gameover.map
select.o: data/selector.raw

arenas.o: data/arena_default_mg.map data/arena_default_bg.map data/arena_vtube_mg.map data/arena_vtube_bg.map

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
	$(RM) *.o data/*.raw data/*.map data/*.tiles data/*.pal mortimer roz tools/*.cmx tools/*.cmi main main.bin
