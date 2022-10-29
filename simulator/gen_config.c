// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

#include <stdio.h>
#include <stdlib.h>

#define FOR_CONFIG 0
#define FOR_COMPILE 1

struct _Define {
   int id;
   int defined_for_config;
   int defined_for_compile;
   char *name;
};

typedef struct _Define Define;

enum DefineValues {
   WITH_EXTENSIONS = 0,  // can activate extensions via $d03f 'V','I','C','2'
   WITH_RAM,             // use block RAM for video RAM
   TEST_PATTERN,         // show a test pattern (for debugging)
   GEN_LUMA_CHROMA,      // output S/LUM and CHROMA signals
   CONFIGURABLE_RGB,     // has registers to change color palette (RGB)
   CONFIGURABLE_LUMAS,   // has registers to change color palette (LUMA/PHASE/AMP)
   CONFIGURABLE_TIMING,  // has registers to change VGA/DVI timing (debugging only)
   HAVE_LUMA_SINK,       // has proper luma current sink for proper sync voltage level
   WITH_SPI,             // include spi CLK, MISO, MOSI lines
   HAVE_EEPROM,          // include EEPROM_S and eeprom save/restore logic
   HAVE_FLASH,           // include FLASH_S and flash support logic
   NEED_RGB,             // has internal RGB regs (required for DVI)
   GEN_RGB,              // include signals for analog RGBHV header
   WITH_DVI,             // include DVI encoder and differential signals
   HIRES_MODES,          // has extra hires modes available
   HIDE_SYNC,            // (for simulator) hide sync signals from view
   WITH_64K,             // select 64K for ram
   WITH_MATH,            // include math registers
   WITH_4K,              // select 4K for ram
   WITH_BLITTER,         // include blitter
};

Define defines[] = {
  {WITH_EXTENSIONS ,0,0,"WITH_EXTENSIONS"},
  {WITH_RAM ,0,0,"WITH_RAM"},
  {TEST_PATTERN ,0,0,"TEST_PATTERN"},
  {GEN_LUMA_CHROMA ,0,0,"GEN_LUMA_CHROMA"},
  {CONFIGURABLE_RGB ,0,0,"CONFIGURABLE_RGB"},
  {CONFIGURABLE_LUMAS ,0,0,"CONFIGURABLE_LUMAS"},
  {CONFIGURABLE_TIMING ,0,0,"CONFIGURABLE_TIMING"},
  {HAVE_LUMA_SINK ,0,0,"HAVE_LUMA_SINK"},
  {WITH_SPI ,0,0,"WITH_SPI"},
  {HAVE_EEPROM ,0,0,"HAVE_EEPROM"},
  {HAVE_FLASH ,0,0,"HAVE_FLASH"},
  {NEED_RGB ,0,0,"NEED_RGB"},
  {GEN_RGB ,0,0,"GEN_RGB"},
  {WITH_DVI ,0,0,"WITH_DVI"},
  {HIRES_MODES ,0,0,"HIRES_MODES"},
  {HIDE_SYNC ,0,0,"HIDE_SYNC"},
  {WITH_64K ,0,0,"WITH_64K"},
  {WITH_MATH ,0,0,"WITH_MATH"},
  {WITH_4K ,0,0,"WITH_4K"},
  {WITH_BLITTER ,0,0,"WITH_BLITTER"},
};

void printcfg(int d, int def) {
  if (d == FOR_CONFIG) {
     if (!defines[def].defined_for_config) {
       printf ("`define %s 1\n", defines[def].name); 
       defines[def].defined_for_config = 1;
     }
  } else {
    if (!defines[def].defined_for_compile) {
      printf ("-D%s=1 ", defines[def].name); 
      defines[def].defined_for_compile = 1;
    }
  }
}

