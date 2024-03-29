set nfacs [ gtkwave::getNumFacs ]
set dumpname [ gtkwave::getDumpFileName ]
set dmt [ gtkwave::getDumpType ]
set pickedsigs [list]

lappend pickedsigs "TOP.clk_phi"
lappend pickedsigs "TOP.clk_dot"
lappend pickedsigs "top.vic_inst.cycle_type"
lappend pickedsigs "top.vic_inst.cycle_num"
lappend pickedsigs "top.vic_inst.raster_line"
lappend pickedsigs "top.vic_inst.raster_line_d"
lappend pickedsigs "top.vic_inst.xpos"
lappend pickedsigs "top.vic_inst.dot_rising"
lappend pickedsigs "top.vic_inst.vic_sprites.cycle_bit"
lappend pickedsigs "TOP.ce"
lappend pickedsigs "TOP.rw"
lappend pickedsigs "top.vic_inst.adi"
lappend pickedsigs "top.vic_inst.dbi"
lappend pickedsigs "TOP.aec"
lappend pickedsigs "TOP.ba"

# Pixel stuff
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.load_pixels"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.char_read"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.char_read_delayed0"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.char_read_delayed1"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.char_read_delayed"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixels_read"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixels_read_delayed0"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixels_read_delayed1"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixels_read_delayed"
#lappend pickedsigs "top.vic_inst.phi_phase_start"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.xpos_mod_8"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.char_shifting"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixels_shifting"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixel_color1"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixel_color2"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.pixel_color3"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.is_background_pixel0"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.is_background_pixel1"
#lappend pickedsigs "top.vic_inst.main_border"
#lappend pickedsigs "top.vic_inst.main_border_stage1"
#lappend pickedsigs "top.vic_inst.main_border_stage2"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.stage0"
#lappend pickedsigs "top.vic_inst.vic_pixel_sequencer.stage1"
#lappend pickedsigs "top.vic_inst.vic_sprites.sprite_m2d"
#lappend pickedsigs "top.vic_inst.vic_sprites.sprite_mmc"
#lappend pickedsigs "top.vic_inst.vic_sprites.sprite_mmc_ff"

# DRAM
lappend pickedsigs "top.ras"
lappend pickedsigs "top.cas"
lappend pickedsigs "top.vic_inst.mux"
lappend pickedsigs "top.vic_inst.ado"

# DVI
#lappend pickedsigs "top.dvi_tx0.serializer.load"
#lappend pickedsigs "top.dvi_tx0.serializer.clk_pixel"
#lappend pickedsigs "top.dvi_tx0.serializer.clk_pixel_x10"
#lappend pickedsigs "top.dvi_tx0.serializer.tmds"
#lappend pickedsigs "top.dvi_tx0.serializer.tmds_internal_0"
#lappend pickedsigs "top.dvi_tx0.serializer.tmds_shift_0"


set num_added [ gtkwave::addSignalsFromList $pickedsigs ]
