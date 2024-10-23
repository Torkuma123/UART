module UART_Receiver (
    input wire clk,
    input wire rst,
    input wire rx,            // Serial input line
    input wire read,          // Read signal (to clear rxrdy)
    output reg [7:0] data,    // Received data
    output reg rxrdy,         // Receiver ready flag
    output reg parityerr,     // Parity error flag
    output reg framingerr,    // Framing error flag
    output reg overrun        // Overrun error flag
);
    parameter BAUD_RATE = 9600;
    parameter CLOCK_FREQ = 50000000;
    localparam BAUD_TICK = CLOCK_FREQ / BAUD_RATE;

    localparam RX_IDLE  = 2'b00, 
               RX_START = 2'b01, 
               RX_DATA  = 2'b10, 
               RX_PARITY = 2'b11,  
               RX_STOP  = 3'b100;

    reg [2:0] rx_state;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_count;   // Explicit 4-bit width to match target
    reg [15:0] baud_count; // Explicit 16-bit width to match target
    reg parity_bit;
    reg rx_prev;

    // Receiver FSM logic
    always @(posedge clk) begin
        if (rst) begin
            rx_state <= RX_IDLE;
            rx_shift_reg <= 8'b0; // Initialize shift register
            rxrdy <= 1'b0;
            bit_count <= 4'b0;   // Explicit 4-bit reset
            baud_count <= 16'b0; // Explicit 16-bit reset
            framingerr <= 1'b0;
            parityerr <= 1'b0;
            overrun <= 1'b0;
        end else begin
            rx_prev <= rx;

            case (rx_state)
                RX_IDLE: begin
                    if (rx == 1'b0 && rx_prev == 1'b1) begin  // Start bit detection
                        baud_count <= BAUD_TICK[15:0] / 2;  // Sample in the middle of the bit
                        rx_state <= RX_START;
                    end
                end

                RX_START: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        baud_count <= 16'b0;
                        rx_state <= RX_DATA;
                        bit_count <= 4'b0;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_DATA: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        baud_count <= 16'b0;
                        rx_shift_reg[bit_count] <= rx;
                        bit_count <= bit_count + 1;
                        if (bit_count == 8) begin
                            rx_state <= RX_PARITY;
                        end
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_PARITY: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        baud_count <= 16'b0;
                        parity_bit <= rx;
                        if (parity_bit != ^rx_shift_reg) begin
                            parityerr <= 1'b1;  // Parity error detected
                        end else begin
                            parityerr <= 1'b0;  // No parity error
                        end
                        rx_state <= RX_STOP;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_STOP: begin
                    if (baud_count == BAUD_TICK[15:0]) begin
                        if (rx != 1'b1) begin  // Checking for framing error
                            framingerr <= 1'b1;  // Framing error
                        end else begin
                            framingerr <= 1'b0;
                        end

                        if (rxrdy) begin  // Check for overrun error
                            overrun <= 1'b1;  // Overrun error if previous data not read
                        end else begin
                            overrun <= 1'b0;
                        end
                        data <= rx_shift_reg;
                        rxrdy <= 1'b1;
                        rx_state <= RX_IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end
            endcase

            // Clear rxrdy when data is read
            if (rxrdy && read) begin
                rxrdy <= 1'b0;
            end
        end
    end
endmodule



/*
module UART_Receiver (
    input wire clk,
    input wire rst,
    input wire rx,            // Serial input line
    input wire read,          // Read signal (to clear rxrdy)
    output reg [7:0] data,    // Received 8-bit data
    output reg rxrdy,         // Receiver ready flag
    output reg parityerr,     // Parity error flag
    output reg framingerr,    // Framing error flag
    output reg overrun        // Overrun error flag
);
    parameter BAUD_RATE = 9600;
    parameter CLOCK_FREQ = 50000000;
    localparam BAUD_TICK = CLOCK_FREQ / BAUD_RATE;

    localparam RX_IDLE  = 2'b00, 
               RX_START = 2'b01, 
               RX_DATA  = 2'b10, 
               RX_PARITY = 2'b11,  
               RX_STOP  = 3'b100;

    reg [2:0] rx_state;
    reg [7:0] rx_shift_reg;
    reg [3:0] bit_count;
    reg [15:0] baud_count;
    reg parity_bit;

    reg rx_prev;
    
    // Receiver FSM logic
    always @(posedge clk) begin
        if (rst) begin
            rx_state <= RX_IDLE;
            rx_shift_reg <= 8'b0;  // Initialize shift register
            rxrdy <= 1'b0;
            bit_count <= 0;
            baud_count <= 0;
            framingerr <= 1'b0;
            parityerr <= 1'b0;
            overrun <= 1'b0;
        end else begin
            rx_prev <= rx;

            case (rx_state)
                RX_IDLE: begin
                    if (rx == 1'b0 && rx_prev == 1'b1) begin  // Start bit detection
                        baud_count <= BAUD_TICK / 2;  // Sample in the middle of the bit
                        rx_state <= RX_START;
                    end
                end

                RX_START: begin // Check start bit
                    if (baud_count == BAUD_TICK) begin
                        baud_count <= 0;
                        rx_state <= RX_DATA;
                        bit_count <= 0;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_DATA: begin // Read the 8 data bits
                    if (baud_count == BAUD_TICK) begin
                        baud_count <= 0;
                        rx_shift_reg[bit_count] <= rx;
                        bit_count <= bit_count + 1;
                        if (bit_count == 8) begin
                            rx_state <= RX_PARITY;
                        end
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_PARITY: begin // Check for parity error
                    if (baud_count == BAUD_TICK) begin
                        baud_count <= 0;
                        parity_bit <= rx;
                        if (parity_bit != ^rx_shift_reg) begin
                            parityerr <= 1'b1;  // Parity error detected
                        end else begin
                            parityerr <= 1'b0;  // No parity error
                        end
                        rx_state <= RX_STOP;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_STOP: begin // Check stop bit and framing error
                    if (baud_count == BAUD_TICK) begin
                        if (rx != 1'b1) begin  // Framing error: Stop bit must be 1
                            framingerr <= 1'b1;
                        end else begin
                            framingerr <= 1'b0;
                        end
                        
                        if (rxrdy) begin
                            overrun <= 1'b1;  // Overrun error if data not read
                        end else begin
                            overrun <= 1'b0;
                        end
                        
                        data <= rx_shift_reg;
                        rxrdy <= 1'b1;
                        rx_state <= RX_IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

            endcase

            // Clear rxrdy when data is read
            if (rxrdy && read) begin
                rxrdy <= 1'b0;
            end
        end
    end
endmodule
*/