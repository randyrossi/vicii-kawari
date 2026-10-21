# VIC-II Kawari Video Chip Replacement Project for the Commodore 64

This repository contains RTL logic for a fpga based replacement of the Commodore 64's VIC-II video chip.  There are also a number of 'extended' features documented in doc/REGISTERS.md.  The extended features are only available once acivated by a custom byte sequence POKE'd to a new register visible from the 6502.

# Building

Activate the toolchain for efinix builds with:

    source ~/tools/efinity/2021.2/bin/setup.sh

NOTE: Builds cannot run in parallel due to some files being written into place by the build script.  For example, hdl/config.vh is created by make config.

## Mini Board

Build steps:

    cd boards/rev_4H
    ./build.sh

This will produce MAINLH, MAINLH-DOTC-1.2, MAINLH-DOTC-1.5 variants for the Mini board.  The bitstream and .rpt files will be found in the build subdirectory.

## Large Board

Build steps:

    cd boards/rev_4G
    ./build.sh
   
This will produce MAINLG-DVI:29MHZ:U, MAINLG-DVI:27MHZ:S, MAINLG-RGB:32MHZ:U variants for the Large board.  The bistream and .rpt files will be found in the build subdirectory.

NOTE: Only rev_4H and rev_4G boards are active.  rev_4J is planned but not in active development.

# Ensuring Correctness with the C64 6567/6569 Chips

The top level 'tests' directory is only used to compare vanilla C64 features to the verilated HDL.  It is not meant to excercise any new features and relies on the patched VICE repo (located at ../vicii-vice-3.4) with some simulator synchronization hooks (i.e. vicii-ipc.h).

Comparing VICE output and the verilated simulator:

    cd tests
    ./run_test simple/simple.prg
    ./compare_screenshots.py simple --prg simple.prg --max-offset 5 

# Testing new features

The 'disks/util/tests' directory contains a collection of programs that test the Kawari extended features.

# Development

The ../vicii-kawari-vice repository is meant to emulate a complete Kawari enabled C64 and does not have the simulator synchronization hooks.  The new Kawari features are re-implemented in C and should thus not be taken to represent actual RTL logic.  If a discrepency between actual RTL logic and the Kawari-VICE fork is found, it should be addressed (most likely making the C match the RTL unless the RTS is incorrect).  

# Other

The sandbox will not allow /tmp directories to persist beween bash shell operations. If you need a tmp directory, create one locally in the workspace.

