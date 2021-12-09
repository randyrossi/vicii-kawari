// Init sequence code for board with no EEPROM.

// We only care about the is_reset case.
task handle_persist(input is_reset);
    if (is_reset)
    begin
        if (internal_rst)
            rstcntr <= rstcntr + `RESET_CTR_INC;
        if (rstcntr == `RESET_LIFT_POINT) begin
            chip <= {chip[1], standard_sw ? chip[0] : ~chip[0]};
            rst <= 0;
        end
    end
endtask
