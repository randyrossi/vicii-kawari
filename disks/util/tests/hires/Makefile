all: hires.prg

OBJS=main.o \
     menu.o \
     ../../common/util.o \
     ../../common/hires.o \
     test_160x200x16.o \
     test_320x200x16.o \
     test_640x200x4.o \
     test_640x200x16.o \
     tests.o

hires.prg: $(OBJS)
	cl65 -o hires.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -o $@ -c $<

clean:
	rm -f *.o hires.prg
