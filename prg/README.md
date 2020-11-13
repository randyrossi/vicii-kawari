These are some useful programs to test the verilog behaves as expected.

sprite5.prg

   Sprite to sprite collision timing test. This places two sprites over top of each other so that the collision happens at least once on every pixel within a cycle.  Four pixels will be on a low cycle and four on a high cycle.  On previous iterations of the verilog, this triggered VICE state check warnings because collisions that occur on the high cycle should not be 'seen' by the CPU until the next high cycle.  If you run through this whole test until you see the READY prompt and no warnings were printed (about registers $19 and $1e) then the test was successful.  When you see READY printed, the test is over.

sprite6.prg

   Sprite to data collision timing test. This places one sprites over top a full character cell so that the collision happens at least once on every pixel within a cycle.  Four pixels will be on a low cycle and four on a high cycle.  On previous iterations of the verilog, this triggered VICE state check warnings because collisions that occur on the high cycle should not be 'seen' by the CPU until the next high cycle.  If you run through this whole test until you see the READY prompt and no warnings were printed (about registers $19 and $1e) then the test was successful.  When you see READY printed, the test is over.

sprite8.prg
sprite9.prg

   Place a single pixel sprite over top a single foreground pixel.
   sprite8 does this in top left corner
   sprite9 does this in top right corner
   Used to make sure background collision happens at expected time
   and border delay being used in sprite.v is correct (can't be too early
   or late or else one of these will fail)
   Need to run this until basic prompt prints results because it reads
   from the collision register to reset it and the next pass should trigger
   the collision.
   NOTE: When a collision happens within a HIGH cycle, the collision register
   set is deferred until the LOW cycle.  So sprite8 test has this delay.
