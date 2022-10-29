# Build for Xilinx boards

Build instructions/notes.

### Generate constraints

    cd hdl
    Edit hdl/config.vh and select options (or copy from rev_X dir)
    java GenConstraints rev_X/wiring.txt config.vh > rev_X/top.ucf

## Making full Header/Golden/Multiboot images

### Generate top.prj

    TODO: The only way to create a top.prg file that works is by first
    using Xilinx ISE tool.  There seems to be no command line to do it.

### Golden image

    make clean golden

This makes kawari_golden.bit which includes the SPIx4 multiboot programming header. Golden resides at 0x000044. Multiboot header points to 0x7d000.

### Multiboot image

    make clean multiboot

This makes the kawari_multiboot.bit file.

### Making .mcs file

    make mcs

This makes spix4_MultiBoot.mcs with header + golden + multiboot.  This can be programmed to the flash device via JTAG using Impact.

### Programming a device via JTAG

    make program

Expects spix4_MultiBoot.mcs to have been made and device connected via JTAG.

### Programming a device via C64 Flash Program

Device's multiboot images can be updated directly from the C64 using demo/config/flash:

    cp kawari_multiboot.bit demo/config/flash/kawari_multiboot_#.#.bit
    cd disks/util/config/flash
    EDIT Makefile and change VERSION/SOURCE_IMG to point to the right .bit file
    make clean all

Makes C64 disks flash0.d64, flash1.d64, etc
Use LOAD "*",8,1 from flash0.d64 to flash the multiboot image.

