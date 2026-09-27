# VIC-II Kawari Video Chip Replacment Project for the Commodore 64

Activate toolchain via 

    source ~/tools/efinity/2021.2/bin/setup.sh

NOTE: Builds cannot run in parallel due to some files being written into place by the build script.  For example, hdl/config.vh is created by make config.

Only rev_4H and rev_4G boards are active.  rev_4J is planned but not in active development.

The sandbox will not allow /tmp directories to persist beween bash shell operations. If you need a tmp directory, create one locally in the workspace.

Testing comparison between VICE and the verilated simulator:

    cd tests
    ./run_test simple/simple.prg
    ./compare_screenshots.py simple --prg simple.prg --max-offset 5 

