These are some useful programs to test the verilog.

linecrunch.prg

	This changes $d011 to perform the line crunch trick.
	SYS 32768
	Then initiate the sync at any time.  Inspect visually the output matches after each frame.

xscroll.prg

	This alters xscroll back and forth to create a saw tooth pattern on text.
	SYS 32768
	Sync is initiated automatically.  Inspect visually the output matches after each frame.

yscroll.prg

	This alters $d011 at a fixed interval.
	SYS 32768
	Sync is initiated automatically.  Inspect visually the output matches after each frame.

removevert.prg

	This tricks the VIC into never drawing the top and bottom borders.
	$3fff is set to 16 to show a stripe pattern which is read during idle cycles.
	SYS 32768
	Then initiate the sync at any time.  Inspect visually the output matches after each frame.

irq.prg

	A simple program to demonstrate IRQ handling
	SYS 32768
	Then initiate the sync at any time.  Inspect visually the output matches after each frame.
