# External clock 12Mhz
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sys_clock}];

#set_output_delay -clock [get_clocks x_clk] -min -add_delay 0.000 [get_ports clk_colref]
#set_output_delay -clock [get_clocks x_clk] -max -add_delay 0.000 [get_ports clk_colref]

# Voltage config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# Board Pins

# colorref out, Pin35
set_property -dict { PACKAGE_PIN V3 IOSTANDARD LVCMOS33 } [get_ports { clk_colref }];

# cSync out, Pin36
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports { cSync }];

# clk_phi out, Pin45
set_property -dict { PACKAGE_PIN U7 IOSTANDARD LVCMOS33 } [get_ports { clk_phi }];

# rst in, Pin34
set_property -dict { PACKAGE_PIN W3 IOSTANDARD LVCMOS33 } [get_ports { rst }];

# sys_clock in, L17 = Internal clock pin 
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; 

# RGB out
# red[0] out, Pin48
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { red[0] }];
# red[1] out, Pin47
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { red[1] }];
# green[0] out, Pin44
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports { green[0] }];
# green[1] out, Pin43
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports { green[1] }];
# blue[0] out, Pin40
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports { blue[0] }];
# blue[1] out, Pin39
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports { blue[1] }];

# Address lines
# ad[0] inout, Pin 26
set_property -dict { PACKAGE_PIN R3 IOSTANDARD LVCMOS33 } [get_ports { ad[0] }];
# ad[1] inout, Pin 27
set_property -dict { PACKAGE_PIN T3 IOSTANDARD LVCMOS33 } [get_ports { ad[1] }];
# ad[2] inout, Pin 28
set_property -dict { PACKAGE_PIN R2 IOSTANDARD LVCMOS33 } [get_ports { ad[2] }];
# ad[3] inout, Pin 29
set_property -dict { PACKAGE_PIN T1 IOSTANDARD LVCMOS33 } [get_ports { ad[3] }];
# ad[4] inout, Pin 30
set_property -dict { PACKAGE_PIN T2 IOSTANDARD LVCMOS33 } [get_ports { ad[4] }];
# ad[5] inout, Pin 31
set_property -dict { PACKAGE_PIN U1 IOSTANDARD LVCMOS33 } [get_ports { ad[5] }];
# ad[6] inout, Pin 32
set_property -dict { PACKAGE_PIN W2 IOSTANDARD LVCMOS33 } [get_ports { ad[6] }];
# ad[7] inout, Pin 33
set_property -dict { PACKAGE_PIN V2 IOSTANDARD LVCMOS33 } [get_ports { ad[7] }];
# ad[8] inout, Pin 18
set_property -dict { PACKAGE_PIN N3 IOSTANDARD LVCMOS33 } [get_ports { ad[8] }];
# ad[9] inout, Pin 17
set_property -dict { PACKAGE_PIN M1 IOSTANDARD LVCMOS33 } [get_ports { ad[9] }];
# ad[10] inout, Pin 46
set_property -dict { PACKAGE_PIN W7 IOSTANDARD LVCMOS33 } [get_ports { ad[10] }];
# ad[11] inout, Pin 19
set_property -dict { PACKAGE_PIN P3 IOSTANDARD LVCMOS33 } [get_ports { ad[11] }];

# Data bus lines
# db[0] inout, Pin 8
set_property -dict { PACKAGE_PIN B15 IOSTANDARD LVCMOS33 } [get_ports { db[0]  }];
# db[1] inout, Pin 7
set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 } [get_ports { db[1]  }];
# db[2] inout, Pin 6
set_property -dict { PACKAGE_PIN H1  IOSTANDARD LVCMOS33 } [get_ports { db[2]  }];
# db[3] inout, Pin 5
set_property -dict { PACKAGE_PIN C15 IOSTANDARD LVCMOS33 } [get_ports { db[3]  }];
# db[4] inout, Pin 4
set_property -dict { PACKAGE_PIN K3  IOSTANDARD LVCMOS33 } [get_ports { db[4]  }];
# db[5] inout, Pin 3
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports { db[5]  }];
# db[6] inout, Pin 2
set_property -dict { PACKAGE_PIN L3  IOSTANDARD LVCMOS33 } [get_ports { db[6]  }];
# db[7] inout, Pin 1
set_property -dict { PACKAGE_PIN M3  IOSTANDARD LVCMOS33 } [get_ports { db[7]  }];
# db[8] inout, Pin 9
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports { db[8]  }];
# db[9] inout, Pin 10
set_property -dict { PACKAGE_PIN J3  IOSTANDARD LVCMOS33 } [get_ports { db[9] }];
# db[10] inout, Pin 11
set_property -dict { PACKAGE_PIN J1  IOSTANDARD LVCMOS33 } [get_ports { db[10] }];
# db[11] inout, Pin 12
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports { db[11] }];

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