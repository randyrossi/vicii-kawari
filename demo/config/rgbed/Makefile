all: rgbed.prg

OBJS=main.o menu.o

rgbed.prg: main.o menu.o ../util.o
	cl65 -o rgbed.prg main.o menu.o ../util.o

main.o: main.c ../../common/util.h
	cl65 --include-dir ../../common -c main.c -o main.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

run:
	x64sc rgbed.prg

clean:
	rm -f *.o rgbed.prg
