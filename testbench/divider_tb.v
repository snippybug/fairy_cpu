`timescale 1ns / 1ps

module divider_tb;

reg clk,resetn;
initial begin
	clk = 1'b0;
	resetn = 1'b0;
	#30
	resetn = 1'b1;
end

always #15 clk = ~clk;

reg unsigned [31:0] x;
reg unsigned [31:0] y;
wire unsigned [31:0] res_q, res_r;
wire unsigned [31:0] ref_q, ref_r;
wire ready = 1;
wire valid;
wire [1:0] debug_state;
wire [62:0] debug_shift_reg;
wire [31:0] debug_divisor;

divider test(
	.clk(clk),
	.reset_n(resetn),
	.ready_i(ready),
	.valid_o(valid),
	.dividend_i(x),
	.divisor_i(y),
	.quotient_o(res_q),
	.remainder_o(res_r),
	.debug_state(debug_state),
	.debug_shift_reg(debug_shift_reg),
	.debug_divisor(debug_divisor)
);

always #10 x = $random;
always #10 y = $random;

assign ref_q = x / y;
assign ref_r = x % y;

initial begin
	#2000 $finish;
end

endmodule
