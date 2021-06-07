// Init sequence code for direct EEPROM config
//
// Responsible for bringing the system out of reset after
// one pass through all 256 addresses of EEPROM containing
// saved settings. Can also be used to write a single
// value back to eeprom.
//
// Usage:
//
//    if (clk_div[2]) begin
//       eeprom_state <= `EEPROM_WRITE
//       eeprom_w_addr <= 8'h2e
//       state_ctr <= 15'd0;
//    end
//
// Note: When chip register is set, clock will potentially
// change as this controls the mux.

task handle_persist(input is_reset);
    begin
`ifdef CMOD_BOARD
        // For test harness using CMOD-A7.
        // Use button0 to write the into next address (start with fc)
        // Use button1 to reset back to read mode
        if (clk_div[2] && btn[0] && eeprom_state != `EEPROM_WRITE) begin
            // Need to trigger write on [2] so [3] will pick up first state
            eeprom_state <= `EEPROM_WRITE;
            eeprom_w_addr <= wreg;
            wreg <= wreg + 1;
            state_ctr <= 15'd0;
        end
        else if (clk_div[2] && btn[1] && eeprom_state == `EEPROM_IDLE) begin
            eeprom_state <= `EEPROM_READ;
        end
`endif
`ifdef SIMULATOR_BOARD
        // Uncomment to test WRITE state in sumulator.
        /*if (clk_div[2] && !test_init) begin
           eeprom_state <= `EEPROM_WRITE;
           eeprom_w_addr <= 8'hfc;
           state_ctr <= 15'd0;
           test_init <= 1'b1;
        end */
