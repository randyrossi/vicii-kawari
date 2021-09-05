# Make bmm transition combos to test
# the ROM address glitch.
#
# Really, we only need to go through
# banks 0 1 2 3 to get all possible address
# ranges and CB 4 and 8 to generate both
# in ROM range and not ROM ranges and
# that should cover everything.  The other
# combos will show different graphics
# depending on contents of memory but
# does nothing to test.

#CB="0 2 4 6 8 10 12 14"
CB="4 8"
BANK="3 2 1 0"

for cb in $CB
do
for bank in $BANK
do
cat glitch.template | sed "s/%CB%/$cb/" | sed "s/%BANK%/$bank/" > glitch.asm
make glitch.prg
mv glitch.prg glitch_${cb}_${bank}.prg
done
done
