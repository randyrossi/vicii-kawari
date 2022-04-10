all: segment1.prg segment2.prg segment3.prg segment4.prg irqload.prg disk

LIB=/usr/share/cc65/share/cc65/lib/c64.lib

OBJS=crt0.o ../../util/common/util.o ../../util/common/color.o
HDRS=../../util/include/util.h ../../util/include/kawari.h

segment1.prg: segment1.o ${OBJS}
	ld65 -o segment1.prg segment1.o ${OBJS} ${LIB} -C c64.cfg

segment2.prg: segment2.asm
	acme --cpu 6510 segment2.asm

segment3.prg: segment3.o ${OBJS}
	ld65 -o segment3.prg segment3.o ${OBJS} ${LIB} -C c64.cfg

segment4.prg: segment4.o ${OBJS}
	ld65 -o segment4.prg segment4.o ${OBJS} ${LIB} -C c64.cfg

%.o: %.c ${HDRS}
	cl65 --include-dir ../../util/include -c $*.c -o $*.o

%.o: %.s
	ca65 $*.s -o $*.o

clean:
	rm -f *.o segment*.prg irqload.prg kawari_inside.d64

irqload.prg: irqload.s
	dasm irqload.s -oirqload.prg -v3 -p3

disk:
	truncate -s 174848 kawari_inside.d64
	c1541 -attach kawari_inside.d64 -format "disk",0
	c1541 -attach kawari_inside.d64 -write irqload.prg
	c1541 -attach kawari_inside.d64 -write segment1.prg s1
	c1541 -attach kawari_inside.d64 -write segment2.prg s2
	c1541 -attach kawari_inside.d64 -write segment3.prg s3
	c1541 -attach kawari_inside.d64 -write segment4.prg s4
	c1541 -attach kawari_inside.d64 -list

