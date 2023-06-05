all: dma.prg

OBJS=../../common/main.o menu.o ../../common/data.o ../../common/util.o \
     ../../common/flash.o \
     ../../common/init.o \
     test_dma.o \
     test_dma_irq.o \
     tests.o

dma.prg: $(OBJS)
	cl65 -o dma.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

clean:
	rm -f *.o *.prg
