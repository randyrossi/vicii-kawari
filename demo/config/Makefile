all: config.prg

OBJS=main.o menu.o

config.prg: main.o menu.o
	cl65 -o config.prg main.o menu.o

main.o: main.c util.h
	cl65 --include-dir ~/src/c65/include -c main.c -o main.o

menu.o: menu.c util.h kawari.h
	cl65 --include-dir ~/src/c65/include -c menu.c -o menu.o

run:
	x64sc main

clean:
	rm -f *.o config.prg
