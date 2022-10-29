all: subdirs

subdirs:
	$(MAKE) -C lumatest
	$(MAKE) -C rgbtest
	$(MAKE) -C mathtest
	$(MAKE) -C regtest
	$(MAKE) -C newdev

clean:
	$(MAKE) -C lumatest clean
	$(MAKE) -C rgbtest clean
	$(MAKE) -C mathtest clean
	$(MAKE) -C regtest clean
	$(MAKE) -C newdev clean
