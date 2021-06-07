// Init sequence code for board with no EEPROM.

// We only care about the is_reset case since
// the only register we ever set is rst.
task handle_persist(input is_reset);
  if (is_reset)
  begin
    if (internal_rst)
        rstcntr <= rstcntr + `RESET_CTR_INC;
    if (rstcntr == `RESET_LIFT_POINT)
        rst <= 0;
  end
endtask
