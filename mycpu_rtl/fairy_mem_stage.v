`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:18:02 03/26/2017 
// Design Name: 
// Module Name:    fairy_mem_stage 
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
module fairy_mem_stage(
   input clk,
   input reset_n,
   input [31:0] data_i,
   input [31:0] inst_i,
	input [31:0] pc_i,
	input overflow_i,
	input exception_i,
	input [31:0] op1_i,
	
	input [31:0] data_sram_rdata_i,
	output [31:0] data_sram_addr_o,
	output [3:0] data_sram_cen_o,
	output [31:0] data_sram_wdata_o,
	output data_sram_wr_o,
	
	output [31:0] inst_o,
	output [31:0] data_o,
	output [31:0] pc_o,
	output overflow_o,
	output unaligned_addr_o
);

// Input
wire exception = exception_i;
wire [31:0] data_sram_rdata = data_sram_rdata_i;
wire [31:0] data_sram_addr = data_i;
wire [31:0] op1 = op1_i;
// Output
assign inst_o = inst;
assign pc_o = pc;
assign overflow_o = overflow;
assign unaligned_addr_o = unaligned_addr;
assign data_o = (mem_load_op & ~unaligned_addr)? mem_rdata : data;
assign data_sram_addr_o = data_sram_addr;
assign data_sram_cen_o = data_sram_cen;
assign data_sram_wr_o = data_sram_wr;
assign data_sram_wdata_o = data_sram_wdata;

reg [31:0] inst;
reg [31:0] data;
reg [31:0] pc;
reg overflow;

// overflow
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		overflow <= 0;
	else
		overflow <= overflow_i;
end

// pc
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		pc <= 31'b0;
	else
		pc <= pc_i;
end

// inst
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		inst <= 32'b0;
	else
		inst <= inst_i;
end

// data
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		data <= 32'b0;
	else
		data <= data_i;
end

wire inst_LB = inst[31:26] == 6'b100000;
wire inst_LBU = inst[31:26] == 6'b100100;
wire inst_LH = inst[31:26] == 6'b100001;
wire inst_LHU = inst[31:26] == 6'b100101;
wire inst_LW = inst[31:26] == 6'b100011;
wire inst_SB = inst_i[31:26] == 6'b101000;
wire inst_SH = inst_i[31:26] == 6'b101001;
wire inst_SW = inst_i[31:26] == 6'b101011;
wire mem_op = mem_load_op | mem_store_op;
wire mem_load_op = inst_LB | inst_LBU | inst_LH | inst_LHU | inst_LW;
wire mem_store_op = inst_SB | inst_SH | inst_SW;

wire [31:0] mem_rdata = ({32{inst_LB}} & {32{data[1:0] == 2'b00}} & {{28{data_sram_rdata[7]}}, data_sram_rdata[7:0]})
							|({32{inst_LB}} & {32{data[1:0] == 2'b01}} & {{28{data_sram_rdata[15]}}, data_sram_rdata[15:8]})
							|({32{inst_LB}} & {32{data[1:0] == 2'b10}} & {{28{data_sram_rdata[23]}}, data_sram_rdata[23:16]})
							|({32{inst_LB}} & {32{data[1:0] == 2'b11}} & {{28{data_sram_rdata[31]}}, data_sram_rdata[31:24]})
							|({32{inst_LBU}} & {32{data[1:0] == 2'b00}} & {28'b0, data_sram_rdata[7:0]})
							|({32{inst_LBU}} & {32{data[1:0] == 2'b01}} & {28'b0, data_sram_rdata[15:8]})
							|({32{inst_LBU}} & {32{data[1:0] == 2'b10}} & {28'b0, data_sram_rdata[23:16]})
							|({32{inst_LBU}} & {32{data[1:0] == 2'b11}} & {28'b0, data_sram_rdata[31:24]})
							|({32{inst_LH}} & {32{data[1] == 0}} & {{16{data_sram_rdata[15]}}, data_sram_rdata[15:0]})
							|({32{inst_LH}} & {32{data[1] == 1}} & {{16{data_sram_rdata[31]}}, data_sram_rdata[31:16]})
							|({32{inst_LHU}} & {32{data[1] == 0}} & {16'b0, data_sram_rdata[15:0]})
							|({32{inst_LHU}} & {32{data[1] == 1}} & {16'b0, data_sram_rdata[31:16]})
							|({32{inst_LW}} & data_sram_rdata)
							;

wire [3:0] data_sram_cen = {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b00}} & 4'b0001
							| {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b01}} & 4'b0010
							| {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b10}} & 4'b0100
							| {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b11}} & 4'b1000
							| {4{inst_SH}} & {4{data_sram_addr[1] == 0}} & 4'b0011
							| {4{inst_SH}} & {4{data_sram_addr[1] == 1}} & 4'b1100
							| {4{inst_SW}} & 4'b1111
							;

wire data_sram_wr = mem_store_op;
wire [31:0] data_sram_wdata = {32{inst_SB}} & {4{op1[7:0]}}
								|{32{inst_SH}} & {2{op1[15:0]}}
								|{32{inst_SW}} & op1[31:0];
								
wire unaligned_addr = (inst_LH & data_sram_addr[0])
							|	(inst_LHU & data_sram_addr[0])
							|	(inst_SH & data_sram_addr[0])
							|	(inst_LW & (|data_sram_addr[1:0]))
							|	(inst_SW & (|data_sram_addr[1:0]))
							;
endmodule
