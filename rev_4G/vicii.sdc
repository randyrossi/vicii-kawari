create_clock -period 69.84 -name clk_col4x_ntsc [get_ports clk_col4x_ntsc]
create_clock -period 56.38 -name clk_col4x_pal [get_ports clk_col4x_pal]

create_clock -period 30.55 -name clk_dot4x_ntsc
create_clock -period 17.46 -name clk_col16x_ntsc
create_clock -period 6.11 -name clk_dot20x_ntsc
create_clock -period 3.055 -name clk_dot40x_ntsc

create_clock -period 31.71 -name clk_dot4x_pal
create_clock -period 14.09 -name clk_col16x_pal
create_clock -period 6.35 -name clk_dot20x_pal
create_clock -period 3.171 -name clk_dot40x_pal

set_clock_groups -exclusive -group {clk_col4x_ntsc clk_dot4x_ntsc clk_col16x_ntsc clk_dot20x_ntsc clk_dot40x_ntsc}
set_clock_groups -exclusive -group {clk_col4x_pal clk_dot4x_pal clk_col16x_pal clk_dot20x_pal clk_dot40x_pal}

set_false_path -from clk_dot4x_ntsc -to clk_col16x_ntsc
set_false_path -from clk_dot4x_pal -to clk_col16x_pal

set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[0]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[1]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[2]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[3]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[4]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[5]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[6]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[7]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[8]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal1_1[9]~FF

set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[0]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[1]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[2]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[3]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[4]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[5]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[6]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[7]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[8]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal0_1[9]~FF

set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[0]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[1]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[2]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[3]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[4]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[5]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[6]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[7]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[8]~FF
set_false_path -from clk_dot4x_pal -to dvi_tx0/serializer/tmds_internal2_1[9]~FF
