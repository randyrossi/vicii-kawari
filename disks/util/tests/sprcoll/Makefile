all: sprcoll.prg

OBJS=main.o \
     menu.o \
     ../../common/util.o \
     ../../common/hires.o \
     test_text.o \
     test_bitmap.o \
     test_color.o \
     test_misc.o \
     tests.o

sprcoll.prg: $(OBJS)
	cl65 -o sprcoll.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h macros.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -o $@ -c $<

clean:
	rm -f *.o sprcoll.prg
