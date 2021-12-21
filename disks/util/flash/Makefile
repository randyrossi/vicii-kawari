# Makes a VIC-II Kawari flash update disk set
# from a multiboot bitstream. Up to 4 disks and
# 28 files (covers Spartan6 X16 bistream size).
#
# Expects: kawari_multiboot_$(VERSION).bit
# Requires: dasm and cc65

# Stuff to potentially edit
FLASH_FORMAT=1
NAME=kawari
VERSION=0.8
# START_ADDRESS = 0 for golden, 512000 for multiboot
START_ADDRESS=512000
# TYPE = multiboot or golden
TYPE=multiboot
# BOARD = beta | a | b | c | d
BOARD=beta

# Do not edit below this line
all: subdirs disks

subdirs:
	$(MAKE) -C third_party

SOURCE_IMG=kawari_$(TYPE)_$(VERSION).bit

# Max 28 disks to cover size of SpX16
FILENUMS=00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28
# Max 4 disks
DISKNUMS=1 2 3 4

OBJS=main.o menu.o ../common/util.o ../common/init.o crt0.o loader_loader.o \
     copy.o compare.o

# Make an info file for flash program to read
# $9000 dest
info_file: load_bytes
	./load_bytes 0 144 > info
	# flash format version
	echo $(FLASH_FORMAT) >> info
	# name, max 31 chars, petscii
	echo $(NAME) >> info
	# version string
	echo $(VERSION) >> info
	# size of image
	wc -c stripped.bit | sed 's/ .*//' >> info
	# start address of image
	echo $(START_ADDRESS) >> info

# Util to output 2 load bytes
load_bytes: load_bytes.c
	gcc load_bytes.c -o load_bytes

flash.prg: ${OBJS}
	ld65 -o flash.prg ${OBJS} /usr/share/cc65/lib/c64.lib \
		-C /usr/share/cc65/cfg/c64.cfg

main.o: main.c ../include/util.h
	cl65 --include-dir ../include -c main.c -o main.o

crt0.o: crt0.s
	ca65 crt0.s -o crt0.o

menu.o: menu.c ../include/util.h ../include/kawari.h
	cl65 --include-dir ../include -c menu.c -o menu.o

loader_loader.o: loader_loader.s
	ca65 loader_loader.s -o loader_loader.o

copy.o: copy.s
	ca65 copy.s -o copy.o

compare.o: compare.s
	ca65 compare.s -o compare.o

%.o: %.c
	cl65 --include-dir ../include -c $*.c -o $*.o

run:
	x64sc flash.prg

clean:
	rm -rf *.o *.prg *.d64 img_* stripped.bit
	$(MAKE) -C third_party clean


# Skips over first X bytes for the header
# X = 88 for x9
# X = 89 for x16
# Then we split the files int 16k chunks
# Then prefix each file with load bytes
# $5000 dest for every chunk
image_files:
	dd skip=1 bs=89 if=$(SOURCE_IMG) > stripped.bit
	split -d -b 16384 stripped.bit img_
	for NUM in $(FILENUMS); do \
           if [ -e img_$$NUM ]; then \
	   ./load_bytes 0 80 > img_d64_$$NUM; \
	   cat img_$$NUM >> img_d64_$$NUM; \
	   fi \
	done

SIZE=$(shell du -b flash.prg | cut -f1)

checksize:
	if [ $(SIZE) -gt 16384 ]; then \
	    echo "ERROR: flash.prg too large" ; exit 1 ; \
	fi

# Put together disk images based on what chunks
# we created.
disks: flash.prg checksize third_party/covert/loader.prg image_files info_file
	for NUM in $(DISKNUMS); do \
	   truncate -s 174848 flash$$NUM.d64; \
	   c1541 -attach flash$$NUM.d64 -format "vicii-flash$$NUM",0; \
	   if [ "$$NUM" = "1" ]; then \
	      c1541 -attach flash$$NUM.d64 -write flash.prg flash; \
	      c1541 -attach flash$$NUM.d64 -write third_party/covert/loader.prg loader; \
	      c1541 -attach flash$$NUM.d64 -write info info; \
	   fi \
	done
	for NUM in $(FILENUMS); do \
           if [ -e img_$$NUM ]; then \
		DN=`echo $$NUM / 8 + 1 | bc`; \
		c1541 -attach flash$$DN.d64 -write img_d64_$$NUM i$$NUM; \
	   fi \
	done	
	rm -f img_*

zip:
	zip kawari_flash_${VERSION}_${BOARD}_${TYPE}.zip flash1.d64 flash2.d64 flash3.d64 flash4.d64
