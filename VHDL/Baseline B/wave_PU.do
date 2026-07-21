onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_pu/clk
add wave -noupdate /tb_pu/U0/PU_predicted_class_idx_output
add wave -noupdate -color Cyan -radix hexadecimal /tb_pu/U0/gen_PE(0)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Cyan -radix hexadecimal /tb_pu/U0/gen_PE(1)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Cyan -radix hexadecimal /tb_pu/U0/gen_PE(2)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Cyan -radix hexadecimal /tb_pu/U0/gen_PE(0)/HD_PE_i/PE_slice_input_QHV
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(0)/HD_PE_i/PE_HamDist_output
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(1)/HD_PE_i/PE_HamDist_output
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(2)/HD_PE_i/PE_HamDist_output
add wave -noupdate /tb_pu/U0/findMin_0/findmin_active_input
add wave -noupdate -radix hexadecimal /tb_pu/U0/findMin_0/findmin_data_input
add wave -noupdate -radix unsigned /tb_pu/U0/findMin_0/findmin_minIdx_output
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1297 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 372
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {21 ns}
