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
	input [4:0] reg_waddr_i,
	input reg_we_i,
	input delayslot_i,
	input eret_i,
	input unaligned_addr_i,

	input hilo_we_i,
	input hilo_sel_i,
	output hilo_we_o,
	output hilo_sel_o,
	
	input illegal_inst_i,
	output illegal_inst_o,
	
	input [31:0] data_sram_rdata_i,
	output [31:0] data_sram_addr_o,
	output [3:0] data_sram_cen_o,
	output [31:0] data_sram_wdata_o,
	output data_sram_wr_o,
	
	output [31:0] inst_o,
	output [31:0] data_o,
	output [31:0] pc_o,
	output overflow_o,
	output unaligned_addr_o,
	output [4:0] reg_waddr_o,
	output reg_we_o,
	output delayslot_o,
	
	output [31:0] debug_mem_rdata,
	output [31:0] debug_data
);

// Input
wire [31:0] data_sram_rdata = data_sram_rdata_i;
wire [31:0] op1 = op1_i;
// Output
assign inst_o = inst;
assign pc_o = pc;
assign overflow_o = overflow;
assign unaligned_addr_o = unaligned_addr;
assign data_o = mem_load_next_op ? mem_rdata : data;
assign data_sram_addr_o = data_i;
assign data_sram_cen_o = data_sram_cen;
assign data_sram_wr_o = data_sram_wr;
assign data_sram_wdata_o = data_sram_wdata;
assign reg_waddr_o = reg_waddr;
assign reg_we_o = reg_we;
assign delayslot_o = delayslot;
assign hilo_we_o = hilo_we;
assign hilo_sel_o = hilo_sel;
assign illegal_inst_o = illegal_inst;
assign debug_mem_rdata = mem_rdata;
assign debug_data = data;

wire reset = ~reset_n | exception_i | eret_i;

reg [31:0] inst;
reg [31:0] data;
reg [31:0] pc;
reg overflow;
reg [4:0] reg_waddr;
reg reg_we;
reg delayslot;
reg hilo_we, hilo_sel;
reg unaligned_addr;
reg illegal_inst;

// illegal_inst
always @(posedge clk)
begin
	if(reset)
		illegal_inst <= 0;
	else
		illegal_inst <= illegal_inst_i;
end

// unaligned_addr
always @(posedge clk)
begin
	if(reset)
		unaligned_addr <= 0;
	else
		unaligned_addr <= (inst_LH & data_i[0])
							|	(inst_LHU & data_i[0])
							|	(inst_SH & data_i[0])
							|	(inst_LW & (|data_i[1:0]))
							|	(inst_SW & (|data_i[1:0]))
							|	unaligned_addr_i
							;
end

// hilo_we && hilo_sel
always @(posedge clk)
begin
	if(reset) begin
		hilo_we <= 0;
		hilo_sel <= 0;
	end
	else begin
		hilo_we <= hilo_we_i;
		hilo_sel <= hilo_sel_i;
	end
end

// delayslot
always @(posedge clk)
begin
	if(reset)
		delayslot <= 0;
	else
		delayslot <= delayslot_i;
end

// reg_we
always @(posedge clk)
begin
	if(reset)
		reg_we <= 0;
	else
		reg_we <= reg_we_i;
end

// reg_waddr
always @(posedge clk)
begin
	if(reset)
		reg_waddr <= 32'b0;
	else
		reg_waddr <= reg_waddr_i;
end

// overflow
always @(posedge clk)
begin
	if(reset)
		overflow <= 0;
	else
		overflow <= overflow_i;
end

// pc
always @(posedge clk)
begin
	if(reset)
		pc <= 31'b0;
	else
		pc <= pc_i;
end

// inst
always @(posedge clk)
begin
	if(reset)
		inst <= 32'b0;
	else
		inst <= inst_i;
end

// data
always @(posedge clk)
begin
	if(reset)
		data <= 32'b0;
	else
		data <= {32{inst_MFLO | inst_MFHI | inst_MTLO | inst_MTHI}} & op1_i
				| {32{~inst_MFLO & ~inst_MFHI}} & data_i;
end

