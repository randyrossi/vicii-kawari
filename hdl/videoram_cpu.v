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

`include "common.vh"

`ifdef CPU_COPROC_ENABLED

// The extended video RAM plus an optional 6502 co-processor that executes out
// of it.
//
// The VRAM is a true dual port block RAM. Port B is the hires scanout fetch and
// is never touched here. Port A is shared between:
//
//   * the legacy master  - the 6510 register window ($d039-$d03f), the VRAM
//                          copy/fill engines, the blitter and the DRAM<->VRAM
//                          DMA engine, all of which drive l_addr/l_we/l_din
//   * the 6502 co-processor
//
// Arbitration is automatic and legacy always wins; there is no user visible
// hold bit to raise before starting a DMA, so software that predates the
// co-processor keeps working unchanged.
//
// The 6502 core assumes a synchronous memory: data is expected on the cycle
// after the address (see the upstream README). The block RAM provides exactly
// that, because its read output is registered. So in the steady state the CPU
// simply owns port A on every cycle and the core advances every cycle.
//
// Withdrawing the port needs care. RDY low freezes the core and makes DIMUX
// fall back to DIHOLD, which keeps AB stable; but the instant RDY rises again
// DIMUX switches back to DI, so AB is only stable if DI already holds the data
// for the address AB is presenting. So after any cycle in which the CPU did not
// own the port, the CPU is given one "re-address" cycle with RDY still low
// before the core is allowed to advance. That restores the pipeline exactly as
// the core would have seen it had the interruption never happened.
//
// Because RDY is only ever released one cycle after an address has been
// presented and left stable, the core's address cannot glitch mid transaction
// and no access can be lost or duplicated.
module videoram_cpu
       #(
           parameter addr_width = `VIDEO_RAM_WIDTH,
           parameter data_width = 8
       )
       (
           input wire clk,
           input wire rst,

           // ---- legacy port A master (6510 window / DMA / blitter / copy / fill)
           input  wire [addr_width-1:0] l_addr,
           input  wire                  l_we,
           input  wire [data_width-1:0] l_din,
           output wire [data_width-1:0] l_dout,
           input  wire                  l_busy,  // engine running
           input  wire                  l_read,  // legacy read in flight

           // ---- video port B (read only), untouched by the CPU
           input  wire [addr_width-1:0] v_addr,
           output wire [data_width-1:0] v_dout,

           // ---- co-processor control
           input  wire [15:0]           cpu_start,   // reset vector
           input  wire                  cpu_reset,   // 1 = hold in reset
           input  wire                  cpu_hold,    // 1 = pause
           input  wire                  cpu_irq,
           input  wire                  cpu_nmi,
           input  wire [1:0]            cpu_speed,   // access rate divider

           // ---- co-processor state readback
           output wire [7:0]            cpu_a,
           output wire [7:0]            cpu_x,
           output wire [7:0]            cpu_y,
           output wire [7:0]            cpu_sp,
           output wire [7:0]            cpu_p,
           output wire [15:0]           cpu_pc,
           output wire                  cpu_owns,
           output wire                  cpu_stalled
       );

// ---------------------------------------------------------------------------
// 6502 core
// ---------------------------------------------------------------------------
wire [15:0] cpu_addr;
wire [7:0]  cpu_do;
wire [7:0]  cpu_di;
wire        cpu_we;
wire        cpu_rdy;

cpu6502 cpu_inst(
    .clk    (clk),
    .reset  (cpu_reset),
    .AB     (cpu_addr),
    .DI     (cpu_di),
    .DO     (cpu_do),
    .WE     (cpu_we),
    .IRQ    (cpu_irq),
    .NMI    (cpu_nmi),
    .RDY    (cpu_rdy),
    .A_out  (cpu_a),
    .X_out  (cpu_x),
    .Y_out  (cpu_y),
    .S_out  (cpu_sp),
    .P_out  (cpu_p),
    .PC_out (cpu_pc)
);

// ---------------------------------------------------------------------------
// Automatic arbitration
//
// Legacy has the port whenever it is reading, writing or running an engine.
// ---------------------------------------------------------------------------
wire legacy_lock = l_busy | l_we | l_read;

// The CPU wants the port whenever legacy is not using it and the CPU is enabled.
wire cpu_want = ~legacy_lock & ~cpu_reset & ~cpu_hold;

// ---------------------------------------------------------------------------
// CPU address register
//
// The CPU address MUST be registered before it reaches the RAM, for two
// independent reasons:
//
//   1. The VRAM wrapper selects the bank with a combinational mux on the top
//      address bits (videoram_efinix.v). Driving that mux from the core's
//      combinational AB would close a real loop:
//      addr -> bank mux -> dout -> DI -> DIMUX -> AB -> addr.
//   2. The bank outputs are registered while the mux select is not, so the
//      select must belong to the same address as the data it is selecting.
//
// It is latched at the *state boundary* (when cpu_rdy is high), not every
// clock, which is what makes it match the core's contract. The core issues
// address A on one bus cycle and expects mem[A] on the NEXT bus cycle; keeping
// addr_r one bus cycle behind AB reproduces exactly that, and leaves it stable
// for the whole access so the bank mux stays aligned with the bank data.
//
// WE and DO are delayed with it. A write must land at the address the core
// presented alongside the data, so all three have to move together; delaying
// only the address would send writes to the previous bus cycle's location.
// ---------------------------------------------------------------------------
reg [15:0] cpu_addr_r;
reg        cpu_we_r;
reg [7:0]  cpu_do_r;

always @(posedge clk) begin
    if (rst || cpu_reset) begin
        cpu_we_r <= 1'b0;
        cpu_do_r <= 8'h00;
    end else if (cpu_rdy) begin
        cpu_addr_r <= cpu_addr;
        cpu_we_r   <= cpu_we;
        cpu_do_r   <= cpu_do;
    end
end

// ---------------------------------------------------------------------------
// Access pipeline
//
// With cpu_speed = 0 a CPU bus cycle takes two clocks:
//
//   clock 0  addr_r (the previous state's address) drives the RAM, RDY low
//   clock 1  bank data for addr_r is valid on vram_dout_a, RDY high so the
//            core samples it and advances; addr_r latches the new AB
//
// cpu_speed stretches the access, which simply freezes the core with a stable
// registered address; the RAM harmlessly re-reads the same location.
//
// Any cycle the CPU does not own the port resets the counter, so after a DMA or
// a 6510 register access the CPU starts a fresh access rather than resuming
// mid pipeline. addr_r is not reloaded while RDY is low, so the address being
// fetched survives the interruption intact.
// ---------------------------------------------------------------------------
reg  [3:0] acc_cnt;
wire [3:0] acc_target = 4'd1 + ((4'd1 << cpu_speed) - 4'd1);
wire       acc_ready  = (acc_cnt == acc_target);

always @(posedge clk) begin
    if (rst || cpu_reset || !cpu_want) acc_cnt <= 4'd0;
    else if (acc_ready)                acc_cnt <= 4'd0;
    else                               acc_cnt <= acc_cnt + 4'd1;
end

assign cpu_owns = cpu_want;
assign cpu_rdy  = cpu_want & acc_ready;

// ---------------------------------------------------------------------------
// Port A multiplexer
// ---------------------------------------------------------------------------
wire [data_width-1:0] vram_dout_a;
wire [addr_width-1:0] vram_addr;
wire                  vram_we;
wire [data_width-1:0] vram_din;

assign vram_addr = cpu_owns ? cpu_addr_r[addr_width-1:0] : l_addr;
assign vram_we   = cpu_owns ? cpu_we_r                   : l_we;
assign vram_din  = cpu_owns ? cpu_do_r                   : l_din;

assign l_dout = vram_dout_a;

// ---------------------------------------------------------------------------
// CPU data in
//
// $FFFC/$FFFD are the 6502 reset vector. The core runs its reset sequence from
// them, so the start vector register is presented here. This shadows two bytes
// of VRAM at the reset vector slot, which is authentic 6502 behaviour and means
// the core needs no state machine modification to start from an arbitrary
// address. addr_r is exactly the address whose data is on vram_dout_a, so it is
// also the address to select on.
// ---------------------------------------------------------------------------
wire [7:0] reset_vec = cpu_addr_r[0] ? cpu_start[15:8] : cpu_start[7:0];

assign cpu_di = (cpu_addr_r[15:1] == 15'h7FFE) ? reset_vec : vram_dout_a;

// Report a stall to software so the 6510 can tell "a DMA is running" from
// "the co-processor is doing something".
assign cpu_stalled = legacy_lock;

// ---------------------------------------------------------------------------
// The extended video RAM
// ---------------------------------------------------------------------------
VIDEO_RAM video_ram(clk,
                    vram_we,
                    vram_addr,
                    vram_din,
                    vram_dout_a,
                    1'b0,          // Video can only read
                    v_addr,
                    8'b0,          // Video can only read
                    v_dout
                   );

endmodule

`endif // CPU_COPROC_ENABLED
