`timescale 1ns / 1ps

`include "common.vh"

// We initialize raster_x,raster_y = (0,0) and let the fist tick
// bring us to raster_x=1 because that initial state is common to all
// chip types. So for reset conditions, remember we are starting things
// off with PHI LOW but already 1/4 the way through its phase and with
// DOT high but already on the second pixel. (This really only matters
// for the simulator since things would eventually fall into line anyway).

// Notes on RST : The reset signal has to reach every flip flop we
// end up resetting.  Try to keep this list to essential resets only.
// i.e, those that are necessary for a sane start state. If the toolchain
// complains about placing dbl into IOB that is connected to flip flops
// with multiple set/reset signals, it'slikely a reset signal (or signals)
// causing it.
//
// clk_dot4x;     32.727272 Mhz NTSC, 31.527955 Mhz PAL
// clk_col4x;     14.318181 Mhz NTSC, 17.734475 Mhz PAL
// clk_dot;       8.18181 Mhz NTSC, 7.8819888 Mhz PAL
// clk_colref     3.579545 Mhz NTSC, 4.43361875 Mhz PAL
// clk_phi        1.02272 Mhz NTSC, .985248 Mhz PAL

module vicii(
           input [1:0] chip,
           input rst,
           input clk_dot4x,
           output clk_phi,
           output [9:0] xpos,
           output [9:0] raster_x,
           output [8:0] raster_line,
           output [3:0] pixel_color3,
           output [11:0] ado,
           input [5:0] adi,
           output [7:0] dbo,
           input [11:0] dbi,
           input ce,
           input rw,
           output irq,
           input lp,
           output reg aec,
           output ba,
           output ras,
           output cas,
           output ls245_data_dir,
           output ls245_data_oe,
           output ls245_addr_dir,
           output ls245_addr_oe,
           output vic_write_db,
           output vic_write_ab
       );

// BA must go low 3 cycles before any dma access on a PHI
// HIGH phase.

// AEC is LOW for PHI LOW phase (vic) and HIGH for PHI
// HIGH phase (cpu) but kept LOW in PHI HIGH phase if vic
// 'stole' a cpu cycle.

// Limits for different chips
reg [9:0] raster_x_max;
reg [8:0] raster_y_max;
reg [9:0] max_xpos;
reg [6:0] sprite_dmachk1;
reg [6:0] sprite_dmachk2;
reg [6:0] sprite_yexp_chk;
reg [6:0] sprite_disp_chk;
reg [9:0] chars_ba_start;
reg [9:0] chars_ba_end;

// These xpos's cover the sprite dma period and 3 cycles
// before the first dma access is required. They are used
// in ba low calcs.
wire [9:0] sprite_ba_start [`NUM_SPRITES-1:0];
wire [9:0] sprite_ba_end [`NUM_SPRITES-1:0];

// sprite_raster_x is raster_x but offset such that the BA fall for the
// first sprite is position 0. This is so we can use a simple interval
// comparison for ba high/low and avoid wrap around conditions.
wire [9:0] sprite_raster_x;

// Set limits for chips
always @(chip)
case(chip)
    `CHIP6567R8:
    begin
        raster_x_max = 10'd519;    // 520 pixels
        raster_y_max = 9'd262;     // 263 lines
        max_xpos = 10'h1ff;
        sprite_dmachk1 = 7'd55;    // low phase
        sprite_dmachk2 = 7'd56;    // low phase
        sprite_yexp_chk = 7'd56;   // high phase
        sprite_disp_chk = 7'd58;
        chars_ba_start = 'h1f4;
        chars_ba_end = 'h14c;
    end
    `CHIP6567R56A:
    begin
        raster_x_max = 10'd511;    // 512 pixels
        raster_y_max = 9'd261;     // 262 lines
        max_xpos = 10'h1ff;
        sprite_dmachk1 = 7'd55;    // low phase
        sprite_dmachk2 = 7'd56;    // low phase
        sprite_yexp_chk = 7'd56;   // high phase
        sprite_disp_chk = 7'd57;
        chars_ba_start = 'h1f4;
        chars_ba_end = 'h14c;
    end
    `CHIP6569, `CHIPUNUSED:
    begin
        raster_x_max = 10'd503;     // 504 pixels
        raster_y_max = 9'd311;      // 312
        max_xpos = 10'h1f7;
        sprite_dmachk1 = 7'd54;     // low phase
        sprite_dmachk2 = 7'd55;     // low phase
        sprite_yexp_chk = 7'd55;    // high phase
        sprite_disp_chk = 7'd57;
        chars_ba_start = 'h1ec;
        chars_ba_end = 'h14c;
    end
