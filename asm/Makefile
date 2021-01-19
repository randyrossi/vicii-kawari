all: irq.prg xscroll.prg linecrunch.prg removevert.prg yscroll.prg pixel.prg mode.prg xscroll2.prg pound.prg noborder.prg hires80.prg

%.prg: %.asm
	acme --cpu 6510 $<

clean:
	rm -f *.prg
