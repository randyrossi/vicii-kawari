all: config.prg subdirs

OBJS=main.o menu.o util.o

config.prg: main.o menu.o util.o init.o
	cl65 -o config.prg main.o menu.o util.o init.o

main.o: main.c ../common/util.h
	cl65 --include-dir ../common -c main.c -o main.o

util.o: util.c ../common/util.h
	cl65 --include-dir ../common -c util.c -o util.o

init.o: init.c ../common/init.h
	cl65 --include-dir ../common -c init.c -o init.o

menu.o: menu.c ../common/util.h ../common/kawari.h
	cl65 --include-dir ../common -c menu.c -o menu.o

run:
	x64sc config.prg

subdirs:
	$(MAKE) -C rgbed
	$(MAKE) -C comped
	$(MAKE) -C timeed
	$(MAKE) -C flash
	$(MAKE) -C quick

clean:
	$(MAKE) -C rgbed clean
	$(MAKE) -C comped clean
	$(MAKE) -C timeed clean
	$(MAKE) -C flash clean
	$(MAKE) -C quick clean
	rm -f *.o config.prg
