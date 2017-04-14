`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:15:04 04/09/2017 
// Design Name: 
// Module Name:    multiplier_tb 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module multiplier_tb;

reg signed [31:0] y;
reg signed [31:0] x;
wire signed [63:0] result;
wire signed [63:0] right;
wire ok;

wire [63:0] partial_result[15:0];
wire [63:0] debug0, debug1;

multiplier test(
	// debug
	.partial_product_0(partial_result[0]),
	.partial_product_1(partial_result[1]),
	.partial_product_2(partial_result[2]),
	.partial_product_3(partial_result[3]),
	.partial_product_4(partial_result[4]),
	.partial_product_5(partial_result[5]),
	.partial_product_6(partial_result[6]),
	.partial_product_7(partial_result[7]),
	.partial_product_8(partial_result[8]),
	.partial_product_9(partial_result[9]),
	.partial_product_10(partial_result[10]),
	.partial_product_11(partial_result[11]),
	.partial_product_12(partial_result[12]),
	.partial_product_13(partial_result[13]),
	.partial_product_14(partial_result[14]),
	.partial_product_15(partial_result[15]),
	.debug0(debug0),
	.debug1(debug1),
	
	.mul_a(x),
	.mul_b(y),
	.mul_res(result)
);

initial begin
	$monitor("x=%d, y=%d, result=%d, OK=%b", x, y, result, ok);
end

always #10 y = $random;
always #10 x = $random;
//always #10 x = 32'h23913401;
//always #10 y = 32'h01020304;

initial begin
	#1000 $finish;
end

assign right = x * y;
assign ok = (right == result);

endmodule
