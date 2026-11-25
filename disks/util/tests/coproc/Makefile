all: coproc.prg

OBJS=main.o menu.o \
     ../../common/util.o ../../common/data.o \
     ../../common/flash.o \
     ../../common/init.o \
     ../../common/hires.o \
     ../../common/ops.o \
     tests.o

coproc.prg: cpu2.h $(OBJS)
	cl65 -o coproc.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h cpu2.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -o $@ -c $<

cpu2.o: cpu2.a
	acme -o cpu2.o cpu2.a

cpu2.h: cpu2.o
	xxd -i cpu2.o > cpu2.h

clean:
	rm -f *.o coproc.prg
