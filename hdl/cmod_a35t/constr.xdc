# Voltage config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# ---------------------------------------------------------
# !!! These must match selection in cmod_a5t/clockgen.v !!!
# ---------------------------------------------------------

# USE_INTCLOCK_NTSC or USE_INTCLOCK_PAL - Internal L3 12Mhz Pin
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sys_clock}];
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; 

# USE_EXTCLOCK_PAL - Pin 36 External 17.3Mhz
#create_clock -add -name pal_clk_in -period 56.38 -waveform {0 28.19} [get_ports {sys_clock}];
#set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }];
#create_clock -add -name phi_clk_out -period 1014.97 -waveform {0 507.48} [get_ports {clk_phi}];
#create_clock -add -name dot4x_clk_out -period 31.71 -waveform {0 15.85} [get_ports {clk_dot4x}];

# USE_EXTCLOCK_NTSC - Pin 36 External 14.3Mhz
#create_clock -add -name ntsc_clk_pin -period 69.84 -waveform {0 34.92} [get_ports {sys_clock}];
#set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }];
#create_clock -add -name phi_clk_out -period 977.78 -waveform {0 488.89} [get_ports {clk_phi}];

# PMOD Pin1
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports { chroma[3] }];

# PMOD Pin2
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports { chroma[2] }];

# PMOD Pin3
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports { chroma[1] }];

# PMOD Pin4
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { chroma[0] }];

# PMOD Pin7
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { D }];

# PMOD Pin8 - DeadPIN on my CMOD :(
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports { adh[5] }];

# PMOD Pin 9
set_property -dict { PACKAGE_PIN J19 IOSTANDARD LVCMOS33 } [get_ports { C }];

# PMOD Pin10
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports { S }];

# Pin 1
set_property -dict { PACKAGE_PIN M3  IOSTANDARD LVCMOS33 } [get_ports { Q }];
# Pin 2
set_property -dict { PACKAGE_PIN L3  IOSTANDARD LVCMOS33 } [get_ports { adh[4] }];
# Pin 3
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports { adh[3] }];
# Pin 4
set_property -dict { PACKAGE_PIN K3  IOSTANDARD LVCMOS33 } [get_ports { adh[2] }];
# Pin 5
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports { adh[1] }];
# Pin 6
set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports { adh[0] }];
# Pin 7
set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 } [get_ports { adl[5] }];
# Pin 8
set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 } [get_ports { adl[4] }];
# Pin 9
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { adl[3] }];
# Pin 10
set_property -dict { PACKAGE_PIN J3 IOSTANDARD LVCMOS33 } [get_ports { adl[2] }];
# Pin 11
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports { adl[1] }];
# Pin 12
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports { adl[0] }];
# Pin 13
set_property -dict { PACKAGE_PIN L1 IOSTANDARD LVCMOS33 } [get_ports { ls245_addr_dir }];
# Pin 14
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports { aec }];
# Pin 17
set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS33 } [get_ports { rw }];
# Pin 18
set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 } [get_ports { ce }];
# Pin 19
set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 } [get_ports { ls245_data_dir }];
# Pin 20
set_property -dict { PACKAGE_PIN M2 IOSTANDARD LVCMOS33 } [get_ports { dbh[3] }];
# Pin 21 
set_property -dict { PACKAGE_PIN N1 IOSTANDARD LVCMOS33 } [get_ports { dbh[2] }];
# Pin 22
set_property -dict { PACKAGE_PIN N2 IOSTANDARD LVCMOS33 } [get_ports { dbh[1] }];
# Pin 23
set_property -dict { PACKAGE_PIN P1 IOSTANDARD LVCMOS33 } [get_ports { dbh[0] }];
# Pin 26
set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS33 } [get_ports { dbl[0] }];
# Pin 27
set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS33 } [get_ports { dbl[1] }];
# Pin 28
set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 } [get_ports { dbl[2] }];
# Pin 29
set_property -dict { PACKAGE_PIN T1 IOSTANDARD LVCMOS33 } [get_ports { dbl[3] }];
# Pin 30
set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS33 } [get_ports { dbl[4] }];
# Pin 31
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 } [get_ports { dbl[5] }];
# Pin 32
set_property -dict { PACKAGE_PIN W2 IOSTANDARD LVCMOS33 } [get_ports { dbl[6] }];
# Pin 33
set_property -dict { PACKAGE_PIN V2 IOSTANDARD LVCMOS33 } [get_ports { dbl[7] }];
# Pin 34
set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports { lp }];
# Pin 35
set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports { cas }];
# Pin 37
set_property -dict { PACKAGE_PIN V4 IOSTANDARD LVCMOS33 } [get_ports { ras }];
# Pin 38
set_property -dict { PACKAGE_PIN U4 IOSTANDARD LVCMOS33 } [get_ports { ba }];
# Pin 39
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports { luma[5] }];
# Pin 40
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports { luma[4] }];
# Pin 41
set_property -dict { PACKAGE_PIN U5 IOSTANDARD LVCMOS33 } [get_ports { luma[3] }];
# Pin 42
set_property -dict { PACKAGE_PIN U2 IOSTANDARD LVCMOS33 } [get_ports { irq }];
# Pin 43
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports { luma[2] }];
# Pin 44
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports { luma[1] }];
# Pin 45
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports { clk_phi }];
# Pin 46
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports { luma[0] }];
# Pin 47
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { chroma[5] }];
# Pin 48
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { chroma[4] }];


