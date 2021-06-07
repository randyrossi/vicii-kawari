// Init sequence code for board with MCU.
// In this config, we use the MCU's EEPROM
// to store/retrieve settings. For chip, the MCU
// is simply setting the incoming chip_ext lines
// hi/lo depending on what chip was persisted
// in EEPROM (on MCU). We just hold reset for a
// while and then switch chip half way through.
//
// All other settings are sent via serial link
// after cclk goes high (indicating loading
// is complete by MCU) and are handled in
// registers_ram.v

// We only care about the is_reset case for
// this version of handle_persist because
// other than chip, all other registers get
// set via the serial link.
task handle_persist(input is_reset);
begin
  if (is_reset) begin
    if (internal_rst)
        rstcntr <= rstcntr + `RESET_CTR_INC;
    if (rstcntr == `RESET_CHIP_LATCH_POINT) begin
        $display("chip <= %d", chip_ext);
        chip <= chip_ext;
    end
    if (rstcntr == `RESET_LIFT_POINT) begin
	rst <= 0;
    end
  end
end
endtask
