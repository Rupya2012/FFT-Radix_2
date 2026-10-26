`timescale 1ns/1ps

module fft_top #(
    parameter ADDR_WIDTH   = 12,
    parameter WORD_WIDTH   = 64,
    parameter DATA_WIDTH   = 32,
    parameter REAL_LENGTH  = 16,
    parameter FRACTIONAL_L = 14
)(
    input clk,
    input clk_enb,
    input rstn,
    input cpu_intrpt,

    input iram_wr_enbl,
    input [ADDR_WIDTH-1:0]iram_wr_addr,
    input [WORD_WIDTH-1:0]iram_wr_data,

    input  oram_rd_enbl,
    input  [ADDR_WIDTH-1:0]oram_rd_addr,
    output [WORD_WIDTH-1:0]oram_rd_data,
     
    output reg valid,
    output  done,
    output  busy,
    output  [3:0]lvl,
    output  [WORD_WIDTH-1:0]y
);
  
   wire new_clk ;
   reg clk_enb_latched;
   always @(*) begin
     if(!clk)begin
      clk_enb_latched <=  (clk_enb || cpu_intrpt);
    end
   end
   assign new_clk = clk_enb_latched & clk ;



    wire [ADDR_WIDTH-1:0] buff_ram_wr_addr;
    wire [3:0]            lvl_int;
    assign lvl = lvl_int;
    wire i_buff_read_sel;
    wire dFF1_enbl;
    wire dFF2_enbl;
    wire mux2x1_sel;
    wire mux2x2_sel;
    wire dFFw_enbl;
    wire mux1w_sel;
    wire wref_ff_enbl;
    wire mux2w_sel;

    wire dFF1_enbl_s;
    wire dFF2_enbl_s;
    wire mux1s_sel;
    wire mux2s_sel;

    wire ctrl_iram_rd_enbl;
    wire ctrl_iram_wr_enbl;
    wire buff_rd_enbl;
    wire buff_wr_enbl;
    wire ctrl_oram_rd_enbl;
    wire oram_wr_enbl;
    wire add_gen_en_l;
    wire add_gen_en_s;
    wire add_0_1_l;
    wire add_0_1_s;
    wire tw_en;
    wire waste_cycle;
    wire counter_rst_l;
    wire counter_rst_s;
    wire tw_count_en;
    wire lvl_enb;

    wire effective_iram_wr_enbl = iram_wr_enbl | ctrl_iram_wr_enbl;
    wire effective_oram_rd_enbl = oram_rd_enbl | ctrl_oram_rd_enbl;

    control #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_control (
        .clk(new_clk),
        .rstn(rstn),
        .lvl(lvl_int),
        .buff_ram_wr_addr(buff_ram_wr_addr),

        .i_buff_read_sel(i_buff_read_sel),
        .dFF1_enbl(dFF1_enbl),
        .dFF2_enbl(dFF2_enbl),
        .mux2x1_sel(mux2x1_sel),
        .mux2x2_sel(mux2x2_sel),
        .dFFw_enbl(dFFw_enbl),
        .mux1w_sel(mux1w_sel),
        .wref_ff_enbl(wref_ff_enbl),
        .mux2w_sel(mux2w_sel),

        .dFF1_enbl_s(dFF1_enbl_s),
        .dFF2_enbl_s(dFF2_enbl_s),
        .mux1s_sel(mux1s_sel),
        .mux2s_sel(mux2s_sel),

        .iram_rd_enbl(ctrl_iram_rd_enbl),
        .iram_wr_enbl(ctrl_iram_wr_enbl),
        .buff_rd_enbl(buff_rd_enbl),
        .buff_wr_enbl(buff_wr_enbl),
        .oram_rd_enbl(ctrl_oram_rd_enbl),
        .oram_wr_enbl(oram_wr_enbl),

        .add_gen_en_l(add_gen_en_l),
        .add_gen_en_s(add_gen_en_s),
        .add_0_1_l(add_0_1_l),
        .add_0_1_s(add_0_1_s),
        .tw_en(tw_en),
        .waste_cycle(waste_cycle),
        .counter_rst_l(counter_rst_l),
        .counter_rst_s(counter_rst_s),
        .tw_count_en(tw_count_en),
        .lvl_enb(lvl_enb),
        .done(done),
        .busy(busy)
    );

    datapath #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WORD_WIDTH(WORD_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .REAL_LENGTH(REAL_LENGTH),
        .FRACTIONAL_L(FRACTIONAL_L)
    ) u_datapath (
        .clk(new_clk),
        .rstn(rstn),

        .i_buff_read_sel(i_buff_read_sel),
        .dFF1_enbl(dFF1_enbl),
        .dFF2_enbl(dFF2_enbl),
        .mux2x1_sel(mux2x1_sel),
        .mux2x2_sel(mux2x2_sel),
        .dFFw_enbl(dFFw_enbl),
        .mux1w_sel(mux1w_sel),
        .wref_ff_enbl(wref_ff_enbl),
        .mux2w_sel(mux2w_sel),

        .dFF1_enbl_s(dFF1_enbl_s),
        .dFF2_enbl_s(dFF2_enbl_s),
        .mux1s_sel(mux1s_sel),
        .mux2s_sel(mux2s_sel),

        .iram_rd_enbl(ctrl_iram_rd_enbl),
        .iram_wr_enbl(effective_iram_wr_enbl),
        .buff_rd_enbl(buff_rd_enbl),
        .buff_wr_enbl(buff_wr_enbl),
        .oram_rd_enbl(effective_oram_rd_enbl),
        .oram_wr_enbl(oram_wr_enbl),

        .add_gen_en_l(add_gen_en_l),
        .add_gen_en_s(add_gen_en_s),
        .add_0_1_l(add_0_1_l),
        .add_0_1_s(add_0_1_s),
        .tw_en(tw_en),
        .waste_cycle(waste_cycle),
        .counter_rst_l(counter_rst_l),
        .counter_rst_s(counter_rst_s),
        .tw_count_en(tw_count_en),
        .lvl_enb(lvl_enb),

        .iram_wr_addr(iram_wr_addr),
        .iram_wr_data(iram_wr_data),
        .oram_rd_addr(oram_rd_addr),
        .oram_rd_data(oram_rd_data),

        .buff_ram_wr_addr(buff_ram_wr_addr),
        .lvl(lvl_int),
        .y(y)
    );

always @(*) begin 
    if(!cpu_intrpt && lvl == 4'd12)begin
        valid <= 1'b1;
    end
    else begin valid <= 1'b0; end 
end

endmodule
