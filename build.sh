#!/bin/sh

# EDIT Makefile.inc to set version 

# Beta board build
pushd rev_3
./build.sh
popd

# Small board build(s)
pushd rev_4S
./build.sh
popd

# Large board build
pushd rev_4L
./build.sh
popd
