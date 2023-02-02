all: 80col-51200.prg 80col-loader.prg

%.prg: %.asm
	acme --cpu 6510 $<

clean:
	rm -f *.prg
