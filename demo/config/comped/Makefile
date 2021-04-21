all: comped.prg

OBJS=main.o menu.o

comped.prg: main.o menu.o
	cl65 -o comped.prg main.o menu.o

main.o: main.c ../../common/util.h
	cl65 --include-dir ../../common -c main.c -o main.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

run:
	x64sc comped.prg

clean:
	rm -f *.o comped.prg
