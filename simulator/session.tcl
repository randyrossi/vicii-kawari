set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
set pickedsigs [list]

lappend pickedsigs "TOP.clk_phi"
lappend pickedsigs "TOP.clk_dot"
lappend pickedsigs "vicii.cycle_num"
lappend pickedsigs "vicii.cycle_type"
lappend pickedsigs "vicii.raster_line"
lappend pickedsigs "vicii.xpos"
lappend pickedsigs "vicii.dbi"
lappend pickedsigs "vicii.loadPixels"
lappend pickedsigs "vicii.pixel_color"
lappend pickedsigs "TOP.aec"
lappend pickedsigs "TOP.ba"
lappend pickedsigs "TOP.ce"
lappend pickedsigs "TOP.rw"
lappend pickedsigs "TOP.aec"
lappend pickedsigs "vicii.vic_addr"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
