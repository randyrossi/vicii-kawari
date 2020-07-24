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
lappend pickedsigs "TOP.dbi"
lappend pickedsigs "TOP.adi"
lappend pickedsigs "TOP.ce"
lappend pickedsigs "TOP.rw"
lappend pickedsigs "vicii.ecm"
lappend pickedsigs "vicii.bmm"
lappend pickedsigs "vicii.mcm"
lappend pickedsigs "vicii.loadPixels"
lappend pickedsigs "vicii.pixel_color"
lappend pickedsigs "TOP.aec"
lappend pickedsigs "TOP.ba"
lappend pickedsigs "vicii.vic_addr"
lappend pickedsigs "vicii.vic_pixel_sequencer.pixel_color1"
lappend pickedsigs "vicii.vic_pixel_sequencer.pixel_color2"
lappend pickedsigs "vicii.pixel_color3"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
