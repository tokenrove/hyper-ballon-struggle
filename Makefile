
CC=/cross/bin/arm-agb-elf-gcc
AS=/cross/bin/arm-agb-elf-as
OBJCOPY=/cross/bin/arm-agb-elf-objcopy

.PHONY: default clean

default: main.bin

SRCOBJS=main.o gfx.o util.o game.o font.o
DATAOBJS=palette.o dude.data.o balloon.data.o fontdat.o

main: $(SRCOBJS) $(DATAOBJS)
	$(CC) $^ -o $@

main.bin: main
	$(OBJCOPY) -Obinary $^ $@

clean:
	$(RM) *.o main
