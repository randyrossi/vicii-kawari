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
lappend pickedsigs "TOP.vicii.pixel_color"
lappend pickedsigs "TOP.vicii.aec"
lappend pickedsigs "TOP.ba"
lappend pickedsigs "TOP.vicii.cycle_type"
lappend pickedsigs "TOP.vicii.vic_addr"

lappend pickedsigs "TOP.vicii.sprite_shift"
lappend pickedsigs "TOP.vicii.sprite_pixels(0)"
lappend pickedsigs "TOP.vicii.sprite_pixels_delayed1(0)"
lappend pickedsigs "TOP.vicii.sprite_pixels_delayed2(0)"
lappend pickedsigs "TOP.vicii.m2d_irq_triggered"
lappend pickedsigs "TOP.vicii.pixels_read"
lappend pickedsigs "TOP.vicii.pixels_delayed(0)"
lappend pickedsigs "TOP.vicii.pixels_delayed(1)"
lappend pickedsigs "TOP.vicii.pixels_delayed(2)"
lappend pickedsigs "TOP.vicii.pixels_delayed(3)"
lappend pickedsigs "TOP.vicii.pixels_delayed(4)"
lappend pickedsigs "TOP.vicii.pixels_delayed(5)"
lappend pickedsigs "TOP.vicii.pixels_delayed(6)"
lappend pickedsigs "TOP.vicii.pixels_delayed(7)"
lappend pickedsigs "TOP.vicii.pixels_delayed(8)"
lappend pickedsigs "TOP.vicii.pixels_shifting"
lappend pickedsigs "TOP.vicii.is_background_pixel"
lappend pickedsigs "TOP.vicii.pixel_color1"
lappend pickedsigs "TOP.vicii.pixel_color2"
lappend pickedsigs "TOP.vicii.pixel_color3"

set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
