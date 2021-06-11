// Transfer incoming rx data and new data signal from
// sys_clock domain onto dot4x clock and ensure
// new_out_data is strobed for only on dot4x tick.
//
// This only works because it's not possible for a new
// byte to arrive before we're done with the handshake
// between clock domains, so this will safely transmit
// new flag and data to the dot4x domain as fast as
// data arrives off the wire.
module serial_cross(
           input in_clk,
           input out_clk,
           input [7:0] in_data,
           input new_in_data,
           output reg [7:0] out_data,
           output reg new_out_data
       );

reg request_in;
reg[7:0] data_in;
reg ack_out;

reg request_in_c;
reg request_in_out; // request_in valid on out clock
always @(posedge out_clk) request_in_c <= request_in;
always @(posedge out_clk) request_in_out <= request_in_c;

reg [7:0] data_in_c;
reg [7:0] data_in_out; // data in valid on out clock
always @(posedge out_clk) data_in_c <= data_in;
always @(posedge out_clk) data_in_out <= data_in_c;

reg ack_out_c;
reg ack_out_in;  // ack_out valid on in clock
always @(posedge in_clk) ack_out_c <= ack_out;
always @(posedge in_clk) ack_out_in <= ack_out_c;

always @(posedge in_clk)
begin
    // New data and have not sent request
    if (new_in_data && request_in == 1'b0) begin
        // Send request
        request_in <= 1'b1;
        data_in <= in_data;
    end

    // Request was acknowledged. Send clear signal
    else if (ack_out_in) begin
        request_in <= 1'b0;
    end
end

always @(posedge out_clk)
begin
    // Got request and haven't acked yet
    if (request_in_out && !ack_out) begin
        // Ack and set data for out clock
        ack_out <= 1'b1;
        out_data <= data_in_out;
        new_out_data <= 1'b1;
    end else begin
        // Ensures new_data_out will be high on only 1 tick
        new_out_data <= 1'b0;
        if (!request_in_out)
            ack_out <= 1'b0;
    end
end

endmodule
