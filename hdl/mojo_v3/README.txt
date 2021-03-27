top_dvi.ucf

   This is a version of constraints that lets the tool place almost
   every pin except the ones that are hardwired on the mojo dev board
   plus the TMDS pins we need to test DVI.  This version can't be
   plugged into the C64 VICII socket with the HAT.  It's only purpose
   is to validate the DVI signals produce a picture.  Requires
   TEST_PATTERN to be defined to force a test pattern to be shown.
   Otherwise, you will just get a black screen.
