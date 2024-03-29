#!/bin/bash
# Usage
# ./test_all [prg]
#
# If prg omitted, all tests run.

VICII_PARENT=/shared/Vivado

input="tests.txt"
while read -r line
do
   stringarray=($line)

   #if [ "${stringarray[2]}" == "screenshot" ]
   #then

	i=${stringarray[0]}

	j=`basename $i`
	k=`dirname $i`

	if [ "${stringarray[1]}" == "NTSC" ]
	then
		standard="-ntsc"
		model="6567"
		chip="0"
		resolution="520x263"
	elif [ "${stringarray[1]}" == "NTSCOLD" ]
	then
		standard="-ntsc"
		model="6567r56a"
		chip="2"
		resolution="512x262"
	else
		standard="-pal"
		model="6569"
		chip="1"
		resolution="512x312"
	fi

	delay="6"
	if [[ $i == +(*spritecrunch*) ]]
	then
		delay="8"
	elif [[ $i == +(*reg_timing*) ]]
	then
		delay="14"
	elif [[ $i == +(*lightpen*) ]]
	then
		delay="16"
	elif [[ $i == +(*lft-safe-vsp*) ]]
	then
		delay="19"
	elif [[ $i == +(*spritescan*) ]]
	then
		delay="19"
	elif [[ $i == +(*sprite0move*) ]]
	then
		delay="19"
	elif [[ $i == +(*spritevssprite*) ]]
	then
		delay="19"
	fi

	pushd ${VICII_PARENT}/vicii-vice-3.4
        ./src/x64sc -sounddev dummy $standard -VICIImodel $model \
		"${VICII_PARENT}/vicii-kawari/tests/$i" 2> stderr &
	popd
	sleep $delay
	rm -f screenshot.bmp
	../simulator/obj_dir/Vtop -k -q -w -z -x -c $chip
	sleep 1

	mv ${VICII_PARENT}/vicii-vice-3.4/stderr $k/vice_$j.log
	convert screenshot.bmp -interpolate Integer -filter point -resize $resolution $k/fpga_$j.png
	mv ${VICII_PARENT}/vicii-vice-3.4/screenshot.png $k/vice_$j.png
   #fi

done < "$input"
