//*****************************************************************************
// Company:          Xilinx
// Engineer:         Karl Kurbjun and Carl Ribbing
// Design Name:      PLL DRP
// Module Name:      pll_drp_func.h
// Project Name:
// Target Devices:   Virtex 5 and Spartan 6 Family
// Tool versions:    L.50 (lin)
// Description:      This header provides the functions necessary to calculate 
//                   the DRP register values for the V5 PLL
//*****************************************************************************

// Define debug to provide extra messages durring elaboration
//`define DEBUG 1

// FRAC_PRECISION describes the width of the fractional portion of the fixed
//    point numbers.
`define FRAC_PRECISION  10
// FIXED_WIDTH describes the total size for fixed point calculations(int+frac).
// Warning: L.50 and below will not calculate properly with FIXED_WIDTHs 
//    greater than 32
`define FIXED_WIDTH     32 

// This function takes a fixed point number and rounds it to the nearest
//    fractional precision bit.
function [`FIXED_WIDTH:1] round_frac
   (
      // Input is (FIXED_WIDTH-FRAC_PRECISION).FRAC_PRECISION fixed point number
      input [`FIXED_WIDTH:1] decimal,  

      // This describes the precision of the fraction, for example a value
      //    of 1 would modify the fractional so that instead of being a .16
      //    fractional, it would be a .1 (rounded to the nearest 0.5 in turn)
      input [`FIXED_WIDTH:1] precision 
   );

   begin
   
`ifdef DEBUG
      $display("round_frac - decimal: %h, precision: %h", decimal, precision);
`endif
      // If the fractional precision bit is high then round up
      if( decimal[(`FRAC_PRECISION-precision)] == 1'b1) begin
         round_frac = decimal + (1'b1 << (`FRAC_PRECISION-precision));
      end else begin
         round_frac = decimal;
      end
`ifdef DEBUG
      $display("round_frac: %h", round_frac);
`endif
   end
endfunction

// This function calculates high_time, low_time, w_edge, and no_count
//    of a non-fractional counter based on the divide and duty cycle
//
// NOTE: high_time and low_time are returned as integers between 0 and 63 
//    inclusive.  64 should equal 6'b000000 (in other words it is okay to 
//    ignore the overflow)
function [13:0] pll_divider
   (
      input [7:0] divide,        // Max divide is 128
      input [31:0] duty_cycle    // Duty cycle is multiplied by 100,000
   );

   reg [`FIXED_WIDTH:1]    duty_cycle_fix;
   
   // High/Low time is initially calculated with a wider integer to prevent a
   // calculation error when it overflows to 64.
   reg [6:0]               high_time;
   reg [6:0]               low_time;
   reg                     w_edge;
   reg                     no_count;

   reg [`FIXED_WIDTH:1]    temp;

   begin
      // Duty Cycle must be between 0 and 1,000
      if(duty_cycle <=0 || duty_cycle >= 100000) begin
         $display("ERROR: duty_cycle: %f is invalid", duty_cycle);
         $finish;
      end

      // Convert to FIXED_WIDTH-FRAC_PRECISION.FRAC_PRECISION fixed point
      duty_cycle_fix = (duty_cycle << `FRAC_PRECISION) / 100_000;
      
`ifdef DEBUG
      $display("duty_cycle_fix: %h", duty_cycle_fix);
`endif

      // If the divide is 1 nothing needs to be set except the no_count bit.
      //    Other values are dummies
      if(divide == 7'h01) begin
         high_time   = 7'h01;
         w_edge      = 1'b0;
         low_time    = 7'h01;
         no_count    = 1'b1;
      end else begin
         temp = round_frac(duty_cycle_fix*divide, 1);

         // comes from above round_frac
         high_time   = temp[`FRAC_PRECISION+7:`FRAC_PRECISION+1]; 
         // If the duty cycle * divide rounded is .5 or greater then this bit
         //    is set.
         w_edge      = temp[`FRAC_PRECISION]; // comes from round_frac
         
         // If the high time comes out to 0, it needs to be set to at least 1
         // and w_edge set to 0
         if(high_time == 7'h00) begin
            high_time   = 7'h01;
            w_edge      = 1'b0;
         end

         if(high_time == divide) begin
            high_time   = divide - 1;
            w_edge      = 1'b1;
         end
         
         // Calculate low_time based on the divide setting and set no_count to
         //    0 as it is only used when divide is 1.
         low_time    = divide - high_time; 
         no_count    = 1'b0;
      end

      // Set the return value.
      pll_divider = {w_edge,no_count,high_time[5:0],low_time[5:0]};
   end
endfunction

// This function calculates delay_time and phase_mux based on the divide and
// phase
function [16:0] pll_phase
   (
      // divide must be an integer (use fractional if not)
      //  assumed that divide already checked to be valid
      input [7:0] divide, // Max divide is 128

      // Phase is given in degrees (-360,000 to 360,000)
      input signed [31:0] phase
   );

   reg [`FIXED_WIDTH:1] phase_in_cycles;
   reg [`FIXED_WIDTH:1] phase_fixed;
   reg [5:0]            delay_time;
   reg [2:0]            phase_mux;

   reg [`FIXED_WIDTH:1] temp;

   begin
`ifdef DEBUG
      $display("pll_phase-divide:%d,phase:%d",
         divide, phase);
`endif
   
      if ((phase < -360000) || (phase > 360000)) begin
         $display("ERROR: phase of $phase is not between -360000 and 360000");
         $finish;
      end

      // If phase is less than 0, convert it to a positive phase shift
      // Convert to (FIXED_WIDTH-FRAC_PRECISION).FRAC_PRECISION fixed point
      if(phase < 0) begin
         phase_fixed = ( (phase + 360000) << `FRAC_PRECISION ) / 1000;
      end else begin
         phase_fixed = ( phase << `FRAC_PRECISION ) / 1000;
      end

      // Put phase in terms of decimal number of vco clock cycles
      phase_in_cycles = ( phase_fixed * divide ) / 360;

`ifdef DEBUG
      $display("phase_in_cycles: %h", phase_in_cycles);
`endif  
      
      temp  =  round_frac(phase_in_cycles, 3);
      
      phase_mux      =  temp[`FRAC_PRECISION:`FRAC_PRECISION-2];
      delay_time     =  temp[`FRAC_PRECISION+6:`FRAC_PRECISION+1];
      
`ifdef DEBUG
      $display("temp: %h", temp);
`endif

      // Setup the return value
      pll_phase={phase_mux, delay_time};
   end
endfunction

// This function takes the divide value and outputs the necessary lock values
function [39:0] v5_pll_lock_lookup
   (
      input [6:0] divide // Max divide is 64
   );
   
   reg [2559:0]   lookup;
   
   begin
      lookup = {
         // This table is composed of:
         // LockRefDly_LockFBDly_LockCnt_LockSatHigh_UnlockCnt
         40'b00110_00110_1111101000_1111101001_0000000001,
         40'b00110_00110_1111101000_1111101001_0000000001,
         40'b01000_01000_1111101000_1111101001_0000000001,
         40'b01011_01011_1111101000_1111101001_0000000001,
         40'b01110_01110_1111101000_1111101001_0000000001,
         40'b10001_10001_1111101000_1111101001_0000000001,
         40'b10011_10011_1111101000_1111101001_0000000001,
         40'b10110_10110_1111101000_1111101001_0000000001,
         40'b11001_11001_1111101000_1111101001_0000000001,
         40'b11100_11100_1111101000_1111101001_0000000001,
         40'b11111_11111_1110000100_1111101001_0000000001,
         40'b11111_11111_1100111001_1111101001_0000000001,
         40'b11111_11111_1011101110_1111101001_0000000001,
         40'b11111_11111_1010111100_1111101001_0000000001,
         40'b11111_11111_1010001010_1111101001_0000000001,
         40'b11111_11111_1001110001_1111101001_0000000001,
         40'b11111_11111_1000111111_1111101001_0000000001,
         40'b11111_11111_1000100110_1111101001_0000000001,
         40'b11111_11111_1000001101_1111101001_0000000001,
         40'b11111_11111_0111110100_1111101001_0000000001,
         40'b11111_11111_0111011011_1111101001_0000000001,
         40'b11111_11111_0111000010_1111101001_0000000001,
         40'b11111_11111_0110101001_1111101001_0000000001,
         40'b11111_11111_0110010000_1111101001_0000000001,
         40'b11111_11111_0110010000_1111101001_0000000001,
         40'b11111_11111_0101110111_1111101001_0000000001,
         40'b11111_11111_0101011110_1111101001_0000000001,
         40'b11111_11111_0101011110_1111101001_0000000001,
         40'b11111_11111_0101000101_1111101001_0000000001,
         40'b11111_11111_0101000101_1111101001_0000000001,
         40'b11111_11111_0100101100_1111101001_0000000001,
         40'b11111_11111_0100101100_1111101001_0000000001,
         40'b11111_11111_0100101100_1111101001_0000000001,
         40'b11111_11111_0100010011_1111101001_0000000001,
         40'b11111_11111_0100010011_1111101001_0000000001,
         40'b11111_11111_0100010011_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001,
         40'b11111_11111_0011111010_1111101001_0000000001
      };
      
      // Set lookup_entry with the explicit bits from lookup with a part select
      v5_pll_lock_lookup = lookup[ ((divide-1)*40) +: 40];
   end
endfunction

function [39:0] s6_pll_lock_lookup
   (
      input [6:0] divide // Max divide is 64
   );
   
   reg [2559:0]   lookup;
   
   begin
      lookup = {
         // This table is composed of:
         // LockRefDly_LockFBDly_LockCnt_LockSatHigh_UnlockCnt
         40'b01001_00111_1111101000_1111101001_0000000001,//1
         40'b01001_00111_1111101000_1111101001_0000000001,//2
         40'b01101_01011_1111101000_1111101001_0000000001,//3
         40'b10010_10000_1111101000_1111101001_0000000001,//4
         40'b10110_10100_1111101000_1111101001_0000000001,//5
         40'b11010_11000_1111101000_1111101001_0000000001,//6
         40'b11111_11101_1111101000_1111101001_0000000001,//7
         40'b11111_11101_1111101000_1111101001_0000000001,//8
         40'b11111_11101_1111101000_1111101001_0000000001,//9
         40'b11111_11101_1111101000_1111101001_0000000001,//10
         40'b11111_11101_1110000100_1111101001_0000000001,//11
         40'b11111_11101_1100111001_1111101001_0000000001,//12
         40'b11111_11101_1011101110_1111101001_0000000001,//13
         40'b11111_11101_1010111100_1111101001_0000000001,//14
         40'b11111_11101_1010001010_1111101001_0000000001,//15
         40'b11111_11101_1001110001_1111101001_0000000001,//16
         40'b11111_11101_1000111111_1111101001_0000000001,//17
         40'b11111_11101_1000100110_1111101001_0000000001,//18
         40'b11111_11101_1000001101_1111101001_0000000001,//19
         40'b11111_11101_0111110100_1111101001_0000000001,//20
         40'b11111_11101_0111011011_1111101001_0000000001,//21
         40'b11111_11101_0111000010_1111101001_0000000001,//22
         40'b11111_11101_0110101001_1111101001_0000000001,//23
         40'b11111_11101_0110010000_1111101001_0000000001,//24
         40'b11111_11101_0110010000_1111101001_0000000001,//25
         40'b11111_11101_0101110111_1111101001_0000000001,//26
         40'b11111_11101_0101011110_1111101001_0000000001,//27
         40'b11111_11101_0101011110_1111101001_0000000001,//28
         40'b11111_11101_0101000101_1111101001_0000000001,//29
         40'b11111_11101_0101000101_1111101001_0000000001,//30
         40'b11111_11101_0100101100_1111101001_0000000001,//31
         40'b11111_11101_0100101100_1111101001_0000000001,//32
         40'b11111_11101_0100101100_1111101001_0000000001,//33
         40'b11111_11101_0100010011_1111101001_0000000001,//34
         40'b11111_11101_0100010011_1111101001_0000000001,//35
         40'b11111_11101_0100010011_1111101001_0000000001,//36
         40'b11111_11101_0011111010_1111101001_0000000001,//37
         40'b11111_11101_0011111010_1111101001_0000000001,//38
         40'b11111_11101_0011111010_1111101001_0000000001,//39
         40'b11111_11101_0011111010_1111101001_0000000001,//40
         40'b11111_11101_0011111010_1111101001_0000000001,//41
         40'b11111_11101_0011111010_1111101001_0000000001,//42
         40'b11111_11101_0011111010_1111101001_0000000001,//43
         40'b11111_11101_0011111010_1111101001_0000000001,//44
         40'b11111_11101_0011111010_1111101001_0000000001,//45
         40'b11111_11101_0011111010_1111101001_0000000001,//46
         40'b11111_11101_0011111010_1111101001_0000000001,//47
         40'b11111_11101_0011111010_1111101001_0000000001,//48
         40'b11111_11101_0011111010_1111101001_0000000001,//49
         40'b11111_11101_0011111010_1111101001_0000000001,//50
         40'b11111_11101_0011111010_1111101001_0000000001,//51
         40'b11111_11101_0011111010_1111101001_0000000001,//52
         40'b11111_11101_0011111010_1111101001_0000000001,//53
         40'b11111_11101_0011111010_1111101001_0000000001,//54
         40'b11111_11101_0011111010_1111101001_0000000001,//55
         40'b11111_11101_0011111010_1111101001_0000000001,//56
         40'b11111_11101_0011111010_1111101001_0000000001,//57
         40'b11111_11101_0011111010_1111101001_0000000001,//58
         40'b11111_11101_0011111010_1111101001_0000000001,//59
         40'b11111_11101_0011111010_1111101001_0000000001,//60
         40'b11111_11101_0011111010_1111101001_0000000001,//61
         40'b11111_11101_0011111010_1111101001_0000000001,//62
         40'b11111_11101_0011111010_1111101001_0000000001,//63
         40'b11111_11101_0011111010_1111101001_0000000001//64
      };
      
      // Set lookup_entry with the explicit bits from lookup with a part select
      s6_pll_lock_lookup = lookup[ ((64-divide)*40) +: 40];
	  
	  $display("lock_lookup: %b", s6_pll_lock_lookup);
   end
endfunction

// This function takes the divide value and the bandwidth setting of the PLL
//  and outputs the digital filter settings necessary.
function [9:0] v5_pll_filter_lookup
   (
      input [6:0] divide, // Max divide is 64
      input [8*9:0] BANDWIDTH
   );
   
   reg [1279:0] lookup;
   
   reg [19:0] lookup_entry;
   
   begin
      lookup = {
         // This table is composed as:
         // High bndwidth__Low  bndwidth
         //   RES_LFHF_CP__RES_LFHF_CP
         20'b1111_00_0101__0001_11_0111, // 1
         20'b1111_00_1111__0001_11_0101, // 2
         20'b1101_00_1111__0001_11_1110, // 3
         20'b1001_00_1111__0001_11_0110, // 4
         20'b1110_00_1111__0001_11_1010, // 5
         20'b0001_00_1111__0001_11_1100, // 6
         20'b0001_00_1111__0001_11_1100, // 7
         20'b0110_00_1111__0001_11_1100, // 8
         20'b1010_00_1111__0001_11_1100, // 9
         20'b1010_00_1111__0001_11_0010, // 10
         20'b1010_00_1111__0001_11_0010, // 11
         20'b1100_00_1110__0001_11_0010, // 12
         20'b1100_00_1111__0001_11_1100, // 13
         20'b1100_00_1111__0001_11_0100, // 14
         20'b1100_00_1111__0001_11_0100, // 15
         20'b1100_00_1111__0001_11_0100, // 16
         20'b1100_00_1111__0001_11_0100, // 17
         20'b1100_00_1111__0001_11_0100, // 18
         20'b1100_00_1111__0001_11_0100, // 19
         20'b1100_00_1111__0001_11_0100, // 20
         20'b1100_00_1110__0001_11_0100, // 21
         20'b1100_00_1110__0001_11_0100, // 22
         20'b1100_00_1110__0001_11_0100, // 23
         20'b1010_00_1111__0001_11_1000, // 24
         20'b1100_00_1101__0001_11_1000, // 25
         20'b0010_00_1100__0001_11_1000, // 26
         20'b1100_00_1101__0001_11_1000, // 27
         20'b1100_00_1101__0001_11_1000, // 28
         20'b1010_00_1111__0001_11_1000, // 29
         20'b1010_00_1111__0001_11_1000, // 30
         20'b1010_00_1111__0001_11_1000, // 31
         20'b0010_00_0111__0001_11_1000, // 32
         20'b1100_00_1100__0001_11_1000, // 33
         20'b1100_00_1100__0001_11_1000, // 34
         20'b1010_00_1110__0001_11_1000, // 35
         20'b0010_00_0110__0001_11_1000, // 36
         20'b0010_00_0110__0001_11_1000, // 37
         20'b0010_00_0110__0010_11_0100, // 38
         20'b1100_00_0111__0010_11_0100, // 39
         20'b0010_00_0110__0010_11_0100, // 40
         20'b0100_00_0100__0010_11_0100, // 41
         20'b0100_00_0100__0010_11_0100, // 42
         20'b0100_00_0100__0010_11_0100, // 43
         20'b0100_00_0100__0010_11_0100, // 44
         20'b0100_00_0100__0010_11_0100, // 45
         20'b0100_00_0100__0010_11_0100, // 46
         20'b1000_00_0011__0010_11_0100, // 47
         20'b1000_00_0011__0010_11_1000, // 48
         20'b1000_00_0011__0010_11_1000, // 49
         20'b1000_00_0011__0010_11_1000, // 50
         20'b1000_00_0011__0010_11_1000, // 51
         20'b1000_00_0011__0010_11_1000, // 52
         20'b1000_00_0011__0010_11_1000, // 53
         20'b1000_00_0011__0010_11_1000, // 54
         20'b1000_00_0011__0010_11_1000, // 55
         20'b1000_00_0011__0010_11_1000, // 56
         20'b1000_00_0011__0010_11_1000, // 57
         20'b1000_00_0011__0010_11_1000, // 58
         20'b1000_00_0011__0010_11_1000, // 59
         20'b1000_00_0011__0010_11_1000, // 60
         20'b1000_00_0011__0010_11_1000, // 61
         20'b1000_00_0011__0010_11_1000, // 62
         20'b1000_00_0011__0010_11_1000, // 63
         20'b1000_00_0011__0010_11_1000  // 64
      };
      
      // Set lookup_entry with the explicit bits from lookup with a part select
      lookup_entry = lookup[ ((divide-1)*20) +: 20];
      
      if(BANDWIDTH == "LOW") begin
         // Low Bandwidth
         v5_pll_filter_lookup=lookup_entry[9:0];
      end else begin
         // High or optimized bandwidth
         v5_pll_filter_lookup=lookup_entry[19:10];
      end
   end
endfunction

function [9:0] s6_pll_filter_lookup
   (
      input [6:0] divide, // Max divide is 64
      input [8*9:0] BANDWIDTH
   );
   
   reg [1279:0] lookup;
   
   reg [19:0] lookup_entry;
   
   begin
      lookup = {
         // This table is composed as:
         // High bndwidth__Low  bndwidth
         //   RES_LFHF_CP__RES_LFHF_CP
         20'b1011_11_0010__1101_11_0001,//1
         20'b1111_11_0101__1110_11_0001,//2
         20'b1011_11_0110__0001_11_0001,//3
         20'b1111_11_1110__0110_11_0001,//4
         20'b1011_11_1110__1010_11_0001,//5
         20'b1101_11_1110__1100_11_0001,//6
         20'b0011_11_1111__1100_11_0001,//7
         20'b0101_11_1111__1100_11_0001,//8
         20'b1001_11_1111__0010_11_0001,//9
         20'b1110_11_1110__0010_11_0001,//10
         20'b1110_11_1111__0100_11_0001,//11
         20'b0001_11_1111__0100_11_0001,//12
         20'b0001_11_1111__0100_11_0001,//13
         20'b0110_11_1110__0100_11_0001,//14
         20'b0110_11_1110__0100_11_0001,//15
         20'b1010_11_1110__0100_11_0001,//16
         20'b1010_11_1110__0100_11_0001,//17
         20'b1010_11_1111__0100_11_0001,//18
         20'b1010_11_1111__0100_11_0001,//19
         20'b1010_11_1111__0100_11_0001,//20
         20'b1010_11_1111__0100_11_0001,//21
         20'b1100_11_1101__1000_11_0001,//22
         20'b1100_11_1101__1000_11_0001,//23
         20'b1100_11_1110__1000_11_0001,//24
         20'b1100_11_1110__1000_11_0001,//25
         20'b1100_11_1111__1000_11_0001,//26
         20'b1100_11_1111__1000_11_0001,//27
         20'b1100_11_1111__1000_11_0001,//28
         20'b1100_11_1111__1000_11_0001,//29
         20'b1100_11_1111__1000_11_0001,//30
         20'b0010_11_1110__1000_11_0001,//31
         20'b0010_11_1110__1000_11_0001,//32
         20'b1100_11_1111__1000_11_0001,//33
         20'b1100_11_1111__1000_11_0001,//34
         20'b0010_11_1101__0100_11_0010,//35
         20'b0010_11_1101__0100_11_0010,//36
         20'b0100_11_1111__0100_11_0010,//37
         20'b0010_11_1100__0100_11_0010,//38
         20'b0010_11_1100__0100_11_0010,//39
         20'b0010_11_1100__0100_11_0010,//40
         20'b1000_11_0100__0100_11_0010,//41
         20'b1000_11_0100__0100_11_0010,//42
         20'b1000_11_0100__0100_11_0010,//43
         20'b0100_11_0101__1000_11_0010,//44
         20'b0010_11_0111__1000_11_0010,//45
         20'b1000_11_0011__1000_11_0010,//46
         20'b1000_11_0011__1000_11_0010,//47
         20'b1000_11_0011__1000_11_0010,//48
         20'b1000_11_0011__1000_11_0010,//49
         20'b1000_11_0011__1000_11_0010,//50
         20'b1000_11_0011__1000_11_0010,//51
         20'b1000_11_0011__1000_11_0010,//52
         20'b1000_11_0011__1000_11_0010,//53
         20'b1000_11_0011__1000_11_0010,//54
         20'b1000_11_0011__1000_11_0010,//55
         20'b1000_11_0011__1000_11_0010,//56
         20'b0100_11_0011__1000_11_0010,//57
         20'b0100_11_0011__1000_11_0010,//58
         20'b0100_11_0011__1000_11_0010,//59
         20'b0100_11_0011__1000_11_0010,//60
         20'b0100_11_0011__1000_11_0010,//61
         20'b0100_11_0011__1000_11_0010,//62
         20'b0100_11_0011__1000_11_0010,//63
         20'b0100_11_0011__1000_11_0010//64
      };
      
      // Set lookup_entry with the explicit bits from lookup with a part select
      lookup_entry = lookup[ ((64-divide)*20) +: 20];
      
      if(BANDWIDTH == "LOW") begin
         // Low Bandwidth
         s6_pll_filter_lookup=lookup_entry[9:0];
      end else begin
         // High or optimized bandwidth
         s6_pll_filter_lookup=lookup_entry[19:10];
      end
	  
	  $display("filter_lookup: %b", s6_pll_filter_lookup);
   end
   
endfunction

// This function takes in the divide, phase, and duty cycle settings to
// calculate the upper and lower counter registers.
function [37:0] v5_pll_count_calc
   (
      input [7:0] divide, // Max divide is 128
      input signed [31:0] phase,
      input [31:0] duty_cycle // Multiplied by 100,000
   );
   
   reg [13:0] div_calc;
   reg [16:0] phase_calc;
   
   begin
`ifdef DEBUG
      $display("pll_count_calc- divide:%h, phase:%d, duty_cycle:%d",
         divide, phase, duty_cycle);
`endif
   
      // w_edge[13], no_count[12], high_time[11:6], low_time[5:0]
      div_calc = pll_divider(divide, duty_cycle);
      // pm[8:6], dt[5:0]
      phase_calc = pll_phase(divide, phase);

      // Return value is the upper and lower address of counter
      //    Upper address is:
      //       RESERVED    [31:24]
      //       EDGE        [23]
      //       NOCOUNT     [22]
      //       DELAY_TIME  [21:16]
      //    Lower Address is:
      //       PHASE_MUX   [15:13]
      //       RESERVED    [12]
      //       HIGH_TIME   [11:6]
      //       LOW_TIME    [5:0]
      
`ifdef DEBUG
      $display("div:%d dc:%d phase:%d ht:%d lt:%d ed:%d nc:%d dt:%d pm:%d",
         divide, duty_cycle, phase, div_calc[11:6], div_calc[5:0], 
         div_calc[13], div_calc[12], phase_calc[5:0], phase_calc[8:6]);
`endif
      
      v5_pll_count_calc =
         {
            // Upper Address
            8'h00, div_calc[13:12], phase_calc[5:0], 
            // Lower Address
            phase_calc[8:6], 1'b0, div_calc[11:0]
         };
   end
endfunction

function [22:0] s6_pll_count_calc
   (
      input [7:0] divide, // Max divide is 128
      input signed [31:0] phase,
      input [31:0] duty_cycle // Multiplied by 100,000
   );
   
   reg [13:0] div_calc;
   reg [8:0] phase_calc;
   
   begin
`ifdef DEBUG
      $display("pll_count_calc- divide:%h, phase:%d, duty_cycle:%d",
         divide, phase, duty_cycle);
`endif
   
      // w_edge[13], no_count[12], high_time[11:6], low_time[5:0]
      div_calc = pll_divider(divide, duty_cycle);
      // pm[8:6], dt[5:0]
      phase_calc = pll_phase(divide, phase);

      // Return value is
      //       PHASE_MUX   [22:20]
      //       DELAY_TIME  [19:14]
      //       EDGE        [13]
      //       NOCOUNT     [12]
      //       HIGH_TIME   [11:6]
      //       LOW_TIME    [5:0]
      
`ifdef DEBUG
      $display("div:%d dc:%d phase:%d ht:%d lt:%d ed:%d nc:%d dt:%d pm:%d",
         divide, duty_cycle, phase, div_calc[11:6], div_calc[5:0], 
         div_calc[13], div_calc[12], phase_calc[5:0], phase_calc[8:6]);
`endif
      
      s6_pll_count_calc =
         {
			phase_calc[8:0], 
			div_calc[13:0]
         };
   end
endfunction
