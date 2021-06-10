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
                        // 25-32 : DATA 8 bit value
                        if (state_val >= 25 && state_val <= 32)
                            data <= { data[6:0], Q };
                    `EEPROM_WAIT:
                        // 9-16 : STATUS 8 bit value
                        if (state_val >= 9 && state_val <= 16)
                            status <= { status[6:0], Q };
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
            // End of state
            case (eeprom_state)
                `EEPROM_READ:
                if (is_reset) begin
                   $display("rst <= 0, chip restored");
                   // First pass was to set chip during reset
                   rst <= 0; // out of reset
                   // Now do another iteration to set registers
		   // so leave eeprom_state set to EEPROM_READ
                   state_ctr <= 15'd0;
                   magic <= 0; // reset our magic counter again
                end else begin
                   $display("registers restored");
		   eeprom_state <= `EEPROM_IDLE;
                end
		`EEPROM_WRITE: begin
                   // Now poll status reg
		   eeprom_state <= `EEPROM_WAIT;
                   state_ctr <= 15'd0;
                end
                `EEPROM_WAIT:
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
                        // 0 : setup
			// 1-8 : 8 bit instruction
			// 9-24 : 16 bit address
			// 25-32 : 8 bit value read
			// 33 : extra for C to go low again
                        if (state_val >= 1 && state_val <= 33)
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

                            // Only restore settings if we have magic
                            if (magic == 4) begin
                              // For 2nd pass, write to registers
                              if (!is_reset)
                                write_ram(
                                  .overlay(1'b1),
                                  .ram_lo(addr_lo),
                                  .ram_hi(8'b0), // ignored
                                  .ram_idx(8'b0), // ignored
                                  .data(data),
                                  .from_cpu(1'b0), // this is from the EEPROM
                                  .do_tx(1'b0) // no tx
                                );
                              // For 1st pass, set chip (during reset) so
                              // everything inits to the right chip model
                              else if (addr_lo == `EXT_REG_CHIP_MODEL) begin
                                 chip <= data[1:0];
                              end
                            end
                        end
                    `EEPROM_WRITE:
                        if (addr_lo == eeprom_w_addr[7:0])
                        begin
                            // 0 : setup
                            // 1-8 : 8 bit instruction
			    // 9 : extra for C to go low again
                            if (state_val >= 1 && state_val <= 9)
                                C <= clk8;
                            // 10 : setup
			    // 11-18 : 8 bit instruction
			    // 19-34 : 16 bit address
			    // 35-42 : 8 bit value
			    // 43 : extra for C to go low again
                            if (state_val >= 1 && state_val <= 43)
                                C <= clk8;
                        end
                    `EEPROM_WAIT:
                        begin
                            // 0 : setup
                            // 1-8 : 8 bit instruction
			    // 9-16 : 8 bit value
			    // 17 : extra for C to go low again
                            if (state_val >= 1 && state_val <= 17)
                                C <= clk8;
                            if (state_val == 17) begin
                                if (!status[0]) begin
                                    $display("NOT BUSY");
                                    eeprom_state <= `EEPROM_IDLE;   
				    eeprom_busy <= 1'b0;
			        end else begin
                                    $display("STILL BUSY");
				    state_ctr <= 0;
			        end
			    end
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
                            C <= clk8;
                        end
                        else if (state_val == 33) begin
                            S <= 1;
                            C <= 1;
                        end
                    `EEPROM_WRITE:
                        // If we hit the write address, then write now.
                        if (addr_lo == eeprom_w_addr)
                        begin
                            if (state_val == 0) begin
                                S <= 0;
                                C <= 1;
                                instr <= 8'b00000110; // WREN
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
				data <= eeprom_w_value;
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
                    `EEPROM_WAIT:
                        if (state_val == 0) begin
                           S <= 0;
                           C <= 1;
                           instr <= 8'b00000101; // RDSR
                        end
                        else if (state_val >= 1 && state_val <= 8) begin
                            // Shift in the instruction - 8 bits
                            D <= instr[7];
                            C <= clk8;
                            instr <= {instr[6:0], 1'b0};
                        end
                        else if (state_val >= 9 && state_val <= 16) begin
                            C <= clk8;
                        end
			else if (state_val == 17) begin
                            C <= 1;
                            S <= 1;
                            $display("POLLED STATUS %d", status);
                        end
                    default:
                        ;
                endcase
            end
        end
    end
endtask