endcase

// Used to generate phi and dot clocks
reg [31:0] phi_gen;
reg [31:0] dot_gen;

// Used to detect rising edge of dot clock inside a dot4x always block
// Sequence goes 1 2 3 0:
//    [1] is first tick inside a single pixel
//    [0] is last tick inside a single pixel
reg [3:0] dot_rising;

// Delayed raster line for irq comparison
wire [8:0] raster_line_d;

`ifdef IS_SIMULATOR
reg [7:0] reg11_delayed;
`endif

reg bmm_delayed;
reg mcm_delayed;
reg ecm_delayed;

// xpos is the x coordinate relative to raster irq. It is not simply
// raster_x with an offset. It does not increment on certain cycles for
// 6567R8 chips and wraps at the high phase of cycle 12.

// What cycle we are on. Only valid on PPS[2] (or greater) within a
// half-phase.
wire [3:0] cycle_type;

// DRAM refresh counter
reg [7:0] refc;

// Current sprite number for dma cycles
wire [2:0] sprite_cnt;

// Video matrix and character banks.
wire [3:0] vm;
wire [2:0] cb;

// cycleNum : Each cycle is 8 pixels.
// 6567R56A : 0-63
// 6567R8   : 0-64
// 6569     : 0-62
// NOTE: cycle_num is not valid until PPS[1] within low phase of PHI
wire [6:0] cycle_num;

// ec : border (edge) color
wire [3:0] ec;
// b#c : background color registers
wire [3:0] b0c,b1c,b2c,b3c;

// Lets us detect our progress through a half cycle inside a dot4x block.
// Range is 0-15. PPS[15] == 1 means PHI will transition next tick.
reg [15:0] phi_phase_start;

// Tracks whether the condition for triggering these
// types of interrupts happened, but may not be
// reported via irq unless enabled
reg irst;
wire ilp;
wire immc;
wire imbc;

// Interrupt latches for $d019, these are set HIGH when an interrupt of that
// type occurs. They are not automatically cleared by the VIC.
wire irst_clr;
wire imbc_clr;
wire immc_clr;
wire ilp_clr;

// Interrupt enable registers for $d01a, these determine if these types of
// interrupts will make irq low.
wire erst;
wire embc;
wire emmc;
wire elp;

// If enabled, what raster line do we trigger irq for irst?
wire [8:0] raster_irq_compare;

// Keeps track of whether raster irq was raised on a line
reg raster_irq_triggered;

wire [9:0] vc; // video counter
wire [2:0] rc; // row counter
wire idle;

wire den; // display enable
wire bmm; // bitmap mode
wire ecm; // extended color mode

wire [2:0] xscroll;
wire [2:0] yscroll;

wire rsel; // border row select
wire csel; // border column select
wire mcm; // multi color mode

wire stage0;
wire stage1;
wire is_background_pixel1;

// mostly used for iterating over sprites
integer n;

// char read off the bus, eventually transfered to char_read
wire [11:0] char_next;

// pixels read off the data bus and char read from the bus (char_next on
// badline) or char_buf (not badline)
wire [11:0] char_read;
wire [7:0] pixels_read;

// badline condition
reg badline;

// determines when ba should drop due to chars and sprites
reg ba_chars;
reg [7:0] ba_sprite;

// NOTE: The sprite_*_o regs/wires are 'flattened' 2D arrays that we
// pack and slice between modules.  Verilog does not support passing
// 2D arrays to modules as params so we have to do this for our
// sprite arrays.  The module that owns the register declares a
// 'flattened' _o output wire that we hook up here.  Any module that
// receives the _o flattened wire via an input will slice it apart
// back into a usable 2D array.
wire [71:0] sprite_x_o; // 9 bits * 8 sprites
wire [63:0] sprite_y_o; // 8 bits * 8 sprites
wire [31:0] sprite_col_o; // 4 bits * 8 sprites
wire [63:0] sprite_ptr_o; // 8 bits * 8 sprites
wire [47:0] sprite_mc_o; // 6 bits * 8 sprites
wire [15:0] sprite_cur_pixel_o; // 2 bits * 8 sprites

