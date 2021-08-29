# Known Issues

Program/Demo/Publisher  | Expected | Observation | Reason
------------------------|----------|-------------|--------
errata (emulamer)       | Secret message for 6569 users | Letters do not flash at top of screen | RAMtoROM BMM transition glitch not implemented
conclusion (emulamer)   | Flashing characters appear after intro msg| No flashing characters appear | RAMtoROM BMM transition glitch not implemented

# RAMtoROM BMM transition glitch not implemented

There is a glitch in the 6569 whereby a BMM flag transition during a graphics fetch cycle causes a generated CHARROM address to be incorrect. This only happens if the graphics fetch would have been a RAM address and the new BMM flag causes a ROM address to be accessed.  The resulting address low byte comes from the old BMM value but the high byte comes from the post BMM transition value.  Although the conditions and the final address accessed is known, I don't think the actual reason for the glitch is well understood.  VICE (and other whole system emulators and/or FPGA implementations) are easily able to reproduce this outcome of the glitch. This is because they have global information about the entire system, such as the current video bank. They can use this information to test the actual addresses that would have been fetched with both old and new BMM flags and check if they were RAM or ROM mapped,  However, a real VIC chip does not know anything about the current video bank. This means (in my opinion) the glitch is most likely caused by some timing issue, possibly involving RAS/CAS and the PLA whereby the low byte of the address was partially latched incorrectly (but only for ROM mappings). If VICII-Kawari is to reproduce this glitch, it will have to do it in the same way the actual chip does. (But it's not a very useful glitch)
