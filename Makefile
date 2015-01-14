
LD=/usr/arm-linux-gnueabi/bin/ld
AS=/usr/arm-linux-gnueabi/bin/as
CC=/usr/bin/arm-linux-gnueabi-gcc-4.9
CFLAGS=-mthumb-interwork -mcpu=arm7tdmi
ASFLAGS=-mthumb-interwork -mcpu=arm7tdmi
OBJCOPY=/usr/arm-linux-gnueabi/bin/objcopy

.PHONY: default clean

default: main.bin

SRCOBJS=start.o main.o dma.o gfx.o util.o game.o font.o
DATAOBJS=palette.o dude.data.o balloon.data.o fontdat.o

main: $(SRCOBJS) $(DATAOBJS)
	$(LD) -T linkscript $^ -o $@

main.bin: main
	$(OBJCOPY) -Obinary $^ $@

clean:
	$(RM) *.o main