// Some sprite stuff
wire [7:0] sprite_pri;
wire [3:0] sprite_mc0;
wire [3:0] sprite_mc1;
wire [7:0] sprite_en;
wire [7:0] sprite_xe;
wire [7:0] sprite_ye;
wire [7:0] sprite_mmc;
wire [`NUM_SPRITES - 1:0] sprite_dma;

// Setup sprite ba start/end ranges.  These are compared against
// sprite_raster_x which is makes sprite #0 drop point = 0
// TODO: Should these end values be +4 to rise back up with
// AEC/PHI? Find out on the scope.
assign sprite_ba_start[0] = 10'd0 + 10'd16 * 0;
assign sprite_ba_end[0] = 10'd40 + 10'd16 * 0;
assign sprite_ba_start[1] = 10'd0 + 10'd16 * 1;
assign sprite_ba_end[1] = 10'd40 + 10'd16 * 1;
assign sprite_ba_start[2] = 10'd0 + 10'd16 * 2;
assign sprite_ba_end[2] = 10'd40 + 10'd16 * 2;
assign sprite_ba_start[3] = 10'd0 + 10'd16 * 3;
assign sprite_ba_end[3] = 10'd40 + 10'd16 * 3;
assign sprite_ba_start[4] = 10'd0 + 10'd16 * 4;
assign sprite_ba_end[4] = 10'd40 + 10'd16 * 4;
assign sprite_ba_start[5] = 10'd0 + 10'd16 * 5;
assign sprite_ba_end[5] = 10'd40 + 10'd16 * 5;
assign sprite_ba_start[6] = 10'd0 + 10'd16 * 6;
assign sprite_ba_end[6] = 10'd40 + 10'd16 * 6;
assign sprite_ba_start[7] = 10'd0 + 10'd16 * 7;
assign sprite_ba_end[7] = 10'd40 + 10'd16 * 7;

// When we pass xpos to the sprite module, we subtract 6 pixels to make
// shifting start at the right time.  The output pixels are shifted another
// 6 before reaching the pixel sequencer.
wire [9:0] xpos_sprite;
assign xpos_sprite = xpos >= 10'd6 ? xpos - 10'd6 : max_xpos - 10'd5 + xpos;

// Shift dot_rising register.
always @(posedge clk_dot4x)
    if (rst)
        dot_rising <= 4'b1000;
    else
        dot_rising <= {dot_rising[2:0], dot_rising[3]};

// This is our PHI clock signal generator. Misaligned at reset
// due to where we start our x pos.
always @(posedge clk_dot4x)
    if (rst) begin
        phi_gen <= 32'b00000000000011111111111111110000;
    end else begin
        phi_gen <= {phi_gen[30:0], phi_gen[31]};
    end

assign clk_phi = phi_gen[0];

// PHI phase start shifter. Misaligned at reset due to where we
// start our x pos.
always @(posedge clk_dot4x)
    if (rst) begin
        phi_phase_start <= 16'b0000000000001000;
    end else
        phi_phase_start <= {phi_phase_start[14:0], phi_phase_start[15]};

// This is simply raster_x divided by 8.
assign cycle_num = raster_x[9:3];

// allow_bad_lines goes high on line 48
// if den is high at any point on line 48
// allow_bad_lines falls on line 248
// den only takes effect on line 48 (including very last cycle)
reg allow_bad_lines;
always @(posedge clk_dot4x)
begin
    if (rst)
        allow_bad_lines = `FALSE;
    else if (~clk_phi && phi_phase_start[1]) begin
        // Use raster_line_d here on [1] before it transitions
        // to the next line in the low cycle so we can catch
        // den on the last cycle of line 48.  den01-49-1.prg
        // sets den on the last cycle of line 48 (PAL cycle 62) so
        // our check has to be made before raster line changes.
        // For cycle 0, use raster_line to catch den at the
        // beginning of 48.
        if (den && ((raster_line == 48 && cycle_num == 0) ||
                    raster_line_d == 48))
            allow_bad_lines = `TRUE;

        if (raster_line == 248)
            allow_bad_lines = `FALSE;

        badline = `FALSE;
        if (raster_line[2:0] == yscroll && allow_bad_lines == `TRUE &&
                raster_line >= 48 && raster_line < 248)
            badline = `TRUE;
    end
end

// Raise raster irq once per raster line
reg [8:0] raster_irq_compare_d;
always @(posedge clk_dot4x) begin
    if (rst) begin
        irst <= `FALSE;
        raster_irq_triggered <= `FALSE;
    end else begin
        raster_irq_compare_d <= raster_irq_compare;
        // To pass rasterirq_hold.prg, we have to make sure raster_irq_compare
        // is set along with the time raster_line_d changes.  This test
        // program 'chases' the raster line comparison test so that the VICII
        // comparison always results in a match (after line 18). So
        // raster_irq_triggered remains true and only lines 16,17,18 should
        // trigger irq (for this particular test program).
        if (raster_line_d == raster_irq_compare_d) begin
            if (!clk_phi && phi_phase_start[8] && !raster_irq_triggered) begin
                raster_irq_triggered <= `TRUE;
                irst <= `TRUE;
            end
        end else begin
            raster_irq_triggered <= `FALSE;
        end

        if (irst_clr)
            irst <= `FALSE;
    end
end

// NOTE: Things like raster irq conditions happen even if the enable bit is off.
// That means as soon as erst is enabled, for example, if the condition was
// met, it will trigger irq immediately.  This seems consistent with how the
// C64 works.  Even if you set raster_irq_compare to 11, when you first enable
// erst, your ISR will get called immediately on the next line. Then, only afer
// you clear the interrupt will you actually get the ISR on the desired line.
assign irq = (ilp & elp) | (immc & emmc) | (imbc & embc) | (irst & erst);

// DRAM refresh counter
always @(posedge clk_dot4x)
    if (rst)
        refc <= 8'hff;
    else if (phi_phase_start[1]) begin // cycle_type is about to transition
        // Decrement at the start of the phase when cycle_type is still valid
        // for the previous half cycle.
        if (cycle_num == 1 && raster_line == 9'd0)
            refc <= 8'hff;
        else if (cycle_type == `VIC_LR)
            refc <= refc - 8'd1; // decrements at END of LR cycle
    end

