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
	
	input [31:0] branch_target_i,
	input branch_valid_i,
	input stall_i,
	
	output [31:0] inst_o,
	output [31:0] pc_o,
	output [31:0] debug_pc_o
);

// Input
wire [31:0] branch_target = branch_target_i;
wire branch_valid = branch_valid_i;
wire exception = exception_i;
wire [31:0] inst_sram_rdata = inst_sram_rdata_i;
wire stall = stall_i;
// Output
assign inst_o = delay ? 0 : inst_sram_rdata;
assign inst_sram_addr_o = pc;
assign debug_pc_o = pc;
assign pc_o = pc;

reg [31:0] pc;	// program counter
reg delay;
// pc
always @(posedge clk)
begin
	if(reset_n == 0)
		pc <= 32'hbfc00000;
	else if(exception)
		pc <= 32'hbfc00380;
	else if(branch_valid)
		pc <= branch_target;
	else
		pc <= pc + 4;
end
// delay
always @(posedge clk)
begin
	if(reset_n == 0 || exception || stall)
		delay <= 1;
	else
		delay <= 0;
end

endmodule
