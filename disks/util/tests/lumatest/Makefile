all: lumatest.prg

%.prg: %.asm
	acme --cpu 6510 $<

clean:
	rm -f *.prg

