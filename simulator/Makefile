######################################################################
#
# DESCRIPTION: Verilator Example: Small Makefile
#
# This calls the object directory makefile.  That allows the objects to
# be placed in the "current directory" which simplifies the Makefile.
#
# Copyright 2003-2019 by Wilson Snyder. This program is free software; you can
# redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
#

# 0 = LUMA CHROMA Minimal Config
# 1 = Test suite config for ../tests
# 2 = Efinix RGB
# 3 = Efinix DVI (PAL_RES takes effect, results in twin disp - no native x)
# 4 = Test Pattern (No video options)
# 5 = Just DVI
# 6 = No luma chroma
# 7 = Flash but on eeprom
# 8 = Extensions but no optional features
# 9 = 4K Video Ram
# 10 = Misc

# Efinix config. Use PAL 29MHZ and NTSC 26MHZ clocks for DVI
SIM_CONFIG = 3

# 32MHZ | 29MHZ | 27MHZ
#PAL_RES = 32MHZ
#PAL_RES = 15MHZ
PAL_RES = 29MHZ
#PAL_RES = 27MHZ

# 32MHZ | 26MHZ
#NTSC_RES = 32MHZ
#NTSC_RES = 16MHZ
NTSC_RES = 26MHZ

######################################################################
# Check for sanity to avoid later confusion


ifneq ($(words $(CURDIR)),1)
 $(error Unsupported: GNU Make cannot build in directories containing spaces, build elsewhere: '$(CURDIR)')
endif

######################################################################

# This is intended to be a minimal example.  Before copying this to start a
# real project, it is better to start with a more complete example,
# e.g. examples/make_tracing_c.

# If $VERILATOR_ROOT isn't in the environment, we assume it is part of a
# package install, and verilator is in your path. Otherwise find the
# binary relative to $VERILATOR_ROOT (such as when inside the git sources).
ifeq ($(VERILATOR_ROOT),)
VERILATOR = verilator
else
export VERILATOR_ROOT
VERILATOR = $(VERILATOR_ROOT)/bin/verilator
endif

VERILOG_SOURCES = ../hdl/simulator/top.v ../hdl/vicii.v ../hdl/common.vh \
		  ../hdl/equalization.v  ../hdl/pixel_sequencer.v \
                  ../hdl/registers.v  ../hdl/comp_sync.v ../hdl/border.v \
	          ../hdl/lightpen.v ../hdl/raster.v ../hdl/divide.v \
	          ../hdl/serration.v  ../hdl/bus_access.v ../hdl/cycles.v \
                  ../hdl/matrix.v ../hdl/sprites.v  ../hdl/hires_vga_sync.v \
                  ../hdl/hires_dvi_sync.v \
		  ../hdl/videoram.v ../hdl/colorreg.v \
		  ../hdl/sinewave.v ../hdl/testpattern.v ../hdl/lumareg.v \
		  ../hdl/hires_matrix.v ../hdl/hires_addressgen.v ../hdl/hires_pixel_sequencer.v \
		  ../hdl/efinix_trion/dvi/dvi.v \
		  ../hdl/efinix_trion/dvi/tmds_channel.v \
		  ../hdl/efinix_trion/dvi/serializer.v

VTOP_DEPS = vicii_ipc.o libvicii_ipc.so $(VERILOG_SOURCES) sim_main.cpp vicii_ipc.c vicii_ipc.h 


VI_INC = ../hdl/registers_eeprom.vi ../hdl/registers_ram.vi ../hdl/registers_eeprom.vi ../hdl/registers_flash.vi

# Use -DHIRES_TEXT -DHIRES_BITMAP1 -DHIRES_BITMAP2 -DHIRES_BITMAP3 -DHIRES_BITMAP4 for other modes
# Add -DVIC_ROLL=1 for vic_roll branch
obj_dir/Vtop: $(VTOP_DEPS) gen_config $(VI_INC)
	@(./gen_config $(NTSC_RES) $(PAL_RES) $(SIM_CONFIG) > ../hdl/config.vh)
	$(VERILATOR) -D$(KAWARI_FLAGS) --top-module top --trace -cc  --exe \
	    -I../hdl $(VERILOG_SOURCES) -I../hdl/dvi sim_main.cpp log.cpp \
	    -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) $(SIM_CONFIG) defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

default: obj_dir/Vtop

vicii_ipc.o: vicii_ipc.c
	$(CC) -o vicii_ipc.o -fPIC -c vicii_ipc.c

libvicii_ipc.so: vicii_ipc.o
	$(CC) -shared vicii_ipc.o -o libvicii_ipc.so

# Install our libvicii_ipc library so VICE can link against it
# TODO: Change this to specify where vice build is instead of installing
# system wide.
install: libvicii_ipc.so
	sudo cp libvicii_ipc.so /usr/lib
	sudo chmod oug+r /usr/lib/libvicii_ipc.so
	sudo cp vicii_ipc.h /usr/include
	sudo chmod oug+r /usr/include/vicii_ipc.h

logic:
	#Make it so we can add bus values in session.tcl
	#cat session.vcd | sed 's/tmds_internal(0)/tmds_internal_0/g' | sed 's/tmds_shift(0)/tmds_shift_0/g' > tmp
	#mv tmp session.vcd
	gtkwave session.vcd --script session.tcl

gen_config: gen_config.o
	cc -o gen_config gen_config.o

gen_config.o: gen_config.c
	cc -c gen_config.c -o gen_config.o

config_test_0: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 0 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 0 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_1: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 1 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 1 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_2: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 2 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 2 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_3: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 3 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 3 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_4: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 4 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 4 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_5: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 5 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 5 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_6: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 6 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 6 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_7: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 7 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 7 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_8: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 8 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 8 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_9: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 9 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 9 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_10: gen_config
	@(./gen_config $(NTSC_RES) $(PAL_RES) 10 > ../hdl/config.vh)
	$(MAKE) mostlyclean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config $(NTSC_RES) $(PAL_RES) 10 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk


config_test: config_test_0 config_test_1 config_test_2 config_test_3 \
	     config_test_4 config_test_5 config_test_6 config_test_7 \
	     config_test_8 config_test_9 config_test_10

######################################################################

mostlyclean:
	-rm -rf obj_dir *.log *.dmp *.vpd core
	-rm -f *.o ipc_test libvicii_ipc.so

clean:
	-rm -rf obj_dir *.log *.dmp *.vpd core
	-rm -f *.o ipc_test gen_config libvicii_ipc.so
