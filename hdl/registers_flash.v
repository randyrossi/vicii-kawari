// Helper for bulk writing data from video ram into
// flash device. Used for updating the device's bitstream.
//
// do 64 times
//    WREN
//    WRITE (data from video ram)
//    READ STATUS, LOOP UNTIL NOT BUSY
//    advance addr by 256 bytes
// done
// reset addr back to start
// do 64 times
//    PAGE READ (compare to video ram)
//    advance addr by 256 bytes
// done
//
// any comparison fails, set verify to 1 to indicate error
// set busy to 0 to indicate done operation

task handle_flash();
begin
    flash_clk_div <= {flash_clk_div[2:0] , flash_clk_div[3]};

    //if (flash_clk_div[3])
    //$display ("state=%d cmd=%d bit=%d S=%d C=%d D=%d ver=%d busy=%d read=%x write=%x", flash_state, flash_command_ctr, flash_bit_ctr, flash_s, spi_c, spi_d, flash_verify_error, flash_busy, flash_read_addr, flash_write_addr);

    if (flash_clk_div[0] && flash_state != `FLASH_IDLE && ~flash_clk8)
    begin
        // READ for WAIT (8 bits)
        if (flash_command_ctr == `FLASH_CMD_WAIT)
            if (flash_bit_ctr >= 6'd9 && flash_bit_ctr <= 6'd16)
                flash_byte <= { flash_byte[6:0] , spi_q };
        // READ for VERIFY (8 bits)
        if (flash_command_ctr == `FLASH_CMD_VERIFY)
            if (flash_bit_ctr >= 6'd33 && flash_bit_ctr <= 6'd40) begin
                flash_byte <= { flash_byte[6:0] , spi_q };
            end
    end
    else if (flash_clk_div[2]) begin
        if (flash_begin) begin
            // We only have one command but this could be extended
            // to initiate other bulk operation types.
            flash_begin <= 1'b0;
            flash_state <= `FLASH_WRITE;
        end if (~flash_clk8 && flash_state != `FLASH_IDLE) begin
            // Advance bit ctr if we are doing stuff
            flash_bit_ctr <= flash_bit_ctr + 6'd1;
        end
    end
    else if (flash_clk_div[3])
    begin
        flash_clk8 <= ~flash_clk8;

	if (~flash_clk8) begin
	    // LOW flash clock
            // Any transition to next state must be done here
            // NOTE: Bit ranges always have 1 extra at end of command for
            // the final clock low pulse before command ends on next ctr.
            case (flash_state)
	    `FLASH_WRITE:
                 // WREN
                 if (flash_command_ctr == `FLASH_CMD_WREN) begin
                    if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd8) begin
                       spi_c <= flash_clk8;
                    end
                    else if (flash_bit_ctr == 6'd10) begin
                       // goto WRITE after WAIT
                       flash_command_ctr <= `FLASH_CMD_WAIT;
                       flash_next_command <= `FLASH_WRITE;
                       flash_bit_ctr <= 6'd0;
                       flash_byte_ctr = 0;
		    end
                 end
                 // WRITE
                 else if (flash_command_ctr == `FLASH_CMD_WRITE) begin
                    if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd41) begin
                       if (flash_bit_ctr == 6'd41) begin
                          flash_byte_ctr = flash_byte_ctr + 1;
                          if (flash_byte_ctr > 0) begin
                             // get next byte from video ram
                             $display("GRAB byte #%d", flash_byte_ctr);
                             flash_byte <= video_ram_data_out_a;
                             flash_bit_ctr <= 6'd33;
                             spi_c <= flash_clk8;
                          end
                       end else
                          spi_c <= flash_clk8;
                    end
                    else if (flash_bit_ctr == 6'd42) begin
                       // goto WAIT and then VERIFY
                       flash_command_ctr <= `FLASH_CMD_WAIT;
                       flash_next_command <= `FLASH_CMD_VERIFY;
                       flash_bit_ctr <= 6'd0;
                    end
                 end
                 // WAIT
                 else if (flash_command_ctr == `FLASH_CMD_WAIT) begin
                    if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd16) begin
                       spi_c <= flash_clk8;
                    end
                    else if (flash_bit_ctr == 6'd18) begin
                       flash_bit_ctr <= 6'd0;
                       if (!flash_byte[0]) begin // remove negation to test loop in sim
                           // done writing, move to next command
                           flash_command_ctr <= flash_next_command;
                           if (flash_next_command == `FLASH_CMD_VERIFY) begin
                               // Have to rewind 256 bytes to do the verify
                               flash_read_addr <= flash_read_addr - 256;
                           end
                           flash_byte_ctr = 0;
                       end
                    end
                 end
                 // VERIFY
                 else if (flash_command_ctr == `FLASH_CMD_VERIFY) begin
                    if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd41) begin
                       if (flash_bit_ctr == 6'd41) begin
                           flash_byte_ctr = flash_byte_ctr + 1;
                           if (flash_byte_ctr > 0) begin
                              // compare for verify
                              if (flash_byte != mem_byte)
                                  flash_verify_error <= 1'b1;
                              // get next byte from video ram
                              $display("VERIFY byte #%d", flash_byte_ctr);
                              mem_byte <= video_ram_data_out_a;
                              flash_bit_ctr <= 6'd33;
                              spi_c <= flash_clk8;
                           end
                       end else
                          spi_c <= flash_clk8;
                    end else if (flash_bit_ctr == 6'd42) begin
                       flash_page_ctr = flash_page_ctr + 1;
                       if (flash_page_ctr > 0) begin
                           // Start over for next page
                           flash_command_ctr <= `FLASH_CMD_WREN;
                           flash_bit_ctr <= 6'd0;
                           flash_write_addr <= flash_write_addr + 256;
                       end else begin
                           flash_state <= `FLASH_IDLE;
                           flash_busy <= 1'b0;
                       end
                    end
                 end
	    default:
		    ;
            endcase
	end else begin
	    // HI flash clock
            case (flash_state)
	    `FLASH_WRITE:
                 // WREN
                 if (flash_command_ctr == `FLASH_CMD_WREN) begin
                    if (flash_bit_ctr == 6'd0) begin
                       flash_s <= 0;
                       spi_c <= 1;
                       flash_instr <= 8'b00000110;
                       $display("WREN page %d", flash_page_ctr);
                    end else if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <=6'd8) begin
                       spi_d <= flash_instr[7];
                       spi_c <= flash_clk8;
                       flash_instr <= {flash_instr[6:0], 1'b0};
                    end else if (flash_bit_ctr == 6'd9) begin
                       flash_s <= 1;
                       spi_c <= 1;
                    end
                 end
                 // WRITE
                 else if (flash_command_ctr == `FLASH_CMD_WRITE) begin
                    if (flash_bit_ctr == 6'd0) begin
                       // setup
                       flash_s <= 0;
                       spi_c <= 1;
                       flash_instr <= 8'b00000010;
                       $display("WRITE page %d", flash_page_ctr);
                    end else if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd8) begin
                       // shift in the instruction
                       spi_d <= flash_instr[7];
                       spi_c <= flash_clk8;
                       flash_instr <= {flash_instr[6:0], 1'b0};
                       flash_write_addr_s <= flash_write_addr;
                    end else if (flash_bit_ctr >= 6'd9 && flash_bit_ctr <= 6'd32) begin
                       // shift in 24 bit address
                       spi_d <= flash_write_addr_s[23];
                       flash_write_addr_s <= {flash_write_addr_s[22:0], 1'b0};
                       spi_c <= flash_clk8;
                       if (flash_bit_ctr == 6'd31) begin
                          video_ram_addr_a <= flash_read_addr;
                       end else if (flash_bit_ctr == 6'd32) begin
                          flash_byte <= video_ram_data_out_a;
                          $display("GRAB1 byte #%d", flash_byte_ctr);
                       end
                    end else if (flash_bit_ctr >= 6'd33 && flash_bit_ctr <= 6'd40) begin
                       spi_d <= flash_byte[7];
                       spi_c <= flash_clk8;
                       flash_byte <= {flash_byte[6:0], 1'b0};
                       if (flash_bit_ctr == 6'd33) begin
                          // advance read addr
                          flash_read_addr <= flash_read_addr + 1;
                       end else if (flash_bit_ctr == 6'd39) begin
                          video_ram_addr_a <= flash_read_addr;
                       end
                    end else if (flash_bit_ctr == 6'd41) begin
                       flash_s <= 1;
                       spi_c <= 1;
                    end
                 end
                 // WAIT
                 else if (flash_command_ctr == `FLASH_CMD_WAIT) begin
                    if (flash_bit_ctr == 6'd0) begin
                       // setup
                       flash_s <= 0;
                       spi_c <= 1;
                       flash_instr <= 8'b00000101;
                       $display("WAIT page %d", flash_page_ctr);
                    end else if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd8) begin
                       // shift in the instruction
                       spi_d <= flash_instr[7];
                       spi_c <= flash_clk8;
                       flash_instr <= {flash_instr[6:0], 1'b0};
                    end else if (flash_bit_ctr >= 6'd9 && flash_bit_ctr <= 6'd16) begin
                       // read one byte
                       spi_c <= flash_clk8;
                    end else if (flash_bit_ctr == 6'd17) begin
                       // done
                       spi_c <= 1;
                       flash_s <= 1;
                    end
                 end
                 // VERIFY
                 else if (flash_command_ctr == `FLASH_CMD_VERIFY) begin
                    if (flash_bit_ctr == 6'd0) begin
                       // setup
                       flash_s <= 0;
                       spi_c <= 1;
                       flash_instr <= 8'b00000011;
                       $display("VERIFY page %d", flash_page_ctr);
                    end else if (flash_bit_ctr >= 6'd1 && flash_bit_ctr <= 6'd8) begin
                       // shift in the instruction
                       spi_d <= flash_instr[7];
                       spi_c <= flash_clk8;
                       flash_instr <= {flash_instr[6:0], 1'b0};
                       flash_write_addr_s <= flash_write_addr;
                    end else if (flash_bit_ctr >= 6'd9 && flash_bit_ctr <= 6'd32) begin
                       // shift in 24 bit address
                       spi_d <= flash_write_addr_s[23];
                       flash_write_addr_s <= {flash_write_addr_s[22:0], 1'b0};
                       spi_c <= flash_clk8;
                       if (flash_bit_ctr == 6'd31) begin
                          video_ram_addr_a <= flash_read_addr;
                       end else if (flash_bit_ctr == 6'd32) begin
                          mem_byte <= video_ram_data_out_a;
                          $display("VERIFY1 for byte # %d", flash_byte_ctr);
                       end
                    end else if (flash_bit_ctr >= 6'd33 && flash_bit_ctr <= 6'd40) begin
                       if (flash_bit_ctr == 6'd33) begin
                          // advance read addr
                          flash_read_addr <= flash_read_addr + 1;
                       end else if (flash_bit_ctr == 6'd39) begin
                          video_ram_addr_a <= flash_read_addr;
                       end
                       spi_c <= flash_clk8;
                    end else if (flash_bit_ctr == 6'd41) begin
                       flash_s <= 1;
                       spi_c <= 1;
                    end
                end
	    default:
		    ;
            endcase
	end
    end

end
endtask
