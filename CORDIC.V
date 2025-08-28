`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.03.2025 20:27:00
// Design Name: 
// Module Name: cordic
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
module CORDIC(input clock,output[31:0] exponential,output[31:0] ln,input [31:0] angle,input[21:0] x_start,y_start,input[1:0] m);



 // parameter signed [21:0] x_start='d3000;
  //parameter signed [21:0] y_start='d1000; 


  // Outputs

  // Generate table of atan values
  wire signed [31:0] atan_table [0:30];
  assign atan_table[00] = 'b00100000000000000000000000000000; 
  assign atan_table[01] = 'b00000000011000111111000101000001; 
  assign atan_table[02] = 'b00000000001011100111111011111000; 
  assign atan_table[03] = 'b00000000000101101101111110110110; 
  assign atan_table[04] = 'b00000000000010110110010001110000;
  assign atan_table[05] = 'b00000000000001011011000011010010;
  assign atan_table[06] = 'b00000000000000101101011111110001;
  assign atan_table[07] = 'b00000000000000010110110000010000;
  assign atan_table[08] = 'b00000000000000001011011000001000;
  assign atan_table[09] = 'b0101101100000101;
  assign atan_table[10] = 'b0010110110000010;
  assign atan_table[11] = 'b0001011011000001;
  assign atan_table[12] = 'b0000101101100000;
  assign atan_table[13] = 'b0000010110110000;
  assign atan_table[14] = 'b0000001011011000;
  assign atan_table[15] = 'b0000000101101100;
  assign atan_table[16] = 'b0000000010110110;
  assign atan_table[17] = 'b0000000001011011;
  assign atan_table[18] = 'b0000000000101101;
  assign atan_table[19] = 'b0000000000010110;
  assign atan_table[20] = 'b0000000000001011;
  assign atan_table[21] = 'b0000000000000101;
  assign atan_table[22] = 'b00000000000000000000000010100010;
  assign atan_table[23] = 'b00000000000000000000000001010001;
  assign atan_table[24] = 'b00000000000000000000000000101000;
  assign atan_table[25] = 'b00000000000000000000000000010100;
  assign atan_table[26] = 'b00000000000000000000000000001010;
  assign atan_table[27] = 'b00000000000000000000000000000101;
  assign atan_table[28] = 'b00000000000000000000000000000010;
  assign atan_table[29] = 'b00000000000000000000000000000001;
  assign atan_table[30] = 'b00000000000000000000000000000000;
  wire signed [31:0] atan_tableh [0:30];
  assign atan_tableh[00] = 'b00100000000000000000000000000000; 
  assign atan_tableh[01] = 'b00000000100100000010111110111000; 
  assign atan_tableh[02] = 'b00000000010000110001010001011010; 
  assign atan_tableh[03] = 'b00000000001000010000000000000001; 
  assign atan_tableh[04] = 'b00000000000100000110111110000111;
  assign atan_tableh[05] = 'b00000000000010000011010110111111;
  assign atan_tableh[06] = 'b00000000000001000001101000110010;
  assign atan_tableh[07] = 'b00000000000000100000110100111011;
  assign atan_tableh[08] = 'b00000000000000010000011010011101;
  assign atan_tableh[09] = 'b1000001101010000;
  assign atan_tableh[10] = 'b100000110100111;
  assign atan_tableh[11] = 'b0010000011010011;
  assign atan_tableh[12] = 'b0001000001101001;
  assign atan_tableh[13] = 'b0000100000110100;
  assign atan_tableh[14] = 'b0000010000011010;
  assign atan_tableh[15] = 'b0000001000001101;
  assign atan_tableh[16] = 'b0000000100000110;
  assign atan_tableh[17] = 'b0000000010000011;
  assign atan_tableh[18] = 'b0000000001000001;
  assign atan_tableh[19] = 'b0000000000011111;
  assign atan_tableh[20] = 'b0000000000010000;
  assign atan_tableh[21] = 'b0000000000000111;
  
  reg signed [22:0] x [0:21];
  reg signed [22:0] y [0:21];
  reg signed    [31:0] z [0:21];

  // make sure rotation angle is in -pi/2 to pi/2 range
  wire [1:0] quadrant;
  assign quadrant = angle[31:30];

  always @(posedge clock)
  begin // make sure the rotation angle is in the -pi/2 to pi/2 range
    case(quadrant)
      2'b00,
      2'b11: // no changes needed for these quadrants
      begin
        x[1] <= x_start;
        y[1] <= y_start;
        z[1] <= angle;
      end

      2'b01:
      begin
        x[1] <= -y_start;
        y[1] <= x_start;
        z[1] <= {2'b00,angle[29:0]}; // subtract pi/2 for angle in this quadrant
      end

      2'b10:
      begin
        x[1] <= y_start;
        y[1] <= -x_start;
        z[1] <= {2'b11,angle[29:0]}; // add pi/2 to angles in this quadrant
      end
    endcase
  end


  // run through iterations
  genvar i;

  generate
  for (i=1; i < (22); i=i+1)
  begin: xyz
    wire z_sign;
    wire y_sign;
    wire signed [22:0] x_shr, y_shr;

    assign x_shr = x[i] >>> i; // signed shift right
    assign y_shr = y[i] >>> i;

    //the sign of the current rotation angle
    assign z_sign = z[i][31];
    assign y_sign = y[i][22];

    always @(posedge clock)
    begin
      // add/subtract shifted data
    case(m)
      
     2'b01:begin
      x[i+1] <= (z_sign) ? x[i] - y_shr : x[i] + y_shr;
      y[i+1] <= (z_sign) ? y[i] - x_shr : y[i] + x_shr;
      z[i+1] <= (z_sign) ? z[i] + atan_table[i] : z[i] - atan_table[i];
      end
     2'b10:begin
      x[i+1] <= (y_sign) ? x[i] + y_shr : x[i] - y_shr;
      y[i+1] <= (y_sign) ? y[i] + x_shr : y[i] - x_shr;
      z[i+1] <= (y_sign) ? z[i] - atan_table[i] : z[i] + atan_table[i];
     end
     2'b11:begin
      x[i+1] <= (y_sign) ? x[i] + y_shr : x[i] - y_shr;
      y[i+1] <= (y_sign) ? y[i] + x_shr : y[i] - x_shr;
      z[i+1] <= (y_sign) ? z[i] - atan_tableh[i] : z[i] + atan_tableh[i];
     end
    endcase
    end
    
  end
  endgenerate

  // assign output
assign exponential = x[21];
assign ln = z[21]<<<1;
endmodule
