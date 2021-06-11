`timescale 1ns / 1ps

`include "common.vh"

`ifdef HAVE_MCU_EEPROM
task persist_eeprom(input do_tx, input [7:0] reg_num, input [7:0] reg_val);
    // This version sends the change bytes to the MCU via serial link
    if (do_tx) begin
        tx_cfg_change_1 <= reg_num;
        tx_cfg_change_2 <= reg_val;
        tx_new_data_start = 1'b1;
    end
endtask
`elsif HAVE_EEPROM
task persist_eeprom(input do_tx, input [7:0] reg_num, input [7:0] reg_val);
    // This version writes to the eeprom
    if (do_tx) begin
       eeprom_busy <= 1'b1;
       eeprom_w_addr <= reg_num;
       eeprom_w_value <= reg_val;
       state_ctr_reset_for_write <= 1'b1;
    end
endtask
`else
task persist_eeprom(input do_tx, input [7:0] reg_num, input [7:0] reg_val);
    ; // noop
endtask
`endif

// For color ram:
//     flip read bit on and set address and which 6-bit-nibble (out of 4)
//     is to be read, dbo will be set by the 'CPU read from color regs' block
//     above.
// For video ram:
//     flip read bit on and set address. dbo will be set by the
//     'CPU read from video ram' block above.
//
// In both cases, read happens next cycle and r flags turned off.
//
// If overlay is on, ram_hi and ram_idx are ignored and it will never
// trigger a vram read.
task read_ram(
    input overlay,
    input [7:0] ram_lo,
    input [7:0] ram_hi,
    input [7:0] ram_idx);
    begin
       if (overlay) begin
          if (ram_lo < 8'h80) begin
              // _r_nibble stores which 6-bit-nibble within the 24 bit
              // lookup value we want.  The lowest 6-bits are never used.
`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
              color_regs_r <= 1'b1;
              color_regs_r_nibble <= ram_lo[1:0];
              color_regs_addr_a <= ram_lo[6:2];
`endif
`endif
          end
`ifdef CONFIGURABLE_LUMAS
/* verilator lint_off WIDTH */
			  else if (ram_lo >= `EXT_REG_LUMA0 && ram_lo <= `EXT_REG_LUMA15) begin
                              luma_regs_r <= 1'b1;
                              luma_regs_r_nibble <= 2'b00; // luma
                              luma_regs_addr_a <= ram_lo[3:0];
			  end
			  else if (ram_lo >= `EXT_REG_PHASE0 && ram_lo <= `EXT_REG_PHASE15) begin
                              luma_regs_r <= 1'b1;
                              luma_regs_r_nibble <= 2'b01; // phase
                              luma_regs_addr_a <= ram_lo[3:0];
			  end
			  else if (ram_lo >= `EXT_REG_AMPL0 && ram_lo <= `EXT_REG_AMPL15) begin
                              luma_regs_r <= 1'b1;
                              luma_regs_r_nibble <= 2'b10; // amplitude
                              luma_regs_addr_a <= ram_lo[3:0];
			  end
/* verilator lint_on WIDTH */
`endif
          else begin
              case (ram_lo)
                 `EXT_REG_CHIP_MODEL:
		               dbo <= {6'b0, chip};
                 `EXT_REG_DISPLAY_FLAGS:
`ifdef NEED_RGB
		               dbo <= {2'b0,
                       last_hpolarity,
                       last_vpolarity,
				       last_enable_csync,
				       last_is_native_x,
				       last_is_native_y,
				       last_raster_lines};
`else
                       dbo <= 8'b0;
`endif
`ifdef HIRES_MODES
                 `EXT_REG_CURSOR_LO:
		               dbo <= hires_cursor_lo;
                 `EXT_REG_CURSOR_HI:
		               dbo <= hires_cursor_hi;
`endif
                 `EXT_REG_VERSION:
                     dbo <= {`VERSION_MAJOR, `VERSION_MINOR};
                 `EXT_REG_VARIANT_NAME1:
                     dbo <= `VARIANT_NAME1;
                 `EXT_REG_VARIANT_NAME2:
                     dbo <= `VARIANT_NAME2;
                 `EXT_REG_VARIANT_NAME3:
                     dbo <= `VARIANT_NAME3;
                 `EXT_REG_VARIANT_NAME4:
                     dbo <= `VARIANT_NAME4;
                 `EXT_REG_VARIANT_NAME5:
                     dbo <= `VARIANT_NAME5;
                 `EXT_REG_VARIANT_NAME6:
                     dbo <= `VARIANT_NAME6;
                 `EXT_REG_VARIANT_NAME7:
                     dbo <= `VARIANT_NAME7;
                 `EXT_REG_VARIANT_NAME8:
                     dbo <= `VARIANT_NAME8;
                 `EXT_REG_VARIANT_NAME9:
                     dbo <= 8'd0;
`ifdef CONFIGURABLE_LUMAS
                 `EXT_REG_BLANKING:
                     dbo <= {2'b0, blanking_level};
                 `EXT_REG_BURSTAMP:
                     dbo <= {4'b0, burst_amplitude};
`endif
                 // Advertise some capability bits
                 `EXT_REG_CAP_LO:
                     begin
                       dbo[`CAP_RGB_BIT] <= `HAS_RGB_CAP;
                       dbo[`CAP_DVI_BIT] <= `HAS_DVI_CAP;
                       dbo[`CAP_COMP_BIT] <= `HAS_COMP_CAP;
                       dbo[`CAP_CONFIG_RGB_BIT] <= `HAS_CONFIG_RGB_CAP;
                       dbo[`CAP_CONFIG_LUMA_BIT] <= `HAS_CONFIG_LUMA_CAP;
                       dbo[`CAP_CONFIG_TIMING_BIT] <= `HAS_CONFIG_TIMING_CAP;
                       dbo[`CAP_PERSIST_BIT] <= `HAS_PERSIST_CAP;
                     end
                 `EXT_REG_CAP_HI:
                     dbo <= 8'b0; // reserved for now
