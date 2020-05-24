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

VERILOG_SOURCES = ../hdl/vicii.v ../hdl/color.v ../hdl/clockdivs.v ../hdl/sync.v ../hdl/serration.v \
                    ../hdl/equalization.v ../hdl/common.vh
obj_dir/Vvicii: vicii_ipc.o libvicii_ipc.so $(VERILOG_SOURCES)
	$(VERILATOR) --trace -cc  --exe -I../hdl $(VERILOG_SOURCES) sim_main.cpp test.cpp log.cpp tests/test*.cpp \
	               -CFLAGS -g -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vvicii.mk

default: obj_dir/VVicii

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
logic:
	gtkwave session.vcd --script session.tcl

# Bring up the logic analyzer after capturing a session from VICE
logic_vice: obj_dir/Vvicii
	obj_dir/Vvicii -z -t
	gtkwave session.vcd --script seession.tcl

# Show a window while capturing and then bring up the logic analyser
logic_window_vice: obj_dir/Vvicii
	obj_dir/Vvicii -w -z -t
	gtkwave session.vcd --script seession.tcl

# Render a frame in the window
view: obj_dir/Vvicii
	obj_dir/Vvicii -w

test:
	victest

make_golden:
	victest 1

######################################################################

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir *.log *.dmp *.vpd core
	-rm -f vicii_ipc.o ipc_test libvicii_ipc.so
