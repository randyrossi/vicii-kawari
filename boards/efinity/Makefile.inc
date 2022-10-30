
all: vicii.hex

config:
	@cat config.vh.${VARIANT} | sed "s/VERSION_MAJOR.*/VERSION_MAJOR 8'd${VERSION_MAJOR}/g" | sed "s/VERSION_MINOR.*/VERSION_MINOR 8'd${VERSION_MINOR}/g" > ../../hdl/config.vh

vicii.hex:  config
	efx_map --project "vicii" --root "top" --write-efx-verilog "outflow/vicii.map.v" --write-premap-module "outflow/vicii.elab.vdb" --binary-db "vicii.vdb" --device "${FPGA}" --family "Trion" --mode "speed" --max_ram "-1" --max_mult "-1" --infer-clk-enable "3" --infer-sync-set-reset "1" --fanout-limit "0" --bram_output_regs_packing "1" --retiming "1" --seq_opt "1" --blast_const_operand_adders "1" --operator-sharing "0" --optimize-adder-tree "0" --mult_input_regs_packing "1" --mult_output_regs_packing "1" --veri_option "verilog_mode=verilog_2k,vhdl_mode=vhdl_2008" --work-dir "work_syn" --output-dir "outflow" --project-xml "vicii.xml" --I "../../hdl"
	${EFINITY_HOME}/bin/python3  "${EFINITY_HOME}/scripts/efx_run_pt.py"  "vicii"  "Trion"  "${FPGA}"
	efx_pnr --circuit "vicii" --family "Trion" --device "${FPGA}" --operating_conditions "${TIMING}" --pack --place --route --vdb_file "work_syn/vicii.vdb" --use_vdb_file "on" --place_file "outflow/vicii.place" --route_file "outflow/vicii.route" --sdc_file "vicii.sdc" --sync_file "outflow/vicii.interface.csv" --optimization_level "TIMING_3" --seed "1" --work_dir "work_pnr" --output_dir "outflow" --timing_analysis "on" --load_delay_matrix
	efx_pgm --source "work_pnr/vicii.lbf" --dest "build/kawari_multiboot_${VARIANT}_${VERSION_MAJOR}.${VERSION_MINOR}.hex" --device "${FPGA}" --family "Trion" --periph "outflow/vicii.lpf" --interface_designer_settings "outflow/vicii_or.ini" --enable_external_master_clock "off" --oscillator_clock_divider "DIV4" --active_capture_clk_edge "posedge" --spi_low_power_mode "on" --io_weak_pullup "on" --enable_roms "smart" --mode "active" --width "4" --release_tri_then_reset "on"

clean:
	rm -rf outflow ip work_pnr work_pt work_syn vicii.vdb