`ifdef CONFIGURABLE_TIMING
                `EXT_REG_TIMING_CHANGE:
                dbo <= {7'b0, timing_change};
                8'hd0:
                dbo <= timing_h_blank_ntsc;
                8'hd1:
                dbo <= timing_h_fporch_ntsc;
                8'hd2:
                dbo <= timing_h_sync_ntsc;
                8'hd3:
                dbo <= timing_h_bporch_ntsc;
                8'hd4:
                dbo <= timing_v_blank_ntsc;
                8'hd5:
                dbo <= timing_v_fporch_ntsc;
                8'hd6:
                dbo <= timing_v_sync_ntsc;
                8'hd7:
                dbo <= timing_v_bporch_ntsc;
                8'hd8:
                dbo <= timing_h_blank_pal;
                8'hd9:
                dbo <= timing_h_fporch_pal;
                8'hda:
                dbo <= timing_h_sync_pal;
                8'hdb:
                dbo <= timing_h_bporch_pal;
                8'hdc:
                dbo <= timing_v_blank_pal;
                8'hdd:
                dbo <= timing_v_fporch_pal;
                8'hde:
                dbo <= timing_v_sync_pal;
                8'hdf:
                dbo <= timing_v_bporch_pal;
`endif
8'hfb:
dbo <= remove_me;
                8'hfc:
                   dbo <= magic_1;
                8'hfd:
                   dbo <= magic_2;
                8'hfe:
                   dbo <= magic_3;
                8'hff:
                   dbo <= magic_4;
                 default: ;
              endcase
          end
       end else begin
           video_ram_r <= 1;
           video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
           end
       end
endtask

// For color ram:
//     Write happens in two stages. First pre_wr flag is set along with
//     value and which 6-bit-nibble (of 4) and the adddress.  When stage 1 is
//     handled above, the value is read out first, the nibble updated
//     and then the write op is done.
// For video ram:
//     Write happens in one stage. We set the wr flag, address and value
//     here.
//
// In both cases, wr flags are turned one cycle after they are set.
//
// If overlay is on, ram_hi and ram_idx are ignored and it will never
// trigger a vram write.
//
// If do_tx is 1, we transmit this change to the MCU for persistence.
task write_ram(
    input overlay,
    input [7:0] ram_lo,
    input [7:0] ram_hi,
    input [7:0] ram_idx,
	 input [7:0] data,
	 input from_cpu,
	 input do_tx);
    begin
       if (overlay) begin
           if (ram_lo < 8'h80) begin
              // In order to write to individual 6 bit
              // values within the 24 bit register, we
              // have to read it first, then write.
`ifdef NEED_RGB
`ifdef CONFIGURABLE_RGB
              color_regs_pre_wr2_a <= 1'b1;
              color_regs_wr_value <= data[5:0];
              color_regs_wr_nibble <= ram_lo[1:0];
              color_regs_addr_a <= ram_lo[6:2];
	      persist_eeprom(do_tx, ram_lo, {2'b0, data[5:0]});
`endif
`endif
          end
`ifdef CONFIGURABLE_LUMAS
/* verilator lint_off WIDTH */
           else if (ram_lo >= `EXT_REG_LUMA0 && ram_lo <= `EXT_REG_LUMA15) begin
              luma_regs_pre_wr2_a <= 1'b1;
              luma_regs_wr_value <= {2'b0, data[5:0]};
              luma_regs_wr_nibble <= 2'b00; // luma
              luma_regs_addr_a <= ram_lo[3:0];
	      persist_eeprom(do_tx, ram_lo, {2'b0, data[5:0]});
           end
           else if (ram_lo >= `EXT_REG_PHASE0 && ram_lo <= `EXT_REG_PHASE15) begin
              luma_regs_pre_wr2_a <= 1'b1;
              luma_regs_wr_value <= data[7:0];
              luma_regs_wr_nibble <= 2'b01; // phase
              luma_regs_addr_a <= ram_lo[3:0];
	      persist_eeprom(do_tx, ram_lo, data[7:0]);
           end
           else if (ram_lo >= `EXT_REG_AMPL0 && ram_lo <= `EXT_REG_AMPL15) begin
              luma_regs_pre_wr2_a <= 1'b1;
              luma_regs_wr_value <= {4'b0, data[3:0]};
              luma_regs_wr_nibble <= 2'b10; // amplitude
              luma_regs_addr_a <= ram_lo[3:0];
	      persist_eeprom(do_tx, ram_lo, {4'b0, data[3:0]});
           end
/* verilator lint_on WIDTH */
`endif
           else begin
              // When we poke certain config registers, we
              // persist them according to persist_eeprom
	      // implementation.
              case (ram_lo)
                 // Not safe to allow nativex/y to be changed from
                 // CPU. Already burned by this with accidental
                 // overwrite of this register. This can effectively
                 // disable your display so leave this only to the
                 // serial connection to change.
                 `EXT_REG_CHIP_MODEL:
                  begin
                    // We never change chip register from CPU. Only
		    // init sequence will set it either from MCU lines
		    // or EEPROM data.
                    persist_eeprom(do_tx, `EXT_REG_CHIP_MODEL, {6'b0, data[1:0]});
                 end
                 `EXT_REG_DISPLAY_FLAGS:
                  begin
`ifdef NEED_RGB
              last_raster_lines <= data[`SHOW_RASTER_LINES_BIT];
			  if (!from_cpu) begin // protect from CPU
			     last_is_native_y <= data[`IS_NATIVE_Y_BIT]; // 15khz
			     last_is_native_x <= data[`IS_NATIVE_X_BIT];
			     last_enable_csync <= data[`ENABLE_CSYNC_BIT];
                 last_hpolarity <= data[`HPOLARITY_BIT];
                 last_vpolarity <= data[`VPOLARITY_BIT];
			  end
	                  persist_eeprom(do_tx, `EXT_REG_DISPLAY_FLAGS,
			             {4'b0,
				     data[`ENABLE_CSYNC_BIT],
				     data[`IS_NATIVE_X_BIT],
				     data[`IS_NATIVE_Y_BIT],
				     data[`SHOW_RASTER_LINES_BIT]
				     });
`endif // NEED_RGB
                 end
`ifdef HIRES_MODES
                 `EXT_REG_CURSOR_LO:
                    hires_cursor_lo <= data;
                 `EXT_REG_CURSOR_HI:
                    hires_cursor_hi <= data;
`endif
`ifdef CONFIGURABLE_LUMAS
                 `EXT_REG_BLANKING: begin
                    blanking_level <= data[5:0];
	            persist_eeprom(do_tx, ram_lo, {2'b0, data[5:0]});
                 end
		 `EXT_REG_BURSTAMP: begin
                    burst_amplitude <= data[3:0];
	            persist_eeprom(do_tx, ram_lo, {4'b0, data[3:0]});
                 end
`endif
`ifdef CONFIGURABLE_TIMING
                `EXT_REG_TIMING_CHANGE:
                timing_change <= data[0];

                8'hd0:
                timing_h_blank_ntsc <= data;
                8'hd1:
                timing_h_fporch_ntsc <= data;
                8'hd2:
                timing_h_sync_ntsc <= data;
                8'hd3:
                timing_h_bporch_ntsc <= data;
                8'hd4:
                timing_v_blank_ntsc <= data;
                8'hd5:
                timing_v_fporch_ntsc <= data;
                8'hd6:
                timing_v_sync_ntsc <= data;
                8'hd7:
                timing_v_bporch_ntsc <= data;
                8'hd8:
                timing_h_blank_pal <= data;
                8'hd9:
                timing_h_fporch_pal <= data;
                8'hda:
                timing_h_sync_pal <= data;
                8'hdb:
                timing_h_bporch_pal <= data;
                8'hdc:
                timing_v_blank_pal <= data;
                8'hdd:
                timing_v_fporch_pal <= data;
                8'hde:
                timing_v_sync_pal <= data;
                8'hdf:
                timing_v_bporch_pal <= data;
`endif
                8'hfc: begin
                   magic_1 <= data;
                   persist_eeprom(do_tx, 8'hfc, data);
                end
                8'hfd: begin
                   magic_2 <= data;
                   persist_eeprom(do_tx, 8'hfd, data);
                end
                8'hfe: begin
                   magic_3 <= data;
                   persist_eeprom(do_tx, 8'hfe, data);
                end
                8'hff: begin
                   magic_4 <= data;
                   persist_eeprom(do_tx, 8'hff, data);
                end
                default: ;
              endcase
           end
        end else begin
           video_ram_wr_a <= 1'b1;
           video_ram_aw <= 1'b1;
           video_ram_data_in_a <= data[7:0];
           video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
        end
    end
endtask

