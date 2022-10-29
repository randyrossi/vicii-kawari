#!/bin/sh

mkdir -p build

# Model SA - Just a VIC-II, Nothing else.
cp SA.top.prj top.prj
make -f SA.Makefile clean golden > build/SA.golden.log
make -f SA.Makefile clean multiboot > build/SA.multiboot.log
make -f SA.Makefile mcs

# Model SA - VIC-II + Enhancements, Switchable (No DVI or RGB)
cp SB.top.prj top.prj
make -f SB.Makefile clean golden > build/SB.golden.log
make -f SB.Makefile clean multiboot > build/SB.multiboot.log
make -f SB.Makefile mcs
