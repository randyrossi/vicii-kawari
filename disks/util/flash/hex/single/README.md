# Notes

MAIN and MAINLD (Spartan builds) are in hex format but .mcs files are generated using the .bit (binary) file.  

Those were converted like this:
hexdump -v -e'/1  "%02X\n"' some.14.bit > some.hex

And then checked in here.

Get back the original .bit using multi_hex_to_bin

For efinix, these .hex files are simply copied from outflow directory.
See copy_to_single.sh utility script in boards dir.
