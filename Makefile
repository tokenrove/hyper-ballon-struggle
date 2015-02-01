
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
DATAOBJS=archetype.o fontdat.o arenas.o instruments.o title-song.o in-game-song.o game-over-sting.o select-tune.o victory-sting.o sight-for-sore-thumbs.o philip-glassy.o


%.s: %.nws
	notangle -L'.line %L%N' outline.nws $^ > $@

data/versus.raw256: data/versus.pcx roz
	./roz -millersoft -p $<

%.raw: %.pcx roz
	./roz $<

%.map: %.pcx mortimer
	./mortimer $<

archetype.o: data/harvey_fly.raw data/harvey_bump.raw data/harvey_die.raw data/harvey_win.raw data/rudolph_fly.raw data/rudolph_bump.raw data/rudolph_die.raw data/rudolph_win.raw data/alien_fly.raw data/alien_bump.raw data/alien_die.raw data/alien_win.raw data/lopez_fly.raw data/lopez_bump.raw data/lopez_die.raw data/lopez_win.raw data/pierce_fly.raw data/pierce_bump.raw data/pierce_die.raw data/pierce_win.raw data/greedy_fly.raw data/greedy_bump.raw data/greedy_die.raw data/greedy_win.raw data/myr_fly.raw data/myr_bump.raw data/myr_die.raw data/myr_win.raw data/randy_fly.raw data/randy_bump.raw data/randy_die.raw data/randy_win.raw data/monocle_fly.raw data/monocle_win.raw data/melville_fly.raw data/melville_bump.raw data/melville_die.raw data/melville_win.raw data/iceclown_fly.raw data/iceclown_bump.raw data/iceclown_die.raw data/iceclown_win.raw data/sam_fly.raw data/sam_bump.raw data/sam_die.raw data/sam_win.raw data/ball2.raw data/ball2e.raw data/sweatdrop.raw

title.o: data/title.map
victory.o: data/victory.map
gameover.o: data/gameover.map
select.o: data/selector.raw
challenge.o: data/versus.raw256

arenas.o: data/arena_default_mg.map data/arena_default_bg.map data/arena_vtube_mg.map data/arena_vtube_bg.map data/arena_lozenge_mg.map data/arena_lozenge_bg.map

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
	$(RM) *.o data/*.raw data/*.raw256 data/*.map data/*.tiles data/*.pal mortimer roz tools/*.cmx tools/*.cmi main main.bin
