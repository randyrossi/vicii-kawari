# Makefile for 80 column drivers

ASM=$(HOME)/asm64

DRV=kawari.ml

all:	$(DRV)

clean:
	rm -f $(DRV)

kawari.ml:	kawari.src novaterm.src.lab
		$(ASM) kawari.src
