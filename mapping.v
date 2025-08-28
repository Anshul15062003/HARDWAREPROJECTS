`timescale 1ns / 1ps



module mapping (
    input clk,
    input reset,

    input [3:0] key,
    input       key_valid,


    output reg [1:0]  operation,
    output reg [31:0] angle,
    output reg [21:0] x_start,
    output reg [21:0] y_start

);
    // FSM states
    localparam INPUT_MODE = 2'b00;
    localparam CALC_MODE  = 2'b01;

    // input target states -  register we're currently filling
    localparam TARGET_ANGLE     = 2'b00;
    localparam TARGET_X_START   = 2'b01;
    localparam TARGET_Y_START   = 2'b10;
    localparam TARGET_OPERATION = 2'b11;

    // operations
    localparam NO_OP    = 2'b00;
    localparam OP_EXP   = 2'b01;
    localparam OP_LN    = 2'b10;
    localparam OP_LOG2  = 2'b11;  

    // internal registers
    reg [1:0] state;
    reg [1:0] input_target;
    reg [4:0] digit_duo_count;

    // key assignments
    localparam KEY_ENTER        = 4'hE;
    localparam KEY_BACKSPACE    = 4'hB;
    localparam KEY_CLEAR        = 4'hC;
    localparam KEY_CALCULATE    = 4'hD;
    localparam KEY_ESCAPE       = 4'hA;   

    // handle key presses
    always @(posedge clk or posedge reset) 
    begin 
        if (reset) begin
            state <= INPUT_MODE; 
            input_target <= TARGET_ANGLE;
            operation <= NO_OP;
            angle   <= 32'd0;
            x_start <= 22'd0;
            y_start <= 22'd0;

            digit_duo_count <= 5'd0;
        end
        else begin
            
            if (key_valid) begin
                case (state)
                    INPUT_MODE: begin
                        case (key)
                            // digits 0-3 which are mapped to 00, 01, 10, 11 resp.
                            4'h0, 4'h1, 4'h2, 4'h3: begin
                                case (input_target)
                                    TARGET_ANGLE: begin
                                        if (digit_duo_count < 16) begin
                                            // shift existing value left by 2 bits and add new 2-bit value
                                            angle <= (angle << 2) | {30'b0, key[1:0]};
                                            digit_duo_count <= digit_duo_count + 1;
                                            end
                                        end
                                    
                                    TARGET_X_START: begin
                                        if (digit_duo_count < 11) begin
                                            // shift existing value left by 2 bits and add new 2-bit value
                                            x_start <= (x_start << 2) | {20'b0, key[1:0]};
                                            digit_duo_count <= digit_duo_count + 1;
                                            end
                                    end
                                    
                                    TARGET_Y_START: begin
                                        if (digit_duo_count < 11) begin
                                            // shift existing value left by 2 bits and add new 2-bit value
                                            y_start <= (y_start << 2) | {20'b0, key[1:0]};
                                            digit_duo_count <= digit_duo_count + 1;
                                        end
                                    end
                                    
                                    TARGET_OPERATION: begin
                                        if (!digit_duo_count) begin
                                            // set operation directly from key value
                                            operation <= key[1:0];
                                            digit_duo_count <= digit_duo_count + 1;
                                        end
                                    end
                                endcase
                            end
                            
                            // enter key (i.e 4'hE) - move to next input target
                            KEY_ENTER: begin
                                case (input_target)
                                    TARGET_ANGLE: begin
                                        if (digit_duo_count > 0) begin
                                            input_target <= TARGET_X_START;
                                            digit_duo_count <= 4'd0;
                                        end
                                    end
                                    
                                    TARGET_X_START: begin
                                        if (digit_duo_count > 0) begin
                                            input_target <= TARGET_Y_START;
                                            digit_duo_count <= 4'd0;
                                        end
                                    end
                                    
                                    TARGET_Y_START: begin
                                        if (digit_duo_count > 0) begin
                                            input_target <= TARGET_OPERATION;
                                            digit_duo_count <= 4'd0;
                                        end
                                    end
                                    
                                    TARGET_OPERATION: begin
                                        if (digit_duo_count) begin
                                            // entered all parameters, go back to angle for potential new calculation
                                            input_target <= TARGET_ANGLE;
                                            digit_duo_count <= 4'd0;
                                        end
                                    end
                                endcase
                            end
                            
                            // backspace key (i.e 4'hB) - remove the latest entered digit duo
                            KEY_BACKSPACE: begin
                                if (digit_duo_count > 0) begin
                                    case (input_target)
                                        TARGET_ANGLE: begin
                                            // shift right by 2 to remove last 2 bits
                                            angle <= angle >> 2;
                                        end
                                        
                                        TARGET_X_START: begin
                                            // shift right by 2 to remove last 2 bits
                                            x_start <= x_start >> 2;
                                        end
                                        
                                        TARGET_Y_START: begin
                                            // shift right by 2 to remove last 2 bits
                                            y_start <= y_start >> 2;
                                        end
                                        
                                        TARGET_OPERATION: begin
                                            // clear operation
                                            operation <= NO_OP;
                                        end
                                    endcase
                                    
                                    digit_duo_count <= digit_duo_count - 1;
                                end
                            end
                            
                            // clear key (i.e 4'hC) - reset current target register
                            KEY_CLEAR: begin
                                case (input_target)
                                    TARGET_ANGLE: begin
                                        angle <= 32'd0;
                                    end
                                    
                                    TARGET_X_START: begin
                                        x_start <= 22'd0;
                                    end
                                    
                                    TARGET_Y_START: begin
                                        y_start <= 22'd0;
                                    end
                                    
                                    TARGET_OPERATION: begin
                                        operation <= NO_OP;
                                    end
                                endcase
                                
                                digit_duo_count <= 4'd0;
                            end
                            
                            // calculate key (i.e. 4'hD) - trigger calculation and enter calculation mode
                            KEY_CALCULATE: begin
                                // allow calculation only if we've fully entered all parameters
                                if (operation != NO_OP) begin
                                    state <= CALC_MODE;
                                end
                            end
                            
                            default: begin
                                // no action for other keys
                            end
                        endcase
                    end
                    
                    CALC_MODE: begin
                        if (key == KEY_ESCAPE) 
                        begin
                            state <= INPUT_MODE;
                            input_target <= TARGET_ANGLE;  // reset to first input target
                            digit_duo_count <= 4'd0;       // Reset the count
                            
                            angle <= 32'd0;
                            x_start <= 22'd0;
                            y_start <= 22'd0;
                            operation <= NO_OP;
                        end
                    end
                endcase
            end
        end
    end
endmodule
