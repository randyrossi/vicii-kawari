#!/bin/bash
pushd $1
pwd
SEEDS=`find . -type d -maxdepth 1`
echo $SEEDS
for i in $SEEDS
do
if [ "$i" != "." ]
then
echo ================================
echo $i
echo ================================
pushd $i
../../check_timing.sh
popd
fi
done
