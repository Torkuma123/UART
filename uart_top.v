module uart_top (
    input wire clk,
    input wire rst,
    input wire write,
    input wire read,
    input wire rx,
    input wire [7:0] tx_data, // Transmitted data
    output wire tx,
    output wire txrdy,
    output wire rxrdy,
    output wire parityerr,
    output wire framingerr,
    output wire overrun,
    output wire [7:0] rx_data  // Received data
);

    // Instantiate UART Transmitter
    UART_Transmitter transmitter_inst (
        .clk(clk),
        .rst(rst),
        .write(write),
        .data_in(tx_data),   // Corrected .data to .tx_data
        .tx(tx),
        .txrdy(txrdy)
    );

    // Instantiate UART Receiver
    UART_Receiver receiver_inst (
        .clk(clk),
        .rst(rst),
        .read(read),
        .data(rx_data),   // Receiver uses rx_data
        .rx(rx),
        .rxrdy(rxrdy),
        .parityerr(parityerr),
        .framingerr(framingerr),
        .overrun(overrun)
    );

endmodule

