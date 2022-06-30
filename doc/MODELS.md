# Feature / PCB Design Matrix

PCB Design             |Kawari-Large|Kawari-Mini |Kawari-POV|
-----------------------|------------|------------|----------|
Luma/Chroma            |Yes         |Yes         |Yes       |
Extra RAM              |64K         |64K         |No        |
Flash updates from C64 |Yes         |Yes         |Yes       |
New Video Modes        |Yes         |Yes         |No        |
Detect Reset           |Yes         |No          |No        |
Analog RGB             |Yes         |No          |No        |
NTSC/PAL               |Switch      |Switch      |Fixed     |
Jumper Config MB Clk   |Yes         |Yes         |Yes       |
HDMI                   |Yes         |No          |No        |
Saveable Config        |Yes         |Yes         |No        |
Old chips?             |Yes         |Yes         |No        |
Current Draw           |~180ma      |TBD         |TBD       |
Variants               |LD,LG       |LH          |LF        |

# Feature Descriptions

## Luma/Chroma 
PCB is capable of Luma/Chroma based video (i.e. Composite or S-Video through the video out jack)

## Flash from C64
PCB firmware can be updated from the C64 using a flash utility disk

## New Video Modes
PCB can enable new video modes (i.e. 80 column mode)

## Analog RGB
Analog RGB header is present and can drive a VGA or RGB monitor.

## NTSC/PAL
JP Fixed : PCB must be configured as NTSC or PAL but cannot switch between standards. Motherboard clock must be working.

Switch : PCB can be told to boot as either 6567 (NTSC) or 6569 (PAL) (either by hardware switch or software selection). Motherboard clock is optional.

## Jumper Config MB Clk
PCB can be configured via jumper to use the mother board clock for either NTSC or PAL. (Used to avoid out of phase issue with some carts that use pin 6.)

## Old Chips
PCB can be configured to act as older NTSC and PAL models 6567R56A or 6569R1.

## HDMI
PCB can output DVI over a HDMI connector (no audio).

## Detect Reset
PCB can optionally connect to RESET line of motherboard.  This will restore colors to default values and turn off hires video modes after a soft reset.

## Saveable Config
PCB can remember changes to palette and other video settings between cold boots.
