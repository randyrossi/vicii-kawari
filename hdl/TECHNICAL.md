hdl/colors.bin
	24 bit RGBx (last byte not used) for all 16 colors
	Use tools/make_colors with BINARY, is_rgb, is_community to gen
	These values are used when no EEPROM config is available or
	it has not been initialized yet.

hdl/luma.bin
	6 bit luma, 8 bit phase, 4 bit ampliutude RAM init values
	These values are used when no EEPROM config is available or
	it has not been initialized yet.
	Use tools/make_luma_bin with BINARY output

hdl/sine.bin
	16 sine waves
	each full wave is 256 entries
	each entry is 9 bits
	values are centered at 256, max 511
	Use tools/chroma/Sine.java to generate
