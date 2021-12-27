
Model                  |SA        |SB        |LD
-----------------------|----------|----------|-----------
FPGA                   |LX4-QTG144|LX9-QTG144|LX16-FTG256
Board                  |S         |S         |L
Variant                |A         |B         |D
Video RAM              |N/A       |64K       |64K
Luma/Chroma            |Yes       |Yes       |Yes
Flash updates from C64 |No        |Yes       |Yes
New Video Modes        |No        |Yes       |Yes
Analog RGB             |No        |No        |Yes
Fixed to NTSC or PAL   |Yes       |N/A       |N/A
Switchable NTSC/PAL    |No        |Yes       |Yes
HDMI                   |No        |No        |Yes
Saveable Config        |No        |Yes       |Yes
Detect Reset           |N/A       |Yes       |Yes
R/W Experiment         |No        |No        |Yes
Old chips?             |No        |Yes       |Yes
BOM Estimate           |$24 USD   |$35 USD   |
PCB Manuf.             |  3 USD   |  3 USD   |
Assembly Estimate      |  5 USD   |  5 USD   |
Total Cost Manuf.      |$32 USD   |$43 USD   |
Retail Est (2x)        |$64 USD   |$86 USD   |

# Feature Descriptions

## Luma/Chroma 
PCB is capable of Luma/Chroma based video (i.e. Composite or S-Video through the video out jack)

## Flash from C64
PCB firmware can be updated from the C64 using a flash utility disk

## New Video Modes
PCB can enable new video modes (i.e. 80 column mode).

## Analog RGB
Analog RGB header is present and can drive a VGA or RGB monitor. 

## Fixed to NTSC or PAL
PCB must be configured as NTSC or PAL but cannot switch between standards. Motherboard clock must be working and match selected video standard.

## Switchable NTSC/PAL
PCB can be told to boot as either 6567 (NTSC) or 6569 (PAL) (either by hardware switch or software selection). Motherboard clock is optional.

## Old Chips
PCB can be configured to act as older NTSC and PAL models 6567R56A or 6569R1.

## HDMI
PCB can output DVI over a HDMI connector (no audio).

## Detect Reset
PCB can optionally connect to RESET line of motherboard and restore colors to default values after soft reset. Only matters if the board can dynamically configure colors or other video settings.

## Saveable Config
PCB can remember changes to palette and other video settings between cold boots.


# Configuration Notes

## Model A

Spartan 6 LX4. VICII replacement only. Acts as either 6567 or 6569 but not both. EEPROM is unpopulated. Right most pin of header must be set by jumper to match the motherboard's clock. CFG1,CFG2,CFG3 have no function. There are no on-board oscillators.

## Model B
Spartan 6 LX9. EEPROM is populated. Right most pin of header must be set to match the motherboard's clock. CFG1, CFG2,CFG3 used to control SPI access, Extensions Access (resp.) and persistence. There are no on-board oscillators. This adds extra video modes and configurable video settings.

## Model C
Spartan 6 LX9. EEPROM is populated. HDMI connector, TVS diodes and anything else HDMI related is unpopulated.  Both oscillators populated.  CFG1, CFG2, CFG3 used to control SPI access, Extensions Access (resp.) and persistence.  This model adds analog RGB and the ability to be either standard.

## Model D
Spartan 6 LX16. Same as model C but HDMI components are populated. This model adds HDMI.

