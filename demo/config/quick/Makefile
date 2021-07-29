all: quickswitch.prg

quickswitch.prg: quickswitch.asm
	acme --cpu 6510 quickswitch.asm

clean:
	rm -f quickswitch.prg