void with_ext(int d) { printcfg(d, WITH_EXTENSIONS); }
void with_ram(int d) { printcfg(d, WITH_RAM); with_ext(d); }
void test_pattern(int d) { printcfg(d, TEST_PATTERN); }
void gen_luma_chroma(int d) { printcfg(d, GEN_LUMA_CHROMA); }
void configurable_rgb(int d) { printcfg(d, CONFIGURABLE_RGB);with_ext(d); }
void configurable_lumas(int d) { gen_luma_chroma(d); printcfg(d, CONFIGURABLE_LUMAS);with_ext(d); }
void configurable_timing(int d) { printcfg(d, CONFIGURABLE_TIMING); with_ext(d); }
void luma_sink(int d) { printcfg(d, HAVE_LUMA_SINK); }
void with_spi(int d) { printcfg(d, WITH_SPI);with_ext(d); }
void have_eeprom(int d) { printcfg(d, HAVE_EEPROM);with_spi(d); }
void have_flash(int d) { printcfg(d, HAVE_FLASH);with_spi(d); with_ram(d); }
void need_rgb(int d) { printcfg(d, NEED_RGB); }
void gen_rgb(int d) { printcfg(d, GEN_RGB); need_rgb(d); }
void with_dvi(int d) { printcfg(d, WITH_DVI);need_rgb(d); }
void hires_modes(int d) { printcfg(d, HIRES_MODES);with_ext(d); with_ram(d); }
void hide_sync(int d) { printcfg(d, HIDE_SYNC); }
void with_64k(int d) { printcfg(d, WITH_64K);  with_ram(d), with_ext(d); }
void with_4k(int d) { printcfg(d, WITH_4K);  with_ram(d), with_ext(d); }
void with_math(int d) { printcfg(d, WITH_MATH); with_ext(d); }
// NOTE: Blitter only works with 64k a.t.m.
// TODO: Fix this and also math reg requirement.
void with_blitter(int d) { printcfg(d, WITH_BLITTER); hires_modes(d); with_64k(d); with_math(d);}

int main(int argc, char* argv[]) {

    int config = -1;
    if (argc > 1)
       config = atoi(argv[1]);

    int d = FOR_CONFIG;
    if (argc > 2) {
        d = FOR_COMPILE;
       printf ("-DSIMULATOR_BOARD=1 ");
    } else {
       printf ("`define VERSION_MAJOR 8'd0\n");
       printf ("`define VERSION_MINOR 8'd2\n");
       printf ("`define SIMULATOR_BOARD 1\n");
       printf ("`define VARIANT_NAME1 8'h53  // S\n");
       printf ("`define VARIANT_NAME2 8'h49  // I\n");
       printf ("`define VARIANT_NAME3 8'h4D  // M\n");
       printf ("`define VARIANT_NAME4 8'h00");
       printf ("`define VARIANT_SUFFIX_1 8'd0\n");
       printf ("`define VARIANT_SUFFIX_2 8'd0\n");
       printf ("`define VARIANT_SUFFIX_3 8'd0\n");
       printf ("`define VARIANT_SUFFIX_4 8'd0\n");
    }

    switch (config) {
            // !!! When using simulator for cycle by cycle stepping,
            // make sure to turn OFF RGB/HIRES so that native pixel sequencer
            // values are used.
	    case 0:
                    // The minimal config. Just a VIC-II.
		    gen_luma_chroma(d);
                    // Add these to test hires modes in simulator
                    //configurable_rgb(d);
                    //hires_modes(d);
                    //gen_rgb(d);
                    //with_64k(d);
                    //with_blitter(d);
		    break;
	    case 1:
		    // Use this config for generating test results
		    // since it hides sync lines.
		    gen_luma_chroma(d);
		    luma_sink(d);
		    have_flash(d);
		    with_dvi(d);
		    hires_modes(d);
		    hide_sync(d);
		    break;
	    case 2:
		    gen_luma_chroma(d);
		    have_eeprom(d);
		    break;
	    case 3:
		    with_dvi(d);
		    gen_rgb(d);
		    break;
	    case 4:
		    test_pattern(d);
		    break;
	    case 5:
                    // Test we don't have to output RGB to have DVI
		    with_dvi(d);
		    break;
	    case 6:
		    gen_rgb(d);
		    configurable_rgb(d);
		    configurable_lumas(d);
		    configurable_timing(d);
                    with_64k(d);
		    break;
	    case 7:
	            // Just a vic replacement config. No extensions.
		    gen_luma_chroma(d);
		    luma_sink(d);
		    break;
	    case 8:
	            // Extensions but no other optional features enabled.
		    gen_luma_chroma(d);
		    with_ext(d);
                    with_math(d);
		    break;
	    case 9:
		    with_4k(d);
		    break;
	    case 10:
		    gen_rgb(d);
                    with_64k(d);
                    with_blitter(d);
		    break;
	    default:
		    break;

    }
    return 0;
}
