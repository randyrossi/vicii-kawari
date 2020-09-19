# Voltage config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# ---------------------------------------------------------
# !!! These must match selection in cmod_a5t/clockgen.v !!!
# ---------------------------------------------------------

# USE_INTCLOCK_NTSC or USE_INTCLOCK_PAL - Internal D18 50Mhz Pin
#create_clock -add -name sys_clk_pin -period 20 -waveform {0 10} [get_ports {sys_clock}];
#set_property -dict { PACKAGE_PIN D18 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; 

# USE_EXTCLOCK_PAL - Pin16 External 17.3Mhz
create_clock -add -name pal_clk_in -period 56.38 -waveform {0 28.19} [get_ports {sys_clock}];
set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }];
#create_clock -add -name phi_clk_out -period 1014.97 -waveform {0 507.48} [get_ports {clk_phi}];
#create_clock -add -name dot4x_clk_out -period 31.71 -waveform {0 15.85} [get_ports {clk_dot4x}];

# USE_EXTCLOCK_NTSC - Pin16 External 14.3Mhz
#create_clock -add -name ntsc_clk_pin -period 69.84 -waveform {0 34.92} [get_ports {sys_clock}];
#set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }];
#create_clock -add -name phi_clk_out -period 977.78 -waveform {0 488.89} [get_ports {clk_phi}];


# Board Pins

# colorref out, Pin U2/12
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports { clk_colref }];

# clk_dot4x out, Pin U2/58
set_property -dict { PACKAGE_PIN R1 IOSTANDARD LVCMOS33 } [get_ports { clk_dot4x }];

# hSync out, Pin U2/23
set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 } [get_ports { hsync }];

# cSync out, Pin U2/20
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 } [get_ports { csync }];

# vSync out, Pin U2/28
set_property -dict { PACKAGE_PIN F2 IOSTANDARD LVCMOS33 } [get_ports { vsync }];

# is_composite, Pin U2/59
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 } [get_ports { is_composite }];

# active signal for HDMI - Pin U2/7
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports { active }];

# clk_phi out, Pin U4/58
set_property -dict { PACKAGE_PIN AA24 IOSTANDARD LVCMOS33 } [get_ports { clk_phi }];

# rst out, Pin U4/9
set_property -dict { PACKAGE_PIN A23 IOSTANDARD LVCMOS33 } [get_ports { cpu_reset }];

# RGB out

# red[0] out, U2/31
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports { red[0] }];
# red[1] out, U2/34
set_property -dict { PACKAGE_PIN H9 IOSTANDARD LVCMOS33 } [get_ports { red[1] }];
# red[2] out, U2/35
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports { red[2] }];

# green[0] out, U2/38 
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 } [get_ports { green[0] }];
# green[1] out,  U2/39
set_property -dict { PACKAGE_PIN K2 IOSTANDARD LVCMOS33 } [get_ports { green[1] }];
# green[2] out,  U2/42
set_property -dict { PACKAGE_PIN K1 IOSTANDARD LVCMOS33 } [get_ports { green[2] }];

# blue[0] out,  U2/43
set_property -dict { PACKAGE_PIN L2 IOSTANDARD LVCMOS33 } [get_ports { blue[0] }];
# blue[1] out,  U2/46
set_property -dict { PACKAGE_PIN N1 IOSTANDARD LVCMOS33 } [get_ports { blue[1] }];
# blue[2] out,  U2/47
set_property -dict { PACKAGE_PIN M5 IOSTANDARD LVCMOS33 } [get_ports { blue[2] }];

# Address lines
# ad[0] inout, Pin U4/31
set_property -dict { PACKAGE_PIN H24 IOSTANDARD LVCMOS33 } [get_ports { adl[0] }];
# ad[1] inout, Pin U4/34
set_property -dict { PACKAGE_PIN K25 IOSTANDARD LVCMOS33 } [get_ports { adl[1] }];
# ad[2] inout, Pin U4/35
set_property -dict { PACKAGE_PIN L25 IOSTANDARD LVCMOS33 } [get_ports { adl[2] }];
# ad[3] inout, Pin U4/38
set_property -dict { PACKAGE_PIN N26 IOSTANDARD LVCMOS33 } [get_ports { adl[3] }];
# ad[4] inout, Pin U4/39
set_property -dict { PACKAGE_PIN M25 IOSTANDARD LVCMOS33 } [get_ports { adl[4] }];
# ad[5] inout, Pin U4/42
set_property -dict { PACKAGE_PIN R26 IOSTANDARD LVCMOS33 } [get_ports { adl[5] }];
# ad[6] inout, Pin U4/43
set_property -dict { PACKAGE_PIN P25 IOSTANDARD LVCMOS33 } [get_ports { adh[0] }];
# ad[7] inout, Pin U4/46
set_property -dict { PACKAGE_PIN U26 IOSTANDARD LVCMOS33 } [get_ports { adh[1] }];
# ad[8] inout, Pin U4/47
set_property -dict { PACKAGE_PIN T25 IOSTANDARD LVCMOS33 } [get_ports  { adh[2] }];
# ad[9] inout, Pin U4/50
set_property -dict { PACKAGE_PIN V26 IOSTANDARD LVCMOS33 } [get_ports { adh[3] }];
# ad[10] inout, Pin U4/51
set_property -dict { PACKAGE_PIN Y26 IOSTANDARD LVCMOS33 } [get_ports { adh[4] }];
# ad[11] inout, Pin U4/54
set_property -dict { PACKAGE_PIN V24 IOSTANDARD LVCMOS33 } [get_ports { adh[5] }];

