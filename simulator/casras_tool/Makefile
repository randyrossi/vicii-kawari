all: wave

wave: wave.c
	gcc -o wave wave.c

logic: wave
	./wave -v 17 -s ntsc > session.vcd
	gtkwave session.vcd --script session.tcl

clean:
	rm -f *.o wave session.vcd
