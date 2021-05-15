`include "M95XXX_Parameters.v"

module M95XXX_Macro_mux;
integer fC        =          5    ;
integer tC        =          200  ;
integer tSLCH     =          60   ;
integer tSHCH     =          60   ;
integer tSHSL     =          90   ;
integer tCHSH     =          60   ;
integer tCHSL     =          60   ;
integer tCH       =          80   ;
integer tCL       =          80   ;
integer tDVCH     =          20   ;
integer tCHDX     =          20   ;
integer tHHCH     =          60   ;
integer tHLCH     =          60   ;
integer tCLHL     =          0    ;
integer tCLHH     =          0    ;
integer tSHQZ     =          80   ;
integer tCLQV     =          80   ;
integer tCLQX     =          0    ;
integer tHHQV     =          80   ;
integer tHLQZ     =          80   ;
integer tW        =          5e6  ;
integer tH_CLK    =          100  ;
integer tL_CLK    =          100  ;
initial begin

 if (`A125_var || `A145_var) begin
    if (`Vcc >= 1.8 && `Vcc < 2.5)
      if (`M32Kb_var || `M64Kb_var ||`M128Kb_var || `M256Kb_var || `M512Kb_var || `M1Mb_var)
         table_5MHz_2;
      else 
         $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
    else if (`Vcc >= 2.5 && `Vcc < 4.5) 
         table_10MHz_1;
    else if (`Vcc >= 4.5) 
      if (`M32Kb_var || `M64Kb_var ||`M128Kb_var || `M256Kb_var)
         table_20MHz_1;
      else if (`M512Kb_var || `M1Mb_var)
         table_16MHz_1;
      else
         $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
 end
 else begin
   if (`F_var && (`Vcc < 1.8 && `Vcc >= 1.7)) begin
      if (`M16Kb_var)
         table_3p5MHz_1;
      else if (`M64Kb_var ||`M128Kb_var || `M256Kb_var || `M512Kb_var)
         table_5MHz_2;
      else if (`M1Mb_var)
         table_2MHz_1;
      else
         $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
   end
   else if (`Vcc < 2.5 && `Vcc >= 1.8) begin
      if (`F_var || `R_var) begin
         if (`M1Kb_var || `M2Kb_var || `M4Kb_var)
            table_5MHz_4;
         else if (`M8Kb_var || `M16Kb_var || `M32Kb_var || `M64Kb_var || `M1Mb_var || `M2Mb_var)
            table_5MHz_2;
         else if (`M1Mb_var)
            table_5MHz_1;
         else
            $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
      end
      else
         $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
   end
   else if (`Vcc >= 2.5) begin
      if (`F_var || `R_var || `W_var) begin
         if (`M1Kb_var || `M2Kb_var || `M4Kb_var)
            table_10MHz_2;
         else if (`M8Kb_var || `M16Kb_var || `M32Kb_var ||`M128Kb_var || `M256Kb_var || `M512Kb_var || `M1Mb_var)
            table_10MHz_1;
         else if (`M64Kb_var)
            table_10MHz_3;
         else if (`M2Mb_var)
            table_5MHz_2;
         else
            $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
      end
      else
         $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
   end
   else begin
         $display("No AC Table exists for this Vcc selection = %1fV", `Vcc);
   end
 end

 tH_CLK    =          tC/2 ; 
 tL_CLK    =          tC/2 ;

end

task table_2MHz_1;
begin
        fC        =          2    ;           // 2 MHz
        tC        =          500  ;           // ns
        tSLCH     =          150  ;           ///S Active Setup Time
        tSHCH     =          150  ;           ///S Not Active Setup Time
        tSHSL     =          200  ;           ///S Deselect Time
        tCHSH     =          150  ;           ///S Active Hold Time
        tCHSL     =          150  ;           ///S Not Active Hold Time
        tCH       =          200  ;
        tCL       =          200  ;
        tDVCH     =          50   ;           //Data In Setup time
        tCHDX     =          50   ;           //Data In Hold time
        tHHCH     =          150  ;
        tHLCH     =          150  ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          200  ;
        tCLQV     =          200  ;
        tCLQX     =          0    ;
        tHHQV     =          200  ;
        tHLQZ     =          200  ;
        tW        =          5e6  ;             //Write Time:5ms
end
endtask

task table_3p5MHz_1;
begin
        fC        =          3.5     ;           // 3.5 MHz
        tC        =          285.71  ;           // ns
        tSLCH     =          85      ;           ///S Active Setup Time
        tSHCH     =          85      ;           ///S Not Active Setup Time
        tSHSL     =          120     ;           ///S Deselect Time
        tCHSH     =          85      ;           ///S Active Hold Time
        tCHSL     =          85      ;           ///S Not Active Hold Time
        tCH       =          110     ;
        tCL       =          110     ;
        tDVCH     =          30      ;           //Data In Setup time
        tCHDX     =          30      ;           //Data In Hold time
        tHHCH     =          85      ;
        tHLCH     =          85      ;
        tCLHL     =          0       ;
        tCLHH     =          0       ;
        tSHQZ     =          120     ;
        tCLQV     =          120     ;
        tCLQX     =          0       ;
        tHHQV     =          110     ;
        tHLQZ     =          110     ;
        tW        =          5e6     ;             //Write Time:5ms
