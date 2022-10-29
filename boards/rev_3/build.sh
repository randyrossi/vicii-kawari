#!/bin/sh

mkdir -p build

cp T.top.prj top.prj
make -f T.Makefile clean golden > build/rev_3T.golden.log
make -f T.Makefile clean multiboot > build/rev_3T.multiboot.log
make -f T.Makefile mcs
