all: demo

demo:
	c1541 -attach demo.d64 -format "vicii-kawaridemo",0
	c1541 -attach demo.d64 -write ../prg/config.prg config
	c1541 -attach demo.d64 -write ../asm/grogu.prg img-grogu
	c1541 -attach demo.d64 -write ../asm/field.prg img-field
	c1541 -attach demo.d64 -write ../asm/horse.prg img-horse
	c1541 -attach demo.d64 -write ../asm/hires80.prg hires80
	c1541 -attach demo.d64 -write ../asm/colorpal.prg raster
	c1541 -attach demo.d64 -write ../prg/palette.prg palette-test
	c1541 -attach demo.d64 -list
