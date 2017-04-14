`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:05:48 04/09/2017 
// Design Name: 
// Module Name:    multiplier 
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
module multiplier(
	// debug
	output [63:0] partial_product_0,
	output [63:0] partial_product_1,
	output [63:0] partial_product_2,
	output [63:0] partial_product_3,
	output [63:0] partial_product_4,
	output [63:0] partial_product_5,
	output [63:0] partial_product_6,
	output [63:0] partial_product_7,
	output [63:0] partial_product_8,
	output [63:0] partial_product_9,
	output [63:0] partial_product_10,
	output [63:0] partial_product_11,
	output [63:0] partial_product_12,
	output [63:0] partial_product_13,
	output [63:0] partial_product_14,
	output [63:0] partial_product_15,
	output [63:0] debug0,
	output [63:0] debug1,
	
	input [31:0] mul_a,
	input [31:0] mul_b,
	output [63:0] mul_res
	
);

// output
assign mul_res = adder_sum;
// debug
assign partial_product_0 = partial_product[0];
assign partial_product_1 = partial_product[1];
assign partial_product_2 = partial_product[2];
assign partial_product_3 = partial_product[3];
assign partial_product_4 = partial_product[4];
assign partial_product_5 = partial_product[5];
assign partial_product_6 = partial_product[6];
assign partial_product_7 = partial_product[7];
assign partial_product_8 = partial_product[8];
assign partial_product_9 = partial_product[9];
assign partial_product_10 = partial_product[10];
assign partial_product_11 = partial_product[11];
assign partial_product_12 = partial_product[12];
assign partial_product_13 = partial_product[13];
assign partial_product_14 = partial_product[14];
assign partial_product_15 = partial_product[15];
assign debug0 = adder_a;
assign debug1 = adder_b;

// Booth algorithm
wire [63:0] x = {{32{mul_a[31]}}, mul_a};
wire [32:0] y = {mul_b, 1'b0};
wire [63:0] partial_product[15:0];
wire [63:0] partial_product_ori[15:0];

genvar i;
generate
	for(i=0;i<16;i=i+1) begin : gen
		partial_product_generate inst(
			.x(x),
			.y(y[2*(i+1):2*i]),
			.product(partial_product_ori[i])
		);
	end
endgenerate

assign partial_product[0] = partial_product_ori[0];
assign partial_product[1] = {partial_product_ori[1][61:0], 2'b0};
assign partial_product[2] = {partial_product_ori[2][59:0], 4'b0};
assign partial_product[3] = {partial_product_ori[3][57:0], 6'b0};
assign partial_product[4] = {partial_product_ori[4][55:0], 8'b0};
assign partial_product[5] = {partial_product_ori[5][53:0], 10'b0};
assign partial_product[6] = {partial_product_ori[6][51:0], 12'b0};
assign partial_product[7] = {partial_product_ori[7][49:0], 14'b0};
assign partial_product[8] = {partial_product_ori[8][47:0], 16'b0};
assign partial_product[9] = {partial_product_ori[9][45:0], 18'b0};
assign partial_product[10] = {partial_product_ori[10][43:0], 20'b0};
assign partial_product[11] = {partial_product_ori[11][41:0], 22'b0};
assign partial_product[12] = {partial_product_ori[12][39:0], 24'b0};
assign partial_product[13] = {partial_product_ori[13][37:0], 26'b0};
assign partial_product[14] = {partial_product_ori[14][35:0], 28'b0};
assign partial_product[15] = {partial_product_ori[15][33:0], 30'b0};

// adder
wire [63:0] adder_a;
wire [64:0] adder_b;
wire [63:0] adder_sum;
assign adder_b[0] = 1'b0;
assign adder_sum = adder_a + adder_b[63:0];

// Wallace Tree
wire[13:0] carries[64:0];
assign carries[0] = 14'b0;
generate
	for(i=0;i<64;i=i+1) begin : tree
		wallace_tree_16_2 inst(
			.in({partial_product[0][i],
				  partial_product[1][i],
				  partial_product[2][i],
				  partial_product[3][i],
				  partial_product[4][i],
				  partial_product[5][i],
				  partial_product[6][i],
				  partial_product[7][i],
				  partial_product[8][i],
				  partial_product[9][i],
				  partial_product[10][i],
				  partial_product[11][i],
				  partial_product[12][i],
				  partial_product[13][i],
				  partial_product[14][i],
				  partial_product[15][i]}
				),
			.c(adder_b[i+1]),
			.s(adder_a[i]),
			.cin(carries[i]),
			.cout(carries[i+1])
		);
	end
endgenerate

endmodule // multiplier

module wallace_tree_16_2(
	input [15:0] in,
	input [13:0] cin,
	output [13:0] cout,
	output c,
	output s
);

// layer0
wire [4:0] layer0;
carry_save_adder adder0_0(
	.a(in[15]),
	.b(in[14]),
	.cin(in[13]),
	.cout(cout[0]),
	.s(layer0[4])
);
carry_save_adder adder0_1(
	.a(in[12]),
	.b(in[11]),
	.cin(in[10]),
	.cout(cout[1]),
	.s(layer0[3])
);
carry_save_adder adder0_2(
	.a(in[9]),
	.b(in[8]),
	.cin(in[7]),
	.cout(cout[2]),
	.s(layer0[2])
);
carry_save_adder adder0_3(
	.a(in[6]),
	.b(in[5]),
	.cin(in[4]),
	.cout(cout[3]),
	.s(layer0[1])
);
carry_save_adder adder0_4(
	.a(in[3]),
	.b(in[2]),
	.cin(in[1]),
	.cout(cout[4]),
	.s(layer0[0])
);

// layer1
wire [3:0] layer1;
carry_save_adder adder1_0(
	.a(layer0[4]),
	.b(layer0[3]),
	.cin(layer0[2]),
	.cout(cout[5]),
	.s(layer1[3])
);
carry_save_adder adder1_1(
	.a(layer0[1]),
	.b(layer0[0]),
	.cin(in[0]),
	.cout(cout[6]),
	.s(layer1[2])
);
carry_save_adder adder1_2(
	.a(1'b0),
	.b(cin[4]),
	.cin(cin[3]),
	.cout(cout[7]),
	.s(layer1[1])
);
carry_save_adder adder1_3(
	.a(cin[2]),
	.b(cin[1]),
	.cin(cin[0]),
	.cout(cout[8]),
	.s(layer1[0])
);

// layer2
wire [1:0] layer2;
carry_save_adder adder2_0(
	.a(layer1[3]),
	.b(layer1[2]),
	.cin(layer1[1]),
	.cout(cout[9]),
	.s(layer2[1])
);
carry_save_adder adder2_1(
	.a(layer1[0]),
	.b(cin[6]),
	.cin(cin[5]),
	.cout(cout[10]),
	.s(layer2[0])
);

// layer3
wire [1:0] layer3;
carry_save_adder adder3_0(
	.a(layer2[1]),
	.b(layer2[0]),
	.cin(cin[10]),
	.cout(cout[11]),
	.s(layer3[1])
);
carry_save_adder adder3_1(
	.a(cin[9]),
	.b(cin[8]),
	.cin(cin[7]),
	.cout(cout[12]),
	.s(layer3[0])
);

// layer4
wire layer4;
carry_save_adder adder4_0(
	.a(layer3[1]),
	.b(layer3[0]),
	.cin(cin[11]),
	.cout(cout[13]),
	.s(layer4)
);

// layer5
carry_save_adder adder5_0(
	.a(layer4),
	.b(cin[13]),
	.cin(cin[12]),
	.cout(c),
	.s(s)
);

endmodule // wallace_tree_16_2

module carry_save_adder(
	input a,
	input b,
	input cin,
	output s,
	output cout
);
assign s = a ^ b ^ cin;
assign cout = (a & b) | (cin & (a | b));
endmodule // carry_save_adder

module partial_product_generate(
	input [63:0] x,
	input [2:0] y,
	output [63:0] product
);

wire [63:0] minus_x = -x;
assign product = 0 & {64{y[2:0] == 3'b000}}
					| x & {64{y[2:0] == 3'b001}}
					| x & {64{y[2:0] == 3'b010}}
					| {x[62:0], 1'b0} & {64{y[2:0] == 3'b011}}
					| {minus_x[62:0], 1'b0} & {64{y[2:0] == 3'b100}}
					| minus_x & {64{y[2:0] == 3'b101}}
					| minus_x & {64{y[2:0] == 3'b110}}
					| 0 & {64{y[2:0] == 3'b111}}
					;
endmodule // partial_product_generate
