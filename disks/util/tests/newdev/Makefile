all: newpal.prg newntsc.prg

OBJS=main.o ../../common/data.o ../../common/util.o ../../common/init.o \
     ../../common/flash.o \
     ../regtest/test_auto_inc_vmem_a.o \
     ../regtest/test_auto_inc_vmem_b.o \
     ../regtest/test_auto_dec_vmem_a.o \
     ../regtest/test_auto_dec_vmem_b.o \
     ../regtest/test_noop_vmem.o \
     ../regtest/test_vmem.o \
     ../regtest/test_vmem_idx.o \
     ../regtest/test_copy.o \
     ../regtest/test_fill.o \
     ../regtest/test_dma.o \
     ../mathtest/test_umult.o \
     ../mathtest/test_smult.o \
     ../mathtest/test_udiv.o \
     ../mathtest/test_sdiv.o

newpal.prg: ${OBJS} menu_pal.o
	cl65 -o newpal.prg menu_pal.o ${OBJS}

newntsc.prg: ${OBJS} menu_ntsc.o
	cl65 -o newntsc.prg menu_ntsc.o ${OBJS}

menu_pal.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -DSTANDARD=1 -c menu.c -o menu_pal.o
	mv menu.o menu_pal.o

menu_ntsc.o: menu.c ../../include/util.h ../../include/kawari.h
	cl65 --include-dir ../../include -DSTANDARD=0 -c menu.c -o menu_ntsc.o
	mv menu.o menu_ntsc.o

%.o: %.c
	cl65 --include-dir ../../include -c $*.c -o $*.o
	
clean:
	rm -f *.o newpal.prg newntsc.prg
