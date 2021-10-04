all: eepromed.prg

OBJS=../../common/main.o menu.o ../../common/util.o ../../common/init.o

eepromed.prg: ${OBJS}
	cl65 -o eepromed.prg ${OBJS}

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

menu.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

clean:
	rm -f *.o *.prg
