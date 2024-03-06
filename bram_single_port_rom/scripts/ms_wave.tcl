add wave sim:/xpm_memory_sprom_tb/r_result
add wave sim:/xpm_memory_sprom_tb/r_result
add wave sim:/xpm_memory_sprom_tb/sl_clk_in
add wave sim:/xpm_memory_sprom_tb/sl_rst_in
add wave -divider addr_in
add wave sim:/xpm_memory_sprom_tb/sv_tb_addra_in
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/addra_in
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/sv_addra_in
add wave -divider data_read_out
add wave sim:/xpm_memory_sprom_tb/sv_tb_data_read_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/data_read_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/sv_data_read_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/sv_shift_reg_data_out
add wave -divider vld_in
add wave sim:/xpm_memory_sprom_tb/sl_tb_dut_vld_in
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/vld_in
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/sl_bram_vld_in
add wave -divider vld_out
add wave sim:/xpm_memory_sprom_tb/sl_tb_dut_vld_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/vld_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/sl_bram_vld_out
add wave -divider rdy_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/rdy_out
add wave sim:/xpm_memory_sprom_tb/xpm_memory_sprom_inst_tb/sl_bram_rdy_out


TreeUpdate [SetDefaultTree]
configure wave -signalnamewidth 1
update