# Data bus lines
# db[0] inout, Pin U4/7
set_property -dict { PACKAGE_PIN A22 IOSTANDARD LVCMOS33 } [get_ports { dbl[0]  }];
# db[1] inout, Pin U4/10
set_property -dict { PACKAGE_PIN B22 IOSTANDARD LVCMOS33 } [get_ports { dbl[1]  }];
# db[2] inout, Pin U4/11
set_property -dict { PACKAGE_PIN A25 IOSTANDARD LVCMOS33 } [get_ports { dbl[2]  }];
# db[3] inout, Pin U4/14
set_property -dict { PACKAGE_PIN C22 IOSTANDARD LVCMOS33 } [get_ports { dbl[3]  }];
# db[4] inout, Pin U4/15
set_property -dict { PACKAGE_PIN B24  IOSTANDARD LVCMOS33 } [get_ports { dbl[4]  }];
# db[5] inout, Pin U4/18
set_property -dict { PACKAGE_PIN C26 IOSTANDARD LVCMOS33 } [get_ports { dbl[5]  }];
# db[6] inout, Pin U4/19
set_property -dict { PACKAGE_PIN D25 IOSTANDARD LVCMOS33 } [get_ports { dbl[6]  }];
# db[7] inout, Pin U4/22
set_property -dict { PACKAGE_PIN E25 IOSTANDARD LVCMOS33 } [get_ports { dbl[7]  }];
# db[8] in, Pin U4/23
set_property -dict { PACKAGE_PIN D26 IOSTANDARD LVCMOS33 } [get_ports { dbh[0]  }];
# db[9] in, Pin U4/26
set_property -dict { PACKAGE_PIN H26 IOSTANDARD LVCMOS33 } [get_ports { dbh[1] }];
# db[10] in, Pin U4/27
set_property -dict { PACKAGE_PIN F25 IOSTANDARD LVCMOS33 } [get_ports { dbh[2] }];
# db[11] in, Pin U4/30
set_property -dict { PACKAGE_PIN J25 IOSTANDARD LVCMOS33 } [get_ports { dbh[3] }];

# cs input, Pin U4/13
set_property -dict { PACKAGE_PIN C23 IOSTANDARD LVCMOS33 } [get_ports { ce }];

# rw input, Pin U4/17
set_property -dict { PACKAGE_PIN B26 IOSTANDARD LVCMOS33 } [get_ports { rw }];

# aec, Pin U4/55
set_property -dict { PACKAGE_PIN AA25 IOSTANDARD LVCMOS33 } [get_ports { aec }];

# ba, Pin U4/53
set_property -dict { PACKAGE_PIN W24 IOSTANDARD LVCMOS33 } [get_ports { ba }];

# irq, Pin U4/20
set_property -dict { PACKAGE_PIN D23 IOSTANDARD LVCMOS33 } [get_ports { irq }];

# RAS, Pin U4/59
set_property -dict { PACKAGE_PIN AC26 IOSTANDARD LVCMOS33 } [get_ports { ras }];

# CAS, Pin U4/60
set_property -dict { PACKAGE_PIN AB26 IOSTANDARD LVCMOS33 } [get_ports { cas }];

# LP, Pin U4/16
set_property -dict { PACKAGE_PIN C24 IOSTANDARD LVCMOS33 } [get_ports { lp }];

# DIR, Pin U4/12
set_property -dict { PACKAGE_PIN B25 IOSTANDARD LVCMOS33 } [get_ports { ls245_data_dir }];

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
set_property DRIVE 4 [get_ports clk_dot4x];
set_property DRIVE 4 [get_ports active];
set_property DRIVE 4 [get_ports csync];
set_property DRIVE 4 [get_ports clk_colref];
set_property DRIVE 4 [get_ports hsync];
set_property DRIVE 4 [get_ports vsync];
set_property DRIVE 4 [get_ports red[0]];
set_property DRIVE 4 [get_ports red[1]];
set_property DRIVE 4 [get_ports red[2]];
set_property DRIVE 4 [get_ports green[0]];
set_property DRIVE 4 [get_ports green[1]];
set_property DRIVE 4 [get_ports green[2]];
set_property DRIVE 4 [get_ports blue[0]];
set_property DRIVE 4 [get_ports blue[1]];
set_property DRIVE 4 [get_ports blue[2]];

