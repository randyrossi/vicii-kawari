#!/bin/sh
mkdir -p build

MAJ=1
MIN=17

# MAINLG-DVI:29MHZ:U
#    Unscaled output. Irregular resolutions. This is/was the default
#    for many releases. The resolutions are not compatible with some
#    monitors.  This has the DVI build identifier.
#
# MAINLG-DVI:27MHZ:U
#    This is identical to the 29MHZ version above except the PAL dot
#    clock is reduced to 27MHZ for a 720x576 resolution that is more
#    compatible with many TVs/monitors.  However, the drawback is
#    the visible region is stretched too much horizontally. The
#    output is not scaled as above. Never released.
#
# MAINLG-DVI:27MHZ:S
#    This is identical to the 27MHZ version above except both NTSC
#    and PAL displays go through a 10 to 9 scaler to get a better
#    aspect ratio.  This has the added benefit of being more
#    compatible as in the 27MGZ:U version but the scaling won't
#    work well for any hires modes (80 column or 640x200). It is
#    offered as an alternative to the default 29MHZ:U build and
#    is given a DVS build identifier.
#
# MAINLG-RGB:32MHZ:U
#    This the one and only full resolution analog RGB build.
#
ALL="MAINLG-DVI:29MHZ:U MAINLG-DVI:27MHZ:S"
for V in $ALL
do
   IFS=':'
   VAR=""
   RES=""
   OPT=""
   for ENTRY in $V
   do
      if [ "$VAR" = "" ]; then
         VAR=$ENTRY
      elif [ "$RES" = "" ]; then
         RES=$ENTRY
      elif [ "$OPT" = "" ]; then
         OPT=$ENTRY
      fi
   done

   VAR=$VAR-$RES-$OPT

   echo "Building $VAR..."

   cp vicii_${RES}.peri.xml vicii.peri.xml
   cp vicii_${RES}.sdc vicii.sdc
   cp vicii_${OPT}.xml vicii.xml

   if [ "$1" = "sweep" ]
   then
      VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${VAR} make clean sweep > build/${VAR}.${MAJ}.${MIN}_sweep.log
   else
      VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${VAR} make clean all > build/${VAR}.${MAJ}.${MIN}.log
      cp outflow/vicii.timing.rpt build/${VAR}.${MAJ}.${MIN}.rpt
   fi
done
