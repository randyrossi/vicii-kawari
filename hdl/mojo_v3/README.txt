top_dvi.ucf

   This is a version of constraints that lets the tool place almost
   every pin except the ones that are hardwired on the mojo dev board
   plus the TMDS pins we need to test DVI.  This version can't be
   plugged into the C64 VICII socket with the HAT.  It's only purpose
   is to validate the DVI signals produce a picture.  Requires registers.v
   to be modified to 'force' a blue / light blue screen by hard coding
   ec, bc0 and den + now allowing them to be set.
