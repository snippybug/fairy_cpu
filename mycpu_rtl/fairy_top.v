module fairy_top(
	aclk,
	areset_n,

	inst_sram_cen,
	inst_sram_wr,
	inst_sram_addr,
	inst_sram_wdata,
	inst_sram_ack,
	inst_sram_rrdy,
	inst_sram_rdata,

	data_sram_cen,
	data_sram_wr,
	data_sram_addr,
	data_sram_wdata,
	data_sram_ack,
	data_sram_rrdy,
	data_sram_rdata,
	
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
	regfile_31,
  
	ex_pc,
	rs_valid
);

input           aclk;
input           areset_n;

output  [ 3:0]  inst_sram_cen;
output  [31:0]  inst_sram_wdata;
input   [31:0]  inst_sram_rdata;
output          inst_sram_wr;
output  [31:0]  inst_sram_addr;
input           inst_sram_ack;		// don't care
input           inst_sram_rrdy;		// don't care

output  [ 3:0]  data_sram_cen;
output  [31:0]  data_sram_wdata;
input   [31:0]  data_sram_rdata;
output          data_sram_wr;
output  [31:0]  data_sram_addr;
input           data_sram_ack;		// don't care
input           data_sram_rrdy;		// don't care

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

output [31:0]  ex_pc;
output rs_valid;

assign inst_sram_cen = 4'b0000;
assign inst_sram_wr = 0;

wire wb_exception;
wire [31:0] decode_branch_target;
wire decode_branch_valid;
wire fetch_stall;
wire wb_eret;
wire [31:0] wb_epc;
wire [31:0] fetch_inst;
wire [31:0] fetch_pc;
wire fetch_unaligned_addr;
fairy_fetch_stage fetch_stage(
	.clk(aclk),
	.reset_n(areset_n),
	
	.inst_sram_rdata_i(inst_sram_rdata),
	.inst_sram_addr_o(inst_sram_addr),
	
	.exception_i(wb_exception),
	.stall_i(fetch_stall),
	.eret_i(wb_eret),
	.epc_i(wb_epc),
	
	.branch_target_i(decode_branch_target),
	.branch_valid_i(decode_branch_valid),
	
	.inst_o(fetch_inst),
	.pc_o(fetch_pc),
	.unaligned_addr_o(fetch_unaligned_addr)
);
	
