# cd into the seed's outflow dir 
# Run this after making multi.hex using efinity_pgm.sh

VER=1.19
DEST=/shared/Vivado/vicii-kawari/disks/util/flash/hex/single/$VER
DESTM=/shared/Vivado/vicii-kawari/disks/util/flash/hex/multi/$VER
VARIANT=LG_RGB-32MHZ-U

echo "Before"
ls -l $DEST/$VARIANT.hex
ls -l $DESTM/kawari_${VER}_${VER}_multi_${VARIANT}.hex

echo "Press return"
read proceed

cp vicii.hex $DEST/$VARIANT.hex
cp vicii.err.log $DEST/$VARIANT.err.log
cp vicii.info.log $DEST/$VARIANT.info.log
cp vicii.map.rpt $DEST/$VARIANT.map.rpt
cp vicii.place $DEST/$VARIANT.place.rpt
cp vicii.route.rpt $DEST/$VARIANT.route.rpt
cp vicii.timing.rpt $DEST/$VARIANT.timing.rpt
cp vicii.warn.log $DEST/$VARIANT.warn.log


cp multi.hex $DESTM/kawari_${VER}_${VER}_multi_${VARIANT}.hex 
cp multi.rpt $DESTM/kawari_${VER}_${VER}_multi_${VARIANT}.rpt 

echo "After"
ls -l $DEST/$VARIANT.hex
ls -l $DESTM/kawari_${VER}_${VER}_multi_${VARIANT}.hex
