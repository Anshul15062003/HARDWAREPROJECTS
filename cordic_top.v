module cordic_top(input clk,input reset,input[3:0] row ,output[3:0] col,output oled_spi_clk,
    output oled_spi_data,
    output oled_vdd,
    output oled_vbat,
    output oled_reset_n,
    output oled_dc_n);
wire[31:0] w1,exp,ln;
reg[31:0] out;
wire[31:0] t;
wire [21:0] w2,w3;
wire [1:0] w;
CORDIC v1(.clock(clk),.exponential(exp),.ln(ln),.angle(w1),.x_start(w2),.y_start(w3),.m(w));
keypad_calculator v2(.clk(clk),.reset(reset),.row(row),.angle_out(w1),.x_start_out(w2),.y_start_out(w3),.operation_out(w),.col(col));



top v3(.clock(clk),.reset(reset),.value_to_display(ln),.oled_spi_clk(oled_spi_clk),.oled_spi_data(oled_spi_data),.oled_vdd(oled_vdd),.oled_vbat(oled_vbat),.oled_reset_n(oled_reset_n),. oled_dc_n(oled_dc_n));
ila_0 your_instance_name (
	.clk(clk), // input wire clk


	.probe0(exp), // input wire [31:0]  probe0  
	.probe1(ln), // input wire [31:0]  probe1 
	.probe2(w1), // input wire [31:0]  probe2 
	.probe3(w2), // input wire [21:0]  probe3 
	.probe4(w3), // input wire [21:0]  probe4 
	.probe5(w) // input wire [1:0]  probe5
);


endmodule
