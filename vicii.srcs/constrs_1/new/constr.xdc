# External clock 12Mhz
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {sys_clock}];

#set_output_delay -clock [get_clocks x_clk] -min -add_delay 0.000 [get_ports clk_colref]
#set_output_delay -clock [get_clocks x_clk] -max -add_delay 0.000 [get_ports clk_colref]

# Voltage config
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

# Board Pins

# M3 = Pin01
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports clk_colref]

# L3 = Pin02
set_property -dict {PACKAGE_PIN L3 IOSTANDARD LVCMOS33} [get_ports clk_phi]

# A16 = Pin03
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports { rst }];

# K3 = Pin04
set_property -dict { PACKAGE_PIN K3 IOSTANDARD LVCMOS33 } [get_ports { cSync  }];

# L17 = Internal clock pin 
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; 

# V8 = 48 = RED0
set_property -dict { PACKAGE_PIN V8 IOSTANDARD LVCMOS33 } [get_ports { red[0] }];

# U8 = 47 = RED1
set_property -dict { PACKAGE_PIN U8 IOSTANDARD LVCMOS33 } [get_ports { red[1] }];

# U3 = 44 = GREEN0
set_property -dict { PACKAGE_PIN U3 IOSTANDARD LVCMOS33 } [get_ports { green[0] }];

# W6 = 43 = GREEN1
set_property -dict { PACKAGE_PIN W6 IOSTANDARD LVCMOS33 } [get_ports { green[1] }];

# W4 = 40 = BLUE0
set_property -dict { PACKAGE_PIN W4 IOSTANDARD LVCMOS33 } [get_ports { blue[0] }];

# V5 = 39 = BLUE1
set_property -dict { PACKAGE_PIN V5 IOSTANDARD LVCMOS33 } [get_ports { blue[1] }];
