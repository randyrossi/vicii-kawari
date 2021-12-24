# History of hardware revisions

mojo_v3 (Deprecated)

    This is a top.v and supporting files for the MojoV3 FPGA devboard with the 'hat'.  The MCU is hooked up to the flash ram and the bitstream is written to the FPGA by the MCU.  There is a serial link between the MCU and FPGA over which persisted data is saved/restored.  Analog RGB is possible over this board since there is a header on the hat but HDMI/DVI is not.

rev_1 (Deprecated)

    This is essentially the same configuration as the MojoV3 FPGA devboard but in an all-in-one PCB.  The MCU and USB connector are still present.  It's more for easy development than something for end users.  A switch was added that can be used to toggle between NTSC/PAL.  This board also added a CPU reset listener so we can reset hires registers when we detect a reset.  This board also has an HDMI connector so DVI is possible.

    An 'experiment' was added to this board to try out using the C64's incoming 4x color clock signal.  A jumper could be used to re-purpose the cpu reset line in to be used as a clock.  (cpu_reset_i could be a clock). This was to determine if a small cheap board could be made without the need for any oscillators, reducing cost even further.  The downside is that it would be a fixed video standard (whatever clock was on the board).  This was removed from the schematic later.

rev_2

    This is the first board that is configured to retrieve the bitstream directly from the FLASH RAM eliminating the need for the MCU, 8Mhz crystal and a number of other components that just add to the cost of the board.  All video options are possible from this board.  It also has a switch for NTSC/PAL toggle and the RW line was also hooked so this board could in theory write to DRAM. This board also listens to the reset line like rev_1.  It has an additional cfg_reset jumper pad that when brought low, will reset the eeprom.  Added the lock bits header here too.  Considering using this layout with the X4 and leaving HDMI off.

rev_3

    Essentially identical to rev_2 except it uses the BGA package (FTG256) for the SpartanX16.  Can, in theory, get 64k of video ram if we use distributed ram for mem instead of block ram.

rev_4L

    Hopefully the last large board revision.  Fixes hardware issues (luma and HDMI backfeeding).

rev_4S

    A small version that can be 'just a vicii' or an enhanced vicii but still limited in hardware features.


# Block RAM Usage

Purpose           | Size needed (bits) | Actual Size used (bits) | Ratio | Percentage
------------------|--------------------|-------------------------|-----------|-----------
VGA/DVI line buf  | 2048 * 4           | 2048 * 9 = 18432        | 18432/576432 |  3.197%
COLOR REGS        | 16 * 27            | 16 * 27 = 432           | 432/576432 | .074%
LUMA REGS         | 16 * 18            | 16 * 18 = 288           | 288/576432 | .049%
SINE WAVES        | 4096 * 9           | 4096 * 9 = 36864        | 36864/576432 | 6.395%
VIDEO RAM         | 32768 * 8          | 32768 * 9 = 294912      | 294912/576432 | 51.161%


# Luma/Phase/Amplitude values

The luma_revX.bin files are luma values for an uninitialized board. They assume the board is PAL.  Once initialized, these values are overwritten by the EEPROM values and are specific to each chip model.

The registers_ram.v also has hard coded values for luma/phase/amplitude in the case there is no configurable luma feature built into the bitstream.  These should match the 'new' 6569R3 and 6567R8 values.
