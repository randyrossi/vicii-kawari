# Utility script to replace just the flash.prg
# inside a flash build .zip.  Use this to update
# just the flash program to a new version.

mkdir repair
cd repair
unzip ../$1

c1541 -attach flash1.d64 -read flash
c1541 -attach flash1.d64 -read loader
c1541 -attach flash1.d64 -read info
LIST=`c1541 -attach flash1.d64 -list | grep i[0-9][0-9][0-9] | sed 's/^.* "//' | sed 's/".*//'`
for i in $LIST
do
c1541 -attach flash1.d64 -read $i
done

cp ../flash.prg flash

rm flash1.d64

c1541 -format 1,flash d64 flash1.d64
c1541 -attach flash1.d64 -write flash
c1541 -attach flash1.d64 -write loader
c1541 -attach flash1.d64 -write info
for i in $LIST
do
c1541 -attach flash1.d64 -write $i
done

rm i[0-9][0-9][0-9]
rm flash
rm loader
rm info



c1541 -attach flash.d81 -read flash
c1541 -attach flash.d81 -read loader
c1541 -attach flash.d81 -read info
LIST=`c1541 -attach flash.d81 -list | grep i[0-9][0-9][0-9] | sed 's/^.* "//' | sed 's/".*//'`
for i in $LIST
do
c1541 -attach flash.d81 -read $i
done

cp ../flash.prg flash

rm flash.d81

c1541 -format kawari-flash,1 d81 flash.d81
c1541 -attach flash.d81 -write flash
c1541 -attach flash.d81 -write loader
c1541 -attach flash.d81 -write info
for i in $LIST
do
c1541 -attach flash.d81 -write $i
done

rm i[0-9][0-9][0-9]
rm flash
rm loader
rm info

zip ../$1.repaired *
cd ..
rm -rf repair