#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[0] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[1] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[2] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[3] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[4] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[5] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[0] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[1] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[2] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[3] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[4] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[5] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { ce }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { ce }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[0] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[1] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[2] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[3] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[0] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[1] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[2] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[3] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[0] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[1] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[2] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[3] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[4] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[5] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[6] }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[7] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[0] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[1] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[2] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[3] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[4] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[5] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[6] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[7] }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { lp }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { lp }];
#set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { rw }];
#set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { rw }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { active }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { red[0] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { red[1] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { red[2] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { green[0] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { green[1] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { green[2] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { blue[0] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { blue[1] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { blue[2] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { csync }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { hsync }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { vsync }];
#set_output_delay -clock clk_col4x_clk_wiz_0 0 [get_ports { clk_colref }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { cpu_reset }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { clk_phi }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[0] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[1] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[2] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[3] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[4] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[5] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[0] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[1] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[2] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[3] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[4] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[5] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { aec }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { ba }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[0] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[1] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[2] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[3] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[4] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[5] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[6] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[7] }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { irq }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { ls245_data_dir }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { ras }];
#set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { cas }];

# Set drive strength to lowest value

#set_property DRIVE 4 [get_ports adh[0]];
#set_property DRIVE 4 [get_ports adh[1]];
#set_property DRIVE 4 [get_ports adh[2]];
#set_property DRIVE 4 [get_ports adh[3]];
#set_property DRIVE 4 [get_ports adh[4]];
#set_property DRIVE 4 [get_ports adh[5]];
#set_property DRIVE 4 [get_ports adl[0]];
#set_property DRIVE 4 [get_ports adl[1]];
#set_property DRIVE 4 [get_ports adl[2]];
#set_property DRIVE 4 [get_ports adl[3]];
#set_property DRIVE 4 [get_ports adl[4]];
#set_property DRIVE 4 [get_ports adl[5]];
#set_property DRIVE 4 [get_ports aec];
#set_property DRIVE 4 [get_ports ras];
#set_property DRIVE 4 [get_ports cas];
#set_property DRIVE 4 [get_ports ba];
#set_property DRIVE 4 [get_ports clk_phi];
#set_property DRIVE 4 [get_ports dbl[0]];
#set_property DRIVE 4 [get_ports dbl[1]];
#set_property DRIVE 4 [get_ports dbl[2]];
#set_property DRIVE 4 [get_ports dbl[3]];
#set_property DRIVE 4 [get_ports dbl[4]];
#set_property DRIVE 4 [get_ports dbl[5]];
#set_property DRIVE 4 [get_ports dbl[6]];
#set_property DRIVE 4 [get_ports dbl[7]];
#set_property DRIVE 4 [get_ports irq];
#set_property DRIVE 4 [get_ports cpu_reset];
#set_property DRIVE 4 [get_ports { clk_dot4x }];
#set_property DRIVE 4 [get_ports { active }];
#set_property DRIVE 4 [get_ports { csync }];
#set_property DRIVE 4 [get_ports { clk_colref }];
#set_property DRIVE 4 [get_ports { hsync }];
#set_property DRIVE 4 [get_ports { vsync }];
#set_property DRIVE 4 [get_ports { red[0] }];
#set_property DRIVE 4 [get_ports { red[1] }];
#set_property DRIVE 4 [get_ports { red[2] }];
#set_property DRIVE 4 [get_ports { green[0] }];
#set_property DRIVE 4 [get_ports { green[1] }];
#set_property DRIVE 4 [get_ports { green[2] }];
#set_property DRIVE 4 [get_ports { blue[0] }];
#set_property DRIVE 4 [get_ports { blue[1] }];
#set_property DRIVE 4 [get_ports { blue[2] }];


set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }];
set_property -dict { PACKAGE_PIN B18   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }];

set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }];
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { led[1] }];