// Handle border
wire main_border;
wire top_bot_border;

// Border values are delayed by 6 pixels before entering the pixel
// sequencer  but we use the non delayed values for VICE comparison.
reg main_border_d1;
reg main_border_d2;
reg main_border_d3;
reg main_border_d4;
reg main_border_d5;
reg top_bot_border_d1;
reg top_bot_border_d2;
reg top_bot_border_d3;
reg top_bot_border_d4;
reg top_bot_border_d5;

border vic_border(
           .rst(rst),
           .clk_dot4x(clk_dot4x),
           .clk_phi(clk_phi),
           .cycle_num(cycle_num),
           .xpos(xpos),
           .raster_line(raster_line),
           .rsel(rsel),
           .csel(csel),
           .den(den),
           .dot_rising(dot_rising[1]),
           .vborder(top_bot_border),
           .main_border(main_border)
       );

always @(posedge clk_dot4x)
begin
    if (dot_rising[0]) begin
        main_border_d1 <= main_border;
        main_border_d2 <= main_border_d1;
        main_border_d3 <= main_border_d2;
        main_border_d4 <= main_border_d3;
        main_border_d5 <= main_border_d4;
        top_bot_border_d1 <= top_bot_border;
        top_bot_border_d2 <= top_bot_border_d1;
        top_bot_border_d3 <= top_bot_border_d2;
        top_bot_border_d4 <= top_bot_border_d3;
        top_bot_border_d5 <= top_bot_border_d4;
    end
end

wire [7:0] lpx;
wire [7:0] lpy;

lightpen vic_lightpen(
             .clk_dot4x(clk_dot4x),
             .rst(rst),
             .ilp_clr(ilp_clr),
             .raster_line(raster_line),
             .raster_y_max(raster_y_max),
             .lp(lp),
             .xpos_div_2(xpos[8:1]),
             .lpx(lpx),
             .lpy(lpy),
             .ilp(ilp)
         );

