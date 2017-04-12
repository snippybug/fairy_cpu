`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:30:01 03/26/2017 
// Design Name: 
// Module Name:    fairy_decode_stage 
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
module fairy_decode_stage(
   input clk,
	input reset_n,
	
	input [31:0] inst_i,
	input	reg_we_i,
	input [4:0] reg_waddr_i,
	input [31:0] reg_wdata_i,
	input [31:0] pc_i,
	input exception_i,
	input eret_i,
	
	output [31:0] op0_o,
	output [31:0] op1_o,
	output [31:0] inst_o,
	output [31:0] pc_o,
	output [31:0] branch_target_o,
	output branch_valid_o,
	output [4:0] reg_waddr_o,
	output reg_we_o,
	
	input [4:0] conflict_addr0_i,
	input [4:0] conflict_addr1_i,	
	input [1:0] conflict_hilo0_i,
	input [1:0] conflict_hilo1_i,
	output stall_o,
	output delayslot_o,
	
	input hilo_we_i,
	input hilo_sel_i,
	output hilo_we_o,
	output hilo_sel_o,
	
	input unaligned_addr_i,
	output unaligned_addr_o,
	output illegal_inst_o,
	
	output [31:0] debug_reg_raddr0,
	output [31:0] debug_reg_raddr1,
	output [31:0] debug_imm_op,
	output [31:0] debug_reg_rdata1,
	output [31:0] debug_lo,
	output [31:0] debug_hi,
	output [31:0] debug_delayslot_mark,
	
	output [31:0]  regfile_00,
	output [31:0]  regfile_01,
	output [31:0]  regfile_02,
	output [31:0]  regfile_03,
	output [31:0]  regfile_04,
	output [31:0]  regfile_05,
	output [31:0]  regfile_06,
	output [31:0]  regfile_07,
	output [31:0]  regfile_08,
	output [31:0]  regfile_09,
	output [31:0]  regfile_10,
	output [31:0]  regfile_11,
	output [31:0]  regfile_12,
	output [31:0]  regfile_13,
	output [31:0]  regfile_14,
	output [31:0]  regfile_15,
	output [31:0]  regfile_16,
	output [31:0]  regfile_17,
	output [31:0]  regfile_18,
	output [31:0]  regfile_19,
	output [31:0]  regfile_20,
	output [31:0]  regfile_21,
	output [31:0]  regfile_22,
	output [31:0]  regfile_23,
	output [31:0]  regfile_24,
	output [31:0]  regfile_25,
	output [31:0]  regfile_26,
	output [31:0]  regfile_27,
	output [31:0]  regfile_28,
	output [31:0]  regfile_29,
	output [31:0]  regfile_30,
	output [31:0]  regfile_31
);

// Input
wire [4:0] conflict_addr0 = conflict_addr0_i;
wire [4:0] conflict_addr1 = conflict_addr1_i;
// Output
assign inst_o = inst;
assign op0_o = op0;
assign op1_o = op1;
assign pc_o = pc;
assign branch_target_o = branch_target;
assign branch_valid_o = ~stall & branch_valid;
assign reg_waddr_o = reg_waddr;
assign reg_we_o = reg_we;
assign stall_o = stall;
assign delayslot_o = delayslot;
assign hilo_we_o = hilo_we;
assign hilo_sel_o = hilo_sel;
assign unaligned_addr_o = unaligned_addr;
assign illegal_inst_o = illegal_inst;
assign debug_reg_raddr0 = reg_raddr0;
assign debug_reg_raddr1 = reg_raddr1;
assign debug_imm_op = {32{imm_op}};
assign debug_reg_rdata1 = reg_rdata1;
assign debug_lo = lo;
assign debug_hi = hi;
assign debug_delayslot_mark = {32{delayslot_mark}};

wire reset = ~reset_n | exception_i | eret_i;

// data dependence
wire inst_op_rs = inst_ADDIU | inst_ADDI | inst_SLTI | inst_SLTIU
					| inst_ANDI | inst_ORI | inst_XORI
					| inst_LB | inst_LBU | inst_LH | inst_LHU | inst_LW
					| inst_BGEZ | inst_BGTZ | inst_BLEZ | inst_BLTZ
					| inst_JR
					| inst_BGEZAL | inst_BLTZAL | inst_JALR
					| inst_MTLO | inst_MTHI
					;
wire inst_MTC0 = inst_i[31:21] == 11'b01000000100 &&
						inst_i[10:3] == 8'b00000000;
wire inst_op_rt = inst_SLL | inst_SRL | inst_SRA | inst_MTC0;
wire inst_op_rs_rt = inst_ADDU | inst_SUBU | inst_ADD | inst_SUB
						| inst_SLT | inst_SLTU | inst_SLLV | inst_SRLV | inst_SRAV
						| inst_AND | inst_OR | inst_XOR | inst_NOR
						| inst_SB | inst_SH | inst_SW
						| inst_BEQ | inst_BNE
						;
wire stall = (inst_op_rs | inst_op_rs_rt) & (inst_i[25:21] == reg_waddr) & (|reg_waddr)
				| (inst_op_rs | inst_op_rs_rt) & (inst_i[25:21] == conflict_addr0) & (|conflict_addr0)
				| (inst_op_rs | inst_op_rs_rt) & (inst_i[25:21] == conflict_addr1) & (|conflict_addr1)
				| (inst_op_rt | inst_op_rs_rt) & (inst_i[20:16] == reg_waddr) & (|reg_waddr)
				| (inst_op_rt | inst_op_rs_rt) & (inst_i[20:16] == conflict_addr0) & (|conflict_addr0)
				| (inst_op_rt | inst_op_rs_rt) & (inst_i[20:16] == conflict_addr1) & (|conflict_addr1)
				| inst_MFHI & (conflict_hilo0_i[1] & conflict_hilo0_i[0])	
				| inst_MFHI & (conflict_hilo1_i[1] & conflict_hilo1_i[0])
				| inst_MFHI & (hilo_we & hilo_sel)
				| inst_MFLO & (conflict_hilo0_i[1] & ~conflict_hilo0_i[0])
				| inst_MFLO & (conflict_hilo1_i[1] & ~conflict_hilo1_i[0])
				| inst_MFLO & (hilo_we & ~hilo_sel)
				;

// add, sub, slt
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
wire inst_SLT = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b101010;
wire inst_SLTI = inst_i[31:26] == 6'b001010;
wire inst_SLTIU = inst_i[31:26] == 6'b001011;
wire inst_SLTU = inst_i[31:26] == 6'b000000 && inst_i[10:6] == 5'b00000
						&& inst_i[5:0] == 6'b101011;
wire slt_op = inst_SLT | inst_SLTI | inst_SLTIU | inst_SLTU;
wire add_op = inst_ADDU | inst_ADDIU | inst_ADD | inst_ADDI;
wire sub_op = inst_SUBU | inst_SUB;

// memory
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

// Branch
wire inst_BEQ = inst_i[31:26] == 6'b000100;
wire inst_BNE = inst_i[31:26] == 6'b000101;
wire inst_BGEZ = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b00001;
wire inst_BGTZ = inst_i[31:26] == 6'b000111 && inst_i[20:16] == 5'b00000;
wire inst_BLEZ = inst_i[31:26] == 6'b000110 && inst_i[20:16] == 5'b00000;
wire inst_BLTZ = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b00000;
wire inst_J = inst_i[31:26] == 6'b000010;
wire inst_JR = inst_i[31:26] == 6'b000000 && inst_i[20:11] == 10'b0000000000
					&& inst_i[5:0] == 6'b001000;
wire inst_BGEZAL = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b10001;
wire inst_BLTZAL = inst_i[31:26] == 6'b000001 && inst_i[20:16] == 5'b10000;
wire inst_JAL = inst_i[31:26] == 6'b000011;
wire inst_JALR = inst_i[31:26] == 6'b000000 && inst_i[20:16] == 5'b00000
					&& inst_i[5:0] == 6'b001001;					

wire branch_op = inst_BEQ | inst_BNE | inst_BGEZ | inst_BGTZ
					| inst_BLEZ | inst_BLTZ
					| inst_BGEZAL | inst_BLTZAL
					;
wire jump_op = inst_J | inst_JR
					| inst_JAL | inst_JALR
					;
wire branch_valid = (inst_BEQ & (branch_a == branch_b))
					| (inst_BNE & ~(branch_a == branch_b))
					| ((inst_BGEZ | inst_BGEZAL) & ~branch_a[31])
					| (inst_BGTZ & ~branch_a[31] & (|branch_a))
					| (inst_BLEZ & (branch_a[31] | ~(|branch_a)))
					| ((inst_BLTZ | inst_BLTZAL) & branch_a[31])
					| jump_op
					;
wire [31:0] branch_target = {32{branch_op}} & (pc_i + 4 + {{14{inst_i[15]}}, inst_i[15:0], 2'b00})
									| {32{inst_J | inst_JAL}} & {pc_i[31:28], inst_i[25:0], 2'b00}
									| {32{inst_JR | inst_JALR}} & branch_a
									;
wire [31:0] branch_a = reg_rdata0;
wire [31:0] branch_b = reg_rdata1;

// lo & hi
wire inst_MFLO = inst_i[31:16] == 16'b0 && inst_i[10:6] == 5'b00000
					&& inst_i[5:0] == 6'b010010;
wire inst_MFHI = inst_i[31:16] == 16'b0 && inst_i[10:6] == 5'b00000
					&& inst_i[5:0] == 6'b010000;
wire inst_MTLO = inst_i[31:26] == 6'b0 && inst_i[20:6] == 15'b0
					&& inst_i[5:0] == 6'b010011;
wire inst_MTHI = inst_i[31:26] == 6'b0 && inst_i[20:6] == 15'b0
					&& inst_i[5:0] == 6'b010001;
wire hilo_op = inst_MFLO | inst_MFHI | inst_MTLO | inst_MTHI;

// exception
wire inst_BREAK = inst_i[31:26] == 6'b000000 && inst_i[5:0] == 6'b001101;
wire inst_SYSCALL = inst_i[31:26] == 6'b000000 && inst_i[5:0] == 6'b001100;
wire exception_op = inst_BREAK | inst_SYSCALL;
wire inst_ERET = inst_i[31:0] == 32'h42000018;

// shift
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
wire shift_op = inst_SLL | inst_SLLV | inst_SRL | inst_SRLV | inst_SRA | inst_SRAV;

// logic
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
wire logic_op = inst_AND | inst_ANDI | inst_OR | inst_ORI | inst_XOR
						| inst_XORI | inst_NOR;
wire inst_LUI = inst_i[31:26] == 6'b001111 && inst_i[25:21] == 5'b00000;

// Register
wire [4:0] reg_raddr0, reg_raddr1;
wire [31:0] reg_rdata0, reg_rdata1;
assign reg_raddr0 = inst_i[25:21];	// rs
assign reg_raddr1 = inst_i[20:16];	// rt

reg [31:0] inst;
reg [31:0] op0, op1;
reg [31:0] pc;
reg [4:0] reg_waddr;
reg reg_we;
reg [31:0] hi;
reg [31:0] lo;
reg delayslot_mark;
reg delayslot;
reg hilo_we;
reg hilo_sel;
reg unaligned_addr;
reg illegal_inst;

// illegal_inst
always @(posedge clk)
begin
	if(reset | stall)
		illegal_inst <= 0;
	else
		illegal_inst <= ~(
					add_op | sub_op | slt_op |
					mem_op | branch_op | jump_op |
					hilo_op |
					inst_MTC0 | inst_MFC0 |
					shift_op | logic_op | inst_LUI |
					exception_op | inst_ERET
					);
end

// unaligned_addr
always @(posedge clk)
begin
	if(reset | stall)
		unaligned_addr <= 0;
	else
		unaligned_addr <= unaligned_addr_i;
end

// hilo_we
always @(posedge clk)
begin
	if(reset | stall)
		hilo_we <= 0;
	else
		hilo_we <= inst_MTHI | inst_MTLO;
end

// hilo_sel
always @(posedge clk)
begin
	if(reset | stall)
		hilo_sel <= 0;
	else
		hilo_sel <= inst_MTHI;
end

// delayslot
always @(posedge clk)
begin
	if(reset | stall)
		delayslot <= 0;
	else 
		delayslot <= delayslot_mark;
end

// delayslot_mark
always @(posedge clk)
begin
	if(reset)
		delayslot_mark <= 0;
	else if(stall)
		delayslot_mark <= delayslot_mark;
	else
		delayslot_mark <= branch_op | jump_op;
end

// hi
always @(posedge clk)
begin
	if(reset_n == 0)
		hi <= 32'b0;
	else if(hilo_we_i == 1 && hilo_sel_i == 1)
		hi <= reg_wdata_i;
end

// lo
always @(posedge clk)
begin
	if(reset_n == 0)
		lo <= 32'b0;
	else if(hilo_we_i == 1 && hilo_sel_i == 0)
		lo <= reg_wdata_i;
end

// reg_we
always @(posedge clk)
begin
	if(reset | stall)
		reg_we <= 0;
	else
		reg_we <= (|inst_i) & 
					(add_op | sub_op | slt_op | shift_op
					| logic_op | inst_LUI
					| mem_load_op
					| link_op
					| inst_MFC0
					| inst_MFLO | inst_MFHI)
					;
end

wire link_op = inst_BGEZAL | inst_BLTZAL | inst_JAL | inst_JALR;
wire imm_op = inst_ADDIU | inst_ADDI | inst_SLTI | inst_SLTIU
				| inst_ANDI | inst_ORI | inst_XORI
				| inst_LUI
				| mem_load_op
				;
wire inst_MFC0 = inst_i[31:21] == 11'b01000000000 &&
						inst_i[10:3] == 8'b00000000;
wire rt_op = imm_op | inst_MFC0;
// reg_waddr
always @(posedge clk)
begin
	if(reset | stall)
		reg_waddr <= 32'b0;
	else
		reg_waddr <= rt_op ? inst_i[20:16] :
					link_op ? 5'd31 : inst_i[15:11];
end

// inst
always @(posedge clk)
begin
	if(reset | stall)
		inst <= 32'b0;
	else
		inst <= inst_i;
end

// op0
always @(posedge clk)
begin
	if(reset | stall)
		op0 <= 32'b0;
	else
		op0 <= reg_rdata0;
end

// op1
always @(posedge clk)
begin
	if(reset | stall)
		op1 <= 32'b0;
	else
		op1 <= {32{inst_MFLO}} & lo
				|{32{inst_MFHI}} & hi
				|{32{inst_MTLO | inst_MTHI}} & reg_rdata0
				|{32{~inst_MFLO & ~inst_MFHI}} & reg_rdata1;
end

// pc
always @(posedge clk)
begin
	if(reset | stall)
		pc <= 32'b0;
	else
		pc <= pc_i;
end

// Register File
rf2r1w u0_rf(
	.clock(clk),
	
	.raddr0(reg_raddr0),
	.rdata0(reg_rdata0),
	.raddr1(reg_raddr1),
	.rdata1(reg_rdata1),
	
	.we(reg_we_i),
	.waddr(reg_waddr_i),
	.wdata(reg_wdata_i),
	
	.regfile_00(regfile_00),
	.regfile_01(regfile_01),
	.regfile_02(regfile_02),
	.regfile_03(regfile_03),
	.regfile_04(regfile_04),
	.regfile_05(regfile_05),
	.regfile_06(regfile_06),
	.regfile_07(regfile_07),
	.regfile_08(regfile_08),
	.regfile_09(regfile_09),
	.regfile_10(regfile_10),
	
	.regfile_11(regfile_11),
	.regfile_12(regfile_12),
	.regfile_13(regfile_13),
	.regfile_14(regfile_14),
	.regfile_15(regfile_15),
	.regfile_16(regfile_16),
	.regfile_17(regfile_17),
	.regfile_18(regfile_18),
	.regfile_19(regfile_19),
	.regfile_20(regfile_20),
	
	.regfile_21(regfile_21),
	.regfile_22(regfile_22),
	.regfile_23(regfile_23),
	.regfile_24(regfile_24),
	.regfile_25(regfile_25),
	.regfile_26(regfile_26),
	.regfile_27(regfile_27),
	.regfile_28(regfile_28),
	.regfile_29(regfile_29),
	.regfile_30(regfile_30),
	.regfile_31(regfile_31)
);

endmodule

module rf2r1w(
	clock,
	
	raddr0, rdata0,
	raddr1, rdata1,
	
	we, waddr, wdata,
	
	regfile_00,
	regfile_01,
	regfile_02,
	regfile_03,
	regfile_04,
	regfile_05,
	regfile_06,
	regfile_07,
	regfile_08,
	regfile_09,
	regfile_10,
	regfile_11,
	regfile_12,
	regfile_13,
	regfile_14,
	regfile_15,
	regfile_16,
	regfile_17,
	regfile_18,
	regfile_19,
	regfile_20,
	regfile_21,
	regfile_22,
	regfile_23,
	regfile_24,
	regfile_25,
	regfile_26,
	regfile_27,
	regfile_28,
	regfile_29,
	regfile_30,
	regfile_31
);

input           clock;

input   [ 4:0]  raddr0;
output  [31:0]  rdata0;
input   [ 4:0]  raddr1;
output  [31:0]  rdata1;

input           we;
input   [ 4:0]  waddr;
input   [31:0]  wdata;

output [31:0]  regfile_00;
output [31:0]  regfile_01;
output [31:0]  regfile_02;
output [31:0]  regfile_03;
output [31:0]  regfile_04;
output [31:0]  regfile_05;
output [31:0]  regfile_06;
output [31:0]  regfile_07;
output [31:0]  regfile_08;
output [31:0]  regfile_09;
output [31:0]  regfile_10;
output [31:0]  regfile_11;
output [31:0]  regfile_12;
output [31:0]  regfile_13;
output [31:0]  regfile_14;
output [31:0]  regfile_15;
output [31:0]  regfile_16;
output [31:0]  regfile_17;
output [31:0]  regfile_18;
output [31:0]  regfile_19;
output [31:0]  regfile_20;
output [31:0]  regfile_21;
output [31:0]  regfile_22;
output [31:0]  regfile_23;
output [31:0]  regfile_24;
output [31:0]  regfile_25;
output [31:0]  regfile_26;
output [31:0]  regfile_27;
output [31:0]  regfile_28;
output [31:0]  regfile_29;
output [31:0]  regfile_30;
output [31:0]  regfile_31;

reg [31:0] regfile[31:0];

// write register
always @(posedge clock)
begin
	if (we) begin
		regfile[waddr] <= wdata;
	end
	regfile[0] <= 32'b0;
end

// read register
assign rdata0 = raddr0 == 5'b0 ? 0 : regfile[raddr0];
assign rdata1 = raddr1 == 5'b0 ? 0 : regfile[raddr1];

assign regfile_00 = regfile[0];
assign regfile_01 = regfile[1];
assign regfile_02 = regfile[2];
assign regfile_03 = regfile[3];
assign regfile_04 = regfile[4];
assign regfile_05 = regfile[5];
assign regfile_06 = regfile[6];
assign regfile_07 = regfile[7];
assign regfile_08 = regfile[8];
assign regfile_09 = regfile[9];
assign regfile_10 = regfile[10];
assign regfile_11 = regfile[11];
assign regfile_12 = regfile[12];
assign regfile_13 = regfile[13];
assign regfile_14 = regfile[14];
assign regfile_15 = regfile[15];
assign regfile_16 = regfile[16];
assign regfile_17 = regfile[17];
assign regfile_18 = regfile[18];
assign regfile_19 = regfile[19];
assign regfile_20 = regfile[20];
assign regfile_21 = regfile[21];
assign regfile_22 = regfile[22];
assign regfile_23 = regfile[23];
assign regfile_24 = regfile[24];
assign regfile_25 = regfile[25];
assign regfile_26 = regfile[26];
assign regfile_27 = regfile[27];
assign regfile_28 = regfile[28];
assign regfile_29 = regfile[29];
assign regfile_30 = regfile[30];
assign regfile_31 = regfile[31];

endmodule // rf2r1w
