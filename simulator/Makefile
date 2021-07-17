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
		  ../hdl/addressgen.v  ../hdl/equalization.v  ../hdl/pixel_sequencer.v \
                  ../hdl/registers.v  ../hdl/comp_sync.v ../hdl/border.v \
	          ../hdl/lightpen.v ../hdl/raster.v \
	          ../hdl/serration.v  ../hdl/bus_access.v ../hdl/cycles.v \
                  ../hdl/matrix.v ../hdl/sprites.v  ../hdl/hires_vga_sync.v \
		  ../hdl/clockdivs.v ../hdl/videoram.v ../hdl/colorreg.v \
		  ../hdl/sinewave.v ../hdl/testpattern.v ../hdl/lumareg.v \
		  ../hdl/hires_matrix.v ../hdl/hires_addressgen.v ../hdl/hires_pixel_sequencer.v

VTOP_DEPS = vicii_ipc.o libvicii_ipc.so $(VERILOG_SOURCES) sim_main.cpp vicii_ipc.c vicii_ipc.h 

SIM_CONFIG = 0

# Use -DHIRES_TEXT -DHIRES_BITMAP1 -DHIRES_BITMAP2 -DHIRES_BITMAP3 for other modes
obj_dir/Vtop: $(VTOP_DEPS) gen_config \
	../hdl/registers_eeprom.v ../hdl/registers_ram.v
	@(./gen_config $(SIM_CONFIG) > ../hdl/config.vh)
	$(VERILATOR) --top-module top --trace -cc  --exe \
	    -I../hdl $(VERILOG_SOURCES) -I../hdl/dvi sim_main.cpp log.cpp \
	    -CFLAGS "-g `./gen_config $(SIM_CONFIG) defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
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

# Bring up the logic analyser on most recent session
logic_fix:
	vicrepair session.vcd
	gtkwave session.vcd --script session.tcl

logic:
	gtkwave session.vcd --script session.tcl

# Render a frame in the window
view: obj_dir/Vtop
	obj_dir/Vtop -w

gen_config: gen_config.o
	cc -o gen_config gen_config.o

gen_config.o: gen_config.c
	cc -c gen_config.c -o gen_config.o

config_test_0: gen_config
	@(./gen_config 0 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 0 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_1: gen_config
	@(./gen_config 1 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 1 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_2: gen_config
	@(./gen_config 2 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 2 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_3: gen_config
	@(./gen_config 3 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 3 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_4: gen_config
	@(./gen_config 4 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 4 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_5: gen_config
	@(./gen_config 5 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 5 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_6: gen_config
	@(./gen_config 6 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 6 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test_7: gen_config
	@(./gen_config 7 > ../hdl/config.vh)
	$(MAKE) clean
	$(MAKE) vicii_ipc.o
	$(VERILATOR) --top-module top --trace -cc  --exe \
		-I../hdl $(VERILOG_SOURCES) sim_main.cpp log.cpp \
	               -CFLAGS "-g `./gen_config 7 defs`" -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vtop.mk

config_test: config_test_0 config_test_1 config_test_2 config_test_3 \
	     config_test_4 config_test_5 config_test_6 config_test_7 

######################################################################

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir *.log *.dmp *.vpd core
	-rm -f vicii_ipc.o ipc_test libvicii_ipc.so
