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

TESTS=tests/test1.cpp tests/test2.cpp

default: ipc_test vicii_ipc.o libvicii_ipc.so
	$(VERILATOR) --trace -cc --exe vicii.v clockdivs.v sync.v serration.v equalization.v sim_main.cpp test.cpp log.cpp $(TESTS) -CFLAGS -g -LDFLAGS '../vicii_ipc.o -lSDL2'
	$(MAKE) -j 4 -C obj_dir -f Vvicii.mk

vicii_ipc.o: vicii_ipc.c
	$(CC) -o vicii_ipc.o -fPIC -c vicii_ipc.c

ipc_test: libvicii_ipc.so
	$(CC) -o ipc_test ipc_test.o -L /usr/lib -lvicii_ipc

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

# Everything
SIGNALS=cas,ras,mux,phi,rw,ce

# Bring up the logic analyser on a frame's worth of data
logic:
	obj_dir/Vvicii -i $(SIGNALS) -o session.vcd
	gtkwave session.vcd

# Bring up the logic analyzer after capturing a session from VICE
logic_vice:
	obj_dir/Vvicii -i $(SIGNALS) -z -o session.vcd
	gtkwave session.vcd

# Show a window while capturing and then bring up the logic analyser
logic_window_vice:
	obj_dir/Vvicii -w -z

# Render a frame in the window
view:
	obj_dir/Vvicii -w

test:
	obj_dir/Vvicii -r 1 -c 0
	obj_dir/Vvicii -r 1 -c 1
	obj_dir/Vvicii -r 1 -c 2

######################################################################

maintainer-copy::
clean mostlyclean distclean maintainer-clean::
	-rm -rf obj_dir *.log *.dmp *.vpd core
	-rm -f vicii_ipc.o ipc_test libvicii_ipc.so
