`timescale 1ns / 1ps

module avr_interface #(
    parameter CLK_RATE = 50000000,
    parameter SERIAL_BAUD_RATE = 500000
  )(
    input clk,
    input rst,
    
    // cclk, or configuration clock is used when the FPGA is begin configured.
    // The AVR will hold cclk high when it has finished initializing.
    // It is important not to drive the lines connecting to the AVR
    // until cclk is high for a short period of time to avoid contention.
    input cclk,
    
    // AVR Serial Signals
    output tx,
	 output tx_busy,
    input rx,
    
    // Serial TX User Interface
    input [7:0] tx_data,
    input new_tx_data,
    
    // Serial Rx User Interface
    output [7:0] rx_data,
    output new_rx_data
  );
  
  wire ready;
  wire n_rdy = !ready;
  
  wire tx_m;
  
  // cclk_detector is used to detect when cclk is high signaling when
  // the AVR is ready
  cclk_detector #(.CLK_RATE(CLK_RATE)) cclk_detector (
    .clk(clk),
    .rst(rst),
    .cclk(cclk),
    .ready(ready)
  );
  
  // CLK_PER_BIT is the number of cycles each 'bit' lasts for
  // rtoi converts a 'real' number to an 'integer'
  parameter CLK_PER_BIT = $rtoi($ceil(CLK_RATE/SERIAL_BAUD_RATE));
  
  serial_rx #(.CLK_PER_BIT(CLK_PER_BIT)) serial_rx (
    .clk(clk),
    .rst(n_rdy),
    .rx(rx),
    .data(rx_data),
    .new_data(new_rx_data)
  );
  
  serial_tx #(.CLK_PER_BIT(CLK_PER_BIT)) serial_tx (
    .clk(clk),
    .rst(n_rdy),
    .tx(tx_m),
    .block(1'b0),
    .busy(tx_busy),
    .data(tx_data),
    .new_data(new_tx_data)
  );
  
  assign tx = ready ? tx_m : 1'bZ;
  
endmodule
