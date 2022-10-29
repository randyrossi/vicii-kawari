// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

`timescale 1ns / 1ps

// Module to do long division, signed or unsigned.
module divide(
   input clk,
   input sign,
   input [15:0] dividend,
   input [15:0] divider,
   output done,
   output reg [15:0] quotient,
   output [15:0] remainder);

   reg [15:0]    quotient_temp;
   reg [31:0]    dividend_copy, divider_copy, diff;
   reg           negative_output;
   
   assign remainder = (!negative_output) ? 
                             dividend_copy[15:0] : 
                             ~dividend_copy[15:0] + 1'b1;

   reg [4:0]     bt; 
   assign done = (bt == 0);

   initial bt = 0;
   initial negative_output = 0;

   always @( posedge clk ) 

     if(done) begin

        bt = 5'd16;
        quotient = 0;
        quotient_temp = 0;
        dividend_copy = (!sign || !dividend[15]) ? 
                        {16'd0,dividend} : 
                        {16'd0,~dividend + 1'b1};
        divider_copy = (!sign || !divider[15]) ? 
                       {1'b0,divider,15'd0} : 
                       {1'b0,~divider + 1'b1,15'd0};

        negative_output = sign &&
                          ((divider[15] && !dividend[15]) 
                        ||(!divider[15] && dividend[15]));
        
     end 
     else if ( bt > 0 ) begin

        diff = dividend_copy - divider_copy;
        quotient_temp = quotient_temp << 1;

        if( !diff[31] ) begin
           dividend_copy = diff;
           quotient_temp[0] = 1'd1;
        end

        quotient = (!negative_output) ? 
                   quotient_temp : 
                   ~quotient_temp + 1'b1;

        divider_copy = divider_copy >> 1;
        bt = bt - 1'b1;
     end
endmodule
