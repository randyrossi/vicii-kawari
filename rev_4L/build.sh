#!/bin/sh

mkdir -p build

cp rev_4LD.top.prj top.prj
make -f rev_4LD.Makefile clean golden > build/rev_4LD.golden.log
make -f rev_4LD.Makefile clean multiboot > build/rev_4LD.multiboot.log
make -f rev_4LD.Makefile mcs
