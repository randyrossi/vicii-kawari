all: sprite5.prg sprite6.prg regs.prg

%.prg: %.basic
	petcat -w2 -o $@ -- $<

clean:
	rm -f *.prg
