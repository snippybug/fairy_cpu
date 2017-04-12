`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:26:13 03/26/2017 
// Design Name: 
// Module Name:    fairy_writeback_stage 
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
module fairy_writeback_stage(
	input clk,
	input reset_n,

   input [31:0] data_i,
   input [31:0] inst_i,
	input [31:0] pc_i,
	input overflow_i,
	input unaligned_addr_i,
	input [4:0] reg_waddr_i,
	input reg_we_i,
	input delayslot_i,
	input illegal_inst_i,
	
	input hilo_we_i,
	input hilo_sel_i,
	output hilo_we_o,
	output hilo_sel_o,
	
	output [31:0] debug_mfc0_data,
	output [31:0] debug_cp0_cause_value,
	
	output reg_we_o,
	output [31:0] reg_wdata_o,
	output [4:0] reg_waddr_o,
	output [31:0] epc_o,
	output exception_o,
	output eret_o
 );

// Input
wire [31:0] data = data_i;
wire [31:0] inst = inst_i;
wire overflow = overflow_i;
wire unaligned_addr = unaligned_addr_i;
// Output
assign reg_wdata_o = inst_MFC0 ? mfc0_data : data;
assign reg_waddr_o = reg_waddr_i;
assign reg_we_o = ~exception & reg_we_i;
assign exception_o = exception;
assign epc_o = cp0_epc;
assign eret_o = inst_ERET;
assign hilo_we_o = hilo_we_i;
assign hilo_sel_o = hilo_sel_i;
assign debug_mfc0_data = mfc0_data;
assign debug_cp0_cause_value = cp0_cause_value;

wire inst_LB = inst_i[31:26] == 6'b100000;
wire inst_LBU = inst_i[31:26] == 6'b100100;
wire inst_LH = inst_i[31:26] == 6'b100001;
wire inst_LHU = inst_i[31:26] == 6'b100101;
wire inst_LW = inst_i[31:26] == 6'b100011;
wire inst_SB = inst_i[31:26] == 6'b101000;
wire inst_SH = inst_i[31:26] == 6'b101001;
wire inst_SW = inst_i[31:26] == 6'b101011;
wire mem_load_op = inst_LB | inst_LBU | inst_LH | inst_LHU | inst_LW;
wire mem_store_op = inst_SB | inst_SH | inst_SW;

wire inst_BREAK = inst_i[31:26] == 6'b000000 && inst_i[5:0] == 6'b001101;
wire inst_SYSCALL = inst_i[31:26] == 6'b000000 && inst_i[5:0] == 6'b001100;

// mfc0
wire inst_MFC0 = inst_i[31:21] == 11'b01000000000 &&
						inst_i[10:3] == 8'b00000000;
wire [31:0] mfc0_data = {32{inst_i[15:11] == 5'd14}} & cp0_epc
							| {32{inst_i[15:11] == 5'd12}} & cp0_status_value
							| {32{inst_i[15:11] == 5'd13}} & cp0_cause_value
							| {32{inst_i[15:11] == 5'd8}} & cp0_badvaddr
							| {32{inst_i[15:11] == 5'd9}} & cp0_count
							;
wire inst_MTC0 = inst_i[31:21] == 11'b01000000100 &&
						inst_i[10:3] == 8'b00000000;

wire inst_ERET = inst_i[31:0] == 32'h42000018;

// Exception
wire exception = overflow | unaligned_addr
					| inst_BREAK | inst_SYSCALL
					| illegal_inst_i
					;
// CP0
reg [31:0] cp0_epc;
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_epc <= 0;
	else if(exception)
		if(delayslot_i)
			cp0_epc <= pc_i - 4;
		else
			cp0_epc <= pc_i;
	else if(inst_MTC0 && inst_i[15:11] == 5'd14)
		cp0_epc <= data;
end
// cp0_status
wire [31:0] cp0_status_value;
// cp0_status_bev
reg cp0_status_bev;
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_status_bev <= 0;
	else if(inst_MTC0 && inst_i[15:11] == 5'd12)
		cp0_status_bev <= data[22];
end
// cp0_status_exl
reg	cp0_status_exl;
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_status_exl <= 0;
	else if(exception || (inst_MTC0 && inst_i[15:11] == 5'd12) || inst_ERET)
		cp0_status_exl <= exception
							| (inst_MTC0 && inst_i[15:11] == 5'd12) & data[1]
							| ~inst_ERET
							;
end
assign cp0_status_value = {9'b0, cp0_status_bev, 20'b0, cp0_status_exl, 1'b0};
// cp0_cause
wire [31:0] cp0_cause_value;
reg [4:0] cp0_cause_exccode;
reg cp0_cause_bd;
// cp0_cause_bd
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_cause_bd <= 0;
	else if((inst_MTC0 && inst_i[15:11] == 5'd13) || exception)
		cp0_cause_bd <= (inst_MTC0 && inst_i[15:11] == 5'd13) & data[31] 
							| delayslot_i;
end
// cp0_cause_exccode
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_cause_exccode <= 0;
	else if(overflow || unaligned_addr || inst_BREAK || inst_SYSCALL
			|| (inst_MTC0 && inst_i[15:11] == 5'd13)
			|| illegal_inst_i
			)
		cp0_cause_exccode <= {5{overflow}} & 5'd12
								| {5{unaligned_addr & mem_load_op}} & 5'd4
								| {5{unaligned_addr & mem_store_op}} & 5'd5
								| {5{unaligned_addr & ~mem_load_op & ~mem_store_op}} & 5'd4
								| {5{inst_BREAK}} & 5'd9
								| {5{inst_SYSCALL}} & 5'd8
								| {5{inst_MTC0 && inst_i[15:11] == 5'd13}} & data[6:2]
								| {5{illegal_inst_i}} & 5'd10
								;
								
end
assign cp0_cause_value = {cp0_cause_bd,24'b0, cp0_cause_exccode, 2'b0};

// cp0_badvaddr
reg [31:0] cp0_badvaddr;
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_badvaddr <= 0;
	else if(unaligned_addr ||
		(inst_MTC0 && inst_i[15:11] == 5'd8))
		cp0_badvaddr <= data;
end

// cp0_count
reg [31:0] cp0_count;
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_count <= 0;
	else if(inst_MTC0 && inst_i[15:11] == 5'd9)
		cp0_count <= data;
	else
		cp0_count <= cp0_count + cp0_count_step;
end

// cp0_count_step
reg cp0_count_step;
always @(posedge clk)
begin
	if(reset_n == 0)
		cp0_count_step <= 0;
	else
		cp0_count_step <= ~cp0_count_step;
end

endmodule
