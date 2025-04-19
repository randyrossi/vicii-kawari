# Makes a VIC-II Kawari flash update disk set
# from a bitstream.
#
# Expects: kawari_$(TYPE)_$(VARIANT)_$(VERSION).bit
# Requires: dasm and cc65

# NOTE: The spartan6 builds separates golden from multiboot
# into separate files but the efinix build makes one file and
# we extract either the first or second bitstream from that one.
# So in either case (golden vs multiboot) name the multi image
# bin file to whatever name this tool expects (or have the
# same file names as golden and multiboot)

# Stuff to potentially edit
#NAME=kawari
#VERSION=1.8
#FPGA=efinix_t20
#    One of: spartan6_x9 | spartan6_x16 | efinix_t8 | efinix_t20
#START_ADDRESS
#    For Spartan6 LD: 0=golden, 512000=multiboot
#    For Efinix   LH: 0=golden, 659456=multiboot
#    For Efinix   LG: 0=golden, 679936=multiboot
#START_ADDRESS=659456
#IMAGE_SIZE=659456
#TYPE
#    One of:  multiboot | golden
#TYPE=multiboot
#VARIANT 
#     Variant name matching registers 0x90-0x9F
#     One of : SIM | MAIN | MAINLD | MAINLG | MAINLH | MAINLJ
#VARIANT=MAINLH
#PAGE_SIZE
#     Must be 4096 for efinix
#     Must be 16k for spartan
#PAGE_SIZE=4096

# Do not edit below this line
all: checkfile subdirs ask d64 d81 teensy tools

ask:
	@echo -------------------------------------------
	@echo MAKING: ${VARIANT}
	@echo FROM: ${SOURCE_IMG}
	@echo -------------------------------------------
	@echo -n Press enter to continue, Cntrl-C to abort:
	#@read dummy

subdirs:
	$(MAKE) -C third_party

SOURCE_IMG=kawari_$(TYPE)_$(VARIANT)_$(VERSION).bit

checkfile:
	@if [ ! -f $(SOURCE_IMG) ]; \
	then echo "Missing $(SOURCE_IMG)"; exit 1; \
	fi

# Max 29 files to cover size of SpX16
FILENUMS=000 001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017 018 019 \
         020 021 022 023 024 025 026 027 028 029 030 031 032 033 034 035 036 037 038 039 \
         040 041 042 043 044 045 046 047 048 049 050 051 052 053 054 055 056 057 058 059 \
         060 061 062 063 064 065 066 067 068 069 070 071 072 073 074 075 076 077 078 079 \
         080 081 082 083 084 085 086 087 088 089 090 091 092 093 094 095 096 097 098 099 \
         100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 \
         120 121 122 123 124 125 126 127 128 129 130 131 132 133 134 135 136 137 138 139 \
         140 141 142 143 144 145 146 147 148 149 150 151 152 153 154 155 156 157 158 159 \
         160 161 162 163 164 165 166 167 168 169 170 171 172 173 174 175 176 177 178 179

COMMON_OBJS=main.o ../common/util.o ../common/flash.o crt0.o loader_loader.o \
            copy.o compare.o checksum_asm.o

UNIVERSAL_OBJS=$(COMMON_OBJS) menu.o

TEENSY_OBJS=$(COMMON_OBJS) teensy_menu.o teensy.o

EXPERT_OBJS=main.o expert.o ../common/util.o ../common/flash.o copy.o

# Make an info file for flash program to read
# $a004 dest
info_file: load_bytes
	./load_bytes 4 160 > info
	# name, max 31 chars, petscii
	echo $(NAME) >> info
	# version string
	echo $(VERSION) >> info
	# size of image
	wc -c stripped.bit | sed 's/ .*//' >> info
	# start address of image
	echo $(START_ADDRESS) >> info
	# variant match
	echo $(VARIANT) >> info
	# page size
	echo $(PAGE_SIZE) >> info
	# num disks
	echo $(NUM_DISKS) >> info

# Util to output 2 load bytes
load_bytes: load_bytes.c
	gcc load_bytes.c -o load_bytes

# Utility to compute checksum bytes
checksum: checksum.c
	gcc checksum.c -o checksum

