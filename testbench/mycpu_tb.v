`timescale 1ns/1ps

`define NO_UNALIGNED
`ifdef NO_UNALIGNED
    `define INST_INIT_FILE "../../../func_lab5/inst_ram_no_unaligned.mif"
`else
    `define INST_INIT_FILE "../../../func_lab5/inst_ram_unaligned.mif"
`endif

`define TRACE_FILE     "../../../cpu132_gettrace/trace.txt"
`define END_PC         32'hbfc00200

module mycpu_tb;

reg clk,resetn;
initial begin
    clk = 1'b0;
    resetn = 1'b0;
  #1000;
    resetn = 1'b1;
end
always #15.15 clk = ~clk;

//my cpu interface
wire [31:0]  rf_0;
wire [31:0]  rf_1;
wire [31:0]  rf_2;
wire [31:0]  rf_3;
wire [31:0]  rf_4;
wire [31:0]  rf_5;
wire [31:0]  rf_6;
wire [31:0]  rf_7;
wire [31:0]  rf_8;
wire [31:0]  rf_9;
wire [31:0]  rf_10;
wire [31:0]  rf_11;
wire [31:0]  rf_12;
wire [31:0]  rf_13;
wire [31:0]  rf_14;
wire [31:0]  rf_15;
wire [31:0]  rf_16;
wire [31:0]  rf_17;
wire [31:0]  rf_18;
wire [31:0]  rf_19;
wire [31:0]  rf_20;
wire [31:0]  rf_21;
wire [31:0]  rf_22;
wire [31:0]  rf_23;
wire [31:0]  rf_24;
wire [31:0]  rf_25;
wire [31:0]  rf_26;
wire [31:0]  rf_27;
wire [31:0]  rf_28;
wire [31:0]  rf_29;
wire [31:0]  rf_30;
wire [31:0]  rf_31;
wire [31:0]  wb_pc;
wire wb_valid;

//my cpu 寄存器值存一拍，用于与参考trace比较
reg [31:0]  rf_0_r1;
reg [31:0]  rf_1_r1;
reg [31:0]  rf_2_r1;
reg [31:0]  rf_3_r1;
reg [31:0]  rf_4_r1;
reg [31:0]  rf_5_r1;
reg [31:0]  rf_6_r1;
reg [31:0]  rf_7_r1;
reg [31:0]  rf_8_r1;
reg [31:0]  rf_9_r1;
reg [31:0]  rf_10_r1;
reg [31:0]  rf_11_r1;
reg [31:0]  rf_12_r1;
reg [31:0]  rf_13_r1;
reg [31:0]  rf_14_r1;
reg [31:0]  rf_15_r1;
reg [31:0]  rf_16_r1;
reg [31:0]  rf_17_r1;
reg [31:0]  rf_18_r1;
reg [31:0]  rf_19_r1;
reg [31:0]  rf_20_r1;
reg [31:0]  rf_21_r1;
reg [31:0]  rf_22_r1;
reg [31:0]  rf_23_r1;
reg [31:0]  rf_24_r1;
reg [31:0]  rf_25_r1;
reg [31:0]  rf_26_r1;
reg [31:0]  rf_27_r1;
reg [31:0]  rf_28_r1;
reg [31:0]  rf_29_r1;
reg [31:0]  rf_30_r1;
reg [31:0]  rf_31_r1;
always @(posedge clk)
begin
    rf_0_r1  <=rf_0 ;
    rf_1_r1  <=rf_1 ;
    rf_2_r1  <=rf_2 ;
    rf_3_r1  <=rf_3 ;
    rf_4_r1  <=rf_4 ;
    rf_5_r1  <=rf_5 ;
    rf_6_r1  <=rf_6 ;
    rf_7_r1  <=rf_7 ;
    rf_8_r1  <=rf_8 ;
    rf_9_r1  <=rf_9 ;
    rf_10_r1 <=rf_10;
    rf_11_r1 <=rf_11;
    rf_12_r1 <=rf_12;
    rf_13_r1 <=rf_13;
    rf_14_r1 <=rf_14;
    rf_15_r1 <=rf_15;
    rf_16_r1 <=rf_16;
    rf_17_r1 <=rf_17;
    rf_18_r1 <=rf_18;
    rf_19_r1 <=rf_19;
    rf_20_r1 <=rf_20;
    rf_21_r1 <=rf_21;
    rf_22_r1 <=rf_22;
    rf_23_r1 <=rf_23;
    rf_24_r1 <=rf_24;
    rf_25_r1 <=rf_25;
    rf_26_r1 <=rf_26;
    rf_27_r1 <=rf_27;
    rf_28_r1 <=rf_28;
    rf_29_r1 <=rf_29;
    rf_30_r1 <=rf_30;
    rf_31_r1 <=rf_31;
end

//读取trace信息
reg [31:0]  rf_0_ref;
reg [31:0]  rf_1_ref;
reg [31:0]  rf_2_ref;
reg [31:0]  rf_3_ref;
reg [31:0]  rf_4_ref;
reg [31:0]  rf_5_ref;
reg [31:0]  rf_6_ref;
reg [31:0]  rf_7_ref;
reg [31:0]  rf_8_ref;
reg [31:0]  rf_9_ref;
reg [31:0]  rf_10_ref;
reg [31:0]  rf_11_ref;
reg [31:0]  rf_12_ref;
reg [31:0]  rf_13_ref;
reg [31:0]  rf_14_ref;
reg [31:0]  rf_15_ref;
reg [31:0]  rf_16_ref;
reg [31:0]  rf_17_ref;
reg [31:0]  rf_18_ref;
reg [31:0]  rf_19_ref;
reg [31:0]  rf_20_ref;
reg [31:0]  rf_21_ref;
reg [31:0]  rf_22_ref;
reg [31:0]  rf_23_ref;
reg [31:0]  rf_24_ref;
reg [31:0]  rf_25_ref;
reg [31:0]  rf_26_ref;
reg [31:0]  rf_27_ref;
reg [31:0]  rf_28_ref;
reg [31:0]  rf_29_ref;
reg [31:0]  rf_30_ref;
reg [31:0]  rf_31_ref;
reg [31:0]  wb_pc_ref;

//cpu132抓取的正确执行的trace
integer trace_ref;
initial begin
    trace_ref = $fopen(`TRACE_FILE,"r");
