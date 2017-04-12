`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:50:14 03/26/2017 
// Design Name: 
// Module Name:    fairy_exe_stage 
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
module fairy_exe_stage(
   input clk,
   input reset_n,
	
   input [31:0] op0_i,
   input [31:0] op1_i,
	input [31:0] inst_i,
	input [31:0] pc_i,
	input exception_i,
	
	output [31:0] debug_adder_a,
	output [31:0] debug_adder_b,
	output [31:0] debug_imm_op,
	output [31:0] debug_adder_b0,
	output [31:0] debug_shift_emptybit,
	
	output [31:0] data_o,
	output [31:0] op1_o,
	output [31:0] inst_o,
	output [31:0] pc_o,
	output overflow_o
);

// Input
wire [31:0] op0 = op0_i;
wire exception = exception_i;
// Output
assign data_o = data;
assign inst_o = inst;
assign pc_o = pc;
assign overflow_o = overflow;
assign op1_o = op1;
assign debug_adder_a = adder_a;
assign debug_adder_b = adder_b;
assign debug_imm_op = {32{imm_op}};
assign debug_adder_b0 = adder_b0;
assign debug_shift_emptybit = {32{shift_emptybit}};

reg [31:0] inst;
reg [31:0] data;
reg overflow;
reg [31:0] pc;
reg [31:0] op1;

// op1
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		op1 <= 31'b0;
	else
		op1 <= op1_i;
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
wire [31:0] result = {31'b0, lt} & {32{slt_op}}
					| adder_sum & {32{add_op | sub_op | mem_op | link_op}}
					| shift_result & {32{shift_op}}
					| logic_result & {32{logic_op}}
					| lui_result & {32{inst_LUI}}
					| op1_i & {32{inst_MTC0}}
					;
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		data <= 32'b0;
	else
		data <= result;
end

// overflow
always @(posedge clk)
begin
	if(reset_n == 0 || exception)
		overflow <= 0;
	else
		overflow <= adder_overflow & overflow_op;
end

// slt
wire inst_SLT = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b101010;
wire inst_SLTI = inst_i[31:26] == 6'b001010;
wire inst_SLTIU = inst_i[31:26] == 6'b001011;
wire inst_SLTU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b101011;
wire slt_op = slts_op | sltu_op;
wire slts_op = inst_SLT | inst_SLTI;
wire sltu_op = inst_SLTIU | inst_SLTU;
wire lt;		// less than
assign lt = sltu_op & (		// unsigned
				(~adder_a[31] & adder_sum[31])
				| (adder_b0[31] & adder_sum[31]) 
			)
			| slts_op & (		// signed
				(adder_a[31] ^~ adder_b[31]) & adder_sum[31]		// same sign
				| (adder_a[31] ^ adder_b[31]) & (adder_a[31] ? 1'b1 : 1'b0)	// different sign
			);

// adder
wire inst_ADDU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100001;
wire inst_ADDIU = inst_i[31:26] == 6'b001001;
wire inst_SUBU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100011;
wire inst_ADD = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100000;
wire inst_ADDI = inst_i[31:26] == 6'b001000;
wire inst_SUB = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b100010;
wire overflow_op = inst_ADD | inst_ADDI | inst_SUB;
wire add_op = inst_ADDU | inst_ADDIU | inst_ADD | inst_ADDI;
wire imm_op = inst_ADDIU | inst_ADDI 
				| inst_SLTI | inst_SLTIU
				| inst_ANDI | inst_ORI | inst_XORI
				| inst_LUI
				| mem_op
				;
wire sub_op = inst_SUBU | inst_SUB;
wire [31:0] adder_a, adder_b, adder_sum, adder_b0;
wire adder_c0;
wire adder_overflow = (~adder_a[31] & ~adder_b[31] & adder_sum[31])
							| (adder_a[31] & adder_b[31] & ~adder_sum[31]);
wire carry_op = sub_op | slt_op;
assign adder_a = link_op ? pc_i : op0;
assign adder_b0 = imm_op ? {{16{inst_i[15]}},inst_i[15:0]} : op1;
assign adder_b = {32{sub_op | slt_op}} & ~adder_b0
					| {32{add_op | mem_op}} & adder_b0
					| {32{link_op}} & 32'd8
					;
assign adder_c0 = carry_op ? 1'b1 : 1'b0;
assign adder_sum = adder_a + adder_b + {31'b0, adder_c0};

// shifter
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
wire [31:0] shift_result;
wire shift_op = inst_SLL | inst_SRL | inst_SRA | shift_var_op;
wire shift_var_op = inst_SLLV | inst_SRLV | inst_SRAV;
wire shift_logic = inst_SLL | inst_SLLV | inst_SRL | inst_SRLV;
wire shift_emptybit = shift_logic ? 1'b0 : shift_operand[31];
wire shift_left = inst_SLL | inst_SLLV;
wire [31:0] shift_operand = op1;	// from rt
wire [4:0] shift_count = shift_var_op ? op0[4:0] : inst_i[10:6];	// [4:0] from rs : sa

// Useful code, but too much synthesis time
/*
genvar i;
generate
	for(i=0; i<32; i=i+1) begin
		assign shift_result[i] = (shift_count == 5'd0) & shift_operand[i]
								| (shift_count == 5'd1) & (shift_left ? (i-1 < 0 ? 0 : shift_operand[i-1]) : (i+1 > 31 ? shift_emptybit : shift_operand[i+1]))
								| (shift_count == 5'd2) & (shift_left ? (i-2 < 0 ? 0 : shift_operand[i-2]) : (i+2 > 31 ? shift_emptybit : shift_operand[i+2]))
								| (shift_count == 5'd3) & (shift_left ? (i-3 < 0 ? 0 : shift_operand[i-3]) : (i+3 > 31 ? shift_emptybit : shift_operand[i+3]))
								| (shift_count == 5'd4) & (shift_left ? (i-4 < 0 ? 0 : shift_operand[i-4]) : (i+4 > 31 ? shift_emptybit : shift_operand[i+4]))
								| (shift_count == 5'd5) & (shift_left ? (i-5 < 0 ? 0 : shift_operand[i-5]) : (i+5 > 31 ? shift_emptybit : shift_operand[i+5]))
								| (shift_count == 5'd6) & (shift_left ? (i-6 < 0 ? 0 : shift_operand[i-6]) : (i+6 > 31 ? shift_emptybit : shift_operand[i+6]))
								| (shift_count == 5'd7) & (shift_left ? (i-7 < 0 ? 0 : shift_operand[i-7]) : (i+7 > 31 ? shift_emptybit : shift_operand[i+7]))
								| (shift_count == 5'd8) & (shift_left ? (i-8 < 0 ? 0 : shift_operand[i-8]) : (i+8 > 31 ? shift_emptybit : shift_operand[i+8]))
								| (shift_count == 5'd9) & (shift_left ? (i-9 < 0 ? 0 : shift_operand[i-9]) : (i+9 > 31 ? shift_emptybit : shift_operand[i+9]))
								| (shift_count == 5'd10) & (shift_left ? (i-10 < 0 ? 0 : shift_operand[i-10]) : (i+10 > 31 ? shift_emptybit : shift_operand[i+10]))
								| (shift_count == 5'd11) & (shift_left ? (i-11 < 0 ? 0 : shift_operand[i-11]) : (i+11 > 31 ? shift_emptybit : shift_operand[i+11]))
								| (shift_count == 5'd12) & (shift_left ? (i-12 < 0 ? 0 : shift_operand[i-12]) : (i+12 > 31 ? shift_emptybit : shift_operand[i+12]))
								| (shift_count == 5'd13) & (shift_left ? (i-13 < 0 ? 0 : shift_operand[i-13]) : (i+13 > 31 ? shift_emptybit : shift_operand[i+13]))
								| (shift_count == 5'd14) & (shift_left ? (i-14 < 0 ? 0 : shift_operand[i-14]) : (i+14 > 31 ? shift_emptybit : shift_operand[i+14]))
								| (shift_count == 5'd15) & (shift_left ? (i-15 < 0 ? 0 : shift_operand[i-15]) : (i+15 > 31 ? shift_emptybit : shift_operand[i+15]))
								| (shift_count == 5'd16) & (shift_left ? (i-16 < 0 ? 0 : shift_operand[i-16]) : (i+16 > 31 ? shift_emptybit : shift_operand[i+16]))
								| (shift_count == 5'd17) & (shift_left ? (i-17 < 0 ? 0 : shift_operand[i-17]) : (i+17 > 31 ? shift_emptybit : shift_operand[i+17]))
								| (shift_count == 5'd18) & (shift_left ? (i-18 < 0 ? 0 : shift_operand[i-18]) : (i+18 > 31 ? shift_emptybit : shift_operand[i+18]))
								| (shift_count == 5'd19) & (shift_left ? (i-19 < 0 ? 0 : shift_operand[i-19]) : (i+19 > 31 ? shift_emptybit : shift_operand[i+19]))
								| (shift_count == 5'd20) & (shift_left ? (i-20 < 0 ? 0 : shift_operand[i-20]) : (i+20 > 31 ? shift_emptybit : shift_operand[i+20]))
								| (shift_count == 5'd21) & (shift_left ? (i-21 < 0 ? 0 : shift_operand[i-21]) : (i+21 > 31 ? shift_emptybit : shift_operand[i+21]))
								| (shift_count == 5'd22) & (shift_left ? (i-22 < 0 ? 0 : shift_operand[i-22]) : (i+22 > 31 ? shift_emptybit : shift_operand[i+22]))
								| (shift_count == 5'd23) & (shift_left ? (i-23 < 0 ? 0 : shift_operand[i-23]) : (i+23 > 31 ? shift_emptybit : shift_operand[i+23]))
								| (shift_count == 5'd24) & (shift_left ? (i-24 < 0 ? 0 : shift_operand[i-24]) : (i+24 > 31 ? shift_emptybit : shift_operand[i+24]))
								| (shift_count == 5'd25) & (shift_left ? (i-25 < 0 ? 0 : shift_operand[i-25]) : (i+25 > 31 ? shift_emptybit : shift_operand[i+25]))
								| (shift_count == 5'd26) & (shift_left ? (i-26 < 0 ? 0 : shift_operand[i-26]) : (i+26 > 31 ? shift_emptybit : shift_operand[i+26]))
								| (shift_count == 5'd27) & (shift_left ? (i-27 < 0 ? 0 : shift_operand[i-27]) : (i+27 > 31 ? shift_emptybit : shift_operand[i+27]))
								| (shift_count == 5'd28) & (shift_left ? (i-28 < 0 ? 0 : shift_operand[i-28]) : (i+28 > 31 ? shift_emptybit : shift_operand[i+28]))
								| (shift_count == 5'd29) & (shift_left ? (i-29 < 0 ? 0 : shift_operand[i-29]) : (i+29 > 31 ? shift_emptybit : shift_operand[i+29]))
								| (shift_count == 5'd30) & (shift_left ? (i-30 < 0 ? 0 : shift_operand[i-30]) : (i+30 > 31 ? shift_emptybit : shift_operand[i+30]))
								| (shift_count == 5'd31) & (shift_left ? (i-31 < 0 ? 0 : shift_operand[i-31]) : (i+31 > 31 ? shift_emptybit : shift_operand[i+31]))
								;
	end
endgenerate
*/

// Logic
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
wire logic_op = inst_AND | inst_ANDI | inst_OR | inst_ORI | inst_XOR
						| inst_XORI | inst_NOR;
wire [31:0] logic_a, logic_b, logic_result;
assign logic_a = op0;
assign logic_b = imm_op ? {{16{inst_i[15]}},inst_i[15:0]} : op1;
assign logic_result = (logic_a & logic_b) & {32{inst_AND | inst_ANDI}}
							|(logic_a | logic_b) & {32{inst_OR | inst_ORI}}
							|(logic_a ^ logic_b) & {32{inst_XOR | inst_XORI}}
							|(logic_a ^~ logic_b) & {32{inst_NOR}};
wire [31:0] lui_result = {inst_i[15:0], 16'b0};

// Memory
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

// Link
wire inst_BGEZAL = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b10001;
wire inst_BLTZAL = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b10000;
wire inst_JAL = inst_i[31:26] == 6'b000011;
wire inst_JALR = inst_i[31:26] == 6'b000000 && inst_i[20:16] == 5'b00000
					&& inst_i[5:0] == 6'b001001;
wire link_op = inst_BGEZAL | inst_BLTZAL | inst_JAL | inst_JALR;

// mtc0
wire inst_MTC0 = inst_i[31:21] == 11'b01000000100 &&
						inst_i[10:3] == 8'b00000000;

endmodule
