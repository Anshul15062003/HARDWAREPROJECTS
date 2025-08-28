`timescale 1ns / 1ps


module pmod_keypad(
    input clk,                // system clock 100MHz
    input reset,              // system reset
    input [3:0] row,          // row inputs from keypad (active low)
    
    
    output reg [3:0] col,     // column outputs to keypad (active low)
    output reg [3:0] key,     // current key value in hex (0-F)
    output reg key_valid      // indicates a valid key press

    );
    
    
    // Parameters
    localparam DEBOUNCE_TIME = 10000;   // 0.1ms at 100MHz
    localparam SETTLE_TIME = 100;       // 1?s at 100MHz
    
    // State definitions
    localparam SCAN_COL0        = 3'd0;
    localparam SCAN_COL1        = 3'd1;
    localparam SCAN_COL2        = 3'd2;
    localparam SCAN_COL3        = 3'd3;
    localparam WAIT_RELEASE     = 3'd4;
    
    // Internal signals
    reg [2:0]   state;
    reg [19:0]  counter;
    reg [3:0]   prev_row;
    reg         key_detected;
    reg [7:0]   stable_count;  // Added to count stable readings
    
    // State machine logic
    always @(posedge clk or posedge reset) 
    begin 
        if (reset) begin
            state <= SCAN_COL0;
            counter <= 0;
            col <= 4'b1111;
            key <= 4'h0;
            key_valid <= 1'b0;
            prev_row <= 4'b1111;
            key_detected <= 1'b0;
            stable_count <= 0;
        end else begin
            // Default values
            key_valid <= 1'b0;
    
            case (state)
                SCAN_COL0: begin
                    col <= 4'b0111;  // Activate column 0 (active low)
    
                    if (counter < SETTLE_TIME) begin
                        // Wait for column signals to settle
                        counter <= counter + 1;
                    end else if (counter < DEBOUNCE_TIME) begin
                        // Sample row values for debounce
                        counter <= counter + 1;
    
                        // Check if a key is pressed
                        if (row != 4'b1111) begin
                            if (row == prev_row) begin
                                // Row is stable, increment counter
                                stable_count <= stable_count + 1;
    
                                // If stable for enough cycles, mark as detected
                                if (stable_count >= 8'd10) begin
                                    key_detected <= 1'b1;
    
                                    // Decode key based on row pattern
                                    case (row)
                                        4'b0111: key <= 4'hD;  // Key "D"
                                        4'b1011: key <= 4'hC;  // Key "C"
                                        4'b1101: key <= 4'hB;  // Key "B"
                                        4'b1110: key <= 4'hA;  // Key "A"
                                        default: key_detected <= 1'b0;
                                    endcase
                                end
                            end else begin
                                // Row changed, reset stable counter
                                stable_count <= 0;
                            end
    
                            // Update previous row
                            prev_row <= row;
                        end else begin
                            // No key pressed, reset stable counter
                            stable_count <= 0;
                            prev_row <= row;
                        end
                    end else begin
                        // Move to next column or handle key press
                        counter <= 0;
                        stable_count <= 0;
    
                        if (key_detected) begin
                            key_valid <= 1'b1;  // Validate the key
                            state <= WAIT_RELEASE;
                        end else begin
                            state <= SCAN_COL1;
                        end
                    end
                end
    
                SCAN_COL1: begin
                    col <= 4'b1011;  // Activate column 1
    
                    if (counter < SETTLE_TIME) begin
                        counter <= counter + 1;
                    end else if (counter < DEBOUNCE_TIME) begin
                        counter <= counter + 1;
    
                        if (row != 4'b1111) begin
                            if (row == prev_row) begin
                                stable_count <= stable_count + 1;
    
                                if (stable_count >= 8'd10) begin
                                    key_detected <= 1'b1;
    
                                    case (row)
                                        4'b0111: key <= 4'hE;  // Key "E"
                                        4'b1011: key <= 4'h9;  // Key "9"
                                        4'b1101: key <= 4'h6;  // Key "6"
                                        4'b1110: key <= 4'h3;  // Key "3"
                                        default: key_detected <= 1'b0;
                                    endcase
                                end
                            end else begin
                                stable_count <= 0;
                            end
    
                            prev_row <= row;
                        end else begin
                            stable_count <= 0;
                            prev_row <= row;
                        end
                    end else begin
                        counter <= 0;
                        stable_count <= 0;
    
                        if (key_detected) begin
                            key_valid <= 1'b1;
                            state <= WAIT_RELEASE;
                        end else begin
                            state <= SCAN_COL2;
                        end
                    end
                end
    
                SCAN_COL2: begin
                    col <= 4'b1101;  // Activate column 2
    
                    if (counter < SETTLE_TIME) begin
                        counter <= counter + 1;
                    end else if (counter < DEBOUNCE_TIME) begin
                        counter <= counter + 1;
    
                        if (row != 4'b1111) begin
                            if (row == prev_row) begin
                                stable_count <= stable_count + 1;
    
                                if (stable_count >= 8'd10) begin
                                    key_detected <= 1'b1;
    
                                    case (row)
                                        4'b0111: key <= 4'hF;  // Key "F"
                                        4'b1011: key <= 4'h8;  // Key "8"
                                        4'b1101: key <= 4'h5;  // Key "5"
                                        4'b1110: key <= 4'h2;  // Key "2"
                                        default: key_detected <= 1'b0;
                                    endcase
                                end
                            end else begin
                                stable_count <= 0;
                            end
    
                            prev_row <= row;
                        end else begin
                            stable_count <= 0;
                            prev_row <= row;
                        end
                    end else begin
                        counter <= 0;
                        stable_count <= 0;
    
                        if (key_detected) begin
                            key_valid <= 1'b1;
                            state <= WAIT_RELEASE;
                        end else begin
                            state <= SCAN_COL3;
                        end
                    end
                end
    
                SCAN_COL3: begin
                    col <= 4'b1110;  // Activate column 3
    
                    if (counter < SETTLE_TIME) begin
                        counter <= counter + 1;
                    end else if (counter < DEBOUNCE_TIME) begin
                        counter <= counter + 1;
    
                        if (row != 4'b1111) begin
                            if (row == prev_row) begin
                                stable_count <= stable_count + 1;
    
                                if (stable_count >= 8'd10) begin
                                    key_detected <= 1'b1;
    
                                    case (row)
                                        4'b0111: key <= 4'h0;  // Key "0"
                                        4'b1011: key <= 4'h7;  // Key "7"
                                        4'b1101: key <= 4'h4;  // Key "4"
                                        4'b1110: key <= 4'h1;  // Key "1"
                                        default: key_detected <= 1'b0;
                                    endcase
                                end
                            end else begin
                                stable_count <= 0;
                            end
    
                            prev_row <= row;
                        end else begin
                            stable_count <= 0;
                            prev_row <= row;
                        end
                    end else begin
                        counter <= 0;
                        stable_count <= 0;
    
                        if (key_detected) begin
                            key_valid <= 1'b1;
                            state <= WAIT_RELEASE;
                        end else begin
                            state <= SCAN_COL0;  // Complete cycle, back to first column
                            key_detected <= 1'b0;
                        end
                    end
                end
    
                WAIT_RELEASE: begin
                    // Keep driving the current column active
                    // Wait until button is released
                    if (row == 4'b1111) begin
                        counter <= counter + 1;
                        // Additional debounce for release
                        if (counter >= DEBOUNCE_TIME) begin
                            state <= SCAN_COL0;
                            counter <= 0;
                            key_detected <= 1'b0;
                        end
                    end else begin
                        counter <= 0;  // Reset counter if button is still pressed
                    end
                end
    
                default: state <= SCAN_COL0;
            endcase
        end
    end
    


endmodule
