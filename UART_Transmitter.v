module UART_Transmitter (
    input wire clk,
    input wire rst,
    input wire write,         // Write signal to trigger transmission
    input wire [7:0] data_in, // Data to be transmitted
    output reg tx,            // Serial output line
    output reg txrdy          // Transmitter ready flag
);
    parameter BAUD_RATE = 9600;
    parameter CLOCK_FREQ = 50000000;
    localparam BAUD_TICK = CLOCK_FREQ / BAUD_RATE;

    localparam TX_IDLE  = 3'b000, 
               TX_START = 3'b001, 
               TX_DATA  = 3'b010, 
               TX_PARITY = 3'b011,   // state for parity during transmission
               TX_STOP  = 3'b100;    // stop bit state in transmission

    reg [2:0] tx_state;
    reg [7:0] tx_shift_reg;
    reg [3:0] bit_count;   // Explicit 4-bit width to match target
    reg [15:0] baud_count; // Explicit 16-bit width to match target
    wire parity_bit;

    // Parity generation
    assign parity_bit = ^data_in;  // Even parity generator

    // Transmitter FSM logic
    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1; // TX line will be high when idle
            tx_shift_reg <= 8'b0; // Initialize shift register
            txrdy <= 1'b1; // Set ready to true
            tx_state <= TX_IDLE;
            baud_count <= 16'b0; // Explicit 16-bit reset
            bit_count <= 4'b0;   // Explicit 4-bit reset
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (write && txrdy) begin
                        tx_shift_reg <= data_in;
                        txrdy <= 1'b0;
                        tx_state <= TX_START;
                    end
                end

                TX_START: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        tx <= 1'b0;  // Start bit
                        baud_count <= 16'b0;
                        tx_state <= TX_DATA;
                        bit_count <= 4'b0;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                TX_DATA: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        tx <= tx_shift_reg[bit_count];
                        baud_count <= 16'b0;
                        bit_count <= bit_count + 1;
                        if (bit_count == 8) begin
                            tx_state <= TX_PARITY;  // After 8 bits, send the parity
                        end
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                TX_PARITY: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        tx <= parity_bit;  // Send the parity bit
                        baud_count <= 16'b0;
                        tx_state <= TX_STOP;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                TX_STOP: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        tx <= 1'b1;  // Stop bit
                        baud_count <= 16'b0;
                        txrdy <= 1'b1;
                        tx_state <= TX_IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end
            endcase
        end
    end
endmodule

