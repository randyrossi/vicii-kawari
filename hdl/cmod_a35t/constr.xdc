# Voltage config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# ---------------------------------------------------------
# !!! These must match selection in cmod_a5t/clockgen.v !!!
# ---------------------------------------------------------

# USE_INTCLOCK_NTSC or USE_INTCLOCK_PAL - Internal L3 12Mhz Pin
#create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sys_clock}];
#set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; 

# USE_EXTCLOCK_PAL - Pin3 External 17.3Mhz
create_clock -add -name pal_clk_in -period 56.38 -waveform {0 28.19} [get_ports {sys_clock}];
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }];
#create_clock -add -name phi_clk_out -period 1014.97 -waveform {0 507.48} [get_ports {clk_phi}];
#create_clock -add -name dot4x_clk_out -period 31.71 -waveform {0 15.85} [get_ports {clk_dot4x}];

# USE_EXTCLOCK_NTSC - Pin3 External 14.3Mhz
#create_clock -add -name ntsc_clk_pin -period 69.84 -waveform {0 34.92} [get_ports {sys_clock}];
#set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }];
#create_clock -add -name phi_clk_out -period 977.78 -waveform {0 488.89} [get_ports {clk_phi}];


# Board Pins

# colorref out, Pin35
set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports { clk_colref }];

# clk_dot4x out, PMOD Pin 9
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { clk_dot4x }];

# hSync out, PMOD Pin1
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports { hsync }];

# cSync out, PMOD Pin2
set_property -dict { PACKAGE_PIN G19 IOSTANDARD LVCMOS33 } [get_ports { csync }];

# vSync out, PMOD Pin7
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { vsync }];

# is_composite, PMOD Pin 8 - Ground for VGA/HDMI, Pull Up for Composite
set_property -dict { PACKAGE_PIN H19 IOSTANDARD LVCMOS33 } [get_ports { is_composite }];

# active signal for HDMI - Pin 41
set_property -dict { PACKAGE_PIN U5    IOSTANDARD LVCMOS33 } [get_ports { active }];

# clk_phi out, Pin45
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports { clk_phi }];

# rst out, Pin34 TODO MOVE TO PMOD HEADER PIN
set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports { cpu_reset }];

# RGB out

# red[0] out, PMOD 3
set_property -dict { PACKAGE_PIN N18 IOSTANDARD LVCMOS33 } [get_ports { red[0] }];
# red[1] out, Pin48
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { red[1] }];
# red[2] out, Pin47
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { red[2] }];

# green[0] out, PMOD 4
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports { green[0] }];
# green[1] out, Pin44
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports { green[1] }];
# green[2] out, Pin43
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports { green[2] }];

# blue[0] out, PMOD 10
set_property -dict { PACKAGE_PIN K18 IOSTANDARD LVCMOS33 } [get_ports { blue[0] }];
# blue[1] out, Pin40
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports { blue[1] }];
# blue[2] out, Pin39
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports { blue[2] }];

# Address lines
# ad[0] inout, Pin 26
set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS33 } [get_ports { adl[0] }];
# ad[1] inout, Pin 27
set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS33 } [get_ports { adl[1] }];
# ad[2] inout, Pin 28
set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 } [get_ports { adl[2] }];
# ad[3] inout, Pin 29
set_property -dict { PACKAGE_PIN T1 IOSTANDARD LVCMOS33 } [get_ports { adl[3] }];
# ad[4] inout, Pin 30
set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS33 } [get_ports { adl[4] }];
# ad[5] inout, Pin 31
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 } [get_ports { adl[5] }];
# ad[6] inout, Pin 32
set_property -dict { PACKAGE_PIN W2 IOSTANDARD LVCMOS33 } [get_ports { adh[0] }];
# ad[7] inout, Pin 33
set_property -dict { PACKAGE_PIN V2 IOSTANDARD LVCMOS33 } [get_ports { adh[1] }];
# ad[8] inout, Pin 18
set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 } [get_ports { adh[2] }];
# ad[9] inout, Pin 17
set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS33 } [get_ports { adh[3] }];
# ad[10] inout, Pin 46
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports { adh[4] }];
# ad[11] inout, Pin 19
set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 } [get_ports { adh[5] }];

# Data bus lines
# db[0] inout, Pin 8
set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 } [get_ports { dbl[0]  }];
# db[1] inout, Pin 7
set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 } [get_ports { dbl[1]  }];
# db[2] inout, Pin 6
set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports { dbl[2]  }];
# db[3] inout, Pin 5
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports { dbl[3]  }];
# db[4] inout, Pin 4
set_property -dict { PACKAGE_PIN K3  IOSTANDARD LVCMOS33 } [get_ports { dbl[4]  }];
# db[5] inout, Pin 36
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { dbl[5]  }];
# db[6] inout, Pin 2
set_property -dict { PACKAGE_PIN L3  IOSTANDARD LVCMOS33 } [get_ports { dbl[6]  }];
# db[7] inout, Pin 1
set_property -dict { PACKAGE_PIN M3  IOSTANDARD LVCMOS33 } [get_ports { dbl[7]  }];
# db[8] in, Pin 9
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { dbh[0]  }];
# db[9] in, Pin 10
set_property -dict { PACKAGE_PIN J3  IOSTANDARD LVCMOS33 } [get_ports { dbh[1] }];
# db[10] in, Pin 11
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports { dbh[2] }];
# db[11] in, Pin 12
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { dbh[3] }];

