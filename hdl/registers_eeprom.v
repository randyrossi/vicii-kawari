// Init sequence code for EEPROM config
// M95160-DRE

// Responsible for bringing the system out of reset after
// one pass through all 256 addresses of EEPROM containing
// saved settings. Can also be used to write a single
// value back to eeprom.   To keep the state machine simple,
// a WRITE cycle still iterates over all registers and only
// when the current register matches eeprom_w_addr does a
// WRITE actually take place.  After the WRITE, the state
// machine enters a WAIT state where it polls the status
// register. Once WIP bit falls low, the eeprom_busy flag
// will be set LOW and the state machine goes IDLE again.
//
//   READ goes through 3 stages at startup only.
//   READ (256 register cycle, warmup, reset phase)
//   READ (256 register cycle, reset phase, chip set)
//   READ (256 register cycle, active phase, sets other regs)
//   IDLE
//
// Usage by caller of handle_persist() to save a single
// register value:
//
//       eeprom_busy <= 1'b1;
//       eeprom_w_addr <= REGISTER_NUM;
//       eeprom_w_value <= REGISTER_VALUE;
//       state_ctr_reset_for_write <= 1'b1
//
// Caller should poll busy state before triggering another
// write.
//
// Note: When chip register is set, clock will potentially
// change as this controls the mux in top.v.

task handle_persist(input is_reset);
    begin

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

        // This block handles READs on HIGH edge of C
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
        else if (clk_div[2])
        begin
            if (state_ctr_reset_for_write) begin
               state_ctr <= 15'b0;
               eeprom_state <= `EEPROM_WRITE;
               state_ctr_reset_for_write <= 1'b0;
            end
            else if (~clk8 && !state_ctr[14])
                state_ctr <= state_ctr + 15'b1;
            else if (state_ctr[14]) begin
                // End of state
                case (eeprom_state)
                  `EEPROM_READ:
                  if (eeprom_warm_up_cycle) begin
                    // We just cycled once through all 256 registers
                    eeprom_warm_up_cycle <= 1'b0;
                    state_ctr <= 15'd0;
                  end
                  else if (is_reset) begin
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
        end
        // Set C,D,S so they become valid on [0] for device
        else if (clk_div[3] && !state_ctr[14])
        begin
            clk8 <= ~clk8;
            // This block handles the LOW phase of clk8
            // which is basically setting things up for
            // the LOW edge of C. We also trigger restoration
            // of chip and other registers here.
            if (~clk8) begin
                // clk8 is LOW and about to set C LOW
                case (eeprom_state)
                    `EEPROM_READ:
                    if (!eeprom_warm_up_cycle) begin
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
                                8'hfc: begin
                                    if (data == 8'd86) // V
                                        magic <= magic + 1;
                                end
                                8'hfd: begin
                                    if (data == 8'd73) // I
                                        magic <= magic + 1;
                                end
                                8'hfe: begin
                                    if (data == 8'd67) // C
                                        magic <= magic + 1;
                                end
                                8'hff: begin
                                    if (data == 8'd50) // 2
                                        magic <= magic + 1;
                                end
                                default:
                                    ;
                            endcase

                            // NOTE: Unless we have magic, none of the
                            // magic bytes will actually be set in the
                            // magic registers.
                            
                            // Only restore settings if we have magic
                            if (magic == 4) begin
                              // For 1st pass, set chip (during reset) so
                              // everything inits to the right chip model
                              if (is_reset && addr_lo == `EXT_REG_CHIP_MODEL) begin
                                 chip <= data[1:0];
                              end else begin
                                // For 2nd pass, write to registers
                                write_ram(
                                  .overlay(1'b1),
                                  .ram_lo(addr_lo),
                                  .ram_hi(8'b0), // ignored
                                  .ram_idx(8'b0), // ignored
                                  .data(data),
                                  .from_cpu(1'b0), // this is from the EEPROM
                                  .do_tx(1'b0) // no tx
                                );
                              end
                            end
                        end
                    end
                    `EEPROM_WRITE:
                        if (addr_lo == eeprom_w_addr)
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
                            if (state_val > 10 && state_val <= 43)
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
			            end
                     default:
                        ;
                endcase
            end else begin
                // This sets up S,C,D for the upcoming HIGH edge
                // of C. This is where we also come out of WAIT
                // state if polling resulted in LOW WIP.
                // clk8 is HIGH and about to set C HIGH
                case (eeprom_state)
                    `EEPROM_READ:
                    if (!eeprom_warm_up_cycle) begin
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
                            if (!status[0]) begin
                                $display("NOT BUSY");
                                eeprom_state <= `EEPROM_IDLE;   
				                eeprom_busy <= 1'b0;
                            end else begin
                                $display("STILL BUSY");
				                state_ctr <= 0;
			                end
                        end
                    default:
                        ;
                endcase
            end
        end
    end
endtask

