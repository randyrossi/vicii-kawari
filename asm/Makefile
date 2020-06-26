all: irq.prg xscroll.prg linecrunch.prg removevert.prg yscroll.prg pixel.prg

%.prg: %.asm
	acme --cpu 6510 $<

clean:
	rm -f *.prg
