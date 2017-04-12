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
	
	// memory
	input [31:0] data_sram_rdata_i,
	output [31:0] data_sram_addr_o,
	output [3:0] data_sram_cen_o,
	output [31:0] data_sram_wdata_o,
	output data_sram_wr_o,
	input [31:0] op1_i,
	
	// pipeline
	input illegal_inst_i,
	output illegal_inst_o,
	input [1:0] hilo_we_i,
	output [1:0] hilo_we_o,
	input [63:0] data_i,
	output [63:0] data_o,
   input [31:0] inst_i,
	output [31:0] inst_o,
	input [31:0] pc_i,
	output [31:0] pc_o,
	input overflow_i,
	output overflow_o,
	input unaligned_addr_i,
	output unaligned_addr_o,
	input [4:0] reg_waddr_i,
	output [4:0] reg_waddr_o,
	input reg_we_i,
	output reg_we_o,
	input delayslot_i,
	output delayslot_o,
	
	// debug
	output [31:0] debug_mem_rdata,
	output [31:0] debug_data,
	
	// exception
	input exception_i,
	input eret_i
);

// Input
wire [31:0] data_sram_rdata = data_sram_rdata_i;
// Output
assign inst_o = inst;
assign pc_o = pc;
assign overflow_o = overflow;
assign unaligned_addr_o = unaligned_addr;
assign data_o = mem_load_next_op ? {32'b0, mem_rdata} : data;
assign data_sram_addr_o = data_i[31:0];
assign data_sram_cen_o = data_sram_cen;
assign data_sram_wr_o = data_sram_wr;
assign data_sram_wdata_o = data_sram_wdata;
assign reg_waddr_o = reg_waddr;
assign reg_we_o = reg_we;
assign delayslot_o = delayslot;
assign hilo_we_o = hilo_we;
assign illegal_inst_o = illegal_inst;
assign debug_mem_rdata = mem_rdata;
assign debug_data = data;

wire reset = ~reset_n | exception_i | eret_i;

reg [31:0] inst;
reg [63:0] data;
reg [31:0] pc;
reg overflow;
reg [4:0] reg_waddr;
reg reg_we;
reg delayslot;
reg [1:0] hilo_we;
reg unaligned_addr;
reg illegal_inst;
reg [31:0] op1;

// op1
always @(posedge clk)
begin
	if(reset)
		op1 <= 0;
	else
		op1 <= op1_i;
end

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

// hilo_we
always @(posedge clk)
begin
	if(reset)
		hilo_we <= 0;
	else
		hilo_we <= hilo_we_i;
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
		data <= 0;
	else
		data <= {64{inst_MFHI | inst_MFLO}} & {32'b0, op1_i}
				| {64{inst_MTHI}} & {op1_i, 32'b0}
				| {64{inst_MTLO}} & {32'b0, op1_i}
				| {64{~inst_MFLO & ~inst_MFHI & ~inst_MTLO & ~inst_MTHI}} & data_i;
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
wire inst_LWL_next = inst[31:26] == 6'b100010;
wire inst_LWR_next = inst[31:26] == 6'b100110;
wire inst_SWL = inst_i[31:26] == 6'b101010;
wire inst_SWR = inst_i[31:26] == 6'b101110;
wire mem_load_next_op = inst_LB_next | inst_LBU_next | inst_LH_next
							| inst_LHU_next | inst_LW_next
							| inst_LWL_next | inst_LWR_next
							;
wire mem_store_op = inst_SB | inst_SH | inst_SW |
						inst_SWL | inst_SWR
						;

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
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b00}} & {data_sram_rdata[7:0], op1[23:0]})
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b01}} & {data_sram_rdata[15:0], op1[15:0]})
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b10}} & {data_sram_rdata[23:0], op1[7:0]})
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b11}} & data_sram_rdata)
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b00}} & data_sram_rdata)
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b01}} & {op1[31:24], data_sram_rdata[31:8]})
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b10}} & {op1[31:16], data_sram_rdata[31:16]})
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b11}} & {op1[31:8], data_sram_rdata[31:24]})
							;

wire [3:0] data_sram_cen = {4{inst_SB}} & {4{data_i[1:0] == 2'b00}} & 4'b0001
							| {4{inst_SB}} & {4{data_i[1:0] == 2'b01}} & 4'b0010
							| {4{inst_SB}} & {4{data_i[1:0] == 2'b10}} & 4'b0100
							| {4{inst_SB}} & {4{data_i[1:0] == 2'b11}} & 4'b1000
							| {4{inst_SH}} & {4{data_i[1] == 0}} & 4'b0011
							| {4{inst_SH}} & {4{data_i[1] == 1}} & 4'b1100
							| {4{inst_SW}} & 4'b1111
							| {4{inst_SWL}} & {4{data_i[1:0] == 2'b00}} & 4'b0001
							| {4{inst_SWL}} & {4{data_i[1:0] == 2'b01}} & 4'b0011
							| {4{inst_SWL}} & {4{data_i[1:0] == 2'b10}} & 4'b0111
							| {4{inst_SWL}} & {4{data_i[1:0] == 2'b11}} & 4'b1111
							| {4{inst_SWR}} & {4{data_i[1:0] == 2'b00}} & 4'b1111
							| {4{inst_SWR}} & {4{data_i[1:0] == 2'b01}} & 4'b1110
							| {4{inst_SWR}} & {4{data_i[1:0] == 2'b10}} & 4'b1100
							| {4{inst_SWR}} & {4{data_i[1:0] == 2'b11}} & 4'b1000
							;

wire data_sram_wr = ~(exception_i | unaligned_addr_store) & mem_store_op;
wire [31:0] data_sram_wdata = {32{inst_SB}} & {4{op1_i[7:0]}}
								|{32{inst_SH}} & {2{op1_i[15:0]}}
								|{32{inst_SW}} & op1_i[31:0]
								|{32{inst_SWL & (data_i[1:0] == 2'b00)}} & {24'b0, op1_i[31:24]}
								|{32{inst_SWL & (data_i[1:0] == 2'b01)}} & {16'b0, op1_i[31:16]}
								|{32{inst_SWL & (data_i[1:0] == 2'b10)}} & {8'b0, op1_i[31:8]}
								|{32{inst_SWL & (data_i[1:0] == 2'b11)}} & op1_i[31:0]
								|{32{inst_SWR & (data_i[1:0] == 2'b00)}} & op1_i[31:0]
								|{32{inst_SWR & (data_i[1:0] == 2'b01)}} & {op1_i[23:0], 8'b0}
								|{32{inst_SWR & (data_i[1:0] == 2'b10)}} & {op1_i[15:0], 16'b0}
								|{32{inst_SWR & (data_i[1:0] == 2'b11)}} & {op1_i[7:0], 24'b0}
								;
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
endmodule // fairy_mem_stage
