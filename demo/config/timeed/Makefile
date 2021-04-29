all: timeed.prg

OBJS=main.o menu.o

timeed.prg: main.o menu.o ../util.o
	cl65 -o timeed.prg main.o menu.o ../util.o

main.o: main.c ../../common/util.h
	cl65 --include-dir ../../common -c main.c -o main.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

run:
	x64sc timeed.prg

clean:
	rm -f *.o timeed.prg
