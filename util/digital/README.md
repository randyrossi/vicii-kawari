# What is this?

This is a digital sample player for the C64 that uses a 4:1 compression scheme.  It was adapted from [A 48k digital music player for the Commodore 64](http://brokenbytes.blogspot.com/2018/03/a-48khz-digital-music-player-for.html).  This version uses much slower sample rates so the timing aspect of playback is not critical like it is with the 48k version.  Examples are given for 8k, 10k and 14k rates.

# Dependencies

pip3 install -U scikit-learn
sudo apt-get install sndfile-programs

# How it works

Compressed samples are loaded into memory between 0x0f00 and 0xd000, so the maximum compressed.bin size is: 0xd000-0x0f00 = 49408 bytes

This means the max uncompressed size will be 49408 * 4 = 197632

    @8k : 24.7 seconds
    @10k : 19.7 seconds
    @14k : 14.1 seconds

Recordings must be in .aif format (unsigned 8-bit samples).  If your recording falls short of 197632 bytes, then you will want the playback to stop before the upper byte of the sample address hits $d0. Calculate the end address and change the CMP #$d0 accordingly. For example, if your compressed.bin is only 47000 bytes, then 0x0f00 + 47000 = 0xc698 so CMP #$d0 would change to CMP #$c6. (The nearest 256 byte boundary without going over the end.)  You must also give the new maximum uncompressed file size to the compress.py program (below).

There is a 1K codepage constructed via compress.py.  Each byte in the compressed.bin file represents 4 samples as determined by the code page.

Each sid chip type (6581 / 8580) has a different sound table that converts a desired output level to d418 value.  By default, the sound.asm assumes 6581.  It does not automatically detect the sound chip type.  You have to change the table manually in the source.

For a description on how the compression works, see the link above.

# Create

    Create your 8k, 10k, or 14k .wav file using audacity.
    Convert it to .aif using "sndfile-convert -pcmu8 input.wav output.aif" or equivalent
    Run python3 compress.py <filename> [max_bytes_uncompressed]
    EDIT sound.asm and set number of noops in delay routine to match your rate (these are approximate for PAL systems, you will not get exactly your sample rate)
    EDIT sound.asm and select either 6581 or 8580 sid table
    make

sound.prg will play your sample on a C64
