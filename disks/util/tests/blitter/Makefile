all: blitter.prg

OBJS=main.o menu.o ../../common/util.o ../../common/data.o \
     ../../common/flash.o \
     ../../common/init.o \
     ../../common/hires.o \
     test_160x200x16_blit.o \
     test_320x200x16_blit.o \
     test_640x200x4_blit.o \
     test_blit_irq.o \
     test_blit_op.o \
     tests.o

blitter.prg: $(OBJS)
	cl65 -o blitter.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h tests.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c tests.h macros.h
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -o $@ -c $<

clean:
	rm -f *.o blitter.prg
