/*=============================================================================

Testbench for Serial SPI Bus EEPROM Simulation Model

=============================================================================*/

`include "M95XXX_Parameters.v"

//This defines the parameter file for M95080-W6, "W" or "G" F6SP36% process
//Any other M95xxx memory should define here the proper M95xxx parameter file

//=====================================
module M95XXX_SIM;

wire c,d,q,s,w,hold,vcc,vss;

//-------------------------------------
M95XXX U_M95XXX(
                    .C(c),
                    .D(d),
                    .Q(q),
                    .S(s),
                    .W(w),
                    .HOLD(hold),
                    .VCC(vcc),
                    .VSS(vss)
                 );
//-------------------------------------
M95XXX_DRV M95XXX_Driver(
                            .C(c),
                            .D(d),
                            .Q(q),
                            .S(s),
                            .W(w),
                            .HOLD(hold),
                            .VCC(vcc),
                            .VSS(vss)
                          );
//-------------------------------------
M95XXX_Macro_mux M95XXX_Macro_mux();

integer index;
reg [8*3:0] string;
reg [8*4:0] string2;

initial begin
   if (!`VALID_PRT) 
   begin
       $display("\n#2#############################################");
       $display("###      NO VAILED MEMORY SIZE CHOOSEN   ###");
       $display("##############################################\n");
       $stop;
   end     

   if (`M1Kb_var)  
           string  = "010";                         
   else if (`M2Kb_var)  
           string  = "020";        
   else if (`M4Kb_var)    
           string  = "040";      
   else if (`M8Kb_var) 
           string  = "080"; 
   else if (`M16Kb_var) 
           string  = "160";  
   else if (`M32Kb_var)  
           string  = "320";
   else if (`M64Kb_var) 
           string  = "640";       
   else if (`M128Kb_var)  
           string  = "128";   
   else if (`M256Kb_var) 
           string  = "256";     
   else if (`M512Kb_var) 
           string  = "512";           
   else if (`M1Mb_var)    
           string  = "M01";    
   else if (`M2Mb_var)  
           string  = "M02";    
   else 
           string  = "XXX";

   if (`A125_var)
          string2 = "A125";
   else if (`A145_var)
          string2 = "A145";
   else
          string2 = "XXXX";

   
   if (`VALID_PRT) begin
      $display("\n################################################################################");
      if (`A125_var || `A145_var) begin
         $display("###     The Selected Model is a AUTOMOTIVE memory, referenced as M95%3s-%4s          ###",string,string2);

         if (`W_var)
            $display("###     Minimum operating voltage range: W=2.5V/145C                                                                ###");
         else if (`R_var)
            $display("###     Minimum operating voltage range: R=1.8V/125C                                                                ###");
      end
      else
         if (`W_var) begin
           if (`IDPAGE)
              $display("###     The Selected Model is a STANDARD memory, referenced as M95%3s-DW                       ###",string);
           else
              $display("###     The Selected Model is a STANDARD memory, referenced as M95%3s-W                        ###",string);
           $display("###     Minimum operating voltage range: W=2.5V                                                                        ###");
         end
         else if (`R_var) begin
           if (`IDPAGE)
              $display("###     The Selected Model is a STANDARD memory, referenced as M95%3s-DR                       ###",string);
           else
              $display("###     The Selected Model is a STANDARD memory, referenced as M95%3s-R                        ###",string);
           $display("###     Minimum operating voltage range: R=1.8V                                                                        ###");
         end
         else if (`F_var) begin
           if (`IDPAGE)
              $display("###     The Selected Model is a STANDARD memory, referenced as M95%3s-DF                       ###",string);
           else
              $display("###     The Selected Model is a STANDARD memory, referenced as M95%3s-F                        ###",string);
           $display("###     Minimum operating voltage range: F=1.7V                                                                        ###");
         end
   end

           $display("###     Operating voltage selected: VCC=%1f V                                                                        ",`Vcc);


   if (`M1Kb_var)                       
        $display("###     Memory Capacity: 1 Kb                                                                                                       ###");
   else if (`M2Kb_var)          
        $display("###     Memory Capacity: 2 Kb                                                                                                       ###");
   else if (`M4Kb_var)          
        $display("###     Memory Capacity: 4 Kb                                                                                                       ###");
   else if (`M8Kb_var)  
        $display("###     Memory Capacity: 8 Kb                                                                                                       ###");        
   else if (`M16Kb_var)   
        $display("###     Memory Capacity: 16 Kb                                                                                                      ###");              
   else if (`M32Kb_var)  
        $display("###     Memory Capacity: 32 Kb                                                                                                      ###");                     
   else if (`M64Kb_var)        
        $display("###     Memory Capacity: 64 Kb                                                                                                      ###");                     
   else if (`M128Kb_var)     
        $display("###     Memory Capacity: 128 Kb                                                                                                     ###");                        
   else if (`M256Kb_var)      
        $display("###     Memory Capacity: 256 Kb                                                                                                     ###");                          
   else if (`M512Kb_var)       
        $display("###     Memory Capacity: 512 Kb                                                                                                     ###");                          
   else if (`M1Mb_var)        
        $display("###     Memory Capacity: 1 Mb                                                                                                       ###");                          
   else if (`M2Mb_var)  
        $display("###     Memory Capacity: 2 Mb                                                                                                       ###");                                  
   else begin
        $display("\n###############################################");
        $display("### 1    NO VAILED MEMORY SIZE CHOOSEN   ###");
        $display("##############################################\n");
        $stop;
   end

   $display("################################################################################\n");

/*    for(index = 0; index < `MEM_SIZE; index = index + 1)
      U_M95080.memory[index] = 8'hff;
    $writememh("memory_hex.txt", U_M95080.memory);
*/

    $display("%t: NOTE: Load memory with Initial content.",$realtime);
    $readmemh("M95XXX_Initial.dat",U_M95XXX.memory);
    $display("%t: NOTE: Initial Load End.\n",$realtime);   

    if (`IDPAGE)
    begin
      $display("%t: NOTE: Load ID memory with Initial content.",$realtime);
      $readmemh("M95XXX_ID_Initial.dat",U_M95XXX.memory_id);
      $display("%t: NOTE: Initial ID Load End.\n",$realtime);
    end
end


//-------------------------------------

endmodule
