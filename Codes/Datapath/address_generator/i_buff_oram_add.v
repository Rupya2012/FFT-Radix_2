module i_buff_oram_add #(
    parameter DATA_WIDTH      = 64,
    parameter IRAM_ADDR_WIDTH = 11,
    parameter BUFF_ADDR_WIDTH = 12,
    parameter ORAM_ADDR_WIDTH = 11
)(
    input clk,
    input rstn,
    input add_gen_en_l,       // control
    input add_gen_en_s,       // control
    input [3:0] lvl, 
    input add_0_1_l,          // control
    input add_0_1_s,          // control
    input tw_en,              // control
    input waste_cycle,        // control
    input counter_rst_l,
    input counter_rst_s,
    input tw_count_en,
    output count_addr_0,
    output [IRAM_ADDR_WIDTH-1:0] i_ram_rd_addr,
    output [BUFF_ADDR_WIDTH-1:0] buff_ram_rd_addr,
    output [BUFF_ADDR_WIDTH-1:0] buff_ram_wr_addr,
    output [ORAM_ADDR_WIDTH-1:0] oram_wr_addr
);

    wire [BUFF_ADDR_WIDTH-1:0] temp_load_add_data;
    wire [BUFF_ADDR_WIDTH-1:0] temp_store_add;
    wire [BUFF_ADDR_WIDTH-1:0] temp_load_add_tw;
    wire [BUFF_ADDR_WIDTH-1:0] temp_load_add;
    wire [BUFF_ADDR_WIDTH-1:0] temp_load_add_tw_waste_cycle;
    wire [BUFF_ADDR_WIDTH-1:0] add_tw;

    loading_add #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(BUFF_ADDR_WIDTH)
    ) la (
        .clk(clk),
        .rstn(rstn),
        .add_gen_en_l(add_gen_en_l),
        .lvl(lvl),
        .add_0_1_l(add_0_1_l),
        .tw_count_en(tw_count_en),
        .counter_rst_l(counter_rst_l),
        .count_addr_0(count_addr_0),
        .data_addr(temp_load_add_data),
        .tw_addr(temp_load_add_tw)
    );

    storing_add #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(BUFF_ADDR_WIDTH)
    ) sa (
        .clk(clk),
        .rstn(rstn),
        .add_gen_en_s(add_gen_en_s),
        .lvl(lvl),
        .add_0_1_s(add_0_1_s),
        .counter_rst_s(counter_rst_s),
        .addr(temp_store_add)
    );

    tw_init_cycle #(
        .ADDR_WIDTH(BUFF_ADDR_WIDTH)
    ) tc (
        .clk(clk),
        .rstn(rstn),
        .lvl(lvl),
        .waste_cycle(waste_cycle),
        .addr_tw_init(temp_load_add_tw_waste_cycle)
    );

    mux2 #(
        .DATA_WIDTH(BUFF_ADDR_WIDTH)
    ) tw_add_2 (
        .in0(temp_load_add_tw),
        .in1(temp_load_add_tw_waste_cycle),
        .sel(waste_cycle),
        .out(add_tw)
    );

    mux2 #(
        .DATA_WIDTH(BUFF_ADDR_WIDTH)
    ) addr_2 (
        .in0(temp_load_add_data),
        .in1(add_tw),
        .sel(tw_en || waste_cycle),
        .out(temp_load_add)
    );

    assign buff_ram_rd_addr = temp_load_add;
    assign buff_ram_wr_addr = temp_store_add;
    assign i_ram_rd_addr    = temp_load_add[IRAM_ADDR_WIDTH-1:0];
    assign oram_wr_addr     = temp_store_add[ORAM_ADDR_WIDTH-1:0];

endmodule
