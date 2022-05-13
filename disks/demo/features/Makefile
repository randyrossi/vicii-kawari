all: segment1.prg segment2.prg segment3.prg segment4.prg segment7.prg \
     segmenta.prg segmentc.prg irqload.prg disk1 disk2

LIB=/usr/share/cc65_hacked/share/cc65/lib/c64.lib

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

segment7.prg: segment7.o ${OBJS}
	ld65 -o segment7.prg segment7.o ${OBJS} ${LIB} -C c64.cfg

segmenta.prg: segmenta.o ${OBJS}
	ld65 -o segmenta.prg segmenta.o ${OBJS} ${LIB} -C c64.cfg

segmentc.prg: segmentc.s
	acme --cpu 6510 segmentc.s

%.o: %.c ${HDRS}
	cl65 --include-dir ../../util/include -c $*.c -o $*.o

%.o: %.s
	ca65 $*.s -o $*.o

clean:
	rm -f *.o segment*.prg irqload.prg *.d64

irqload.prg: irqload.s
	dasm irqload.s -oirqload.prg -v3 -p3

disk1:
	truncate -s 174848 kawari_inside.d64
	c1541 -attach kawari_inside.d64 -format "disk1",0
	c1541 -attach kawari_inside.d64 -write irqload.prg
	c1541 -attach kawari_inside.d64 -write segment1.prg s1
	c1541 -attach kawari_inside.d64 -write segment2.prg s2
	c1541 -attach kawari_inside.d64 -write segment3.prg s3
	c1541 -attach kawari_inside.d64 -write segment4.prg s4
	c1541 -attach kawari_inside.d64 -write bruno_img.bin s5
	c1541 -attach kawari_inside.d64 -write bruno_col.bin s6
	c1541 -attach kawari_inside.d64 -write segment7.prg s7
	c1541 -attach kawari_inside.d64 -write horse_img.bin s8
	c1541 -attach kawari_inside.d64 -write horse_col.bin s9
	c1541 -attach kawari_inside.d64 -write segmenta.prg sa
	c1541 -attach kawari_inside.d64 -list

disk2:
	truncate -s 174848 kawari_inside_2.d64
	c1541 -attach kawari_inside_2.d64 -format "disk2",0
	c1541 -attach kawari_inside_2.d64 -write falcon.char d1
	c1541 -attach kawari_inside_2.d64 -write falcon.lut d2
	c1541 -attach kawari_inside_2.d64 -write segmentc.prg sc
	c1541 -attach kawari_inside_2.d64 -list
