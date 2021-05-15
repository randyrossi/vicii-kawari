/*=======================================================================================

 M95XXX: 1K-2048K Bits Serial SPI Bus EEPROM Verilog Simulation Model

=========================================================================================

 This program is provided "as is" without warranty of any kind, either
 expressed or implied, including but not limited to, the implied warranty
 of merchantability and fitness for a particular purpose. The entire risk
 as to the quality and performance of the program is with you. Should the
 program prove defective, you assume the cost of all necessary servicing,
 repair or correction.
 
 Copyright 2004, STMicroelectronics Corporation, All Right Reserved.

=======================================================================================*/

`include "M95XXX_Parameters.v"
//This defines the parameter file for M95080-W6, "W" or "G" F6SP36% process
//Any other M95xxx memory should define here the proper M95xxx parameter file

//=====================================
// M95080 memory simulation model
//=====================================
module M95XXX(
                C,
                D,
                Q,
                S,
                W,
                HOLD,
                VCC,
                VSS
             );

//=====================================
// I/O signal definition
//=====================================
input  C,D,S,W,HOLD,VCC,VSS;
output Q;

//===================================================================
//define "flag variable", reflecting the device operation status
//===================================================================
integer i,page_no,idx;

reg Q,dout,power_on,power_off,power_on_rst;
reg clk_in,select_ok,bit_counter_en,bit_counter_ld;
reg wr_protect,byte_ok,write_data_byte_ok;
reg write_en_id,write_dis_id,read_data_bytes,read_id_data_bytes,write_data_in,write_id_data_in,write_id_data_end;
reg sr_write,new_sr_byte,write_new_sr_ok,set_new_lockid_ok;
reg instruction_byte,address_h_byte,address_h2_byte,address_l_byte,data_byte,lock_byte;
reg hold_condition,hold_start_next,hold_stop_next;
reg pageidlocked,readidwrap;
reg nonxt_byte;
reg wrapping;
reg rds_inprogress;
reg writemem_in_progress = 0;

reg[1:0] mode;
reg[3:0] operation;
reg[7:0] instruction;
reg[7:0] status_reg,shift_in_reg,data_out_buf,bit_counter;
reg[7:0] lock_latch,sr_latch,instruction_code,address_h2_code,address_h_code,address_l_code;
reg[`MEM_ADDR_BITS-1:0] memory_address;
reg[`PAGE_ADDR_BITS-1:0] page_address;
reg[`PAGE_OFFSET_BITS-1:0] page_offset_addr;
reg[`PAGE_OFFSET_BITS-1:0] start_address,end_address;
reg[`DATA_BITS-1:0] memory[`MEM_SIZE-1:0];
reg[`DATA_BITS-1:0] data_latch[`PAGE_SIZE-1:0];
reg[`DATA_BITS-1:0] memory_id[`PAGE_SIZE-1:0];
reg[`PAGE_OFFSET_BITS:0] page_size;

//===============================================
//define variable regarding timing check
//===============================================
reg  din_change,r_S,f_S,r_C,r_Cr,f_C,r_H,f_H;
time t_rS,t_fS,t_rC,t_fC,t_d,t_rC1,t_rH,t_fH,Tc;
time tCH,tCL,tSLCH,tCHSL,tDVCH,tCHDX,tCHSH,tSHCH,tSHSL,tCLHH,tCLHL,tHLCH,tHHCH;

//=========================================================
//define parameter regarding instruction
//=========================================================
parameter WRITE_ENABLE           = 8'b0000_0001;
parameter WRITE_DISABLE          = 8'b0000_0010;
parameter READ_STATUS_REGISTER   = 8'b0000_0011;
parameter WRITE_STATUS_REGISTER  = 8'b0000_0100;
parameter READ_FROM_MEMORY_ARRAY = 8'b0000_0101;
parameter WRITE_TO_MEMORY_ARRAY  = 8'b0000_0110;
parameter READ_ID_PAGE           = 8'b1000_0011;
parameter WRITE_ID_PAGE          = 8'b1000_0010;
//=========================================================
//define parameter regarding operation
//=========================================================
parameter EN_WRITE               = 4'b0001;
parameter DIS_WRITE              = 4'b0010;
parameter READ_SR_OUT            = 4'b0011;
parameter WRITE_SR_IN            = 4'b0100;
parameter READ_DATA_OUT          = 4'b0101;
parameter WRITE_DATA_IN          = 4'b0110;
parameter READ_ID_DATA_OUT       = 4'b0111;
parameter WRITE_ID_DATA_IN       = 4'b1000;
parameter LOCKID                 = 4'b1001;
//=========================================================
//define parameter regarding device mode
//=========================================================
parameter device_no_power_mode   = 2'b00;
parameter active_power_mode      = 2'b01;
parameter device_standby_mode    = 2'b10;

//===============================================
//"variable" initialization
//===============================================
initial
begin
  mode          = device_no_power_mode;
  power_on      = 1'b0;
  power_off     = 1'b1;
  power_on_rst  = 1'b0;
end

