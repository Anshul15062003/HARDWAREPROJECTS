module keypad_calculator(
    input clk,              
    input reset,            
    input [3:0] row,       
    
    output [3:0] col,       
    
    output [31:0] angle_out,
    output [21:0] x_start_out,
    output [21:0] y_start_out,
    output [1:0] operation_out

);

    wire [3:0] key;
    wire       key_valid;
    wire [1:0] operation;
    wire [31:0] angle;
    wire [21:0] x_start, y_start;
    

    pmod_keypad keypad (
        .clk(clk),
        .reset(reset),

        .row(row),
        .col(col),

        .key(key),
        .key_valid(key_valid)
    );
    
    mapping mapping (
        .clk(clk),
        .reset(reset),

        .key(key),
        .key_valid(key_valid),


        .angle(angle),
        .x_start(x_start),
        .y_start(y_start),
        .operation(operation)

    );
    
    assign operation_out = operation;
    assign angle_out = angle;
    assign x_start_out = x_start;
    assign y_start_out = y_start;
endmodule
