`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:20:25 03/26/2017 
// Design Name: 
// Module Name:    fairy_fetch_stage 
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
module fairy_fetch_stage(
   input clk,
   input reset_n,
	
	input   [31:0]  inst_sram_rdata_i,
	output  [31:0]  inst_sram_addr_o,
	
	input exception_i,
	input eret_i,
	input [31:0] epc_i,
	
	input [31:0] branch_target_i,
	input branch_valid_i,
	input stall_i,
	
	output [31:0] inst_o,
	output [31:0] pc_o,
	output unaligned_addr_o
);

// Input
wire [31:0] branch_target = branch_target_i;
wire branch_valid = branch_valid_i;
wire exception = exception_i;
wire [31:0] inst_sram_rdata = inst_sram_rdata_i;
// Output
assign inst_o = bubble ? 0 : inst_sram_rdata;
assign inst_sram_addr_o = stall_i ? oldpc : pc;
assign pc_o = oldpc;
assign unaligned_addr_o = unaligned_addr;

reg [31:0] pc;	// program counter
reg bubble;
reg [31:0] oldpc;
reg unaligned_addr;

// unaligned_addr
always @(posedge clk)
begin
	if(reset_n == 0 || eret_i || exception_i)
		unaligned_addr <= 0;
	else if(stall_i)
		unaligned_addr <= unaligned_addr;
	else
		unaligned_addr <= (|inst_sram_addr_o[1:0]);
end


// oldpc
always @(posedge clk)
begin
	if(exception | eret_i)
		oldpc <= 0;
	else if(stall_i == 0)
		oldpc <= pc;
end

// pc
always @(posedge clk)
begin
	if(reset_n == 0)
		pc <= 32'hbfc00000;
	else if(exception | eret_i)
		pc <= {32{exception}} & 32'hbfc00380
			| {32{eret_i}} & epc_i
			;
	else if(stall_i)
		pc <= pc;
	else
		pc <= branch_valid ? branch_target : (pc+4);
end

// bubble
always @(posedge clk)
begin
	if(reset_n == 0 || exception || eret_i)
		bubble <= 1;
	else
		bubble <= 0;
end

endmodule