flash.prg: ${UNIVERSAL_OBJS}
	ld65 -o flash.prg ${UNIVERSAL_OBJS} /usr/share/cc65/lib/c64.lib \
		-C /usr/share/cc65/cfg/c64.cfg

teensy_flash.prg: ${TEENSY_OBJS}
	ld65 -o teensy_flash.prg ${TEENSY_OBJS} /usr/share/cc65/lib/c64.lib \
		-C /usr/share/cc65/cfg/c64.cfg

expert.prg: ${EXPERT_OBJS}
	cl65 -o expert.prg ${EXPERT_OBJS}

main.o: main.c ../include/util.h
	cl65 --include-dir ../include -c main.c -o main.o

crt0.o: crt0.s
	ca65 crt0.s -o crt0.o

menu.o: menu.c ../include/util.h ../include/kawari.h
	cl65 --include-dir ../include -c menu.c -o menu.o

# Workaround for bug in cl65 that does not use -o properly to name
# the output.  Have to copy menu.c to teensy_menu.c
teensy_menu.o: menu.c ../include/util.h ../include/kawari.h
	cp menu.c teensy_menu.c
	cl65 --include-dir ../include -DTEENSY -c teensy_menu.c -o teensy_menu.o
	rm -f teensy_menu.c

expert.o: expert.c ../include/util.h ../include/kawari.h ../include/flash.h
	cl65 --include-dir ../include -c expert.c -o expert.o

loader_loader.o: loader_loader.s
	ca65 loader_loader.s -o loader_loader.o

copy.o: copy.s
	ca65 copy.s -o copy.o

compare.o: compare.s
	ca65 compare.s -o compare.o

teensy.o: teensy.s
	ca65 teensy.s -o teensy.o

checksum_asm.o: checksum_asm.s
	ca65 checksum_asm.s -o checksum_asm.o

%.o: %.c
	cl65 --include-dir ../include -c $*.c -o $*.o

run:
	x64sc flash.prg

clean:
	rm -rf *.o *.prg *.d64 *.d81 tmp stripped.bit multi_hex_to_bit autoswap.lst
	$(MAKE) -C third_party clean

# For Spartan6 devices, we need to skip over the first X
# bytes for the header.  It's different depending on
# the model.
# X = 88 for x9
# X = 89 for x16
#
# For Efinix devices, we have to isolate the one image
# we want to update from the multi image.
#
# Then we split the files into chunks based on the
# page size.
#
# Then prefix each file with load bytes
# $6000 dest for every chunk
image_files: load_bytes checksum
	mkdir -p tmp
	if [ "$(FPGA)" = "spartan6_x16" ]; then \
	   dd skip=1 bs=89 if=$(SOURCE_IMG) > stripped.bit; \
	fi
	if [ "$(FPGA)" = "spartan6_x9" ]; then \
	   dd skip=1 bs=88 if=$(SOURCE_IMG) > stripped.bit; \
	fi
	if [ "$(FPGA)" = "efinix_t8" -a "$(TYPE)" = "multiboot" ]; then \
	   dd skip=1 bs=$(IMAGE_SIZE) if=$(SOURCE_IMG) > stripped.bit; \
	fi
	if [ "$(FPGA)" = "efinix_t20" -a "$(TYPE)" = "multiboot" ]; then \
	   dd skip=1 bs=$(IMAGE_SIZE) if=$(SOURCE_IMG) > stripped.bit; \
	fi
	if [ "$(FPGA)" = "efinix_t8" -a "$(TYPE)" = "golden" ]; then \
	   dd skip=0 bs=$(IMAGE_SIZE) count=1 if=$(SOURCE_IMG) > stripped.bit; \
	fi
	if [ "$(FPGA)" = "efinix_t20" -a "$(TYPE)" = "golden" ]; then \
	   dd skip=0 bs=$(IMAGE_SIZE) count=1 if=$(SOURCE_IMG) > stripped.bit; \
	fi
	split -a 3 -d -b $(PAGE_SIZE) stripped.bit tmp/img_
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
	   ./load_bytes 0 96 > tmp/img_d64_$$NUM; \
	   cat tmp/img_$$NUM >> tmp/img_d64_$$NUM; \
	   ./checksum tmp/img_$$NUM >> tmp/img_d64_$$NUM; \
	   fi \
	done

