# Makes a Kawari flash update disk set
# Up to 4 disks and 28 files (covers Spartan6 X16
# bistream size).
# Expects: kawari_multiboot.bit with the image bitstream

FILENUMS=00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28
DISKNUMS=0 1 2 3

all: disks

OBJS=main.o menu.o ../util.o ../init.o

# Make an info file for flash program to read
info_file: load_bytes
	./load_bytes 0 144 > info
	# flash format version
	echo "1" >> info
	# name
	echo "kawari" >> info
	# version string
	echo "1.0" >> info
	# size of image
	wc -c stripped.bit | sed 's/ .*//' >> info
	# start address of image
	echo "512000" >> info

# Util to output 2 load bytes
load_bytes: load_bytes.c
	gcc load_bytes.c -o load_bytes

# DEL ME LATER

flash.prg: main.o menu.o ../util.o ../init.o crt0.o loader_loader.o copy.o
	#cl65 -o flash.prg main.o menu.o loader_loader.o ../util.o ../init.o
	ld65 -o flash.prg main.o menu.o crt0.o loader_loader.o copy.o \
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

copy.o: copy.s
	ca65 copy.s -o copy.o

run:
	x64sc flash.prg

clean:
	rm -rf *.o *.prg *.d64 img_* stripped.bit


# Skips over first 88 bytes for the header
# Then we split the files int 16k chunks
# Then prefix each file with load bytes
image_files:
	dd skip=1 bs=88 if=kawari_multiboot.bit > stripped.bit
	split -d -b 16384 stripped.bit img_
	for NUM in $(FILENUMS); do \
           if [ -e img_$$NUM ]; then \
	   ./load_bytes 0 64 > img_d64_$$NUM; \
	   cat img_$$NUM >> img_d64_$$NUM; \
	   fi \
	done


disks: flash.prg loader.prg image_files info_file
	for NUM in $(DISKNUMS); do \
	   truncate -s 174848 flash$$NUM.d64; \
	   c1541 -attach flash$$NUM.d64 -format "vicii-flash$$NUM",0; \
	   if [ "$$NUM" = "0" ]; then \
	      c1541 -attach flash$$NUM.d64 -write flash.prg flash; \
	      c1541 -attach flash$$NUM.d64 -write loader.prg loader; \
	      c1541 -attach flash$$NUM.d64 -write info info; \
	   fi \
	done
	for NUM in $(FILENUMS); do \
           if [ -e img_$$NUM ]; then \
		DN=`echo $$NUM / 8 | bc`; \
		c1541 -attach flash$$DN.d64 -write img_d64_$$NUM i$$NUM; \
	   fi \
	done	
	rm -f img_*
