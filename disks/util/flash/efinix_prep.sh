# Use the Efinity programming tool to make a selectable
# .hex file with the following profile:
# Slot 00 = fallback image
# Slot 01 = empty
# Slot 10 = active image
# Slot 11 = empty

if [ "$1" = "" -o "$2" = "" ]
then
  echo "Usage: ./efinix_prep.sh <hex.file> <version>"
  exit
fi

if [ -e $1 ]
then
  make multi_hex_to_bit
  ./multi_hex_to_bit $1 > kawari_multiboot_LH_$2.bit
else
  echo "$1" does not exit
fi
