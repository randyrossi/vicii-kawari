# Makes an img.bin and col.bin file that can be loaded
# directly into vmem 

INCLUDE_LOAD_BYTES=1

if [ "$1" == "" ]
then
   echo "Usage make_image.sh <res> img.png"
   echo "Where res is 320x200x16 or 640x200x4"
   exit 0
fi

if [ "$1" != "320x200x16" -a "$1" != "640x200x4" ]
then
echo "Unknown format"
exit -1
fi

if [ "$2" == "" ]
then
echo "Missing file"
exit -1
fi

# Make the img binary
java MakeImage -bin $1 $2 img.bin col.bin

# Prepend load bytes
if [ "$INCLUDE_LOAD_BYTES" = "1" ]
then
../disks/util/flash/load_bytes 0 0 > tmp.bin
cat img.bin >> tmp.bin
mv tmp.bin img.bin
fi

# Color file must also add hsv equivalents
if [ "$1" = "320x200x16" ]
then
NUM_COLS=16
elif [ "$1" = "640x200x4" ]
then
NUM_COLS=4
fi
./rgb2hsv col.bin $NUM_COLS 20 tmp.bin
cat tmp.bin >> col.bin
rm -f tmp.bin

if [ "$INCLUDE_LOAD_BYTES" = "1" ]
then
../disks/util/flash/load_bytes 160 64 > tmp.bin
cat col.bin >> tmp.bin
mv tmp.bin col.bin
fi

# For simulator
#xxd -g 1 img.bin > bitmap.hex
#xxd -g 1 col.bin > colors.hex
#python tobin.py