end

//mycpu 完成提交
reg [31:0] wb_pc_r1;
always @(posedge clk)
begin
    if (!resetn)
	 begin
         wb_pc_r1    <= 32'd0;
	 end
	 else if (wb_valid)
	 begin
	     wb_pc_r1    <= wb_pc;
	 end
end

always @(posedge clk)
begin
    if(wb_pc != wb_pc_r1 && wb_valid)
	 begin
        $fscanf(trace_ref,"%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h",
                                         wb_pc_ref,rf_0_ref ,rf_1_ref ,rf_2_ref ,rf_3_ref,
                                                   rf_4_ref ,rf_5_ref ,rf_6_ref ,rf_7_ref,
                                                   rf_8_ref ,rf_9_ref ,rf_10_ref,rf_11_ref,
                                                   rf_12_ref,rf_13_ref,rf_14_ref,rf_15_ref,
                                                   rf_16_ref,rf_17_ref,rf_18_ref,rf_19_ref,
                                                   rf_20_ref,rf_21_ref,rf_22_ref,rf_23_ref,
                                                   rf_24_ref,rf_25_ref,rf_26_ref,rf_27_ref,
                                                   rf_28_ref,rf_29_ref,rf_30_ref,rf_31_ref);
    end
end

//读取trace信息
reg read_out;
always @(posedge clk)
begin
    if (!resetn)
    begin
        read_out <= 1'b0; 
    end
    else if(wb_pc != wb_pc_r1 && wb_valid)
	 begin
        read_out <= 1'b1;
    end
    else
    begin
        read_out <= 1'b0;
    end
end

//trace对比
wire [32:0] ok;
wire ok_00;
assign ok_00 = &ok;

