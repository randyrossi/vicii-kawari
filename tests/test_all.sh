#!/bin/bash
# Usage
# ./test_all [prg]
#
# If prg omitted, all tests run.

if [ "$1" == "" ]
then
   PRG_TESTS=`find ./VICII -name '*.prg' -type f`
   VSF_TESTS=`find . -name '*.vsf' -type f`
   TESTS="$PRG_TESTS $VSF_TESTS"
else
   TESTS="$1"
fi

for i in $TESTS
do
	j=`basename $i`
	k=`dirname $i`

	if [[ $i == +(*ntsc*) ]]
	then
		model="ntsc"
		chip="0"
	else
		model="pal"
		chip="1"
	fi

	delay="6"
	if [[ $i == +(*spritecrunch*) ]]
	then
		delay="8"
	elif [[ $i == +(*reg_timing*) ]]
	then
		delay="10"
	fi

	pushd /shared/Vivado/vicii-vice-3.4
        ./src/x64sc -sounddev dummy -pal -VICIImodel $model \
		"/shared/Vivado/vicii/tests/$i" 2> stderr &
	popd

	sleep $delay

	rm -f screenshot.bmp
	../simulator/obj_dir/Vtop -w -z -x -c $chip

	convert screenshot.bmp -scale 50% $k/fpga_$j.png
	mv /shared/Vivado/vicii-vice-3.4/screenshot.png $k/vice_$j.png
	mv /shared/Vivado/vicii-vice-3.4/stderr $k/vice_$j.log
done
