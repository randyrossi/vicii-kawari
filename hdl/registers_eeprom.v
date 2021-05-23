// Init sequence code for direct EEPROM config
//
// Responsible for bringing the system out of reset after
// one pass through all 256 addresses of EEPROM containing
// saved settings. Can also be used to write either a single
// value back to eeprom or save all registers to eeprom
// (for first initialization).
//
// Usage:
//
//    eeprom_state <= `EEPROM_WRITE
//    eeprom_w_addr <= 9'h2e
//    state_ctr <= 15'd0;
//    clk_div <= 4'b0001;
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
reg clk8;

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
reg [8:0] eeprom_w_addr = 9'd0;

always @(posedge clk_dot4x)
begin
  begin
    clk_div <= {clk_div[2:0] , clk_div[3]};
    // Once state_ctr reaches 16384, we're done reading all
    // 256 register values.
    if (clk_div[3] && !state_ctr[14])
    begin
	// We are in reset state
	rst <= 1;
        clk8 <= ~clk8;
	if (~clk8) begin
		state_ctr <= state_ctr + 15'b1;
		case (eeprom_state)
                `EEPROM_READ:
		   if (state_val == 0) begin
			S <= 0;
			C <= 1;
			instr <= 8'b00000011; // READ
			addr <= {8'b0, addr_lo};
		   end
		   else if (state_val >= 1 && state_val <= 8) begin
			// Shift in the instruction
			D <= instr[7];
			C <= ~clk8;
			instr <= {instr[6:0], 1'b0};
		   end
		   else if (state_val >= 9 && state_val <= 24) begin
			// Shift in the address
			D <= addr[15];
			addr <= {addr[14:0], 1'b0};
			C <= ~clk8;
		   end
		   else if (state_val >= 25 && state_val <= 32) begin
			// Shift in data from EEPROM
			data <= { data[6:0], Q };
			C <= ~clk8;
		   end
		   else if (state_val == 33) begin
			$display("GOT %d for ADDR %d (magic %d)", data, addr_lo, magic);
			C <= 1;
			S <= 1;
			if (addr_lo == 8'hfc && data == 8'd86) // V
				magic <= magic + 1;
			else if (addr_lo == 8'hfd && data == 8'd73) // I
				magic <= magic + 1;
			else if (addr_lo == 8'hfe && data == 8'd67) // C
				magic <= magic + 1;
			else if (addr_lo == 8'hff && data == 8'd50) // 2
				magic <= magic + 1;
			// TODO handle register cases here
		   end
		   `EEPROM_WRITE:
                   // If we hit the write address or if the 'all' flag bit 8
		   // is set, then write now.
		   if ((addr_lo == eeprom_w_addr[7:0] && ~eeprom_w_addr[8])
			   || eeprom_w_addr[8])
		   begin
		   if (state_val == 0) begin
			S <= 0;
			C <= 1;
			instr <= 8'b00000110; // WREN
		   end
		   else if (state_val >= 1 && state_val <= 8) begin
			// Shift in the instruction
			D <= instr[7];
			C <= ~clk8;
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
			// TODO PICK FROM REGISTER or hard coded magic
			data <= 8'd55; 
		   end
		   else if (state_val >= 11 && state_val <= 18) begin
			// Shift in the instruction
			D <= instr[7];
			C <= ~clk8;
			instr <= {instr[6:0], 1'b0};
		   end
		   else if (state_val >= 19 && state_val <= 34) begin
			// Shift in the address
			D <= addr[15];
			addr <= {addr[14:0], 1'b0};
			C <= ~clk8;
		   end
		   else if (state_val >= 35 && state_val <= 42) begin
			// Shift out the data
			D <= data[7];
			C <= ~clk8;
			data <= {data[6:0], 1'b0};
		   end
		   else if (state_val == 43) begin
			C <= 1;
			S <= 1;
			$display("WROTE for ADDR %d", addr_lo);
		   end
		   end
		endcase
	end else begin
	    case (eeprom_state)
                `EEPROM_READ:
		if (state_val >=1 && state_val <= 32) begin
			// This will leave the clock HIGH after we read
			// the data.
			C <= ~clk8;
		end
	        `EEPROM_WRITE:
		if (state_val >=1 && state_val <= 8) begin
			C <= ~clk8;
		end
		else if (state_val >=11 && state_val <= 42) begin
			C <= ~clk8;
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