SIZE=$(shell du -b flash.prg | cut -f1)

# Need to make sure our program doesn't leave too little
# space for heap. Our load buffer is at 0x6000 and the
# progrm starts at 0x801 which leaves 22527 bytes but
# we want at least 2048 for stack space. So put an upper
# limit of 20478 for program size.
checksize:
	if [ $(SIZE) -gt 20478 ]; then \
	    echo "ERROR: flash.prg too large" ; exit 1 ; \
	fi

# Put together disk images based on what chunks
# we created. NOTE: These divisors must match
# what is hard coded in the flasher program. (8 and 34)
d64: flash.prg checksize third_party/covert/loader.prg image_files info_file
	@rm -f autoswap.lst;
	for NUM in $(DISKNUMS); do \
	   truncate -s 174848 flash$$NUM.d64; \
	   c1541 -attach flash$$NUM.d64 -format "vicii-flash$$NUM",0; \
	   echo "flash$$NUM.d64" >> autoswap.lst; \
	   if [ "$$NUM" = "1" ]; then \
	      c1541 -attach flash$$NUM.d64 -write flash.prg flash; \
	      c1541 -attach flash$$NUM.d64 -write third_party/covert/loader.prg loader; \
	      c1541 -attach flash$$NUM.d64 -write info info; \
	   fi \
	done
	if [ "$(PAGE_SIZE)" = "16384" ]; then \
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
		DN=`echo $$NUM / 8 + 1 | bc`; \
		c1541 -attach flash$$DN.d64 -write tmp/img_d64_$$NUM i$$NUM; \
	   fi \
	done \
	else \
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
		DN=`echo $$NUM / 34 + 1 | bc`; \
		c1541 -attach flash$$DN.d64 -write tmp/img_d64_$$NUM i$$NUM; \
	   fi \
	done \
	fi

d81: flash.prg checksize third_party/covert/loader.prg image_files info_file
	c1541 -format 1,flash d81 flash.d81; \
	c1541 -attach flash.d81 -write flash.prg flash; \
	c1541 -attach flash.d81 -write third_party/covert/loader.prg loader; \
	c1541 -attach flash.d81 -write info info; \
	if [ "$(PAGE_SIZE)" = "16384" ]; then \
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
		DN=`echo $$NUM / 8 + 1 | bc`; \
		c1541 -attach flash.d81 -write tmp/img_d64_$$NUM i$$NUM; \
	   fi \
	done \
	else \
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
		DN=`echo $$NUM / 34 + 1 | bc`; \
		c1541 -attach flash.d81 -write tmp/img_d64_$$NUM i$$NUM; \
	   fi \
	done \
	fi

# We rename teensy_flash.prg to be just flash.prg in the archive
teensy: teensy_flash.prg checksize third_party/covert/loader.prg image_files info_file
	rm -rf Kawari_TeensyROM__${VERSION}_${VARIANT}_$(TYPE); \
	mkdir -p Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE); \
	cp teensy_flash.prg Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE)/flash.prg; \
	cp info Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE)/info; \
	if [ "$(PAGE_SIZE)" = "16384" ]; then \
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
		DN=`echo $$NUM / 8 + 1 | bc`; \
		cp tmp/img_d64_$$NUM Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE)/i$$NUM; \
	   fi \
	done \
	else \
	for NUM in $(FILENUMS); do \
           if [ -e tmp/img_$$NUM ]; then \
		DN=`echo $$NUM / 34 + 1 | bc`; \
		cp tmp/img_d64_$$NUM Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE)/i$$NUM; \
	   fi \
	done \
	fi; \
	zip -r Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE).zip Kawari_TeensyROM_${VERSION}_${VARIANT}_$(TYPE); \
	rm -rf Kawari_TeensyROM__${VERSION}_${VARIANT}_$(TYPE)

zip: all
	zip kawari_flash_${VERSION}_${VARIANT}_${TYPE}.zip flash*.d64 flash.d81 autoswap.lst

tools:
	cc -o multi_hex_to_bit multi_hex_to_bit.c
