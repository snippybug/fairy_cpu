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
	output [31:0] debug_load_data,
	output [31:0] debug_data,
	output [31:0] debug_dc_rdata0,
	output [31:0] debug_dc_rdata1,
	output [31:0] debug_dc_rtag0,
	output [31:0] debug_dc_rtag1,
	output [31:0] debug_dc_valid0,
	output [31:0] debug_dc_valid1,
	output [31:0] debug_dc_state,
	output [31:0] debug_dc_miss,
	output [31:0] debug_dc_counter,
	output [31:0] debug_inst,
	
	// exception
	output stall_o,
	input exception_i,
	input eret_i
);

// Input
wire [31:0] mem_rdata = dc_rdata;
// Output
assign inst_o = stall ? 0 : inst;
assign pc_o = stall ? 0 : pc;
assign overflow_o = stall ? 0 : overflow;
assign unaligned_addr_o = stall ? 0 : unaligned_addr;
assign data_o = {64{mem_load_next_op}} & {32'b0, load_data}
					|{64{stall}} & 0
					|{64{~mem_load_next_op & ~stall}} & data;
assign reg_waddr_o = stall ? 0 : reg_waddr;
assign reg_we_o = stall ? 0 : reg_we;
assign delayslot_o = stall ? 0 : delayslot;
assign hilo_we_o = stall ? 0 : hilo_we;
assign illegal_inst_o = stall ? 0 : illegal_inst;
assign stall_o = stall;
assign debug_load_data = load_data;
assign debug_data = data;
assign debug_inst = inst;

// global
wire reset = ~reset_n | exception_i | eret_i;
wire stall = dc_stall;

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
	else if(stall == 0)
		op1 <= op1_i;
end

// illegal_inst
always @(posedge clk)
begin
	if(reset)
		illegal_inst <= 0;
	else if(stall == 0)
		illegal_inst <= illegal_inst_i;
end

// unaligned_addr
always @(posedge clk)
begin
	if(reset)
		unaligned_addr <= 0;
	else if(stall == 0)
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
	else if(stall == 0)
		hilo_we <= hilo_we_i;
end

// delayslot
always @(posedge clk)
begin
	if(reset)
		delayslot <= 0;
	else if(stall == 0)
		delayslot <= delayslot_i;
end

// reg_we
always @(posedge clk)
begin
	if(reset)
		reg_we <= 0;
	else if(stall == 0)
		reg_we <= reg_we_i;
end

// reg_waddr
always @(posedge clk)
begin
	if(reset)
		reg_waddr <= 0;
	else if(stall == 0)
		reg_waddr <= reg_waddr_i;
end

// overflow
always @(posedge clk)
begin
	if(reset)
		overflow <= 0;
	else if(stall == 0)
		overflow <= overflow_i;
end

// pc
always @(posedge clk)
begin
	if(reset)
		pc <= 0;
	else if(stall == 0)
		pc <= pc_i;
end

// inst
always @(posedge clk)
begin
	if(reset)
		inst <= 0;
	else if(stall == 0)
		inst <= inst_i;
end

// data
always @(posedge clk)
begin
	if(reset)
		data <= 0;
	else if(stall == 0)
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
wire inst_LWL = inst_i[31:26] == 6'b100010;
wire inst_LWR = inst_i[31:26] == 6'b100110;
wire inst_LWL_next = inst[31:26] == 6'b100010;
wire inst_LWR_next = inst[31:26] == 6'b100110;
wire inst_SWL = inst_i[31:26] == 6'b101010;
wire inst_SWR = inst_i[31:26] == 6'b101110;
wire mem_load_next_op = inst_LB_next | inst_LBU_next | inst_LH_next
							| inst_LHU_next | inst_LW_next
							| inst_LWL_next | inst_LWR_next
							;
wire mem_load_op = inst_LB | inst_LBU | inst_LH
							| inst_LHU | inst_LW
							| inst_LWL | inst_LWR
							;
wire mem_store_op = inst_SB | inst_SH | inst_SW |
						inst_SWL | inst_SWR
						;

wire [31:0] load_data = ({32{inst_LB_next}} & {32{data[1:0] == 2'b00}} & {{28{mem_rdata[7]}}, mem_rdata[7:0]})
							|({32{inst_LB_next}} & {32{data[1:0] == 2'b01}} & {{28{mem_rdata[15]}}, mem_rdata[15:8]})
							|({32{inst_LB_next}} & {32{data[1:0] == 2'b10}} & {{28{mem_rdata[23]}}, mem_rdata[23:16]})
							|({32{inst_LB_next}} & {32{data[1:0] == 2'b11}} & {{28{mem_rdata[31]}}, mem_rdata[31:24]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b00}} & {28'b0, mem_rdata[7:0]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b01}} & {28'b0, mem_rdata[15:8]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b10}} & {28'b0, mem_rdata[23:16]})
							|({32{inst_LBU_next}} & {32{data[1:0] == 2'b11}} & {28'b0, mem_rdata[31:24]})
							|({32{inst_LH_next}} & {32{data[1] == 0}} & {{16{mem_rdata[15]}}, mem_rdata[15:0]})
							|({32{inst_LH_next}} & {32{data[1] == 1}} & {{16{mem_rdata[31]}}, mem_rdata[31:16]})
							|({32{inst_LHU_next}} & {32{data[1] == 0}} & {16'b0, mem_rdata[15:0]})
							|({32{inst_LHU_next}} & {32{data[1] == 1}} & {16'b0, mem_rdata[31:16]})
							|({32{inst_LW_next}} & mem_rdata)
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b00}} & {mem_rdata[7:0], op1[23:0]})
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b01}} & {mem_rdata[15:0], op1[15:0]})
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b10}} & {mem_rdata[23:0], op1[7:0]})
							|({32{inst_LWL_next}} & {32{data[1:0] == 2'b11}} & mem_rdata)
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b00}} & mem_rdata)
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b01}} & {op1[31:24], mem_rdata[31:8]})
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b10}} & {op1[31:16], mem_rdata[31:16]})
							|({32{inst_LWR_next}} & {32{data[1:0] == 2'b11}} & {op1[31:8], mem_rdata[31:24]})
							;

wire [3:0] mem_cen = {4{inst_SB}} & {4{data_i[1:0] == 2'b00}} & 4'b0001
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

wire mem_wr = ~(exception_i | unaligned_addr_store) & mem_store_op;
wire [31:0] mem_wdata = {32{inst_SB}} & {4{op1_i[7:0]}}
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

// data cache
wire [31:0] dc_addr = data_i[31:0];
wire [31:0] dc_rdata;
wire [31:0] dc_wdata = mem_wdata;
wire [3:0] dc_cen = mem_cen;
wire dc_wr = mem_wr;
wire dc_stall;
wire dc_en = mem_load_next_op;
wire dc_lru_we = mem_load_next_op;
fairy_dc data_cache(
	.clk(clk),
	.reset_n(reset_n),
	
	// data path
	.dc_addr_i(dc_addr),
	.dc_rdata_o(dc_rdata),
	.dc_wdata_i(dc_wdata),
	.dc_cen_i(dc_cen),
	.dc_wr_i(dc_wr),
	.dc_addr_latch_i(data),
	
	.dc_en_i(dc_en),
	.dc_stall_o(dc_stall),
	.dc_lru_we_i(dc_lru_we),
	
	// debug
	.debug_rdata0(debug_dc_rdata0),
	.debug_rdata1(debug_dc_rdata1),
	.debug_rtag0(debug_dc_rtag0),
	.debug_rtag1(debug_dc_rtag1),
	.debug_valid0(debug_dc_valid0),
	.debug_valid1(debug_dc_valid1),
	.debug_state(debug_dc_state),
	.debug_miss(debug_dc_miss),
	.debug_counter(debug_dc_counter),
	
	// memory
	.data_sram_rdata_i(data_sram_rdata_i),
	.data_sram_addr_o(data_sram_addr_o),
	.data_sram_cen_o(data_sram_cen_o),
	.data_sram_wdata_o(data_sram_wdata_o),
	.data_sram_wr_o(data_sram_wr_o)
);

endmodule // fairy_mem_stage
