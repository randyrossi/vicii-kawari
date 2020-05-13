`timescale 1ns / 1ps

// It's easier to initialize our state registers to
// raster_x,raster_y = (0,0) and let the fist tick bring us to
// raster_x=1 because that initial state is common to all chip types.
// If we wanted the first tick to produce raster_x,raster_y=(0,0)
// then we would have to initialize state to the last pixel
// of a frame which is different for each chip.  So remember we are
// starting things off with PHI LOW but already 1/4 the way
// through its phase and with DOT high but already on the second
// pixel.

module vicii(
   input [1:0] chip,
   input rst,
   input clk_dot4x,
   input clk_col4x,
   output clk_phi,
   output clk_colref,
   output[1:0] red,
   output[1:0] green,
   output[1:0] blue,
   output cSync,
   output [11:0] ado,
   input [11:0] adi,
   output reg [11:0] dbo,
   input [11:0] dbi,
   input ce,
   input rw,
   output irq,
   output aec,
   output ba,
   output ras,
   output cas,
   
   // For simulation
   reg [3:0] vicCycle,
   output reg[15:0] rasr,
   output reg[15:0] casr,
   output reg[15:0] muxr,
   output reg[7:0] refc
);

parameter CHIP6567R8   = 2'd0;
parameter CHIP6567R56A = 2'd1;
parameter CHIP6569     = 2'd2;
parameter CHIPUNUSED   = 2'd3;

// Cycle types
parameter VIC_LP   = 0; // low phase, sprite pointer
parameter VIC_LPI2 = 1; // low phase, sprite idle
parameter VIC_LS2  = 2; // low phase, sprite dma byte 2 
parameter VIC_LR   = 3; // low phase, dram refresh
parameter VIC_LG   = 4; // low phase, g-access
parameter VIC_HS1  = 5; // high phase, sprite dma byte 1
parameter VIC_HPI1 = 6; // high phase, sprite idle
parameter VIC_HPI2 = 7; // high phase, sprite idle
parameter VIC_HS3  = 8; // high phase, sprite dma byte 3
parameter VIC_HRI  = 9; // high phase, refresh idle
parameter VIC_HRC  = 10; // high phase, c-access after r
parameter VIC_HGC  = 11; // high phase, c-access after g
parameter VIC_HGI  = 12; // high phase, idle after g
parameter VIC_HI   = 13; // high phase, idle
parameter VIC_LI   = 14; // low phase, idle

// These are the only valid combinations
// for phase 1 and 2. Idle 2nd phase is
// CPU bus access.
// II, PI, PS, SS, RI, RC, GC, GI

// BA must go low 3 cycles before PS, SS, RC & GC
// BA can go high again at any *I unless
// one of PS, SS, RC & GC are within 3 upcoming
// cycles

// AEC is LOW for PHI LOW phase (vic) and HIGH for PHI 
// HIGH phase (cpu) but kept LOW in PHI HIGH phase if vic
// 'stole' a cpu cycle.

// Limits for different chips
reg [9:0] rasterXMax;
reg [8:0] rasterYMax;
reg [9:0] hSyncStart;
reg [9:0] hSyncEnd;
reg [9:0] hVisibleStart;
reg [8:0] vBlankStart;
reg [8:0] vBlankEnd;

//clk_dot4x;     32.272768 Mhz NTSC
//clk_col4x;     14.381818 Mhz NTSC
wire clk_dot;  // 8.18181 Mhz NTSC
// clk_colref     3.579545 Mhz NTSC
// clk_phi        1.02272 Mhz NTSC

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:
   begin
      rasterXMax = 10'd519;     // 520 pixels 
      rasterYMax = 9'd261;      // 262 lines
      hSyncStart = 10'd406;
      hSyncEnd = 10'd443;       // 4.6us
      hVisibleStart = 10'd494;  // 10.7us after hSyncStart seems to work
      vBlankStart = 9'd11;
      vBlankEnd = 9'd19;
   end
CHIP6567R56A:
   begin
      rasterXMax = 10'd511;     // 512 pixels
      rasterYMax = 9'd260;      // 261 lines
      hSyncStart = 10'd406;
      hSyncEnd = 10'd443;       // 4.6us
      hVisibleStart = 10'd494;  // 10.7us after hSyncStart seems to work
      vBlankStart = 9'd11;
      vBlankEnd = 9'd19;
   end
CHIP6569,CHIPUNUSED:
   begin
      rasterXMax = 10'd503;     // 504 pixels
      rasterYMax = 9'd311;      // 312
      hSyncStart = 10'd408;
      hSyncEnd = 10'd444;       // ~4.6us
      hVisibleStart = 10'd492;  // ~10.7 after hSyncStart
      vBlankStart = 9'd301;
      vBlankEnd = 9'd309;
   end
endcase

  // used to generate phi and dot clocks
  reg [31:0] phir;
  reg [31:0] dotr;
  
  // used to detect rising edge of dot clock inside a dot4x always block
  reg [15:0] dot_risingr;
  wire dot_rising;
  
  // cycle steal - current : 1 bit high that represents the
  // current cycle we are in. Used to check cycle_stba to
  // determine the value of BA and cycle_staec to determine
  // the value of AEC
  reg [64:0] cycle_stc;
  
  // cycle steal - ba : When masked with cycle_stc, determines
  // whether BA should be HIGH or LOW.  > 0 = HIGH, otherwise LOW
  reg [64:0] cycle_stba;
  
  // cycle steal - When a condition arises that makes it known that
  // N cycles need be stolen M cycles from now, these registers
  // are ANDed with cycle_stba to make sure BA goes low in advance. 
  // cycle_st_N_in_M
  reg [64:0] cycle_st1_in_3_ba;
  reg [64:0] cycle_st2_in_3_ba;

  // Same idea as cycle steal above except marks when AEC should
  // remain low in 2nd phi phase.
  reg [64:0] cycle_staec;
  reg [64:0] cycle_st1_in_3_aec;
  reg [64:0] cycle_st2_in_3_aec;
  
  // Divides the color4x clock by 4 to get color reference clock
  clk_div4 clk_colorgen (
     .clk_in(clk_col4x),     // from 4x color clock
     .reset(rst),
     .clk_out(clk_colref)    // create color ref clock
  );

  // current raster x and line position
  reg [9:0] raster_x;
  reg [8:0] raster_line;
  
  // xpos is the x coordinate relative to raster irq
  // It is not simply raster_x with an offset, it does not
  // increment on certain cycles for 6567R8
  // chips and wraps at the high phase of cycle 12.
  reg [9:0] xpos;

  // What cycle we are on:
  //reg [2:0] vicCycle;

  // DRAM refresh counter
//  reg [7:0] refc;

  // When enabled, sprite bytes are fetched in sprite cycles
  reg spriteDmaEn;
  
  // Counters for sprite, refresh and idle cycles
  reg [2:0] spriteCnt;
  reg [2:0] refreshCnt;
  reg [2:0] idleCnt;

  // VIC read address
  reg [13:0] vicAddr;
  
  // cycle_num : Each cycle is 8 pixels.
  // 6567R56A : 0-63
  // 6567R8   : 0-64
  // 6569     : 0-62
  wire [6:0] cycle_num;

  // bit_cycle : The pixel number within the line cycle.
  // 0-7
  wire [2:0] bit_cycle;
  
  // char_line_num : For text mode, what character line are we on.
  reg [2:0] char_line_num;

  // ec : border (edge) color
  reg [3:0] ec;
  // b#c : background color registers
  reg [3:0] b0c,b1c,b2c,b3c;
  reg [3:0] mm0,mm1;
  
  ///////////// TEMPORARY STUFF
  wire visible_horizontal;
  wire visible_vertical;
  wire WE;
  ///////////// END TEMPORARY STUFF

  // lower 8 bits of ado are muxed
  reg [7:0] ado8;
  
  // lets us detect when a phi phase is
  // starting within a 4x dot always block
  // phi_phase_start[15]==1 means phi will be HIGH next tick
  reg [15:0] phi_phase_start;

  //reg [15:0] rasr;
  //reg [15:0] casr;
  //reg [15:0] muxr;

  // mux last 8 bits of read address
  wire mux;

  // tracks whether the condition for triggering these
  // types of interrupts happened, but may not be
  // reported via irq unless enabled
  reg irst;
  reg ilp;
  reg immc;
  reg imbc;

  // interrupt latches for $d019, these are set HIGH when
  // an interrupt of that type occurs. They are not automatically
  // cleared by the VIC.
  reg irst_clr;
  reg imbc_clr;
  reg immc_clr;
  reg ilp_clr;

  // interrupt enable registers for $d01a, these determine
  // if these types of interrupts will make irq low
  reg erst;
  reg embc;
  reg emmc;
  reg elp;

  reg [8:0] rasterCmp;
  reg rasterIrqDone;

  // Initialization section
  initial
  begin
    raster_x           = 10'd0;
    case(chip)
    CHIP6567R8:          xpos = 10'h19c;
    CHIP6567R56A:        xpos = 10'h19c;
    CHIP6569,CHIPUNUSED: xpos = 10'h194;
    endcase
    raster_line        = 9'd0;
    cycle_stc          = 65'b00000000000000000000000000000000000000000000000000000000000000001;
    cycle_stba         = 65'b11111111111111111111111111111111111111111111111111111111111111111;
    cycle_st1_in_3_ba  = 65'b11111111111111111111111111111111111111111111111111111111111100001;
    cycle_st2_in_3_ba  = 65'b11111111111111111111111111111111111111111111111111111111111000001;
    cycle_staec        = 65'b11111111111111111111111111111111111111111111111111111111111111111;
    cycle_st1_in_3_aec = 65'b11111111111111111111111111111111111111111111111111111111111101111;
    cycle_st2_in_3_aec = 65'b11111111111111111111111111111111111111111111111111111111111001111;
    refc               = 8'hff;
    vicAddr            = 14'b0;
    vicCycle           = VIC_LP;
    phi_phase_start    = 16'b0000000000000100;
    dot_risingr        = 16'b0100010001000100;
    phir               = 32'b00000000000000111111111111111100;
    dotr               = 32'b00110011001100110011001100110011;
    
    // These start after 3 rotations from their usual start
    // positions since we always begin on pixel 1 (not 0).
    // So that's 4 dot4x ticks to get to the right spot
    // 3 on init and 1 more initial tick makes 4.
    rasr = 16'b1111000000000000;
    casr = 16'b1111110000000000;
    muxr = 16'b1111100000000000;

    rasterIrqDone = 1'b1;    
    rasterCmp = 9'b100;
    irst = 1'b0;
    embc = 1'b0;
    emmc = 1'b0;
    elp = 1'b0;
    
    spriteCnt = 3'd3;
    refreshCnt = 3'd0;
    idleCnt = 3'd0;
    spriteDmaEn = 1'b0;
  end
  
  always @(posedge clk_dot4x)
  if (rst)
        dot_risingr <= 16'b1000100010001000;
  else
        dot_risingr <= {dot_risingr[14:0], dot_risingr[15]};
  assign dot_rising = dot_risingr[15];

  always @(posedge clk_dot4x)
  if (rst)
        phir <= 32'b00000000000000001111111111111111;
  else
        phir <= {phir[30:0], phir[31]};
  assign clk_phi = phir[31];

  always @(posedge clk_dot4x)
  if (rst)
        dotr <= 32'b11001100110011001100110011001100;
  else
        dotr <= {dotr[30:0], dotr[31]};
  assign clk_dot = dotr[31];

  always @(posedge clk_dot4x)
  if (rst) begin
     phi_phase_start <= 16'b1000000000000000;
  end else
     phi_phase_start <= {phi_phase_start[14:0], phi_phase_start[15]};

  // The bit_cycle (0-7) is taken from the raster_x
  assign bit_cycle = raster_x[2:0];
  // This is simply raster_x divided by 8.
  assign cycle_num = raster_x[9:3];
  
  
  // Raise raster irq once per raster line
  // On raster line 0, it happens on cycle 1, otherwise, cycle 0
  always @(posedge clk_dot4x)
  begin
     if (clk_phi && phi_phase_start[15] &&
       ((raster_line == 0 && cycle_num == 1) || (raster_line != 0 && cycle_num == 0)))
       rasterIrqDone <= 1'b0;
     if (irst_clr)
       irst <= 1'b0;
     if (rasterIrqDone == 1'b0 && raster_line == rasterCmp) begin
       rasterIrqDone <= 1'b1;
       if ((raster_line == 0 && cycle_num == 1) || (raster_line != 0 && cycle_num == 0)) begin
          irst <= 1'b1;
       end
     end
  end
  
  assign irq = (ilp & elp) | (immc & emmc) | (imbc & embc) | (irst & erst);
 
 
  // DRAM refresh counter
  always @(posedge clk_dot4x)
  if (rst)
     refc <= 8'hff;
  else if (phi_phase_start[15]) begin
     // About to leave LR into HRC or HRI
     if (vicCycle == VIC_LR)
         refc <= refc - 8'd1;
     else if (raster_x == rasterXMax && raster_line == rasterYMax)
         refc <= 8'hff;
  end
  
  
  // Update x,y position
  always @(posedge clk_dot4x)
  if (rst)
  begin
    raster_x <= 0;
    raster_line <= 0;
    case(chip)
    CHIP6567R56A, CHIP6567R8:
      xpos <= 10'h19d;
    CHIP6569, CHIPUNUSED:
      xpos <= 10'h195;
    endcase
  end
  else if (dot_rising)
  if (raster_x < rasterXMax)
  begin
    // Can advance to next pixel
    raster_x <= raster_x + 10'd1;
    
    // Handle xpos move but deal with special cases
    case(chip)
    CHIP6567R8:
        if (cycle_num == 7'd0 && bit_cycle == 3'd0)
           xpos <= 10'h19d;
        else if (cycle_num == 7'd60 && bit_cycle == 3'd7)
           xpos <= 10'h184;
        else if (cycle_num == 7'd61 && (bit_cycle == 3'd3 || bit_cycle == 3'd7))
           xpos <= 10'h184;
        else if (cycle_num == 7'd12 && bit_cycle == 3'd3)
           xpos <= 10'h0;
        else
           xpos <= xpos + 10'd1;
    CHIP6567R56A:
        if (cycle_num == 7'd0 && bit_cycle == 3'd0)
           xpos <= 10'h19d;
        else if (cycle_num == 7'd12 && bit_cycle == 3'd3)
           xpos <= 10'h0;
        else
           xpos <= xpos + 10'd1;
    CHIP6569, CHIPUNUSED:
        if (cycle_num == 7'd0 && bit_cycle == 3'd0)
           xpos <= 10'h195;
        else if (cycle_num == 7'd12 && bit_cycle == 3'd3)
           xpos <= 10'h0;
        else
           xpos <= xpos + 10'd1;
    endcase
  end
  else  
  begin
    // Time to go back to x coord 0
    raster_x <= 10'd0;

    // xpos also goes back to start value
    case(chip)
    CHIP6567R56A, CHIP6567R8:
      xpos <= 10'h19c;
    CHIP6569, CHIPUNUSED:
      xpos <= 10'h194;
    endcase

    if (raster_line < rasterYMax) begin
       // Move to next raster line
       raster_line <= raster_line + 9'd1;
    end
    else begin
       // Time to go back to y coord 0, reset refresh counter
       raster_line <= 9'd0;
    end
  end



// cycle stealing registers let us 'schedule' when ba/aec
// should be held low a number of cycles in advance and for
// a number of cycles.  For example, if a condition arises
// in which you know you will need the bus for two phi HIGH
// cycles 3 cycles from now, you would do this:
// cycle_stba <= cycle_stba & cycle_st2_in_3_ba
// cycle_staec <= cycle_st2_in_3_aec & cycle_st2_in_3_aec

always @(posedge clk_dot4x)
  if (rst) begin
    cycle_stc          <= 65'b00000000000000000000000000000000000000000000000000000000000000001;
    cycle_stba         <= 65'b11111111111111111111111111111111111111111111111111111111111111111;
    cycle_st1_in_3_ba  <= 65'b11111111111111111111111111111111111111111111111111111111111100001;
    cycle_st2_in_3_ba  <= 65'b11111111111111111111111111111111111111111111111111111111111000001;
    cycle_staec        <= 65'b11111111111111111111111111111111111111111111111111111111111111111;
    cycle_st1_in_3_aec <= 65'b11111111111111111111111111111111111111111111111111111111111101111;
    cycle_st2_in_3_aec <= 65'b11111111111111111111111111111111111111111111111111111111111001111;
  end
  else if (dot_rising)
    if (bit_cycle == 3'd7) // going to next cycle?
    begin
      case (chip)
      CHIP6567R8:
      begin
        cycle_stc <= {cycle_stc[63:0], cycle_stc[64]};
        cycle_st1_in_3_ba <= {cycle_st1_in_3_ba[63:0], cycle_st1_in_3_ba[64]};
        cycle_st2_in_3_ba <= {cycle_st2_in_3_ba[63:0], cycle_st2_in_3_ba[64]};
        cycle_st1_in_3_aec <= {cycle_st1_in_3_aec[63:0], cycle_st1_in_3_aec[64]};
        cycle_st2_in_3_aec <= {cycle_st2_in_3_aec[63:0], cycle_st2_in_3_aec[64]};
      end
      CHIP6567R56A:
      begin
        cycle_stc <= {1'b0,cycle_stc[62:0],cycle_stc[63]};
        cycle_st1_in_3_ba <= {1'b1, cycle_st1_in_3_ba[62:0], cycle_st1_in_3_ba[63]};
        cycle_st2_in_3_ba <= {1'b1, cycle_st2_in_3_ba[62:0], cycle_st2_in_3_ba[63]};
        cycle_st1_in_3_aec <= {1'b1, cycle_st1_in_3_aec[62:0], cycle_st1_in_3_aec[63]};
        cycle_st2_in_3_aec <= {1'b1, cycle_st2_in_3_aec[62:0], cycle_st2_in_3_aec[63]};
      end
      CHIP6569,CHIPUNUSED:
      begin
        cycle_stc <= {2'b00,cycle_stc[61:0],cycle_stc[62]};
        cycle_st1_in_3_ba <= {2'b11, cycle_st1_in_3_ba[61:0],cycle_st1_in_3_ba[62]};
        cycle_st2_in_3_ba <= {2'b11, cycle_st2_in_3_ba[61:0],cycle_st2_in_3_ba[62]};
        cycle_st1_in_3_aec <= {2'b11, cycle_st1_in_3_aec[61:0],cycle_st1_in_3_aec[62]};
        cycle_st2_in_3_aec <= {2'b11, cycle_st2_in_3_aec[61:0],cycle_st2_in_3_aec[62]};
      end
      endcase
    end
  
  // cycle_stba masked with cycle_stc tells us if ba should go low
  assign ba = (cycle_stba & cycle_stc) == 0 ? 0 : 1;
  
  // First phase, always low
  // Second phase, low if cycle steal reg says so, otherwise high for CPU
  assign aec = bit_cycle < 4 ? 0 : ((cycle_staec & cycle_stc) == 0 ? 0 : 1);

  // LP --dmaEn--> HS1 -> LS2 -> HS3  --<7?--> LP
  //                                  --else-> LR
  //    --else---> HPI -> LPI2-> HPI2 --<7>--> LP 
  //                                  --else-> LR
  //
  // LR --4&d?--> HRC -> LG
  // LR --else--> HRI --4?--> LG
  //                  -else-> LR
  //
  // LG --54?--> HI
  //    --d? --> HC
  //    --else-> HGI
  //
  // HC -> LG
  // HGI -> LG
  // HI --2|3|4?--> LP
  //      --else--> LI
  // LI -> HI
   
  always @(posedge clk_dot4x)
     if (phi_phase_start[15]) begin
       if (clk_phi == 1'b0) begin // about to go phi high
          case (vicCycle)
             VIC_LP: begin
                if (spriteDmaEn)
                   vicCycle <= VIC_HS1;
                else
                   vicCycle <= VIC_HPI1;
             end
             VIC_LPI2:
                   vicCycle <= VIC_HPI2;
             VIC_LS2:
                vicCycle <= VIC_HS3;
             VIC_LR: begin
                if (refreshCnt == 4 && raster_line == 1)
                    vicCycle <= VIC_HRC;
                else
                    vicCycle <= VIC_HRI;
             end
             VIC_LG: begin
                if (cycle_num == 54) begin
                      vicCycle <= VIC_HI;
                      idleCnt <= 0;
                end else
                   if (raster_line == 1)
                      vicCycle <= VIC_HGC;
                   else
                      vicCycle <= VIC_HGI;
                end
             VIC_LI: vicCycle <= VIC_HI;
             default: ;
          endcase
       end else begin // about to go phi low
          case (vicCycle)
             VIC_HS1: vicCycle <= VIC_LS2;
             VIC_HPI1: vicCycle <= VIC_LPI2;
             VIC_HS3, VIC_HPI2: begin
                 if (spriteCnt == 7) begin
                    vicCycle <= VIC_LR;
                    spriteCnt <= 0;
                    refreshCnt <= 0;
                 end else begin
                    vicCycle <= VIC_LP;
                    spriteCnt <= spriteCnt + 1'd1;
                 end
             end
             VIC_HRI: begin
                 if (refreshCnt == 4) begin
                    vicCycle <= VIC_LG;
                 end else begin
                    vicCycle <= VIC_LR;
                    refreshCnt <= refreshCnt + 1'd1;
                 end
             end
             VIC_HRC: begin
                 vicCycle <= VIC_LG;
             end
             VIC_HGC, VIC_HGI: vicCycle <= VIC_LG;
             VIC_HI: begin
                 if (chip == CHIP6567R56A && idleCnt == 3)
                    vicCycle <= VIC_LP;
                 else if (chip == CHIP6567R8 && idleCnt == 4)
                    vicCycle <= VIC_LP;
                 else if (chip == CHIP6569 && idleCnt == 2)
                    vicCycle <= VIC_LP;
                 else begin
                    idleCnt <= idleCnt + 1'd1;
                    vicCycle <= VIC_LI;
                 end
             end
             default: ;
          endcase
       end
     end
     
    
  // RAS/CAS/MUX profiles
  always @(posedge clk_dot4x)
  if (rst) begin
     rasr <= 16'b1111111111111111;
     casr <= 16'b1111111111111111;
  end
  else if (phi_phase_start[15]) begin
    // Here we check bit cycle = 7 to indicate we will
    // transition from high to low phi for this delayed
    // assignment.
    if (bit_cycle == 3'd7) // phi going low
    case (vicCycle)
    VIC_LPI2, VIC_LI: begin
             rasr <= 16'b1111111111111111;
             casr <= 16'b1111111111111111;
           end
    default: begin
             rasr <= 16'b1111111000000000;
             casr <= 16'b1111111110000000;
           end
    endcase
    else if (bit_cycle == 3'd3) begin // phi going high
       rasr <= 16'b1111111000000000;
       casr <= 16'b1111111110000000;
    end
  end else begin
    rasr <= {rasr[14:0],1'b0};
    casr <= {casr[14:0],1'b0};
  end
    
  assign ras = rasr[15];
  assign cas = casr[15];

  always @(posedge clk_dot4x)
  if (rst)
     muxr <= 16'b1111111111111111;
  // Must be one dot4x cycle earlier than condition above
  // because ado is delayed assignment not like ras/cas
  // above. Necessary to get mux to happen between ras/cas
  // as expected.
  else if (phi_phase_start[14])
    // Here we check bit cycle = 7 to indicate we will be
    // transitioning from high low phi on next tick for
    // this delayed assignment
    if (bit_cycle == 3'd7) // phi going low
    case (vicCycle)
    VIC_LPI2, VIC_LI: muxr <= 16'b1111111111111111;
    VIC_LR:           muxr <= 16'b0000000000000000;
    default:          muxr <= 16'b1111111100000000;
    endcase
    else if (bit_cycle == 3'd3) // phi going high
                      muxr <= 16'b1111111100000000;
  else
    muxr <= {muxr[14:0],1'b0};

  assign mux = muxr[15];

  always @(posedge clk_dot4x)
  if (rst)
     ado8 <= 8'hFF;
  else
     ado8 <= mux ? {2'b11, vicAddr[13:8]} : vicAddr[7:0];
  assign ado = {vicAddr[11:8], ado8};
  
  ///////// BEGIN TEMP STUFF
 // Stuff like this won't work in the real core. There is no comparitor controlling
  // when the border is visible like this.
  assign visible_vertical = (raster_line >= 51) & (raster_line < 251) ? 1 : 0;
  // Official datasheet says 28-348 but Christian's doc says 24-344
  assign visible_horizontal = (xpos >= 24) & (xpos < 344) ? 1 : 0;
  assign WE = visible_horizontal & visible_vertical & (bit_cycle == 2) & (char_line_num == 0);

  reg [11:0] char_buffer [39:0];
  reg [11:0] char_buffer_out;
  reg [5:0] char_buf_pos;

 always @(posedge clk_dot)
  if (WE)
    begin
      char_buffer[char_buf_pos] <= 12'b000000000000;
      char_buffer_out <= 12'b000000000000;
    end
  else
    char_buffer_out <= char_buffer[char_buf_pos];

  always @(posedge clk_dot)
    if (!visible_vertical)
      char_line_num <= 0;
    else if (raster_x == 384)
      char_line_num <= char_line_num + 1;

  always @(posedge clk_dot)
    if (!visible_vertical)
      char_buf_pos <= 0;
    else if (bit_cycle == 0 & visible_horizontal)
    begin
      if (char_buf_pos < 39)
        char_buf_pos <= char_buf_pos + 1;
      else
        char_buf_pos <= 0;
    end

  reg [9:0] screen_mem_pos;
  always @(posedge clk_dot)
    if (!visible_vertical)
       screen_mem_pos <= 0;
    else if (bit_cycle == 0 & visible_horizontal & char_line_num == 0)
       screen_mem_pos <= screen_mem_pos + 1;

//  always @*
//    if (bit_cycle == 1)
//       addr = {4'b1, screen_mem_pos};

//    always @*
//     if (bit_cycle == 1)
//       addr = {4'b1, screen_mem_pos};
//     else
//       addr = {3'b010,char_buffer_out[7:0],char_line_num};

  wire [3:0] out_color;
  wire [3:0] out_pixel;
  reg [7:0] pixel_shift_reg;
  reg [3:0] color_buffered_val;

  assign out_color = pixel_shift_reg[7] == 1 ? color_buffered_val : b0c; // 4'd6
  assign out_pixel = visible_vertical & visible_horizontal ? out_color : ec; // 4'd14

  always @(posedge clk_dot)
  if (bit_cycle == 7)
    color_buffered_val <= char_buffer_out[11:8];

  always @(posedge clk_dot)
  if (bit_cycle == 7)
      pixel_shift_reg <= 8'b00000000;  //    pixel_shift_reg <= data[7:0];
  else
      pixel_shift_reg <= {pixel_shift_reg[6:0],1'b0};


  ///////// END TEMP STUFF


  // Translate out_pixel (indexed) to RGB values
  color viccolor(
     .chip(chip),
     .x_pos(xpos),
     .y_pos(raster_line),
     .out_pixel(out_pixel),
     .hSyncStart(hSyncStart),
     .hVisibleStart(hVisibleStart),
     .vBlankStart(vBlankStart),
     .vBlankEnd(vBlankEnd),
     .red(red),
     .green(green),
     .blue(blue)
  );

  // Generate cSync signal
  sync vicsync(
     .chip(chip),
     .rst(rst),
     .clk(clk_dot4x),
     .rasterX(xpos),
     .rasterY(raster_line),
     .hSyncStart(hSyncStart),
     .hSyncEnd(hSyncEnd),
     .cSync(cSync)
  );
  
// Register Read/Write
always @(posedge clk_dot4x)
if (rst) begin
  ec <= 4'd0;
  b0c <= 4'd0;
end
else begin
 if (!ce) begin
   // READ from register
   if (clk_phi && rw) begin
      dbo <= 12'hFF;
      case(adi[5:0])
      6'h19:  dbo[7:0] <= {!irq,3'b111,ilp,immc,imbc,irst};
      6'h1A:  dbo[7:0] <= {4'b1111,elp,emmc,embc,erst};
      6'h20:  dbo[3:0] <= ec;
      6'h21:  dbo[3:0] <= b0c;
      default: ;
      endcase
   end
   // WRITE to register
   // This sets the register at any time rw and ce are low but
   // it may be more correct to do it only on the falling edge
   // of phi. VICE seems to think registers can get set by
   // the 2nd rising dot within it's phi phase but I doubt that's
   // the case on real hardware.  This is probably because VICE
   // first emulates the CPU ticks which changes memory followed
   // by all VIC 8 pixels so it 'sees' the change too early. But
   // on real hardware, vic's pixels are output in parallel with
   // the CPU phase and it would not be able to see the register
   // change (likely) until the falling edge of phi.  Does it
   // change registers on some other edge perhaps?
   else begin //if (phi_phase_start[15] && bit_cycle == 3'd7 ) begin // falling phi edge
      irst_clr <= 1'b0;
      imbc_clr <= 1'b0;
      immc_clr <= 1'b0;
      ilp_clr <= 1'b0;
      if (!rw) begin
         case(adi[5:0])
         6'h19:  begin
           irst_clr <= dbi[0];
           imbc_clr <= dbi[1];
           immc_clr <= dbi[2];
           ilp_clr <= dbi[3];
           end
         6'h1A:  begin
           erst <= dbi[0];
           embc <= dbi[1];
           emmc <= dbi[2];
           elp <= dbi[3];
           end
         6'h20:  ec <= dbi[3:0];
         6'h21:  b0c <= dbi[3:0];
         default: ;
         endcase
      end
   end
 end
end
  
endmodule