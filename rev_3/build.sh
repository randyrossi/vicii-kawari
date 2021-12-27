#!/bin/sh

mkdir -p build

cp rev_3.top.prj top.prj
make -f rev_3.Makefile clean golden > build/rev_3.golden.log
make -f rev_3.Makefile clean multiboot > build/rev_3.multiboot.log
make -f rev_3.Makefile mcs
