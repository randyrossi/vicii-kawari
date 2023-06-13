Large Board - Efinix Trion project files

IMPORTANT: Make sure bistream generation has SPI 4X
selected in the project's settings.  Otherwise, the
bitstream will not load since the FPGA is configured
for 4X SPI.

This design ended up being very congested and not all routing
attempts will result in a good build.  Need to sweep seeds
(and possibly optimization levels) to get a good build.

These timing violations are okay...

Path Begin    : vic_inst/vic_registers/video_ram_addr_a[2]~FF|CLK
Path End      : vic_inst/vic_registers/video_ram/video_ram_4/ram_dual_port__D$0c12|ADDRA[10]
Launch Clock  : clk_dot4x_pal (RISE)
Capture Clock : clk_dot4x_pal (RISE)
Reason        : There are at least 2 ticks of dot4x before reading the data out port. So as
                long as the slack is not excessive, it is okay.

Path Begin    : vic_inst/vic_hires_addressgen/vic_inst/video_ram_addr_b[0]~FF|CLK
Path End      : vic_inst/vic_registers/video_ram/video_ram_7/ram_dual_port__D$3g1|ADDRB[8]
Launch Clock  : clk_dot4x_pal (RISE)
Capture Clock : clk_dot4x_pal (RISE)
Reason        : There are at least 2 ticks of dot4x before reading the data out port. So as
                long as the slack is not excessive, it is okay.
--
Path Begin    : vic_inst/vic_dvi_sync/h_count[0]~FF|CLK
Path End      : vic_inst/vic_dvi_sync/line_buf_1/ram_single_port__D$1|WADDR[9]
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dot4x_pal (RISE)
Reason        : TBD
--
Path Begin    : vic_inst/vic_dvi_sync/vic_inst/pixel_color4_vga[1]~FF|CLK
Path End      : vic_inst/vic_registers/color_regs/ram_dual_port__D$12|ADDRB[0]
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dvi_pal (RISE)
Reason        : We don't need color reg changes to reflect on the next tick.
--
Path Begin    : vic_inst/vic_registers/luma_regs_addr_a[0]~FF|CLK
Path End      : vic_inst/vic_registers/luma_regs/ram_dual_port__D$1|ADDRA[11]
Launch Clock  : clk_dot4x_pal (RISE)
Capture Clock : clk_dot4x_pal (RISE)
Reason        : We don't need luma reg changes to reflect on the next tick.
--
Path Begin    : vic_inst/vic_registers/color_regs_data_in_a[0]~FF|CLK
Path End      : vic_inst/vic_registers/color_regs/ram_dual_port__D$2|WDATAA[0]
Launch Clock  : clk_dot4x_pal (RISE)
Capture Clock : clk_dot4x_pal (RISE)
Reason        : We don't need color reg changes to reflect on the next tick.
--
Path Begin    : dvi_tx0/tmds_channel1/dvi_tx0/tmds_g[X]~FF_brt_81|CLK
Path End      : dvi_tx0/serializer/tmds_internal2_1[X]~FF|D
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dvi10x_pal (RISE)
Reason        : The path end is the beginning of a synchronizer chain to handle cdc
--
Path Begin    : dvi_tx0/tmds_channel1/dvi_tx0/tmds_r[X]~FF_brt_81|CLK
Path End      : dvi_tx0/serializer/tmds_internal1_1[X]~FF|D
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dvi10x_pal (RISE)
Reason        : The path end is the beginning of a synchronizer chain to handle cdc
--
Path Begin    : dvi_tx0/tmds_channel1/dvi_tx0/tmds_b[X]~FF_brt_81|CLK
Path End      : dvi_tx0/serializer/tmds_internal0_1[X]~FF|D
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dvi10x_pal (RISE)
Reason        : The path end is the beginning of a synchronizer chain to handle cdc
--
Path Begin    : dvi_tx0/serializer/tmds_internalX_1[2]~FF|CLK
Path End      : dvi_tx0/serializer/tmds_internalX_2[2]~FF|D
Launch Clock  : clk_dvi10x_pal (RISE)
Capture Clock : clk_dvi10x_pal (RISE)
Reason        : Middle of a synchronizer chain to handle cdc
--
Path Begin    : vic_inst/vic_bus_access/char_buf_counter[3]~FF|CLK
Path End      : vic_inst/vic_bus_access/char_buf|WADDR[3]
Launch Clock  : clk_dot4x_pal (RISE)
Capture Clock : clk_dot4x_pal (RISE)
Reason        : There are many ticks between the change and when it is read.
--

These are definitely not okay...

Path Begin    : vic_inst/vic_dvi_sync/h_count[1]~FF|CLK
Path End      : vic_inst/vic_dvi_sync/h_count[1]~FF|D
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dvi_pal (RISE)

Path Begin    : vic_inst/vic_addressgen/pal_sr[N]~FF|CLK
Path End      : vic_inst/vic_addressgen/pal_sr[N]~FF|D
Launch Clock  : clk_col16x_pal (RISE)
Capture Clock : clk_col16x_pal (RISE)

Path Begin    : vic_inst/vic_addressgen/ntsc_sr[N]~FF|CLK
Path End      : vic_inst/vic_addressgen/ntsc_sr[N]~FF|D
Launch Clock  : clk_col16x_pal (RISE)
Capture Clock : clk_col16x_pal (RISE)

Path Begin    : dvi_tx0/serializer/tmds_internalX_2[N]~FF|CLK
Path End      : dvi_tx0/serializer/tmds_shiftY[N]~FF|D
Launch Clock  : clk_dvi10x_pal (RISE)
Capture Clock : clk_dvi10x_pal (RISE)

Path Begin    : vic_inst/vic_dvi_sync/ff[0]_2~FF|CLK
Path End      : vic_inst/vic_dvi_sync/ff[0]_2~FF|D
Launch Clock  : clk_dvi_pal (RISE)
Capture Clock : clk_dvi_pal (RISE)

Path Begin    : dvi_tx0/serializer/tmds_shift1[0]~FF|CLK
Path End      : dvi_tx0/serializer/dffrs_55/tmds_data_g~FF|D
Launch Clock  : clk_dvi10x_pal (RISE)
Capture Clock : clk_dvi10x_pal (RISE)

Path Begin    : vic_inst/vic_comp_sync/phaseCounter[0]_2~FF|CLK
Path End      : vic_inst/vic_comp_sync/phaseCounter[0]_2~FF|D
Launch Clock  : clk_col16x_pal (RISE)
Capture Clock : clk_col16x_pal (RISE)