wire inst_LB = inst_i[31:26] == 6'b100000;
wire inst_LBU = inst_i[31:26] == 6'b100100;
wire inst_LH = inst_i[31:26] == 6'b100001;
wire inst_LHU = inst_i[31:26] == 6'b100101;
wire inst_LW = inst_i[31:26] == 6'b100011;
wire inst_LB_next = inst[31:26] == 6'b100000;
wire inst_LBU_next = inst[31:26] == 6'b100100;
wire inst_LH_next = inst[31:26] == 6'b100001;
wire inst_LHU_next = inst[31:26] == 6'b100101;
wire inst_LW_next = inst[31:26] == 6'b100011;
wire inst_SB = inst_i[31:26] == 6'b101000;
wire inst_SH = inst_i[31:26] == 6'b101001;
wire inst_SW = inst_i[31:26] == 6'b101011;
wire mem_load_next_op = inst_LB_next | inst_LBU_next | inst_LH_next
							| inst_LHU_next | inst_LW_next;
wire mem_store_op = inst_SB | inst_SH | inst_SW;

wire [31:0] mem_rdata = ({32{inst_LB_next}} & {32{data[1:0] == 2'b00}} & {{28{data_sram_rdata[7]}}, data_sram_rdata[7:0]})
							|({32{inst_LB_next}} & {32{data[1:0] == 2'b01}} & {{28{data_sram_rdata[15]}}, data_sram_rdata[15:8]})
							|({32{inst_LB_next}} & {32{data[1:0] == 2'b10}} & {{28{data_sram_rdata[23]}}, data_sram_rdata[23:16]})
							|({32{inst_LB_next}} & {32{data[1:0] == 2'b11}} & {{28{data_sram_rdata[31]}}, data_sram_rdata[31:24]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b00}} & {28'b0, data_sram_rdata[7:0]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b01}} & {28'b0, data_sram_rdata[15:8]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b10}} & {28'b0, data_sram_rdata[23:16]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b11}} & {28'b0, data_sram_rdata[31:24]})
							|({32{inst_LH_next}} & {32{data[1] == 0}} & {{16{data_sram_rdata[15]}}, data_sram_rdata[15:0]})
							|({32{inst_LH_next}} & {32{data[1] == 1}} & {{16{data_sram_rdata[31]}}, data_sram_rdata[31:16]})
							|({32{inst_LHU_next}} & {32{data[1] == 0}} & {16'b0, data_sram_rdata[15:0]})
							|({32{inst_LHU_next}} & {32{data[1] == 1}} & {16'b0, data_sram_rdata[31:16]})
							|({32{inst_LW_next}} & data_sram_rdata)
							;

wire [3:0] data_sram_cen = {4{inst_SB}} & {4{data_i[1:0] == 2'b00}} & 4'b0001
							| {4{inst_SB}} & {4{data_i[1:0] == 2'b01}} & 4'b0010
							| {4{inst_SB}} & {4{data_i[1:0] == 2'b10}} & 4'b0100
							| {4{inst_SB}} & {4{data_i[1:0] == 2'b11}} & 4'b1000
							| {4{inst_SH}} & {4{data_i[1] == 0}} & 4'b0011
							| {4{inst_SH}} & {4{data_i[1] == 1}} & 4'b1100
							| {4{inst_SW}} & 4'b1111
							;

wire data_sram_wr = ~(exception_i | unaligned_addr_store) & mem_store_op;
wire [31:0] data_sram_wdata = {32{inst_SB}} & {4{op1[7:0]}}
								|{32{inst_SH}} & {2{op1[15:0]}}
								|{32{inst_SW}} & op1[31:0];
wire unaligned_addr_store = (inst_SH & data_i[0])
							|	(inst_SW & (|data_i[1:0]))
							;
							
// mflo && mfhi && mtlo && mthi
wire inst_MFLO = inst_i[31:16] == 16'b0 && inst_i[10:6] == 5'b00000
					&& inst_i[5:0] == 6'b010010;
wire inst_MFHI = inst_i[31:16] == 16'b0 && inst_i[10:6] == 5'b00000
					&& inst_i[5:0] == 6'b010000;
wire inst_MTHI = inst_i[31:26] == 6'b0 && inst_i[20:6] == 15'b0
					&& inst_i[5:0] == 6'b010001;
wire inst_MTLO = inst_i[31:26] == 6'b0 && inst_i[20:6] == 15'b0
					&& inst_i[5:0] == 6'b010011;
endmodule
