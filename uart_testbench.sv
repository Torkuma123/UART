

`timescale 1ns / 1ps 
module UART_TESTBENCH;
	 
  // Testbench uses a 10 MHz clock
  // Want to interface to 9600 baud UART
  // 10000000 / 9600 = 1042 Clocks Per Bit.

	reg  clk =0 ;             
	reg  rst = 0 ;              
	reg  [7:0] data_in ;    
	reg  tx_start ;   
	reg  rx = 1 ;     
	wire tx;              
	wire tx_done;         
	wire [7:0] data_out; 
	wire crc_error;  
     

  
     // Clock and Baud rate parameters
    parameter CLK_PERIOD = 100; // 10 MHz clock  localparam used in submodule clks_per_bit = 1042; Baud rate tick for 9600 baud
   
    parameter c_BIT_PERIOD = 104167;
	 
   uart_top UUT(
	.clk(clk),               // Connects the system clock to the transmitter
	.rst(rst),               // Connects the reset signal to the transmitter
	.data_in(data_in),       // Connects the 8-bit data input to the transmitter
	.tx_start(tx_start),     // Connects the transmission start signal to the transmitter
	.tx(tx),                 // Transmitter output line (serial data out)
	.tx_done(tx_done),        // Transmission complete indicator
   .rx(rx),                 // Connects the serial data input line to the receiver
	.data_out(data_out),     // Outputs the 8-bit parallel data received
	.crc_error(crc_error)   // Sets the CRC error flag if an error is detected in received data
	);
   

 // Generate a 10 MHz clock
    always #(CLK_PERIOD / 2) clk = ~clk;

   
 
  // Takes in input byte and serializes it 
  task UART_WRITE_BYTE;
    input [11:0] i_Data;
    integer     ii;
    begin
       
      // Send Start Bit
      rx <= 1'b0;
      #(c_BIT_PERIOD);
      
        
      // Send Data Byte
      for (ii=0; ii<11; ii=ii+1)
        begin
          rx <= i_Data[ii];
          #(c_BIT_PERIOD);
        end
        
      // Send Stop Bit
      rx <= 1'b1;
      #(c_BIT_PERIOD);
     end
  endtask 
   
  // Main Testing:
  initial
    begin
       
      // Tell UART to send a command (exercise Tx)
      @(posedge clk);
      @(posedge clk);
      tx_start <= 1'b1;
      // For 8'b3F (binary 0011 1111): CRC = 4'b0101 (or decimal 5) for wave form verification on tx wire
      data_in <= 8'h3F;
      @(posedge clk);
      tx_start <= 1'b0;
      @(posedge tx_done);
        
      // Send a command to the UART (exercise Rx)
      @(posedge clk);
      //	For 8'hAF (binary 1010 1111): CRC = 4'b1010 (or decimal 10) for wave form verification on rx wire
      UART_WRITE_BYTE(12'b101010101111);	
      //  UART_WRITE_BYTE(12'b100000111111);	
    
    end 
endmodule