assign ok[00] = (rf_0_r1  === rf_0_ref );
assign ok[01] = (rf_1_r1  === rf_1_ref );
assign ok[02] = (rf_2_r1  === rf_2_ref );
assign ok[03] = (rf_3_r1  === rf_3_ref );
assign ok[04] = (rf_4_r1  === rf_4_ref );
assign ok[05] = (rf_5_r1  === rf_5_ref );
assign ok[06] = (rf_6_r1  === rf_6_ref );
assign ok[07] = (rf_7_r1  === rf_7_ref );
assign ok[08] = (rf_8_r1  === rf_8_ref );
assign ok[09] = (rf_9_r1  === rf_9_ref );
assign ok[10] = (rf_10_r1 === rf_10_ref);
assign ok[11] = (rf_11_r1 === rf_11_ref);
assign ok[12] = (rf_12_r1 === rf_12_ref);
assign ok[13] = (rf_13_r1 === rf_13_ref);
assign ok[14] = (rf_14_r1 === rf_14_ref);
assign ok[15] = (rf_15_r1 === rf_15_ref);
assign ok[16] = (rf_16_r1 === rf_16_ref);
assign ok[17] = (rf_17_r1 === rf_17_ref);
assign ok[18] = (rf_18_r1 === rf_18_ref);
assign ok[19] = (rf_19_r1 === rf_19_ref);
assign ok[20] = (rf_20_r1 === rf_20_ref);
assign ok[21] = (rf_21_r1 === rf_21_ref);
assign ok[22] = (rf_22_r1 === rf_22_ref);
assign ok[23] = (rf_23_r1 === rf_23_ref);
assign ok[24] = (rf_24_r1 === rf_24_ref);
assign ok[25] = (rf_25_r1 === rf_25_ref);
assign ok[26] = (rf_26_r1 === rf_26_ref);
assign ok[27] = (rf_27_r1 === rf_27_ref);
assign ok[28] = (rf_28_r1 === rf_28_ref);
assign ok[29] = (rf_29_r1 === rf_29_ref);
assign ok[30] = (rf_30_r1 === rf_30_ref);
assign ok[31] = (rf_31_r1 === rf_31_ref);
assign ok[32] = (wb_pc_r1 === wb_pc_ref);

//trace对比结果打印
always @(negedge clk)
begin
    if(!ok_00 && read_out)
    begin
        $display("Error at PC %h\nError code %h",wb_pc_r1,~ok);
		  #10;
        $finish;
    end
end

//结束仿真
always @(posedge clk)
begin
    if (wb_pc<32'hbfc00000 && wb_pc>32'hbfc0ffff && wb_valid)
	 begin
	     $display("Error: in PC!!!");
         $finish;
	 end
	 else if(wb_pc==`END_PC)
	 begin
         $display("PASS!!!\n");
		 $fclose(trace_ref);
	     $finish;
	 end
end


my_cpu #(.INST_INIT_FILE(`INST_INIT_FILE)) test(
    .clk(clk),
    .resetn(resetn),

    .rf_0(rf_0),
    .rf_1(rf_1),
    .rf_2(rf_2),
    .rf_3(rf_3),
    .rf_4(rf_4),
    .rf_5(rf_5),
    .rf_6(rf_6),
    .rf_7(rf_7),
    .rf_8(rf_8),
    .rf_9(rf_9),
    .rf_10(rf_10),
    .rf_11(rf_11),
    .rf_12(rf_12),
    .rf_13(rf_13),
    .rf_14(rf_14),
    .rf_15(rf_15),
    .rf_16(rf_16),
    .rf_17(rf_17),
    .rf_18(rf_18),
    .rf_19(rf_19),
    .rf_20(rf_20),
    .rf_21(rf_21),
    .rf_22(rf_22),
    .rf_23(rf_23),
    .rf_24(rf_24),
    .rf_25(rf_25),
    .rf_26(rf_26),
    .rf_27(rf_27),
    .rf_28(rf_28),
    .rf_29(rf_29),
    .rf_30(rf_30),
    .rf_31(rf_31),

    .wb_pc(wb_pc),
    .wb_valid(wb_valid)
    );

endmodule
