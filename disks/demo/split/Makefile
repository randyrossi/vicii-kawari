all: split.prg

%.prg: %.asm
	acme -I ../include --cpu 6510 $<

clean:
	rm -f *.prg
