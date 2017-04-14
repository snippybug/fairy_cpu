module divider(
	input clk,
	input reset_n,
	
	input ready_i,
	output valid_o,
	
	output [1:0] debug_state,
	output [62:0] debug_shift_reg,
	output [31:0] debug_divisor,
	
	input [31:0] dividend_i,
	input [31:0] divisor_i,
	output [31:0] quotient_o,
	output [31:0] remainder_o
);

// Output
assign valid_o = valid;
assign remainder_o = (sub_res[32] ? shift_reg[62:31] : sub_res[31:0]);
assign quotient_o = {shift_reg[30:0], ~sub_res[32]};
assign debug_state = state;
assign debug_shift_reg = shift_reg;
assign debug_divisor = divisor;

wire valid = (state == OUTPUT);

reg [4:0] counter;
reg [62:0] shift_reg;
reg [31:0] divisor;
reg [1:0] state;

// state
parameter IDLE = 2'b00, 
			 READ_OP = 2'b01, 
			 COMPUTING = 2'b10,
			 OUTPUT = 2'b11;
always @(posedge clk)
begin
	if(reset_n == 0)
		state <= IDLE;
	else
		case(state)
			IDLE:
				if(ready_i)
					state <= READ_OP;
			READ_OP:
				state <= COMPUTING;
			COMPUTING:
				if(counter == 0)
					state <= OUTPUT;
			OUTPUT:
				if(ready_i)
					state <= READ_OP;
				else
					state <= IDLE;
		endcase
end

// divisor
always @(posedge clk)
begin
	if(state == READ_OP)
		divisor <= divisor_i;
end

// counter
always @(posedge clk)
begin
	counter <= {5{state == READ_OP}} & 5'b11110
				| {5{state == COMPUTING}} & (counter - 1)
				;
end

// shift_reg
always @(posedge clk)
begin
	if(state == READ_OP)
		shift_reg <= {31'b0, dividend_i};	// unsigned
	else if(state == COMPUTING) begin
		shift_reg[0] <= ~sub_res[32];
		shift_reg[31:1] <= shift_reg[30:0];
		shift_reg[62:32] <= (sub_res[32] ? shift_reg[61:31] : sub_res[30:0]);
	end
end

// subtractor
wire [32:0] sub_res = {1'b0, shift_reg[62:31]} - {1'b0, divisor};

endmodule // divider