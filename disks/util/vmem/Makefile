all: vmem-49152.prg

%.prg: %.asm
	acme --cpu 6510 $<

clean:
	rm -f *.prg
