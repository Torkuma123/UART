
`timescale 1ns / 1ps
module uart_testbench;

    // Testbench signals
    reg clk;
    reg rst;
    reg write;
    reg read;
    reg [7:0] data_in;
    wire [7:0] data_out;
    reg rx; 
    wire tx;
    wire txrdy;
    wire rxrdy;
    wire parityerr;
    wire framingerr;
    wire overrun;

    // Clock and Baud rate parameters
    localparam CLK_PERIOD = 20;        // 50 MHz clock
    localparam BAUD_TICK = 5208;       // Baud rate tick for 9600 baud
    
    // Clock generation
    always #(CLK_PERIOD / 2) clk = ~clk;

    // Instantiate the UART Top Module
    UART_Top uut (
        .clk(clk),
        .rst(rst),
        .write(write),
        .read(read),
        .tx_data(data_in),
        .rx_data(data_out),
        .rx(rx),
        .tx(tx),
        .txrdy(txrdy),
        .rxrdy(rxrdy),
        .parityerr(parityerr),
        .framingerr(framingerr),
        .overrun(overrun)
    );

    // Test process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        write = 0;
        read = 0;
        data_in = 8'b0;
        rx = 1'b1;  // Idle state of rx (high)

        // Reset the system
        #50;
        rst = 0;
        #50;
        rst = 1;

        // Start simple transmission
        test_simple_transmission(8'h55);  // Send simple byte 0x55 (01010101)
        #5000;

        // End of simulation
        $finish;
    end

    // Task to simulate a simple data transmission
    task test_simple_transmission(input [7:0] data);
        begin
            $display("Simple transmission with data: %h", data);
            
            write = 1;
            data_in = data;
            #CLK_PERIOD;
            write = 0;

            // Wait for transmission to complete
            wait (txrdy == 1);
            
            // Simulate RX data (simple loopback without errors)
            simulate_rx_data(data, 1'b0, 1'b1);  // Correct parity and stop bits

            // Wait for RX ready signal
            wait (rxrdy == 1);
            
            // Read the received data
            read = 1;
            #CLK_PERIOD;
            read = 0;
            $display("Received data: %h", data_out);

            // Self-check: Compare transmitted and received data
            if (data_out !== data) 
                $display("ERROR: Mismatch between sent and received data. Sent: %h, Received: %h", data, data_out);
            else
                $display("Data received successfully.");

            #100;
        end
    endtask

    // Task to simulate RX data reception (without errors)
    task automatic simulate_rx_data(input [7:0] data_in, input parity, input stop);
        integer i;
        begin
            rx = 0;  // Start bit
            #BAUD_TICK;

            // Send 8 bits of data
            for (i = 0; i < 8; i = i + 1) begin
                rx = data_in[i];
                #BAUD_TICK;
            end

            // Parity bit
            rx = parity;
            #BAUD_TICK;

            // Stop bit (usually high)
            rx = stop;
            #BAUD_TICK;
        end
    endtask

    // Dump waveform to view in EPWave or similar tools
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_testbench);
    end
endmodule