wire [31:0] decode_op0, decode_op1;
wire [31:0] decode_inst;
wire [31:0] decode_pc;
wire wb_reg_we;
wire [31:0] wb_reg_wdata;
wire [4:0] wb_reg_waddr;
wire [4:0] decode_reg_waddr;
wire [4:0] exe_reg_waddr;
wire [4:0] mem_reg_waddr;
wire decode_reg_we;
wire decode_delayslot;
wire [1:0] wb_hilo_we;
wire [1:0] exe_hilo_we;
wire [1:0] mem_hilo_we;
wire [1:0] decode_hilo_we;
wire decode_unaligned_addr;
wire decode_illegal_inst;
wire [31:0] debug_decode_delayslot_mark;
wire [31:0] debug_decode_hi;
wire [31:0] debug_decode_lo;
fairy_decode_stage decode_stage(
	.clk(aclk),
	.reset_n(areset_n),
	
	.inst_i(fetch_inst),
	.reg_we_i(wb_reg_we),
	.reg_waddr_i(wb_reg_waddr),
	.reg_wdata_i(wb_reg_wdata),
	
	.illegal_inst_o(decode_illegal_inst),
	
	.exception_i(wb_exception),
	.branch_target_o(decode_branch_target),
	.branch_valid_o(decode_branch_valid),
	.pc_i(fetch_pc),
	.pc_o(decode_pc),
	.eret_i(wb_eret),
	.unaligned_addr_i(fetch_unaligned_addr),
	.unaligned_addr_o(decode_unaligned_addr),
	
	.hilo_we_i(wb_hilo_we),
	.hilo_we_o(decode_hilo_we),
	
	.op0_o(decode_op0),
	.op1_o(decode_op1),
	.inst_o(decode_inst),
	.stall_o(fetch_stall),
	
	.conflict_addr0_i(exe_reg_waddr),
	.conflict_addr1_i(mem_reg_waddr),
	.conflict_hilo0_i(exe_hilo_we),
	.conflict_hilo1_i(mem_hilo_we),
	
	.reg_waddr_o(decode_reg_waddr),
	.reg_we_o(decode_reg_we),
	.delayslot_o(decode_delayslot),
	
	.debug_delayslot_mark(debug_decode_delayslot_mark),
	.debug_hi(debug_decode_hi),
	.debug_lo(debug_decode_lo),
	
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

wire [31:0] exe_data;
wire [31:0] exe_inst;
wire [31:0] exe_pc;
wire [31:0] exe_op1;
wire exe_overflow;
wire exe_reg_we;
wire exe_delayslot;
wire exe_unaligned_addr;
wire exe_illegal_inst;
wire [31:0] debug_exe_adder_sum;
fairy_exe_stage exe_stage(
	.clk(aclk),
	.reset_n(areset_n),
	
	.op0_i(decode_op0),
	.op1_i(decode_op1),
	.inst_i(decode_inst),
	.pc_i(decode_pc),
	.exception_i(wb_exception),
	.delayslot_i(decode_delayslot),
	.eret_i(wb_eret),
	
	.unaligned_addr_i(decode_unaligned_addr),
	.unaligned_addr_o(exe_unaligned_addr),
	.illegal_inst_i(decode_illegal_inst),
	.illegal_inst_o(exe_illegal_inst),
	
	//.debug_adder_b(regfile_23),
	.debug_adder_sum(debug_exe_adder_sum),
	
	.hilo_we_i(decode_hilo_we),
	.hilo_we_o(exe_hilo_we),
	
	.reg_waddr_i(decode_reg_waddr),
	.reg_we_i(decode_reg_we),
	.reg_waddr_o(exe_reg_waddr),
	.reg_we_o(exe_reg_we),
	
	.pc_o(exe_pc),
	.data_o(exe_data),
	.inst_o(exe_inst),
	.overflow_o(exe_overflow),
	.op1_o(exe_op1),
	.delayslot_o(exe_delayslot)
);

wire [31:0] mem_inst;
wire [31:0] mem_data;
wire [31:0] mem_pc;
wire mem_overflow;
wire mem_unaligned_addr;
wire mem_reg_we;
wire mem_delayslot;
wire mem_illegal_inst;
fairy_mem_stage mem_stage(
	.clk(aclk),
	.reset_n(areset_n),
	
	.data_i(exe_data),
	.inst_i(exe_inst),
	.pc_i(exe_pc),
	.op1_i(exe_op1),
	.overflow_i(exe_overflow),
	.exception_i(wb_exception),
	.delayslot_i(exe_delayslot),
	.unaligned_addr_o(mem_unaligned_addr),
	.eret_i(wb_eret),
	.unaligned_addr_i(exe_unaligned_addr),
	
	.hilo_we_i(exe_hilo_we),
	.hilo_we_o(mem_hilo_we),
	.illegal_inst_i(exe_illegal_inst),
	.illegal_inst_o(mem_illegal_inst),
	
	.reg_waddr_i(exe_reg_waddr),
	.reg_we_i(exe_reg_we),
	.reg_waddr_o(mem_reg_waddr),
	.reg_we_o(mem_reg_we),
	
	.data_sram_cen_o(data_sram_cen),
	.data_sram_wdata_o(data_sram_wdata),
	.data_sram_wr_o(data_sram_wr),
	.data_sram_rdata_i(data_sram_rdata),
	.data_sram_addr_o(data_sram_addr),
	
	.inst_o(mem_inst),
	.data_o(mem_data),
	.pc_o(mem_pc),
	.overflow_o(mem_overflow),
	.delayslot_o(mem_delayslot)
	
	//.debug_mem_rdata(regfile_12),
	//.debug_data(regfile_16)
);

wire [31:0] debug_wb_mfc0_data;
wire [31:0] debug_wb_cp0_cause_value;
fairy_writeback_stage wb_stage(
	.clk(aclk),
	.reset_n(areset_n),
	
	.data_i(mem_data),
	.inst_i(mem_inst),
	.pc_i(mem_pc),
	.overflow_i(mem_overflow),
	.unaligned_addr_i(mem_unaligned_addr),
	
	.reg_waddr_i(mem_reg_waddr),
	.reg_we_i(mem_reg_we),
	.delayslot_i(mem_delayslot),
	
	.hilo_we_i(mem_hilo_we),
	.hilo_we_o(wb_hilo_we),
	.illegal_inst_i(mem_illegal_inst),
	
	.debug_mfc0_data(debug_wb_mfc0_data),
	.debug_cp0_cause_value(debug_wb_cp0_cause_value),
	
	.reg_we_o(wb_reg_we),
	.reg_wdata_o(wb_reg_wdata),
	.reg_waddr_o(wb_reg_waddr),
	.exception_o(wb_exception),
	.epc_o(wb_epc),
	.eret_o(wb_eret)
);

assign ex_pc = mem_pc;
assign rs_valid = |ex_pc;
/*
assign regfile_17 = mem_inst;
assign regfile_18 = exe_inst;
assign regfile_19 = decode_inst;
assign regfile_20 = fetch_inst;
assign regfile_21 = mem_data;
assign regfile_22 = exe_data;
assign regfile_23 = decode_op0;
assign regfile_24 = decode_op1;
assign regfile_25 = debug_decode_hi;
assign regfile_26 = debug_decode_lo;
assign regfile_27 = {30'b0, decode_hilo_we};
assign regfile_28 = {30'b0, exe_hilo_we};
assign regfile_29 = {30'b0, mem_hilo_we};
assign regfile_30 = mem_pc;
*/
endmodule // fairytop
