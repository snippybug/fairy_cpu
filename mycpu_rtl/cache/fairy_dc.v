module fairy_dc(
	input clk,
	input reset_n,
	
	// data flow
	input [31:0] dc_addr_i,
	input [31:0] dc_wdata_i,
	input [3:0] dc_cen_i,
	input dc_wr_i,
	output [31:0] dc_rdata_o,
	input [31:0] dc_addr_latch_i,
	
	input dc_en_i,
	input dc_lru_we_i,
	
	// exception
	output dc_stall_o,
	
	// debug
	output [31:0] debug_rdata0,
	output [31:0] debug_rdata1,
	output [31:0] debug_rtag0,
	output [31:0] debug_rtag1,
	output [31:0] debug_valid0,
	output [31:0] debug_valid1,
	output [31:0] debug_state,
	output [31:0] debug_miss,
	output [31:0] debug_counter,
	
	// memory
	input [31:0] data_sram_rdata_i,
	output [31:0] data_sram_addr_o,
	output [3:0] data_sram_cen_o,
	output [31:0] data_sram_wdata_o,
	output data_sram_wr_o
);

// output
assign dc_rdata_o = mux_data;
assign dc_stall_o = cache_miss | write_stall;
assign debug_rdata0 = rdata0;
assign debug_rdata1 = rdata1;
assign debug_rtag0 = {{15'b0}, rtag0};
assign debug_rtag1 = {{15'b0}, rtag1};
assign debug_valid0 = {32{valid0}};
assign debug_valid1 = {32{valid1}};
assign debug_state = {{29'b0}, state};
assign debug_miss = {32{cache_miss}};
assign debug_counter = {{30'b0}, counter};

// internal signals
wire [12:0] data_index_i = dc_addr_i[14:2];
wire [12:0] data_index_latch_i = dc_addr_latch_i[14:2];
wire [10:0] block_index_i = dc_addr_i[14:4];
wire [10:0] block_index_latch_i = dc_addr_latch_i[14:4];
wire [16:0] addr_tag_i = dc_addr_i[31:15];
wire [16:0] addr_tag_latch_i = dc_addr_latch_i[31:15];
wire cache_write = dc_wr_i;

// mux
wire [31:0] rdata0, rdata1;
wire [16:0] rtag0, rtag1;
wire rws0, rws1;
wire valid0 = rws0;
wire valid1 = rws1;
wire lru_bit;

reg [16:0] addr_tag;
// addr_tag
always@(posedge clk)
begin
	if(reset_n == 0)
		addr_tag <= 0;
	else if(state == NORMAL || state == MISS)
		addr_tag <= {17{state == NORMAL}} & addr_tag_i
					|{17{state == MISS}} & addr_tag_latch_i
					;
		
end
wire hit0 = valid0 & (rtag0 == addr_tag);
wire hit1 = valid1 & (rtag1 == addr_tag);
wire cache_hit = hit0 | hit1;
wire cache_miss = dc_en_i & (~cache_hit | (state != NORMAL));

wire [31:0] mux_data = {32{hit0}} & rdata0
                    | {32{hit1}} & rdata1
                    ;
wire [12:0] data_index = {13{state == NORMAL}} & data_index_i
								|{13{state == REFILL || state == MISS}} & replace_data_index
								|{13{state == READ || state == WRITE}} & data_index_latch_i
								;
wire [10:0] block_index = cache_miss ? block_index_latch_i : block_index_i;

wire w0_we = w0_refill_we | w0_store_we;
wire w1_we = w1_refill_we | w1_store_we;
reg w0_refill_we, w1_refill_we;

// w0_refill_we
always @(posedge clk)
begin
	if(reset_n == 0)
		w0_refill_we <= 0;
	else if(state == MISS || state == REFILL)
		w0_refill_we <= (state == MISS) & ((~valid0 & valid1) | ((valid0 ^~ valid1) & ~lru_bit))
				|(state == REFILL) & (counter != 0) & w0_refill_we
				;
end

// w1_refill_we
always @(posedge clk)
begin
	if(reset_n == 0)
		w1_refill_we <= 0;
	else if(state == MISS || state == REFILL)
		w1_refill_we <= (state == MISS) & ((valid0 & ~valid1) | ((valid0 ^~ valid1) & lru_bit))
				|(state == REFILL) & (counter != 0) & w1_refill_we
				;
end

wire [31:0] wdata0 = {32{state == REFILL}} & mem_data
						| {32{state == WRITE}} & write_buffer
						;
wire [31:0] wdata1 = wdata0;
wire [16:0] wtag0 = addr_tag_latch_i;
wire [16:0] wtag1 = addr_tag_latch_i;
wire wws0 = 1'b1;
wire wws1 = 1'b1;
wire lru_we = ~cache_miss & dc_lru_we_i;
wire lru_wbit = hit0 ? 1'b1 : 1'b0;

dc_data_array darray_w0(
  .clka(clk),
  .wea(w0_we),
  .addra(data_index),
  .dina(wdata0),
  .douta(rdata0)
);

dc_data_array darray_w1(
  .clka(clk),
  .wea(w1_we),
  .addra(data_index),
  .dina(wdata1),
  .douta(rdata1)
);

dc_tag_array tarray_w0(
  .clka(clk),
  .wea(w0_refill_we),
  .addra(block_index),
  .dina(wtag0),
  .douta(rtag0)
);

dc_tag_array tarray_w1(
  .clka(clk),
  .wea(w1_refill_we),
  .addra(block_index),
  .dina(wtag1),
  .douta(rtag1)
);

dc_ws_array ws_array_w0(
  .clka(clk),
  .wea(w0_refill_we),
  .addra(block_index),
  .dina(wws0),
  .douta(rws0)
);

dc_ws_array ws_array_w1(
  .clka(clk),
  .wea(w1_refill_we),
  .addra(block_index),
  .dina(wws1),
  .douta(rws1)
);

dc_lru_array lru_array(
	.clka(clk),
	.wea(lru_we),
	.addra(block_index_latch_i),
	.dina(lru_wbit),
	.clkb(clk),
	.addrb(block_index),
	.doutb(lru_bit)
);

// state machine
parameter NORMAL = 3'b000,
			MISS = 3'b010,
			REFILL = 3'b011,
			READ = 3'b001,
			WRITE = 3'b100
			;
reg [2:0] state;
always@(posedge clk)
begin
	if(reset_n == 0)
		state <= NORMAL;
	else
		case(state)
			NORMAL:
				if(cache_miss)
					state <= MISS;
				else if(cache_write)
					state <= WRITE;
			MISS:
				state <= REFILL;
			REFILL:
				if(counter == 0)
					state <= READ;
			READ:
				state <= NORMAL;
			WRITE:
				state <= NORMAL;
		endcase
end

// cache refill
wire [31:0] mem_data = data_sram_rdata_i;
wire [12:0] replace_data_index = {13{counter == 0}} & {block_index_latch_i, 2'b11}
					| {13{counter == 1}} & {block_index_latch_i, 2'b00}
					| {13{counter == 2}} & {block_index_latch_i, 2'b01}
					| {13{counter == 3}} & {block_index_latch_i, 2'b10}
					;

reg [1:0] counter;
always@(posedge clk)
begin
	if(state == NORMAL && cache_miss == 1)
		counter <= 0;
	else if(state != NORMAL)
		counter <= counter + 1;
end

// cache write
wire write_stall = state == WRITE;
wire w0_store_we = (state == WRITE) & hit0;
wire w1_store_we = (state == WRITE) & hit1;
reg [31:0] write_buffer;

// write_buffer
always@(posedge clk)
begin
	if(reset_n == 0)
		write_buffer <= 0;
	else if(cache_write)
		write_buffer <= dc_wdata_i;
end

// memory
reg [3:0] data_sram_cen;

// data_sram_cen
always @(posedge clk)
begin
	if(reset_n == 0)
		data_sram_cen <= 0;
	else
		data_sram_cen <= dc_cen_i;
end

wire [31:0] data_sram_addr = state == WRITE ? dc_addr_latch_i : {dc_addr_latch_i[31:4], counter, 2'b00};
assign data_sram_addr_o = data_sram_addr;
assign data_sram_cen_o = data_sram_cen;
assign data_sram_wdata_o = write_buffer;
assign data_sram_wr_o = state == WRITE;

endmodule // fairy_dc
