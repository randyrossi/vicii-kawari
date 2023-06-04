all: subdirs

subdirs:
	$(MAKE) -C lumatest
	$(MAKE) -C rgbtest
	$(MAKE) -C mathtest
	$(MAKE) -C regtest
	$(MAKE) -C newdev
	$(MAKE) -C copyfill
	$(MAKE) -C dma
	$(MAKE) -C blitter

clean:
	$(MAKE) -C lumatest clean
	$(MAKE) -C rgbtest clean
	$(MAKE) -C mathtest clean
	$(MAKE) -C regtest clean
	$(MAKE) -C newdev clean
	$(MAKE) -C copyfill clean
	$(MAKE) -C dma clean
	$(MAKE) -C blitter clean
