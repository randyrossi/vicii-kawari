all: irq.prg scroll.prg linecrunch.prg removevert.prg

%.prg: %.asm
	acme --cpu 6510 $<

clean:
	rm -f *.prg
