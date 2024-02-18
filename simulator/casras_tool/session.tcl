set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
set pickedsigs [list]

lappend pickedsigs "TOP.clk_phi"
lappend pickedsigs "TOP.clk_cc"
lappend pickedsigs "TOP.clk_dc"
lappend pickedsigs "TOP.ras_cc_p"
lappend pickedsigs "TOP.ras_cc_n"
lappend pickedsigs "TOP.ras_dc_p"
lappend pickedsigs "TOP.ras_dc_n"
lappend pickedsigs "TOP.ras"
lappend pickedsigs "TOP.cas_cc_p"
lappend pickedsigs "TOP.cas_cc_n"
lappend pickedsigs "TOP.cas_dc_p"
lappend pickedsigs "TOP.cas_dc_n"
lappend pickedsigs "TOP.cas"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
