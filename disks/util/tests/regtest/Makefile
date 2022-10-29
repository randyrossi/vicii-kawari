all: regtest.prg

OBJS=../../common/main.o menu.o ../../common/data.o ../../common/util.o ../../common/init.o \
     test_auto_inc_vmem_a.o \
     test_auto_inc_vmem_b.o \
     test_auto_dec_vmem_a.o \
     test_auto_dec_vmem_b.o \
     test_noop_vmem.o \
     test_vmem.o \
     test_vmem_idx.o \
     test_copy.o \
     test_fill.o \
     test_dma.o

regtest.prg: $(OBJS)
	cl65 -o regtest.prg $(OBJS)

menu.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -c menu.c -o menu.o

test_%.o: test_%.c
	cl65 --include-dir ../../include -o $@ -c $<

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o

clean:
	rm -f *.o *.prg
