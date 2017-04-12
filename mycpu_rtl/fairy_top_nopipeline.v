module fairy_top_nopipeline(
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

// Exception
wire exception;
assign exception = ~areset_n | adder_overflow | mem_addr_error
						| inst_BREAK | inst_SYSCALL
						;

wire pc_decrease;
reg pc_decrease_ctr;
always @(posedge aclk)
begin
	if(areset_n == 0)
		pc_decrease_ctr = 1;
	else if(mem_load_op == 1)
		pc_decrease_ctr = 0;
	else
		pc_decrease_ctr = 1;
end
assign pc_decrease = pc_decrease_ctr & mem_load_op;
// inst SRAM Interface
wire [31:0] pc;
reg  [31:0] nextpc;	// program counter + 4
reg  [31:0] ir;	// instruction register
assign inst_sram_cen = 4'b0;	// always valid
assign inst_sram_wr = 0;		// always read
assign inst_sram_addr = nextpc;
assign pc = nextpc - 4;
// nextpc
always @(posedge aclk)
begin
	if(exception) begin
		if(areset_n == 0)
			nextpc <= 32'hbfc00000;
		else
			nextpc <= 32'hbfc00380;
	end
	else begin
		if(pc_decrease)
			nextpc <= pc;
		else if(branch_valid)
			if(inst_J | inst_JAL)
				nextpc <= {nextpc[31:28], ir[25:0], 2'b00};
			else if(inst_JR | inst_JALR)
				nextpc <= jump_target;
			else
				nextpc <= branch_target;
		else
			nextpc <= nextpc + 4;
	end
end
// ir
reg ir_valid;
always @(posedge aclk)
begin
	if(exception | branch_valid)
		ir_valid <= 0;
	else
		ir_valid <= 1;
end
always @(posedge aclk)
begin
	if(exception)
		ir <= 32'b0;
	else if(ir_valid)
		if(mem_load_op)
			if(pc_decrease)
				ir <= ir;
			else
				ir <= 32'b0;
		else
			ir <= inst_sram_rdata;
end

// CP0
reg [31:0] cp0_epc;
wire is_bd;		// branch delay
assign is_bd = 0;
always @(posedge aclk)
begin
	if(adder_overflow)
		if(is_bd)
			cp0_epc <= nextpc - 12;
		else
			cp0_epc <= nextpc - 8;
end
reg [31:0] cp0_badvaddr;
always @(posedge aclk)
begin
	if(mem_addr_error)
		cp0_badvaddr <= data_sram_addr;
end

// cp0_status
wire [31:0] cp0_status_value;
reg	cp0_status_exl;
always @(posedge aclk)
begin
	if(adder_overflow)
		cp0_status_exl <= 1'b1;
end
assign cp0_status_value = {30'b0, cp0_status_exl, 1'b0};
// cp0_cause
wire [31:0] cp0_cause_value;
reg [4:0] cp0_cause_exccode;
always @(posedge aclk)
begin
	if(adder_overflow)
		cp0_cause_exccode <= 5'd12;
	else if(mem_addr_error && mem_load_op)
		cp0_cause_exccode <= 5'd4;
	else if(mem_addr_error && mem_store_op)
		cp0_cause_exccode <= 5'd5;
	else if(inst_BREAK)
		cp0_cause_exccode <= 5'd9;
	else if(inst_SYSCALL)
		cp0_cause_exccode <= 5'd8;
end
assign cp0_cause_value = {25'b0, cp0_cause_exccode, 2'b0};

// Instruction Signal
wire inst_ADDU, inst_ADDIU, inst_SUBU;
wire inst_ADD, inst_ADDI, inst_SUB;
wire inst_SLT, inst_SLTI, inst_SLTU, inst_SLTIU;
wire inst_SLL, inst_SLLV, inst_SRL, inst_SRLV, inst_SRA, inst_SRAV;
wire inst_AND, inst_ANDI, inst_OR, inst_ORI, inst_XOR, inst_XORI, inst_NOR, inst_LUI;
wire inst_LB, inst_LBU, inst_LH, inst_LHU, inst_LW;
wire inst_SB, inst_SH, inst_SW;
wire inst_BEQ, inst_BNE, inst_BGEZ, inst_BGTZ, inst_BLEZ, inst_BLTZ;
wire inst_J, inst_JR;
wire inst_BGEZAL, inst_BLTZAL, inst_JAL, inst_JALR;
wire inst_BREAK, inst_SYSCALL;
wire inst_MTC0, inst_MFC0;
wire inst_ERET;

assign inst_ADDU = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100001;
assign inst_ADDIU = ir[31:26] == 6'b001001;
assign inst_SUBU = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100011;
assign inst_ADD = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100000;
assign inst_ADDI = ir[31:26] == 6'b001000;
assign inst_SUB = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100010;
assign inst_SLT = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b101010;
assign inst_SLTI = ir[31:26] == 6'b001010;
assign inst_SLTIU = ir[31:26] == 6'b001011;
assign inst_SLTU = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b101011;
assign inst_SLL = ir[31:26] == 6'b000000 && ir[25:21] == 5'b00000
						&& ir[5:0] == 6'b000000;
assign inst_SLLV = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b000100;
assign inst_SRL = ir[31:26] == 6'b000000 && ir[25:21] == 5'b00000
						&& ir[5:0] == 6'b000010;
assign inst_SRLV = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b000110;
assign inst_SRA = ir[31:26] == 6'b000000 && ir[25:21] == 5'b00000
						&& ir[5:0] == 6'b000011;
assign inst_SRAV = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b000111;
assign inst_AND = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100100;
assign inst_ANDI = ir[31:26] == 6'b001100;
assign inst_OR = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100101;
assign inst_ORI = ir[31:26] == 6'b001101;
assign inst_XOR = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100110;
assign inst_XORI = ir[31:26] == 6'b001110;
assign inst_NOR = ir[31:26] == 6'b000000 && ir[10:6] == 5'b00000
						&& ir[5:0] == 6'b100111;
assign inst_LUI = ir[31:26] == 6'b001111 && ir[25:21] == 5'b00000;
assign inst_LB = ir[31:26] == 6'b100000;
assign inst_LBU = ir[31:26] == 6'b100100;
assign inst_LH = ir[31:26] == 6'b100001;
assign inst_LHU = ir[31:26] == 6'b100101;
assign inst_LW = ir[31:26] == 6'b100011;
assign inst_SB = ir[31:26] == 6'b101000;
assign inst_SH = ir[31:26] == 6'b101001;
assign inst_SW = ir[31:26] == 6'b101011;
assign inst_BEQ = ir[31:26] == 6'b000100;
assign inst_BNE = ir[31:26] == 6'b000101;
assign inst_BGEZ = ir[31:26] == 6'b000001 && ir[20:16] == 5'b00001;
assign inst_BGTZ = ir[31:26] == 6'b000111 && ir[20:16] == 5'b00000;
assign inst_BLEZ = ir[31:26] == 6'b000110 && ir[20:16] == 5'b00000;
assign inst_BLTZ = ir[31:26] == 6'b000001 && ir[20:16] == 5'b00000;
assign inst_J = ir[31:26] == 6'b000010;
assign inst_JR = ir[31:26] == 6'b000000 && ir[20:11] == 10'b0000000000
					&& ir[5:0] == 6'b001000;
assign inst_BGEZAL = ir[31:26] == 6'b000001 && ir[20:16] == 5'b10001;
assign inst_BLTZAL = ir[31:26] == 6'b000001 && ir[20:16] == 5'b10000;
assign inst_JAL = ir[31:26] == 6'b000011;
assign inst_JALR = ir[31:26] == 6'b000000 && ir[20:16] == 5'b00000
					&& ir[5:0] == 6'b001001;
assign inst_BREAK = ir[31:26] == 6'b000000 && ir[5:0] == 6'b001101;
assign inst_SYSCALL = ir[31:26] == 6'b000000 && ir[5:0] == 6'b001100;
assign inst_MTC0 = ir[31:21] == 11'b01000000100 &&
						ir[10:3] == 8'b00000000;
assign inst_MFC0 = ir[31:21] == 11'b01000000000 &&
						ir[10:3] == 8'b00000000;
assign inst_ERET = ir[31:0] == 32'h42000018;

wire imm_op, sub_op, add_op;
assign imm_op = inst_ADDIU | inst_ADDI | inst_SLTI | inst_SLTIU
					| inst_ANDI | inst_ORI | inst_XORI
					| inst_LUI
					| mem_load_op | mem_store_op
					;
// Adder
assign add_op = inst_ADDU | inst_ADDIU | inst_ADD | inst_ADDI;
assign sub_op = inst_SUBU | inst_SUB;
wire [31:0] adder_a, adder_b, adder_sum;
wire [31:0] adder_b0;	// value from reg or imm
wire adder_c0;
wire adder_overflow;
assign adder_sum = adder_a + adder_b + {31'b0, adder_c0};
assign adder_a = branch_op ? pc : reg_rdata0;		// rs
assign adder_b0 = imm_op ? {{16{ir[15]}},ir[15:0]} : reg_rdata1;
assign adder_b = {32{sub_op | slt_op}} & ~adder_b0
					| {32{add_op}} & adder_b0
					| {32{branch_op}} & {{14{ir[15]}}, ir[15:0], 2'b00}
					;
assign adder_c0 = (sub_op | slt_op) ? 1'b1 : 1'b0;
assign adder_overflow = (~adder_a[31] & ~adder_b[31] & adder_sum[31])
							| (adder_a[31] & adder_b[31] & ~adder_sum[31]);

// slt & sltu
assign slt_op = slts_op | sltu_op;
assign slts_op = inst_SLT | inst_SLTI;
assign sltu_op = inst_SLTIU | inst_SLTU;
wire lt;		// less than
assign lt = sltu_op & adder_sum[31]		// unsigned
			| slts_op & (		// signed
				(adder_a[31] ^~ adder_b[31]) & adder_sum[31]		// same sign
				| (adder_a[31] ^ adder_b[31]) & (adder_a[31] ? 1'b1 : 1'b0)	// different sign
			);

// shifter
wire [31:0] shift_operand, shift_result;
wire [4:0] shift_count;
wire shift_left, shift_logic, shift_emptybit;
wire shift_op = inst_SLL | inst_SRL | inst_SRA | shift_var_op;
wire shift_var_op = inst_SLLV | inst_SRLV | inst_SRAV;
assign shift_logic = inst_SLL | inst_SLLV | inst_SRL | inst_SRLV;
assign shift_emptybit = shift_logic ? 1'b0 : shift_operand[31];
assign shift_left = inst_SLL | inst_SLLV;
assign shift_operand = reg_rdata1;	// from rt
assign shift_count = shift_var_op ? reg_rdata0[4:0] : ir[10:6];	// [4:0] from rs : sa
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

// logic operation
wire logic_op;
assign logic_op = inst_AND | inst_ANDI | inst_OR | inst_ORI | inst_XOR
						| inst_XORI | inst_NOR;
wire [31:0] logic_a, logic_b, logic_result;
assign logic_a = reg_rdata0;
assign logic_b = imm_op ? {{16{ir[15]}},ir[15:0]} : reg_rdata1;
assign logic_result = (logic_a & logic_b) & {32{inst_AND | inst_ANDI}}
							|(logic_a | logic_b) & {32{inst_OR | inst_ORI}}
							|(logic_a ^ logic_b) & {32{inst_XOR | inst_XORI}}
							|(logic_a ^~ logic_b) & {32{inst_NOR}};
wire [31:0] lui_result;
assign lui_result = {ir[15:0], 16'b0};

// Memory
wire mem_load_op, mem_store_op;
wire mem_addr_error;
wire [31:0] mem_rdata;
assign mem_load_op = inst_LB | inst_LBU | inst_LH | inst_LHU | inst_LW;
assign mem_store_op = inst_SB | inst_SH | inst_SW;
assign data_sram_addr = adder_sum;
assign data_sram_cen = {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b00}} & 4'b0001
							| {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b01}} & 4'b0010
							| {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b10}} & 4'b0100
							| {4{inst_SB}} & {4{data_sram_addr[1:0] == 2'b11}} & 4'b1000
							| {4{inst_SH}} & {4{data_sram_addr[1] == 0}} & 4'b0011
							| {4{inst_SH}} & {4{data_sram_addr[1] == 1}} & 4'b1100
							| {4{inst_SW}} & 4'b1111
							;

assign data_sram_wr = mem_store_op;
assign mem_rdata = ({32{inst_LB}} & {32{data_sram_addr[1:0] == 2'b00}} & {{28{data_sram_rdata[7]}}, data_sram_rdata[7:0]})
						|({32{inst_LB}} & {32{data_sram_addr[1:0] == 2'b01}} & {{28{data_sram_rdata[15]}}, data_sram_rdata[15:8]})
						|({32{inst_LB}} & {32{data_sram_addr[1:0] == 2'b10}} & {{28{data_sram_rdata[23]}}, data_sram_rdata[23:16]})
						|({32{inst_LB}} & {32{data_sram_addr[1:0] == 2'b11}} & {{28{data_sram_rdata[31]}}, data_sram_rdata[31:24]})
						|({32{inst_LBU}} & {32{data_sram_addr[1:0] == 2'b00}} & {28'b0, data_sram_rdata[7:0]})
						|({32{inst_LBU}} & {32{data_sram_addr[1:0] == 2'b01}} & {28'b0, data_sram_rdata[15:8]})
						|({32{inst_LBU}} & {32{data_sram_addr[1:0] == 2'b10}} & {28'b0, data_sram_rdata[23:16]})
						|({32{inst_LBU}} & {32{data_sram_addr[1:0] == 2'b11}} & {28'b0, data_sram_rdata[31:24]})
						|({32{inst_LH}} & {32{data_sram_addr[1] == 0}} & {{16{data_sram_rdata[15]}}, data_sram_rdata[15:0]})
						|({32{inst_LH}} & {32{data_sram_addr[1] == 1}} & {{16{data_sram_rdata[31]}}, data_sram_rdata[31:16]})
						|({32{inst_LHU}} & {32{data_sram_addr[1] == 0}} & {16'b0, data_sram_rdata[15:0]})
						|({32{inst_LHU}} & {32{data_sram_addr[1] == 1}} & {16'b0, data_sram_rdata[31:16]})
						|({32{inst_LW}} & data_sram_rdata)
						;
assign data_sram_wdata = {32{inst_SB}} & {4{reg_rdata1[7:0]}}
								|{32{inst_SH}} & {2{reg_rdata1[15:0]}}
								|{32{inst_SW}} & reg_rdata1[31:0];
								
assign mem_addr_error = (inst_LH & data_sram_addr[0])
							|	(inst_LHU & data_sram_addr[0])
							|	(inst_SH & data_sram_addr[0])
							|	(inst_LW & (|data_sram_addr[1:0]))
							|	(inst_SW & (|data_sram_addr[1:0]))
							;

// Branch
wire branch_link_op = inst_BGEZAL | inst_BLTZAL | inst_JAL | inst_JALR;
wire branch_valid;
wire branch_op = inst_BEQ | inst_BNE | inst_BGEZ | inst_BGTZ | inst_BLEZ
					| inst_BLTZ | inst_BGEZAL | inst_BLTZAL;
wire [31:0] branch_cmp_a, branch_cmp_b, branch_cmp_res;
wire [31:0] branch_target;
assign branch_cmp_a = reg_rdata0;	// rs
assign branch_cmp_b = reg_rdata1;	// rt
assign branch_cmp_res = branch_cmp_a - branch_cmp_b;
assign branch_target = adder_sum;
assign branch_valid = inst_BEQ & ~(|branch_cmp_res)
						| inst_BNE & (|branch_cmp_res)
						| (inst_BGEZ | inst_BGEZAL) & ~branch_cmp_a[31]
						| inst_BGTZ & ~branch_cmp_a[31] & (|branch_cmp_a)
						| inst_BLEZ & (branch_cmp_a[31] | ~(|branch_cmp_a))
						| (inst_BLTZ | inst_BLTZAL) & branch_cmp_a[31]
						| jump_op
						;

// Jump
wire jump_op = inst_J | inst_JR | inst_JAL | inst_JALR;
wire [31:0] jump_target;
assign jump_target = reg_rdata0;		// rs

// debug use
assign regfile_25 = {32{data_sram_wr}};
assign regfile_26 = data_sram_wdata;
assign regfile_27 = data_sram_rdata;
assign regfile_28 = data_sram_addr;
assign regfile_29 = ir;
assign regfile_30 = nextpc;

// Register signal
wire reg_we;
wire [4:0] reg_waddr;
wire [4:0] reg_raddr0, reg_raddr1;
wire [31:0] reg_rdata0, reg_rdata1;
wire [31:0] reg_wdata;
assign reg_we = add_op | sub_op | slt_op | shift_op | logic_op | inst_LUI
					| (mem_load_op & ~pc_decrease)
					| branch_link_op
					;
assign reg_waddr = imm_op ? ir[20:16] : 
						(inst_BGEZAL | inst_BLTZAL | inst_JAL) ? 5'b11111
						: ir[15:11];	// including JALR
assign reg_raddr0 = ir[25:21];	// rs
assign reg_raddr1 = ir[20:16];	// rt
assign reg_wdata = {31'b0, lt} & {32{slt_op}}
						| adder_sum & {32{add_op | sub_op}}
						| shift_result & {32{shift_op}}
						| logic_result & {32{logic_op}}
						| lui_result & {32{inst_LUI}}
						| mem_rdata & {32{mem_load_op}}
						| nextpc & {32{branch_link_op}}
						;
// Register File
rf2r1w u0_rf(
	.clock(aclk),
	
	.raddr0(reg_raddr0),
	.rdata0(reg_rdata0),
	.raddr1(reg_raddr1),
	.rdata1(reg_rdata1),
	
	.we(reg_we),
	.waddr(reg_waddr),
	.wdata(reg_wdata),
	
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
	//.regfile_21(regfile_21),
	//.regfile_22(regfile_22),
	//.regfile_23(regfile_23),
	//.regfile_24(regfile_24),
	//.regfile_25(regfile_25)
	//.regfile_26(regfile_26),
	//.regfile_27(regfile_27),
	//.regfile_28(regfile_28),
	//.regfile_29(regfile_29)
	//.regfile_30(regfile_30),
	.regfile_31(regfile_31)
);

endmodule // fairy_top

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
