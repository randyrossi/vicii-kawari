create_clock -period 69.84 -name clk_col4x_ntsc [get_ports clk_col4x_ntsc]
create_clock -period 56.38 -name clk_col4x_pal [get_ports clk_col4x_pal]

create_clock -period 30.55 -name clk_dot4x_ntsc
create_clock -period 17.46 -name clk_col16x_ntsc
create_clock -period 75.2 -name clk_dvi_ntsc
create_clock -period 7.52 -name clk_dvi10x_ntsc

create_clock -period 31.71 -name clk_dot4x_pal
create_clock -period 14.09 -name clk_col16x_pal
create_clock -period 12.70 -name clk_dot20x_pal
create_clock -period 72.4 -name clk_dvi_pal
create_clock -period 7.24 -name clk_dvi10x_pal

set_clock_groups -exclusive -group {clk_col4x_ntsc clk_dot4x_ntsc clk_col16x_ntsc clk_dvi_ntsc clk_dvi10x_ntsc}
set_clock_groups -exclusive -group {clk_col4x_pal clk_dot4x_pal clk_col16x_pal clk_dot20x_pal clk_dvi_pal clk_dvi10x_pal}

set_false_path -from clk_dot4x_ntsc -to clk_col16x_ntsc
set_false_path -from clk_dot4x_pal -to clk_col16x_pal
set_false_path -from clk_dot4x -to clk_col16x
set_false_path -from clk_dot4x_pal -to clk_dvi_pal
set_false_path -from clk_dot4x_ntsc -to clk_dvi_ntsc
set_false_path -from clk_dot4x -to clk_dvi
