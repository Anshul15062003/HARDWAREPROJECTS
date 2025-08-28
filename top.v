`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 12:17:00
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
    input  clock, //100MHz onboard clock
    input  reset,
    input  [31:0] value_to_display, // Your 32-bit input
    //oled interface
    output oled_spi_clk,
    output oled_spi_data,
    output oled_vdd,
    output oled_vbat,
    output oled_reset_n,
    output oled_dc_n
);
    
    reg [1:0] state;
    reg [7:0] sendData;
    reg sendDataValid;
    integer byteCounter;
    wire sendDone;
    
    // For hexadecimal display (8 characters)
    reg [7:0] hex_chars [0:7];
    
    localparam IDLE = 'd0,
               SEND = 'd1,
               DONE = 'd2;
    
    // Convert 32-bit value to 8 hexadecimal ASCII characters
    always @(*) begin
        // Convert each 4-bit nibble to hex ASCII
        hex_chars[0] = nibble_to_ascii(value_to_display[31:28]);
        hex_chars[1] = nibble_to_ascii(value_to_display[27:24]);
        hex_chars[2] = nibble_to_ascii(value_to_display[23:20]);
        hex_chars[3] = nibble_to_ascii(value_to_display[19:16]);
        hex_chars[4] = nibble_to_ascii(value_to_display[15:12]);
        hex_chars[5] = nibble_to_ascii(value_to_display[11:8]);
        hex_chars[6] = nibble_to_ascii(value_to_display[7:4]);
        hex_chars[7] = nibble_to_ascii(value_to_display[3:0]);
    end
    
    // Function to convert 4-bit nibble to ASCII hex character
    function [7:0] nibble_to_ascii;
        input [3:0] nibble;
        begin
            if (nibble < 10)
                nibble_to_ascii = 8'h30 + nibble; // '0'-'9'
            else
                nibble_to_ascii = 8'h41 + (nibble - 10); // 'A'-'F'
        end
    endfunction
    
    always @(posedge clock) begin
        if(reset) begin
            state <= IDLE;
            byteCounter <= 0;
            sendDataValid <= 1'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(!sendDone) begin
                        sendData <= hex_chars[byteCounter];
                        sendDataValid <= 1'b1;
                        state <= SEND;
                    end
                end
                SEND: begin
                    if(sendDone) begin
                        sendDataValid <= 1'b0;
                        if(byteCounter < 7) begin
                            byteCounter <= byteCounter + 1;
                            state <= IDLE;
                        end
                        else begin
                            state <= DONE;
                        end
                    end
                end
                DONE: begin
                    state <= DONE;
                end
            endcase
        end
    end
    
    oledControl OC(
        .clock(clock), //100MHz onboard clock
        .reset(reset),
        //oled interface
        .oled_spi_clk(oled_spi_clk),
        .oled_spi_data(oled_spi_data),
        .oled_vdd(oled_vdd),
        .oled_vbat(oled_vbat),
        .oled_reset_n(oled_reset_n),
        .oled_dc_n(oled_dc_n),
        //
        .sendData(sendData),
        .sendDataValid(sendDataValid),
        .sendDone(sendDone)
    );    
    
endmodule

