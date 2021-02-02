all: sprite5.prg sprite6.prg sprite7.prg regs.prg sprite8.prg sprite9.prg \
     extramem1.prg extramem2.prg extramem3.prg config.prg palette.prg

%.prg: %.basic
	petcat -w2 -o $@ -- $<

config.basic: config.src
	java BasicGen config.src > config.basic

palette.basic: palette.src
	java BasicGen palette.src > palette.basic

clean:
	rm -f *.prg
