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

   input [31:0] data_i,
   input [31:0] inst_i,
	input [31:0] pc_i,
	input overflow_i,
	input unaligned_addr_i,
	
	output reg_we_o,
	output [31:0] reg_wdata_o,
	output [4:0] reg_waddr_o,
	output [31:0] epc_o,
	output debug_imm_op_o,
	output exception_o
 );

// Input
wire [31:0] data = data_i;
wire [31:0] inst = inst_i;
wire [31:0] pc = pc_i;
wire overflow = overflow_i;
wire unaligned_addr = unaligned_addr_i;
// Output
assign reg_wdata_o = inst_MFC0 ? mfc0_data : data;
assign reg_waddr_o = rt_op ? inst[20:16] :
							link_op ? 5'd31 : inst[15:11];
assign reg_we_o = ~exception & (add_op | sub_op | slt_op | shift_op
						| logic_op | inst_LUI
						| mem_load_op
						| link_op
						| inst_MFC0
						);
assign exception_o = exception;
assign epc_o = cp0_epc;

wire inst_ADDU, inst_ADDIU, inst_SUBU;
assign inst_ADDU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100001;
assign inst_ADDIU = inst_i[31:26] == 6'b001001;
assign inst_SUBU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100011;
wire inst_ADD = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100000;
wire inst_ADDI = inst_i[31:26] == 6'b001000;
wire inst_SUB = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100010;
wire inst_SLT = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b101010;
wire inst_SLTI = inst_i[31:26] == 6'b001010;
wire inst_SLTIU = inst_i[31:26] == 6'b001011;
wire inst_SLTU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b101011;
wire inst_SLL = inst_i[31:26] == 6'b000000 && inst_i[25:21] == 5'b00000
						&& inst_i[5:0] == 6'b000000;
wire inst_SLLV = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b000100;
wire inst_SRL = inst_i[31:26] == 6'b000000 && inst_i[25:21] == 5'b00000
						&& inst_i[5:0] == 6'b000010;
wire inst_SRLV = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b000110;
wire inst_SRA = inst_i[31:26] == 6'b000000 && inst_i[25:21] == 5'b00000
						&& inst_i[5:0] == 6'b000011;
wire inst_SRAV = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b000111;
wire inst_AND = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100100;
wire inst_ANDI = inst_i[31:26] == 6'b001100;
wire inst_OR = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100101;
wire inst_ORI = inst_i[31:26] == 6'b001101;
wire inst_XOR = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100110;
wire inst_XORI = inst_i[31:26] == 6'b001110;
wire inst_NOR = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100111;
wire inst_LUI = inst_i[31:26] == 6'b001111 && inst_i[25:21] == 5'b00000;
wire inst_LB = inst_i[31:26] == 6'b100000;
wire inst_LBU = inst_i[31:26] == 6'b100100;
wire inst_LH = inst_i[31:26] == 6'b100001;
wire inst_LHU = inst_i[31:26] == 6'b100101;
wire inst_LW = inst_i[31:26] == 6'b100011;
wire inst_SB = inst_i[31:26] == 6'b101000;
wire inst_SH = inst_i[31:26] == 6'b101001;
wire inst_SW = inst_i[31:26] == 6'b101011;
wire mem_op = mem_load_op | mem_store_op;
wire mem_load_op = inst_LB | inst_LBU | inst_LH | inst_LHU | inst_LW;
wire mem_store_op = inst_SB | inst_SH | inst_SW;
wire logic_op = inst_AND | inst_ANDI | inst_OR | inst_ORI | inst_XOR
						| inst_XORI | inst_NOR;
wire imm_op = inst_ADDIU | inst_ADDI | inst_SLTI | inst_SLTIU
				| inst_ANDI | inst_ORI | inst_XORI
				| inst_LUI
				| mem_load_op
				;
wire add_op = inst_ADDU | inst_ADDIU | inst_ADD | inst_ADDI;
wire sub_op = inst_SUBU | inst_SUB;
wire slt_op = inst_SLT | inst_SLTI | inst_SLTIU | inst_SLTU;
wire shift_op = inst_SLL | inst_SLLV | inst_SRL | inst_SRLV | inst_SRA | inst_SRAV;
wire rt_op = imm_op | inst_MFC0;

wire inst_BGEZAL = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b10001;
wire inst_BLTZAL = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b10000;
wire inst_JAL = inst_i[31:26] == 6'b000011;
wire inst_JALR = inst_i[31:26] == 6'b000000 && inst_i[20:16] == 5'b00000
					&& inst_i[5:0] == 6'b001001;
wire link_op = inst_BGEZAL | inst_BLTZAL | inst_JAL | inst_JALR;

wire inst_BREAK = inst_i[31:26] == 6'b000000 && inst_i[5:0] == 6'b001101;
wire inst_SYSCALL = inst_i[31:26] == 6'b000000 && inst_i[5:0] == 6'b001100;

// mfc0
wire inst_MFC0 = inst_i[31:21] == 11'b01000000000 &&
						inst_i[10:3] == 8'b00000000;
wire [31:0] mfc0_data = {32{inst_i[15:11] == 5'd14}} & cp0_epc
							| {32{inst_i[15:11] == 5'd12}} & cp0_status_value
							| {32{inst_i[15:11] == 5'd13}} & cp0_cause_value
							| {32{inst_i[15:11] == 5'd8}} & cp0_badvaddr
							;
wire inst_MTC0 = inst_i[31:21] == 11'b01000000100 &&
						inst_i[10:3] == 8'b00000000;

wire inst_ERET = inst_i[31:0] == 32'h42000018;

// Exception
wire exception = overflow | unaligned_addr
					| inst_BREAK | inst_SYSCALL
					;
// CP0
reg [31:0] cp0_epc;
wire is_bd;		// branch delay
assign is_bd = 0;
always @(posedge clk)
begin
	if(exception)
		if(is_bd)
			cp0_epc <= pc - 4;
		else
			cp0_epc <= pc;
	else if(inst_MTC0 && inst_i[15:11] == 5'd14)
		cp0_epc <= data;
end
// cp0_status
wire [31:0] cp0_status_value;
reg	cp0_status_exl;
always @(posedge clk)
begin
	if(exception)
		cp0_status_exl <= 1;
	else if(inst_MTC0 && inst_i[15:11] == 5'd12)
		cp0_status_exl <= data[1];
	else if(inst_ERET)
		cp0_status_exl <= 0;
end
assign cp0_status_value = {30'b0, cp0_status_exl, 1'b0};
// cp0_cause
wire [31:0] cp0_cause_value;
reg [4:0] cp0_cause_exccode;
always @(posedge clk)
begin
	if(overflow)
		cp0_cause_exccode <= 5'd12;
	else if(unaligned_addr && mem_load_op)
		cp0_cause_exccode <= 5'd4;
	else if(unaligned_addr && mem_store_op)
		cp0_cause_exccode <= 5'd5;
	else if(inst_BREAK)
		cp0_cause_exccode <= 5'd9;
	else if(inst_SYSCALL)
		cp0_cause_exccode <= 5'd8;
	else if(inst_MTC0 && inst_i[15:11] == 5'd13)
		cp0_cause_exccode <= data[6:2];
end
assign cp0_cause_value = {25'b0, cp0_cause_exccode, 2'b0};

// cp0_badvaddr
reg [31:0] cp0_badvaddr;
always @(posedge clk)
begin
	if(unaligned_addr ||
		(inst_MTC0 && inst_i[15:11] == 5'd8))
		cp0_badvaddr <= data;
end

endmodule
