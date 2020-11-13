all: sprite5.prg sprite6.prg sprite7.prg regs.prg sprite8.prg sprite9.prg

%.prg: %.basic
	petcat -w2 -o $@ -- $<

clean:
	rm -f *.prg
