all: disk

OBJS=main.o menu.o ../util.o ../init.o

# Make an info file for flash program to read
info_file: load_bytes
	./load_bytes > info
	# version
	echo "1" >> info
	# size of image
	echo "458752" >> info
	# start address of image
	echo "1234" >> info

# Util to output 2 load bytes
load_bytes: load_bytes.c
	gcc load_bytes.c -o load_bytes

# DEL ME LATER

flash.prg: main.o menu.o ../util.o ../init.o crt0.o loader_loader.o
	#cl65 -o flash.prg main.o menu.o loader_loader.o ../util.o ../init.o
	ld65 -o flash.prg main.o menu.o crt0.o loader_loader.o \
		../util.o ../init.o /usr/share/cc65/lib/c64.lib \
		-C /usr/share/cc65/cfg/c64.cfg

main.o: main.c ../../common/util.h
	cl65 --include-dir ../../common -c main.c -o main.o

crt0.o: crt0.s
	ca65 crt0.s -o crt0.o

../init.o: ../init.c ../../common/init.h
	cl65 --include-dir ../common -c ../init.c -o ../init.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

loader.prg: loader.s
	dasm loader.s -oloader.prg -v3 -p3

loader_loader.o: loader_loader.s
	ca65 loader_loader.s -o loader_loader.o

run:
	x64sc flash.prg

clean:
	rm -f *.o *.prg *.d64

disk: info_file flash.prg loader.prg
	truncate -s 174848 flash.d64
	c1541 -attach flash.d64 -format "vicii-flash",0
	c1541 -attach flash.d64 -write flash.prg flash
	c1541 -attach flash.d64 -write info info
	c1541 -attach flash.d64 -write datafile a0
	c1541 -attach flash.d64 -write datafile a1
	c1541 -attach flash.d64 -write datafile a2
	c1541 -attach flash.d64 -write datafile a3
	c1541 -attach flash.d64 -write datafile a4
	c1541 -attach flash.d64 -write datafile a5
	c1541 -attach flash.d64 -write datafile a6
	c1541 -attach flash.d64 -write datafile a7
	c1541 -attach flash.d64 -write loader.prg loader
	c1541 -attach flash.d64 -list
	truncate -s 174848 flash2.d64
	c1541 -attach flash2.d64 -format "vicii-flash",0
	c1541 -attach flash2.d64 -write datafile b0
	c1541 -attach flash2.d64 -write datafile b1
	c1541 -attach flash2.d64 -write datafile b2
	c1541 -attach flash2.d64 -write datafile b3
	c1541 -attach flash2.d64 -write datafile b4
	c1541 -attach flash2.d64 -write datafile b5
	c1541 -attach flash2.d64 -write datafile b6
	c1541 -attach flash2.d64 -write datafile b7
	c1541 -attach flash2.d64 -list
	truncate -s 174848 flash3.d64
	c1541 -attach flash3.d64 -format "vicii-flash",0
	c1541 -attach flash3.d64 -write datafile c0
	c1541 -attach flash3.d64 -write datafile c1
	c1541 -attach flash3.d64 -write datafile c2
	c1541 -attach flash3.d64 -write datafile c3
	c1541 -attach flash3.d64 -write datafile c4
	c1541 -attach flash3.d64 -write datafile c5
	c1541 -attach flash3.d64 -write datafile c6
	c1541 -attach flash3.d64 -write datafile c7
	c1541 -attach flash3.d64 -list
	truncate -s 174848 flash4.d64
	c1541 -attach flash4.d64 -format "vicii-flash",0
	c1541 -attach flash4.d64 -write datafile d0
	c1541 -attach flash4.d64 -write datafile d1
	c1541 -attach flash4.d64 -write datafile d2
	c1541 -attach flash4.d64 -write datafile d3
	c1541 -attach flash4.d64 -list
