set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
set pickedsigs [list]

lappend pickedsigs "TOP.clk_phi"
lappend pickedsigs "TOP.clk_dot"
lappend pickedsigs "top.vic_inst.cycle_num"
lappend pickedsigs "top.vic_inst.cycle_type"
lappend pickedsigs "top.vic_inst.raster_line"
lappend pickedsigs "top.vic_inst.xpos"
lappend pickedsigs "TOP.dbi"
lappend pickedsigs "TOP.adi"
lappend pickedsigs "TOP.ce"
lappend pickedsigs "TOP.rw"
lappend pickedsigs "TOP.vicii.ecm"
lappend pickedsigs "TOP.vicii.bmm"
lappend pickedsigs "TOP.vicii.mcm"
lappend pickedsigs "TOP.vicii.loadPixels"
lappend pickedsigs "TOP.vicii.pixel_color"
lappend pickedsigs "TOP.aec"
lappend pickedsigs "TOP.ba"
lappend pickedsigs "TOP.vicii.vic_addr"
lappend pickedsigs "vicii.vic_pixel_sequencer.pixel_color1"
lappend pickedsigs "vicii.vic_pixel_sequencer.pixel_color2"
lappend pickedsigs "vicii.pixel_color3"
lappend pickedsigs "TOP.ras"
lappend pickedsigs "top.vic_inst.mux"
lappend pickedsigs "TOP.cas"
lappend pickedsigs "top.vic_inst.ado"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
