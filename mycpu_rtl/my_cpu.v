module my_cpu(
    input         resetn, 
    input         clk,

    //display data
	output        wb_valid,
	output [31:0] wb_pc,
	output [31:0] rf_0,
	output [31:0] rf_1,
	output [31:0] rf_2,
	output [31:0] rf_3,
	output [31:0] rf_4,
	output [31:0] rf_5,
	output [31:0] rf_6,
	output [31:0] rf_7,
	output [31:0] rf_8,
	output [31:0] rf_9,
	output [31:0] rf_10,
	output [31:0] rf_11,
	output [31:0] rf_12,
	output [31:0] rf_13,
	output [31:0] rf_14,
	output [31:0] rf_15,
	output [31:0] rf_16,
	output [31:0] rf_17,
	output [31:0] rf_18,
	output [31:0] rf_19,
	output [31:0] rf_20,
	output [31:0] rf_21,
	output [31:0] rf_22,
	output [31:0] rf_23,
	output [31:0] rf_24,
	output [31:0] rf_25,
	output [31:0] rf_26,
	output [31:0] rf_27,
	output [31:0] rf_28,
	output [31:0] rf_29,
	output [31:0] rf_30,
	output [31:0] rf_31

);
//INST SRAM: 0xbfff_8000 ~ 0xbfff_ffff
wire [3 :0] inst_sram_cen;
wire        inst_sram_wr;
wire [31:0] inst_sram_addr;
wire [31:0] inst_sram_wdata;
wire        inst_sram_ack  = 1'b1;
wire        inst_sram_rrdy =1'b1;
wire [31:0] inst_sram_rdata;

//DATA SRAM: 0xbfff_0000 ~ 0xbfff_7fff
wire [3 :0] data_sram_cen;
wire        data_sram_wr;
wire [31:0] data_sram_addr;
wire [31:0] data_sram_wdata;
wire        data_sram_ack  = 1'b1;
wire        data_sram_rrdy = 1'b1;
wire [31:0] data_sram_rdata;

// CPU IP
fairy_top fairy(
    .aclk             (clk    ),
    .areset_n         (resetn ),

    .inst_sram_cen    (inst_sram_cen  ),
    .inst_sram_wr     (inst_sram_wr   ),
    .inst_sram_addr   (inst_sram_addr ),
    .inst_sram_wdata  (inst_sram_wdata),
    .inst_sram_ack    (inst_sram_ack  ),
    .inst_sram_rrdy   (inst_sram_rrdy ),
    .inst_sram_rdata  (inst_sram_rdata),
    
    .data_sram_cen    (data_sram_cen  ),
    .data_sram_wr     (data_sram_wr   ),
    .data_sram_addr   (data_sram_addr ),
    .data_sram_wdata  (data_sram_wdata),
    .data_sram_ack    (data_sram_ack  ),
    .data_sram_rrdy   (data_sram_rrdy ),
    .data_sram_rdata  (data_sram_rdata),

    //display data
    .regfile_00       (rf_0     ),
    .regfile_01       (rf_1     ),
    .regfile_02       (rf_2     ),
    .regfile_03       (rf_3     ),
    .regfile_04       (rf_4     ),
    .regfile_05       (rf_5     ),
    .regfile_06       (rf_6     ),
    .regfile_07       (rf_7     ),
    .regfile_08       (rf_8     ),
    .regfile_09       (rf_9     ),
    .regfile_10       (rf_10    ),
    .regfile_11       (rf_11    ),
    .regfile_12       (rf_12    ),
    .regfile_13       (rf_13    ),
    .regfile_14       (rf_14    ),
    .regfile_15       (rf_15    ),
    .regfile_16       (rf_16    ),
    .regfile_17       (rf_17    ),
    .regfile_18       (rf_18    ),
    .regfile_19       (rf_19    ),
    .regfile_20       (rf_20    ),
    .regfile_21       (rf_21    ),
    .regfile_22       (rf_22    ),
    .regfile_23       (rf_23    ),
    .regfile_24       (rf_24    ),
    .regfile_25       (rf_25    ),
    .regfile_26       (rf_26    ),
    .regfile_27       (rf_27    ),
    .regfile_28       (rf_28    ),
    .regfile_29       (rf_29    ),
    .regfile_30       (rf_30    ),
    .regfile_31       (rf_31    ),
    
    .ex_pc            (wb_pc),
    .rs_valid         (wb_valid)
);

//inst sram
parameter INST_INIT_FILE = "none";
inst_ram #(.INST_INIT_FILE(INST_INIT_FILE)) inst_ram(
    .clka (clk                              ),
    .wea  (inst_sram_cen & {4{inst_sram_wr}}),
    .addra(inst_sram_addr[15:2]             ),
    .dina (inst_sram_wdata                  ),
    .douta(inst_sram_rdata                  )
);

//data sram
data_ram data_ram(
    .clka (clk                              ),
    .wea  (data_sram_cen & {4{data_sram_wr}}),
    .addra(data_sram_addr[15:2]             ),
    .dina (data_sram_wdata                  ),
    .douta(data_sram_rdata                  )
);
endmodule

