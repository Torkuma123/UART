onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /UART_TESTBENCH/CLK_PERIOD
add wave -noupdate /UART_TESTBENCH/c_BIT_PERIOD
add wave -noupdate /UART_TESTBENCH/clk
add wave -noupdate /UART_TESTBENCH/rst
add wave -noupdate /UART_TESTBENCH/data_in
add wave -noupdate /UART_TESTBENCH/tx_start
add wave -noupdate /UART_TESTBENCH/rx
add wave -noupdate /UART_TESTBENCH/tx
add wave -noupdate /UART_TESTBENCH/tx_done
add wave -noupdate /UART_TESTBENCH/data_out
add wave -noupdate /UART_TESTBENCH/crc_error
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 200
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {31742492672 ps}
