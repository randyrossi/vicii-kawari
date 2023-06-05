all: copyfill.prg

OBJS=../../common/main.o menu.o ../../common/data.o ../../common/util.o \
     ../../common/flash.o \
     ../../common/init.o \
     ../../common/hires.o \
     test_copy.o \
     test_copy_irq.o \
     test_fill.o \
     tests.o

copyfill.prg: $(OBJS)
	cl65 -o copyfill.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

clean:
	rm -f *.o *.prg
