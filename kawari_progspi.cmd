setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify
IdentifyMPM
attachflash -position 1 -spi "w25q16v"
assignfiletoattachedflash -position 1 -file "spix4_MultiBoot.mcs"
program -p 1 -dataWidth 4 -spionly -e -v -loadfpga
Quit