//--------------------------------
always@(power_on_rst)
begin
  if(power_on_rst == 1'b1)
  begin
    mode                = device_standby_mode;
    power_on_rst        = 1'b0;
    byte_ok             = 1'b0;
    select_ok           = 1'b0;
    status_reg          = 7'b00;
    operation           = 4'b0000;
    instruction         = 4'b0000;
    write_data_byte_ok  = 1'b0;
    bit_counter_en      = 1'b0;
    write_en_id         = 1'b0;
    write_dis_id        = 1'b0; 
    instruction_byte    = 1'b0;
    address_h_byte      = 1'b0;
    address_h2_byte     = 1'b0;
    address_l_byte      = 1'b0;
    data_byte           = 1'b0;
    read_data_bytes     = 1'b0;
    read_id_data_bytes  = 1'b0;
    write_data_in       = 1'b0;
    write_id_data_in    = 1'b0;
    write_id_data_end   = 1'b0;
    wr_protect          = 1'b0;
    hold_condition      = 1'b0;
    hold_stop_next      = 1'b0;
    hold_start_next     = 1'b0;
    lock_byte           = 1'b0;
    set_new_lockid_ok   = 1'b0;
    pageidlocked        = 1'b0; 
    page_size           = `PAGE_SIZE;
    nonxt_byte          = 1'b0;
    wrapping            = 1'b0;
    rds_inprogress      = 1'b0;
  end
end

//==========================================
//Write Protect (Hardware Protected)
//==========================================
always@(W)
begin
  if((W == 1'b0)&&(S == 1'b1)&&(power_on == 1'b1))  wr_protect = 1'b1;
  if((W !== 1'b0)&&(W !== 1'b1)&&(power_on == 1'b1))
    $display("%t: WARNING: /W input is not driven, please don't let /W input pin unconnected!\n",$realtime);
end

//==========================================
//Device Power On/Off
//==========================================
always@(VCC)
begin
  if(VCC == 1'b1)
  begin
    mode         = device_standby_mode;
    power_on     = 1'b1;
    power_off    = 1'b0;
    power_on_rst = 1'b1;
    $display("%t: NOTE: DEVICE IS POWERED ON!\n",$realtime);
  end
//-----------------------------------------------
  else begin
    if(power_on == 1'b1) $display("%t: NOTE: DEVICE IS POWERED OFF!\n",$realtime);
    mode         = device_no_power_mode;
    power_on     = 1'b0;
    power_off    = 1'b1;
  end
end

//==========================================
//Hold Condition
//==========================================
always@(HOLD)
begin
  if(power_on == 1'b1)
  begin
    if(HOLD == 1'b0)
    begin
      if(S == 1'b0)
      begin
        if(C == 1'b0)
        begin
          if(hold_stop_next == 1'b1) hold_stop_next = 1'b0;
          if(hold_condition == 1'b1)
            $display("%t: WARNING: This falling edge on HOLD has no effect because HOLD CONDITION has already started!",$realtime);
          else begin
            $display("%t: NOTE: COMMUNICATION PAUSED!",$realtime);
            clk_in = 1'b0; hold_condition = 1'b1;
          end
        end
        else if(C == 1'b1)
        begin
          if(hold_stop_next == 1'b1)
          begin
            hold_start_next = 1'b0; hold_stop_next = 1'b0;
          end
          else if(hold_condition == 1'b0) hold_start_next = 1'b1;
          //$display("%t: WARNING: This falling edge on HOLD can not start HOLD CONDITION because clock is high!",$realtime); 
        end
      end
      else $display("%t: ERROR: The Device is not selected! To start the HOLD condition, /S must be driven low!",$realtime);
    end
    else if(HOLD == 1'b1)
    begin
      if(C == 1'b0)
      begin
        if(hold_start_next == 1'b1) hold_start_next = 1'b0;
        if(hold_condition == 1'b0)
          $display("%t: WARNING: This rising edge on HOLD has no effect because HOLD CONDITION has not started!",$realtime);
        else begin
          $display("%t: NOTE: COMMUNICATION RESUME!\n",$realtime);
          clk_in = C; hold_condition = 1'b0;
        end
      end
      else if(C == 1'b1)
      begin
        if(hold_start_next == 1'b1)
        begin
          hold_start_next = 1'b0; hold_stop_next = 1'b0;
        end
        else if(hold_condition == 1'b1) hold_stop_next = 1'b1;
        //$display("%t: WARNING: This rising edge on HOLD can not end HOLD CONDITION because clock is high!",$realtime); 
      end
    end
    else $display("%t: WARNING: /HOLD input is not driven, please don't let /HOLD input pin unconnected!\n",$realtime); 
  end
  else $display("%t: ERROR: Device is not Powered on!\n",$realtime);
end

//=========================================================
always@(C)
begin
  if(C == 1'b0)
  begin
    if(hold_start_next == 1'b1)
    begin
      hold_start_next = 1'b0; hold_condition = 1'b1;
      $display("%t: NOTE: COMMUNICATION PAUSED!",$realtime);
      //clk_in = 1'b0;
    end
    if(hold_stop_next == 1'b1)
    begin
      hold_stop_next = 1'b0; hold_condition = 1'b0;
      $display("%t: NOTE: COMMUNICATION RESUME!\n",$realtime); 
      //clk_in = C;
    end
  end
  if(hold_condition == 1'b0) clk_in = C;
  if(hold_condition == 1'b1) clk_in = 1'b0;
end

//=========================================================
//during HOLD Condition period, Serial clock is not be care
always@(posedge hold_condition)
begin
  Q = #(M95XXX_SIM.M95XXX_Macro_mux.tHLQZ) 1'bz;
end

//---------------------------
always@(negedge hold_condition)
begin
  Q = #(M95XXX_SIM.M95XXX_Macro_mux.tHHQV) dout;
end

//---------------------------
always@(dout || S)
begin
  if(hold_condition == 1'b0) Q = dout;
end

always@(posedge S) 
begin
  #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ); 
  Q = 1'bz;
  dout = 1'bz;
end


//=========================================================
//chip select driven low, device active.
//=========================================================
always@(negedge S)
begin
  if(power_on == 1'b1)
  begin
    if(W == 1'b0) wr_protect = 1'b1; //W=0 when chip select, Write Protect
    if((W !== 1'b0)&&(W !== 1'b1))
      $display("%t: WARNING: /W input is not driven, please don't let /W input pin unconnected!\n",$realtime);
    if((HOLD !== 1'b0)&&(HOLD !== 1'b1))
      $display("%t: WARNING: /HOLD input is not driven, please don't let /HOLD input pin unconnected!\n",$realtime);
    select_ok        = 1'b1;
    bit_counter_en   = 1'b1;
    bit_counter_ld   = 1'b1;
    instruction_byte = 1'b1;
    mode = active_power_mode;
  end
  else $display("%t: ERROR: Device is not Powered on!\n",$realtime);

end

//=========================================================
//Serial data bit(on the "D" line) input
//=========================================================
always@(posedge clk_in)
begin
  if(power_on == 1'b1)
  begin
    if(S == 1'b0)
    begin
      if((bit_counter_en == 1'b1)&&(bit_counter_ld == 1'b1))
      begin
        bit_counter = 3'b111;
        shift_in_reg = {shift_in_reg[6:0],D};
        if(operation == WRITE_DATA_IN) write_data_byte_ok = 1'b0;
        if(operation == WRITE_ID_DATA_IN) write_data_byte_ok = 1'b0;
        if(operation == EN_WRITE) write_en_id = 1'b0;
        if(operation == DIS_WRITE) write_dis_id = 1'b0;
        if(operation == WRITE_SR_IN) write_new_sr_ok = 1'b0;
        if(operation == LOCKID) set_new_lockid_ok = 1'b0;
      end
      else if((bit_counter_en == 1'b1)&&(bit_counter_ld == 1'b0))
      begin
        bit_counter = bit_counter - 3'b001;
        shift_in_reg = {shift_in_reg[6:0],D};
      end
      if((bit_counter_en == 1'b1)&&(bit_counter == 3'b000))
      begin
        byte_ok = 1'b1;
        bit_counter_en = 1'b0;
      end
      else if(bit_counter_en == 1'b1) bit_counter_ld = 1'b0;
    end
    else $display("%t: WARNING: Device is in standby mode! Falling edge on /S is required!\n",$realtime);
  end
  else $display("%t: ERROR: Device is not Powered on!\n",$realtime);
end

//===================================================================
//chip select driven high, internal write cycle and standby
//===================================================================
  //----------------------------Read status register

always@(posedge S)              //chip select driven high,device disable.
begin

  if(operation == READ_SR_OUT)
  begin
    operation = 4'b0000;
    instruction = 4'b0000;
    $display("%t: NOTE: Read status register operation is finished.\n",$realtime);
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
    rds_inprogress = 1'b0;
  end
end

always@(posedge S)              //chip select driven high,device disable.
begin
  select_ok = 1'b0;


  //used on last bit of last data byte when the S enable is deactivated when byte_ok is still set last falling edge clk never arrives
  if((mode == active_power_mode)&&(data_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    byte_ok = 1'b0;
    data_latch[page_offset_addr] = shift_in_reg;
    if(page_offset_addr == {`PAGE_OFFSET_BITS {1'b1}}) page_offset_addr = {`PAGE_OFFSET_BITS {1'b0}};
    else page_offset_addr = page_offset_addr + {{`PAGE_OFFSET_BITS-1 {1'b0}},1'b1};
    end_address = page_offset_addr;
    bit_counter_en = 1'b1;
    bit_counter_ld = 1'b1;
    write_data_byte_ok = 1'b1;
  end

  //----------------------------new SR value input --used on last bit of last data byte when the S enable is deactivated when byte_ok is still set last falling edge clk never arrives
  if((mode == active_power_mode)&&(new_sr_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    byte_ok = 1'b0;
    sr_latch = shift_in_reg;
    new_sr_byte = 1'b0;
    write_new_sr_ok = 1'b1;
  end

  //---------------------------- Write Lock ID --used on last bit of last data byte when the S enable is deactivated when byte_ok is still set last falling edge clk never arrives
  if((mode == active_power_mode)&&(lock_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    byte_ok = 1'b0;
    lock_latch = shift_in_reg;
    lock_byte = 1'b0;
    set_new_lockid_ok = 1'b1;
  end

  //----------------------------Read Data From Memory Array
  if(operation == READ_DATA_OUT)
  begin
    if(i==0)
    begin
      if(memory_address[`MEM_ADDR_BITS-1:0] == {`MEM_ADDR_BITS {1'b1}}) //`MEM_ADDR_BITS'h3ff)
        memory_address[`MEM_ADDR_BITS-1:0] = {`MEM_ADDR_BITS {1'b0}};
      else memory_address[`MEM_ADDR_BITS-1:0] = memory_address[`MEM_ADDR_BITS-1:0] + {{`MEM_ADDR_BITS-1 {1'b0}},1'b1};// `MEM_ADDR_BITS'h001;
      i = 8;
    end
    data_out_buf = memory[memory_address[`MEM_ADDR_BITS-1:0]];
    dout = data_out_buf[i-1];
    i = i-1;
  end

  //----------------------------Read Data From ID Memory Array or Read lock status
  if(operation == READ_ID_DATA_OUT)
  begin
      if(i==0)
      begin  //??????????????? WRAP AROUND ?????????????????
        if((readidwrap)&&(memory_address[`PAGE_OFFSET_BITS-1:0] == {`PAGE_OFFSET_BITS {1'b0}})) $display("%t: ERROR:  The number of bytes read has exceeded ID page boundary [%d], unexpected data is read\n",$realtime,page_size);

        if(memory_address[`PAGE_OFFSET_BITS-1:0] == {`PAGE_OFFSET_BITS {1'b1}})
        begin
           memory_address[`PAGE_OFFSET_BITS-1:0] = {`PAGE_OFFSET_BITS {1'b0}}; 
           $display("%t: NOTE:  The number of bytes read has reached ID page boundary [%d]\n",$realtime,page_size-1);
           readidwrap = 1'b1;
        end
        else memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + {{`PAGE_OFFSET_BITS-1 {1'b0}},1'b1};
        i = 8;
      end
      data_out_buf = memory_id[memory_address[`PAGE_OFFSET_BITS-1:0]];
      dout = data_out_buf[i-1];
      i = i-1;
  end


  //----------------------------incorrect /S input checking
  if(instruction_byte == 1'b1 && !byte_ok) $display("%t: ERROR: /S is driven high during the instruction byte latched in.",$realtime);
  if(address_h2_byte  == 1'b1) $display("%t: ERROR: /S is driven high during the high byte 2 address byte latched in.",$realtime);
  if(address_h_byte   == 1'b1) $display("%t: ERROR: /S is driven high during the high byte 1 address byte latched in.",$realtime);
  if(address_l_byte   == 1'b1) $display("%t: ERROR: /S is driven high during the low address byte latched in.",$realtime);
  if(hold_condition   == 1'b1) 
  begin
    hold_condition = 1'b0;
    $display("%t: WARNING: /S is driven high when memory is in the HOLD Condition, Reset the current state of memory!",$realtime);
  end
  //----------------------------Write Enable Instruction Execute
  if(operation == EN_WRITE)
  begin
    operation = 4'b0000;
    if(write_en_id == 1'b1)
    begin
      write_en_id   = 1'b0;
      status_reg[1] = 1'b1;     //WEL is Set
      $display("%t: NOTE: WRITE ENABLE.\n",$realtime);
    end
    else if(write_en_id == 1'b0)
      $display("%t: ERROR: \"/S\" should not be deselected after the 8th bit of the write enable instruction code is latched. Write Enable instruction is not executed.\n",$realtime);
  end
  //----------------------------Write Disable Instruction Execute
  if(operation == DIS_WRITE)
  begin
    operation = 4'b0000;
    if(write_dis_id == 1'b1)
    begin
      write_dis_id  = 1'b0;
      status_reg[1] = 1'b0;     //WEL is Reset
      $display("%t: NOTE: WRITE DISABLE.\n",$realtime);
    end
    else if(write_dis_id == 1'b0)
      $display("%t: ERROR: \"/S\" should not be deselected after the 8th bit of the write disable instruction code is latched. Write Disable instruction is not executed.\n",$realtime);
  end
/*  //----------------------------Read status register
  if(operation == READ_SR_OUT)
  begin
    operation = 4'b0000;
    instruction = 4'b0000;
    $display("%t: NOTE: Read status register operation is finished.\n",$realtime);
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
    rds_inprogress = 1'b0;
  end
*/
  //----------------------------Write SR Instruction Execute
  if(operation == WRITE_SR_IN)
  begin
    operation = 4'b0000;
    if(write_new_sr_ok == 1'b1)
    begin
      write_new_sr_ok = 1'b0;
      if((wr_protect == 1'b1)&&(status_reg[7] == 1'b1)) //Hardware write protect
      begin
        $display("%t: WARNING: The Write Status Register(WRSR) instruction is not executed because Hardware Write Protected Mode(HPM) is entered!\n",$realtime);
        //$display("%t: WARNING: Status Register is Hardware Write Protected, the values in BP1,0 can't be Changed!\n",$realtime);
        //status_reg[0] = 1'b1;           //WIP is 1 during this cycle
        //#(M95XXX_SIM.M95XXX_Macro_mux.tW);                         //Write time
        //status_reg[7] = sr_latch[7];    //SRWD
        //$display("%t: NOTE: Write Status Register Instruction finish!\n",$realtime);
        //status_reg[0] = 1'b0;           //WIP is reset when write cycle is completed.
        //status_reg[1] = 1'b0;           //WEL is reset when write cycle is completed.
      end
      else begin
        $display("%t: NOTE: Begin to Write Status Register!",$realtime);
        status_reg[0] = 1'b1;           //WIP is 1 during this cycle
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);                         //Write time
        status_reg[3:2]= sr_latch[3:2]; //BP1,BP0
        status_reg[7] = sr_latch[7];    //SRWD
        $display("%t: NOTE: Write Status Register successfully!",$realtime);
        status_reg[0] = 1'b0;           //WIP is reset when write cycle is completed.
        status_reg[1] = 1'b0;           //WEL is reset when write cycle is completed.
      end
    end
    else if(write_new_sr_ok == 1'b0)
      $display("%t: ERROR: \"/S\" should not be deselected after the 8th bit of data is latched, Write SR instruction is not executed.\n",$realtime);

    nonxt_byte = 1'b0;
  end
  //----------------------------
  if(operation == READ_DATA_OUT)
  begin
    operation = 4'b0000;
    $display("%t: NOTE: Read data bytes operation is finished.\n",$realtime);
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
  end
  //----------------------------
  if(operation == READ_ID_DATA_OUT)
  begin
    operation = 4'b0000;
    readidwrap = 1'b0;
    if(!memory_address[10]) $display("%t: NOTE: Read ID data bytes operation is finished.\n",$realtime);
    else $display("%t: NOTE: Read Lock Status data bytes operation is finished.\n",$realtime);
    
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
  end
 
  //----------------------------Write LOCK ID
  if(operation == LOCKID)
  begin
    lock_byte = 1'b0;
    operation = 4'b0000;
    if(status_reg[3:2] == 2'b11)
      $display("%t: WARNING: Whole memory is Write Protected, the LOCK ID instruction is not accepted!\n",$realtime);
    else if(pageidlocked)
      $display("%t: WARNING: The identification page is already locked by the Lock status bit, the LOCK ID instruction is not accepted!\n",$realtime);
    else begin
      if(set_new_lockid_ok == 1'b1)
      begin                             
        set_new_lockid_ok = 1'b0;
        if(lock_latch[1])
        begin
          pageidlocked = 1'b1; 
          #(M95XXX_SIM.M95XXX_Macro_mux.tW);                         //Write Time
          $display("%t: NOTE: LOCK ID accepted and the Identification Memory is Now Permanently locked, operation is finished.\n",$realtime);
        end
        else
          $display("%t: WARNING: LOCK ID not accepted due to bit two not equal to zero, operation is finished.\n",$realtime);         
      end
      else if((set_new_lockid_ok == 1'b0)&&(!nonxt_byte))
        $display("%t: ERROR: \"/S\" should not be deselected after the 8th bit of data is latched, Page Program instruction is not executed.\n",$realtime);
    end
  end

  //----------------------------Write Data Instruction Execute
  if((operation == WRITE_DATA_IN)||(operation == WRITE_ID_DATA_IN))
  begin
    writemem_in_progress = 1'b1;

    data_byte = 1'b0;
    operation = 4'b0000;
    page_no = page_address;
    if(status_reg[3:2] == 2'b11)
      $display("%t: WARNING: Whole memory is Write Protected, the Byte Write instruction is not accepted!\n",$realtime);
    else if((status_reg[3:2] == 2'b10)&&(page_no >= `PAGES/2)&&(!write_id_data_end))
      $display("%t: WARNING: Upper half of memory is Write Protected, the Byte Write instruction is not accepted!\n",$realtime);
    else if((status_reg[3:2] == 2'b01)&&(page_no >= `PAGES*3/4)&&(!write_id_data_end))
      $display("%t: WARNING: Upper quarter of memory is Write Protected, the Byte Write instruction is not accepted!\n",$realtime);
    else if((pageidlocked)&&(write_id_data_end))
      $display("%t: WARNING: ID PAGE is Permanently Locked, the Write Instruction ID Cycle has not been accepted!\n",$realtime);
    else begin
      if(write_data_byte_ok == 1'b1)
      begin                             //Page Program
        write_data_byte_ok = 1'b0;
        if(write_id_data_end) $display("%t: NOTE: ID Page: Program Cycle has started!",$realtime); 
        else  $display("%t: NOTE: Page[%d] Program Cycle has started!",$realtime,page_address);
        status_reg[0] = 1'b1;           //WIP is 1 during this cycle
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);                         //Write Time
        if(start_address == end_address)  //Definite Page wrap around
        begin : loop1
          for(idx=1;idx<=`PAGE_SIZE;idx=idx+1)
          begin
            if(write_id_data_end) 
            begin
              if((write_id_data_end)&&(wrapping == 1'b1))
              begin
                 wrapping = 1'b0;
                 $display("%t: Error: Cannot write beyond the boundry of the ID Page!\n",$realtime);
                 disable loop1; 
              end 

               if(!memory_address[10] && !wrapping) memory_id[start_address] = data_latch[start_address];

            end
            else memory[{page_address,start_address}] = data_latch[start_address];
            
            if(start_address == {`PAGE_OFFSET_BITS {1'b1}})  
            begin
                start_address = {`PAGE_OFFSET_BITS {1'b0}};
                if(write_id_data_end) wrapping = 1'b1;
            end
            else start_address = start_address + {{`PAGE_OFFSET_BITS-1 {1'b0}},1'b1};
          end
        end
        else begin :loop2
        while(!(start_address == end_address))
          begin
            if(write_id_data_end)
            begin 
              if((write_id_data_end)&&(wrapping == 1'b1))
              begin
                 wrapping = 1'b0;
                 $display("%t: Error: Cannot write beyond the boundry of the ID Page!!\n",$realtime);
                 disable loop2; 
              end 

              if(!memory_address[10] && wrapping==1'b0) memory_id[start_address] = data_latch[start_address];

            end
            else memory[{page_address,start_address}] = data_latch[start_address];
            
            if(start_address == {`PAGE_OFFSET_BITS {1'b1}})
            begin
                start_address = {`PAGE_OFFSET_BITS {1'b0}};

                if(write_id_data_end) wrapping = 1'b1;
            end
            else 
               start_address = start_address + 1; //{{`PAGE_OFFSET_BITS-1 {1'b0}},1'b1};
          end
        end
        
        while(rds_inprogress == 1 && i !== 7) //read status goes directly to 0
        begin : loop
          #(10);
        end

        if(write_id_data_end&&!memory_address[10]) $display("%t: NOTE: ID Page: Program Cycle is completed! \n",$realtime);
        else $display("%t: NOTE: Page[%d] Program Cycle is completed! \n",$realtime,page_address);

        status_reg[0] = 1'b0;           //WIP is 0 when this cycle completed
        status_reg[1] = 1'b0;           //WEL is reset
        
        wrapping = 1'b0;
      end
      else if(write_data_byte_ok == 1'b0)
        $display("%t: ERROR: \"/S\" WRITE should not be deselected after the 8th bit of data is latched, Page Program instruction is not executed.\n",$realtime);
    end
  end
  write_id_data_end = 1'b0;
  
  wr_protect = 1'b0;
  if(S) begin  mode = device_standby_mode; dout = 1'bz; end
 
  writemem_in_progress = 1'b0;
 
end

always@(posedge byte_ok)
begin
  //----------------------------instruction byte input and decode, needed for clk left high at end of transaction
  if((mode == active_power_mode)&&(instruction_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    instruction_code = shift_in_reg;

    casex(instruction_code)
      8'b0000_x110:   begin                     
                          instruction = WRITE_ENABLE;
                          instruction_byte = 1'b0; byte_ok = 1'b0;

                          instruction = 4'b0000;
                          if(status_reg[0] == 1'b1)   //WIP is set, an internal write cycle is in progress
                            $display("%t: WARNING:  An internal write cycle is in progress, this WRITE ENABLE INSTRUCTION is rejected!",$realtime);
                          else begin
                            write_en_id = 1'b1;
                            operation = EN_WRITE;
                            $display("%t: WARNING: WRITE ENABLE INSTRUCTION is starting!",$realtime);
                          end

                      end
      8'b0000_x100:   begin
                          instruction = WRITE_DISABLE;
                          instruction_byte = 1'b0; byte_ok = 1'b0;
                          instruction_code = shift_in_reg;

                          instruction = 4'b0000;
                          if(status_reg[0] == 1'b1)   //WIP is set, an internal write cycle is in progress
                            $display("%t: WARNING:  An internal write cycle is in progress, this WRITE DISABLE INSTRUCTION is rejected!",$realtime);
                          else begin
                            write_dis_id = 1'b1;
                            operation = DIS_WRITE;
                          end
                       end
    endcase
  end
end


//=========================================================
always@(negedge clk_in)
begin
  //----------------------------instruction byte input and decode
  if((mode == active_power_mode)&&(instruction_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    instruction_byte = 1'b0; byte_ok = 1'b0;
    instruction_code = shift_in_reg;

    casex(instruction_code)
      8'b0000_x110:   instruction = WRITE_ENABLE;
      8'b0000_x100:   instruction = WRITE_DISABLE;
      8'b0000_x001:   instruction = WRITE_STATUS_REGISTER;
      8'b0000_x011:   instruction = READ_FROM_MEMORY_ARRAY;
      8'b0000_x010:   instruction = WRITE_TO_MEMORY_ARRAY;
      8'b0000_x101:   begin instruction = READ_STATUS_REGISTER; rds_inprogress = 1'b1; i = 8; end
      8'b1000_x011:   instruction = READ_ID_PAGE; 
      8'b1000_x010:   instruction = WRITE_ID_PAGE;
      default:
        $display("%t: ERROR: The input instruction code[%b] is undefined!\n",$realtime,instruction_code);
    endcase
  end
  //----------------------------address high byte 2 input
  if((mode == active_power_mode)&&(address_h2_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    address_h2_byte = 1'b0; byte_ok = 1'b0;
    address_h2_code = shift_in_reg;
    address_h_byte =1'b1;
    bit_counter_en = 1'b1;
    bit_counter_ld = 1'b1;
  end
  //----------------------------address high byte 1 input
  if((mode == active_power_mode)&&(address_h_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    address_h_byte = 1'b0; byte_ok = 1'b0;
    address_h_code = shift_in_reg;
    address_l_byte =1'b1;
    bit_counter_en = 1'b1;
    bit_counter_ld = 1'b1;
  end
  //----------------------------address low byte input
  if((mode == active_power_mode)&&(address_l_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    address_l_byte = 1'b0; byte_ok = 1'b0;
    address_l_code = shift_in_reg;

    if (`MEM_ADDR_BITS <= 8)
       memory_address = {address_l_code};
    else if (`MEM_ADDR_BITS == 9)
       memory_address = {instruction_code[3],address_l_code};
    else if (9 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 16)
       memory_address = {address_h_code,address_l_code};
    else if (16 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 24)
       memory_address = {address_h2_code,address_h_code,address_l_code};
    //-------------------------  READ MEM OR ID ARRAY  
    if(read_data_bytes == 1'b1) //receives address in Read Data Bytes Instruction
    begin
      read_data_bytes = 1'b0; operation = READ_DATA_OUT; i = 8;
    end
    if(read_id_data_bytes == 1'b1)
    begin
      read_id_data_bytes = 1'b0; operation = READ_ID_DATA_OUT; i = 8;
    end    
    //------------------------- WRITE MEM OR ID ARRAY 
/*    if((write_data_in == 1'b1) || (write_id_data_in == 1'b1))   //receives address in Write Data Bytes Instruction
    begin
      bit_counter_en = 1'b1; bit_counter_ld = 1'b1;
      
      if (write_id_data_in)
      begin
         write_id_data_in = 1'b0; 
         if(memory_address[10])
         begin
            operation = LOCKID;
            lock_byte = 1'b1;
         end
         else
         begin
            write_id_data_end = 1'b1;
            operation = WRITE_ID_DATA_IN;
            data_byte = 1'b1;
         end
      end
      else
      begin
         write_data_in = 1'b0; 
         operation = WRITE_DATA_IN;
         page_address = memory_address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`PAGE_ADDR_BITS];
         data_byte = 1'b1;
      end

      start_address = memory_address[`PAGE_OFFSET_BITS-1:0];
      page_offset_addr = memory_address[`PAGE_OFFSET_BITS-1:0];
    end */

    if(write_id_data_in == 1'b1)   //receives address in Write ID Data Bytes Instruction
    begin
      if(memory_address[10])
      begin
         if(!pageidlocked)
         begin 
           bit_counter_en = 1'b1; bit_counter_ld = 1'b1;      
           write_id_data_in = 1'b0; 
           operation = LOCKID;
           lock_byte = 1'b1;
         end
         else
            $display("%t: WARNING: The identification page is already locked by the Lock status bit, the LOCK ID instruction is not accepted!\n",$realtime);
      end
      else
      begin
         bit_counter_en = 1'b1; bit_counter_ld = 1'b1;      
         write_id_data_in = 1'b0; 
         write_id_data_end = 1'b1;
         operation = WRITE_ID_DATA_IN;
         data_byte = 1'b1;
         start_address = memory_address[`PAGE_OFFSET_BITS-1:0];
         page_offset_addr = memory_address[`PAGE_OFFSET_BITS-1:0];
      end
    end

    if(write_data_in == 1'b1)    //receives address in Write Data Bytes Instruction
    begin
      bit_counter_en = 1'b1; bit_counter_ld = 1'b1;      
      write_data_in = 1'b0; 
      operation = WRITE_DATA_IN;
      page_address = memory_address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`PAGE_ADDR_BITS];
      data_byte = 1'b1;
      start_address = memory_address[`PAGE_OFFSET_BITS-1:0];
      page_offset_addr = memory_address[`PAGE_OFFSET_BITS-1:0];
    end
  end

  //----------------------------data bytes input
  if((mode == active_power_mode)&&(data_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    byte_ok = 1'b0;
    data_latch[page_offset_addr] = shift_in_reg;
    if(page_offset_addr == {`PAGE_OFFSET_BITS {1'b1}}) page_offset_addr = {`PAGE_OFFSET_BITS {1'b0}};
    else page_offset_addr = page_offset_addr + {{`PAGE_OFFSET_BITS-1 {1'b0}},1'b1};
    end_address = page_offset_addr;
    bit_counter_en = 1'b1;
    bit_counter_ld = 1'b1;
    write_data_byte_ok = 1'b1;
  end
  //----------------------------Set LOCKID input
  if((mode == active_power_mode)&&(set_new_lockid_ok == 1'b1))
  begin
     nonxt_byte = 1'b1;
     set_new_lockid_ok = 1'b0;
     $display("%t: ERROR: Chip select \S must be driven high after the rising edge of Serial Clock after the first data Byte: Lock ID has not been Executed!",$realtime);
  end

  if((mode == active_power_mode)&&(lock_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    byte_ok = 1'b0;
    lock_latch = shift_in_reg;
    lock_byte = 1'b0;
    set_new_lockid_ok = 1'b1;
  end

  //----------------------------new SR value input
  if((mode == active_power_mode)&&(new_sr_byte == 1'b1)&&(byte_ok == 1'b1))
  begin
    byte_ok = 1'b0;
    sr_latch = shift_in_reg;
    new_sr_byte = 1'b0;
    write_new_sr_ok = 1'b1;
  end
  //----------------------------Read Data From Memory Array
  if(operation == READ_DATA_OUT)
  begin
    if(i==0)
    begin
      if(memory_address[`MEM_ADDR_BITS-1:0] == {`MEM_ADDR_BITS {1'b1}}) //`MEM_ADDR_BITS'h3ff)
        memory_address[`MEM_ADDR_BITS-1:0] = {`MEM_ADDR_BITS {1'b0}};
      else memory_address[`MEM_ADDR_BITS-1:0] = memory_address[`MEM_ADDR_BITS-1:0] + {{`MEM_ADDR_BITS-1 {1'b0}},1'b1};// `MEM_ADDR_BITS'h001;
      i = 8;
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tCLQV);                  //clock low to Output Valid
    data_out_buf = memory[memory_address[`MEM_ADDR_BITS-1:0]];
    dout = data_out_buf[i-1];
    i = i-1;
  end

  //----------------------------Read Data From ID Memory Array or Read lock status
  if(operation == READ_ID_DATA_OUT)
  begin
    if (memory_address[10])  //read lock ID
    begin
      if(i==0) i = 8;

      #(M95XXX_SIM.M95XXX_Macro_mux.tCLQV);                  //clock low to Output Valid
      data_out_buf = {7'b0000000,pageidlocked};
      dout = data_out_buf[i-1];
      i = i-1;
    end
    else
    begin
      if(i==0)
      begin  //??????????????? WRAP AROUND ?????????????????
        if((readidwrap)&&(memory_address[`PAGE_OFFSET_BITS-1:0] == {`PAGE_OFFSET_BITS {1'b0}})) $display("%t: ERROR:  The number of bytes read has exceeded ID page boundary [%d], unexpected data is read\n",$realtime,page_size);

        if(memory_address[`PAGE_OFFSET_BITS-1:0] == {`PAGE_OFFSET_BITS {1'b1}})
        begin
           memory_address[`PAGE_OFFSET_BITS-1:0] = {`PAGE_OFFSET_BITS {1'b0}}; 
           $display("%t: NOTE:  The number of bytes read has reached ID page boundary [%d]\n",$realtime,page_size-1);
           readidwrap = 1'b1;
        end
        else memory_address[`PAGE_OFFSET_BITS-1:0] = memory_address[`PAGE_OFFSET_BITS-1:0] + {{`PAGE_OFFSET_BITS-1 {1'b0}},1'b1};
        i = 8;
      end
      #(M95XXX_SIM.M95XXX_Macro_mux.tCLQV);                  //clock low to Output Valid
      data_out_buf = memory_id[memory_address[`PAGE_OFFSET_BITS-1:0]];
      dout = data_out_buf[i-1];
      i = i-1;
    end
  end
//---------------------------
  case(instruction)             //execute instruction
//---------------------------
  WRITE_ENABLE:
  begin
    instruction = 4'b0000;
    if(status_reg[0] == 1'b1)   //WIP is set, an internal write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this WRITE ENABLE INSTRUCTION is rejected!",$realtime);
    else begin
      write_en_id = 1'b1;
      operation = EN_WRITE;
    end
  end
//---------------------------
  WRITE_DISABLE:
  begin
    instruction = 4'b0000;
    if(status_reg[0] == 1'b1)   //WIP is set, an internal write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this WRITE DISABLE INSTRUCTION is rejected!",$realtime);
    else begin
      write_dis_id = 1'b1;
      operation = DIS_WRITE;
    end
  end
//---------------------------
  READ_STATUS_REGISTER:
  begin
    operation = READ_SR_OUT;
    if(i==0)  i = 8;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCLQV);                  //Clock low to Output Valid
    if (instruction_byte == 1'b0) 
       dout = status_reg[i-1];
    else
       dout = 1'bz;

    i = i-1;
  end
//---------------------------
  WRITE_STATUS_REGISTER:
  begin
    instruction = 4'b0000;
    if(status_reg[0] == 1'b1)   //WIP is set, an internal write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this WRITE SR INSTRUCTION is rejected!",$realtime);
    else begin
      if(status_reg[1] == 1'b1) //before "WRITE_SR_IN",WEL must be set
      begin
        sr_write       = 1'b1;
        new_sr_byte    = 1'b1;  //receives new value
        bit_counter_en = 1'b1;
        bit_counter_ld = 1'b1;
        operation = WRITE_SR_IN;
      end
      else $display("%t: ERROR: Write Disable! Write SR instruction can not be accepted!",$realtime);
    end
  end
//---------------------------
  READ_FROM_MEMORY_ARRAY:
  begin
    instruction = 4'b0000;      //clear "READ_DATA_BYTES" instruction
    if(status_reg[0] == 1'b1)   //WIP is set, an erase,program,write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this READ FROM MEMORY ARRAY INSTRUCTION is rejected!",$realtime);
    else begin
      read_data_bytes = 1'b1;

      if (`MEM_ADDR_BITS <= 9)
      begin
         address_l_byte = 1'b1; //receives address low byte
         bit_counter_en = 1'b1;
         bit_counter_ld = 1'b1;
      end
      else if (9 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 16)
      begin
         address_h_byte  = 1'b1;   //receives address high byte 1
         bit_counter_en  = 1'b1;
         bit_counter_ld  = 1'b1;
      end
      else if (16 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 24)
      begin
         address_h2_byte = 1'b1;   //receives address high byte 2
         bit_counter_en  = 1'b1;
         bit_counter_ld  = 1'b1;
      end
    end
  end
//---------------------------
  WRITE_TO_MEMORY_ARRAY:
  begin
    instruction = 4'b0000;
    if(status_reg[0] == 1'b1)   //WIP is set, an erase,program,write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this WRITE TO MEMORY ARRAY INSTRUCTION is rejected!",$realtime);
    else begin
      if(status_reg[1] == 1'b1) //before "WRITE DATA",WEL must be set
      begin
        write_data_in  = 1'b1;

        if (`MEM_ADDR_BITS <= 9)
        begin
           address_l_byte = 1'b1; //receives address low byte
           bit_counter_en = 1'b1;
           bit_counter_ld = 1'b1;
        end
        else if (9 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 16)
        begin
           address_h_byte = 1'b1;  //receives address high byte 1
           bit_counter_en = 1'b1;
           bit_counter_ld = 1'b1;
        end
        else if (16 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 24)
        begin
           address_h2_byte = 1'b1;   //receives address high byte 2
           bit_counter_en  = 1'b1;
           bit_counter_ld  = 1'b1;
        end
      end
      else $display("%t: ERROR: Write Disable! Write instruction can not be accepted!",$realtime);
    end
  end
//---------------------------
  READ_ID_PAGE:
  begin
    instruction = 4'b0000;
    read_id_data_bytes = 1'b1;
    if(status_reg[0] == 1'b1)   //WIP is set, an erase,program,write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this READ FROM IDENTIFICATION PAGE INSTRUCTION is rejected!",$realtime);
    else begin
      if (9 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 16)
      begin
         address_h_byte  = 1'b1;   //receives address high byte 1
         bit_counter_en  = 1'b1;
         bit_counter_ld  = 1'b1;
      end
      else if (16 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 24)
      begin
         address_h2_byte = 1'b1;   //receives address high byte 2
         bit_counter_en  = 1'b1;
         bit_counter_ld  = 1'b1;
      end
    end
  end
//---------------------------
  WRITE_ID_PAGE:
  begin
    instruction = 4'b0000;
    if(status_reg[0] == 1'b1)   //WIP is set, an erase,program,write cycle is in progress
      $display("%t: WARNING:  An internal write cycle is in progress, this WRITE TO MEMORY ARRAY INSTRUCTION is rejected!",$realtime);
    else begin
      if(status_reg[1] == 1'b1) //before "WRITE DATA",WEL must be set
      begin
        write_id_data_in  = 1'b1;

        if (9 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 16)
        begin
           address_h_byte = 1'b1;  //receives address high byte 1
           bit_counter_en = 1'b1;
           bit_counter_ld = 1'b1;
        end
        else if (16 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 24)
        begin
           address_h2_byte = 1'b1;   //receives address high byte 2
           bit_counter_en  = 1'b1;
           bit_counter_ld  = 1'b1;
        end
      end
      else $display("%t: ERROR: Write ID Disable! Write instruction can not be accepted!",$realtime);
    end
  end
//---------------------------

  endcase
end

//=========================================================
//AC timing Characteristics Check
//=========================================================
always@(posedge S)    //rising edge of /S
begin
  r_S = 1'b1; t_rS = $time;
  if(r_C == 1'b1)
  begin
    tCHSH = t_rS - t_rC;
    if(tCHSH < M95XXX_SIM.M95XXX_Macro_mux.tCHSH) $display("%t: ERROR: /S Active Hold Time(tCHSH) violated.\n",$realtime);
  end
end
//================================
always@(negedge S)    //falling edge of /S
begin
  f_S = 1'b1; t_fS = $time;
  if(r_S == 1'b1)
  begin               //check /S deselect time
    tSHSL = t_fS - t_rS;
    if(tSHSL < M95XXX_SIM.M95XXX_Macro_mux.tSHSL) $display("%t: ERROR: /S Deselect Time(tSHSL) violated.\n",$realtime);
  end
  if(r_C == 1'b1)
  begin               //check /S not active hold time (relative to clk_in)
    tCHSL = t_fS - t_rC;
    if(tCHSL < M95XXX_SIM.M95XXX_Macro_mux.tCHSL) $display("%t: ERROR: /S Not Active Hold Time(tCHSL) violated.\n",$realtime);
  end
end
//================================
always@(C)
begin
  if(C == 1'b1)       //rising edge of clock
  begin
    t_rC = $time;
    if(r_C == 1'b1)
    begin
      Tc = t_rC - t_rC1;
      if(Tc < M95XXX_SIM.M95XXX_Macro_mux.tC) $display("%t: ERROR: Clock Frequency(fC) violated, fC > %0d MHz. Tc=%d TC=%d\n",$realtime,M95XXX_SIM.M95XXX_Macro_mux.fC,Tc,M95XXX_SIM.M95XXX_Macro_mux.tC);
    end
    r_C = 1'b1;
    if(f_S == 1'b1)
    begin
      tSLCH = t_rC - t_fS;
      if(tSLCH < M95XXX_SIM.M95XXX_Macro_mux.tSLCH) $display("%t: ERROR: /S Active Setup Time(tSLCH) violated.\n",$realtime);
    end
    if(r_S == 1'b1)
    begin
      tSHCH = t_rC - t_rS;
      if(tSHCH < M95XXX_SIM.M95XXX_Macro_mux.tSHCH) $display("%t: ERROR: /S Not Active Setup Time(tSHCH) violated.\n",$realtime);
    end
    if(f_C == 1'b1)
    begin
      tCL = t_rC - t_fC;
      if(tCL < M95XXX_SIM.M95XXX_Macro_mux.tCL) $display("%t: ERROR: Clock Low Time(tCL) violated.\n",$realtime);
    end
    if(din_change == 1'b1)
    begin
      tDVCH = t_rC - t_d;
      if(tDVCH < M95XXX_SIM.M95XXX_Macro_mux.tDVCH) $display("%t: ERROR: Data In Setup Time(tDVCH) violated.\n",$realtime);
    end
    if(f_H == 1'b1)
    begin
      tHLCH = t_rC - t_fH;
      if(tHLCH < M95XXX_SIM.M95XXX_Macro_mux.tHLCH) $display("%t: ERROR: Clock Low Hold Time After HOLD Active(tHLCH) violated.\n",$realtime);
    end
    if(r_H == 1'b1)
    begin
      tHHCH = t_rC - t_rH;
      if(tHHCH < M95XXX_SIM.M95XXX_Macro_mux.tHHCH) $display("%t: ERROR: Clock Low Hold Time After HOLD Not Active(tHHCH) violated.\n",$realtime);
    end
    t_rC1 = t_rC;
  end
  //================================
  if(C == 1'b0)       //falling edge of clock
  begin
    f_C = 1'b1; t_fC = $time;
    if(r_C == 1'b1)
    begin
      tCH = t_fC - t_rC;
      if(tCH < M95XXX_SIM.M95XXX_Macro_mux.tCH) $display("%t: ERROR: Clock High Time(tCH) violated.\n",$realtime);
    end
  end
end
//================================
always@(posedge HOLD)
begin
  r_H = 1'b1;
  t_rH = $time;
  if(f_C == 1'b1)
  begin
    tCLHH = t_rH - t_fC;
    if(tCLHH < M95XXX_SIM.M95XXX_Macro_mux.tCLHH) $display("%t: ERROR: Clock High Set-Up Time Before HOLD Not Active(tCLHH) violated.\n",$realtime);
  end
end
//================================
always@(negedge HOLD)
begin
  f_H = 1'b1;
  t_fH = $time;
  if(f_C == 1'b1)
  begin
    tCLHL = t_fH - t_fC;
    if(tCLHL < M95XXX_SIM.M95XXX_Macro_mux.tCLHL) $display("%t: ERROR: Clock High Set-Up Time Before HOLD Active(tCLHL) violated.\n",$realtime);
  end
end
//================================
always@(D)            //Input data change on "D" line
begin
  din_change = 1'b1;
  t_d = $time;
  if(r_C == 1'b1)
  begin
    tCHDX = t_d - t_rC;
    if(tCHDX < M95XXX_SIM.M95XXX_Macro_mux.tCHDX) $display("%t: ERROR: Data In Hold Time(tCHDX) violated.\n",$realtime);
  end
end
//================================

endmodule
