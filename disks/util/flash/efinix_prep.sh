# Use the Efinity programming tool to make a selectable
# .hex file with the following profile:
# Slot 00 = fallback image
# Slot 01 = empty
# Slot 10 = active image
# Slot 11 = empty

if [ "$1" = "" -o "$2" = "" -o "$3" = "" ]
then
  echo "Usage: ./efinix_prep.sh <hex.file> <image> <version>"
  echo
  echo "        where <image> is golden or multiboot"
  exit
fi

if [ "$2" = "golden" -o "$2" = "multiboot" ]
then

if [ -e $1 ]
then
  make multi_hex_to_bit
  ./multi_hex_to_bit $1 > kawari_$2_LH_$3.bit
else
  echo "$1" does not exit
fi

else
  echo "Unknown image type :golden or multiboot"
fi
