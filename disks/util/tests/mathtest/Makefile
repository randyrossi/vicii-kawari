all: mathtest.prg

OBJS=../../common/main.o menu.o ../../common/util.o ../../common/data.o \
     ../../common/flash.o \
     ../../common/init.o \
     test_umult.o \
     test_smult.o \
     test_udiv.o \
     test_sdiv.o

mathtest.prg: $(OBJS)
	cl65 -o mathtest.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -o $@ -c $<

clean:
	rm -f *.o mathtest.prg
