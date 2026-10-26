module datapath #(
    parameter ADDR_WIDTH   = 12,
    parameter WORD_WIDTH   = 64,
    parameter DATA_WIDTH   = 32,
    parameter REAL_LENGTH  = 16,
    parameter FRACTIONAL_L = 14
)(
    input clk,
    input rstn,

    input i_buff_read_sel,
    input dFF1_enbl,
    input dFF2_enbl,
    input mux2x1_sel,
    input mux2x2_sel,
    input dFFw_enbl,
    input mux1w_sel,
    input wref_ff_enbl,
    input mux2w_sel,

    input dFF1_enbl_s,
    input dFF2_enbl_s,
    input mux1s_sel,
    input mux2s_sel,

    input iram_rd_enbl,
    input iram_wr_enbl,
    input buff_rd_enbl,
    input buff_wr_enbl,
    input oram_rd_enbl,
    input oram_wr_enbl,

    input add_gen_en_l,
    input add_gen_en_s,
    input add_0_1_l,
    input add_0_1_s,
    input tw_en,
    input waste_cycle,
    input counter_rst_l,
    input counter_rst_s,
    input tw_count_en,
    input lvl_enb,

    input  [ADDR_WIDTH-1:0] iram_wr_addr,
    input  [WORD_WIDTH-1:0] iram_wr_data,
    input  [ADDR_WIDTH-1:0] oram_rd_addr,
    output [WORD_WIDTH-1:0] oram_rd_data,

    output [ADDR_WIDTH-1:0] buff_ram_wr_addr,
    output [3:0]            lvl,

    output [WORD_WIDTH-1:0] y
);

    wire [3:0] lvl_int;
    assign lvl = lvl_int;

    wire [ADDR_WIDTH-2:0] iram_rd_addr_int;
    wire [ADDR_WIDTH-1:0] buff_rd_addr_int;
    wire [ADDR_WIDTH-1:0] buff_wr_addr_int;
    wire [ADDR_WIDTH-2:0] oram_wr_addr_int;

    assign buff_ram_wr_addr = buff_wr_addr_int;

    wire [WORD_WIDTH-1:0] iram_rd_data;
    wire [WORD_WIDTH-1:0] buff_rd_data;

    wire [WORD_WIDTH-1:0] compute_wr_data;

    lvl u_lvl (
        .clk(clk),
        .rstn(rstn),
        .lvl_enb(lvl_enb),
        .lvl(lvl_int)
    );

    wire count_addr_0;

    i_buff_oram_add #(
        .DATA_WIDTH(WORD_WIDTH),
        .IRAM_ADDR_WIDTH(ADDR_WIDTH-1),
        .BUFF_ADDR_WIDTH(ADDR_WIDTH),
        .ORAM_ADDR_WIDTH(ADDR_WIDTH-1)
    ) u_addr_gen (
        .clk(clk),
        .rstn(rstn),
        .add_gen_en_l(add_gen_en_l),
        .add_gen_en_s(add_gen_en_s),
        .lvl(lvl_int),
        .add_0_1_l(add_0_1_l),
        .add_0_1_s(add_0_1_s),
        .tw_en(tw_en),
        .waste_cycle(waste_cycle),
        .counter_rst_l(counter_rst_l),
        .counter_rst_s(counter_rst_s),
        .tw_count_en(tw_count_en),
        .count_addr_0(count_addr_0),
        .i_ram_rd_addr(iram_rd_addr_int),
        .buff_ram_rd_addr(buff_rd_addr_int),
        .buff_ram_wr_addr(buff_wr_addr_int),
        .oram_wr_addr(oram_wr_addr_int)
    );

    iram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WORD_WIDTH(WORD_WIDTH)
    ) u_iram (
        .clk(clk),
        .rstn(rstn),
        .iram_wr_enbl(iram_wr_enbl),
        .iram_rd_enbl(iram_rd_enbl),
        .iram_wr_addr(iram_wr_addr),
        .iram_rd_addr({1'b0, iram_rd_addr_int}),
        .iram_wr_data(iram_wr_data),
        .iram_rd_data(iram_rd_data)
    );

    buff #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WORD_WIDTH(WORD_WIDTH),
        .FRACTIONAL_L(FRACTIONAL_L)
    ) u_buff_mem (
        .clk(clk),
        .rstn(rstn),
        .buff_wr_enbl(buff_wr_enbl),
        .buff_rd_enbl(buff_rd_enbl),
        .buff_wr_addr(buff_wr_addr_int),
        .buff_rd_addr(buff_rd_addr_int),
        .buff_wr_data(compute_wr_data),
        .buff_rd_data(buff_rd_data)
    );

    oram #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .WORD_WIDTH(WORD_WIDTH)
    ) u_oram (
        .clk(clk),
        .rstn(rstn),
        .oram_wr_enbl(oram_wr_enbl),
        .oram_rd_enbl(oram_rd_enbl),
        .oram_wr_addr({1'b0, oram_wr_addr_int}),
        .oram_rd_addr(oram_rd_addr),
        .oram_wr_data(compute_wr_data),
        .oram_rd_data(oram_rd_data)
    );

    wire [WORD_WIDTH-1:0] iram_buff_rd_data;

    mux2 #(
        .DATA_WIDTH(WORD_WIDTH)
    ) u_i_buff_mux (
        .in0(iram_rd_data),
        .in1(buff_rd_data),
        .sel(i_buff_read_sel),
        .out(iram_buff_rd_data)
    );

    wire [WORD_WIDTH-1:0] sipo_dout0;
    wire [WORD_WIDTH-1:0] sipo_dout1;

    sipo #(
        .DATA_WIDTH(WORD_WIDTH)
    ) u_sipo (
        .clk(clk),
        .rstn(rstn),
        .en0_d(dFF1_enbl),
        .en1_d(dFF2_enbl),
        .din(iram_buff_rd_data),
        .dout0(sipo_dout0),
        .dout1(sipo_dout1)
    );

    wire [DATA_WIDTH-1:0] x_1;
    wire [DATA_WIDTH-1:0] x_2;

    mux2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux2x1 (
        .in0(sipo_dout0[WORD_WIDTH-1:DATA_WIDTH]),
        .in1(sipo_dout1[DATA_WIDTH-1:0]),
        .sel(mux2x1_sel),
        .out(x_1)
    );

    mux2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux2x2 (
        .in0(iram_buff_rd_data[WORD_WIDTH-1:DATA_WIDTH]),
        .in1(sipo_dout0[DATA_WIDTH-1:0]),
        .sel(mux2x2_sel),
        .out(x_2)
    );

    wire [DATA_WIDTH-1:0] dffw_msb_out;
    wire [DATA_WIDTH-1:0] dffw_lsb_out;
    wire [DATA_WIDTH-1:0] mux1w_out;
    wire [DATA_WIDTH-1:0] wref_out;
    wire [DATA_WIDTH-1:0] w_mult_out;
    wire [DATA_WIDTH-1:0] W;

    siso_32 u_dffw_msb (
        .clk(clk),
        .rstn(rstn),
        .en(dFFw_enbl),
        .din(iram_buff_rd_data[WORD_WIDTH-1:DATA_WIDTH]),
        .dout(dffw_msb_out)
    );

    siso_32 u_dffw_lsb (
        .clk(clk),
        .rstn(rstn),
        .en(dFFw_enbl),
        .din(iram_buff_rd_data[DATA_WIDTH-1:0]),
        .dout(dffw_lsb_out)
    );

    mux2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux1w (
        .in0(dffw_msb_out),
        .in1(dffw_lsb_out),
        .sel(count_addr_0 ? 1'b1 : 1'b0),
        .out(mux1w_out)
    );

    siso_32 u_wref_ff (
        .clk(clk),
        .rstn(rstn),
        .en(wref_ff_enbl),
        .din(iram_buff_rd_data[DATA_WIDTH-1:0]),
        .dout(wref_out)
    );

    multiplier #(
        .TOTAL_WIDTH(DATA_WIDTH),
        .REAL_LENGTH(REAL_LENGTH),
        .FRACTIONAL_L(FRACTIONAL_L)
    ) u_w_mult (
        .w1(mux1w_out),
        .w2(wref_out),
        .y(w_mult_out)
    );

    mux2 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_mux2w (
        .in0(mux1w_out),
        .in1(w_mult_out),
        .sel(mux2w_sel),
        .out(W)
    );

    wire [DATA_WIDTH-1:0] y1_int;
    wire [DATA_WIDTH-1:0] y2_int;

    compute #(
        .DATA_WIDTH(DATA_WIDTH),
        .REAL_LENGTH(REAL_LENGTH),
        .FRACTIONAL_L(FRACTIONAL_L)
    ) u_compute (
        .twiddle_factor(W),
        .x_1(x_1),
        .x_2(x_2),
        .y_1(y1_int),
        .y_2(y2_int)
    );

    wire [WORD_WIDTH-1:0] sipo_y1_s;
    wire [WORD_WIDTH-1:0] sipo_y0_s;

    sipo #(
        .DATA_WIDTH(WORD_WIDTH)
    ) u_sipo_store (
        .clk(clk),
        .rstn(rstn),
        .en0_d(dFF1_enbl_s),
        .en1_d(dFF2_enbl_s),
        .din({y1_int,y2_int}),
        .dout0(sipo_y0_s),
        .dout1(sipo_y1_s)
    );
    
    wire [WORD_WIDTH-1:0] wr_data_lvl1 = (mux1s_sel == 1'b0) ? sipo_y1_s : sipo_y0_s;
    wire [WORD_WIDTH-1:0] wr_data_other = (mux1s_sel == 1'b0) ? 
        {sipo_y1_s[WORD_WIDTH-1:DATA_WIDTH], sipo_y0_s[WORD_WIDTH-1:DATA_WIDTH]} :
        {sipo_y1_s[DATA_WIDTH-1:0],          sipo_y0_s[DATA_WIDTH-1:0]};

    assign compute_wr_data = (lvl_int == 4'd1) ? wr_data_lvl1 : wr_data_other;

    assign y = compute_wr_data;



endmodule