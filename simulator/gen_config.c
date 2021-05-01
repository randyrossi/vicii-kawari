#include <stdio.h>
#include <stdlib.h>

int for_comp = 0;

typedef void (*def_func)();

void test_pattern_0() { printf ("`define TEST_PATTERN 1\n"); }
void have_color_clocks_0() { printf ("`define HAVE_COLOR_CLOCKS 1\n"); }
void have_composite_encoder_0() { printf ("`define HAVE_COMPOSITE_ENCODER 1\n"); }
void gen_luma_chroma_0() { printf ("`define GEN_LUMA_CHROMA 1\n"); }
void configurable_lumas_0() { printf ("`define CONFIGURABLE_LUMAS 1\n"); }
void configurable_timing_0() { printf ("`define CONFIGURABLE_TIMING 1\n"); }
void average_lumas_0() { printf ("`define AVERAGE_LUMAS 1\n"); }
void have_serial_link_0() { printf ("`define HAVE_SERIAL_LINK 1\n"); }
void need_rgb_0() { printf ("`define NEED_RGB 1\n"); }
void gen_rgb_0() { printf ("`define GEN_RGB 1\n"); need_rgb_0(); }
void with_dvi_0() { printf ("`define WITH_DVI 1\n"); need_rgb_0(); }
void hires_modes_0() { printf ("`define HIRES_MODES 1\n"); }
void hide_sync_0() { printf ("`define HIDE_SYNC 1\n"); }

void test_pattern_1() { printf ("-DTEST_PATTERN=1 "); }
void have_color_clocks_1() { printf ("-DHAVE_COLOR_CLOCKS=1 "); }
void have_composite_encoder_1() { printf ("-DHAVE_COMPOSITE_ENCODER=1 "); }
void gen_luma_chroma_1() { printf ("-DGEN_LUMA_CHROMA=1 "); }
void configurable_lumas_1() { printf ("-DCONFIGURABLE_LUMAS=1 "); }
void configurable_timing_1() { printf ("-DCONFIGURABLE_TIMING=1 "); }
void average_lumas_1() { printf ("-DAVERAGE_LUMAS=1 "); }
void have_serial_link_1() { printf ("-DHAVE_SERIAL_LINK=1 "); }
void need_rgb_1() { printf ("-DNEED_RGB=1 "); }
void gen_rgb_1() { printf ("-DGEN_RGB=1 "); need_rgb_1(); }
void with_dvi_1() { printf ("-DWITH_DVI=1 "); need_rgb_1(); }
void hires_modes_1() { printf ("-DHIRES_MODES=1 "); }
void hide_sync_1() { printf ("-DHIDE_SYNC=1 "); }

void main(int argc, char* argv[]) {

	def_func test_pattern;
	def_func with_dvi;
	def_func have_color_clocks;
	def_func have_composite_encoder;
	def_func gen_luma_chroma;
	def_func configurable_lumas;
	def_func configurable_timing;
	def_func average_lumas;
	def_func have_serial_link;
	def_func need_rgb;
	def_func gen_rgb;
	def_func hires_modes;
	def_func hide_sync;

    char defines[] = {
    };

    int config = -1;
    if (argc > 1)
       config = atoi(argv[1]);

    test_pattern = test_pattern_0;
    with_dvi = with_dvi_0;
    have_color_clocks = have_color_clocks_0;
    have_composite_encoder = have_composite_encoder_0;
    gen_luma_chroma = gen_luma_chroma_0;
    configurable_lumas = configurable_lumas_0;
    configurable_timing  = configurable_timing_0;
    average_lumas = average_lumas_0;
    have_serial_link = have_serial_link_0;
    need_rgb = need_rgb_0;
    gen_rgb = gen_rgb_0;
    hires_modes = hires_modes_0;
    hide_sync = hide_sync_0;

    if (argc > 2) {
        test_pattern = test_pattern_1;
        with_dvi = with_dvi_1;
        have_color_clocks = have_color_clocks_1;
        have_composite_encoder = have_composite_encoder_1;
        gen_luma_chroma = gen_luma_chroma_1;
        configurable_lumas = configurable_lumas_1;
        configurable_timing  = configurable_timing_1;
        average_lumas = average_lumas_1;
        have_serial_link = have_serial_link_1;
        need_rgb = need_rgb_1;
        gen_rgb = gen_rgb_1;
        hires_modes = hires_modes_1;
        hide_sync = hide_sync_1;
    }
    else {
       printf ("`define VERSION_MAJOR 4'd0\n");
       printf ("`define VERSION_MINOR 4'd2\n");
       printf ("`define SIMULATOR_BOARD 1\n");
    }

    switch (config) {
	    case 0:
		    have_color_clocks();
		    gen_luma_chroma();
		    have_serial_link();
		    gen_rgb();
		    hires_modes();
		    break;
	    case 1:
		    // Use this config for generating test results
		    // since it hides sync lines.
		    have_color_clocks();
		    gen_luma_chroma();
		    have_serial_link();
		    with_dvi();
		    hires_modes();
		    hide_sync();
	    case 2:
		    have_color_clocks();
		    gen_luma_chroma();
		    have_serial_link();
		    break;
	    case 3:
		    with_dvi();
		    gen_rgb();
		    break;
	    case 4:
		    test_pattern();
		    break;
	    case 5:
		    have_color_clocks();
		    have_composite_encoder();
		    break;
	    case 6:
		    have_color_clocks();
		    gen_luma_chroma();
		    gen_rgb();
		    configurable_lumas();
		    configurable_timing();
		    break;
	    case 7:
		    have_color_clocks();
		    gen_luma_chroma();
		    average_lumas();
		    break;
	    default:
		    break;

    }
}
