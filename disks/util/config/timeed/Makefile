all: timed.prg

OBJS=../../common/main.o menu.o ../../common/data.o ../../common/util.o ../../common/init.o

timed.prg: ${OBJS}
	cl65 -o timed.prg ${OBJS}

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

menu.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

clean:
	rm -f *.o *.prg
