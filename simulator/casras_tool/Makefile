all: wave

wave: wave.c
	gcc -o wave wave.c

logic17_ntsc: wave
	./wave -v 17 -s ntsc > session17.vcd
	gtkwave session17.vcd --script session.tcl

logic17_pal: wave
	./wave -v 17 -s pal > session17.vcd
	gtkwave session17.vcd --script session.tcl

logic18_ntsc: wave
	./wave -v 18 -s ntsc > session18.vcd
	gtkwave session18.vcd --script session.tcl

logic18_pal: wave
	./wave -v 18 -s pal > session18.vcd
	gtkwave session18.vcd --script session.tcl

clean:
	rm -f *.o wave session.vcd
