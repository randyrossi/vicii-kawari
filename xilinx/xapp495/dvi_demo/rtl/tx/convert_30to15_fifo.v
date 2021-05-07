module convert_30to15_fifo(
  input  wire rst,   // reset
  input  wire clk,   // clock input
  input  wire clkx2, // 2x clock input
  input  wire [29:0] datain,   // input data for 2:1 serialisation
  output wire [14:0] dataout); // 5-bit data out

  ////////////////////////////////////////////////////
  // Here we instantiate a 16x10 Dual Port RAM
  // and fill first it with data aligned to
  // clk domain
  ////////////////////////////////////////////////////
  wire  [3:0]   wa;       // RAM read address
  reg   [3:0]   wa_d;     // RAM read address
  wire  [3:0]   ra;       // RAM read address
  reg   [3:0]   ra_d;     // RAM read address
  wire  [29:0]  dataint;  // RAM output

  parameter ADDR0  = 4'b0000;
  parameter ADDR1  = 4'b0001;
  parameter ADDR2  = 4'b0010;
  parameter ADDR3  = 4'b0011;
  parameter ADDR4  = 4'b0100;
  parameter ADDR5  = 4'b0101;
  parameter ADDR6  = 4'b0110;
  parameter ADDR7  = 4'b0111;
  parameter ADDR8  = 4'b1000;
  parameter ADDR9  = 4'b1001;
  parameter ADDR10 = 4'b1010;
  parameter ADDR11 = 4'b1011;
  parameter ADDR12 = 4'b1100;
  parameter ADDR13 = 4'b1101;
  parameter ADDR14 = 4'b1110;
  parameter ADDR15 = 4'b1111;

  always@(wa) begin
    case (wa)
      ADDR0   : wa_d = ADDR1 ;
      ADDR1   : wa_d = ADDR2 ;
      ADDR2   : wa_d = ADDR3 ;
      ADDR3   : wa_d = ADDR4 ;
      ADDR4   : wa_d = ADDR5 ;
      ADDR5   : wa_d = ADDR6 ;
      ADDR6   : wa_d = ADDR7 ;
      ADDR7   : wa_d = ADDR8 ;
      ADDR8   : wa_d = ADDR9 ;
      ADDR9   : wa_d = ADDR10;
      ADDR10  : wa_d = ADDR11;
      ADDR11  : wa_d = ADDR12;
      ADDR12  : wa_d = ADDR13;
      ADDR13  : wa_d = ADDR14;
      ADDR14  : wa_d = ADDR15;
      default : wa_d = ADDR0;
    endcase
  end

  FDC fdc_wa0 (.C(clk),  .D(wa_d[0]), .CLR(rst), .Q(wa[0]));
  FDC fdc_wa1 (.C(clk),  .D(wa_d[1]), .CLR(rst), .Q(wa[1]));
  FDC fdc_wa2 (.C(clk),  .D(wa_d[2]), .CLR(rst), .Q(wa[2]));
  FDC fdc_wa3 (.C(clk),  .D(wa_d[3]), .CLR(rst), .Q(wa[3]));

  //Dual Port fifo to bridge data from clk to clkx2
  DRAM16XN #(.data_width(30))
  fifo_u (
         .DATA_IN(datain),
         .ADDRESS(wa),
         .ADDRESS_DP(ra),
         .WRITE_EN(1'b1),
         .CLK(clk),
         .O_DATA_OUT(),
         .O_DATA_OUT_DP(dataint));

  /////////////////////////////////////////////////////////////////
  // Here starts clk2x domain for fifo read out 
  // FIFO read is set to be once every 2 cycles of clk2x in order
  // to keep up pace with the fifo write speed
  // Also FIFO read reset is delayed a bit in order to avoid
  // underflow.
  /////////////////////////////////////////////////////////////////

  always@(ra) begin
    case (ra)
      ADDR0   : ra_d = ADDR1 ;
      ADDR1   : ra_d = ADDR2 ;
      ADDR2   : ra_d = ADDR3 ;
      ADDR3   : ra_d = ADDR4 ;
      ADDR4   : ra_d = ADDR5 ;
      ADDR5   : ra_d = ADDR6 ;
      ADDR6   : ra_d = ADDR7 ;
      ADDR7   : ra_d = ADDR8 ;
      ADDR8   : ra_d = ADDR9 ;
      ADDR9   : ra_d = ADDR10;
      ADDR10  : ra_d = ADDR11;
      ADDR11  : ra_d = ADDR12;
      ADDR12  : ra_d = ADDR13;
      ADDR13  : ra_d = ADDR14;
      ADDR14  : ra_d = ADDR15;
      default : ra_d = ADDR0;
    endcase
  end

  wire rstsync, rstsync_q, rstp;
  (* ASYNC_REG = "TRUE" *) FDP fdp_rst  (.C(clkx2),  .D(rst), .PRE(rst), .Q(rstsync));

  FD fd_rstsync (.C(clkx2),  .D(rstsync), .Q(rstsync_q));
  FD fd_rstp    (.C(clkx2),  .D(rstsync_q), .Q(rstp));

  wire sync;
  FDR sync_gen (.Q (sync), .C (clkx2), .R(rstp), .D(~sync));

  FDRE fdc_ra0 (.C(clkx2),  .D(ra_d[0]), .R(rstp), .CE(sync), .Q(ra[0]));
  FDRE fdc_ra1 (.C(clkx2),  .D(ra_d[1]), .R(rstp), .CE(sync), .Q(ra[1]));
  FDRE fdc_ra2 (.C(clkx2),  .D(ra_d[2]), .R(rstp), .CE(sync), .Q(ra[2]));
  FDRE fdc_ra3 (.C(clkx2),  .D(ra_d[3]), .R(rstp), .CE(sync), .Q(ra[3]));

  wire [29:0] db;

  FDE fd_db0 (.C(clkx2), .D(dataint[0]),   .CE(sync), .Q(db[0]));
  FDE fd_db1 (.C(clkx2), .D(dataint[1]),   .CE(sync), .Q(db[1]));
  FDE fd_db2 (.C(clkx2), .D(dataint[2]),   .CE(sync), .Q(db[2]));
  FDE fd_db3 (.C(clkx2), .D(dataint[3]),   .CE(sync), .Q(db[3]));
  FDE fd_db4 (.C(clkx2), .D(dataint[4]),   .CE(sync), .Q(db[4]));
  FDE fd_db5 (.C(clkx2), .D(dataint[5]),   .CE(sync), .Q(db[5]));
  FDE fd_db6 (.C(clkx2), .D(dataint[6]),   .CE(sync), .Q(db[6]));
  FDE fd_db7 (.C(clkx2), .D(dataint[7]),   .CE(sync), .Q(db[7]));
  FDE fd_db8 (.C(clkx2), .D(dataint[8]),   .CE(sync), .Q(db[8]));
  FDE fd_db9 (.C(clkx2), .D(dataint[9]),   .CE(sync), .Q(db[9]));
  FDE fd_db10 (.C(clkx2), .D(dataint[10]), .CE(sync), .Q(db[10]));
  FDE fd_db11 (.C(clkx2), .D(dataint[11]), .CE(sync), .Q(db[11]));
  FDE fd_db12 (.C(clkx2), .D(dataint[12]), .CE(sync), .Q(db[12]));
  FDE fd_db13 (.C(clkx2), .D(dataint[13]), .CE(sync), .Q(db[13]));
  FDE fd_db14 (.C(clkx2), .D(dataint[14]), .CE(sync), .Q(db[14]));
  FDE fd_db15 (.C(clkx2), .D(dataint[15]), .CE(sync), .Q(db[15]));
  FDE fd_db16 (.C(clkx2), .D(dataint[16]), .CE(sync), .Q(db[16]));
  FDE fd_db17 (.C(clkx2), .D(dataint[17]), .CE(sync), .Q(db[17]));
  FDE fd_db18 (.C(clkx2), .D(dataint[18]), .CE(sync), .Q(db[18]));
  FDE fd_db19 (.C(clkx2), .D(dataint[19]), .CE(sync), .Q(db[19]));
  FDE fd_db20 (.C(clkx2), .D(dataint[20]), .CE(sync), .Q(db[20]));
  FDE fd_db21 (.C(clkx2), .D(dataint[21]), .CE(sync), .Q(db[21]));
  FDE fd_db22 (.C(clkx2), .D(dataint[22]), .CE(sync), .Q(db[22]));
  FDE fd_db23 (.C(clkx2), .D(dataint[23]), .CE(sync), .Q(db[23]));
  FDE fd_db24 (.C(clkx2), .D(dataint[24]), .CE(sync), .Q(db[24]));
  FDE fd_db25 (.C(clkx2), .D(dataint[25]), .CE(sync), .Q(db[25]));
  FDE fd_db26 (.C(clkx2), .D(dataint[26]), .CE(sync), .Q(db[26]));
  FDE fd_db27 (.C(clkx2), .D(dataint[27]), .CE(sync), .Q(db[27]));
  FDE fd_db28 (.C(clkx2), .D(dataint[28]), .CE(sync), .Q(db[28]));
  FDE fd_db29 (.C(clkx2), .D(dataint[29]), .CE(sync), .Q(db[29]));

  wire [14:0] mux;
  assign mux = (~sync) ? db[14:0] : db[29:15];

  FD fd_out0 (.C(clkx2), .D(mux[0]), .Q(dataout[0]));
  FD fd_out1 (.C(clkx2), .D(mux[1]), .Q(dataout[1]));
  FD fd_out2 (.C(clkx2), .D(mux[2]), .Q(dataout[2]));
  FD fd_out3 (.C(clkx2), .D(mux[3]), .Q(dataout[3]));
  FD fd_out4 (.C(clkx2), .D(mux[4]), .Q(dataout[4]));
  FD fd_out5 (.C(clkx2), .D(mux[5]), .Q(dataout[5]));
  FD fd_out6 (.C(clkx2), .D(mux[6]), .Q(dataout[6]));
  FD fd_out7 (.C(clkx2), .D(mux[7]), .Q(dataout[7]));
  FD fd_out8 (.C(clkx2), .D(mux[8]), .Q(dataout[8]));
  FD fd_out9 (.C(clkx2), .D(mux[9]), .Q(dataout[9]));
  FD fd_out10 (.C(clkx2), .D(mux[10]), .Q(dataout[10]));
  FD fd_out11 (.C(clkx2), .D(mux[11]), .Q(dataout[11]));
  FD fd_out12 (.C(clkx2), .D(mux[12]), .Q(dataout[12]));
  FD fd_out13 (.C(clkx2), .D(mux[13]), .Q(dataout[13]));
  FD fd_out14 (.C(clkx2), .D(mux[14]), .Q(dataout[14]));

endmodule
