#!/bin/sh

mkdir -p build

cp LD.top.prj top.prj
make -f LD.Makefile clean golden > build/LD.golden.log
make -f LD.Makefile clean multiboot > build/LD.multiboot.log
make -f LD.Makefile mcs
