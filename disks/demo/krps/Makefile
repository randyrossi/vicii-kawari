# This is all very messy. Uses a hodge podge of tools
# techniques to get this to happen.  It needs to be
# cleaned up.

all: subdirs img.bin rgb.bin hsv.bin krps.d64

subdirs:
	$(MAKE) -C jpg2krps

krps.d64: krps_rgb.prg krps_hsv.prg
	c1541 -format 1,krps d64 krps.d64
	c1541 -attach krps.d64 -write krps_rgb.prg krps-rgb
	c1541 -attach krps.d64 -write krps_hsv.prg krps-hsv
	c1541 -attach krps.d64 -write img1.bin img1
	c1541 -attach krps.d64 -write img2.bin img2
	c1541 -attach krps.d64 -write hsv.bin hsv
	c1541 -attach krps.d64 -write rgb.bin rgb

%.prg: %.asm
	acme -I ../include --cpu 6510 $<

img.bin: jpg2krps/img.bin
	split -b 16384 jpg2krps/img.bin
	echo "00" > img1.hex
	echo "00" >> img1.hex
	hexdump -v -e '/1 "%02X\n"' xaa >> img1.hex
	echo "00" > img2.hex
	echo "00" >> img2.hex
	hexdump -v -e '/1 "%02X\n"' xab >> img2.hex
	xxd -r -p img1.hex img1.bin
	xxd -r -p img2.hex img2.bin

rgb.bin: jpg2krps/rgb.bin
	echo "00" > rgb.hex
	echo "00" >> rgb.hex
	hexdump -v -e '/1 "%02X\n"' jpg2krps/rgb.bin >> rgb.hex
	xxd -r -p rgb.hex rgb.bin

hsv.bin: jpg2krps/rgb.bin
	gcc rgb2hsv.c -lm -o rgb2hsv
	./rgb2hsv jpg2krps/rgb.bin 16 12 hsv.tmp
	cp load_bytes hsv.bin
	cat hsv.tmp >> hsv.bin
	rm -f hsv.tmp

clean:
	$(MAKE) -C jpg2krps clean
	rm -f *.prg *.d64 img1.hex img1.bin img2.hex img2.bin rgb.hex rgb.bin hsv.bin xaa xab rgb2hsv multi_hex_to_bit
