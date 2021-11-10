# Do not edit below this line
all: flashtest.prg

OBJS=main.o menu.o support.o ../../common/util.o ../../common/init.o 

flashtest.prg: ${OBJS}
	ld65 -o flashtest.prg ${OBJS} /usr/share/cc65/lib/c64.lib \
		-C /usr/share/cc65/cfg/c64.cfg

main.o: main.c ../../include/util.h
	cl65 --include-dir ../../include -c main.c -o main.o

menu.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

support.o: support.s
	ca65 support.s -o support.o

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

run:
	x64sc flashtest.prg

clean:
	rm -rf *.o *.prg

