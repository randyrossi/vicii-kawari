all: config.prg subdirs

OBJS=../common/main.o menu.o ../common/util.o ../common/init.o

config.prg: ${OBJS}
	cl65 -o config.prg ${OBJS}

%.o: %.c
	cl65 --include-dir ../include -c $*.c -o $*.o

menu.o: menu.c ../include/util.h ../include/kawari.h
	cl65 --include-dir ../include -c menu.c -o menu.o

subdirs:
	$(MAKE) -C rgbed
	$(MAKE) -C comped
	$(MAKE) -C timeed
	$(MAKE) -C quick

clean:
	$(MAKE) -C rgbed clean
	$(MAKE) -C comped clean
	$(MAKE) -C timeed clean
	$(MAKE) -C quick clean
	rm -f *.o config.prg
