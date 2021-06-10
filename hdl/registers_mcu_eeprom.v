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

  // Always reset start flag. write_ram may flip this true if a register was
  // changed and it should be persisted.
  tx_new_data_start = 1'b0;

  // Handle incoming serial commands.
  // This is guaranteed to go back low on next tick.
  if (rx_new_data_4x) begin
     rx_new_data_ff <= ~rx_new_data_ff;
     if (~rx_new_data_ff) begin
        // Config byte 1
        rx_cfg_change_1 <= rx_data_4x;
     end else begin
        // Config byte 2
        write_ram(
                  .overlay(1'b1),
                  .ram_lo(rx_cfg_change_1), // 1st byte from rx
                  .ram_hi(8'b0), // ignored
                  .ram_idx(8'b0), // ignored
                       .data(rx_data_4x), // 2nd byte from rx
                        .from_cpu(1'b0), // this is from the MCU
                       .do_tx(1'b0) // no tx
        );
     end
  end

end
endtask

// When transmitting config changes over serial tx, we transmit
// two bytes for every register change. The first is the register
// number and the second is the value. The tx_new_data strobe
// is separated for these two bytes by ~2048 dot4x ticks which gives
// enough time for the serial module to transmit a byte before
// transmitting the next one. The tx strobe is held high for two
// dot4x ticks.  2048 dot 4x ticks = 64 dot clock periods.  Worst
// case dot clock period is approx 122.5 nanoseconds.  So that's
// 7840 nano seconds for 7.8 us to transmit a byte.  Therefore, when
// the 6502 is making register changes with the persistence flag
// turned on, it should not change registers faster than 15.6us
// which seems good enough for BASIC to stay away from.  6502
// assembly might not work though.  This start value (2048) can
// probably be reduced but I haven't found the lowest value possible.
`ifdef HAVE_MCU_EEPROM
always @(posedge clk_dot4x)
begin
   // Signal from other process blocks to start the serial transmission.
   if (tx_new_data_start) begin
       tx_new_data_ctr <= 11'd2047;
   end

   if (tx_new_data_ctr > 0)
       tx_new_data_ctr <= tx_new_data_ctr - 11'b1;

   if (tx_new_data_ctr == 1 || tx_new_data_ctr == 2) begin
      tx_new_data_4x <= 1'b1;
      tx_data_4x <= tx_cfg_change_2;
   end else if (tx_new_data_ctr == 2046 || tx_new_data_ctr == 2047) begin
      tx_new_data_4x <= 1'b1;
      tx_data_4x <= tx_cfg_change_1;
   end else
      tx_new_data_4x <= 1'b0;
end
`endif
