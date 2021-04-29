all: config.prg subdirs

OBJS=main.o menu.o

config.prg: main.o menu.o
	cl65 -o config.prg main.o menu.o

main.o: main.c ../common/util.h
	cl65 --include-dir ../common -c main.c -o main.o

menu.o: menu.c ../common/util.h ../common/kawari.h
	cl65 --include-dir ../common -c menu.c -o menu.o

run:
	x64sc config.prg

subdirs:
	$(MAKE) -C rgbed
	$(MAKE) -C comped
	$(MAKE) -C timeed

clean:
	$(MAKE) -C rgbed clean
	$(MAKE) -C comped clean
	$(MAKE) -C timeed clean
	rm -f *.o config.prg
