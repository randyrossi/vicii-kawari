all: wave

wave: wave.c
	gcc -o wave wave.c

logic17: wave
	./wave -v 17 -s ntsc > session17.vcd
	gtkwave session17.vcd --script session.tcl

logic18: wave
	./wave -v 18 -s ntsc > session18.vcd
	gtkwave session18.vcd --script session.tcl

clean:
	rm -f *.o wave session.vcd
