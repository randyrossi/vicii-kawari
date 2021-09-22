setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify
IdentifyMPM
attachflash -position 1 -spi "w25q16v"
assignfiletoattachedflash -position 1 -file "build/spix4_MultiBoot_%GOLDEN_MAJOR%_%GOLDEN_MINOR%-%MULTIBOOT_MAJOR%_%MULTIBOOT_MINOR%.mcs"
program -p 1 -dataWidth 4 -spionly -e -v -loadfpga
Quit
