# Use the Efinity programming tool to make a selectable
# .hex file with the following profile:
#
# Slot 00 = fallback image
# Slot 01 = empty
# Slot 10 = active image
# Slot 11 = empty
#
# Then use this tool to create a .bit file that the
# Makefile can work with to create flash disks.

if [ "$1" = "" -o "$2" = "" -o "$3" = "" -o "$4" = "" ]
then
  echo "Usage: ./efinix_prep.sh <hex.file> <type> <variant> <version>"
  echo
  echo "        where <type> is golden or multiboot"
  echo "        where <variant> is MAINLH|MAINLH-DOTC|MAINLG-DVI|MAINLG-RGB"
  exit
fi

if [ "$2" = "golden" -o "$2" = "multiboot" ]
then

if [ -e $1 ]
then
  make multi_hex_to_bit
  ./multi_hex_to_bit $1 kawari_$2_$3_$4.bit
  echo "Created kawari_$2_$3_$4.bit"
else
  echo "$1" does not exit
fi

else
  echo "Unknown type:golden or multiboot"
fi
