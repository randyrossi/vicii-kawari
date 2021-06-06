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
//       clk_div <= 4'b0001;
//    end
//
// Note: When chip register is set, clock will potentially
// change as this controls the mux.

// Every 64 ticks of state_ctr cycles through all 256
// EEPROM addresses and performs the operation as indicated
// by eeprom_state (READ, WRITE)
reg [14:0] state_ctr = 15'b0;

// clk_div divides dot4x by 4 to give us approx 8Mhz clock
// for EEPROM access
reg [3:0] clk_div = 4'b0001;

// Register for an internal 8Mhz clock that is sometimes
// 'exported' to C
reg clk8 = 1'b1;

// Bits 13-6 represent the address in EEPROM we are reading
// (0-256) but we offset by -4 to start at 0xfc and end at
// 0xfb rather than 0x00-0xff.  This is so the first thing
// we read are the magic bytes.  If we don't find them within
// the first 4 reads, none of the data gets assigned to any
// registers. This prevents blank EEPROM from setting registers
// to garbage.
wire [5:0] state_val = state_ctr[5:0];

// We start at 0xfc so we read the magic bytes first
wire [7:0] addr_lo = state_ctr[13:6] - 8'd4;

reg [7:0] instr; // Instruction shift register
reg [15:0] addr; // Address shift register
reg [7:0] data; // Data shift reigster

reg [2:0] magic = 3'd0;

// Start off reading existing eeprom data
reg eeprom_state = `EEPROM_READ;

// When in EEPROM_WRITE mode, what addr are we writing
// to? Use 0x100 for ALL.
reg [7:0] eeprom_w_addr = 8'd0;

`ifdef CMOD_BOARD
assign led[0] = magic == 4;  // indicates we successfully read magic bytes
assign led[1] = eeprom_state == `EEPROM_WRITE; // indicates our r/w mode
reg [7:0] wreg = 8'hfc;
`endif

`ifdef SIMULATOR_BOAD
reg test_init;
`endif

always @(posedge clk_dot4x)
begin
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
        else if (clk_div[2] && btn[1] && eeprom_state == `EEPROM_WRITE) begin
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
                            // magic was found.
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
                endcase
            end
        end
        else if (state_ctr[14]) begin
            // We are out of reset
            case (eeprom_state)
                `EEPROM_READ: begin
                    rst <= 0;
                end
                `EEPROM_WRITE:
                    ;
            endcase

        end
    end
end
