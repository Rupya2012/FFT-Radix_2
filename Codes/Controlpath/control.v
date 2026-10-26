module control #(
    parameter ADDR_WIDTH = 12
)(
    input clk,
    input rstn,
    input [3:0] lvl,
    input [ADDR_WIDTH-1:0] buff_ram_wr_addr,
    
    output i_buff_read_sel,
    output dFF1_enbl,
    output dFF2_enbl,
    output mux2x1_sel,
    output mux2x2_sel,
    output dFFw_enbl,
    output mux1w_sel,
    output wref_ff_enbl,
    output mux2w_sel,

    output dFF1_enbl_s,
    output dFF2_enbl_s,
    output mux1s_sel,
    output mux2s_sel,

    output iram_rd_enbl,
    output iram_wr_enbl,
    output buff_rd_enbl,
    output buff_wr_enbl,
    output oram_rd_enbl,
    output oram_wr_enbl,

    output add_gen_en_l,
    output add_gen_en_s,
    output add_0_1_l,
    output add_0_1_s,
    output tw_en,
    output waste_cycle,
    output counter_rst_l,
    output counter_rst_s,
    output tw_count_en,
    output lvl_enb,
    output done,
    output busy
);

    wire [2:0] count_5_init;
    wire [2:0] count_5;
    wire lvl_change;
    wire waste_cycle_raw;
    wire counter_rst_l_raw;
    wire counter_rst_s_raw;
    wire lvl_enb_raw;

    wire i_buff_read_sel_raw;
    wire dFF1_enbl_raw;
    wire dFF2_enbl_raw;
    wire mux2x1_sel_raw;
    wire mux2x2_sel_raw;
    wire dFFw_enbl_raw;
    wire mux1w_sel_raw;
    wire wref_ff_enbl_raw;
    wire mux2w_sel_raw;

    wire dFF1_enbl_s_raw;
    wire dFF2_enbl_s_raw;
    wire mux1s_sel_raw;
    wire mux2s_sel_raw;

    wire iram_rd_enbl_raw;
    wire iram_wr_enbl_raw;
    wire buff_rd_enbl_raw;
    wire buff_wr_enbl_raw;
    wire oram_rd_enbl_raw;
    wire oram_wr_enbl_raw;

    wire add_gen_en_l_raw;
    wire add_gen_en_s_raw;
    wire tw_count_en_raw;
    wire tw_en_raw;
    wire add_0_1_l_raw;
    wire add_0_1_s_raw;

    lvl_enb #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_lvl_enb (
        .clk(clk),
        .rstn(rstn),
        .lvl(lvl),
        .buff_ram_wr_addr(buff_ram_wr_addr),
        .lvl_enb(lvl_enb_raw)
    );

    reg done_reg;
    always @(posedge clk) begin
        if (!rstn) begin
            done_reg <= 1'b0;
        end else if (lvl >= 4'd12 && lvl_enb_raw) begin
            done_reg <= 1'b1;
        end
    end
    assign done = done_reg;
    assign busy = !done;

    wire lvl_enb_eff = done_reg ? 1'b0 : lvl_enb_raw;
    assign lvl_enb   = lvl_enb_eff;

    count_5_init u_count_5_init (
        .clk(clk),
        .rstn(rstn && !done_reg),
        .lvl_enb(lvl_enb_eff),
        .count_5_init(count_5_init),
        .lvl_change(lvl_change),
        .waste_cycle(waste_cycle_raw),
        .counter_rst_l(counter_rst_l_raw),
        .counter_rst_s(counter_rst_s_raw)
    );

    count_5 u_count_5 (
        .clk(clk),
        .rstn(rstn && !done_reg),
        .lvl_enb(lvl_enb_eff),
        .count_5(count_5)
    );

    reg_mux_control u_reg_mux_control (
        .clk(clk),
        .rstn(rstn && !done_reg),
        .count_5(count_5),
        .count_5_init(count_5_init),
        .lvl(lvl),
        .i_buff_read_sel(i_buff_read_sel_raw),
        .dFF1_enbl(dFF1_enbl_raw),
        .dFF2_enbl(dFF2_enbl_raw),
        .mux2x1_sel(mux2x1_sel_raw),
        .mux2x2_sel(mux2x2_sel_raw),
        .dFFw_enbl(dFFw_enbl_raw),
        .mux1w_sel(mux1w_sel_raw),
        .wref_ff_enbl(wref_ff_enbl_raw),
        .mux2w_sel(mux2w_sel_raw)
    );

    r_w_enb u_r_w_enb (
        .clk(clk),
        .rstn(rstn && !done_reg),
        .lvl(lvl),
        .count_5_init(count_5_init),
        .count_5(count_5),
        .iram_rd_enbl(iram_rd_enbl_raw),
        .iram_wr_enbl(iram_wr_enbl_raw),
        .buff_rd_enbl(buff_rd_enbl_raw),
        .buff_wr_enbl(buff_wr_enbl_raw),
        .oram_rd_enbl(oram_rd_enbl_raw),
        .oram_wr_enbl(oram_wr_enbl_raw)
    );

    add_gen_contol u_add_gen_control (
        .clk(clk),
        .rstn(rstn && !done_reg),
        .lvl(lvl),
        .count_5_init(count_5_init),
        .count_5(count_5),
        .add_gen_en_l(add_gen_en_l_raw),
        .add_gen_en_s(add_gen_en_s_raw),
        .tw_count_en(tw_count_en_raw),
        .tw_en(tw_en_raw),
        .add_0_1_l(add_0_1_l_raw),
        .add_0_1_s(add_0_1_s_raw)
    );

    mux_ctrl_strl u_mux_ctrl_str (
        .clk(clk),
        .rstn(rstn && !done_reg),
        .count_5(count_5),
        .count_5_init(count_5_init),
        .dFF1_enbl_s_raw(dFF1_enbl_s_raw),
        .dFF2_enbl_s_raw(dFF2_enbl_s_raw),
        .mux1s_sel_raw(mux1s_sel_raw),
        .mux2s_sel_raw(mux2s_sel_raw)
    );

    assign i_buff_read_sel = i_buff_read_sel_raw;
    assign dFF1_enbl       = done_reg ? 1'b0 : dFF1_enbl_raw;
    assign dFF2_enbl       = done_reg ? 1'b0 : dFF2_enbl_raw;
    assign mux2x1_sel      = mux2x1_sel_raw;
    assign mux2x2_sel      = mux2x2_sel_raw;
    assign dFFw_enbl       = done_reg ? 1'b0 : dFFw_enbl_raw;
    assign mux1w_sel       = mux1w_sel_raw;
    assign wref_ff_enbl    = done_reg ? 1'b0 : wref_ff_enbl_raw;
    assign mux2w_sel       = mux2w_sel_raw;

    assign dFF1_enbl_s     = done_reg ? 1'b0 : dFF1_enbl_s_raw;
    assign dFF2_enbl_s     = done_reg ? 1'b0 : dFF2_enbl_s_raw;
    assign mux1s_sel       = mux1s_sel_raw;
    assign mux2s_sel       = mux2s_sel_raw;

    assign iram_rd_enbl    = done_reg ? 1'b0 : iram_rd_enbl_raw;
    assign iram_wr_enbl    = done_reg ? 1'b0 : iram_wr_enbl_raw;
    assign buff_rd_enbl    = done_reg ? 1'b0 : buff_rd_enbl_raw;
    assign buff_wr_enbl    = done_reg ? 1'b0 : buff_wr_enbl_raw;
    assign oram_rd_enbl    = done_reg ? 1'b0 : oram_rd_enbl_raw;
    assign oram_wr_enbl    = done_reg ? 1'b0 : oram_wr_enbl_raw;

    assign add_gen_en_l    = done_reg ? 1'b0 : add_gen_en_l_raw;
    assign add_gen_en_s    = done_reg ? 1'b0 : add_gen_en_s_raw;
    assign add_0_1_l       = add_0_1_l_raw;
    assign add_0_1_s       = add_0_1_s_raw;
    assign tw_en           = tw_en_raw;
    assign waste_cycle     = waste_cycle_raw;
    assign counter_rst_l   = counter_rst_l_raw;
    assign counter_rst_s   = counter_rst_s_raw;
    assign tw_count_en     = done_reg ? 1'b0 : tw_count_en_raw;
    
    



endmodule
