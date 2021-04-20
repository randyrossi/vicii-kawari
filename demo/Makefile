all: demo

demo:
	truncate -s 174848 demo.d64
	c1541 -attach demo.d64 -format "vicii-kawaridemo",0
	c1541 -attach demo.d64 -write config/config.prg config
	c1541 -attach demo.d64 -write ../asm/grogu.prg img-grogu
	c1541 -attach demo.d64 -write ../asm/field.prg img-field
	c1541 -attach demo.d64 -write ../asm/horse.prg img-horse
	c1541 -attach demo.d64 -write ../asm/hires80.prg 80col-51200
	c1541 -attach demo.d64 -write ../asm/colorpal.prg raster-49152
	c1541 -attach demo.d64 -write ../prg/palette.prg palette-test
	c1541 -attach demo.d64 -write ../prg/adventureland80.prg adventureland80
	c1541 -attach demo.d64 -list

clean:
	rm -f demo.d64
