set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
set pickedsigs [list]

lappend pickedsigs "TOP.clk_phi"
lappend pickedsigs "TOP.clk_dot"
lappend pickedsigs "TOP.vicii.vic_raster.cycle_num"
lappend pickedsigs "TOP.vicii.vic_raster.raster_line"
lappend pickedsigs "TOP.vicii.xpos"
lappend pickedsigs "TOP.vicii.dbi"
lappend pickedsigs "TOP.vicii.loadPixels"
lappend pickedsigs "TOP.vicii.pixel_color"
lappend pickedsigs "TOP.vicii.aec"
lappend pickedsigs "TOP.ba"
lappend pickedsigs "TOP.ce"
lappend pickedsigs "TOP.rw"
lappend pickedsigs "TOP.aec"
lappend pickedsigs "TOP.vicii.cycle_type"
lappend pickedsigs "TOP.vicii.vic_addr"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
