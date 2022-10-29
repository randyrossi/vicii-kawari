Prerequisites

    verilator (synced to hash 7bbce51f7bcb41cdd2d6d4f6e4fccd462dd6098b)
    sudo apt-get install gtkwave

    PATH=$VICII_HOME/bin:$PATH

Build

    make             - verilate fpga design
    make logic       - show logic analyser on simulation trace
    make view        - show a frame (vicsim -w)
    make config_test - run through config permutations

Usage

   Use the -z option to have the simulator wait for a IPC request from
   our modified VICE-3.4 code to shadow it's vic.  See vicii-vice-3.4
   repo.

       vicsim -z -w    (wait for IPC, show window)

   Then run the modified VICE code to act as the sender.

   Capture can be started by poking $d3ff to set capture flags.

   POKE 54271,1 - Set bit 1 enables FPGA sync

   When sync is enabled, VICE will single step the fpga design 16 half cycles
   after every CPU cycle.  If a write or read to/from a VIC register happens,
   this also sets address, data, ba, ce, rw lines appropriately so the fpga
   eval can operate on those values.

   You can keep VICE running and start/stop multiple captures. You have to end
   the fpga sync in a fairly short time or else you will generate too much
   data to view at once in pulseview.  It also takes a really long time
   to sync one whole frame as the fpga is evaluated every half dot clock cycle.

   POKE 54270,0 - Disable sync trigger by POKE, only monitor can enable

   From VICE's monitor: f d3ff,d3ff,1 - to enable sync

   vicsim -h  for other options