raster vic_raster(
           .clk_phi(clk_phi),
           .clk_dot4x(clk_dot4x),
           .rst(rst),
           .phi_phase_start_0(phi_phase_start[0]),
           .dot_rising_0(dot_rising[0]),
           .chip(chip),
           .cycle_num(cycle_num),
           .raster_x_max(raster_x_max),
           .raster_y_max(raster_y_max),
           .xpos(xpos),
           .raster_x(raster_x),
           .sprite_raster_x(sprite_raster_x),
           .raster_line(raster_line),
           .raster_line_d(raster_line_d)
       );

matrix vic_matrix(
           .rst(rst),
           .clk_phi(clk_phi),
           .clk_dot4x(clk_dot4x),
           .phi_phase_start_1(phi_phase_start[1]),
           .phi_phase_start_14(phi_phase_start[14]),
           .cycle_num(cycle_num),
           .raster_line(raster_line),
           .badline(badline),
           .idle(idle),
           .vc(vc),
           .rc(rc)
       );

// Handle when ba should go low due to c-access. We can use xpos
// here since there are no repeats within this range.
always @(*)
    if (rst)
        ba_chars = `FALSE;
    else begin
        if ((xpos >= chars_ba_start || xpos < chars_ba_end) && badline)
            ba_chars = `FALSE;
        else
            ba_chars = `TRUE;
    end

// Handle when ba should go low due to s-access. These ranges are
// compared against sprite_raster_x which is just raster_x with an
// offset that brings sprite 0 to the start.
always @(*) begin
    for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
        if (sprite_dma[n] && sprite_raster_x >= sprite_ba_start[n] &&
                sprite_raster_x < sprite_ba_end[n])
            ba_sprite[n] = 1;
        else
            ba_sprite[n] = 0;
    end
end

// Drop BA if either chars or sprites need it.
assign ba = ba_chars & (ba_sprite == 0);

// Cascade ba through three cycles, making sure
// aec is lowered 3 cycles after ba went low
reg ba1,ba2,ba3;
always @(posedge clk_dot4x)
    if (rst) begin
        ba1 <= `TRUE;
        ba2 <= `TRUE;
        ba3 <= `TRUE;
    end
    else begin
        if (clk_phi == `TRUE && phi_phase_start[15]) begin
            ba1 <= ba;
            ba2 <= ba1 | ba;
            ba3 <= ba2 | ba;
        end
    end

// Cycle state machine
cycles vic_cycles(
           .rst(rst),
           .clk_dot4x(clk_dot4x),
           .clk_phi(clk_phi),
           .chip(chip),
           .phi_phase_start_1(phi_phase_start[1]),
           .sprite_dma(sprite_dma),
           .badline(badline),
           .cycle_num(cycle_num),
           .cycle_type(cycle_type),
           .sprite_cnt(sprite_cnt)
       );

// sprite logic
wire handle_sprite_crunch;
wire m2m_clr;
wire m2d_clr;
wire [7:0] sprite_m2m;
wire [7:0] sprite_m2d;
wire main_border_stage1;

wire [7:0] sprite_mmc_d;
wire [7:0] sprite_pri_d;
wire [3:0] active_sprite_d;

sprites vic_sprites(
            .rst(rst),
            .clk_dot4x(clk_dot4x),
            .clk_phi(clk_phi),
            .cycle_type(cycle_type),
            .dbi8(dbi[7:0]),
            .dot_rising_1(dot_rising[1]),
            .phi_phase_start_m2clr(phi_phase_start[`M2CLR_CHECK]),
            .phi_phase_start_1(phi_phase_start[1]),
            .phi_phase_start_dav(phi_phase_start[`DATA_DAV]),
            .xpos(xpos_sprite[8:0]), // top bit omitted
            .raster_line(raster_line[7:0]), // top bit omitted
            .cycle_num(cycle_num),
            .cycle_bit(raster_x[2:0]),
            .handle_sprite_crunch(handle_sprite_crunch),
            .sprite_x_o(sprite_x_o),
            .sprite_y_o(sprite_y_o),
            .sprite_xe(sprite_xe),
            .sprite_ye(sprite_ye),
            .sprite_en(sprite_en),
            .sprite_mmc(sprite_mmc),
            .sprite_pri(sprite_pri),
            .sprite_pri_d(sprite_pri_d),
            .sprite_cnt(sprite_cnt),
            .aec(aec),
            .is_background_pixel(is_background_pixel1),
            .stage0(stage0),
            .stage1(stage1),
            .main_border(main_border_stage1),
            .imbc_clr(imbc_clr),
            .immc_clr(immc_clr),
            .sprite_dmachk1(sprite_dmachk1),
            .sprite_dmachk2(sprite_dmachk2),
            .sprite_yexp_chk(sprite_yexp_chk),
            .sprite_disp_chk(sprite_disp_chk),
            .immc(immc),
            .imbc(imbc),
            .sprite_cur_pixel_o(sprite_cur_pixel_o),
            .sprite_mc_o(sprite_mc_o),
            .sprite_dma(sprite_dma),
            .m2m_clr(m2m_clr),
            .m2d_clr(m2d_clr),
            .sprite_m2m(sprite_m2m),
            .sprite_m2d(sprite_m2d),
            .sprite_mmc_d(sprite_mmc_d),
            .active_sprite_d(active_sprite_d)
        );


// AEC LOW tells CPU to tri-state its bus lines
// AEC will remain HIGH during PHI phase 2 for 3 cycles
// after which it will remain LOW with ba.
always @(posedge clk_dot4x)
    if (rst) begin
        aec <= `FALSE;
    end else
    begin
        aec <= ba ? clk_phi : ba3 & clk_phi;
    end

// For reference, on LS245's:
//    OE pin low = all channels active
//    OE pin high = all channels disabled
//    DIR pin low = Bx to Ax (vic sets bus)
//    DIR pin high = Ax to Bx (vic reads bus)

// Both data/addr LS245s have OE pin grounded (always enabled)

// We write to data bus when chip select is low and rw is high
// (cpu reading from us).
assign vic_write_db = rw && ~ce;

// AEC low means we own the address bus so we can write to it.
// For address bus direction pin, use aec,
assign vic_write_ab = ~aec;

// For data bus direction, use inverse of vic_write_db
assign ls245_data_dir = ~vic_write_db;
assign ls245_data_oe = 1'b0; // aec & ce;  for now, always enable
assign ls245_addr_dir = aec;
assign ls245_addr_oe = 1'b0; // aec & ce;  for now, always enable


// Handle cycles that perform data bus accesses
bus_access vic_bus_access(
               .rst(rst),
               .clk_dot4x(clk_dot4x),
               .phi_phase_start_dav(phi_phase_start[`DATA_DAV]),
               .cycle_type(cycle_type),
               .dbi(dbi),
               .idle(idle),
               .sprite_cnt(sprite_cnt),
               .sprite_dma(sprite_dma),
               .sprite_ptr_o(sprite_ptr_o),
               .pixels_read(pixels_read),
               .char_read(char_read),
               .char_next(char_next),
               .aec(aec)
           );

// Address generation
addressgen vic_addressgen(
               //.rst(rst),
               .cycle_type(cycle_type),
               .clk_dot4x(clk_dot4x),
               .cb(cb),
               .vc(vc),
               .vm(vm),
               .rc(rc),
               .ras(ras),
               .cas(cas),
               // Some magic from VICE:
               //    g_fetch_addr((uint8_t)(vicii.regs[0x11] |
               //        (vicii.reg11_delay & 0x20)));
               .bmm(bmm | bmm_delayed),
               .ecm(ecm), // NOT delayed!
               .idle(idle),
               .refc(refc),
               .char_ptr(char_next[7:0]),
               .aec(aec),
               .sprite_cnt(sprite_cnt),
               .sprite_ptr_o(sprite_ptr_o),
               .sprite_mc_o(sprite_mc_o),
               .phi_phase_start_rlh(phi_phase_start[0]),
               .phi_phase_start_rhl(phi_phase_start[5]),
               .phi_phase_start_clh(phi_phase_start[15]),
               .phi_phase_start_chl(phi_phase_start[7]),
               .phi_phase_start_row(phi_phase_start[2]),
               .phi_phase_start_col(phi_phase_start[6]),
               .ado(ado));

// Handle set/get registers
registers vic_registers(
              .rst(rst),
              .clk_dot4x(clk_dot4x),
              .clk_phi(clk_phi),
              .phi_phase_start_dav_plus_1(phi_phase_start[`DATA_DAV_PLUS_1]),
              .phi_phase_start_dav(phi_phase_start[`DATA_DAV]),
              .ce(ce),
              .rw(rw),
              .aec(aec),
              .ras(ras),
              .adi(adi),
              .dbi(dbi[7:0]),
              .raster_line(raster_line_d), // advertise the delayed version
              .irq(irq),
              .ilp(ilp),
              .immc(immc),
              .imbc(imbc),
              .irst(irst),
              .sprite_m2m(sprite_m2m),
              .sprite_m2d(sprite_m2d),
              .lpx(lpx),
              .lpy(lpy),
              .ec(ec),
              .b0c(b0c),
              .b1c(b1c),
              .b2c(b2c),
              .b3c(b3c),
              .xscroll(xscroll),
              .yscroll(yscroll),
              .csel(csel),
              .rsel(rsel),
              .den(den),
              .bmm(bmm),
              .ecm(ecm),
              .mcm(mcm),
              .irst_clr(irst_clr),
              .imbc_clr(imbc_clr),
              .immc_clr(immc_clr),
              .ilp_clr(ilp_clr),
              .raster_irq_compare(raster_irq_compare),
              .sprite_en(sprite_en),
              .sprite_xe(sprite_xe),
              .sprite_ye(sprite_ye),
              .sprite_pri(sprite_pri),
              .sprite_mmc(sprite_mmc),
              .sprite_mc0(sprite_mc0),
              .sprite_mc1(sprite_mc1),
              .sprite_x_o(sprite_x_o),
              .sprite_y_o(sprite_y_o),
              .sprite_col_o(sprite_col_o),
              .m2m_clr(m2m_clr),
              .m2d_clr(m2d_clr),
              .handle_sprite_crunch(handle_sprite_crunch),
              .dbo(dbo),
              .cb(cb),
              .vm(vm),
              .elp(elp),
              .emmc(emmc),
              .embc(embc),
              .erst(erst)
          );

// at the start of every high phase, store current reg11 for delayed fetch
// and badline calcs
always @(posedge clk_dot4x)
begin
    // must be before badline idle reset in vic_matrix
    if (clk_phi && phi_phase_start[0]) begin
`ifdef IS_SIMULATOR
        reg11_delayed <= { raster_line[8], ecm, bmm, den, rsel, yscroll };
`endif
        bmm_delayed <= bmm;
        ecm_delayed <= ecm;
        mcm_delayed <= mcm;
    end
end


// Pixel sequencer - outputs stage 3 pixel_color3
pixel_sequencer vic_pixel_sequencer(
                    .clk_dot4x(clk_dot4x),
                    .clk_phi(clk_phi),
                    .dot_rising_1(dot_rising[1]),
                    .dot_rising_3(dot_rising[3]),
                    .phi_phase_start_pl(phi_phase_start[`PIXEL_LATCH]),
                    .phi_phase_start_dav(phi_phase_start[`DATA_DAV]),
                    .mcm(mcm_delayed), // delayed
                    .bmm(bmm_delayed), // delayed
                    .ecm(ecm_delayed), // delayed
                    .idle(idle),
                    .cycle_bit(raster_x[2:0]),
                    .cycle_num(cycle_num),
`ifdef PIXEL_LOG
                    .raster_line(raster_line),
`endif
                    .xscroll(xscroll),
                    .pixels_read(pixels_read),
                    .char_read(char_read),
                    .b0c(b0c),
                    .b1c(b1c),
                    .b2c(b2c),
                    .b3c(b3c),
                    .ec(ec),
                    .main_border(main_border_d5), // in
                    .vborder(top_bot_border_d5), // in
                    .main_border_stage1(main_border_stage1), // out for sprite
                    .sprite_cur_pixel_o(sprite_cur_pixel_o),
                    .sprite_pri_d(sprite_pri_d),  // delayed
                    .sprite_mmc_d(sprite_mmc_d),  // delayed
                    .sprite_col_o(sprite_col_o),
                    .sprite_mc0(sprite_mc0),
                    .sprite_mc1(sprite_mc1),
                    .is_background_pixel1(is_background_pixel1),
                    .stage0(stage0),
                    .stage1(stage1),
                    .pixel_color3(pixel_color3),
                    .active_sprite_d(active_sprite_d)
                );

endmodule : vicii