end
endtask

task table_5MHz_1;
begin
        fC        =          5    ;           // 5 MHz table for M95M01-125 (W3) device
        tC        =          200  ;           // ns
        tSLCH     =          60   ;           // /S Active Setup Time
        tSHCH     =          60   ;           // /S Not Active Setup Time
        tSHSL     =          60   ;           // /S Deselect Time
        tCHSH     =          60   ;           // /S Active Hold Time
        tCHSL     =          60   ;           // /S Not Active Hold Time
        tCH       =          90   ;
        tCL       =          90   ;
        tDVCH     =          20   ;           //Data In Setup time
        tCHDX     =          20   ;           //Data In Hold time
        tHHCH     =          60   ;
        tHLCH     =          60   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          80   ;
        tCLQV     =          80	  ;				//specific tCLQV
        tCLQX     =          0    ;
        tHHQV     =          80   ;
        tHLQZ     =          80   ;
        tW        =          5e6  ;             //Write Time:5ms
end
endtask

task table_5MHz_2;
begin
        fC        =          5    ;           // 5 MHz
        tC        =          200  ;           // ns
        tSLCH     =          60   ;           ///S Active Setup Time
        tSHCH     =          60   ;           ///S Not Active Setup Time
        tSHSL     =          90   ;           ///S Deselect Time
        tCHSH     =          60   ;           ///S Active Hold Time
        tCHSL     =          60   ;           ///S Not Active Hold Time
        tCH       =          80   ;
        tCL       =          80   ;
        tDVCH     =          20   ;           //Data In Setup time
        tCHDX     =          20   ;           //Data In Hold time
        tHHCH     =          60   ;
        tHLCH     =          60   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          80   ;
        tCLQV     =          80   ;
        tCLQX     =          0    ;
        tHHQV     =          80   ;
        tHLQZ     =          80   ;
        if (`R_var && `A125_var && (`M32Kb_var || `M64Kb_var || `M128Kb_var || `M256Kb_var || `M512Kb_var || `M1Mb_var))
           tW     =          4e6  ;             //Write Time:4ms
		    else if (`R_var && `M2Mb_var) begin  
		       tW     =          10e6 ;            //Write Time:10ms (2Mb, M95M02-R6)
		       tCH    =          90   ;			//clock high time (2Mb, M95M02-R6)
           tCL    =          90   ;			//clock low time (2Mb, M95M02-R6)
        end
		    else
          tW      =          5e6  ;             //Write Time:5ms
end
endtask

task table_5MHz_3;
begin
        fC        =          5    ;           // 5 MHz table all M95xxx-125 (W3) devices(except 1Mb) 
		    tC        =          200  ;           // ns
        tSLCH     =          90   ;           // /S Active Setup Time
        tSHCH     =          90   ;           // /S Not Active Setup Time
        tSHSL     =          100  ;           // /S Deselect Time
        tCHSH     =          90   ;           // /S Active Hold Time
        tCHSL     =          90   ;           // /S Not Active Hold Time
        tCH       =          90   ;
        tCL       =          90   ;
        tDVCH     =          20   ;           //Data In Setup time
        tCHDX     =          30   ;           //Data In Hold time
        tHHCH     =          70   ;
        tHLCH     =          40   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          100  ;
        tCLQV     =          60	  ;				//specific tCLQV
        tCLQX     =          0    ;
        tHHQV     =          50   ;
        tHLQZ     =          100  ;
        tW        =          5e6  ;             //Write Time:5ms
end
endtask

task table_5MHz_4;
begin
        fC        =          5    ;           // 5 MHz
        tC        =          200  ;           // ns
        tSLCH     =          90   ;           ///S Active Setup Time
        tSHCH     =          90   ;           ///S Not Active Setup Time
        tSHSL     =          100  ;           ///S Deselect Time
        tCHSH     =          90   ;           ///S Active Hold Time
        tCHSL     =          90   ;           ///S Not Active Hold Time
        tCH       =          90   ;
        tCL       =          90   ;
        tDVCH     =          20   ;           //Data In Setup time
        tCHDX     =          30   ;           //Data In Hold time
        tHHCH     =          70   ;
        tHLCH     =          40   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          100  ;
        tCLQV     =          80   ;
        tCLQX     =          0    ;
        tHHQV     =          50   ;
        tHLQZ     =          100  ;
        tW        =          5e6  ;             //Write Time:5ms
end
endtask

