/*=============================================================================

  M95XXX Serial SPI EEPROM Driver

=============================================================================*/

`include "M95XXX_Parameters.v"

//This defines the parameter file for M95080-W6, "W" or "G" F6SP36% process
//Any other M95xxx memory should define here the proper M95xxx parameter file

//`define     tH_CLK      `tC/2
//`define     tL_CLK      `tC/2

//=====================================
module M95XXX_DRV(
                    C,
                    D,
                    Q,
                    S,
                    W,
                    HOLD,
                    VCC,
                    VSS
                  );

//-------------------------------------
input Q;
output C,D,S,W,HOLD,VCC,VSS;

//-------------------------------------
integer i,j,n;
integer add_bytes,instructionA8;

reg C,D,S,W,HOLD,VCC,VSS;
reg[7:0] sr,read_dat;
reg[7:0] data;
reg[3*8-1:0] d_address;


//-------------------------------------
initial begin
        if (`MEM_ADDR_BITS <= 9)
           add_bytes = 1;
        else if (9 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 16)
           add_bytes = 2;
        else if (16 < `MEM_ADDR_BITS && `MEM_ADDR_BITS <= 24)
           add_bytes = 3;
        else
           add_bytes = 2;

        if (`MEM_ADDR_BITS == 9)
           instructionA8 = 1;
        else
           instructionA8 = 0;
       
        VSS = 1'b0;
        VCC = 1'b1;
        #100;
        S = 1'b1;
        #100;
        S = 1'b0;       ///HOLD and /W are not driven before this instruction. Model will warn to user.
        #100;
        
        VCC = 1'b0;
        #100;
        VCC = 1'b1;
        #100;
        S = 1'b1;
        W = 1'b1;       ///W is driven high
        HOLD = 1'b1;    ///HOLD is driven high
        #100;

        //---------------------------------------
        $display("======================================================================");
        $display("==  TESTING1: READ/WRITE STATUS REGISTER INSTRUCTION VERIFICATION.  ==");
        $display("======================================================================");
        W = 1;
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b1111_1111);
        READ_STATUS_REGISTER;   //should be "0000_0011"
        //bit0(WIP) is "1" during the WRSR cycle. bit1(WEL) is "1". bit 4,5,6 are always "0"
//        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_STATUS_REGISTER;   //should be "1000_1100"
        //bit0(WIP) is "0" and bit1(WEL) is reset when WRSR cycle is completed. 

        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0000);
        READ_STATUS_REGISTER;   //should be "1000_1111"
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_STATUS_REGISTER;   //should be "0000_0000"

        W = 0;
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b1111_1111);
        READ_STATUS_REGISTER;   //should be "0000_0011"
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_STATUS_REGISTER;   //should be "1000_1100"

        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0000);
        //W = 0, SRWD = 1, enter "HPM" this "WRSR" instruction is not executed and self-time WRSR cycle is not initiated.
        READ_STATUS_REGISTER;   //should be "1000_1110"
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_STATUS_REGISTER;   //should be "1000_1110"

        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0011);
        READ_STATUS_REGISTER;   //should be "1000_1110"
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_STATUS_REGISTER;   //should be "1000_1110"

        W = 1;
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0011);
        READ_STATUS_REGISTER;   //should be "1000_1111"
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_STATUS_REGISTER;   //should be "0000_0000"
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);


        //---------------------------------------
        $display("=======================================================");
        $display("==  TESTING2: MEMORY ARRAY READ/WRITE VERIFICATION.  ==");
        $display("=======================================================");
        W = 1;

//        READ_DATA_BYTES(2,`MEM_ADDR_BITS'h3ff);
        READ_DATA_BYTES(2,{`MEM_ADDR_BITS {1'b1}});

        WRITE_ENABLE;
//        WRITE_DATA_IN(64,`DATA_BITS'h55,`MEM_ADDR_BITS'h3ff);
        WRITE_DATA_IN(`PAGE_SIZE,`DATA_BITS'h55,{`MEM_ADDR_BITS {1'b1}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
//        READ_DATA_BYTES(34,`MEM_ADDR_BITS'h3df);
        READ_DATA_BYTES(`PAGE_SIZE+2,{`MEM_ADDR_BITS {1'b1}}-`PAGE_SIZE);
        WRITE_DATA_IN(`PAGE_SIZE,`DATA_BITS'h55,{`MEM_ADDR_BITS {1'b1}});   //This Write Enable Instruction will not be executed.

        WRITE_ENABLE;
        WRITE_DATA_IN(2,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(`PAGE_SIZE,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
//WRITE WITH POLLING (RDSR)	
		$display("=WRITE WITH POLLING (loop on read status register)");
        WRITE_ENABLE;
        WRITE_DATA_IN(2,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGE_SIZE-1);
        POLLING_WITH_SEL_LOOP_ON_RDSR_DESEL; 		// replacing TW by polling routine #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(`PAGE_SIZE,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
		
//WRITE WITH POLLING (RDSR)	
		$display("=WRITE WITH POLLING (loop on select read status register deselect)");
        WRITE_ENABLE;
        WRITE_DATA_IN(2,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGE_SIZE-1);
        POLLING_WITH_LOOP_ON_SEL_RDSR_DESEL; 		// replacing TW by polling routine #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(`PAGE_SIZE,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
		
        WRITE_ENABLE;

        WRITE_DATA_IN(2,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGE_SIZE-1);
        READ_STATUS_REGISTER;   //should be "0000_0000"

#4.991e6;
        READ_STATUS_REGISTER;   //should be "0000_0000"
#500
        READ_STATUS_REGISTER;   //should be "0000_0000"
#10
        READ_STATUS_REGISTER;   //should be "0000_0000"
        READ_STATUS_REGISTER;   //should be "0000_0000"

        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        //---------------------------------------
        $display("===================================================================================================");
        $display("==  TESTING3: ALL INSTRUCTIONS (except RDSR) ARE NOT EXECUTED WHILE WRITE CYCLE IS IN PROGRESS.  ==");
        $display("===================================================================================================");
        W = 1;
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h11,{`MEM_ADDR_BITS {1'b0}});
        WRITE_ENABLE;
        WRITE_DISABLE;
        WRITE_STATUS_REGISTER(8'b1000_0111);
        READ_DATA_BYTES(1,{`MEM_ADDR_BITS {1'b0}});
        WRITE_DATA_IN(1,`DATA_BITS'h22,{`MEM_ADDR_BITS {1'b0}});
        READ_STATUS_REGISTER;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
        //---------------------------------------


        $display("===================================================================================================");
        $display("==  TESTING 3A: RANDOM TESTS                                                                     ==");
        $display("===================================================================================================");
        W = 1;


       //--------------------------------------------------------
       //Enable and disable test with write data when disabled(rejected)

        WRITE_ENABLE;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_DISABLE;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_DATA_IN(1,`DATA_BITS'h11,{`MEM_ADDR_BITS {1'b0}}); //rejected

        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h11,{`MEM_ADDR_BITS {1'b0}});

        WRITE_STATUS_REGISTER(8'b1000_0111); //rejected
        READ_STATUS_REGISTER;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(4,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
       //--------------------------------------------------------

       //--------------------------------------------------------
       //Wrap around Test for write an read
        WRITE_ENABLE;
        WRITE_DATA_IN(3,`DATA_BITS'h55,{`MEM_ADDR_BITS {1'b1}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        READ_DATA_BYTES(4,{`MEM_ADDR_BITS {1'b1}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        READ_DATA_BYTES(4,{`MEM_ADDR_BITS {1'b1}}-`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
        //--------------------------------------------------------

       //--------------------------------------------------------
       //Read at the ID boundry and write beyond the boundry

        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b0,{`PAGE_OFFSET_BITS {1'b1}}); //read beyond the ID boundry
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'h23,{`PAGE_OFFSET_BITS {1'b1}}); //2 written byte rejected beyond the boundry
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_ID_PAGE_OR_LOCK_STATUS(3,1'b0,{`PAGE_OFFSET_BITS {1'b1}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'h23,{`PAGE_OFFSET_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_ID_PAGE_OR_LOCK_STATUS(3,1'b0,{`PAGE_OFFSET_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
       //--------------------------------------------------------

       //--------------------------------------------------------
       //write and read the entire ID page

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK({`PAGE_OFFSET_BITS {1'b1}}+1,1'b0,`DATA_BITS'hAA,{`PAGE_OFFSET_BITS {1'b0}}); //write the entire ID PAGE to 0xAA  //{`PAGE_OFFSET_BITS {1'b1}}+1
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        READ_ID_PAGE_OR_LOCK_STATUS({`PAGE_OFFSET_BITS {1'b1}}+1,1'b0,{`PAGE_OFFSET_BITS {1'b0}});  //read the whole ID PAGE 
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
       //--------------------------------------------------------

       //--------------------------------------------------------
       //write and read LOCK ID STATUS

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(1,1'b1,`DATA_BITS'h02,`MEM_ADDR_BITS'h400); //write lock ID, accepted cause only 1 byte sent
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,`MEM_ADDR_BITS'h400);  //read lock status twice
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b1,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write lock id when it is already lock, not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write ID memory when it is lock, not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,{`PAGE_OFFSET_BITS {1'b1}});
        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,`MEM_ADDR_BITS'h400);  //read lock status twice
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
       //--------------------------------------------------------


       //--------------------------------------------------------
       //write when memory disabled and a write polling the read status 

        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h22,{`MEM_ADDR_BITS {1'b0}});
        READ_STATUS_REGISTER;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW/2);
        READ_STATUS_REGISTER;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW/2);
        READ_STATUS_REGISTER;

        READ_DATA_BYTES(1,{`MEM_ADDR_BITS {1'b0}});
        WRITE_DATA_IN(1,`DATA_BITS'h22,{`MEM_ADDR_BITS {1'b0}}); //rejected, write disabled
        READ_STATUS_REGISTER;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
       //--------------------------------------------------------



       //--------------------------------------------------------
       //write when memory disabled and a write polling the read status,alternating clk fininsh on zero or one

        WRITE_ENABLE;
        WRITE_DATA_INh(1,`DATA_BITS'h22,{`MEM_ADDR_BITS {1'b0}});
        READ_STATUS_REGISTER;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW/2);
        READ_STATUS_REGISTERh;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW/2);
        READ_STATUS_REGISTER;

        READ_DATA_BYTESh(1,{`MEM_ADDR_BITS {1'b0}});
        WRITE_DATA_IN(1,`DATA_BITS'h22,{`MEM_ADDR_BITS {1'b0}}); //rejected, write disabled
        READ_STATUS_REGISTERh;
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLE;
        WRITE_DATA_INh(`PAGE_SIZE,`DATA_BITS'h55,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTESh(`PAGE_SIZE,{`MEM_ADDR_BITS {1'b0}});
        WRITE_ENABLE;
        WRITE_DATA_INh(`PAGE_SIZE/4,`DATA_BITS'h33,`PAGE_SIZE/2);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTESh(`PAGE_SIZE,{`MEM_ADDR_BITS {1'b0}});

        READ_DATA_BYTES(`PAGE_SIZE,{{`MEM_ADDR_BITS-2 {1'b1}},2'b00});


        WRITE_ENABLEh;
        WRITE_DATA_INh(1,`DATA_BITS'hAA,{`MEM_ADDR_BITS {1'b1}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,{`MEM_ADDR_BITS {1'b1}});
        READ_DATA_BYTESh(1,{`MEM_ADDR_BITS {1'b0}});


       //--------------------------------------------------------
       //write and read LOCK ID STATUS, alternating clk fininsh on zero or one

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCKh(1,1'b1,`DATA_BITS'h02,`MEM_ADDR_BITS'h400); //write lock ID, accepted cause only 1 byte sent
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,`MEM_ADDR_BITS'h400);  //read lock status twice
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLEh;
        WRITE_ID_PAGE_OR_LOCK(2,1'b1,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write lock id when it is already lock, not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLEh;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write ID memory when it is lock, not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,{`PAGE_OFFSET_BITS {1'b1}});
        READ_ID_PAGE_OR_LOCK_STATUSh(2,1'b1,`MEM_ADDR_BITS'h400);  //read lock status twice
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
       //--------------------------------------------------------


       //--------------------------------------------------------

        //---------------------------------------
        $display("=========================================================================");
        $display("==  TESTING4: VERIFICATION OF ADDRESS INSIDE A WRITE PROTECTED ARRAY.  ==");
        $display("=========================================================================");
        $display("------------------------------------------");
        $display("-- Note: Memory Array is not Protected. --");
        $display("------------------------------------------");
        W = 1;
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0000);    //No block of memory is protected
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'h99,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        $display("-------------------------------------------------------");
        $display("-- Note: Upper quarter of Memory Array is Protected. --");
        $display("-------------------------------------------------------");
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0100);    //Upper quarter of memory is protected
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'haa,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);


        $display("----------------------------------------------------");
        $display("-- Note: Upper half of Memory Array is Protected. --");
        $display("----------------------------------------------------");
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_1000);    //Upper half of memory is protected
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hbb,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);


        $display("--------------------------------------------");
        $display("-- Note: Whole Memory Array is Protected. --");
        $display("--------------------------------------------");
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_1100);    //whole memory is protected
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/2*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(2,`MEM_ADDR_BITS'd`PAGES/4*3*`PAGE_SIZE-1);
        WRITE_ENABLE;
        WRITE_DATA_IN(1,`DATA_BITS'hcc,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_DATA_BYTES(1,`MEM_ADDR_BITS'd`PAGES*`PAGE_SIZE-1);
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

       
        //---------------------------------------
        if (`IDPAGE)
        begin
        //---------------------------------------
        $display("\n=====================================================");
        $display("==  TESTING5: MEMORY ID ARRAY READ/WRITE VERIFICATION.  ==");
        $display("========================================+++==========\n");
        #20000;
        W = 1;

        $display("-------------------------------------------------------------");
        $display("-- Note: Whole Memory Array is Protected --");
        $display("-------------------------------------------------------------");
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_1100);    //whole memory is protected
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(1,1'b1,`DATA_BITS'ha5,`MEM_ADDR_BITS'h7ff); //write lock id when it bp1,bp0 = (1,1), not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'ha5,`MEM_ADDR_BITS'h3ff); //write ID memory when it bp1,bp0 = (1,1), not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0000);    //whole memory is protected
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        $display("\n-------------------------------------------------");
        $display("-- Note: READ/WRITE MEMORY ID. --");
        $display("-------------------------------------------------");

        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b0,{`PAGE_OFFSET_BITS {1'b1}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'h23,{`PAGE_OFFSET_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b0,{`PAGE_OFFSET_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(3,1'b0,`DATA_BITS'hAA,{`PAGE_OFFSET_BITS {1'b1}}); //write the entire ID PAGE to 0xAA
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b0,{`PAGE_OFFSET_BITS {1'b1}});  //read the whole ID PAGE
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);


        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(`PAGE_SIZE,1'b0,`DATA_BITS'hAA,{`PAGE_OFFSET_BITS {1'b0}}); //write the entire ID PAGE to 0xAA
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);


        WRITE_ID_PAGE_OR_LOCK(`PAGE_SIZE,1'b0,`DATA_BITS'h55,{`PAGE_OFFSET_BITS {1'b1}});   //This Write Enable Instruction will not be executed.

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write last byte in page and first byte wrap
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(5,1'b0,`DATA_BITS'h13,`PAGE_OFFSET_BITS'h0A); //write starting at loc 0x13 location for 5 bytes
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        READ_ID_PAGE_OR_LOCK_STATUS(`PAGE_SIZE,1'b0,{`PAGE_OFFSET_BITS {1'b0}});  //read the whole ID PAGE
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        $display("-------------------------------------------------------------------------------");
        $display("-- Note: WRITE LOCK ID AND READ/WRITE MEMORY ID --");
        $display("-------------------------------------------------------------------------------");
        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,`MEM_ADDR_BITS'h400);  //read lock status twice
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b1,`DATA_BITS'h02,{`MEM_ADDR_BITS {1'b1}}); //write LOCK ID, not accepted cause more than 1 byte
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(1,1'b1,`DATA_BITS'h02,`MEM_ADDR_BITS'h400); //write lock ID, accepted cause only 1 byte sent
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        READ_ID_PAGE_OR_LOCK_STATUS(2,1'b1,`MEM_ADDR_BITS'h400);  //read lock status twice
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b1,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write lock id when it is already lock, not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        WRITE_ID_PAGE_OR_LOCK(2,1'b0,`DATA_BITS'ha5,{`MEM_ADDR_BITS {1'b1}}); //write ID memory when it is lock, not accepted 
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);

        end


        //---------------------------------------
        $display("==============================================");
        if (`IDPAGE)
          $display("==  TESTING6: HOLD CONDITION VERIFICATION.  ==");
        else
          $display("==  TESTING5: HOLD CONDITION VERIFICATION.  ==");
        $display("==============================================");
        W = 1;
        WRITE_ENABLE;
        WRITE_STATUS_REGISTER(8'b0000_0000);
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        WRITE_ENABLE;
        //////////////////////////Write Data Instruction
        S = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
        S = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time - data in setup time
        //////////////////////////
        //************************
        HOLD = 1'b0;            //HOLD driven low when CLK=1, Pause right now
        D = 1'b0;
        //#(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);            //data in setup time
        #(M95XXX_SIM.M95XXX_Macro_mux.tHLCH);              //clock low hold time after "HOLD" active
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK-50);
        HOLD = 1'b0;
        #25;
        HOLD = 1'b1;            //HOLD driven high when C=1, Resume next CLK falling edge
        #25;
        //************************
        HOLD = 1'b0;            //HOLD driven high same as CLK falling edge, Pause
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        for(i=0;i<add_bytes*8-1;i=i+1)
        begin
            #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
            C = 1'b1;
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        end
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        C = 1'b1;
        //#(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK-40);
        HOLD = 1'b1;            //HOLD driven high when C=1, no effect
        #20;
        HOLD = 1'b0;            //HOLD driven low when C=1 no effect
        #20
        HOLD = 1'b1;            //HOLD driven high when C=1, and sametime C is driven low, Resume
        //------------------------
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCLHL);
        HOLD = 1'b0;            //HOLD driven low when C=0, hold start
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        for(i=0;i<4;i=i+1)
        begin
            #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
            C = 1'b1;
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        end
        HOLD = 1'b1;            //HOLD driven high when C=0, hold end
        //#(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        #(M95XXX_SIM.M95XXX_Macro_mux.tHHCH);
        //------------------------
        C = 1'b1;               //D0 of instruction code, latched in
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        HOLD = 1'b0;            //HOLD driven low when C=1, next C falling edge start
        for(i=0;i<4;i=i+1)
        begin
            #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
            C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK);
            C = 1'b1;
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        end
        HOLD = 1'b1;            //HOLD driven high when C=1, next falling edge stop
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //------------------------
        //*********************************************************************
        //  ---Write Memory Instruction code with a changing /HOLD signal ---
        //*********************************************************************
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        //D = 1'b0;
        //#(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);            //data setup time
        //C = 1'b1;
        //#(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        //C = 1'b0;
        //#(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);              //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        //----------------------//indicate destination address
        d_address = {`MEM_ADDR_BITS {1'b0}};
        for(i=0;i<=add_bytes*8-1;i=i+1)               
        begin                              
            D = d_address[add_bytes*8-1-i];             
            #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
            C = 1'b1;                      
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        end
        //----------------------//write data
        n = 32;                 //the number of data bytes
        data = 8'h29;           //indicate data value
        for(i=0;i<=n-1;i=i+1)
        begin
            for(j=0;j<=7;j=j+1)
            begin
                D = data[7-j];
                #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);      //data setup time
                C = 1'b1;
                #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
                C = 1'b0;
                #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
            end
        end
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        //----------------------
        #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
        S = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
        #(M95XXX_SIM.M95XXX_Macro_mux.tW);
        //----------------------//Write Instruction Over
        READ_DATA_BYTES_HD(16,1'b0,{`MEM_ADDR_BITS {1'b0}});
        #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);

        $display("-------------------------------------------------------------------------------");
        $display("-- Note: READ MEMORY ID WITH HOLDS --");
        $display("-------------------------------------------------------------------------------");

        if (`IDPAGE) begin
          READ_DATA_BYTES_HD(16,1'b1,{`MEM_ADDR_BITS {1'b0}});
          #(M95XXX_SIM.M95XXX_Macro_mux.tSHQZ);
        end
       
        $display("======================================================");
        if (`IDPAGE)
          $display("==  TESTING7: THE VIOLATED AC TIMING VERIFICATION.  ==");
        else
          $display("==  TESTING6: THE VIOLATED AC TIMING VERIFICATION.  ==");

        $display("======================================================");
        //Following code executes unmeaning operation. It is only used for checking the AC Timing out of spec.
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL - 1);      //violated the /S not active hold time //violated the clock high time
        S = 1'b0;
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCL - 1);        //violated the /S active setup time //violated the clock low time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCH);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCL);
        D = ~D;             //change the value on "D" input pin
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH - 1);      //violated the Data In Setup Time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCHDX - 1);      //violated the Data In Hold Time
        D = ~D;             //change the value on "D" input pin
        #(M95XXX_SIM.M95XXX_Macro_mux.tCH);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCL);
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH - 1);      //violated the /S Active Hold Time //violated the clock high time
        S = 1'b1;
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCL - 1);        //violated the /S Active Setup Time //violated the clock low time //violated /S Deselest Time
        C = 1'b1;
        #1;                 //violated the /S not active hold time
        S = 1'b0;
        
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCL);
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCH);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCLHL);          //Clock Low Set-Up Time before /HOLD Active = 0s
        HOLD = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tHLCH - 1);      //violated the CLock Low Hold Time after /HOLD Active //violated the clock low time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCH);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tCLHH);          //Clock Low Set-Up Time before /HOLD Not Active = 0s
        HOLD = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tHHCH - 1);      //violated the CLock Low Hold Time after /HOLD Not Active //violated the clock low time
        C = 1'b1;
        #100;
        S = 1'b1;
        #200;

        if (!`VALID_PRT) 
        begin
           $display("\n######################################################################");
           $display("      ERROR: Part Choosen is NOT a valid Part ");
           $display("######################################################################\n");
        end     

           $display("\n######################################################################");
           $display("      TESTS DONE ");
           $display("######################################################################\n");



        $stop;            //testing completed
end
//===============================================
//Stimuli task definition
//===============================================
`define logicbit 1'b0

task WRITE_ENABLEi;
input initclk;
begin
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    for(i=0;i<=7;i=i+1)
    begin
        if((i==5)||(i==6))  D = 1'b1;
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time, and /S active setup time with #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH)
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);         //Clock High Time
        if (i==7) C = initclk; else C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task WRITE_ENABLE;
   WRITE_ENABLEi(`logicbit);
endtask

task WRITE_ENABLEh;
   WRITE_ENABLEi(1'b1);
endtask

//===============================================
task WRITE_DISABLEi;
input initclk;
begin
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if(i==5) D = 1'b1;
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (i==7) C = initclk; else C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task WRITE_DISABLE;
   WRITE_DISABLEi(`logicbit);
endtask

task WRITE_DISABLEh;
   WRITE_DISABLEi(1'b1);
endtask

//===============================================
task READ_STATUS_REGISTERi;
input initclk;
begin
    //----------------------instruction
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if((i==5)||(i==7)) D = 1'b1;
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    //----------------------read status register
    for(i=0;i<=7;i=i+1)
    begin
        C = 1'b1;
        sr = {sr[6:0],Q};
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (i==7) C = initclk; else C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK);
    end
    $display("%t: STATUS_REGISTER = [%b]",$realtime,sr);
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task READ_STATUS_REGISTER;
   READ_STATUS_REGISTERi(`logicbit);
endtask

task READ_STATUS_REGISTERh;
   READ_STATUS_REGISTERi(1'b1);
endtask
//===============================================
task POLLING_WITH_SEL_LOOP_ON_RDSR_DESEL;
begin
    //----------------------instruction
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if((i==5)||(i==7)) D = 1'b1;
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    //----------------------read status register
	sr = 03;
    while (sr != 0)
	begin
		for(i=0;i<=7;i=i+1)
		begin
			C = 1'b1;
			sr = {sr[6:0],Q};
			#(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
			C = 1'b0;
			#(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK);
		end
		$display("%t: STATUS_REGISTER = [%b]",$realtime,sr);
	end
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

//===============================================
task POLLING_WITH_LOOP_ON_SEL_RDSR_DESEL;
begin
    //----------------------instruction
  if (C==1) C=1'b0;

	sr = 03;
    while (sr != 0)
	begin	
		S = 1'b1;
		#(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
		S = 1'b0;
		#(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
		for(i=0;i<=7;i=i+1)
		begin
			if((i==5)||(i==7)) D = 1'b1;
			else D = 1'b0;
			#(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
			C = 1'b1;
			#(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
			C = 1'b0;
			#(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
		end
		#(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
		//----------------------read status register
		for(i=0;i<=7;i=i+1)
		begin
			C = 1'b1;
			sr = {sr[6:0],Q};
			#(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
			C = 1'b0;
			#(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK);
		end
		$display("%t: STATUS_REGISTER = [%b]",$realtime,sr);
		#(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
		S = 1'b1;
		#(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
	end
end
endtask

//===============================================
task WRITE_STATUS_REGISTERi;
input[7:0] sr_data;
input initclk;
begin
    //----------------------instruction
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    for(i=0;i<=7;i=i+1)
    begin
        if(i==7)    D = 1'b1;
        else        D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------write status register
    for(i=0;i<=7;i=i+1)
    begin
        D = sr_data[7-i];
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (i==7) C = initclk; else C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task WRITE_STATUS_REGISTER;
input[7:0] sr_data;
begin
   WRITE_STATUS_REGISTERi(sr_data,`logicbit);
end
endtask

task WRITE_STATUS_REGISTERh;
input[7:0] sr_data;
begin
   WRITE_STATUS_REGISTERi(sr_data,1'b1);
end
endtask

//===============================================
task READ_DATA_BYTESi;
input n;
input[23:0] address;
input initclk;
integer j,n;
begin
    if (C==1) C=1'b0;
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if((i==6)||(i==7)) D = 1'b1;
        else if ((instructionA8==1)&&(i==4)) D = address[`MEM_ADDR_BITS-1];          
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        if (C==1) C = 1'b0; else C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (C==0) C = 1'b1; else C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------address
    for(i=0;i<=add_bytes*8-1;i=i+1)
    begin
        D = address[add_bytes*8-1-i];
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        if (C==1) C = 1'b0; else C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (C==0) C = 1'b1; else C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    //----------------------read data bytes
    for(i=1;i<=n;i=i+1)
    begin
//        address = U_M95XXX.memory_address[`MEM_ADDR_BITS-1:0];
        for(j=0;j<=7;j=j+1)
        begin
            if (C==1) C = 1'b0; else C = 1'b1;
//            read_dat = {read_dat[6:0],Q};
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            read_dat = {read_dat[6:0],Q};
            address = U_M95XXX.memory_address[`MEM_ADDR_BITS-1:0];

            if (i==n&&j==7) C = initclk; else C = 1'b0;

            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK);
        end
        $display("%t: READ RESULT: ADDRESS = [%h], DATA = [%h]\n",$realtime,address,read_dat);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task READ_DATA_BYTES;
input n;
input[23:0] address;
integer n;
begin
   READ_DATA_BYTESi(n,address,`logicbit);
end
endtask

task READ_DATA_BYTESh;
input n;
input[23:0] address;
integer n;
begin
   READ_DATA_BYTESi(n,address,1'b1);
end
endtask

//===============================================
task WRITE_DATA_INi;
input n;                    //the number of data byte that be written in
input[7:0] data;            //the data written in memory
input[23:0] address;        //the accessed location's address
input initclk;
integer j,n;
begin
    if (C==1) C=1'b0;
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if(i==6) D = 1'b1;
        else if ((instructionA8==1)&&(i==4)) D = address[`MEM_ADDR_BITS-1];          
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        if (C==1)
           C = 1'b0;
        else
           C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (C==0)
           C = 1'b1;
        else
           C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------address
    for(i=0;i<=add_bytes*8-1;i=i+1)
    begin
        D = address[add_bytes*8-1-i];
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        if (C==1)
           C = 1'b0;
        else
           C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        if (C==0)
           C = 1'b1;
        else
           C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------write data
    for(i=0;i<=n-1;i=i+1)
    begin
        for(j=0;j<=7;j=j+1)
        begin
            D = data[7-j];
            #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);      //data setup time
            if (C==1) C = 1'b0; else C = 1'b1;
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            if (i==n-1&&j==7) C = initclk; else C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        end
    end
    //----------------------
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task WRITE_DATA_IN;
input n;                    //the number of data byte that be written in
input[7:0] data;            //the data written in memory
input[23:0] address;        //the accessed location's address
integer n;
begin
   WRITE_DATA_INi(n,data,address,`logicbit);
end
endtask

task WRITE_DATA_INh;
input n;                    //the number of data byte that be written in
input[7:0] data;            //the data written in memory
input[23:0] address;        //the accessed location's address
integer n;
begin
   WRITE_DATA_INi(n,data,address,1'b1);
end
endtask
//===============================================
task WRITE_ID_PAGE_OR_LOCKi;
input n;                    //the number of data byte that be written in
input idn_lock;
input[7:0] data;            //the data written in memory
input[23:0] address;        //the accessed location's address
input initclk;
integer j,n;
begin
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if((i==0||i==6)) D = 1'b1;
//        else if ((instructionA8==1)&&(i==4)) D = address[`MEM_ADDR_BITS-1];          
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------address
    if((address[10])&&(!idn_lock))
    begin
       $display("%t: ERROR: A10 set for lock on a Write ID Operation!",$realtime);
       $display("%t: WARNING: Setting A10 to Zero for Write ID Operation!\n",$realtime);
       address[10] = 1'b0;
    end
    else if((!address[10])&&(idn_lock))
    begin
       $display("%t: ERROR: A10 set for a Write ID on a Lock ID Operation!",$realtime);
       $display("%t: WARNING: Setting A10 to one for Lock ID Operation!\n",$realtime);
      address[10] = 1'b1;

    end

    for(i=0;i<=add_bytes*8-1;i=i+1)
    begin
        D = address[add_bytes*8-1-i];
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------write data

    for(i=0;i<=n-1;i=i+1)
    begin
        for(j=0;j<=7;j=j+1)
        begin
            D = data[7-j];
            #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);      //data setup time
            C = 1'b1;
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            if (i==n-1&&j==7) C = initclk; else C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
        end
    end
    //----------------------
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task WRITE_ID_PAGE_OR_LOCK;
input n;                    //the number of data byte that be written in
input idn_lock;
input[7:0] data;            //the data written in memory
input[23:0] address;        //the accessed location's address
integer n;
begin
   WRITE_ID_PAGE_OR_LOCKi(n,idn_lock,data,address,`logicbit);
end
endtask

task WRITE_ID_PAGE_OR_LOCKh;
input n;                    //the number of data byte that be written in
input idn_lock;
input[7:0] data;            //the data written in memory
input[23:0] address;        //the accessed location's address
integer n;
begin
   WRITE_ID_PAGE_OR_LOCKi(n,idn_lock,data,address,1'b1);
end
endtask
//===============================================
task READ_ID_PAGE_OR_LOCK_STATUSi;
input n;
input idn_status;
input[23:0] address;
input initclk;
integer j,n;
begin
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if((i==0)||(i==6)||(i==7)) D = 1'b1;
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end

    //----------------------address
    if((address[10])&&(!idn_status))
    begin
       $display("%t: ERROR: A10 set for Read Lock Status on a Read ID Operation!",$realtime);
       $display("%t: WARNING: Setting A10 to Zero for Read ID Operation!\n",$realtime);
       address[10] = 1'b0;
    end
    else if((!address[10])&&(idn_status))
    begin
       $display("%t: ERROR: A10 set for Read ID Operation on a Read Lock Status Operation!",$realtime);
       $display("%t: WARNING: Setting A10 to one for Read Lock Status Operation!\n",$realtime);
       address[10] = 1'b1;
    end

 //   address[`MEM_ADDR_BITS-1:`MEM_ADDR_BITS-`PAGE_ADDR_BITS] = {`PAGE_ADDR_BITS{1'b0}}; 

    for(i=0;i<=add_bytes*8-1;i=i+1)
    begin
        D = address[add_bytes*8-1-i];
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    //----------------------read data bytes
    for(i=1;i<=n;i=i+1)
    begin
        address = U_M95XXX.memory_address[`MEM_ADDR_BITS-`PAGE_ADDR_BITS-1:0];
        for(j=0;j<=7;j=j+1)
        begin
            C = 1'b1;
            read_dat = {read_dat[6:0],Q};
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            if (i==n&&j==7) C =initclk; else C = 1'b0;
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK);
        end
        $display("%t: READ RESULT: ADDRESS = [%h], DATA = [%h]\n",$realtime,address,read_dat);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask

task READ_ID_PAGE_OR_LOCK_STATUS;
input n;
input idn_status;
input[23:0] address;
integer n;
begin
   READ_ID_PAGE_OR_LOCK_STATUSi(n,idn_status,address,`logicbit);
end
endtask

task READ_ID_PAGE_OR_LOCK_STATUSh;
input n;
input idn_status;
input[23:0] address;
integer n;
begin
   READ_ID_PAGE_OR_LOCK_STATUSi(n,idn_status,address,1'b1);
end
endtask
//===============================================
task READ_DATA_BYTES_HD;
input n;
input id;
input[23:0] address;
integer j,n,k;
reg id;
begin
    if (C==1) C=1'b0;

    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSL);              ///S not active hold time
    S = 1'b0;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSLCH-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);       ///S active setup time
    for(i=0;i<=7;i=i+1)
    begin
        if((id==1)&&(i==0)) D = 1'b1;
        else if((i==6)||(i==7)) D = 1'b1;
        else if ((instructionA8==1)&&(i==4)) D = address[`MEM_ADDR_BITS-1];          
        else D = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    //----------------------address
    for(i=0;i<=add_bytes*8-1;i=i+1)
    begin
        D = address[add_bytes*8-1-i];
        #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);          //data setup time
        C = 1'b1;
        #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
        C = 1'b0;
        #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tDVCH);
    //----------------------read data bytes
    for(i=1;i<=n;i=i+1)
    begin
        address = U_M95XXX.memory_address[`MEM_ADDR_BITS-1:0];
        for(j=0;j<=7;j=j+1)
        begin
            C = 1'b1;
            read_dat = {read_dat[6:0],Q};
            #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
            C = 1'b0;
            //#(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-40);
            #(M95XXX_SIM.M95XXX_Macro_mux.tCLHL);      //clk low setup time before "HOLD" active
            //---------------------------------------------
            HOLD = 1'b0;    //HOLD Condition start
            for(k=0;k<1;k=k+1)
            begin
                //#60;
                #(M95XXX_SIM.M95XXX_Macro_mux.tHLCH);  //clk low hold time after "HOLD" active
                #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tCLHL-M95XXX_SIM.M95XXX_Macro_mux.tHLCH);
                C = 1'b1;
                #(M95XXX_SIM.M95XXX_Macro_mux.tH_CLK);
                C = 1'b0;
                //#(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-40);
                #(M95XXX_SIM.M95XXX_Macro_mux.tCLHL);  //clk low setup time before "HOLD" active
            end
            HOLD = 1'b1;    //HOLD Condition end
            //#60;
            #(M95XXX_SIM.M95XXX_Macro_mux.tHLCH);      //clk low hold time after "HOLD" active
            #(M95XXX_SIM.M95XXX_Macro_mux.tL_CLK-M95XXX_SIM.M95XXX_Macro_mux.tCLHL-M95XXX_SIM.M95XXX_Macro_mux.tHLCH);
            //---------------------------------------------        
        end
        $display("%t: READ RESULT: ADDRESS = [%h], DATA = [%h]\n",$realtime,address,read_dat);
    end
    #(M95XXX_SIM.M95XXX_Macro_mux.tCHSH);              ///S active hold time
    S = 1'b1;
    #(M95XXX_SIM.M95XXX_Macro_mux.tSHSL);              ///S Deselect time
end
endtask
//===============================================

endmodule