`endif

        clk_div <= {clk_div[2:0] , clk_div[3]};

        // Once state_ctr reaches 16384, we're done cycling through
        // 256 register values.  Even for a write of a single register, we
        // still cycle through all 256 and just issue a write for the one
        // register that matches the target.
        //
        // D - device latches on rising edge of C
        // Q - we read on rising edge of C
        //
        // We set D,S on clk8_HIGH_div[3] to be ready by next C_HIGH edge on div[0]
        // We read Q on clk8_LOW_div[0] which is C_HIGH edge

        // Handle READs on HIGH edge of C
        if (clk_div[0] && !state_ctr[14])
        begin
            if (~clk8) begin
                case (eeprom_state)
                    `EEPROM_READ:
                        if (state_val >= 25 && state_val <= 32) begin
                            // Shift in data from EEPROM - 8 bits
                            data <= { data[6:0], Q };
                        end
                    default:
                        ;
                endcase
            end
        end
        // Transition state counter so it becomes valid on [3]
        else if (clk_div[2] && !state_ctr[14])
        begin
            if (~clk8)
                state_ctr <= state_ctr + 15'b1;
        end
        else if (clk_div[2] && state_ctr[14]) begin
            case (eeprom_state)
                `EEPROM_READ:
                if (is_reset) begin
                   $display("rst <= 0, chip restored");
                   // First pass was to set chip during reset
                   rst <= 0;
                   // Now do another iteration to set registers
                   state_ctr <= 15'd0;
                   magic <= 0; // reset our magic counter again
                end else begin
                   $display("registers restored");
		   eeprom_state <= `EEPROM_IDLE;
                end
                `EEPROM_WRITE:
		   eeprom_state <= `EEPROM_IDLE;
                default:
                   ;
            endcase
        end
        // Set C,D,S so they become valid on [0] for device
        else if (clk_div[3] && !state_ctr[14])
        begin
            clk8 <= ~clk8;
            if (~clk8) begin
                // clk8 is LOW and about to set C LOW
                case (eeprom_state)
                    `EEPROM_READ:
                        if (state_val >= 1 && state_val <= 33)
                            // Include 33 for last C pulse low
                            C <= clk8;
                        else if (state_val == 34) begin
                            $display("GOT %d for ADDR %d (magic %d)",
                                     data, addr_lo, magic);
                            case (addr_lo)
                                8'hfc:
                                    if (data == 8'd86) // V
                                        magic <= magic + 1;
                                8'hfd:
                                    if (data == 8'd73) // I
                                        magic <= magic + 1;
                                8'hfe:
                                    if (data == 8'd67) // C
                                        magic <= magic + 1;
                                8'hff:
                                    if (data == 8'd50) // 2
                                        magic <= magic + 1;
                                default:
                                    ;
                            endcase
                            // TODO: Set the register with the data but only if
                            // magic was found.  Only chip for is_reset and
			    // anything else for !is_reset
                        end
                    `EEPROM_WRITE:
                        if (addr_lo == eeprom_w_addr[7:0])
                        begin
                            if (state_val >= 1 && state_val <= 9)
                                // Extra after last bit to bring C LOW again
                                C <= clk8;
                            else if (state_val > 10 && state_val <= 43)
                                // Extra after last bit to bring C LOW again
                                C <= clk8;
                        end
                     default:
                        ;
                endcase
            end else begin
                // clk8 is HIGH and about to set C HIGH
                case (eeprom_state)
                    `EEPROM_READ:
                        if (state_val == 0) begin
                            S <= 0;
                            C <= 1;
                            instr <= 8'b00000011; // READ
                            addr <= {8'b0, addr_lo};
                        end
                        else if (state_val >= 1 && state_val <= 8) begin
                            // Shift in the instruction - 8 bits
                            D <= instr[7];
                            C <= clk8;
                            instr <= {instr[6:0], 1'b0};
                        end
                        else if (state_val >= 9 && state_val <= 24) begin
                            // Shift in the address - 16 bits
                            D <= addr[15];
                            addr <= {addr[14:0], 1'b0};
                            C <= clk8;
                        end
                        else if (state_val >= 25 && state_val <= 32) begin
                            // Extra state for last pulse to go low again
                            C <= clk8;
                        end
                        else if (state_val == 33) begin
                            S <= 1;
                            C <= 1;
                        end

                    `EEPROM_WRITE:
                        // If we hit the write address, then write now.
                        if (addr_lo == eeprom_w_addr[7:0])
                        begin
                            if (state_val == 0) begin
                                S <= 0;
                                C <= 1;
                                instr <= 8'b00000110; // WREN
                                // TODO: Set the persist busy flag to true here
                            end
                            else if (state_val >= 1 && state_val <= 8) begin
                                // Shift in the instruction - 8 bits
                                D <= instr[7];
                                C <= clk8;
                                instr <= {instr[6:0], 1'b0};
                            end
                            else if (state_val == 9) begin
                                S <= 1;
                                C <= 1;
                            end
                            else if (state_val == 10) begin
                                S <= 0;
                                C <= 1;
                                instr <= 8'b00000010; // WRITE
                                addr <= {8'b0, addr_lo};
                                case (addr_lo)
                                    8'hfc:
                                        data <= 8'd86; // V
                                    8'hfd:
                                        data <= 8'd73; // I
                                    8'hfe:
                                        data <= 8'd67; // C
                                    8'hff:
                                        data <= 8'd50; // 2
                                    default:
                                        data <= 8'd55; // TODO get from register
                                endcase
                            end
                            else if (state_val >= 11 && state_val <= 18) begin
                                // Shift in the instruction - 8 bits
                                D <= instr[7];
                                C <= clk8;
                                instr <= {instr[6:0], 1'b0};
                            end
                            else if (state_val >= 19 && state_val <= 34) begin
                                // Shift in the address - 16 bits
                                D <= addr[15];
                                addr <= {addr[14:0], 1'b0};
                                C <= clk8;
                            end
                            else if (state_val >= 35 && state_val <= 42) begin
                                // Shift out the data - 8 bits
                                D <= data[7];
                                C <= clk8;
                                data <= {data[6:0], 1'b0};
                            end
                            else if (state_val == 43) begin
                                C <= 1;
                                S <= 1;
                                $display("WROTE for ADDR %d", addr_lo);
                            end
                        end
                    default:
                        ;
                endcase
            end
        end
    end
endtask
