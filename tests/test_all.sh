#!/bin/bash

PRG_TESTS=`find ./VICII_Old -name '*.prg' -type f`
VSF_TESTS=`find . -name '*.vsf' -type f`
TESTS="$PRG_TESTS $VSF_TESTS"

# Currently failing
# tests/dentest/den01-49-1.prg

for i in $TESTS
do
	j=`basename $i`
	k=`dirname $i`

	pushd /shared/Vivado/vicii-vice-3.4
        ./src/x64sc -sounddev dummy -pal -VICIImodel 6569 "/shared/Vivado/vicii/tests/$i" 2> stderr &
	popd

	sleep 6

	rm -f screenshot.bmp
	../simulator/obj_dir/Vtop -w -z -x

	convert screenshot.bmp -scale 50% $k/fpga_$j.png
	mv /shared/Vivado/vicii-vice-3.4/screenshot.png $k/vice_$j.png
	mv /shared/Vivado/vicii-vice-3.4/stderr $k/vice_$j.log
done
