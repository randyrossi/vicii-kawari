These are some useful programs to test the verilog.
TODO: Convert these to .asm if possible. They are too slow to run through atm.

sprite5.prg

   Sprite to sprite collision timing test. This places two sprites over top of each other so that the collision happens at least once on every pixel within a cycle.  Four pixels will be on a low cycle and four on a high cycle.  On previous iterations of the verilog, this triggered VICE state check warnings because collisions that occur on the high cycle should not be 'seen' by the CPU until the next high cycle.  If you run through this whole test until you see the READY prompt and no warnings were printed (about registers $19 and $1e) then the test was successful.  Ignore the numbers printed.

sprite6.prg

   Sprite to data collision timing test. This places one sprites over top a full character cell so that the collision happens at least once on every pixel within a cycle.  Four pixels will be on a low cycle and four on a high cycle.  On previous iterations of the verilog, this triggered VICE state check warnings because collisions that occur on the high cycle should not be 'seen' by the CPU until the next high cycle.  If you run through this whole test until you see the READY prompt and no warnings were printed (about registers $19 and $1e) then the test was successful.  Ignore the numbers printed.

