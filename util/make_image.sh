# Makes an img.bin and col.bin file that can be loaded
# directly into vmem 
if [ "$1" == "" ]
then
   echo "Usage make_image.sh img.png"
   exit 0
fi

# Make the img binary
java MakeImage -bin 640x200x4 $1 img.bin col.bin

# Prepend load bytes
../disks/util/flash/load_bytes 0 0 > tmp.bin
cat img.bin >> tmp.bin
mv tmp.bin img.bin

# Color file must also add hsv equivalents
./rgb2hsv col.bin > tmp.bin
cat tmp.bin >> col.bin
rm -f tmp.bin
../disks/util/flash/load_bytes 160 64 > tmp.bin
cat col.bin >> tmp.bin
mv tmp.bin col.bin
