all: eepromed.prg

OBJS=../../common/main.o menu.o ../../common/data.o ../../common/util.o ../../common/init.o

eepromed.prg: ${OBJS}
	cl65 -o eepromed.prg ${OBJS}

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

menu.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

make_init_mem: make_init_mem.c ../../common/data.c ../../include/data.h
	gcc -c ../../common/data.c -o data.o
	gcc -c make_init_mem.c -o make_init_mem.o
	gcc -o make_init_mem data.o make_init_mem.o

clean:
	rm -f *.o *.prg