task table_10MHz_1;
begin
        fC        =          10   ;           // 10 MHz(standard W6 and A125-A145 W3 devices)
        tC        =          100  ;           // ns
        tSLCH     =          30   ;           ///S Active Setup Time
        tSHCH     =          30   ;           ///S Not Active Setup Time
        tSHSL     =          40   ;           ///S Deselect Time
        tCHSH     =          30   ;           ///S Active Hold Time
        tCHSL     =          30   ;           ///S Not Active Hold Time
        tCH       =          40   ;
        tCL       =          40   ;
        tDVCH     =          10   ;           //Data In Setup time
        tCHDX     =          10   ;           //Data In Hold time
        tHHCH     =          30   ;
        tHLCH     =          30   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          40   ;
        tCLQV     =          40   ;
        tCLQX     =          0    ;
        tHHQV     =          40   ;
        tHLQZ     =          40   ;

        if ((`A125_var || `A145_var) && (`M32Kb_var || `M64Kb_var || `M128Kb_var 
                       || `M256Kb_var || `M512Kb_var || `M1Mb_var)) 
           tW     =          4e6  ;             //Write Time:4ms (M95xxx-A125-A145)
        else
           tW     =          5e6  ;             //Write Time:5ms (standard M95xxx)
end
endtask

task table_10MHz_2;
begin
        fC        =          10   ;           // 10 MHz(standard W6 devices)
        tC        =          100  ;           // ns
        tSLCH     =          15   ;           ///S Active Setup Time
        tSHCH     =          15   ;           ///S Not Active Setup Time
        tSHSL     =          40   ;           ///S Deselect Time
        tCHSH     =          25   ;           ///S Active Hold Time
        tCHSL     =          15   ;           ///S Not Active Hold Time
        tCH       =          40   ;
        tCL       =          40   ;
        tDVCH     =          15   ;           //Data In Setup time
        tCHDX     =          15   ;           //Data In Hold time
        tHHCH     =          15   ;
        tHLCH     =          20   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          25   ;
        tCLQV     =          35   ;
        tCLQX     =          0    ;
        tHHQV     =          25   ;
        tHLQZ     =          35   ;
        tW        =          5e6  ;             //Write Time:5ms
end
endtask

task table_10MHz_3;
begin
        fC        =          10   ;           //10MHz_3
        tC        =          100  ;           // ns
        tSLCH     =          30   ;           ///S Active Setup Time
        tSHCH     =          30   ;           ///S Not Active Setup Time
        tSHSL     =          40   ;           ///S Deselect Time
        tCHSH     =          30   ;           ///S Active Hold Time
        tCHSL     =          30   ;           ///S Not Active Hold Time
        tCH       =          42   ;
        tCL       =          40   ;
        tDVCH     =          10   ;           //Data In Setup time
        tCHDX     =          10   ;           //Data In Hold time
        tHHCH     =          30   ;
        tHLCH     =          30   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          40   ;
        tCLQV     =          40   ;
        tCLQX     =          0    ;
        tHHQV     =          40   ;
        tHLQZ     =          40   ;
        tW        =          5e6  ;             //Write Time:5ms 	
end
endtask

task table_16MHz_1;
begin
        fC        =          16   ;           //16MHz_1
        tC        =          62   ;           // ns
        tSLCH     =          20   ;           ///S Active Setup Time
        tSHCH     =          20   ;           ///S Not Active Setup Time
        tSHSL     =          25   ;           ///S Deselect Time
        tCHSH     =          20   ;           ///S Active Hold Time
        tCHSL     =          20   ;           ///S Not Active Hold Time
        tCH       =          25   ;
        tCL       =          25   ;
        tDVCH     =          10   ;           //Data In Setup time
        tCHDX     =          10   ;           //Data In Hold time
        tHHCH     =          25   ;
        tHLCH     =          20   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          25   ;
        tCLQV     =          25   ;
        tCLQX     =          0    ;
        tHHQV     =          25   ;
        tHLQZ     =          25   ;
        tW        =          4e6  ;             //Write Time:4ms 	
end
endtask

task table_20MHz_1;
begin
        fC        =          20   ;           //20MHz_1
        tC        =          50   ;           // ns
        tSLCH     =          15   ;           ///S Active Setup Time
        tSHCH     =          15   ;           ///S Not Active Setup Time
        tSHSL     =          20   ;           ///S Deselect Time
        tCHSH     =          15   ;           ///S Active Hold Time
        tCHSL     =          15   ;           ///S Not Active Hold Time
        tCH       =          20   ;
        tCL       =          20   ;
        tDVCH     =          5    ;           //Data In Setup time
        tCHDX     =          10   ;           //Data In Hold time
        tHHCH     =          15   ;
        tHLCH     =          15   ;
        tCLHL     =          0    ;
        tCLHH     =          0    ;
        tSHQZ     =          20   ;
        tCLQV     =          20   ;
        tCLQX     =          0    ;
        tHHQV     =          20   ;
        tHLQZ     =          20   ;
        tW        =          4e6  ;             //Write Time:4ms  
end
endtask



endmodule
