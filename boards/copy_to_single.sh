#!/bin/bash

# Edit VER before running

VER=1.19
DEST=../../../disks/util/flash/hex/single/${VER}


# Copy the single .hex files into the single flash dir

# Expects PREFIX_SEED# files to be present inside the chosen seed dir.
#
# rev_4G/sweep_1.19_27mhz/LG_DVI-27MHZ-S_SEED6
# rev_4G/sweep_1.19_29mhz/LG_DVI-29MHZ-U_SEED2
# rev_4G/sweep_1.19_32mhz/LG_RGB-32MHZ-U_SEED2
# rev_4H/sweep_1.19/LH_SEED2
# rev_4H/sweep_1.19_DOTC-1.2/LH-DOTC-1.2_SEED7
# rev_4H/sweep_1.19_DOTC-1.5/LH-DOTC-1.5_SEED3

DIRS=`find . -name "sweep_$VER*"`

for i in $DIRS
do

pushd $i > /dev/null

SEEDNUM=`find . -name '*SEED*' | sed 's@^./@@' | sed 's/.*SEED//'`
PREFIX=`find . -name '*SEED*' | sed 's@^./@@' | sed 's/SEED.*//' | sed 's/_$//'`

if [ ! -e seed_${SEEDNUM}/outflow/vicii.hex ]
then
    echo "Seed pointer not found $i"
    exit
fi

# Save some important files
echo $i from seed_${SEEDNUM}
cp seed_${SEEDNUM}/outflow/vicii.hex $DEST/${PREFIX}.hex
cp seed_${SEEDNUM}/outflow/vicii.log $DEST/${PREFIX}.log
cp seed_${SEEDNUM}/outflow/vicii.info.log $DEST/${PREFIX}.info.log
cp seed_${SEEDNUM}/outflow/vicii.warn.log $DEST/${PREFIX}.warn.log
cp seed_${SEEDNUM}/outflow/vicii.err.log $DEST/${PREFIX}.err.log
cp seed_${SEEDNUM}/outflow/vicii.timing.rpt $DEST/${PREFIX}.timing.rpt
cp seed_${SEEDNUM}/outflow/vicii.place.rpt $DEST/${PREFIX}.place.rpt
cp seed_${SEEDNUM}/outflow/vicii.map.rpt $DEST/${PREFIX}.map.rpt
cp seed_${SEEDNUM}/outflow/vicii.route.rpt $DEST/${PREFIX}.route.rpt

popd > /dev/null

done
