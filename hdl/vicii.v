`timescale 1ns / 1ps

`include "common.vh"

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
   input chip_type chip,
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
   input [5:0] adi,
   output reg [11:0] dbo,
   input [11:0] dbi,
   input ce,
   input rw,
   output irq,
   output reg aec,
   output ba,
   output ras,
   output cas,
   output ls245_oe,
   output ls245_dir,
   output vic_write_db,
   output vic_write_ab,
   
   output mux,
   output clk_dot
);

// Register write phi_phase_start data available
`define REG_DAV 7
// Char read phi_phase_start data available
`define CHAR_DAV 13
// Pixel read phi_phase_start data available
`define PIXEL_DAV 13
// How many dot ticks we need to delay out pixels before they get into the shifter
`define PIXEL_DELAY 8

`define NUM_SPRITES 8

// BA must go low 3 cycles before HS1, HS3, HRC & HGC

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

//clk_dot4x;     32.272768 Mhz NTSC, 31.527955 Mhz PAL
//clk_col4x;     14.318181 Mhz NTSC, 17.734475 Mhz PAL
//wire clk_dot;  // 8.18181 Mhz NTSC, 7.8819888 Mhz PAL
// clk_colref     3.579545 Mhz NTSC, 4.43361875 Mhz PAL
// clk_phi        1.02272 Mhz NTSC, .985248 Mhz PAL

// TODO: For the R56A, add an option to use an alternate
// clock of 32.160296 (8.040074 dot clock) to get a frequency
// closer to 15.734Khz horizontal frequency.  Some monitors
// are less forgiving when the R56A produces a hfreq outside
// the range they are expecting.

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:
   begin
      rasterXMax = 10'd519;     // 520 pixels 
      rasterYMax = 9'd262;      // 263 lines
      hSyncStart = 10'd406;
      hSyncEnd = 10'd443;       // 4.6us
      hVisibleStart = 10'd494;  // 10.7us after hSyncStart seems to work
      vBlankStart = 9'd11;
      vBlankEnd = 9'd19;
   end
CHIP6567R56A:
   begin
      rasterXMax = 10'd511;     // 512 pixels
      rasterYMax = 9'd261;      // 262 lines
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
  
  // Divides the color4x clock by 4 to get color reference clock
  clk_div4 clk_colorgen (
     .clk_in(clk_col4x),     // from 4x color clock
     .reset(rst),
     .clk_out(clk_colref)    // create color ref clock
  );

  // current raster x and line position
  reg [9:0] raster_x;
  reg [8:0] raster_line;
  reg allow_bad_lines;
  
  // According to VICE, reg11 is delayed by 1 cycle. TODO: confirm this
  reg [7:0] reg11_delayed;
  
  // A counter that increments with each dot4x clock tick
  // Used for precise timing within a phase for some circumstances
  reg [4:0] cycle_fine_ctr;
  
  // xpos is the x coordinate relative to raster irq
  // It is not simply raster_x with an offset, it does not
  // increment on certain cycles for 6567R8
  // chips and wraps at the high phase of cycle 12.
  reg [9:0] xpos;

  // What cycle we are on:
  reg [3:0] vicCycle;
  vic_cycle vicPreCycle;
  
  // DRAM refresh counter
  reg [7:0] refc;

  // When enabled, sprite bytes are fetched in sprite cycles
  reg spriteDmaEn;
  
  // Counters for sprite, refresh and idle 'stretches' for
  // the vicCycle state machine.
  reg [2:0] spriteCnt;
  reg [2:0] refreshCnt;
  reg [2:0] idleCnt;

  // VIC read address
  reg [13:0] vicAddr;
  reg [3:0] vm;
  reg [2:0] cb;

  // cycle_num : Each cycle is 8 pixels.
  // 6567R56A : 0-63
  // 6567R8   : 0-64
  // 6569     : 0-62
  wire [6:0] cycle_num;

  // bit_cycle : The pixel number within the line cycle.
  // 0-7
  wire [2:0] bit_cycle;
  
  // ec : border (edge) color
  vic_color ec;
  // b#c : background color registers
  vic_color b0c,b1c,b2c,b3c;
    
  // lower 8 bits of ado are muxed
  reg [7:0] ado8;
  
  // lets us detect when a phi phase is
  // starting within a 4x dot always block
  // phi_phase_start[15]==1 means phi will transition next tick
  reg [15:0] phi_phase_start;

  // determines timing within a phase when RAS,CAS and MUX will
  // fall.  (MUX determines when address transition occurs which
  // should be between RAS and CAS. MUXR falls one cycle early
  // because mux is then used in a delayed assignment for ado
  // which makes the transition happen between RAS and CAS.)
  reg [15:0] rasr;
  reg [15:0] casr;
  reg [15:0] muxr;

  // muxes the last 8 bits of our read address for CAS/RAS latches
  //wire mux;

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

  // if enabled, what raster line do we trigger irq for irst?
  reg [8:0] rasterCmp;
  reg rasterIrqDone;
  
  reg [9:0] vcBase; // video counter base
  reg [9:0] vc; // video counter
  reg [2:0] rc; // row counter
  reg idle;

  reg den; // display enable
  reg bmm; // bitmap mode
  reg ecm; // extended color mode
  reg [2:0] xscroll;
  reg [2:0] yscroll;
  
  reg rsel; // border row select
  reg csel; // border column select
  reg mcm; // multi color mode
  reg res; // no function

  integer n;
  reg [11:0] nextChar;
  reg [11:0] charbuf [38:0];

  reg [11:0] readChar;
  reg [7:0] readPixels;
  
  reg [11:0] waitingChar[`PIXEL_DELAY + 1];
  reg [7:0] waitingPixels[`PIXEL_DELAY + 1];

  reg [11:0] shiftingChar;
  reg [7:0] shiftingPixels;

  reg baChars;
  reg badline;

  reg [8:0] sprite_x[0:`NUM_SPRITES - 1];
  reg [7:0] sprite_y[0:`NUM_SPRITES - 1];
  reg [7:0] sprite_pri;
  vic_color sprite_col[0:`NUM_SPRITES - 1];
  vic_color sprite_mc0, sprite_mc1;
  reg [7:0] sprite_en;
  reg [7:0] sprite_xe;
  reg [7:0] sprite_ye;
  reg [7:0] sprite_mmc;
  reg [7:0] sprite_m2m;
  reg [7:0] sprite_m2d;
  
  // dot_risingr[15] means dot going high next cycle
  always @(posedge clk_dot4x)
  if (rst)
        dot_risingr <= 16'b1000100010001000;
  else
        dot_risingr <= {dot_risingr[14:0], dot_risingr[15]};
  
  // drives the dot clock
  always @(posedge clk_dot4x)
  if (rst)
        dotr <= 32'b01100110011001100110011001100110;
  else
        dotr <= {dotr[30:0], dotr[31]};
  assign clk_dot = dotr[31];

  // phir[31]=HIGH means phi is high next cycle
  always @(posedge clk_dot4x)
  if (rst)
        phir <= 32'b00000000000011111111111111110000;
  else
        phir <= {phir[30:0], phir[31]};
  assign clk_phi = phir[0];

  // phi_phase_start[15]=HIGH means phi is high next cycle
  always @(posedge clk_dot4x)
  if (rst) begin
     phi_phase_start <= 16'b0000000000001000;
  end else
     phi_phase_start <= {phi_phase_start[14:0], phi_phase_start[15]};

  // The bit_cycle (0-7) is taken from the raster_x
  assign bit_cycle = raster_x[2:0];
  // This is simply raster_x divided by 8.
  assign cycle_num = raster_x[9:3];
  
  // allow_bad_lines goes high on line 48
  // if den is high at any point on line 48
  // allow_bad_lines falls on line 248
  // den only takes effect on line 48
  always @(posedge clk_dot4x)
  begin
     if (rst)
        allow_bad_lines <= 1'b0;
     else if (dot_risingr[0]) begin
       if (raster_line == 48 && den == 1'b1)
          allow_bad_lines <= 1'b1;
       if (raster_line == 248)
          allow_bad_lines <= 1'b0;
     end 
  end

  // use delayed reg11 for yscroll
  always @(raster_line, reg11_delayed, allow_bad_lines)
  begin
     badline = 1'b0;
     if (raster_line[2:0] == reg11_delayed[2:0] && allow_bad_lines == 1'b1 && raster_line >= 48 && raster_line < 248)
        badline = 1'b1;
  end

  // at the start of every high phase, store current reg11 for delayed fetch
  // and badline calcs
  always @(posedge clk_dot4x)
  begin
     if (rst)
        reg11_delayed <= 8'b0;
     else if (clk_phi && phi_phase_start[0]) begin // must be before badline idle reset below
        reg11_delayed[2:0] <= yscroll;
        reg11_delayed[3] <= rsel;
        reg11_delayed[4] <= den;
        reg11_delayed[5] <= bmm;
        reg11_delayed[6] <= ecm;
        reg11_delayed[7] <= raster_line[8];
     end
  end
  
  // Raise raster irq once per raster line
  // On raster line 0, it happens on cycle 1, otherwise, cycle 0
  always @(posedge clk_dot4x)
  begin
     if (rst)
       irst <= 1'b0;
     else begin
     // TODO: What point in the phi low cycle does irq rise? This might
     // be too early.  Find out.
     if (clk_phi == 1'b1 && phi_phase_start[15] && // phi going low
       (vicCycle == VIC_HPI3 || vicCycle == VIC_HS3) && spriteCnt == 2)
       rasterIrqDone <= 1'b0;
     if (irst_clr)
       irst <= 1'b0;
     if (rasterIrqDone == 1'b0 && raster_line == rasterCmp) begin
       if ((raster_line == 0 && cycle_num == 1) || (raster_line != 0 && cycle_num == 0)) begin
          rasterIrqDone <= 1'b1;
          irst <= 1'b1;
       end
     end
     end
  end
  
  // NOTE: Things like raster irq conditions happen even if the enable bit is off.
  // That means as soon as erst is enabled, for example, if the condition was
  // met, it will trigger irq immediately.  This seems consistent with how the
  // C64 works.  Even if you set rasterCmp to 11, when you first enable erst,
  // your ISR will get called immediately on the next line. Then, only afer you clear
  // the interrupt will you actually get the ISR on the desired line.
  assign irq = (ilp & elp) | (immc & emmc) | (imbc & embc) | (irst & erst);

  // DRAM refresh counter
  always @(posedge clk_dot4x)
  if (rst)
     refc <= 8'hff;
  else if (phi_phase_start[15]) begin // about to transition
     // About to leave LR into HRC or HRI. Okay to use vicCycle here
     // before the end of this phase because we know it's either heading
     // into HRC or HRI.
     if (vicCycle == VIC_LR)
         refc <= refc - 8'd1;
     else if (raster_x == rasterXMax && raster_line == rasterYMax)
         refc <= 8'hff;
  end
    
  always @(posedge clk_dot4x)
  if (rst)
      cycle_fine_ctr <= 5'd3;
  else
      cycle_fine_ctr <= cycle_fine_ctr + 5'b1;
    
  reg start_of_frame;
  reg start_of_line;
  
  // xpos_d is xpos shifted by the pixel delay minus 1. It is used
  // to delay both pixels and border locations to align with expected
  // times pixels should come out of the sequencer.
  reg [9:0] xpos_d;
  assign xpos_d = xpos - (`PIXEL_DELAY - 1);
  
  // Update x,y position
  always @(posedge clk_dot4x)
  if (rst)
  begin
    raster_x <= 10'b0;
    raster_line <= 9'b0;
    start_of_frame <= 1'b0;
    case(chip)
    CHIP6567R56A, CHIP6567R8:
      xpos <= 10'h19c;
    CHIP6569, CHIPUNUSED:
      xpos <= 10'h194;
    endcase
  end
  else if (dot_risingr[0])
  if (raster_x < rasterXMax)
  begin
    // Can advance to next pixel
    raster_x <= raster_x + 10'd1;

    if (clk_phi && phi_phase_start[0]) begin
      if (start_of_frame && cycle_num == 1) begin
         raster_line <= 9'd0;
         start_of_frame <= 1'b0;
      end else if (start_of_line && cycle_num == 0) begin
         raster_line <= raster_line + 9'd1;
         start_of_line <= 1'b0;
      end
    end
    
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

    // Reset of raster line after a frame is delayed until end of cycle 0 (see above)
    if (raster_line == rasterYMax)
       start_of_frame <= 1'b1;
    else
       start_of_line <= 1'b1;
  end
  
  // Update rc/vc/vcbase
  always @(posedge clk_dot4x)
  if (rst)
  begin
    vcBase <= 10'd0;
    vc <= 10'd0;
    rc <= 3'd7;
    idle <= 1'b1;
  end
  else begin 
    if (clk_phi == 1'b1 && phi_phase_start[0]) begin
      if (cycle_num > 14 && cycle_num < 55 && idle == 1'b0)
        vc <= vc + 1'b1;
  
      if (cycle_num == 13) begin
        vc <= vcBase;
        if (badline)
          rc <= 3'd0;
      end
    
      if (cycle_num == 57) begin
        if (rc == 3'd7) begin
          vcBase <= vc;
          idle <= 1;
        end
        else if (!idle | badline)
          rc <= rc + 1'b1;
      end

      if (cycle_num == 1 && start_of_frame) begin
         vcBase <= 10'd0;
         vc <= 10'd0;
      end   
   end
   
   // This needs to be checked next 4x tick within the phase because
   // badline does not trigger until after raster line has incremented
   // which is after start of line which happens on tick 0 and due to
   // delayed assignment raster line yscroll comparison won't happen until
   // tick 1.
   if (clk_phi == 1'b1 && phi_phase_start[1])
      if (badline)
        idle <= 1'b0;

  end
  
  always @(posedge clk_dot4x)
  if (rst)
     baChars <= 1'b1;
  else
  begin
     if (dot_risingr[0] && phir[0] == 1'b0)
       if (cycle_num > 7'd10 && cycle_num < 7'd54 && badline)
          baChars <= 1'b0;
       else
          baChars <= 1'b1;
  end

  assign ba = baChars;

  // Cascade ba through three cycles, making sure
  // aec is lowered 3 cycles after ba went low
  reg ba1,ba2,ba3;
  always @(posedge clk_dot4x)
  if (rst) begin
    ba1 <= 1'b1;
    ba2 <= 1'b1;
    ba3 <= 1'b1;
  end
  else begin
    if (clk_phi == 1'b1 && phi_phase_start[15]) begin
      ba1 <= ba;
      ba2 <= ba1 | ba;
      ba3 <= ba2 | ba;
    end
  end
 

  // vicCycle state machine
  //
  // LP --dmaEn?-> HS1 -> LS2 -> HS3  --<7?--> LP
  //                                  --else-> LR
  //    --else---> HPI1 -> LPI2-> HPI3 --<7>--> LP 
  //                                   --else-> LR
  //
  // LR --5th&bad?--> HRC -> LG
  // LR --5th&!bad?-> HRX -> LG
  // LR --else--> HRI --> LR
  //
  // LG --55?--> HI
  //    --bad?--> HGC
  //    --else-> HGI
  //
  // HGC -> LG
  // HGI -> LG
  // HI --2|3|4?--> LP
  //      --else--> LI
  // LI -> HI
  always @(posedge clk_dot4x)
     if (rst) begin
        vicPreCycle <= VIC_LP;
        spriteCnt <= 3'd3;
        refreshCnt <= 3'd0;
        idleCnt <= 3'd0;
     end else if (phi_phase_start[14]) begin
       if (clk_phi == 1'b0) begin // about to go phi high
          case (vicCycle)
             VIC_LP: begin
                if (spriteDmaEn)
                   vicPreCycle <= VIC_HS1;
                else
                   vicPreCycle <= VIC_HPI1;
             end
             VIC_LPI2:
                   vicPreCycle <= VIC_HPI3;
             VIC_LS2:
                vicPreCycle <= VIC_HS3;
             VIC_LR: begin
                if (refreshCnt == 4) begin
                  if (badline == 1'b1)
                    vicPreCycle <= VIC_HRC;
                  else
                    vicPreCycle <= VIC_HRX;
                end else
                    vicPreCycle <= VIC_HRI;
             end
             VIC_LG: begin
                if (cycle_num == 54) begin
                      vicPreCycle <= VIC_HI;
                      idleCnt <= 0;
                end else
                   if (badline == 1'b1)
                      vicPreCycle <= VIC_HGC;
                   else
                      vicPreCycle <= VIC_HGI;
                end
             VIC_LI: vicPreCycle <= VIC_HI;
             default: ;
          endcase
       end else begin // about to go phi low
          case (vicCycle)
             VIC_HS1: vicPreCycle <= VIC_LS2;
             VIC_HPI1: vicPreCycle <= VIC_LPI2;
             VIC_HS3, VIC_HPI3: begin
                 if (spriteCnt == 7) begin
                    vicPreCycle <= VIC_LR;
                    spriteCnt <= 0;
                    refreshCnt <= 0;
                 end else begin
                    vicPreCycle <= VIC_LP;
                    spriteCnt <= spriteCnt + 1'd1;
                 end
             end
             VIC_HRI: begin
                 vicPreCycle <= VIC_LR;
                 refreshCnt <= refreshCnt + 1'd1;
             end
             VIC_HRC, VIC_HRX:
                 vicPreCycle <= VIC_LG;            
             VIC_HGC, VIC_HGI: vicPreCycle <= VIC_LG;
             VIC_HI: begin
                 if (chip == CHIP6567R56A && idleCnt == 3)
                    vicPreCycle <= VIC_LP;
                 else if (chip == CHIP6567R8 && idleCnt == 4)
                    vicPreCycle <= VIC_LP;
                 else if (chip == CHIP6569 && idleCnt == 2)
                    vicPreCycle <= VIC_LP;
                 else begin
                    idleCnt <= idleCnt + 1'd1;
                    vicPreCycle <= VIC_LI;
                 end
             end
             default: ;
          endcase
       end
     end
     
  // transfer vicPreCycle to vicCycle. vicPreCycle lets us determine what
  // cycle the state machine will be in on the last tick of a phase if
  // we need to
  always @(posedge clk_dot4x)
     if (rst)
        vicCycle <= VIC_LP;
     else if (phi_phase_start[15])
        vicCycle <= vicPreCycle;
    
  // RAS/CAS/MUX profiles
  // Data must be stable by falling RAS edge
  // Then stable by falling CAS edge
  // MUX drops at the same time rasr drops due
  // to its delayed use to set ado 
  always @(posedge clk_dot4x)
  if (rst) begin
     rasr <= 16'b1100000000000000;
     casr <= 16'b1111000000000000;
  end
  else if (phi_phase_start[15]) begin // about to transition
    if (clk_phi) // phi going low
    case (vicPreCycle)
    VIC_LPI2, VIC_LI: begin
             rasr <= 16'b1111111111111111;
             casr <= 16'b1111111111111111;
           end
    default: begin
             rasr <= 16'b1111100000000000;
             casr <= 16'b1111111000000000;
           end
    endcase
    else begin // phi going high
       rasr <= 16'b1111100000000000;
       casr <= 16'b1111111000000000;
    end
  end else begin
    rasr <= {rasr[14:0],1'b0};
    casr <= {casr[14:0],1'b0};
  end
  assign ras = rasr[15];
  assign cas = casr[15];

  // muxr drops 1 cycle early due to delayed use for
  // ado.
  always @(posedge clk_dot4x)
  if (rst)
     muxr <= 16'b1100000000000000;
  else if (phi_phase_start[15]) begin // about to transition
    if (clk_phi) // phi going low
    case (vicPreCycle)
    VIC_LPI2, VIC_LI: muxr <= 16'b1111111111111111;
    VIC_LR:           muxr <= 16'b1111111111111111;
    default:          muxr <= 16'b1111100000000000;
    endcase
    else        // phi going high
                      muxr <= 16'b1111100000000000;
  end else
    muxr <= {muxr[14:0],1'b0};
  assign mux = muxr[15]; 

  // AEC LOW tells CPU to tri-state its bus lines 
  // AEC will remain HIGH during Phi phase 2 for 3 cycles
  // after which it will remain LOW with ba.
  always @(posedge clk_dot4x)
  if (rst) begin
    aec <= 1'b0;
  end else begin
    aec <= ba ? clk_phi : ba3 & clk_phi;
  end  


  // aec -> LS245 DIR Pin (addr)
  // aec   : low = VIC sets address lines (Bx to Ax)
  //       : high = VIC reads address lines(Ax to Bx)
  // When CPU owns the bus (aec high), VIC reads address lines (high)
  // When VIC owns the bus (aec low), VIC sets address lines (low)
  // OE pin is grounded (always enabled)
  
  // ls245_oe -> LS245 OE Pin (data)
  // ls245_oe : low = all channels active
  //            high = all channels disabled
  // When CPU owns the bus (aec high)
  //    Enable data lines if VIC is selected (ce low) (ce)
  //    Disable data lines if VIC is not selected (ce high) (ce)
  // When VIC owns the bus (aec low)
  //    Enable data lines (0)
  assign ls245_oe = aec ? ce : 1'b0;
  
  // ls245_dir -> LS245 DIR Pin (data)
  // ls245_dir : low = VIC writes to data lines (Bx to Ax)
  //             high = VIC reads from data lines (Ax to Bx)
  // When CPU owns the bus (aec high)
  //   VIC writes to data bus when rw high (rw)
  //   VIC reads from data bus when rw low (rw)
  // When VIC owns the bus (aec low)
  //   VIC reads from data (1)
  assign ls245_dir = aec ? (!ce ? ~rw : 1'b1) : 1'b1;

  // aec ce rw den dir
  // 0   x  x  0   1    ; vic or stollen cycle, enable db and read
  // 1   0  1  0   0    ; cpu read from vic, enable db and write
  // 1   0  0  0   1    ; cpu write to vic, enable db and read 
  // 1   1  x  1   1    ; cpu neither read nor write from/to vic, disable db, read
  
  // Apparently, even though AEC is high, we can't enable the data bus or we
  // have contention issues with something else (what?). There are timing
  // constraints that must go with our write condition.
  assign vic_write_db = aec && rw && ~ce && cycle_fine_ctr <= 23;

  // NTSC : 977.8ns - 1 tick is 30.55ns
  // PAL : 1014.9ns - 1 tick is 31.71ns
  // 0123 4567 8911 1111 1111 2222 2222 2233
  //             01 2345 6789 0123 4567 8901           
  
  
  // AEC low means we own the address bus so we can write to it. 
  assign vic_write_ab = ~aec;

  // c-access reads
  always @(posedge clk_dot4x)
  if (rst)
     nextChar <= 12'b0;
  else if (!vic_write_db && phi_phase_start[`CHAR_DAV]) begin
     case (vicCycle)
     VIC_HRC, VIC_HGC: // badline c-access
         nextChar <= dbi;
     VIC_HRX, VIC_HGI: // not badline idle (char from cache)
         nextChar <= idle ? 12'b0 : charbuf[38];
     default:
         if (idle)
            nextChar <= 12'b0;
     endcase
     
     case (vicCycle)
     VIC_HRC, VIC_HGC, VIC_HRX, VIC_HGI: begin
         for (n = 38; n > 0; n = n - 1) begin
           charbuf[n] = charbuf[n-1];
         end
         charbuf[0] <= nextChar;
     end
     default: ;
     endcase
  end

  // g-access reads
  always @(posedge clk_dot4x)
  begin
  if (rst)
    readPixels <= 8'd0;
  else if (!vic_write_db && phi_phase_start[`PIXEL_DAV]) begin
    readPixels <= 8'd0;
    if (vicCycle == VIC_LG) begin // g-access
      readPixels <= dbi[7:0];
      readChar <= idle ? 12'd0 : nextChar;
    end
  end
  end

  // Transfer read pixels and char into waiting*[0] so they
  // are available at the first dot of PHI2
  always @(posedge clk_dot4x)
  begin
    if (clk_phi == 1'b0 && phi_phase_start[15]) begin // must be > PIXEL_DAV
      waitingPixels[0] <= readPixels;
      waitingChar[0] <= readChar;
    end
  end

  // Now delay these pixels until waitingPixels[PIXEL_DELAY]
  // is available for loading into shifting pixels by loadPixels
  // flag starting with xpos ##0 and fully available until xpos ##7.
  // This makes loading pixels on ##0 make the first pixel show
  // up on ##1. Note, these delays are relative to xpos_d which is
  // xpos with a negative offset. 
  always @(posedge clk_dot4x)
  begin
    if (dot_risingr[0]) begin
       for (n = `PIXEL_DELAY; n > 0; n = n - 1) begin
          waitingPixels[n] <= waitingPixels[n-1];
          waitingChar[n] <= waitingChar[n-1];
       end
    end
  end
  
  // Address generation - use delayed reg11 values here
  always @*
  begin
     case(vicCycle)
     VIC_LR: vicAddr = {6'b111111, refc};
     VIC_LG: begin
        if (idle)
          vicAddr = 14'h3FFF;
        else begin
          if (reg11_delayed[5]) // bmm
            vicAddr = {cb[2], vc, rc}; // bitmap data
          else
            vicAddr = {cb, nextChar[7:0], rc}; // character pixels
          if (reg11_delayed[6]) // ecm
            vicAddr[10:9] = 2'b00;
        end
     end
     VIC_HRC, VIC_HGC: vicAddr = {vm, vc}; // video matrix
     default: vicAddr = 14'h3FFF;
     endcase
  end
  
  // Address out
  // ROW first, COL second
  always @(posedge clk_dot4x)
  if (rst)
     ado8 <= 8'hFF;
  else
     ado8 <= mux ? vicAddr[7:0] : {2'b11, vicAddr[13:8]};
  assign ado = {vicAddr[11:8], ado8};

// Pixel sequencer stuff  
reg loadPixels;
reg pixelBgFlag;
reg clkShift;
reg ismc;

vic_color pixelColor;

always @(*)
        ismc = mcm & (bmm | ecm | shiftingChar[11]);

// Use xpos_d here so we can properly delay our pixels
// using waitingChar[]/waitingPixels[] regs.
always @(*)
        loadPixels = xpos_d[2:0] == xscroll;

always @(posedge clk_dot4x)
if (dot_risingr[0]) begin // rising dot
        if (loadPixels)
                clkShift <= ~(mcm & (bmm | ecm | waitingChar[`PIXEL_DELAY][11]));
        else
                clkShift <= ismc ? ~clkShift : clkShift;
end

always @(posedge clk_dot4x)
if (dot_risingr[0]) begin
        if (loadPixels)
                shiftingChar <= waitingChar[`PIXEL_DELAY];
end

// Pixel shifter
always @(posedge clk_dot4x)
if (dot_risingr[0]) begin
        if (loadPixels)
                shiftingPixels <= waitingPixels[`PIXEL_DELAY];
        else if (clkShift) begin
                if (ismc)
                        shiftingPixels <= {shiftingPixels[5:0], 2'b0};
                else
                        shiftingPixels <= {shiftingPixels[6:0], 1'b0};
        end
end

// handle display modes
always @(posedge clk_dot4x)
    begin
        if (dot_risingr[0]) begin
            pixelColor <= BLACK;
            case ({ecm, bmm, mcm})
                MODE_STANDARD_CHAR:
                    pixelColor <= shiftingPixels[7] ? vic_color'(shiftingChar[11:8]):b0c;
                MODE_MULTICOLOR_CHAR:
                    if (shiftingChar[11])
                        case (shiftingPixels[7:6])
                            2'b00: pixelColor <= b0c;
                            2'b01: pixelColor <= b1c;
                            2'b10: pixelColor <= b2c;
                            2'b11: pixelColor <= vic_color'({1'b0, shiftingChar[10:8]});
                        endcase
                    else
                        pixelColor <= shiftingPixels[7] ? vic_color'(shiftingChar[11:8]):b0c;
                MODE_STANDARD_BITMAP, MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP:
                    pixelColor <= shiftingPixels[7] ? vic_color'(shiftingChar[7:4]):vic_color'(shiftingChar[3:0]);
                MODE_MULTICOLOR_BITMAP, MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
                    case (shiftingPixels[7:6])
                        2'b00: pixelColor <= b0c;
                        2'b01: pixelColor <= vic_color'(shiftingChar[7:4]);
                        2'b10: pixelColor <= vic_color'(shiftingChar[3:0]);
                        2'b11: pixelColor <= vic_color'(shiftingChar[11:8]);
                    endcase
                MODE_EXTENDED_BG_COLOR:
                    case ({shiftingPixels[7], shiftingChar[7:6]})
                        3'b000: pixelColor <= b0c;
                        3'b001: pixelColor <= b1c;
                        3'b010: pixelColor <= b2c;
                        3'b011: pixelColor <= b3c;
                        default: pixelColor <= vic_color'(shiftingChar[11:8]);
                    endcase
                MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR:
                    if (shiftingChar[11])
                        case (shiftingPixels[7:6])
                            2'b00: pixelColor <= b0c;
                            2'b01: pixelColor <= b1c;
                            2'b10: pixelColor <= b2c;
                            2'b11: pixelColor <= vic_color'(shiftingChar[11:8]);
                        endcase
                    else
                        case ({shiftingPixels[7], shiftingChar[7:6]})
                            3'b000: pixelColor <= b0c;
                            3'b001: pixelColor <= b1c;
                            3'b010: pixelColor <= b2c;
                            3'b011: pixelColor <= b3c;
                            default: pixelColor <= vic_color'(shiftingChar[11:8]);
                        endcase
            endcase
        end
    end

vic_color color_code;

always @(posedge clk_dot4x)
    begin
        // illegal modes should have black pixels
        case ({ecm, bmm, mcm})
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR,
            MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP,
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
                color_code <= BLACK;
            default: color_code <= pixelColor;
        endcase
        // See if the mib overrides the output
//  for (n = 0; n < MIBCNT; n = n + 1) begin
//    if (!mdp[n] || !pixelBgFlag) begin
//      if (mmc[n]) begin  // multi-color mode ?
//        case(MCurrentPixel[n])
//        2'b00:  ;
//        2'b01:  color_code <= mm0;
//        2'b10:  color_code <= mc[n];
//        2'b11:  color_code <= mm1;
//        endcase
//      end
//      else if (MCurrentPixel[n][1])
//        color_code <= mc[n];
//    end
//  end
end

reg TBBorder = 1'b1;
reg LRBorder = 1'b1;
reg newTBBorder = 1'b1;

always @(raster_line, rsel, allow_bad_lines, TBBorder)
begin
    newTBBorder = TBBorder;
    if (raster_line == 55 && allow_bad_lines == 1'b1)
        newTBBorder = 1'b0;
                               
    if (raster_line == 51 && rsel == 1'b1 && allow_bad_lines == 1'b1)
        newTBBorder = 1'b0;
                             
    if (raster_line == 247 && rsel == 1'b0)
       newTBBorder = 1'b1;
                             
    if (raster_line == 251 && rsel == 1'b1)
       newTBBorder = 1'b1;
end

always @(posedge clk_dot4x)
begin
    if (dot_risingr[0]) begin
       if (xpos_d == 32 && csel == 1'b0) begin
          LRBorder <= newTBBorder;
          TBBorder <= newTBBorder;
       end
       if (xpos_d == 25 && csel == 1'b1) begin
          LRBorder <= newTBBorder;
          TBBorder <= newTBBorder;
       end
       if (xpos_d == 336 && csel == 1'b0)
          LRBorder <= 1'b1;
                              
       if (xpos_d == 345 && csel == 1'b1)
          LRBorder <= 1'b1;
    end
end

// mask with border
vic_color color8;
always @(posedge clk_dot4x)
begin
    if (LRBorder | TBBorder)
      color8 <= ec;
    else
      color8 <= color_code;
end

// Translate out_pixel (indexed) to RGB values
color viccolor(
     .chip(chip),
     .x_pos(xpos),
     .y_pos(raster_line),
     .out_pixel(color8),
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
        ec <= BLACK;
        b0c <= BLACK;
        xscroll <= 3'd0;
        yscroll <= 3'd3;
        csel <= 1'b0;
        rsel <= 1'b0;
        den <= 1'b1;
        bmm <= 1'b0;
        ecm <= 1'b0;
        res <= 1'b0;
        mcm <= 1'b0;
        irst_clr <= 1'b0;
        rasterCmp <= 9'b0;
    end
    else begin
        if (!vic_write_ab && !ce) begin
            // READ from register
            if (rw) begin
                dbo <= 12'hFF;               
                case (adi[5:0])
                    /* 0x00 */ REG_SPRITE_X_0:
                        dbo[7:0] <= sprite_x[0][7:0]; 
                    /* 0x02 */ REG_SPRITE_X_1:
                        dbo[7:0] <= sprite_x[1][7:0]; 
                    /* 0x04 */ REG_SPRITE_X_2:
                        dbo[7:0] <= sprite_x[2][7:0]; 
                    /* 0x06 */ REG_SPRITE_X_3:
                        dbo[7:0] <= sprite_x[3][7:0]; 
                    /* 0x08 */ REG_SPRITE_X_4:
                        dbo[7:0] <= sprite_x[4][7:0]; 
                    /* 0x0a */ REG_SPRITE_X_5:
                        dbo[7:0] <= sprite_x[5][7:0]; 
                    /* 0x0c */ REG_SPRITE_X_6:
                        dbo[7:0] <= sprite_x[6][7:0]; 
                    /* 0x0e */ REG_SPRITE_X_7:
                        dbo[7:0] <= sprite_x[7][7:0]; 
                    /* 0x01 */ REG_SPRITE_Y_0:
                        dbo[7:0] <= sprite_y[0]; 
                    /* 0x03 */ REG_SPRITE_Y_1:
                        dbo[7:0] <= sprite_y[1]; 
                    /* 0x05 */ REG_SPRITE_Y_2:
                        dbo[7:0] <= sprite_y[2]; 
                    /* 0x07 */ REG_SPRITE_Y_3:
                        dbo[7:0] <= sprite_y[3]; 
                    /* 0x09 */ REG_SPRITE_Y_4:
                        dbo[7:0] <= sprite_y[4]; 
                    /* 0x0b */ REG_SPRITE_Y_5:
                        dbo[7:0] <= sprite_y[5]; 
                    /* 0x0d */ REG_SPRITE_Y_6:
                        dbo[7:0] <= sprite_y[6]; 
                    /* 0x0f */ REG_SPRITE_Y_7:
                        dbo[7:0] <= sprite_y[7]; 
                    /* 0x10 */ REG_SPRITE_X_BIT_8:
                        dbo[7:0] <= {sprite_x[7][8], 
                                     sprite_x[6][8],
                                     sprite_x[5][8],
                                     sprite_x[4][8],
                                     sprite_x[3][8],
                                     sprite_x[2][8],
                                     sprite_x[1][8],
                                     sprite_x[0][8]};
                    /* 0x11 */ REG_SCREEN_CONTROL_1: begin
                        dbo[2:0] <= yscroll;
                        dbo[3] <= rsel;
                        dbo[4] <= den;
                        dbo[5] <= bmm;
                        dbo[6] <= ecm;
                        dbo[7] <= raster_line[8];
                    end
                    /* 0x12 */ REG_RASTER_LINE: dbo[7:0] <= raster_line[7:0];
                    /* 0x15 */ REG_SPRITE_ENABLE: dbo[7:0] <= sprite_en;
                    /* 0x16 */ REG_SCREEN_CONTROL_2:
                        dbo[7:0] <= {2'b11, res, mcm, csel, xscroll};
                    /* 0x17 */ REG_SPRITE_EXPAND_Y:
                        dbo[7:0] <= sprite_ye;
                    /* 0x18 */ REG_MEMORY_SETUP: begin
                        dbo[0] <= 1'b1;
                        dbo[3:1] <= cb[2:0];
                        dbo[7:4] <= vm[3:0];
                    end
                    // NOTE: Our irq is inverted already
                    /* 0x19 */ REG_INTERRUPT_STATUS:
                        dbo[7:0] <= {irq, 3'b111, ilp, immc, imbc, irst};
                    /* 0x1a */ REG_INTERRUPT_CONTROL:
                        dbo[7:0] <= {4'b1111, elp, emmc, embc, erst};
                    /* 0x1b */ REG_SPRITE_PRIORITY:
                        dbo[7:0] <= sprite_pri;
                    /* 0x1c */ REG_SPRITE_MULTICOLOR_MODE:
                        dbo[7:0] <= sprite_mmc;
                    /* 0x1d */ REG_SPRITE_EXPAND_X:
                        dbo[7:0] <= sprite_ye;
                    /* 0x1e */ REG_SPRITE_2_SPRITE_COLLISION:
                        dbo[7:0] <= sprite_m2m;
                    /* 0x1f */ REG_SPRITE_2_DATA_COLLISION:
                        dbo[7:0] <= sprite_m2d;
                    /* 0x20 */ REG_BORDER_COLOR:
                        dbo[7:0] <= {4'b1111, ec};
                    /* 0x21 */ REG_BACKGROUND_COLOR_0:
                        dbo[7:0] <= {4'b1111, b0c};
                    /* 0x22 */ REG_BACKGROUND_COLOR_1:
                        dbo[7:0] <= {4'b1111, b1c};
                    /* 0x23 */ REG_BACKGROUND_COLOR_2:
                        dbo[7:0] <= {4'b1111, b2c};
                    /* 0x24 */ REG_BACKGROUND_COLOR_3:
                        dbo[7:0] <= {4'b1111, b3c};
                    /* 0x25 */ REG_SPRITE_MULTI_COLOR_0:
                        dbo[7:0] <= {4'b1111, sprite_mc0};
                    /* 0x26 */ REG_SPRITE_MULTI_COLOR_1:
                        dbo[7:0] <= {4'b1111, sprite_mc1};
                    /* 0x27 */ REG_SPRITE_COLOR_0:
                        dbo[7:0] <= {5'b11111, sprite_col[0]};
                    /* 0x28 */ REG_SPRITE_COLOR_1:
                        dbo[7:0] <= {5'b11111, sprite_col[1]};
                    /* 0x29 */ REG_SPRITE_COLOR_2:
                        dbo[7:0] <= {5'b11111, sprite_col[2]};
                    /* 0x2a */ REG_SPRITE_COLOR_3:
                        dbo[7:0] <= {5'b11111, sprite_col[3]};
                    /* 0x2b */ REG_SPRITE_COLOR_4:
                        dbo[7:0] <= {5'b11111, sprite_col[4]};
                    /* 0x2c */ REG_SPRITE_COLOR_5:
                        dbo[7:0] <= {5'b11111, sprite_col[5]};
                    /* 0x2d */ REG_SPRITE_COLOR_6:
                        dbo[7:0] <= {5'b11111, sprite_col[6]};
                    /* 0x2e */ REG_SPRITE_COLOR_7:
                        dbo[7:0] <= {5'b11111, sprite_col[7]};

                    default:;
                endcase
            end
            // WRITE to register
            //
            // LOLOLOLOLOLOLOLOHIHIHIHIHIHIHIHI
            // 0   1   2   3   4   5   6   7   |
            //           111111          111111|
            // 01234567890123450123456789012345|
            //
            else if (phi_phase_start[`REG_DAV]) begin
                irst_clr <= 1'b0;
                imbc_clr <= 1'b0;
                immc_clr <= 1'b0;
                ilp_clr <= 1'b0;
                if (!rw) begin
                    case (adi[5:0])
                        /* 0x00 */ REG_SPRITE_X_0:
                            sprite_x[0][7:0] <= dbi[7:0]; 
                        /* 0x02 */ REG_SPRITE_X_1:
                            sprite_x[1][7:0] <= dbi[7:0];
                        /* 0x04 */ REG_SPRITE_X_2:
                            sprite_x[2][7:0] <= dbi[7:0];
                        /* 0x06 */ REG_SPRITE_X_3:
                            sprite_x[3][7:0] <= dbi[7:0];
                        /* 0x08 */ REG_SPRITE_X_4:
                            sprite_x[4][7:0] <= dbi[7:0];
                        /* 0x0a */ REG_SPRITE_X_5:
                            sprite_x[5][7:0] <= dbi[7:0];
                        /* 0x0c */ REG_SPRITE_X_6:
                            sprite_x[6][7:0] <= dbi[7:0];
                        /* 0x0e */ REG_SPRITE_X_7:
                            sprite_x[7][7:0] <= dbi[7:0];
                        /* 0x01 */ REG_SPRITE_Y_0:
                            sprite_y[0] <= dbi[7:0];
                        /* 0x03 */ REG_SPRITE_Y_1:
                            sprite_y[1] <= dbi[7:0]; 
                        /* 0x05 */ REG_SPRITE_Y_2:
                            sprite_y[2] <= dbi[7:0];
                        /* 0x07 */ REG_SPRITE_Y_3:
                            sprite_y[3] <= dbi[7:0];
                        /* 0x09 */ REG_SPRITE_Y_4:
                            sprite_y[4] <= dbi[7:0];
                        /* 0x0b */ REG_SPRITE_Y_5:
                            sprite_y[5] <= dbi[7:0]; 
                        /* 0x0d */ REG_SPRITE_Y_6:
                            sprite_y[6] <= dbi[7:0]; 
                        /* 0x0f */ REG_SPRITE_Y_7:
                            sprite_y[7] <= dbi[7:0];
                        /* 0x10 */ REG_SPRITE_X_BIT_8: begin
                            sprite_x[7][8] <= dbi[7];
                            sprite_x[6][8] <= dbi[6];
                            sprite_x[5][8] <= dbi[5];
                            sprite_x[4][8] <= dbi[4];
                            sprite_x[3][8] <= dbi[3];
                            sprite_x[2][8] <= dbi[2];
                            sprite_x[1][8] <= dbi[1];
                            sprite_x[0][8] <= dbi[0];
                        end
                        /* 0x11 */ REG_SCREEN_CONTROL_1: begin
                            yscroll <= dbi[2:0];
                            rsel <= dbi[3];
                            den <= dbi[4];
                            bmm <= dbi[5];
                            ecm <= dbi[6];
                            rasterCmp[8] <= dbi[7];
                        end
                        /* 0x12 */ REG_RASTER_LINE: rasterCmp[7:0] <= dbi[7:0];
                        /* 0x15 */ REG_SPRITE_ENABLE: sprite_en <= dbi[7:0];
                        /* 0x16 */ REG_SCREEN_CONTROL_2: begin
                            xscroll <= dbi[2:0];
                            csel <= dbi[3];
                            mcm <= dbi[4];
                            res <= dbi[5];
                        end
                        /* 0x17 */ REG_SPRITE_EXPAND_Y:
                            sprite_ye <= dbi[7:0];
                        /* 0x18 */ REG_MEMORY_SETUP: begin
                            cb[2:0] <= dbi[3:1];
                            vm[3:0] <= dbi[7:4];
                        end
                        /* 0x19 */ REG_INTERRUPT_STATUS: begin
                            irst_clr <= dbi[0];
                            imbc_clr <= dbi[1];
                            immc_clr <= dbi[2];
                            ilp_clr <= dbi[3];
                        end
                        /* 0x1a */ REG_INTERRUPT_CONTROL: begin
                            erst <= dbi[0];
                            embc <= dbi[1];
                            emmc <= dbi[2];
                            elp <= dbi[3];
                        end
                        /* 0x1b */ REG_SPRITE_PRIORITY:
                            sprite_pri <= dbi[7:0];
                        /* 0x1c */ REG_SPRITE_MULTICOLOR_MODE:
                            sprite_mmc <= dbi[7:0];
                        /* 0x1d */ REG_SPRITE_EXPAND_X:
                            sprite_xe <= dbi[7:0];
                        /* 0x1e */ REG_SPRITE_2_SPRITE_COLLISION:
                            sprite_m2m <= dbi[7:0];
                        /* 0x1f */ REG_SPRITE_2_DATA_COLLISION:
                            sprite_m2d <= dbi[7:0];
                        /* 0x20 */ REG_BORDER_COLOR:
                            ec <= vic_color'(dbi[3:0]);
                        /* 0x21 */ REG_BACKGROUND_COLOR_0:
                            b0c <= vic_color'(dbi[3:0]);
                        /* 0x22 */ REG_BACKGROUND_COLOR_1:
                            b1c <= vic_color'(dbi[3:0]);
                        /* 0x23 */ REG_BACKGROUND_COLOR_2:
                            b2c <= vic_color'(dbi[3:0]);
                        /* 0x24 */ REG_BACKGROUND_COLOR_3:
                            b3c <= vic_color'(dbi[3:0]);
                        /* 0x25 */ REG_SPRITE_MULTI_COLOR_0:
                            sprite_mc0 <= vic_color'(dbi[3:0]);
                        /* 0x26 */ REG_SPRITE_MULTI_COLOR_1:
                            sprite_mc1 <= vic_color'(dbi[3:0]);
                        /* 0x27 */ REG_SPRITE_COLOR_0:
                            sprite_col[0] <= vic_color'(dbi[3:0]);
                        /* 0x28 */ REG_SPRITE_COLOR_1:
                            sprite_col[1] <= vic_color'(dbi[3:0]);
                        /* 0x29 */ REG_SPRITE_COLOR_2:
                            sprite_col[2] <= vic_color'(dbi[3:0]);
                        /* 0x2a */ REG_SPRITE_COLOR_3:
                            sprite_col[3] <= vic_color'(dbi[3:0]);
                        /* 0x2b */ REG_SPRITE_COLOR_4:
                            sprite_col[4] <= vic_color'(dbi[3:0]);
                        /* 0x2c */ REG_SPRITE_COLOR_5:
                            sprite_col[5] <= vic_color'(dbi[3:0]);
                        /* 0x2d */ REG_SPRITE_COLOR_6:
                            sprite_col[6] <= vic_color'(dbi[3:0]);
                        /* 0x2e */ REG_SPRITE_COLOR_7:
                            sprite_col[7] <= vic_color'(dbi[3:0]);
                        default:;
                    endcase
                end
            end
        end
    end
endmodule : vicii
