set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
set pickedsigs [list]

lappend pickedsigs "TOP.clk_phi"
lappend pickedsigs "TOP.clk_dot"
lappend pickedsigs "TOP.vicii.cycle_num"
lappend pickedsigs "TOP.vicii.raster_line"
lappend pickedsigs "TOP.vicii.xpos"
lappend pickedsigs "TOP.vicii.dbi"
lappend pickedsigs "TOP.vicii.loadPixels"
lappend pickedsigs "TOP.vicii.shifting_pixels"
lappend pickedsigs "TOP.vicii.pixelColor"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