# cs input, Pin 13
set_property -dict { PACKAGE_PIN L1    IOSTANDARD LVCMOS33 } [get_ports { ce }];

# rw input, Pin 14
set_property -dict { PACKAGE_PIN L2    IOSTANDARD LVCMOS33 } [get_ports { rw }];

# aec, Pin 20
set_property -dict { PACKAGE_PIN M2    IOSTANDARD LVCMOS33 } [get_ports { aec }];

# ba, Pin 21 
set_property -dict { PACKAGE_PIN N1    IOSTANDARD LVCMOS33 } [get_ports { ba }];

# irq, Pin 37
set_property -dict { PACKAGE_PIN V4    IOSTANDARD LVCMOS33 } [get_ports { irq }];

# RAS, Pin 22
set_property -dict { PACKAGE_PIN N2    IOSTANDARD LVCMOS33 } [get_ports { ras }];

# CAS, Pin 23
set_property -dict { PACKAGE_PIN P1    IOSTANDARD LVCMOS33 } [get_ports { cas }];

# LP, Pin 42
set_property -dict { PACKAGE_PIN U2    IOSTANDARD LVCMOS33 } [get_ports { lp }];

# DIR, Pin 38
set_property -dict { PACKAGE_PIN U4    IOSTANDARD LVCMOS33 } [get_ports { ls245_data_dir }];

set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[0] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[1] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[2] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[3] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[4] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { adl[5] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[0] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[1] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[2] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[3] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[4] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { adl[5] }];

set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { ce }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { ce }];

set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[0] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[1] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[2] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[3] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[0] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[1] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[2] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbh[3] }];

set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[0] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[1] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[2] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[3] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[4] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[5] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[6] }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[7] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[0] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[1] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[2] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[3] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[4] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[5] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[6] }];
set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { dbl[7] }];

set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { lp }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { lp }];

set_input_delay 0 -min -clock clk_dot4x_clk_wiz_0 [get_ports { rw }];
set_input_delay 0 -max -clock clk_dot4x_clk_wiz_0 [get_ports { rw }];

set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { active }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { red[0] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { red[1] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { red[2] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { green[0] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { green[1] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { green[2] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { blue[0] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { blue[1] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { blue[2] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { csync }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { hsync }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { vsync }];
set_output_delay -clock clk_col4x_clk_wiz_0 0 [get_ports { clk_colref }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { cpu_reset }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { clk_phi }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[0] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[1] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[2] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[3] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[4] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adh[5] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[0] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[1] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[2] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[3] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[4] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { adl[5] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { aec }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { ba }];

set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[0] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[1] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[2] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[3] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[4] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[5] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[6] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { dbl[7] }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { irq }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { ls245_data_dir }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { ras }];
set_output_delay -clock clk_dot4x_clk_wiz_0 0 [get_ports { cas }];


set_property DRIVE 4 [get_ports adh[0]];
set_property DRIVE 4 [get_ports adh[1]];
set_property DRIVE 4 [get_ports adh[2]];
set_property DRIVE 4 [get_ports adh[3]];
set_property DRIVE 4 [get_ports adh[4]];
set_property DRIVE 4 [get_ports adh[5]];
set_property DRIVE 4 [get_ports adl[0]];
set_property DRIVE 4 [get_ports adl[1]];
set_property DRIVE 4 [get_ports adl[2]];
set_property DRIVE 4 [get_ports adl[3]];
set_property DRIVE 4 [get_ports adl[4]];
set_property DRIVE 4 [get_ports adl[5]];
set_property DRIVE 4 [get_ports aec];
set_property DRIVE 4 [get_ports ras];
set_property DRIVE 4 [get_ports cas];
set_property DRIVE 4 [get_ports ba];
set_property DRIVE 4 [get_ports clk_phi];
set_property DRIVE 4 [get_ports dbl[0]];
set_property DRIVE 4 [get_ports dbl[1]];
set_property DRIVE 4 [get_ports dbl[2]];
set_property DRIVE 4 [get_ports dbl[3]];
set_property DRIVE 4 [get_ports dbl[4]];
set_property DRIVE 4 [get_ports dbl[5]];
set_property DRIVE 4 [get_ports dbl[6]];
set_property DRIVE 4 [get_ports dbl[7]];
set_property DRIVE 4 [get_ports irq];
set_property DRIVE 4 [get_ports cpu_reset];
set_property DRIVE 4 [get_ports { clk_dot4x }];
set_property DRIVE 4 [get_ports { active }];
set_property DRIVE 4 [get_ports { csync }];
set_property DRIVE 4 [get_ports { clk_colref }];
set_property DRIVE 4 [get_ports { hsync }];
set_property DRIVE 4 [get_ports { vsync }];
set_property DRIVE 4 [get_ports { red[0] }];
set_property DRIVE 4 [get_ports { red[1] }];
set_property DRIVE 4 [get_ports { red[2] }];
set_property DRIVE 4 [get_ports { green[0] }];
set_property DRIVE 4 [get_ports { green[1] }];
set_property DRIVE 4 [get_ports { green[2] }];
set_property DRIVE 4 [get_ports { blue[0] }];
set_property DRIVE 4 [get_ports { blue[1] }];
set_property DRIVE 4 [get_ports { blue[2] }];

