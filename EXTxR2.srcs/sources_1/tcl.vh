RESET
reset_run EXT1616R     
reset_run EXT2430R     
reset_run EXT2430RD    
reset_run EXT2430RI    
reset_run EXT2832R     
reset_run EXT2832R_2   
reset_run EXT4343R_1   
reset_run EXT4343R_2   
reset_run EXT4343R_3   
reset_run EXT4343RC_1  
reset_run EXT4343RC_2  
reset_run EXT4343RC_3  
reset_run EXT4343RCI_1 
reset_run EXT4343RI_2  

COMPILE
launch_runs impl_EXT1616R     -to_step write_bitstream -jobs 2
launch_runs impl_EXT2430R     -to_step write_bitstream -jobs 2
launch_runs impl_EXT2430RD    -to_step write_bitstream -jobs 2
launch_runs impl_EXT2430RI    -to_step write_bitstream -jobs 2
launch_runs impl_EXT2832R     -to_step write_bitstream -jobs 2
launch_runs impl_EXT2832R_2   -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343R_1   -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343R_2   -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343R_3   -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343RC_1  -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343RC_2  -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343RC_3  -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343RCI_1 -to_step write_bitstream -jobs 2
launch_runs impl_EXT4343RI_2  -to_step write_bitstream -jobs 2

COPY
current_run [get_runs EXT1616R    ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT2430R    ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT2430RD   ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT2430RI   ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT2832R    ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT2832R_2  ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343R_1  ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343R_2  ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343R_3  ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343RC_1 ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343RC_2 ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343RC_3 ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343RCI_1]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa
current_run [get_runs EXT4343RI_2 ]; write_hw_platform -fixed -include_bit -force -file /home/fpga0/work/EXTxR2/vitis/EXTREAM_R.xsa

