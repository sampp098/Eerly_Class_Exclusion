onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_pu/clk
add wave -noupdate /tb_pu/rstn
add wave -noupdate /tb_pu/start
add wave -noupdate /tb_pu/ready
add wave -noupdate -radix unsigned /tb_pu/prediction
add wave -noupdate /tb_pu/U0/FSMD_0/state_reg
add wave -noupdate /tb_pu/U0/FSMD_0/fsmd_PE_acc_clear_output
add wave -noupdate /tb_pu/U0/FSMD_0/fsmd_PE_acc_enable_output
add wave -noupdate -color Cyan -radix unsigned /tb_pu/U0/FSMD_0/segment_idx_reg
add wave -noupdate -color Cyan -radix unsigned /tb_pu/U0/FSMD_0/slice_idx_reg
add wave -noupdate -color Cyan -radix unsigned /tb_pu/U0/FSMD_0/fsmd_MEM_addr_slice_output
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(0)/HD_PE_i/PE_slice_input_QHV
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(0)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(1)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(2)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(3)/HD_PE_i/PE_slice_input_BHV
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(0)/HD_PE_i/PE_HamDist_output
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(1)/HD_PE_i/PE_HamDist_output
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(2)/HD_PE_i/PE_HamDist_output
add wave -noupdate -color Yellow -radix hexadecimal /tb_pu/U0/gen_PE(3)/HD_PE_i/PE_HamDist_output
add wave -noupdate -radix hexadecimal /tb_pu/U0/findMax_0/findmax_data_input
add wave -noupdate -radix unsigned /tb_pu/U0/findMax_0/findmax_maxIdx_output
add wave -noupdate /tb_pu/U0/FSMD_0/active_classes_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {7839 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 318
configure wave -valuecolwidth 89
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
WaveRestoreZoom {0 ps} {105 ns}
